class_name M3bSectUiRunner
extends SceneTree

const UI_ICON_SCRIPT = preload("res://src/presentation/ui_icon.gd")

func _init() -> void:
	print("\n--- Running M3-B Sect UI Runner ---")
	test_sect_panel_lifecycle()
	test_responsive_layouts()
	test_gamesession_sect_command_integration()
	test_era_eligibility_button_states()
	print("PASS: M3-B sect UI, tabs, joining, expeditions, techniques, market, responsiveness, and GameSession integration.")
	quit(0)

func _create_test_state(era: int = 2) -> GameState:
	var state := GameState.new()
	state.era_id = era
	state.level = 1
	state.reincarnation_count = 0
	state.resources["money"] = {"value": AmountCompat.from_number(1000.0), "unlocked": true, "ever_obtained": true}
	state.resources["lingqi"] = {"value": AmountCompat.from_number(100.0), "unlocked": true, "ever_obtained": true}
	state.resources["wood"] = {"value": AmountCompat.from_number(1000.0), "unlocked": true, "ever_obtained": true}
	state.resources["stone_low"] = {"value": AmountCompat.from_number(200.0), "unlocked": true, "ever_obtained": true}
	state.resources["herb"] = {"value": AmountCompat.from_number(500.0), "unlocked": true, "ever_obtained": true}
	return state

func test_sect_panel_lifecycle() -> void:
	print("Testing SectPanel node creation, tabs and interactions...")
	var panel := SectPanel.new()
	root.add_child(panel)
	
	var state := _create_test_state(2)
	
	# Initial state: not joined yet
	panel.update_view(state)
	panel.set_layout_bounds(Rect2(0, 0, 1280, 720))
	assert(panel.clip_contents, "SectPanel must enable clip_contents")
	assert(panel._scroll.size.y < 720, "Scroll height must be bounded within panel size")
	
	# Join sect via signal
	var join_state := {"received": false}
	panel.join_sect_requested.connect(func(sect_name):
		join_state["received"] = true
		SectSystem.join_sect(state, sect_name)
		panel.update_view(state)
	)
	
	# Simulate joining
	panel.join_sect_requested.emit("紫霄玄門")
	assert(join_state["received"], "join_sect_requested signal should fire")
	assert(bool(state.sect.get("unlocked", false)), "State sect should be unlocked")
	
	# Switch tabs
	panel._switch_tab(SectPanel.TabMode.TECHNIQUES)
	assert(panel._current_tab == SectPanel.TabMode.TECHNIQUES, "Should switch to techniques tab")
	
	panel._switch_tab(SectPanel.TabMode.MARKET)
	assert(panel._current_tab == SectPanel.TabMode.MARKET, "Should switch to market tab")
	
	panel._switch_tab(SectPanel.TabMode.EXPEDITIONS)
	assert(panel._current_tab == SectPanel.TabMode.EXPEDITIONS, "Should switch back to expeditions tab")
	panel.update_view(state)
	var stable_card := panel._tab_content_container.get_child(0)
	panel.update_view(state)
	assert(panel._tab_content_container.get_child(0) == stable_card, "unchanged HUD updates preserve input targets")
	assert(_has_ui_icon(panel._tab_content_container, UI_ICON_SCRIPT.Kind.SCROLL), "Expedition list heading uses a Godot-drawn scroll icon")
	
	# Start expedition via signal
	var start_state := {"received": false}
	panel.start_expedition_requested.connect(func(task_id):
		start_state["received"] = true
		SectSystem.start_expedition(state, task_id)
		panel.update_view(state)
	)
	var tasks: Array = state.sect.get("available_tasks", [])
	assert(not tasks.is_empty(), "Tasks should be available")
	panel.start_expedition_requested.emit(tasks[0]["id"])
	assert(start_state["received"], "start_expedition_requested signal should fire")
	assert(state.sect.get("active_expedition") != null, "Active expedition should be set")
	assert(_has_ui_icon(panel._tab_content_container, UI_ICON_SCRIPT.Kind.HOURGLASS), "Active expedition heading uses a Godot-drawn hourglass icon")
	assert(not _has_emoji_glyph(panel._tab_content_container), "Sect expedition UI does not rely on emoji font glyphs")
	
	panel.queue_free()

func _has_ui_icon(node: Node, kind: int) -> bool:
	if node.get_script() == UI_ICON_SCRIPT and int(node.get("kind")) == kind:
		return true
	for child in node.get_children():
		if _has_ui_icon(child, kind):
			return true
	return false

func _has_emoji_glyph(node: Node) -> bool:
	if node is Label and _contains_emoji(String(node.text)):
		return true
	if node is Button and _contains_emoji(String(node.text)):
		return true
	for child in node.get_children():
		if _has_emoji_glyph(child):
			return true
	return false

