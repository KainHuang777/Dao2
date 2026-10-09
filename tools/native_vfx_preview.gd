extends SceneTree
## Real Compatibility rendering, isolated save fixture, no progression commands.
const OUT := "res://docs/verification/artifacts/native-vfx"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://native_vfx_home_preview"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	abode.camera.set_process(false)
	await process_frame
	await process_frame
	abode.offline_summary.visible = false
	if abode.text_transition == null:
		push_error("Presentation components failed to load")
		quit(1)
		return
	var initial: Dictionary = abode.session.state.to_snapshot_dict()
	for viewport in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = viewport
		root.content_scale_size = viewport
		await process_frame
		abode._layout_for_size(root.get_visible_rect().size)
		await create_timer(0.5).timeout
		await _capture("home-%dx%d" % [viewport.x, viewport.y])
		abode._toggle_motion()
		await process_frame
		await _capture("home-reduced-%dx%d" % [viewport.x, viewport.y])
		abode._toggle_motion()
		abode.text_transition.play("天雷淬體 · 道心初成", "靈光流轉，萬象歸一")
		abode.text_transition.set_process(false)
		abode.text_transition.advance_presentation(1.0)
		await _capture("neon-text-%dx%d" % [viewport.x, viewport.y])
		abode.text_transition.skip()
	if initial != abode.session.state.to_snapshot_dict():
		push_error("VFX preview changed game state")
		quit(1)
		return
	abode.queue_free()
	await process_frame
	slots.reset()
	quit(0)
func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
	if error != OK:
		push_error("VFX capture failed: " + label)
		quit(1)
	print("FX3_CAPTURE ", label)
