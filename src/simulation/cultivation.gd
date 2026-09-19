class_name Cultivation
extends RefCounted

static func cumulative_training_time(base_time: float, time_multiplier: float, current_level: int) -> float:
	if time_multiplier == 1.0:
		return base_time * float(current_level)
	var result: float = base_time * (1.0 - pow(time_multiplier, float(current_level))) / (1.0 - time_multiplier)
	if result == 0.0:
		return 0.0
	return result

static func single_level_time(base_time: float, time_multiplier: float, current_level: int) -> float:
	return base_time * pow(time_multiplier, float(maxi(0, current_level - 1)))

static func apply_time_bonuses(raw: float, time_bonus: float, skill_time_mult: float, time_reduction: float) -> float:
	var t: float = raw / (1.0 + time_bonus)
	t = t * maxf(0.1, skill_time_mult)
	t = t * maxf(0.1, 1.0 - time_reduction)
	return t

static func skill_time_multiplier(skills: Array) -> float:
	var mult: float = 1.0
	for entry in skills:
		var skill: Dictionary = entry
		if String(skill.get("type", "")) == "time_reduction":
			mult *= pow(float(skill["amount"]), float(skill["level"]))
	return mult

static func next_level_required_seconds(era_def: Dictionary, era_level: int, time_bonus: float, skill_time_mult: float) -> float:
	var req: Dictionary = era_def["level_up_requirements"]
	return apply_time_bonuses(single_level_time(float(req["base_time"]), float(req["time_multiplier"]), era_level), time_bonus, skill_time_mult, 0.0)

static func level_up_cost(era_def: Dictionary, era_level: int, cost_reduction: float) -> Dictionary:
	var req: Dictionary = era_def["level_up_requirements"]
	var costs: Dictionary[String, AmountCompat] = {}
	var resources: Dictionary = req["resources"]
	for resource_id in resources:
		costs[String(resource_id)] = AmountCompat.from_number(float(resources[resource_id])).multiply(AmountCompat.from_number(1.0 - cost_reduction)).floor_amount()
	if era_level == 9:
		var raw_lv9: Variant = req.get("lv9_item", null)
		if raw_lv9 is Dictionary:
			var lv9_item: Dictionary = raw_lv9
			costs[String(lv9_item["type"])] = AmountCompat.from_number(float(lv9_item["amount"])).multiply(AmountCompat.from_number(1.0 - cost_reduction)).floor_amount()
	return costs
