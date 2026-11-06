extends SceneTree
var failures := []
var checks := 0
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok: failures.append(note); print("FAIL ", note)
func _init() -> void: run.call_deferred()
func frames() -> void:
	for i in 6: await process_frame
func button(node: Node, value: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == value: return child
		var found := button(child, value)
		if found != null: return found
	return null
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	SaveManager._content = content
	var state: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
	state = SectLife.prepare(state)
	state.sect.entry = SectEntry.initial()
	state.sect.entry.skip = true
	SectLife.advance(state, 1, true)
	var panel := SectPanel.new()
	root.add_child(panel)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280,720)
	panel.set_layout_bounds(Rect2(20,20,1240,640))
	panel.update_view(state)
	panel._switch_tab(SectPanel.TabMode.FELLOWS)
	await frames()
	var before := state.to_snapshot_dict()
	var heading := panel._folio._reading.get_node("PersonHeading")
	check(panel._folio._name_label.text == "·\n沈\n照\n微\n·", "vertical name uses direction-neutral seals")
	check(heading.find_child("AffinityAmount", true, false).text == "交情  0／100", "affinity number remains exact and separate from rank")
	check(heading.find_child("AffinityProgress", true, false).value == 0, "affinity progress reads actual value including zero")
	check(heading.find_child("AffinityAmount", true, false).size.y < 40, "affinity is a full short phrase, never wrapped character by character")
	check(panel._folio._reading.get_node("StoryProse").get_theme_font_size("font_size") >= 18, "story prose keeps readable 18px")
	check(panel._folio._actions.get_child_count() == 3, "all three choices and rewards have fixed visible groups")
	check(button(panel, "逐字校勘").get_parent().get_node("ChoiceReward").text.contains("貢獻 +2"), "reward stays adjacent to its actual choice")
	panel._folio._reading.get_node("StoryProse").text = "長文測試。".repeat(300)
	await frames()
	check(panel._folio._scroll_hint.text.contains("下方尚有內文"), "overflow tells readers to scroll")
	panel._folio._scroll.scroll_vertical = int(panel._folio._scroll.get_v_scroll_bar().max_value)
	await frames()
	check(panel._folio._scroll_hint.text == "已讀至內文末尾", "scroll hint updates at actual end")
	for tab in [panel._tab_expeditions_btn, panel._tab_techniques_btn, panel._tab_market_btn, panel._tab_fellows_btn, panel._tab_tournament_btn]:
		check(tab.secondary and tab.size.y >= 44 and tab.focus_mode == Control.FOCUS_ALL, "inner tabs retain 44px and keyboard access")
		check(tab.get_theme_stylebox("normal").border_width_right > 0, "idle and selected tabs have visible divisions")
	for mode in [SectPanel.TabMode.EXPEDITIONS, SectPanel.TabMode.TECHNIQUES, SectPanel.TabMode.MARKET, SectPanel.TabMode.TOURNAMENT, SectPanel.TabMode.FELLOWS]:
		panel._switch_tab(mode)
		await frames()
		check(panel._current_tab == mode and panel.get_global_rect().encloses(panel._tab_row.get_global_rect()), "inner navigation stays inside paper")
	check(panel._folio.visible and not panel._scroll.visible, "fellow folio occupies existing paper")
	check(panel._tab_row.vertical and panel._tab_row.get_global_rect().end.x <= panel._right_stage.global_position.x + 1, "sect sub-tabs consolidated on left rail")
	check(panel._folio._reading_col.size.y >= 560, "fellow reading column spans full top-to-bottom height")
	check(panel._folio._art.texture != null, "accepted portrait loaded")
	check(button(panel, "逐字校勘") != null, "frozen pending choices readable")
	var action := button(panel, "逐字校勘")
	action.grab_focus()
	SectLife.advance(state, 1, true)
	panel.update_view(state)
	await frames()
	check(is_instance_valid(action) and action == button(panel, "逐字校勘"), "tenure tick keeps controls and keyboard focus")
	check(action.has_focus(), "keyboard focus survives tick")
	var commands := []
	panel.reform_action_requested.connect(func(kind: String, option: String): commands.append([kind, option]))
	action.pressed.emit()
	check(commands == [["story:" + state.sect.life.pending_story.instance_id, "A"]], "signal carries exact instance and option")
	var after := state.to_snapshot_dict()
	before.sect.life.tenure_seconds = after.sect.life.tenure_seconds
	check(SectLifeSave.same(before, after), "render and click never mutate inventory or RNG")
	check(panel._folio.get_global_rect().encloses(action.get_global_rect()), "fixed action inside folio")
	for child in panel._folio._actions.get_children(): check(child.size.y >= 44, "44px action")
	var instance: String = state.sect.life.pending_story.instance_id
	var text: Dictionary = SectLife.view(state).story_text
	check(SectLife.resolve(content, state, {"instance_id":instance,"option_id":"B"}).ok, "resolve through authoritative rules")
	panel._folio.resolved(text.responses.B)
	panel.update_view(state)
	await frames()
	check(button(panel, "逐字校勘") == null, "resolved instance no longer actionable")
	button(panel, "最近記錄").pressed.emit()
	await frames()
	check(panel._folio.records and panel._folio._reading.get_child_count() >= 3, "bounded records with response")
	for mode in [SectPanel.TabMode.EXPEDITIONS, SectPanel.TabMode.TECHNIQUES, SectPanel.TabMode.MARKET]:
		panel._switch_tab(mode)
		check(panel._scroll.visible and not panel._folio.visible, "original tab retained %d" % mode)
	state.sect.life.pending_story = SectLife.frozen("tx_book_return", "later", 240, 0, false)
	panel.update_view(state)
	panel._folio.records = false
	panel._folio.selected_npc = 0
	panel._switch_tab(SectPanel.TabMode.FELLOWS)
	panel._folio._rebuild()
	await frames()
	check(button(panel, "列出索引") != null and button(panel, "列出索引").tooltip_text.begins_with("貢獻 +0"), "branch callback and frozen zero contribution")
	panel._pending_save = true
	panel.update_view(state)
	check(button(panel, "列出索引").disabled, "save failure locks story")
	panel._pending_save = false
	panel._folio.records = true
	var unjoined := GameSession.create_new_game(content, 45).state
	unjoined.era_id = 2
	panel.update_view(unjoined)
	await frames()
	check(panel._folio.gate and panel._folio._art.texture != null, "gate illustration and selected sect")
	check(panel._sub_selector_host.visible and panel._sub_selector_host.get_child_count() == 5, "five sect gate tabs consolidated on left rail")
	check(panel._folio._scroll.size.y >= 560, "gate reading scroll spans full top-to-bottom height")
	check(panel._folio._reading.get_node("GateTitle").get_theme_font_size("font_size") == 28, "gate name has a distinct shared title role")
	check(panel._folio._reading.get_node("GateFlavor").get_theme_font_size("font_size") == 20, "gate flavor remains distinct from body")
	check(panel._folio._scroll_hint.visible, "gate retains overflow reading affordance")
	check(panel._folio._art.visible, "gate art survives previous records view")
	check(panel._folio._response.is_empty(), "new life clears transient response")
	button(panel, "天劍聖宗").pressed.emit()
	await frames()
	check(panel._folio.selected_sect == "天劍聖宗" and panel._folio._art.texture != null, "selected sect gate loaded")
	for sect in SectSystem.SECT_NAMES:
		button(panel, sect).pressed.emit()
		await frames()
		var sid := SectIdentity.canonical_id(sect)
		var stem := sid.trim_suffix("_sect")
		check(panel._folio._art.texture.resource_path == "res://assets/ui/sect-life/" + stem + "-gate-portrait.png", "portrait gate in tall folio " + sid)
		var art := panel._folio._art
		check(art.texture.get_width() * 3 == art.texture.get_height() * 2, "composed 2:3 portrait " + sid)
		check(art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "full uncropped gate never blocks input " + sid)
		var drawn := art.texture.get_size() * minf(art.size.x / art.texture.get_width(), art.size.y / art.texture.get_height())
		check(drawn.y >= art.size.y * 0.75, "portrait fills tall art stage " + sid)
		if OS.get_environment("DAO_GATE_CAPTURE") == "1" and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://.test-output/gate-portrait/" + stem + ".png") == OK, "native gate capture " + sid)
		panel.set_layout_bounds(Rect2(20,20,1240,280))
		await frames()
		check(art.texture.resource_path == "res://assets/ui/sect-life/" + stem + "-gate.png", "short folio retains panorama " + sid)
		panel.set_layout_bounds(Rect2(20,20,1240,640))
		await frames()
		check(art.texture.resource_path.ends_with("-gate-portrait.png"), "portrait restored after resize " + sid)
	button(panel, "天劍聖宗").pressed.emit()
	var joins := []
	panel.join_sect_requested.connect(func(id: String): joins.append(id))
	button(panel, "立誓拜入「天劍聖宗」").pressed.emit()
	check(joins == ["天劍聖宗"], "single oath targets selected sect")
	for sid in SectIdentity.NAMES:
		var member: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
		SectIdentity.write(member.sect,sid)
		SectLineage.observe(member)
		member.sect.available_tasks = []
		SectSystem.refresh_tasks(member)
		member = SectLife.prepare(member)
		member.sect.entry = SectEntry.initial()
		member.sect.entry.skip = true
		SectLife.advance(member,1,true)
		panel._folio.records = false
		panel._folio.selected_npc = 0
		panel.update_view(member)
		panel._switch_tab(SectPanel.TabMode.FELLOWS)
		await frames()
		var names := SectLife.table(sid,"names")
		var prose := SectLifeContent.read(member.sect.life.pending_story.template_id,{})
		check(button(panel,names[0]) != null and button(panel,names[1]) != null and button(panel,names[2]) != null,"three local names "+sid)
		check(button(panel,prose.A) != null and button(panel,prose.A).size.y >= 44,"local chapter and44px action "+sid)
		var captured := member.to_snapshot_dict()
		panel._folio.selected_npc = 2
		panel._folio._rebuild()
		await frames()
		check(button(panel,"查看%s的訪帖" % names[0]) != null,"local pending owner "+sid)
		check(SectLifeSave.same(captured,member.to_snapshot_dict()),"navigation readonly "+sid)
		for index in 3:
			button(panel, names[index]).pressed.emit()
			await frames()
			var npc: String = SectLife.table(sid, "npcs")[index]
			var portrait := npc.substr(npc.find("_") + 1).replace("_", "-")
			check(panel._folio._art.texture.resource_path == "res://assets/ui/sect-life/" + portrait + ".png", "exact named portrait " + npc)
			check(panel._folio._art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "uncropped portrait " + npc)
			check(panel._folio._art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "art never blocks input " + npc)
	panel.queue_free()
	await frames()
	print("SECT-LIFE UI ", checks, " checks; failures=", failures)
	print(JSON.stringify({"result":"pass" if failures.is_empty() else "fail", "checks":checks, "failures":failures}))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
