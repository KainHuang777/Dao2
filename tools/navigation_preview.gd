extends SceneTree
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://nav1_native_preview"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	root.size = Vector2i(1280, 720)
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.offline_summary.visible = false
	abode.session.state.era_id = 3
	abode.session.state.resources.spirit_grass_low = {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true}
	abode.session.acquire_beast("jade_fox")
	var dir := "res://docs/verification/artifacts/nav1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for viewport in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = viewport
		await process_frame
		for route in ["home", "buildings", "outposts", "alchemy", "beasts", "reincarnation", "realms", "sect", "fortune", "decisions"]:
			if route == "home": abode.feature_navigation.home()
			else: abode.feature_navigation.open(route)
			abode._layout()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var path := dir + "/%s-%dx%d.png" % [route, viewport.x, viewport.y]
			var error := root.get_texture().get_image().save_png(path)
			if error != OK:
				push_error("Preview save failed " + path)
				quit(1)
				return
			print("NAV1_CAPTURE " + path)
	abode.queue_free()
	await process_frame
	slots.reset()
	quit(0)
