extends SceneTree
## Synthetic isolated W fixtures. Earned / UI paths belong to SECT-2.
const DIR := "res://docs/verification/artifacts/content-p2-sect/"
var content: GameContent
var checks := 0
var failures: Array[String] = []
var serial := 0
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ",label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"sect2-"+str(serial),"type":kind,"payload":payload,"expected_revision":s.state.revision})
func fresh(era: int = 6) -> GameSession:
	var s := GameSession.create_new_game(content,20261025)
	s.state.era_id = era
	s.state.highest_era = 6
	s.state.buildings.core_storehouse_4 = 1
	s.state.buildings.core_storehouse_5 = 1
	check(send(s,"activate_islands").ok,"synthetic activation")
	for island in s.state.economy.islands: s.state.economy.islands[island].opened = true
	for id in s.state.resources:
		s.state.resources[id].value = AmountCompat.from_number(1000000)
		s.state.resources[id].unlocked = true
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	s.state.sect.contribution = "10000"
	return s
func rejected(s: GameSession, kind: String, payload: Dictionary, label: String) -> void:
	var before := s.state.to_snapshot_dict()
	check(not send(s,kind,payload).ok and before == s.state.to_snapshot_dict(),label)
func frozen(id: String, instance: String = "sect2-fixture", era: int = 6) -> Dictionary:
	var t: Dictionary = SectSystem.P2_TASKS[id]
	var cfg: Dictionary = SectSystem.RARITY_CONFIGS[t.rarity]
	var rewards: Dictionary = t.rewards.duplicate(true)
	rewards.contribution = cfg.contrib_min
	rewards.money = int(50*float(cfg.reward_mult)*era)
	return {"id":instance,"template_id":id,"generation_era":era,"name":t.name,"desc":t.desc,"rarity":t.rarity,"rarity_name":cfg.name,"rarity_color":cfg.color,"duration":cfg.duration,"elapsed":0,"rewards":rewards}
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	check(SectSystem.TECHNIQUES.size()==8 and SectSystem.MARKET_ITEMS.size()==8 and SectSystem.P2_TASKS.size()==10,"8/30/8 registry")
	_techniques()
	_pills()
	_beasts()
	_tasks()
	_market()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"core.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-SECT ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL",0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func _techniques() -> void:
	var costs := [[120,180,270,405,608],[150,225,338,507,760]]
	var materials := [[10,15,23,34,51],[200,300,450,675,1013]]
	for i in 2:
		var id: String = SectSystem.P2_TECHNIQUES[i]
		var resource := "stone_low" if i==0 else "wood"
		var s := fresh()
		for level in 5:
			var before: AmountCompat = s.state.resources[resource].value
			var contribution := float(s.state.sect.contribution)
			check(send(s,"learn_sect_technique",{"technique_id":id}).ok,"learn "+id)
			check(contribution-float(s.state.sect.contribution)==costs[i][level] and before.subtract(s.state.resources[resource].value).to_float()==materials[i][level],"rank costs "+id+str(level))
		for reason in ["max","era","membership","supply","version","contribution","material","unknown","lifespan"]:
			s = fresh()
			if reason=="max": s.state.sect.techniques[id]=5
			elif reason=="era": s.state.era_id=3
			elif reason=="membership": s.state.sect.unlocked=false
			elif reason=="supply": s.state.economy={}
			elif reason=="version": s.state.sect_version=1
			elif reason=="contribution": s.state.sect.contribution="0"
			elif reason=="material": s.state.resources[resource].value=AmountCompat.zero()
			elif reason=="lifespan": s.state.total_elapsed_seconds=1e9
			rejected(s,"learn_sect_technique",{"technique_id":"unknown" if reason=="unknown" else id},"learn atomic "+reason)
	var s := fresh()
	s.state.sect.techniques={"p2_pill_qi_conservation":5,"sacred_beast_feed_conservation":5}
	s.state.sect.market_purchases={"refined_iron_reserve":10,"ancient_herb_reserve":9}
	SectSystem.on_reincarnate(s.state)
	check(s.state.sect.techniques.p2_pill_qi_conservation==5 and s.state.sect.market_purchases.refined_iron_reserve==10,"cross life retention")
	check(SectSystem.active_level(s.state,"p2_pill_qi_conservation")==0,"retired sect inactive")
	for era in [1,3,4,6]:
		for joined in [false,true]:
			s.state.era_id=era; s.state.sect.unlocked=joined
			check(SectSystem.active_level(s.state,"p2_pill_qi_conservation")== (5 if era>=4 and joined else 0),"current life gate")
	s=fresh()
	s.state.sect.techniques={"p2_pill_qi_conservation":5,"sacred_beast_feed_conservation":4}
	s.state.sect.market_purchases={"refined_iron_reserve":7,"ancient_herb_reserve":3}
	var permanent := s.state.sect.duplicate(true)
	s.state.total_elapsed_seconds=1e9
	check(send(s,"reincarnate",{"mode":"normal"}).ok,"formal reincarnation")
	for field in ["techniques","market_purchases","contribution"]: check(s.state.sect[field]==permanent[field],"formal inheritance "+field)
	check(send(s,"join_sect").ok and SectSystem.active_level(s.state,"sacred_beast_feed_conservation")==0,"Era1 rejoin no P2 effect")
