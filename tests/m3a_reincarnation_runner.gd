extends SceneTree

func _init() -> void:
	print("--- Running M3-A Reincarnation Runner ---")
	var success := true
	success = _test_golden_fixture_parity() and success
	success = _test_eligibility_gating() and success
	success = _test_reincarnation_execution_and_reset() and success
	success = _test_talents_and_multipliers() and success
	success = _test_persistence_roundtrip() and success

	if success:
		print("PASS: M3-A reincarnation lifecycle, golden fixture parity, talents, reset/preserve contracts, and persistence.")
		quit(0)
	else:
		printerr("FAIL: M3-A reincarnation verification failed.")
		quit(1)

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		printerr("ASSERTION FAILED: " + message)
		return false
	return true

func _expect_equal(actual: Variant, expected: Variant, message: String) -> bool:
	if actual != expected:
		printerr("ASSERTION FAILED: %s (expected %s, got %s)" % [message, str(expected), str(actual)])
		return false
	return true

func _load_test_content() -> GameContent:
	var loaded := ContentLoader.load_directory("res://content")
	if not bool(loaded.ok):
		printerr("Failed to load content in test")
		return null
	return loaded.content

func _test_golden_fixture_parity() -> bool:
	print("Testing golden fixture parity against m0-b-v1.json...")
	var ok := true
	var fixture_file := FileAccess.open("res://tests/fixtures/legacy/m0-b-v1.json", FileAccess.READ)
	if fixture_file == null:
		printerr("Cannot open m0-b-v1.json fixture")
		return false
	var parsed: Variant = JSON.parse_string(fixture_file.get_as_text())
	fixture_file.close()
	var reinc_fixture: Dictionary = parsed["expected"]["reincarnation"]

	# 1. normal mode: B=125, era=1
	var norm_reward := ReincarnationRules.compute_reward(125, 1, "normal")
	ok = _expect_equal(int((norm_reward["dao_heart"] as AmountCompat).to_float()), int(reinc_fixture["normal"]["daoHeart"]), "Golden parity: normal daoHeart") and ok
	ok = _expect_equal(int(norm_reward["dao_proof"]), int(reinc_fixture["normal"]["daoProof"]), "Golden parity: normal daoProof") and ok

	# 2. advanced mode: B=125, era=1
	var adv_reward := ReincarnationRules.compute_reward(125, 1, "advanced")
	ok = _expect_equal(int((adv_reward["dao_heart"] as AmountCompat).to_float()), int(reinc_fixture["advanced"]["daoHeart"]), "Golden parity: advanced daoHeart") and ok
	ok = _expect_equal(int(adv_reward["dao_proof"]), int(reinc_fixture["advanced"]["daoProof"]), "Golden parity: advanced daoProof") and ok

	# 3. era floor: B=5, era=4+ (floor=25)
	var floor_reward := ReincarnationRules.compute_reward(5, 4, "normal")
	ok = _expect_equal(int((floor_reward["dao_heart"] as AmountCompat).to_float()), int(reinc_fixture["era_floor"]["daoHeart"]), "Golden parity: era floor daoHeart") and ok
	ok = _expect_equal(int(floor_reward["dao_proof"]), int(reinc_fixture["era_floor"]["daoProof"]), "Golden parity: era floor daoProof") and ok

	# 4. start inheritance amounts for cap 999 across rebirth counts [0, 1, 2, 20]
	var expected_starts: Array = reinc_fixture["start"]
	var counts := [0, 1, 2, 20]
	for i in range(counts.size()):
		var actual_start := ReincarnationRules.compute_start_amount(999.0, counts[i], 0.0)
		ok = _expect_equal(int(actual_start), int(expected_starts[i]), "Golden parity: start resource for count %d" % counts[i]) and ok

	return ok

