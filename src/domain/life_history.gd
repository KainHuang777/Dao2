class_name LifeHistory
extends RefCounted
## Sparse observations, never reconstructed yearly balances or economic inputs.
const VERSION := 1
const LIMIT := 16
const SERIES_LIMIT := 12
const BUDGET := 6 * 1024

static func observe(state: GameState, content: GameContent, force: bool = false) -> void:
	var at := state.total_elapsed_seconds
	if not force and int(floor(at)) % 60 != 0: return
	LifeLedger.observe(state)
	var life: Dictionary = state.life_ledger.current
	if not life.has("history"):
		life.history = {"version": VERSION, "started_at": at, "omitted": 0, "samples": []}
	var history: Dictionary = life.history
	var rows := {}
	var caps := observed_caps(state, content)
	var resource_ids := state.resources.keys()
	resource_ids.sort()
	for id in resource_ids:
		if not bool(state.resources[id].unlocked): continue
		rows["home:" + id] = [ResourceLedger.encode(state.resources[id].value), ResourceLedger.encode(caps[id]) if caps.has(id) else null]
	var scopes: Array = state.economy.get("islands", {}).keys()
	scopes.sort()
	for scope in scopes:
		if scope == "home": continue
		var ids: Array = state.economy.islands[scope].inventory.keys()
		ids.sort()
		for id in ids:
			rows[scope + ":" + id] = [state.economy.islands[scope].inventory[id], ResourceLedger.encode(AmountCompat.from_number(IslandProgression.capacity(state, scope)))]
	# Prioritise the same deterministic first twelve stock scopes at each observation.
	while rows.size() > SERIES_LIMIT:
		rows.erase(rows.keys().back())
		history.omitted = int(history.omitted) + 1
	var sample := {"at": at, "rows": rows}
	if not history.samples.is_empty() and float(history.samples.back().at) == at:
		history.samples[-1] = sample
	else:
		history.samples.append(sample)
	trim(life, LifeLedger.CURRENT_BYTES)

static func observed_caps(state: GameState, content: GameContent) -> Dictionary:
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills)
	# These existing multiplier APIs initialise dictionaries. Give them an isolated
	# projection so observing a command cannot initialise gameplay or draw RNG.
	var projection := GameState.new()
	projection.era_id = state.era_id
	projection.total_elapsed_seconds = state.total_elapsed_seconds
	projection.chrono = state.chrono.duplicate(true)
	projection.beasts = state.beasts.duplicate(true)
	projection.beast_talents = state.beast_talents.duplicate(true)
	var sect := SectSystem.compute_multipliers(state)
	var chrono := ChronoSystem.compute_multipliers(projection)
	var beast := BeastSystem.compute_multipliers(projection)
	for id in caps:
		var cap: AmountCompat = caps[id]
		var bonus := float(sect.storage_bonus) + float(chrono.storage_bonus) + float(beast.all_capacity_mult)
		if id in ["stone_low", "refined_iron"] and float(beast.cap_stone_iron) > 0: bonus += float(beast.cap_stone_iron)
		if bonus > 0 and cap.sign > 0: cap = cap.multiply(AmountCompat.from_number(1 + bonus))
		if id == "lingqi" and float(sect.lingqi_cap_bonus) > 0 and cap.sign > 0: cap = cap.multiply(AmountCompat.from_number(1 + float(sect.lingqi_cap_bonus)))
		if not state.economy.is_empty() and content.processing_catalog.get("resources", {}).has(id):
			var processing_cap := AmountCompat.from_number(float(content.processing_catalog.resources[id].cap))
			if cap.compare_to(processing_cap) > 0: cap = processing_cap
		caps[id] = cap
	return caps

