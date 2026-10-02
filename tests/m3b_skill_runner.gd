extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	print("[RUNNING] tests/m3b_skill_runner.gd")
	var loaded: Dictionary = ContentLoader.load_directory("res://content")
	if not bool(loaded.get("ok", false)):
		print("FAIL load_production_content ContentLoader.load_directory: %s" % str(loaded.get("errors", [])))
		print("RESULT: FAIL (1 failures)")
		quit(1)
		return
	var content: GameContent = loaded["content"]
	_test_can_learn_unknown_skill(content)
	_test_learn_basic_meditation_success(content)
	_test_learn_to_max(content)
	_test_insufficient_resource(content)
	_test_flat_cost_not_scaling(content)
	_test_get_view_shape(content)
	_test_command_rejects_empty_skill_id(content)
	_test_save_load_roundtrip(content)
	_test_reconcile_zero_fill(content)
	_test_game_session_view(content)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL (%d failures)" % failures.size())
		quit(1)

func _check(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		print("PASS %s" % name)
	else:
		print("FAIL %s %s" % [name, detail])
		failures.append("%s: %s" % [name, detail])

func _note(text: String) -> void:
	print("NOTE %s" % text)

func _string_set(values: Array) -> Dictionary:
	var set := {}
	for value in values:
		set[String(value)] = true
	return set

func _new_reconciled_state(content: GameContent, era_id: int) -> GameState:
	var state := GameState.new()
	state.era_id = era_id
	state.level = 1
	state.onboarding_version = Onboarding.SCHEMA_VERSION
	ContentReconciliation.reconcile(state, content)
	return state

func _grant_all(state: GameState, amounts: Dictionary) -> void:
	for resource_id in amounts:
		var entry: Dictionary = state.resources[String(resource_id)]
		entry["value"] = AmountCompat.from_number(float(amounts[resource_id]))
		entry["unlocked"] = true
		entry["ever_obtained"] = true

func _learn_command(skill_id: String, state: GameState) -> Dictionary:
	return {"command_id": "m3b_skill", "type": "learn_skill", "expected_revision": state.revision, "payload": {"skill_id": skill_id}}

func _amount_matches(serial: Variant, expected: float) -> bool:
	if not (serial is String):
		return false
	var parsed: Dictionary = AmountCompat.try_parse(String(serial))
	if not bool(parsed.get("ok", false)):
		return false
	var value: AmountCompat = parsed["value"]
	return value.compare_to(AmountCompat.from_number(expected)) == 0

func _entry_matches(state: GameState, resource_id: String, expected: float) -> bool:
	if not state.resources.has(resource_id):
		return false
	var entry: Dictionary = state.resources[resource_id]
	var value: AmountCompat = entry["value"]
	return value.compare_to(AmountCompat.from_number(expected)) == 0

func _find_view_entry(view: Array, skill_id: String) -> Dictionary:
	for entry_variant in view:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) == skill_id:
			return entry
	return {}

