class_name WorldGenerator
extends RefCounted

## WorldGenerator
## Pure deterministic procedural generator for WorldDescriptors.
## Strictly follows:
## 1. Deterministic hashing: (universe_seed, world_address, generator_version) -> identical output.
## 2. Nine Realms Law compliance (ScaleLawContract).
## 3. Anti-arbitrage constraint checking with safe fallback to canonical baselines.
## 4. Bounded execution: pure in-memory calculation, zero runtime allocations of Nodes/Textures.

const CURRENT_GENERATOR_VERSION: int = 1
const ARCHETYPES_PATH: String = "res://content/worlds/world_archetypes.json"

static var _archetypes_cache: Dictionary = {}
static var _is_initialized: bool = false

static func init_archetypes(data: Dictionary) -> void:
	_archetypes_cache = data.duplicate(true)
	_is_initialized = true

static func _ensure_archetypes_loaded() -> void:
	if _is_initialized:
		return
	if FileAccess.file_exists(ARCHETYPES_PATH):
		var file := FileAccess.open(ARCHETYPES_PATH, FileAccess.READ)
		if file != null:
			var json_str := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary:
				_archetypes_cache = parsed
				_is_initialized = true
				return
	# Fallback if json not loaded
	_archetypes_cache = {"generator_version": CURRENT_GENERATOR_VERSION, "realms": {}}
	_is_initialized = true

## Pure 32-bit FNV-1a deterministic hash function for strings
static func hash_string(text: String, seed_val: int = 2166136261) -> int:
	var h: int = seed_val
	var bytes := text.to_utf8_buffer()
	for b in bytes:
		h = ((h ^ int(b)) * 16777619) & 0x7FFFFFFF
	return h

## Pseudo-random float [0.0, 1.0) derived from deterministic step
static func _hash_float(h: int, step: int) -> float:
	var mixed: int = ((h + step * 374761393) ^ ((h >> 13) + step * 668265263)) & 0x7FFFFFFF
	return float(mixed % 1000000) / 1000000.0

## Pseudo-random integer [0, max_exclusive - 1]
static func _hash_choice(h: int, step: int, max_exclusive: int) -> int:
	if max_exclusive <= 1:
		return 0
	var mixed: int = ((h + step * 374761393) ^ ((h >> 13) + step * 668265263)) & 0x7FFFFFFF
	return mixed % max_exclusive

