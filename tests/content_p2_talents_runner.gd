extends SceneTree
const META := {"save_id":"talent2-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
var serial := 0
var content: GameContent
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var corrupt := ""
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if fail == "*" or key == fail: return {"ok":false,"error":"injected"}
		data[key] = "corrupt" if key == corrupt else value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"p2-talent-"+str(serial), "type":kind, "payload":payload, "expected_revision":s.state.revision})
func fresh() -> GameSession:
	var s := GameSession.create_new_game(content, 20261024)
	s.state.reincarnation_count = 1
	s.state.highest_era = 6
	s.state.achievements.erase("story")
	StoryProgress.ensure(s.state)
	s.state.life_ledger = {}
	LifeLedger.initialize(s.state, true)
	return s
func stock(s: GameState, id: String, amount: float) -> void:
	s.resources[id] = {"value":AmountCompat.from_number(amount), "unlocked":true, "ever_obtained":true}
func stop_routes(s: GameSession) -> void:
	s.state.economy.routes = {}
	for id in IslandEconomy.supply_data().routes:
		var def: Array = IslandEconomy.supply_data().routes[id]
		if s.state.economy.islands.has(def[0]) and s.state.economy.islands.has(def[1]) and s.state.economy.islands[def[0]].opened and s.state.economy.islands[def[1]].opened:
			s.state.economy.routes[id] = {"enabled":false, "reserve":"0", "target":"100", "level":1}
func previous_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0,value)
	bytes.encode_u64(0,bytes.decode_u64(0)-1)
	return bytes.decode_double(0)
func _init() -> void: run.call_deferred()
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"supply attached")
	check(TalentSystem.TALENTS.size() == 9,"nine definitions")
	for id in TalentSystem.P2_IDS:
		var s := fresh()
		s.state.dao_heart = AmountCompat.from_number(310)
		for gate in ["reincarnation", "highest", "version"]:
			s.state.reincarnation_count = 0 if gate == "reincarnation" else 1
			s.state.highest_era = 3 if gate == "highest" else 6
			s.state.talent_version = 2 if gate == "version" else 3
			var before := s.state.to_snapshot_dict()
			var rejected := send(s,"learn_talent",{"talent_id":id})
			check(not rejected.ok and rejected.events.is_empty() and before == s.state.to_snapshot_dict(),id+" atomic "+gate)
		s.state.talent_version = 3
		for rank in range(5):
			check(TalentSystem.get_cost(id,rank).to_float() == [10,20,40,80,160][rank],id+" cost")
			check(send(s,"learn_talent",{"talent_id":id}).ok and s.state.talents[id] == rank+1,id+" learn")
		var before := s.state.to_snapshot_dict()
		check(s.state.dao_heart.to_float() == 0.0 and not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),id+" max atomic")
		var encoded := SaveCodec.encode(s.state,content.content_version,META)
		check(encoded.ok and SaveCodec.decode(encoded.json).ok,id+" roundtrip in era1 "+JSON.stringify(encoded if not encoded.ok else SaveCodec.decode(encoded.json).get("error")))
		s = fresh()
		s.state.dao_heart = AmountCompat.from_number(9)
		before = s.state.to_snapshot_dict()
		check(not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),id+" insufficient")
		for version in [1,2]:
			check(not TalentSystem.validate(version,{id:0}).is_empty(),id+" older ID rejected even zero")
		for value in [-1,6,0.5,true,"1",INF,NAN]:
			check(not TalentSystem.validate(3,{id:value}).is_empty(),id+" malformed")
		for gate in ["reincarnation", "highest"]:
			s = fresh()
			s.state.talents[id] = 1
			s.state.reincarnation_count = 0 if gate == "reincarnation" else 1
			s.state.highest_era = 3 if gate == "highest" else 6
			check(not SaveCodec.encode(s.state,content.content_version,META).ok,id+" contradictory encode")
	_test_costs()
	_test_rates()
	_test_beasts()
	_test_save()
	_test_reincarnation()
	DirAccess.make_dir_recursive_absolute("res://docs/verification/artifacts/content-p2-talents")
	var file := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/content-p2-talents/runner.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-TALENTS ",checks," checks failures=",JSON.stringify(failures))
	print("RUNNER_RESULT status=%s exit=%d" % ["PASS" if failures.is_empty() else "FAIL", 0 if failures.is_empty() else 1])
	quit(0 if failures.is_empty() else 1)
