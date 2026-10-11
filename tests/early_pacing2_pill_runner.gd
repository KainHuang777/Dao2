extends SceneTree
## Pill training-ceiling clamp tests (no overshoot past the current level gate).
## Run: godot --headless --path . --script res://tests/early_pacing2_pill_runner.gd

const CONTENT_DIR := "res://content"
const EPS := 0.000001

var failures: Array[String] = []
var passed := 0
var failed := 0

func _init() -> void:
	print("[RUNNING] tests/early_pacing2_pill_runner.gd")
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	if not bool(loaded.ok):
		print("FAIL: content load: %s" % str(loaded.errors))
		quit(1)
		return
	var content: GameContent = loaded.content
	_test_legacy_ceiling(content)
	_test_partial_gain(content)
	_test_zero_gain_and_command_error(content)
	_test_multi_pill_partial(content)
	_test_non_cultivation_pills(content)
	_test_command_clamp_no_overshoot(content)
	_test_command_other_pill_unaffected(content)
	print("PASS: %d  FAIL: %d" % [passed, failed])
	if failures.is_empty():
		print("PILL CEILING RUNNER DONE")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		quit(1)

func _test_legacy_ceiling(content: GameContent) -> void:
	var state := _fresh_state(content)
	state.training_seconds = 10.0
	state.pills["cultivation_pill"] = 3
	var result := AlchemySystem.consume(state, "cultivation_pill", 1)
	var applied := _applied(result)
	_expect(bool(result.get("ok", false)), "legacy ceiling: consume ok")
	_expect_close(state.training_seconds, 70.0, "legacy ceiling: training 10 to 70")
	_expect_close(float(applied.get("training_gain", 0.0)), 60.0, "legacy ceiling: gain 60")
	_expect_equal(int(state.pills.get("cultivation_pill", 0)), 2, "legacy ceiling: pills deducted")

func _test_partial_gain(content: GameContent) -> void:
	var state := _fresh_state(content)
	state.training_seconds = 50.0
	state.pills["cultivation_pill"] = 3
	var result := AlchemySystem.consume(state, "cultivation_pill", 1, 100.0)
	var applied := _applied(result)
	_expect(bool(result.get("ok", false)), "ceiling 100: consume ok")
	_expect_close(state.training_seconds, 100.0, "ceiling 100: training exactly 100")
	_expect_close(float(applied.get("training_gain", 0.0)), 50.0, "ceiling 100: gain 50")

func _test_zero_gain_and_command_error(content: GameContent) -> void:
	var state := _fresh_state(content)
	state.training_seconds = 100.0
	state.pills["cultivation_pill"] = 2
	var result := AlchemySystem.consume(state, "cultivation_pill", 1, 100.0)
	var applied := _applied(result)
	var allowed := maxf(100.0 - 100.0, 0.0)
	_expect_close(allowed, 0.0, "ceiling 100 at 100: allowed is 0")
	_expect(bool(result.get("ok", false)), "ceiling 100 at 100: consume ok")
	_expect_close(state.training_seconds, 100.0, "ceiling 100 at 100: training unchanged")
	_expect_close(float(applied.get("training_gain", 0.0)), 0.0, "ceiling 100 at 100: gain 0")
	var cmd_state := _fresh_state(content)
	var era_def: Variant = content.era(cmd_state.era_id)
	var req: float = Cultivation.next_level_required_seconds(era_def, cmd_state.level, 0.0, 1.0)
	cmd_state.training_seconds = req
	cmd_state.pills["cultivation_pill"] = 2
	var res: Dictionary = CommandProcessor.apply(content, cmd_state, {"type": "consume_pill", "payload": {"pill_id": "cultivation_pill", "count": 1}})
	_expect(not bool(res.get("ok", false)), "processor at gate: consume rejected")
	_expect_equal(String(res.get("error", "")), "TRAINING_ALREADY_COMPLETE", "processor at gate: error id")
	_expect_equal(int(cmd_state.pills.get("cultivation_pill", 0)), 2, "processor at gate: pills not deducted")
	_expect_close(cmd_state.training_seconds, req, "processor at gate: training unchanged")

func _test_multi_pill_partial(content: GameContent) -> void:
	var state := _fresh_state(content)
	state.training_seconds = 50.0
	state.pills["cultivation_pill"] = 5
	var result := AlchemySystem.consume(state, "cultivation_pill", 3, 183.5)
	var applied := _applied(result)
	_expect(bool(result.get("ok", false)), "multi-pill ceiling 183.5: consume ok")
	_expect_close(state.training_seconds, 183.5, "multi-pill ceiling 183.5: final 183.5", 0.000001)
	_expect_close(float(applied.get("training_gain", 0.0)), 133.5, "multi-pill ceiling 183.5: gain 133.5", 0.000001)
	_expect_equal(int(state.pills.get("cultivation_pill", 0)), 2, "multi-pill ceiling 183.5: 3 pills deducted")

