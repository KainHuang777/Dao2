extends SceneTree

## m3b_spirit_beast_runner.gd
## Verifies M3-B Spirit Beast System:
## 1. Beast configurations, era unlocking, and acquisition rules.
## 2. Feeding mechanics, resource deduction, cooldowns, and stage progression (egg -> young -> growing -> mature).
## 3. Beast talents tree, soul costs, pre-requisite tiers, and discount/boost effects.
## 4. Reincarnation settlement (mature beast grants beast soul, active beast resets, souls/talents persist).
## 5. Multipliers calculation and TimeAdvancer simulation integration.
## 6. GameSession commands and SaveCodec persistence roundtrip.

const BeastSystem = preload("res://src/simulation/beast_system.gd")

func _init() -> void:
	print("[M3B_BEAST_RUNNER] Starting M3-B Spirit Beast System Tests...")
	var success := true

	success = success and _test_beast_configs_and_acquire()
	success = success and _test_beast_feeding_and_stages()
	success = success and _test_beast_talents_and_souls()
	success = success and _test_reincarnation_beast_souls()
	success = success and _test_gamesession_beast_integration()
	success = success and _test_savecodec_beast_roundtrip()

	if success:
		print("[M3B_BEAST_RUNNER] ALL M3-B SPIRIT BEAST TESTS PASSED (exit 0)")
		quit(0)
	else:
		printerr("[M3B_BEAST_RUNNER] SOME M3-B SPIRIT BEAST TESTS FAILED (exit 1)")
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
	state.era_id = 3
	state.level = 1
	state.current_realm = "realm_human"
	state.world_address = WorldAddress.default_for_realm("realm_human").to_address_string()
	state.training_seconds = 0.0
	state.total_elapsed_seconds = 100.0
	state.dao_heart = AmountCompat.from_number(1.0)
	state.resources = {
		"money": {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true},
		"wood": {"value": AmountCompat.from_number(300), "unlocked": true, "ever_obtained": true},
		"stone_low": {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true},
		"refined_iron": {"value": AmountCompat.from_number(200), "unlocked": true, "ever_obtained": true},
		"spirit_grass_low": {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true},
		"spirit_grass_1000y": {"value": AmountCompat.from_number(50), "unlocked": true, "ever_obtained": true},
		"void_essence": {"value": AmountCompat.from_number(50), "unlocked": true, "ever_obtained": true},
		"star_metal": {"value": AmountCompat.from_number(50), "unlocked": true, "ever_obtained": true},
		"lingqi": {"value": AmountCompat.from_number(50), "unlocked": true, "ever_obtained": true}
	}
	BeastSystem.ensure_initialized(state)
	return state

func _test_beast_configs_and_acquire() -> bool:
	print("--- 1. Testing Beast Configurations & Acquisition ---")
	var ok := true
	ok = ok and _assert(BeastSystem.BEAST_CONFIGS.size() == 4, "Must have 4 defined beasts")
	ok = ok and _assert(BeastSystem.BEAST_CONFIGS.has("jade_fox"), "Must include jade_fox")
	ok = ok and _assert(BeastSystem.BEAST_CONFIGS.has("iron_turtle"), "Must include iron_turtle")
	ok = ok and _assert(BeastSystem.BEAST_CONFIGS.has("fire_phoenix"), "Must include fire_phoenix")
	ok = ok and _assert(BeastSystem.BEAST_CONFIGS.has("cloud_serpent"), "Must include cloud_serpent")

	var state := _create_test_state()
	state.era_id = 1 # Low era

	# Attempt to acquire jade_fox (requires era 3) at era 1
	var low_era_res := BeastSystem.acquire_beast(state, "jade_fox")
	ok = ok and _assert(not bool(low_era_res.ok), "Should reject jade_fox when era is too low")
	ok = ok and _assert(String(low_era_res.error) == "INSUFFICIENT_ERA", "Error should be INSUFFICIENT_ERA")

	# Advance era to 3
	state.era_id = 3
	var acq_res := BeastSystem.acquire_beast(state, "jade_fox")
	ok = ok and _assert(bool(acq_res.ok), "Should acquire jade_fox successfully at era 3")
	var active := BeastSystem.get_active_beast(state)
	ok = ok and _assert(String(active.get("id", "")) == "jade_fox", "Active beast ID should be jade_fox")
	ok = ok and _assert(String(active.get("stage", "")) == "egg", "Initial stage must be egg")
	ok = ok and _assert(int(active.get("exp", 0)) == 0, "Initial exp must be 0")

	# Try to acquire another beast in same life
	var duplicate_res := BeastSystem.acquire_beast(state, "iron_turtle")
	ok = ok and _assert(not bool(duplicate_res.ok), "Should reject second beast in same life")
	ok = ok and _assert(String(duplicate_res.error) == "ALREADY_HAS_ACTIVE_BEAST", "Error should be ALREADY_HAS_ACTIVE_BEAST")

	print("  Beast configs & acquisition: " + ("PASS" if ok else "FAIL"))
	return ok

