class_name ScaleLawContract
extends RefCounted

## ScaleLawContract
## Pure mathematical & deterministic contract for:
## 1. Nine Realms core law factors (cultivation, lifespan dilation, pool scale)
## 2. Seven-dimensional laws (alchemy flame, resource veins, soul affinity, elements)
## 3. Celestial Aspiration resonance (心印嚮往跨界道韻共鳴)
## 4. Spatial Scale Tiers (Tier 0 Abode -> Tier 4 Cosmos)
## 5. Strict conservation: camera scale does not create secondary economies.

const DEFAULT_REALM_LAWS: Dictionary = {
	"realm_human": {
		"name": "人界",
		"cultivation_factor": 1.0,
		"lifespan_flow_ratio": 1.0,
		"lingqi_pool_scale": 1.0,
		"tier_scale_bonus": 0.0,
		"dominant_element": "earth",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 1.0,
			"pill_success_bonus": 0.0,
			"flame_element": "mortal"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 1.0,
			"mineral_mining_mult": 1.0,
			"wood_harvest_mult": 1.0
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.0,
			"tribulation_defense_bonus": 0.0
		}
	},
	"realm_spirit": {
		"name": "靈界",
		"cultivation_factor": 1.5,
		"lifespan_flow_ratio": 0.85,
		"lingqi_pool_scale": 10.0,
		"tier_scale_bonus": 0.05,
		"dominant_element": "wood",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 1.3,
			"pill_success_bonus": 0.15,
			"flame_element": "spiritual"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 2.0,
			"mineral_mining_mult": 0.9,
			"wood_harvest_mult": 1.5
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.10,
			"tribulation_defense_bonus": 0.05
		}
	},
	"realm_nether": {
		"name": "幽冥界",
		"cultivation_factor": 0.8,
		"lifespan_flow_ratio": 0.5,
		"lingqi_pool_scale": 5.0,
		"tier_scale_bonus": 0.0,
		"dominant_element": "yin",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 0.7,
			"pill_success_bonus": -0.10,
			"flame_element": "nether_yin"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 0.3,
			"mineral_mining_mult": 1.2,
			"wood_harvest_mult": 0.2
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.50,
			"tribulation_defense_bonus": 0.20
		}
	},
	"realm_beast": {
		"name": "萬妖界",
		"cultivation_factor": 0.85,
		"lifespan_flow_ratio": 0.7,
		"lingqi_pool_scale": 8.0,
		"tier_scale_bonus": 0.0,
		"dominant_element": "metal",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 0.8,
			"pill_success_bonus": -0.05,
			"flame_element": "beast_blood"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 0.8,
			"mineral_mining_mult": 2.5,
			"wood_harvest_mult": 2.2
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.05,
			"tribulation_defense_bonus": -0.05
		}
	},
	"realm_demon": {
		"name": "天魔界",
		"cultivation_factor": 2.5,
		"lifespan_flow_ratio": 1.6,
		"lingqi_pool_scale": 15.0,
		"tier_scale_bonus": 0.10,
		"dominant_element": "fire",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 2.0,
			"pill_success_bonus": -0.15,
			"flame_element": "demon_blaze"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 0.5,
			"mineral_mining_mult": 1.5,
			"wood_harvest_mult": 0.5
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.15,
			"tribulation_defense_bonus": -0.20
		}
	},
	"realm_immortal": {
		"name": "仙界",
		"cultivation_factor": 3.0,
		"lifespan_flow_ratio": 0.2,
		"lingqi_pool_scale": 100.0,
		"tier_scale_bonus": 0.15,
		"dominant_element": "yang",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 1.8,
			"pill_success_bonus": 0.25,
			"flame_element": "pure_yang"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 2.5,
			"mineral_mining_mult": 2.0,
			"wood_harvest_mult": 2.0
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.30,
			"tribulation_defense_bonus": 0.25
		}
	},
	"realm_buddha": {
		"name": "佛界",
		"cultivation_factor": 1.2,
		"lifespan_flow_ratio": 0.6,
		"lingqi_pool_scale": 50.0,
		"tier_scale_bonus": 0.05,
		"dominant_element": "water",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 1.0,
			"pill_success_bonus": 0.10,
			"flame_element": "karma_lotus"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 1.3,
			"mineral_mining_mult": 0.7,
			"wood_harvest_mult": 1.3
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.40,
			"tribulation_defense_bonus": 0.30
		}
	},
	"realm_chaos": {
		"name": "混沌界",
		"cultivation_factor": 2.0,
		"lifespan_flow_ratio": 1.2,
		"lingqi_pool_scale": 200.0,
		"tier_scale_bonus": 0.10,
		"dominant_element": "chaos",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 1.5,
			"pill_success_bonus": -0.10,
			"flame_element": "primordial_chaos"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 1.8,
			"mineral_mining_mult": 3.0,
			"wood_harvest_mult": 1.8
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.20,
			"tribulation_defense_bonus": -0.10
		}
	},
	"realm_origin": {
		"name": "太初界",
		"cultivation_factor": 5.0,
		"lifespan_flow_ratio": 0.1,
		"lingqi_pool_scale": 1000.0,
		"tier_scale_bonus": 0.20,
		"dominant_element": "void",
		"alchemy_flame_affinity": {
			"pill_speed_mult": 3.0,
			"pill_success_bonus": 0.30,
			"flame_element": "genesis_void"
		},
		"vein_resource_affinity": {
			"herb_growth_mult": 4.0,
			"mineral_mining_mult": 4.0,
			"wood_harvest_mult": 4.0
		},
		"soul_affinity": {
			"dao_heart_retention_bonus": 0.60,
			"tribulation_defense_bonus": 0.40
		}
	}
}

