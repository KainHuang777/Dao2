extends SceneTree
const META := {"save_id":"content-p1-skills-isolated", "saved_at_utc_ms":"0", "settled_until_utc_ms":"0", "sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
var serial := 0
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key,""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if fail == "*" or fail == key: return {"ok":false, "error":"injected"}
		data[key] = value
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"content-p1-"+str(serial), "type":kind, "expected_revision":s.state.revision, "payload":payload})
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(c).ok and c.skill_defs.size() == 24, "24 definitions")
	var base := GameSession.create_new_game(c)
	for id in SkillSystem.P1_LIMITS:
		var s := GameSession.create_new_game(c)
		var snapshot := s.state.to_snapshot_dict()
		check(not send(s,"learn_skill",{"skill_id":id}).ok and snapshot == s.state.to_snapshot_dict(), id+" study lock atomic")
		s.state.era_id = 2
		s.state.buildings.library = 1
		SkillSystem.sync_unlock(s.state)
		snapshot = s.state.to_snapshot_dict()
		check(not send(s,"learn_skill",{"skill_id":id}).ok and snapshot == s.state.to_snapshot_dict(), id+" points/era lock atomic")
		if int(c.skill_defs[id].era) == 3:
			s.state.resources.skill_point.value = AmountCompat.from_number(6000)
			snapshot = s.state.to_snapshot_dict()
			check(not send(s,"learn_skill",{"skill_id":id}).ok and snapshot == s.state.to_snapshot_dict(),id+" Era2 rejects funded")
		s.state.era_id = 3
		for level in range(1,4):
			s.state.resources.skill_point.value = AmountCompat.from_number(c.skill_defs[id].cost)
			var learned := send(s,"learn_skill",{"skill_id":id})
			check(learned.ok and s.state.skills[id] == level and s.state.resources.skill_point.value.sign == 0,id+" exact cost level "+str(level))
			var again := s.submit({"command_id":"content-p1-"+str(serial),"type":"learn_skill","payload":{"skill_id":id},"expected_revision":s.state.revision-1})
			check(again.ok and again.duplicate and s.state.skills[id] == level,id+" duplicate level "+str(level))
		snapshot = s.state.to_snapshot_dict()
		check(not send(s,"learn_skill",{"skill_id":id}).ok and snapshot == s.state.to_snapshot_dict(), id+" max atomic")
		for value in [-1,4,0.5,"1",true,INF]:
			check(not SkillSystem.validate(3,{id:value}).is_empty(),id+" invalid "+str(value))
		for version in [0,1,2,5]:
			check(not SkillSystem.validate(version,{id:1}).is_empty(),id+" rejects incompatible version "+str(version))
		check(SkillSystem.validate(3,{id:3}).is_empty(),id+" v3 valid")
		base.state.skills[id] = 3
	# Independent reference formulas and unaffected resources/buildings.
	var buildings := {"forest_farm":2,"stone_mine":2,"herb_farm":2,"library":2,"wooden_house":2,"hut":2}
	var rates := Production.compute_rates(c,buildings)
	for level in range(4):
		var skills := {"greenwood_nourishment":level,"ore_breath_refinement":level,"herbal_spirit_nurture":level,"warehouse_preparation":level}
		var boosted := Production.compute_rates(c,buildings,1.0,skills)
		for id in rates:
			var expected: AmountCompat = rates[id].multiply(AmountCompat.from_number(pow(1.1,level))) if id in SkillSystem.MATERIALS else rates[id]
			check(boosted[id].compare_to(expected) == 0,"rate boundary "+id+" L"+str(level))
		var caps := Production.compute_caps(c,{},3,1,skills)
		var old_caps := Production.compute_caps(c,{},3,1)
		for id in caps:
			var extra := 200*level if id in SkillSystem.MATERIALS else 0
			check(caps[id].compare_to(old_caps[id].add(AmountCompat.from_number(extra))) == 0,"cap boundary "+id+" L"+str(level))
	# Natural point production with no sect, bounded waits and repeated spending.
	var natural := GameSession.create_new_game(c)
	natural.state.era_id = 2 # Explicit Era fixture; not a natural Era1->3 claim.
	natural.state.buildings.library = 1
	SkillSystem.sync_unlock(natural.state)
	for id in ["greenwood_nourishment","ore_breath_refinement","herbal_spirit_nurture"]:
		var waited := 0
		while natural.state.resources.skill_point.value.to_float() < 120 and waited < 120:
			natural.advance_time(1)
			waited += 1
		check(waited <= 60 and send(natural,"learn_skill",{"skill_id":id}).ok,"produced points fund "+id)
	# Discount's Amount values, view, actual stock and unchanged pill ingredients.
	var a := GameSession.create_new_game(c)
	a.state.era_id = 3
	for level in range(4):
		a.state.skills.alchemical_breath_control = level
		for id in AlchemySystem.PILLS:
			var cost := AlchemySystem.refinement_cost(a.state,id)
			for resource in AlchemySystem.PILLS[id].cost:
				var expected := float(AlchemySystem.PILLS[id].cost[resource])
				if resource == "lingli" and id in AlchemySystem.LINGLI_DISCOUNT_PILLS: expected *= 1.0-0.05*level
				check(is_equal_approx(float(cost[resource]) if cost[resource] is int else cost[resource].to_float(),expected),"discount scope "+id+" "+resource+" L"+str(level))
		var unit := 50.0*(1.0-0.05*level)
		a.state.resources.lingli.value = AmountCompat.from_number(unit*3)
		a.state.resources.spirit_grass_low.value = AmountCompat.from_number(30)
		check(AlchemySystem.can_refine(a.state,"cultivation_pill",3).can_refine,"batch affordable L"+str(level))
		var view: Array = AlchemySystem.get_view(a.state).pills
		check(is_equal_approx(float(view[0].cost.lingli),unit),"view exact unit L"+str(level))
		check(send(a,"refine_pill",{"pill_id":"cultivation_pill","count":3}).ok and absf(a.state.resources.lingli.value.to_float()) < 1e-9 and a.state.resources.spirit_grass_low.value.sign == 0,"batch payment L"+str(level))
		a.state.resources.lingli.value = AmountCompat.from_number(unit-0.1)
		a.state.resources.spirit_grass_low.value = AmountCompat.from_number(10)
		var before := a.state.to_snapshot_dict()
		check(not send(a,"refine_pill",{"pill_id":"cultivation_pill","count":1}).ok and before == a.state.to_snapshot_dict(),"fractional insufficient atomic")
	# All 24 IDs survive; v2 cannot smuggle v3 ID, future version rejected.
	for id in c.skill_defs:
		if not base.state.skills.has(id): base.state.skills[id] = 1
	# Reference one-second ticks vs the shipping closed-form/economy-jump path.
	for with_economy in [false,true]:
		for duration in [1,60,600]:
			var fixture := GameSession.create_new_game(c)
			fixture.state.era_id = 3
			fixture.state.buildings.merge(buildings,true)
			fixture.state.skills = base.state.skills.duplicate()
			SkillSystem.sync_unlock(fixture.state)
			if with_economy:
				check(send(fixture,"activate_islands",{}).ok,"offline economy activate")
			var reference := fixture.state.duplicate_state()
			var optimized := fixture.state.duplicate_state()
			for i in duration: TimeAdvancer.advance(reference,c,1)
			OfflineSettlement.settle(optimized,c,1000+duration*1000,1000)
			for id in reference.resources:
				check(reference.resources[id].value.compare_to(optimized.resources[id].value) == 0,"offline stock "+id+" "+str(with_economy)+" "+str(duration))
			check(reference.economy == optimized.economy,"offline island scope "+str(duration))
			check(reference.abode_scenery == optimized.abode_scenery,"offline RNG "+str(duration))
			check(ResourceLedger.equivalent(reference.life_ledger.current.get("accounts",{}),optimized.life_ledger.current.get("accounts",{})),"offline actual ledger "+str(duration))
	var encoded := SaveCodec.encode(base.state,c.content_version,META)
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok and decoded.state.skills == base.state.skills and decoded.state.skill_version == 4,"24 ID roundtrip")
	for bad in [2,5]:
		var raw: Dictionary = JSON.parse_string(encoded.json)
		raw.state.skill_version = bad
		raw.checksum = SaveCodec.compute_checksum(raw)
		check(not SaveCodec.decode(JSON.stringify(raw)).ok,"decode version rejects "+str(bad))
	var old := GameSession.create_new_game(c)
	old.state.skill_version = 2
	old.state.skills = {"basic_meditation":2,"golden_core_formation":1}
	var original: String = SaveCodec.encode(old.state,c.content_version,META).json
	var mem := Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c,mem)
	var migrated := SaveManager.current_state()
	check(migrated.skill_version == 4 and migrated.skills == old.state.skills,"v2 migration preserves only earned skills")
	var archive := "save_before_skills_"+original.sha256_text()
	mem.fail = archive
	check(not SaveManager.save(migrated,META).ok and mem.data[SaveSlots.SLOT_MAIN] == original,"archive refusal preserves original")
	mem.fail = ""
	check(SaveManager.save(migrated,META).ok and mem.data[archive] == original,"verified archive and retry")
	SaveManager.configure(c,mem)
	check(SaveManager.current_state().skills == old.state.skills,"migration reload no free skills")
	base.state.revision = migrated.revision + 1
	mem.fail = "*"
	check(not SaveManager.save(base.state,META).ok,"save fails without replay")
	mem.fail = ""
	check(SaveManager.save(base.state,META).ok,"retry saves existing state")
	SaveManager.configure(c,mem)
	check(SaveManager.current_state().skills == base.state.skills,"all learned survive retry reload")
	SaveManager.reset_for_tests()
	base.state.era_id = 3
	base.state.level = 10
	base.state.buildings.rebirth_lotus = 1
	check(send(base,"reincarnate",{"mode":"normal"}).ok and base.state.skills.is_empty(),"reincarnation clears all new skills")
	print("CONTENT-P1-SKILL ",checks," checks; failures=",JSON.stringify(failures))
	var report := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/content-p1-skills/runner.json"),FileAccess.WRITE)
	if report != null: report.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
