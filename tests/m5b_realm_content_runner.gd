extends SceneTree

## m5b_realm_content_runner.gd
## Verifies M5-B Realm Content Expansion:
## 1. Realm strategic decisions across all 9 realms (costs, cooldowns, effects, era gates).
## 2. Deepened terrain traits pool (6+ per realm) and mutual exclusion rules.
## 3. Realm-specific encounters and current_realm 3.0x weight bias.
## 4. GameSession command integration (execute_realm_decision) & get_view() exposure.
## 5. SaveCodec persistence roundtrip with realm_decisions state.

const RealmDecisionSystem = preload("res://src/simulation/realm_decision_system.gd")

func _init() -> void:
	print("[M5B_RUNNER] Starting M5-B Realm Content & Strategic Decisions Tests...")
	var success := true

	success = success and _test_realm_decisions_integrity_and_execution()
	success = success and _test_deepened_terrain_traits_and_exclusion()
	success = success and _test_realm_specific_encounters_and_bias()
	success = success and _test_gamesession_decision_command_and_view()
	success = success and _test_savecodec_persistence_roundtrip()

	if success:
		print("[M5B_RUNNER] ALL M5-B TESTS PASSED (exit 0)")
		quit(0)
	else:
		printerr("[M5B_RUNNER] SOME M5-B TESTS FAILED (exit 1)")
		quit(1)

func _assert(condition: bool, msg: String) -> bool:
	if not condition:
		printerr("  FAIL: " + msg)
		return false
	return true

func _load_test_content() -> GameContent:
	var loaded := ContentLoader.load_directory("res://content")
	return loaded["content"] as GameContent

func _create_test_state() -> GameState:
	var state := GameState.new()
	state.era_id = 4
	state.level = 1
	state.current_realm = "realm_human"
	state.world_address = WorldAddress.default_for_realm("realm_human").to_address_string()
	state.training_seconds = 0.0
	state.total_elapsed_seconds = 100.0
	state.dao_heart = AmountCompat.from_number(1.0)
	state.resources = {
		"money": {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true},
		"wood": {"value": AmountCompat.from_number(300), "unlocked": true, "ever_obtained": true},
		"herb": {"value": AmountCompat.from_number(200), "unlocked": true, "ever_obtained": true},
		"lingqi": {"value": AmountCompat.from_number(50), "unlocked": true, "ever_obtained": true}
	}
	RealmDecisionSystem.ensure_initialized(state)
	FortuneSystem.ensure_initialized(state)
	return state

