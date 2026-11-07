class_name EconomyProfile
extends RefCounted
## Opt-in application boundary. Never installed in the legacy launcher.
## Composite snapshot owns the existing GameState AND research; no legacy codec changes.
const PROFILE := "dao2-econ-r1"
const SCHEMA := 1
const RULES := "econ-r1-rules-2"
const ECONOMY := "econ-r1-economy-2"
const META := {"save_id":"econ-r1", "saved_at_utc_ms":"0", "settled_until_utc_ms":"0", "sim_tick":"0"}
var _content: GameContent
var _catalog: Dictionary
var _game: GameSession
var _research: Dictionary
var _storage: EconomyProfileStorage
var _slots: SaveSlots
var _settled_until := 0
var _generation := 0
var _source := ""
var _pending := ""
var _pending_result: Dictionary = {}
var _settling := false

func save_pending() -> bool:
	return not _pending.is_empty()

func settled_until() -> int:
	return _settled_until

func committed_game() -> GameSession:
	return _game

func research_view() -> Dictionary:
	var readiness := {}
	for node in _catalog.nodes:
		if int(node.era) <= _game.state.era_id:
			readiness[node.id] = ResearchSystem.availability(_catalog, _research, _game.state, node.id, _content).get("error", "")
	return {
		"nodes": _catalog.nodes.duplicate(true), "state": _research.duplicate(true),
		"readiness": readiness,
		"inheritance": ResearchSystem.inheritance(_catalog, _research),
	}

static func open(content: GameContent, adapter: StorageAdapter, catalog: Dictionary, create: bool = false, seed: int = 1) -> Dictionary:
	var error := ResearchSystem.validate_catalog(catalog, content)
	if not error.is_empty(): return {"ok": false, "error": error}
	var profile := EconomyProfile.new()
	profile._content = content
	profile._catalog = catalog.duplicate(true)
	profile._storage = EconomyProfileStorage.new(adapter)
	profile._slots = SaveSlots.new(profile._storage)
	# Never downgrade an authenticated incompatible generation by falling back to v1.
	for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]:
		var stored := profile._storage.read(slot)
		if not stored.ok: continue # read_best below propagates storage denial.
		var parser := JSON.new()
		if parser.parse(stored.data) != OK or not parser.data is Dictionary: continue
		var envelope: Dictionary = parser.data
		if envelope.get("checksum") is String and envelope.checksum == _checksum(envelope):
			var inspected := profile._decode(stored.data)
			if not inspected.ok and (String(inspected.get("error", "")).begins_with("PROFILE_VERSION:") or inspected.get("error") == "PROFILE_LEGACY_UNSUPPORTED"):
				return inspected
	var loaded := profile._slots.read_best(profile._revision_of)
	if loaded.ok:
		if create: return {"ok": false, "error": "PROFILE_EXISTS"}
		profile._install(loaded.json)
		return {"ok": true, "profile": profile}
	if loaded.error == "empty_storage":
		var index := profile._storage.read(SaveSlots.INDEX_KEY)
		if index.ok or index.get("error") != "missing": return {"ok":false, "error":"PROFILE_INDEX_WITHOUT_SLOTS"}
	if not create or loaded.error != "empty_storage":
		var causes := {}
		for slot in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]:
			var raw := profile._storage.read(slot)
			if raw.ok: causes[slot] = profile._decode(raw.data).get("error", "")
		return {"ok": false, "error": loaded.error, "causes":causes, "detail":"新版 profile 無有效存檔；舊進度請使用原版入口。"}
	profile._game = GameSession.create_new_game(content, seed)
	profile._game._executing_save_candidate = true
	profile._research = ResearchSystem.initial()
	profile._game.content = EconomySlice.bind(content, profile._research)
	var staged := profile._stage(profile._game, profile._research, {"ok":true, "created":true})
	# A failed initial write still returns its retryable owner; never silently recreate.
	return {"ok": staged.ok, "profile":profile, "error":staged.get("error", "")}

func _rules() -> String:
	return "econ-r1-rules-4" if EconomySlice.frontier(_content) else "econ-r1-rules-3" if EconomySlice.late(_content) else RULES

