extends SceneTree

func _init() -> void:
	print("[M5A_RUNNER] Starting M5-A World Generation & Nine Realms Law Tests...")
	var success := true

	success = success and _test_deterministic_generation()
	success = success and _test_nine_realms_law_compliance()
	success = success and _test_anti_arbitrage_and_fallback()
	success = success and _test_celestial_aspiration_resonance()
	success = success and _test_world_descriptor_and_persistence_roundtrip()

	if success:
		print("[M5A_RUNNER] ALL M5-A TESTS PASSED (exit 0)")
		quit(0)
	else:
		printerr("[M5A_RUNNER] SOME M5-A TESTS FAILED (exit 1)")
		quit(1)

func _assert(condition: bool, msg: String) -> bool:
	if not condition:
		printerr("  FAIL: " + msg)
		return false
	return true

func _test_deterministic_generation() -> bool:
	print("--- 1. Testing Deterministic Generation ---")
	var addr1 := WorldAddress.parse("universe_dao/sector_spirit_0/realm_spirit/region_pure_pool/loc_spirit_outpost")
	var addr2 := WorldAddress.parse("universe_dao/sector_spirit_0/realm_spirit/region_pure_pool/loc_spirit_outpost")

	var desc1 := WorldGenerator.generate_world(addr1, "seed_alpha", 1)
	var desc2 := WorldGenerator.generate_world(addr2, "seed_alpha", 1)

	var ok := true
	ok = ok and _assert(desc1 != null and desc2 != null, "Descriptors should not be null")
	ok = ok and _assert(desc1.name == desc2.name, "Deterministic name match: %s vs %s" % [desc1.name, desc2.name])
	ok = ok and _assert(desc1.description == desc2.description, "Deterministic description match")
	ok = ok and _assert(is_equal_approx(desc1.qi_density, desc2.qi_density), "Deterministic qi_density match: %.4f vs %.4f" % [desc1.qi_density, desc2.qi_density])
	ok = ok and _assert(desc1.danger_level == desc2.danger_level, "Deterministic danger_level match")
	ok = ok and _assert(desc1.environment_traits.size() == desc2.environment_traits.size(), "Deterministic traits count match")

	# Different seed produces different generation
	var desc3 := WorldGenerator.generate_world(addr1, "seed_beta", 1)
	var different := (desc1.name != desc3.name) or (not is_equal_approx(desc1.qi_density, desc3.qi_density))
	ok = ok and _assert(different, "Different seed produces variation")

	print("  Determinism verified: identical inputs -> identical output.")
	return ok

func _test_nine_realms_law_compliance() -> bool:
	print("--- 2. Testing Nine Realms Law Compliance Across All 9 Realms ---")
	var realms := [
		"realm_human", "realm_spirit", "realm_nether", "realm_beast",
		"realm_demon", "realm_immortal", "realm_buddha", "realm_chaos", "realm_origin"
	]
	var ok := true

	for r_id in realms:
		var addr := WorldAddress.default_for_realm(r_id)
		var desc := WorldGenerator.generate_world(addr, "cosmic_seed_42", 1)
		ok = ok and _assert(desc != null and desc.is_valid(), "Descriptor for realm %s must be valid" % r_id)
		ok = ok and _assert(desc.realm_id == r_id, "Realm ID match for %s" % r_id)

		var base_factor := ScaleLawContract.get_cultivation_factor(r_id)
		# Bounded within [0.4x, 3.0x] canonical factor
		var min_bound := base_factor * 0.4
		var max_bound := base_factor * 3.0
		ok = ok and _assert(desc.qi_density >= min_bound and desc.qi_density <= max_bound,
			"Qi density for %s (%.2f) must be in [%.2f, %.2f]" % [r_id, desc.qi_density, min_bound, max_bound])

		# Dominant element match
		var expected_elem := ScaleLawContract.get_dominant_element(r_id)
		ok = ok and _assert(desc.dominant_element == expected_elem,
			"Dominant element for %s must be %s (got %s)" % [r_id, expected_elem, desc.dominant_element])

		# Danger level bounded
		ok = ok and _assert(desc.danger_level >= 1 and desc.danger_level <= 12,
			"Danger level for %s (%d) within [1, 12]" % [r_id, desc.danger_level])

	print("  Nine Realms Law compliance verified across all 9 realms.")
	return ok

