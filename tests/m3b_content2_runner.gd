extends SceneTree

const ERA2_RESOURCE_IDS := ["skill_point", "spirit_rice", "refined_iron", "beast_hide_low", "beast_bone_low", "beast_crystal_low", "bronze_essence", "monster_core_low", "liquid"]
const ERA2_BUILDING_IDS := ["iron_mine", "hunter_camp", "rice_field", "library", "scripture_hall", "stone_mine_mid", "storage_lingli_mid", "storage_stone_mid", "storage_money_mid", "storage_wood_mid", "storage_herb_mid"]
const GRANT_AMOUNTS := {"lingli": 100000.0, "money": 50000.0, "wood": 10000.0, "stone_low": 5000.0, "spirit_grass_low": 1000.0, "black_copper": 500.0}

var failures: Array[String] = []

func _init() -> void:
	print("[RUNNING] tests/m3b_content2_runner.gd")
	var loaded: Dictionary = ContentLoader.load_directory("res://content")
	if not bool(loaded.get("ok", false)):
		print("FAIL load_production_content ContentLoader.load_directory: %s" % str(loaded.get("errors", [])))
		print("RESULT: FAIL (1 failures)")
		quit(1)
		return
	var content: GameContent = loaded["content"]
	_test_load_production_content(content)
	_test_era2_parities(content)
	_test_era2_resource_defs(content)
	_test_era2_building_defs(content)
	_test_recipes_exact(content)
	_test_skills_exact(content)
	_test_reconcile_legacy_save(content)
	_test_unlock_sweep_gates(content)
	_test_breakthrough_economy_chain(content)
	_test_content_version_determinism()
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

func _int_set(values: Array) -> Dictionary:
	var set := {}
	for value in values:
		set[int(value)] = true
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

func _resource_unlock_ids(events: Array) -> Dictionary:
	var ids := {}
	for event in events:
		if String(event.get("kind", "")) == "resource_unlocked":
			ids[String(event.get("resource_id", ""))] = true
	return ids

func _event_kinds(events: Array) -> Dictionary:
	var kinds := {}
	for event in events:
		kinds[String(event.get("kind", ""))] = true
	return kinds

func _test_load_production_content(content: GameContent) -> void:
	_check("content_version_non_empty", not content.content_version.is_empty(), "content_version is empty")
	var era_set := _int_set(content.era_ids)
	_check("era_ids_are_1_2", era_set == {1: true, 2: true}, "got %s" % str(era_set))
	_check("building_count_21", content.building_ids.size() == 21, "got %d" % content.building_ids.size())
	_check("resource_count_16", content.resource_ids.size() == 16, "got %d" % content.resource_ids.size())
	var expected_resources := {}
	for id in ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low", "foundation_pill"]:
		expected_resources[id] = true
	for id in ERA2_RESOURCE_IDS:
		expected_resources[id] = true
	var resource_set := _string_set(content.resource_ids)
	_check("resource_ids_exact_set", resource_set == expected_resources, "got %s" % str(resource_set))
	var recipe_set := _string_set(content.recipe_ids)
	var expected_recipes := {"craft_bronze_essence": true, "craft_liquid": true, "craft_monster_core_low": true}
	_check("recipe_ids_exact", recipe_set == expected_recipes, "got %s" % str(recipe_set))
	_check("skill_count_6", content.skill_ids.size() == 6, "got %d" % content.skill_ids.size())
	var expected_skills := {"basic_meditation": true, "foundation_building": true, "qi_storage_1": true, "body_strengthening_1": true, "building_mastery_1": true, "qi_condensation": true}
	var skill_set := _string_set(content.skill_ids)
	_check("skill_ids_exact", skill_set == expected_skills, "got %s" % str(skill_set))

