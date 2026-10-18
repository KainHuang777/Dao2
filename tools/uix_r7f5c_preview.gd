extends SceneTree
const OUT := "res://docs/verification/artifacts/uix-r7-f5c"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r7-f5c-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.session.state.dao_heart = AmountCompat.from_number(50)
	abode.session.state.buildings.rebirth_lotus = 1
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		abode.feature_navigation.open("reincarnation")
		abode._layout_for_size(Vector2(vp))
		var panel: ReincarnationPanel = abode.reincarnation_panel
		for tab in ["reincarnate", "talents", "confirm", "save-error"]:
			panel._feedback_row.hide()
			panel._switch_tab("reincarnate" if tab == "confirm" else ("talents" if tab == "save-error" else tab))
			if tab == "confirm": panel._on_reincarnate_action_pressed()
			if tab == "save-error": panel.set_save_result({"ok":false})
			for frame in 12: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/%s-%dx%d.png" % [tab,vp.x,vp.y]) != OK:
				quit(1)
				return
		abode.reincarnation_seq.play(abode.camera,1,15,Callable(),false)
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "/motion-%dx%d.png" % [vp.x,vp.y])
		abode.reincarnation_seq.skip()
		for frame in 12: await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(OUT + "/result-%dx%d.png" % [vp.x,vp.y]) != OK:
			quit(1)
			return
		abode.reincarnation_seq._finish_button.pressed.emit()
	abode.queue_free()
	await process_frame
	quit(0)