func _economy() -> String:
	return "econ-r1-economy-4" if EconomySlice.frontier(_content) else "econ-r1-economy-3" if EconomySlice.late(_content) else ECONOMY

func view() -> Dictionary:
	if _game == null: return {}
	return {"profile":PROFILE, "rules":_rules(), "economy":_economy(), "research_version":ResearchSystem.VERSION, "state":_game.state.to_snapshot_dict(), "research":_research.duplicate(true), "settled_until_utc_ms":_settled_until, "save_pending":not _pending.is_empty()}

func quote_research(id: String) -> Dictionary:
	return ResearchSystem.quote(_catalog, _research, _game.state, id)

func submit(command: Dictionary) -> Dictionary:
	if _settling: return {"ok":false, "error":"PROFILE_SETTLING"}
	if not _pending.is_empty(): return {"ok":false, "error":"PROFILE_SAVE_REQUIRED"}
	if not _game._is_valid_shape(command) and command.get("type") not in ["start_research", "cancel_research", "record_tutorial"]: return {"ok":false, "error":"INVALID_COMMAND"}
	if not command.get("command_id") is String or command.command_id.is_empty() or not command.get("payload") is Dictionary or not ResearchSystem.integer(command.get("expected_revision"), 0, 9007199254740991): return {"ok":false, "error":"INVALID_COMMAND"}
	if _game.state.command_receipts.has(command.command_id):
		return {"ok":true, "duplicate":true, "events":[], "new_revision":_game.state.revision}
	if int(command.expected_revision) != _game.state.revision: return {"ok":false, "error":"STALE_REVISION"}
	var candidate := _copy_game()
	var research := _research.duplicate(true)
	candidate.content = EconomySlice.bind(_content, research)
	var result: Dictionary
	match command.type:
		"record_tutorial":
			var flag: Variant = command.payload.get("flag")
			var value: Variant = command.payload.get("value")
			if not flag is String: return {"ok":false, "error":"INVALID_COMMAND"}
			if flag == "aspired_realm" and value is String:
				var realms := ContentLoader.load_realms()
				if not realms.ok or not realms.realms.any(func(realm: Dictionary): return realm.id == value):
					return {"ok":false, "error":"INVALID_COMMAND"}
			elif flag not in ["seen_nine_realms_hook", "v2_rules_notice_seen"] or not value is bool:
				return {"ok":false, "error":"INVALID_COMMAND"}
			candidate.state.tutorial_flags[flag] = value
			result = {"ok":true, "events":[], "changed_ids":["tutorial_flags"]}
		"start_research":
			if not command.payload.get("research_id") is String: return {"ok":false, "error":"INVALID_COMMAND"}
			result = ResearchSystem.start(_catalog, research, candidate.state, command.payload.research_id, _content)
		"cancel_research": result = ResearchSystem.cancel(research)
		_:
			# Candidate content carries C gates; legacy content has no new gates.
			if EconomySlice.frontier(_content) and command.type == "open_island" and not IslandProgression.active(candidate.state):
				var activation := candidate.submit({
					"command_id": command.command_id + ":activate", "type": "activate_islands",
					"expected_revision": candidate.state.revision, "payload": {"hub":true},
				})
				if not activation.ok: return activation
				command = command.duplicate()
				command.expected_revision = candidate.state.revision
			result = candidate.submit(command)
			if result.ok and command.type == "reincarnate": ResearchSystem.reset_life(research, _catalog)
	if not result.ok: return result
	if command.type in ["start_research", "cancel_research", "record_tutorial"]:
		candidate.state.revision += 1
		result.new_revision = candidate.state.revision
		result.duplicate = false
		candidate._remember(command.command_id, result)
	return _stage(candidate, research, result)

