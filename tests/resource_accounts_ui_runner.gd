extends SceneTree
var checks := 0
var failures := []
const DIR := "res://docs/verification/artifacts/ledger-1/"
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
	load("res://src/abode/living_abode.gd").save_dir_override = "user://ledger-1-ui"
	SaveSlots.new(FileStorageAdapter.new("user://ledger-1-ui")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.reduced = true
	ResourceAccountsFixture.apply(abode.session)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel = abode.reincarnation_panel
	abode.feature_navigation.open("reincarnation")
	abode._refresh_hud()
	panel._accounts_toggle.button_pressed = true
	panel._accounts_toggle.pressed.emit()
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode._refresh_hud()
		await frames()
		var accounts: ResourceAccountsView = panel._accounts_view
		for i in accounts.selector.item_count:
			if accounts.selector.get_item_metadata(i) == "all:wood": accounts.selector.select(i)
		accounts.selector.item_selected.emit(accounts.selector.selected)
		check(accounts.copy.text.contains("實際收入 30") and accounts.copy.text.contains("已付支出 20"), "gross text " + str(vp))
		check(accounts.selector.size.y >= 44, "selector hit")
		check(accounts.selector.get_popup().get_theme_constant("v_separation") >= 28, "popup row hit")
		panel._body_scroll.ensure_control_visible(accounts.selector)
		await frames()
		check(panel._body_scroll.get_global_rect().encloses(accounts.selector.get_global_rect()), "selector reachable")
		check(accounts.get_global_rect().end.x <= panel._body_scroll.get_global_rect().end.x, "no horizontal overflow")
		check(panel._body_scroll.get_global_rect().end.y <= panel._footer.get_global_rect().position.y + 1, "fixed footer")
		await shot("accounts-%dx%d" % [vp.x,vp.y])
		panel._body_scroll.scroll_vertical = 100000
		await frames()
		await shot("table-%dx%d" % [vp.x,vp.y])
		panel._on_reincarnate_action_pressed()
		check(panel._confirming, "explicit confirmation")
		var before: Dictionary = abode.session.get_resource_accounts()
		panel._cancel_confirmation()
		check(abode.session.get_resource_accounts() == before, "cancel read only")
	var precise: Dictionary = abode.session.get_resource_accounts()
	precise.rows["home:wood"] = {"opening":"0", "closing":"1999.998", "income":{"production":"1999.998"}, "expense":{}, "adjustment":"0", "overflow":"0"}
	panel._accounts_view.show_book(precise)
	check(panel._accounts_view.copy.text.contains("1999.998"), "table keeps fractional amounts near integers")
	# Existing save protection reads the exact sealed book and keeps its retry fixed.
	check(abode.session.reincarnate().ok, "transfer")
	abode._pending_life_report = abode.session.get_life_report(abode.session.state.reincarnation_count)
	abode._show_storage_block("隔離驗收：此世已結算；保存失敗。")
	await frames()
	var views: Array = abode._storage_block_layer.find_children("*", "ResourceAccountsView", true, false)
	var sealed_views := 0
	for view in views:
		if view._book == abode._pending_life_report.life.get("accounts", {}): sealed_views += 1
	check(sealed_views == 1, "sealed account readable under protection")
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		await frames()
		var reading: ScrollContainer = abode._storage_block_layer.find_child("PendingLifeReading", true, false)
		reading.scroll_vertical = 100000
		await frames()
		check(reading.size.y >= 100, "protection scroll")
		await shot("protection-%dx%d" % [vp.x,vp.y])
	abode._storage_block_layer.queue_free()
	abode._storage_block_layer = null
	paused = false
	abode.queue_free()
	await process_frame
	print("REPORT-1B UI ", checks, " checks failures=", failures)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)


