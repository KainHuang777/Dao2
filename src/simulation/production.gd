class_name Production
extends RefCounted

const BASIC_RESOURCE_KEYS := ["lingli", "money", "wood", "stone_low", "spirit_grass_low"]
const SYNTHETIC_RESOURCE_KEYS := ["stone_mid", "stone_high", "liquid", "talisman", "star_metal", "void_crystal"]

static func compute_rates(content: GameContent, buildings: Dictionary, resource_multiplier: float = 1.0, skills: Dictionary = {}, talents: Dictionary = {}) -> Dictionary:
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
			if building_id in TalentSystem.ARTISAN_BUILDINGS:
				scaled = scaled.multiply(AmountCompat.from_number(1.0 + TalentSystem.p1_bonus(talents, "artisan_past_wisdom")))
			if String(key) == "all_rate":
				for resource_id in BASIC_RESOURCE_KEYS:
					if rates.has(resource_id):
						rates[resource_id] = rates[resource_id].add(scaled)
			elif rates.has(String(key)):
				rates[key] = rates[key].add(scaled)
	for resource_id in rates:
		var addition := SkillSystem.effect(content, skills, String(resource_id) + "_rate")
		var multiplier := SkillSystem.effect(content, skills, String(resource_id) + "_multiplier")
		if addition != 0:
			rates[resource_id] = rates[resource_id].add(AmountCompat.from_number(addition))
		if multiplier != 1:
			rates[resource_id] = rates[resource_id].multiply(AmountCompat.from_number(multiplier))
		var p2_multiplier := SksP2Rules.home_rate_multiplier(String(resource_id), skills)
		if p2_multiplier != 1.0:
			rates[resource_id] = rates[resource_id].multiply(AmountCompat.from_number(p2_multiplier))
		rates[resource_id] = rates[resource_id].multiply(AmountCompat.from_number(resource_multiplier))
	return rates

static func compute_caps(content: GameContent, buildings: Dictionary, era_id: int, onboarding_version: int, skills: Dictionary = {}) -> Dictionary:
	var caps := {}
	for resource_id in content.resource_ids:
		var definition: Dictionary = content.resources[resource_id]
		caps[resource_id] = AmountCompat.from_number(float(definition.max))
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
		var addition := SkillSystem.effect(content, skills, String(resource_id) + "_max")
		if resource_id in SkillSystem.MATERIALS:
			addition += SkillSystem.effect(content, skills, "p1_material_capacity_flat")
		if addition != 0:
			caps[resource_id] = caps[resource_id].add(AmountCompat.from_number(addition))
		var p2_multiplier := SksP2Rules.cap_multiplier(String(resource_id), skills)
		if p2_multiplier != 1.0:
			caps[resource_id] = caps[resource_id].multiply(AmountCompat.from_number(p2_multiplier))
		caps[resource_id] = caps[resource_id].floor_amount()
	return caps

static func _scaled_amount(definition: Dictionary, key: String, level: int) -> AmountCompat:
	var value := float(definition.effects[key])
	var weight := 0.0 if definition.effect_weight == null else float(definition.effect_weight)
	return AmountCompat.from_number(value).multiply(AmountCompat.from_number(pow(float(level) + weight, 1.5)))

static func _flat_amount(definition: Dictionary, key: String, level: int) -> AmountCompat:
	var value := float(definition.effects[key])
	return AmountCompat.from_number(value).multiply(AmountCompat.from_number(float(level)))

static func _is_capacity_key(key: String) -> bool:
	return key.ends_with("_max")

## The flat pill extension is always applied after existing multipliers/rounding.
static func add_pill_capacity(state: GameState, id: String, cap: AmountCompat) -> AmountCompat:
	var flat := AlchemySystem.capacity_bonus(state, id)
	if SectSpecialization.capacity_bonus(state, id) > 0: cap = cap.floor_amount()
	return cap.floor_amount().add(AmountCompat.from_number(flat)) if flat > 0 else cap

static func pill_caps(state: GameState, caps: Dictionary) -> Dictionary:
	for id in caps:
		if AlchemySystem.capacity_bonus(state, id) <= 0 and SectSpecialization.capacity_bonus(state, id) <= 0: continue
		var cap: AmountCompat = caps[id]
		var copy := GameState.new()
		copy.era_id = state.era_id
		copy.total_elapsed_seconds = state.total_elapsed_seconds
		copy.beasts = state.beasts.duplicate(true)
		copy.beast_talents = state.beast_talents.duplicate(true)
		copy.chrono = state.chrono.duplicate(true)
		copy.sect = state.sect
		var beast := BeastSystem.compute_multipliers(copy)
		var sect := SectSystem.compute_multipliers(copy)
		var chrono := ChronoSystem.compute_multipliers(copy)
		var bonus := SectSpecialization.capacity_bonus(state, id) + float(beast.all_capacity_mult) + float(sect.storage_bonus) + float(chrono.storage_bonus)
		if id in ["stone_low", "refined_iron"]: bonus += float(beast.cap_stone_iron)
		if bonus > 0 and cap.sign > 0: cap = cap.multiply(AmountCompat.from_number(1.0 + bonus))
		caps[id] = add_pill_capacity(state, id, cap)
	return caps