func _test_costs() -> void:
	for rank in range(6):
		var s := fresh()
		s.state.era_id = 6
		s.state.buildings.herb_farm = 3
		s.state.skills.alchemical_breath_control = 3
		s.state.talents["elixir_conservation_memory"] = rank
		for count in [1,99]:
			for pill in AlchemySystem.PILLS:
				var costs := AlchemySystem.refinement_cost(s.state,pill,count)
				var plain := s.state.duplicate_state()
				plain.talents = {}
				var original := AlchemySystem.refinement_cost(plain,pill,count)
				for resource in costs:
					if costs[resource] is AmountCompat:
						var multiplier := (1.0-0.04*rank) if (pill == "lifespan_pill" and resource == "spirit_grass_low") or (pill == "tribulation_pill" and resource == "spirit_grass_100y") else 1.0
						check(is_equal_approx(costs[resource].to_float(),original[resource].to_float()*multiplier),"cost scope "+pill+resource+str(rank)+str(count))
					else: check(costs[resource] == original[resource],"nested pill unchanged")
			for pill in ["lifespan_pill","tribulation_pill"]:
				var costs := AlchemySystem.refinement_cost(s.state,pill,count)
				for resource in costs:
					if costs[resource] is AmountCompat: stock(s.state,resource,costs[resource].to_float())
					else: s.state.pills[resource] = costs[resource]
				var herb := "spirit_grass_low" if pill == "lifespan_pill" else "spirit_grass_100y"
				stock(s.state,herb,costs[herb].to_float()-0.00001)
				var before := s.state.to_snapshot_dict()
				check(not send(s,"refine_pill",{"pill_id":pill,"count":count}).ok and before == s.state.to_snapshot_dict(),"short herbs atomic "+pill+str(rank)+str(count))
				stock(s.state,herb,costs[herb].to_float())
				var exact: float = costs[herb].to_float()
				stock(s.state,herb,previous_float(exact))
				before = s.state.to_snapshot_dict()
				check(not send(s,"refine_pill",{"pill_id":pill,"count":count}).ok and before == s.state.to_snapshot_dict(),"representable shortfall atomic")
				stock(s.state,herb,exact)
				var paid := send(s,"refine_pill",{"pill_id":pill,"count":count})
				check(paid.ok,"exact discounted cost payable "+pill+str(rank)+str(count)+JSON.stringify(paid))
				check(s.state.resources[herb].value.sign == 0,"exact herbs exhausted")
