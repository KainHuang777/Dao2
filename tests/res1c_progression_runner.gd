extends SceneTree
## Blank-save player-command flow, real T2 sinks and migration retry isolation.
var checks := 0
var failures: Array[String] = []
var serial := 0
const META := {"save_id": "res1c", "saved_at_utc_ms": "100000", "settled_until_utc_ms": "100000", "sim_tick": "0"}

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var fail_key := ""
	var fail_write_number := -1
	var writes := 0
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		writes += 1
		if key == fail_key or writes == fail_write_number:
			return {"ok": false, "error": "injected quota"}
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

func _send(s: GameSession, kind: String, payload: Dictionary = {}, id: String = "") -> Dictionary:
	serial += 1
	return s.submit({"command_id": id if not id.is_empty() else "c-" + str(serial), "type": kind, "payload": payload, "expected_revision": s.state.revision})

func _snapshot(s: GameSession) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(s.state.to_snapshot_dict()), "", true)

func _reject(s: GameSession, kind: String, p: Dictionary, error: String) -> void:
	var before := _snapshot(s)
	var result := _send(s, kind, p)
	_expect(not result.ok and result.error == error, "reject " + error + ": " + str(result))
	_expect(before == _snapshot(s), "no mutation " + error)

func _build(s: GameSession, id: String) -> bool:
	var building: Dictionary = s.get_view().buildings[id]
	for resource in building.costs:
		var attempts := 0
		while s.state.resources[resource].value.to_float() < float(building.costs[resource]):
			attempts += 1
			if attempts > 1000 or not _send(s, "gather", {"resource_id": resource}).ok:
				return false
	return _send(s, "upgrade_building", {"building_id": id}).ok

func _clone(s: GameSession) -> GameSession:
	var copy := GameSession.new()
	copy.content = s.content
	copy.state = s.state.duplicate_state()
	copy.clock = GameClock.create(s.state.total_elapsed_seconds)
	return copy

