extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	print("[RUNNING] tests/m3b_skill_effect_runner.gd")
	var loaded: Dictionary = ContentLoader.load_directory("res://content")
	if not bool(loaded.get("ok", false)):
		print("FAIL load_content ContentLoader.load_directory: %s" % str(loaded.get("errors", [])))
		print("RESULT: FAIL (1 failures)")
		quit(1)
		return
	var content: GameContent = loaded["content"]
	_test_skill_defs_have_effects(content)
	_test_compute_rates_empty_skills(content)
	_test_lingli_multiplier(content)
	_test_lingli_rate_addition(content)
	_test_lingli_and_money_effects(content)
	_test_caps_skill_max_additions(content)
	_test_caps_rate_skill_no_cap_effect(content)
	_test_level_cap_building_mastery(content)
	_test_time_multiplier_no_time_reduction_skill(content)
	_test_session_view_reflects_skills(content)
	_test_bad_effect_schema_rejected()
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

func _learn(content: GameContent, state: GameState, skill_id: String, points: float) -> bool:
	_grant_all(state, {"skill_point": points})
	var result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b_effect", "type": "learn_skill", "expected_revision": state.revision, "payload": {"skill_id": skill_id}})
	state.revision += 1
	return bool(result.get("ok", false))

func _amount_matches(serial: Variant, expected: float) -> bool:
	if not (serial is String):
		return false
	var parsed: Dictionary = AmountCompat.try_parse(String(serial))
	if not bool(parsed.get("ok", false)):
		return false
	return (parsed["value"] as AmountCompat).compare_to(AmountCompat.from_number(expected)) == 0

func _rates_as_numbers(rates: Dictionary) -> Dictionary:
	var out := {}
	for resource_id in rates:
		out[String(resource_id)] = (rates[resource_id] as AmountCompat).to_float()
	return out

func _test_skill_defs_have_effects(content: GameContent) -> void:
	var skill_ids := ["basic_meditation", "qi_condensation", "foundation_building", "qi_storage_1", "body_strengthening_1", "building_mastery_1"]
	var expected_effects := {
		"basic_meditation": {"type": "lingli_multiplier", "amount": 1.1},
		"qi_condensation": {"type": "lingli_rate", "amount": 2.0},
		"foundation_building": {"type": "money_multiplier", "amount": 1.2},
		"qi_storage_1": {"type": "lingli_max", "amount": 200.0},
		"body_strengthening_1": {"type": "money_max", "amount": 2000.0},
		"building_mastery_1": {"type": "building_level_cap", "amount": 10.0},
	}
	for skill_id in skill_ids:
		var def_variant: Variant = content.skill(String(skill_id))
		_check("def_%s_exists" % skill_id, def_variant != null, "missing")
		if def_variant == null:
			continue
		var def: Dictionary = def_variant
		var effect: Variant = def.get("effect", null)
		_check("def_%s_effect_object" % skill_id, effect is Dictionary, "got %s" % str(effect))
		if not (effect is Dictionary):
			continue
		var expected: Dictionary = expected_effects[skill_id]
		_check("def_%s_effect_type" % skill_id, String(effect.get("type", "")) == String(expected["type"]), "got %s" % String(effect.get("type", "")))
		_check("def_%s_effect_amount" % skill_id, absf(float(effect.get("amount", -1.0)) - float(expected["amount"])) < 0.0001, "got %s" % str(effect.get("amount", 0.0)))

func _test_compute_rates_empty_skills(content: GameContent) -> void:
	var baseline: Dictionary = Production.compute_rates(content, {}, 1.0)
	var with_empty: Dictionary = Production.compute_rates(content, {}, 1.0, {})
	var base_numbers := _rates_as_numbers(baseline)
	var empty_numbers := _rates_as_numbers(with_empty)
	_check("empty_skills_same_baseline", base_numbers == empty_numbers, "%s vs %s" % [str(base_numbers), str(empty_numbers)])
	var caps_baseline: Dictionary = Production.compute_caps(content, {}, 2, Onboarding.SCHEMA_VERSION)
	var caps_with_empty: Dictionary = Production.compute_caps(content, {}, 2, Onboarding.SCHEMA_VERSION, {})
	var base_caps := _rates_as_numbers(caps_baseline)
	var empty_caps := _rates_as_numbers(caps_with_empty)
	_check("empty_skills_same_caps", base_caps == empty_caps, "%s vs %s" % [str(base_caps), str(empty_caps)])