## Generates a WorldDescriptor for the given address deterministically
static func generate_world(address: WorldAddress, universe_seed: String = "", gen_version: int = CURRENT_GENERATOR_VERSION) -> WorldDescriptor:
	_ensure_archetypes_loaded()

	if address == null or not address.is_valid():
		return get_fallback_descriptor(WorldAddress.default_home())

	var realm_id: String = address.world_id
	var realms_dict: Dictionary = _archetypes_cache.get("realms", {})
	if not realms_dict.has(realm_id):
		# Unknown realm, fallback safely
		return get_fallback_descriptor(address)

	var realm_data: Dictionary = realms_dict[realm_id]
	var seed_key: String = "%s|%s|%d" % [
		universe_seed if not universe_seed.is_empty() else address.universe_seed,
		address.to_address_string(),
		gen_version
	]
	var h: int = hash_string(seed_key)

	var desc := WorldDescriptor.new(address)
	desc.generator_version = gen_version
	desc.realm_id = realm_id
	desc.dominant_element = ScaleLawContract.get_dominant_element(realm_id)

	# 1. Generate Name
	var prefixes: Array = realm_data.get("name_prefixes", ["神秘"])
	var suffixes: Array = realm_data.get("name_suffixes", ["境"])
	var p_idx := _hash_choice(h, 1, prefixes.size())
	var s_idx := _hash_choice(h, 2, suffixes.size())
	desc.name = "%s%s" % [prefixes[p_idx], suffixes[s_idx]]

	# 2. Select Description
	var descs: Array = realm_data.get("descriptions", ["天地靈機交匯之地。"])
	var d_idx := _hash_choice(h, 3, descs.size())
	desc.description = String(descs[d_idx])

	# 3. Base Law Factor & Qi Density Calculation
	var base_cultivation: float = ScaleLawContract.get_cultivation_factor(realm_id)
	var qi_variance := (_hash_float(h, 4) - 0.5) * 0.4 # +/- 20% natural variance
	var initial_qi := base_cultivation * (1.0 + qi_variance)

	# 4. Environment Traits Selection with Mutual Exclusion
	var traits_pool: Array = realm_data.get("traits_pool", [])
	var chosen_traits: Array = []
	var forbidden_traits: Array = []

	if traits_pool.size() > 0:
		var trait_count := 1 + _hash_choice(h, 5, mini(3, traits_pool.size()))
		for t_step in range(trait_count):
			var cand_idx := _hash_choice(h, 10 + t_step, traits_pool.size())
			var candidate: Dictionary = traits_pool[cand_idx]
			var t_id: String = String(candidate.get("id", ""))
			if t_id in forbidden_traits:
				continue
			var already_has := false
			for ct in chosen_traits:
				if ct.get("id") == t_id:
					already_has = true
					break
			if already_has:
				continue

			chosen_traits.append(candidate.duplicate(true))
			var incomp: Array = candidate.get("incompatible", [])
			for inc in incomp:
				if not (inc in forbidden_traits):
					forbidden_traits.append(String(inc))

	desc.environment_traits = chosen_traits

	# Apply trait modifiers to Qi density
	var total_trait_qi_mod := 0.0
	for t in chosen_traits:
		total_trait_qi_mod += float(t.get("qi_mod", 0.0))
	desc.qi_density = maxf(0.1, initial_qi * (1.0 + total_trait_qi_mod))

	# 5. Danger Level (bounded 1 to 12)
	var realm_law := ScaleLawContract.get_realm_law(realm_id)
	var base_danger := 1
	match realm_id:
		"realm_human": base_danger = 1
		"realm_spirit": base_danger = 2
		"realm_nether", "realm_beast": base_danger = 3
		"realm_demon": base_danger = 4
		"realm_immortal", "realm_buddha": base_danger = 5
		"realm_chaos": base_danger = 6
		"realm_origin": base_danger = 7
	var danger_offset := _hash_choice(h, 6, 3) - 1 # -1, 0, +1
	desc.danger_level = clampi(base_danger + danger_offset, 1, 12)

	# 6. Resources & Biases
	var r_bias: Dictionary = realm_data.get("resource_bias", {})
	desc.resource_bias = r_bias.duplicate(true)
	var fallback_tags: Array = ["basic", "mortal"]
	var r_law_tags: Variant = realm_law.get("allowed_resource_tags", fallback_tags)
	if r_law_tags is Array:
		desc.resource_tags = (r_law_tags as Array).duplicate(true)
	else:
		desc.resource_tags = fallback_tags.duplicate(true)

	# 7. Scale Tier
	desc.scale_tier = WorldAddress.ScaleTier.REGION

	# 8. Strict Anti-Arbitrage Validation
	if not validate_descriptor(desc):
		# Fallback if law or anti-arbitrage constraint breached
		return get_fallback_descriptor(address)

	return desc

## Strict validation against runaway numbers or law violations
static func validate_descriptor(desc: WorldDescriptor) -> bool:
	if desc == null or not desc.is_valid():
		return false
	var realm_id := desc.realm_id
	var base_cultivation: float = ScaleLawContract.get_cultivation_factor(realm_id)

	# Qi density must remain within [0.4x, 3.0x] of the realm's canonical factor
	var min_qi := base_cultivation * 0.4
	var max_qi := base_cultivation * 3.0
	if desc.qi_density < min_qi or desc.qi_density > max_qi:
		return false

	if desc.danger_level < 1 or desc.danger_level > 12:
		return false

	return true

## Returns a guaranteed valid baseline descriptor for safety fallback
static func get_fallback_descriptor(address: WorldAddress) -> WorldDescriptor:
	_ensure_archetypes_loaded()
	var fallback_addr: WorldAddress = address.duplicate_address() if address != null else WorldAddress.default_home()
	var realm_id: String = fallback_addr.world_id
	var realms_dict: Dictionary = _archetypes_cache.get("realms", {})
	var realm_data: Dictionary = realms_dict.get(realm_id, {})
	var fb_dict: Dictionary = realm_data.get("fallback", {})

	var desc := WorldDescriptor.new(fallback_addr)
	desc.name = String(fb_dict.get("name", "靈脈福地"))
	desc.description = String(fb_dict.get("description", "天地靈機平穩流轉之福地。"))
	desc.qi_density = float(fb_dict.get("qi_density", ScaleLawContract.get_cultivation_factor(realm_id)))
	desc.danger_level = int(fb_dict.get("danger_level", 1))
	desc.dominant_element = ScaleLawContract.get_dominant_element(realm_id)

	var trait_ids: Array = fb_dict.get("environment_traits", [])
	desc.environment_traits = []
	for tid in trait_ids:
		desc.environment_traits.append({"id": String(tid), "name": "地脈調和", "qi_mod": 0.0})

	desc.resource_tags = (fb_dict.get("resource_tags", ["basic", "mortal"]) as Array).duplicate(true)
	desc.resource_bias = (realm_data.get("resource_bias", {"herb": 1.0, "mineral": 1.0}) as Dictionary).duplicate(true)
	return desc
