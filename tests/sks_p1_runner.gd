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
	return s.submit({"command_id": "sks-p1-" + str(serial), "type": kind, "expected_revision": s.state.revision, "payload": payload})
func golden_item(view: Dictionary) -> Dictionary:
	var skills_view: Dictionary = view["skills"]
	for item in skills_view["items"]:
		var entry: Dictionary = item
		if String(entry.get("id", "")) == "golden_core_formation":
			return entry
	return {}
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var c: GameContent = ContentLoader.load_directory("res://content").content
	var meta := {"save_id": "sks-p1-test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}
	var attached := IslandProgression.attach(c)
	if not attached.ok:
		RunnerResult.finish(self, 1)
		return
	check(attached.ok, "attach skill content")
	check(c.skill_defs.size() == 24 and c.skill_defs.has("golden_core_formation"), "twenty-four skill definitions after attach")
	var version := c.content_version
	check(IslandProgression.attach(c).ok and c.content_version == version, "idempotent content attachment")
	check(c.skill_defs.size() == 24, "second attach keeps twenty-four skills")
	check(SkillSystem.attach(c).ok, "skill attach idempotent")
	check(SkillSystem.VERSION == 4 and SkillSystem.CONTENT_TAG == "+content-p1-skills", "skill system version and tag")
	var golden: Dictionary = c.skill_defs.golden_core_formation
	var golden_requires: Dictionary = golden.get("requires", {})
	check(String(golden.name) == "結丹法" and int(golden.max_level) == 5 and int(golden.era) == 3 and float(golden.cost) == 7650.0 and String(golden.effect) == "time_multiplier" and is_equal_approx(float(golden.amount), 0.9) and String(golden_requires.get("skill_id", "")) == "foundation_building" and int(golden_requires.get("level", 0)) == 1, "golden core definition frozen numbers")
	var s := GameSession.create_new_game(c)
	check(s.state.skill_version == 4 and s.get_view().skills.items.size() == 24, "new state and twenty-four skill view")
	s.state.era_id = 2
	for id in ["money", "wood", "stone_low", "spirit_grass_low", "black_copper"]:
		s.state.resources[id].value = AmountCompat.from_number(10000)
		s.state.resources[id].unlocked = true
	check(send(s, "upgrade_building", {"building_id": "library"}).ok and s.state.resources.skill_point.unlocked, "paid library unlocks production")
	s.state.resources.skill_point.value = AmountCompat.from_number(7650)
	var before := s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s.state.to_snapshot_dict() == before, "golden refused before era 3 atomically")
	check(String(golden_item(s.get_view()).get("reason", "")) == "SKILL_ERA_LOCKED", "era-locked view reason")
	s.state.era_id = 3
	before = s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s.state.to_snapshot_dict() == before, "golden refused at era 3 without foundation")
	check(String(golden_item(s.get_view()).get("reason", "")) == "SKILL_PREREQ_LOCKED", "prereq-locked view reason")
	s.state.resources.skill_point.value = AmountCompat.from_number(3600)
	check(send(s, "learn_skill", {"skill_id": "foundation_building"}).ok and s.state.skills.foundation_building == 1, "foundation prereq learned")
	s.state.resources.skill_point.value = AmountCompat.from_number(7650)
	var points_before: float = s.state.resources.skill_point.value.to_float()
	check(send(s, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s.state.skills.golden_core_formation == 1, "golden learn allowed after prereq")
	var points_after: float = s.state.resources.skill_point.value.to_float()
	check(is_equal_approx(points_before - points_after, 7650.0) and is_equal_approx(points_after, 0.0), "first golden learn deducts 7650 exactly")
	var duplicate := s.submit({"command_id": "sks-p1-" + str(serial), "type": "learn_skill", "expected_revision": s.state.revision - 1, "payload": {"skill_id": "golden_core_formation"}})
	check(duplicate.ok and duplicate.duplicate and s.state.skills.golden_core_formation == 1 and is_equal_approx(s.state.resources.skill_point.value.to_float(), 0.0), "duplicate learn does not double-charge")
	for level in range(2, 6):
		s.state.resources.skill_point.value = AmountCompat.from_number(7650)
		check(send(s, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s.state.skills.golden_core_formation == level, "golden level %d learn" % level)
	s.state.resources.skill_point.value = AmountCompat.from_number(7650)
	before = s.state.to_snapshot_dict()
	check(not send(s, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s.state.to_snapshot_dict() == before, "golden max level refusal atomic")
	var max_item := golden_item(s.get_view())
	check(String(max_item.get("reason", "")) == "SKILL_MAX_LEVEL" and not bool(max_item.get("can_learn", true)), "golden max level view reason")
	var s2 := GameSession.create_new_game(c)
	s2.state.era_id = 3
	s2.state.buildings.library = 1
	SkillSystem.sync_unlock(s2.state)
	for id in ["lingli", "money", "stone_mid", "liquid", "formation_core", "spirit_grass_low"]:
		if not s2.state.resources.has(id):
			s2.state.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": true}
		s2.state.resources[id].value = AmountCompat.from_number(10000)
		s2.state.resources[id].unlocked = true
	check(is_equal_approx(SkillSystem.effect(c, s2.state.skills, "time_multiplier"), 1.0), "time multiplier without golden is one")
	s2.state.resources.skill_point.value = AmountCompat.from_number(3600)
	check(send(s2, "learn_skill", {"skill_id": "foundation_building"}).ok and s2.state.skills.foundation_building == 1, "second session foundation prereq")
	s2.state.resources.skill_point.value = AmountCompat.from_number(7650)
	check(send(s2, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s2.state.skills.golden_core_formation == 1, "second session golden level 1")
	var era_def: Variant = c.era(3)
	var level_one := s2.state.level
	var base_case := Cultivation.next_level_required_seconds(era_def, level_one, 0.0, 1.0)
	var mult_one := SkillSystem.effect(c, s2.state.skills, "time_multiplier")
	check(is_equal_approx(mult_one, 0.9), "N1 effect is pow 0.9")
	var reduced_one := Cultivation.next_level_required_seconds(era_def, level_one, 0.0, mult_one)
	check(absf(reduced_one - base_case * pow(0.9, 1)) <= 0.001 * base_case * pow(0.9, 1), "N1 reduced requirement equals base times pow")
	s2.state.training_seconds = reduced_one
	check(send(s2, "level_up_cultivation", {}).ok and s2.state.level == 2, "N1 level up at reduced requirement")
	s2.state.resources.skill_point.value = AmountCompat.from_number(7650)
	check(send(s2, "learn_skill", {"skill_id": "golden_core_formation"}).ok and s2.state.skills.golden_core_formation == 2, "second session golden level 2")
	var base_two := Cultivation.next_level_required_seconds(era_def, s2.state.level, 0.0, 1.0)
	var mult_two := SkillSystem.effect(c, s2.state.skills, "time_multiplier")
	check(is_equal_approx(mult_two, 0.81), "N2 effect is pow 0.81")
	var reduced_two := Cultivation.next_level_required_seconds(era_def, s2.state.level, 0.0, mult_two)
	check(absf(reduced_two - base_two * pow(0.9, 2)) <= 0.001 * base_two * pow(0.9, 2), "N2 reduced requirement equals base times pow")
	s2.state.training_seconds = reduced_two
	check(send(s2, "level_up_cultivation", {}).ok and s2.state.level == 3, "N2 level up at reduced requirement")
	check(send(s2, "refine_pill", {"pill_id": "cultivation_pill", "count": 2}).ok and int(s2.state.pills.get("cultivation_pill", 0)) == 2, "cultivation pills refined via command")
	var reduced_three := Cultivation.next_level_required_seconds(era_def, s2.state.level, 0.0, SkillSystem.effect(c, s2.state.skills, "time_multiplier"))
	s2.state.training_seconds = reduced_three + 1.0
	var refused_pill := send(s2, "consume_pill", {"pill_id": "cultivation_pill", "count": 1})
	check(not refused_pill.ok and String(refused_pill.get("error", "")) == "TRAINING_ALREADY_COMPLETE" and int(s2.state.pills.get("cultivation_pill", 0)) == 2, "pill above reduced ceiling refused")
	s2.state.training_seconds = reduced_three - 60.0
	var consumed_pill := send(s2, "consume_pill", {"pill_id": "cultivation_pill", "count": 1})
	check(consumed_pill.ok and absf(s2.state.training_seconds - reduced_three) <= 0.000001 and int(s2.state.pills.get("cultivation_pill", 0)) == 1, "pill clamps to reduced ceiling")
	check(send(s2, "level_up_cultivation", {}).ok and s2.state.level == 4, "progression consistent after pill")
	var roundtrip := SaveCodec.decode(SaveCodec.encode(s2.state, c.content_version, meta).json)
	check(roundtrip.ok and int(roundtrip.state.skill_version) == 4 and roundtrip.state.skills == s2.state.skills, "save skill roundtrip version 4")
	check(roundtrip.ok and int(roundtrip.state.skills.get("golden_core_formation", 0)) == 2, "golden level preserved in roundtrip")
	s2.state.skills.unknown = 1
	check(not SaveCodec.encode(s2.state, c.content_version, meta).ok, "reject unknown skill")
	s2.state.skills.erase("unknown")
	var tampered: Dictionary = JSON.parse_string(SaveCodec.encode(s2.state, c.content_version, meta).json)
	tampered.state.skills["mystery_skill"] = 1
	tampered.checksum = SaveCodec.compute_checksum(tampered)
	var rejected := SaveCodec.decode(JSON.stringify(tampered))
	check(not rejected.ok and rejected.state == null, "decode rejects unknown skill id")
	var old := GameSession.create_new_game(c)
	var snapshot: Dictionary = old.state.to_snapshot_dict()
	snapshot.skill_version = 1
	snapshot.skills = {"basic_meditation": 2, "qi_condensation": 1, "foundation_building": 1, "qi_storage_1": 1, "body_strengthening_1": 1, "building_mastery_1": 1}
	var legacy_envelope: Dictionary = {"schema_version": 5, "game_version": SaveCodec.GAME_VERSION, "content_version": c.content_version, "rules_version": SaveCodec.RULES_VERSION, "amount_format_version": SaveCodec.AMOUNT_FORMAT_VERSION, "generator_version": SaveCodec.GENERATOR_VERSION, "save_id": meta.save_id, "revision": int(old.state.revision), "saved_at_utc_ms": meta.saved_at_utc_ms, "settled_until_utc_ms": meta.settled_until_utc_ms, "sim_tick": meta.sim_tick, "state": snapshot, "rng_streams": {}, "last_offline_report": null}
	legacy_envelope.checksum = SaveCodec.compute_checksum(legacy_envelope)
	var original := JSON.stringify(legacy_envelope)
	check(SaveCodec.RULES_VERSION == "core-flow-17-content-p1-story", "rules version content p1 story")
	check(SaveCodec.decode(original).ok, "v1 save decodes")
	var memory := Memory.new()
	memory.data[SaveSlots.SLOT_MAIN] = original
	SaveManager.configure(c, memory)
	var migrated := SaveManager.current_state()
	check(migrated != null and migrated.skill_version == 4, "v1 migration bumps skill version to 4")
	check(migrated != null and migrated.skills.size() == 6 and not migrated.skills.has("golden_core_formation"), "v1 migration keeps b1 skills without golden")
	check(migrated != null and migrated.revision == old.state.revision + 1, "v1 migration bumps revision")
	var key := "save_before_skills_" + original.sha256_text()
	memory.fail = key
	check(not SaveManager.save(migrated, meta).ok and memory.data[SaveSlots.SLOT_MAIN] == original, "archive failure preserves old slot")
	memory.fail = ""
	memory.data[key] = "wrong"
	check(not SaveManager.save(migrated, meta).ok and memory.data[SaveSlots.SLOT_MAIN] == original, "archive readback conflict blocks overwrite")
	memory.data.erase(key)
	check(SaveManager.save(migrated, meta).ok and memory.data[key] == original, "archive exact bytes and retry")
	SaveManager.configure(c, memory)
	check(SaveManager.current_state() != null and SaveManager.current_state().skill_version == 4, "restart migration success")
	SaveManager.reset_for_tests()
	s.state.buildings.rebirth_lotus = 1
	check(send(s, "reincarnate", {"mode": "normal"}).ok, "reincarnation command accepted")
	check(not s.state.skills.has("golden_core_formation"), "reincarnation clears golden core")
	check(s.state.skills.is_empty() and s.state.resources.skill_point.value.to_float() == 0 and not s.state.resources.skill_point.unlocked, "no skill inheritance")
	check(s.state.reincarnation_count == 1, "reincarnation counted")
	var fixture := GameSession.create_new_game(c)
	fixture.state.era_id = 2
	fixture.state.buildings.library = 1
	SkillSystem.sync_unlock(fixture.state)
	fixture.state.resources.skill_point.value = AmountCompat.from_number(7650)
	var panel := preload("res://src/presentation/system_actions_panel.gd").new()
	root.add_child(panel)
	await process_frame
	panel.mode = "skills"
	panel.refresh(fixture.get_view())
	var page = panel.skill_view
	check(page.cards.size() == 24, "twenty-four skill cards")
	check(panel.buttons.size() == 25, "twenty-four skill actions plus study shortcut")
	var golden_button: Button = page.buttons["skill:golden_core_formation"]
	check(golden_button.text == "境界未達" and golden_button.disabled, "era-locked button label and disabled")
	var fixture_two := GameSession.create_new_game(c)
	fixture_two.state.era_id = 3
	fixture_two.state.buildings.library = 1
	SkillSystem.sync_unlock(fixture_two.state)
	fixture_two.state.resources.skill_point.value = AmountCompat.from_number(7650)
	panel.refresh(fixture_two.get_view())
	check(golden_button.text == "前置未足" and golden_button.disabled, "prereq-locked button label and disabled")
	panel.free()
	if failures.is_empty():
		print("PASS: SKS-P1 %d checks" % checks)
		RunnerResult.finish(self, 0)
	else:
		for failure in failures: push_error(failure)
		RunnerResult.finish(self, 1)