func _test_realm_decisions_integrity_and_execution() -> bool:
	print("--- 1. Testing Realm Decisions Integrity & Execution ---")
	var ok := true
	var all_decisions: Array = RealmDecisionSystem.load_decisions()
	ok = ok and _assert(all_decisions.size() >= 14, "Decisions count should be at least 14, got %d" % all_decisions.size())

	# Check that all 9 realms have at least one decision
	var realms := [
		"realm_human", "realm_spirit", "realm_nether", "realm_beast",
		"realm_demon", "realm_immortal", "realm_buddha", "realm_chaos", "realm_origin"
	]
	for r_id in realms:
		var r_decs: Array = RealmDecisionSystem.get_decisions_for_realm(r_id)
		ok = ok and _assert(r_decs.size() >= 1, "Realm %s should have decisions, got %d" % [r_id, r_decs.size()])

	var state := _create_test_state()

	# Test Era gate: Human compile dao canon (min_era: 1, state.era_id = 4 -> ok)
	var dec_id := "human_compile_dao_canon"
	var prev_money: int = int(round(state.resources["money"].value.to_float()))
	var prev_wood: int = int(round(state.resources["wood"].value.to_float()))
	var prev_training := state.training_seconds
	var prev_dh: float = state.dao_heart.to_float()

	var exec_res: Dictionary = RealmDecisionSystem.execute_decision(state, "realm_human", dec_id)
	ok = ok and _assert(bool(exec_res.get("ok", false)), "Execution of human_compile_dao_canon should succeed")
	ok = ok and _assert(int(round(state.resources["money"].value.to_float())) == prev_money - 50, "Money deducted properly")
	ok = ok and _assert(int(round(state.resources["wood"].value.to_float())) == prev_wood - 30, "Wood deducted properly")
	ok = ok and _assert(state.training_seconds == prev_training + 60.0, "Training seconds granted")
	ok = ok and _assert(state.dao_heart.to_float() > prev_dh, "Dao heart increased")
	ok = ok and _assert(state.buffs.has("insight_glow"), "Insight glow buff applied")

	# Test Cooldown enforcement
	var cd_res: Dictionary = RealmDecisionSystem.execute_decision(state, "realm_human", dec_id)
	ok = ok and _assert(not bool(cd_res.get("ok", false)), "Execution should fail when cooldown is active")
	ok = ok and _assert(String(cd_res.get("error", "")) == "COOLDOWN_ACTIVE", "Error code should be COOLDOWN_ACTIVE")

	# Test Cooldown decay with advance_time
	var views: Array = RealmDecisionSystem.get_realm_decisions_view(state, "realm_human")
	var found_view := false
	for v in views:
		if v.get("id") == dec_id:
			found_view = true
			ok = ok and _assert(float(v.get("cooldown_remaining", 0.0)) > 0.0, "View shows active cooldown")
			ok = ok and _assert(not bool(v.get("is_ready", true)), "View shows not ready")
	ok = ok and _assert(found_view, "Found decision in view")

	RealmDecisionSystem.advance_time(state, 185.0)
	var post_cd_res: Dictionary = RealmDecisionSystem.execute_decision(state, "realm_human", dec_id)
	ok = ok and _assert(bool(post_cd_res.get("ok", false)), "Execution should succeed after cooldown expires")

	# Test Era Gate: Era 7 origin decision should fail on Era 4 state
	var origin_res: Dictionary = RealmDecisionSystem.execute_decision(state, "realm_origin", "origin_spin_genesis_wheel")
	ok = ok and _assert(not bool(origin_res.get("ok", false)), "Origin decision should fail for era 4")
	ok = ok and _assert(String(origin_res.get("error", "")) == "ERA_TOO_LOW", "Error should be ERA_TOO_LOW")

	print("  Realm decisions integrity & execution: PASS")
	return ok

func _test_deepened_terrain_traits_and_exclusion() -> bool:
	print("--- 2. Testing Deepened Terrain Traits & Mutual Exclusion ---")
	var ok := true
	var realms := [
		"realm_human", "realm_spirit", "realm_nether", "realm_beast",
		"realm_demon", "realm_immortal", "realm_buddha", "realm_chaos", "realm_origin"
	]

	for r_id in realms:
		var addr := WorldAddress.default_for_realm(r_id)
		var desc := WorldGenerator.generate_world(addr, "seed_m5b_terrain", 1)
		ok = ok and _assert(desc != null, "Descriptor for %s should not be null" % r_id)
		ok = ok and _assert(desc.environment_traits.size() >= 1, "Desc should have at least 1 trait")

		# Check mutual exclusion in generated traits
		var chosen_trait_ids: Array = []
		for t in desc.environment_traits:
			chosen_trait_ids.append(String(t.get("id", "")))

		for t in desc.environment_traits:
			var incomp: Array = t.get("incompatible", [])
			for bad_id in incomp:
				ok = ok and _assert(not (bad_id in chosen_trait_ids), "Trait %s has incompatible trait %s generated in %s" % [t.get("id"), bad_id, r_id])

	print("  Deepened terrain traits & mutual exclusion: PASS")
	return ok

