extends SceneTree

const SCENE_PATH := "res://scenes/living_abode.tscn"
const TEST_SAVE_DIR := "user://m2d_responsive_ui_test_saves"
var _failed: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = TEST_SAVE_DIR
	var slots := SaveSlots.new(FileStorageAdapter.new(TEST_SAVE_DIR))
	slots.reset()
	var abode = load(SCENE_PATH).instantiate()
	root.add_child(abode)
	await process_frame

	# State A: world, cultivation, passive resource readouts, and explicit gather action.
	abode._layout_for_size(Vector2(1280, 720))
	_expect(is_equal_approx(float(abode.sky_material.get_shader_parameter("background_focal_x")), 0.5), "wide viewport samples the full-bleed background without edge extension")
	var island_composition: Node2D = abode.get_node("洞府浮島構圖")
	_expect(is_equal_approx(island_composition.scale.x, 0.92) and is_equal_approx(island_composition.position.y, 18.0), "foreground island composition uses modest uniform scale and downward offset")
	var hut: Node2D = abode.buildings["hut"]
	var hut_probe: Vector2 = hut.to_global(Vector2(0, -33))
	var hut_was_visible: bool = hut.visible
	hut.visible = true
	_expect(hut.contains_point(hut_probe), "building hit testing remains aligned after the island composition transform")
	hut.visible = hut_was_visible
	await process_frame
	_check_scene(abode, Vector2(1280, 720), "desktop island")
	_expect(abode.hint_panel.size.y >= 200.0 and abode.hint_log_label.get_theme_font_size("normal_font_size") >= 17, "desktop messages must provide a readable default height and font")
	_expect(abode.hint.text.contains("茅屋") and abode.hint.text.contains("靈氣"), "fresh-game guidance must explain gathering for the hut")
	_expect(abode.building_catalog.resource_gather_buttons["lingli"].visible, "fresh-game island HUD must expose direct gather action on lingli card")
	_expect(abode.building_catalog.resource_buttons["lingli"] is PanelContainer, "resource readouts must be passive information cards with inline gather")
	_expect(abode.building_catalog.resource_buttons.has("foundation_pill"), "resource panel must include the later Era resource instead of hard-coding the first six")
	# Completion must survive mode/detail changes; a fresh objective must restore guidance.
	var initial_buildings: Dictionary = abode.session.state.buildings.duplicate(true)
	for milestone in Onboarding.MILESTONES:
		abode.session.state.buildings[milestone.building] = milestone.level
	abode._refresh_hud()
	await process_frame
	_expect(not abode.objective_button.visible and not abode.building_catalog.objective_button.visible, "completed onboarding must remove both objective buttons")
	abode._open_building_catalog()
	abode.building_catalog.show_detail(true)
	abode.building_catalog.show_detail(false)
	abode.building_catalog.set_short_mode(true)
	abode.building_catalog.set_short_mode(false)
	_expect(not abode.building_catalog.objective_button.visible, "detail and density changes must not revive completed onboarding")
	abode._close_building_catalog()
	abode.session.state.buildings = initial_buildings
	abode._refresh_hud()
	abode._layout_for_size(Vector2(1280, 720))
	_expect(abode.objective_button.visible and abode.building_catalog.objective_button.visible, "a valid new objective must restore guidance")
	abode._toggle_guidance()
	abode._refresh_hud()
	abode._layout_for_size(Vector2(844, 390))
	_expect(not abode.hint_panel.visible, "refresh and resizing must preserve a user's closed-message choice")
	abode._toggle_guidance()
	abode._layout_for_size(Vector2(1280, 720))
	var lingli_before: AmountCompat = abode.session.state.resources["lingli"].value
	abode.building_catalog.resource_gather_buttons["lingli"].pressed.emit()
	_expect(abode.session.state.resources["lingli"].value.compare_to(lingli_before) > 0, "direct lingli gather must use the normal resource command")
	_expect(not abode.more_menu.visible and abode.more_menu.get_popup().item_count == 0, "game features must use canonical section tabs instead of More")
	_expect(abode.settings_menu.get_popup().item_count >= 5, "system settings actions must remain in settings_menu")

	# State B: left resources, a right-side building ledger, and the same cultivation status.
	abode.building_catalog_button.pressed.emit()
	await process_frame
	_check_management(abode, Vector2(1280, 720), "desktop management")
	_expect(abode.building_catalog.rows["hut"].visible, "unbuilt hut must remain available in management")
	_expect(abode.building_catalog.resource_buttons["lingli"].visible, "left resource list must show lingli")
	_expect(abode.resource_ribbon.get_global_rect().end.x < abode.building_catalog.get_global_rect().position.x, "desktop resources and buildings must occupy separate columns")
	_expect(abode.building_catalog.resource_buttons["lingli"].size.x > 100.0, "resource readout cards must fill the ribbon width instead of collapsing: %s" % abode.building_catalog.resource_buttons["lingli"].size)
	_expect(abode.resource_ribbon.position.y >= abode.header.position.y + abode.header.size.y, "resource ribbon must not overlap header: ribbon_y=%s header_bottom=%s" % [abode.resource_ribbon.position.y, abode.header.position.y + abode.header.size.y])

	# Test level up button appearance and dynamic reflow without overlap
	abode.level_up_button.visible = true
	abode._reflow_header()
	await process_frame
	_expect(abode.resource_ribbon.position.y >= abode.header.position.y + abode.header.size.y, "resource ribbon must dynamically move down when header expands with level up button: ribbon_y=%s header_bottom=%s" % [abode.resource_ribbon.position.y, abode.header.position.y + abode.header.size.y])
	abode.level_up_button.visible = false
	abode._reflow_header()
	await process_frame

	_expect(abode.island_mode_button.disabled == false and abode.building_catalog_button.disabled, "management tab must expose the return-to-island layout")
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(20.0)
	abode._refresh_hud()
	_expect(not abode.building_catalog.upgrade_buttons["hut"].disabled, "affordable hut must expose a direct build action")
	abode.building_catalog.upgrade_buttons["hut"].pressed.emit()
	_expect(abode.session.state.buildings["hut"] == 1, "direct building action must use the normal upgrade command exactly once")
	abode.building_catalog.rows["hut"].pressed.emit()
	_expect(abode.building_catalog.row_info["hut"].box.visible, "selecting a row must expand its effects and cost inline")
	abode.building_catalog.row_info["hut"].box.get_child(1).pressed.emit()
	await process_frame
	abode._layout_for_size(Vector2(1280, 720))
	await process_frame
	_check_detail(abode, Vector2(1280, 720), "desktop detail")
	_expect(abode.resource_ribbon.visible, "normal-height detail must keep left resource values visible")
	abode._close_detail()
	_expect(abode.building_catalog.visible and abode.building_catalog.scroll.visible and not abode.info_panel.visible, "detail close must return to the same building list")
	abode.building_catalog.close_button.pressed.emit()
	abode._layout_for_size(Vector2(1280, 720))
	_check_scene(abode, Vector2(1280, 720), "returned island")

	# Retain the DAO2 objective chain and existing resource/building unlocks.
	abode.session.state.buildings["hut"] = 2
	for id in abode.session.state.resources:
		var entry: Dictionary = abode.session.state.resources[id]
		entry.unlocked = true
		abode.session.state.resources[id] = entry
	abode._refresh_hud()
	_expect(abode.hint.text.contains("金錢") and abode.hint.text.contains("木屋"), "guidance must advance to wooden house")
	abode.session.state.buildings["wooden_house"] = 2
	abode._refresh_hud()
	_expect(abode.hint.text.contains("林場"), "guidance must advance to forest farm")
	abode.session.state.buildings["forest_farm"] = 3
	abode._refresh_hud()
	_expect(abode.hint.text.contains("採石場"), "guidance must advance to stone mine")
	abode.session.state.buildings["stone_mine"] = 3
	abode._refresh_hud()
	_expect(abode.hint.text.contains("靈植場"), "guidance must advance to herb farm")
	abode.session.state.buildings["wooden_house"] = 0
	abode.session.state.buildings["forest_farm"] = 0
	abode.session.state.buildings["stone_mine"] = 0
	abode._refresh_hud()
	_expect(not abode.buildings["wooden_house"].visible and not abode.buildings["storage_lingli"].visible, "routine facilities must not appear as unplanned island props")
	abode._toggle_building_catalog()
	await process_frame
	_expect(abode.building_catalog.rows["wooden_house"].visible and abode.building_catalog.rows["storage_money"].visible, "unlocked facilities must remain in the list")
	abode.building_catalog.filter_buttons["production"].pressed.emit()
	_expect(not abode.building_catalog.group_rows["storage"].visible and abode.building_catalog.group_rows["production"].visible, "production filter must separate facilities from storage")
	abode.building_catalog.filter_buttons["all"].pressed.emit()
	_expect(abode.building_catalog.group_rows["storage"].visible, "all filter must restore storage without losing scrollable buildings")
	_expect(abode.building_catalog.resource_summary.text.contains("靈石") and abode.building_catalog.resource_buttons["money"].visible, "left list must include unlocked resource values")
	var money_before: AmountCompat = abode.session.state.resources["money"].value
	_expect(abode.building_catalog.resource_gather_buttons["money"].visible, "unlocked money card must expose direct gather button")
	abode.building_catalog.resource_gather_buttons["money"].pressed.emit()
	_expect(abode.session.state.resources["money"].value.compare_to(money_before) > 0, "direct money gather button must issue a command")
	_expect(abode.building_catalog.rows["wooden_house"].custom_minimum_size.y == 48.0 and abode.building_catalog.upgrade_buttons["wooden_house"].custom_minimum_size.y == 48.0, "compact 48px rows must remain touchable")
	_expect(not abode.building_catalog.rows["wooden_house"].text.contains("金錢"), "collapsed building rows must omit repeated resource costs")
	_expect(abode.building_catalog.progress_bars["wooden_house"].bg.visible, "collapsed building rows must retain requirement progress")
	abode.building_catalog.rows["wooden_house"].pressed.emit()
	_expect(abode.building_catalog.row_info["wooden_house"].box.visible, "building information must expand within the list")
	_expect(abode.building_catalog.row_info["wooden_house"].label.text.contains("需求"), "expanded building information must show costs")
	abode.building_catalog.row_info["wooden_house"].box.get_child(1).pressed.emit()
	abode._layout_for_size(Vector2(1280, 720))
	await process_frame
	_check_detail(abode, Vector2(1280, 720), "wooden-house detail")
	abode.detail_scroll.scroll_vertical = 10000
	await process_frame
	_check_bounded(abode.upgrade_button, Vector2(1280, 720), "upgrade action after detail scroll")

	# Resize while the same detail is open; no extra right-hand detail surface appears.
	for vp in [Vector2(1920, 902), Vector2(844, 390), Vector2(360, 640), Vector2(360, 480)]:
		abode._layout_for_size(vp)
		await process_frame
		var expected_focal := lerpf(0.39, 0.5, smoothstep(0.75, 1.65, vp.x / vp.y))
		var actual_focal := float(abode.sky_material.get_shader_parameter("background_focal_x"))
		var horizontal_span := minf(1.0, vp.x / vp.y / (float(abode.sky.texture.get_width()) / float(abode.sky.texture.get_height())))
		_expect(is_equal_approx(actual_focal, expected_focal), "background framing follows the responsive viewport aspect ratio")
		_expect(actual_focal - horizontal_span * 0.5 >= 0.0 and actual_focal + horizontal_span * 0.5 <= 1.0, "background UV crop stays inside the source image without stretching edge pixels")
		_check_management(abode, vp, "management %s" % vp)
		_check_detail(abode, vp, "detail %s" % vp)
		_expect(abode.building_catalog.resource_grid.visible or (vp.y < 560.0 and not abode.resource_ribbon.visible), "short-phone detail may focus while other sizes retain resources")
		if vp.x < vp.y:
			_expect(abode.orientation_prompt != null and abode.orientation_prompt.visible, "portrait viewport must show orientation prompt overlay")
		else:
			_expect(abode.orientation_prompt != null and not abode.orientation_prompt.visible, "landscape viewport must hide orientation prompt overlay")
		if is_equal_approx(vp.x, 844.0) and is_equal_approx(vp.y, 390.0):
			_expect(abode.layout_mode == abode.HudLayout.COMPACT, "844x390 mobile landscape must adopt compact layout instead of desktop wide")
	abode._close_detail()
	abode._layout_for_size(Vector2(360, 640))
	await process_frame
	_expect(abode.resource_ribbon.visible and abode.building_catalog.scroll.visible, "return from detail must restore the building ledger")
	abode._layout_for_size(Vector2(360, 480))
	abode.resource_mode_buttons[2].pressed.emit()
	await process_frame
	abode._layout_for_size(Vector2(360, 480))
	await process_frame
	_check_bounded(abode.resource_ribbon, Vector2(360, 480), "expanded short-phone resources")
	_check_bounded(abode.building_catalog, Vector2(360, 480), "expanded short-phone building ledger")
	_expect(abode.building_catalog.scroll.size.y > 0.0, "expanded short-phone resources must leave a usable building list")
	abode.resource_scroll.scroll_vertical = 100
	await process_frame
	_expect(abode.resource_scroll.scroll_vertical > 0, "full short-phone resources must scroll inside their fixed panel")
	abode.resource_mode_buttons[0].pressed.emit()
	_expect(not abode.resource_scroll.visible, "closed resource mode must hide the list but retain mode controls")
	abode.resource_mode_buttons[1].pressed.emit()
	_expect(abode.resource_display_mode == 1 and abode.resource_scroll.visible, "summary mode must restore resource quantities")
	var resource_normal_color: Color = abode.building_catalog.resource_value_labels["lingli"].get_theme_color("font_color")
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(400.0)
	abode._refresh_hud()
	_expect(abode.building_catalog.resource_value_labels["lingli"].get_theme_color("font_color") != resource_normal_color and abode.building_catalog.resource_value_labels["lingli"].text.contains("滿"), "full resource must change color and retain an explicit full-storage summary")
	_expect(abode.building_catalog.resource_gather_buttons["lingli"].disabled, "full resource must disable manual gathering")
	abode.session.state.era_id = 2
	abode._refresh_hud()
	_expect(not abode.building_catalog.resource_gather_buttons["lingli"].visible, "Era 2 must not show manual gather buttons on resource cards")
	await process_frame
	abode._layout_for_size(Vector2(360, 480))
	await process_frame
	abode.building_catalog.scroll.scroll_vertical = 300
	await process_frame
	var saved_scroll: int = abode.building_catalog.scroll.scroll_vertical
	_expect(saved_scroll > 0, "Era 2 building list must scroll beneath fixed resources on a phone: %s scroll_size=%s content_min=%s rail=%s" % [saved_scroll, abode.building_catalog.scroll.size, abode.building_catalog._content.get_combined_minimum_size(), abode.building_catalog.size])
	var fixed_resource_y: float = abode.resource_ribbon.get_global_rect().position.y
	abode.building_catalog.scroll.scroll_vertical = 500
	await process_frame
	_expect(is_equal_approx(abode.resource_ribbon.get_global_rect().position.y, fixed_resource_y), "building scroll must not move resources")
	abode.building_catalog.rows["hut"].pressed.emit()
	abode.building_catalog.row_info["hut"].box.get_child(1).pressed.emit()
	abode._close_detail()
	await process_frame
	_expect(abode.building_catalog.scroll.scroll_vertical > 0, "return from detail must restore list scroll position")
	abode.building_catalog.close_button.pressed.emit()
	abode._layout_for_size(Vector2(360, 640))
	_check_scene(abode, Vector2(360, 640), "portrait island")
	_expect(abode.island_mode_button.disabled and not abode.building_catalog_button.disabled, "island tab must expose the management layout")
	_expect(abode.realm_label.text.contains("築基") and abode.realm_label.text.contains("1/10 層"), "realm and level must remain visible in island HUD")

	# Existing secondary screens remain bounded after the mode change.
	abode._toggle_save_controls()
	abode._layout_for_size(Vector2(360, 640))
	_expect(abode.save_controls.visible and abode.save_controls.size.x <= 336.0, "save controls must remain available in portrait")
	abode._toggle_save_controls()
	abode._open_nine_realms_overview()
	await process_frame
	var preview = abode.nine_realms_preview
	preview.size = Vector2(360, 480)
	preview.set_workspace_bounds(Rect2(12, 12, 336, 456))
	_expect(preview._overview_panel.size.x <= 336.0 and preview._overview_panel.size.y <= 456.0, "nine-realms panel must fit a short phone viewport")
	preview._scroll.scroll_vertical = 400
	await process_frame
	_expect(preview._scroll.scroll_vertical > 0, "nine-realms body must scroll")
	preview._on_close_pressed()
	var breakthrough = abode.breakthrough_seq
	breakthrough.size = Vector2(360, 640)
	breakthrough._layout_for_viewport()
	await process_frame
	_check_bounded(breakthrough._close_button, Vector2(360, 640), "breakthrough close")
	abode.queue_free()
	slots.reset()
	abode_script.save_dir_override = ""
	if _failed:
		quit(1)
		return
	print("PASS: M2-D island/management tabs, three resource modes, compact building rows, detail return, and responsive bounds.")
	quit(0)

