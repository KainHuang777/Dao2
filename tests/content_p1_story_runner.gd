extends SceneTree
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p1-story/")
const META := {"save_id":"story-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var corrupt_read := ""
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary:
		if key == corrupt_read: return {"ok":true,"data":"corrupt"}
		return {"ok":true,"data":data[key]} if data.has(key) else {"ok":false,"error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if fail == "*" or key.begins_with(fail) and not fail.is_empty(): return {"ok":false,"error":"TEST_DENIED"}
		data[key] = value
		return {"ok":true}
var checks := 0
var failures := []
var serial := 0
var content: GameContent
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ", label)
func send(s: GameSession, type: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"type":type,"payload":payload,"command_id":"r-"+str(serial),"expected_revision":s.state.revision})
func fixture() -> GameSession:
	var s := GameSession.create_new_game(content, 123)
	s.state.era_id = 3
	s.state.reincarnation_count = 1
	StoryProgress.next_life(s.state)
	for id in s.state.resources:
		s.state.resources[id].value = AmountCompat.from_number(80)
	s.state.resources.foundation_pill.value = AmountCompat.zero()
	s.state.buildings = {"hut":2,"wooden_house":2,"forest_farm":3,"stone_mine":3,"herb_farm":3,"storage_lingli":3}
	s.state.skills = {"greenwood_nourishment":1,"warehouse_preparation":1,"alchemical_breath_control":1}
	for id in StoryProgress.TALENTS: s.state.talents[id] = 1
	SectSystem.ensure_sect_state(s.state)
	s.state.sect.unlocked = true
	s.state.sect.contribution = "0.5"
	s.state.sect.techniques = {"alchemy_herb_conservation":1,"fox_feed_conservation":1}
	s.state.beasts = {"active":{"id":"jade_fox","stage":"mature","exp":1000},"cooldown_remaining":0.0}
	s.state.beast_talents = {"fox_t1_boost":1}
	FortuneSystem.ensure_initialized(s.state)
	s.state.life_ledger = {}
	LifeLedger.initialize(s.state,true)
	return s
func invite(s: GameSession, def: Dictionary) -> void:
	var pending := StorySaveContract.freeze(def, s.state)
	pending.instance_id = ("story-fixture-"+str(serial)).sha256_text()
	s.state.fortune.pending_encounter = pending
func valid_old(raw: String) -> String:
	var env: Dictionary = JSON.parse_string(raw)
	env.state.erase("story_version")
	env.state.fortune.erase("rng_version")
	env.state.fortune.erase("rng_state")
	env.state.achievements.erase("story")
	for field in ["unlocked", "claimed"]:
		for id in env.state.achievements.get(field, {}).keys():
			if str(id).begins_with("p1_"): env.state.achievements[field].erase(id)
	env.erase("checksum")
	env.checksum = SaveCodec.compute_checksum(env)
	return JSON.stringify(env)
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(content).ok, "content attach")
	check(AchievementSystem.DEFINITIONS.size() == 48, "48 achievements including Y")
	check(FortuneSystem.get_encounters().size() == 56, "56 encounters including Y")
	var new_defs: Array = []
	for def in FortuneSystem.get_encounters():
		if def.get("content_batch") == "content-p1-story": new_defs.append(def)
	check(new_defs.size() == 12, "12 new encounters")
	for def in new_defs:
		var s := fixture()
		StoryProgress.mark(s.state,"timber_completed")
		StoryProgress.mark(s.state,"positive_home_arrival")
		StoryProgress.mark(s.state,"new_supply_claimed")
		StoryProgress.pill(s.state,"wood_nurture_pill",false)
		StoryProgress.pill(s.state,"wood_nurture_pill",true)
		StoryProgress.pill(s.state,"herb_nurture_pill",true)
		s.state.economy = IslandEconomy.initial()
		s.state.economy.islands.wood.opened = true
		check(StoryProgress.eligible(s.state,def),def.id+" all eligible")
		for realm in ["realm_spirit","realm_nether"]:
			s.state.current_realm = realm
			check(not StoryProgress.eligible(s.state,def),def.id+" other realm")
		s.state.current_realm = "realm_human"
		s.state.era_id = int(def.min_era)-1
		s.state.highest_era = 12
		check(not StoryProgress.eligible(s.state,def),def.id+" current era")
		# Each option goes through authoritative GameSession resolve, fixed effects/receipt, duplicate and no second execution.
		for index in 3:
			s = fixture()
			# eligibility fixture, frozen pending is validated separately from current membership.
			for key in StoryProgress.CURRENT: StoryProgress.mark(s.state,key)
			for id in AlchemySystem.P1_IDS:
				StoryProgress.pill(s.state,id,false); StoryProgress.pill(s.state,id,true)
			s.state.economy = IslandEconomy.initial(); s.state.economy.islands.wood.opened = true
			invite(s,def)
			s.state.economy = {} # No shipping cap, qualification is frozen.
			s.state.sect.unlocked = false
			s.state.beasts.active = {}
			var before := s.state.duplicate_state()
			var result := send(s,"resolve_fortune",{"option_index":index,"instance_id":s.state.fortune.pending_encounter.instance_id})
			check(result.ok,def.id+" option "+str(index))
			if not result.ok: continue
			var receipt: Dictionary = result.events[0].receipt
			check(receipt.option_index == index and s.state.fortune.pending_encounter.is_empty(),def.id+" receipt/pending")
			var option: Dictionary = def.options[index]
			for id in option.costs:
				check(receipt.resources[id].paid == str(int(option.costs[id])),def.id+" paid "+id)
			for id in option.rewards.get("resources", {}):
				check(receipt.resources[id].gained == str(int(option.rewards.resources[id])),def.id+" gained "+id)
			for id in option.rewards.get("pills", {}):
				check(int(s.state.pills[id]) == int(before.pills.get(id,0)) + int(option.rewards.pills[id]),def.id+" gifted pill")
			check(StoryProgress.facts(s.state) == StoryProgress.facts(before),def.id+" no false behavior facts")
			var again := send(s,"resolve_fortune",{"option_index":index})
			check(not again.ok,def.id+" consumed instance")
			var replay := s.submit({"type":"resolve_fortune","payload":{"option_index":(index+1)%3},"command_id":"r-"+str(serial-1),"expected_revision":0})
			check(replay.ok and replay.duplicate,def.id+" command replay")
		# Fixed paid failures must preserve complete state; free leave bypasses overflow.
		for mode in ["cost","capacity","precision","digest","stale"]:
			s = fixture()
			for key in StoryProgress.CURRENT: StoryProgress.mark(s.state,key)
			for id in AlchemySystem.P1_IDS:
				StoryProgress.pill(s.state,id,false); StoryProgress.pill(s.state,id,true)
			s.state.economy = IslandEconomy.initial(); s.state.economy.islands.wood.opened = true
			invite(s,def); s.state.economy = {}
			var option: Dictionary = def.options[0]
			if mode == "cost":
				for id in option.costs: s.state.resources[id].value = AmountCompat.zero()
			if mode == "precision":
				for id in option.costs: s.state.resources[id].value = AmountCompat.try_parse("1e100").value
			if mode == "capacity":
				for id in option.rewards.get("resources", {}): s.state.resources[id].value = StoryProgress.cap(s.state,content,id)
				for id in option.rewards.get("pills", {}): s.state.pills[id] = 999999
				if option.rewards.has("training_seconds"): continue
			if mode == "digest": s.state.fortune.pending_encounter.options[0].rewards.training_seconds = 999
			var snapshot := JSON.stringify(s.state.to_snapshot_dict())
			var result := send(s,"resolve_fortune",{"option_index":0,"instance_id":"stale" if mode == "stale" else s.state.fortune.pending_encounter.instance_id})
			check(not result.ok,def.id+" reject "+mode)
			check(snapshot == JSON.stringify(s.state.to_snapshot_dict()),def.id+" atomic "+mode)

	# Every generated qualification has an independent negative witness.
	var s: GameSession
	for def in new_defs:
		for key in def.requires:
			s = fixture()
			for flag in StoryProgress.CURRENT: StoryProgress.mark(s.state,flag)
			for pill_id in AlchemySystem.P1_IDS:
				StoryProgress.pill(s.state,pill_id,false); StoryProgress.pill(s.state,pill_id,true)
			s.state.economy = IslandEconomy.initial(); s.state.economy.islands.wood.opened = true
			match key:
				"wood_open": s.state.economy.islands.wood.opened = false
				"timber_completed", "positive_home_arrival", "new_supply_claimed": s.state.achievements.story.current[key] = false
				"joined_sect": s.state.sect.unlocked = false
				"refined_any_p1": s.state.achievements.story.current.refined_mask = 0
				"two_p1_consumed": s.state.achievements.story.current.consumed_mask = 1
				"active_fox": s.state.beasts.active.id = "black_tortoise"
				"mature_active_fox": s.state.beasts.active.stage = "growing"
				"second_life": s.state.reincarnation_count = 0
				"any_new_talent": s.state.talents = {}
			check(not StoryProgress.eligible(s.state,def),def.id+" missing "+key)
	# Injected RNG test: same seed replays, and all 12 eligible new definitions can be selected.
	var seen := {}
	var first_sequence := []
	for pass_index in 2:
		s = fixture()
		for flag in StoryProgress.CURRENT: StoryProgress.mark(s.state,flag)
		for pill_id in AlchemySystem.P1_IDS:
			StoryProgress.pill(s.state,pill_id,false); StoryProgress.pill(s.state,pill_id,true)
		s.state.economy = IslandEconomy.initial(); s.state.economy.islands.wood.opened = true
		var rng := SeededRandom.from_seed(20261023)
		for draw in 1024:
			s.state.fortune.pending_encounter = {}
			var chosen := FortuneSystem.trigger_fortune(s.state,rng)
			if pass_index == 0: first_sequence.append(chosen.id); seen[chosen.id] = true
			else: check(chosen.id == first_sequence[draw],"seeded replay "+str(draw))
			if chosen.get("content_batch") == "content-p1-story": check(StorySaveContract.validate_pending(chosen).is_empty(),"generated digest/eligibility")
	for def in new_defs: check(seen.has(def.id),def.id+" selected with injected RNG")

	# Real default stream: seed replay survives save/reload; pending and read-only view consume no draws.
	s = fixture()
	var replay_state := s.state.duplicate_state()
	var rng_seen := {}
	for draw in 128:
		s.state.fortune.pending_encounter = {}
		replay_state.fortune.pending_encounter = {}
		var old_seed := s.state.tribulation_seed
		var old_roll := s.state.tribulation_roll_index
		var actual := FortuneSystem.trigger_fortune(s.state)
		var expected := FortuneSystem.trigger_fortune(replay_state)
		check(actual.id == expected.id and s.state.fortune.rng_state == replay_state.fortune.rng_state,"default RNG replay "+str(draw))
		rng_seen[actual.id] = true
		check(s.state.tribulation_seed == old_seed and s.state.tribulation_roll_index == old_roll,"tribulation RNG untouched")
		var rng_before: int = s.state.fortune.rng_state
		s.get_view(); FortuneSystem.trigger_fortune(s.state)
		check(s.state.fortune.rng_state == rng_before,"pending/view no draw")
		var encoded_rng := SaveCodec.encode(s.state,content.content_version,META)
		check(encoded_rng.ok,"RNG snapshot")
		if encoded_rng.ok: replay_state = SaveCodec.decode(encoded_rng.json).state
	check(rng_seen.size()>1,"default RNG no fixed-first fallback")
	# Actual success hooks for study, sect, beast and talents.
	s = fixture(); s.state.skills = {}; s.state.buildings.library = 1
	SkillSystem.sync_unlock(s.state)
	for skill in ["greenwood_nourishment","warehouse_preparation","alchemical_breath_control"]:
		s.state.resources.skill_point.value = AmountCompat.from_number(float(content.skill_defs[skill].cost))
		check(send(s,"learn_skill",{"skill_id":skill}).ok,"official study "+skill)
	check(s.state.achievements.unlocked.has("p1_greenwood_student") and s.state.achievements.unlocked.has("p1_golden_specialist"),"study commits unlock both")
	s = fixture(); s.state.sect.techniques = {}; s.state.sect.contribution = "1000"
	s.state.resources.wood.value = AmountCompat.from_number(200)
	for technique in ["alchemy_herb_conservation","fox_feed_conservation"]: check(send(s,"learn_sect_technique",{"technique_id":technique}).ok,"official technique "+technique)
	check(s.state.achievements.unlocked.has("p1_two_sect_specialties"),"both techniques unlock")
	s = fixture(); s.state.beast_talents = {}; s.state.beast_souls = {"jade_fox":1}
	check(not StoryProgress.achievement_met(s.state,"p1_fox_soul_choice"),"soul inventory insufficient")
	check(send(s,"unlock_beast_talent",{"talent_id":"fox_t1_boost"}).ok,"official soul talent")
	check(s.state.achievements.unlocked.has("p1_fox_soul_choice"),"soul talent unlock")
	s = fixture(); s.state.talents = {}; s.state.dao_heart = AmountCompat.from_number(15)
	for talent in StoryProgress.TALENTS: check(send(s,"learn_talent",{"talent_id":talent}).ok,"official past wisdom "+talent)
	check(s.state.achievements.unlocked.has("p1_three_past_wisdoms") and s.state.dao_heart.sign == 0,"three wisdoms cost15 unlock")
	s = fixture(); s.state.beasts.active = {"id":"jade_fox","stage":"growing","exp":999}
	check(not StoryProgress.achievement_met(s.state,"p1_mature_jade_fox"),"growing fox insufficient")
	check(send(s,"feed_beast").ok,"official final fox feed")
	check(StoryProgress.facts(s.state,true).fox_matured and s.state.achievements.unlocked.has("p1_mature_jade_fox"),"actual maturation unlock")
	# Atomically claim after capacity and Amount checks, including inherited over-cap holdings.
	for id in AchievementSystem.P1_DEFINITIONS:
		s = fixture()
		for key in StoryProgress.LIFETIME: StoryProgress.mark(s.state,key)
		for pill_id in AlchemySystem.P1_IDS:
			StoryProgress.pill(s.state,pill_id,false); StoryProgress.pill(s.state,pill_id,true)
		AchievementSystem.check_achievements(s.state,content)
		var reward: Dictionary = AchievementSystem.P1_DEFINITIONS[id].rewards
		if reward.has("resource"):
			for resource in reward.resource: s.state.resources[resource].value = StoryProgress.cap(s.state,content,resource)
		else: s.state.sect.contribution = "1e100"
		var old := JSON.stringify(s.state.to_snapshot_dict())
		check(not send(s,"claim_achievement",{"achievement_id":id}).ok,id+" full/precision rejects")
		check(old == JSON.stringify(s.state.to_snapshot_dict()),id+" failed claim atomic")

	# Full inventory cannot trap the free option.
	s = fixture()
	invite(s,new_defs[0])
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.from_number(100000)
	check(send(s,"resolve_fortune",{"option_index":2}).ok,"free leave while over cap")
	# Behavior flags from successful gameplay entry points only.
	s = fixture()
	s.state.beasts.active = {}
	s.state.skills = {}
	s.state.resources.lingli.value = AmountCompat.from_number(1000)
	for id in AlchemySystem.P1_IDS:
		check(send(s,"refine_pill",{"pill_id":id,"count":1}).ok,"formal refine "+id)
		check(send(s,"consume_pill",{"pill_id":id,"count":1}).ok,"formal consume "+id)
		var old_mask: int = StoryProgress.facts(s.state).consumed_mask
		check(not send(s,"consume_pill",{"pill_id":id,"count":1}).ok,"rejected empty/no extension "+id)
		check(old_mask == StoryProgress.facts(s.state).consumed_mask,"rejected consume unchanged")
	check(StoryProgress.facts(s.state,true).refined_mask == 15 and StoryProgress.facts(s.state,true).consumed_mask == 15,"four pill masks")
	StoryProgress.completed(s.state,"wood","spirit_timber")
	StoryProgress.arrived(s.state,"timber_home",1)
	StoryProgress.arrived(s.state,"bronze_home",0)
	check(not StoryProgress.achievement_met(s.state,"p1_homebound_cargo"),"empty bronze insufficient")
	s.state.reincarnation_count += 1
	StoryProgress.next_life(s.state)
	StoryProgress.arrived(s.state,"bronze_home",1)
	check(StoryProgress.achievement_met(s.state,"p1_homebound_cargo"),"cargo spans lives")
	check(StoryProgress.facts(s.state).refined_mask == 0 and StoryProgress.facts(s.state,true).refined_mask == 15,"current resets lifetime retained")
	# Claim all twelve with resource/contribution deltas, duplicate rejection.
	s = fixture()
	for key in StoryProgress.LIFETIME: StoryProgress.mark(s.state,key)
	for id in AlchemySystem.P1_IDS:
		StoryProgress.pill(s.state,id,false); StoryProgress.pill(s.state,id,true)
	AchievementSystem.check_achievements(s.state,content)
	for id in AchievementSystem.P1_DEFINITIONS:
		check(s.state.achievements.unlocked.has(id),id+" unlocked")
		for res in s.state.resources: s.state.resources[res].value = AmountCompat.zero()
		var result := send(s,"claim_achievement",{"achievement_id":id})
		check(result.ok,id+" claim")
		check(not send(s,"claim_achievement",{"achievement_id":id}).ok,id+" no second claim")
	check(s.state.sect.contribution == "65.5","fractional contribution retained")
	# Malformed snapshot/definitions; digest checking rejects injected frozen effects.
	var encoded := SaveCodec.encode(s.state,content.content_version,META)
	check(encoded.ok,"v1 encode "+str(encoded.get("error", "")))
	if encoded.ok:
		check(SaveCodec.decode(encoded.json).ok,"v1 roundtrip")
		var old := valid_old(encoded.json)
		check(SaveCodec.decode(old).ok,"v0 decodes")
		for fault in ["archive_write","archive_readback","slots", "none"]:
			var memory := Memory.new(); memory.data[SaveSlots.SLOT_MAIN] = old
			SaveManager.configure(content,memory)
			var loaded := SaveManager.current_state()
			check(loaded != null and loaded.story_version == StoryProgress.VERSION,"migrate "+fault)
			if loaded == null: continue
			check(StoryProgress.facts(loaded,true).refined_mask == 0 and not StoryProgress.facts(loaded,true).timber_completed,"no historical action fabrication")
			var key := "save_before_story_"+old.sha256_text()
			if fault == "archive_write": memory.fail = "save_before_story_"
			if fault == "archive_readback": memory.corrupt_read = key
			if fault == "slots": memory.fail = SaveSlots.SLOT_BACKUP
			var saved := SaveManager.save(loaded,META)
			check(saved.ok == (fault == "none"),"migration failure "+fault)
			if not saved.ok:
				check(memory.data[SaveSlots.SLOT_MAIN] == old,"old slot preserved "+fault)
				memory.fail = ""; memory.corrupt_read = ""
				check(SaveManager.save(loaded,META).ok,"retry migration "+fault)
			check(memory.data.get(key) == old,"original bytes archived")
		for value in [-1,3,"1",true]:
			var env: Dictionary = JSON.parse_string(encoded.json)
			env.state.story_version = value; env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
			check(not SaveCodec.decode(JSON.stringify(env)).ok,"invalid story version "+str(value))
		for value in [-1,16,1.5,"1",true]:
			var env: Dictionary = JSON.parse_string(encoded.json)
			env.state.achievements.story.current.refined_mask = value; env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
			check(not SaveCodec.decode(JSON.stringify(env)).ok,"invalid mask "+str(value))
	var bad: Dictionary = new_defs[0].duplicate(true); bad.requires.append("arbitrary_script")
	check(not StorySaveContract.definition_error(bad).is_empty(),"requires whitelist")

	# Bound/version/future RNG snapshots and frozen definition metadata reject without repair.
	s = fixture()
	for key in ["rng_version", "rng_state"]:
		for value in [-1,"1",true,4294967296]:
			var bad_state := s.state.duplicate_state()
			bad_state.fortune[key] = value
			check(not SaveCodec.encode(bad_state,content.content_version,META).ok,"reject RNG "+key+str(value))
	var bad_state := s.state.duplicate_state()
	bad_state.achievements.story.current.unapproved = true
	check(not SaveCodec.encode(bad_state,content.content_version,META).ok,"unknown fact rejected")
	bad_state = s.state.duplicate_state(); bad_state.achievements.story.current_life_id = 99
	check(not SaveCodec.encode(bad_state,content.content_version,META).ok,"wrong life rejected")
	bad_state = s.state.duplicate_state(); bad_state.achievements.story.started_age_seconds = INF
	check(not SaveCodec.encode(bad_state,content.content_version,META).ok,"nonfinite start rejected")
	var old_pending: Dictionary = FortuneSystem.get_encounters()[0].duplicate(true)
	bad_state = s.state.duplicate_state(); bad_state.fortune.pending_encounter = old_pending
	var old_pending_encoded := SaveCodec.encode(bad_state,content.content_version,META)
	check(old_pending_encoded.ok and SaveCodec.decode(old_pending_encoded.json).state.fortune.pending_encounter == old_pending,"legacy pending payload retained exactly")
	var decoded_pending := StorySaveContract.freeze(new_defs[0],s.state)
	decoded_pending.instance_id = "a".repeat(64)
	bad_state = s.state.duplicate_state(); bad_state.fortune.pending_encounter = decoded_pending
	var pending_encoded := SaveCodec.encode(bad_state,content.content_version,META)
	check(pending_encoded.ok and SaveCodec.decode(pending_encoded.json).state.fortune.pending_encounter == decoded_pending,"new frozen pending exact roundtrip")
	for change in ["digest","version","qualification","keys","size"]:
		var altered := decoded_pending.duplicate(true)
		match change:
			"digest": altered.definition_digest = "b".repeat(64)
			"version": altered.definition_version = 2
			"qualification": altered.qualifications.script = true
			"keys": altered.injected = "unknown"
			"size": altered.desc = "x".repeat(13000)
		check(not StorySaveContract.validate_pending(altered).is_empty(),"reject pending "+change)
	# Fixture only for desktop mouse acceptance, not natural generation evidence.
	s = fixture()
	for key in StoryProgress.LIFETIME: StoryProgress.mark(s.state,key)
	for id in AlchemySystem.P1_IDS:
		StoryProgress.pill(s.state,id,false); StoryProgress.pill(s.state,id,true)
	AchievementSystem.check_achievements(s.state,content)
	for id in s.state.resources: s.state.resources[id].value = AmountCompat.zero()
	var ui_encoded := SaveCodec.encode(s.state,content.content_version,META)
	if ui_encoded.ok:
		var write_file_story_fixture := FileAccess.open(RunnerResult.output_path("res://src/verification/content_p1_story_fixture.json"),FileAccess.WRITE)
		if write_file_story_fixture == null:
			push_error("write failed: " + str("res://src/verification/content_p1_story_fixture.json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_story_fixture.store_string(ui_encoded.json)
	var write_file_rules := FileAccess.open(DIR+"rules.json",FileAccess.WRITE)
	if write_file_rules == null:
		push_error("write failed: " + str(DIR+"rules.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_rules.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-STORY ",checks," checks failures=",failures)
	SaveManager.reset_for_tests()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)



