extends SceneTree
const META := {"save_id":"p1-pill-test","saved_at_utc_ms":"0","settled_until_utc_ms":"0","sim_tick":"0"}
const DIR := "res://docs/verification/artifacts/content-p1-pills/"
var checks := 0
var failures := []
var serial := 0
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	func read(key: String) -> Dictionary: return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func exists(key: String) -> bool: return data.has(key)
	func write(key: String,value: String) -> Dictionary:
		if fail == "*" or fail == key: return {"ok":false,"error":"injected"}
		data[key] = value
		return {"ok":true}
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ",label)
func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"pill-"+str(serial),"type":kind,"expected_revision":s.state.revision,"payload":payload})
func funded(c: GameContent) -> GameSession:
	var s := GameSession.create_new_game(c)
	s.state.era_id = 3
	s.state.buildings = {"hut":2,"wooden_house":2,"forest_farm":2,"stone_mine":2,"herb_farm":3}
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.from_number(100000)
	return s
func _init() -> void: run.call_deferred()
func run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(c).ok,"content attached")
	check(AlchemySystem.PILLS.size() == 12,"12 pills")
	var targets := ["wood","spirit_grass_low","money","lingli"]
	for i in range(4):
		var id: String = AlchemySystem.P1_IDS[i]
		var def: Dictionary = AlchemySystem.PILLS[id]
		var s := funded(c)
		s.state.era_id = int(def.min_era)-1
		s.state.pills[id] = 20
		var before := s.state.to_snapshot_dict()
		check(not send(s,"refine_pill",{"pill_id":id}).ok and before == s.state.to_snapshot_dict(),id+" refine era")
		check(not send(s,"consume_pill",{"pill_id":id}).ok and before == s.state.to_snapshot_dict(),id+" consume era")
		s.state.era_id = int(def.min_era)
		for bad in [0,-1,100,1.5,"2",true]:
			before = s.state.to_snapshot_dict()
			for kind in ["refine_pill","consume_pill"]:
				check(not send(s,kind,{"pill_id":id,"count":bad}).ok and before == s.state.to_snapshot_dict(),id+" invalid "+str(bad)+kind)
		for n in [1,99]:
			var stock: int = int(s.state.pills[id])
			var grass: float = s.state.resources.spirit_grass_low.value.to_float()
			var qi: float = s.state.resources.lingli.value.to_float()
			check(send(s,"refine_pill",{"pill_id":id,"count":n}).ok and s.state.pills[id] == stock+n,id+" refine batch "+str(n))
			check(is_equal_approx(grass-s.state.resources.spirit_grass_low.value.to_float(),float(def.cost.get("spirit_grass_low",0))*n),id+" grass paid")
			check(is_equal_approx(qi-s.state.resources.lingli.value.to_float(),float(def.cost.get("lingli",0))*n),id+" qi paid")
			check(not s.state.resources.has(id),id+" no mirror")
		# Exact fractional discount uses shared Amount function.
		s.state.skills.alchemical_breath_control = 3
		var cost := AlchemySystem.refinement_cost(s.state,id,3)
		check(not cost.has("lingli") if i == 3 else is_equal_approx(cost.lingli.to_float(),102),id+" discounted batch")
		s.state.pills[id] = 999998
		before = s.state.to_snapshot_dict()
		check(not send(s,"refine_pill",{"pill_id":id,"count":2}).ok and before == s.state.to_snapshot_dict(),id+" cap atomic")
		check(send(s,"refine_pill",{"pill_id":id}).ok and s.state.pills[id] == 999999,id+" exact cap")
		before = s.state.to_snapshot_dict()
		check(not send(s,"refine_pill",{"pill_id":id}).ok and before == s.state.to_snapshot_dict(),id+" full cap")
		s.state.resources.lingli.value = AmountCompat.zero()
		s.state.resources.spirit_grass_low.value = AmountCompat.zero()
		s.state.resources.wood.value = AmountCompat.zero()
		before = s.state.to_snapshot_dict()
		check(not send(s,"refine_pill",{"pill_id":id}).ok and before == s.state.to_snapshot_dict(),id+" no half payment")
		s.state.pills[id] = 99
		for remaining in [0,100,300,500,3600]:
			s.state.buffs.clear()
			if remaining > 0: BuffSystem.apply_buff(s.state,def.effects.buff_id,remaining)
			before = s.state.to_snapshot_dict()
			var r := send(s,"consume_pill",{"pill_id":id})
			check(r.ok == (remaining < 300),id+" refresh "+str(remaining))
			if remaining >= 300: check(before == s.state.to_snapshot_dict(),id+" no extension atomic")
			else: check(AlchemySystem.p1_remaining(s.state,id) == 300 and r.events[0].applied_effects.net_extension_seconds == 300-remaining,id+" net receipt")
		s.state.buffs.clear()
		BuffSystem.apply_buff(s.state,def.effects.buff_id,500)
		check(send(s,"consume_pill",{"pill_id":id,"count":2}).ok and AlchemySystem.p1_remaining(s.state,id) == 600,id+" refresh not additive")
		s.state.buffs.clear()
		check(send(s,"consume_pill",{"pill_id":id,"count":12}).ok and AlchemySystem.p1_remaining(s.state,id) == 3600,id+" max duration")
		s.state.buffs.clear()
		before = s.state.to_snapshot_dict()
		check(not send(s,"consume_pill",{"pill_id":id,"count":13}).ok and before == s.state.to_snapshot_dict(),id+" max duration reject")
		check(send(s,"consume_pill",{"pill_id":id}).ok,id+" activates")
		var m := BuffSystem.compute_multipliers(s.state)
		check(m.specific_resource_multipliers == {targets[i]:1.0} and m.global_production_multiplier == 0,id+" single target")
		BuffSystem.apply_buff(s.state,"spirit_tide")
		check(BuffSystem.compute_multipliers(s.state).global_production_multiplier == 0.5,id+" global separate")
		if i == 3:
			BuffSystem.apply_buff(s.state,"spirit_surge")
			check(BuffSystem.compute_multipliers(s.state).specific_resource_multipliers.lingli == 1.5,"same resource additive")
		var encoded := SaveCodec.encode(s.state,c.content_version,META)
		check(encoded.ok and SaveCodec.decode(encoded.json).state.buffs == s.state.buffs,id+" roundtrip")
		for bad in [-1,1000000,0.5,"1",true,INF]: check(not AlchemySystem.validate(1,{id:bad},{}).is_empty(),id+" invalid saved stock "+str(bad))
		check(not AlchemySystem.validate(0,{id:0},{}).is_empty(),id+" old version ID rejected")
		var env: Dictionary = JSON.parse_string(encoded.json)
		env.state.buffs[def.effects.buff_id].effects.specific_resource_multiplier[targets[i]] = 2.0
		env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
		check(not SaveCodec.decode(JSON.stringify(env)).ok,id+" tampered effect rejected")
		for bad in [-1,3601,"300",true,INF]:
			var b := s.state.buffs.duplicate(true)
			b[def.effects.buff_id].remaining_seconds = bad
			check(not AlchemySystem.validate(1,{},b).is_empty(),id+" invalid saved remaining")
		check(not BuffSystem.apply_buff(s.state,def.effects.buff_id,300,{"production_multiplier":100}).ok,id+" cannot override")
		# Shared apply_buff can refresh an existing longer effect without creating
		# an internally invalid duration/remaining pair; old buff metadata stays unchanged.
		BuffSystem.apply_buff(s.state,def.effects.buff_id,500)
		BuffSystem.apply_buff(s.state,def.effects.buff_id,300)
		check(AlchemySystem.validate(1,s.state.pills,s.state.buffs).is_empty() and AlchemySystem.p1_remaining(s.state,id) == 500,id+" shared buff refresh remains saveable")
		# Analytical last-second production, independent of the offline implementation.
		var plain := funded(c).state
		for resource in plain.resources: plain.resources[resource].value = AmountCompat.zero()
		var boosted := plain.duplicate_state()
		BuffSystem.apply_buff(boosted,def.effects.buff_id,1)
		TimeAdvancer.advance(plain,c,1)
		TimeAdvancer.advance(boosted,c,1)
		for resource in plain.resources:
			check(is_equal_approx(boosted.resources[resource].value.to_float(),plain.resources[resource].value.to_float()*(2.0 if resource == targets[i] else 1.0)),id+" final tick actual target "+resource)
		check(not boosted.buffs.has(def.effects.buff_id),id+" removes after paid last tick")
		# Online seconds and optimized offline include exactly the final active tick.
		for duration in [1,299,300,301]:
			var base := funded(c).state
			base.pills[id] = 1
			for resource in base.resources: base.resources[resource].value = AmountCompat.zero()
			AlchemySystem.consume(base,id)
			var slow := base.duplicate_state()
			var fast := base.duplicate_state()
			for tick in duration: TimeAdvancer.advance(slow,c,1)
			OfflineSettlement.settle(fast,c,1000+duration*1000,1000)
			for resource in slow.resources:
				check(is_equal_approx(slow.resources[resource].value.to_float(),fast.resources[resource].value.to_float()),id+" offline "+resource+str(duration))
			check(slow.buffs == fast.buffs and slow.tribulation_roll_index == fast.tribulation_roll_index,id+" offline buff rng "+str(duration))
			check(slow.economy == fast.economy,id+" economy unchanged "+str(duration))
			slow = base.duplicate_state()
			BuffSystem.tick(slow,299)
			check(AlchemySystem.p1_remaining(slow,id) == 1,id+" final second active")
			BuffSystem.tick(slow,1)
			check(not slow.buffs.has(def.effects.buff_id),id+" expires")
		s.state.total_elapsed_seconds = 999999
		check(send(s,"reincarnate",{"mode":"normal"}).ok and s.state.pills.is_empty() and s.state.buffs.is_empty(),id+" rebirth clears")
	# Activated island economy, processing and remote rates are independent of home buffs.
	var eco := funded(c)
	for resource in eco.state.resources:
		eco.state.resources[resource].value = AmountCompat.zero()
		eco.state.resources[resource].unlocked = true
	for resource in ["wood","stone_low","spirit_grass_low","lingli"]: eco.state.resources[resource].value = AmountCompat.from_number(200)
	eco.state.buildings.workshop = 1
	check(send(eco,"migrate_processing",{}).ok,"economy migrated")
	check(send(eco,"open_island",{"island_id":"wood"}).ok,"remote wood opened")
	var job := send(eco,"craft",{"recipe_id":"liquid","count":2})
	check(job.ok,"processing starts "+str(job.get("error","")))
	var no_buff := eco.state.duplicate_state()
	for id in AlchemySystem.P1_IDS:
		eco.state.pills[id] = 1
		check(send(eco,"consume_pill",{"pill_id":id}).ok,"economy consumes "+id)
	for duration in [1,20,299,300,301,3601]:
		var slow := eco.state.duplicate_state()
		var fast := eco.state.duplicate_state()
		var remote_plain := no_buff.duplicate_state()
		for tick in duration: TimeAdvancer.advance(slow,c,1)
		OfflineSettlement.settle(fast,c,1000+duration*1000,1000)
		OfflineSettlement.settle(remote_plain,c,1000+duration*1000,1000)
		for resource in slow.resources: check(is_equal_approx(slow.resources[resource].value.to_float(),fast.resources[resource].value.to_float()),"economy offline "+resource+str(duration))
		check(slow.economy == fast.economy,"economy jump exact "+str(duration))
		check(slow.buffs == fast.buffs,"economy buff boundary "+str(duration))
		check(slow.economy == remote_plain.economy,"no remote/process acceleration "+str(duration))
	# Independent resources coexist; lifespan stop keeps zero production after death.
	var all := funded(c)
	for id in AlchemySystem.P1_IDS:
		all.state.pills[id] = 1
		check(send(all,"consume_pill",{"pill_id":id}).ok,"coexist "+id)
	check(all.state.buffs.size() == 4,"four coexist")
	check(not AlchemySystem.validate(2,{},{}).is_empty(),"future version rejected")
	var dead := all.state.duplicate_state()
	dead.total_elapsed_seconds = 999999
	var dead_before := dead.to_snapshot_dict()
	TimeAdvancer.advance(dead,c,300)
	check(dead_before == dead.to_snapshot_dict(),"death stops all simulation")
	# Original-byte migration and save-only retries preserve one paid command.
	var old := funded(c)
	var env: Dictionary = JSON.parse_string(SaveCodec.encode(old.state,c.content_version,META).json)
	env.state.erase("pill_version"); env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
	var original := JSON.stringify(env)
	var mem := Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c,mem)
	var migrated := SaveManager.current_state()
	check(migrated.pill_version == 1,"legacy migrates")
	var archive := "save_before_pills_"+original.sha256_text()
	mem.fail = archive
	check(not SaveManager.save(migrated,META).ok and mem.data[SaveSlots.SLOT_MAIN] == original,"archive failure intact")
	mem.fail = ""
	check(SaveManager.save(migrated,META).ok and mem.data[archive] == original,"archive readback retry")
	mem = Memory.new()
	SaveManager.configure(c,mem)
	var s := funded(c)
	check(send(s,"refine_pill",{"pill_id":"wood_nurture_pill"}).ok,"paid before slot failure")
	mem.fail = "*"
	check(not SaveManager.save(s.state,META).ok,"slot denial")
	mem.fail = ""
	check(SaveManager.save(s.state,META).ok,"slot save retry")
	SaveManager.configure(c,mem)
	var reloaded := SaveManager.current_state()
	check(reloaded.pills.wood_nurture_pill == 1 and is_equal_approx(reloaded.resources.lingli.value.to_float(),99960),"no double pay on reload")
	var shared := SaveManager.import_share_string(Marshalls.utf8_to_base64(original))
	check(shared.ok and shared.state.pill_version == 1,"old share migrates version")
	mem.data[SaveSlots.SLOT_BACKUP] = mem.data[SaveSlots.SLOT_MAIN]
	mem.data[SaveSlots.SLOT_MAIN] = "broken"
	SaveManager.configure(c,mem)
	check(SaveManager.current_state().pills.get("wood_nurture_pill",0) == 1,"corrupt main fallback")
	mem.data[SaveSlots.SLOT_BACKUP] = "broken too"
	SaveManager.configure(c,mem)
	check(SaveManager.current_state() == null,"two corrupt slots protected")
	SaveManager.reset_for_tests()
	# Explicit funded Era3 fixture for actual UI commands, not natural progression.
	var fixture := funded(c)
	fixture.state.skills.alchemical_breath_control = 3
	for resource in fixture.state.resources: fixture.state.resources[resource].value = AmountCompat.from_number(400)
	var f := FileAccess.open("res://src/verification/content_p1_pills_fixture.json",FileAccess.WRITE)
	f.store_string(SaveCodec.encode(fixture.state,c.content_version,META).json)
	f = FileAccess.open(DIR+"runner.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-PILL ",checks," checks failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