func _test_era2_parities(content: GameContent) -> void:
	var era2: Dictionary = content.eras[2]
	_check("era2_name", String(era2.get("name", "")) == "築基期", "got %s" % str(era2.get("name", "")))
	_check("era2_max_level", int(era2.get("max_level", 0)) == 10, "got %s" % str(era2.get("max_level")))
	_check("era2_resource_multiplier", float(era2.get("resource_multiplier", -1.0)) == 1.5, "got %s" % str(era2.get("resource_multiplier")))
	_check("era2_lifespan", float(era2.get("lifespan", -1.0)) == 120.0, "got %s" % str(era2.get("lifespan")))
	var level_up: Dictionary = era2.get("level_up_requirements", {})
	_check("era2_base_time", float(level_up.get("base_time", -1.0)) == 120.0, "got %s" % str(level_up.get("base_time")))
	_check("era2_time_multiplier", float(level_up.get("time_multiplier", -1.0)) == 1.18, "got %s" % str(level_up.get("time_multiplier")))
	var level_resources: Dictionary = level_up.get("resources", {})
	_check("era2_level_up_resources", level_resources == {"lingli": 500.0, "money": 100.0, "stone_low": 50.0}, "got %s" % str(level_resources))
	var upgrade: Dictionary = era2.get("upgrade_requirements", {})
	_check("era2_upgrade_level", float(upgrade.get("level", -1.0)) == 10.0, "got %s" % str(upgrade.get("level")))
	var capacity: Dictionary = upgrade.get("capacity", {})
	_check("era2_upgrade_capacity_stripped_keys", capacity == {"lingli": 2000.0, "stone_low": 1000.0}, "got %s" % str(capacity))

func _test_era2_resource_defs(content: GameContent) -> void:
	var type_expected := {"skill_point": "basic", "beast_crystal_low": "basic", "bronze_essence": "crafted", "monster_core_low": "crafted", "liquid": "crafted"}
	var max_expected := {"skill_point": 200.0, "refined_iron": 300.0, "beast_hide_low": 100.0, "beast_bone_low": 100.0, "spirit_rice": 200.0, "beast_crystal_low": 80.0, "bronze_essence": 100.0, "monster_core_low": 150.0, "liquid": 1000.0}
	var unlocked_false_count := 0
	for id in ERA2_RESOURCE_IDS:
		var def_variant: Variant = content.resources.get(id)
		if def_variant == null:
			_check("era2_resource_exists_%s" % id, false, "missing resource def")
			continue
		var def: Dictionary = def_variant
		_check("era2_resource_max_%s" % id, float(def.get("max", -1.0)) == float(max_expected[id]), "got %s" % str(def.get("max")))
		_check("era2_resource_rate_%s" % id, float(def.get("rate", -1.0)) == 0.0, "got %s" % str(def.get("rate")))
		if type_expected.has(id):
			_check("era2_resource_type_%s" % id, String(def.get("type", "")) == String(type_expected[id]), "got %s" % str(def.get("type")))
		if not bool(def.get("unlocked", true)):
			unlocked_false_count += 1
	_note("era2 resource defs unlocked==false for %d/9 (informational)" % unlocked_false_count)

