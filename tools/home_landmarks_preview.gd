extends SceneTree
## Diagnostic rendering of core home landmarks; never touches normal player saves.
const OUT := "res://docs/verification/artifacts/altar-grounded"
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var altar_image: Image = load("res://assets/abode/altar-grounded/altar-grounded-v2.png").get_image()
	if altar_image == null or altar_image.get_pixel(0, 0).a > 0.0:
		push_error("Grounded altar must retain a transparent background")
		quit(1)
		return
	print("ALTAR_ALPHA_QC size=", altar_image.get_size(), " used=", altar_image.get_used_rect(), " corner_alpha=", altar_image.get_pixel(0, 0).a)
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://home_landmarks_review_20261007"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.offline_summary.hide()
	abode.hint_panel.hide()
	abode._hud_controller._messages_open = false
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	if not decoded.ok:
		quit(1)
		return
	# Clone a command-earned fixture for presentation only; this is not reachability evidence.
	abode.session.state = decoded.state.duplicate_state()
	abode.session.state.era_id = 1
	for vp in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		abode._layout_for_size(root.get_visible_rect().size)
		abode.camera.focus_home()
		abode.camera.position = abode.camera.home_position
		abode.camera.zoom = Vector2.ONE * abode.camera.home_zoom
		abode.session.state.buildings["storage_lingli"] = 1
		abode._refresh_hud()
		abode.hint_panel.hide()
		await process_frame
		await process_frame
		abode._home_frame_size = Vector2.ZERO
		abode._layout_for_size(root.get_visible_rect().size)
		abode.camera.focus_home()
		abode.camera.position = abode.camera.home_position
		abode.camera.zoom = Vector2.ONE * abode.camera.home_zoom
		abode.home_marker.hide()
		var before: Dictionary = abode.session.state.to_snapshot_dict()
		await _capture("built-%dx%d" % [vp.x, vp.y])
		if before != abode.session.state.to_snapshot_dict():
			push_error("Rendering changed rules")
			quit(1)
			return
		abode.session.state.buildings.erase("storage_lingli")
		abode._refresh_hud()
		abode.hint_panel.hide()
		abode.home_marker.hide()
		await _capture("empty-%dx%d" % [vp.x, vp.y])
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	quit(0)

func _capture(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
	if result != OK:
		push_error("Capture failed: " + label)
		quit(1)
	print("HOME_LANDMARK_CAPTURE ", label)
