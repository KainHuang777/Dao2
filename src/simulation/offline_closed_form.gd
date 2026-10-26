class_name OfflineClosedForm
extends RefCounted

const LAYER_LIMIT := 9.0e15
const INT_LIMIT := 9007199254740992.0

static func advance(state: GameState, content: GameContent, ticks: int, prepared: Dictionary = {}) -> Dictionary:
	# The original jump proof assumes integer gathering and local workshops.
	# R46 fractional gathering uses the authoritative one-second path until a
	# separate proof covers its event/capacity boundaries.
	if IslandEconomy.expanded(state):
		var result := TimeAdvancer.advance(state, content, ticks, prepared)
		result.exact = true
		return result
	if not state.economy.is_empty() and content.processing_catalog.is_empty():
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": "processing_content_missing", "exact": true}
	if ticks <= 0:
		return {"ticks_advanced": 0, "events": [], "changed_ids": [], "stopped": null, "exact": true}
	if prepared.is_empty():
		prepared = TimeAdvancer.prepare_advance(state, content)
	LifeLedger.initialize(state)
	var start_elapsed: float = state.total_elapsed_seconds
	if not _is_int_float(start_elapsed):
		return _unsupported("fractional_elapsed")
	for resource_id in state.resources:
		var entry: Dictionary = state.resources[resource_id]
		var slot: Variant = entry.get("value", null)
		if not slot is AmountCompat:
			return _unsupported("non_layer0")
		if (slot as AmountCompat).layer != 0:
			return _unsupported("non_layer0")
	for buff_id in state.buffs:
		var buff: Dictionary = state.buffs[buff_id]
		if bool(buff.get("is_permanent", false)):
			continue
		if not _is_int_float(float(buff.get("remaining_seconds", 0.0))):
			return _unsupported("fractional_buff")
	var decision_cds: Dictionary = _sub_dict(state.realm_decisions, "cooldowns")
	for k in decision_cds:
		if not _is_int_float(float(decision_cds[k])):
			return _unsupported("fractional_decision")
	var beast_cd: float = 0.0
	if state.beasts is Dictionary:
		beast_cd = float((state.beasts as Dictionary).get("cooldown_remaining", 0.0))
	if not _is_int_float(beast_cd):
		return _unsupported("fractional_beast")
	var sect_state: Dictionary = _coerce_dict(state.sect)
	if not sect_state.is_empty() and bool(sect_state.get("unlocked", false)):
		var active_e: Variant = sect_state.get("active_expedition", null)
		if active_e is Dictionary:
			var exp_d: Dictionary = active_e
			if not _is_int_float(float(exp_d.get("duration", 0))) or not _is_int_float(float(exp_d.get("elapsed", 0))):
				return _unsupported("fractional_sect")
		if not _is_int_float(float(sect_state.get("next_refresh_seconds", 0))):
			return _unsupported("fractional_sect")
	var scenery: Dictionary = _coerce_dict(state.abode_scenery)
	if not scenery.is_empty():
		var scenery_active: Variant = scenery.get("active", [])
		var active_size: int = (scenery_active as Array).size() if scenery_active is Array else 0
		if active_size < AbodeScenery.MAX_ACTIVE and not _is_int_float(float(scenery.get("remaining", 12.0))):
			return _unsupported("fractional_scenery")
	var fortune: Dictionary = _coerce_dict(state.fortune)
	var pending: Dictionary = _coerce_dict(fortune.get("pending_encounter", {}))
	if pending.is_empty():
		var cd: float
		if fortune.is_empty() or not fortune.has("cooldown_remaining"):
			cd = FortuneSystem.compute_cooldown_for_era(maxi(1, state.era_id))
		else:
			cd = float(fortune["cooldown_remaining"])
		if not _is_int_float(cd):
			return _unsupported("fractional_fortune")
		if int(ceil(cd)) <= ticks:
			var encounters: Array = FortuneSystem.get_encounters()
			var has_candidate := false
			for enc in encounters:
				if enc is Dictionary and state.era_id >= int((enc as Dictionary).get("min_era", 1)):
					has_candidate = true
					break
			if encounters.is_empty():
				return _unsupported("no_encounters")
			if not has_candidate:
				return _unsupported("no_candidates")
	if state.era_id >= 2 and RealmSystem.is_spirit_realm_unlocked(state):
		var spirit: Variant = state.realms_data.get("realm_spirit", {})
		var outposts: Variant = {}
		if spirit is Dictionary:
			outposts = (spirit as Dictionary).get("outposts", {})
		if outposts is Dictionary:
			var op: Dictionary = outposts
			if int(op.get("celestial_hub", 0)) > 0 or int(op.get("pure_pool", 0)) > 0:
				return _unsupported("realm_outposts")
	var talents: Dictionary = _coerce_dict(prepared.get("talents", {}))
	if talents.is_empty():
		talents = TalentSystem.compute_multipliers(state)
	var caps: Dictionary = _coerce_dict(prepared.get("caps", {}))
	if caps.is_empty():
		caps = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills)
	var lifespans: Variant = prepared.get("lifespans", [])
	if not lifespans is Array or (lifespans as Array).is_empty():
		lifespans = content.era_lifespan_entries()
	var sect_m: Dictionary = _coerce_dict(prepared.get("sect", {}))
	if sect_m.is_empty():
		sect_m = SectSystem.compute_multipliers(state)
	var beast_m: Dictionary = _coerce_dict(prepared.get("beast", {}))
	if beast_m.is_empty():
		beast_m = BeastSystem.compute_multipliers(state)
	var era_mult: float = _opt_float(prepared, "era_multiplier", NAN)
	if is_nan(era_mult):
		var era_def: Variant = content.era(state.era_id)
		era_mult = 1.0 if era_def == null else float((era_def as Dictionary).resource_multiplier)
	var feedback_boost: float = _opt_float(prepared, "feedback_boost", NAN)
	if is_nan(feedback_boost):
		feedback_boost = RealmSystem.get_feedback_cultivation_boost(state)
	var probe: Dictionary = OfflineEconomyJump.advance(state, content, 0, prepared)
	if bool(probe.get("unsupported", false)):
		return {"unsupported": true, "reason": "economy: " + String(probe.get("reason", "unknown"))}
	var ticks_left := ticks
	var executed := 0
	var events: Array = []
	var scenery_changed := false
	var stopped: Variant = null
	var max_cached: float = NAN
	var max_count := -1
	var cached_prod: Array = []
	var cached_buff_m: Dictionary = {}
	var cached_chrono_m: Dictionary = {}
	var cached_valid := false
	while ticks_left > 0 and stopped == null:
		var buff_m: Dictionary = BuffSystem.compute_multipliers(state)
		var chrono_m: Dictionary = ChronoSystem.compute_multipliers(state)
		var pill_prod: float = 1.0 + float(state.pill_effects.get("production_multiplier", 0.0)) + float(buff_m["global_production_multiplier"])
		var global_prod_total: float = era_mult * float(talents["global_production_multiplier"]) * (pill_prod + float(chrono_m["global_production_multiplier"]) + float(beast_m["global_production_multiplier"]))
		var rates: Dictionary = Production.compute_rates(content, state.buildings, global_prod_total, state.skills, state.talents)
		var count_now := state.buffs.size()
		var max_seconds: float
		if not is_nan(max_cached) and count_now == max_count:
			max_seconds = max_cached
		elif max_count < 0 and (prepared.get("max_seconds", null) is float or prepared.get("max_seconds", null) is int):
			max_seconds = float(prepared["max_seconds"])
			max_cached = max_seconds
			max_count = count_now
		else:
			max_seconds = float(Lifespan.max_lifespan_seconds(lifespans as Array, state.era_id, float(talents["lifespan_bonus"]), float(state.pill_effects.get("lifespan_bonus_years", 0.0)) + float(buff_m["lifespan_bonus_years"])))
			max_cached = max_seconds
			max_count = count_now
		if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
			stopped = "lifespan_exhausted"
			break
		var T := float(state.total_elapsed_seconds)
		var run_cap := mini(ticks_left, maxi(1, int(ceil((max_seconds - T) / 1.0))))
		var n := ticks_left
		var r := int(T) % 60
		var chrono_next := 60 - r if r != 0 else 60
		n = mini(n, chrono_next)
		for buff_id in state.buffs:
			var buff: Dictionary = state.buffs[buff_id]
			if bool(buff.get("is_permanent", false)):
				continue
			var k := int(ceil(float(buff.get("remaining_seconds", 0.0))))
			if k < 1:
				k = 1
			n = mini(n, k)
		var hb: int = OfflineEconomyJump.next_home_boundary(state, content, prepared, ticks_left)
		if hb >= 1:
			n = mini(n, hb)
		# Split at fact boundaries too: preserve exact ordering and ages across modes.
		if not state.economy.is_empty():
			n = mini(n, OfflineEconomyJump._next_event_offset(state, content.processing_catalog, n))
		var expedition: Variant = state.sect.get("active_expedition")
		if expedition is Dictionary:
			var remaining := int(expedition.get("duration", 0)) - int(expedition.get("elapsed", 0))
			if remaining > 0:
				n = mini(n, remaining)
		n = mini(n, run_cap)
		if n <= 0:
			n = 1
		var economy_empty: bool = state.economy.is_empty()
		var catalog: Dictionary = content.processing_catalog
		if not cached_valid or cached_buff_m != buff_m or cached_chrono_m != chrono_m:
			cached_buff_m = buff_m
			cached_chrono_m = chrono_m
			var built: Dictionary = _build_prod(state, content, rates, caps, buff_m, chrono_m, sect_m, beast_m, economy_empty, catalog)
			if not String(built["unsupported"]).is_empty():
				var u: Dictionary = _unsupported(String(built["unsupported"]))
				u["executed"] = executed
				return u
			cached_prod = built["items"]
			cached_valid = true
		for item in cached_prod:
			var fill_result: int = _fill(item as Dictionary, n, state, catalog)
			if fill_result == 2:
				var u2: Dictionary = _unsupported("non_layer0")
				u2["executed"] = executed
				return u2
		var training_speed: float = 1.0 + float(talents["cultivation_speed_bonus"]) + float(buff_m["cultivation_speed_bonus"]) + float(sect_m["cultivation_speed_bonus"]) + float(chrono_m["cultivation_speed_bonus"]) + float(beast_m["cultivation_speed_bonus"]) + feedback_boost
		state.training_seconds = _seq_add(state.training_seconds, training_speed, n)
		BuffSystem.tick(state, float(n))
		RealmDecisionSystem.advance_time(state, float(n))
		SectSystem.tick(state, float(n), state.total_elapsed_seconds)
		BeastSystem.tick(state, float(n))
		var eco: Dictionary = OfflineEconomyJump.advance(state, content, n, prepared)
		if bool(eco.get("unsupported", false)):
			var u3: Dictionary = {"unsupported": true, "reason": "economy: " + String(eco.get("reason", "unknown"))}
			u3["executed"] = executed
			return u3
		events.append_array(eco.get("events", []) as Array)
		state.total_elapsed_seconds += float(n)
		ChronoSystem.ensure_initialized(state)
		if state.era_id >= 2 and RealmSystem.is_spirit_realm_unlocked(state):
			RealmSystem.tick(state, float(n))
		var sc_events: Array = AbodeScenery.advance(state, float(n))
		if not sc_events.is_empty():
			events.append_array(sc_events)
			scenery_changed = true
		FortuneSystem.advance_time(state, float(n))
		if Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds):
			events.append({"kind": "lifespan_exhausted", "total_elapsed_seconds": float(state.total_elapsed_seconds), "max_lifespan_seconds": max_seconds})
			LifeLedger.exhausted(state)
			stopped = "lifespan_exhausted"
		LifeLedger.observe(state)
		LifeHistory.observe(state, content)
		executed += n
		ticks_left -= n
	var changed_final: Array = []
	if scenery_changed:
		changed_final.append("abode_scenery")
	if executed > 0:
		changed_final.append("economy")
	return {"ticks_advanced": executed, "events": events, "changed_ids": changed_final, "stopped": stopped, "exact": true}