func _test_lingli_multiplier(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var original_lingli_rate: Variant = content.resources["lingli"]["rate"]
	content.resources["lingli"]["rate"] = 10.0
	var before := _rates_as_numbers(Production.compute_rates(content, state.buildings, 1.0, state.skills))
	var ok := _learn(content, state, "basic_meditation", 100.0)
	_check("mult_learn_ok", ok, "learn failed")
	var after := _rates_as_numbers(Production.compute_rates(content, state.buildings, 1.0, state.skills))
	var base_rate: float = content.resources["lingli"]["rate"]
	_check("mult_base_rate_10", absf(before.get("lingli", -1.0) - 10.0) < 0.0001, "got %s" % str(before.get("lingli", 0.0)))
	_check("mult_lingli_rate_1_1x", absf(after.get("lingli", -1.0) - 11.0) < 0.0001, "got %s base %s" % [str(after.get("lingli", 0.0)), str(before.get("lingli", 0.0))])
	var learned_all := true
	for attempt in range(2, 6):
		if not _learn(content, state, "basic_meditation", 90.0):
			learned_all = false
			_check("mult_learn_to_%d" % attempt, false, "learn failed")
	var final := _rates_as_numbers(Production.compute_rates(content, state.buildings, 1.0, state.skills))
	if learned_all:
		var expected: float = base_rate * pow(1.1, 5.0)
		_check("mult_lingli_rate_level5", absf(final.get("lingli", -1.0) - expected) < 0.0001, "got %s want %s" % [str(final.get("lingli", 0.0)), str(expected)])
	var caps_with: Dictionary = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills)
	_check("mult_caps_lingli_unchanged", _amount_matches((caps_with["lingli"] as AmountCompat).serialize(), 100.0), "got %s" % str((caps_with["lingli"] as AmountCompat).serialize()))
	content.resources["lingli"]["rate"] = original_lingli_rate

