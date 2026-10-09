extends SceneTree
var failures: Array[String] = []
var checks := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
func snapshot(state: GameState) -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(state.to_snapshot_dict()), "", true)
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://res1c2_world_runner"
	script.island_preview_override = false
	var adapter := FileStorageAdapter.new(script.save_dir_override)
	var slots := SaveSlots.new(adapter)
	slots.reset()
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	SaveManager.configure(content, adapter)
	var state: GameState = SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json")).state
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	check(SaveManager.save(state, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": "0"}).ok, "isolated earned Era2 seed")
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.visible = false
	var first_view: Dictionary = abode._presentation_view()
	check(is_same(first_view, abode._presentation_view()), "unchanged frames reuse presentation view")
	abode.session.advance_time(1.0)
	var advanced_view: Dictionary = abode._presentation_view()
	check(not is_same(first_view, advanced_view) and advanced_view.total_elapsed_seconds == abode.session.state.total_elapsed_seconds, "tick refreshes view at revision change")
	var refreshed: Dictionary = abode.session.submit({"command_id": "perf-view-buff", "expected_revision": abode.session.state.revision, "type": "apply_buff", "payload": {"buff_id": "epiphany"}})
	check(refreshed.ok and not is_same(advanced_view, abode._presentation_view()), "command invalidates presentation cache")
	abode.session.state.training_seconds = 7.0 # Existing debug edits request explicit HUD refresh.
	abode._refresh_hud()
	check(abode._presentation_view().training_seconds == 7.0, "explicit refresh covers direct debug edits")
	check(abode.island_world != null, "normal game builds islands without preview feature")
	check(not abode.content.processing_catalog.is_empty(), "normal content includes processing")
	check(abode.session.state.economy.is_empty(), "loading legacy save does not silently activate islands")
	abode.feature_navigation.open("outposts")
	check(abode.feature_navigation.tab_buttons.outposts.text == "空島", "player-facing name does not imply three-island cap")
	abode.feature_navigation.home()
	var world = abode.island_world
	for id in ["wood", "ore"]:
		check(world.landmarks[id].texture.resource_path.ends_with("res1c3/%s_landmark.png" % id), "production layered landmark " + id)
	world.refresh()
	check(not world.landmarks.wood.visible and not world.landmarks.ore.visible, "unopened islands have no invented facilities")
	var before := snapshot(abode.session.state)
	var baseline_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var memory_samples: Array[int] = [int(Performance.get_monitor(Performance.MEMORY_STATIC))]
	for index in range(50):
		world.enter("wood" if index % 2 == 0 else "ore")
		await process_frame
		if (index + 1) % 10 == 0:
			memory_samples.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == baseline_nodes, "50 switches retain node count")
	print("C2_MEMORY: native headless static_bytes every10switches=", memory_samples, " nodes=", baseline_nodes)
	check(before == snapshot(abode.session.state), "50 presentation switches do not change rules")
	world.enter("wood")
	abode._pick_world(world.LOCATIONS.wood + Vector2(300, 50))
	check(abode.feature_navigation.page == "outposts" and abode.feature_navigation.island_panel.island == "wood", "world hit uses canonical management page")
	world.enter("home")
	check(abode.feature_navigation.group == "home" and world.current == "home", "explicit ancestor return")
	for size in [Vector2(1280, 720), Vector2(844, 390)]:
		root.size = Vector2i(size)
		await process_frame
		abode._layout_for_size(size)
		world.enter("ore")
		await process_frame
		var art: Sprite2D = world.landmarks.ore
		var top: Vector2 = art.global_transform * Vector2(-art.texture.get_width() * 0.5, -art.texture.get_height() * 0.5)
		var projected: Vector2 = (top - abode.camera.target_position) * abode.camera.target_zoom + size * 0.5
		check(projected.y >= 0.0, "remote landmark upper bounds in frame " + str(size))
		check(world.buttons.ore.size.y >= 44 and world.buttons.home.size.y >= 44, "44px world buttons " + str(size))
		check(world.rail.get_global_rect().size.x <= size.x, "rail fits viewport " + str(size))
		abode.offline_summary.show_report({"away_ms": 172800000, "effective_ms": 86400000, "cap_applied": true, "stopped": "lifespan_exhausted"})
		abode._layout_for_size(size)
		await process_frame
		var close: Button = abode.offline_summary.get_node("OfflineSummaryBox/OfflineSummaryClose")
		check(close.get_global_rect().end.y < abode.toolbar.get_global_rect().position.y, "fixed summary close above navigation " + str(size))
		abode.offline_summary.visible = false
	root.size = Vector2i(1280, 720)
	await process_frame
	abode._layout_for_size(Vector2(1280, 720))
	world.enter("ore")
	var desktop_zoom: float = abode.camera.target_zoom
	root.size = Vector2i(844, 390)
	await process_frame
	abode._layout_for_size(Vector2(844, 390))
	world.refresh()
	check(world.current == "ore" and abode.camera.target_zoom < desktop_zoom, "resize reframes current island without re-entering")
	check(not world.title.text.contains("\n"), "short landscape uses compact island rail")
	abode.queue_free()
	await process_frame
	script.island_preview_override = false
	script.save_dir_override = ""
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-C3 normal-world/summary ", checks, " checks")
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)

