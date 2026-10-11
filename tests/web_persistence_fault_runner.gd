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
	func erase(key: String) -> Dictionary:
		data.erase(key)
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
	# A pre-v2 payload rescued into an occupied key blocks load until released.
	a = FaultAdapter.new()
	var encoded := SaveCodec.encode(s.state, content.content_version, _meta(1000))
	var raw: Dictionary = JSON.parse_string(encoded.json)
	raw.schema_version = 3
	raw.state.erase("economy")
	raw.erase("checksum")
	raw.checksum = SaveCodec.compute_checksum(raw)
	var original := JSON.stringify(raw)
	a.data[SaveSlots.SLOT_MAIN] = original
	a.data[SaveManager.SAVE_PRE_V2_RESCUE_KEY] = "occupied"
	a.fail_write = SaveManager.SAVE_PRE_V2_RESCUE_KEY
	SaveManager.configure(content, a)
	_check(SaveManager.current_state() == null and SaveManager.load_error() == "LOAD_FAILED", "occupied rescue archive blocks quarantine release")
	a.fail_write = ""
	a.erase(SaveManager.SAVE_PRE_V2_RESCUE_KEY)
	var recovered: GameState = SaveManager.current_state()
	_check(recovered != null and recovered.economy.is_empty(), "rescue recovers blank state and forced reset")
	_check(SaveManager.consume_forced_reset(), "forced reset consumed after quarantine release")
	_check(String(a.data.get(SaveManager.SAVE_PRE_V2_RESCUE_KEY, "")) == original, "rescue archive preserves exact pre-v2 fixture bytes")
	_check(String(a.data.get(SaveSlots.SLOT_MAIN, "")) == "" and String(a.data.get(SaveSlots.SLOT_BACKUP, "")) == "", "rescue release wipes both save slots")
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
