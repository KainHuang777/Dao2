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
func inside(outer, inner) -> bool:
	if outer == null or inner == null:
		return false
	return outer.is_ancestor_of(inner)
func count_of(hay: String, needle: String) -> int:
	if needle.is_empty():
		return 0
	var total := 0
	var index := hay.find(needle)
	while index != -1:
		total += 1
		index = hay.find(needle, index + needle.length())
	return total
func capture(label: String, vp: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-ui2/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-ui2-save")
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
	abode.session.state.buildings["herb_farm"] = 3
	abode.session.state.resources["spirit_grass_low"] = {"value": AmountCompat.from_number(200.0), "unlocked": true, "ever_obtained": true}
	abode.session.state.resources["black_copper"] = {"value": AmountCompat.from_number(200.0), "unlocked": true, "ever_obtained": true}
	abode.session.state.resources["lingli"] = {"value": AmountCompat.from_number(2000.0), "unlocked": true, "ever_obtained": true}
	var rec = abode.session.recruit_maid("qingheng")
	var asg = abode.session.assign_maid_duty("qingheng", {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": 2, "reserve": {}})
	abode.session.state.maid["maids"]["qingheng"]["duty_actions"] = 10
	var ch = abode.session.claim_maid_chapter("qingheng", "qingheng_1")
	abode._refresh_hud()
	check(bool(rec.get("ok", false)), "setup recruits qingheng")
	check(bool(asg.get("ok", false)), "setup assigns steward duty")
	check(bool(ch.get("ok", false)), "setup claims first chapter")
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var viewports := ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)])
	if "--maid-ui2-short" in OS.get_cmdline_user_args(): viewports = [Vector2i(800,360)]
	var logic_done := false
	for vp in viewports:
		root.size = vp
		root.content_scale_size = vp
		nav.open("characters")
		abode._layout_for_size(Vector2(vp))
		await frames()
		panel.tabs.work.pressed.emit()
		await frames()
		check(panel.work.visible, "work page shows after work tab")
		check(fits(panel, panel.work), "work scroll enclosed by page")
		check(nav.bar.get_global_rect().end.x <= panel.content.global_position.x + 1, "work page clears shared nav bar")
		check(not abode.toolbar.visible, "work page clears main navigation")
		check(panel.duty_picker.size.y >= 44, "duty picker reaches 44px")
		check(panel.duty_target.size.y >= 44, "duty target reaches 44px")
		check(panel.assign_button.size.y >= 44, "assign action reaches 44px")
		check(panel.pause_button.size.y >= 44, "pause action reaches 44px")
		check(panel.execute_button.size.y >= 44, "execute action reaches 44px")
		check(panel.clear_button.size.y >= 44, "clear action reaches 44px")
		if not logic_done:
			var status_code := String(panel._duty().get("status", "RUNNING"))
			var status_text := String(panel.work_status.text)
			check(status_text.contains(MaidSystem.status_text(status_code)), "work status echoes duty status text")
			check(status_text.contains("累計"), "work status reports cumulative actions")
			check(String(panel.work_owner.text).contains("生效中：青蘅"), "work owner names the active maid")
			check(panel.duty_target.visible, "target stepper visible for qingheng")
			var picker_text: String = panel.duty_picker.get_item_text(panel.duty_picker.selected)
			check(picker_text.contains("築基丹") and picker_text != "foundation_pill", "duty picker shows the recipe display name")
			check(inside(panel.work, panel.feedback), "work feedback row lives inside the work scroll")
			var before_cmd: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
			panel.assign_button.pressed.emit()
			await frames()
			check(panel.feedback.visible, "assign shows a feedback line")
			check(String(panel.feedback.text).begins_with("職掌已指派"), "assign reports success")
			check(not panel.pause_button.disabled, "pause enabled after assign")
			check(not panel.execute_button.disabled, "execute enabled after assign")
			check(not panel.clear_button.disabled, "clear enabled after assign")
			var after_cmd: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
			for key in ["maid", "revision", "command_receipts"]:
				before_cmd.erase(key)
				after_cmd.erase(key)
			check(before_cmd == after_cmd, "assign command changes only maid, revision and receipts")
			panel.pause_button.pressed.emit()
			await frames()
			check(String(panel.pause_button.text) == "恢復", "pause flips to resume label")
			var paused_text := String(panel.work_status.text)
			check(paused_text.contains("已暫停"), "paused work status mentions the pause")
			check(count_of(paused_text, "已暫停") <= 1, "paused work status reports the pause once")
			panel.execute_button.pressed.emit()
			await frames()
			check(String(panel.feedback.text).begins_with("操作未完成："), "execute on paused duty reports a refusal")
			check(String(panel.feedback.text).contains("職掌已暫停"), "refusal names the paused reason")
			panel.pause_button.pressed.emit()
			await frames()
		panel.tabs.bond.pressed.emit()
		await frames()
		check(panel.bond.visible, "bond page shows after bond tab")
		check(fits(panel, panel.bond), "bond scroll enclosed by page")
		check(nav.bar.get_global_rect().end.x <= panel.content.global_position.x + 1, "bond page clears shared nav bar")
		check(not abode.toolbar.visible, "bond page clears main navigation")
		check(inside(panel.bond, panel.bond_feedback), "bond feedback row lives inside the bond scroll")
		if not logic_done:
			check(String(panel.bond_status.text).contains("青蘅"), "bond status names the maid")
			check(String(panel.bond_status.text).contains("點"), "bond status shows bond points")
			check(String(panel.bond_next.text).contains("40"), "bond next reports the forty point gate")
			var row0 := String((panel.chapter_rows[0] as Dictionary)["info"].text)
			check(row0.contains("一盞燈"), "first chapter row shows its title")
			check(row0.contains("已領取"), "first chapter row reports claimed")
			check(not (panel.chapter_rows[1] as Dictionary)["claim"].visible, "second chapter claim hidden")
			check(not (panel.chapter_rows[2] as Dictionary)["claim"].visible, "third chapter claim hidden")
			check(not panel.recruit_box.visible, "recruit box hidden for recruited maid")
			panel.select_maid("nuomeizi")
			await frames()
			check(panel.recruit_box.visible, "recruit box shows for an unrecruited maid")
			check(panel.recruit_button.disabled, "recruit action gated before requirements")
			check(String(panel.recruit_label.text).contains("相知"), "recruit hint explains the bond requirement")
			check(not panel.duty_target.visible, "target stepper hidden for the overseer")
			check(String(panel.feedback.text) == "", "switching maids clears feedback")
			panel.select_maid("qingheng")
			await frames()
			MaidSystem.on_reincarnate(abode.session.state)
			abode._refresh_hud()
			await frames()
			check(panel.reunion_box.visible, "reunion row appears after rebirth")
			panel.reunion_button.pressed.emit()
			await frames()
			check(not panel.reunion_box.visible, "reunion clears after the button")
			logic_done = true
		panel.show_mode("person")
		await frames()
		panel.show_mode("work")
		await frames()
		check(panel.work.visible, "work is the only page after mode reset")
		check(not panel.person.visible, "person hidden in work mode")
		check(not panel.meeting.visible, "meeting hidden in work mode")
		check(not panel.bond.visible, "bond hidden in work mode")
		check(inside(panel.work, panel.feedback), "feedback stays inside work after mode churn")
		if vp.y < 400:
			check(panel.action_row.vertical, "compact work stacks the action row")
			check(panel.work_fields.vertical, "compact work stacks the field row")
			check(not panel.title.visible, "compact work hides the page title")
			check(fits(panel, panel.work), "compact work scroll still enclosed")
		check(panel.maid_row.visible, "roster stays available on the work page")
		var started_work: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
		panel.maid_buttons.nuomeizi.pressed.emit()
		await frames()
		check(panel.selected_maid == "nuomeizi" and panel.mode == "work", "roster switches maids without leaving the work page")
		check(String(panel.work_status.text).contains(String(panel.MAID_NAMES.nuomeizi)), "work page follows the switched maid")
		check(abode.session.state.to_snapshot_dict() == started_work, "roster switching never mutates state")
		panel.maid_buttons.qingheng.pressed.emit()
		await frames()
		check(panel.selected_maid == "qingheng", "roster switches back to the recruited maid")
		await capture("work", vp)
		panel.tabs.bond.pressed.emit()
		await frames()
		check(panel.maid_row.visible, "roster stays available on the bond page")
		await capture("bond", vp)
	panel.refresh({})
	await frames()
	check(not String(panel.work_status.text).is_empty(), "empty view keeps a readable work status")
	abode.queue_free()
	await process_frame
	print("MAID-UI2 checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
