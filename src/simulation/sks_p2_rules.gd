class_name SksP2Rules
extends RefCounted

const LIMITS := {"nascent_soul_incubation": 5, "nascent_soul_mastery": 3, "heavenly_craft": 3, "deep_vein_resonance": 3, "void_expansion": 3, "spirit_transformation": 3, "ancient_herb_attunement": 3, "spirit_sea_breath": 3, "void_mastery": 3, "void_refinement": 3, "void_essence_attunement": 3, "frontier_storekeeping": 3}
const HOME_CAPACITY_IDS := ["lingli", "money", "wood", "stone_low", "spirit_grass_low", "skill_point", "black_copper", "bronze_essence", "foundation_pill", "spirit_grass_100y", "stone_mid", "golden_core_pill", "liquid", "talisman", "spirit_timber", "formation_core", "refined_iron", "mithril", "cold_iron", "spirit_grass_1000y", "stone_high", "trans_pill", "void_essence"]
const ADVANCED_CAPACITY_IDS := ["refined_iron", "mithril", "cold_iron", "spirit_grass_1000y", "stone_high", "trans_pill", "void_essence"]
const HOME_RATE_IDS := ["lingli", "money", "wood", "stone_low", "spirit_grass_low", "skill_point"]
const DISCOUNT_RECIPE_IDS := ["stone_mid_bulk", "stone_high"]
const LOCAL_CAPACITY_ISLANDS := ["deep", "ancient", "void"]
const INCUBATION_FACTOR := 1.15
const ADVANCED_CAPACITY_FACTOR := 1.1
const HOME_RATE_FACTOR := 1.1
const LOCAL_RATE_FACTOR := 1.1
const DISCOUNT_PER_LEVEL := 0.05
const LOCAL_CAPACITY_PER_LEVEL := 100.0

static func home_cap_multiplier(skills: Dictionary) -> float:
	return pow(INCUBATION_FACTOR, float(_level(skills, "nascent_soul_incubation")))

static func advanced_cap_multiplier(skills: Dictionary) -> float:
	return pow(ADVANCED_CAPACITY_FACTOR, float(_level(skills, "void_expansion")))

static func cap_multiplier(id: String, skills: Dictionary) -> float:
	if not HOME_CAPACITY_IDS.has(id):
		return 1.0
	var result := home_cap_multiplier(skills)
	if ADVANCED_CAPACITY_IDS.has(id):
		result *= advanced_cap_multiplier(skills)
	return result

static func home_rate_multiplier(id: String, skills: Dictionary) -> float:
	if not HOME_RATE_IDS.has(id):
		return 1.0
	return pow(HOME_RATE_FACTOR, float(_level(skills, "void_mastery")))

static func local_rate_multiplier(island: String, skills: Dictionary) -> float:
	var island_skill_ids := {"deep": "deep_vein_resonance", "ancient": "ancient_herb_attunement", "void": "void_essence_attunement"}
	if not island_skill_ids.has(island):
		return 1.0
	return pow(LOCAL_RATE_FACTOR, float(_level(skills, String(island_skill_ids[island]))))

static func local_capacity_bonus(island: String, skills: Dictionary) -> float:
	if not LOCAL_CAPACITY_ISLANDS.has(island):
		return 0.0
	return LOCAL_CAPACITY_PER_LEVEL * float(_level(skills, "frontier_storekeeping"))

static func lingli_discount_multiplier(skills: Dictionary) -> float:
	return 1.0 - DISCOUNT_PER_LEVEL * float(_level(skills, "heavenly_craft"))

static func discounted_amount(recipe_id: String, island: String, id: String, raw: String, skills: Dictionary) -> String:
	if island != "home" or not DISCOUNT_RECIPE_IDS.has(recipe_id) or id != "lingli":
		return raw
	var parsed := AmountCompat.try_parse(raw)
	if not bool(parsed.get("ok", false)):
		return raw
	var value: AmountCompat = parsed["value"]
	return value.multiply(AmountCompat.from_number(lingli_discount_multiplier(skills))).serialize()

static func _level(skills: Dictionary, id: String) -> int:
	return clampi(int(skills.get(id, 0)), 0, int(LIMITS[id]))