func advance_time(seconds: float) -> Dictionary:
	if _settling: return {"ok":false, "error":"PROFILE_SETTLING"}
	if not _pending.is_empty(): return {"ok":false, "error":"PROFILE_SAVE_REQUIRED"}
	if not EconomyEffects.finite(seconds) or seconds <= 0 or seconds > 172800: return {"ok":false, "error":"PROFILE_TIME_RANGE"}
	var candidate := _copy_game()
	var research := _research.duplicate(true)
	candidate.content = EconomySlice.bind(_content, research)
	var result := _advance_working(candidate, research, seconds)
	if not result.ok: return result
	var cursor := _settled_until + int(round(seconds * 1000.0)) if _settled_until > 0 else 0
	return _stage(candidate, research, result, cursor)

func settle_to(now_utc_ms: int) -> Dictionary:
	var prepared := _prepare_settlement(now_utc_ms)
	if not prepared.ok or not prepared.has("candidate"): return prepared
	var result := _advance_working(prepared.candidate, prepared.research, prepared.seconds)
	return _finish_settlement(prepared, result, now_utc_ms)

func settle_to_async(now_utc_ms: int, tree: SceneTree, progress: Callable) -> Dictionary:
	var prepared := _prepare_settlement(now_utc_ms)
	if not prepared.ok or not prepared.has("candidate"): return prepared
	var result := _empty_advance()
	var remaining: float = prepared.seconds
	var budget := Time.get_ticks_usec()
	_settling = true
	while remaining > 0.0:
		var chunk := minf(remaining, 16.0)
		result = _advance_working(prepared.candidate, prepared.research, chunk, result)
		remaining -= chunk
		if not result.ok or result.stopped != null: break
		if Time.get_ticks_usec() - budget >= 8000:
			progress.call(int(prepared.seconds - remaining), int(prepared.seconds))
			await tree.process_frame
			budget = Time.get_ticks_usec()
	_settling = false
	return _finish_settlement(prepared, result, now_utc_ms)

func _prepare_settlement(now_utc_ms: int) -> Dictionary:
	if _settling: return {"ok":false, "error":"PROFILE_SETTLING"}
	if not _pending.is_empty(): return {"ok":false, "error":"PROFILE_SAVE_REQUIRED"}
	if now_utc_ms <= 0 or now_utc_ms > 9007199254740991: return {"ok":false, "error":"PROFILE_UTC_RANGE"}
	var plan := OfflineSettlement.plan(now_utc_ms, _settled_until)
	if plan.rollback or now_utc_ms == _settled_until:
		return {"ok":true, "committed":false, "report":plan, "ticks_advanced":0}
	var candidate := _copy_game()
	var research := _research.duplicate(true)
	candidate.content = EconomySlice.bind(_content, research)
	return {"ok":true, "candidate":candidate, "research":research, "plan":plan,
		"carry":candidate.state.tick_remainder_seconds, "seconds":float(plan.effective_ms) / 1000.0}

func _finish_settlement(prepared: Dictionary, result: Dictionary, now_utc_ms: int) -> Dictionary:
	if not result.ok: return result
	var candidate: GameSession = prepared.candidate
	var plan: Dictionary = prepared.plan
	var carry: float = prepared.carry
	var seconds: float = prepared.seconds
	var total_ticks := TimeAdvancer.ticks_for_elapsed(carry + float(plan.away_ms) / 1000.0)
	var full_ticks := TimeAdvancer.ticks_for_elapsed(carry + seconds)
	var time_only_ticks := maxi(0, total_ticks - full_ticks)
	if result.stopped == null and time_only_ticks > 0:
		var tail := TimeAdvancer.advance_time_only(candidate.state, _content, time_only_ticks)
		result.events.append_array(tail.events)
		result.stopped = tail.stopped
		candidate.state.revision += 1
	if int(plan.away_ms) > 0:
		candidate.state.tick_remainder_seconds = 0.0 if result.stopped != null else maxf(0.0, carry + float(plan.away_ms) / 1000.0 - total_ticks)
	result.report = plan
	result.report["time_only_ticks"] = time_only_ticks
	result.report["effective_ticks"] = int(result.ticks_advanced)
	result.report["age_seconds"] = candidate.state.total_elapsed_seconds
	result.report["stopped"] = result.stopped
	result.report["report_id"] = "econ-r1-offline:" + str(now_utc_ms)
	result.committed = true
	result.new_revision = candidate.state.revision
	# Commit observed UTC even when capped/dead. Reload cannot collect the same gap.
	return _stage(candidate, prepared.research, result, now_utc_ms)

