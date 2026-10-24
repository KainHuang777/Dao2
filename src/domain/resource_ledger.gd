class_name ResourceLedger
extends RefCounted
## Observes committed stock writes. Never computes rewards or modifies Amounts.
const VERSION := 1
const LIMIT := 48
const BUDGET := 12 * 1024
const CATEGORIES := ["production", "gather", "building", "cultivation", "alchemy", "fortune", "decision", "sect", "beast", "achievement", "scenery", "skill", "processing", "transfer", "realm", "adjustment"]

static func initialize(state: GameState, complete: bool = false) -> void:
	LifeLedger.initialize(state)
	var life: Dictionary = state.life_ledger.current
	if life.has("accounts"): return
	life.accounts = {"version": VERSION, "started_at": state.total_elapsed_seconds, "coverage": "complete" if complete else "partial", "omitted": 0, "estimated_bytes": 256, "rows": {}}
	# Opening balances are snapshots, never income. Other scopes are captured lazily.
	for id in state.resources:
		_row(state, "home", id, state.resources[id].value)
	for scope in state.economy.get("islands", {}):
		if scope == "home": continue
		for id in state.economy.islands[scope].inventory:
			_row(state, scope, id, amount(state.economy.islands[scope].inventory[id]))
	for trip_id in state.economy.get("trips", {}):
		var trip: Dictionary = state.economy.trips[trip_id]
		var id: String = IslandEconomy.route_defs(state)[trip_id][2]
		var row := _row(state, "transit", id, AmountCompat.zero())
		if not row.is_empty():
			row.opening = encode(amount(row.opening).add(amount(trip.cargo)))
			row.closing = row.opening
	for id in ["spirit_crystal", "azure_nectar"]:
		_row(state, "realm_spirit", id, AmountCompat.from_number(float(state.realms_data.get("realm_spirit", {}).get(id, 0))))

static func _row(state: GameState, scope: String, id: String, before: AmountCompat) -> Dictionary:
	var book: Dictionary = state.life_ledger.current.accounts
	var key := scope + ":" + id
	if not book.rows.has(key):
		if book.rows.size() >= LIMIT:
			book.omitted = int(book.omitted) + 1
			book.coverage = "partial"
			return {}
		book.rows[key] = {"opening": encode(before), "closing": encode(before), "income": {}, "expense": {}, "adjustment": "0", "overflow": "0"}
		book.estimated_bytes = int(book.estimated_bytes) + LifeLedger.bytes(book.rows[key]) + key.length() + 4
	return book.rows[key]

static func change(state: GameState, scope: String, id: String, before: AmountCompat, after: AmountCompat, category: String, nominal: AmountCompat = null) -> AmountCompat:
	# Lazy initialization is performed only on an accepted write, not a failed command.
	initialize(state)
	var row := _row(state, scope, id, before)
	if row.is_empty(): return after
	var row_bytes := LifeLedger.bytes(row)
	if category not in CATEGORIES: category = "adjustment"
	var delta := after.subtract(before)
	# External/debug writes create an explicit adjustment instead of invented income.
	var gap := before.subtract(amount(row.closing))
	if before.compare_to(amount(row.closing)) != 0: row.adjustment = encode(amount(row.adjustment).add(gap))
	var movement := nominal if category == "transfer" and nominal != null else delta
	if category == "transfer" and movement.compare_to(delta) != 0:
		row.adjustment = encode(amount(row.adjustment).add(delta.subtract(movement)))
	if category == "adjustment":
		row.adjustment = encode(amount(row.adjustment).add(delta))
	elif category == "production" and delta.sign < 0:
		row.adjustment = encode(amount(row.adjustment).add(delta))
	elif movement.sign != 0:
		var side: Dictionary = row.income if movement.sign > 0 else row.expense
		var magnitude := movement if movement.sign > 0 else AmountCompat.zero().subtract(movement)
		side[category] = encode(amount(side.get(category, "0")).add(magnitude))
	if category != "transfer" and nominal != null and nominal.sign > 0:
		var gained := delta if delta.sign > 0 else AmountCompat.zero()
		var lost := nominal.subtract(gained)
		if nominal.compare_to(gained) > 0: row.overflow = encode(amount(row.overflow).add(lost))
	row.closing = encode(after)
	# Cargo belongs to its own inventory while travelling. The matching side
	# makes consolidated transfers internal even before arrival.
	var book: Dictionary = state.life_ledger.current.accounts
	book.estimated_bytes = int(book.estimated_bytes) + LifeLedger.bytes(row) - row_bytes
	if category == "transfer" and scope != "transit":
		var transit := _row(state, "transit", id, AmountCompat.zero())
		if not transit.is_empty():
			var cargo := AmountCompat.zero()
			for trip_id in state.economy.get("trips", {}):
				if IslandEconomy.route_defs(state)[trip_id][2] == id:
					cargo = cargo.add(amount(state.economy.trips[trip_id].cargo))
			change(state, "transit", id, cargo, cargo.subtract(movement), "transfer")
	if int(book.estimated_bytes) > BUDGET:
		trim(state.life_ledger.current, LifeLedger.CURRENT_BYTES)
	return after

