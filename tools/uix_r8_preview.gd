extends SceneTree
const OUT := "res://docs/verification/artifacts/uix-r8"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r8-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		for state_name in ["locked", "ready", "last", "save-error"]:
			abode.session.state.era_id = 1 if state_name == "locked" else 2
			abode.session.state.buildings.library = 0 if state_name == "locked" else 1
			abode.session.state.buildings.scripture_hall = 1
			SkillSystem.sync_unlock(abode.session.state)
			abode.session.state.resources.skill_point.value = AmountCompat.from_number(6200)
			abode.session.state.skills = {"basic_meditation":2,"qi_storage_1":1}
			abode.feature_navigation.open("skills")
			abode._layout_for_size(Vector2(vp))
			var panel = abode.feature_navigation.action_panel
			panel.status.hide()
			panel.retry_button.hide()
			panel.save_failed = false
			panel.skill_view.scroll.scroll_vertical = 0
			if state_name == "save-error": panel.show_save_failure("研習已生效，但保存失敗；恢復儲存後重試保存。")
			for frame in 12: await process_frame
			if state_name == "last": panel.skill_view.scroll.scroll_vertical = 10000
			for frame in 6: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/%s-%dx%d.png" % [state_name,vp.x,vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
