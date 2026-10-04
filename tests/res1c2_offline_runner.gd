extends SceneTree
var checks := 0
var failures: Array[String] = []
var callbacks := 0
var serial := 0
const META := {"save_id": "c2", "saved_at_utc_ms": "100000", "settled_until_utc_ms": "100000", "sim_tick": "0"}
class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		if fail:
			return {"ok": false, "error": "quota"}
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}
func _init() -> void:
	call_deferred("_run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
func snapshot(state: GameState) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(state.to_snapshot_dict()), "", true)
func send(s: GameSession, kind: String, payload: Dictionary = {}) -> void:
	serial += 1
	expect(s.submit({"command_id": "c2-" + str(serial), "expected_revision": s.state.revision, "type": kind, "payload": payload}).ok, kind + str(payload))
func _run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var s := GameSession.new()
	s.content = content
	s.state = SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json")).state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	send(s, "activate_islands")
	for id in ["wood", "ore"]:
		send(s, "open_island", {"island_id": id})
	for id in ["wood_ore", "ore_wood", "timber_home", "bronze_home"]:
		send(s, "configure_route", {"route_id": id})
	s.advance_time(30)
	for id in ["wood", "ore"]:
		send(s, "craft", {"island_id": id, "recipe_id": IslandProgression.RECIPES[id], "repeat": true})
	var fixture_meta := META.duplicate(true)
	var fixture_now := int(Time.get_unix_time_from_system() * 1000.0) - 172800000
	fixture_meta.saved_at_utc_ms = str(fixture_now)
	fixture_meta.settled_until_utc_ms = str(fixture_now)
	var fixture := FileAccess.open("res://docs/verification/artifacts/res1-c2-offline-fixture.json", FileAccess.WRITE)
	fixture.store_string(SaveCodec.encode(s.state, content.content_version, fixture_meta).json)
	fixture.close()
	expect(SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-offline-fixture.json")).ok, "actual serialized fixture checksum roundtrip")
	for duration in [600000, 172800000, -1000, 850]:
		var direct := s.state.duplicate_state()
		var chunked := s.state.duplicate_state()
		direct.tick_remainder_seconds = 0.4
		chunked.tick_remainder_seconds = 0.4
		var expected := OfflineSettlement.settle(direct, content, 100000 + duration, 100000)
		callbacks = 0
		var actual := await OfflineCoordinator.compute_async(chunked, content, 100000 + duration, 100000, self, func(_done: int, _planned: int): callbacks += 1)
		expect(snapshot(direct) == snapshot(chunked), "chunk state equality " + str(duration))
		expect(expected == actual, "report equality " + str(duration))
		if duration >= 600000:
			expect(callbacks > 1, "multiple frame yields " + str(duration))
		print("C2_CHUNKS: duration_ms=", duration, " yields=", callbacks)
	var adapter := MemoryAdapter.new()
	SaveManager.configure(content, adapter)
	expect(SaveManager.save(s.state, META).ok, "source saved")
	var before := snapshot(s.state)
	var original := adapter.data.duplicate(true)
	adapter.fail = true
	var failed := await OfflineCoordinator.settle_state_async(s.state, content, 700000, 100000, self)
	expect(not failed.ok and not failed.committed, "failed commit explicit")
	expect(snapshot(s.state) == before and adapter.data == original, "failed commit preserves source and slots")
	adapter.fail = false
	var retry := await OfflineCoordinator.settle_state_async(s.state, content, 700000, 100000, self)
	expect(retry.ok and retry.committed, "retry commits")
	expect(snapshot(s.state) == before, "caller source unchanged even on success")
	var loaded: GameState = SaveManager.load_state()
	expect(snapshot(loaded) == snapshot(retry.state) and SaveManager.last_settled_utc_ms() == 700000, "resources cargo jobs and cursor atomic")
	var again := await OfflineCoordinator.settle_state_async(loaded, content, 700000, 700000, self)
	expect(again.state.economy == loaded.economy and again.state.total_elapsed_seconds == loaded.total_elapsed_seconds, "reload no double settlement")
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-C2 chunked settlement ", checks, " checks")
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)
