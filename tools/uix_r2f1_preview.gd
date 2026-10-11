extends SceneTree
## Render the actual HUD with isolated fresh progress; no player save access.
const OUT := "res://docs/verification/artifacts/uix-r2-f1"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r2f1-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		for route in ["home", "buildings", "outposts", "manufacturing", "transport"]:
			if route == "home": abode.feature_navigation.home()
			else: abode.feature_navigation.open(route)
			abode._layout_for_size(Vector2(vp))
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var captured := root.get_texture().get_image()
			if captured.save_png(OUT + "/%s-%dx%d.png" % [route, vp.x, vp.y]) != OK:
				quit(1)
				return
			var control: Control = abode.hud.get_node("GoalScroll") if route == "home" else abode.feature_navigation.bar
			var rect := control.get_global_rect()
			var crop := Rect2i(Vector2i(rect.position), Vector2i(rect.size)).intersection(Rect2i(Vector2i.ZERO, vp))
			if captured.get_region(crop).save_png(OUT + "/%s-%dx%d-strip.png" % [route, vp.x, vp.y]) != OK:
				quit(1)
				return
			print("SCROLL_CAPTURE ", route, " ", vp, " rect=", rect)
	abode.queue_free()
	await process_frame
	quit(0)
