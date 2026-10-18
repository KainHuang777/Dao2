extends SceneTree
const OUT := "res://docs/verification/artifacts/uix-r11"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r11-preview"
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
		for state_name in ["human", "spirit", "shortage", "era", "cooldown", "save-error", "long"]:
			abode.session.state.current_realm = "realm_human" if state_name in ["human", "shortage"] else "realm_spirit"
			abode.session.state.era_id = 1 if state_name == "era" else 2
			abode.session.state.realm_decisions = {}
			for id in ["money", "wood", "lingli", "spirit_grass_low"]:
				abode.session.state.resources[id].value = AmountCompat.from_number(0 if state_name == "shortage" else 1000)
			if state_name == "cooldown":
				RealmDecisionSystem.ensure_initialized(abode.session.state)
				abode.session.state.realm_decisions.cooldowns.spirit_attune_lingchao = 240
			abode.feature_navigation.open("decisions")
			abode._layout_for_size(Vector2(vp))
			var panel = abode.feature_navigation.action_panel
			panel.status.hide()
			panel.retry_button.hide()
			panel.save_failed = false
			panel.decision_view.scroll.scroll_vertical = 0
			if state_name == "save-error": panel.show_save_failure("法令已生效，但保存失敗；恢復儲存後重試保存。")
			if state_name == "long":
				var view: Dictionary = abode.session.get_view()
				view.realm_decisions[1].name = "仙池靈露催熟・長標題與代價閱讀驗收".repeat(3)
				view.resources.money.value = "123456789012345678901234567890"
				panel.refresh(view)
			for frame in 18: await process_frame
			if state_name in ["long", "save-error"]:
				panel.decision_view.scroll.scroll_vertical = 10000
				for frame in 6: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT + "/%s-%dx%d.png" % [state_name,vp.x,vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