func _empty_advance() -> Dictionary:
	return {"ok":true, "ticks_advanced":0, "events":[], "changed_ids":[], "stopped":null}

func _advance_working(candidate: GameSession, research: Dictionary, seconds: float, result: Dictionary = {}) -> Dictionary:
	if result.is_empty(): result = _empty_advance()
	var remaining := seconds
	# Reuse the existing command-free tick preparation; do not batch or skip ticks.
	var prepared := TimeAdvancer.prepare_advance(candidate.state, candidate.content)
	# One authoritative second at a time: existing production/cargo/work/buffs/death first,
	# then research for that executed tick. The final living tick may finish research.
	while remaining > 0.0:
		var step_seconds := minf(1.0, remaining)
		var step := candidate.advance_time(step_seconds, prepared)
		# Maid duties can issue build/craft commands inside an otherwise elapsed-only call.
		if not candidate.state.maid.get("maids", {}).is_empty(): prepared.clear()
		if not step.ok: return step
		result.ticks_advanced += int(step.ticks_advanced)
		result.events.append_array(step.events)
		for id in step.changed_ids:
			if not id in result.changed_ids: result.changed_ids.append(id)
		if int(step.ticks_advanced) > 0:
			var research_events := ResearchSystem.tick(research)
			result.events.append_array(research_events)
			if not research_events.is_empty(): prepared.clear() # Newly unlocked production invalidates idle cache.
			if not research.job.is_empty() or research != _research:
				if not "research" in result.changed_ids: result.changed_ids.append("research")
		result.stopped = step.stopped
		remaining -= step_seconds
		if step.stopped != null: break
	# The outer save generation is monotonic even for fractional/zero-tick transactions.
	result.new_revision = candidate.state.revision
	return result

func retry_save() -> Dictionary:
	if _pending.is_empty(): return {"ok":false, "error":"PROFILE_NO_PENDING"}
	# Source archive and exact candidate are retained through every failure stage.
	var current := _slots.read_best(_revision_of)
	if current.ok:
		if current.json != _source and current.json != _pending: return {"ok":false, "error":"PROFILE_SOURCE_CHANGED"}
	elif not _source.is_empty() or current.error not in ["empty_storage", "no_valid_slot"]:
		return {"ok":false, "error":"PROFILE_READ_FAILED", "cause":current.error}
	if not _source.is_empty():
		var archive := _storage.write("source_before_commit", _source)
		if not archive.ok: return {"ok":false, "error":"PROFILE_SAVE_REQUIRED", "cause":"PROFILE_ARCHIVE_FAILED"}
		var readback := _storage.read("source_before_commit")
		if not readback.ok or readback.data != _source: return {"ok":false, "error":"PROFILE_SAVE_REQUIRED", "cause":"PROFILE_ARCHIVE_READBACK"}
	# Reuse exact bytes: no command/tick/reincarnation/material payment is replayed.
	var result := _slots.commit(_pending, int(JSON.parse_string(_pending).revision))
	if not result.ok: return {"ok":false, "error":"PROFILE_SAVE_REQUIRED", "cause":result.error}
	_install(_pending)
	var committed := _pending_result.duplicate(true)
	committed["persisted"] = true
	_pending = ""
	_pending_result = {}
	return committed

func _copy_game() -> GameSession:
	var copy := GameSession.new()
	copy.content = _content
	copy.state = _game.state.duplicate_state()
	copy.clock = GameClock.create(_game.clock.now())
	# Prevent legacy global SaveManager from intercepting composite candidate commands.
	copy._executing_save_candidate = true
	return copy

func _stage(candidate: GameSession, research: Dictionary, result: Dictionary, cursor: int = -1) -> Dictionary:
	var encoded := _encode(candidate, research, _settled_until if cursor < 0 else cursor)
	if not encoded.ok: return encoded
	_pending = encoded.json
	_pending_result = result.duplicate(true)
	return retry_save()

