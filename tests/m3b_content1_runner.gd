extends SceneTree

const FIXTURE_DIR := "res://tests/fixtures/content1"

var failures: Array[String] = []

func _init() -> void:
	print("[RUNNING] tests/m3b_content1_runner.gd")
	var loaded := ContentLoader.load_directory(FIXTURE_DIR)
	if not bool(loaded.get("ok", false)):
		failures.append("Content load failed: %s" % str(loaded.get("errors", [])))
		_finish()
		return
	var content: GameContent = loaded["content"]
	var raw_resources: Array = _parse_file("resources/era1.json")
	var raw_buildings: Array = _parse_file("buildings/era1.json")
	var raw_eras: Array = []
	if not raw_resources.is_empty():
		_test_manifest_with_new_files(content)
		_test_hash_sensitivity(content, raw_resources, raw_buildings)
		_test_validation_gaps(content)
		_test_reconciliation_rules(content)
		_test_zero_fill_no_unlock(content)
		_test_status_matrix(content)
		_test_alchemy_no_double_grant_and_capacity(content)
		_test_snapshot_roundtrip(content)
		_test_save_manager_reconciliation(content)
	else:
		failures.append("fixture resources file could not be parsed")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PASS: M3-B-CONTENT1 content contracts, reconciliation, progression and unified inventory.")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _expect_equal(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

func _parse_file(relative_path: String) -> Array:
	var text := FileAccess.get_file_as_string(FIXTURE_DIR.path_join(relative_path))
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	return []

func _test_manifest_with_new_files(content: GameContent) -> void:
	_expect(content.recipe_ids.has("copper_refine"), "content has recipe copper_refine")
	_expect(content.skill_ids.has("basic_breathing"), "content has skill basic_breathing")
	_expect(content.consumable_ids.has("copper_refine"), "content has consumable copper_refine")
	_expect(not content.content_version.is_empty(), "content_version is non-empty")

func _test_hash_sensitivity(content: GameContent, raw_resources: Array, raw_buildings: Array) -> void:
	var recipes_v1: Array = _parse_file("recipes/recipes.json")
	var consumables_raw: Array = _parse_file("consumables/consumables.json")
	var skills_raw: Array = _parse_file("skills/skills.json")
	_expect(not recipes_v1.is_empty() and not skills_raw.is_empty(), "fixture recipe/skill arrays parsed")
	var base_result := ContentLoader.build_content(raw_resources, raw_buildings, _parse_file("eras/era1.json") + _parse_file("eras/era2.json"), recipes_v1.duplicate(true), consumables_raw.duplicate(true), skills_raw.duplicate(true))
	_expect(bool(base_result.get("ok", false)), "build_content base ok: %s" % str(base_result.get("errors", [])))
	var version1 := String(base_result.get("content", GameContent.new()).content_version)
	var recipes_added: Array = recipes_v1.duplicate(true)
	recipes_added.append({"id": "extra_recipe", "inputs": {"black_copper": 1.0}, "output": {"resource_id": "copper_refine", "amount": 1.0}, "requirements": [], "unlock_skill": null})
	var result2 := ContentLoader.build_content(raw_resources, raw_buildings, _parse_file("eras/era1.json") + _parse_file("eras/era2.json"), recipes_added, consumables_raw.duplicate(true), skills_raw.duplicate(true))
	_expect(bool(result2.get("ok", false)), "build_content v2 ok: %s" % str(result2.get("errors", [])))
	var resources_edited: Array = raw_resources.duplicate(true)
	for entry in resources_edited:
		if String(entry.get("id", "")) == "spirit_grass_low":
			entry["display_order"] = 7
	var result3 := ContentLoader.build_content(resources_edited, raw_buildings, _parse_file("eras/era1.json") + _parse_file("eras/era2.json"), recipes_v1.duplicate(true), consumables_raw.duplicate(true), skills_raw.duplicate(true))
	_expect(bool(result3.get("ok", false)), "build_content v3 ok: %s" % str(result3.get("errors", [])))
	var version1b := String(result3.get("content", GameContent.new()).content_version)
	_expect(version1 != version1b, "content_version differs when resource display_order changed")

