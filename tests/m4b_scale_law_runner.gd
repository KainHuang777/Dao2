extends SceneTree

const ContentLoaderScript = preload("res://src/content/content_loader.gd")
const GameStateScript = preload("res://src/domain/game_state.gd")
const WorldAddressScript = preload("res://src/domain/world_address.gd")
const ScaleLawContractScript = preload("res://src/simulation/scale_law_contract.gd")
const RealmSystemScript = preload("res://src/simulation/realm_system.gd")
const SaveCodecScript = preload("res://src/persistence/save_codec.gd")
const GameSessionScript = preload("res://src/application/game_session.gd")
const AmountCompatScript = preload("res://src/domain/amount_compat.gd")

func _init() -> void:
	print("--- Running M4-B Scale & Laws Runner ---")
	test_world_address_contract()
	test_spatial_scale_tiers_and_zoom()
	test_realms_data_loader_and_integrity()
	test_scale_law_contract_calculations()
	test_game_state_and_save_codec_persistence()
	test_realm_system_and_session_integration()
	print("--- M4-B Scale & Laws Runner: ALL PASS ---")
	quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		push_error("Assertion failed: " + msg)
		quit(1)

func assert_equal(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		push_error("Assertion failed: %s (expected %s, got %s)" % [msg, str(b), str(a)])
		quit(1)

func assert_approx(a: float, b: float, msg: String, tolerance: float = 0.001) -> void:
	if absf(a - b) > tolerance:
		push_error("Assertion failed: %s (expected %f, got %f, diff %f)" % [msg, b, a, absf(a - b)])
		quit(1)

func test_world_address_contract() -> void:
	print("Testing WorldAddress structure and parser...")
	var default_addr := WorldAddressScript.default_home()
	assert_true(default_addr.is_valid(), "Default home address should be valid")
	assert_equal(default_addr.to_address_string(), "universe_0/sector_human_0/realm_human/region_cloud_peak/loc_home_island", "Default address string mismatch")
	assert_true(default_addr.matches_realm("realm_human"), "Default address should match realm_human")

	# Parse 5-tier address
	var custom_str := "universe_9/sector_immortal_1/realm_immortal/region_nine_heavens/loc_palace"
	var parsed := WorldAddressScript.parse(custom_str)
	assert_equal(parsed.universe_seed, "universe_9", "Universe seed parse mismatch")
	assert_equal(parsed.sector_id, "sector_immortal_1", "Sector ID parse mismatch")
	assert_equal(parsed.world_id, "realm_immortal", "World ID parse mismatch")
	assert_equal(parsed.region_id, "region_nine_heavens", "Region ID parse mismatch")
	assert_equal(parsed.location_id, "loc_palace", "Location ID parse mismatch")
	assert_equal(parsed.to_address_string(), custom_str, "Roundtrip string mismatch")

	# Duplicate & Equality
	var dup := parsed.duplicate_address()
	assert_true(parsed.equals(dup), "Duplicate address should equal original")
	assert_true(parsed.matches_realm("realm_immortal"), "Parsed address should match realm_immortal")

	# Realm defaults
	var spirit_addr := WorldAddressScript.default_for_realm("realm_spirit")
	assert_equal(spirit_addr.world_id, "realm_spirit", "Spirit realm address world_id mismatch")
	var nether_addr := WorldAddressScript.default_for_realm("realm_nether")
	assert_equal(nether_addr.world_id, "realm_nether", "Nether realm address world_id mismatch")
	print("  WorldAddress contract: PASS")

func test_spatial_scale_tiers_and_zoom() -> void:
	print("Testing spatial ScaleTier mapping...")
	assert_equal(WorldAddressScript.ScaleTier.ABODE, 0, "Tier 0 is ABODE")
	assert_equal(WorldAddressScript.ScaleTier.REGION, 1, "Tier 1 is REGION")
	assert_equal(WorldAddressScript.ScaleTier.WORLD, 2, "Tier 2 is WORLD")
	assert_equal(WorldAddressScript.ScaleTier.SECTOR, 3, "Tier 3 is SECTOR")
	assert_equal(WorldAddressScript.ScaleTier.COSMOS, 4, "Tier 4 is COSMOS")

	# Zoom to Tier mapping
	assert_equal(WorldAddressScript.get_tier_for_zoom(0.70), WorldAddressScript.ScaleTier.ABODE, "Zoom 0.70 is ABODE")
	assert_equal(WorldAddressScript.get_tier_for_zoom(0.40), WorldAddressScript.ScaleTier.REGION, "Zoom 0.40 is REGION")
	assert_equal(WorldAddressScript.get_tier_for_zoom(0.20), WorldAddressScript.ScaleTier.WORLD, "Zoom 0.20 is WORLD")
	assert_equal(WorldAddressScript.get_tier_for_zoom(0.10), WorldAddressScript.ScaleTier.SECTOR, "Zoom 0.10 is SECTOR")
	assert_equal(WorldAddressScript.get_tier_for_zoom(0.08), WorldAddressScript.ScaleTier.COSMOS, "Zoom 0.08 is COSMOS")

	# Reference Zooms
	assert_approx(WorldAddressScript.get_reference_zoom(WorldAddressScript.ScaleTier.ABODE), 0.70, "Ref zoom ABODE mismatch")
	assert_approx(WorldAddressScript.get_reference_zoom(WorldAddressScript.ScaleTier.COSMOS), 0.08, "Ref zoom COSMOS mismatch")
	print("  ScaleTier mapping: PASS")

func test_realms_data_loader_and_integrity() -> void:
	print("Testing ContentLoader.load_realms data integrity...")
	var load_res := ContentLoaderScript.load_realms("res://content/realms/realms.json")
	assert_true(bool(load_res.get("ok", false)), "load_realms should succeed")
	var realms: Array = load_res.get("realms", [])
	assert_equal(realms.size(), 9, "Must contain all 9 canonical realms")

	var realm_ids: Dictionary = {}
	for entry in realms:
		var r_id: String = String(entry["id"])
		realm_ids[r_id] = entry
		var cult_factor: float = float(entry["cultivation_factor"])
		var lifespan_ratio: float = float(entry["lifespan_flow_ratio"])
		var pool_scale: float = float(entry["lingqi_pool_scale"])
		assert_true(cult_factor > 0.0 and is_finite(cult_factor), "cultivation_factor must be positive finite: " + r_id)
		assert_true(lifespan_ratio > 0.0 and is_finite(lifespan_ratio), "lifespan_flow_ratio must be positive finite: " + r_id)
		assert_true(pool_scale > 0.0 and is_finite(pool_scale), "lingqi_pool_scale must be positive finite: " + r_id)

	# Verify specific realm law characteristics
	var human = realm_ids["realm_human"]
	assert_approx(float(human.cultivation_factor), 1.0, "Human cult factor is 1.0")
	assert_approx(float(human.lifespan_flow_ratio), 1.0, "Human lifespan flow is 1.0")
	assert_approx(float(human.lingqi_pool_scale), 1.0, "Human pool scale is 1.0")

	var immortal = realm_ids["realm_immortal"]
	assert_approx(float(immortal.cultivation_factor), 3.0, "Immortal cult factor is 3.0")
	assert_approx(float(immortal.lifespan_flow_ratio), 0.2, "Immortal lifespan flow is 0.2")
	assert_approx(float(immortal.lingqi_pool_scale), 100.0, "Immortal pool scale is 100.0")

	var demon = realm_ids["realm_demon"]
	assert_approx(float(demon.cultivation_factor), 2.5, "Demon cult factor is 2.5")
	assert_approx(float(demon.lifespan_flow_ratio), 1.6, "Demon lifespan flow is 1.6")

	var nether = realm_ids["realm_nether"]
	assert_approx(float(nether.lifespan_flow_ratio), 0.5, "Nether lifespan flow is 0.5")

	var origin = realm_ids["realm_origin"]
	assert_approx(float(origin.lingqi_pool_scale), 1000.0, "Origin pool scale is 1000.0")
	print("  Realms data integrity: PASS")

func test_scale_law_contract_calculations() -> void:
	print("Testing ScaleLawContract deterministic arithmetic...")
	# 1. Cultivation speed
	var base_speed := 10.0
	var human_speed := ScaleLawContractScript.compute_effective_cultivation_speed(base_speed, "realm_human", WorldAddressScript.ScaleTier.ABODE, 0.0)
	assert_approx(human_speed, 10.0, "Human abode speed is base speed")

	var immortal_speed := ScaleLawContractScript.compute_effective_cultivation_speed(base_speed, "realm_immortal", WorldAddressScript.ScaleTier.ABODE, 0.0)
	assert_approx(immortal_speed, 30.0, "Immortal speed is 3x base speed")

	# Cosmos observation bonus (+10%)
	var cosmos_speed := ScaleLawContractScript.compute_effective_cultivation_speed(base_speed, "realm_human", WorldAddressScript.ScaleTier.COSMOS, 0.0)
	assert_approx(cosmos_speed, 11.0, "Cosmos tier speed should receive +10% observation bonus")

	# 2. Lifespan flow dilation
	var elapsed := 100.0
	var human_loss := ScaleLawContractScript.compute_lifespan_consumption(elapsed, "realm_human")
	assert_approx(human_loss, 100.0, "Human lifespan flow is 1.0x")

	var immortal_loss := ScaleLawContractScript.compute_lifespan_consumption(elapsed, "realm_immortal")
	assert_approx(immortal_loss, 20.0, "Immortal lifespan flow is 0.2x (100s elapsed = 20s lifespan used)")

	var demon_loss := ScaleLawContractScript.compute_lifespan_consumption(elapsed, "realm_demon")
	assert_approx(demon_loss, 160.0, "Demon lifespan flow is 1.6x (100s elapsed = 160s lifespan used)")

	# 3. Lingqi Pool Scale with AmountCompat
	var base_cap := AmountCompatScript.from_number(100.0)
	var human_cap := ScaleLawContractScript.compute_scaled_lingqi_cap(base_cap, "realm_human", WorldAddressScript.ScaleTier.ABODE)
	assert_approx(human_cap.to_float(), 100.0, "Human cap is 100.0")

	var spirit_cap := ScaleLawContractScript.compute_scaled_lingqi_cap(base_cap, "realm_spirit", WorldAddressScript.ScaleTier.ABODE)
	assert_approx(spirit_cap.to_float(), 1000.0, "Spirit cap is 10x base cap (1000.0)")

	var immortal_cap := ScaleLawContractScript.compute_scaled_lingqi_cap(base_cap, "realm_immortal", WorldAddressScript.ScaleTier.ABODE)
	assert_approx(immortal_cap.to_float(), 10000.0, "Immortal cap is 100x base cap (10000.0)")
	print("  ScaleLawContract calculations: PASS")

func test_game_state_and_save_codec_persistence() -> void:
	print("Testing GameState & SaveCodec persistence roundtrip...")
	var state := GameStateScript.new()
	assert_equal(state.world_address, "universe_0/sector_human_0/realm_human/region_cloud_peak/loc_home_island", "Default state world_address mismatch")

	# Modify world_address
	state.world_address = "universe_0/sector_spirit_0/realm_spirit/region_pure_pool/loc_spirit_outpost"
	var dup := state.duplicate_state()
	assert_equal(dup.world_address, state.world_address, "duplicate_state should preserve world_address")

	var snapshot := state.to_snapshot_dict()
	assert_equal(String(snapshot.get("world_address")), state.world_address, "to_snapshot_dict should export world_address")

	# Encode and Decode with SaveCodec
	var meta := {
		"save_id": "test_save_01",
		"saved_at_utc_ms": "1700000000000",
		"settled_until_utc_ms": "1700000000000",
		"sim_tick": "1000",
		"rng_streams": {}
	}
	var encoded := SaveCodecScript.encode(state, "content_test_v1", meta)
	assert_true(bool(encoded.get("ok", false)), "SaveCodec.encode should succeed")
	var json_str: String = encoded.get("json", "")
	assert_true(not json_str.is_empty(), "SaveCodec JSON should not be empty")

	var decoded := SaveCodecScript.decode(json_str)
	assert_true(bool(decoded.get("ok", false)), "SaveCodec.decode should succeed: " + str(decoded.get("error")))
	var restored_state: GameState = decoded["state"]
	assert_equal(restored_state.world_address, state.world_address, "Decoded state world_address mismatch")

	# Backward compatibility: decode snapshot missing world_address
	var legacy_snapshot := snapshot.duplicate(true)
	legacy_snapshot.erase("world_address")
	var legacy_decoded := SaveCodecScript._state_from_snapshot(legacy_snapshot)
	assert_true(bool(legacy_decoded.get("ok", false)), "Legacy snapshot without world_address should decode successfully")
	var legacy_state: GameState = legacy_decoded["state"]
	assert_true(not legacy_state.world_address.is_empty(), "Legacy state should receive fallback default world_address")
	print("  Persistence roundtrip: PASS")

func test_realm_system_and_session_integration() -> void:
	print("Testing RealmSystem & GameSession integration...")
	var state := GameStateScript.new()
	state.era_id = 2 # Foundation unlocked

	# 1. RealmSystem.get_view
	var view := RealmSystemScript.get_view(state)
	assert_true(view.has("world_address"), "Realm view must contain world_address")
	assert_true(view.has("scale_tier"), "Realm view must contain scale_tier")
	assert_true(view.has("realm_law"), "Realm view must contain realm_law")
	var law: Dictionary = view["realm_law"]
	assert_approx(float(law.get("cultivation_factor", 0.0)), 1.0, "Human law cult factor is 1.0")

	# 2. Switch realm updates world_address
	var switch_res := RealmSystemScript.switch_realm(state, "realm_spirit")
	assert_true(bool(switch_res.get("ok", false)), "switch_realm to realm_spirit should succeed")
	assert_equal(state.current_realm, "realm_spirit", "current_realm updated to realm_spirit")
	var expected_spirit_addr := WorldAddressScript.default_for_realm("realm_spirit").to_address_string()
	assert_equal(state.world_address, expected_spirit_addr, "switch_realm should synchronize state.world_address")
	assert_equal(String(switch_res.get("world_address")), expected_spirit_addr, "switch_realm result should contain world_address")

	# 3. GameSession get_view
	var content_res := ContentLoaderScript.load_directory("content")
	assert_true(bool(content_res.get("ok", false)), "ContentLoader must load content successfully")
	var content = content_res["content"]
	var session := GameSessionScript.create_new_game(content)
	session.state.era_id = 2
	RealmSystemScript.switch_realm(session.state, "realm_spirit")

	var session_view := session.get_view()
	assert_true(session_view.has("world_address"), "session_view must expose world_address")
	assert_equal(session_view.get("world_address"), expected_spirit_addr, "session_view world_address mismatch")
	assert_true(session_view.has("realm"), "session_view must expose realm")
	var session_realm_view: Dictionary = session_view["realm"]
	assert_equal(session_realm_view.get("current_realm"), "realm_spirit", "session_realm_view current_realm mismatch")
	assert_approx(float(session_realm_view.get("realm_law", {}).get("cultivation_factor", 0.0)), 1.5, "Spirit cult factor is 1.5")
	print("  RealmSystem & Session integration: PASS")