func _test_beast_feeding_and_stages() -> bool:
	print("--- 2. Testing Beast Feeding, Cooldowns & Stage Progression ---")
	var ok := true
	var state := _create_test_state()
	state.era_id = 3
	var _acq := BeastSystem.acquire_beast(state, "jade_fox")

	# Initial feed (cost 50 spirit_grass_low)
	var prev_grass: float = (state.resources["spirit_grass_low"]["value"] as AmountCompat).to_float()
	var feed1 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed1.ok), "Initial feed should succeed")
	var new_grass: float = (state.resources["spirit_grass_low"]["value"] as AmountCompat).to_float()
	ok = ok and _assert(is_equal_approx(prev_grass - new_grass, 50.0), "Feed should deduct exactly 50 spirit_grass_low")

	var beast := BeastSystem.get_active_beast(state)
	ok = ok and _assert(int(beast.exp) == 50, "Exp should increase by 50 to 50")
	ok = ok and _assert(String(beast.stage) == "egg", "At 50 exp stage should still be egg")

	# Attempt feed while on cooldown
	var feed_cd := BeastSystem.feed_beast(state)
	ok = ok and _assert(not bool(feed_cd.ok), "Feeding during cooldown must fail")
	ok = ok and _assert(String(feed_cd.error) == "FEED_ON_COOLDOWN", "Error must be FEED_ON_COOLDOWN")

	# Reset cooldown
	state.beasts["cooldown_remaining"] = 0.0

	# Feed again -> 100 exp -> should reach 'young' stage
	var feed2 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed2.ok), "Second feed should succeed")
	beast = BeastSystem.get_active_beast(state)
	ok = ok and _assert(int(beast.exp) == 100, "Exp should be 100")
	ok = ok and _assert(String(beast.stage) == "young", "Stage should upgrade to young at 100 exp")

	# Boost exp to 500 (growing) and 1000 (mature)
	beast["exp"] = 490
	state.beasts["cooldown_remaining"] = 0.0
	var feed3 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed3.ok), "Feed 3 should succeed")
	beast = BeastSystem.get_active_beast(state)
	ok = ok and _assert(int(beast.exp) >= 500, "Exp should be >= 500")
	ok = ok and _assert(String(beast.stage) == "growing", "Stage should advance to growing at 500 exp")

	beast["exp"] = 990
	state.beasts["cooldown_remaining"] = 0.0
	var feed4 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed4.ok), "Feed 4 should succeed")
	beast = BeastSystem.get_active_beast(state)
	ok = ok and _assert(int(beast.exp) >= 1000, "Exp should be >= 1000")
	ok = ok and _assert(String(beast.stage) == "mature", "Stage should advance to mature at 1000 exp")

	# Mature beast cannot be fed further
	state.beasts["cooldown_remaining"] = 0.0
	var feed_mature := BeastSystem.feed_beast(state)
	ok = ok and _assert(not bool(feed_mature.ok), "Mature beast cannot be fed further")
	ok = ok and _assert(String(feed_mature.error) == "BEAST_ALREADY_MATURE", "Error should be BEAST_ALREADY_MATURE")

	# Insufficient resource test
	state.resources["spirit_grass_low"]["value"] = AmountCompat.from_number(5.0)
	var state_starve := _create_test_state()
	state_starve.era_id = 3
	BeastSystem.acquire_beast(state_starve, "jade_fox")
	state_starve.resources["spirit_grass_low"]["value"] = AmountCompat.from_number(5.0)
	var feed_starve := BeastSystem.feed_beast(state_starve)
	ok = ok and _assert(not bool(feed_starve.ok), "Feeding without sufficient materials must fail")
	ok = ok and _assert(String(feed_starve.error) == "INSUFFICIENT_FEED_RESOURCE", "Error should be INSUFFICIENT_FEED_RESOURCE")

	print("  Feeding, cooldowns & stages: " + ("PASS" if ok else "FAIL"))
	return ok

