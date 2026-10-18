extends SceneTree
const OUT := "res://docs/verification/artifacts/uix-r10"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r10-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.session.state.era_id = 2
	abode.offline_summary.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		for mode in ["ready","cooldown","pending","paid","result","save-error","long"]:
			abode.session.state.fortune.pending_encounter = {}
			abode.session.state.fortune.cooldown_remaining = 0 if mode=="ready" else 600
			if mode in ["pending","paid","save-error","long"]:
				for enc in FortuneSystem.get_encounters():
					if enc.id == ("enc_wandering_taoist" if mode=="paid" else "enc_ancient_cave"):
						abode.session.state.fortune.pending_encounter = enc.duplicate(true)
			var panel: FortuneModal = abode.fortune_modal
			panel._feedback_row.hide()
			panel._pending_save = false
			panel.set_result_message("參悟石壁殘圖，獲得90秒修為。" if mode=="result" else "")
			abode._refresh_hud()
			abode.feature_navigation.open("fortune")
			abode._layout_for_size(Vector2(vp))
			if mode=="save-error": panel.set_command_result({"ok":true},{"ok":false,"error":"R10_WRITE_DENIED"})
			if mode=="long":
				var view: Dictionary = abode.session.get_view()
				view.fortune.pending_encounter.desc = "山間雲霧散去，一段往事浮現。".repeat(80)
				panel.refresh(view)
			panel._body_scroll.scroll_vertical = 0
			for frame in 18: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT+"/%s-%dx%d.png" % [mode,vp.x,vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
