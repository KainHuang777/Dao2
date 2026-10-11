extends SceneTree
## Isolated native rendering; not browser interaction evidence.
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://ear2-ui-f1-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var fixture := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	if not fixture.ok:
		quit(1)
		return
	abode.session.state = fixture.state.duplicate_state()
	abode._refresh_hud()
	abode.feature_navigation.open("outposts")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for phase in ["first", "opened"]:
		if phase == "opened":
			abode.feature_navigation.island_panel.opening.pressed.emit()
			if not abode.session.state.economy.get("islands", {}).get("wood", {}).get("opened", false):
				quit(1)
				return
		for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
			root.size = vp
			root.content_scale_size = vp
			abode._layout_for_size(Vector2(vp))
			for frame in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png("res://docs/verification/artifacts/ear2-ui-f1/final-%s-%dx%d.png" % [phase, vp.x, vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
