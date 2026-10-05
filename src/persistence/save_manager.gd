class_name SaveManager
extends RefCounted

const DEFAULT_CONTENT_DIR := "res://content"
const DEFAULT_SAVE_DIR := "user://saves"
const LEGACY_RAW_KEY := "legacy_import_raw"

static var _content: GameContent = null
static var _slots: SaveSlots = null
static var _current_state: GameState = null
static var _envelope: Dictionary = {}
static var _adapter: StorageAdapter = null
static var _schema2_original: String = ""
static var _load_error: String = ""
const SCHEMA2_ARCHIVE_KEY := "save_schema2_original"
const ISLAND_ARCHIVE_KEY := "save_before_islands"
const D2_ARCHIVE_KEY := "save_before_d2"

static func activate_islands(session: GameSession, meta: Dictionary) -> Dictionary:
	# Persist the current source first; archive those exact bytes before C activation.
	# The live Session is only replaced after a verified two-slot commit.
	var checked := IslandProgression.preview(session.state, session.content)
	if not checked.ok:
		return checked
	var extending: bool = session.state.economy.get("version") == IslandProgression.LEGACY_VERSION
	var archive_key := D2_ARCHIVE_KEY if extending else ISLAND_ARCHIVE_KEY
	var source_saved := save(session.state, meta)
	if not source_saved.ok:
		return source_saved
	var source := slots().read_best(func(raw: String) -> int:
		var decoded := SaveCodec.decode(raw)
		return decoded.state.revision if decoded.ok else -1)
	if not source.ok:
		return source
	var original := adapter().read(archive_key)
	if not original.ok:
		if original.get("error") != "missing":
			return {"ok": false, "error": "ISLAND_ARCHIVE_READ_FAILED"}
		var written := adapter().write(archive_key, source.json)
		if not written.ok:
			return {"ok": false, "error": "ISLAND_ARCHIVE_WRITE_FAILED"}
		original = adapter().read(archive_key)
		if not original.ok or original.data != source.json:
			return {"ok": false, "error": "ISLAND_ARCHIVE_READBACK"}
	var archived := SaveCodec.decode(original.data)
	if not archived.ok or archived.envelope.save_id != String(meta.get("save_id", "local")):
		return {"ok": false, "error": "ISLAND_ARCHIVE_CONFLICT"}
	if (extending and archived.state.economy.get("version") != IslandProgression.LEGACY_VERSION) or (not extending and not archived.state.economy.is_empty()):
		return {"ok": false, "error": "ISLAND_ARCHIVE_CONFLICT"}
	var candidate := GameSession.new()
	candidate.content = session.content
	candidate.clock = GameClock.create(session.state.total_elapsed_seconds)
	candidate.state = session.state.duplicate_state()
	var result := candidate.submit({"command_id": "activate-islands-" + str(session.state.revision), "type": "activate_islands", "expected_revision": session.state.revision, "payload": {}})
	if not result.ok:
		return result
	var committed := save(candidate.state, meta)
	if not committed.ok:
		return committed
	session.state = candidate.state
	return result

static func configure(content: GameContent, adapter: StorageAdapter = null) -> void:
	_content = content
	var use_adapter: StorageAdapter = adapter
	if use_adapter == null:
		use_adapter = FileStorageAdapter.new(DEFAULT_SAVE_DIR)
	_schema2_original = ""
	_load_error = ""
	_adapter = use_adapter
	_slots = SaveSlots.new(use_adapter)
	_current_state = null
	_envelope = {}

static func content() -> GameContent:
	if _content == null:
		var loaded: Dictionary = ContentLoader.load_directory(DEFAULT_CONTENT_DIR)
		if bool(loaded.get("ok", false)):
			_content = loaded["content"]
	return _content

static func slots() -> SaveSlots:
	if _slots == null:
		_slots = SaveSlots.new(adapter())
	return _slots

