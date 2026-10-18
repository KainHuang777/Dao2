extends SceneTree
## Isolated native rendering; does not prove browser input or touch behavior.
const OUT := "res://docs/verification/artifacts/uix-r4-f5"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r4-f5-preview"
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.session.state.buildings["hut"] = 2
	abode.session.state.buildings["wooden_house"] = 2
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		for stock in [0.0, 999.99]:
			for id in abode.session.state.resources:
				abode.session.state.resources[id].value = AmountCompat.from_number(stock)
			abode.session.state.revision += 1
			abode._refresh_hud()
			abode.feature_navigation.open("buildings")
			abode._layout_for_size(Vector2(vp))
			for frame in 12:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/catalog-%dx%d-%d.png" % [vp.x, vp.y, int(stock)]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
