class_name SaveManager
extends RefCounted

const DEFAULT_CONTENT_DIR := "res://content"
const DEFAULT_SAVE_DIR := "user://saves"
const LEGACY_RAW_KEY := "legacy_import_raw"
const SAVE_PRE_V2_RESCUE_KEY := "save_pre_v2_rescue"
const SCHEMA2_ARCHIVE_KEY := "save_schema2_original"
const ISLAND_ARCHIVE_KEY := "save_before_islands"
const D2_ARCHIVE_KEY := "save_before_d2"

static var _content: GameContent = null
static var _slots: SaveSlots = null
static var _current_state: GameState = null
static var _envelope: Dictionary = {}
static var _adapter: StorageAdapter = null
static var _schema2_original: String = ""
static var _skills_original: String = ""
static var _talents_original: String = ""
static var _talents_candidate: GameState = null
static var _story_original: String = ""
static var _story_candidate: GameState = null
static var _beasts_original: String = ""
static var _beasts_candidate: GameState = null
static var _sect_original: String = ""
static var _sect_candidate: GameState = null
static var _pills_original: String = ""
static var _pills_candidate: GameState = null
static var _ledger_original: String = ""
static var _supply_original: String = ""
static var _supply_candidate: GameState = null
static var _load_error: String = ""
static var _forced_reset := false

static func migration_pending(state: GameState) -> bool:
	return (not _story_original.is_empty() and state == _story_candidate) or (not _beasts_original.is_empty() and state == _beasts_candidate) or (not _sect_original.is_empty() and state == _sect_candidate) or (not _pills_original.is_empty() and state == _pills_candidate) or supply_pending(state) or (not _talents_original.is_empty() and state == _talents_candidate)

static func migration_error(state: GameState) -> String:
	return "STORY_SAVE_REQUIRED" if not _story_original.is_empty() and state == _story_candidate else "BEAST_SAVE_REQUIRED" if not _beasts_original.is_empty() and state == _beasts_candidate else "SUPPLY_SAVE_REQUIRED" if supply_pending(state) else "PILL_SAVE_REQUIRED" if not _pills_original.is_empty() and state == _pills_candidate else "SECT_SAVE_REQUIRED" if not _sect_original.is_empty() and state == _sect_candidate else "TALENT_SAVE_REQUIRED"

static func supply_pending(state: GameState) -> bool:
	return not _supply_original.is_empty() and state == _supply_candidate