func _contains_emoji(value: String) -> bool:
	for index in value.length():
		var codepoint := value.unicode_at(index)
		if (codepoint >= 0x1F300 and codepoint <= 0x1FAFF) or (codepoint >= 0x2600 and codepoint <= 0x27BF):
			return true
	return false

func test_responsive_layouts() -> void:
	print("Testing SectPanel responsive layouts...")
	var panel := SectPanel.new()
	root.add_child(panel)
	var state := _create_test_state(2)
	SectSystem.join_sect(state)
	panel.update_view(state)
	
	# Desktop 1280x720 modal bounds (e.g. 620x600 centered)
	panel.set_layout_bounds(Rect2(330, 60, 620, 600))
	assert(panel.size.x == 620 and panel.size.y == 600, "Desktop modal bounds set")
	assert(panel._scroll.size.y <= 600, "Desktop scroll height within modal")
	
	# Mobile Portrait 360x640
	panel.set_layout_bounds(Rect2(12, 12, 336, 616))
	assert(panel.size.x == 336 and panel.size.y == 616, "Portrait bounds set")
	assert(panel._scroll.size.y <= 616, "Portrait scroll height within modal")
	
	# Compact Height 360x480
	panel.set_layout_bounds(Rect2(12, 12, 336, 456))
	assert(panel.size.x == 336 and panel.size.y == 456, "Compact height bounds set")
	assert(panel._scroll.size.y <= 456, "Compact scroll height within modal")
	
	panel.queue_free()

func test_gamesession_sect_command_integration() -> void:
	print("Testing GameSession sect commands integration (KNOWN_COMMAND_TYPES)...")
	var content := GameContent.new()
	content.resource_ids = ["money", "lingqi", "wood", "stone_low", "herb"]
	content.building_ids = []
	for r in content.resource_ids:
		content.resources[r] = {"id": r, "type": "basic", "unlocked_at_era": 1}
	
	var session := GameSession.create_new_game(content)
	session.state.era_id = 2 # Era 2 Foundation period
	session.state.resources["money"] = {"value": AmountCompat.from_number(1000.0), "unlocked": true, "ever_obtained": true}
	
	# Test join_sect command via GameSession.submit
	var res := session.join_sect("天劍聖宗")
	assert(bool(res.get("ok", false)), "session.join_sect should succeed and not be rejected as UNKNOWN_COMMAND")
	assert(session.state.sect.get("unlocked", false) == true, "State sect unlocked after join")
	assert(session.state.sect.get("sect_name", "") == "天劍聖宗", "State sect name correctly set")
	
	# Test refresh_sect_tasks via session
	var ref_res := session.refresh_sect_tasks(true)
	assert(bool(ref_res.get("ok", false)), "session.refresh_sect_tasks should succeed")
	
	# Test start_sect_expedition via session
	var tasks: Array = session.state.sect.get("available_tasks", [])
	assert(not tasks.is_empty(), "Tasks generated")
	var start_res := session.start_sect_expedition(String(tasks[0]["id"]))
	assert(bool(start_res.get("ok", false)), "session.start_sect_expedition should succeed")

func test_era_eligibility_button_states() -> void:
	print("Testing SectPanel button states in Era 1 vs Era 2...")
	var panel := SectPanel.new()
	root.add_child(panel)
	
	# Era 1: Ineligible (buttons must be disabled)
	var state_era1 := _create_test_state(1)
	panel.update_view(state_era1)
	panel.set_layout_bounds(Rect2(0, 0, 620, 600))
	
	var buttons_found := 0
	for child in panel._tab_content_container.get_children():
		if child is PanelContainer:
			for row_child in child.get_children():
				if row_child is HBoxContainer:
					for sub in row_child.get_children():
						if sub is Button:
							buttons_found += 1
							assert(sub.disabled == true, "Join button in Era 1 must be disabled")
							assert(sub.text == "需達築基期", "Button text should explain foundation requirement")
	assert(buttons_found == 5, "5 sect cards should have disabled join buttons in Era 1")
	
	# Era 2: Eligible (buttons must be enabled)
	var state_era2 := _create_test_state(2)
	panel.update_view(state_era2)
	panel.set_layout_bounds(Rect2(0, 0, 620, 600))
	
	var enabled_buttons := 0
	for child in panel._tab_content_container.get_children():
		if child is PanelContainer:
			for row_child in child.get_children():
				if row_child is HBoxContainer:
					for sub in row_child.get_children():
						if sub is Button:
							enabled_buttons += 1
							assert(sub.disabled == false, "Join button in Era 2 must be enabled")
							assert(sub.text == "立誓拜入", "Button text should be 立誓拜入")
	assert(enabled_buttons == 5, "5 sect cards should have enabled join buttons in Era 2")
	
	panel.queue_free()
