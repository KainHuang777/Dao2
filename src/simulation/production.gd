class_name Production
extends RefCounted

const BASIC_RESOURCE_KEYS := ["lingli", "money", "wood", "stone_low", "spirit_grass_low"]
const SYNTHETIC_RESOURCE_KEYS := ["stone_mid", "stone_high", "liquid", "talisman", "star_metal", "void_crystal"]

static func compute_rates(content: GameContent, buildings: Dictionary, resource_multiplier: float = 1.0, skills: Dictionary = {}) -> Dictionary:
	var skill_defs := _collect_skill_effects(content, skills)
	var skill_rate_additions := _skill_rate_additions(content, skill_defs)
	var skill_rate_multipliers := _skill_rate_multipliers(content, skill_defs)
	var rates := {}
	for resource_id in content.resource_ids:
		var definition: Dictionary = content.resources[resource_id]
		rates[resource_id] = AmountCompat.from_number(float(definition.rate))
	for building_id in content.building_ids:
		var definition: Dictionary = content.buildings[building_id]
		var level := int(buildings.get(building_id, 0))
		if level <= 0:
			continue
		for key in definition.effects:
			if _is_capacity_key(String(key)):
				continue
			if String(key) == "synthetic_max_mult":
				continue
			var scaled := _scaled_amount(definition, String(key), level)
			if String(key) == "all_rate":
				for resource_id in BASIC_RESOURCE_KEYS:
					if rates.has(resource_id):
						rates[resource_id] = rates[resource_id].add(scaled)
			elif rates.has(String(key)):
				rates[key] = rates[key].add(scaled)
	for resource_id in rates:
		if skill_rate_additions.has(String(resource_id)):
			rates[resource_id] = rates[resource_id].add(AmountCompat.from_number(float(skill_rate_additions[String(resource_id)])))
	for resource_id in rates:
		if skill_rate_multipliers.has(String(resource_id)):
			rates[resource_id] = rates[resource_id].multiply(AmountCompat.from_number(float(skill_rate_multipliers[String(resource_id)])))
	for resource_id in rates:
		rates[resource_id] = rates[resource_id].multiply(AmountCompat.from_number(resource_multiplier))
	return rates

static func compute_caps(content: GameContent, buildings: Dictionary, era_id: int, onboarding_version: int, skills: Dictionary = {}, skill_max_multipliers: Dictionary = {}) -> Dictionary:
	var caps := {}
	for resource_id in content.resource_ids:
		var definition: Dictionary = content.resources[resource_id]
		caps[resource_id] = AmountCompat.from_number(float(definition.max))
	var skill_defs := _collect_skill_effects(content, skills)
	var skill_cap_additions := _skill_capacity_additions(content, skill_defs)
	for resource_id in caps:
		if skill_cap_additions.has(String(resource_id)):
			caps[resource_id] = caps[resource_id].add(AmountCompat.from_number(float(skill_cap_additions[String(resource_id)])))
	for building_id in content.building_ids:
		var definition: Dictionary = content.buildings[building_id]
		var level := int(buildings.get(building_id, 0))
		if level <= 0:
			continue
		for key in definition.effects:
			if String(key) == "all_max":
				var flat_all := _flat_amount(definition, String(key), level)
				for resource_id in BASIC_RESOURCE_KEYS:
					if caps.has(resource_id):
						caps[resource_id] = caps[resource_id].add(flat_all)
			elif _is_capacity_key(String(key)):
				var target := String(key).substr(0, String(key).length() - 4)
				if caps.has(target):
					caps[target] = caps[target].add(_flat_amount(definition, String(key), level))
	var hut_bonus := Onboarding.hut_lingli_capacity(era_id, onboarding_version, buildings)
	if hut_bonus > 0 and caps.has("lingli"):
		caps["lingli"] = caps["lingli"].add(AmountCompat.from_number(float(hut_bonus)))
	var synthetic_bonus := AmountCompat.zero()
	for building_id in content.building_ids:
		var definition: Dictionary = content.buildings[building_id]
		var level := int(buildings.get(building_id, 0))
		if level <= 0:
			continue
		if definition.effects.has("synthetic_max_mult"):
			synthetic_bonus = synthetic_bonus.add(_scaled_amount(definition, "synthetic_max_mult", level))
	if synthetic_bonus.sign != 0:
		var factor := AmountCompat.from_number(1.0).add(synthetic_bonus)
		for resource_id in SYNTHETIC_RESOURCE_KEYS:
			if caps.has(resource_id):
				caps[resource_id] = caps[resource_id].multiply(factor)
	for resource_id in caps:
		if skill_max_multipliers.has(String(resource_id)):
			caps[resource_id] = caps[resource_id].multiply(AmountCompat.from_number(float(skill_max_multipliers[String(resource_id)])))
	for resource_id in caps:
		caps[resource_id] = caps[resource_id].floor_amount()
	return caps