func _pills() -> void:
	var s := fresh()
	for id in AlchemySystem.PILLS:
		for level in 6:
			s.state.sect.techniques.p2_pill_qi_conservation=level
			for count in [1,5,99]:
				var cost := AlchemySystem.refinement_cost(s.state,id,count)
				var plain := s.state.duplicate_state()
				plain.sect.techniques.clear()
				var base := AlchemySystem.refinement_cost(plain,id,count)
				for resource in cost:
					if cost[resource] is int:
						check(cost[resource]==base[resource],"nested pill unchanged")
					else:
						var expected: AmountCompat = base[resource]
						if id in AlchemySystem.P2_IDS and resource=="lingli": expected=expected.multiply(AmountCompat.from_number(100-2*level)).divide(AmountCompat.from_number(100))
						check(cost[resource].compare_to(expected)==0,"recipe "+id+resource+str([level,count]))
	for id in AlchemySystem.P2_IDS:
		s=fresh(); s.state.sect.techniques.p2_pill_qi_conservation=5
		s.state.skills.alchemical_breath_control=3
		s.state.sect.techniques.alchemy_herb_conservation=5
		s.state.talents.elixir_conservation_memory=5
		var costs := AlchemySystem.refinement_cost(s.state,id,99)
		var unit := AlchemySystem.refinement_cost(s.state,id)
		check(costs.lingli.compare_to(unit.lingli.multiply(AmountCompat.from_number(99)))==0,"unit batch equality "+id)
		var before: AmountCompat = s.state.resources.lingli.value
		var result := send(s,"refine_pill",{"pill_id":id,"count":99})
		check(result.ok and before.subtract(s.state.resources.lingli.value).compare_to(costs.lingli)==0,"actual debit "+id)
		check(result.ok and result.events[0].paid_cost.lingli==costs.lingli.serialize(),"paid receipt "+id)
	# Sect techniques do not enter manufacturing cost calculation.
	var catalog := content.processing_catalog
	s=fresh()
	for recipe in catalog.recipes:
		var before := IslandEconomy.effective_inputs(s.state,catalog,"home",recipe)
		s.state.sect.techniques.p2_pill_qi_conservation=5
		check(before==IslandEconomy.effective_inputs(s.state,catalog,"home",recipe),"manufacturing unchanged "+recipe)
		s.state.sect.techniques.clear()
func _beasts() -> void:
	for beast in ["iron_turtle","fire_phoenix"]:
		var prefix := "turtle" if beast=="iron_turtle" else "phoenix"
		for soul in [false,true]:
			for growth in [false,true]:
				for level in 6:
					for talent in 6:
						var s := fresh()
						s.state.sect.techniques.sacred_beast_feed_conservation=level
						s.state.talents.sacred_beast_nurture_memory=talent
						s.state.beasts={"active":{"id":beast,"stage":"egg","exp":0},"cooldown_remaining":0.0}
						if soul: s.state.beast_talents[prefix+"_t3_cheap"]=1
						if growth: s.state.beast_talents[prefix+"_t2_speed"]=1
						var costs := BeastSystem.feed_costs(s.state,beast)
						var expected := {}
						var before := {}
						for resource in BeastSystem.BEAST_CONFIGS[beast].feed_resource:
							expected[resource]=maxi(1,int(BeastSystem.BEAST_CONFIGS[beast].feed_resource[resource])*(60 if soul else 100)*(100-2*level)/10000)
							before[resource]=s.state.resources[resource].value
							check(costs[resource]==expected[resource],"integer feed "+beast+str([soul,level,talent]))
						check(send(s,"feed_beast").ok,"feed command")
						for resource in costs: check(before[resource].subtract(s.state.resources[resource].value).to_float()==expected[resource],"feed actual debit")
						check(s.state.beasts.active.exp==(65 if growth else 50)+10*talent and s.state.beasts.cooldown_remaining==300,"XP/cooldown unchanged")
	var s := fresh()
	s.state.sect.techniques.sacred_beast_feed_conservation=5
	for beast in ["jade_fox","cloud_serpent"]:
		var plain := s.state.duplicate_state(); plain.sect.techniques.clear()
		check(BeastSystem.feed_costs(s.state,beast)==BeastSystem.feed_costs(plain,beast),"excluded "+beast)
	s.state.era_id=5
	check(BeastSystem.feed_costs(s.state,"fire_phoenix").spirit_grass_1000y==10,"phoenix Era5 no new discount")
