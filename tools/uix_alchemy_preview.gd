extends SceneTree
## Isolated rendered layout evidence, not browser interaction evidence.
const OUT := "res://docs/verification/artifacts/uix-alchemy"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-alchemy-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.session.state.buildings["herb_farm"] = 3
	abode.session.state.pills["lifespan_pill"] = 1
	abode.session.state.revision += 1
	abode._refresh_hud()
	# One native pixel per logical pixel for direct bounds comparison in this tool.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		abode.session.state.pills["lifespan_pill"] = 1
		abode.session.state.pill_effects.clear()
		for id in ["spirit_grass_low", "lingli", "wood", "money", "black_copper"]:
			abode.session.state.resources[id].unlocked = true
			abode.session.state.resources[id].value = AmountCompat.from_number(100)
		abode.session.state.revision += 1
		abode._refresh_hud()
		root.size = vp
		root.content_scale_size = vp
		for frame in 8:
			await process_frame
		for route in ["alchemy", "consumed"]:
			if route == "alchemy": abode.feature_navigation.open("alchemy")
			else: abode._on_alchemy_consume_requested("lifespan_pill", 1)
			abode._set_resource_display_mode(1)
			abode._layout_for_size(Vector2(vp))
			for frame in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/verified-%s-%dx%d.png" % [route, vp.x, vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
