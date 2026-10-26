extends SceneTree
var checks := 0
var failures := []
const DIR := "res://docs/verification/artifacts/report-2/"
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for n in 12: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(DIR + name + ".png")
func run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://report-2-ui"
	SaveSlots.new(FileStorageAdapter.new("user://report-2-ui")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.reduced = true
	LifeHistoryFixture.apply(abode.session)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel = abode.reincarnation_panel
	abode.feature_navigation.open("reincarnation")
	panel._switch_tab("history")
	abode._refresh_hud()
	var view: LifeHistoryView = panel._history_view
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode._refresh_hud()
		await frames()
		view.life_selector.select(1)
		view.life_selector.item_selected.emit(1)
		for i in view.resource_selector.item_count:
			if view.resource_selector.get_item_metadata(i) == "home:wood": view.resource_selector.select(i)
		view.resource_selector.item_selected.emit(view.resource_selector.selected)
		check(view.comparison.text.contains("未有紀錄") and view.comparison.text.contains("80000.00祀"), "coverage and uncut lifespan")
		check(view.plot.finish == 4800000 and not view.plot.samples.is_empty(), "age axis covers long life")
		for selector in [view.life_selector, view.resource_selector, view.interval_selector]:
			check(selector.size.y >= 44, "selector44")
			check(selector.get_popup().get_theme_constant("v_separation") >= 28, "popup44")
		check(panel._history_button.size.y >= 44, "tab44")
		panel._body_scroll.ensure_control_visible(view.life_selector)
		await frames()
		check(panel._body_scroll.get_global_rect().encloses(view.life_selector.get_global_rect()), "life selection reachable")
		check(view.get_global_rect().end.x <= panel._body_scroll.get_global_rect().end.x + 1, "no horizontal overflow")
		await shot("select-%dx%d" % [vp.x,vp.y])
		panel._body_scroll.ensure_control_visible(view.plot)
		await frames()
		await shot("plot-%dx%d" % [vp.x,vp.y])
		view.interval_selector.select(4)
		view.interval_selector.item_selected.emit(4)
		check(view.plot.size.y <= panel._body_scroll.size.y, "complete plot fits reading viewport")
		check(view.plot.start == 3600000 and view.plot.finish == 4800000, "quarter interval")
		panel._body_scroll.ensure_control_visible(view.table)
		await frames()
		await shot("table-%dx%d" % [vp.x,vp.y])
		view.life_selector.select(0)
		view.life_selector.item_selected.emit(0)
		check(view.coverage.text.contains("未有紀錄") and view.plot.samples.is_empty() and not view.plot.visible and not view.resource_selector.visible, "old life missing no curve or blank selector")
		check(not panel._confirming and not panel._reincarnate_action_button.visible, "history cannot accidentally rebirth")
		check(panel._footer.get_global_rect().end.x <= panel.get_global_rect().end.x + 1, "footer in bounds")
	var reading_snapshot: Dictionary = abode.session.get_life_record()
	var old_key: String = view._key
	var updated_snapshot: Dictionary = reading_snapshot.duplicate(true)
	updated_snapshot.current.until = float(updated_snapshot.current.until) + 60
	view.life_selector.get_popup().show()
	view.show_record(updated_snapshot)
	check(view._key == old_key, "clock refresh preserves open mouse menu")
	view.life_selector.get_popup().hide()
	view.show_record(updated_snapshot)
	check(view._key != old_key, "deferred history refresh applies after menu closes")
	view.show_record(reading_snapshot)
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	view.interval_selector.select(0)
	view.interval_selector.item_selected.emit(0)
	check(before == abode.session.state.to_snapshot_dict(), "reading does not mutate state")
	panel._switch_tab("reincarnate")
	panel._on_reincarnate_action_pressed()
	panel._switch_tab("history")
	check(not panel._confirming, "switch cancels confirmation")
	view.show_record({})
	check(view.plot.samples.is_empty() and view.table.text == "未有紀錄", "empty replacement removes stale chart")
	check(abode.session.reincarnate().ok, "isolation transfer")
	abode._pending_life_report = abode.session.get_life_report(abode.session.state.reincarnation_count)
	abode._show_storage_block("隔離測試：保存失敗，歷世仍可讀。")
	await frames()
	var reading_views: Array = abode._storage_block_layer.find_children("*", "LifeHistoryView", true, false)
	check(reading_views.size() == 1, "history readable under save protection")
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		await frames()
		var reading: ScrollContainer = abode._storage_block_layer.find_child("PendingLifeReading", true, false)
		var history: LifeHistoryView = reading_views[0]
		reading.ensure_control_visible(history.life_selector)
		await frames()
		check(reading.get_global_rect().encloses(history.life_selector.get_global_rect()), "protection life selector reachable")
		await shot("protection-%dx%d" % [vp.x,vp.y])
	abode._storage_block_layer.queue_free()
	abode._storage_block_layer = null
	paused = false
	abode.queue_free()
	await process_frame
	print("REPORT-2 UI ", checks, " checks failures=", failures)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
