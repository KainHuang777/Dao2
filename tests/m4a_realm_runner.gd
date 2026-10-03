extends SceneTree

func _init() -> void:
	print("\n--- Running M4-A Realm Runner (Spirit Realm & Dual-Realm Parity) ---")
	test_unlock_gating()
	test_realm_switching_and_return_home()
	test_outpost_upgrades_and_costs()
	test_dual_realm_parallel_tick_and_opportunity_cost()
	test_cross_realm_cultivation_feedback()
	test_persistence_roundtrip()
	test_teleport_modal_ui()
	print("PASS: M4-A spirit realm unlock, dual-realm parallel simulation, opportunity costs, feedback boost, persistence, and modal UI.\n")
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
			"value": AmountCompat.from_number(200.0),
			"unlocked": true,
			"ever_obtained": true,
		}
	return {"content": content, "state": state}

func test_unlock_gating() -> void:
	print("Testing Spirit Realm unlock conditions...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]

	# Era 1, 0 reincarnations -> locked
	_assert(not RealmSystem.is_spirit_realm_unlocked(state), "spirit realm should be locked initially in Era 1")
	var switch_res := RealmSystem.switch_realm(state, "realm_spirit")
	_assert(not bool(switch_res.get("ok", false)), "switching to locked spirit realm should fail")

	# Era 2 -> unlocked
	state.era_id = 2
	_assert(RealmSystem.is_spirit_realm_unlocked(state), "spirit realm should unlock when reaching Era 2")

	# Era 1 with reincarnation_count = 1 -> unlocked
	state.era_id = 1
	state.reincarnation_count = 1
	_assert(RealmSystem.is_spirit_realm_unlocked(state), "spirit realm should unlock after reincarnation")

func test_realm_switching_and_return_home() -> void:
	print("Testing realm switching and seamless return to human abode...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	state.era_id = 2

	_assert(state.current_realm == "realm_human", "initial realm should be human")

	# Switch to spirit realm
	var res1 := RealmSystem.switch_realm(state, "realm_spirit")
	_assert(bool(res1.get("ok", false)), "switch to spirit realm should succeed")
	_assert(state.current_realm == "realm_spirit", "current realm should now be spirit")

	# Return to human realm
	var res2 := RealmSystem.switch_realm(state, "realm_human")
	_assert(bool(res2.get("ok", false)), "return to human realm should succeed")
	_assert(state.current_realm == "realm_human", "current realm should return to human")

func test_outpost_upgrades_and_costs() -> void:
	print("Testing Spirit Realm outpost construction and upgrades...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	state.era_id = 2
	RealmSystem.ensure_spirit_data(state)

	# Upgrade celestial_hub (costs money: 100, stone_low: 50)
	var can_upg := RealmSystem.can_upgrade_outpost(state, "celestial_hub")
	_assert(bool(can_upg.get("can_upgrade", false)), "can_upgrade celestial_hub should be true with sufficient resources")

	var upg_res := RealmSystem.upgrade_outpost(state, "celestial_hub")
	_assert(bool(upg_res.get("ok", false)), "upgrade_outpost celestial_hub should succeed")
	var data: Dictionary = state.realms_data["realm_spirit"]
	_assert(int(data["outposts"]["celestial_hub"]) == 1, "celestial_hub level should be 1")

	# Test max level cap
	data["outposts"]["celestial_hub"] = 10
	var cap_check := RealmSystem.can_upgrade_outpost(state, "celestial_hub")
	_assert(not bool(cap_check.get("can_upgrade", false)), "upgrading capped outpost should fail")
	_assert(String(cap_check.get("reason", "")) == "MAX_LEVEL", "reason should be MAX_LEVEL")

func test_dual_realm_parallel_tick_and_opportunity_cost() -> void:
	print("Testing parallel dual-realm tick simulation and stone consumption opportunity cost...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]
	state.era_id = 2

	# Activate celestial_hub lv 1
	var data := RealmSystem.ensure_spirit_data(state)
	data["outposts"]["celestial_hub"] = 1
	state.resources["stone_low"]["value"] = AmountCompat.from_number(10.0)

	# Regardless of whether player is currently viewing human or spirit realm, tick runs in parallel!
	state.current_realm = "realm_human"
	var prev_stone: float = (state.resources["stone_low"]["value"] as AmountCompat).to_float()
	TimeAdvancer.advance(state, content, 5)

	# 5 seconds: celestial_hub consumes 0.2 stone/s * 5 = 1.0 stone, produces 0.1 crystal/s * 5 = 0.5 crystal
	var cur_crystal := float(data.get("spirit_crystal", 0.0))
	_assert(cur_crystal >= 0.49, "celestial_hub should produce spirit_crystal in parallel during human view")
	var cur_stone: float = (state.resources["stone_low"]["value"] as AmountCompat).to_float()
	_assert(cur_stone < prev_stone, "celestial_hub should consume human stone_low as opportunity cost")

	# Test pure_pool converting crystal to nectar (temporarily disable celestial_hub to isolate pure_pool consumption)
	data["outposts"]["celestial_hub"] = 0
	data["outposts"]["pure_pool"] = 1
	data["spirit_crystal"] = 10.0
	data["azure_nectar"] = 0.0
	state.current_realm = "realm_spirit"
	TimeAdvancer.advance(state, content, 10)
	var cur_nectar := float(data.get("azure_nectar", 0.0))
	_assert(cur_nectar >= 0.49, "pure_pool should produce azure_nectar in parallel")
	_assert(float(data.get("spirit_crystal", 0.0)) < 10.0, "pure_pool should consume spirit_crystal")

func test_cross_realm_cultivation_feedback() -> void:
	print("Testing pure pool cultivation feedback boost to human cultivation speed...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	var content: GameContent = ctx["content"]
	state.era_id = 2
	var data := RealmSystem.ensure_spirit_data(state)

	# Baseline training rate without pure_pool
	data["outposts"]["pure_pool"] = 0
	state.training_seconds = 0.0
	TimeAdvancer.advance(state, content, 10)
	var base_training := state.training_seconds

	# With pure_pool lv 2 (+30% cultivation speed feedback)
	data["outposts"]["pure_pool"] = 2
	state.training_seconds = 0.0
	TimeAdvancer.advance(state, content, 10)
	var boosted_training := state.training_seconds

	_assert(boosted_training > base_training * 1.25, "pure_pool should significantly boost cultivation speed across realms")

func test_persistence_roundtrip() -> void:
	print("Testing SaveCodec encode and decode roundtrip with dual-realm data...")
	var ctx := _setup_state_and_content()
	var state: GameState = ctx["state"]
	state.era_id = 2
	state.current_realm = "realm_spirit"
	var data := RealmSystem.ensure_spirit_data(state)
	data["spirit_crystal"] = 88.5
	data["azure_nectar"] = 42.0
	data["outposts"]["celestial_hub"] = 3
	data["outposts"]["pure_pool"] = 2

	var meta := {
		"save_id": "test_realm",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "0",
	}
	var enc_res := SaveCodec.encode(state, "test_v1", meta)
	_assert(bool(enc_res.get("ok", false)), "SaveCodec.encode should succeed")
	var json_text: String = enc_res["json"]

	var decode_res := SaveCodec.decode(json_text)
	_assert(bool(decode_res.get("ok", false)), "SaveCodec decode should succeed")
	var loaded_state: GameState = decode_res["state"]
	_assert(loaded_state.current_realm == "realm_spirit", "loaded current_realm should match")
	var loaded_data: Dictionary = loaded_state.realms_data.get("realm_spirit", {})
	_assert(is_equal_approx(float(loaded_data["spirit_crystal"]), 88.5), "spirit_crystal balance should persist")
	_assert(is_equal_approx(float(loaded_data["azure_nectar"]), 42.0), "azure_nectar balance should persist")
	_assert(int(loaded_data["outposts"]["celestial_hub"]) == 3, "outpost level should persist")

	# Backward compatibility test without realm fields
	var env: Dictionary = JSON.parse_string(json_text)
	var legacy_snapshot: Dictionary = env["state"]
	legacy_snapshot.erase("current_realm")
	legacy_snapshot.erase("realms_data")
	env["state"] = legacy_snapshot
	env.erase("checksum")
	env["checksum"] = SaveCodec.compute_checksum(env)
	var legacy_decode := SaveCodec.decode(JSON.stringify(env))
	_assert(bool(legacy_decode.get("ok", false)), "SaveCodec decode legacy save without realm fields should succeed")
	var legacy_state: GameState = legacy_decode["state"]
	_assert(legacy_state.current_realm == "realm_human", "default current_realm should be realm_human")

func test_teleport_modal_ui() -> void:
	print("Testing RealmTeleportModal node rendering and state refresh...")
	var modal := RealmTeleportModal.new()
	var view := {
		"realm": {
			"current_realm": "realm_spirit",
			"unlocked": true,
			"spirit_crystal": 50.0,
			"azure_nectar": 20.0,
			"crystal_cap": 200.0,
			"nectar_cap": 100.0,
			"cultivation_feedback_boost": 0.30,
			"outposts": [
				{
					"id": "celestial_hub",
					"name": "天樞陣眼",
					"description": "維繫跨界靈脈",
					"level": 2,
					"max_level": 10,
					"costs": {"stone_low": 20.0},
					"can_upgrade": true,
				},
				{
					"id": "pure_pool",
					"name": "化靈仙池",
					"description": "凝練仙液",
					"level": 1,
					"max_level": 10,
					"costs": {"spirit_crystal": 10.0},
					"can_upgrade": false,
				}
			]
		}
	}
	modal.refresh(view)
	_assert(modal._outpost_cards_box.get_child_count() == 2, "modal should render 2 outpost cards")
	var stable_card := modal._outpost_cards_box.get_child(0)
	modal.refresh(view)
	_assert(modal._outpost_cards_box.get_child(0) == stable_card, "unchanged realm updates preserve clickable outpost cards")
	_assert(modal._teleport_button.text.contains("返回祖基仙府"), "teleport button should prompt return when in spirit realm")

	# Refresh as human realm
	view["realm"]["current_realm"] = "realm_human"
	modal.refresh(view)
	_assert(modal._teleport_button.text.contains("跨界神遊"), "teleport button should prompt enter when in human realm")

	modal.free()
