extends SceneTree

const CONTENT_DIR := "res://content"
const EPS := 0.000001

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	_expect(bool(loaded.ok), "content loads from %s" % CONTENT_DIR)
	if bool(loaded.ok):
		var content: GameContent = loaded.content
		_test_era1_graded_normalized(content.eras[1])
		_test_era2_graded_normalized(content.eras[2])
		_test_era_costs(content.eras[1], content.eras[2])
	_test_lv9_inline_behavior()
	_test_loader_rejections()
	print("%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("EARLY PACING 2 RUNNER DONE")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		quit(1)

func _test_era1_graded_normalized(era_def: Dictionary) -> void:
	var graded: Array = era_def["level_up_requirements"]["graded_resources"]
	_expect(graded is Array and graded.size() == 3, "era1 graded_resources has 3 entries")
	if graded.size() != 3:
		return
	var expected_from_levels := [3, 5, 7]
	for index in range(3):
		var entry: Dictionary = graded[index]
		_expect(int(entry["from_level"]) == int(expected_from_levels[index]), "era1 graded[%d] from_level %d" % [index, int(expected_from_levels[index])])
	_expect(graded[0]["resources"].size() == 1 and graded[0]["resources"].has("wood"), "era1 graded[0] wood only")
	_expect(_f(graded[0]["resources"]["wood"]) == 40.0, "era1 graded[0] wood 40")
	_expect(graded[1]["resources"].size() == 1 and graded[1]["resources"].has("stone_low"), "era1 graded[1] stone_low only")
	_expect(_f(graded[1]["resources"]["stone_low"]) == 40.0, "era1 graded[1] stone_low 40")
	_expect(graded[2]["resources"].size() == 1 and graded[2]["resources"].has("spirit_grass_low"), "era1 graded[2] spirit_grass_low only")
	_expect(_f(graded[2]["resources"]["spirit_grass_low"]) == 30.0, "era1 graded[2] spirit_grass_low 30")

func _test_era2_graded_normalized(era_def: Dictionary) -> void:
	var graded: Array = era_def["level_up_requirements"]["graded_resources"]
	_expect(graded is Array and graded.size() == 2, "era2 graded_resources has 2 entries")
	if graded.size() != 2:
		return
	_expect(int(graded[0]["from_level"]) == 1, "era2 graded[0] from_level 1")
	_expect(int(graded[1]["from_level"]) == 5, "era2 graded[1] from_level 5")
	var first: Dictionary = graded[0]["resources"]
	_expect(first.size() == 2 and first.has("spirit_timber") and first.has("bronze_essence"), "era2 graded[0] timber and bronze only")
	_expect(_f(first["spirit_timber"]) == 20.0, "era2 graded[0] spirit_timber 20")
	_expect(_f(first["bronze_essence"]) == 10.0, "era2 graded[0] bronze_essence 10")
	var second: Dictionary = graded[1]["resources"]
	_expect(second.size() == 1 and second.has("liquid"), "era2 graded[1] liquid only")
	_expect(_f(second["liquid"]) == 5.0, "era2 graded[1] liquid 5")

func _test_era_costs(era1_def: Dictionary, era2_def: Dictionary) -> void:
	var flat := _cost_as_floats(Cultivation.level_up_cost(era1_def, 2, 0.0))
	_expect(flat.size() == 1 and flat.has("lingli"), "era1 L2 cost keys only lingli")
	_expect_approx(flat.get("lingli", -1.0), 50.0, "era1 L2 lingli 50")
	var lvl3 := _cost_as_floats(Cultivation.level_up_cost(era1_def, 3, 0.0))
	_expect(lvl3.has("lingli") and lvl3.has("wood") and lvl3.size() == 2, "era1 L3 cost keys lingli and wood")
	_expect_approx(lvl3.get("lingli", -1.0), 50.0, "era1 L3 lingli 50")
	_expect_approx(lvl3.get("wood", -1.0), 40.0, "era1 L3 wood 40")
	var lvl9 := _cost_as_floats(Cultivation.level_up_cost(era1_def, 9, 0.0))
	_expect(lvl9.has("lingli") and lvl9.has("wood") and lvl9.has("stone_low") and lvl9.has("spirit_grass_low") and lvl9.size() == 4, "era1 L9 cost keys all graded")
	_expect_approx(lvl9.get("lingli", -1.0), 50.0, "era1 L9 lingli 50")
	_expect_approx(lvl9.get("wood", -1.0), 40.0, "era1 L9 wood 40")
	_expect_approx(lvl9.get("stone_low", -1.0), 40.0, "era1 L9 stone_low 40")
	_expect_approx(lvl9.get("spirit_grass_low", -1.0), 30.0, "era1 L9 spirit_grass_low 30")
	var era2_l1 := _cost_as_floats(Cultivation.level_up_cost(era2_def, 1, 0.0))
	_expect(era2_l1.has("lingli") and era2_l1.has("spirit_timber") and era2_l1.has("bronze_essence") and era2_l1.size() == 3, "era2 L1 cost keys")
	_expect_approx(era2_l1.get("lingli", -1.0), 200.0, "era2 L1 lingli 200")
	_expect_approx(era2_l1.get("spirit_timber", -1.0), 20.0, "era2 L1 spirit_timber 20")
	_expect_approx(era2_l1.get("bronze_essence", -1.0), 10.0, "era2 L1 bronze_essence 10")
	var era2_l5 := _cost_as_floats(Cultivation.level_up_cost(era2_def, 5, 0.0))
	_expect(era2_l5.has("liquid") and era2_l5.size() == 4, "era2 L5 adds liquid")
	_expect_approx(era2_l5.get("liquid", -1.0), 5.0, "era2 L5 liquid 5")
	_expect_approx(era2_l5.get("lingli", -1.0), 200.0, "era2 L5 lingli stays 200")
	var reduced := _cost_as_floats(Cultivation.level_up_cost(era1_def, 3, 0.5))
	_expect(reduced.has("lingli") and reduced.has("wood") and reduced.size() == 2, "era1 L3 reduced cost keys lingli and wood")
	_expect_approx(reduced.get("lingli", -1.0), 25.0, "era1 L3 reduced lingli 25")
	_expect_approx(reduced.get("wood", -1.0), 20.0, "era1 L3 reduced wood 20")

func _test_lv9_inline_behavior() -> void:
	var era3_style := {
		"id": 3,
		"name": "金丹期",
		"max_level": 10,
		"resource_multiplier": 2.0,
		"lifespan": 540.0,
		"level_up_requirements": {
			"base_time": 240.0,
			"time_multiplier": 1.22,
			"resources": {"lingli": 2000.0, "money": 500.0, "stone_mid": 50.0, "liquid": 1.0, "formation_core": 1.0},
			"lv9_item": {"type": "talisman", "amount": 10.0},
		},
		"upgrade_requirements": {"level": 10.0, "capacity": {}},
	}
	var lv8 := _cost_as_floats(Cultivation.level_up_cost(era3_style, 8, 0.0))
	_expect(lv8.has("lingli") and lv8.has("stone_mid") and lv8.has("formation_core") and not lv8.has("talisman") and lv8.size() == 5, "era3-style L8 cost has flat five, no talisman")
	_expect_approx(lv8.get("stone_mid", -1.0), 50.0, "era3-style L8 stone_mid 50")
	_expect_approx(lv8.get("formation_core", -1.0), 1.0, "era3-style L8 formation_core 1")
	var lv9 := _cost_as_floats(Cultivation.level_up_cost(era3_style, 9, 0.0))
	_expect(lv9.has("talisman") and lv9.size() == 6, "era3-style L9 appends talisman")
	_expect_approx(lv9.get("talisman", -1.0), 10.0, "era3-style L9 talisman 10")
	_expect_approx(lv9.get("lingli", -1.0), 2000.0, "era3-style L9 lingli 2000")
	var lv9_reduced := _cost_as_floats(Cultivation.level_up_cost(era3_style, 9, 0.5))
	_expect_approx(lv9_reduced.get("talisman", -1.0), 5.0, "era3-style L9 talisman reduced 5")

func _test_loader_rejections() -> void:
	var resources := [
		{"id": "lingli", "type": "basic", "max": 10000, "rate": 0, "unlocked": true},
		{"id": "wood", "type": "basic", "max": 1000, "rate": 0, "unlocked": true},
	]
	var era_with_bad_level := [{
		"id": 1, "name": "練氣期", "max_level": 10, "resource_multiplier": 1, "lifespan": 80,
		"level_up_requirements": {
			"base_time": 60, "time_multiplier": 1.15,
			"resources": {"lingli": 50},
			"graded_resources": [{"from_level": 0, "resources": {"wood": 40}}],
		},
		"upgrade_requirements": {"level": 10, "capacity": {"lingli": 500}},
	}]
	var rejected_level := ContentLoader.build_content(resources, [], era_with_bad_level)
	_expect(not bool(rejected_level.ok), "loader rejects graded from_level 0")
	_expect(not rejected_level.get("errors", []).is_empty(), "loader from_level 0 reports errors")
	_expect(String(str(rejected_level.get("errors", []))).contains("from_level"), "from_level 0 error mentions from_level")
	var era_with_unknown_id := [{
		"id": 1, "name": "練氣期", "max_level": 10, "resource_multiplier": 1, "lifespan": 80,
		"level_up_requirements": {
			"base_time": 60, "time_multiplier": 1.15,
			"resources": {"lingli": 50},
			"graded_resources": [{"from_level": 3, "resources": {"no_such_thing": 40}}],
		},
		"upgrade_requirements": {"level": 10, "capacity": {"lingli": 500}},
	}]
	var rejected_id := ContentLoader.build_content(resources, [], era_with_unknown_id)
	_expect(not bool(rejected_id.ok), "loader rejects graded unknown resource id")
	_expect(String(str(rejected_id.get("errors", []))).contains("references unknown resource"), "unknown graded id error mentions unknown resource")
	var era_with_deferred_id := [{
		"id": 1, "name": "練氣期", "max_level": 10, "resource_multiplier": 1, "lifespan": 80,
		"level_up_requirements": {
			"base_time": 60, "time_multiplier": 1.15,
			"resources": {"lingli": 50},
			"graded_resources": [{"from_level": 3, "resources": {"bronze_essence": 10}}],
		},
		"upgrade_requirements": {"level": 10, "capacity": {"lingli": 500}},
	}]
	var accepted_deferred := ContentLoader.build_content(resources, [], era_with_deferred_id)
	_expect(bool(accepted_deferred.ok), "loader accepts deferred id bronze_essence in graded_resources")
	if bool(accepted_deferred.ok):
		var deferred_cost := _cost_as_floats(Cultivation.level_up_cost(accepted_deferred.content.eras[1], 3, 0.0))
		_expect_approx(deferred_cost.get("bronze_essence", -1.0), 10.0, "deferred id contributes to cost at from_level")

func _cost_as_floats(costs: Dictionary) -> Dictionary:
	var result := {}
	for resource_id in costs:
		result[String(resource_id)] = _f(costs[resource_id])
	return result

func _f(value: Variant) -> float:
	if value is AmountCompat:
		return (value as AmountCompat).to_float()
	return float(value)

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func _expect_approx(actual: float, expected: float, label: String, tolerance: float = EPS) -> void:
	if absf(actual - expected) > tolerance:
		_expect(false, "%s; expected=%f actual=%f" % [label, expected, actual])
		return
	checks += 1
