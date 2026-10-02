class_name TimeAdvancer
extends RefCounted

const SECONDS_PER_TICK := 1

static func ticks_for_elapsed(elapsed_seconds: float) -> int:
	if is_nan(elapsed_seconds) or is_inf(elapsed_seconds) or elapsed_seconds < 0.0:
		return 0
	return int(floor(elapsed_seconds / float(SECONDS_PER_TICK)))

static func advance(state: GameState, content: GameContent, ticks: int) -> Dictionary:
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null}
	var multipliers := TalentSystem.compute_multipliers(state)
	var buff_multipliers := BuffSystem.compute_multipliers(state)
	var pill_lifespan_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_multipliers.lifespan_bonus_years)
	var max_seconds := float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, float(multipliers.lifespan_bonus), pill_lifespan_bonus))
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "lifespan_exhausted"}
	# Rates and multipliers stay fixed until a player command; combine whole seconds for offline settlement.
	var executed := mini(ticks, maxi(1, int(ceil((max_seconds - state.total_elapsed_seconds) / float(SECONDS_PER_TICK)))))
	var elapsed := float(executed) * float(SECONDS_PER_TICK)
	var era_def = content.era(state.era_id)
	var era_multiplier := 1.0 if era_def == null else float(era_def.resource_multiplier)
	var pill_prod_multiplier := 1.0 + float(state.pill_effects.get("production_multiplier", 0.0)) + float(buff_multipliers.global_production_multiplier)
	var chrono_multipliers := ChronoSystem.compute_multipliers(state)
	var global_prod_total := era_multiplier * float(multipliers.global_production_multiplier) * (pill_prod_multiplier + float(chrono_multipliers.global_production_multiplier))
	var rates := Production.compute_rates(content, state.buildings, global_prod_total, state.skills)
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills)
	var sect_multipliers := SectSystem.compute_multipliers(state)
	var spec_multipliers: Dictionary = buff_multipliers.get("specific_resource_multipliers", {})
	var chrono_spec: Dictionary = chrono_multipliers.get("specific_resource_multipliers", {})
	var changed_ids: Array = []
	for resource_id in state.resources:
		var entry: Dictionary = state.resources[resource_id]
		if not bool(entry.unlocked) or not rates.has(resource_id):
			continue
		var rate: AmountCompat = rates[resource_id]
		if spec_multipliers.has(resource_id):
			var extra_mult: float = 1.0 + float(spec_multipliers[resource_id])
			rate = rate.multiply(AmountCompat.from_number(extra_mult))
		if chrono_spec.has(resource_id):
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(chrono_spec[resource_id])))
		if (resource_id == "herb" or resource_id == "wood") and float(sect_multipliers.production_herb_wood) > 0.0:
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(sect_multipliers.production_herb_wood)))
		var delta: AmountCompat = rate.multiply(AmountCompat.from_number(elapsed))
		var new_value: AmountCompat = entry.value.add(delta)
		var cap_limit: AmountCompat = caps.get(resource_id, AmountCompat.zero())
		var total_storage_bonus: float = float(sect_multipliers.storage_bonus) + float(chrono_multipliers.storage_bonus)
		if total_storage_bonus > 0.0 and cap_limit.compare_to(AmountCompat.zero()) > 0:
			cap_limit = cap_limit.multiply(AmountCompat.from_number(1.0 + total_storage_bonus))
		if resource_id == "lingqi" and float(sect_multipliers.lingqi_cap_bonus) > 0.0 and cap_limit.compare_to(AmountCompat.zero()) > 0:
			cap_limit = cap_limit.multiply(AmountCompat.from_number(1.0 + float(sect_multipliers.lingqi_cap_bonus)))
		if caps.has(resource_id) and new_value.compare_to(cap_limit) > 0:
			new_value = cap_limit
		if new_value.compare_to(entry.value) != 0:
			entry.value = new_value
			changed_ids.append(String(resource_id))
	var feedback_boost := RealmSystem.get_feedback_cultivation_boost(state)
	state.training_seconds += elapsed * (1.0 + float(multipliers.cultivation_speed_bonus) + float(buff_multipliers.cultivation_speed_bonus) + float(sect_multipliers.cultivation_speed_bonus) + float(chrono_multipliers.cultivation_speed_bonus) + feedback_boost)
	state.total_elapsed_seconds += elapsed
	BuffSystem.tick(state, elapsed)
	RealmSystem.tick(state, elapsed)
	SectSystem.tick(state, elapsed)
	ChronoSystem.tick(state, elapsed)
	FortuneSystem.advance_time(state, elapsed)
	RealmDecisionSystem.advance_time(state, elapsed)
	var events: Array = []
	var stopped = null
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		events.append({"kind": "lifespan_exhausted", "total_elapsed_seconds": state.total_elapsed_seconds, "max_lifespan_seconds": max_seconds})
		stopped = "lifespan_exhausted"
	return {"ticks_advanced": executed, "events": events, "changed_ids": changed_ids, "stopped": stopped}

static func advance_time_only(state: GameState, content: GameContent, ticks: int) -> Dictionary:
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null}
	var lifespan_bonus := float(TalentSystem.compute_multipliers(state).lifespan_bonus)
	var buff_multipliers := BuffSystem.compute_multipliers(state)
	var pill_lifespan_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_multipliers.lifespan_bonus_years)
	var max_seconds := float(Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, lifespan_bonus, pill_lifespan_bonus))
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "lifespan_exhausted"}
	var executed := mini(ticks, maxi(1, int(ceil((max_seconds - state.total_elapsed_seconds) / float(SECONDS_PER_TICK)))))
	var elapsed := float(executed) * float(SECONDS_PER_TICK)
	state.total_elapsed_seconds += elapsed
	BuffSystem.tick(state, elapsed)
	RealmSystem.tick(state, elapsed)
	SectSystem.tick(state, elapsed)
	ChronoSystem.tick(state, elapsed)
	FortuneSystem.advance_time(state, elapsed)
	RealmDecisionSystem.advance_time(state, elapsed)
	var events: Array = []
	var stopped = null
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		events.append({"kind": "lifespan_exhausted", "total_elapsed_seconds": state.total_elapsed_seconds, "max_lifespan_seconds": max_seconds})
		stopped = "lifespan_exhausted"
	return {"ticks_advanced": executed, "events": events, "changed_ids": [], "stopped": stopped}