func _encode(game: GameSession, research: Dictionary, cursor: int) -> Dictionary:
	var error := ResearchSystem.validate(research, _catalog)
	if not error.is_empty(): return {"ok":false, "error":error}
	var base := SaveCodec.encode(game.state, _content.content_version, META)
	if not base.ok: return base
	var envelope := {"profile":PROFILE, "schema_version":SCHEMA, "rules_version":_rules(), "economy_version":_economy(), "research_version":ResearchSystem.VERSION, "content_version":_content.content_version, "catalog_sha256":JSON.stringify(_catalog, "", true).sha256_text(), "revision":_generation + 1, "core_revision":game.state.revision, "settled_until_utc_ms":cursor, "clock":game.clock.now(), "core_json":base.json, "research":research.duplicate(true)}
	# Hash precisely the JSON representation that will be read back.
	envelope = JSON.parse_string(JSON.stringify(envelope, "", true))
	envelope.checksum = _checksum(envelope)
	var raw := JSON.stringify(envelope, "", true)
	var verified := _decode(raw)
	if not verified.ok: return verified
	return {"ok":true, "json":raw}

func _decode(raw: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {"ok":false, "error":"PROFILE_JSON"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return {"ok":false, "error":"PROFILE_JSON"}
	if not parsed.get("profile") is String or parsed.profile != PROFILE: return {"ok":false, "error":"PROFILE_LEGACY_UNSUPPORTED", "detail":"請返回舊版入口；新版不匯入舊進度。"}
	var versions := {"schema_version":SCHEMA, "rules_version":_rules(), "economy_version":_economy(), "research_version":ResearchSystem.VERSION, "content_version":_content.content_version, "catalog_sha256":JSON.stringify(_catalog, "", true).sha256_text()}
	for key in versions:
		var expected: Variant = versions[key]
		if not ResearchSystem.same(parsed.get(key), expected): return {"ok":false, "error":"PROFILE_VERSION:" + key}
	if not parsed.get("checksum") is String or parsed.checksum != _checksum(parsed): return {"ok":false, "error":"PROFILE_CHECKSUM"}
	if not EconomyEffects.finite(parsed.get("clock")) or parsed.clock < 0 or not parsed.get("core_json") is String: return {"ok":false, "error":"PROFILE_SHAPE"}
	if not ResearchSystem.integer(parsed.get("settled_until_utc_ms"), 0, 9007199254740991): return {"ok":false, "error":"PROFILE_UTC"}
	var decoded := SaveCodec.decode(parsed.core_json)
	if not decoded.ok: return decoded
	if not ResearchSystem.integer(parsed.get("revision"), 0, 9007199254740991) or not ResearchSystem.integer(parsed.get("core_revision"), 0, 9007199254740991) or int(parsed.core_revision) != decoded.state.revision: return {"ok":false, "error":"PROFILE_REVISION"}
	var error := ResearchSystem.validate(parsed.get("research"), _catalog)
	if not error.is_empty(): return {"ok":false, "error":error}
	return {"ok":true, "state":decoded.state, "research":parsed.research, "clock":parsed.clock, "revision":int(parsed.revision), "cursor":int(parsed.settled_until_utc_ms)}

func _revision_of(raw: String) -> int:
	var decoded := _decode(raw)
	return int(decoded.revision) if decoded.ok else -1

func _install(raw: String) -> void:
	var decoded := _decode(raw)
	_game = GameSession.new()
	_game.content = EconomySlice.bind(_content, decoded.research)
	_game.state = decoded.state
	_game.clock = GameClock.create(decoded.clock)
	_game._executing_save_candidate = true
	_research = decoded.research.duplicate(true)
	_settled_until = decoded.cursor
	_generation = decoded.revision
	_source = raw

static func _checksum(envelope: Dictionary) -> String:
	var payload := envelope.duplicate(true)
	payload.erase("checksum")
	return JSON.stringify(payload, "", true).sha256_text()

func inspect_save(raw: String) -> Dictionary:
	# Explicit read-only import preflight. Version changes never auto-migrate or install.
	var decoded := _decode(raw)
	return {"ok":decoded.ok, "error":decoded.get("error", ""), "detail":decoded.get("detail", "")}