func _test_era2_building_defs(content: GameContent) -> void:
	var building_expectations := [
		{"id": "iron_mine", "cf": 1.5, "maxlvl": 100, "prereq": {"building": "hunter_camp", "level": 1}, "base_cost": {"wood": 15.0, "money": 15.0, "beast_bone_low": 10.0}, "effects": {"refined_iron": 0.05}, "weight": 0.3},
		{"id": "hunter_camp", "cf": 1.7, "maxlvl": 100, "prereq": {"building": "forest_farm", "level": 3}, "base_cost": {"wood": 30.0, "money": 20.0}, "effects": {"beast_hide_low": 0.03, "beast_bone_low": 0.03}, "weight": 0.05},
		{"id": "rice_field", "cf": 1.8, "maxlvl": 100, "prereq": {"building": "iron_mine", "level": 2}, "base_cost": {"stone_low": 15.0, "wood": 25.0}, "effects": {"spirit_rice": 0.08}, "weight": 0.1},
		{"id": "library", "cf": 1.8, "maxlvl": 100, "prereq": null, "base_cost": {"money": 500.0, "wood": 200.0, "stone_low": 50.0, "spirit_grass_low": 20.0}, "effects": {"skill_point": 6.0, "lingli": 1.23}, "weight": 0.0},
		{"id": "scripture_hall", "cf": 1.8, "maxlvl": 100, "prereq": {"building": "library", "level": 1}, "base_cost": {"money": 500.0, "wood": 500.0, "stone_low": 300.0, "bronze_essence": 5.0}, "effects": {"skill_point_max": 6000.0}, "weight": null},
		{"id": "stone_mine_mid", "cf": 1.8, "maxlvl": 100, "prereq": {"building": "stone_mine", "level": 1}, "base_cost": {"money": 1000.0, "stone_low": 150.0, "refined_iron": 50.0, "beast_bone_low": 20.0}, "effects": {"stone_low": 0.5}, "weight": 1.0},
		{"id": "storage_lingli_mid", "cf": 1.1, "maxlvl": 50, "prereq": {"building": "storage_lingli", "level": 1}, "base_cost": {"money": 500.0, "stone_low": 50.0}, "effects": {"lingli_max": 50000.0}, "weight": null},
		{"id": "storage_stone_mid", "cf": 1.1, "maxlvl": 50, "prereq": {"building": "storage_stone", "level": 1}, "base_cost": {"money": 400.0, "stone_low": 50.0}, "effects": {"stone_low_max": 2500.0}, "weight": null},
		{"id": "storage_money_mid", "cf": 1.35, "maxlvl": 50, "prereq": {"building": "storage_money", "level": 1}, "base_cost": {"money": 500.0, "wood": 100.0}, "effects": {"money_max": 5000.0}, "weight": null},
		{"id": "storage_wood_mid", "cf": 1.35, "maxlvl": 50, "prereq": {"building": "storage_wood", "level": 1}, "base_cost": {"money": 300.0, "wood": 100.0}, "effects": {"wood_max": 2000.0}, "weight": null},
		{"id": "storage_herb_mid", "cf": 1.35, "maxlvl": 50, "prereq": {"building": "storage_herb", "level": 1}, "base_cost": {"money": 400.0, "wood": 150.0}, "effects": {"spirit_grass_low_max": 1000.0}, "weight": null},
	]
	for expectation in building_expectations:
		var id := String(expectation["id"])
		var def_variant: Variant = content.buildings.get(id)
		if def_variant == null:
			_check("era2_building_exists_%s" % id, false, "missing building def")
			continue
		var def: Dictionary = def_variant
		_check("era2_building_era_%s" % id, int(def.get("era", 0)) == 2, "got %s" % str(def.get("era")))
		_check("era2_building_max_level_%s" % id, int(def.get("max_level", 0)) == int(expectation["maxlvl"]), "got %s" % str(def.get("max_level")))
		_check("era2_building_cost_factor_%s" % id, float(def.get("cost_factor", -1.0)) == float(expectation["cf"]), "got %s" % str(def.get("cost_factor")))
		_check("era2_building_base_cost_%s" % id, def.get("base_cost", {}) == expectation["base_cost"], "got %s" % str(def.get("base_cost")))
		_check("era2_building_prereq_%s" % id, def.get("prereq") == expectation["prereq"], "got %s" % str(def.get("prereq")))
		_check("era2_building_effects_%s" % id, def.get("effects", {}) == expectation["effects"], "got %s" % str(def.get("effects")))
		var weight: Variant = expectation["weight"]
		if weight == null:
			_check("era2_building_weight_%s" % id, def.get("effect_weight") == null, "got %s" % str(def.get("effect_weight")))
		else:
			_check("era2_building_weight_%s" % id, def.get("effect_weight") != null and float(def.get("effect_weight")) == float(weight), "got %s" % str(def.get("effect_weight")))