func _test_anti_arbitrage_and_fallback() -> bool:
	print("--- 3. Testing Anti-Arbitrage Validation & Safe Fallback ---")
	var ok := true

	# Invalid realm address
	var invalid_addr := WorldAddress.new("seed", "sector", "realm_unknown_void", "region", "loc")
	var fb_desc := WorldGenerator.generate_world(invalid_addr, "seed", 1)
	ok = ok and _assert(fb_desc != null and fb_desc.is_valid(), "Fallback descriptor must be valid")
	ok = ok and _assert(fb_desc.qi_density > 0.0, "Fallback qi_density must be positive")

	# Trait mutual exclusion test
	var spirit_addr := WorldAddress.default_for_realm("realm_spirit")
	var gen_desc := WorldGenerator.generate_world(spirit_addr, "seed_test", 1)
	var trait_ids: Array = []
	for t in gen_desc.environment_traits:
		trait_ids.append(t.get("id", ""))
	
	# Verify incompatible traits not coexisting (e.g. trait_pure_pool and trait_nether_chill)
	var has_pool := "trait_pure_pool" in trait_ids
	var has_chill := "trait_nether_chill" in trait_ids
	ok = ok and _assert(not (has_pool and has_chill), "Incompatible traits must not coexist")

	print("  Anti-arbitrage and safe fallback verified.")
	return ok

func _test_celestial_aspiration_resonance() -> bool:
	print("--- 4. Testing Celestial Aspiration Resonance (心印嚮往) ---")
	var ok := true

	# Case 1: Cultivator in Human Realm aspiring to Spirit Realm (boosts herb growth)
	var res_spirit := ScaleLawContract.compute_aspiration_resonance("realm_human", "realm_spirit")
	ok = ok and _assert(bool(res_spirit.get("is_active", false)), "Resonance should be active")
	ok = ok and _assert(float(res_spirit.get("herb_bonus", 0.0)) > 0.0, "Spirit aspiration should grant herb bonus")

	# Case 2: Cultivator aspiring to Beast Realm (boosts mineral mining)
	var res_beast := ScaleLawContract.compute_aspiration_resonance("realm_human", "realm_beast")
	ok = ok and _assert(float(res_beast.get("mineral_bonus", 0.0)) > 0.0, "Beast aspiration should grant mineral mining bonus")

	# Case 3: Cultivator aspiring to Nether Realm (slows lifespan flow / grants dilation)
	var res_nether := ScaleLawContract.compute_aspiration_resonance("realm_human", "realm_nether")
	ok = ok and _assert(float(res_nether.get("lifespan_dilation_bonus", 0.0)) > 0.0, "Nether aspiration grants lifespan dilation")
	ok = ok and _assert(float(res_nether.get("dao_heart_retention_bonus", 0.0)) > 0.0, "Nether aspiration grants dao heart retention")

	# Case 4: Aspiring to own realm produces no resonance
	var res_self := ScaleLawContract.compute_aspiration_resonance("realm_human", "realm_human")
	ok = ok and _assert(not bool(res_self.get("is_active", false)), "Self realm aspiration is inactive")

	print("  Celestial Aspiration Resonance mathematical contract verified.")
	return ok

func _test_world_descriptor_and_persistence_roundtrip() -> bool:
	print("--- 5. Testing WorldDescriptor Serialization & SaveCodec Integration ---")
	var ok := true

	var addr := WorldAddress.default_for_realm("realm_spirit")
	var desc := WorldGenerator.generate_world(addr, "save_seed_99", 1)
	var dict := desc.to_dict()

	var restored := WorldDescriptor.from_dict(dict)
	ok = ok and _assert(restored.name == desc.name, "Restored name match")
	ok = ok and _assert(is_equal_approx(restored.qi_density, desc.qi_density), "Restored qi_density match")
	ok = ok and _assert(restored.realm_id == desc.realm_id, "Restored realm_id match")
	ok = ok and _assert(restored.dominant_element == desc.dominant_element, "Restored dominant_element match")

	# GameState & SaveCodec Roundtrip
	var state := GameState.new()
	state.revision = 10
	state.current_realm = "realm_human"
	state.aspiration_realm = "realm_spirit"
	state.discovered_worlds[addr.to_address_string()] = dict

	var meta := {
		"save_id": "save_test_m5a",
		"saved_at_utc_ms": "1000",
		"settled_until_utc_ms": "1000",
		"sim_tick": "1000",
		"rng_streams": {}
	}
	var enc := SaveCodec.encode(state, "manifest_m5a", meta)
	ok = ok and _assert(bool(enc.get("ok", false)), "SaveCodec encode must succeed")
	var json_str: String = String(enc.get("json", ""))
	var dec := SaveCodec.decode(json_str)
	ok = ok and _assert(bool(dec.get("ok", false)), "SaveCodec decode must succeed")

	var dec_state: GameState = dec.get("state")
	ok = ok and _assert(dec_state != null, "Decoded state must not be null")
	ok = ok and _assert(dec_state.aspiration_realm == "realm_spirit", "Decoded aspiration_realm must match")
	ok = ok and _assert(dec_state.discovered_worlds.has(addr.to_address_string()), "Decoded discovered_worlds must contain address")

	var stored_desc_dict: Dictionary = dec_state.discovered_worlds[addr.to_address_string()]
	var roundtrip_desc := WorldDescriptor.from_dict(stored_desc_dict)
	ok = ok and _assert(roundtrip_desc.name == desc.name, "Roundtrip descriptor name match: %s" % roundtrip_desc.name)

	print("  WorldDescriptor and SaveCodec roundtrip verified.")
	return ok