func _test_eligibility_gating() -> bool:
	print("Testing eligibility gating...")
	var ok := true
	var content: GameContent = _load_test_content()
	if content == null:
		return false
	var session := GameSession.create_new_game(content)

	# Opening state: Era 1, 0 elapsed time -> cannot reincarnate
	var preview := session.get_reincarnation_preview()
	ok = _expect(not bool(preview["eligible"]), "Opening state should not be eligible for reincarnation") and ok

	var result := session.reincarnate()
	ok = _expect(not bool(result["ok"]), "Reincarnation command should fail when not eligible") and ok
	ok = _expect_equal(String(result.get("error", "")), "REINCARNATION_NOT_ELIGIBLE", "Error should be REINCARNATION_NOT_ELIGIBLE") and ok

	# Advance time past era 1 lifespan (4800 seconds)
	var adv := session.advance_time(5000.0)
	ok = _expect_equal(String(adv.get("stopped", "")), "lifespan_exhausted", "Time advancement should stop on lifespan exhaustion") and ok

	# Now should be eligible
	preview = session.get_reincarnation_preview()
	ok = _expect(bool(preview["eligible"]), "Exhausted lifespan should grant reincarnation eligibility") and ok
	ok = _expect_equal(String(preview["reason"]), "lifespan_exhausted", "Reason should be lifespan_exhausted") and ok

	# Era 2 without lotus and unexhausted lifespan cannot reincarnate
	var session_era2 := GameSession.create_new_game(content)
	session_era2.state.era_id = 2
	var preview2 := session_era2.get_reincarnation_preview()
	ok = _expect(not bool(preview2["eligible"]), "Era 2 without rebirth_lotus and full lifespan cannot reincarnate") and ok

	# Era 2 with rebirth_lotus enables early reincarnation
	session_era2.state.buildings["rebirth_lotus"] = 1
	var preview_lotus := session_era2.get_reincarnation_preview()
	ok = _expect(bool(preview_lotus["eligible"]), "Building rebirth_lotus enables early reincarnation") and ok
	ok = _expect_equal(String(preview_lotus["reason"]), "rebirth_lotus", "Reason should be rebirth_lotus") and ok

	return ok

func _test_reincarnation_execution_and_reset() -> bool:
	print("Testing reincarnation execution, state reset, and resource inheritance...")
	var ok := true
	var content: GameContent = _load_test_content()
	if content == null:
		return false
	var session := GameSession.create_new_game(content)

	# Gather and build hut level 1 & 2
	session.submit({"command_id": "c1", "type": "gather", "expected_revision": session.state.revision, "payload": {"resource_id": "lingli"}})
	session.state.resources["money"].unlocked = true
	session.state.resources["money"].value = AmountCompat.from_number(1000.0)
	session.state.resources["wood"].unlocked = true
	session.state.resources["wood"].value = AmountCompat.from_number(1000.0)
	session.state.buildings["hut"] = 2
	session.state.buildings["wooden_house"] = 1
	session.state.buildings["rebirth_lotus"] = 1
	session.state.era_id = 2  # Era 2 (築基)
	session.state.level = 3

	# Verify eligibility at Era 2 with rebirth_lotus
	var preview := session.get_reincarnation_preview("normal")
	ok = _expect(bool(preview["eligible"]), "Player with rebirth_lotus should be eligible to reincarnate") and ok
	# Building sum = 2 + 1 + 1 = 4, Era 2 floor = 15 => dao_heart = 15, dao_proof = 0
	ok = _expect_equal(int(preview["building_sum"]), 4, "Building sum should be 4") and ok
	ok = _expect_equal(String(preview["dao_heart"]), "15", "Dao heart should use Era 2 floor (15)") and ok

	# Execute reincarnation
	var reinc_res := session.reincarnate("normal")
	ok = _expect(bool(reinc_res["ok"]), "Reincarnation should succeed") and ok

	# Verify state resets and meta preserves
	var s: GameState = session.state
	ok = _expect_equal(s.reincarnation_count, 1, "Reincarnation count should increment to 1") and ok
	ok = _expect_equal(s.highest_era, 2, "Highest era should be recorded as 2") and ok
	ok = _expect_equal(s.dao_heart.serialize(), "15", "Dao heart should be 15") and ok
	ok = _expect_equal(s.era_id, 1, "Era should reset to 1") and ok
	ok = _expect_equal(s.level, 1, "Level should reset to 1") and ok
	ok = _expect_equal(s.training_seconds, 0.0, "Training seconds should reset to 0") and ok
	ok = _expect_equal(s.total_elapsed_seconds, 0.0, "Total elapsed seconds should reset to 0") and ok
	ok = _expect(s.buildings.is_empty(), "Buildings should be completely cleared") and ok

	# Verify start resource inheritance (40% of base cap 100 for unlocked basic resource)
	var lingli_amount: AmountCompat = s.resources["lingli"].value
	var lingli_val: float = lingli_amount.to_float()
	ok = _expect(lingli_val >= 40.0, "First reincarnation should grant 40% initial resource inheritance") and ok

	return ok