func _test_beast_talents_and_souls() -> bool:
	print("--- 3. Testing Beast Talents Tree, Costs & Effects ---")
	var ok := true
	var state := _create_test_state()

	# Initially 0 souls
	var unlock_no_souls := BeastSystem.unlock_talent(state, "fox_t1_boost")
	ok = ok and _assert(not bool(unlock_no_souls.ok), "Should fail unlock with 0 beast souls")
	ok = ok and _assert(String(unlock_no_souls.error) == "INSUFFICIENT_BEAST_SOULS", "Error should be INSUFFICIENT_BEAST_SOULS")

	# Grant souls
	state.beast_souls["jade_fox"] = 10

	# Try unlock tier 2 directly without tier 1
	var unlock_t2_early := BeastSystem.unlock_talent(state, "fox_t2_speed")
	ok = ok and _assert(not bool(unlock_t2_early.ok), "Should fail unlock tier 2 without tier 1")
	ok = ok and _assert(String(unlock_t2_early.error) == "PREV_TIER_REQUIRED", "Error should be PREV_TIER_REQUIRED")

	# Unlock tier 1 (cost 1)
	var unlock_t1 := BeastSystem.unlock_talent(state, "fox_t1_boost")
	ok = ok and _assert(bool(unlock_t1.ok), "Unlock tier 1 should succeed")
	ok = ok and _assert(int(state.beast_souls["jade_fox"]) == 9, "Souls should decrease from 10 to 9")
	ok = ok and _assert(int(state.beast_talents["fox_t1_boost"]) == 1, "Talent should be marked unlocked")

	# Cannot unlock twice
	var duplicate_unlock := BeastSystem.unlock_talent(state, "fox_t1_boost")
	ok = ok and _assert(not bool(duplicate_unlock.ok), "Cannot unlock same talent twice")
	ok = ok and _assert(String(duplicate_unlock.error) == "TALENT_ALREADY_UNLOCKED", "Error should be TALENT_ALREADY_UNLOCKED")

	# Unlock tier 2 (cost 2)
	var unlock_t2 := BeastSystem.unlock_talent(state, "fox_t2_speed")
	ok = ok and _assert(bool(unlock_t2.ok), "Unlock tier 2 should succeed")
	ok = ok and _assert(int(state.beast_souls["jade_fox"]) == 7, "Souls should decrease from 9 to 7")

	# Test T2 effect (exp gain +30% -> base 50 becomes 65)
	state.era_id = 3
	BeastSystem.acquire_beast(state, "jade_fox")
	var feed_t2 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed_t2.ok), "Feed with T2 talent should succeed")
	ok = ok and _assert(int(feed_t2.exp_gained) == 65, "Exp gained should be 65 (+30% of 50)")

	# Unlock tier 3 (cost 3)
	var unlock_t3 := BeastSystem.unlock_talent(state, "fox_t3_cheap")
	ok = ok and _assert(bool(unlock_t3.ok), "Unlock tier 3 should succeed")
	ok = ok and _assert(int(state.beast_souls["jade_fox"]) == 4, "Souls should decrease from 7 to 4")

	# Test T3 effect (cost discount 40% -> 50 * 0.6 = 30)
	state.beasts["cooldown_remaining"] = 0.0
	var prev_grass: float = (state.resources["spirit_grass_low"]["value"] as AmountCompat).to_float()
	var feed_t3 := BeastSystem.feed_beast(state)
	ok = ok and _assert(bool(feed_t3.ok), "Feed with T3 discount should succeed")
	var cur_grass: float = (state.resources["spirit_grass_low"]["value"] as AmountCompat).to_float()
	ok = ok and _assert(is_equal_approx(prev_grass - cur_grass, 30.0), "Feed cost should be 30 (40% discount on 50)")

	# Unlock tier 4 (cost 5, currently have 4) -> should fail then succeed
	var unlock_t4_fail := BeastSystem.unlock_talent(state, "fox_t4_passive")
	ok = ok and _assert(not bool(unlock_t4_fail.ok), "Should fail tier 4 when souls (4) < cost (5)")
	state.beast_souls["jade_fox"] += 1
	var unlock_t4 := BeastSystem.unlock_talent(state, "fox_t4_passive")
	ok = ok and _assert(bool(unlock_t4.ok), "Unlock tier 4 should succeed with 5 souls")
	ok = ok and _assert(int(state.beast_souls["jade_fox"]) == 0, "Souls should be 0")

	# Test T4 passive bonus
	var mults := BeastSystem.compute_multipliers(state)
	ok = ok and _assert(is_equal_approx(float(mults.production_herb), 0.10), "T4 talent should grant +10% herb production")

	print("  Talents tree & effects: " + ("PASS" if ok else "FAIL"))
	return ok

