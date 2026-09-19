class_name BuildingCosts
extends RefCounted

const DEFAULT_COST_FACTOR := 1.15
const COST_REDUCTION_CAP := 0.9
const COST_TOLERANCE := 0.000001

static func resolve_base_cost(building_id: String, base_cost: Dictionary, onboarding_active: bool) -> Dictionary:
	if building_id == "hut" and not onboarding_active:
		return {"money": 30.0}
	return base_cost

static func compute_cost(base_cost: Dictionary, level: int, cost_factor: float, cost_reduction: float = 0.0, intuition_level: int = 0) -> Dictionary:
	var b1 := maxf(1.0, cost_factor - 0.01 * float(intuition_level))
	var b2 := b1 + 0.10
	var b3 := b1 + 0.15
	var exponential := _exponential_factor(b1, b2, b3, level)
	var linear := 1.0 + float(level) / 20.0
	var reducer := _reduction_factor(cost_reduction)
	var costs := {}
	for resource_id in base_cost:
		var base := AmountCompat.from_number(float(base_cost[resource_id]))
		costs[resource_id] = base.multiply(exponential).multiply(AmountCompat.from_number(linear)).multiply(reducer).floor_amount()
	return costs

static func _exponential_factor(b1: float, b2: float, b3: float, level: int) -> AmountCompat:
	if level <= 20:
		return AmountCompat.from_number(b1).pow_amount(float(level))
	var head := AmountCompat.from_number(b1).pow_amount(20.0)
	if level <= 50:
		return head.multiply(AmountCompat.from_number(b2).pow_amount(float(level - 20)))
	return head.multiply(AmountCompat.from_number(b2).pow_amount(30.0)).multiply(AmountCompat.from_number(b3).pow_amount(float(level - 50)))

static func _reduction_factor(cost_reduction: float) -> AmountCompat:
	var clamped := clampf(cost_reduction, 0.0, COST_REDUCTION_CAP)
	if clamped <= 0.0:
		clamped = 0.0
	var units := int(round(clamped * 1000000.0))
	return AmountCompat.from_number(float(1000000 - units) / 1000000.0)