static func adapter() -> StorageAdapter:
	if _adapter == null:
		_adapter = FileStorageAdapter.new(DEFAULT_SAVE_DIR)
	return _adapter

static func current_state() -> GameState:
	if _current_state == null:
		_current_state = _load_from_slots()
	if _current_state == null and _load_error.is_empty():
		_current_state = _new_state()
	return _current_state

static func load_error() -> String:
	return _load_error

static func load_state() -> Variant:
	return current_state()

static func save(state: GameState, meta: Dictionary) -> Dictionary:
	if not _load_error.is_empty():
		return {"ok": false, "error": "LOAD_NOT_TRUSTED"}
	if state == null:
		return {"ok": false, "error": "STATE_MISSING"}
	var content_obj: GameContent = content()
	if content_obj == null:
		return {"ok": false, "error": "CONTENT_MISSING"}
	var profile_encode := RuntimeProfile.begin()
	var encode_result: Dictionary = SaveCodec.encode(state, content_obj.content_version, _normalize_meta(meta))
	RuntimeProfile.end("save_encode", profile_encode)
	if not bool(encode_result.get("ok", false)):
		return {"ok": false, "error": String(encode_result.get("error", "ENCODE_FAILED"))}
	if not _schema2_original.is_empty():
		if not adapter().exists(SCHEMA2_ARCHIVE_KEY):
			var archived := adapter().write(SCHEMA2_ARCHIVE_KEY, _schema2_original)
			if not archived.ok:
				return {"ok": false, "error": "MIGRATION_ARCHIVE_FAILED"}
		var verified := adapter().read(SCHEMA2_ARCHIVE_KEY)
		if not verified.ok or verified.data != _schema2_original:
			return {"ok": false, "error": "MIGRATION_ARCHIVE_READBACK"}
	var profile_commit := RuntimeProfile.begin()
	var commit_result: Dictionary = slots().commit(String(encode_result["json"]), state.revision)
	RuntimeProfile.end("save_commit", profile_commit)
	if bool(commit_result.get("ok", false)):
		_current_state = state
		_envelope = _normalize_meta(meta)
	return commit_result

static func import_legacy_text(input_text: String) -> Dictionary:
	var content_obj: GameContent = content()
	if content_obj == null:
		return {"ok": false, "error": "CONTENT_MISSING", "report": {}, "state": null}
	var imported: Dictionary = LegacyImporter.import_text(input_text, content_obj)
	if not bool(imported.get("ok", false)):
		return {"ok": false, "error": String(imported.get("error", "IMPORT_FAILED")), "report": imported.get("report", {}), "state": null}
	var raw_json: String = String(imported.get("raw_json", ""))
	if not raw_json.is_empty():
		adapter().write(LEGACY_RAW_KEY, raw_json)
	var state: GameState = imported["state"]
	var best: Dictionary = slots().read_best(func(json_text: String) -> int:
		var decode_result: Dictionary = SaveCodec.decode(json_text)
		if not bool(decode_result.get("ok", false)):
			return -1
		var decoded_state: GameState = decode_result["state"]
		return decoded_state.revision
	)
	var previous_revision: int = -1
	if bool(best.get("ok", false)):
		previous_revision = int(best.get("revision", -1))
	state.revision = maxi(previous_revision + 1, 1)
	var meta: Dictionary = {
		"save_id": "legacy_import",
		"saved_at_utc_ms": "0",
		"settled_until_utc_ms": "0",
		"sim_tick": "0",
	}
	var encode_result: Dictionary = SaveCodec.encode(state, content_obj.content_version, meta)
	if not bool(encode_result.get("ok", false)):
		return {"ok": false, "error": String(encode_result.get("error", "ENCODE_FAILED")), "report": imported["report"], "state": null}
	var commit_result: Dictionary = slots().commit(String(encode_result["json"]), state.revision)
	if not bool(commit_result.get("ok", false)):
		return {"ok": false, "error": String(commit_result.get("error", "COMMIT_FAILED")), "report": imported["report"], "state": null}
	return {"ok": true, "error": "", "report": imported["report"], "state": state}

