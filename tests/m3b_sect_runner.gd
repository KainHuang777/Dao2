class_name M3bSectRunner
extends SceneTree

func _init() -> void:
	print("\n--- Running M3-B Sect System Runner (Expeditions, Techniques & Market) ---")
	test_unlock_and_join()
	test_expedition_lifecycle()
	test_techniques_and_multipliers()
	test_market_purchases()
	test_save_codec_roundtrip()
	test_reincarnation_behavior()
	print("PASS: M3-B sect unlock, expeditions, techniques, market, multipliers, persistence, and reincarnation.")
	quit(0)

func _create_test_state() -> GameState:
	var state := GameState.new()
	state.era_id = 1
	state.level = 1
	state.reincarnation_count = 0
	state.resources["money"] = {"value": AmountCompat.from_number(1000.0), "unlocked": true, "ever_obtained": true}
	state.resources["lingqi"] = {"value": AmountCompat.from_number(50.0), "unlocked": true, "ever_obtained": true}
	state.resources["wood"] = {"value": AmountCompat.from_number(500.0), "unlocked": true, "ever_obtained": true}
	state.resources["stone_low"] = {"value": AmountCompat.from_number(100.0), "unlocked": true, "ever_obtained": true}
	state.resources["herb"] = {"value": AmountCompat.from_number(200.0), "unlocked": true, "ever_obtained": true}
	return state

func test_unlock_and_join() -> void:
	print("Testing sect unlock conditions and joining...")
	var state := _create_test_state()
	
	# Era 1 and 0 reincarnations -> locked
	assert(not SectSystem.is_unlocked(state), "Should be locked in Era 1 without reincarnation")
	var join_fail := SectSystem.join_sect(state)
	assert(not bool(join_fail.get("ok", false)), "Should fail joining when locked")
	assert(join_fail.get("error", "") == "SECT_LOCKED", "Error should be SECT_LOCKED")
	
	# Unlock via reincarnation
	state.reincarnation_count = 1
	assert(SectSystem.is_unlocked(state), "Should be unlocked with reincarnation_count >= 1")
	
	# Or unlock via Era 2
	state.reincarnation_count = 0
	state.era_id = 2
	assert(SectSystem.is_unlocked(state), "Should be unlocked in Era 2")
	
	# Join sect
	var join_ok := SectSystem.join_sect(state, "紫霄玄門")
	assert(bool(join_ok.get("ok", false)), "Joining sect should succeed")
	assert(state.sect.get("sect_name", "") == "紫霄玄門", "Sect name should be set")
	assert(bool(state.sect.get("unlocked", false)), "Sect should be marked unlocked")
	assert(state.sect.get("available_tasks", []).size() == SectSystem.EXPEDITION_SLOTS, "Should generate tasks upon joining")
	
	# Cannot join again
	var join_again := SectSystem.join_sect(state)
	assert(not bool(join_again.get("ok", false)), "Cannot join sect twice")

func test_expedition_lifecycle() -> void:
	print("Testing expedition task start, time advance, and claim...")
	var state := _create_test_state()
	state.era_id = 2
	SectSystem.join_sect(state, "太虛天闕")
	
	var tasks: Array = state.sect.get("available_tasks", [])
	var initial_count: int = tasks.size()
	assert(initial_count > 0, "Tasks should exist")
	var first_task: Dictionary = tasks[0]
	var task_id: String = first_task["id"]
	var duration: int = first_task["duration"]
	
	# Start expedition
	var start_res := SectSystem.start_expedition(state, task_id)
	assert(bool(start_res.get("ok", false)), "Start expedition should succeed")
	assert(state.sect.get("active_expedition") != null, "Active expedition should be set")
	assert(state.sect.get("available_tasks", []).size() == initial_count - 1, "Task should be removed from available list")
	
	# Cannot start another while one is active
	var start_second := SectSystem.start_expedition(state, "dummy_id")
	assert(not bool(start_second.get("ok", false)), "Cannot start second expedition concurrently")
	
	# Try claim before finishing -> fail
	var claim_early := SectSystem.claim_expedition_reward(state)
	assert(not bool(claim_early.get("ok", false)), "Cannot claim incomplete expedition")
	assert(claim_early.get("error", "") == "EXPEDITION_NOT_FINISHED", "Error should be EXPEDITION_NOT_FINISHED")
	
	# Advance time via SectSystem.tick
	SectSystem.tick(state, float(duration))
	var active = state.sect.get("active_expedition")
	assert(int(active.get("elapsed", 0)) >= duration, "Elapsed should reach duration")
	
	# Claim reward
	var money_before: float = (state.resources["money"]["value"] as AmountCompat).to_float()
	var claim_res := SectSystem.claim_expedition_reward(state)
	assert(bool(claim_res.get("ok", false)), "Claim should succeed")
	assert(state.sect.get("active_expedition") == null, "Active expedition should be cleared")
	
	var money_after: float = (state.resources["money"]["value"] as AmountCompat).to_float()
	assert(money_after > money_before, "Money should have increased from task reward")
	
	var contrib_val := AmountCompat.try_parse(String(state.sect.get("contribution", "0")))
	assert(bool(contrib_val.get("ok", false)) and contrib_val["value"].to_float() > 0.0, "Contribution should be gained")

