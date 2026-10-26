extends SceneTree
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for n in 8: await process_frame
func run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://atm-life-a-ui"
	SaveSlots.new(FileStorageAdapter.new("user://atm-life-a-ui")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel = abode.reincarnation_panel
	abode.reduced = true
	for mode in ["exhausted", "early", "living", "partial"]:
		LifeReportFixture.apply(abode.session.state, mode)
		abode.feature_navigation.open("reincarnation")
		for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
			root.size = vp
			root.content_scale_size = vp
			abode._layout_for_size(Vector2(vp))
			abode._refresh_hud()
			await frames()
			check(panel._report_view.title.text == "雲外初行", mode + str(vp) + " title")
			check(panel._body_scroll.size.y >= 80, mode + str(vp) + " readable viewport")
			check(panel._reincarnate_action_button.size.y >= 44, "action hit")
			check(panel.get_global_rect().encloses(panel._footer.get_global_rect()), "fixed footer bounded")
			check(panel._body_scroll.get_global_rect().end.y <= panel._footer.get_global_rect().position.y + 1, "body clears footer")
			check(panel._reincarnate_action_button.disabled == (mode == "living"), "original eligibility")
			check(panel._report_view.title.get_theme_font("font") == UiTypography.epilogue_title_font(), "shared serif role")
			check(panel._body_scroll.get_global_rect().encloses(panel._report_view.title.get_global_rect()), "title visible before scrolling")
			check(panel._body_scroll.get_global_rect().encloses(panel._report_view.closing.get_global_rect()), "closing visible before scrolling")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/verification/artifacts/atm-life-a/%s-%dx%d.png" % [mode, vp.x, vp.y])
		panel._report_view.records_button.pressed.emit()
		check(panel._report_view.sources.visible, "sources expanded")
		panel.set_layout_bounds(panel.get_global_rect())
		check(panel._report_view.sources.visible, "resize keeps reading")
		panel._report_view.sources.hide()
		if mode != "living":
			panel._on_reincarnate_action_pressed()
			check(panel._confirming, "explicit confirmation")
			var before: Dictionary = abode.session.get_life_record()
			panel._cancel_confirmation()
			check(before == abode.session.get_life_record(), "cancel no seal")
		abode.feature_navigation.home()
	var prior: GameState = abode.session.state
	var replacement: GameState = prior.duplicate_state()
	replacement.life_ledger.current.events.clear()
	abode.session.state = replacement
	abode.feature_navigation.open("reincarnation")
	await frames()
	check(panel._report_view.title.text == "此世行跡", "same revision replaced state invalidates report")
	abode.session.state = prior
	abode._refresh_hud()
	check(panel._report_view.title.text == "雲外初行", "restoring state identity refreshes")
	var transfer: Dictionary = abode.session.reincarnate()
	check(transfer.ok, "actual transfer for protection")
	abode._pending_life_report = abode.session.get_life_report(abode.session.state.reincarnation_count)
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._show_storage_block("本世已結算；保存失敗，請恢復儲存後重試。")
		await frames()
		var reading: ScrollContainer = abode._storage_block_layer.find_child("PendingLifeReading", true, false)
		check(reading != null and reading.size.y >= 100, "protection reading area")
		if reading != null:
			var report: LifeReportView = reading.get_child(0).get_child(0)
			check(report.title.text == "雲外初行", "protection reads frozen title")
			check(reading.get_global_rect().encloses(report.title.get_global_rect()), "protection title visible")
			check(report.records_button.custom_minimum_size.y >= 44, "protection read action")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/verification/artifacts/atm-life-a/protection-%dx%d.png" % [vp.x, vp.y])
		abode._storage_block_layer.queue_free()
		abode._storage_block_layer = null
		await frames()
	print(JSON.stringify({"suite":"REPORT-1A UI", "checks":checks, "failures":failures}))
	abode.queue_free()
	await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
