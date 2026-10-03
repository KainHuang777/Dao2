extends SceneTree
## UI8 render fixtures only. Does not touch player slots or claim rewards.
func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://ui8_core_preview"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	root.size = Vector2i(1280, 720)
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.offline_summary.visible = false
	var dir := "res://docs/verification/artifacts/ui8-icons"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for viewport in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = viewport
		await process_frame
		for mode in ["new", "full", "notices", "notices-more", "notices-tip"]:
			abode.session.state.era_id = 1 if mode == "new" else 2
			abode.session.state.level = 1 if mode == "new" else 10
			abode.session.state.total_elapsed_seconds = 0 if mode == "new" else 999999
			abode._refresh_hud()
			if mode.begins_with("notices"):
				var view: Dictionary = abode.session.get_view()
				view.beast.can_feed = true
				view.fortune.has_pending = true
				view.buffs = [{"id": "sample", "name": "天靈氣湧", "icon_text": "湧", "description": "全產率 +30%", "formatted_remaining": "04:56"}]
				for i in range(7):
					view.buffs.append({"id": "extra%d" % i, "name": "試驗增益%d" % i, "icon_text": "符", "description": "多狀態排版 fixture", "formatted_remaining": "常駐"})
				abode.buff_hud_bar.update_status(view, {"unlocked": true, "active_expedition": {"duration": 30, "elapsed": 30}})
				abode._hud_controller._status_scroll.visible = true
				abode._hud_controller._status_row.visible = true
				abode._hud_controller._status_more.visible = true
			abode._layout()
			await process_frame
			await process_frame
			if mode in ["notices-more", "notices-tip"]:
				abode.buff_hud_bar.next_page()
				await process_frame
			if mode.begins_with("notices"):
				var bounds: Rect2 = abode._hud_controller._status_scroll.get_global_rect()
				for badge in abode.buff_hud_bar.badges.values():
					if badge.visible and not bounds.encloses(badge.get_global_rect()):
						push_error("Status icon clipped: " + str(badge.get_global_rect()))
						quit(1)
						return
			if mode == "notices-tip":
				var badge: Button = abode.buff_hud_bar.badges["buff:sample"]
				for down in [true, false]:
					var click := InputEventMouseButton.new()
					click.position = badge.get_global_rect().get_center()
					click.button_index = MOUSE_BUTTON_LEFT
					click.pressed = down
					root.push_input(click)
					await process_frame
				if not badge.get_child(1).visible:
					push_error("BUFF detail did not open from viewport mouse input")
					quit(1)
					return
			await RenderingServer.frame_post_draw
			var path := "%s/%s-%dx%d.png" % [dir, mode, viewport.x, viewport.y]
			if root.get_texture().get_image().save_png(path) != OK:
				quit(1)
				return
			print("UI8_CAPTURE ", path)
	abode.queue_free()
	await process_frame
	slots.reset()
	quit(0)
