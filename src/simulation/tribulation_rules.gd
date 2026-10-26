class_name TribulationRules
extends RefCounted

const TRIBULATION_MIN_ERA := 3
const BASE_RATE_EAR3 := 0.80
const BASE_RATE_STEP := 0.10
const BASE_RATE_FLOOR := 0.30
const DECAY := 0.85
const COUNT_CAP := 99
const P_MIN := 0.05
const P_MAX := 0.95
const PILL_BONUS := {"golden_tribulation_pill": 0.03, "tribulation_pill": 0.05}
const ERA_PILL := {3: "golden_tribulation_pill", 4: "tribulation_pill"}

static func requires_tribulation(from_era: int) -> bool:
	return from_era >= TRIBULATION_MIN_ERA

static func base_rate(from_era: int) -> float:
	if from_era < TRIBULATION_MIN_ERA:
		return 0.0
	return maxf(BASE_RATE_FLOOR, BASE_RATE_EAR3 - BASE_RATE_STEP * float(from_era - TRIBULATION_MIN_ERA))

static func pill_for_era(from_era: int) -> String:
	return String(ERA_PILL.get(from_era, ""))

static func pill_bonus(pill_id: String, count: int) -> float:
	var base_bonus: float = float(PILL_BONUS.get(pill_id, 0.0))
	var n: int = clampi(count, 0, COUNT_CAP)
	return base_bonus * (1.0 - pow(DECAY, float(n))) / (1.0 - DECAY)

static func success_probability(from_era: int, pill_count: int) -> float:
	return clampf(base_rate(from_era) + pill_bonus(pill_for_era(from_era), pill_count), P_MIN, P_MAX)

static func roll(seed_value: int, roll_index: int) -> float:
	return float(("%d:%d" % [seed_value, roll_index]).hash() & 0x7FFFFFFF) / 2147483648.0

static func is_success(roll_value: float, probability: float) -> bool:
	return roll_value < probability

static func state_probability(state: GameState) -> float:
	var bonus := 0.0
	for id in AlchemySystem.P2_WARDS:
		bonus += float(AlchemySystem.P2_WARDS[id]) * AlchemySystem.stack_count(state, id)
	return clampf(base_rate(state.era_id) + pill_bonus(pill_for_era(state.era_id), AlchemySystem.stack_count(state, pill_for_era(state.era_id))) + bonus, P_MIN, P_MAX)
