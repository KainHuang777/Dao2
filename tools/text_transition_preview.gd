extends SceneTree
## Native render-only evidence. Does not load a save or mutate a game session.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var out := "res://docs/verification/artifacts/text-transition"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var panel = load("res://src/presentation/text_transition.gd").new()
	root.add_child(panel)
	for viewport in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = viewport
		await process_frame
		panel.play("境界等級提升至 LV2", "築基期 ERA2 — 壽元剩餘 80祀")
		panel.set_process(false)
		for timing in [0.4, 0.6]:
			panel.advance_presentation(timing)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var phase := "reveal" if timing == 0.4 else "hold"
			var path := "%s/%s-%dx%d.png" % [out, phase, viewport.x, viewport.y]
			var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			if error != OK:
				push_error("Capture failed: %s" % path)
				quit(1)
				return
			print("CAPTURE ", path)
	panel.queue_free()
	await process_frame
	quit(0)
