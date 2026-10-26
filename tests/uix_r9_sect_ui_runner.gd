extends SceneTree
var checks := 0
var failed := false
class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://uix-r9-fault" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r9-fault"))
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok":false,"error":"R9_WRITE_DENIED"} if fail_writes else backend.write(key,value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(label)
func frames() -> void:
	for n in 12: await process_frame
func buttons(node: Node, text: String = "") -> Array[Button]:
	var result: Array[Button] = []
	if node is Button and (text.is_empty() or node.text == text): result.append(node)
	for child in node.get_children(): result.append_array(buttons(child,text))
	return result
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r9-runner" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("uix-r9-runner")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.feature_navigation.shell.apply(abode.hud.size)
	var nav = abode.feature_navigation
	nav.open("sect")
	var panel: SectPanel = abode.sect_panel
	check(buttons(panel,"需達築基期").size() == 5,"five locked sect choices")
	abode.session.state.era_id = 2
	for id in abode.content.resource_ids:
		abode.session.state.resources[id].value = AmountCompat.from_number(10000)
	abode._refresh_hud()
	check(buttons(panel,"立誓拜入").size() == 5,"five eligible sect choices")
	buttons(panel,"立誓拜入")[0].pressed.emit()
	check(abode.session.state.sect.unlocked,"real routed join")
	check(panel._feedback.text.contains("保存"),"join feedback in visible panel")
	abode.session.state.sect.contribution = "1000"
	abode._refresh_hud()
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(abode.content,adapter)
	panel._switch_tab(SectPanel.TabMode.TECHNIQUES)
	adapter.fail_writes = true
	buttons(panel,"參悟提升")[0].pressed.emit()
	check(abode.session.state.sect.techniques.divine_farm == 1,"real technique upgrade")
	check(abode.session.state.sect.contribution == "950","technique deducted50")
	check(panel._pending_save and panel._retry.visible,"failed write remains explicit")
	var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
	panel._retry.pressed.emit()
	check(snapshot == abode.session.state.to_snapshot_dict() and panel._pending_save,"failed retry cannot upgrade twice")
	adapter.fail_writes = false
	panel._retry.pressed.emit()
	check(not panel._pending_save and snapshot == abode.session.state.to_snapshot_dict(),"save retry no double deduction")
	SaveManager.configure(abode.content,ToggleAdapter.new())
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and loaded.sect.techniques.divine_farm == 1 and loaded.sect.contribution == "950","disk reload retains upgrade and exact cost")
	panel._switch_tab(SectPanel.TabMode.MARKET)
	buttons(panel,"兌換物資")[0].pressed.emit()
	check(abode.session.state.sect.market_purchases.herb_bundle == 1 and abode.session.state.sect.contribution == "920","market exact contribution deduction")
	panel._switch_tab(SectPanel.TabMode.EXPEDITIONS)
	var tasks: Array = abode.session.state.sect.available_tasks
	var dispatches := buttons(panel).filter(func(b): return b.name == "Dispatch")
	check(dispatches.size() == tasks.size(), "one image dispatch per task")
	check(dispatches.all(func(b): return b.text.is_empty() and b.icon != null and b.get_theme_stylebox("normal") is StyleBoxEmpty), "image dispatch without text or frame")
	dispatches[0].pressed.emit()
	check(abode.session.state.sect.active_expedition != null,"real expedition start")
	check(buttons(panel).filter(func(b): return b.name == "Dispatch").all(func(b): return b.disabled),"one active expedition blocks dispatch")
	var stable: Button = buttons(panel,"歷練中")[0]
	SectSystem.tick(abode.session.state,1)
	abode._refresh_hud()
	check(buttons(panel,"歷練中")[0] == stable,"countdown keeps mouse target")
	abode.session.advance_time(1000)
	abode._refresh_hud()
	check(buttons(panel,"領取獎勵").size() == 1,"completed reward action")
	var before: String = abode.session.state.sect.contribution
	buttons(panel,"領取獎勵")[0].pressed.emit()
	check(abode.session.state.sect.active_expedition == null and abode.session.state.sect.contribution != before,"claim actual rewards")
	check(not abode.session.claim_sect_expedition().ok,"repeat claim rejected")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		for tab in [SectPanel.TabMode.EXPEDITIONS,SectPanel.TabMode.TECHNIQUES,SectPanel.TabMode.MARKET]:
			panel._switch_tab(tab)
			await frames()
			check(panel.get_global_rect().encloses(panel._scroll.get_global_rect()),"scroll in paper vp=%s tab=%s panel=%s scroll=%s" % [vp,tab,panel.get_global_rect(),panel._scroll.get_global_rect()])
			check(panel._scroll.size.y >= 60,"readable compact content")
			if tab == SectPanel.TabMode.EXPEDITIONS:
				check(panel._tab_content_container.get_child(1).size.y <= 64,"task heading cannot collapse into vertical text")
			check(panel._tab_techniques_btn is GameTab and panel._close_button is CloseSeal,"shared controls")
			for art in panel._art_nodes: check(art.texture != null,"runtime painted image")
			for button in buttons(panel._tab_content_container): check(button.size.y >= 44,"44px actions")
			for grid in panel._grids:
				check(grid.columns == (2 if vp.x == 1280 else 1),"desktop grid compact single column")
				check(grid.size.x <= panel._scroll.size.x + 1,"grid width bounded")
			var header_y: float = panel._header_container.global_position.y
			panel._scroll.scroll_vertical = 10000
			await frames()
			check(is_equal_approx(header_y,panel._header_container.global_position.y),"fixed header")
			var last: Button = buttons(panel._tab_content_container).back()
			check(panel._scroll.get_global_rect().encloses(last.get_global_rect()),"last action reachable vp=%s tab=%s scroll=%s button=%s" % [vp,tab,panel._scroll.get_global_rect(),last.get_global_rect()])
			check(last.get_global_rect().end.y <= panel.get_global_rect().end.y - (20 if vp.y >= 500 else 14) + 1,"scroll rod safety")
			panel._scroll.scroll_vertical = 0
		if abode.offline_summary.visible: abode.offline_summary._on_close_pressed()
		abode.v2_rules_notice.hide()
		nav.shell.apply(abode.hud.size)
		nav.home()
		check(not panel.visible,"return home")
		nav.open("sect")
		await frames()
		check(not nav.bar.get_global_rect().intersects(abode.settings_menu.get_global_rect()),"close clears settings after reopen")
		var joined: Dictionary = abode.session.state.sect.duplicate(true)
		abode.session.state.sect = {}
		abode._refresh_hud()
		panel._scroll.scroll_vertical = 0
		await frames()
		check(panel._scroll.get_global_rect().encloses(buttons(panel,"立誓拜入")[0].get_global_rect()),"first join action visible without scroll vp=%s scroll=%s button=%s" % [vp,panel._scroll.get_global_rect(),buttons(panel,"立誓拜入")[0].get_global_rect()])
		abode.session.state.sect = joined
		abode._refresh_hud()
	abode.session.state.sect.contribution = "0"
	abode._refresh_hud()
	panel._switch_tab(SectPanel.TabMode.MARKET)
	check(buttons(panel,"貢獻不足").size() >= 4,"legacy market shortage; P1 may separately show era/full destination")
	abode.session.state.sect.market_purchases.herb_bundle = 20
	abode._refresh_hud()
	check(buttons(panel,"售罄").size() == 1,"sold out")
	abode.session.state.sect.techniques.divine_farm = 10
	abode._refresh_hud()
	panel._switch_tab(SectPanel.TabMode.TECHNIQUES)
	check(buttons(panel,"已圓滿").size() == 1,"technique max")
	abode.queue_free()
	await process_frame
	print("UIX-R9 %d checks failed=%s" % [checks,failed])
	RunnerResult.finish(self, 1 if failed else 0)