func _test_validation_gaps(content: GameContent) -> void:
	var rid_set := {}
	for resource_id in content.resource_ids:
		rid_set[resource_id] = true
	var sid_set := {}
	for skill_id in content.skill_ids:
		sid_set[skill_id] = true
	var errors: Array = []
	var recipes_v1: Array = _parse_file("recipes/recipes.json")
	recipes_v1.append({"id": "bad_recipe", "inputs": {"fake_res": 1.0}, "output": {"resource_id": "lingli", "amount": 1.0}, "requirements": [], "unlock_skill": null})
	var validated: Array = ContentSchema.validate_recipes(recipes_v1, rid_set, sid_set, errors)
	_expect(not errors.is_empty(), "recipe unknown resource appends error")
	var has_bad_recipe := false
	for def in validated:
		if String(def.get("id", "")) == "bad_recipe":
			has_bad_recipe = true
	_expect(not has_bad_recipe, "bad recipe not in validated output")

	errors = []
	var recipes_zero: Array = [{"id": "zero_out", "inputs": {"black_copper": 2.0}, "output": {"resource_id": "copper_refine", "amount": 0.0}, "requirements": [], "unlock_skill": null}]
	ContentSchema.validate_recipes(recipes_zero, rid_set, sid_set, errors)
	_expect(not errors.is_empty(), "recipe output amount 0 appends error")

	errors = []
	var consumables_bad_key: Array = [{"resource_id": "copper_refine", "consume_requirements": [], "effects": {"hp_boost": 1.0}, "lifetime_policy": "permanent_this_life"}]
	ContentSchema.validate_consumables(consumables_bad_key, rid_set, errors)
	_expect(not errors.is_empty(), "consumable unsupported effect key appends error")

	errors = []
	var consumables_bad_value: Array = [{"resource_id": "copper_refine", "consume_requirements": [], "effects": {"instant_training_seconds": "30"}, "lifetime_policy": "permanent_this_life"}]
	ContentSchema.validate_consumables(consumables_bad_value, rid_set, errors)
	_expect(not errors.is_empty(), "consumable effect value string appends error")

	errors = []
	var recipes_empty_inputs: Array = [{"id": "empty_inputs_recipe", "inputs": {}, "output": {"resource_id": "lingli", "amount": 1.0}, "requirements": [], "unlock_skill": null}]
	ContentSchema.validate_recipes(recipes_empty_inputs, rid_set, sid_set, errors)
	_expect(not errors.is_empty(), "recipe empty inputs appends error")

	errors = []
	ContentSchema.validate_requirement_shapes([{"type": "karma", "level": 1}], "test_req", errors)
	_expect(not errors.is_empty(), "unknown requirement type rejected")

