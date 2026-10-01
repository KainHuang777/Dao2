extends SceneTree

const FortuneSystem = preload("res://src/simulation/fortune_system.gd")

func _init() -> void:
	print("\n--- Running M3-B Fortune & Encounter System Runner ---")
	test_era_cooldown_contracts()
	test_advance_time_and_trigger()
	test_aspiration_and_weather_bias()
	test_resolve_fortune_rewards_and_costs()
	test_session_and_command_integration()
	test_save_codec_roundtrip()
	test_reincarnation_reset()
	print("PASS: M3-B fortune cooldown contracts, trigger, bias, resolution, persistence, and reincarnation.\n")
	quit(0)

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: " + msg)
		print("FAIL: " + msg)
		quit(1)

func _create_test_state() -> GameState:
	var state := GameState.new()
	state.era_id = 1
	state.level = 1
	state.resources["lingqi"] = {"value": AmountCompat.from_number(100.0), "unlocked": true, "ever_obtained": true}
	state.resources["money"] = {"value": AmountCompat.from_number(100.0), "unlocked": true, "ever_obtained": true}
	state.resources["herb"] = {"value": AmountCompat.from_number(50.0), "unlocked": true, "ever_obtained": true}
	state.resources["wood"] = {"value": AmountCompat.from_number(50.0), "unlocked": true, "ever_obtained": true}
	FortuneSystem.ensure_initialized(state)
	return state

func test_era_cooldown_contracts() -> void:
	print("Testing era cooldown and max-per-hour contracts...")
	_assert(FortuneSystem.compute_max_per_hour(1) == 1, "Era 1 max per hour must be 1")
	_assert(FortuneSystem.compute_max_per_hour(2) == 2, "Era 2 max per hour must be 2")
	_assert(FortuneSystem.compute_max_per_hour(3) == 3, "Era 3 max per hour must be 3")
	_assert(FortuneSystem.compute_max_per_hour(10) == 10, "Era 10 max per hour must be 10")

	_assert(is_equal_approx(FortuneSystem.compute_cooldown_for_era(1), 3600.0), "Era 1 cooldown must be 3600s (1h)")
	_assert(is_equal_approx(FortuneSystem.compute_cooldown_for_era(2), 1800.0), "Era 2 cooldown must be 1800s (30m)")
	_assert(is_equal_approx(FortuneSystem.compute_cooldown_for_era(3), 1200.0), "Era 3 cooldown must be 1200s (20m)")
	_assert(is_equal_approx(FortuneSystem.compute_cooldown_for_era(6), 600.0), "Era 6 cooldown must be 600s (10m)")

func test_advance_time_and_trigger() -> void:
	print("Testing advance_time and pending encounter cooldown pause...")
	var state := _create_test_state()
	state.era_id = 3
	state.fortune["cooldown_remaining"] = 1200.0

	# Advance 500s
	var res := FortuneSystem.advance_time(state, 500.0)
	_assert(not res.triggered, "Should not trigger yet")
	_assert(is_equal_approx(float(state.fortune["cooldown_remaining"]), 700.0), "Remaining should be 700s")

	# Advance 701s -> triggers
	var rng := SeededRandom.from_seed(42)
	res = FortuneSystem.advance_time(state, 701.0, rng)
	_assert(res.triggered, "Should trigger encounter")
	_assert(not (state.fortune["pending_encounter"] as Dictionary).is_empty(), "Pending encounter should be populated")
	_assert(is_equal_approx(float(state.fortune["cooldown_remaining"]), 1200.0), "Cooldown should reset to Era 3 cooldown")

	# Advance time while pending encounter is present -> cooldown remains paused
	res = FortuneSystem.advance_time(state, 300.0)
	_assert(not res.triggered, "Should not trigger while pending")
	_assert(is_equal_approx(float(state.fortune["cooldown_remaining"]), 1200.0), "Cooldown must pause while pending encounter exists")

func test_aspiration_and_weather_bias() -> void:
	print("Testing celestial aspiration and weather bias weights...")
	var state := _create_test_state()
	state.era_id = 2
	state.aspiration_realm = "realm_nether"
	ChronoSystem.ensure_initialized(state)
	state.chrono["current_weather"] = "water"

	# With seed 100, trigger fortune
	var rng := SeededRandom.from_seed(100)
	var enc := FortuneSystem.trigger_fortune(state, rng)
	_assert(not enc.is_empty(), "Encounter should be triggered")
	_assert(state.fortune.encounter_history_count == 1, "Encounter history count should increment")

