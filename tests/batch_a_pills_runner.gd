extends SceneTree

const CONTENT_DIR := "res://content"
const EPS := 0.000001
const TIGHT := 0.000000001

var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	print("[RUNNING] tests/batch_a_pills_runner.gd")
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	if not bool(loaded.ok):
		_expect(false, "content loads from %s: %s" % [CONTENT_DIR, str(loaded.errors)])
		_finish()
		return
	var content: GameContent = loaded.content
	_expect(true, "content loads from %s" % CONTENT_DIR)
	_test_tribulation_fixtures()
	_test_determinism_scan()
	_test_alchemy_consume(content)
	_test_refine_gate(content)
	_test_buff_pills(content)
	_test_breakthrough(content)
	_finish()

func _finish() -> void:
	print("%d checks, %d failures" % [checks, failures.size()])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: %s" % label)
	else:
		print("FAIL: %s" % label)
		failures.append(label)

func _expect_approx(actual: float, expected: float, label: String, tolerance: float = EPS) -> void:
	checks += 1
	if absf(actual - expected) <= tolerance:
		print("PASS: %s" % label)
	else:
		var message := "%s; expected=%f actual=%f (tol=%f)" % [label, expected, actual, tolerance]
		print("FAIL: %s" % message)
		failures.append(message)

func _expect_int(actual: int, expected: int, label: String) -> void:
	checks += 1
	if actual == expected:
		print("PASS: %s" % label)
	else:
		var message := "%s; expected=%d actual=%d" % [label, expected, actual]
		print("FAIL: %s" % message)
		failures.append(message)

func _expect_string(actual: String, expected: String, label: String) -> void:
	checks += 1
	if actual == expected:
		print("PASS: %s" % label)
	else:
		var message := "%s; expected=%s actual=%s" % [label, expected, actual]
		print("FAIL: %s" % message)
		failures.append(message)

func _test_tribulation_fixtures() -> void:
	_expect(not TribulationRules.requires_tribulation(2), "requires_tribulation(2) is false")
	_expect(TribulationRules.requires_tribulation(3), "requires_tribulation(3) is true")
	_expect_approx(TribulationRules.base_rate(3), 0.80, "base_rate(3)=0.80", TIGHT)
	_expect_approx(TribulationRules.base_rate(4), 0.70, "base_rate(4)=0.70", TIGHT)
	_expect_approx(TribulationRules.base_rate(5), 0.60, "base_rate(5)=0.60", TIGHT)
	_expect_approx(TribulationRules.base_rate(9), 0.30, "base_rate(9)=0.30", TIGHT)
	_expect_approx(TribulationRules.base_rate(10), 0.30, "base_rate(10)=0.30", TIGHT)
	_expect_approx(TribulationRules.pill_bonus("golden_tribulation_pill", 1), 0.03, "golden pill bonus 1 ~0.03", TIGHT)
	_expect_approx(TribulationRules.pill_bonus("tribulation_pill", 1), 0.05, "tribulation pill bonus 1 ~0.05", TIGHT)
	_expect_approx(TribulationRules.pill_bonus("golden_tribulation_pill", 0), 0.0, "golden pill bonus 0 is 0", TIGHT)
	var golden_99: float = TribulationRules.pill_bonus("golden_tribulation_pill", 99)
	_expect(golden_99 > 0.199 and golden_99 <= 0.2, "golden pill bonus 99 in (0.199,0.2]")
	var delta_0: float = TribulationRules.pill_bonus("golden_tribulation_pill", 0)
	var delta_1: float = TribulationRules.pill_bonus("golden_tribulation_pill", 1)
	var delta_2: float = TribulationRules.pill_bonus("golden_tribulation_pill", 2)
	_expect((delta_2 - delta_1) < (delta_1 - delta_0), "golden pill bonus is diminishing")
	_expect_approx(TribulationRules.success_probability(3, 0), 0.80, "success_probability(3,0)~0.80", TIGHT)
	_expect_approx(TribulationRules.success_probability(3, 1), 0.83, "success_probability(3,1)~0.83", TIGHT)
	_expect_approx(TribulationRules.success_probability(3, 99), 0.95, "success_probability(3,99)=0.95", TIGHT)
	_expect_approx(TribulationRules.success_probability(9, 0), 0.30, "success_probability(9,0)~0.30", TIGHT)
	_expect(TribulationRules.is_success(0.2, 0.3), "is_success(0.2,0.3) is true")
	_expect(not TribulationRules.is_success(0.3, 0.3), "is_success(0.3,0.3) is false")
	_expect_approx(TribulationRules.roll(7, 3), TribulationRules.roll(7, 3), "roll(7,3) is stable", TIGHT)
	var roll_73: float = TribulationRules.roll(7, 3)
	_expect(roll_73 >= 0.0 and roll_73 < 1.0, "roll(7,3) in [0,1)")
	_expect(TribulationRules.roll(7, 0) != TribulationRules.roll(7, 1), "roll(7,0) differs from roll(7,1)")

