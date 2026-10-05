class_name TimeAdvancer
extends RefCounted

const SECONDS_PER_TICK := 1

static func ticks_for_elapsed(elapsed_seconds: float) -> int:
	if is_nan(elapsed_seconds) or is_inf(elapsed_seconds) or elapsed_seconds < 0.0:
		return 0
	return int(floor(elapsed_seconds / float(SECONDS_PER_TICK)))

static func advance(state: GameState, content: GameContent, ticks: int, prepared: Dictionary = {}) -> Dictionary:
	if state.economy.is_empty():
		return _advance_legacy(state, content, ticks)
	if content.processing_catalog.is_empty():
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "processing_content_missing"}
	var executed := 0
	var events: Array = []
	var changed: Array = []
	var stopped: Variant = null
	if prepared.is_empty():
		prepared = prepare_advance(state, content)
	# The yielding coordinator requests one tick at a time. Avoid constructing
	# and merging a second result envelope for that same single tick.
	if ticks == 1:
		var result := _advance_legacy(state, content, 1, prepared)
		if int(result.ticks_advanced) > 0:
			var economy_events := IslandEconomy.tick_prepared(state, content.processing_catalog, prepared.economy)
			economy_events.append_array(result.events)
			result.events = economy_events
			result.changed_ids.append("economy")
		return result
	# Fixed one-second boundaries also split buffs, weather and lifespan. No frame RNG.
	for _tick in range(maxi(0, ticks)):
		var result := _advance_legacy(state, content, 1, prepared)
		if int(result.ticks_advanced) > 0:
			executed += 1
			events.append_array(IslandEconomy.tick_prepared(state, content.processing_catalog, prepared.economy))
		for id in result.changed_ids:
			if not id in changed:
				changed.append(id)
		events.append_array(result.events)
		stopped = result.stopped
		if stopped != null:
			break
	if executed > 0:
		changed.append("economy")
	return {"ticks_advanced": executed, "events": events, "changed_ids": changed, "stopped": stopped}

static func prepare_advance(state: GameState, content: GameContent) -> Dictionary:
	# Scoped to one command-free settlement. Never persist or reuse after commands.
	# Timers and observed stock still advance at one-second boundaries.
	return {"talents": TalentSystem.compute_multipliers(state),
		"caps": Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills),
		"lifespans": content.era_lifespan_entries(),
		"sect": SectSystem.compute_multipliers(state), "economy": {},
		"era_multiplier": 1.0 if content.era(state.era_id) == null else float(content.era(state.era_id).resource_multiplier),
		"feedback_boost": RealmSystem.get_feedback_cultivation_boost(state)}

