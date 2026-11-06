extends SceneTree
var checks := 0
var failures: Array[String] = []
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 8: await process_frame
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-guide/%s.png" % label))
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-guide-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	abode._refresh_hud()
	var stand = abode.maid_stand
	var guide = stand.guidance
	abode.feature_navigation.open("buildings")
	await frames()
	check(stand.visible and stand.panel.visible, "management retains half-body companion")
	var work: Rect2 = abode.feature_navigation.shell.workbench.panel.get_global_rect()
	var companion: Rect2 = stand.panel.get_global_rect()
	check(work.end.x + 11 <= companion.position.x, "workbench reserves space instead of covering cards")
	check(companion.end.x <= 1280 and companion.end.y <= abode.toolbar.position.y, "companion stays in viewport above navigation")
	check(not abode.building_catalog.objective_button.visible, "embedded catalog consolidates duplicate guide into dock")
	check(guide.guide_button.size.y >= 44, "guide icon has a 44px target")
	var fixed_portrait: Rect2 = stand.portrait.get_global_rect()
	guide.advance(1)
	await frames()
	check(not guide.bubble.is_visible_in_tree(), "1280 management suppresses automatic bubbles when there is no safe outside space")
	guide.guide_button.pressed.emit()
	await frames()
	check(guide.reader.visible and abode.feature_navigation.shell.state.snapshot().overlay == "tool", "manual guide uses a dismissible reader when outside space is unavailable")
	guide.auto_check.button_pressed = false
	guide.auto_check.button_pressed = true
	abode.feature_navigation.shell.close_overlay()
	await frames()
	check(stand.portrait.get_global_rect() == fixed_portrait, "closing the guide reader restores the identical portrait size and position")
	check(guide._counts.get(guide._key, 0) == 2, "closing a reader suppresses repeat reminders for this step")
	abode.feature_navigation.home()
	await frames()
	check(stand.bubble_bounds(Vector2(1280, 720)).size.x > 0, "home has safe outside speech space")
	fixed_portrait = stand.portrait.get_global_rect()
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	guide._counts.clear()
	guide._pending = true
	guide.advance(1)
	await frames()
	check(guide.bubble.visible and not guide._manual, "new goal displays an automatic bubble")
	check(guide.message.text.contains("茅屋") and guide.message.text.contains("靈氣") and guide.message.tooltip_text == abode._hud_controller._current_guidance_text, "bubble summarizes the real goal and shortage; full guidance remains available")
	check(guide._title.text == "修行指引", "unrecruited portrait does not impersonate a recruited maid")
	check(stand.portrait.get_global_rect() == fixed_portrait, "outside bubble does not resize or move the portrait")
	check(not guide.bubble.get_global_rect().intersects(stand.panel.get_global_rect()) and not guide.bubble.get_global_rect().intersects(abode.hint_panel.get_global_rect()), "outside bubble clears companion and visible message panel")
	check(stand.panel.get_global_rect().end.x <= 1280 and not stand.panel.get_global_rect().intersects(abode.settings_menu.get_global_rect()), "expanded bubble clears viewport and settings")
	await capture("management-bubble")
	guide.advance(7)
	check(not guide.bubble.visible, "automatic bubble expires after seven seconds")
	await frames()
	check(stand.portrait.get_global_rect() == fixed_portrait and stand.open_button.visible and stand.status_label.visible, "bubble expiry leaves portrait and companion controls unchanged")
	guide.refresh(abode._presentation_view(), stand.selected_id())
	guide.advance(49)
	check(not guide.bubble.visible, "same goal does not refresh-spam or remind before fifty seconds")
	guide.advance(1)
	check(guide.bubble.visible, "same goal reminds after fifty seconds")
	guide.advance(7)
	guide.advance(100)
	check(not guide.bubble.visible and guide._counts[guide._key] == 2, "same goal stops after two automatic bubbles")
	guide.guide_button.pressed.emit()
	check(guide.bubble.visible and guide._manual, "manual entry works after automatic limit")
	guide.advance(100)
	check(guide.bubble.visible, "manual reading does not auto-dismiss")
	guide.close_button.pressed.emit()
	check(not guide.bubble.visible and guide._counts.get(guide._key, 0) == 2, "close seal dismisses and mutes the current step")
	guide.guide_button.pressed.emit()
	guide.auto_check.button_pressed = false
	guide.dismiss()
	guide._pending = true
	guide._counts.clear()
	guide.advance(100)
	check(not guide.bubble.visible, "automatic reminders can be disabled")
	guide.guide_button.pressed.emit()
	check(guide.bubble.visible, "disabled automatic reminders retain manual access")
	guide.details_button.pressed.emit()
	await frames()
	check(abode.feature_navigation.shell.state.snapshot().overlay == "messages", "details opens canonical guide reading overlay")
	check(not stand.visible and not stand.tab.visible, "blocking overlay hides both companion forms")
	guide.auto_check.button_pressed = true
	var count_before: int = guide._counts.get(guide._key, 0)
	guide.advance(100)
	check(int(guide._counts.get(guide._key, 0)) == count_before, "blocked time never queues reminders")
	abode.feature_navigation.shell.close_overlay()
	await frames()
	check(stand.visible, "closing guide restores original management page")
	guide.dismiss()
	guide._counts.clear()
	guide._pending = false
	guide._elapsed = 0.0
	var changed: Dictionary = abode._presentation_view().duplicate(true)
	changed.early_guidance = {"step": "F2", "route": "manufacturing", "text": "測試"}
	guide.refresh(changed, "qingheng")
	guide.advance(1)
	check(guide.bubble.visible and guide._counts[guide._key] == 1, "new stable step resets reminder eligibility")
	guide.dismiss()
	guide.refresh(abode._presentation_view(), stand.selected_id())
	guide.guide_button.pressed.emit()
	guide.target_button.pressed.emit()
	await frames()
	check(not guide.bubble.visible, "target navigation dismisses the bubble")
	check(abode.feature_navigation.group in ["home", "management"], "target action uses canonical destination")
	var after: Dictionary = abode.session.state.to_snapshot_dict()
	check(JSON.stringify(before) == JSON.stringify(after), "reminders, preferences and guide navigation never mutate gameplay or saves")
	for vp in ([Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280, 720)]):
		root.size = vp
		root.content_scale_size = vp
		abode.feature_navigation.open("buildings")
		abode._layout_for_size(Vector2(vp))
		await frames()
		check(guide.guide_button.is_visible_in_tree(), "guide remains accessible at %s" % vp)
		check(guide.guide_button.get_global_rect().end.x <= vp.x, "guide entry stays inside viewport at %s" % vp)
		if not stand.panel.visible:
			check(stand.tab.visible and stand.tab.get_parent() == abode.feature_navigation.shell.entry, "compact companion participates in the entry container")
			check(not stand.tab.get_global_rect().intersects(abode.toolbar.get_global_rect()), "compact dock clears bottom navigation")
		guide.guide_button.pressed.emit()
		await frames()
		check(guide.bubble.is_visible_in_tree(), "manual reading remains available at %s" % vp)
		await capture("management-%dx%d" % [vp.x, vp.y])
		guide.dismiss()
	if "--maid-bubble-wide" in OS.get_cmdline_user_args():
		root.size = Vector2i(1920, 1080)
		root.content_scale_size = root.size
		abode.feature_navigation.open("buildings")
		abode._layout_for_size(Vector2(1920, 1080))
		await frames()
		guide._counts.clear()
		guide._pending = true
		guide.auto_check.button_pressed = true
		fixed_portrait = stand.portrait.get_global_rect()
		guide.advance(1)
		await frames()
		check(guide.bubble.is_visible_in_tree(), "wide management shows its outside bubble")
		check(guide.get_global_rect().end.x <= stand.panel.global_position.x and not guide.get_global_rect().intersects(abode.feature_navigation.shell.workbench.panel.get_global_rect()), "reserved speech lane clears companion and complete workbench")
		check(stand.portrait.get_global_rect() == fixed_portrait, "wide appearance leaves the portrait unchanged")
		await capture("wide-outside")
		guide.close_button.pressed.emit()
		await frames()
		check(stand.portrait.get_global_rect() == fixed_portrait and not guide.bubble.visible, "wide close leaves the portrait unchanged")
	abode.queue_free()
	await process_frame
	print("MAID-GUIDE-DOCK checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
