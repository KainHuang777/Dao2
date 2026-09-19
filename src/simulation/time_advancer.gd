class_name TimeAdvancer
extends RefCounted

const SECONDS_PER_TICK := 60
const AFFORD_TOLERANCE := 0.000001
const ZERO_SNAP := 0.000000001

static func ticks_for_elapsed(elapsed_seconds: float) -> int:
	if is_nan(elapsed_seconds) or is_inf(elapsed_seconds) or elapsed_seconds < 0.0:
		return 0
	return int(floor(elapsed_seconds / float(SECONDS_PER_TICK)))

static func advance(state: GameState, content: GameContent, ticks: int) -> Dictionary:
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null}
	var events: Array = []
	var changed_ids: Array = []
	var changed_set := {}
	var executed := 0
	var stopped = null
	for _tick in range(ticks):
		var era_def = content.era(state.era_id)
		var era_multiplier := 1.0
		if era_def != null:
			era_multiplier = float(era_def.resource_multiplier)
		var rates := Production.compute_rates(content, state.buildings, era_multiplier)
		var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
		for resource_id in state.resources:
			var entry: Dictionary = state.resources[resource_id]
			if not bool(entry.unlocked):
				continue
			if not rates.has(resource_id):
				continue
			var delta: AmountCompat = rates[resource_id].multiply(AmountCompat.from_number(float(SECONDS_PER_TICK)))
			var new_value: AmountCompat = entry.value.add(delta)
			if caps.has(resource_id) and new_value.compare_to(caps[resource_id]) > 0:
				new_value = caps[resource_id]
			if new_value.compare_to(entry.value) != 0:
				entry.value = new_value
				var key := String(resource_id)
				if not changed_set.has(key):
					changed_set[key] = true
					changed_ids.append(key)
		state.training_seconds += float(SECONDS_PER_TICK)
		if era_def != null:
			var required := float(Cultivation.next_level_required_seconds(era_def, state.level, 0.0, 1.0))
			var max_level := int(era_def.max_level)
			if state.level < max_level and required > 0.0 and state.training_seconds >= required:
				var cost: Dictionary = Cultivation.level_up_cost(era_def, state.level, 0.0)
				if _is_affordable(state, cost):
					_deduct_cost(state, cost)
					state.level += 1
					state.training_seconds = 0.0
					events.append({"kind": "level_up", "level": state.level})
					if not changed_set.has("level"):
						changed_set["level"] = true
						changed_ids.append("level")
		state.total_elapsed_seconds += float(SECONDS_PER_TICK)
		var max_seconds := float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id))
		if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
			events.append({
				"kind": "lifespan_exhausted",
				"total_elapsed_seconds": state.total_elapsed_seconds,
				"max_lifespan_seconds": max_seconds,
			})
			stopped = "lifespan_exhausted"
			executed += 1
			break
		executed += 1
	return {
		"ticks_advanced": executed,
		"events": events,
		"changed_ids": changed_ids,
		"stopped": stopped,
	}

static func advance_time_only(state: GameState, content: GameContent, ticks: int) -> Dictionary:
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null}
	var events: Array = []
	var executed := 0
	var stopped = null
	for _tick in range(ticks):
		state.total_elapsed_seconds += float(SECONDS_PER_TICK)
		var max_seconds := float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id))
		if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
			events.append({
				"kind": "lifespan_exhausted",
				"total_elapsed_seconds": state.total_elapsed_seconds,
				"max_lifespan_seconds": max_seconds,
			})
			stopped = "lifespan_exhausted"
			executed += 1
			break
		executed += 1
	return {
		"ticks_advanced": executed,
		"events": events,
		"changed_ids": [],
		"stopped": stopped,
	}

static func _is_affordable(state: GameState, cost: Dictionary) -> bool:
	for cost_id in cost:
		var key := String(cost_id)
		if not state.resources.has(key):
			return false
		var entry: Dictionary = state.resources[key]
		if not bool(entry.unlocked):
			return false
		var available: AmountCompat = entry.value.add(AmountCompat.from_number(AFFORD_TOLERANCE))
		var required: AmountCompat = cost[cost_id]
		if available.compare_to(required) < 0:
			return false
	return true

static func _deduct_cost(state: GameState, cost: Dictionary) -> void:
	for cost_id in cost:
		var entry: Dictionary = state.resources[String(cost_id)]
		var required: AmountCompat = cost[cost_id]
		var after: AmountCompat = entry.value.subtract(required)
		if after.sign < 0 or after.mag < ZERO_SNAP:
			after = AmountCompat.zero()
		entry.value = after
