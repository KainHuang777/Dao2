class_name WorldAddress
extends RefCounted

## WorldAddress & SpatialScale
## Represents a 5-tier deterministic hierarchical address:
## universe_seed / sector_id / world_id / region_id / location_id
## Used to anchor points across the 5 spatial scale tiers (Abode -> Cosmos).

enum ScaleTier {
	ABODE = 0,   # Tier 0: 洞府尺度 (10m - 100m), base micro-building & disciples
	REGION = 1,  # Tier 1: 山域尺度 (1km - 10km), nearby peaks & valley landmarks
	WORLD = 2,   # Tier 2: 世界/洞天尺度 (1,000km - 10,000km), realm landmass
	SECTOR = 3,  # Tier 3: 星域尺度 (1 - 100 light years), star maps & stargates
	COSMOS = 4   # Tier 4: 諸天宇宙尺度, nine realms overview & void
}

const DEFAULT_UNIVERSE := "universe_0"
const DEFAULT_SECTOR := "sector_human_0"
const DEFAULT_WORLD := "realm_human"
const DEFAULT_REGION := "region_cloud_peak"
const DEFAULT_LOCATION := "loc_home_island"

const TIER_ZOOM_REFERENCE := {
	ScaleTier.ABODE: 0.70,
	ScaleTier.REGION: 0.40,
	ScaleTier.WORLD: 0.20,
	ScaleTier.SECTOR: 0.10,
	ScaleTier.COSMOS: 0.08
}

var universe_seed: String = DEFAULT_UNIVERSE
var sector_id: String = DEFAULT_SECTOR
var world_id: String = DEFAULT_WORLD
var region_id: String = DEFAULT_REGION
var location_id: String = DEFAULT_LOCATION

func _init(u: String = DEFAULT_UNIVERSE, s: String = DEFAULT_SECTOR, w: String = DEFAULT_WORLD, r: String = DEFAULT_REGION, l: String = DEFAULT_LOCATION) -> void:
	universe_seed = u.strip_edges()
	sector_id = s.strip_edges()
	world_id = w.strip_edges()
	region_id = r.strip_edges()
	location_id = l.strip_edges()

func to_address_string() -> String:
	return "%s/%s/%s/%s/%s" % [universe_seed, sector_id, world_id, region_id, location_id]

func _to_string() -> String:
	return to_address_string()

func is_valid() -> bool:
	return not universe_seed.is_empty() and not sector_id.is_empty() and not world_id.is_empty() and not region_id.is_empty() and not location_id.is_empty()

func equals(other: WorldAddress) -> bool:
	if other == null:
		return false
	return (universe_seed == other.universe_seed and
		sector_id == other.sector_id and
		world_id == other.world_id and
		region_id == other.region_id and
		location_id == other.location_id)

func matches_realm(target_realm_id: String) -> bool:
	return world_id == target_realm_id

func duplicate_address() -> WorldAddress:
	var copy := WorldAddress.new(universe_seed, sector_id, world_id, region_id, location_id)
	return copy

static func default_home() -> WorldAddress:
	return WorldAddress.new(DEFAULT_UNIVERSE, DEFAULT_SECTOR, DEFAULT_WORLD, DEFAULT_REGION, DEFAULT_LOCATION)

static func default_for_realm(target_realm: String) -> WorldAddress:
	match target_realm:
		"realm_spirit":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_spirit_0", "realm_spirit", "region_pure_pool", "loc_spirit_outpost")
		"realm_nether":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_nether_0", "realm_nether", "region_yellow_spring", "loc_soul_altar")
		"realm_beast":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_beast_0", "realm_beast", "region_primeval_forest", "loc_totem_nest")
		"realm_demon":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_demon_0", "realm_demon", "region_abyss_mirror", "loc_heart_trial")
		"realm_immortal":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_immortal_0", "realm_immortal", "region_nine_heavens", "loc_celestial_court")
		"realm_buddha":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_buddha_0", "realm_buddha", "region_pure_land", "loc_bodhi_seat")
		"realm_chaos":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_chaos_0", "realm_chaos", "region_primordial_rift", "loc_chaos_core")
		"realm_origin":
			return WorldAddress.new(DEFAULT_UNIVERSE, "sector_origin_0", "realm_origin", "region_void_beginning", "loc_cosmic_eye")
		_:
			return WorldAddress.new(DEFAULT_UNIVERSE, DEFAULT_SECTOR, DEFAULT_WORLD, DEFAULT_REGION, DEFAULT_LOCATION)

static func parse(path_str: String) -> WorldAddress:
	if path_str.is_empty():
		return default_home()
	var parts := path_str.split("/")
	if parts.size() == 5:
		return WorldAddress.new(parts[0], parts[1], parts[2], parts[3], parts[4])
	elif parts.size() == 1 and not parts[0].is_empty():
		# Fallback if given just a realm_id
		return default_for_realm(parts[0])
	return default_home()

static func get_reference_zoom(tier: int) -> float:
	return float(TIER_ZOOM_REFERENCE.get(tier, 0.70))

static func get_tier_for_zoom(zoom: float) -> int:
	if zoom >= 0.55:
		return ScaleTier.ABODE
	elif zoom >= 0.30:
		return ScaleTier.REGION
	elif zoom >= 0.15:
		return ScaleTier.WORLD
	elif zoom >= 0.09:
		return ScaleTier.SECTOR
	else:
		return ScaleTier.COSMOS