static func _advance_legacy(state: GameState, content: GameContent, ticks: int, prepared: Dictionary = {}) -> Dictionary:
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null}
	var multipliers: Dictionary = prepared.get("talents", {})
	if multipliers.is_empty():
		multipliers = TalentSystem.compute_multipliers(state)
	var buff_multipliers: Dictionary
	if not prepared.is_empty() and prepared.get("buff_count", -1) == state.buffs.size():
		buff_multipliers = prepared.buffs
	else:
		buff_multipliers = BuffSystem.compute_multipliers(state)
		if not prepared.is_empty():
			# In this command-free run tick only expires buffs; it never adds/edits effects.
			prepared.buffs = buff_multipliers
			prepared.buff_count = state.buffs.size()
			prepared.erase("max_seconds")
			prepared.erase("training_speed")
	var pill_lifespan_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_multipliers.lifespan_bonus_years)
	var lifespans: Array = prepared.get("lifespans", [])
	if lifespans.is_empty():
		lifespans = content.era_lifespan_entries()
	var max_seconds: float
	if prepared.has("max_seconds"):
		max_seconds = prepared.max_seconds
	else:
		max_seconds = float(Lifespan.max_lifespan_seconds(lifespans, state.era_id, float(multipliers.lifespan_bonus), pill_lifespan_bonus))
		if not prepared.is_empty():
			prepared.max_seconds = max_seconds
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "lifespan_exhausted"}
	# Rates and multipliers stay fixed until a player command; combine whole seconds for offline settlement.
	var executed := mini(ticks, maxi(1, int(ceil((max_seconds - state.total_elapsed_seconds) / float(SECONDS_PER_TICK)))))
	var elapsed := float(executed) * float(SECONDS_PER_TICK)
	var era_multiplier: float
	if prepared.has("era_multiplier"):
		era_multiplier = prepared.era_multiplier
	else:
		var era_def = content.era(state.era_id)
		era_multiplier = 1.0 if era_def == null else float(era_def.resource_multiplier)
	var pill_prod_multiplier := 1.0 + float(state.pill_effects.get("production_multiplier", 0.0)) + float(buff_multipliers.global_production_multiplier)
	var chrono_multipliers: Dictionary
	var shichen := int(floor(maxf(0, state.total_elapsed_seconds) / ChronoSystem.SECONDS_PER_SHICHEN))
	if not prepared.is_empty() and prepared.get("shichen", -1) == shichen:
		chrono_multipliers = prepared.chrono
	else:
		chrono_multipliers = ChronoSystem.compute_multipliers(state)
		if not prepared.is_empty():
			# Weather boundaries are multiples of shichen; tick still syncs saved progress.
			prepared.chrono = chrono_multipliers
			prepared.shichen = shichen
			prepared.erase("training_speed")
	var beast_multipliers: Dictionary = prepared.get("beast", {})
	if beast_multipliers.is_empty():
		beast_multipliers = BeastSystem.compute_multipliers(state)
		if not prepared.is_empty():
			# Initialization has side effects: defer until after the lifespan/zero-tick guard.
			prepared.beast = beast_multipliers
	var global_prod_total := era_multiplier * float(multipliers.global_production_multiplier) * (pill_prod_multiplier + float(chrono_multipliers.global_production_multiplier) + float(beast_multipliers.global_production_multiplier))
	var rates: Dictionary
	if prepared.has("rates") and prepared.get("rate_multiplier") == global_prod_total:
		rates = prepared.rates
	else:
		rates = Production.compute_rates(content, state.buildings, global_prod_total, state.skills)
		if not prepared.is_empty():
			prepared.rates = rates
			prepared.rate_multiplier = global_prod_total
	var caps: Dictionary = prepared.get("caps", {})
	if caps.is_empty():
		caps = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills)
	var sect_multipliers: Dictionary = prepared.get("sect", {})
	if sect_multipliers.is_empty():
		sect_multipliers = SectSystem.compute_multipliers(state)
	var spec_multipliers: Dictionary = buff_multipliers.get("specific_resource_multipliers", {})
	var chrono_spec: Dictionary = chrono_multipliers.get("specific_resource_multipliers", {})
	var changed_ids: Array = []
	if not prepared.is_empty() and executed == 1:
		changed_ids = _produce_prepared(state, content, rates, caps, buff_multipliers, chrono_multipliers, sect_multipliers, beast_multipliers, prepared)
	else:
		changed_ids = _produce_uncached(state, content, rates, caps, spec_multipliers, chrono_spec, sect_multipliers, chrono_multipliers, beast_multipliers, elapsed)
	var training_speed: float
	if prepared.has("training_speed"):
		training_speed = prepared.training_speed
	else:
		var feedback_boost: float = prepared.get("feedback_boost", RealmSystem.get_feedback_cultivation_boost(state))
		training_speed = 1.0 + float(multipliers.cultivation_speed_bonus) + float(buff_multipliers.cultivation_speed_bonus) + float(sect_multipliers.cultivation_speed_bonus) + float(chrono_multipliers.cultivation_speed_bonus) + float(beast_multipliers.cultivation_speed_bonus) + feedback_boost
		if not prepared.is_empty():
			prepared.training_speed = training_speed
	# Keep the original addition every second, including floating-point rounding.
	state.training_seconds += elapsed * training_speed
	state.total_elapsed_seconds += elapsed
	BuffSystem.tick(state, elapsed)
	RealmSystem.tick(state, elapsed)
	SectSystem.tick(state, elapsed)
	ChronoSystem.tick(state, elapsed)
	FortuneSystem.advance_time(state, elapsed)
	RealmDecisionSystem.advance_time(state, elapsed)
	BeastSystem.tick(state, elapsed)
	var events: Array = AbodeScenery.advance(state, elapsed)
	if not events.is_empty():
		changed_ids.append("abode_scenery")
	var stopped = null
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		events.append({"kind": "lifespan_exhausted", "total_elapsed_seconds": state.total_elapsed_seconds, "max_lifespan_seconds": max_seconds})
		stopped = "lifespan_exhausted"
	return {"ticks_advanced": executed, "events": events, "changed_ids": changed_ids, "stopped": stopped}

