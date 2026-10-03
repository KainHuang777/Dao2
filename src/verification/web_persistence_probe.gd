extends Node
## Exported only by WebPersistenceTest. DOM is a test report, never gameplay UI.
var checks := 0
var failures: Array[String] = []
var adapter: WebStorageAdapter
var content: GameContent
var scenario := ""

func _ready() -> void:
	if not OS.has_feature("persistence_verification"):
		return
	scenario = str(_js("new URLSearchParams(location.search).get('case') || 'retry'"))
	adapter = WebStorageAdapter.new("dao2_matrix_" + scenario)
	var status := adapter.begin_session()
	while status == "pending":
		await get_tree().process_frame
		status = adapter.session_status()
	if scenario == "lock":
		if status == "writer_busy":
			_check(not adapter.write("unauthorized", "bad").ok, "second tab cannot write")
			_finish("SECOND TAB BLOCKED")
			return
		_check(status == "ready", "first tab owns exclusive lock")
		_finish("FIRST TAB OWNS LOCK")
		return
	_check(status == "ready", "exclusive lock acquired")
	if status != "ready":
		_finish()
		return
	content = ContentLoader.load_directory("res://content").content
	content.processing_catalog = ProcessingCatalog.load_file().catalog
	content.content_version += "+res1-b-1"
	SaveManager.configure(content, adapter)
	match scenario:
		"reload": _reload_case()
		"retry": _retry_case()
		"corrupt": _corrupt_case()
		"denied": _denied_case()
		"migration": _migration_case()
		"cap": _cap_case()
		"actualquota": _actual_quota_case()
		_: _check(false, "unknown case")
	_finish()

