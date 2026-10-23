class_name LifeLedger
extends RefCounted

# Facts only. No reward calculations, wall clock, rendering or random draws.
const VERSION := 1
const RETAINED_LIVES := 9
const EVENT_LIMIT := 64
const ANCHOR_LIMIT := 48
const EVENT_BYTES := 384
const SEALED_BYTES := 32 * 1024
const CURRENT_BYTES := 64 * 1024
const TOTAL_BYTES := 352 * 1024
const TEXT_BYTES := 4096
const FIRST_ONLY := ["building_built", "island_opened", "cargo_arrived", "pill_refined", "skill_learned", "joined_sect", "expedition_completed", "expedition_claimed", "beast_acquired", "beast_matured", "lifespan_exhausted"]
const KINDS := ["building_built", "island_opened", "cargo_arrived", "cultivation_leveled_up", "era_breakthrough", "tribulation_failed", "tribulation_passed", "pill_refined", "skill_learned", "joined_sect", "expedition_completed", "expedition_claimed", "beast_acquired", "beast_matured", "lifespan_exhausted"]

static func initialize(state: GameState, complete: bool = false) -> void:
	if not state.life_ledger.is_empty():
		return
	state.life_ledger = {"version": VERSION, "archive": [], "current": _new_life(state, complete)}

static func _new_life(state: GameState, complete: bool) -> Dictionary:
	var age := state.total_elapsed_seconds
	return {"life_id": state.reincarnation_count + 1, "started_at": age, "until": age,
		"coverage": "complete" if complete else "partial", "omitted_count": 0, "next_sequence": 1,
		"peak": {"era_id": state.era_id, "level": state.level, "at": age},
		"events": [], "beast_instance": "", "economy_origin": age - float(state.economy.get("tick", 0)),
		"end_state": {}, "text_version": "", "frozen_text": ""}

static func observe(state: GameState) -> void:
	initialize(state)
	var life: Dictionary = state.life_ledger.current
	life.until = maxf(float(life.until), state.total_elapsed_seconds)
	var peak: Dictionary = life.peak
	if state.era_id > int(peak.era_id) or (state.era_id == int(peak.era_id) and state.level > int(peak.level)):
		life.peak = {"era_id": state.era_id, "level": state.level, "at": state.total_elapsed_seconds}

static func note(state: GameState, kind: String, subject: String, source: String, at: float, instance: String = "") -> void:
	initialize(state)
	var life: Dictionary = state.life_ledger.current
	# Sources before the import boundary are explicitly not evidence for this life.
	if not kind in KINDS or at < float(life.started_at):
		return
	var id := (str(life.life_id) + "|" + source + "|" + kind + "|" + subject).sha256_text()
	var events: Array = life.events
	for event in events:
		if event.id == id:
			return
	# First 48 distinct milestones are pinned; 16 recent facts form a bounded ring.
	# Repeated route arrivals/buildings are represented by their first proven fact.
	for i in range(mini(events.size(), ANCHOR_LIMIT)):
		if kind in FIRST_ONLY and events[i].kind == kind and events[i].subject == subject and events[i].instance == instance:
			return
	var event := {"id": id, "seq": int(life.next_sequence), "kind": kind, "subject": subject,
		"at": at, "era_id": state.era_id, "level": state.level, "instance": instance}
	life.next_sequence = int(life.next_sequence) + 1
	life.until = maxf(float(life.until), at)
	if subject.to_utf8_buffer().size() > 96 or bytes(event) > EVENT_BYTES:
		life.omitted_count = int(life.omitted_count) + 1
		life.coverage = "partial"
		return
	if events.size() >= EVENT_LIMIT:
		events.remove_at(ANCHOR_LIMIT)
		life.omitted_count = int(life.omitted_count) + 1
		life.coverage = "partial"
	events.append(event)