func _test_can_learn_unknown_skill(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var check: Dictionary = SkillSystem.can_learn(content, state, "nonexistent_skill")
	_check("unknown_can_learn_false", not bool(check.get("can_learn", true)), "got %s" % str(check))
	_check("unknown_can_learn_reason", String(check.get("reason", "")) == "UNKNOWN_SKILL", "got %s" % String(check.get("reason", "")))
	var def_variant: Variant = SkillSystem.get_definition(content, "nonexistent_skill")
	_check("unknown_get_definition_null", def_variant == null, "got %s" % str(def_variant))
	var result: Dictionary = CommandProcessor.apply(content, state, _learn_command("nonexistent_skill", state))
	state.revision += 1
	_check("unknown_command_rejected", not bool(result.get("ok", true)), "got %s" % str(result))
	_check("unknown_command_error", String(result.get("error", "")) == "UNKNOWN_SKILL", "got %s" % String(result.get("error", "")))

func _test_learn_basic_meditation_success(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 100.0})
	var result: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
	state.revision += 1
	_check("success_ok", bool(result.get("ok", false)), "%s %s" % [String(result.get("error", "")), str(result.get("detail", {}))])
	_check("success_level_1", int(state.skills.get("basic_meditation", -1)) == 1, "got %d" % int(state.skills.get("basic_meditation", -1)))
	var events: Array = result.get("events", [])
	_check("success_event_count", events.size() == 1, "got %d" % events.size())
	if events.size() == 1:
		var event: Dictionary = events[0]
		_check("success_event_kind", String(event.get("kind", "")) == "skill_learned", "got %s" % String(event.get("kind", "")))
		_check("success_event_skill_id", String(event.get("skill_id", "")) == "basic_meditation", "got %s" % String(event.get("skill_id", "")))
		_check("success_event_new_level", int(event.get("new_level", -1)) == 1, "got %d" % int(event.get("new_level", -1)))
		_check("success_event_cost_resource", String(event.get("cost_resource", "")) == "skill_point", "got %s" % String(event.get("cost_resource", "")))
		_check("success_event_cost_90", _amount_matches(event.get("cost"), 90.0), "got %s" % str(event.get("cost")))
		_check("success_event_remaining_10", _amount_matches(event.get("remaining"), 10.0), "got %s" % str(event.get("remaining")))
	var changed := _string_set(result.get("changed_ids", []))
	_check("success_changed_skill_point", changed.has("skill_point"), "got %s" % str(changed))
	_check("success_changed_skills", changed.has("skills"), "got %s" % str(changed))
	_check("success_balance_10", _entry_matches(state, "skill_point", 10.0), "balance not 10")

func _test_learn_to_max(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 100.0})
	var reached_max := true
	for attempt in range(1, 6):
		var result: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
		state.revision += 1
		if not bool(result.get("ok", false)):
			_check("maxlvl_attempt_%d_ok" % attempt, false, "%s %s" % [String(result.get("error", "")), str(result.get("detail", {}))])
			reached_max = false
			break
		_check("maxlvl_level_%d" % attempt, int(state.skills.get("basic_meditation", -1)) == attempt, "got %d" % int(state.skills.get("basic_meditation", -1)))
		_grant_all(state, {"skill_point": 90.0})
	if reached_max:
		var overflow: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
		state.revision += 1
		_check("maxlvl_sixth_rejected", not bool(overflow.get("ok", true)), "got %s" % str(overflow))
		_check("maxlvl_sixth_error", String(overflow.get("error", "")) == "SKILL_MAX_LEVEL", "got %s" % String(overflow.get("error", "")))
		_check("maxlvl_stays_5", int(state.skills.get("basic_meditation", -1)) == 5, "got %d" % int(state.skills.get("basic_meditation", -1)))
	else:
		_note("maxlvl chain aborted before level 5, sixth-attempt checks skipped")

func _test_insufficient_resource(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 50.0})
	var result: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
	state.revision += 1
	_check("insufficient_rejected", not bool(result.get("ok", true)), "got %s" % str(result))
	_check("insufficient_error", String(result.get("error", "")) == "INSUFFICIENT_RESOURCE", "got %s" % String(result.get("error", "")))
	_check("insufficient_level_unchanged", int(state.skills.get("basic_meditation", -1)) == 0, "got %d" % int(state.skills.get("basic_meditation", -1)))
	_check("insufficient_balance_50", _entry_matches(state, "skill_point", 50.0), "balance not 50")
	var check: Dictionary = SkillSystem.can_learn(content, state, "basic_meditation")
	_check("insufficient_can_learn_reason", String(check.get("reason", "")) == "INSUFFICIENT_RESOURCE", "got %s" % String(check.get("reason", "")))