static func _collect_skill_effects(content: GameContent, skills: Dictionary) -> Array:
	var out: Array = []
	for skill_id in skills:
		var level := int(skills[skill_id])
		if level <= 0:
			continue
		var def_variant: Variant = content.skill(String(skill_id))
		if def_variant == null:
			continue
		var def: Dictionary = def_variant
		var effect: Variant = def.get("effect", null)
		if effect == null or not (effect is Dictionary):
			continue
		var effect_dict: Dictionary = effect
		var effect_type := String(effect_dict.get("type", ""))
		if effect_type.is_empty():
			continue
		out.append({"type": effect_type, "amount": float(effect_dict.get("amount", 0.0)), "level": level})
	return out

static func _skill_rate_additions(_content: GameContent, skill_defs: Array) -> Dictionary:
	var out := {}
	for e in skill_defs:
		var entry: Dictionary = e
		var type := String(entry.type)
		if type.ends_with("_rate"):
			var resource_id := type.substr(0, type.length() - 5)
			out[resource_id] = float(out.get(resource_id, 0.0)) + float(entry.amount) * float(entry.level)
	return out

static func _skill_rate_multipliers(_content: GameContent, skill_defs: Array) -> Dictionary:
	var out := {}
	for e in skill_defs:
		var entry: Dictionary = e
		var type := String(entry.type)
		if type.ends_with("_multiplier") and type != "all_rate_multiplier" and type != "all_max_multiplier":
			var resource_id := type.substr(0, type.length() - String("_multiplier").length())
			out[resource_id] = float(out.get(resource_id, 1.0)) * pow(float(entry.amount), float(entry.level))
	return out

static func _skill_capacity_additions(_content: GameContent, skill_defs: Array) -> Dictionary:
	var out := {}
	for e in skill_defs:
		var entry: Dictionary = e
		var type := String(entry.type)
		if type == "all_max":
			var flat := float(entry.amount) * float(entry.level)
			for resource_id in BASIC_RESOURCE_KEYS:
				out[resource_id] = float(out.get(resource_id, 0.0)) + flat
		elif type.ends_with("_max") and not type.ends_with("_max_multiplier") and type != "all_max_multiplier":
			var resource_id_f := type.substr(0, type.length() - String("_max").length())
			out[resource_id_f] = float(out.get(resource_id_f, 0.0)) + float(entry.amount) * float(entry.level)
	return out

static func _scaled_amount(definition: Dictionary, key: String, level: int) -> AmountCompat:
	var value := float(definition.effects[key])
	var weight := 0.0 if definition.effect_weight == null else float(definition.effect_weight)
	return AmountCompat.from_number(value).multiply(AmountCompat.from_number(pow(float(level) + weight, 1.5)))

static func _flat_amount(definition: Dictionary, key: String, level: int) -> AmountCompat:
	var value := float(definition.effects[key])
	return AmountCompat.from_number(value).multiply(AmountCompat.from_number(float(level)))

static func _is_capacity_key(key: String) -> bool:
	return key.ends_with("_max")
