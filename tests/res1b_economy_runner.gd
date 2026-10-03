extends SceneTree

var failures: Array[String] = []
var checks := 0
var catalog: Dictionary
var serial := 0
const META := {"save_id": "res1b_test", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail_key := ""
	var truncate_key := ""
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		if key == fail_key:
			return {"ok": false, "error": "injected quota/interruption"}
		data[key] = payload.left(8) if key == truncate_key else payload
		return {"ok": true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	catalog = ProcessingCatalog.load_file().catalog
	_test_migration()
	_test_jobs()
	_test_switch_and_reservations()
	_test_routes()
	_test_time()
	_test_persistence()
	_test_reincarnation()
	if failures.is_empty():
		print("PASS: RES1-B %d checks; timed batches, local inventory, cargo conservation, time, migration, offline retry, reincarnation." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func _session(migrate: bool = true) -> GameSession:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	content.processing_catalog = catalog.duplicate(true)
	content.content_version += "+res1-b-1"
	var session := GameSession.create_new_game(content)
	session.state.era_id = 3
	session.state.buildings = {"hut": 2, "stone_mine": 3, "herb_farm": 3}
	for id in catalog.resources:
		session.state.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
	if migrate:
		_expect(_send(session, "migrate_processing").ok, "migration command")
	return session

func _send(s: GameSession, kind: String, payload: Dictionary = {}, id: String = "") -> Dictionary:
	serial += 1
	return s.submit({"command_id": id if not id.is_empty() else "b-" + str(serial), "type": kind, "expected_revision": s.state.revision, "payload": payload})

func _put(s: GameSession, id: String, amount: float, island: String = "home") -> void:
	IslandEconomy._put(s.state, island, id, amount)

func _v(s: GameSession, id: String, island: String = "home") -> float:
	return IslandEconomy.value(s.state, island, id)

func _snap(s: GameSession) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(s.state.to_snapshot_dict()), "", true)

func _reject(s: GameSession, kind: String, p: Dictionary, error: String) -> void:
	var before := _snap(s)
	var r := _send(s, kind, p)
	_expect(not r.ok and r.error == error, "reject " + error + ": " + str(r))
	_expect(_snap(s) == before, "rejection atomic " + error)

func _open(s: GameSession, island: String) -> void:
	_put(s, "wood", 100)
	_put(s, "stone_low", 100)
	_expect(_send(s, "open_island", {"island_id": island}).ok, "open " + island)

func _test_migration() -> void:
	var s := _session(false)
	_put(s, "wood", 123)
	s.state.realms_data = {"realm_spirit": {"lingjing": 77.0}}
	var before := _snap(s)
	var preview := IslandEconomy.migration_preview(s.state, catalog)
	_expect(preview.ok and _snap(s) == before, "migration preview is read only")
	_expect(_send(s, "migrate_processing", {}, "migration").ok, "migrate once")
	_expect(_v(s, "wood") == 123 and s.state.economy.islands.home.inventory.is_empty(), "old stock aliases home once")
	_expect(s.state.realms_data.realm_spirit.lingjing == 77 and int(s.state.buildings.hut) == 2, "realm and buildings preserved")
	_expect(_send(s, "migrate_processing", {}, "migration").duplicate, "migration replay")
	_reject(s, "migrate_processing", {}, "ALREADY_MIGRATED")
	s.state.era_id = 1
	_reject(s, "open_island", {"island_id": "wood"}, "ERA_REQUIREMENT")
	s = _session(false)
	s.state.pills.foundation_pill = 2
	_reject(s, "migrate_processing", {}, "INVENTORY_CONFLICT")
	s = _session(false)
	s.state.resources.wood.value = AmountCompat.try_parse("ee20").value
	_reject(s, "migrate_processing", {}, "UNSUPPORTED_AMOUNT")

func _test_jobs() -> void:
	var s := _session()
	var p := {"recipe_id": "spirit_timber"}
	_reject(s, "craft", p, "INSUFFICIENT_RESOURCE")
	_put(s, "wood", 30)
	_put(s, "stone_low", 15)
	_put(s, "spirit_timber", 1000000)
	_reject(s, "craft", p, "OUTPUT_FULL")
	_put(s, "spirit_timber", 999999)
	_expect(_send(s, "craft", p, "job").ok, "reserve final output slot")
	_expect(_v(s, "wood") == 20 and _v(s, "spirit_timber") == 999999, "deduct inputs at start, no early output")
	_expect(IslandEconomy.reserved(s.state, "home", "spirit_timber", catalog) == 1, "output reserved")
	var before := _snap(s)
	_expect(_send(s, "craft", p, "job").duplicate and _snap(s) == before, "job command replay no second charge")
	_reject(s, "craft", p, "JOB_BUSY")
	_expect(_send(s, "stop_processing").ok, "stop at batch boundary")
	TimeAdvancer.advance(s.state, s.content, 9)
	_expect(_v(s, "spirit_timber") == 999999, "nine seconds not complete")
	TimeAdvancer.advance(s.state, s.content, 1)
	_expect(_v(s, "spirit_timber") == 1000000 and s.state.economy.jobs.is_empty(), "complete exact cap once after stop")
	s = _session()
	_put(s, "wood", 30)
	_put(s, "stone_low", 15)
	_expect(_send(s, "craft", {"recipe_id": "spirit_timber", "count": 3, "reserves": {"wood": "10"}}).ok, "three batches with reserve")
	TimeAdvancer.advance(s.state, s.content, 30)
	_expect(_v(s, "spirit_timber") == 2 and _v(s, "wood") == 10, "reserve prevents third batch without loss")
	_expect(s.state.economy.jobs.home.status == "INSUFFICIENT_RESOURCE", "waiting job reports shortage")
	_put(s, "wood", 20)
	TimeAdvancer.advance(s.state, s.content, 11)
	_expect(_v(s, "spirit_timber") == 3 and s.state.economy.jobs.is_empty(), "waiting resumes once supplied")
	s = _session()
	_open(s, "wood")
	_put(s, "wood", 10, "wood")
	_put(s, "stone_low", 100)
	_reject(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber"}, "INSUFFICIENT_RESOURCE")
	_put(s, "stone_low", 5, "wood")
	_expect(_send(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber"}).ok, "local inputs required")
	TimeAdvancer.advance(s.state, s.content, 10)
	_expect(_v(s, "spirit_timber", "wood") == 1 and _v(s, "spirit_timber") == 0, "remote output stays remote")
	for bad in [0, -1, 1.5, "2", true, 1000001]:
		s = _session()
		_reject(s, "craft", {"recipe_id": "liquid", "count": bad}, "INVALID_COUNT")

func _test_routes() -> void:
	var s := _session()
	_open(s, "wood")
	_open(s, "ore")
	_put(s, "wood", 100, "wood")
	_put(s, "wood", 95, "ore")
	_expect(_send(s, "configure_route", {"route_id": "wood_ore", "target": "100", "reserve": "20"}).ok, "fixed route")
	IslandEconomy.tick(s.state, catalog)
	_expect(_v(s, "wood", "wood") == 95 and float(s.state.economy.trips.wood_ore.cargo) == 5, "departure subtracts cargo limited by destination")
	_expect(IslandEconomy.reserved(s.state, "ore", "wood", catalog) == 5, "trip reserves capacity")
	_expect(_v(s, "wood", "wood") + _v(s, "wood", "ore") + float(s.state.economy.trips.wood_ore.cargo) == 195, "departure conservation; full producer adds zero")
	_expect(_send(s, "configure_route", {"route_id": "wood_ore", "enabled": false}).ok, "disable in transit")
	for i in range(10):
		IslandEconomy.tick(s.state, catalog)
	_expect(_v(s, "wood", "ore") == 100 and s.state.economy.trips.is_empty(), "disabled route still delivers reserved cargo")
	for level in [1, 2]:
		s = _session()
		_open(s, "wood")
		_open(s, "ore")
		_put(s, "wood", 100, "wood")
		_expect(_send(s, "configure_route", {"route_id": "wood_ore", "target": "100", "level": level}).ok, "route level " + str(level))
		for i in range(21):
			IslandEconomy.tick(s.state, catalog)
		_expect(_v(s, "wood", "ore") == 20 * level, "actual throughput level " + str(level))
		_expect(IslandEconomy.validate(s.state).is_empty(), "trip/job reservations valid")

func _test_switch_and_reservations() -> void:
	var s := _session()
	_reject(s, "refine_pill", {"pill_id": "foundation_pill", "count": 1.5}, "INVALID_COUNT")
	_reject(s, "consume_pill", {"pill_id": "foundation_pill", "count": 1.5}, "INVALID_COUNT")
	_put(s, "foundation_pill", 10000000000)
	_expect(_send(s, "consume_pill", {"pill_id": "foundation_pill"}).ok, "consume migrated large layer-zero pill stock")
	_expect(_v(s, "foundation_pill") == 9999999999 and int(s.state.pills.foundation_pill) == 9999999999, "one authoritative pill delta without legacy clamp loss")
	s = _session()
	_put(s, "wood", 20)
	_put(s, "stone_low", 15)
	_put(s, "black_copper", 10)
	_expect(_send(s, "craft", {"recipe_id": "spirit_timber", "repeat": true}).ok, "switch starts original batch")
	for _i in range(3):
		IslandEconomy.tick(s.state, catalog)
	_expect(_send(s, "switch_processing", {"recipe_id": "bronze_essence"}).ok, "switch queued")
	_expect(_v(s, "black_copper") == 10 and _v(s, "wood") == 10, "queued switch neither refunds nor precharges")
	var restored := SaveCodec.decode(_encode(s))
	_expect(restored.ok, "pending switch persists")
	if restored.ok:
		s.state = restored.state
	for _i in range(7):
		IslandEconomy.tick(s.state, catalog)
	_expect(_v(s, "spirit_timber") == 1 and _v(s, "black_copper") == 0 and s.state.economy.jobs.home.recipe_id == "bronze_essence", "switch only after original completion")
	for _i in range(10):
		IslandEconomy.tick(s.state, catalog)
	_expect(_v(s, "bronze_essence") == 1 and s.state.economy.jobs.is_empty(), "next recipe completes once")
	# A job and a route compete for the same destination slot.
	for first in ["job", "trip"]:
		s = _session()
		_open(s, "wood")
		_put(s, "spirit_timber", 999999)
		_put(s, "spirit_timber", 5, "wood")
		_expect(_send(s, "configure_route", {"route_id": "timber_home", "target": "1000000"}).ok, "capacity conflict route")
		if first == "job":
			_expect(_send(s, "craft", {"recipe_id": "spirit_timber"}).ok, "job claims slot first")
			IslandEconomy.tick(s.state, catalog)
			_expect(s.state.economy.trips.is_empty(), "route cannot double reserve job slot")
		else:
			IslandEconomy.tick(s.state, catalog)
			_reject(s, "craft", {"recipe_id": "spirit_timber"}, "OUTPUT_FULL")
		_expect(IslandEconomy.reserved(s.state, "home", "spirit_timber", catalog) == 1, "one reservation " + first)

func _chain() -> GameSession:
	var s := _session()
	_open(s, "wood")
	_open(s, "ore")
	_put(s, "wood", 40, "wood")
	_put(s, "stone_low", 20, "wood")
	_put(s, "black_copper", 40, "ore")
	_put(s, "stone_low", 20, "ore")
	for route in ["wood_ore", "ore_wood", "timber_home", "bronze_home"]:
		_expect(_send(s, "configure_route", {"route_id": route}).ok, "chain route " + route)
	_expect(_send(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber", "repeat": true}).ok, "repeat timber")
	_expect(_send(s, "craft", {"island_id": "ore", "recipe_id": "bronze_essence", "repeat": true}).ok, "repeat bronze")
	return s

func _test_time() -> void:
	var a := _chain()
	var b := GameSession.new()
	b.content = a.content
	b.state = a.state.duplicate_state()
	_expect(TimeAdvancer.advance(a.state, a.content, 600).ticks_advanced == 600, "600 seconds")
	for n in [1, 9, 57, 133, 400]:
		TimeAdvancer.advance(b.state, b.content, n)
	_expect(_snap(a) == _snap(b), "600 once equals irregular partitions including weather boundaries")
	_expect(_v(a, "spirit_timber") > 0 and _v(a, "bronze_essence") > 0, "chain arrives home")
	var c := _chain()
	var offline := c.state.duplicate_state()
	OfflineSettlement.settle(offline, c.content, 601000, 1000)
	TimeAdvancer.advance(c.state, c.content, 600)
	_expect(JSON.stringify(SaveCodec._normalize_numbers(offline.to_snapshot_dict()), "", true) == _snap(c), "offline same 600 seconds")
	c = _chain()
	var lifespan := Lifespan.max_lifespan_seconds(c.content.era_lifespan_entries(), c.state.era_id)
	c.state.total_elapsed_seconds = lifespan - 3
	_expect(TimeAdvancer.advance(c.state, c.content, 100).ticks_advanced == 3, "lifespan clips processing")
	var before := _snap(c)
	_expect(TimeAdvancer.advance(c.state, c.content, 10).ticks_advanced == 0 and _snap(c) == before, "exhaustion freezes jobs and cargo")
	c = _chain()
	var e_before := SaveCodec.compute_checksum(c.state.economy)
	TimeAdvancer.advance_time_only(c.state, c.content, 600)
	_expect(SaveCodec.compute_checksum(c.state.economy) == e_before, "forfeited age-only time gives no processing or shipping rewards")
	c = _session()
	var report: Dictionary = OfflineSettlement.settle(c.state, c.content, 172801000, 1000).report
	_expect(report.cap_applied and report.effective_ticks == 86400 and report.time_only_ticks == 86400, "48h economy settlement plans only first 24h rewards")

func _encode(s: GameSession) -> String:
	var encoded := SaveCodec.encode(s.state, s.content.content_version, META)
	_expect(encoded.ok, "valid economy encodes: " + str(encoded.get("error")))
	return encoded.get("json", "")

func _test_persistence() -> void:
	var s := _chain()
	TimeAdvancer.advance(s.state, s.content, 7)
	var raw := _encode(s)
	var decoded := SaveCodec.decode(raw)
	_expect(decoded.ok, "decode active jobs and cargo")
	if decoded.ok:
		_expect(JSON.stringify(SaveCodec._normalize_numbers(decoded.state.to_snapshot_dict()), "", true) == _snap(s), "exact active roundtrip")
		var copy: GameState = decoded.state
		TimeAdvancer.advance(copy, s.content, 593)
		TimeAdvancer.advance(s.state, s.content, 593)
		_expect(JSON.stringify(SaveCodec._normalize_numbers(copy.to_snapshot_dict()), "", true) == _snap(s), "reload remaining times equal uninterrupted")
	for mode in ["recipe", "route", "overflow", "negative", "version", "fractional_tick"]:
		var env: Dictionary = JSON.parse_string(raw)
		match mode:
			"recipe": env.state.economy.jobs.wood.recipe_version = 99
			"route": env.state.economy.routes.ghost = env.state.economy.routes.wood_ore
			"overflow": env.state.economy.islands.ore.inventory.wood = "100"
			"negative": env.state.economy.trips.wood_ore.cargo = "-1"
			"version": env.state.economy.version = "future"
			"fractional_tick": env.state.economy.trips.wood_ore.remaining = 1.000001
		env.erase("checksum")
		env.checksum = SaveCodec.compute_checksum(env)
		_expect(not SaveCodec.decode(JSON.stringify(env)).ok, "reject malformed/unknown " + mode)
	# Preserve schema 2 bytes before schema 3 commit; failure never advances in-memory state.
	s = _session(false)
	var old: Dictionary = JSON.parse_string(_encode(s))
	old.schema_version = 2
	old.rules_version = "core-flow-5-session-receipts"
	old.state.erase("economy")
	old.erase("checksum")
	old.checksum = SaveCodec.compute_checksum(old)
	var original := JSON.stringify(old)
	_expect(SaveCodec.migration_preview(original).ok, "schema2 migration preview")
	var adapter := MemoryAdapter.new()
	var slots := SaveSlots.new(adapter)
	_expect(slots.commit(original, s.state.revision).ok, "seed isolated old slot")
	SaveManager.configure(s.content, adapter)
	var restored: GameState = SaveManager.current_state()
	_expect(restored.economy.is_empty(), "schema2 decode does not enable economy")
	s.state = restored
	_expect(_send(s, "migrate_processing").ok, "explicit activation after preview")
	adapter.fail_key = SaveManager.SCHEMA2_ARCHIVE_KEY
	_expect(not SaveManager.save(s.state, META).ok, "archive failure blocks migration commit")
	adapter.fail_key = ""
	_expect(SaveManager.save(s.state, META).ok, "migration retry")
	_expect(adapter.data[SaveManager.SCHEMA2_ARCHIVE_KEY] == original, "original schema2 bytes retained")
	# Offline atomic copy + cursor under payload, readback and index failures.
	for phase in ["payload", "readback", "index"]:
		s = _chain()
		adapter = MemoryAdapter.new()
		SaveManager.configure(s.content, adapter)
		_expect(SaveManager.save(s.state, META).ok, "seed " + phase)
		var before := _snap(s)
		var target := SaveSlots.SLOT_BACKUP
		if phase == "readback":
			adapter.truncate_key = target
		else:
			adapter.fail_key = SaveSlots.INDEX_KEY if phase == "index" else target
		var failed := OfflineCoordinator.settle(601000)
		_expect(not failed.ok and not failed.committed, "offline failure " + phase)
		_expect(_snap(s) == before and SaveManager.last_settled_utc_ms() == 1000, "failure retains original and cursor " + phase)
		adapter.fail_key = ""
		adapter.truncate_key = ""
		var retry := OfflineCoordinator.settle(601000)
		_expect(retry.ok and retry.committed, "offline retry " + phase)
		var expected: GameState = s.state.duplicate_state()
		TimeAdvancer.advance(expected, s.content, 600)
		expected.revision += 1
		_expect(JSON.stringify(SaveCodec._normalize_numbers(expected.to_snapshot_dict()), "", true) == JSON.stringify(SaveCodec._normalize_numbers(retry.state.to_snapshot_dict()), "", true), "no double settlement " + phase)
		SaveManager.configure(s.content, adapter)
		var loaded: GameState = SaveManager.current_state()
		var same := JSON.stringify(SaveCodec._normalize_numbers(loaded.to_snapshot_dict()), "", true)
		_expect(OfflineCoordinator.settle(601000).report.effective_ticks == 0, "reload cursor grants no second reward " + phase)
		_expect(JSON.stringify(SaveCodec._normalize_numbers(loaded.to_snapshot_dict()), "", true) == same, "loaded object unchanged by coordinator")
	# A torn index may leave a complete new payload: restart adopts its cursor atomically.
	s = _chain()
	adapter = MemoryAdapter.new()
	SaveManager.configure(s.content, adapter)
	_expect(SaveManager.save(s.state, META).ok, "seed interrupted index restart")
	adapter.fail_key = SaveSlots.INDEX_KEY
	_expect(not OfflineCoordinator.settle(601000).ok, "interrupt index")
	adapter.fail_key = ""
	SaveManager.configure(s.content, adapter)
	_expect(OfflineCoordinator.settle(601000).report.effective_ticks == 0, "restart accepts complete orphan snapshot without duplicate rewards")
	# Corrupt newest generation falls back to the earlier intact state + cursor.
	adapter.data[SaveManager.slots().active_slot()] = "broken"
	SaveManager.configure(s.content, adapter)
	_expect(not SaveManager.current_state().economy.is_empty(), "corruption restores earlier economy generation")
	SaveManager.reset_for_tests()

func _test_reincarnation() -> void:
	var s := _chain()
	TimeAdvancer.advance(s.state, s.content, 7)
	_put(s, "formation_core", 50)
	s.state.buildings.rebirth_lotus = 1
	_expect(_send(s, "reincarnate", {}, "rebirth").ok, "reincarnate with jobs and cargo")
	_expect(s.state.economy.jobs.is_empty() and s.state.economy.trips.is_empty() and not s.state.economy.islands.wood.opened, "clear industry per life")
	_expect(_v(s, "formation_core") == 0 and _v(s, "wood", "wood") == 0, "extra resources and remote stock cleared")
	_expect(_send(s, "reincarnate", {}, "rebirth").duplicate and s.state.reincarnation_count == 1, "rebirth receipt survives; no repeated reward")
	_expect(IslandEconomy.validate(s.state).is_empty(), "new life snapshot valid")
