extends SceneTree

const CONTENT_DIR := "res://content"

var failures: Array[String] = []

func _init() -> void:
	print("[RUNNING] tests/m3b_alchemy_runner.gd")
	var loaded := ContentLoader.load_directory(CONTENT_DIR)
	if not bool(loaded.ok):
		failures.append("Content load failed: %s" % str(loaded.errors))
		_finish()
		return
	var content: GameContent = loaded.content
	_test_alchemy_unlock_and_guards(content)
	_test_refine_and_consume_effects(content)
	_test_time_advancer_lifespan_integration(content)
	_test_save_persistence_roundtrip(content)
	_test_reincarnation_reset(content)
	_test_idempotency(content)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PASS: M3-B alchemy system, refining, consumption, lifespan boost, production boost, persistence and reincarnation reset.")
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

func _test_alchemy_unlock_and_guards(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	_expect(not AlchemySystem.is_unlocked(session.state), "alchemy locked at new game")
	
	# Attempting to refine when locked must fail
	var res := session.refine_pill("cultivation_pill", 1)
	_expect(not bool(res.ok), "refine while locked must fail")
	_expect_equal(res.error, "ALCHEMY_LOCKED", "refine locked error code")

	# Build herb_farm to level 3 -> unlocks alchemy
	session.state.buildings["herb_farm"] = 3
	_expect(AlchemySystem.is_unlocked(session.state), "alchemy unlocked when herb_farm >= 3")

	# Unknown pill
	var unk := session.refine_pill("unknown_pill_xyz", 1)
	_expect(not bool(unk.ok), "unknown pill rejected")
	_expect_equal(unk.error, "UNKNOWN_PILL", "unknown pill error code")

	# Insufficient resources
	var ins := session.refine_pill("cultivation_pill", 1)
	_expect(not bool(ins.ok), "refine without materials rejected")
	_expect_equal(ins.error, "INSUFFICIENT_RESOURCE", "insufficient resource error code")

func _test_refine_and_consume_effects(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.buildings["herb_farm"] = 3

	# Give materials
	session.state.resources["spirit_grass_low"].value = AmountCompat.from_number(200.0)
	session.state.resources["lingli"].value = AmountCompat.from_number(500.0)
	session.state.resources["wood"].value = AmountCompat.from_number(100.0)
	session.state.resources["money"].value = AmountCompat.from_number(100.0)
	session.state.resources["black_copper"].value = AmountCompat.from_number(100.0)

	# 1. Refine cultivation_pill
	var r1 := session.refine_pill("cultivation_pill", 2)
	_expect(bool(r1.ok), "refine cultivation_pill ok")
	_expect_equal(int(session.state.pills.get("cultivation_pill", 0)), 2, "cultivation_pill count 2")
	_expect_equal(session.state.resources["spirit_grass_low"].value.to_float(), 180.0, "consumed 20 spirit grass")
	_expect_equal(session.state.resources["lingli"].value.to_float(), 400.0, "consumed 100 lingli")

	# Consume cultivation_pill: instant training
	var prev_training := session.state.training_seconds
	var c1 := session.consume_pill("cultivation_pill", 1)
	_expect(bool(c1.ok), "consume cultivation_pill ok")
	_expect_equal(int(session.state.pills["cultivation_pill"]), 1, "remaining cultivation_pill 1")
	_expect_equal(session.state.training_seconds, prev_training + 60.0, "training increased by 60s")

	# 2. Refine lifespan_pill
	var r2 := session.refine_pill("lifespan_pill", 1)
	_expect(bool(r2.ok), "refine lifespan_pill ok")
	_expect_equal(int(session.state.pills.get("lifespan_pill", 0)), 1, "lifespan_pill count 1")

	# Consume lifespan_pill: lifespan_bonus_years
	var c2 := session.consume_pill("lifespan_pill", 1)
	_expect(bool(c2.ok), "consume lifespan_pill ok")
	_expect_equal(float(session.state.pill_effects.get("lifespan_bonus_years", 0.0)), 5.0, "lifespan bonus years 5")

	# 3. Refine foundation_pill (and verify resource sync)
	var r3 := session.refine_pill("foundation_pill", 1)
	_expect(bool(r3.ok), "refine foundation_pill ok")
	_expect_equal(int(session.state.pills.get("foundation_pill", 0)), 0, "foundation_pill legacy counter untouched")
	_expect_equal(session.state.resources["foundation_pill"].value.to_float(), 1.0, "resources foundation_pill authoritative count 1.0")

	# Consume foundation_pill: production multiplier
	var c3 := session.consume_pill("foundation_pill", 1)
	_expect(bool(c3.ok), "consume foundation_pill ok")
	_expect_equal(float(session.state.pill_effects.get("production_multiplier", 0.0)), 0.1, "production multiplier 0.1")
	_expect_equal(session.state.resources["foundation_pill"].value.to_float(), 0.0, "resources foundation_pill synced after consume")

func _test_time_advancer_lifespan_integration(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	# Base Era 1 lifespan = 80 years = 4800 seconds
	var view_base := session.get_view()
	_expect_equal(float(view_base.max_lifespan_seconds), 4800.0, "base max lifespan 4800s")

	# Add 5 years from pill (+300s = 5100s)
	session.state.pill_effects["lifespan_bonus_years"] = 5.0
	var view_boosted := session.get_view()
	_expect_equal(float(view_boosted.max_lifespan_seconds), 5100.0, "boosted max lifespan 5100s")

	# Run TimeAdvancer past 4800s, should NOT exhaust because limit is now 5100s
	session.state.total_elapsed_seconds = 4850.0
	var adv := TimeAdvancer.advance(session.state, content, 10)
	_expect(adv.stopped == null, "not exhausted at 4860s thanks to pill")

func _test_save_persistence_roundtrip(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.pills = {"cultivation_pill": 5, "lifespan_pill": 2}
	session.state.pill_effects = {"lifespan_bonus_years": 10.0, "total_consumed": 7}
	
	var meta := {
		"save_id": "test_save_alchemy",
		"saved_at_utc_ms": "1700000000000",
		"settled_until_utc_ms": "1700000000000",
		"sim_tick": "100",
		"rng_streams": {},
	}
	var enc := SaveCodec.encode(session.state, content.content_version, meta)
	_expect(bool(enc.ok), "SaveCodec encode ok")

	var dec := SaveCodec.decode(String(enc.json))
	_expect(bool(dec.ok), "SaveCodec decode ok")
	var loaded_state: GameState = dec.state
	_expect_equal(int(loaded_state.pills.get("cultivation_pill", 0)), 5, "loaded cultivation_pill 5")
	_expect_equal(int(loaded_state.pills.get("lifespan_pill", 0)), 2, "loaded lifespan_pill 2")
	_expect_equal(float(loaded_state.pill_effects.get("lifespan_bonus_years", 0.0)), 10.0, "loaded lifespan_bonus_years 10")
	_expect_equal(int(loaded_state.pill_effects.get("total_consumed", 0)), 7, "loaded total_consumed 7")

func _test_reincarnation_reset(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.era_id = 2 # Era 2 qualifies for reincarnation
	session.state.buildings["rebirth_lotus"] = 1
	session.state.pills = {"cultivation_pill": 10}
	session.state.pill_effects = {"lifespan_bonus_years": 15.0}

	var r_res := session.reincarnate("normal")
	_expect(bool(r_res.ok), "reincarnation ok")
	_expect(session.state.pills.is_empty(), "pills cleared after reincarnation")
	_expect(session.state.pill_effects.is_empty(), "pill_effects cleared after reincarnation")

func _test_idempotency(content: GameContent) -> void:
	var session := GameSession.create_new_game(content)
	session.state.buildings["herb_farm"] = 3
	session.state.resources["spirit_grass_low"].value = AmountCompat.from_number(100.0)
	session.state.resources["lingli"].value = AmountCompat.from_number(200.0)

	var cmd := {
		"command_id": "test_refine_idempotent_1",
		"type": "refine_pill",
		"expected_revision": session.state.revision,
		"payload": {"pill_id": "cultivation_pill", "count": 1},
	}
	var res1 := session.submit(cmd)
	_expect(bool(res1.ok), "first submit ok")
	_expect(not bool(res1.duplicate), "first submit not duplicate")
	_expect_equal(int(session.state.pills.get("cultivation_pill", 0)), 1, "pills count 1")

	# Replay exact command
	var res2 := session.submit(cmd)
	_expect(bool(res2.ok), "replay submit ok")
	_expect(bool(res2.duplicate), "replay submit is duplicate")
	_expect_equal(int(session.state.pills.get("cultivation_pill", 0)), 1, "pills count remains 1, no double-craft")
