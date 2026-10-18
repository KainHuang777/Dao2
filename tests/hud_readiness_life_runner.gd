extends SceneTree
var checks := 0
var failed := false
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)
func frames() -> void:
	for n in 10: await process_frame
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://hud-readiness-life"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var session: GameSession = abode.session
	var hud = abode._hud_controller
	session.state.level = 5
	for id in ["hut","storage_lingli","storage_wood","storage_stone"]: session.state.buildings[id] = 1
	for id in ["lingli","wood","stone_low"]: session.state.resources[id].unlocked = true
	var req := Cultivation.next_level_required_seconds(abode.content.era(1),5,0.0,1.0)
	session.state.training_seconds = req - 0.1
	for id in ["lingli","wood"]: session.state.resources[id].value = AmountCompat.from_number(200)
	session.state.resources.stone_low.value = AmountCompat.zero()
	abode._refresh_hud()
	check(not session.get_view().training_complete and not abode.level_up_button.visible,"rounding cannot imply training complete")
	check(abode.realm_progress_label.text == "修煉 104 / 105 秒","fractional threshold cannot show105/105 early")
	session.state.training_seconds = req
	abode._refresh_hud()
	check(abode.level_up_button.visible and abode.level_up_button.disabled,"complete but short resources exposes disabled action")
	check(abode.realm_progress_label.text == "修煉 105 / 105 秒","complete threshold shows full displayed progress")
	check(hud._rank_label.text.contains("下品靈石") and abode.level_up_button.tooltip_text.contains("需要 40"),"visible missing resource and exact tooltip")
	check(session.get_view().level_up_missing_resources.stone_low.required == "40","View reports actual graded material")
	session.state.training_seconds = req - CommandProcessor.AFFORD_TOLERANCE * 0.5
	session.state.resources.stone_low.value = AmountCompat.from_number(40)
	check(session.get_view().can_level_up,"View training tolerance matches command")
	check(session.submit({"command_id":"tolerance-level","type":"level_up_cultivation","expected_revision":session.state.revision,"payload":{}}).ok,"same tolerance accepted by real command")
	session.state.level = 5
	session.state.training_seconds = req
	session.state.buildings.stone_mine = 1
	session.state.resources.stone_low.value = AmountCompat.from_number(39.99)
	abode._refresh_hud()
	check(abode.level_up_button.disabled,"short before production")
	session.advance_time(1.0)
	abode._refresh_hud(false)
	check(abode.level_up_button.visible and not abode.level_up_button.disabled,"one production tick enables immediately without15s save")
	check(abode.level_up_button.text == "修為晉階","ready action restored")
	abode.level_up_button.pressed.emit()
	check(session.state.level == 6 and session.state.training_seconds == 0,"real HUD command advances and resets training")
	abode.breakthrough_seq.hide()
	var base: Dictionary = session.get_view()
	base.level = 5
	base.next_level_required_seconds = req
	base.training_seconds = req
	base.training_complete = true
	base.can_level_up = false
	base.level_up_missing_resources = {"lingli":{"required":"50","available":"0"},"wood":{"required":"40","available":"0"},"stone_low":{"required":"40","available":"0"}}
	base.max_lifespan_seconds = 4800.0
	var cases := [[0.0,"39734d"],[1599.9,"39734d"],[1600.0,"907000"],[3199.9,"907000"],[3200.0,"b45a18"],[4319.9,"b45a18"],[4320.0,"b43832"],[4799.9,"b43832"],[4800.0,"b43832"],[5000.0,"b43832"]]
	for item in cases:
		base.total_elapsed_seconds = item[0]
		hud._refresh_hud(base)
		check(hud._lifespan_text.get_theme_color("font_color") == Color(item[1]),"lifespan stage %s" % item[0])
		check(hud._lifespan_text.get_parent().get_child(0).tint == Color(item[1]),"icon matches lifespan stage")
		var used := mini(80,int(floor(float(item[0])/60.0)))
		check(hud._lifespan_text.text == "壽元 %d / 80 祀" % used,"cumulative age floors and clamps")
		if item[0] >= 4800.0: check(abode.level_up_button.disabled,"expired cannot offer enabled action")
	base.total_elapsed_seconds = 4320.0
	base.max_lifespan_seconds = 7200.0
	hud._refresh_hud(base)
	check(hud._lifespan_text.text == "壽元 72 / 120 祀" and hud._lifespan_text.get_theme_color("font_color") == Color("907000"),"life extension keeps age and reevaluates proportion")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		hud._refresh_hud(base)
		await frames()
		check(abode.header.get_global_rect().encloses(abode.level_up_button.get_global_rect()),"readiness action inside HUD %s" % vp)
		check(abode.level_up_button.size.y >= 44,"44px action")
		check(hud._lifespan_text.get_line_count() == 1,"age remains single line")
		check(abode.header.get_global_rect().encloses(hud._rank_label.get_global_rect()),"multiple shortages wrap inside HUD")
	abode.queue_free()
	await process_frame
	print("HUD readiness/life %d checks failed=%s" % [checks,failed])
	quit(1 if failed else 0)