static func command_committed(state: GameState, command: Dictionary, events: Array) -> void:
	observe(state)
	var source: String = String(command.get("command_id", "direct:" + JSON.stringify(command, "", true).sha256_text()))
	var life: Dictionary = state.life_ledger.current
	if String(command.type) in ["activate_islands", "migrate_processing"]:
		life.economy_origin = state.total_elapsed_seconds - float(state.economy.get("tick", 0))
	if String(command.type) == "open_island":
		note(state, "island_opened", String(command.payload.get("island_id", "")), source, state.total_elapsed_seconds)
	for event in events:
		var kind: String = String(event.get("kind", ""))
		match kind:
			"building_upgraded":
				if int(event.new_level) == 1:
					note(state, "building_built", String(event.building_id), source, state.total_elapsed_seconds)
			"era_breakthrough", "tribulation_failed", "tribulation_passed":
				note(state, kind, str(event.from_era) + ":" + str(event.to_era), source, state.total_elapsed_seconds)
			"cultivation_leveled_up":
				note(state, kind, str(state.era_id) + ":" + str(state.level), source, state.total_elapsed_seconds)
			"pill_refined", "skill_learned":
				note(state, kind, String(event.get("pill_id", event.get("skill_id", ""))), source, state.total_elapsed_seconds)
			"joined_sect", "expedition_claimed":
				note(state, kind, "sect", source, state.total_elapsed_seconds)
			"beast_acquired":
				life.beast_instance = (str(life.life_id) + "|" + source).sha256_text()
				note(state, kind, String(event.beast_id), source, state.total_elapsed_seconds, life.beast_instance)
			"beast_stage_up":
				if event.new_stage == "mature" and not String(life.beast_instance).is_empty():
					note(state, "beast_matured", String(event.beast_id), source, state.total_elapsed_seconds, life.beast_instance)

static func cargo_arrived(state: GameState, route_id: String) -> void:
	initialize(state)
	var tick: int = int(state.economy.get("tick", 0))
	var age := float(state.life_ledger.current.economy_origin) + float(tick)
	note(state, "cargo_arrived", route_id, "cargo:" + str(tick) + ":" + route_id, age)

static func exhausted(state: GameState) -> void:
	observe(state)
	note(state, "lifespan_exhausted", "life", "lifespan", state.total_elapsed_seconds)

static func seal(state: GameState, reason: String, source: String) -> void:
	observe(state)
	var life: Dictionary = state.life_ledger.current
	life.end_state = {"reason": reason, "era_id": state.era_id, "level": state.level,
		"at": state.total_elapsed_seconds, "settlement_id": source.sha256_text()}
	life.text_version = LifeReport.VERSION
	life.frozen_text = JSON.stringify(LifeReport.generate(life, reason), "", true)
	LifeHistory.trim(life, SEALED_BYTES)
	DecisionReceipt.trim(life, SEALED_BYTES)
	ResourceLedger.trim(life, SEALED_BYTES)
	state.life_ledger.archive.append(life.duplicate(true))
	while state.life_ledger.archive.size() > RETAINED_LIVES:
		state.life_ledger.archive.pop_front()

static func begin_next(state: GameState) -> void:
	state.life_ledger.current = _new_life(state, true)
	ResourceLedger.initialize(state, true)

static func bytes(value: Variant) -> int:
	return JSON.stringify(value, "", true).to_utf8_buffer().size()

static func coverage(state: GameState, kind: String = "") -> String:
	if not kind.is_empty() and not kind in KINDS:
		return "unsupported"
	if state.life_ledger.is_empty():
		return "missing"
	return String(state.life_ledger.current.coverage)