func _test_reconciliation_rules(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 1
	state.resources["lingli"] = {"value": AmountCompat.from_number(10.0), "unlocked": true, "ever_obtained": true}
	state.resources["foundation_pill"] = {"value": AmountCompat.from_number(5.0), "unlocked": true, "ever_obtained": true}
	state.buildings["hut"] = 2
	state.pills["foundation_pill"] = 3
	var result := ContentReconciliation.reconcile(state, content)
	_expect(bool(result.get("ok", false)), "reconcile ok: %s" % str(result.get("error", "")))
	var report: Dictionary = result.get("report", {})
	_expect_equal(state.resources["foundation_pill"].value.serialize(), "5", "foundation_pill resource value stays 5")
	_expect_equal(int(state.pills["foundation_pill"]), 0, "foundation_pill pills 0")
	var conflicts: Array = report.get("pills_conflicts", [])
	_expect(not conflicts.is_empty(), "pills_conflicts non-empty")
	_expect_equal(String(conflicts[0].get("resolution", "")), "kept_resource_authority", "pill conflict resolution")
	_expect(report.get("missing_resources_added", []).has("beast_pelt"), "missing_resources_added has beast_pelt")
	_expect(not report.get("missing_resources_added", []).has("foundation_pill"), "missing_resources_added does not have foundation_pill")
	_expect(report.get("missing_buildings_added", []).has("library"), "missing_buildings_added has library")
	_expect_equal(state.resources["beast_pelt"]["unlocked"], false, "beast_pelt stays unlocked false")
	var result2 := ContentReconciliation.reconcile(state, content)
	var report2: Dictionary = result2.get("report", {})
	_expect(bool(result2.get("ok", false)), "second reconcile ok")
	_expect(report2.get("missing_resources_added", []).is_empty(), "second: missing_resources_added empty")
	_expect(report2.get("pills_migrated", []).is_empty(), "second: pills_migrated empty")
	_expect(report2.get("pills_conflicts", []).is_empty(), "second: pills_conflicts empty")

func _test_zero_fill_no_unlock(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 1
	state.resources["lingli"] = {"value": AmountCompat.from_number(10.0), "unlocked": true, "ever_obtained": true}
	var result := ContentReconciliation.reconcile(state, content)
	_expect(bool(result.get("ok", false)), "zero fill reconcile ok")
	_expect_equal(state.resources["lingli"].value.to_float(), 10.0, "lingli untouched value 10")
	_expect_equal(state.resources["lingli"]["unlocked"], true, "lingli unlocked true")
	_expect_equal(state.resources["beast_pelt"]["unlocked"], false, "beast_pelt zero-fill unlocked false")
	_expect_equal(state.resources["beast_pelt"]["ever_obtained"], false, "beast_pelt zero-fill ever_obtained false")
	_expect_equal(state.resources["beast_pelt"].value.to_float(), 0.0, "beast_pelt zero-fill value 0")

func _test_status_matrix(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 1
	state.buildings["hut"] = 1
	state.skills["basic_breathing"] = 1
	state.resources["lingli"] = {"value": AmountCompat.from_number(10.0), "unlocked": true, "ever_obtained": true}
	var hut_status := ProgressionEvaluator.building_status(state, content, "hut")
	_expect_equal(hut_status.get("status", ""), "owned", "building hut owned at era 1 lvl 1")
	var library_status_v1 := ProgressionEvaluator.building_status(state, content, "library")
	_expect_equal(library_status_v1.get("status", ""), "hidden", "library hidden at era 1")
	_expect_equal(library_status_v1.get("reason", ""), "REASON_ERA_NOT_REACHED", "library hidden reason")
	state.era_id = 2
	var library_status_v2 := ProgressionEvaluator.building_status(state, content, "library")
	_expect_equal(library_status_v2.get("status", ""), "available", "library available after era 2")
	var lingli_status := ProgressionEvaluator.resource_status(state, content, "lingli")
	_expect_equal(lingli_status.get("status", ""), "owned", "resource lingli owned")
	state.era_id = 1
	var beast_pelt_status_v1 := ProgressionEvaluator.resource_status(state, content, "beast_pelt")
	_expect_equal(beast_pelt_status_v1.get("reason", ""), "REASON_ERA_NOT_REACHED", "beast_pelt era 1 hidden")
	state.era_id = 2
	var beast_pelt_status_v2 := ProgressionEvaluator.resource_status(state, content, "beast_pelt")
	_expect_equal(beast_pelt_status_v2.get("status", ""), "available", "beast_pelt era 2 available")
	var met_result := ProgressionEvaluator.requirement_is_met(state, {"type": "era", "era": 2})
	_expect_equal(bool(met_result.get("met", true)), true, "era requirement met at era 2")
	state.era_id = 1
	met_result = ProgressionEvaluator.requirement_is_met(state, {"type": "era", "era": 2})
	_expect_equal(met_result.get("reason", ""), "REASON_ERA_NOT_REACHED", "era requirement reason")
	var unknown_req := ProgressionEvaluator.requirement_is_met(state, {"type": "karma", "level": 1})
	_expect_equal(unknown_req.get("reason", ""), "REASON_UNKNOWN_TYPE", "unknown requirement type reason")

func _test_alchemy_no_double_grant_and_capacity(content: GameContent) -> void:
	var state := GameState.new()
	state.era_id = 2
	state.resources["spirit_grass_low"] = {"value": AmountCompat.from_number(520000.0), "unlocked": true, "ever_obtained": true}
	state.resources["black_copper"] = {"value": AmountCompat.from_number(400000.0), "unlocked": true, "ever_obtained": true}
	state.resources["lingli"] = {"value": AmountCompat.from_number(990000.0), "unlocked": true, "ever_obtained": true}
	state.resources["foundation_pill"] = {"value": AmountCompat.from_number(0.0), "unlocked": true, "ever_obtained": false}
	var result := AlchemySystem.refine(state, "foundation_pill", 201)
	_expect(bool(result.get("ok", false)), "refine foundation_pill 201 ok: %s" % str(result.get("error", "")))
	_expect_equal(int(result.get("applied_count", 0)), 200, "applied_count 200")
	_expect_equal(state.resources["foundation_pill"].value.to_float(), 200.0, "foundation_pill value clamped 200")
	_expect_equal(state.resources["spirit_grass_low"].value.to_float(), 510000.0, "remaining spirit_grass_low 510000")
	_expect_equal(state.resources["black_copper"].value.to_float(), 396000.0, "remaining black_copper 396000")
	_expect_equal(state.resources["lingli"].value.to_float(), 950000.0, "remaining lingli 950000")
	var capacity_result := AlchemySystem.refine(state, "foundation_pill", 1)
	_expect_equal(String(capacity_result.get("error", "")), "CAPACITY_FULL", "refine at capacity rejected")
	_expect_equal(state.resources["foundation_pill"].value.to_float(), 200.0, "capacity refine leaves value 200")

func _test_snapshot_roundtrip(content: GameContent) -> void:
	var state := GameState.new()
	state.skills = {"basic_breathing": 2}
	state.learned_recipes = {"copper_refine": 1}
	var meta := {
		"save_id": "test",
		"saved_at_utc_ms": "0",
		"settled_until_utc_ms": "0",
		"sim_tick": "0",
		"rng_streams": {},
	}
	var enc := SaveCodec.encode(state, content.content_version, meta)
	_expect(bool(enc.get("ok", false)), "SaveCodec encode ok: %s" % str(enc.get("error", "")))
	var dec := SaveCodec.decode(String(enc.get("json", "")))
	_expect(bool(dec.get("ok", false)), "SaveCodec decode ok: %s" % str(dec.get("error", "")))
	var loaded_state: GameState = dec.get("state")
	_expect_equal(int(loaded_state.skills.get("basic_breathing", 0)), 2, "roundtrip skills")
	_expect_equal(int(loaded_state.learned_recipes.get("copper_refine", 0)), 1, "roundtrip learned_recipes")

func _test_save_manager_reconciliation(content: GameContent) -> void:
	SaveManager.reset_for_tests()
	SaveManager.configure(content, Content1MemoryAdapter.new())
	var legacy_state := GameState.new()
	legacy_state.era_id = 1
	legacy_state.revision = 5
	legacy_state.resources["lingli"] = {"value": AmountCompat.from_number(10.0), "unlocked": true, "ever_obtained": true}
	legacy_state.buildings["hut"] = 2
	legacy_state.pills["foundation_pill"] = 3
	var meta := {
		"save_id": "content1",
		"saved_at_utc_ms": "0",
		"settled_until_utc_ms": "0",
		"sim_tick": "0",
		"rng_streams": {},
	}
	var enc := SaveCodec.encode(legacy_state, content.content_version, meta)
	_expect(bool(enc.get("ok", false)), "legacy encode ok")
	var real_content_loaded := ContentLoader.load_directory("res://content")
	_expect(bool(real_content_loaded.get("ok", false)), "real content loads")
	var real_content: GameContent = real_content_loaded["content"]
	SaveManager.configure(real_content, Content1MemoryAdapter.new())
	SaveManager.adapter().write("save_main", String(enc["json"]))
	var loaded: GameState = SaveManager.load_state()
	_expect(loaded != null, "SaveManager load returns state")
	_expect(int(loaded.pills.get("foundation_pill", -1)) == 0, "manager loader migrates pills to zero")
	_expect(loaded.resources.has("foundation_pill"), "manager loader adds foundation_pill entry")
	_expect_equal(loaded.resources["foundation_pill"].value.to_float(), 3.0, "manager loader migrates pill count 3")
	_expect_equal(loaded.resources["lingli"].value.to_float(), 10.0, "manager load keeps lingli 10")
	_expect(loaded.resources.has("black_copper"), "manager loader zero-fills new content resource")
	_expect_equal(loaded.resources["black_copper"]["unlocked"], false, "zero-fill does not unlock")
	SaveManager.reset_for_tests()

class Content1MemoryAdapter extends StorageAdapter:
	var _key_data: Dictionary = {}
	func read(key: String) -> Dictionary:
		if not _key_data.has(key):
			return {"ok": false, "data": "", "error": "MISSING"}
		return {"ok": true, "data": String(_key_data[key]), "error": ""}
	func write(key: String, data: String) -> Dictionary:
		_key_data[key] = data
		return {"ok": true, "error": ""}
	func erase(key: String) -> Dictionary:
		_key_data.erase(key)
		return {"ok": true, "error": ""}
	func exists(key: String) -> bool:
		return _key_data.has(key)
	func backend_name() -> String:
		return "content1_memory"
	func is_persistent() -> bool:
		return false
