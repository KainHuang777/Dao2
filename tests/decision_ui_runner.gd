extends SceneTree
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok: failures.append(msg)
func frames() -> void:
	for n in 18: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://docs/verification/artifacts/decision-1/" + name + ".png"))
func run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = (OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("decision-ui-runner")
	SaveSlots.new(FileStorageAdapter.new((OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("decision-ui-runner"))).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.reduced = true
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel: FortuneModal = abode.fortune_modal
	var state: GameState = abode.session.state
	state.reincarnation_count = 1
	StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
	state.life_ledger = {}
	LifeLedger.initialize(state, true)
	FortuneSystem.ensure_initialized(state)
	for enc in FortuneSystem.get_encounters():
		if enc.id == "enc_wandering_taoist": state.fortune.pending_encounter = enc.duplicate(true)
	state.resources.spirit_grass_low.value = AmountCompat.from_number(50)
	state.revision += 1
	abode.feature_navigation.open("fortune")
	abode._refresh_hud()
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		check(panel._body_scroll.size.y >= 70, "pending scroll " + str(vp))
		check(panel._book_button.size.y >= 44, "book hit")
		check(panel._story.get_global_rect().end.x <= panel.get_global_rect().end.x, "no overflow")
		panel._body_scroll.ensure_control_visible(panel._option_rows.back().button)
		await frames()
		check(panel._body_scroll.get_global_rect().encloses(panel._option_rows.back().button.get_global_rect()), "last option reachable " + str(vp) + " body=" + str(panel._body_scroll.get_global_rect()) + " option=" + str(panel._option_rows.back().button.get_global_rect()))
		panel._body_scroll.scroll_vertical = 0
		await frames()
		await shot("pending-%dx%d" % [vp.x,vp.y])
	var id := panel.displayed_instance
	abode.feature_navigation.home()
	state.resources.spirit_grass_low.value = AmountCompat.from_number(0)
	state.revision += 1
	abode.feature_navigation.open("fortune")
	abode._refresh_hud()
	check(panel.displayed_instance == id and panel._option_rows[0].button.disabled, "reopen same pending fresh shortage")
	state.resources.spirit_grass_low.value = AmountCompat.from_number(50)
	state.revision += 1
	abode._refresh_hud()
	panel._option_rows[0].button.pressed.emit()
	check(abode.session.get_decision_book().receipts.size() == 1, "routed settlement")
	check(panel._book.copy.text.contains("已付 20") and panel._book.visible, "inline actual paid")
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		panel._body_scroll.scroll_vertical = 100000
		await frames()
		# The accepted fixed timer reserves 44px; the shortest layout must still
		# expose two full body-text lines and allow scrolling to the receipt end.
		check(panel._body_scroll.size.y >= 2.0 * UiTypography.BASE_FONT.get_height(18), "two receipt lines " + str(vp) + " body=" + str(panel._body_scroll.size))
		check(panel._body_scroll.scroll_vertical + panel._body_scroll.size.y >= panel._encounter_panel.size.y - 2.0, "receipt end reachable " + str(vp))
		check(panel.get_global_rect().encloses(panel._book_button.get_global_rect()) or panel._book_button.get_global_rect().position.y < panel.get_global_rect().position.y, "book inside content scroll")
		await shot("receipt-%dx%d" % [vp.x,vp.y])
		abode.feature_navigation.open("reincarnation")
		abode._refresh_hud()
		var rc = abode.reincarnation_panel
		rc._decision_toggle.button_pressed = true
		rc._decision_toggle.pressed.emit()
		await frames()
		rc._body_scroll.scroll_vertical = 100000
		await frames()
		check(rc._decision_view.visible and rc._decision_view.copy.text.contains("已付 20"), "report same receipt")
		check(rc._body_scroll.get_global_rect().end.y <= rc._footer.get_global_rect().position.y + 1, "fixed footer")
		await shot("book-%dx%d" % [vp.x,vp.y])
		abode.feature_navigation.open("fortune")
		abode._refresh_hud()
	abode._show_storage_block("隔離測試：結果已結算，保存失敗；請重試。")
	await frames()
	var sealed_views := 0
	var sealed_key := JSON.stringify(abode.session.get_decision_book(), "", true) + str(false)
	for view in abode._storage_block_layer.find_children("*", "DecisionBookView", true, false):
		if view.is_visible_in_tree() and view._key == sealed_key: sealed_views += 1
	check(sealed_views == 1, "protection read receipt")
	await shot("protection-800x360")
	abode._storage_block_layer.queue_free()
	abode._storage_block_layer = null
	paused = false
	abode.queue_free()
	await process_frame
	print("DECISION-UI ", checks, " checks failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

