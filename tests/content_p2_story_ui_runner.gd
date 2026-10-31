extends "res://tests/content_p2_story_runner.gd"
## Synthetic per-ID presentation coverage, separate from the earned flow runner.
var OUT := (OS.get_environment("DAO_TEST_STORAGE_ROOT") if not OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else "res://.test-output").path_join("story2-ui/")
func frames() -> void:
	for i in 6: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var glyphs := {}
	var copy := JSON.stringify(AchievementSystem.P2_DEFINITIONS)
	for encounter in FortuneSystem.get_encounters():
		if encounter.get("content_batch") == "content-p2-story": copy += JSON.stringify(encounter)
	for index in copy.length():
		var code := copy.unicode_at(index)
		if code >= 0x3400 and code <= 0x9fff: glyphs[code] = true
	for code in glyphs:
		check(UiTypography.BASE_FONT.has_char(code),"P2 sans glyph U+%04X" % code)
		check(UiTypography.CHAPTER_FONT.has_char(code),"P2 serif glyph U+%04X" % code)
	load("res://src/abode/living_abode.gd").save_dir_override = OUT+"native-storage"
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames(); await frames()
	abode.set_process(false); abode.offline_summary.hide(); abode.v2_rules_notice.hide()
	content = abode.content
	var s := fresh()
	abode.session.state = s.state
	abode.session.clock = GameClock.create(s.state.total_elapsed_seconds)
	var panel: AchievementPanel = abode.achievement_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp; root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp)); abode._refresh_hud(); abode.feature_navigation.open("achievements"); await frames()
		check(panel._achievement_items.size()==64,"64 achievement cards (48 formal + 16 lineage)")
		for id in AchievementSystem.P2_DEFINITIONS:
			var card: Control = panel._achievement_items[id]
			panel._scroll.ensure_control_visible(card); await frames()
			var action: Button = card.get_node("HBox/Badge/Action")
			check(card.get_node("HBox/Badge").texture != null,id+" actual art")
			check(card.size.x <= panel._scroll.size.x+1,id+" card width")
			check(action.size.x>=44 and action.size.y>=44,id+" 44px")
			check(panel._scroll.get_global_rect().encloses(action.get_global_rect()),id+" reachable")
			check(not card.tooltip_text.is_empty(),id+" condition tooltip")
			check(action is GraphicAction and action.text.is_empty(), id+" artwork claim target")
			check(action.get_global_rect() == card.get_node("HBox/Badge").get_global_rect(), id+" badge owns hit area")
			if id in ["p2_deep_student","p2_mature_stag","p2_three_memories"]: await shot("native-"+str(vp.x)+"-"+id)
		var probe: Dictionary = s.get_view().achievements.achievements.filter(func(a): return a.id == "p2_deep_student")[0].duplicate(true)
		var probe_card: PanelContainer = panel._achievement_items[probe.id]
		probe.can_claim = true; probe.claimed = false; probe.reason = ""
		panel._update_card(probe_card, probe)
		var hit: GraphicAction = probe_card.get_node("HBox/Badge/Action")
		check(not hit.disabled and hit.attention, "claimable badge has permanent affordance")
		probe.claimed = true; probe.can_claim = false
		panel._update_card(probe_card, probe)
		check(hit.disabled and not hit.attention and not hit.is_processing(), "claimed badge stops pulse and rejects input")
		check(probe_card.get_node("HBox/Info/State").has_theme_stylebox_override("normal"), "claimed badge shows ink stamp")
		await frames()
		check(probe_card.get_node("HBox/Info/State").get_line_count() == 1, "stamp stays horizontal instead of wrapping one character per line")
		for def in FortuneSystem.get_encounters():
			if def.get("content_batch") != "content-p2-story": continue
			invite(s,def)
			abode.offline_summary.hide()
			abode._refresh_hud(); abode.feature_navigation.open("fortune")
			abode.fortune_modal.refresh(s.get_view())
			await frames()
			var modal: FortuneModal = abode.fortune_modal
			check(modal._art.texture != null,def.id+" art")
			check(modal._option_rows.size()==3,def.id+" 3 choices")
			if modal._option_rows.size()!=3: continue
			for index in 3:
				var row: Dictionary = modal._option_rows[index]
				modal._body_scroll.ensure_control_visible(row.button); await frames()
				check(row.button.size.x>=44 and row.button.size.y>=44,def.id+" option44")
				check(row.button.icon != null and row.button.text == def.options[index].text,def.id+" illustrated action identifies decision")
				check(modal._body_scroll.get_global_rect().encloses(row.button.get_global_rect()),def.id+" option reachable")
				if index==2:
					var labels: Array = row.card.find_children("*","Label",true,false)
					check(labels.any(func(l): return l.text=="固定效果：不支付、不取得額外收益"),def.id+" explicit free departure")
			if def.art in ["frontier","herbarium"]: await shot("native-"+str(vp.x)+"-"+def.id)
		var timer_view := s.get_view().duplicate(true)
		timer_view.fortune.has_pending = false
		timer_view.fortune.pending_encounter = {}
		timer_view.fortune.cooldown_total = 900.0
		timer_view.fortune.cooldown_remaining = 60.1
		var modal: FortuneModal = abode.fortune_modal
		modal.refresh(timer_view); await frames()
		check(modal._trigger_btn.text == "神識推演" and modal._trigger_btn.disabled, "cooldown independent of action text")
		check(modal._timer_label.text == "感應蓄力  01:01", "countdown ceil avoids early ready")
		check(is_equal_approx(modal._timer_bar.value,839.9), "bar from authoritative remaining and cycle")
		check(modal._timer_label.get_theme_color("font_color") == GraphicAction.COOL, "countdown state color")
		check(modal.get_global_rect().encloses(modal._timer_box.get_global_rect()), "countdown stays in fixed visible footer")
		await shot("native-"+str(vp.x)+"-timer-countdown")
		timer_view.fortune.cooldown_remaining = 0
		modal.refresh(timer_view); await frames()
		check(not modal._trigger_btn.disabled and modal._timer_label.text == "感應就緒", "ready reenables same action")
		check(modal._timer_label.get_theme_color("font_color") == GraphicAction.JADE and modal._timer_bar.value == 900, "ready has distinct color and full bar")
		var graphic: GraphicAction = modal._trigger_btn
		graphic.present(true, true)
		check(not graphic.is_processing(), "reduced motion keeps static affordance")
		graphic.present(false)
		check(not graphic.is_processing(), "inactive action stops animation")
		await shot("native-"+str(vp.x)+"-timer-ready")
		abode.feature_navigation.home(); await frames()
		check(not panel.visible and not abode.fortune_modal.visible,"return to world")
	var receipt := {"life_id":1,"at":1,"title":"測試","option":"A","log":"","resources":{},"training":{"before":100,"nominal":120,"gained":10,"overflow":110,"after":110},"pills":{},"buff":{}}
	var text := DecisionBookView.receipt_text(receipt)
	check("實增 10" in text and "捨棄 110" in text and "標稱 120" in text,"actual clipped training receipt readable")
	var file := FileAccess.open(OUT+"ui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L2","checks":checks,"failures":failures,"boundary":"Synthetic per-ID presentation/geometry; not earned progression or real mouse evidence"},"\t"))
	print("STORY2 UI ",checks," failures=",JSON.stringify(failures))
	abode.queue_free(); await frames()
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