func _test_flat_cost_not_scaling(content: GameContent) -> void:
	var def_variant: Variant = SkillSystem.get_definition(content, "basic_meditation")
	_check("flat_def_exists", def_variant != null, "definition missing")
	if def_variant == null:
		return
	var def: Dictionary = def_variant
	var cost_l0: AmountCompat = SkillSystem.get_cost(def)
	_check("flat_cost_level_0_is_90", cost_l0.compare_to(AmountCompat.from_number(90.0)) == 0, "got %s" % cost_l0.serialize())
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 200.0})
	var first: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
	state.revision += 1
	_check("flat_first_ok", bool(first.get("ok", false)), String(first.get("error", "")))
	var cost_l1: AmountCompat = SkillSystem.get_cost(def)
	_check("flat_cost_level_1_is_90", cost_l1.compare_to(AmountCompat.from_number(90.0)) == 0, "got %s" % cost_l1.serialize())
	var second: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
	state.revision += 1
	_check("flat_second_ok", bool(second.get("ok", false)), String(second.get("error", "")))
	_check("flat_level_2", int(state.skills.get("basic_meditation", -1)) == 2, "got %d" % int(state.skills.get("basic_meditation", -1)))
	_check("flat_remaining_20", _entry_matches(state, "skill_point", 20.0), "balance not 20")

func _test_get_view_shape(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 200.0})
	for attempt in range(1, 3):
		var result: Dictionary = CommandProcessor.apply(content, state, _learn_command("basic_meditation", state))
		state.revision += 1
		if not bool(result.get("ok", false)):
			_check("view_prelude_learn_%d" % attempt, false, String(result.get("error", "")))
	_grant_all(state, {"skill_point": 200.0})
	var view: Array = SkillSystem.get_view(content, state)
	_check("view_size_6", view.size() == 6, "got %d" % view.size())
	var bm := _find_view_entry(view, "basic_meditation")
	_check("view_bm_present", not bm.is_empty(), "entry missing")
	if not bm.is_empty():
		_check("view_bm_keys", bm.has("id") and bm.has("name_key") and bm.has("level") and bm.has("max_level") and bm.has("cost") and bm.has("cost_resource") and bm.has("can_learn") and bm.has("reason"), "got %s" % str(bm.keys()))
		_check("view_bm_name_key", not String(bm.get("name_key", "")).is_empty(), "got %s" % String(bm.get("name_key", "")))
		_check("view_bm_level_2", int(bm.get("level", -1)) == 2, "got %d" % int(bm.get("level", -1)))
		_check("view_bm_max_5", int(bm.get("max_level", -1)) == 5, "got %d" % int(bm.get("max_level", -1)))
		_check("view_bm_cost_resource", String(bm.get("cost_resource", "")) == "skill_point", "got %s" % String(bm.get("cost_resource", "")))
		var bm_cost: Dictionary = bm.get("cost", {})
		_check("view_bm_cost_90", _amount_matches(bm_cost.get("skill_point"), 90.0), "got %s" % str(bm_cost))
		_check("view_bm_can_learn", bool(bm.get("can_learn", false)), "got %s" % str(bm.get("can_learn", false)))
	var fb := _find_view_entry(view, "foundation_building")
	_check("view_fb_present", not fb.is_empty(), "entry missing")
	if not fb.is_empty():
		_check("view_fb_level_0", int(fb.get("level", -1)) == 0, "got %d" % int(fb.get("level", -1)))
		_check("view_fb_max_5", int(fb.get("max_level", -1)) == 5, "got %d" % int(fb.get("max_level", -1)))
		_check("view_fb_can_learn_false", not bool(fb.get("can_learn", true)), "got %s" % str(fb.get("can_learn", true)))
		_check("view_fb_reason", String(fb.get("reason", "")) == "INSUFFICIENT_RESOURCE", "got %s" % String(fb.get("reason", "")))

