extends SceneTree
var checks := 0
var failures := []
const DIR := "res://docs/verification/artifacts/atm-life-c/"
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 12: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(DIR + name + ".png")
func run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://atm-life-c-ui"
	SaveSlots.new(FileStorageAdapter.new("user://atm-life-c-ui")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.reduced = true
	abode.session.state.reincarnation_count = 1
	StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
	LifeEchoFixture.apply(abode.session)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel = abode.reincarnation_panel
	abode.feature_navigation.open("reincarnation")
	abode._refresh_hud()
	check(panel.visible, "canonical reincarnation route available")
	var view: LifeReportView = panel._report_view
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode._refresh_hud()
		await frames()
		check(view.echoes.text.contains("石壁之後") and view.echoes.text.contains("山門回程") and view.echoes.text.contains("同行漸長"), "three current chains")
		check(view.echoes.get_theme_font_size("font_size") == 18, "narrative18")
		check(view.records_button.size.y >= 44, "source button44")
		check(view.get_global_rect().end.x <= panel._body_scroll.get_global_rect().end.x + 1, "no width overflow")
		panel._body_scroll.ensure_control_visible(view.echoes)
		await frames()
		await shot("echoes-%dx%d" % [vp.x,vp.y])
		view.sources.show()
		check(view.sources.text.contains("選項2") and view.sources.text.contains("同一靈獸成熟") and view.sources.text.contains("不推定收益因果"), "traceable original choice and matching beast")
		panel._body_scroll.ensure_control_visible(view.sources)
		await frames()
		await shot("sources-%dx%d" % [vp.x,vp.y])
		view.sources.hide()
		check(panel._reincarnate_action_button.size.y >= 44 and panel._footer.get_global_rect().end.y <= panel.get_global_rect().end.y + 1, "fixed action reachable")
	check(snapshot == abode.session.state.to_snapshot_dict(), "reading leaves state unchanged")
	panel._on_reincarnate_action_pressed()
	panel._cancel_confirmation()
	check(snapshot == abode.session.state.to_snapshot_dict(), "cancel does not seal")
	check(abode.session.reincarnate().ok, "real seal")
	abode._pending_life_report = abode.session.get_life_report(abode.session.state.reincarnation_count)
	abode._show_storage_block("隔離測試：保存失敗，回聲仍可讀。")
	await frames()
	var protected: Array = abode._storage_block_layer.find_children("*", "LifeReportView", true, false)
	check(protected.size() > 0, "protected reading view")
	var found := false
	for candidate in protected:
		if candidate.echoes.text.contains("石壁之後"): found = true
	check(found, "frozen echoes under save protection")
	await shot("protection-800x360")
	var missing := {"life":{}, "report":{}}
	view.show_report(missing, "living")
	check(not view.echoes.visible and view.echoes.text.is_empty(), "missing replacement clears previous echoes")
	print(JSON.stringify({"suite":"ATM-LIFE-C-UI", "checks":checks, "failures":failures}))
	abode.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
