extends SceneTree
## Synthetic contracts only. Earned creature lives belong to BEAST-2.
const DIR := "res://docs/verification/artifacts/content-p2-beasts/"
var checks := 0
var failures: Array[String] = []
var content: GameContent
var serial := 0
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"beast1-"+str(serial),"type":kind,"payload":payload,"expected_revision":s.state.revision})
func fresh(era: int = 6) -> GameSession:
	var s := GameSession.create_new_game(content,20261026)
	s.state.era_id=era; s.state.highest_era=6
	check(send(s,"activate_islands").ok,"synthetic activation")
	for id in s.state.economy.islands: s.state.economy.islands[id].opened=true
	for id in s.state.resources: s.state.resources[id].value=AmountCompat.from_number(10000)
	s.state.resources.foundation_pill.value=AmountCompat.zero()
	return s
func rejected(s: GameSession, kind: String, payload: Dictionary, label: String) -> void:
	var before := s.state.to_snapshot_dict()
	check(not send(s,kind,payload).ok and before==s.state.to_snapshot_dict(),label)
func run() -> void:
	content=ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	check(BeastSystem.BEAST_CONFIGS.size()==6 and BeastSystem.BEAST_TALENTS.size()==24,"6 beasts 24 talents")
	for id in BeastSystem.P2_IDS:
		var config: Dictionary=BeastSystem.BEAST_CONFIGS[id]
		var prefix := "stag" if id=="frost_stag" else "crane"
		for reason in ["era","supply","island","active","version","lifespan"]:
			var s:=fresh()
			if reason=="era": s.state.era_id=int(config.unlock_era)-1
			elif reason=="supply": s.state.economy={}
			elif reason=="island": s.state.economy.islands[config.island].opened=false
			elif reason=="active": s.state.beasts={"active":{"id":"jade_fox","exp":0,"stage":"egg"},"cooldown_remaining":0}
			elif reason=="version": s.state.beast_version=0
			else: s.state.total_elapsed_seconds=1e9
			rejected(s,"acquire_beast",{"beast_id":id},"atomic acquire "+id+reason)
		var s:=fresh(int(config.unlock_era))
		check(BeastSystem.get_view(s.state).acquire_requirements[id].ok,"shared eligibility")
		check(send(s,"acquire_beast",{"beast_id":id}).ok,"acquire "+id)
		rejected(s,"acquire_beast",{"beast_id":id},"cannot reacquire")
		var exhausted:=s.state.total_elapsed_seconds
		s.state.total_elapsed_seconds=1e9; s.state.beast_souls[id]=11
		rejected(s,"feed_beast",{},"exhausted feed")
		rejected(s,"unlock_beast_talent",{"talent_id":prefix+"_t1_boost"},"exhausted soul purchase")
		s.state.total_elapsed_seconds=exhausted; s.state.beast_souls.clear()
		var home_before:=BeastSystem.compute_multipliers(s.state)
		for exp_value in [0,100,500,1000]:
			var stage := "egg" if exp_value==0 else "young" if exp_value==100 else "growing" if exp_value==500 else "mature"
			s.state.beasts.active={"id":id,"stage":stage,"exp":exp_value}
			for t1 in [0,1]:
				s.state.beast_talents={prefix+"_t1_boost":t1}
				var boost: float = 0.0 if exp_value==0 else (0.1 if exp_value==100 else 0.15 if exp_value==500 else 0.2) + 0.01*t1
				for island in ["deep","ancient","void","home","herb"]:
					for res in ["refined_iron","mithril","cold_iron","spirit_grass_1000y","spirit_grass_100y","money"]:
						var expected: float = 1.0+boost if island==config.island and res in config.resources else 1.0
						check(is_equal_approx(BeastSystem.local_rate_multiplier(s.state,island,res),expected),"stage whitelist "+id+stage+island+res+str(t1))
				check(BeastSystem.compute_multipliers(s.state)==home_before,"new beast no home bonuses")
		# Every resource must be present at home; failed feeds preserve all fields.
		for resource in config.feed_resource:
			s.state.beasts={"active":{"id":id,"stage":"egg","exp":0},"cooldown_remaining":0}
			s.state.resources[resource].value=AmountCompat.zero()
			rejected(s,"feed_beast",{},"atomic shortage "+resource)
			s.state.resources[resource].value=AmountCompat.from_number(10000)
		for tier in 5:
			s=fresh()
			check(send(s,"acquire_beast",{"beast_id":id}).ok,"growth acquire")
			s.state.beast_souls[id]=11
			for step in tier:
				var talent_id: String=[prefix+"_t1_boost",prefix+"_t2_growth",prefix+"_t3_discount",prefix+"_t4_capacity"][step]
				check(send(s,"unlock_beast_talent",{"talent_id":talent_id}).ok,"ordered soul purchase "+talent_id)
			check(int(s.state.beast_souls[id])==11-[0,1,3,6,11][tier],"soul price sequence")
			var costs:=BeastSystem.feed_costs(s.state,id)
			for resource in costs:
				var expected:=maxi(1,int(float(config.feed_resource[resource])*0.6)) if tier>=3 else int(config.feed_resource[resource])
				check(int(costs[resource])==expected,"actual integer cost")
			# U/W are explicitly limited to turtle/phoenix.
			s.state.talents.sacred_beast_nurture_memory=5
			SectSystem.ensure_sect_state(s.state); s.state.sect.unlocked=true
			s.state.sect.techniques.sacred_beast_feed_conservation=5
			check(BeastSystem.feed_costs(s.state,id)==costs,"W whitelist unchanged")
			var count:=0
			while s.state.beasts.active.stage!="mature" and count<21:
				var before: AmountCompat=s.state.resources[config.feed_resource.keys()[0]].value
				check(send(s,"feed_beast").ok,"manual feed")
				check(int(s.state.beasts.active.exp)==(count+1)*(65 if tier>=2 else 50),"U whitelist / XP")
				check(is_equal_approx(before.subtract(s.state.resources[config.feed_resource.keys()[0]].value).to_float(),float(costs[config.feed_resource.keys()[0]])),"exact debit")
				check(float(s.state.beasts.cooldown_remaining)==300,"reset cooldown")
				if s.state.beasts.active.stage!="mature": rejected(s,"feed_beast",{},"cooldown rejects")
				BeastSystem.tick(s.state,300)
				count+=1
			check(count==(16 if tier>=2 else 20),"mature feed count")
			rejected(s,"feed_beast",{},"mature stops feeding")
			check(int(s.state.beast_souls[id])==11-[0,1,3,6,11][tier],"maturity gives no soul")
			var cap:=330.0 if tier==4 else 300.0
			check(IslandProgression.capacity(s.state,config.island)==cap,"flat local capacity")
			s.state.buildings.rebirth_lotus=1
			check(send(s,"reincarnate").ok,"formal reincarnation")
			check(s.state.beasts.active.is_empty() and int(s.state.beast_souls[id])==12-[0,1,3,6,11][tier],"exact one soul")
			check(BeastSystem.local_capacity_bonus(s.state,config.island)==0,"closed island no early bonus")
			if tier==4:
				s.state.economy.islands[config.island].opened=true
				check(BeastSystem.local_capacity_bonus(s.state,config.island)==30,"T4 persists without beast next life")
		for talent in BeastSystem.BEAST_TALENTS:
			if BeastSystem.BEAST_TALENTS[talent].beast_id!=id: continue
			s=fresh(); s.state.beast_souls[id]=11
			if int(BeastSystem.BEAST_TALENTS[talent].tier)>1: rejected(s,"unlock_beast_talent",{"talent_id":talent},"previous tier required")
			s.state.beast_souls[id]=0
			rejected(s,"unlock_beast_talent",{"talent_id":talent},"soul shortage")
	_test_time()
	_test_local_contracts()
	for id in BeastSystem.BEAST_CONFIGS:
		var s:=fresh(); s.state.beasts={"active":{"id":id,"stage":"mature","exp":1000},"cooldown_remaining":300}
		s.state.buildings.rebirth_lotus=1; s.state.beast_souls[id]=2147483647
		rejected(s,"reincarnate",{},"atomic overflow "+id)
		s.state.beast_souls[id]=0
		check(send(s,"reincarnate").ok and s.state.beast_souls[id]==1,"six beasts soul award "+id)
		s=fresh(); s.state.beasts={"active":{"id":id,"stage":"growing","exp":999},"cooldown_remaining":1}
		s.state.buildings.rebirth_lotus=1
		check(send(s,"reincarnate").ok and int(s.state.beast_souls.get(id,0))==0,"immature reincarnation grants no soul "+id)
	DirAccess.make_dir_recursive_absolute(DIR)
	var file:=FileAccess.open(DIR+"core.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-BEASTS ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL",0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func _test_time() -> void:
	for id in BeastSystem.P2_IDS:
		var s:=fresh()
		check(send(s,"acquire_beast",{"beast_id":id}).ok,"time acquire")
		var prepared:=TimeAdvancer.prepare_advance(s.state,content)
		TimeAdvancer.advance(s.state,content,1,prepared)
		# Reusing a prepared projection after a command must invalidate stale state.
		s.state.beasts.active.exp=1000; s.state.beasts.active.stage="mature"
		var a:=s.state.duplicate_state(); var b:=s.state.duplicate_state()
		TimeAdvancer.advance(a,content,10,prepared)
		TimeAdvancer.advance(b,content,10)
		check(a.to_snapshot_dict()==b.to_snapshot_dict(),"prepared invalidation "+id)
		var offline:=b.duplicate_state(); var online:=b.duplicate_state()
		OfflineClosedForm.advance(offline,content,301)
		TimeAdvancer.advance(online,content,301)
		check(offline.to_snapshot_dict()==online.to_snapshot_dict(),"offline exact local production "+id)
		check(int(offline.beasts.active.exp)==1000 and offline.beast_souls.is_empty(),"offline never feeds or grants soul")
		var cfg: Dictionary=BeastSystem.BEAST_CONFIGS[id]
		for res in cfg.resources:
			check(is_equal_approx(IslandEconomy.rate(b,cfg.island,res),float(IslandEconomy.supply_data().islands[cfg.island].rates[res])*1.2),"rate integration "+res)

func _test_local_contracts() -> void:
	for id in BeastSystem.P2_IDS:
		var cfg: Dictionary=BeastSystem.BEAST_CONFIGS[id]
		var prefix: String="stag" if id=="frost_stag" else "crane"
		var s:=fresh()
		check(send(s,"acquire_beast",{"beast_id":id}).ok,"stacking acquire")
		s.state.beasts.active={"id":id,"exp":1000,"stage":"mature"}
		s.state.beast_talents={prefix+"_t1_boost":1,prefix+"_t2_growth":1,prefix+"_t3_discount":1,prefix+"_t4_capacity":1}
		for rank in 4:
			s.state.skills.frontier_storekeeping=rank
			check(IslandProgression.capacity(s.state,cfg.island)==330+100*rank,"T4 adds flat30 after SKS")
		var old_cap:=IslandEconomy.home_cap(s.state,cfg.resources[0],content.processing_catalog)
		var home_without:=s.state.duplicate_state(); home_without.beasts={}; home_without.beast_talents={}
		check(old_cap==IslandEconomy.home_cap(home_without,cfg.resources[0],content.processing_catalog),"local T4 never changes home cap")
		for skill in ["deep_vein_resonance","ancient_herb_attunement","void_essence_attunement"]:
			s.state.skills[skill]=3
		s.state.talents.frontier_prospector_memory=5
		s.state.buildings[IslandEconomy.supply_data().dispatch[cfg.island]]=1
		if id=="herb_crane": BuffSystem.apply_buff(s.state,"p2_ancient_dew",600)
		for resource in cfg.resources:
			var without:=s.state.duplicate_state(); without.beasts={}
			check(is_equal_approx(IslandEconomy.rate(s.state,cfg.island,resource),IslandEconomy.rate(without,cfg.island,resource)*1.21),"independent multiplier stacking")
		# Live capacity/reservation helpers must expose exactly the added space.
		var resource: String=cfg.resources[0]
		var cap:=IslandProgression.capacity(s.state,cfg.island)
		s.state.economy.islands[cfg.island].inventory[resource]=str(cap-10)
		check(is_equal_approx(IslandEconomy.free_space(s.state,cfg.island,resource,content.processing_catalog),10),"local free space with T4")
		var prepared: Dictionary={}
		IslandEconomy.tick_prepared(s.state,content.processing_catalog,prepared)
		# Removing the synthetic owned T4 proves idle fast paths do not keep old capacity.
		s.state.beast_talents.erase(prefix+"_t4_capacity")
		IslandEconomy.tick_prepared(s.state,content.processing_catalog,prepared)
		check(IslandEconomy.free_space(s.state,cfg.island,resource,content.processing_catalog)==0,"capacity cache invalidation")
		var view:=IslandEconomy.manufacturing_view(s.state,content.processing_catalog)
		check(float(view.islands[cfg.island].capacity)==cap-30,"view uses current effective capacity")
		var route: String="deep_iron_home" if id=="frost_stag" else "ancient_grass_home"
		var home_cap:=IslandEconomy.home_cap(s.state,resource,content.processing_catalog)
		s.state.resources[resource].value=AmountCompat.from_number(home_cap-5)
		s.state.economy.trips[route]={"version":1,"remaining":1,"cargo":"5"}
		check(IslandEconomy.reserved(s.state,"home",resource,content.processing_catalog)==5,"cargo reserves existing home space")
		var info:=IslandEconomy.departure_info(s.state,content.processing_catalog,route,{"reserve":"0","target":str(home_cap),"level":3})
		check(float(info.cargo)==0 and float(info.space)==0 and float(info.throughput)==30,"beast never expands transport or oversubscribes arrival")
		IslandEconomy.tick(s.state,content.processing_catalog)
		check(is_equal_approx(IslandEconomy.value(s.state,"home",resource),home_cap) and IslandEconomy.reserved(s.state,"home",resource,content.processing_catalog)==0,"arrival consumes reservation exactly")
