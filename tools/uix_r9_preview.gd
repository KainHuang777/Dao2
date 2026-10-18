extends SceneTree
const OUT := "res://docs/verification/artifacts/uix-r9"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r9-preview"
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
		for mode in ["locked","join","tasks","active","claim","techniques","market","save-error"]:
			abode.session.state.era_id = 1 if mode == "locked" else 2
			abode.session.state.sect = {}
			for id in abode.content.resource_ids: abode.session.state.resources[id].value = AmountCompat.from_number(10000)
			if mode not in ["locked","join"]:
				abode.session.join_sect("太虛天闕")
				abode.session.state.sect.contribution = "1000"
				if mode in ["active","claim"]:
					abode.session.start_sect_expedition(abode.session.state.sect.available_tasks[0].id)
					if mode == "claim": SectSystem.tick(abode.session.state,1000)
			abode._refresh_hud()
			abode.feature_navigation.open("sect")
			abode._layout_for_size(Vector2(vp))
			var panel: SectPanel = abode.sect_panel
			panel._feedback_row.hide()
			panel._pending_save = false
			panel._switch_tab(SectPanel.TabMode.TECHNIQUES if mode == "techniques" else (SectPanel.TabMode.MARKET if mode == "market" else SectPanel.TabMode.EXPEDITIONS))
			if mode == "save-error": panel.set_command_result({"ok":true},{"ok":false,"error":"R9_WRITE_DENIED"})
			panel._scroll.scroll_vertical = 0
			for frame in 18: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT+"/%s-%dx%d.png" % [mode,vp.x,vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
