extends SceneTree
## Isolated native art evidence; manual presentation time never advances rules.
const OUT := "res://docs/verification/artifacts/ambience"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://ambience_review_20261007"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.cultivator.set_process(false)
	abode.island_fx.set_process(false)
	abode.offline_summary.hide()
	abode.hint_panel.hide()
	abode._hud_controller._messages_open = false
	abode._refresh_hud()
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for vp in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		abode._layout_for_size(root.get_visible_rect().size)
		abode._home_frame_size = Vector2.ZERO
		abode._layout_for_size(root.get_visible_rect().size)
		abode.camera.focus_home()
		abode.camera.position = abode.camera.home_position
		abode.camera.zoom = Vector2.ONE * abode.camera.home_zoom
		abode.home_marker.hide()
		for era in [1, 3, 7]:
			abode.cultivator.clock = 2.0
			abode.cultivator.present(false, 0.0, era)
			abode.cultivator.queue_redraw()
			abode.sky_material.set_shader_parameter("flow_time", 8.0)
			await _capture("era%d-%dx%d" % [era, vp.x, vp.y])
		abode.cultivator.present(true, 0.0, 7)
		abode.sky_material.set_shader_parameter("reduced_motion", true)
		await _capture("reduced-%dx%d" % [vp.x, vp.y])
		abode.sky_material.set_shader_parameter("reduced_motion", false)
	# Background-only comparisons expose masks, motion and the fog landing zones.
	abode.hud.hide()
	for child in abode.get_children():
		if child is Node2D:
			child.hide()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await process_frame
	abode._layout_for_size(root.get_visible_rect().size)
	var first_sky: Image
	for time in [0.0, 8.0, 18.0]:
		abode.sky_material.set_shader_parameter("flow_time", time)
		var sky_image: Image = await _capture("sky-%02d" % int(time))
		if time == 0.0:
			first_sky = sky_image
		elif time == 18.0 and sky_image.get_data() == first_sky.get_data():
			push_error("Ambient shader did not animate")
			quit(1)
			return
	abode.sky_material.set_shader_parameter("reduced_motion", true)
	abode.sky_material.set_shader_parameter("flow_time", 0.0)
	var frozen_sky: Image = await _capture("sky-reduced-00")
	abode.sky_material.set_shader_parameter("flow_time", 18.0)
	var later_frozen: Image = await _capture("sky-reduced-18")
	if frozen_sky.get_data() != later_frozen.get_data():
		push_error("Reduced motion must freeze the ambient background")
		quit(1)
		return
	if before != abode.session.state.to_snapshot_dict():
		push_error("Ambient art preview changed gameplay state")
		quit(1)
		return
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	print("AMBIENCE_PREVIEW PASS: unchanged state; two layouts, three absorption tiers, low motion and sky phases")
	quit(0)

func _capture(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var captured := root.get_texture().get_image()
	var error := captured.save_png(OUT + "/" + label + ".png")
	if error != OK:
		push_error("Capture failed: " + label)
		quit(1)
	print("AMBIENCE_CAPTURE ", label)
	return captured
