extends SceneTree
## Read-only presentation fixture. Does not load or save player progress.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var background := TextureRect.new()
	background.texture = load("res://assets/ui/reincarnation-painted/reincarnation_wheel.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.modulate = Color(0.4, 0.55, 0.5, 0.25)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var sequence := ReincarnationSequence.new()
	root.add_child(sequence)
	sequence.set_layout_bounds(Rect2(Vector2.ZERO, Vector2(1280, 720)))
	sequence.play(null, 12, 0, Callable(), true)
	sequence.skip()
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.test-output/action-r1")
	var result := root.get_texture().get_image().save_png("res://.test-output/action-r1/reincarnation-1280.png")
	print("ACTION_PREVIEW: capture=", result, " action=", sequence._finish_button.get_global_rect())
	print("ACTION_LAYOUT: box=", sequence._center_box.get_rect(), " min=", sequence._center_box.get_combined_minimum_size(), " parent=", sequence._center_box.get_parent().get_rect())
	if "--hold" not in OS.get_cmdline_user_args():
		quit(0 if result == OK else 1)