static func _produce_uncached(state: GameState, content: GameContent, rates: Dictionary, caps: Dictionary, spec_multipliers: Dictionary, chrono_spec: Dictionary, sect_multipliers: Dictionary, chrono_multipliers: Dictionary, beast_multipliers: Dictionary, elapsed: float) -> Array:
	# Reference Amount operation order, also used by the aggregate legacy path.
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
		if (resource_id == "herb" or resource_id == "spirit_grass_low") and (float(sect_multipliers.production_herb_wood) > 0.0 or float(beast_multipliers.production_herb) > 0.0):
			var herb_mult := 1.0 + float(sect_multipliers.production_herb_wood) + float(beast_multipliers.production_herb)
			rate = rate.multiply(AmountCompat.from_number(herb_mult))
		if (resource_id == "stone_low" or resource_id == "refined_iron") and float(beast_multipliers.production_stone_iron) > 0.0:
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast_multipliers.production_stone_iron)))
		if resource_id == "money" and float(beast_multipliers.money_rate) > 0.0:
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast_multipliers.money_rate)))
		var delta: AmountCompat = rate.multiply(AmountCompat.from_number(elapsed))
		var new_value: AmountCompat = entry.value.add(delta)
		var cap_limit: AmountCompat = caps.get(resource_id, AmountCompat.zero())
		var total_storage_bonus: float = float(sect_multipliers.storage_bonus) + float(chrono_multipliers.storage_bonus) + float(beast_multipliers.all_capacity_mult)
		if (resource_id == "stone_low" or resource_id == "refined_iron") and float(beast_multipliers.cap_stone_iron) > 0.0:
			total_storage_bonus += float(beast_multipliers.cap_stone_iron)
		if total_storage_bonus > 0.0 and cap_limit.compare_to(AmountCompat.zero()) > 0:
			cap_limit = cap_limit.multiply(AmountCompat.from_number(1.0 + total_storage_bonus))
		if resource_id == "lingqi" and float(sect_multipliers.lingqi_cap_bonus) > 0.0 and cap_limit.compare_to(AmountCompat.zero()) > 0:
			cap_limit = cap_limit.multiply(AmountCompat.from_number(1.0 + float(sect_multipliers.lingqi_cap_bonus)))
		if not state.economy.is_empty() and content.processing_catalog.resources.has(resource_id):
			var held := IslandEconomy.reserved(state, "home", resource_id, content.processing_catalog)
			var effective_cap := minf(cap_limit.to_float(), float(content.processing_catalog.resources[resource_id].cap)) - held
			# Capacity contraction stops future production; never deletes existing stock.
			cap_limit = AmountCompat.from_number(maxf(entry.value.to_float(), maxf(0, effective_cap)))
		if caps.has(resource_id) and new_value.compare_to(cap_limit) > 0:
			new_value = cap_limit
		if new_value.compare_to(entry.value) != 0:
			entry.value = new_value
			changed_ids.append(String(resource_id))
	return changed_ids