static func _unsupported(reason: String) -> Dictionary:
	return {"unsupported": true, "reason": reason}

static func _coerce_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}

static func _sub_dict(container: Variant, key: String) -> Dictionary:
	if not container is Dictionary:
		return {}
	var inner: Variant = (container as Dictionary).get(key, null)
	if inner is Dictionary:
		return inner
	return {}

static func _opt_float(source: Dictionary, key: String, fallback: float) -> float:
	if not source.has(key):
		return fallback
	var v: Variant = source[key]
	if v is float:
		return float(v)
	if v is int:
		return float(v)
	return fallback

static func _is_int_float(v: float) -> bool:
	return is_finite(v) and v == floor(v)

static func _cmp_signed(a: float, b: float) -> int:
	var sa := 0
	if a > 0.0:
		sa = 1
	elif a < 0.0:
		sa = -1
	var sb := 0
	if b > 0.0:
		sb = 1
	elif b < 0.0:
		sb = -1
	if sa != sb:
		return -1 if sa < sb else 1
	if sa == 0:
		return 0
	if not is_equal_approx(absf(a), absf(b)):
		return (-1 if absf(a) < absf(b) else 1) * sa
	return 0

static func _seq_add(total: float, speed: float, n_ticks: int) -> float:
	if _is_int_float(total) and _is_int_float(speed):
		var scaled: float = speed * float(n_ticks)
		if is_finite(scaled) and absf(total) <= INT_LIMIT and absf(scaled) <= INT_LIMIT and absf(total + scaled) <= INT_LIMIT:
			return total + scaled
	var t := total
	for i in range(n_ticks):
		t = t + 1.0 * speed
	return t