static func from_snapshot(value: Dictionary) -> Dictionary:
	# JSON numbers lose int/float types. Restore the declared contract so native
	# Dictionary equality and deep copies agree with freshly-created facts.
	var result := value.duplicate(true)
	if result.is_empty():
		return result
	result.version = int(result.version)
	var lives: Array = result.archive.duplicate()
	lives.append(result.current)
	for life in lives:
		if life.has("settlement"): life.settlement.dao_proof = int(life.settlement.dao_proof)
		if life.has("history"):
			life.history.version = int(life.history.version)
			life.history.omitted = int(life.history.omitted)
			life.history.started_at = float(life.history.started_at)
			for sample in life.history.samples: sample.at = float(sample.at)
		if life.has("accounts"):
			life.accounts.version = int(life.accounts.version)
			life.accounts.omitted = int(life.accounts.omitted)
			life.accounts.estimated_bytes = int(life.accounts.estimated_bytes)
			life.accounts.started_at = float(life.accounts.started_at)
		if life.has("decisions"):
			var book: Dictionary = life.decisions
			book.version = int(book.version)
			book.omitted = int(book.omitted)
			book.started_at = float(book.started_at)
			for r in book.receipts:
				r.version = int(r.version)
				r.life_id = int(r.life_id)
				r.option_index = int(r.option_index)
				r.at = float(r.at)
				for key in r.training: r.training[key] = float(r.training[key])
				for row in r.pills.values():
					for key in row: row[key] = int(row[key])
				if not r.buff.is_empty():
					r.buff.before = float(r.buff.before)
					r.buff.after = float(r.buff.after)
		for key in ["life_id", "omitted_count", "next_sequence"]:
			life[key] = int(life[key])
		for key in ["started_at", "until", "economy_origin"]:
			life[key] = float(life[key])
		var positions: Array = life.events.duplicate()
		positions.append(life.peak)
		if not life.end_state.is_empty():
			positions.append(life.end_state)
		for position in positions:
			position.at = float(position.at)
			position.era_id = int(position.era_id)
			position.level = int(position.level)
			if position.has("seq"):
				position.seq = int(position.seq)
	return result

static func _integer(v: Variant, minimum: int = 0) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and float(v) >= minimum and float(v) < 9007199254740991.0

static func _number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) >= 0.0

static func _keys(value: Dictionary, names: Array) -> bool:
	if value.size() != names.size():
		return false
	for key in names:
		if not value.has(key):
			return false
	return true

static func validate(value: Variant, life_id: int) -> String:
	if not value is Dictionary or not _keys(value, ["version", "current", "archive"]):
		return "LEDGER_STRUCTURE"
	if not _integer(value.version, 1) or int(value.version) != VERSION:
		return "LEDGER_VERSION"
	if not value.archive is Array or value.archive.size() > RETAINED_LIVES or bytes(value) > TOTAL_BYTES:
		return "LEDGER_LIMIT"
	var previous := 0
	for life in value.archive:
		var error := _validate_life(life, true)
		if not error.is_empty():
			return error
		if int(life.life_id) <= previous or int(life.life_id) >= life_id:
			return "LEDGER_LIFE_ORDER"
		previous = int(life.life_id)
	var current_error := _validate_life(value.current, false)
	if not current_error.is_empty():
		return current_error
	return "" if int(value.current.life_id) == life_id else "LEDGER_LIFE_ID"

