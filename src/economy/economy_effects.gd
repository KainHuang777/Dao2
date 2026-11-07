class_name EconomyEffects
extends RefCounted
## New-edition only. Positive reductions use one sum and one DR per family/scope.
const LIMITS := {"building_cost": 0.8, "processing_cost": 0.5, "work_time": 0.7, "research_inheritance": 0.7}
const PRECISION := 1000000.0
const MAX_AMOUNT := 1.0e12

static func finite(value: Variant) -> bool:
	return (value is int or value is float) and not is_nan(float(value)) and not is_inf(float(value))

static func dr(raw: float, limit: float) -> Dictionary:
	if not finite(raw) or not finite(limit) or raw < 0.0 or limit <= 0.0:
		return {"ok": false, "error": "EFFECT_DOMAIN"}
	var effective := raw if raw <= 0.75 * limit else limit - pow(0.25 * limit, 2) / (raw - 0.5 * limit)
	return {"ok": true, "effective": effective}

static func resolve(family: String, scope: String, sources: Array) -> Dictionary:
	if not LIMITS.has(family) or scope.is_empty(): return {"ok": false, "error": "EFFECT_FAMILY"}
	var raw := 0.0
	var included: Array = []
	var seen := {}
	for source in sources:
		if not source is Dictionary: return {"ok": false, "error": "EFFECT_SOURCE"}
		for key in ["effect_id", "family", "scope", "unit", "stack_mode", "source"]:
			if not source.get(key) is String or source[key].is_empty(): return {"ok": false, "error": "EFFECT_SOURCE"}
		if not LIMITS.has(source.family) or source.get("unit") != "reduction" or source.get("stack_mode") != "sum_then_dr" or not finite(source.get("limit")) or float(source.limit) != LIMITS[source.family] or not finite(source.get("value")) or float(source.value) < 0:
			return {"ok": false, "error": "EFFECT_SOURCE"}
		if seen.has(source.effect_id): return {"ok": false, "error": "EFFECT_DUPLICATE"}
		seen[source.effect_id] = true
		if source.family == family and source.scope == scope:
			raw += float(source.value)
			included.append(source.duplicate(true))
	var result := dr(raw, LIMITS[family])
	if not result.ok: return result
	result.merge({"family": family, "scope": scope, "raw": raw, "limit": LIMITS[family], "sources": included})
	return result

static func valid_reduction(reduction: Dictionary) -> bool:
	if not reduction.get("ok") is bool or not reduction.ok or not reduction.get("family") is String or not LIMITS.has(reduction.family) or not reduction.get("scope") is String or not reduction.get("sources") is Array: return false
	var resolved := resolve(reduction.family, reduction.scope, reduction.sources)
	return resolved.ok and ResearchSystem.same(resolved, reduction)

static func duration(base_seconds: int, reduction: Dictionary, minimum: int = 1) -> Dictionary:
	if base_seconds <= 0 or minimum < 1 or not valid_reduction(reduction) or reduction.get("family") not in ["work_time", "research_inheritance"]:
		return {"ok": false, "error": "DURATION_DOMAIN"}
	return {"ok": true, "seconds": maxi(minimum, int(ceil(base_seconds * (1.0 - float(reduction.effective))))), "effect": reduction.duplicate(true)}

static func cost(base: AmountCompat, batches: int, discrete: bool, reduction: Dictionary) -> Dictionary:
	if base == null or not finite(base.mag) or base.layer != 0 or base.sign <= 0 or base.to_float() > MAX_AMOUNT or batches < 1 or batches > 1000000 or not valid_reduction(reduction) or reduction.get("family") not in ["building_cost", "processing_cost"]:
		return {"ok": false, "error": "COST_DOMAIN"}
	var unit := base.to_float()
	if discrete:
		if unit != floor(unit): return {"ok": false, "error": "DISCRETE_COST"}
	else:
		# Round each unit upward at fixed precision BEFORE multiplying by batches.
		# All preview/start/batch consumers use this quote; splitting cannot save.
		unit = maxf(1.0 / PRECISION, ceil(unit * (1.0 - float(reduction.effective)) * PRECISION) / PRECISION)
	if unit * batches > MAX_AMOUNT: return {"ok": false, "error": "COST_BOUNDARY"}
	return {"ok": true, "amount": AmountCompat.from_number(unit).multiply(AmountCompat.from_number(batches)), "unit": unit, "effect": reduction.duplicate(true)}