func _tasks() -> void:
	var s := fresh()
	for era in [3,4,5,6]:
		for beast in ["","iron_turtle","fire_phoenix"]:
			for mask in 8:
				s.state.era_id=era; s.state.beasts={"active":{"id":beast}}
				for i in 3: s.state.economy.islands[["deep","ancient","void"][i]].opened=bool(mask & (1 << i))
				for id in SectSystem.P2_TASKS:
					var t: Dictionary = SectSystem.P2_TASKS[id]
					var expected: bool = era>=t.min_era and (t.requires_active_beast=="" or beast==t.requires_active_beast)
					for island in t.requires_open_islands: expected=expected and s.state.economy.islands[island].opened
					var found := false
					for task in SectSystem.eligible_templates(s.state,t.rarity): found=found or task.get("template_id")==id
					check(found==expected,"eligibility "+id+str([era,beast,mask]))
	for id in SectSystem.P2_TASKS:
		s=fresh()
		var task := frozen(id)
		s.state.sect.available_tasks=[task]
		check(SectSaveContract.validate(2,s.state.sect).is_empty(),"registered "+id)
		check(send(s,"start_sect_expedition",{"task_id":task.id}).ok,"start "+id)
		rejected(s,"claim_sect_expedition",{},"unfinished")
		s.state.beasts.clear(); s.state.era_id=3
		for island in s.state.economy.islands: s.state.economy.islands[island].opened=false
		SectSystem.tick(s.state,float(task.duration))
		var before := s.state.duplicate_state()
		check(send(s,"claim_sect_expedition").ok,"frozen eligibility "+id)
		for resource in task.rewards:
			if resource=="contribution": continue
			check(s.state.resources[resource].value.subtract(before.resources[resource].value).to_float()==task.rewards[resource],"reward exact no clamp "+id+resource)
		check(s.state.economy==before.economy,"no remote mirror")
		rejected(s,"claim_sect_expedition",{},"no double reward")
	# Real generator samples are structural checks, not earned natural acquisition.
	s=fresh(); s.state.beasts={"active":{"id":"iron_turtle"}}
	for i in 100:
		check(SectSystem.refresh_tasks(s.state,true).ok and SectSaveContract.validate(2,s.state.sect).is_empty(),"generator snapshot "+str(i))
		check(SectSystem.eligible_templates(s.state,"legendary").size()==4,"legendary old3 + turtle1 (fox mutually exclusive)")
func _market() -> void:
	for id in SectSystem.P2_MARKET:
		var def: Dictionary = SectSystem.MARKET_ITEMS[id]
		var resource: String = def.grant_resource
		var s := fresh()
		s.state.resources[resource].value=AmountCompat.zero()
		for count in 10:
			var before := float(s.state.sect.contribution)
			check(send(s,"buy_sect_market_item",{"item_id":id}).ok,"buy "+id)
			check(before-float(s.state.sect.contribution)==def.cost and s.state.sect.market_purchases[id]==count+1,"atomic cost/count")
		check(s.state.resources[resource].value.to_float()==def.grant_amount*10,"lifetime quantity")
		rejected(s,"buy_sect_market_item",{"item_id":id},"lifetime cap")
		for reason in ["era","membership","version","supply","island","contribution","full","overflow","reserved","unknown"]:
			s=fresh(); s.state.resources[resource].value=AmountCompat.zero()
			if reason=="era": s.state.era_id=int(def.min_era)-1
			elif reason=="membership": s.state.sect.unlocked=false
			elif reason=="version": s.state.sect_version=1
			elif reason=="supply": s.state.economy={}
			elif reason=="island": s.state.economy.islands[def.requires_open_island].opened=false
			elif reason=="contribution": s.state.sect.contribution="0"
			elif reason in ["full","overflow","reserved"]:
				var cap := IslandEconomy.home_cap(s.state,resource,content.processing_catalog)
				s.state.resources[resource].value=AmountCompat.from_number(cap+(1 if reason=="overflow" else 0))
				if reason=="reserved":
					s.state.resources[resource].value=AmountCompat.from_number(cap-def.grant_amount)
					var route := "deep_iron" if resource=="refined_iron" else "ancient_1000y"
					for candidate in IslandEconomy.route_defs(s.state):
						if IslandEconomy.route_defs(s.state)[candidate][1]=="home" and IslandEconomy.route_defs(s.state)[candidate][2]==resource: route=candidate
					s.state.economy.trips[route]={"cargo":1,"remaining":1}
			rejected(s,"buy_sect_market_item",{"item_id":"unknown" if reason=="unknown" else id},"market no mutation "+reason)
		s=fresh(); var cap := IslandEconomy.home_cap(s.state,resource,content.processing_catalog)
		s.state.resources[resource].value=AmountCompat.from_number(cap-def.grant_amount)
		check(send(s,"buy_sect_market_item",{"item_id":id}).ok and s.state.resources[resource].value.to_float()==cap,"exact fit")
		check(SectSystem.market_destination_error(s.state,id,null)=="MARKET_CONTENT_REQUIRED","missing content named")
		var original_catalog := content.processing_catalog
		for invalid in ["unparseable",-1,true,INF]:
			content.processing_catalog=original_catalog.duplicate(true)
			content.processing_catalog.resources[resource].cap=invalid
			check(SectSystem.market_destination_error(s.state,id,content)=="MARKET_CAPACITY_INVALID","invalid cap named")
		content.processing_catalog=original_catalog.duplicate(true)
		content.processing_catalog.resources.erase(resource)
		check(SectSystem.market_destination_error(s.state,id,content)=="MARKET_RESOURCE_MISSING","unknown resource named")
		content.processing_catalog=original_catalog