static func activate_islands(session: GameSession, meta: Dictionary, first_island: String = "") -> Dictionary:
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
		var written := adapter().write(archive_key, String(source.json))
		if not written.ok:
			return {"ok": false, "error": "ISLAND_ARCHIVE_WRITE_FAILED"}
		original = adapter().read(archive_key)
		if not original.ok or original.data != source.json:
			return {"ok": false, "error": "ISLAND_ARCHIVE_READBACK"}
	var source_json := String(source.json)
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
	if not first_island.is_empty():
		result = candidate.submit({"command_id": "first-island-" + str(candidate.state.revision), "type": "open_island", "expected_revision": candidate.state.revision, "payload": {"island_id": first_island}})
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
	_skills_original = ""
	_talents_original = ""
	_talents_candidate = null
	_story_original = ""
	_story_candidate = null
	_beasts_original = ""
	_beasts_candidate = null
	_sect_original = ""
	_sect_candidate = null
	_pills_original = ""
	_pills_candidate = null
	_ledger_original = ""
	_supply_original = ""
	_supply_candidate = null
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
	if _story_candidate != null and state != _story_candidate:
		return {"ok": false, "error": "STORY_CANDIDATE_REQUIRED"}
	if _beasts_candidate != null and state != _beasts_candidate:
		return {"ok": false, "error": "BEAST_CANDIDATE_REQUIRED"}
	if _sect_candidate != null and state != _sect_candidate:
		return {"ok": false, "error": "SECT_CANDIDATE_REQUIRED"}
	if _pills_candidate != null and state != _pills_candidate:
		return {"ok": false, "error": "PILL_CANDIDATE_REQUIRED"}
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
	if not _skills_original.is_empty():
		var archive_key := "save_before_skills_" + _skills_original.sha256_text()
		var original := adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "SKILL_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _skills_original).ok:
				return {"ok": false, "error": "SKILL_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _skills_original:
			return {"ok": false, "error": "SKILL_ARCHIVE_READBACK"}
	if not _talents_original.is_empty():
		var archive_key := "save_before_talents_" + _talents_original.sha256_text()
		var original := adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "TALENT_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _talents_original).ok:
				return {"ok": false, "error": "TALENT_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _talents_original:
			return {"ok": false, "error": "TALENT_ARCHIVE_READBACK"}
	if not _story_original.is_empty():
		var archive_key := "save_before_story_" + _story_original.sha256_text()
		var original := adapter().read(archive_key)
		if original.ok and original.data != _story_original:
			var damaged_key := archive_key + "_damaged_" + String(original.data).sha256_text()
			if not adapter().write(damaged_key, original.data).ok:
				return {"ok": false, "error": "STORY_ARCHIVE_RESCUE_WRITE_FAILED"}
			var damaged := adapter().read(damaged_key)
			if not damaged.ok or damaged.data != original.data:
				return {"ok": false, "error": "STORY_ARCHIVE_RESCUE_READBACK"}
			if not adapter().write(archive_key, _story_original).ok:
				return {"ok": false, "error": "STORY_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "STORY_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _story_original).ok:
				return {"ok": false, "error": "STORY_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _story_original:
			return {"ok": false, "error": "STORY_ARCHIVE_READBACK"}
	if not _beasts_original.is_empty():
		var archive_key := "save_before_beasts_" + _beasts_original.sha256_text()
		var original := adapter().read(archive_key)
		# A failed readback may leave a damaged archive. Preserve those bytes
		# separately before retrying the same immutable original, never a new state.
		if original.ok and original.data != _beasts_original:
			var damaged_key := archive_key + "_damaged_" + String(original.data).sha256_text()
			if not adapter().write(damaged_key, original.data).ok:
				return {"ok": false, "error": "BEAST_ARCHIVE_RESCUE_WRITE_FAILED"}
			var damaged := adapter().read(damaged_key)
			if not damaged.ok or damaged.data != original.data:
				return {"ok": false, "error": "BEAST_ARCHIVE_RESCUE_READBACK"}
			if not adapter().write(archive_key, _beasts_original).ok:
				return {"ok": false, "error": "BEAST_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "BEAST_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _beasts_original).ok:
				return {"ok": false, "error": "BEAST_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _beasts_original:
			return {"ok": false, "error": "BEAST_ARCHIVE_READBACK"}
	if not _sect_original.is_empty():
		var archive_key := "save_before_sect_" + _sect_original.sha256_text()
		var original := adapter().read(archive_key)
		# A failed readback may leave a damaged archive. Preserve those bytes
		# separately before retrying the same immutable original, never a new state.
		if original.ok and original.data != _sect_original:
			var damaged_key := archive_key + "_damaged_" + String(original.data).sha256_text()
			if not adapter().write(damaged_key, original.data).ok:
				return {"ok": false, "error": "SECT_ARCHIVE_RESCUE_WRITE_FAILED"}
			var damaged := adapter().read(damaged_key)
			if not damaged.ok or damaged.data != original.data:
				return {"ok": false, "error": "SECT_ARCHIVE_RESCUE_READBACK"}
			if not adapter().write(archive_key, _sect_original).ok:
				return {"ok": false, "error": "SECT_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "SECT_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _sect_original).ok:
				return {"ok": false, "error": "SECT_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _sect_original:
			return {"ok": false, "error": "SECT_ARCHIVE_READBACK"}
	if not _pills_original.is_empty():
		var archive_key := "save_before_pills_" + _pills_original.sha256_text()
		var original := adapter().read(archive_key)
		# A failed readback may leave a damaged archive. Preserve those bytes
		# separately before retrying the same immutable original, never a new state.
		if original.ok and original.data != _pills_original:
			var damaged_key := archive_key + "_damaged_" + String(original.data).sha256_text()
			if not adapter().write(damaged_key, original.data).ok:
				return {"ok": false, "error": "PILL_ARCHIVE_RESCUE_WRITE_FAILED"}
			var damaged := adapter().read(damaged_key)
			if not damaged.ok or damaged.data != original.data:
				return {"ok": false, "error": "PILL_ARCHIVE_RESCUE_READBACK"}
			if not adapter().write(archive_key, _pills_original).ok:
				return {"ok": false, "error": "PILL_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "PILL_ARCHIVE_READ_FAILED"}
			if not adapter().write(archive_key, _pills_original).ok:
				return {"ok": false, "error": "PILL_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(archive_key)
		if not original.ok or original.data != _pills_original:
			return {"ok": false, "error": "PILL_ARCHIVE_READBACK"}
	if not _ledger_original.is_empty():
		var key := "save_before_ledger_" + _ledger_original.sha256_text()
		var original := adapter().read(key)
		if not original.ok:
			if original.get("error") != "missing":
				return {"ok": false, "error": "LEDGER_ARCHIVE_READ_FAILED"}
			if not adapter().write(key, _ledger_original).ok:
				return {"ok": false, "error": "LEDGER_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(key)
		if not original.ok or original.data != _ledger_original:
			return {"ok": false, "error": "LEDGER_ARCHIVE_READBACK"}
	if not _supply_original.is_empty():
		var key := "save_before_supply_" + _supply_original.sha256_text()
		var original := adapter().read(key)
		if not original.ok:
			if original.get("error") != "missing": return {"ok": false, "error": "SUPPLY_ARCHIVE_READ_FAILED"}
			if not adapter().write(key, _supply_original).ok: return {"ok": false, "error": "SUPPLY_ARCHIVE_WRITE_FAILED"}
			original = adapter().read(key)
		if not original.ok or original.data != _supply_original:
			return {"ok": false, "error": "SUPPLY_ARCHIVE_READBACK"}
	var profile_commit := RuntimeProfile.begin()
	var commit_result: Dictionary = slots().commit(String(encode_result["json"]), state.revision)
	RuntimeProfile.end("save_commit", profile_commit)
	if bool(commit_result.get("ok", false)):
		_current_state = state
		_skills_original = ""
		_talents_original = ""
		_talents_candidate = null
		_story_original = ""
		_story_candidate = null
		_beasts_original = ""
		_beasts_candidate = null
		_sect_original = ""
		_sect_candidate = null
		_pills_original = ""
		_pills_candidate = null
		_ledger_original = ""
		_supply_original = ""
		_supply_candidate = null
		_envelope = _normalize_meta(meta)
	return commit_result

static func import_legacy_text(input_text: String) -> Dictionary:
	if _story_candidate != null or _beasts_candidate != null or _sect_candidate != null or _pills_candidate != null or _talents_candidate != null or _supply_candidate != null:
		return {"ok": false, "state": null, "report": {}, "error": "MIGRATION_PENDING"}
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
	SkillSystem.reconcile(content_obj, state)
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
	# An outstanding migration owns its exact original and candidate. A second
	# import must not replace references used by the eventual atomic save.
	if _story_candidate != null or _beasts_candidate != null or _sect_candidate != null or _pills_candidate != null or _talents_candidate != null or _supply_candidate != null:
		return {"ok": false, "state": null, "error": "MIGRATION_PENDING"}
	if share.is_empty():
		return {"ok": false, "state": null, "error": "EMPTY"}
	var json_text: String = Marshalls.base64_to_utf8(share)
	if json_text.is_empty():
		return {"ok": false, "state": null, "error": "BASE64"}
	var decode_result: Dictionary = SaveCodec.decode(json_text)
	if not bool(decode_result.get("ok", false)):
		return {"ok": false, "state": null, "error": String(decode_result.get("error", "DECODE_FAILED"))}
	if content() != null and content().processing_catalog.get("version") == IslandProgression.SUPPLY_VERSION and (decode_result.state.economy.get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION] or not decode_result.state.resources.has("void_essence")):
		var prepared := IslandProgression.prepare_supply(content(), decode_result.state)
		if not prepared.ok: return {"ok": false, "state": null, "error": prepared.error}
		_supply_original = json_text
		decode_result.state = prepared.state
		_supply_candidate = prepared.state
	if decode_result.state.story_version < StoryProgress.VERSION:
		_story_original = json_text
		StoryProgress.migrate(decode_result.state)
		_story_candidate = decode_result.state
	SkillSystem.reconcile(content(), decode_result["state"])
	if TalentSystem.reconcile(decode_result["state"]):
		_talents_original = json_text
		_talents_candidate = decode_result.state
	if decode_result.state.pill_version < AlchemySystem.VERSION:
		_pills_original = json_text
		_pills_candidate = decode_result.state
		decode_result.state.pill_version = AlchemySystem.VERSION
	if decode_result.state.beast_version < BeastSystem.VERSION:
		_beasts_original = json_text
		_beasts_candidate = decode_result.state
		decode_result.state.beast_version = BeastSystem.VERSION
	if decode_result.state.sect_version < SectSystem.VERSION:
		_sect_original = json_text
		_sect_candidate = decode_result.state
		decode_result.state.sect_version = SectSystem.VERSION
	return {"ok": true, "state": decode_result["state"], "error": ""}

static func reset_for_tests() -> void:
	_content = null
	_slots = null
	_current_state = null
	_envelope = {}
	_adapter = null
	_schema2_original = ""
	_skills_original = ""
	_talents_original = ""
	_talents_candidate = null
	_story_original = ""
	_story_candidate = null
	_beasts_original = ""
	_beasts_candidate = null
	_sect_original = ""
	_sect_candidate = null
	_pills_original = ""
	_pills_candidate = null
	_ledger_original = ""
	_supply_original = ""
	_supply_candidate = null
	_load_error = ""
	_forced_reset = false

static func _load_from_slots() -> GameState:
	var adapter_obj: StorageAdapter = adapter()
	for slot_name in [SaveSlots.SLOT_MAIN, SaveSlots.SLOT_BACKUP]:
		var raw: Dictionary = adapter_obj.read(slot_name)
		if not bool(raw.get("ok", false)) or String(raw.get("data", "")) == "":
			continue
		var parsed: Variant = JSON.parse_string(String(raw.data))
		if not (parsed is Dictionary):
			continue
		if SaveCodec.classify_envelope(parsed) != "older" or int(parsed.get("schema_version", 0)) >= 2:
			continue
		if adapter_obj is WebStorageAdapter and adapter_obj.session_status() != "ready":
			break
		var written: Dictionary = adapter_obj.write(SAVE_PRE_V2_RESCUE_KEY, String(raw.data))
		if not bool(written.get("ok", false)):
			_load_error = "LOAD_FAILED"
			return null
		slots().reset()
		var verify: Dictionary = adapter_obj.read(SaveSlots.SLOT_MAIN)
		if bool(verify.get("ok", false)) and String(verify.get("data", "")) != "":
			_load_error = "LOAD_FAILED"
			return null
		_load_error = ""
		_forced_reset = true
		return null
	var sect_decode_error := {"value":""}
	var best: Dictionary = slots().read_best(func(json_text: String) -> int:
		var decode_result: Dictionary = SaveCodec.decode(json_text)
		if not bool(decode_result.get("ok", false)):
			if String(decode_result.get("error", "")).begins_with("BEAST_") or String(decode_result.get("error", "")).begins_with("SECT_") or String(decode_result.get("error", "")).begins_with("STORY_"):
				sect_decode_error.value = String(decode_result.error)
			return -1
		var decoded_state: GameState = decode_result["state"]
		return decoded_state.revision
	)
	if not bool(best.get("ok", false)):
		_load_error = "" if best.get("error") == "empty_storage" else String(best.get("error", "LOAD_FAILED"))
		if not String(sect_decode_error.value).is_empty(): _load_error = String(sect_decode_error.value)
		return null
	var decode_result: Dictionary = SaveCodec.decode(String(best["json"]))
	if not bool(decode_result.get("ok", false)):
		return null
	_envelope = decode_result["envelope"]
	if int(_envelope.schema_version) < SaveCodec.SCHEMA_VERSION:
		_ledger_original = String(best["json"])
	if int(_envelope.schema_version) == 2:
		_schema2_original = String(best["json"])
	var loaded_state: GameState = decode_result["state"]
	if content() != null and content().processing_catalog.get("version") == IslandProgression.SUPPLY_VERSION and (loaded_state.economy.get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION] or not loaded_state.resources.has("void_essence")):
		var prepared := IslandProgression.prepare_supply(content(), loaded_state)
		if not prepared.ok:
			_load_error = String(prepared.get("error", "SUPPLY_MIGRATION"))
			return null
		_supply_original = String(best["json"])
		loaded_state = prepared.state
		_supply_candidate = loaded_state
	if content() != null and SkillSystem.reconcile(content(), loaded_state):
		_skills_original = String(best["json"])
		loaded_state.revision += 1
	if TalentSystem.reconcile(loaded_state):
		_talents_original = String(best["json"])
		_talents_candidate = loaded_state
		loaded_state.revision += 1
	if loaded_state.pill_version < AlchemySystem.VERSION:
		_pills_original = String(best["json"])
		_pills_candidate = loaded_state
		loaded_state.pill_version = AlchemySystem.VERSION
		loaded_state.revision += 1
	if loaded_state.beast_version < BeastSystem.VERSION:
		_beasts_original = String(best["json"])
		_beasts_candidate = loaded_state
		loaded_state.beast_version = BeastSystem.VERSION
		loaded_state.revision += 1
	if loaded_state.sect_version < SectSystem.VERSION:
		_sect_original = String(best["json"])
		_sect_candidate = loaded_state
		loaded_state.sect_version = SectSystem.VERSION
		loaded_state.revision += 1
	if loaded_state.story_version < StoryProgress.VERSION:
		_story_original = String(best["json"])
		StoryProgress.migrate(loaded_state)
		_story_candidate = loaded_state
		loaded_state.revision += 1
	return loaded_state

static func _new_state() -> GameState:
	var content_obj: GameContent = content()
	if content_obj == null:
		return null
	var session: GameSession = GameSession.create_new_game(content_obj)
	return session.state

static func is_forced_reset() -> bool:
	return _forced_reset

static func consume_forced_reset() -> bool:
	var ret := _forced_reset
	_forced_reset = false
	return ret

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

static func commit_supply_startup() -> Dictionary:
	var candidate := current_state()
	if candidate == null: return {"ok": false, "error": "NO_STATE"}
	if not migration_pending(candidate): return {"ok": true, "committed": false}
	# Preserve the old settled cursor. Offline settlement happens after this commit.
	return save(candidate, envelope().duplicate(true))