static func _fill(item: Dictionary, n_ticks: int, state: GameState, catalog: Dictionary) -> int:
	var before: AmountCompat = item.entry.value
	var result := _fill_unobserved(item, n_ticks, state, catalog)
	if result != 2:
		var nominal := AmountCompat.from_number(float(item.delta_sign) * float(item.delta_mag) * n_ticks)
		ResourceLedger.change(state, "home", item.id, before, item.entry.value, "production", nominal)
	return result

static func _fill_unobserved(item: Dictionary, n_ticks: int, state: GameState, catalog: Dictionary) -> int:
	var limited: bool = bool(item["limited"])
	var d: float = float(int(item["delta_sign"])) * float(item["delta_mag"])
	var cap_base: float = float(item["cap"])
	var processing: bool = bool(item["processing"])
	var entry: Dictionary = item["entry"]
	var cur: float = (entry["value"] as AmountCompat).to_float()
	var held: float = IslandEconomy.reserved(state, "home", String(item["id"]), catalog) if processing else 0.0
	var cap_eff: float = maxf(cur, maxf(0.0, cap_base - held)) if processing else cap_base
	if absf(cur) + float(n_ticks) * absf(d) > LAYER_LIMIT:
		return 2
	if limited and d >= 0.0 and _cmp_signed(cur, cap_eff) == 0:
		return 0
	var changed := false
	if _is_int_float(cur) and _is_int_float(d) and (not limited or _is_int_float(cap_eff)):
		var steps: float = d * float(n_ticks)
		if is_finite(steps) and absf(steps) <= INT_LIMIT and is_finite(cur + steps) and absf(cur + steps) <= INT_LIMIT:
			var jump: float = cur + steps
			if limited and _cmp_signed(jump, cap_eff) > 0:
				jump = cap_eff
			if _cmp_signed(jump, cur) != 0:
				entry["value"] = AmountCompat.from_number(jump)
				return 1
			return 0
	for i in range(n_ticks):
		if limited and d >= 0.0 and _cmp_signed(cur, cap_eff) == 0:
			continue
		var next: float = cur + d
		if is_nan(next) or is_inf(next):
			next = 0.0
		if limited and _cmp_signed(next, cap_eff) > 0:
			next = cap_eff
		if _cmp_signed(next, cur) != 0:
			cur = next
			changed = true
	if changed:
		entry["value"] = AmountCompat.from_number(cur)
	return 1 if changed else 0

