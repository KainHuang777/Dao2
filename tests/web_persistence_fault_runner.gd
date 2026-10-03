extends SceneTree
var failures: Array[String] = []
var checks := 0
class FaultAdapter extends StorageAdapter:
	var data := {}
	var fail_read := false
	var fail_write := ""
	func read(key: String) -> Dictionary:
		if fail_read:
			return {"ok": false, "error": "SecurityError"}
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if key == fail_write:
			return {"ok": false, "error": "QuotaExceededError"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	var a := FaultAdapter.new()
	SaveManager.configure(content, a)
	var s := GameSession.create_new_game(content)
	_check(SaveManager.save(s.state, _meta(1000)).ok, "first save")
	a.fail_read = true
	SaveManager.configure(content, a)
	_check(SaveManager.current_state() == null, "read denial refuses new game")
	_check(SaveManager.load_error() == "storage_read_failed", "read error explicit")
	_check(not SaveManager.save(s.state, _meta(2000)).ok, "read denial prevents overwrite")
	a.fail_read = false
	SaveManager.configure(content, a)
	_check(SaveManager.current_state() != null, "recovered reads")
	# Same revision, advancing cursor, interrupted index update.
	a.fail_write = SaveSlots.INDEX_KEY
	_check(not SaveManager.save(s.state, _meta(2000)).ok, "index failure surfaced")
	a.fail_write = ""
	SaveManager.configure(content, a)
	_check(SaveManager.current_state() != null, "complete unindexed snapshot recovers")
	_check(SaveManager.last_settled_utc_ms() == 2000, "same revision selects newer cursor")
	_check(SaveManager.slots().active_slot() == SaveSlots.SLOT_BACKUP, "rotation adopts recovered slot")
	a.fail_write = SaveSlots.SLOT_MAIN
	_check(not SaveManager.save(s.state, _meta(3000)).ok, "next failed write targets old slot")
	_check(SaveCodec.decode(a.data[SaveSlots.SLOT_BACKUP]).envelope.settled_until_utc_ms == "2000", "recovered snapshot preserved")
	a.fail_write = ""
	_check(SaveManager.save(s.state, _meta(500)).ok, "online rollback save")
	_check(SaveManager.last_settled_utc_ms() == 2000, "online cursor never goes backward")
	a.data[SaveSlots.SLOT_MAIN] = "{broken"
	a.data[SaveSlots.SLOT_BACKUP] = "{broken"
	SaveManager.configure(content, a)
	_check(SaveManager.current_state() == null, "both corrupt refuses new game")
	_check(not SaveManager.save(s.state, _meta(4000)).ok, "corrupt data retained")
	# An existing migration archive must match the actual source bytes.
	a = FaultAdapter.new()
	var encoded := SaveCodec.encode(s.state, content.content_version, _meta(1000))
	var raw: Dictionary = JSON.parse_string(encoded.json)
	raw.schema_version = 2
	raw.state.erase("economy")
	raw.erase("checksum")
	raw.checksum = SaveCodec.compute_checksum(raw)
	var original := JSON.stringify(raw)
	a.data[SaveSlots.SLOT_MAIN] = original
	a.data[SaveManager.SCHEMA2_ARCHIVE_KEY] = "different original"
	SaveManager.configure(content, a)
	var legacy := SaveManager.current_state()
	_check(legacy != null, "archive conflict fixture loads")
	_check(SaveManager.save(legacy, _meta(2000)).error == "MIGRATION_ARCHIVE_READBACK", "conflicting existing archive blocks migration")
	_check(a.data[SaveSlots.SLOT_MAIN] == original, "archive conflict preserves source bytes")
	a.data[SaveManager.SCHEMA2_ARCHIVE_KEY] = original
	_check(SaveManager.save(legacy, _meta(2000)).ok, "matching archive permits retry")
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: Web persistence fault core %d checks." % checks)
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)

func _meta(cursor: int) -> Dictionary:
	return {"save_id":"fault_core", "saved_at_utc_ms":str(cursor), "settled_until_utc_ms":str(cursor), "sim_tick":"0"}
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
