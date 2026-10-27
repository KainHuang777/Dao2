extends "res://tests/content_p2_story_runner.gd"
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	var corrupt := ""
	var read_fail := ""
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary:
		if key == read_fail: return {"ok":false,"error":"injected_read"}
		return {"ok":true,"data":data[key]} if data.has(key) else {"ok":false,"error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if key == fail or fail == "*": return {"ok":false,"error":"injected_write"}
		data[key] = "damaged" if key == corrupt else value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key); return {"ok":true}
func encode(state: GameState) -> String:
	var result := SaveCodec.encode(state,content.content_version,META)
	check(result.ok,"encode fixture "+str(result.get("error")))
	return result.get("json", "")
func old_state(version: int, pending: String = "") -> GameState:
	var state := GameSession.create_new_game(content,123).state
	AchievementSystem.ensure_achievements_state(state)
	StoryProgress.ensure(state); FortuneSystem.ensure_initialized(state)
	state.story_version = version
	state.achievements.story.erase("p2"); state.achievements.story.version = version
	state.achievements.claimed.p1_greenwood_student = true; state.achievements.unlocked.p1_greenwood_student = 0
	state.achievements.story.lifetime.refined_mask = 1
	if version == 0:
		state.achievements = {}; state.fortune.erase("rng_version"); state.fortune.erase("rng_state")
	if not pending.is_empty():
		for def in FortuneSystem.get_encounters():
			if (pending == "p1" and def.get("content_batch") == "content-p1-story") or (pending == "legacy" and not def.has("content_batch")):
				var frozen: Dictionary = StorySaveContract.freeze(def,state) if pending == "p1" else def.duplicate(true)
				frozen.instance_id = "a".repeat(64)
				if pending == "p1":
					for key in frozen.qualifications: frozen.qualifications[key] = true
				state.fortune.pending_encounter = frozen
				break
	return state
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok,"attach")
	for version in [0,1]:
		for imported in [false,true]:
			for fault in ["archive_write","archive_read","archive_corrupt","slot_write","slot_corrupt","index","none"]:
				var old := old_state(version,"p1" if version == 1 else "legacy")
				var raw := " \n"+encode(old)+"\n"
				var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = raw
				SaveManager.configure(content,mem)
				var candidate: GameState
				if imported:
					var result := SaveManager.import_share_string(Marshalls.utf8_to_base64(raw))
					check(result.ok,"import accepted"); candidate = result.get("state")
				else: candidate = SaveManager.current_state()
				check(candidate != null,"load v"+str(version))
				if candidate == null: continue
				check(candidate.story_version == 2 and SaveManager.migration_error(candidate) == "STORY_SAVE_REQUIRED","candidate gated")
				check(StoryProgressP2.facts(candidate,true) == StoryProgressP2.blank(),"no historical P2 masks")
				check(candidate.fortune.pending_encounter == old.fortune.pending_encounter,"pending bytes/qualifications retained")
				if version == 1:
					check(candidate.achievements.claimed.p1_greenwood_student and candidate.achievements.story.lifetime.refined_mask == 1,"P1 facts/claim retained")
					check(candidate.fortune.rng_state == old.fortune.rng_state,"P1 RNG unchanged")
				else: check(candidate.fortune.has("rng_state"),"v0 RNG initialized")
				var before := candidate.to_snapshot_dict()
				check(not SaveManager.save(candidate.duplicate_state(),META).ok,"identity gate")
				check(not SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).ok and SaveManager.import_legacy_text("{}").get("error") == "MIGRATION_PENDING","second import gate")
				var s := GameSession.new(); s.content = content; s.state = candidate; s.clock = GameClock.create(0)
				check(not send(s,"trigger_fortune").ok and not s.advance_time(60).ok,"commands/online locked")
				check(not OfflineCoordinator.settle_state(candidate,content,61000,1000).ok and before == candidate.to_snapshot_dict(),"offline locked unchanged")
				var key := "save_before_story_"+raw.sha256_text()
				if fault == "archive_write": mem.fail = key
				elif fault == "archive_read": mem.read_fail = key
				elif fault == "archive_corrupt": mem.corrupt = key
				elif fault == "slot_write": mem.fail = SaveSlots.SLOT_MAIN if imported else SaveSlots.SLOT_BACKUP
				elif fault == "slot_corrupt": mem.corrupt = SaveSlots.SLOT_MAIN if imported else SaveSlots.SLOT_BACKUP
				elif fault == "index": mem.fail = SaveSlots.INDEX_KEY
				var saved := SaveManager.save(candidate,META)
				check(saved.ok == (fault == "none"), "fault "+fault)
				if fault != "none":
					check(SaveManager.migration_pending(candidate) and not SaveManager.save(candidate,META).ok,"repeat failure remains gated")
					check(before == candidate.to_snapshot_dict(),"fault no mutation")
					mem.fail = ""; mem.read_fail = ""; mem.corrupt = ""
					check(SaveManager.save(candidate,META).ok,"recover same candidate")
				check(mem.data.get(key) == raw and not SaveManager.migration_pending(candidate),"original archived and gate cleared")
				SaveManager.configure(content,mem)
				var recovered := SaveManager.current_state()
				check(recovered != null and recovered.story_version == 2 and recovered.fortune.pending_encounter == candidate.fortune.pending_encounter,"reload same candidate/pending")
				SaveManager.reset_for_tests()
	_validation()
	_resolution_retry()
	_concurrent()
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR+"save.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P2-STORY-SAVE ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
func _validation() -> void:
	var state := GameSession.create_new_game(content,123).state
	AchievementSystem.ensure_achievements_state(state)
	for key in StoryProgressP2.MASKS:
		for value in [-1, StoryProgressP2.MASKS[key]+1, true, 1.5, "1"]:
			var bad := state.duplicate_state(); bad.achievements.story.p2.current[key] = value
			check(not SaveCodec.encode(bad,content.content_version,META).ok,"invalid mask "+key+str(value))
		var bad := state.duplicate_state(); bad.achievements.story.p2.current[key] = 1
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"subset "+key)
	for fault in ["key", "future", "start_life", "start_age", "mask_key", "claim_type", "unlock_type", "unknown_id"]:
		var bad := state.duplicate_state()
		match fault:
			"key": bad.achievements.story.p2.foo = 1
			"future": bad.story_version = 3
			"start_life": bad.achievements.story.p2.started_life_id = 3
			"start_age": bad.achievements.story.p2.started_age_seconds = 1
			"mask_key": bad.achievements.story.p2.lifetime.foo = 0
			"claim_type": bad.achievements.claimed.p2_deep_student = 1
			"unlock_type": bad.achievements.unlocked.p2_deep_student = true
			"unknown_id": bad.achievements.claimed.p2_fake = true
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"reject "+fault)
	for version in [0,1]:
		var bad := old_state(version); bad.achievements.claimed = {"p2_deep_student":true}
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"old P2 claim")
		bad = old_state(version); bad.achievements.story = state.achievements.story.duplicate(true)
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"old P2 facts")
	var s := fresh()
	var definition: Dictionary
	for item in FortuneSystem.get_encounters():
		if item.id == "enc_p2_silver_scale": definition = item
	invite(s,definition)
	var pending: Dictionary = s.state.fortune.pending_encounter
	for fault in ["digest", "type", "id", "qualification", "origin", "batch", "version", "size"]:
		var bad := pending.duplicate(true)
		match fault:
			"digest": bad.definition_digest = "b".repeat(64)
			"type": bad.qualifications.deep_open = 1
			"id": bad.id = "enc_p2_unknown"
			"qualification": bad.qualifications.deep_open = false
			"origin": bad.generation_era = 3
			"batch": bad.content_batch = "content-p1-story"
			"version": bad.definition_version = 2
			"size": bad.desc = "文".repeat(5000)
		check(not StorySaveContract.validate_pending(bad).is_empty(),"P2 frozen rejects "+fault)
	for version in [0,1]:
		var bad := old_state(version); bad.fortune.pending_encounter = pending
		check(not SaveCodec.encode(bad,content.content_version,META).ok,"old version P2 pending")
	var oversized := state.duplicate_state(); oversized.achievements.story.p2.extra = "文".repeat(1400)
	check(StorySaveContract.validate(oversized) == "STORY_SIZE","story 4KiB UTF8 budget")
	oversized = state.duplicate_state(); oversized.achievements.stats.padding = "文".repeat(5500)
	check(StorySaveContract.validate(oversized) == "STORY_ACHIEVEMENTS_SIZE","achievements 16KiB UTF8 budget")
	for id in StoryProgressP2.BEASTS:
		var old := old_state(1); old.beasts = {"active":{"id":id,"stage":"mature","exp":1000},"cooldown_remaining":0}
		var original_rng: int = old.fortune.rng_state
		StoryProgress.migrate(old)
		check(StoryProgressP2.facts(old,true).mature_mask == 1 << StoryProgressP2.BEASTS.find(id) and old.fortune.rng_state == original_rng,"only current mature backfill "+id)
	var raw := encode(state)
	var env: Dictionary = JSON.parse_string(raw); env.state.achievements.story.p2.lifetime.market_mask = 3.0
	env.erase("checksum"); env.checksum = SaveCodec.compute_checksum(env)
	var normalized := SaveCodec.decode(JSON.stringify(env))
	check(normalized.ok and normalized.state.achievements.story.p2.lifetime.market_mask is int,"JSON integral mask normalized")
	for raw_bad in ["broken", raw.replace('"story_version":2','"story_version":3')]:
		var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = raw_bad; mem.data[SaveSlots.SLOT_BACKUP] = raw_bad
		SaveManager.configure(content,mem)
		check(SaveManager.current_state() == null and not SaveManager.save(state,META).ok and mem.data[SaveSlots.SLOT_MAIN] == raw_bad,"damaged/future slots protected")
		SaveManager.reset_for_tests()
