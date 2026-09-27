class_name M3bSectUiRunner
extends SceneTree

func _init() -> void:
	print("\n--- Running M3-B Sect UI Runner ---")
	test_sect_panel_lifecycle()
	test_responsive_layouts()
	print("PASS: M3-B sect UI, tabs, joining, expeditions, techniques, market, and responsiveness.")
	quit(0)

func _create_test_state() -> GameState:
	var state := GameState.new()
	state.era_id = 2
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
	
	var state := _create_test_state()
	
	# Initial state: not joined yet
	panel.update_view(state)
	panel.set_layout_bounds(Rect2(0, 0, 1280, 720))
	
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
	
	panel.queue_free()

func test_responsive_layouts() -> void:
	print("Testing SectPanel responsive layouts...")
	var panel := SectPanel.new()
	root.add_child(panel)
	var state := _create_test_state()
	SectSystem.join_sect(state)
	panel.update_view(state)
	
	# Desktop 1280x720
	panel.set_layout_bounds(Rect2(20, 20, 1240, 680))
	assert(panel.size.x == 1240 and panel.size.y == 680, "Desktop bounds set")
	
	# Mobile Portrait 360x640
	panel.set_layout_bounds(Rect2(12, 12, 336, 616))
	assert(panel.size.x == 336 and panel.size.y == 616, "Portrait bounds set")
	
	# Compact Height 360x480
	panel.set_layout_bounds(Rect2(12, 12, 336, 456))
	assert(panel.size.x == 336 and panel.size.y == 456, "Compact height bounds set")
	
	panel.queue_free()
