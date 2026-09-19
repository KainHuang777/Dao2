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

static func configure(content: GameContent, adapter: StorageAdapter = null) -> void:
	_content = content
	var use_adapter: StorageAdapter = adapter
	if use_adapter == null:
		use_adapter = FileStorageAdapter.new(DEFAULT_SAVE_DIR)
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
	if _current_state == null:
		_current_state = _new_state()
	return _current_state

static func load_state() -> Variant:
	return current_state()

static func save(state: GameState, meta: Dictionary) -> Dictionary:
	if state == null:
		return {"ok": false, "error": "STATE_MISSING"}
	var content_obj: GameContent = content()
	if content_obj == null:
		return {"ok": false, "error": "CONTENT_MISSING"}
	var encode_result: Dictionary = SaveCodec.encode(state, content_obj.content_version, _normalize_meta(meta))
	if not bool(encode_result.get("ok", false)):
		return {"ok": false, "error": String(encode_result.get("error", "ENCODE_FAILED"))}
	var commit_result: Dictionary = slots().commit(String(encode_result["json"]), state.revision)
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

static func _load_from_slots() -> GameState:
	var best: Dictionary = slots().read_best(func(json_text: String) -> int:
		var decode_result: Dictionary = SaveCodec.decode(json_text)
		if not bool(decode_result.get("ok", false)):
			return -1
		var decoded_state: GameState = decode_result["state"]
		return decoded_state.revision
	)
	if not bool(best.get("ok", false)):
		return null
	var decode_result: Dictionary = SaveCodec.decode(String(best["json"]))
	if not bool(decode_result.get("ok", false)):
		return null
	_envelope = decode_result["envelope"]
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
		"settled_until_utc_ms": String(meta.get("settled_until_utc_ms", "0")),
		"sim_tick": String(meta.get("sim_tick", "0")),
	}
	if meta.has("rng_streams") and meta["rng_streams"] is Dictionary:
		normalized["rng_streams"] = meta["rng_streams"]
	if meta.has("last_offline_report"):
		normalized["last_offline_report"] = meta["last_offline_report"]
	return normalized
