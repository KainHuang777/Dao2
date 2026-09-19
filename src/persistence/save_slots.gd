class_name SaveSlots
extends RefCounted

const SLOT_MAIN := "save_main"
const SLOT_BACKUP := "save_backup"
const INDEX_KEY := "save_index"

var _adapter: StorageAdapter = null
var _active_slot: String = ""
var _commit_sequence: int = 0
var _revision: int = -1

func _init(adapter: StorageAdapter) -> void:
	_adapter = adapter
	_load_index()

func commit(json_text: String, revision: int) -> Dictionary:
	if json_text == "":
		return _commit_result(false, "empty_payload", _active_slot, _commit_sequence)
	var target: String = SLOT_BACKUP if _active_slot == SLOT_MAIN else SLOT_MAIN
	var write_result: Dictionary = _adapter.write(target, json_text)
	if not bool(write_result.get("ok", false)):
		return _commit_result(false, String(write_result.get("error", "write_failed")), _active_slot, _commit_sequence)
	var read_result: Dictionary = _adapter.read(target)
	if not bool(read_result.get("ok", false)):
		return _commit_result(false, String(read_result.get("error", "readback_failed")), _active_slot, _commit_sequence)
	if String(read_result.get("data", "")) != json_text:
		return _commit_result(false, "readback_mismatch", _active_slot, _commit_sequence)
	var next_sequence: int = _commit_sequence + 1
	var index_payload: Dictionary = {
		"commit_sequence": next_sequence,
		"active_slot": target,
		"revision": revision,
	}
	var index_result: Dictionary = _adapter.write(INDEX_KEY, JSON.stringify(index_payload))
	if not bool(index_result.get("ok", false)):
		return _commit_result(false, String(index_result.get("error", "index_write_failed")), _active_slot, _commit_sequence)
	_commit_sequence = next_sequence
	_active_slot = target
	_revision = revision
	return _commit_result(true, "", _active_slot, _commit_sequence)

func read_best(validator: Callable = Callable()) -> Dictionary:
	var best_json: String = ""
	var best_slot: String = ""
	var best_revision: int = -1
	var slots: Array[String] = [SLOT_MAIN, SLOT_BACKUP]
	for slot in slots:
		var read_result: Dictionary = _adapter.read(slot)
		if not bool(read_result.get("ok", false)):
			continue
		var data: String = String(read_result.get("data", ""))
		if data == "":
			continue
		var revision: int = -1
		if validator.is_valid():
			revision = int(validator.call(data))
		else:
			revision = _revision_from_json(data)
		if revision < 0:
			continue
		if revision > best_revision or (revision == best_revision and slot == _active_slot):
			best_revision = revision
			best_slot = slot
			best_json = data
	if best_revision < 0:
		return {"ok": false, "json": "", "slot": "", "revision": -1, "error": "no_valid_slot"}
	return {"ok": true, "json": best_json, "slot": best_slot, "revision": best_revision, "error": ""}

func active_slot() -> String:
	return _active_slot

func commit_sequence() -> int:
	return _commit_sequence

func reset() -> void:
	_adapter.erase(SLOT_MAIN)
	_adapter.erase(SLOT_BACKUP)
	_adapter.erase(INDEX_KEY)
	_active_slot = ""
	_commit_sequence = 0
	_revision = -1

func _load_index() -> void:
	_active_slot = ""
	_commit_sequence = 0
	_revision = -1
	var read_result: Dictionary = _adapter.read(INDEX_KEY)
	if not bool(read_result.get("ok", false)):
		return
	var parsed: Variant = JSON.parse_string(String(read_result.get("data", "")))
	if not (parsed is Dictionary):
		return
	var raw: Dictionary = parsed as Dictionary
	var slot: String = String(raw.get("active_slot", ""))
	if slot != SLOT_MAIN and slot != SLOT_BACKUP:
		return
	_active_slot = slot
	_commit_sequence = int(raw.get("commit_sequence", 0))
	_revision = int(raw.get("revision", -1))

func _revision_from_json(data: String) -> int:
	if not data.begins_with("{"):
		return -1
	var parsed: Variant = JSON.parse_string(data)
	if not (parsed is Dictionary):
		return -1
	var raw: Dictionary = parsed as Dictionary
	if not raw.has("revision"):
		return -1
	var value: Variant = raw.get("revision")
	if value is int:
		return value as int
	if value is float:
		return int(value)
	return -1

func _commit_result(success: bool, error_text: String, slot: String, sequence: int) -> Dictionary:
	return {
		"ok": success,
		"error": error_text,
		"active_slot": slot,
		"commit_sequence": sequence,
	}