static func legacy_raw() -> String:
	var result: Dictionary = adapter().read(LEGACY_RAW_KEY)
	if not bool(result.get("ok", false)):
		return ""
	return String(result.get("data", ""))

static func last_settled_utc_ms() -> int:
	if _envelope.is_empty():
		return 0
	var raw: Variant = _envelope.get("settled_until_utc_ms", "0")
	if raw is int:
		return int(raw)
	if raw is float:
		return int(raw)
	if raw is String:
		var text: String = raw
		if text.is_valid_int():
			return int(text)
	return 0

static func envelope() -> Dictionary:
	return _envelope

static func export_share_string(state: Variant = null, meta: Dictionary = {}) -> String:
	var exported: GameState = null
	if state is GameState:
		exported = state as GameState
	else:
		exported = current_state()
	if exported == null:
		return ""
	var content_obj: GameContent = content()
	if content_obj == null:
		return ""
	var encode_result: Dictionary = SaveCodec.encode(exported, content_obj.content_version, _normalize_meta(meta))
	if not bool(encode_result.get("ok", false)):
		return ""
	return Marshalls.utf8_to_base64(String(encode_result["json"]))

static func import_share_string(share: String) -> Dictionary:
	if share.is_empty():
		return {"ok": false, "state": null, "error": "EMPTY"}
	var json_text: String = Marshalls.base64_to_utf8(share)
	if json_text.is_empty():
		return {"ok": false, "state": null, "error": "BASE64"}
	var decode_result: Dictionary = SaveCodec.decode(json_text)
	if not bool(decode_result.get("ok", false)):
		return {"ok": false, "state": null, "error": String(decode_result.get("error", "DECODE_FAILED"))}
	return {"ok": true, "state": decode_result["state"], "error": ""}

static func reset_for_tests() -> void:
	_content = null
	_slots = null
	_current_state = null
	_envelope = {}
	_adapter = null
	_schema2_original = ""
	_load_error = ""

static func _load_from_slots() -> GameState:
	var best: Dictionary = slots().read_best(func(json_text: String) -> int:
		var decode_result: Dictionary = SaveCodec.decode(json_text)
		if not bool(decode_result.get("ok", false)):
			print("SAVE_SLOT_REJECTED: ", decode_result.get("error", "DECODE_FAILED"))
			return -1
		var decoded_state: GameState = decode_result["state"]
		return decoded_state.revision
	)
	if not bool(best.get("ok", false)):
		_load_error = "" if best.get("error") == "empty_storage" else String(best.get("error", "LOAD_FAILED"))
		return null
	var decode_result: Dictionary = SaveCodec.decode(String(best["json"]))
	if not bool(decode_result.get("ok", false)):
		return null
	_envelope = decode_result["envelope"]
	if int(_envelope.schema_version) == 2:
		_schema2_original = String(best["json"])
	return decode_result["state"]

static func _new_state() -> GameState:
	var content_obj: GameContent = content()
	if content_obj == null:
		return null
	var session: GameSession = GameSession.create_new_game(content_obj)
	return session.state

static func _normalize_meta(meta: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"save_id": String(meta.get("save_id", "local")),
		"saved_at_utc_ms": String(meta.get("saved_at_utc_ms", "0")),
		"settled_until_utc_ms": str(maxi(int(meta.get("settled_until_utc_ms", "0")), last_settled_utc_ms())),
		"sim_tick": String(meta.get("sim_tick", "0")),
	}
	if meta.has("rng_streams") and meta["rng_streams"] is Dictionary:
		normalized["rng_streams"] = meta["rng_streams"]
	if meta.has("last_offline_report"):
		normalized["last_offline_report"] = meta["last_offline_report"]
	return normalized