static func trim(life: Dictionary, budget: int) -> void:
	if not life.has("history"): return
	var h: Dictionary = life.history
	# Keep first and newest observations. Thin interior points, never cut the age axis.
	while h.samples.size() > 2 and (h.samples.size() > LIMIT or LifeLedger.bytes(h) > BUDGET or LifeLedger.bytes(life) > budget):
		var kept := [h.samples[0]]
		for index in range(1, h.samples.size() - 1):
			if index % 2 == 0: kept.append(h.samples[index])
			else: h.omitted = int(h.omitted) + 1
		kept.append(h.samples.back())
		h.samples = kept
	while not h.samples.is_empty() and (LifeLedger.bytes(h) > BUDGET or LifeLedger.bytes(life) > budget):
		# Extreme single rows cannot consume an unbounded part of the sealed book.
		var sample: Dictionary = h.samples[0]
		if not sample.rows.is_empty(): sample.rows.erase(sample.rows.keys().back())
		else: h.samples.pop_front()
		h.omitted = int(h.omitted) + 1

static func validate(h: Variant, life: Dictionary) -> String:
	if not h is Dictionary or not LifeLedger._keys(h, ["version", "started_at", "omitted", "samples"]): return "HISTORY_STRUCTURE"
	if not LifeLedger._integer(h.version, 1) or int(h.version) != VERSION: return "HISTORY_VERSION"
	if not LifeLedger._number(h.started_at) or not LifeLedger._integer(h.omitted): return "HISTORY_COVERAGE"
	if not LifeLedger._number(life.get("started_at")) or not LifeLedger._number(life.get("until")) or float(h.started_at) < float(life.started_at) or float(h.started_at) > float(life.until): return "HISTORY_TIME"
	if not h.samples is Array or h.samples.size() > LIMIT or LifeLedger.bytes(h) > BUDGET: return "HISTORY_LIMIT"
	var previous := -1.0
	for s in h.samples:
		if not s is Dictionary or not LifeLedger._keys(s, ["at", "rows"]) or not LifeLedger._number(s.at): return "HISTORY_SAMPLE"
		if float(s.at) <= previous or float(s.at) < float(h.started_at) or float(s.at) > float(life.until): return "HISTORY_TIME"
		previous = float(s.at)
		if not s.rows is Dictionary or s.rows.size() > SERIES_LIMIT: return "HISTORY_ROWS"
		for key in s.rows:
			if not key is String or key.length() > 128 or key.split(":").size() != 2 or key.get_slice(":", 0) not in ["home", "wood", "ore", "herb"] or key.get_slice(":", 1).is_empty(): return "HISTORY_KEY"
			for ch in key:
				if ch not in "abcdefghijklmnopqrstuvwxyz0123456789_:": return "HISTORY_KEY"
			var row: Variant = s.rows[key]
			if not row is Array or row.size() != 2 or not ResourceLedger._valid_amount(row[0], false) or (row[1] != null and not ResourceLedger._valid_amount(row[1], false)): return "HISTORY_AMOUNT"
	return ""

static func interval(life: Dictionary, start: float, finish: float) -> Dictionary:
	var result := {"samples": [], "events": [], "decisions": []}
	for s in life.get("history", {}).get("samples", []):
		if float(s.at) >= start and float(s.at) <= finish: result.samples.append(s.duplicate(true))
	for e in life.get("events", []):
		if float(e.at) >= start and float(e.at) <= finish: result.events.append(e.duplicate(true))
	for r in life.get("decisions", {}).get("receipts", []):
		if float(r.at) >= start and float(r.at) <= finish: result.decisions.append(r.duplicate(true))
	return result

static func equivalent(x: Dictionary, y: Dictionary) -> bool:
	# Observation strings retain full precision; compare values under Amount's contract.
	if x.is_empty() or y.is_empty(): return x == y
	for field in ["version", "started_at", "omitted"]:
		if x[field] != y[field]: return false
	if x.samples.size() != y.samples.size(): return false
	for i in x.samples.size():
		var p: Dictionary = x.samples[i]
		var q: Dictionary = y.samples[i]
		if p.at != q.at or p.rows.size() != q.rows.size(): return false
		for key in p.rows:
			if not q.rows.has(key): return false
			for field in 2:
				if p.rows[key][field] == null or q.rows[key][field] == null:
					if p.rows[key][field] != q.rows[key][field]: return false
				elif ResourceLedger.amount(p.rows[key][field]).compare_to(ResourceLedger.amount(q.rows[key][field])) != 0: return false
	return true