func _seed() -> GameSession:
	SaveSlots.new(adapter).reset()
	SaveManager.configure(content, adapter)
	var s := GameSession.create_new_game(content)
	s.state.era_id = 3
	s.state.buildings = {"hut": 2, "stone_mine": 3}
	for id in content.processing_catalog.resources:
		s.state.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
	_check(_command(s, "migrate_processing", {}, "migrate").ok, "migrate economy")
	IslandEconomy._put(s.state, "home", "wood", 100)
	IslandEconomy._put(s.state, "home", "stone_low", 100)
	_check(_command(s, "open_island", {"island_id": "wood"}, "open").ok, "open wood island")
	IslandEconomy._put(s.state, "wood", "wood", 40)
	IslandEconomy._put(s.state, "wood", "stone_low", 20)
	_check(_command(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber", "repeat": true}, "job").ok, "start processing")
	_check(_command(s, "configure_route", {"route_id": "timber_home"}, "route").ok, "configure transport")
	TimeAdvancer.advance(s.state, content, 17)
	_check(SaveManager.save(s.state, _meta(1000)).ok, "seed committed")
	return s

func _reload_case() -> void:
	if not adapter.exists("expected"):
		var s := _seed()
		var expected := s.state.duplicate_state()
		OfflineSettlement.settle(expected, content, 601000, 1000)
		expected.revision += 1
		_check(adapter.write("expected", _hash(expected)).ok, "expected persisted")
		_check(adapter.write("phase", "seed").ok, "seed phase persisted")
		_report("SEED SAVED: reload this page", {})
		return
	var current := SaveManager.current_state()
	_check(current != null, "reload decodes snapshot")
	if current == null:
		return
	if adapter.read("phase").data == "seed":
		_check(int(current.economy.tick) == 17, "in-flight state persisted")
		var s := GameSession.new()
		s.state = current
		s.content = content
		_check(_command(s, "craft", {}, "job").get("duplicate", false), "command receipt persisted")
		var result := OfflineCoordinator.settle(601000)
		_check(result.ok, "offline commit after reload")
		_check(_hash(result.state) == adapter.read("expected").data, "complete state matches expected")
		adapter.write("phase", "settled")
	else:
		_check(_hash(current) == adapter.read("expected").data, "settled state survives second reload")
		_check(SaveManager.last_settled_utc_ms() == 601000, "cursor persisted")
		_check(OfflineCoordinator.settle(601000).report.effective_ticks == 0, "zero repeated rewards")

func _retry_case() -> void:
	for fault in ["quota", "security", "readback", "index", "truncate"]:
		var s := _seed()
		var before := _hash(s.state)
		var expected := s.state.duplicate_state()
		OfflineSettlement.settle(expected, content, 601000, 1000)
		expected.revision += 1
		_fault(fault)
		var failed := OfflineCoordinator.settle(601000)
		_check(not failed.ok, fault + " commit rejected")
		_check(_hash(SaveManager.current_state()) == before, fault + " keeps source state")
		_check(SaveManager.last_settled_utc_ms() == 1000, fault + " keeps cursor")
		_fault("")
		# Restart after a partial commit must recover the whole new snapshot if valid.
		SaveManager.configure(content, adapter)
		var recovered := SaveManager.current_state()
		var already_committed := _hash(recovered) == _hash(expected)
		_check(already_committed or _hash(recovered) == before, fault + " recovery is whole old or new state")
		var retry := OfflineCoordinator.settle(601000)
		_check(retry.ok, fault + " retry succeeds")
		var snapshot: Dictionary = retry.state.to_snapshot_dict()
		snapshot.revision = expected.revision
		_check(SaveCodec.compute_checksum(snapshot) == _hash(expected), fault + " exactly one reward")
		_check(OfflineCoordinator.settle(601000).report.effective_ticks == 0, fault + " immediate reload grants zero")
	# In-memory live background retry uses the exact same coordinator.
	var live := _seed()
	var hash_before := _hash(live.state)
	_fault("quota")
	_check(not OfflineCoordinator.settle_state(live.state, content, 601000, 1000).ok, "background failure")
	_check(_hash(live.state) == hash_before, "background source unchanged")
	_fault("")
	_check(OfflineCoordinator.settle_state(live.state, content, 601000, 1000).ok, "background retry succeeds")

func _corrupt_case() -> void:
	var s := _seed()
	var original := _hash(s.state)
	s.state.revision += 1
	_check(SaveManager.save(s.state, _meta(2000)).ok, "second generation")
	var latest := SaveManager.slots().active_slot()
	adapter.write(latest, "{broken")
	SaveManager.configure(content, adapter)
	_check(_hash(SaveManager.current_state()) == original, "corrupt latest recovers predecessor")
	adapter.write(SaveSlots.SLOT_MAIN, "{broken")
	adapter.write(SaveSlots.SLOT_BACKUP, "{broken")
	SaveManager.configure(content, adapter)
	_check(SaveManager.current_state() == null, "both corrupt never becomes a new game")
	_check(not SaveManager.save(s.state, _meta(2000)).ok, "untrusted load refuses overwrite")

func _denied_case() -> void:
	var s := _seed()
	var original: String = adapter.read(SaveSlots.SLOT_MAIN).data
	_fault("deny_read")
	SaveManager.configure(content, adapter)
	_check(SaveManager.current_state() == null, "SecurityError read cannot become missing/new game")
	_check(SaveManager.load_error() == "storage_read_failed", "read error is explicit")
	_check(not SaveManager.save(s.state, _meta(2000)).ok, "denied load cannot overwrite progress")
	_fault("")
	_check(adapter.read(SaveSlots.SLOT_MAIN).data == original, "stored bytes unchanged")
	SaveManager.configure(content, adapter)
	_check(SaveManager.current_state() != null, "reload after permission recovery")

func _migration_case() -> void:
	SaveSlots.new(adapter).reset()
	var s := GameSession.create_new_game(content)
	var encoded := SaveCodec.encode(s.state, content.content_version, _meta(1000))
	var raw: Dictionary = JSON.parse_string(encoded.json)
	raw.schema_version = 2
	raw.state.erase("economy")
	raw.erase("checksum")
	raw.checksum = SaveCodec.compute_checksum(raw)
	var legacy := JSON.stringify(raw)
	_check(SaveCodec.decode(legacy).ok, "schema2 fixture valid")
	adapter.write(SaveSlots.SLOT_MAIN, legacy)
	SaveManager.configure(content, adapter)
	var loaded := SaveManager.current_state()
	_check(loaded != null, "schema2 loaded")
	if loaded == null:
		return
	_fault("archive")
	_check(not SaveManager.save(loaded, _meta(2000)).ok, "archive failure blocks migration")
	_fault("")
	_check(adapter.read(SaveSlots.SLOT_MAIN).data == legacy, "schema2 original untouched")
	_check(SaveManager.save(loaded, _meta(2000)).ok, "migration retry")
	_check(adapter.read(SaveManager.SCHEMA2_ARCHIVE_KEY).data == legacy, "original bytes archived")

func _cap_case() -> void:
	var s := _seed()
	var expected := s.state.duplicate_state()
	OfflineSettlement.settle(expected, content, 172801000, 1000)
	expected.revision += 1
	var result := OfflineCoordinator.settle(172801000)
	_check(result.ok, "48h commit")
	_check(result.report.cap_applied and result.report.effective_ms == 86400000, "24h cap explicit")
	_check(_hash(result.state) == _hash(expected), "full state and age match capped policy")
	SaveManager.configure(content, adapter)
	_check(OfflineCoordinator.settle(172801000).report.effective_ticks == 0, "forfeited day cannot be reclaimed")
	_check(OfflineCoordinator.settle(1000).report.rollback, "clock rollback reports zero")
	_check(SaveManager.last_settled_utc_ms() == 172801000, "rollback cursor never retreats")
	_check(SaveManager.save(SaveManager.current_state(), _meta(1000)).ok, "online save with rollback")
	_check(SaveManager.last_settled_utc_ms() == 172801000, "online save preserves high cursor")

func _actual_quota_case() -> void:
	var s := _seed()
	var before := _hash(s.state)
	var filled := str(_js("""(function(){
		let n=0; try { for(; n<64; n++) localStorage.setItem('dao2_matrix_fill:'+n,'x'.repeat(262144)); } catch(e) {}
		try { for(let m=0; m<512; m++) localStorage.setItem('dao2_matrix_small:'+m,'x'.repeat(1024)); } catch(e) { return e.name; }
		return 'quota_not_reached';
	})()"""))
	_check(filled == "QuotaExceededError", "actual browser storage quota reached")
	var result := OfflineCoordinator.settle(601000)
	_check(not result.ok and result.get("detail") == "QuotaExceededError", "actual quota rejects snapshot")
	_check(_hash(SaveManager.current_state()) == before, "actual quota keeps state")
	_check(SaveManager.last_settled_utc_ms() == 1000, "actual quota keeps cursor")
	_js("Object.keys(localStorage).filter(k=>k.startsWith('dao2_matrix_fill:') || k.startsWith('dao2_matrix_small:')).forEach(k=>localStorage.removeItem(k))")
	_check(OfflineCoordinator.settle(601000).ok, "retry after freeing disposable test filler")
	_check(OfflineCoordinator.settle(601000).report.effective_ticks == 0, "no double quota retry grant")

func _fault(kind: String) -> void:
	# Test-only Storage prototype interception exercises the production adapter.
	_js("window.dao2Fault = " + JSON.stringify(kind))

func _command(s: GameSession, kind: String, payload: Dictionary, id: String) -> Dictionary:
	return s.submit({"type": kind, "payload": payload, "command_id": id, "expected_revision": s.state.revision})

func _meta(cursor: int) -> Dictionary:
	return {"save_id": "web_matrix", "saved_at_utc_ms": str(cursor), "settled_until_utc_ms": str(cursor), "sim_tick": "0"}

func _hash(s: GameState) -> String:
	return SaveCodec.compute_checksum(s.to_snapshot_dict()) if s != null else "NULL"

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func _finish(note: String = "") -> void:
	_report("PASS" if failures.is_empty() else "FAIL", {"case": scenario, "checks": checks, "failures": failures, "note": note})

func _report(status: String, details: Dictionary) -> void:
	if scenario == "reload" and adapter.read("phase").get("data") == "seed" and details.is_empty():
		pass
	_js("document.getElementById('report').textContent = " + JSON.stringify(status + "\n" + JSON.stringify(details, "  ")))
	print("WEB_MATRIX: ", status, " ", JSON.stringify(details))

func _js(script: String) -> Variant:
	return Engine.get_singleton("JavaScriptBridge").eval(script)