static var _custom_realm_cache: Dictionary = {}

static func set_custom_realm_laws(realms_list: Array) -> void:
	_custom_realm_cache.clear()
	for entry in realms_list:
		if entry is Dictionary and entry.has("id"):
			var r_id: String = String(entry["id"])
			_custom_realm_cache[r_id] = {
				"name": String(entry.get("name", r_id)),
				"cultivation_factor": float(entry.get("cultivation_factor", 1.0)),
				"lifespan_flow_ratio": float(entry.get("lifespan_flow_ratio", 1.0)),
				"lingqi_pool_scale": float(entry.get("lingqi_pool_scale", 1.0)),
				"tier_scale_bonus": float(entry.get("tier_scale_bonus", 0.0)),
				"dominant_element": String(entry.get("dominant_element", "earth")),
				"alchemy_flame_affinity": (entry.get("alchemy_flame_affinity", {}) as Dictionary).duplicate(true),
				"vein_resource_affinity": (entry.get("vein_resource_affinity", {}) as Dictionary).duplicate(true),
				"soul_affinity": (entry.get("soul_affinity", {}) as Dictionary).duplicate(true),
			}

static func get_realm_law(realm_id: String) -> Dictionary:
	if _custom_realm_cache.has(realm_id):
		return _custom_realm_cache[realm_id]
	if DEFAULT_REALM_LAWS.has(realm_id):
		return DEFAULT_REALM_LAWS[realm_id]
	return DEFAULT_REALM_LAWS["realm_human"]

static func get_cultivation_factor(realm_id: String) -> float:
	var law := get_realm_law(realm_id)
	return maxf(0.01, float(law.get("cultivation_factor", 1.0)))

static func get_lifespan_flow_ratio(realm_id: String) -> float:
	var law := get_realm_law(realm_id)
	return maxf(0.01, float(law.get("lifespan_flow_ratio", 1.0)))

static func get_lingqi_pool_scale(realm_id: String) -> float:
	var law := get_realm_law(realm_id)
	return maxf(0.01, float(law.get("lingqi_pool_scale", 1.0)))

static func get_dominant_element(realm_id: String) -> String:
	var law := get_realm_law(realm_id)
	return String(law.get("dominant_element", "earth"))

static func get_alchemy_flame_affinity(realm_id: String) -> Dictionary:
	var law := get_realm_law(realm_id)
	var fallback: Dictionary = {
		"pill_speed_mult": 1.0,
		"pill_success_bonus": 0.0,
		"flame_element": "mortal"
	}
	var aff: Variant = law.get("alchemy_flame_affinity", fallback)
	if aff is Dictionary:
		return aff
	return fallback

static func get_vein_resource_affinity(realm_id: String) -> Dictionary:
	var law := get_realm_law(realm_id)
	var fallback: Dictionary = {
		"herb_growth_mult": 1.0,
		"mineral_mining_mult": 1.0,
		"wood_harvest_mult": 1.0
	}
	var aff: Variant = law.get("vein_resource_affinity", fallback)
	if aff is Dictionary:
		return aff
	return fallback