func _run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	_expect(IslandProgression.attach(content).ok, "C profile loads")
	var s := GameSession.create_new_game(content)
	_reject(s, "activate_islands", {}, "ERA_REQUIREMENT")
	# No Debug, injected stock, era or building levels anywhere in this flow.
	for id in ["hut", "hut", "wooden_house", "wooden_house", "forest_farm", "forest_farm", "forest_farm", "stone_mine", "stone_mine", "stone_mine", "herb_farm", "herb_farm", "herb_farm", "storage_lingli", "storage_lingli", "storage_money", "storage_stone", "storage_wood", "storage_herb"]:
		_expect(_build(s, id), "earned build " + id)
	for _attempt in range(120):
		if s.state.level == 10:
			break
		if s.get_view().can_level_up:
			_expect(_send(s, "level_up_cultivation").ok, "earned cultivation level")
		else:
			s.advance_time(30)
	_expect(s.state.level == 10, "earned level10")
	_expect(_send(s, "breakthrough_era").ok and s.state.era_id == 2, "blank reaches Era2")
	var fixture_file := FileAccess.open("res://docs/verification/artifacts/res1-c-earned-era2.json", FileAccess.WRITE)
	fixture_file.store_string(SaveCodec.encode(s.state, content.content_version, {"save_id": "local", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": str(int(s.state.total_elapsed_seconds))}).json)
	fixture_file.close()
	var before := _snapshot(s)
	var preview := IslandProgression.preview(s.state, content)
	_expect(preview.ok and before == _snapshot(s), "read-only migration preview")
	var adapter := MemoryAdapter.new()
	SaveManager.configure(content, adapter)
	adapter.fail_key = SaveManager.ISLAND_ARCHIVE_KEY
	_expect(not SaveManager.activate_islands(s, META).ok and before == _snapshot(s), "archive write failure leaves live source untouched")
	adapter.fail_key = ""
	_expect(SaveManager.activate_islands(s, META).ok, "activation retry commits")
	var archived: String = adapter.data[SaveManager.ISLAND_ARCHIVE_KEY]
	_expect(SaveCodec.decode(archived).ok and SaveCodec.decode(archived).state.economy.is_empty(), "recoverable pre-islands archive")
	_expect(s.state.buildings == SaveCodec.decode(archived).state.buildings, "ancestral buildings preserved")
	var retry_source := _clone(s)
	retry_source.state = SaveCodec.decode(archived).state
	var failed_commit := MemoryAdapter.new()
	SaveManager.configure(content, failed_commit)
	failed_commit.fail_write_number = 5 # source payload/index, archive, then candidate payload/index
	var source_before := _snapshot(retry_source)
	_expect(not SaveManager.activate_islands(retry_source, META).ok and _snapshot(retry_source) == source_before, "candidate index failure retains live source")
	failed_commit.fail_write_number = -1
	_expect(SaveManager.activate_islands(retry_source, META).ok, "candidate failure retry activates once")
	var corrupt_archive := MemoryAdapter.new()
	SaveManager.configure(content, corrupt_archive)
	corrupt_archive.data[SaveManager.ISLAND_ARCHIVE_KEY] = "corrupt"
	var conflict := _clone(s)
	conflict.state = SaveCodec.decode(archived).state
	var conflict_before := _snapshot(conflict)
	_expect(not SaveManager.activate_islands(conflict, META).ok and _snapshot(conflict) == conflict_before, "invalid pre-islands archive refuses overwrite")
	_expect(corrupt_archive.data[SaveManager.ISLAND_ARCHIVE_KEY] == "corrupt", "conflicting archive bytes preserved")
	SaveManager.configure(content, adapter)
	_expect(IslandEconomy.validate(s.state).is_empty(), "C state validates")
	_reject(s, "activate_islands", {}, "ALREADY_MIGRATED")
	s.advance_time(30)
	for island in ["wood", "ore"]:
		_expect(_send(s, "open_island", {"island_id": island}).ok, "T1-only opening " + island)
	_reject(s, "open_island", {"island_id": "herb"}, "ERA_REQUIREMENT")
	for id in ["wood_ore", "ore_wood", "timber_home", "bronze_home"]:
		_expect(_send(s, "configure_route", {"route_id": id}).ok, "start route " + id)
	s.advance_time(30)
	_reject(s, "craft", {"island_id": "home", "recipe_id": "spirit_timber"}, "RECIPE_ISLAND_REQUIREMENT")
	for island in ["wood", "ore"]:
		var started := _send(s, "craft", {"island_id": island, "recipe_id": IslandProgression.RECIPES[island], "repeat": true})
		_expect(started.ok, "repeat local " + island + ": " + str(started))
	s.advance_time(120)
	_expect(IslandEconomy.value(s.state, "home", "spirit_timber") >= 2 and IslandEconomy.value(s.state, "home", "bronze_essence") >= 2, "both T2 materials delivered to ancestor")
	var timber := IslandEconomy.value(s.state, "home", "spirit_timber")
	var bronze := IslandEconomy.value(s.state, "home", "bronze_essence")
	_expect(_send(s, "upgrade_island_facility", {"island_id": "wood", "facility_id": "workshop"}, "workshop-upgrade").ok, "T2 consumed by real upgrade")
	_expect(IslandEconomy.value(s.state, "home", "spirit_timber") == timber - 2 and IslandEconomy.value(s.state, "home", "bronze_essence") == bronze - 2, "exact T2 costs from ancestor")
	_expect(IslandProgression.duration(s.state, "wood", "spirit_timber") == 5, "workshop doubles future batch throughput")
	var upgraded := _snapshot(s)
	_expect(_send(s, "upgrade_island_facility", {"island_id": "wood", "facility_id": "workshop"}, "workshop-upgrade").duplicate and upgraded == _snapshot(s), "upgrade replay does not spend twice")
	_reject(s, "upgrade_island_facility", {"island_id": "wood", "facility_id": "ghost"}, "UNKNOWN_FACILITY")
	s.advance_time(90)
	var routes_before := _snapshot(s)
	_expect(_send(s, "configure_route", {"route_id": "wood_ore", "level": 2}).ok, "T2 upgrades operational cargo")
	_expect(routes_before != _snapshot(s), "transport upgrade changes state")
	_expect(_send(s, "upgrade_island_facility", {"island_id": "wood", "facility_id": "storage"}).ok, "T2 warehouse upgrade")
	_expect(IslandProgression.capacity(s.state, "wood") == 200, "warehouse improves capacity")
	_expect(_send(s, "upgrade_island_facility", {"island_id": "ore", "facility_id": "extractor"}).ok, "T2 extractor upgrade")
	# Transport bottleneck controlled by route capacity, not by animation or source rates.
	var low := _clone(s)
	low.state.economy.routes.wood_ore.level = 1
	low.state.economy.routes.wood_ore.target = "200"
	low.state.economy.jobs.erase("ore")
	low.state.economy.islands.ore.inventory.wood = "0"
	low.state.economy.islands.wood.inventory.wood = "100"
	low.state.economy.trips.erase("wood_ore")
	var high := _clone(low)
	high.state.economy.routes.wood_ore.level = 2
	low.advance_time(31)
	high.advance_time(31)
	_expect(IslandEconomy.value(high.state, "ore", "wood") > IslandEconomy.value(low.state, "ore", "wood"), "cargo upgrade improves measured arrivals")
	var once := _clone(s)
	var split := _clone(s)
	TimeAdvancer.advance(once.state, content, 600)
	for seconds in [7, 23, 101, 169, 300]:
		TimeAdvancer.advance(split.state, content, seconds)
	_expect(_snapshot(once) == _snapshot(split), "600 seconds once equals partitioned")
	var encoded := SaveCodec.encode(s.state, content.content_version, META)
	_expect(encoded.ok, "C encodes with new economy version")
	var decoded := SaveCodec.decode(encoded.json)
	_expect(decoded.ok, "C decodes facilities jobs cargo")
	var restored := _clone(s)
	restored.state = decoded.state
	_expect(_snapshot(restored) == _snapshot(s), "C full save roundtrip")
	var invalid := _clone(s)
	invalid.state.economy.islands.wood.facilities.storage = 4
	_expect(not SaveCodec.encode(invalid.state, content.content_version, META).ok, "unknown facility level rejected")
	var offline := _clone(s)
	var online := _clone(s)
	TimeAdvancer.advance(online.state, content, 600)
	OfflineSettlement.settle(offline.state, content, 700000, 100000)
	_expect(_snapshot(offline) == _snapshot(online), "offline actual C profile equals online")
	var offline_start := Time.get_ticks_msec()
	var stress := _clone(s)
	var stress_result := OfflineSettlement.settle(stress.state, content, 172900000, 100000)
	print("RES1C_OFFLINE_CPU_MS: ", Time.get_ticks_msec() - offline_start, " ticks=", stress_result.report.get("effective_ticks", 0))
	_expect(IslandEconomy.validate(stress.state).is_empty(), "long-offline C facilities/cargo integrity")
	var reborn := _clone(stress)
	var reset := ReincarnationRules.apply_reincarnation(reborn.state, content, "normal")
	_expect(reset.ok and IslandProgression.active(reborn.state), "rebirth retains C contract")
	_expect(reborn.state.economy.jobs.is_empty() and reborn.state.economy.trips.is_empty() and not reborn.state.economy.islands.wood.opened, "rebirth clears jobs/cargo/openings")
	_expect(int(reborn.state.economy.islands.wood.facilities.workshop) == 1, "rebirth clears facility upgrades")
	_expect(IslandEconomy.validate(reborn.state).is_empty(), "reborn save validates")
	await _test_ui(s)
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-C1 %d checks; blank Era2, T2 sinks, bottleneck, migration retry, saves, time and UI." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_ui(s: GameSession) -> void:
	var panel := preload("res://src/presentation/island_management_panel.gd").new()
	root.add_child(panel)
	panel.island = "wood"
	panel.refresh(s.get_view(), s.content.processing_catalog)
	panel._rebuild()
	panel.refresh(s.get_view(), s.content.processing_catalog)
	var requested: Array = []
	panel.action_requested.connect(func(kind: String, payload: Dictionary): requested.append([kind, payload]))
	for viewport in [Vector2(1280, 720), Vector2(844, 390)]:
		var width: float = minf(400, viewport.x * 0.44)
		panel.set_layout_bounds(Rect2(Vector2(viewport.x - width - 16, 84), Vector2(width, viewport.y - 180)))
		await process_frame
		_expect(panel.size.x <= width and panel.get_global_rect().end.x <= viewport.x - 16 and panel.get_global_rect().end.y <= viewport.y - 96, "actual management rail fits " + str(viewport))
		_expect(panel.work_buttons[2].size.y >= 44, "stop target minimum44")
		panel.facility_buttons.workshop.pressed.emit()
		_expect(requested.back()[0] == "upgrade_island_facility" and requested.back()[1].island_id == "wood", "UI emits canonical upgrade command")
	panel.show_result("操作未保存：SecurityError。原檔已保留，恢復儲存後重試。")
	panel.storage_recovered()
	_expect(panel.message.text == "保存已恢復，進度已存妥。", "storage retry clears stale failed-command instruction")
	panel.show_result("加工原料或工程材料不足；請查看當地庫存、祖島靈氣與航線。")
	panel.storage_recovered()
	_expect(panel.message.text.begins_with("加工原料"), "background save does not clear gameplay rejection")
	panel.queue_free()
	await process_frame