static func _produce_prepared(state: GameState, content: GameContent, rates: Dictionary, caps: Dictionary, buffs: Dictionary, chrono: Dictionary, sect: Dictionary, beast: Dictionary, prepared: Dictionary) -> Array:
	# Cache one-second deltas/base caps only while ALL rate/cap multipliers agree.
	# Stock and reservations are read each tick, before arrivals/completions/departures.
	if not prepared.has("production") or prepared.production_buffs != buffs or prepared.production_chrono != chrono:
		var production := {}
		for id in state.resources:
			if not bool(state.resources[id].unlocked) or not rates.has(id):
				continue
			var rate: AmountCompat = rates[id]
			for specific in [buffs.specific_resource_multipliers, chrono.specific_resource_multipliers]:
				if specific.has(id):
					rate = rate.multiply(AmountCompat.from_number(1.0 + float(specific[id])))
			if (id == "herb" or id == "spirit_grass_low") and (float(sect.production_herb_wood) > 0.0 or float(beast.production_herb) > 0.0):
				rate = rate.multiply(AmountCompat.from_number(1.0 + float(sect.production_herb_wood) + float(beast.production_herb)))
			if (id == "stone_low" or id == "refined_iron") and float(beast.production_stone_iron) > 0.0:
				rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast.production_stone_iron)))
			if id == "money" and float(beast.money_rate) > 0.0:
				rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast.money_rate)))
			# Keep the reference multiply(1) normalization, rather than float arithmetic.
			var delta := rate.multiply(AmountCompat.from_number(1.0))
			var cap: AmountCompat = caps.get(id, AmountCompat.zero())
			var bonus := float(sect.storage_bonus) + float(chrono.storage_bonus) + float(beast.all_capacity_mult)
			if (id == "stone_low" or id == "refined_iron") and float(beast.cap_stone_iron) > 0.0:
				bonus += float(beast.cap_stone_iron)
			if bonus > 0.0 and cap.sign > 0:
				cap = cap.multiply(AmountCompat.from_number(1.0 + bonus))
			if id == "lingqi" and float(sect.lingqi_cap_bonus) > 0.0 and cap.sign > 0:
				cap = cap.multiply(AmountCompat.from_number(1.0 + float(sect.lingqi_cap_bonus)))
			var processing: bool = not state.economy.is_empty() and content.processing_catalog.resources.has(id)
			if processing:
				cap = AmountCompat.from_number(minf(cap.to_float(), float(content.processing_catalog.resources[id].cap)))
			production[id] = {"delta": delta, "cap": cap, "limited": caps.has(id), "processing": processing}
		prepared.production = production
		prepared.production_buffs = buffs.duplicate(true)
		prepared.production_chrono = chrono.duplicate(true)
		prepared.erase("production_home")
	# After an unchanged production pass and a stationary economy there are no
	# changing reservations. Amount identity also catches realm resource sinks.
	# Rebuilding multipliers above always invalidates this shortcut first.
	if prepared.economy.has("idle_home") and prepared.has("production_home") and IslandEconomy._same_home(state, prepared.production_home):
		return []
	var changed: Array = []
	for id in prepared.production:
		var item: Dictionary = prepared.production[id]
		var entry: Dictionary = state.resources[id]
		var cap: AmountCompat = item.cap
		var current: AmountCompat = entry.value
		if item.processing:
			var held := IslandEconomy.reserved(state, "home", id, content.processing_catalog)
			var effective := maxf(current.to_float(), maxf(0, cap.to_float() - held))
			if effective != cap.to_float():
				cap = AmountCompat.from_number(effective)
		var delta: AmountCompat = item.delta
		# Full/contraction caps with nonnegative production cannot change the Amount.
		if item.limited and delta.sign >= 0 and current.compare_to(cap) == 0:
			continue
		var next := current.add(delta)
		if item.limited and next.compare_to(cap) > 0:
			next = cap
		if next.compare_to(current) != 0:
			entry.value = next
			changed.append(String(id))
	if changed.is_empty():
		prepared.production_home = IslandEconomy._home_values(state)
	return changed

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
	BeastSystem.tick(state, elapsed)
	var events: Array = AbodeScenery.advance(state, elapsed)
	var stopped = null
	if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
		events.append({"kind": "lifespan_exhausted", "total_elapsed_seconds": state.total_elapsed_seconds, "max_lifespan_seconds": max_seconds})
		stopped = "lifespan_exhausted"
	return {"ticks_advanced": executed, "events": events, "changed_ids": [], "stopped": stopped}