static func _build_prod(state: GameState, content: GameContent, rates: Dictionary, caps: Dictionary, buff_m: Dictionary, chrono_m: Dictionary, sect_m: Dictionary, beast_m: Dictionary, economy_empty: bool, catalog: Dictionary) -> Dictionary:
	var spec_b: Dictionary = buff_m.get("specific_resource_multipliers", {})
	var spec_c: Dictionary = chrono_m.get("specific_resource_multipliers", {})
	var prod: Array = []
	for id in state.resources:
		var entry: Dictionary = state.resources[id]
		if not bool(entry.get("unlocked", false)) or not rates.has(id):
			continue
		var rate: AmountCompat = rates[id]
		if spec_b.has(id):
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(spec_b[id])))
		if spec_c.has(id):
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(spec_c[id])))
		if (id == "herb" or id == "spirit_grass_low") and (float(sect_m["production_herb_wood"]) > 0.0 or float(beast_m["production_herb"]) > 0.0):
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(sect_m["production_herb_wood"]) + float(beast_m["production_herb"])))
		if (id == "stone_low" or id == "refined_iron") and float(beast_m["production_stone_iron"]) > 0.0:
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast_m["production_stone_iron"])))
		if id == "money" and float(beast_m["money_rate"]) > 0.0:
			rate = rate.multiply(AmountCompat.from_number(1.0 + float(beast_m["money_rate"])))
		var delta_amount: AmountCompat = rate.multiply(AmountCompat.from_number(1.0))
		var cap_amount: AmountCompat = caps.get(id, AmountCompat.zero())
		var bonus: float = float(sect_m["storage_bonus"]) + float(chrono_m["storage_bonus"]) + float(beast_m["all_capacity_mult"])
		if (id == "stone_low" or id == "refined_iron") and float(beast_m["cap_stone_iron"]) > 0.0:
			bonus += float(beast_m["cap_stone_iron"])
		if bonus > 0.0 and cap_amount.sign > 0:
			cap_amount = cap_amount.multiply(AmountCompat.from_number(1.0 + bonus))
		if id == "lingqi" and float(sect_m["lingqi_cap_bonus"]) > 0.0 and cap_amount.sign > 0:
			cap_amount = cap_amount.multiply(AmountCompat.from_number(1.0 + float(sect_m["lingqi_cap_bonus"])))
		cap_amount = Production.add_pill_capacity(state, id, cap_amount)
		var processing: bool = not economy_empty and catalog.resources.has(id)
		if processing and not IslandEconomy.expanded(state):
			cap_amount = AmountCompat.from_number(minf(cap_amount.to_float(), float(catalog.resources[id].cap)))
		if delta_amount.layer != 0 or cap_amount.layer != 0:
			return {"items": [], "unsupported": "non_layer0"}
		prod.append({"id": id, "entry": entry, "delta_sign": delta_amount.sign, "delta_mag": delta_amount.mag, "cap": cap_amount.to_float(), "limited": bool(caps.has(id)), "processing": processing})
	return {"items": prod, "unsupported": ""}