func _test_recipes_exact(content: GameContent) -> void:
	var recipe_expectations := {
		"craft_bronze_essence": {"inputs": {"black_copper": 10.0, "stone_low": 5.0}, "output": {"resource_id": "bronze_essence", "amount": 1.0}},
		"craft_liquid": {"inputs": {"spirit_grass_low": 5.0, "lingli": 50.0}, "output": {"resource_id": "liquid", "amount": 1.0}},
		"craft_monster_core_low": {"inputs": {"beast_crystal_low": 2.0, "spirit_grass_low": 2.0}, "output": {"resource_id": "monster_core_low", "amount": 1.0}},
	}
	for id in recipe_expectations:
		var def_variant: Variant = content.recipes.get(id)
		if def_variant == null:
			_check("recipe_exists_%s" % id, false, "missing recipe def")
			continue
		var def: Dictionary = def_variant
		var expected: Dictionary = recipe_expectations[id]
		_check("recipe_inputs_%s" % id, def.get("inputs", {}) == expected["inputs"], "got %s" % str(def.get("inputs")))
		_check("recipe_output_%s" % id, def.get("output", {}) == expected["output"], "got %s" % str(def.get("output")))
		_check("recipe_unlock_skill_%s" % id, def.get("unlock_skill") == null, "got %s" % str(def.get("unlock_skill")))
		var requirements: Array = def.get("requirements", [])
		_check("recipe_requirements_empty_%s" % id, requirements.is_empty(), "got %s" % str(requirements))

func _test_skills_exact(content: GameContent) -> void:
	var skill_expectations := {
		"basic_meditation": [5, 90.0],
		"foundation_building": [5, 3600.0],
		"qi_storage_1": [1, 120.0],
		"body_strengthening_1": [1, 1000.0],
		"building_mastery_1": [1, 200.0],
		"qi_condensation": [5, 1800.0],
	}
	for id in skill_expectations:
		var def_variant: Variant = content.skills.get(id)
		if def_variant == null:
			_check("skill_exists_%s" % id, false, "missing skill def")
			continue
		var def: Dictionary = def_variant
		var expected: Array = skill_expectations[id]
		_check("skill_max_level_%s" % id, int(def.get("max_level", 0)) == int(expected[0]), "got %s" % str(def.get("max_level")))
		_check("skill_cost_%s" % id, def.get("cost", {}) == {"skill_point": float(expected[1])}, "got %s" % str(def.get("cost")))
		_check("skill_cost_resource_%s" % id, String(def.get("cost_resource", "")) == "skill_point", "got %s" % str(def.get("cost_resource")))