func _test_lingli_rate_addition(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var base_rate: float = content.resources["lingli"]["rate"]
	for level in range(1, 6):
		if not _learn(content, state, "qi_condensation", 1800.0):
			_check("rate_learn_%d" % level, false, "learn failed")
			return
		var rates := _rates_as_numbers(Production.compute_rates(content, state.buildings, 1.0, state.skills))
		var expected: float = base_rate + 2.0 * float(level)
		_check("rate_lingli_level_%d" % level, absf(rates.get("lingli", -1.0) - expected) < 0.0001, "got %s want %s" % [str(rates.get("lingli", 0.0)), str(expected)])

func _test_lingli_and_money_effects(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var ok1 := _learn(content, state, "foundation_building", 3600.0)
	var ok2 := _learn(content, state, "basic_meditation", 90.0)
	_check("combined_learn_ok", ok1 and ok2, "learn failed")
	var original_money_rate: Variant = content.resources["money"]["rate"]
	content.resources["money"]["rate"] = 10.0
	var original_lingli_rate: Variant = content.resources["lingli"]["rate"]
	content.resources["lingli"]["rate"] = 10.0
	var boosted := _rates_as_numbers(Production.compute_rates(content, state.buildings, 1.0, state.skills))
	content.resources["money"]["rate"] = original_money_rate
	content.resources["lingli"]["rate"] = original_lingli_rate
	_check("combined_money_1_2x", absf(boosted.get("money", -1.0) - 12.0) < 0.0001, "got %s" % str(boosted.get("money", 0.0)))
	_check("combined_lingli_1_1x", absf(boosted.get("lingli", -1.0) - 11.0) < 0.0001, "got %s" % str(boosted.get("lingli", 0.0)))

func _test_caps_skill_max_additions(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var ok1 := _learn(content, state, "qi_storage_1", 120.0)
	var ok2 := _learn(content, state, "body_strengthening_1", 1000.0)
	_check("cap_learn_ok", ok1 and ok2, "learn failed")
	var caps := _rates_as_numbers(Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills))
	_check("cap_lingli_300", absf(caps.get("lingli", -1.0) - 300.0) < 0.0001, "got %s" % str(caps.get("lingli", 0.0)))
	_check("cap_money_2200", absf(caps.get("money", -1.0) - 2200.0) < 0.0001, "got %s" % str(caps.get("money", 0.0)))
	_check("cap_wood_100", absf(caps.get("wood", -1.0) - 100.0) < 0.0001, "got %s" % str(caps.get("wood", 0.0)))

func _test_caps_rate_skill_no_cap_effect(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	_learn(content, state, "qi_condensation", 1800.0)
	var caps := _rates_as_numbers(Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills))
	_check("rate_skill_cap_lingli_100", absf(caps.get("lingli", -1.0) - 100.0) < 0.0001, "got %s" % str(caps.get("lingli", 0.0)))

func _test_level_cap_building_mastery(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 2)
	var def_variant: Variant = content.building("library")
	_check("library_def_exists", def_variant != null, "missing library")
	if def_variant == null:
		return
	var definition: Dictionary = def_variant
	var original_max_level: Variant = definition.get("max_level")
	definition["max_level"] = 10
	var base_cap := CommandProcessor.level_cap(definition)
	_check("level_cap_base_10", base_cap == 10, "got %d" % base_cap)
	var ok := _learn(content, state, "building_mastery_1", 10000.0)
	_check("mastery_learn_ok", ok, "learn failed")
	var boosted_cap := CommandProcessor.level_cap(definition, content, state)
	_check("level_cap_boosted_20", boosted_cap == 20, "got %d" % boosted_cap)
	var cap_with_default := CommandProcessor.level_cap(definition)
	_check("level_cap_no_state_unchanged", cap_with_default == 10, "got %d" % cap_with_default)
	definition["max_level"] = original_max_level

func _test_time_multiplier_no_time_reduction_skill(content: GameContent) -> void:
	var era_def: Variant = content.era(2)
	_check("era2_exists", era_def != null, "missing era 2")
	if era_def == null:
		return
	var state := _new_reconciled_state(content, 2)
	state.skills["basic_meditation"] = 5
	state.skills["qi_condensation"] = 3
	var skill_arr: Array = Production._collect_skill_effects(content, state.skills)
	var mult := Cultivation.skill_time_multiplier(skill_arr)
	_check("time_mult_1_without_time_reduction", absf(mult - 1.0) < 0.0001, "got %s" % str(mult))
	var base_req: float = Cultivation.next_level_required_seconds(era_def, 1, 0.0, 1.0)
	var req: float = Cultivation.next_level_required_seconds(era_def, 1, 0.0, mult)
	_check("time_req_unchanged", absf(req - base_req) < 0.0001, "got %s vs %s" % [str(req), str(base_req)])

func _test_session_view_reflects_skills(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.era_id = 2
	var original_lingli_rate: Variant = content.resources["lingli"]["rate"]
	content.resources["lingli"]["rate"] = 10.0
	var pre_view: Dictionary = session.get_view()
	var pre_resources: Dictionary = pre_view.get("resources", {})
	var pre_lingli: Dictionary = pre_resources.get("lingli", {})
	var pre_serial: Variant = pre_lingli.get("rate", "")
	var pre_parsed: Dictionary = AmountCompat.try_parse(String(pre_serial))
	_check("session_pre_rate_parses", bool(pre_parsed.get("ok", false)), "rate %s" % str(pre_serial))
	if not bool(pre_parsed.get("ok", false)):
		content.resources["lingli"]["rate"] = original_lingli_rate
		return
	var base_rate: float = (pre_parsed["value"] as AmountCompat).to_float()
	_check("session_base_rate_nonzero", base_rate > 0.0, "got %s" % str(base_rate))
	var ok := _learn(content, session.state, "basic_meditation", 100.0)
	_check("session_effect_learn_ok", ok, "learn failed")
	var view: Dictionary = session.get_view()
	content.resources["lingli"]["rate"] = original_lingli_rate
	var resources: Dictionary = view.get("resources", {})
	var lingli: Dictionary = resources.get("lingli", {})
	var rate_serial: Variant = lingli.get("rate", "")
	var parsed: Dictionary = AmountCompat.try_parse(String(rate_serial))
	_check("session_view_rate_parses", bool(parsed.get("ok", false)), "rate %s" % str(rate_serial))
	_check("session_view_rate_has_multiplier", bool(parsed.get("ok", false)) and absf((parsed["value"] as AmountCompat).to_float() - base_rate * 1.1) < 0.001, "got %s" % str(rate_serial))
	if bool(parsed.get("ok", false)):
		var value: float = (parsed["value"] as AmountCompat).to_float()
		_check("session_view_rate_1_1x", absf(value - base_rate * 1.1) < 0.001, "got %s want %s" % [str(value), str(base_rate * 1.1)])
	var buildings: Dictionary = view.get("buildings", {})
	_check("session_view_buildings_serializable", not buildings.is_empty(), "empty buildings")

func _test_bad_effect_schema_rejected() -> void:
	var tmp_path := "user://m3b_skill_effect_bad.json"
	var raw := [
		{"id": "bad_skill", "name_key": "壞技能", "max_level": 1, "cost": {"skill_point": 10}, "effect": {"type": "", "amount": 1.0}},
	]
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(raw))
	file.close()
	var errors: Array = []
	var resource_ids := {"skill_point": true}
	var defs: Array = ContentSchema.validate_skills(raw, resource_ids, errors)
	_check("bad_effect_type_rejected", defs.is_empty() and errors.size() > 0, "errors %s" % str(errors))
	var raw2 := [
		{"id": "good_skill", "name_key": "好技能", "max_level": 1, "cost": {"skill_point": 10}, "effect": {"type": "lingli_rate", "amount": 2.0}},
	]
	var errors2: Array = []
	var defs2: Array = ContentSchema.validate_skills(raw2, resource_ids, errors2)
	_check("good_effect_accepted", defs2.size() == 1 and errors2.is_empty(), "errors %s" % str(errors2))
	if defs2.size() == 1:
		var effect: Variant = defs2[0].get("effect", null)
		_check("good_effect_roundtrip", effect is Dictionary and String(effect.get("type", "")) == "lingli_rate" and absf(float(effect.get("amount", 0.0)) - 2.0) < 0.0001, "got %s" % str(effect))
	DirAccess.remove_absolute(tmp_path)