func test_techniques_and_multipliers() -> void:
	print("Testing sect technique learning and multipliers...")
	var state := _create_test_state()
	state.era_id = 2
	SectSystem.join_sect(state)
	
	# Grant sufficient contribution
	state.sect["contribution"] = "500"
	
	# Learn divine_farm (tier 1)
	var learn_farm := SectSystem.learn_technique(state, "divine_farm")
	assert(bool(learn_farm.get("ok", false)), "Should learn divine_farm")
	assert(int(state.sect["techniques"].get("divine_farm", 0)) == 1, "divine_farm level should be 1")
	
	# Learn breathing_method (tier 1)
	var learn_breath := SectSystem.learn_technique(state, "breathing_method")
	assert(bool(learn_breath.get("ok", false)), "Should learn breathing_method")
	
	# Check multipliers
	var mults := SectSystem.compute_multipliers(state)
	assert(is_equal_approx(float(mults["production_herb_wood"]), 0.10), "divine_farm should give 10% herb/wood boost")
	assert(is_equal_approx(float(mults["cultivation_speed_bonus"]), 0.02), "breathing_method should give 2% cultivation speed")
	
	# Insufficient contribution check
	state.sect["contribution"] = "0"
	var fail_contrib := SectSystem.learn_technique(state, "divine_farm")
	assert(not bool(fail_contrib.get("ok", false)), "Should fail with insufficient contribution")

func test_market_purchases() -> void:
	print("Testing sect market item exchange and limits...")
	var state := _create_test_state()
	state.era_id = 2
	SectSystem.join_sect(state)
	
	state.sect["contribution"] = "300"
	
	# Buy herb bundle
	var herb_before: float = (state.resources["herb"]["value"] as AmountCompat).to_float()
	var buy_herb := SectSystem.buy_market_item(state, "herb_bundle")
	assert(bool(buy_herb.get("ok", false)), "Buy herb bundle should succeed")
	var herb_after: float = (state.resources["herb"]["value"] as AmountCompat).to_float()
	assert(herb_after == herb_before + 50.0, "Herb should increase by 50")
	
	# Buy foundation pill
	var buy_pill := SectSystem.buy_market_item(state, "foundation_pill")
	assert(bool(buy_pill.get("ok", false)), "Buy foundation pill should succeed")
	assert(int(state.pills.get("foundation_pill", 0)) == 1, "Pill inventory should have 1 foundation_pill")

func test_save_codec_roundtrip() -> void:
	print("Testing SaveCodec roundtrip with sect state...")
	var state := _create_test_state()
	state.era_id = 2
	SectSystem.join_sect(state, "縹緲仙宮")
	state.sect["contribution"] = "250"
	state.sect["techniques"] = {"divine_farm": 2, "breathing_method": 1}
	
	var meta := {
		"save_id": "slot_1",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "0",
		"rng_streams": {},
	}
	var encode_res := SaveCodec.encode(state, "content-v1", meta)
	assert(bool(encode_res.get("ok", false)), "SaveCodec.encode should succeed")
	
	var decoded := SaveCodec.decode(String(encode_res.get("json", "")))
	assert(bool(decoded.get("ok", false)), "SaveCodec.decode should succeed")
	var decoded_state: GameState = decoded["state"]
	assert(decoded_state.sect is Dictionary, "Decoded state must contain sect")
	assert(String(decoded_state.sect.get("sect_name", "")) == "縹緲仙宮", "Sect name match")
	assert(String(decoded_state.sect.get("contribution", "0")) == "250", "Contribution match")
	assert(int(decoded_state.sect.get("techniques", {}).get("divine_farm", 0)) == 2, "Technique level match")

func test_reincarnation_behavior() -> void:
	print("Testing sect state reset on reincarnation...")
	var state := _create_test_state()
	state.era_id = 2
	SectSystem.join_sect(state)
	state.sect["active_expedition"] = {"id": "dummy", "elapsed": 10, "duration": 60}
	
	# Trigger reincarnation cleanup
	SectSystem.on_reincarnate(state)
	assert(state.sect.get("active_expedition") == null, "Active expedition should be cleared on reincarnation")
	assert(state.sect.get("available_tasks", []).is_empty(), "Available tasks should be cleared")
	assert(not bool(state.sect.get("unlocked", false)), "Sect unlocked status should reset for new mortal life")
