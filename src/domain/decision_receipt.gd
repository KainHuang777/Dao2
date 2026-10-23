class_name DecisionReceipt
extends RefCounted
## Observed committed fortune transactions, within the existing LifeLedger budget.
const VERSION := 1
const LIMIT := 8
const RECEIPT_BYTES := 8192
const BOOK_BYTES := 16 * 1024

static func pending_id(state: GameState) -> String:
	var pending: Dictionary = state.fortune.get("pending_encounter", {})
	if pending.is_empty(): return ""
	return str(pending.get("instance_id", ("legacy|%d|%d|%s" % [state.reincarnation_count + 1, int(state.fortune.get("encounter_history_count", 0)), str(pending.get("id", ""))]).sha256_text()))

static func record(state: GameState, receipt: Dictionary) -> void:
	LifeLedger.observe(state)
	var life: Dictionary = state.life_ledger.current
	if not life.has("decisions"):
		life.decisions = {"version": VERSION, "started_at": state.total_elapsed_seconds, "omitted": 0, "receipts": []}
	var book: Dictionary = life.decisions
	for old in book.receipts:
		if old.instance_id == receipt.instance_id: return
	if LifeLedger.bytes(receipt) > RECEIPT_BYTES:
		book.omitted = int(book.omitted) + 1
		return
	book.receipts.append(receipt.duplicate(true))
	trim(life, LifeLedger.CURRENT_BYTES)

static func trim(life: Dictionary, budget: int) -> void:
	if not life.has("decisions"): return
	var book: Dictionary = life.decisions
	while not book.receipts.is_empty() and (book.receipts.size() > LIMIT or LifeLedger.bytes(book) > BOOK_BYTES or LifeLedger.bytes(life) > budget):
		book.receipts.pop_front()
		book.omitted = int(book.omitted) + 1

static func validate(book: Variant, life: Dictionary) -> String:
	if not book is Dictionary or not LifeLedger._keys(book, ["version", "started_at", "omitted", "receipts"]): return "DECISION_STRUCTURE"
	if not LifeLedger._integer(book.version, 1) or int(book.version) != VERSION: return "DECISION_VERSION"
	if not LifeLedger._number(book.started_at) or float(book.started_at) < float(life.started_at) or float(book.started_at) > float(life.until) or not LifeLedger._integer(book.omitted): return "DECISION_COVERAGE"
	if not book.receipts is Array or book.receipts.size() > LIMIT or LifeLedger.bytes(book) > BOOK_BYTES: return "DECISION_LIMIT"
	var ids := {}
	var previous := float(book.started_at)
	for r in book.receipts:
		if not r is Dictionary or not LifeLedger._keys(r, ["version", "instance_id", "source", "life_id", "at", "encounter_id", "title", "option_index", "option", "log", "resources", "training", "pills", "buff"]): return "DECISION_RECEIPT_STRUCTURE"
		if LifeLedger.bytes(r) > RECEIPT_BYTES or not LifeLedger._integer(r.version, 1) or int(r.version) != VERSION: return "DECISION_RECEIPT_VERSION"
		if not LifeLedger._hash(r.instance_id) or not LifeLedger._hash(r.source) or ids.has(r.instance_id): return "DECISION_RECEIPT_ID"
		if not LifeLedger._integer(r.life_id, 1) or int(r.life_id) != int(life.life_id) or not LifeLedger._integer(r.option_index): return "DECISION_RECEIPT_LIFE"
		if not LifeLedger._number(r.at) or float(r.at) < previous or float(r.at) > float(life.until): return "DECISION_RECEIPT_TIME"
		for key in ["encounter_id", "title", "option", "log"]:
			if not r[key] is String or r[key].to_utf8_buffer().size() > 2048: return "DECISION_RECEIPT_TEXT"
		if not r.resources is Dictionary or r.resources.size() > 16: return "DECISION_RESOURCES"
		for id in r.resources:
			if not id is String or id.length() > 96: return "DECISION_RESOURCE_ID"
			var row: Variant = r.resources[id]
			if not row is Dictionary or not LifeLedger._keys(row, ["before", "paid", "nominal", "gained", "overflow", "after"]): return "DECISION_RESOURCE_ROW"
			for key in row:
				if not row[key] is String or row[key].length() > 128: return "DECISION_AMOUNT"
				var parsed := AmountCompat.try_parse(row[key])
				if not parsed.ok or parsed.value.compare_to(AmountCompat.zero()) < 0: return "DECISION_AMOUNT"
			if not _amount_equal(_amount(row.before).subtract(_amount(row.paid)).add(_amount(row.gained)), _amount(row.after)) or not _amount_equal(_amount(row.gained).add(_amount(row.overflow)), _amount(row.nominal)): return "DECISION_RECONCILIATION"
		if not _numeric_delta(r.training): return "DECISION_TRAINING"
		if not r.pills is Dictionary or r.pills.size() > 16: return "DECISION_PILLS"
		for id in r.pills:
			if not id is String or id.length() > 96 or not _numeric_delta(r.pills[id], true): return "DECISION_PILLS"
		if not r.buff is Dictionary: return "DECISION_BUFF"
		if not r.buff.is_empty():
			if not LifeLedger._keys(r.buff, ["id", "before", "after", "permanent"]) or not r.buff.id is String or r.buff.id.length() > 96 or not r.buff.permanent is bool or not LifeLedger._number(r.buff.before) or not LifeLedger._number(r.buff.after): return "DECISION_BUFF"
		ids[r.instance_id] = true
		previous = float(r.at)
	return ""

static func _amount(raw: String) -> AmountCompat:
	return AmountCompat.try_parse(raw).value

static func _amount_equal(a: AmountCompat, b: AmountCompat) -> bool:
	return a.compare_to(b) == 0

static func _numeric_delta(row: Variant, integer: bool = false) -> bool:
	if not row is Dictionary or not LifeLedger._keys(row, ["before", "gained", "after"]): return false
	for key in row:
		if not LifeLedger._number(row[key]) or (integer and not LifeLedger._integer(row[key])): return false
	return is_equal_approx(float(row.before) + float(row.gained), float(row.after))

static func validate_pending(fortune: Dictionary) -> String:
	var pending: Variant = fortune.get("pending_encounter", {})
	if not pending is Dictionary: return "DECISION_PENDING_TYPE"
	if pending.has("instance_id") and not LifeLedger._hash(pending.instance_id): return "DECISION_PENDING_ID"
	return StorySaveContract.validate_pending(pending)
