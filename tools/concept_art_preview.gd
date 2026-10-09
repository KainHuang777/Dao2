extends SceneTree
## Isolated art review, no normal saves or commands; captures native rendering only.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://concept_art_review_20261006"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	abode.camera.set_process(false)
	await process_frame
	if abode.offline_summary != null:
		abode.offline_summary.hide()
	abode.hint_panel.hide()
	var initial: Dictionary = abode.session.state.to_snapshot_dict()
	var out := "res://docs/verification/artifacts/fx3art1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for vp in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		abode._layout_for_size(root.get_visible_rect().size)
		abode.camera.focus_home()
		abode.camera.position = abode.camera.home_position
		abode.camera.zoom = Vector2.ONE * abode.camera.home_zoom
		await _capture(out, "idle-%dx%d" % [vp.x, vp.y])
		abode.breakthrough_seq.play_preview(8)
		abode.breakthrough_seq.set_process(false)
		abode.breakthrough_seq._process(2.6)
		abode.sky_material.set_shader_parameter("energy", abode.island_fx.energy)
		await _capture(out, "tribulation-%dx%d" % [vp.x, vp.y])
		abode.breakthrough_seq._on_close_pressed()
		abode.sky_material.set_shader_parameter("energy", 0.0)
	if initial != abode.session.state.to_snapshot_dict():
		push_error("Art preview changed gameplay state")
		quit(1)
		return
	abode.queue_free()
	await process_frame
	quit(0)

func _capture(out: String, label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(out + "/" + label + ".png")
	if error != OK:
		push_error("Capture failed " + label)
		quit(1)
	print("ART_CAPTURE ", label)
