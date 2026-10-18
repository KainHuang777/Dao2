extends SceneTree
## Isolated native rendering, not browser/touch evidence.
const OUT := "res://docs/verification/artifacts/uix-r6/art-feedback"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r6-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.session.state.level = 2
	abode.session.state.buildings.hut = 1
	AchievementSystem.check_achievements(abode.session.state)
	abode.session.claim_achievement("era_qi")
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		abode.feature_navigation.open("achievements")
		abode._layout_for_size(Vector2(vp))
		var panel: AchievementPanel = abode.achievement_panel
		panel.show_status_message("")
		panel._retry_button.hide()
		for category in [0, 2, 6]:
			panel._filters._buttons[category].pressed.emit()
			for frame in 12: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/album-%dx%d-category%d.png" % [vp.x,vp.y,category]) != OK:
				quit(1)
				return
		panel.set_save_result({"ok":false,"error":"R6_WRITE_DENIED"})
		for frame in 12: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "/save-failure-%dx%d.png" % [vp.x,vp.y])
	abode.queue_free()
	await process_frame
	quit(0)
