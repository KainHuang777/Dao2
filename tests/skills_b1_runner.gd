extends SceneTree
var failures: Array[String] = []
var checks := 0
var serial := 0
class Memory extends StorageAdapter:
	var data := {}
	var fail := ""
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if key == fail: return {"ok": false, "error": "injected"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool: return data.has(key)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func send(s: GameSession, kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return s.submit({"command_id": "b1-" + str(serial), "type": kind, "expected_revision": s.state.revision, "payload": payload})
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	var old := GameSession.create_new_game(c)
	var meta := {"save_id": "skills-test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
	var encoded := SaveCodec.encode(old.state, c.content_version, meta)
	var raw: Dictionary = JSON.parse_string(encoded.json)
	raw.state.erase("skills")
	raw.state.erase("skill_version")
	raw.erase("checksum")
	raw.checksum = SaveCodec.compute_checksum(raw)
	var original := JSON.stringify(raw)
	var attached := IslandProgression.attach(c)
	if not attached.ok:
		quit(1)
		return
	check(attached.ok, "attach skill content")
	var version := c.content_version
	check(IslandProgression.attach(c).ok and c.content_version == version, "idempotent content attachment")
	var s := GameSession.create_new_game(c)
	check(s.state.skill_version == 1 and s.get_view().skills.items.size() == 6, "new state and six skill view")
	var before := s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "basic_meditation"}).ok and s.state.to_snapshot_dict() == before, "atomic locked refusal")
	s.state.era_id = 2
	for id in ["money", "wood", "stone_low", "spirit_grass_low", "black_copper"]:
		s.state.resources[id].value = AmountCompat.from_number(10000)
		s.state.resources[id].unlocked = true
	check(send(s, "upgrade_building", {"building_id": "library"}).ok and s.state.resources.skill_point.unlocked, "paid library unlocks production")
	s.advance_time(100)
	check(s.state.resources.skill_point.value.to_float() == 200, "Era2 library produces points capped at 200")
	for id in ["money", "wood", "stone_low", "black_copper"]:
		s.state.resources[id].value = AmountCompat.from_number(10000)
	check(send(s, "upgrade_building", {"building_id": "scripture_hall"}).ok, "paid scripture hall")
	check(Production.compute_caps(c, s.state.buildings, 2, 1).skill_point.to_float() == 6200, "scripture capacity")
	s.advance_time(3000)
	check(s.state.resources.skill_point.value.to_float() == 6200, "points capped at enlarged capacity")
	for id in c.skill_defs:
		s.state.resources.skill_point.value = AmountCompat.from_number(6200)
		var cost := float(c.skill_defs[id].cost)
		var result := send(s, "learn_skill", {"skill_id": id})
		check(result.ok and s.state.skills[id] == 1 and is_equal_approx(s.state.resources.skill_point.value.to_float(), 6200-cost), "paid learn " + id)
		var duplicate := s.submit({"command_id": "b1-" + str(serial), "type": "learn_skill", "expected_revision": s.state.revision-1, "payload": {"skill_id": id}})
		check(duplicate.ok and duplicate.duplicate and s.state.skills[id] == 1, "idempotent " + id)
	var plain := Production.compute_rates(c, s.state.buildings, 2)
	var boosted := Production.compute_rates(c, s.state.buildings, 2, s.state.skills)
	check(is_equal_approx(boosted.lingli.to_float(), (plain.lingli.to_float()+4)*1.1), "lingli additive and multiplier")
	check(is_equal_approx(boosted.money.to_float(), plain.money.to_float()*1.2), "money multiplier")
	var caps := Production.compute_caps(c, s.state.buildings, 2, 1, s.state.skills)
	var base := Production.compute_caps(c, s.state.buildings, 2, 1)
	check(caps.lingli.to_float() == base.lingli.to_float()+200 and caps.money.to_float() == base.money.to_float()+2000, "capacity effects")
	check(CommandProcessor.level_cap(c.buildings.wooden_house, c, s.state) == 20, "production mastery")
	check(CommandProcessor.level_cap(c.buildings.storage_lingli, c, s.state) == 10 and CommandProcessor.level_cap(c.buildings.foundation_reservoir, c, s.state) == 3, "storage pathway preserved")
	before = s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "qi_storage_1"}).ok and s.state.to_snapshot_dict() == before, "max skill refusal")
	s.state.resources.skill_point.value = AmountCompat.zero()
	before = s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "basic_meditation"}).ok and s.state.to_snapshot_dict() == before, "insufficient points atomic")
	var a := GameSession.create_new_game(c)
	a.state = s.state.duplicate_state()
	var b := GameSession.create_new_game(c)
	b.state = s.state.duplicate_state()
	a.advance_time(60)
	for i in 60: b.advance_time(1)
	a.state.revision = b.state.revision
	check(a.state.to_snapshot_dict() == b.state.to_snapshot_dict(), "tick partitions")
	var roundtrip := SaveCodec.decode(SaveCodec.encode(s.state, c.content_version, meta).json)
	check(roundtrip.ok and roundtrip.state.skills == s.state.skills, "save skill roundtrip")
	s.state.skills.unknown = 1
	check(not SaveCodec.encode(s.state, c.content_version, meta).ok, "reject unknown skill")
	s.state.skills.erase("unknown")
	var memory := Memory.new()
	memory.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c, memory)
	var migrated := SaveManager.current_state()
	check(migrated != null and migrated.skill_version == 1 and migrated.skills.is_empty() and migrated.revision == old.state.revision+1, "old save migration")
	var key := "save_before_skills_" + original.sha256_text()
	memory.fail = key
	check(not SaveManager.save(migrated, meta).ok and memory.data[SaveSlots.SLOT_MAIN] == original, "archive failure preserves old slot")
	memory.fail = ""
	memory.data[key] = "wrong"
	check(not SaveManager.save(migrated, meta).ok and memory.data[SaveSlots.SLOT_MAIN] == original, "archive readback conflict blocks overwrite")
	memory.data.erase(key)
	check(SaveManager.save(migrated, meta).ok and memory.data[key] == original, "archive exact bytes and retry")
	SaveManager.configure(c, memory)
	check(SaveManager.current_state().skill_version == 1, "restart migration success")
	SaveManager.reset_for_tests()
	s.state.era_id = 3
	s.state.level = 10
	s.state.buildings.wooden_house = 10
	s.state.buildings.rebirth_lotus = 1
	check(ReincarnationRules.apply_reincarnation(s.state, c, "normal").ok, "reincarnation")
	check(s.state.skills.is_empty() and s.state.resources.skill_point.value.to_float() == 0 and not s.state.resources.skill_point.unlocked, "no skill inheritance")
	# Isolated fixture for real UI verification; never touches user storage.
	var fixture := GameSession.create_new_game(c)
	fixture.state.era_id = 2
	fixture.state.buildings.library = 1
	fixture.state.buildings.scripture_hall = 1
	SkillSystem.sync_unlock(fixture.state)
	fixture.advance_time(3000)
	var panel := preload("res://src/presentation/system_actions_panel.gd").new()
	root.add_child(panel)
	await process_frame
	panel.mode = "skills"
	panel.refresh(fixture.get_view())
	var first_button: Button = panel.buttons["skill:basic_meditation"]
	fixture.advance_time(1)
	panel.refresh(fixture.get_view())
	check(panel.buttons["skill:basic_meditation"] == first_button, "point tick preserves button and scroll identity")
	check(panel.buttons.size() == 7 and not first_button.disabled, "six skill actions plus study shortcut")
	panel.show_save_failure("injected")
	panel.storage_recovered()
	check(not panel.save_failed and panel.status.text.contains("已恢復保存"), "save recovery status")
	panel.free()
	var f := FileAccess.open("res://docs/verification/artifacts/skills-b1-fixture.json", FileAccess.WRITE)
	var fixture_meta := meta.duplicate()
	fixture_meta.saved_at_utc_ms = str(int(Time.get_unix_time_from_system()*1000))
	fixture_meta.settled_until_utc_ms = fixture_meta.saved_at_utc_ms
	f.store_string(SaveCodec.encode(fixture.state, c.content_version, fixture_meta).json)
	if failures.is_empty():
		print("PASS: SKILL-B1 %d checks" % checks)
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