func _test_rates() -> void:
	var s := fresh()
	s.state.era_id = 6
	check(send(s,"activate_islands").ok,"activate economy")
	for island in ["deep","ancient","void"]:
		for resource in IslandEconomy.supply_data().islands[island].rates:
			check(IslandEconomy.rate(s.state,island,resource) == 0,"unopened zero")
			s.state.economy.islands[island].opened = true
			for rank in range(6):
				s.state.talents["frontier_prospector_memory"] = rank
				var base := float(IslandEconomy.supply_data().islands[island].rates[resource])
				check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),base*(1+0.1*rank)),"local linear multiplier")
				s.state.buildings[IslandEconomy.supply_data().dispatch[island]] = 1
				check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),base*2*(1+0.1*rank)),"dispatch multiplicative")
				s.state.buildings[IslandEconomy.supply_data().dispatch[island]] = 0
			s.state.economy.islands[island].opened = false
	for island in ["wood","ore","herb"]:
		s.state.economy.islands[island].opened = true
		for resource in IslandEconomy.ISLANDS[island].rates:
			check(is_equal_approx(IslandEconomy.rate(s.state,island,resource),float(IslandEconomy.ISLANDS[island].rates[resource])),"old islands unaffected")
	for rank in [0,1,5]:
		s.state.talents["frontier_prospector_memory"] = rank
		s.state.economy.islands.deep.opened = true
		stop_routes(s)
		s.state.economy.islands.deep.inventory = {}
		var slow := s.state.duplicate_state()
		var fast := s.state.duplicate_state()
		for tick in range(60): TimeAdvancer.advance(slow,content,1)
		OfflineSettlement.settle(fast,content,61000,1000)
		check(slow.economy == fast.economy,"online offline economy rank "+str(rank))
		check(is_equal_approx(IslandEconomy.value(fast,"deep","cold_iron"),3*(1+0.1*rank)),"sixty second cold iron")
	s.state.talents = {}
	s.state.skills = {"deep_vein_resonance":3}
	s.state.buildings.mineral_focus = 1
	s.state.economy.islands.deep.inventory = {"cold_iron":"0"}
	s.state.dao_heart = AmountCompat.from_number(25)
	var prior := IslandEconomy.rate(s.state,"deep","cold_iron")
	check(send(s,"learn_talent",{"talent_id":"frontier_prospector_memory"}).ok,"buy after previous advance")
	check(is_equal_approx(IslandEconomy.rate(s.state,"deep","cold_iron"),prior*1.1),"skill dispatch and talent multiply")
	check(IslandEconomy.value(s.state,"deep","cold_iron") == 0,"purchase does not backfill")
	s.advance_time(1)
	check(is_equal_approx(IslandEconomy.value(s.state,"deep","cold_iron"),prior*1.1),"next advance invalidates prior prepared calculation")
	var cap := IslandProgression.capacity(s.state,"deep")
	s.state.economy.islands.deep.inventory.cold_iron = str(cap)
	s.advance_time(2)
	check(IslandEconomy.value(s.state,"deep","cold_iron") == cap,"full local capacity stops production")
func _test_beasts() -> void:
	for rank in range(6):
		for beast in ["jade_fox","iron_turtle","fire_phoenix"]:
			for soul in [false,true]:
				var s := fresh()
				s.state.era_id = 6
				s.state.talents["sacred_beast_nurture_memory"] = rank
				s.state.beasts = {"active":{"id":beast,"stage":"egg","exp":0},"cooldown_remaining":0.0}
				var soul_id: String = {"jade_fox":"fox_t2_speed","iron_turtle":"turtle_t2_speed","fire_phoenix":"phoenix_t2_speed"}[beast]
				s.state.beast_talents = {soul_id:1} if soul else {}
				for resource in BeastSystem.BEAST_CONFIGS[beast].feed_resource: stock(s.state,resource,100000)
				check(send(s,"feed_beast").ok,"feed successful")
				check(s.state.beasts.active.exp == (65 if soul else 50)+(0 if beast == "jade_fox" else 10*rank),"beast additive exact xp")
				var before := s.state.to_snapshot_dict()
				check(not send(s,"feed_beast").ok and before == s.state.to_snapshot_dict(),"cooldown atomic")
				if beast != "jade_fox":
					s.state.beasts.active.exp = 990
					s.state.beasts.active.stage = "growing"
					s.state.beasts.cooldown_remaining = 0.0
					check(send(s,"feed_beast").ok and s.state.beasts.active.stage == "mature","maturity threshold unchanged")
					before = s.state.to_snapshot_dict()
					check(not send(s,"feed_beast").ok and before == s.state.to_snapshot_dict(),"mature feed refused")