func _test_reincarnation_beast_souls() -> bool:
	print("--- 4. Testing Reincarnation Settlement with Beast Souls ---")
	var ok := true
	var content := _load_test_content()
	var state := _create_test_state()
	state.era_id = 4
	state.buildings["rebirth_lotus"] = 1 # Allow reincarnation

	# 1. Reincarnating with NO beast or IMMATURE beast
	BeastSystem.acquire_beast(state, "jade_fox")
	var beast := BeastSystem.get_active_beast(state)
	beast["stage"] = "growing"

	var res_growing := ReincarnationRules.apply_reincarnation(state, content)
	ok = ok and _assert(bool(res_growing.ok), "Reincarnation should succeed")
	ok = ok and _assert(int(state.beast_souls.get("jade_fox", 0)) == 0, "Immature beast should NOT grant beast soul")
	ok = ok and _assert(BeastSystem.get_active_beast(state).is_empty(), "Active beast should be cleared after reincarnation")

	# 2. Reincarnating with MATURE beast
	state.era_id = 4
	state.buildings["rebirth_lotus"] = 1
	BeastSystem.acquire_beast(state, "jade_fox")
	beast = BeastSystem.get_active_beast(state)
	beast["stage"] = "mature"

	var res_mature := ReincarnationRules.apply_reincarnation(state, content)
	ok = ok and _assert(bool(res_mature.ok), "Reincarnation with mature beast should succeed")
	ok = ok and _assert(int(state.beast_souls.get("jade_fox", 0)) == 1, "Mature beast MUST grant 1 beast soul on reincarnation")
	ok = ok and _assert(BeastSystem.get_active_beast(state).is_empty(), "Active beast should be cleared")

	# Events check
	var events: Array = res_mature.get("events", [])
	ok = ok and _assert(events.size() > 0, "Must produce reincarnation event")
	var rein_ev: Dictionary = events[0]
	var gained_souls: Dictionary = rein_ev.get("gained_beast_souls", {})
	ok = ok and _assert(int(gained_souls.get("jade_fox", 0)) == 1, "Event must record gained_beast_souls")

	print("  Reincarnation beast soul settlement: " + ("PASS" if ok else "FAIL"))
	return ok

func _test_gamesession_beast_integration() -> bool:
	print("--- 5. Testing GameSession Beast Commands & Time Advancement ---")
	var ok := true
	var content := _load_test_content()
	var session := GameSession.create_new_game(content)
	session.state.era_id = 3
	for res_id in ["money", "wood", "spirit_grass_low", "stone_low", "refined_iron"]:
		session.state.resources[res_id] = {
			"value": AmountCompat.from_number(1000.0),
			"unlocked": true,
			"ever_obtained": true
		}

	# Command: acquire_beast
	var acq_res := session.acquire_beast("jade_fox")
	ok = ok and _assert(bool(acq_res.ok), "GameSession acquire_beast should succeed")
	var active := BeastSystem.get_active_beast(session.state)
	ok = ok and _assert(String(active.get("id", "")) == "jade_fox", "Active beast should be jade_fox")

	# Command: feed_beast
	var feed_res := session.feed_beast()
	ok = ok and _assert(bool(feed_res.ok), "GameSession feed_beast should succeed")
	ok = ok and _assert(float(session.state.beasts.get("cooldown_remaining", 0.0)) > 200.0, "Cooldown should be set")

	# Time advancement: cooldown decrements
	var initial_cd: float = float(session.state.beasts["cooldown_remaining"])
	session.advance_time(50.0)
	var after_cd: float = float(session.state.beasts["cooldown_remaining"])
	ok = ok and _assert(is_equal_approx(initial_cd - after_cd, 50.0), "advance_time(50) should decrement cooldown by 50s")

	# Give souls and test talent command
	session.state.beast_souls["jade_fox"] = 5
	var talent_res := session.unlock_beast_talent("fox_t1_boost")
	ok = ok and _assert(bool(talent_res.ok), "GameSession unlock_beast_talent should succeed")
	ok = ok and _assert(int(session.state.beast_talents.get("fox_t1_boost", 0)) == 1, "Talent fox_t1_boost should be unlocked")

	print("  GameSession commands & simulation integration: " + ("PASS" if ok else "FAIL"))
	return ok