func _resolution_retry() -> void:
	var s := fresh()
	var def: Dictionary
	for item in FortuneSystem.get_encounters():
		if item.id == "enc_p2_silver_scale": def = item
	invite(s,def); s.state.resources.stone_low.value = AmountCompat.from_number(80)
	check(send(s,"resolve_fortune",{"option_index":0}).ok,"resolution commits")
	var after := s.state.to_snapshot_dict()
	var mem := Memory.new(); SaveManager.configure(content,mem); mem.fail = "*"
	check(not SaveManager.save(s.state,META).ok and not SaveManager.save(s.state,META).ok and after == s.state.to_snapshot_dict(),"failed saves do not settle again")
	mem.fail = ""; check(SaveManager.save(s.state,META).ok,"resolution recovery")
	SaveManager.configure(content,mem)
	var loaded := SaveManager.current_state()
	check(loaded != null and loaded.fortune.pending_encounter.is_empty() and loaded.resources.refined_iron.value.to_float() == 3 and loaded.resources.stone_low.value.to_float() == 0,"reloaded exact settled amounts")
	SaveManager.reset_for_tests()

func _concurrent() -> void:
	for imported in [false,true]:
		var old := old_state(1); old.beast_version = 0; old.sect_version = 1; old.pill_version = 1; old.talent_version = 2
		var raw := "\n"+encode(old)+"\n"
		var mem := Memory.new(); mem.data[SaveSlots.SLOT_MAIN] = raw
		SaveManager.configure(content,mem)
		var candidate: GameState
		if imported: candidate = SaveManager.import_share_string(Marshalls.utf8_to_base64(raw)).get("state")
		else: candidate = SaveManager.current_state()
		check(candidate != null,"concurrent candidate")
		if candidate == null: continue
		mem.fail = SaveSlots.INDEX_KEY
		check(not SaveManager.save(candidate,META).ok and SaveManager.migration_pending(candidate),"concurrent failure gate")
		var before := candidate.to_snapshot_dict()
		mem.fail = ""
		check(SaveManager.save(candidate,META).ok and before == candidate.to_snapshot_dict(),"concurrent retry no reapply")
		for group in ["story","beasts","sect","pills","talents"]:
			check(mem.data.get("save_before_"+group+"_"+raw.sha256_text()) == raw,"same raw across upgrades "+group)
		SaveManager.reset_for_tests()