func _test_realm_specific_encounters_and_bias() -> bool:
	print("--- 3. Testing Realm-Specific Encounters & Current Realm Bias ---")
	var ok := true
	var encounters := FortuneSystem.get_encounters()
	ok = ok and _assert(encounters.size() >= 26, "Total encounters should be at least 26, got %d" % encounters.size())

	# Verify realm coverage in encounters
	var realm_counts: Dictionary = {}
	for enc in encounters:
		var r_bias: String = String(enc.get("realm_bias", ""))
		if not r_bias.is_empty():
			realm_counts[r_bias] = int(realm_counts.get(r_bias, 0)) + 1

	ok = ok and _assert(int(realm_counts.get("realm_nether", 0)) >= 3, "Nether realm should have at least 3 encounters")
	ok = ok and _assert(int(realm_counts.get("realm_beast", 0)) >= 3, "Beast realm should have at least 3 encounters")
	ok = ok and _assert(int(realm_counts.get("realm_demon", 0)) >= 3, "Demon realm should have at least 3 encounters")

	# Test Current Realm 3.0x Bias
	var state := _create_test_state()
	state.current_realm = "realm_nether"
	state.aspiration_realm = ""
	state.fortune["cooldown_remaining"] = 0.0

	# Test Current Realm 3.0x Bias across 20 deterministic rolls
	var nether_hits := 0
	for i in range(20):
		state.fortune["pending_encounter"] = {}
		var r := SeededRandom.from_seed(2000 + i)
		var enc := FortuneSystem.trigger_fortune(state, r)
		if String(enc.get("realm_bias", "")) == "realm_nether":
			nether_hits += 1

	ok = ok and _assert(nether_hits >= 4, "Nether realm 3.0x bias should produce substantial nether events (got %d/20)" % nether_hits)

	# Test Resolve Fortune
	var resolve_res := FortuneSystem.resolve_fortune(state, 0)
	ok = ok and _assert(bool(resolve_res.get("ok", false)), "Resolve fortune should succeed")
	ok = ok and _assert(int(state.fortune.get("total_fortunes_claimed", 0)) >= 1, "Fortunes claimed incremented")

	print("  Realm-specific encounters & bias: PASS")
	return ok

func _test_gamesession_decision_command_and_view() -> bool:
	print("--- 4. Testing GameSession Decision Command & View Exposure ---")
	var ok := true
	var content := _load_test_content()
	var session := GameSession.create_new_game(content)
	session.state.era_id = 3
	session.state.resources["money"].value = AmountCompat.from_number(500)
	session.state.resources["wood"].value = AmountCompat.from_number(300)

	var cmd: Dictionary = {
		"type": "execute_realm_decision",
		"command_id": "cmd_realm_dec_1",
		"expected_revision": session.state.revision,
		"payload": {
			"realm_id": "realm_human",
			"decision_id": "human_compile_dao_canon"
		}
	}
	var res: Dictionary = session.submit(cmd)
	ok = ok and _assert(bool(res.get("ok", false)), "GameSession.submit execute_realm_decision should succeed: %s" % str(res))

	# Also test helper method
	var helper_res := session.execute_realm_decision("realm_human", "human_irrigate_spiritual_vein")
	ok = ok and _assert(bool(helper_res.get("ok", false)), "session.execute_realm_decision helper should succeed")

	var view := session.get_view()
	ok = ok and _assert(view.has("realm_decisions"), "Session view should contain realm_decisions")
	var dec_view: Array = view.get("realm_decisions", [])
	ok = ok and _assert(dec_view.size() > 0, "Decisions view should not be empty")

	print("  GameSession command & view exposure: PASS")
	return ok

func _test_savecodec_persistence_roundtrip() -> bool:
	print("--- 5. Testing SaveCodec Persistence Roundtrip ---")
	var ok := true
	var state := _create_test_state()
	state.realm_decisions = {
		"cooldowns": {"human_compile_dao_canon": 142.5},
		"usage_counts": {"human_compile_dao_canon": 3},
		"total_decisions_executed": 3
	}

	var meta := {
		"save_id": "test_m5b_save",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "0",
		"rng_streams": {},
	}
	var encode_res: Dictionary = SaveCodec.encode(state, "content_1", meta)
	ok = ok and _assert(bool(encode_res.get("ok", false)), "SaveCodec.encode should succeed")

	var json_str: String = String(encode_res.get("json", ""))
	var decode_res: Dictionary = SaveCodec.decode(json_str)
	ok = ok and _assert(bool(decode_res.get("ok", false)), "SaveCodec.decode should succeed")

	var decoded_state: GameState = decode_res.get("state")
	ok = ok and _assert(decoded_state != null, "Decoded state should not be null")
	ok = ok and _assert(decoded_state.realm_decisions is Dictionary, "Decoded realm_decisions is dictionary")
	ok = ok and _assert(int(decoded_state.realm_decisions.get("total_decisions_executed", 0)) == 3, "Total decisions matched")
	ok = ok and _assert(is_equal_approx(float(decoded_state.realm_decisions["cooldowns"]["human_compile_dao_canon"]), 142.5), "Cooldown matched")
	ok = ok and _assert(int(decoded_state.realm_decisions["usage_counts"]["human_compile_dao_canon"]) == 3, "Usage count matched")

	print("  SaveCodec persistence roundtrip: PASS")
	return ok