func _test_save() -> void:
	for version in [1,2]:
		for fault in ["archive","readback","slot"]:
			var s := fresh()
			s.state.talent_version = version
			s.state.talents = {"resource_inheritance":1}
			s.state.dao_heart = AmountCompat.from_number(25)
			var raw: String = SaveCodec.encode(s.state,content.content_version,META).json
			var mem := Memory.new()
			mem.data[SaveSlots.SLOT_MAIN] = raw
			SaveManager.configure(content,mem)
			var migrated := SaveManager.current_state()
			if migrated == null:
				check(false,"migration load failed "+SaveManager.load_error())
				return
			check(migrated.talent_version == 3 and migrated.talents == s.state.talents and migrated.dao_heart.to_float() == 25,"migration preserves meta")
			s.state = migrated
			check(SaveManager.migration_pending(migrated),"migration pending")
			var before := migrated.to_snapshot_dict()
			check(not send(s,"learn_talent",{"talent_id":TalentSystem.P2_IDS[0]}).ok and not s.advance_time(60).ok and not OfflineCoordinator.settle_state(migrated,content,61000,1000).ok and before == migrated.to_snapshot_dict(),"pending blocks commands and settlement")
			var key := "save_before_talents_"+raw.sha256_text()
			mem.fail = key if fault == "archive" else ("*" if fault == "slot" else "")
			mem.corrupt = key if fault == "readback" else ""
			check(not SaveManager.commit_supply_startup().ok and mem.data[SaveSlots.SLOT_MAIN] == raw,"migration fault preserves old main "+fault)
			mem.fail = ""
			mem.corrupt = ""
			if fault == "readback": mem.data.erase(key)
			check(SaveManager.commit_supply_startup().ok and mem.data[key] == raw and not SaveManager.migration_pending(migrated),"same candidate retry")
			check(send(s,"learn_talent",{"talent_id":TalentSystem.P2_IDS[0]}).ok,"purchase after migration")
			before = migrated.to_snapshot_dict()
			mem.fail = "*"
			check(not SaveManager.save(migrated,META).ok,"purchase save fails")
			mem.fail = ""
			check(SaveManager.save(migrated,META).ok and before == migrated.to_snapshot_dict(),"purchase only saves same candidate")
			SaveManager.configure(content,mem)
			var loaded := SaveManager.current_state()
			check(loaded.dao_heart.to_float() == 15 and loaded.talents["elixir_conservation_memory"] == 1,"reload single debit")
			SaveManager.reset_for_tests()
	# Import migration archives its own exact text, including whitespace.
	var old := fresh()
	old.state.talent_version = 2
	var raw: String = "  "+SaveCodec.encode(old.state,content.content_version,META).json+"\n"
	var mem := Memory.new()
	SaveManager.configure(content,mem)
	var imported := SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
	check(imported.ok and SaveManager.migration_pending(imported.state),"import tracked")
	check(SaveManager.save(imported.state,META).ok and mem.data["save_before_talents_"+raw.sha256_text()] == raw,"import exact archive")
	SaveManager.reset_for_tests()
	var good := fresh()
	good.state.talents["elixir_conservation_memory"] = 1
	var encoded := SaveCodec.encode(good.state,content.content_version,META)
	check(encoded.ok,"valid new save "+str(encoded.get("error"))+str(good.state.talents))
	if not encoded.ok: return
	var env: Dictionary = JSON.parse_string(encoded.json)
	for field in ["reincarnation_count","highest_era"]:
		var invalid := env.duplicate(true)
		invalid.state[field] = 0
		invalid.erase("checksum")
		invalid.checksum = SaveCodec.compute_checksum(invalid)
		check(not SaveCodec.decode(JSON.stringify(invalid)).ok,"decode contradictory "+field)
func _test_reincarnation() -> void:
	var s := fresh()
	s.state.era_id = 4
	s.state.total_elapsed_seconds = 999999
	s.state.talents = {"elixir_conservation_memory":1,"frontier_prospector_memory":2,"sacred_beast_nurture_memory":3}
	check(send(s,"reincarnate",{"mode":"normal"}).ok,"formal reincarnation")
	check(s.state.talents == {"elixir_conservation_memory":1,"frontier_prospector_memory":2,"sacred_beast_nurture_memory":3} and s.state.era_id == 1,"talents preserved")