func _test_savecodec_beast_roundtrip() -> bool:
	print("--- 6. Testing SaveCodec Roundtrip with Beast State ---")
	var ok := true
	var state := _create_test_state()
	state.era_id = 4
	BeastSystem.acquire_beast(state, "iron_turtle")
	var beast := BeastSystem.get_active_beast(state)
	beast["stage"] = "growing"
	beast["exp"] = 750
	state.beasts["cooldown_remaining"] = 123.45
	state.beast_souls["iron_turtle"] = 3
	state.beast_souls["jade_fox"] = 2
	state.beast_talents["turtle_t1_boost"] = 1

	var snapshot := state.to_snapshot_dict()
	ok = ok and _assert(snapshot.has("beasts"), "Snapshot must include beasts")
	ok = ok and _assert(snapshot.has("beast_souls"), "Snapshot must include beast_souls")
	ok = ok and _assert(snapshot.has("beast_talents"), "Snapshot must include beast_talents")

	# Encode and decode via SaveCodec
	var meta := {
		"game_version": "0.1.0",
		"content_version": "v1.0",
		"rules_version": "v1.0",
		"save_id": "slot_test",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "100",
		"rng_streams": {}
	}
	var encode_res := SaveCodec.encode(state, "v1.0", meta)
	ok = ok and _assert(bool(encode_res.ok), "SaveCodec.encode should succeed")

	var decode_res := SaveCodec.decode(String(encode_res.json))
	ok = ok and _assert(bool(decode_res.ok), "SaveCodec.decode should succeed")
	var loaded_state: GameState = decode_res.state

	var loaded_active := BeastSystem.get_active_beast(loaded_state)
	ok = ok and _assert(String(loaded_active.get("id", "")) == "iron_turtle", "Loaded beast ID must be iron_turtle")
	ok = ok and _assert(String(loaded_active.get("stage", "")) == "growing", "Loaded stage must be growing")
	ok = ok and _assert(int(loaded_active.get("exp", 0)) == 750, "Loaded exp must be 750")
	ok = ok and _assert(is_equal_approx(float(loaded_state.beasts.get("cooldown_remaining", 0.0)), 123.45), "Loaded cooldown matches")
	ok = ok and _assert(int(loaded_state.beast_souls.get("iron_turtle", 0)) == 3, "Loaded beast souls match")
	ok = ok and _assert(int(loaded_state.beast_talents.get("turtle_t1_boost", 0)) == 1, "Loaded beast talent matches")

	# Test backward compatibility: snapshot without beasts
	var legacy_snapshot: Dictionary = snapshot.duplicate(true)
	legacy_snapshot.erase("beasts")
	legacy_snapshot.erase("beast_souls")
	legacy_snapshot.erase("beast_talents")
	var legacy_state_res: Dictionary = SaveCodec._state_from_snapshot(legacy_snapshot)
	ok = ok and _assert(bool(legacy_state_res.ok), "Should decode legacy snapshot without beast keys")
	var leg_state: GameState = legacy_state_res.state
	BeastSystem.ensure_initialized(leg_state)
	ok = ok and _assert(BeastSystem.get_active_beast(leg_state).is_empty(), "Legacy state active beast should be empty")

	print("  SaveCodec roundtrip & backward compatibility: " + ("PASS" if ok else "FAIL"))
	return ok
