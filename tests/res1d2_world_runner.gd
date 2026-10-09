extends SceneTree
## Presentation diagnostics use earned fixture clones; they are not reachability evidence.
var checks := 0
var failures: Array[String] = []
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
	script.save_dir_override = "user://res1d2_world_runner"
	script.island_preview_override = false
	var adapter := FileStorageAdapter.new(script.save_dir_override)
	SaveSlots.new(adapter).reset()
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	SaveManager.configure(content, adapter)
	var earned := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(earned.ok, "command-earned Era3 fixture decodes")
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	check(SaveManager.save(earned.state, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": "0"}).ok, "isolated seed saved")
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.visible = false
	root.size = Vector2i(1280, 720)
	await process_frame
	abode._layout_for_size(Vector2(1280, 720))
	abode._refresh_hud()
	var world = abode.island_world
	world.refresh()
	check(world.buttons.has("herb") and world.roots.has("herb"), "Danxia has world and rail entries")
	check(world.bodies.herb.texture.resource_path.ends_with("res1d2/herb_body.png"), "dedicated terrain")
	check(world.landmarks.herb.texture.resource_path.ends_with("res1d2/herb_landmark.png"), "dedicated separate workshop")
	check(world.bodies.herb.get_parent() == world.landmarks.herb.get_parent() and world.bodies.herb != world.landmarks.herb, "independent layer nodes")
	check(world.landmarks.herb.visible, "earned opened Danxia shows workshop")
	var source: GameState = abode.session.state
	var before := snapshot(source)
	var cargo_state := source.duplicate_state()
	abode.session.state = cargo_state
	cargo_state.economy.trips = {}
	world.refresh()
	for sword in world.cargo_swords.values():
		check(not sword.visible, "idle routes have no flight")
	cargo_state.economy.trips = {"liquid_home": {"remaining": 10, "cargo": 1}}
	var cargo_before := snapshot(cargo_state)
	world.refresh()
	var cargo_sword: Sprite2D = world.cargo_swords.liquid_home
	check(cargo_sword.visible and cargo_sword.position.is_equal_approx(world.LOCATIONS.herb + Vector2(-280, 40)), "loaded flight starts at source island")
	cargo_state.economy.trips.liquid_home.remaining = 5
	world.refresh()
	check(cargo_sword.position.is_equal_approx((world.LOCATIONS.herb * 0.5) + Vector2(-280, 40)), "flight follows core remaining time")
	check(is_equal_approx(cargo_sword.rotation, (Vector2.ZERO - world.LOCATIONS.herb).angle()), "flight faces destination")
	abode.reduced = true
	world.refresh()
	check(cargo_sword.visible and float(cargo_sword.material.get_shader_parameter("clock")) == 0.0, "low effects preserve cargo marker without shader motion")
	abode.reduced = false
	cargo_state.economy.trips.liquid_home.remaining = 10
	check(snapshot(cargo_state) == cargo_before, "cargo rendering changes no inventory or rule state")
	cargo_state.economy.trips = {}
	world.refresh()
	check(not cargo_sword.visible, "delivery removes flight without empty return")
	abode.session.state = source
	world.refresh()
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for index in range(50):
		world.enter(["herb", "wood", "ore", "home"][index % 4])
		await process_frame
	check(snapshot(source) == before, "50 world switches leave complete rule state unchanged")
	check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes, "50 switches retain nodes")
	world.enter("herb")
	abode._pick_world(world.LOCATIONS.herb + Vector2(300, 50))
	check(abode.feature_navigation.page == "outposts" and abode.feature_navigation.island_panel.island == "herb", "Danxia world hit uses canonical management")
	var basics = abode.feature_navigation.island_panel
	check(basics.world_button.text == "前往丹霞島" and basics.short_world_button.tooltip_text == "前往丹霞島", "Danxia management offers reverse world route")
	var mask: BitMap = world.landmark_masks.herb
	var picked := false
	for y in range(0, mask.get_size().y, 16):
		for x in range(0, mask.get_size().x, 16):
			if mask.get_bitv(Vector2i(x, y)):
				var art: Sprite2D = world.landmarks.herb
				var point := art.global_transform * (art.get_rect().position + Vector2(x, y))
				picked = world.pick(point)
				break
		if picked:
			break
	check(picked and abode.feature_navigation.page == "manufacturing" and abode.feature_navigation.manufacturing_panel.selected_recipe == "liquid", "opaque workshop hit enters the same Danxia manufacturing job")
	world.enter("home")
	check(world.current == "home" and abode.feature_navigation.group == "home", "ancestor return")
	var diagnostic: GameState = source.duplicate_state()
	diagnostic.economy.islands.herb.opened = false
	abode.session.state = diagnostic
	world.enter("herb")
	world.banner_until = 0
	world.refresh()
	check(not world.landmarks.herb.visible and world.bodies.herb.visible, "unopened Danxia has empty foundation")
	check(world.title.text.contains("待開拓"), "Era3 pending opening visible")
	diagnostic.era_id = 2
	world.refresh()
	check(world.title.text.contains("金丹解鎖"), "Era2 preview distinguishes locked Danxia")
	world.manage_current()
	check(abode.feature_navigation.island_panel.opening.disabled, "Era2 cannot open Danxia from world route")
	diagnostic.era_id = 1
	world.refresh()
	check(not world.roots.herb.visible and not world.rail.visible and world.current == "home", "Era1 hides Danxia and returns home")
	check(not world.pick(world.LOCATIONS.herb), "hidden Danxia cannot be picked")
	abode.session.state = source
	for size in [Vector2(1280, 720), Vector2(844, 390), Vector2(640, 360)]:
		root.size = Vector2i(size)
		await process_frame
		abode._layout_for_size(size)
		world.enter("herb")
		await process_frame
		await process_frame
		world.refresh()
		var art: Sprite2D = world.landmarks.herb
		var top: Vector2 = art.global_transform * Vector2(0, -art.texture.get_height() * 0.5)
		var projected: Vector2 = (top - abode.camera.target_position) * abode.camera.target_zoom + size * 0.5
		check(projected.y >= 0, "workshop roof within frame " + str(size))
		check(world.buttons.herb.size.y >= 44 and world.buttons.home.size.y >= 44, "44px world controls " + str(size))
		print("D2_RAIL_GEOMETRY size=", size, " hud=", abode.hud.size, " rail=", world.rail.get_global_rect(), " herb=", world.buttons.herb.get_global_rect(), " toolbar=", abode.toolbar.get_global_rect(), " header=", abode.header.size)
		check(world.buttons.herb.get_global_rect().end.x <= size.x and world.buttons.home.get_global_rect().position.x >= 0, "world controls fit " + str(size))
		check(world.rail.get_global_rect().size.x <= size.x, "rail fits " + str(size))
		check(world.buttons.herb.get_global_rect().end.y <= abode.toolbar.get_global_rect().position.y, "rail above navigation " + str(size))
		world.enter("home")
		world.refresh()
		if size.y < 500:
			check(not world.title.visible and not world.buttons.home.visible and not world.manage_button.visible, "compact home rail leaves core landmarks visible")
			check(world.buttons.wood.visible and world.buttons.ore.visible and world.buttons.herb.visible, "compact home retains destination island controls")
		world.enter("herb")
		check(world.title.visible and world.buttons.home.visible and world.manage_button.visible, "remote rail retains return and management controls")
	root.size = Vector2i(1280, 720)
	await process_frame
	abode._layout_for_size(Vector2(1280, 720))
	world.enter("herb")
	var desktop_zoom: float = abode.camera.target_zoom
	root.size = Vector2i(844, 390)
	await process_frame
	abode._layout_for_size(Vector2(844, 390))
	world.refresh()
	check(world.current == "herb" and abode.camera.target_zoom < desktop_zoom, "resize reframes Danxia")
	check(not world.title.text.contains("\n"), "compact single line banner")
	# _process samples real elapsed time even at delta=0; use a diagnostic clone.
	abode.session.state = source.duplicate_state()
	abode.camera.zoom = Vector2.ONE * abode.camera.target_zoom
	abode._process(0.0)
	var region_labels_hidden := true
	for child in abode.region_layer.get_children():
		if child is Label:
			region_labels_hidden = region_labels_hidden and not child.visible
	check(region_labels_hidden and not abode.home_marker.visible, "remote compact world hides unrelated home/region captions")
	world.enter("home")
	abode.camera.zoom = Vector2.ONE * 0.30
	abode._process(0.0)
	check(abode.home_marker.visible, "home overview caption returns normally")
	check(snapshot(source) == before, "diagnostic presentation leaves earned state unchanged")
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-D2-R1 Danxia world ", checks, " checks; nodes=", nodes)
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)
