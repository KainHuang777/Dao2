extends SceneTree
## Render isolated presentation fixtures; never submit a breakthrough command.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := "res://docs/verification/artifacts/breakthrough-fx2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://breakthrough_fx2_preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	root.size = Vector2i(1280, 720)
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	abode.camera.set_process(false)
	await process_frame
	var initial: Dictionary = abode.session.state.to_snapshot_dict()
	for vp in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		var logical: Vector2 = root.get_visible_rect().size
		abode._layout_for_size(logical)
		print("CAPTURE_VIEWPORT physical=", vp, " logical=", logical)
		for era in [2, 8, 12]:
			abode.breakthrough_seq.reduced_motion = false
			abode.breakthrough_seq.play("前境", "ERA%d 視覺試播" % era, era)
			abode.breakthrough_seq.set_process(false)
			abode.breakthrough_seq._process(2.6)
			abode.sky_material.set_shader_parameter("energy", abode.island_fx.energy)
			await _capture(out, "era%d-%dx%d" % [era, vp.x, vp.y])
			abode.breakthrough_seq._on_close_pressed()
		abode.breakthrough_seq.reduced_motion = true
		abode.breakthrough_seq.play("前境", "低特效視覺試播", 12)
		abode.breakthrough_seq.set_process(false)
		abode.breakthrough_seq._process(0.5)
		abode.sky_material.set_shader_parameter("energy", abode.island_fx.energy)
		await _capture(out, "reduced-%dx%d" % [vp.x, vp.y])
		abode.breakthrough_seq._on_close_pressed()
	if initial != abode.session.state.to_snapshot_dict():
		push_error("Presentation preview mutated game state")
		quit(1)
		return
	abode.queue_free()
	await process_frame
	quit(0)

func _capture(out: String, label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(out + "/" + label + ".png")
	if error != OK:
		push_error("Capture failed: " + label)
		quit(1)
	print("CAPTURE ", label)
