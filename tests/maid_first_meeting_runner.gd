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
func fits(outer, inner) -> bool:
	if outer == null or inner == null:
		return false
	return outer.get_global_rect().encloses(inner.get_global_rect())
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-first-meeting/%s.png" % label))
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-first-meeting-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	abode.session.state.buildings["hut"] = 1
	abode._refresh_hud()
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	nav.open("characters")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	check(nav.page == "characters", "characters route opens")
	check(panel.mode == "person", "entry starts on the person page")
	check(panel.meeting_image.texture == null, "meeting CG stays unloaded before recruitment")
	panel.tabs.bond.pressed.emit()
	await frames()
	check(panel.bond.visible, "bond page lists the recruit row")
	check(not panel.recruit_button.disabled, "hut unlocks the qingheng recruit")
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	panel.recruit_button.pressed.emit()
	await frames()
	check(bool(panel._maid_entry().get("recruited", false)), "recruit reaches the maid state")
	check(panel.mode == "meeting", "successful recruit switches to the first meeting")
	check(panel.selected_maid == "qingheng", "first meeting keeps the recruited maid")
	check(panel.selected_reply == -1, "first meeting restarts from the opening")
	check(panel.meeting.visible and not panel.person.visible, "only the meeting page shows")
	check(panel.tabs.meeting.button_pressed, "meeting tab reflects the auto switch")
	check(panel.meeting_image.texture != null, "first meeting CG is loaded")
	check(panel.meeting_image.texture.resource_path.contains("qingheng/first-meeting.png"), "first meeting CG belongs to qingheng")
	check(panel.line.text == panel.OPENING, "first meeting shows the qingheng opening line")
	check(panel.line_scroll.scroll_vertical == 0, "opening line starts at the top")
	check(panel.choices.visible, "choices wait at the opening")
	check(not panel.replay.visible, "replay stays hidden before a reply")
	check(String(panel.feedback.text) == "仙侍已入府。", "recruit feedback survives the auto switch")
	check(panel.get_global_rect().end.y <= abode.toolbar.global_position.y + 1, "meeting page clears main navigation")
	check(fits(panel, panel.meeting), "meeting page is enclosed by the panel")
	var after: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	for key in ["maid", "revision", "command_receipts", "achievements", "life_ledger"]:
		before.erase(key)
		after.erase(key)
	check(before == after, "auto meeting keeps every other state slice intact")
	panel.choice_buttons[0].pressed.emit()
	await frames()
	check(panel.selected_reply == 0, "reply selects the first response")
	check(panel.replay.visible and not panel.choices.visible, "reply reveals the replay action")
	panel.replay.pressed.emit()
	await frames()
	check(panel.selected_reply == -1 and panel.choices.visible, "replay restores the opening choices")
	check(panel.line.text == panel.OPENING, "replay restores the opening line")
	panel.tabs.person.pressed.emit()
	await frames()
	check(panel.mode == "person", "person tab leaves the meeting")
	var settled: Dictionary = abode.session.state.to_snapshot_dict()
	nav.refresh(abode.session.get_view())
	await frames()
	check(abode.session.state.to_snapshot_dict() == settled, "refresh after the meeting never mutates state")
	await capture("meeting")
	abode.queue_free()
	await process_frame
	print("MAID-FIRST-MEETING checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