static func encode(value: AmountCompat) -> String:
	# Display serialization rounds near integers; repeated parse/add would lose
	# real fractional flow. Store layer-zero counters with full JSON precision.
	if value.layer == 0:
		var number := float(value.sign) * value.mag
		if number == floor(number): return str(int(number))
		return JSON.stringify(number, "", true, true)
	return value.serialize()

static func amount(value: String) -> AmountCompat:
	if value.is_valid_float():
		var number := value.to_float()
		if is_finite(number) and absf(number) <= AmountCompat.EXP_LIMIT: return AmountCompat.from_number(number)
	return AmountCompat.try_parse(value).value

static func trim(life: Dictionary, budget: int) -> void:
	if not life.has("accounts"): return
	var book: Dictionary = life.accounts
	while not book.rows.is_empty() and (int(book.estimated_bytes) > BUDGET or LifeLedger.bytes(life) > budget):
		var key: String = book.rows.keys().back()
		book.estimated_bytes = int(book.estimated_bytes) - LifeLedger.bytes(book.rows[key]) - key.length() - 4
		book.rows.erase(key)
		book.omitted = int(book.omitted) + 1
		book.coverage = "partial"

static func validate(book: Variant) -> String:
	if not book is Dictionary or not LifeLedger._keys(book, ["version", "started_at", "coverage", "omitted", "estimated_bytes", "rows"]): return "ACCOUNTS_STRUCTURE"
	if not LifeLedger._integer(book.version, 1) or int(book.version) != VERSION: return "ACCOUNTS_VERSION"
	if not LifeLedger._integer(book.estimated_bytes) or int(book.estimated_bytes) > BUDGET: return "ACCOUNTS_LIMIT"
	if not LifeLedger._number(book.started_at) or not LifeLedger._integer(book.omitted) or book.coverage not in ["complete", "partial"]: return "ACCOUNTS_COVERAGE"
	if book.coverage == "complete" and (float(book.started_at) != 0 or int(book.omitted) != 0): return "ACCOUNTS_COVERAGE"
	if not book.rows is Dictionary or book.rows.size() > LIMIT or LifeLedger.bytes(book) > BUDGET or int(book.estimated_bytes) < LifeLedger.bytes(book): return "ACCOUNTS_LIMIT"
	for key in book.rows:
		if not key is String or key.length() > 128 or key.split(":").size() != 2: return "ACCOUNTS_KEY"
		if key.get_slice(":", 0) not in ["home", "wood", "ore", "herb", "deep", "ancient", "void", "realm_spirit", "transit"] or key.get_slice(":", 1).is_empty(): return "ACCOUNTS_KEY"
		for character in key:
			if character not in "abcdefghijklmnopqrstuvwxyz0123456789_:": return "ACCOUNTS_KEY"
		var row: Variant = book.rows[key]
		if not row is Dictionary or not LifeLedger._keys(row, ["opening", "closing", "income", "expense", "adjustment", "overflow"]): return "ACCOUNTS_ROW"
		for field in ["opening", "closing", "adjustment", "overflow"]:
			if not _valid_amount(row[field], field == "adjustment"): return "ACCOUNTS_AMOUNT"
		for field in ["income", "expense"]:
			if not row[field] is Dictionary or row[field].size() > CATEGORIES.size(): return "ACCOUNTS_CATEGORY"
			for category in row[field]:
				if category not in CATEGORIES or not _valid_amount(row[field][category], false): return "ACCOUNTS_CATEGORY"
	return ""

static func _valid_amount(value: Variant, signed: bool) -> bool:
	if not value is String or value.length() > 96: return false
	var parsed := AmountCompat.try_parse(value)
	return bool(parsed.ok) and (signed or parsed.value.sign >= 0)

static func equivalent(a: Dictionary, b: Dictionary) -> bool:
	# Grouped and one-second additions may differ below Amount comparison precision.
	if a.is_empty() or b.is_empty(): return a == b
	for field in ["version", "started_at", "coverage", "omitted"]:
		if a[field] != b[field]: return false
	if a.rows.size() != b.rows.size(): return false
	for key in a.rows:
		if not b.rows.has(key): return false
		for field in ["opening", "closing", "adjustment", "overflow"]:
			if amount(a.rows[key][field]).compare_to(amount(b.rows[key][field])) != 0: return false
		for field in ["income", "expense"]:
			if a.rows[key][field].size() != b.rows[key][field].size(): return false
			for category in a.rows[key][field]:
				if not b.rows[key][field].has(category) or amount(a.rows[key][field][category]).compare_to(amount(b.rows[key][field][category])) != 0: return false
	return true
