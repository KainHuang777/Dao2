extends SceneTree
## Isolated rendered layout evidence, not browser interaction evidence.
const OUT := "res://docs/verification/artifacts/uix-r2-f3"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r2f3-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode._on_debug_auto_build_toggled(true)
	abode._refresh_hud()
	# One native pixel per logical pixel for direct bounds comparison in this tool.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		for frame in 8:
			await process_frame
		for route in ["home", "buildings"]:
			if route == "home": abode.feature_navigation.home()
			else: abode.feature_navigation.open(route)
			abode._set_resource_display_mode(1)
			abode._layout_for_size(Vector2(vp))
			for frame in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/%s-%dx%d.png" % [route, vp.x, vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
