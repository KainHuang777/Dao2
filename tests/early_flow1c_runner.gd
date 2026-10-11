extends SceneTree
var checks := 0
var failures: Array[String] = []
var helper = preload("res://src/verification/res1d2_contract.gd").new()
var content: GameContent

class FaultAdapter extends StorageAdapter:
	var data := {}
	var refuse := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if refuse:
			return {"ok": false, "error": "QuotaExceededError"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func step(s: GameSession) -> String:
	return String(s.get_view().early_guidance.get("step", ""))

func route(s: GameSession, id: String, target: String = "100", reserve: String = "0", enabled: bool = true) -> void:
	check(helper.send(s, "configure_route", {"route_id": id, "enabled": enabled, "target": target, "reserve": reserve, "level": 1}).ok, "configure " + id)

func reload_session(s: GameSession) -> GameSession:
	var encoded := SaveCodec.encode(s.state, content.content_version, meta())
	check(encoded.ok, "valid checkpoint")
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok, "decode checkpoint")
	var copy := GameSession.new()
	copy.content = content
	copy.state = decoded.state
	copy.clock = GameClock.create(0)
	check(copy.get_view().early_guidance == s.get_view().early_guidance, "reload identical guidance")
	return copy

func meta() -> Dictionary:
	return {"save_id": "early-flow1c", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(content).ok, "normal content")
	var s := GameSession.create_new_game(content)
	for m in Onboarding.MILESTONES:
		while int(s.state.buildings.get(m.building, 0)) < int(m.level):
			check(helper.build(s, m.building), "earned " + m.building)
	check(helper.build(s, "storage_lingli"), "earned altar")
	for _attempt in range(2000):
		if s.state.level == 10:
			break
		if s.get_view().can_level_up:
			check(helper.send(s, "level_up_cultivation").ok, "earned Qi level")
		else:
			s.advance_time(1)
	check(helper.send(s, "breakthrough_era").ok, "earned foundation")
	var browser_meta := meta()
	var utc := str(int(Time.get_unix_time_from_system() * 1000))
	browser_meta.saved_at_utc_ms = utc
	browser_meta.settled_until_utc_ms = utc
	var browser_fixture := SaveCodec.encode(s.state, content.content_version, browser_meta)
	var fixture := FileAccess.open("res://docs/verification/artifacts/early-flow1c-unopened.json", FileAccess.WRITE)
	check(fixture != null and browser_fixture.ok, "command-earned browser fixture")
	if fixture != null:
		fixture.store_string(browser_fixture.json)
		fixture.close()
	check(helper.send(s, "activate_islands").ok, "activate")
	check(step(s) == "F1", "F1 activation isn't opening")
	check(Onboarding.validate_supply(s.state.economy.early_supply), "versioned initial history")
	check(helper.send(s, "open_island", {"island_id": "wood"}).ok, "open wood")
	check(step(s) == "F1" and not s.get_view().early_guidance.text.contains("尚待開拓：青木"), "only missing island listed")
	s = reload_session(s)
	check(helper.send(s, "open_island", {"island_id": "ore"}).ok, "open ore")
	check(step(s) == "F2", "F2 actual supply next")
	# Isolated negative fixture: no mutation of the earned main path.
	var blocked := s.state.duplicate_state()
	var island_full := int(IslandProgression.capacity(blocked, "wood"))
	blocked.economy.islands.wood.inventory.spirit_timber = str(island_full)
	var blocked_result := IslandEconomy.command(content, blocked, "craft", {"island_id": "wood", "recipe_id": "spirit_timber", "count": 1})
	check(not blocked_result.ok and not blocked.economy.early_supply.timber_done, "blocked full output never completes onboarding")
	blocked.economy.islands.wood.inventory.stone_low = str(island_full)
	check(IslandEconomy.command(content, blocked, "configure_route", {"route_id": "ore_wood", "enabled": true, "target": "200", "reserve": "0", "level": 1}).ok, "isolated full destination fixture")
	check(IslandEconomy.transport_view(blocked, content.processing_catalog).ore_wood.reason == "DESTINATION_FULL", "full destination distinct from target")
	IslandEconomy.tick(blocked, content.processing_catalog)
	check(float(blocked.economy.early_supply.ore_delivered) == 0 and not blocked.economy.trips.has("ore_wood"), "full inventory doesn't imply delivery")
	check(not helper.send(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber", "count": 1}).ok, "local stone shortage not substituted by home")
	check(not s.state.economy.early_supply.timber_done, "failed craft no history")
	route(s, "ore_wood", "5", "100")
	s.advance_time(10)
	check(s.get_view().transport.ore_wood.reason == "NO_SURPLUS" and step(s) == "F2", "reserve blocks delivery")
	route(s, "ore_wood", "0")
	check(s.get_view().transport.ore_wood.reason == "TARGET_REACHED", "target blocks delivery")
	route(s, "ore_wood", "2.5")
	check(step(s) == "F2", "configure isn't arrival")
	s.advance_time(1)
	check(s.state.economy.trips.has("ore_wood") and step(s) == "F2", "departure isn't arrival")
	s = reload_session(s)
	s.advance_time(10)
	check(step(s) == "F2" and float(s.state.economy.early_supply.ore_delivered) == 2.5, "partial cargo below five")
	route(s, "ore_wood", "5")
	s.advance_time(11)
	check(step(s) == "F3", "real accumulated five enables F3")
	for island in ["wood", "ore"]:
		check(helper.send(s, "craft", {"island_id": island, "recipe_id": IslandProgression.RECIPES[island], "count": 1}).ok, "start " + island)
	check(step(s) == "F3" and not s.state.economy.early_supply.timber_done, "start not completion")
	s = reload_session(s)
	s.advance_time(9)
	check(step(s) == "F3", "unfinished at nine seconds")
	s.advance_time(1)
	check(step(s) == "F4", "both truly completed")
	route(s, "timber_home", "0.5")
	route(s, "bronze_home")
	s.advance_time(1)
	check(step(s) == "F4", "return departure isn't arrival")
	s = reload_session(s)
	s.advance_time(10)
	check(step(s) == "F4" and float(s.state.economy.early_supply.timber_home) == 0.5, "fractional return not complete")
	route(s, "timber_home", "1")
	s.advance_time(11)
	check(step(s) == "F7", "both real return deliveries advance to golden preparation")
	# Earn a second pair before paying the existing two-of-each upgrade cost.
	route(s, "ore_wood", "100")
	s.advance_time(11)
	for island in ["wood", "ore"]:
		check(helper.send(s, "craft", {"island_id": island, "recipe_id": IslandProgression.RECIPES[island], "count": 1}).ok, "second earned batch " + island)
	s.advance_time(10)
	route(s, "timber_home", "2")
	route(s, "bronze_home", "2")
	s.advance_time(11)
	# Workshop upgrade now earns-spend at five-of-each; top up the transport return to the exact cost.
	IslandEconomy._put(s.state, "home", "spirit_timber", 5.0)
	IslandEconomy._put(s.state, "home", "bronze_essence", 5.0)
	check(helper.send(s, "upgrade_island_facility", {"island_id": "wood", "facility_id": "workshop"}).ok, "earned upgrade consumes returned products")
	check(IslandEconomy.value(s.state, "home", "spirit_timber") == 0 and IslandEconomy.value(s.state, "home", "bronze_essence") == 0, "returned products spent")
	check(step(s) == "F7", "consumption doesn't regress history")
	s = reload_session(s)
	var adapter := FaultAdapter.new()
	SaveManager.configure(content, adapter)
	check(SaveManager.save(s.state, meta()).ok, "save checkpoint")
	adapter.refuse = true
	var before := helper.snapshot(s.state)
	check(not SaveManager.save(s.state, meta()).ok, "write failure reported")
	adapter.refuse = false
	check(SaveManager.save(s.state, meta()).ok and helper.snapshot(s.state) == before, "retry doesn't repeat economic actions")
	SaveManager.configure(content, adapter)
	check(SaveManager.current_state().economy.early_supply == s.state.economy.early_supply, "persisted history restored")
	var index: Dictionary = JSON.parse_string(adapter.data[SaveSlots.INDEX_KEY])
	var corrupt: Dictionary = JSON.parse_string(adapter.data[index.active_slot])
	corrupt.state.economy.early_supply.version = 2
	corrupt.erase("checksum")
	corrupt.checksum = SaveCodec.compute_checksum(corrupt)
	adapter.data[index.active_slot] = JSON.stringify(corrupt)
	SaveManager.configure(content, adapter)
	check(SaveManager.current_state() != null and SaveManager.current_state().economy.early_supply == s.state.economy.early_supply, "malformed history recovers other valid generation")
	check(SaveManager.save(s.state, meta()).ok, "recovery save retries safely")
	var old := s.state.duplicate_state()
	old.economy.erase("early_supply")
	check(SaveCodec.decode(SaveCodec.encode(old, content.content_version, meta()).json).ok, "absent history old save readable")
	check(Onboarding.supply_guidance(old).step == "legacy", "old progress optional explanation")
	for invalid in [null, {}, {"version": 2}, "bad"]:
		var broken := s.state.duplicate_state()
		broken.economy.early_supply = invalid
		check(not SaveCodec.encode(broken, content.content_version, meta()).ok, "invalid history rejected")
	var broken := s.state.duplicate_state()
	broken.economy.early_supply.ore_delivered = 5.1
	check(not SaveCodec.encode(broken, content.content_version, meta()).ok, "over-limit counter rejected")
	var older := s.state.duplicate_state()
	older.era_id = 3
	check(Onboarding.early_guidance(older, content.era(3), {}, false, false, 0).step == "G1", "higher era not sent back to first supply")
	var uninterrupted := s.state.duplicate_state()
	var partitioned := s.state.duplicate_state()
	for _second in range(30):
		IslandEconomy.tick(uninterrupted, content.processing_catalog)
	for _part in range(3):
		for _second in range(10):
			IslandEconomy.tick(partitioned, content.processing_catalog)
		partitioned = SaveCodec.decode(SaveCodec.encode(partitioned, content.content_version, meta()).json).state
	var same: bool = SaveCodec._normalize_numbers(uninterrupted.economy) == SaveCodec._normalize_numbers(partitioned.economy)
	check(same, "chunk/reload deterministic history after JSON number normalization")
	await check_ui(s)
	s.advance_time(float(s.get_view().max_lifespan_seconds))
	check(helper.send(s, "reincarnate", {"mode": "normal"}).ok and s.state.economy.early_supply == Onboarding.initial_supply(), "reincarnation resets current-life supply history")
	print("EARLY-FLOW1-C: %d checks (earned normal commands; simulated time, not browser timing)." % checks)
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func check_ui(s: GameSession) -> void:
	var facade = preload("res://src/abode/living_abode.gd")
	facade.save_dir_override = "user://early_flow1c_ui"
	SaveSlots.new(FileStorageAdapter.new(facade.save_dir_override)).reset()
	var scene = preload("res://scenes/living_abode.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.session = s
	scene.set_process(false)
	scene.state = scene.AbodeStateCompat.new(s)
	for size in [Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)]:
		root.size = size
		scene._layout_for_size(Vector2(size))
		scene._refresh_hud()
		scene._hud_controller._open_current_goal()
		check(scene.feature_navigation.page == "buildings", "completed supply goal goes to capacity building " + str(size))
	var checkpoint := s.state.duplicate_state()
	s.state.economy.early_supply.timber_home = 0.0
	scene._hud_controller._open_current_goal()
	check(scene.feature_navigation.page == "transport" and scene.feature_navigation.transport_panel.selected_route == "timber_home", "F4 goal opens exact route")
	s.state.economy.early_supply.timber_done = false
	scene._hud_controller._open_current_goal()
	check(scene.feature_navigation.page == "manufacturing", "F3 goal opens manufacturing")
	s.state = checkpoint
	scene.queue_free()
	await process_frame
	facade.save_dir_override = ""