func _test_talents_and_multipliers() -> bool:
	print("Testing talent purchasing, multipliers, and lifespan bonus...")
	var ok := true
	var content: GameContent = _load_test_content()
	if content == null:
		return false
	var session := GameSession.create_new_game(content)

	# Seed with 25 dao heart and 4 dao proof
	session.state.dao_heart = AmountCompat.from_number(25.0)
	session.state.dao_proof = 4

	# Learn lifespan_extension (cost: 10)
	var learn_res := session.learn_talent("lifespan_extension")
	ok = _expect(bool(learn_res["ok"]), "Learning lifespan_extension should succeed") and ok
	ok = _expect_equal(session.state.dao_heart.serialize(), "15", "Remaining dao heart should be 15") and ok
	ok = _expect_equal(int(session.state.talents.get("lifespan_extension", 0)), 1, "lifespan_extension level should be 1") and ok

	# Learn resource_inheritance (cost: 5)
	learn_res = session.learn_talent("resource_inheritance")
	ok = _expect(bool(learn_res["ok"]), "Learning resource_inheritance should succeed") and ok
	ok = _expect_equal(session.state.dao_heart.serialize(), "10", "Remaining dao heart should be 10") and ok
	ok = _expect_equal(int(session.state.talents.get("resource_inheritance", 0)), 1, "resource_inheritance level should be 1") and ok

	# Check multipliers
	var view := session.get_view()
	var mults: Dictionary = view["multipliers"]
	ok = _expect(float(mults["lifespan_bonus"]) >= 0.1, "Lifespan bonus should be at least 10%") and ok
	ok = _expect(float(mults["resource_inheritance_bonus"]) >= 0.1, "Resource inheritance bonus should be at least 10%") and ok
	ok = _expect(float(mults["dao_proof_bonus"]) > 0.0, "Dao proof bonus should be positive") and ok
	ok = _expect(float(mults["global_production_multiplier"]) > 1.0, "Global production multiplier should be > 1.0 with dao heart") and ok

	# Base era 1 lifespan is 4800s; with 10% bonus it should be floor(80 * 1.1) * 60 = 88 * 60 = 5280s
	var max_lifespan: float = float(view["max_lifespan_seconds"])
	ok = _expect_equal(int(max_lifespan), 5280, "Era 1 lifespan with talent should be 5280s") and ok

	return ok

func _test_persistence_roundtrip() -> bool:
	print("Testing persistence encode/decode roundtrip for reincarnation state...")
	var ok := true
	var state := GameState.new()
	state.revision = 7
	state.era_id = 1
	state.level = 2
	state.reincarnation_count = 3
	state.highest_era = 2
	state.dao_heart = AmountCompat.from_number(4200.0)
	state.dao_proof = 77
	state.talents = {"resource_inheritance": 2, "lifespan_extension": 1}
	state.resources["lingli"] = {
		"value": AmountCompat.from_number(88.0),
		"unlocked": true,
		"ever_obtained": true,
	}

	var meta := {
		"save_id": "m3a_test",
		"saved_at_utc_ms": "1700000000000",
		"settled_until_utc_ms": "1700000000000",
		"sim_tick": "100",
		"rng_streams": {},
	}

	var encoded := SaveCodec.encode(state, "content-v1", meta)
	ok = _expect(bool(encoded["ok"]), "SaveCodec encode should succeed") and ok

	var decoded := SaveCodec.decode(String(encoded["json"]))
	ok = _expect(bool(decoded["ok"]), "SaveCodec decode should succeed") and ok

	var restored: GameState = decoded["state"]
	ok = _expect_equal(restored.reincarnation_count, 3, "Restored reincarnation_count should match") and ok
	ok = _expect_equal(restored.highest_era, 2, "Restored highest_era should match") and ok
	ok = _expect_equal(restored.dao_heart.serialize(), "4200", "Restored dao_heart should match") and ok
	ok = _expect_equal(restored.dao_proof, 77, "Restored dao_proof should match") and ok
	ok = _expect_equal(int(restored.talents.get("resource_inheritance", 0)), 2, "Restored talent resource_inheritance should match") and ok
	ok = _expect_equal(int(restored.talents.get("lifespan_extension", 0)), 1, "Restored talent lifespan_extension should match") and ok

	return ok
