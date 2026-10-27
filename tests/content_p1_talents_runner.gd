extends SceneTree
const META := {"save_id":"p1-talent-test", "saved_at_utc_ms":"0", "settled_until_utc_ms":"0", "sim_tick":"0"}
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p1-talents/")
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
	if not ok: failures.append(label)
func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id":"talent-"+str(serial),"type":kind,"expected_revision":s.state.revision,"payload":payload})
func _init() -> void: run.call_deferred()
func run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(c).ok,"content attached")
	check(TalentSystem.TALENTS.size() == 9,"nine talents")
	for id in TalentSystem.P1_IDS:
		var s := GameSession.create_new_game(c)
		var before := s.state.to_snapshot_dict()
		check(not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),id+" unfunded atomic")
		s.state.dao_heart = AmountCompat.from_number(155)
		for level in range(5):
			check(TalentSystem.get_cost(id,level).to_float() == [5,10,20,40,80][level],id+" cost "+str(level))
			var balance := s.state.dao_heart.to_float()
			check(send(s,"learn_talent",{"talent_id":id}).ok and int(s.state.talents[id]) == level+1 and s.state.dao_heart.to_float() == balance-[5,10,20,40,80][level],id+" purchase "+str(level))
			var duplicate := s.submit({"command_id":"talent-"+str(serial),"type":"learn_talent","expected_revision":s.state.revision-1,"payload":{"talent_id":id}})
			check(duplicate.ok and duplicate.duplicate and int(s.state.talents[id]) == level+1,id+" duplicate")
		before = s.state.to_snapshot_dict()
		check(not send(s,"learn_talent",{"talent_id":id}).ok and before == s.state.to_snapshot_dict(),id+" max atomic")
		for value in [-1,6,0.5,"1",true,INF]: check(not TalentSystem.validate(2,{id:value}).is_empty(),id+" rejects malformed "+str(value))
		check(not TalentSystem.validate(1,{id:1}).is_empty(),id+" legacy version rejects")
		var encoded := SaveCodec.encode(s.state,c.content_version,META)
		check(encoded.ok and SaveCodec.decode(encoded.json).state.talents == s.state.talents,id+" roundtrip")
		s.state.era_id = 3
		s.state.total_elapsed_seconds = 999999
		check(send(s,"reincarnate",{"mode":"normal"}).ok and int(s.state.talents[id]) == 5,id+" rebirth preserves")
		check(s.state.buildings.is_empty() and s.state.skills.is_empty() and s.state.resources.lingli.value.sign == 0,id+" no unintended inheritance")
	# Pure per-building contribution, before skill and global multipliers; caps excluded.
	for level in range(6):
		for bid in c.building_ids:
			var buildings := {bid:2}
			var base := Production.compute_rates(c,buildings)
			var empty := Production.compute_rates(c,{})
			var boosted := Production.compute_rates(c,buildings,1.0,{}, {"artisan_past_wisdom":level})
			for resource in base:
				var factor := 1.0 + 0.08*level if bid in TalentSystem.ARTISAN_BUILDINGS else 1.0
				var expected: AmountCompat = empty[resource].add(base[resource].subtract(empty[resource]).multiply(AmountCompat.from_number(factor)))
				check(is_equal_approx(boosted[resource].to_float(),expected.to_float()),"contribution "+bid+" "+resource+" L"+str(level))
		var s := GameSession.create_new_game(c)
		s.state.talents = {"alchemical_past_wisdom":level,"beast_bond_past_wisdom":level}
		for pill in ["cultivation_pill","high_cultivation_pill"]:
			for count in [1,3]:
				s.state.training_seconds = 0
				s.state.pills[pill] = count
				s.state.pill_effects = {"stacks":{"high_cultivation_pill":2}}
				var k := AlchemySystem.stack_count(s.state,pill)
				var expected: float = 60.0*count if pill == "cultivation_pill" else 300.0*pow(0.85,k)*(1-pow(0.85,count))/(1-0.85)
				var res := AlchemySystem.consume(s.state,pill,count,100000)
				check(res.ok and is_equal_approx(s.state.training_seconds,expected*(1+0.1*level)),"pill decay/batch "+pill+str(level)+str(count))
				s.state.pills[pill] = 1
				s.state.training_seconds = 990
				check(AlchemySystem.consume(s.state,pill,1,1000).ok and s.state.training_seconds == 1000,"ceiling "+pill)
		for beast in BeastSystem.BEAST_CONFIGS:
			if not BeastSystem.BEAST_CONFIGS.has(beast): continue
			s.state.beasts = {"active":{"id":beast,"stage":"egg","exp":0},"cooldown_remaining":0.0}
			s.state.beast_talents = {}
			for resource in s.state.resources: s.state.resources[resource].value = AmountCompat.from_number(100000)
			for resource in BeastSystem.BEAST_CONFIGS[beast].feed_resource:
				if not s.state.resources.has(resource): s.state.resources[resource] = {"value":AmountCompat.from_number(100000),"unlocked":true,"ever_obtained":true}
			var res := BeastSystem.feed_beast(s.state)
			check(res.ok and s.state.beasts.active.exp == int(floor(50*(1+0.2*level))) if beast == "jade_fox" else s.state.beasts.active.exp == 50,"feed scope "+beast+str(level))
			var snapshot := s.state.to_snapshot_dict()
			check(not BeastSystem.feed_beast(s.state).ok and snapshot == s.state.to_snapshot_dict(),"cooldown preserved")
		s.state.beasts = {"active":{"id":"jade_fox","stage":"egg","exp":0},"cooldown_remaining":0.0}
		s.state.beast_talents = {"fox_t2_speed":1}
		check(BeastSystem.feed_beast(s.state).ok and s.state.beasts.active.exp == [65,75,85,95,105,115][level],"additive soul growth "+str(level))
		s.state.beasts = {"active":{"id":"jade_fox","stage":"growing","exp":990},"cooldown_remaining":0.0}
		check(BeastSystem.feed_beast(s.state).ok and s.state.beasts.active.stage == "mature","maturity threshold")
		var mature := s.state.to_snapshot_dict()
		check(not BeastSystem.feed_beast(s.state).ok and mature == s.state.to_snapshot_dict(),"mature atomic")
		var plain := GameSession.create_new_game(c).state
		var boosted := plain.duplicate_state()
		boosted.talents = {"alchemical_past_wisdom":level,"artisan_past_wisdom":level,"beast_bond_past_wisdom":level}
		for pill in ["lifespan_pill","foundation_pill"]:
			plain.pills[pill] = 1
			boosted.pills[pill] = 1
			AlchemySystem.consume(plain,pill)
			AlchemySystem.consume(boosted,pill)
		check(plain.pill_effects == boosted.pill_effects,"other pill effects unchanged")
		var before_caps: Dictionary = GameSession.create_new_game(c).get_view().resources
		var cap_session := GameSession.create_new_game(c)
		cap_session.state.talents = boosted.talents
		var after_caps: Dictionary = cap_session.get_view().resources
		for resource in before_caps: check(before_caps[resource].cap == after_caps[resource].cap,"capacity unchanged "+resource)
	var bad := GameSession.create_new_game(c)
	for version in [0,4]:
		bad.state.talent_version = version
		check(not SaveCodec.encode(bad.state,c.content_version,META).ok,"encode rejects version")
	bad.state.talent_version = 2
	for values in [{"unknown":1},{"alchemical_past_wisdom":6},{"innate_dao_body":11},{"lifespan_extension":true}]:
		bad.state.talents = values
		check(not SaveCodec.encode(bad.state,c.content_version,META).ok,"encode rejects malformed talents")
	# Online vs optimized offline with talent, skills, held-heart cost and economy.
	for duration in [1,61,600]:
		var s := GameSession.create_new_game(c)
		s.state.buildings = {"hut":2,"wooden_house":2,"forest_farm":2,"stone_mine":2,"herb_farm":2,"library":2}
		s.state.era_id = 3
		s.state.dao_heart = AmountCompat.from_number(20)
		s.state.talents.artisan_past_wisdom = 5
		s.state.skills.greenwood_nourishment = 3
		SkillSystem.sync_unlock(s.state)
		var slow := s.state.duplicate_state()
		var fast := s.state.duplicate_state()
		for i in duration: TimeAdvancer.advance(slow,c,1)
		OfflineSettlement.settle(fast,c,1000+duration*1000,1000)
		for resource in slow.resources: check(is_equal_approx(slow.resources[resource].value.to_float(),fast.resources[resource].value.to_float()),"offline "+resource+str(duration))
	# Old snapshot archive happens before any slot changes; retry saves the same candidate.
	var old := GameSession.create_new_game(c)
	old.state.talent_version = 1
	old.state.talents = {"resource_inheritance":1,"lifespan_extension":2,"innate_dao_body":1}
	var original: String = SaveCodec.encode(old.state,c.content_version,META).json
	var env: Dictionary = JSON.parse_string(original)
	env.state.erase("talent_version")
	env.erase("checksum")
	env.checksum = SaveCodec.compute_checksum(env)
	original = JSON.stringify(env)
	var mem := Memory.new()
	mem.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c,mem)
	var migrated := SaveManager.current_state()
	check(migrated.talent_version == 3 and migrated.talents == old.state.talents,"old three migrate intact")
	var archive := "save_before_talents_"+original.sha256_text()
	mem.fail = archive
	check(not SaveManager.save(migrated,META).ok and mem.data[SaveSlots.SLOT_MAIN] == original,"archive fail preserves slots")
	mem.fail = ""
	check(SaveManager.save(migrated,META).ok and mem.data[archive] == original,"archive readback retry")
	var s := GameSession.create_new_game(c)
	s.state.dao_heart = AmountCompat.from_number(20)
	check(send(s,"learn_talent",{"talent_id":"alchemical_past_wisdom"}).ok,"purchase before failure")
	mem.fail = "*"
	check(not SaveManager.save(s.state,META).ok,"slot failure")
	mem.fail = ""
	check(SaveManager.save(s.state,META).ok,"retry save")
	SaveManager.configure(c,mem)
	var reloaded := SaveManager.current_state()
	check(reloaded.dao_heart.to_float() == 15 and reloaded.talents.alchemical_past_wisdom == 1,"retry reload no duplicate cost")
	SaveManager.reset_for_tests()
	# Earn the browser's 20 hearts via the formal reincarnate command, from explicit Era3 fixture.
	var earned := GameSession.create_new_game(c)
	earned.state.era_id = 3
	earned.state.total_elapsed_seconds = 999999
	check(send(earned,"reincarnate",{"mode":"normal"}).ok and earned.state.dao_heart.to_float() == 20,"formal reward 20 hearts")
	var f := FileAccess.open(RunnerResult.output_path("res://src/verification/content_p1_talents_fixture.json"),FileAccess.WRITE)
	if f == null:
		push_error("write failed: res://src/verification/content_p1_talents_fixture.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(SaveCodec.encode(earned.state,c.content_version,META).json)
	f = FileAccess.open(DIR+"runner.json",FileAccess.WRITE)
	if f == null:
		push_error("write failed: " + DIR + "runner.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-TALENT ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