static func get_soul_affinity(realm_id: String) -> Dictionary:
	var law := get_realm_law(realm_id)
	var fallback: Dictionary = {
		"dao_heart_retention_bonus": 0.0,
		"tribulation_defense_bonus": 0.0
	}
	var aff: Variant = law.get("soul_affinity", fallback)
	if aff is Dictionary:
		return aff
	return fallback

## Computes the remote resonance bonus when a cultivator aspires to a certain realm (心印嚮往道韻共鳴)
## Returns a Dictionary with remote bonus factors applied to the cultivator's home abode.
static func compute_aspiration_resonance(current_realm: String, aspiration_realm: String) -> Dictionary:
	var resonance: Dictionary = {
		"aspiration_realm": aspiration_realm,
		"is_active": false,
		"cultivation_resonance_boost": 0.0,
		"mineral_bonus": 0.0,
		"herb_bonus": 0.0,
		"lifespan_dilation_bonus": 0.0,
		"dao_heart_retention_bonus": 0.0,
	}
	if aspiration_realm.is_empty() or aspiration_realm == current_realm:
		return resonance

	resonance["is_active"] = true
	var asp_law := get_realm_law(aspiration_realm)
	var asp_cult := float(asp_law.get("cultivation_factor", 1.0))
	var asp_vein: Dictionary = get_vein_resource_affinity(aspiration_realm)
	var asp_soul: Dictionary = get_soul_affinity(aspiration_realm)
	var asp_lifespan := float(asp_law.get("lifespan_flow_ratio", 1.0))

	# 20% remote projection resonance ratio
	const PROJECTION_RATIO := 0.20

	if asp_cult > 1.0:
		resonance["cultivation_resonance_boost"] = (asp_cult - 1.0) * PROJECTION_RATIO
	var min_mult := float(asp_vein.get("mineral_mining_mult", 1.0))
	if min_mult > 1.0:
		resonance["mineral_bonus"] = (min_mult - 1.0) * PROJECTION_RATIO
	var herb_mult := float(asp_vein.get("herb_growth_mult", 1.0))
	if herb_mult > 1.0:
		resonance["herb_bonus"] = (herb_mult - 1.0) * PROJECTION_RATIO
	if asp_lifespan < 1.0:
		# If aspiring to a realm with slower lifespan flow (e.g. Nether or Immortal), grant partial dilation
		resonance["lifespan_dilation_bonus"] = (1.0 - asp_lifespan) * PROJECTION_RATIO
	resonance["dao_heart_retention_bonus"] = float(asp_soul.get("dao_heart_retention_bonus", 0.0)) * PROJECTION_RATIO

	return resonance

static func compute_effective_cultivation_speed(base_speed: float, realm_id: String, tier: int = WorldAddress.ScaleTier.ABODE, extra_bonus: float = 0.0) -> float:
	var realm_factor := get_cultivation_factor(realm_id)
	# Minor cosmic enlightenment tier boost when observing cosmos (tier 4)
	var tier_boost := 0.0
	if tier == WorldAddress.ScaleTier.COSMOS:
		tier_boost = 0.10
	elif tier == WorldAddress.ScaleTier.SECTOR:
		tier_boost = 0.05
	return maxf(0.0, base_speed * realm_factor * (1.0 + tier_boost) * (1.0 + extra_bonus))

static func compute_lifespan_consumption(real_elapsed_seconds: float, realm_id: String) -> float:
	if real_elapsed_seconds <= 0.0:
		return 0.0
	var ratio := get_lifespan_flow_ratio(realm_id)
	return maxf(0.0, real_elapsed_seconds * ratio)

static func compute_scaled_lingqi_cap(base_cap: AmountCompat, realm_id: String, tier: int = WorldAddress.ScaleTier.ABODE, external_bonus: float = 0.0) -> AmountCompat:
	if base_cap == null or base_cap.compare_to(AmountCompat.zero()) <= 0:
		return AmountCompat.zero()
	var pool_scale := get_lingqi_pool_scale(realm_id)
	var tier_multiplier := 1.0 + float(tier) * 0.05
	var total_scale := pool_scale * tier_multiplier * (1.0 + external_bonus)
	return base_cap.multiply(AmountCompat.from_number(total_scale)).floor_amount()
