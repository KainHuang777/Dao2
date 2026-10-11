extends RefCounted
## Pure pacing formulas for the early-game audit (no state, no content access).
## Callers feed numbers produced by the real rules (Production / BuildingCosts /
## Cultivation); nothing here duplicates a game rule.
## Units: resources, seconds, per-second rates.

const INF_SECONDS := 1.0e12

## Relative rate gain of one upgrade, e.g. 5 -> 7 is 0.4.
static func gain_ratio(rate_old: float, rate_new: float) -> float:
	if rate_old <= 0.0:
		return INF_SECONDS if rate_new > 0.0 else 0.0
	return (rate_new - rate_old) / rate_old

## Seconds until `cost` is affordable from `stock` at `rate`.
static func afford_seconds(cost: float, stock: float, rate: float) -> float:
	var deficit := cost - stock
	if deficit <= 0.0:
		return 0.0
	if rate <= 0.0:
		return INF_SECONDS
	return deficit / rate

## Seconds to fill an empty store.
static func fill_seconds(cap: float, rate: float) -> float:
	if cap <= 0.0:
		return 0.0
	if rate <= 0.0:
		return INF_SECONDS
	return cap / rate

## Capacity / next cost. < 1 means the cost can never be paid (deadlock).
static func cap_pressure(cap: float, cost: float) -> float:
	if cost <= 0.0:
		return INF_SECONDS
	return cap / cost

## Resources lost by buying `delay` seconds late: the extra rate that was not earned.
static func delay_loss(delta_rate: float, delay: float) -> float:
	return maxf(0.0, delta_rate) * maxf(0.0, delay)

## Fraction of production discarded when the store is only emptied every `interval` s.
static func overflow_ratio(cap: float, rate: float, interval: float) -> float:
	var produced := rate * interval
	if produced <= 0.0:
		return 0.0
	return clampf(1.0 - cap / produced, 0.0, 1.0)

## Cost expressed as seconds of production, summed over cost resources, divided by gain.
## `cost_seconds` is the sum over cost resources of cost / rate.
static func payback_seconds(cost_seconds: float, gain: float) -> float:
	if gain <= 0.0:
		return INF_SECONDS
	return cost_seconds / gain

## Share of the idle duration that active play removes.
static func reducible_share(idle_seconds: float, active_seconds: float) -> float:
	if idle_seconds <= 0.0:
		return 0.0
	return clampf((idle_seconds - active_seconds) / idle_seconds, 0.0, 1.0)

static func in_band(value: float, low: float, high: float) -> bool:
	return value >= low and value <= high

## Total wall-clock seconds of the level-up chain: sum of base * mult^(l-1), l = 1..max-1.
static func chain_training_seconds(base_time: float, time_multiplier: float, max_level: int) -> float:
	var total := 0.0
	for level in range(1, max_level):
		total += base_time * pow(time_multiplier, float(level - 1))
	return total

static func fmt(value: float) -> String:
	if value >= INF_SECONDS * 0.5:
		return "INF"
	if absf(value) >= 100.0:
		return "%.0f" % value
	if absf(value) >= 10.0:
		return "%.1f" % value
	return "%.2f" % value