func _test_reconcile_legacy_save(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 1
	state.resources["lingli"] = {"value": AmountCompat.from_number(5.0), "unlocked": true, "ever_obtained": true}
	state.buildings["hut"] = 2
	var result: Dictionary = ContentReconciliation.reconcile(state, content)
	_check("reconcile_ok", bool(result.get("ok", false)), "got %s" % str(result.get("error", "")))
	var report: Dictionary = result.get("report", {})
	var missing_set := _string_set(report.get("missing_resources_added", []))
	var expected_missing := {}
	for id in content.resource_ids:
		if String(id) != "lingli":
			expected_missing[String(id)] = true
	_check("reconcile_missing_resources_exact", missing_set == expected_missing, "got %s" % str(missing_set))
	_check("reconcile_missing_skill_point", missing_set.has("skill_point"), "missing skill_point")
	_check("reconcile_missing_spirit_rice", missing_set.has("spirit_rice"), "missing spirit_rice")
	_check("reconcile_missing_refined_iron", missing_set.has("refined_iron"), "missing refined_iron")
	_check("reconcile_missing_bronze_essence", missing_set.has("bronze_essence"), "missing bronze_essence")
	_check("reconcile_missing_liquid", missing_set.has("liquid"), "missing liquid")
	var era2_entries_locked := true
	for id in ERA2_RESOURCE_IDS:
		var entry: Dictionary = state.resources[id]
		if bool(entry.get("unlocked", true)):
			era2_entries_locked = false
	_check("reconcile_era2_entries_locked", era2_entries_locked, "some era2 entries unlocked after reconcile")
	_check("reconcile_lingli_keeps_unlocked", bool(state.resources["lingli"]["unlocked"]) == true, "got %s" % str(state.resources["lingli"]["unlocked"]))
	var missing_building_set := _string_set(report.get("missing_buildings_added", []))
	var era2_buildings_missing := true
	for id in ERA2_BUILDING_IDS:
		if not missing_building_set.has(id):
			era2_buildings_missing = false
	_check("reconcile_missing_buildings_era2", era2_buildings_missing, "got %s" % str(missing_building_set))
	_check("reconcile_missing_buildings_has_library", missing_building_set.has("library"), "missing library")
	var missing_skills: Array = report.get("missing_skills_added", [])
	_check("reconcile_missing_skills_6", missing_skills.size() == 6, "got %d" % missing_skills.size())
	_check("reconcile_content_version", not String(report.get("content_version", "")).is_empty(), "content_version empty")

func _test_unlock_sweep_gates(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 1
	state.level = 1
	state.onboarding_version = Onboarding.SCHEMA_VERSION
	ContentReconciliation.reconcile(state, content)
	state.buildings["library"] = 1
	var sweep_a: Dictionary = ContentReconciliation.unlock_eligible_resources(state, content)
	_check("sweep_case_a_ok", bool(sweep_a.get("ok", false)), "got %s" % str(sweep_a.get("errors", [])))
	var unlocked_a: Array = sweep_a.get("unlocked", [])
	_check("sweep_case_a_no_skill_point_era1", not unlocked_a.has("skill_point"), "got %s" % str(unlocked_a))
	_check("sweep_case_a_skill_point_locked", bool(state.resources["skill_point"]["unlocked"]) == false, "got %s" % str(state.resources["skill_point"]["unlocked"]))

	state = _new_reconciled_state(content, 2)
	state.buildings["library"] = 1
	var sweep_b: Dictionary = ContentReconciliation.unlock_eligible_resources(state, content)
	_check("sweep_case_b_ok", bool(sweep_b.get("ok", false)), "got %s" % str(sweep_b.get("errors", [])))
	var unlocked_b: Array = sweep_b.get("unlocked", [])
	_check("sweep_case_b_skill_point_unlocked", unlocked_b.has("skill_point"), "got %s" % str(unlocked_b))
	_check("sweep_case_b_skill_point_entry", bool(state.resources["skill_point"]["unlocked"]) == true, "got %s" % str(state.resources["skill_point"]["unlocked"]))

	var state_c := _new_reconciled_state(content, 2)
	state_c.buildings["library"] = 1
	var sweep_c1: Dictionary = ContentReconciliation.unlock_eligible_resources(state_c, content)
	var unlocked_c1: Array = sweep_c1.get("unlocked", [])
	_check("sweep_case_c_no_refined_iron", not unlocked_c1.has("refined_iron"), "got %s" % str(unlocked_c1))
	_check("sweep_case_c_refined_iron_locked", bool(state_c.resources["refined_iron"]["unlocked"]) == false, "got %s" % str(state_c.resources["refined_iron"]["unlocked"]))
	state_c.buildings["iron_mine"] = 1
	var sweep_c2: Dictionary = ContentReconciliation.unlock_eligible_resources(state_c, content)
	var unlocked_c2: Array = sweep_c2.get("unlocked", [])
	_check("sweep_case_c_refined_iron_unlocked", unlocked_c2.has("refined_iron"), "got %s" % str(unlocked_c2))
	_check("sweep_case_c_refined_iron_entry", bool(state_c.resources["refined_iron"]["unlocked"]) == true, "got %s" % str(state_c.resources["refined_iron"]["unlocked"]))

	var state_d := _new_reconciled_state(content, 2)
	state_d.buildings["hunter_camp"] = 1
	var sweep_d: Dictionary = ContentReconciliation.unlock_eligible_resources(state_d, content)
	var unlocked_d: Array = sweep_d.get("unlocked", [])
	_check("sweep_case_d_beast_hide_low", unlocked_d.has("beast_hide_low"), "got %s" % str(unlocked_d))
	_check("sweep_case_d_beast_bone_low", unlocked_d.has("beast_bone_low"), "got %s" % str(unlocked_d))

	var state_e := _new_reconciled_state(content, 2)
	var sweep_e1: Dictionary = ContentReconciliation.unlock_eligible_resources(state_e, content)
	var unlocked_e1: Array = sweep_e1.get("unlocked", [])
	_check("sweep_case_e_no_spirit_rice", not unlocked_e1.has("spirit_rice"), "got %s" % str(unlocked_e1))
	state_e.buildings["rice_field"] = 1
	var sweep_e2: Dictionary = ContentReconciliation.unlock_eligible_resources(state_e, content)
	var unlocked_e2: Array = sweep_e2.get("unlocked", [])
	_check("sweep_case_e_spirit_rice_unlocked", unlocked_e2.has("spirit_rice"), "got %s" % str(unlocked_e2))

	var state_f := _new_reconciled_state(content, 2)
	var sweep_f: Dictionary = ContentReconciliation.unlock_eligible_resources(state_f, content)
	var unlocked_f: Array = sweep_f.get("unlocked", [])
	_check("sweep_case_f_bronze_essence", unlocked_f.has("bronze_essence"), "got %s" % str(unlocked_f))
	_check("sweep_case_f_liquid", unlocked_f.has("liquid"), "got %s" % str(unlocked_f))
	_check("sweep_case_f_beast_crystal_locked", not unlocked_f.has("beast_crystal_low"), "got %s" % str(unlocked_f))
	_check("sweep_case_f_monster_core_locked", not unlocked_f.has("monster_core_low"), "got %s" % str(unlocked_f))

	var state_g := _new_reconciled_state(content, 2)
	var sweep_g1: Dictionary = ContentReconciliation.unlock_eligible_resources(state_g, content)
	var unlocked_g1: Array = sweep_g1.get("unlocked", [])
	_check("sweep_case_g_no_monster_core", not unlocked_g1.has("monster_core_low"), "got %s" % str(unlocked_g1))
	var beast_crystal_entry: Dictionary = state_g.resources["beast_crystal_low"]
	beast_crystal_entry["ever_obtained"] = true
	var sweep_g2: Dictionary = ContentReconciliation.unlock_eligible_resources(state_g, content)
	var unlocked_g2: Array = sweep_g2.get("unlocked", [])
	_check("sweep_case_g_monster_core_unlocked", unlocked_g2.has("monster_core_low"), "got %s" % str(unlocked_g2))

	var state_h := _new_reconciled_state(content, 2)
	state_h.buildings["library"] = 1
	var skill_point_entry: Dictionary = state_h.resources["skill_point"]
	skill_point_entry["unlocked"] = true
	var sweep_h1: Dictionary = ContentReconciliation.unlock_eligible_resources(state_h, content)
	var unlocked_h1: Array = sweep_h1.get("unlocked", [])
	_check("sweep_case_h_no_duplicate", not unlocked_h1.has("skill_point"), "got %s" % str(unlocked_h1))
	var sweep_h2: Dictionary = ContentReconciliation.unlock_eligible_resources(state_h, content)
	var unlocked_h2: Array = sweep_h2.get("unlocked", [])
	_check("sweep_case_h_idempotent", unlocked_h2.is_empty(), "got %s" % str(unlocked_h2))

func _test_breakthrough_economy_chain(content: GameContent) -> void:
	var state := _new_reconciled_state(content, 1)
	var targets := [
		{"id": "hut", "to": 2},
		{"id": "wooden_house", "to": 10},
		{"id": "forest_farm", "to": 3},
		{"id": "stone_mine", "to": 3},
		{"id": "herb_farm", "to": 3},
		{"id": "storage_lingli", "to": 5},
		{"id": "storage_stone", "to": 5},
	]
	for target in targets:
		var building_id := String(target["id"])
		var target_level := int(target["to"])
		while int(state.buildings.get(building_id, 0)) < target_level:
			_grant_all(state, GRANT_AMOUNTS)
			var next_level := int(state.buildings.get(building_id, 0)) + 1
			var command_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "upgrade_building", "expected_revision": state.revision, "payload": {"building_id": building_id}})
			state.revision += 1
			if not bool(command_result.get("ok", false)):
				_check("chain_upgrade_%s_to_%d" % [building_id, next_level], false, "%s %s" % [String(command_result.get("error", "")), str(command_result.get("detail", {}))])
				break
	_check("chain_hut_2", int(state.buildings.get("hut", 0)) == 2, "got %d" % int(state.buildings.get("hut", 0)))
	_check("chain_wooden_house_10", int(state.buildings.get("wooden_house", 0)) == 10, "got %d" % int(state.buildings.get("wooden_house", 0)))
	_check("chain_forest_farm_3", int(state.buildings.get("forest_farm", 0)) == 3, "got %d" % int(state.buildings.get("forest_farm", 0)))
	_check("chain_stone_mine_3", int(state.buildings.get("stone_mine", 0)) == 3, "got %d" % int(state.buildings.get("stone_mine", 0)))
	_check("chain_herb_farm_3", int(state.buildings.get("herb_farm", 0)) == 3, "got %d" % int(state.buildings.get("herb_farm", 0)))
	_check("chain_storage_lingli_5", int(state.buildings.get("storage_lingli", 0)) == 5, "got %d" % int(state.buildings.get("storage_lingli", 0)))
	_check("chain_storage_stone_5", int(state.buildings.get("storage_stone", 0)) == 5, "got %d" % int(state.buildings.get("storage_stone", 0)))
	var caps: Dictionary = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	_check("chain_lingli_cap_ge_500", caps["lingli"].to_float() >= 500.0, "got %s" % str(caps["lingli"].to_float()))
	var era1_def: Dictionary = content.era(1)
	var breakthrough_capacity: Dictionary = era1_def.get("upgrade_requirements", {}).get("capacity", {})
	_check("chain_breakthrough_req_capacity_stripped", breakthrough_capacity == {"lingli": 500.0}, "got %s" % str(breakthrough_capacity))
	while state.level < 10:
		_grant_all(state, GRANT_AMOUNTS)
		state.training_seconds = 100000.0
		var level_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "level_up_cultivation", "expected_revision": state.revision, "payload": {}})
		state.revision += 1
		if not bool(level_result.get("ok", false)):
			_check("chain_level_up_at_level_%d" % state.level, false, String(level_result.get("error", "")))
			break
	_check("chain_cultivation_level_10", state.level == 10, "got %d" % state.level)
	_grant_all(state, GRANT_AMOUNTS)
	var breakthrough_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "breakthrough_era", "expected_revision": state.revision, "payload": {}})
	state.revision += 1
	_check("chain_breakthrough_ok", bool(breakthrough_result.get("ok", false)), "%s %s" % [String(breakthrough_result.get("error", "")), str(breakthrough_result.get("detail", {}))])
	_check("chain_breakthrough_era_2", state.era_id == 2, "got %d" % state.era_id)
	for mid_target in [{"id": "storage_lingli_mid", "to": 1}, {"id": "storage_stone_mid", "to": 1}]:
		var mid_id := String(mid_target["id"])
		while int(state.buildings.get(mid_id, 0)) < int(mid_target["to"]):
			_grant_all(state, GRANT_AMOUNTS)
			var mid_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "upgrade_building", "expected_revision": state.revision, "payload": {"building_id": mid_id}})
			state.revision += 1
			if not bool(mid_result.get("ok", false)):
				_check("chain_upgrade_%s" % mid_id, false, "%s %s" % [String(mid_result.get("error", "")), str(mid_result.get("detail", {}))])
				break
	var era2_caps: Dictionary = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	var era2_upgrade: Dictionary = content.era(2).get("upgrade_requirements", {}).get("capacity", {})
	_check("chain_era2_upgrade_capacity_stripped", era2_upgrade == {"lingli": 2000.0, "stone_low": 1000.0}, "got %s" % str(era2_upgrade))
	_check("chain_era2_lingli_cap_ge_2000", era2_caps["lingli"].to_float() >= 2000.0, "got %s" % str(era2_caps["lingli"].to_float()))
	_check("chain_era2_stone_low_cap_ge_1000", era2_caps["stone_low"].to_float() >= 1000.0, "got %s" % str(era2_caps["stone_low"].to_float()))
	var breakthrough_events: Array = breakthrough_result.get("events", [])
	var breakthrough_kinds := _event_kinds(breakthrough_events)
	_check("chain_breakthrough_event_present", breakthrough_kinds.has("era_breakthrough"), "got %s" % str(breakthrough_events))
	_check("chain_breakthrough_unlock_sweep_event", breakthrough_kinds.has("resource_unlocked"), "got %s" % str(breakthrough_events))
	_grant_all(state, GRANT_AMOUNTS)
	var library_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "upgrade_building", "expected_revision": state.revision, "payload": {"building_id": "library"}})
	state.revision += 1
	_check("chain_library_ok", bool(library_result.get("ok", false)), "%s %s" % [String(library_result.get("error", "")), str(library_result.get("detail", {}))])
	var library_unlocks := _resource_unlock_ids(library_result.get("events", []))
	_check("chain_library_skill_point_event", library_unlocks.has("skill_point"), "got %s" % str(library_unlocks))
	_grant_all(state, GRANT_AMOUNTS)
	var hunter_camp_result: Dictionary = CommandProcessor.apply(content, state, {"command_id": "m3b2_e2e", "type": "upgrade_building", "expected_revision": state.revision, "payload": {"building_id": "hunter_camp"}})
	state.revision += 1
	_check("chain_hunter_camp_ok", bool(hunter_camp_result.get("ok", false)), "%s %s" % [String(hunter_camp_result.get("error", "")), str(hunter_camp_result.get("detail", {}))])
	var hunter_camp_unlocks := _resource_unlock_ids(hunter_camp_result.get("events", []))
	_check("chain_hunter_camp_beast_hide_event", hunter_camp_unlocks.has("beast_hide_low"), "got %s" % str(hunter_camp_unlocks))
	_check("chain_hunter_camp_beast_bone_event", hunter_camp_unlocks.has("beast_bone_low"), "got %s" % str(hunter_camp_unlocks))

func _test_content_version_determinism() -> void:
	var first: Dictionary = ContentLoader.load_directory("res://content")
	var second: Dictionary = ContentLoader.load_directory("res://content")
	_check("determinism_second_load_ok", bool(second.get("ok", false)), "got %s" % str(second.get("errors", [])))
	var first_version := ""
	var second_version := ""
	if bool(first.get("ok", false)):
		var first_content: GameContent = first["content"]
		first_version = String(first_content.content_version)
	if bool(second.get("ok", false)):
		var second_content: GameContent = second["content"]
		second_version = String(second_content.content_version)
	_check("content_version_deterministic", first_version == second_version and not first_version.is_empty(), "got '%s' vs '%s'" % [first_version, second_version])