func _check_scene(abode: Node, vp: Vector2, label: String) -> void:
	_expect(abode.header.visible and abode.resource_ribbon.visible and not abode.building_catalog.visible and abode.toolbar.visible, label + " must show cultivation, resources, world, and primary actions")
	_expect(abode.hint_panel.visible == (vp.x >= vp.y), label + " must open messages by default in landscape")
	if abode.hint_panel.visible:
		_check_bounded(abode.hint_panel, vp, label + " system messages")
		_expect(not abode.hint_panel.get_global_rect().intersects(abode.header.get_global_rect()) and not abode.hint_panel.get_global_rect().intersects(abode.resource_ribbon.get_global_rect()), label + " messages must leave status and resources accessible")
	_check_bounded(abode.header, vp, label + " HUD")
	_check_bounded(abode.resource_ribbon, vp, label + " resource ribbon")
	_check_bounded(abode.toolbar, vp, label + " primary navigation")
	var world_gap: float = abode.toolbar.position.y - (abode.header.position.y + abode.header.size.y)
	_expect(world_gap >= 80.0, label + " must leave a contiguous world interaction area")

func _check_management(abode: Node, vp: Vector2, label: String) -> void:
	var detail_focus: bool = vp.y < 560.0 and abode.info_panel.visible
	_expect(abode.building_catalog.visible and (detail_focus or (abode.header.visible and abode.resource_ribbon.visible)) and abode.toolbar.visible, label + " must keep fixed status or focus short-phone detail")
	_check_bounded(abode.building_catalog, vp, label + " rail")
	if not detail_focus:
		_check_bounded(abode.resource_ribbon, vp, label + " resource panel")
	_check_bounded(abode.toolbar, vp, label + " navigation")
	_check_bounded(abode.building_catalog.close_button, vp, label + " return button")
	_expect(abode.building_catalog.size.x <= 400.0 or vp.x < 640.0, label + " rail width must stay bounded")
	_expect(abode.building_catalog.scroll.visible or abode.building_catalog.detail_slot.visible, label + " must have a building or detail region")

func _check_detail(abode: Node, vp: Vector2, label: String) -> void:
	_expect(abode.building_catalog.visible and abode.info_panel.visible and abode.building_catalog.detail_slot.visible and not abode.building_catalog.scroll.visible, label + " must replace the list inside the same rail")
	_check_bounded(abode.info_panel, vp, label + " detail")
	var close_button: Button = abode.info_panel.get_child(0).get_child(0).get_child(1)
	_check_bounded(close_button, vp, label + " detail return")
	_expect(abode.detail_scroll.size.y > 0.0, label + " must keep a scrollable detail body")

func _check_bounded(control: Control, vp: Vector2, label: String) -> void:
	var rect: Rect2 = control.get_global_rect()
	_expect(rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= vp.x + 0.5 and rect.end.y <= vp.y + 0.5, "%s outside %s: %s" % [label, vp, rect])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("FAIL: " + message)