static func _validate_life(life: Variant, sealed: bool) -> String:
	if not life is Dictionary or not _keys(life, ["life_id", "started_at", "until", "coverage", "omitted_count", "next_sequence", "peak", "events", "beast_instance", "economy_origin", "end_state", "text_version", "frozen_text"] + (["decisions"] if life is Dictionary and life.has("decisions") else []) + (["accounts"] if life is Dictionary and life.has("accounts") else []) + (["history"] if life is Dictionary and life.has("history") else []) + (["settlement"] if life is Dictionary and life.has("settlement") else [])):
		return "LEDGER_LIFE_STRUCTURE"
	if life.has("history"):
		var history_error := LifeHistory.validate(life.history, life)
		if not history_error.is_empty(): return history_error
	if life.has("settlement"):
		var r: Variant = life.settlement
		if not sealed or not r is Dictionary or not _keys(r, ["dao_heart", "dao_proof"]) or not ResourceLedger._valid_amount(r.dao_heart, false) or not _integer(r.dao_proof): return "LEDGER_SETTLEMENT"
	if life.has("accounts"):
		var account_error := ResourceLedger.validate(life.accounts)
		if not account_error.is_empty(): return account_error
		if not _number(life.get("started_at")) or not _number(life.get("until")) or float(life.accounts.started_at) < float(life.started_at) or float(life.accounts.started_at) > float(life.until): return "ACCOUNTS_COVERAGE"
	if life.has("decisions"):
		var decision_error := DecisionReceipt.validate(life.decisions, life)
		if not decision_error.is_empty(): return decision_error
	if bytes(life) > (SEALED_BYTES if sealed else CURRENT_BYTES):
		return "LEDGER_LIFE_LIMIT"
	for key in ["life_id", "next_sequence"]:
		if not _integer(life[key], 1):
			return "LEDGER_INTEGER"
	if not _integer(life.omitted_count) or not _number(life.started_at) or not _number(life.until) or float(life.started_at) > float(life.until):
		return "LEDGER_COVERAGE"
	if not life.coverage in ["complete", "partial"] or (life.coverage == "complete" and (float(life.started_at) != 0.0 or int(life.omitted_count) != 0)):
		return "LEDGER_COVERAGE"
	if not life.beast_instance is String or (not life.beast_instance.is_empty() and not _hash(life.beast_instance)):
		return "LEDGER_INSTANCE"
	if not (life.economy_origin is int or life.economy_origin is float) or not is_finite(float(life.economy_origin)):
		return "LEDGER_ORIGIN"
	if not life.text_version is String or life.text_version.to_utf8_buffer().size() > 64 or not life.frozen_text is String or life.frozen_text.to_utf8_buffer().size() > TEXT_BYTES:
		return "LEDGER_TEXT"
	if not life.peak is Dictionary or not _keys(life.peak, ["era_id", "level", "at"]) or not _position(life.peak, life):
		return "LEDGER_PEAK"
	if not life.events is Array or life.events.size() > EVENT_LIMIT:
		return "LEDGER_EVENTS"
	var sequence := 0
	var ids := {}
	var last_age := float(life.started_at)
	for event in life.events:
		if not event is Dictionary or not _keys(event, ["id", "seq", "kind", "subject", "at", "era_id", "level", "instance"]):
			return "LEDGER_EVENT_STRUCTURE"
		if bytes(event) > EVENT_BYTES or not _hash(event.id) or ids.has(event.id) or not _integer(event.seq, 1) or int(event.seq) <= sequence or int(event.seq) >= int(life.next_sequence):
			return "LEDGER_EVENT_ID"
		if not event.kind in KINDS or not event.subject is String or event.subject.to_utf8_buffer().size() > 96 or not event.instance is String or (not event.instance.is_empty() and not _hash(event.instance)):
			return "LEDGER_EVENT_TYPE"
		if not _position(event, life) or float(event.at) < last_age:
			return "LEDGER_EVENT_TIME"
		ids[event.id] = true
		sequence = int(event.seq)
		last_age = float(event.at)
	if not life.end_state is Dictionary:
		return "LEDGER_END"
	if sealed:
		var ending: Dictionary = life.end_state
		if not _keys(ending, ["reason", "era_id", "level", "at", "settlement_id"]) or not ending.reason in ["lifespan_exhausted", "rebirth_lotus"] or not _position(ending, life) or float(ending.at) != float(life.until) or not _hash(ending.settlement_id):
			return "LEDGER_END"
	elif not life.end_state.is_empty():
		return "LEDGER_CURRENT_SEALED"
	return ""

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for char in value:
		if not char in "0123456789abcdef":
			return false
	return true

static func _position(value: Dictionary, life: Dictionary) -> bool:
	return _integer(value.get("era_id"), 1) and int(value.era_id) <= 12 and _integer(value.get("level"), 1) and _number(value.get("at")) and float(value.at) >= float(life.started_at) and float(value.at) <= float(life.until)