func _test_command_rejects_empty_skill_id(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_grant_all(state, {"skill_point": 100.0})
	var result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b_skill", "type": "learn_skill", "expected_revision": state.revision, "payload": {}})
	state.revision += 1
	_check("empty_id_rejected", not bool(result.get("ok", true)), "got %s" % str(result))
	_check("empty_id_error", String(result.get("error", "")) == "EMPTY_SKILL_ID", "got %s" % String(result.get("error", "")))
	_check("empty_id_no_events", (result.get("events", []) as Array).is_empty(), "got %s" % str(result.get("events", [])))

func _test_save_load_roundtrip(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	state.skills["basic_meditation"] = 3
	state.skills["qi_storage_1"] = 1
	var meta := {"save_id": "test", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0", "rng_streams": {}}
	var enc: Dictionary = SaveCodec.encode(state, content.content_version, meta)
	_check("roundtrip_encode_ok", bool(enc.get("ok", false)), String(enc.get("error", "")))
	if not bool(enc.get("ok", false)):
		return
	var dec: Dictionary = SaveCodec.decode(String(enc.get("json", "")))
	_check("roundtrip_decode_ok", bool(dec.get("ok", false)), String(dec.get("error", "")))
	if not bool(dec.get("ok", false)):
		return
	var loaded_variant: Variant = dec.get("state")
	_check("roundtrip_state_present", loaded_variant is GameState, "got %s" % str(loaded_variant))
	if not (loaded_variant is GameState):
		return
	var loaded: GameState = loaded_variant
	_check("roundtrip_skills_dict", loaded.skills is Dictionary, "got %s" % str(loaded.skills))
	_check("roundtrip_bm_3", int(loaded.skills.get("basic_meditation", -1)) == 3, "got %d" % int(loaded.skills.get("basic_meditation", -1)))
	_check("roundtrip_qs_1", int(loaded.skills.get("qi_storage_1", -1)) == 1, "got %d" % int(loaded.skills.get("qi_storage_1", -1)))
	_check("roundtrip_qc_0", int(loaded.skills.get("qi_condensation", -1)) == 0, "got %d" % int(loaded.skills.get("qi_condensation", -1)))

func _test_reconcile_zero_fill(content: GameContent) -> void:
	var state := GameState.new()
	_check("zero_fill_start_empty", state.skills.is_empty(), "got %s" % str(state.skills))
	var result: Dictionary = ContentReconciliation.reconcile(state, content)
	_check("zero_fill_reconcile_ok", bool(result.get("ok", false)), String(result.get("error", "")))
	_check("zero_fill_count_6", state.skills.size() == 6, "got %d" % state.skills.size())
	var all_zero := true
	for skill_id in content.skill_ids:
		if not state.skills.has(String(skill_id)) or int(state.skills[String(skill_id)]) != 0:
			all_zero = false
	_check("zero_fill_all_six_zero", all_zero, "got %s" % str(state.skills))
	var report: Dictionary = result.get("report", {})
	var added: Array = report.get("missing_skills_added", [])
	_check("zero_fill_report_6", added.size() == 6, "got %d" % added.size())

func _test_game_session_view(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.era_id = 2
	_grant_all(session.state, {"skill_point": 100.0})
	var revision_before: int = session.state.revision
	var res: Dictionary = session.learn_skill("basic_meditation")
	_check("session_learn_ok", bool(res.get("ok", false)), "%s %s" % [String(res.get("error", "")), str(res.get("detail", {}))])
	_check("session_learn_revision_bumped", int(res.get("new_revision", -1)) == revision_before + 1, "got %d" % int(res.get("new_revision", -1)))
	_check("session_learn_level_1", int(session.state.skills.get("basic_meditation", -1)) == 1, "got %d" % int(session.state.skills.get("basic_meditation", -1)))
	var view: Dictionary = session.get_view()
	_check("session_view_has_skills", view.has("skills"), "missing skills key")
	var skills_variant: Variant = view.get("skills")
	_check("session_view_skills_array_6", skills_variant is Array and (skills_variant as Array).size() == 6, "got %s" % str(skills_variant))
