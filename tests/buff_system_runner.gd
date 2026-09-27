extends SceneTree

func _init() -> void:
	print("\n--- Running Buff System Runner ---")
	test_buff_lifecycle_and_tick()
	test_multipliers_and_production_boost()
	test_cultivation_and_lifespan_boost()
	test_breakthrough_auto_buff()
	test_persistence_roundtrip()
	test_reincarnation_buff_filtering()
	test_buff_hud_bar_ui()
	print("PASS: Buff system definition, decay, multipliers, breakthrough trigger, persistence, reincarnation, and HUD bar.\n")
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
	return {"content": content, "state": state}

func test_buff_lifecycle_and_tick() -> void:
	print("Testing BUFF lifecycle, refresh, and time tick decay...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]

	# Apply spirit_surge
	var res := BuffSystem.apply_buff(state, "spirit_surge", 100.0)
	_assert(bool(res.get("ok", false)), "apply_buff spirit_surge should succeed")
	_assert(state.buffs.has("spirit_surge"), "state should contain spirit_surge")
	var b_entry: Dictionary = state.buffs["spirit_surge"]
	_assert(is_equal_approx(float(b_entry["remaining_seconds"]), 100.0), "remaining_seconds should be 100")

	# Refresh buff with shorter duration shouldn't decrease remaining
	BuffSystem.apply_buff(state, "spirit_surge", 50.0)
	_assert(is_equal_approx(float(state.buffs["spirit_surge"]["remaining_seconds"]), 100.0), "remaining_seconds should not decrease on shorter reapply")

	# Refresh buff with longer duration should extend
	BuffSystem.apply_buff(state, "spirit_surge", 150.0)
	_assert(is_equal_approx(float(state.buffs["spirit_surge"]["remaining_seconds"]), 150.0), "remaining_seconds should extend to 150")

	# Apply permanent buff
	BuffSystem.apply_buff(state, "turtle_breath")
	_assert(state.buffs.has("turtle_breath"), "state should contain turtle_breath")
	_assert(bool(state.buffs["turtle_breath"]["is_permanent"]), "turtle_breath should be permanent")

	# Advance 50 seconds
	var tick_res := BuffSystem.tick(state, 50.0)
	_assert(tick_res["expired"].is_empty(), "no buffs should expire after 50s")
	_assert(is_equal_approx(float(state.buffs["spirit_surge"]["remaining_seconds"]), 100.0), "spirit_surge remaining should be 100s after 50s tick")
	_assert(state.buffs.has("turtle_breath"), "permanent buff remains unaffected by tick")

	# Advance remaining 100s -> spirit_surge should expire
	var tick_res2 := BuffSystem.tick(state, 100.0)
	_assert(tick_res2["expired"].has("spirit_surge"), "spirit_surge should be reported in expired list")
	_assert(not state.buffs.has("spirit_surge"), "spirit_surge should be removed from buffs")
	_assert(state.buffs.has("turtle_breath"), "turtle_breath still remains")

func test_multipliers_and_production_boost() -> void:
	print("Testing BUFF production multipliers and specific resource bonus in TimeAdvancer...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]

	state.buildings["hut"] = 2
	state.resources["lingli"]["value"] = AmountCompat.zero()
	state.resources["wood"]["value"] = AmountCompat.zero()

	# Run 10 ticks without buff
	var state_no_buff := state.duplicate_state()
	TimeAdvancer.advance(state_no_buff, content, 10)
	var lingli_base: float = state_no_buff.resources["lingli"]["value"].to_float()
	_assert(lingli_base > 0.0, "base lingli should increase")

	# Run 10 ticks with spirit_surge (+30% global prod, +50% lingli)
	BuffSystem.apply_buff(state, "spirit_surge", 60.0)
	TimeAdvancer.advance(state, content, 10)
	var lingli_boosted: float = state.resources["lingli"]["value"].to_float()

	# (1.0 + 0.3) * (1.0 + 0.5) = 1.95x base rate
	_assert(lingli_boosted > lingli_base * 1.5, "boosted lingli should be significantly higher than base")

func test_cultivation_and_lifespan_boost() -> void:
	print("Testing BUFF cultivation speed and lifespan extension...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]

	# Cultivation test with epiphany (+100% cultivation)
	state.training_seconds = 0.0
	var state_no_buff := state.duplicate_state()
	TimeAdvancer.advance(state_no_buff, content, 10)
	var training_base := state_no_buff.training_seconds

	BuffSystem.apply_buff(state, "epiphany", 60.0)
	TimeAdvancer.advance(state, content, 10)
	var training_boosted := state.training_seconds

	_assert(is_equal_approx(training_boosted, training_base * 2.0), "epiphany should double cultivation rate")

	# Lifespan test with turtle_breath (+10 years)
	var mults_before := BuffSystem.compute_multipliers(state)
	BuffSystem.apply_buff(state, "turtle_breath")
	var mults_after := BuffSystem.compute_multipliers(state)
	_assert(is_equal_approx(float(mults_after["lifespan_bonus_years"]), 10.0), "turtle_breath should add 10 years lifespan")

func test_breakthrough_auto_buff() -> void:
	print("Testing automatic breakthrough_resonance buff upon era breakthrough...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]

	# Set up state ready for breakthrough to Era 2
	state.era_id = 1
	state.level = 10
	state.training_seconds = 1000.0
	state.buildings["storage_lingli"] = 5 # Provide enough lingli capacity

	var cmd := {
		"type": "breakthrough_era",
		"payload": {}
	}
	var res := CommandProcessor.apply(content, state, cmd)
	_assert(bool(res.get("ok", false)), "breakthrough_era command should succeed")
	_assert(state.era_id == 2, "era_id should now be 2")
	_assert(state.buffs.has("breakthrough_resonance"), "breakthrough_resonance BUFF should be automatically granted on breakthrough")
	_assert(is_equal_approx(float(state.buffs["breakthrough_resonance"]["remaining_seconds"]), 120.0), "breakthrough_resonance duration should be 120s")

func test_persistence_roundtrip() -> void:
	print("Testing SaveCodec encode and decode roundtrip with BUFFs...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	BuffSystem.apply_buff(state, "spirit_surge", 123.4)
	BuffSystem.apply_buff(state, "turtle_breath")

	var meta := {
		"save_id": "test_buff",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "0",
	}
	var enc_res := SaveCodec.encode(state, "test_v1", meta)
	_assert(bool(enc_res.get("ok", false)), "SaveCodec.encode should succeed")
	var json_text: String = enc_res["json"]

	var decode_res := SaveCodec.decode(json_text)
	_assert(bool(decode_res.get("ok", false)), "SaveCodec decode should succeed: " + str(decode_res.get("error", "")))
	var loaded_state: GameState = decode_res["state"]
	_assert(loaded_state.buffs.has("spirit_surge"), "loaded state should have spirit_surge")
	_assert(is_equal_approx(float(loaded_state.buffs["spirit_surge"]["remaining_seconds"]), 123.4), "loaded spirit_surge remaining_seconds should match")
	_assert(loaded_state.buffs.has("turtle_breath"), "loaded state should have turtle_breath")

	# Test backward compatibility without buffs field
	var envelope: Dictionary = JSON.parse_string(json_text)
	var legacy_snapshot: Dictionary = envelope["state"]
	legacy_snapshot.erase("buffs")
	envelope["state"] = legacy_snapshot
	envelope.erase("checksum")
	envelope["checksum"] = SaveCodec.compute_checksum(envelope)
	var legacy_decode := SaveCodec.decode(JSON.stringify(envelope))
	_assert(bool(legacy_decode.get("ok", false)), "SaveCodec should decode legacy snapshot missing buffs field: " + str(legacy_decode.get("error", "")))
	var legacy_state: GameState = legacy_decode["state"]
	_assert(legacy_state.buffs.is_empty(), "legacy state buffs should default to empty dict")

func test_reincarnation_buff_filtering() -> void:
	print("Testing ReincarnationRules clearing mortal buffs and preserving transmigratable buffs...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]

	state.era_id = 2
	state.level = 1
	state.buildings["hut"] = 10

	# Normal buff
	BuffSystem.apply_buff(state, "spirit_surge", 300.0, {}, false)
	# Transmigratable buff (e.g. Dao imprint)
	BuffSystem.apply_buff(state, "dao_mark", 0.0, {"production_multiplier": 0.05}, true)
	state.buffs["dao_mark"]["is_permanent"] = true

	_assert(state.buffs.has("spirit_surge") and state.buffs.has("dao_mark"), "both buffs applied")

	var res := ReincarnationRules.apply_reincarnation(state, content, "normal")
	_assert(bool(res.get("ok", false)), "reincarnation should succeed")
	_assert(not state.buffs.has("spirit_surge"), "normal buff spirit_surge should be wiped upon reincarnation")
	_assert(state.buffs.has("dao_mark"), "transmigratable buff dao_mark should survive reincarnation")

func test_buff_hud_bar_ui() -> void:
	print("Testing BuffHudBar UI node rendering and responsive hide/show...")
	var hud_bar := BuffHudBar.new()

	# When empty, should be invisible
	hud_bar.update_buffs([])
	_assert(hud_bar.visible == false, "BuffHudBar should be hidden when buffs array is empty")
	_assert(hud_bar.get_child_count() == 0, "BuffHudBar should have 0 children when empty")

	# With 2 active buffs
	var active := [
		{
			"id": "spirit_surge",
			"name": "天靈氣湧",
			"icon_text": "湧",
			"color": "#4fe3c1",
			"description": "全產率 +30%",
			"is_permanent": false,
			"remaining_seconds": 295.4,
			"formatted_remaining": "04:56",
			"effects": {"production_multiplier": 0.3}
		},
		{
			"id": "turtle_breath",
			"name": "長生龜息",
			"icon_text": "壽",
			"color": "#77f29b",
			"description": "壽元 +10 祀",
			"is_permanent": true,
			"remaining_seconds": 0.0,
			"formatted_remaining": "常駐",
			"effects": {"lifespan_bonus_years": 10.0}
		}
	]
	hud_bar.update_buffs(active)
	_assert(hud_bar.visible == true, "BuffHudBar should be visible when buffs are present")
	_assert(hud_bar.get_child_count() == 2, "BuffHudBar should instantiate 2 badge containers")

	# Re-empty
	hud_bar.update_buffs([])
	_assert(hud_bar.visible == false, "BuffHudBar should hide again when buffs clear")
	_assert(hud_bar.get_child_count() == 0, "BuffHudBar children should be cleaned up")

	hud_bar.free()