func test_resolve_fortune_rewards_and_costs() -> void:
	print("Testing resolve_fortune rewards, costs, and state mutation...")
	var state := _create_test_state()
	state.fortune["pending_encounter"] = {
		"id": "enc_test",
		"title": "測試奇遇",
		"options": [
			{
				"text": "選項1：無消耗得資源與修為",
				"costs": {},
				"rewards": {
					"resources": {"money": 50, "herb": 20},
					"training_seconds": 45.0,
					"buff_id": "insight_glow",
					"log_text": "成功領悟！"
				}
			},
			{
				"text": "選項2：需花費 200 靈石",
				"costs": {"money": 200},
				"rewards": {
					"pills": {"cultivation_pill": 2},
					"log_text": "購得靈丹！"
				}
			}
		]
	}

	# Test option 1 (no cost)
	var init_money: float = state.resources["money"].value.to_float()
	var init_herb: float = state.resources["herb"].value.to_float()
	var init_training: float = state.training_seconds

	var res := FortuneSystem.resolve_fortune(state, 0)
	_assert(res.ok, "Option 0 should succeed")
	_assert((state.fortune["pending_encounter"] as Dictionary).is_empty(), "Pending encounter should be cleared")
	_assert(state.fortune.total_fortunes_claimed == 1, "Claimed count should increment")
	_assert(is_equal_approx(state.resources["money"].value.to_float(), init_money + 50.0), "Money should increase by 50")
	_assert(is_equal_approx(state.resources["herb"].value.to_float(), init_herb + 20.0), "Herb should increase by 20")
	_assert(is_equal_approx(state.training_seconds, init_training + 45.0), "Training seconds should increase by 45")
	_assert(state.buffs.has("insight_glow"), "Insight glow buff should be applied")

	# Test option 2 with insufficient funds
	state.fortune["pending_encounter"] = {
		"id": "enc_test2",
		"options": [
			{
				"text": "貴重的選項",
				"costs": {"money": 99999.0},
				"rewards": {}
			}
		]
	}
	var fail_res := FortuneSystem.resolve_fortune(state, 0)
	_assert(not fail_res.ok, "Should fail due to insufficient money")
	_assert(fail_res.error.begins_with("INSUFFICIENT_RESOURCE"), "Error should reflect insufficient resource")
	_assert(not (state.fortune["pending_encounter"] as Dictionary).is_empty(), "Pending encounter must remain uncleared upon failure")

func _load_test_content() -> GameContent:
	var loaded := ContentLoader.load_directory("res://content")
	return loaded.content

func test_session_and_command_integration() -> void:
	print("Testing GameSession submit commands and get_view for fortune...")
	var content := _load_test_content()
	var session := GameSession.create_new_game(content)
	FortuneSystem.ensure_initialized(session.state)

	# Session view exposes fortune
	var view := session.get_view()
	_assert(view.has("fortune"), "Session get_view must expose fortune")
	_assert(view.fortune.has("cooldown_remaining"), "fortune view must have cooldown_remaining")
	_assert(view.fortune.max_per_hour == 1, "Era 1 max per hour must be 1")

	# Trigger via session command
	var cmd_res := session.trigger_fortune()
	_assert(cmd_res.ok, "Session trigger_fortune command should succeed")
	_assert(session.state.fortune.pending_encounter.size() > 0, "Pending encounter should be set")

	# Resolve via session command
	var res_cmd := session.resolve_fortune(0)
	_assert(res_cmd.ok, "Session resolve_fortune command should succeed")
	_assert(session.state.fortune.total_fortunes_claimed == 1, "Total claimed should be 1")

func test_save_codec_roundtrip() -> void:
	print("Testing SaveCodec encode and decode roundtrip with fortune...")
	var state := _create_test_state()
	state.fortune = {
		"cooldown_remaining": 888.5,
		"pending_encounter": {"id": "enc_ancient_cave", "title": "古仙殘府遺址"},
		"encounter_history_count": 5,
		"total_fortunes_claimed": 3
	}

	var snapshot := state.to_snapshot_dict()
	_assert(snapshot.has("fortune"), "Snapshot must include fortune")

	var meta := {
		"save_id": "test_save",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "0",
		"rng_streams": {},
	}
	var encode_res := SaveCodec.encode(state, "content_1", meta)
	_assert(encode_res.ok, "Encode save should succeed")

	var decode_res := SaveCodec.decode(encode_res.json)
	_assert(decode_res.ok, "Decode save should succeed")
	var decoded_state: GameState = decode_res.state
	_assert(decoded_state.fortune is Dictionary, "Decoded state must have fortune dictionary")
	_assert(is_equal_approx(float(decoded_state.fortune["cooldown_remaining"]), 888.5), "cooldown_remaining should match")
	_assert(decoded_state.fortune["encounter_history_count"] == 5, "history count should match")
	_assert(decoded_state.fortune["total_fortunes_claimed"] == 3, "claimed count should match")
	_assert(decoded_state.fortune["pending_encounter"]["id"] == "enc_ancient_cave", "pending encounter id should match")

func test_reincarnation_reset() -> void:
	print("Testing ReincarnationRules reset of fortune...")
	var content := _load_test_content()
	var state := _create_test_state()
	state.era_id = 3
	state.buildings["rebirth_lotus"] = 1
	state.fortune = {
		"cooldown_remaining": 300.0,
		"pending_encounter": {"id": "enc_ancient_cave"},
		"encounter_history_count": 8,
		"total_fortunes_claimed": 6
	}

	var res := ReincarnationRules.apply_reincarnation(state, content, "normal")
	_assert(res.ok, "Reincarnation must succeed")
	_assert(state.era_id == 1, "Era should reset to 1")
	_assert(state.fortune.pending_encounter.is_empty(), "Pending encounter must be cleared on rebirth")
	_assert(is_equal_approx(float(state.fortune.cooldown_remaining), 3600.0), "Cooldown should reset to Era 1 (3600s)")
	_assert(state.fortune.encounter_history_count == 8, "History count must be preserved")
	_assert(state.fortune.total_fortunes_claimed == 6, "Claimed count must be preserved")
