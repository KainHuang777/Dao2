extends SceneTree

func _init() -> void:
	print("\n--- Running M3-B Chrono System Runner (Weather & Shichen) ---")
	test_shichen_cycle_progression()
	test_weather_cycle_progression()
	test_multipliers_computation()
	test_time_advancer_integration()
	test_persistence_roundtrip()
	test_game_session_view()
	print("PASS: M3-B chrono system shichen progression, five-element weather cycle, multipliers, time advancer integration, persistence, and session view.\n")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: " + message)
		print("FAIL: " + message)
		quit(1)

func _setup_state_and_content() -> Dictionary:
	var content := ContentLoader.load_directory("res://content")["content"] as GameContent
	var state := GameState.new()
	state.era_id = 1
	state.level = 1
	state.onboarding_version = 1
	for r_id in content.resource_ids:
		state.resources[r_id] = {
			"value": AmountCompat.from_number(100.0),
			"unlocked": true,
			"ever_obtained": true,
		}
	ChronoSystem.unlock_chrono(state)
	return {"content": content, "state": state}

func test_shichen_cycle_progression() -> void:
	print("Testing Shichen 12-stage cycle progression...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	
	# t = 0s -> 子時 (index 0, day 1)
	ChronoSystem.ensure_initialized(state)
	var sc0 := ChronoSystem.get_current_shichen(state)
	_assert(int(sc0["name"] == "子時"), "0s should be 子時")
	_assert(int(sc0["day"]) == 1, "0s should be day 1")
	
	# t = 65s -> 丑時 (index 1)
	state.total_elapsed_seconds = 65.0
	ChronoSystem.tick(state, 65.0)
	var sc1 := ChronoSystem.get_current_shichen(state)
	_assert(int(sc1["name"] == "丑時"), "65s should be 丑時")
	
	# t = 180s -> 卯時 (index 3)
	state.total_elapsed_seconds = 180.0
	ChronoSystem.tick(state, 115.0)
	var sc3 := ChronoSystem.get_current_shichen(state)
	_assert(int(sc3["name"] == "卯時"), "180s should be 卯時")
	
	# t = 730s -> 子時 of day 2 (720s cycle)
	state.total_elapsed_seconds = 730.0
	ChronoSystem.tick(state, 550.0)
	var sc_day2 := ChronoSystem.get_current_shichen(state)
	_assert(int(sc_day2["name"] == "子時"), "730s should wrap to 子時")
	_assert(int(sc_day2["day"]) == 2, "730s should be day 2")

func test_weather_cycle_progression() -> void:
	print("Testing Five Elements Celestial Weather cycle...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	
	# 0s -> water (坎水運)
	state.total_elapsed_seconds = 0.0
	ChronoSystem.tick(state, 0.0)
	var w0 := ChronoSystem.get_current_weather(state)
	_assert(String(w0["id"]) == "water", "0s should be water weather (坎水運)")
	
	# 360s -> wood (巽木運)
	state.total_elapsed_seconds = 360.0
	ChronoSystem.tick(state, 360.0)
	var w1 := ChronoSystem.get_current_weather(state)
	_assert(String(w1["id"]) == "wood", "360s should be wood weather (巽木運)")
	
	# 720s -> fire (離火運)
	state.total_elapsed_seconds = 720.0
	ChronoSystem.tick(state, 360.0)
	var w2 := ChronoSystem.get_current_weather(state)
	_assert(String(w2["id"]) == "fire", "720s should be fire weather (離火運)")

func test_multipliers_computation() -> void:
	print("Testing Chrono multipliers computation...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	
	# t = 0s: 子時 (cultivation +10%) + 坎水運 (lingqi +15%)
	state.total_elapsed_seconds = 0.0
	ChronoSystem.tick(state, 0.0)
	var m0 := ChronoSystem.compute_multipliers(state)
	_assert(is_equal_approx(float(m0["cultivation_speed_bonus"]), 0.10), "子時 should give +10% cultivation speed")
	var spec0: Dictionary = m0["specific_resource_multipliers"]
	_assert(is_equal_approx(float(spec0.get("lingqi", 0.0)), 0.15), "坎水運 should give +15% lingqi production")
	
	# t = 360s: 午時 (index 6, global prod +10%) + 巽木運 (herb +25%, wood +15%)
	state.total_elapsed_seconds = 360.0
	ChronoSystem.tick(state, 360.0)
	var m1 := ChronoSystem.compute_multipliers(state)
	_assert(is_equal_approx(float(m1["global_production_multiplier"]), 0.10), "午時 should give +10% global prod")
	var spec1: Dictionary = m1["specific_resource_multipliers"]
	_assert(is_equal_approx(float(spec1.get("herb", 0.0)), 0.25), "巽木運 should give +25% herb")
	_assert(is_equal_approx(float(spec1.get("wood", 0.0)), 0.15), "巽木運 should give +15% wood")

func test_time_advancer_integration() -> void:
	print("Testing TimeAdvancer integration with Chrono...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]
	
	state.buildings["hut"] = 1 # Produces lingli
	state.total_elapsed_seconds = 0.0
	
	# Advance 10 seconds under 子時 (10% cultivation bonus) + 坎水運
	var initial_train: float = state.training_seconds
	var res := TimeAdvancer.advance(state, content, 10)
	_assert(int(res["ticks_advanced"]) == 10, "10 ticks advanced")
	
	# Cultivation speed should be >= 10 * 1.10 = 11.0
	var train_delta := state.training_seconds - initial_train
	_assert(train_delta >= 10.99, "Training speed boosted by 子時")
	_assert(state.chrono.has("shichen_index"), "Chrono state updated after advance")

func test_persistence_roundtrip() -> void:
	print("Testing Chrono persistence roundtrip with SaveCodec...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	state.total_elapsed_seconds = 200.0
	ChronoSystem.tick(state, 200.0)
	
	var meta := {
		"save_id": "test_chrono_save",
		"saved_at_utc_ms": "1700000000000",
		"settled_until_utc_ms": "1700000000000",
		"sim_tick": "200",
		"rng_streams": {}
	}
	
	var enc := SaveCodec.encode(state, "content_v1", meta)
	_assert(bool(enc.get("ok", false)), "SaveCodec.encode should succeed with chrono state")
	
	var dec := SaveCodec.decode(String(enc["json"]))
	_assert(bool(dec.get("ok", false)), "SaveCodec.decode should succeed")
	var loaded_state: GameState = dec["state"]
	_assert(loaded_state.chrono is Dictionary, "Loaded state should have chrono Dictionary")
	_assert(int(loaded_state.chrono.get("shichen_index", -1)) == int(state.chrono.get("shichen_index", -2)), "shichen_index restored accurately")
	_assert(String(loaded_state.chrono.get("weather_id", "")) == String(state.chrono.get("weather_id", "")), "weather_id restored accurately")

func test_game_session_view() -> void:
	print("Testing GameSession get_view() exposes chrono...")
	var content := ContentLoader.load_directory("res://content")["content"] as GameContent
	var session := GameSession.create_new_game(content)
	var view := session.get_view()
	_assert(view.has("chrono"), "session view must contain chrono")
	var ch: Dictionary = view["chrono"]
	_assert(ch.has("shichen") and ch.has("weather") and ch.has("multipliers"), "chrono view must have shichen, weather, multipliers")