func _test_non_cultivation_pills(content: GameContent) -> void:
	var state := _fresh_state(content)
	state.training_seconds = 40.0
	state.pills["lifespan_pill"] = 2
	var life := AlchemySystem.consume(state, "lifespan_pill", 1)
	_expect(bool(life.get("ok", false)), "lifespan_pill default ceiling: consume ok")
	_expect_close(state.training_seconds, 40.0, "lifespan_pill default ceiling: training unchanged")
	_expect_close(float(state.pill_effects.get("lifespan_bonus_years", 0.0)), 5.0, "lifespan_pill default ceiling: bonus 5")
	var clamped_state := _fresh_state(content)
	clamped_state.training_seconds = 50.0
	clamped_state.pills["lifespan_pill"] = 1
	var life2 := AlchemySystem.consume(clamped_state, "lifespan_pill", 1, 100.0)
	_expect(bool(life2.get("ok", false)), "lifespan_pill ceiling 100: consume ok")
	_expect_close(clamped_state.training_seconds, 50.0, "lifespan_pill ceiling 100: training unchanged")
	_expect_close(float(_applied(life2).get("lifespan_gain", 0.0)), 5.0, "lifespan_pill ceiling 100: bonus applied")
	var foundation_state := _fresh_state(content)
	foundation_state.training_seconds = 55.0
	foundation_state.pills["foundation_pill"] = 2
	var found := AlchemySystem.consume(foundation_state, "foundation_pill", 1)
	_expect(bool(found.get("ok", false)), "foundation_pill default ceiling: consume ok")
	_expect_close(foundation_state.training_seconds, 55.0, "foundation_pill default ceiling: training unchanged")
	_expect_close(float(_applied(found).get("production_gain", 0.0)), 0.1, "foundation_pill default ceiling: production 0.1")
	_expect_close(float(foundation_state.pill_effects.get("production_multiplier", 0.0)), 0.1, "foundation_pill default ceiling: effect stored")

func _test_command_clamp_no_overshoot(content: GameContent) -> void:
	var state := _fresh_state(content)
	var era_def: Variant = content.era(state.era_id)
	var req: float = Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0)
	state.training_seconds = req - 25.0
	state.pills["cultivation_pill"] = 2
	var res: Dictionary = CommandProcessor.apply(content, state, {"type": "consume_pill", "payload": {"pill_id": "cultivation_pill", "count": 1}})
	_expect(bool(res.get("ok", false)), "processor near gate: consume ok")
	_expect_close(state.training_seconds, req, "processor near gate: lands exactly on requirement")
	_expect_equal(int(state.pills.get("cultivation_pill", 0)), 1, "processor near gate: one pill deducted")

func _test_command_other_pill_unaffected(content: GameContent) -> void:
	var state := _fresh_state(content)
	var era_def: Variant = content.era(state.era_id)
	var req: float = Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0)
	state.training_seconds = req
	state.pills["lifespan_pill"] = 1
	var res: Dictionary = CommandProcessor.apply(content, state, {"type": "consume_pill", "payload": {"pill_id": "lifespan_pill", "count": 1}})
	_expect(bool(res.get("ok", false)), "processor other pill at gate: consume ok")
	_expect_close(state.training_seconds, req, "processor other pill at gate: training unchanged")
	_expect_close(float(state.pill_effects.get("lifespan_bonus_years", 0.0)), 5.0, "processor other pill at gate: bonus applied")

func _fresh_state(content: GameContent) -> GameState:
	var session := GameSession.create_new_game(content)
	return session.state

func _applied(result: Dictionary) -> Dictionary:
	var events: Array = result.get("events", [])
	if events.is_empty():
		return {}
	var first: Dictionary = events[0]
	var effects: Dictionary = first.get("applied_effects", {})
	return effects

func _expect(condition: bool, label: String) -> void:
	if bool(condition):
		passed += 1
	else:
		failed += 1
		failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _expect_close(actual: float, expected: float, label: String, tolerance: float = EPS) -> void:
	if absf(actual - expected) <= tolerance:
		passed += 1
	else:
		failed += 1
		failures.append("%s: expected %f, got %f" % [label, expected, actual])