func _test_determinism_scan() -> void:
	var ok := true
	for seed_value in range(0, 20):
		for roll_index in range(0, 50):
			var first: float = TribulationRules.roll(seed_value, roll_index)
			var second: float = TribulationRules.roll(seed_value, roll_index)
			if first < 0.0 or first >= 1.0 or first != second:
				ok = false
	_expect(ok, "roll determinism over seed 0..19 and idx 0..49")

func _test_alchemy_consume(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	var state: GameState = session.state
	state.era_id = 4
	state.pills["high_cultivation_pill"] = 1
	var before: float = state.training_seconds
	var first := AlchemySystem.consume(state, "high_cultivation_pill", 1)
	_expect(bool(first.get("ok", false)), "high_cultivation fresh count1 consume ok")
	_expect_approx(state.training_seconds - before, 300.0, "high_cultivation fresh count1 grants 300")
	_expect_int(AlchemySystem.stack_count(state, "high_cultivation_pill"), 1, "high_cultivation stack is 1 after one pill")
	state.pills["high_cultivation_pill"] = 1
	var before_second: float = state.training_seconds
	var second := AlchemySystem.consume(state, "high_cultivation_pill", 1)
	_expect(bool(second.get("ok", false)), "high_cultivation second count1 consume ok")
	_expect_approx(state.training_seconds - before_second, 255.0, "high_cultivation second count1 grants 255")

	var fresh_session := GameSession.create_new_game(content)
	var fresh_state: GameState = fresh_session.state
	fresh_state.era_id = 4
	fresh_state.pills["high_cultivation_pill"] = 2
	var pair := AlchemySystem.consume(fresh_state, "high_cultivation_pill", 2)
	_expect(bool(pair.get("ok", false)), "high_cultivation fresh count2 consume ok")
	_expect_approx(fresh_state.training_seconds, 555.0, "high_cultivation fresh count2 grants 555")

	var invalid := AlchemySystem.consume(fresh_state, "high_cultivation_pill", 100)
	_expect(not bool(invalid.get("ok", true)), "high_cultivation count 100 is rejected")
	_expect_string(String(invalid.get("error", "")), "INVALID_COUNT", "high_cultivation count 100 error is INVALID_COUNT")

	var overflow_session := GameSession.create_new_game(content)
	var overflow_state: GameState = overflow_session.state
	overflow_state.era_id = 4
	overflow_state.pills["high_cultivation_pill"] = 2
	overflow_state.pill_effects["stacks"] = {"high_cultivation_pill": 98}
	var overflow := AlchemySystem.consume(overflow_state, "high_cultivation_pill", 2)
	_expect(not bool(overflow.get("ok", true)), "high_cultivation stack overflow is rejected")
	_expect_string(String(overflow.get("error", "")), "PILL_STACK_LIMIT", "high_cultivation stack overflow error is PILL_STACK_LIMIT")

	var life_session := GameSession.create_new_game(content)
	var life_state: GameState = life_session.state
	life_state.era_id = 4
	life_state.pills["lifespan_pill"] = 2
	var life := AlchemySystem.consume(life_state, "lifespan_pill", 2)
	_expect(bool(life.get("ok", false)), "lifespan_pill count2 consume ok")
	_expect_approx(float(life_state.pill_effects.get("lifespan_bonus_years", 0.0)), 20.0, "lifespan_pill count2 grants 20 years")

func _test_refine_gate(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	var state: GameState = session.state
	state.buildings["herb_farm"] = 3
	state.era_id = 1
	var locked: Dictionary = AlchemySystem.can_refine(state, "lifespan_pill", 1)
	_expect(not bool(locked.get("can_refine", true)), "lifespan refine at era1 is rejected")
	_expect_string(String(locked.get("reason", "")), "PILL_LOCKED", "lifespan refine at era1 reason is PILL_LOCKED")
	_expect_int(int(locked.get("required_era", 0)), 4, "lifespan refine at era1 reports required_era 4")
	state.era_id = 4
	state.resources["spirit_grass_low"].value = AmountCompat.from_number(100.0)
	state.resources["wood"].value = AmountCompat.from_number(100.0)
	state.resources["money"].value = AmountCompat.from_number(100.0)
	var allowed: Dictionary = AlchemySystem.can_refine(state, "lifespan_pill", 1)
	_expect(bool(allowed.get("can_refine", false)), "lifespan refine at era4 is allowed")
	var refined := AlchemySystem.refine(state, "lifespan_pill", 1)
	_expect(bool(refined.get("ok", false)), "lifespan refine at era4 ok")
	_expect_int(int(state.pills.get("lifespan_pill", 0)), 1, "lifespan pill count is 1 after refine")
	var invalid: Dictionary = AlchemySystem.can_refine(state, "lifespan_pill", 100)
	_expect(not bool(invalid.get("can_refine", true)), "refine count 100 is rejected")
	_expect_string(String(invalid.get("reason", "")), "INVALID_COUNT", "refine count 100 reason is INVALID_COUNT")

func _test_buff_pills(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	var state: GameState = session.state
	state.era_id = 4
	state.pills["spirit_tide_pill"] = 21
	var first := AlchemySystem.consume(state, "spirit_tide_pill", 1)
	_expect(bool(first.get("ok", false)), "spirit_tide_pill count1 consume ok")
	var tide_entry: Dictionary = state.buffs.get("spirit_tide", {})
	_expect_approx(float(tide_entry.get("remaining_seconds", 0.0)), 300.0, "spirit_tide remaining 300 after one pill")
	var merged := AlchemySystem.consume(state, "spirit_tide_pill", 20)
	_expect(bool(merged.get("ok", false)), "spirit_tide_pill count20 consume ok")
	tide_entry = state.buffs.get("spirit_tide", {})
	_expect_approx(float(tide_entry.get("remaining_seconds", 0.0)), 3600.0, "spirit_tide merged remaining capped at 3600")
	state.pills["quick_output_pill"] = 1
	var quick := AlchemySystem.consume(state, "quick_output_pill", 1)
	_expect(bool(quick.get("ok", false)), "quick_output_pill count1 consume ok")
	var quick_entry: Dictionary = state.buffs.get("quick_output", {})
	_expect_approx(float(quick_entry.get("remaining_seconds", 0.0)), 600.0, "quick_output remaining 600 after one pill")

func _test_breakthrough(content: GameContent) -> void:
	var era2: Variant = content.era(2)
	if era2 == null:
		print("SKIP: breakthrough section because content has no era 2")
		return
	_ensure_era(content, 3, "金丹期")
	_ensure_era(content, 4, "元嬰期")
	var era3: Dictionary = content.eras[3]
	var upgrade: Dictionary = era3.get("upgrade_requirements", {})
	upgrade["capacity"] = {}
	era3["upgrade_requirements"] = upgrade
	var from_era: int = 3
	var era3_def: Variant = content.era(from_era)
	var max_level: int = int(era3_def.max_level)
	var probability: float = TribulationRules.success_probability(from_era, 0)
	var success_index: int = -1
	var failure_index: int = -1
	for index in range(0, 201):
		var roll_value: float = TribulationRules.roll(0, index)
		if success_index < 0 and roll_value < probability:
			success_index = index
		if failure_index < 0 and roll_value >= probability:
			failure_index = index
		if success_index >= 0 and failure_index >= 0:
			break
	_expect(success_index >= 0, "breakthrough fixture found a success roll index")
	_expect(failure_index >= 0, "breakthrough fixture found a failure roll index")
	if success_index < 0 or failure_index < 0:
		return
	var era2_max: int = int(era2.max_level)

	var success_state := GameState.new()
	success_state.era_id = from_era
	success_state.level = max_level
	success_state.onboarding_version = Onboarding.SCHEMA_VERSION
	success_state.tribulation_seed = 0
	success_state.tribulation_roll_index = success_index
	var success_result: Dictionary = CommandProcessor.apply(content, success_state, {"type": "breakthrough_era", "payload": {}})
	_expect(bool(success_result.get("ok", false)), "tribulation success returns ok")
	_expect_int(success_state.era_id, 4, "tribulation success advances to era 4")
	_expect_int(success_state.tribulation_roll_index, success_index + 1, "tribulation success increments roll index")
	var success_events: Array = success_result.get("events", [])
	if not success_events.is_empty():
		var success_event: Dictionary = success_events[0]
		_expect_string(String(success_event.get("kind", "")), "era_breakthrough", "tribulation success event kind is era_breakthrough")

	var failure_state := GameState.new()
	failure_state.era_id = from_era
	failure_state.level = max_level
	failure_state.onboarding_version = Onboarding.SCHEMA_VERSION
	failure_state.tribulation_seed = 0
	failure_state.tribulation_roll_index = failure_index
	var failure_result: Dictionary = CommandProcessor.apply(content, failure_state, {"type": "breakthrough_era", "payload": {}})
	_expect(bool(failure_result.get("ok", false)), "tribulation failure returns ok true")
	_expect_int(failure_state.era_id, 2, "tribulation failure drops to era 2")
	_expect_int(failure_state.level, era2_max, "tribulation failure level equals era 2 max level")
	_expect_int(failure_state.tribulation_roll_index, failure_index + 1, "tribulation failure increments roll index")
	var failure_events: Array = failure_result.get("events", [])
	if not failure_events.is_empty():
		var failure_event: Dictionary = failure_events[0]
		_expect_string(String(failure_event.get("kind", "")), "tribulation_failed", "tribulation failure event kind is tribulation_failed")

func _ensure_era(content: GameContent, era_id: int, era_name: String) -> void:
	if content.eras.has(era_id):
		return
	content.eras[era_id] = {
		"id": era_id,
		"name": era_name,
		"max_level": 10,
		"resource_multiplier": 2.0,
		"lifespan": 540.0,
		"level_up_requirements": {
			"base_time": 240.0,
			"time_multiplier": 1.22,
			"resources": {},
			"graded_resources": [],
			"lv9_item": null,
		},
		"upgrade_requirements": {"level": 10.0, "capacity": {}},
	}
	content.era_ids.append(era_id)
