extends SceneTree
## Captures isolated command-earned state, never changes player save directories.
const OUT := "res://docs/verification/artifacts/res1-ui1-r2"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://res1_ui1r2_preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.offline_summary.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	if not decoded.ok:
		quit(1)
		return
	abode.session.state = decoded.state.duplicate_state()
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var fixture := SaveCodec.encode(abode.session.state, abode.content.content_version, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": str(int(abode.session.state.total_elapsed_seconds))})
	if not fixture.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/res1-ui1-r2-review.json", FileAccess.WRITE)
	file.store_string(fixture.json)
	file.close()
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		var nav = abode.feature_navigation
		nav.open("outposts")
		nav.island_panel.select_island("ore")
		abode._layout_for_size(root.get_visible_rect().size)
		await capture("basics-%dx%d" % [vp.x, vp.y])
		nav.open("manufacturing")
		# Native visual diagnostic only: show an existing job and its inline meter.
		abode.session.state.economy.jobs.ore = {"recipe_id": "bronze_essence", "recipe_version": 1, "remaining": 4, "batches": 0, "repeat": true, "reserves": {}, "status": "running"}
		IslandEconomy._put(abode.session.state, "herb", "spirit_grass_low", 0)
		abode._refresh_hud()
		await capture("recipes-%dx%d" % [vp.x, vp.y])
		nav.manufacturing_panel.category = "合成"
		abode._refresh_hud()
		await capture("synthesis-%dx%d" % [vp.x, vp.y])
		nav.manufacturing_panel.category = "精煉"
		nav.manufacturing_panel.select_recipe("liquid")
		await capture("detail-%dx%d" % [vp.x, vp.y])
		print("UI1_DETAIL_RECT ", nav.manufacturing_panel.get_global_rect(), " viewport=", root.get_visible_rect(), " min=", nav.manufacturing_panel.get_combined_minimum_size())
		_inspect(nav.manufacturing_panel, vp.x - 32)
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	quit(0)
func capture(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
	if result != OK:
		quit(1)
	print("UI1_CAPTURE ", label)

func _inspect(node: Node, width: float) -> void:
	if node is Control and node.is_visible_in_tree() and (node.get_combined_minimum_size().x > width or node.size.x > width):
		print("UI1_OVERSIZE ", node.get_path(), " rect=", node.get_global_rect(), " min=", node.get_combined_minimum_size())
	for child in node.get_children():
		_inspect(child, width)

