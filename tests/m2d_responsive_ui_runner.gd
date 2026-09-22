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

	abode._layout_for_size(Vector2(1280, 720))
	_expect(abode._layout_mode_name() == "wide", "1280×720 must select wide layout")
	_expect(abode.header.position.x < 100.0 and abode.info_panel.position.x > 700.0, "wide layout must keep status and detail on opposite sides")
	_expect(not abode.more_menu.visible and abode.motion_button.visible and abode.save_button.visible, "wide layout must expose the desktop toolbar")
	# Hut level 2 unlocks additional resources and plots; the status must stay bounded.
	abode.session.state.buildings["hut"] = 2
	for id in abode.session.state.resources:
		var entry: Dictionary = abode.session.state.resources[id]
		entry.unlocked = true
		abode.session.state.resources[id] = entry
	abode._refresh_hud()
	await process_frame
	_expect(abode.resource_label.text.find("\n") == -1, "top status must stay a one-line resource summary")
	_expect(abode.header.position.y + abode.header.size.y + 8.0 <= abode.viewbar.position.y, "expanded status must not overlap zoom controls")
	abode._toggle_resources()
	_expect(abode.resource_panel.visible and abode.resource_full_label.text.find("靈石") >= 0, "resource overview must expose newly unlocked resources")
	_expect(abode.resource_panel.position.y + abode.resource_panel.size.y <= 720.0, "resource overview must fit desktop height")
	abode._toggle_resources()
	_expect(not abode.resource_panel.visible, "resource overview must close")
	_expect(not abode.buildings["storage_money"].visible, "routine storage must not be drawn on the island")
	_expect(not abode.buildings["wooden_house"].visible and not abode.buildings["storage_lingli"].visible, "unplanned production and altar plots must be absent from the island")
	abode.building_catalog_button.pressed.emit()
	_expect(abode.building_catalog.visible, "building catalogue button signal must open the panel")
	_expect(abode.building_catalog.rows["wooden_house"].visible and abode.building_catalog.rows["storage_lingli"].visible and abode.building_catalog.rows["storage_money"].visible, "hut level 2 must expose newly unlocked buildings in the catalogue")
	abode.building_catalog.rows["wooden_house"].pressed.emit()
	_expect(abode.building_catalog.visible and abode.selected_id == "wooden_house" and abode.info_panel.visible, "catalogue row signal must keep catalogue open and open building detail")
	# Test opening resource panel directly from the catalogue title bar
	abode.building_catalog.resource_button.pressed.emit()
	_expect(abode.building_catalog.visible and abode.resource_panel.visible, "catalog resource button must toggle resource panel directly")
	_expect(abode.building_catalog.position.x >= abode.resource_panel.position.x + abode.resource_panel.size.x, "resource panel and building catalogue must be side by side without overlapping")
	abode.resource_density_button.pressed.emit()
	_expect(abode.ui_compact_mode and abode.building_catalog.is_compact, "switching density from resource panel must synchronize to catalog")
	_expect(abode.building_catalog.rows["wooden_house"].custom_minimum_size.y <= 44.0, "compact mode must decrease button height to 40")
	abode.building_catalog.density_button.pressed.emit()
	_expect(not abode.ui_compact_mode and not abode.building_catalog.is_compact, "switching density from catalog must restore standard mode")
	_expect(abode.building_catalog.rows["wooden_house"].custom_minimum_size.y >= 50.0, "standard mode must restore comfortable button height")
	abode._toggle_resources()
	abode.building_catalog.close_button.pressed.emit()
	abode._close_detail()

	abode._layout_for_size(Vector2(844, 390))
	_expect(abode._layout_mode_name() == "compact", "844×390 must select compact layout")
	_expect(abode.toolbar.size.y >= 128.0, "compact layout must reserve wrapped toolbar space")
	_expect(abode.info_panel.position.x >= 420.0, "compact layout must keep detail drawer out of the left status region")
	_expect(abode.header.position.y + abode.header.size.y <= abode.toolbar.position.y, "short compact status must not cover bottom navigation")
	_expect(not abode.viewbar.visible, "short compact layout must hide zoom controls when there is no safe vertical room")

	abode.session.state.era_id = 2
	abode._refresh_hud()
	_expect(abode.session.get_view().buildings["hut"].visible and abode.session.get_view().buildings["storage_money"].visible, "era 2 must retain earlier-era building access")
	abode._layout_for_size(Vector2(360, 640))
	_expect(abode._layout_mode_name() == "portrait", "360×640 must select portrait layout")
	_expect(is_equal_approx(abode.header.position.x, 12.0) and is_equal_approx(abode.header.size.x, 336.0), "portrait status must remain inside 360 CSS px safe margins")
	_expect(abode.info_panel.position.y + abode.info_panel.size.y <= 552.0, "portrait detail drawer must leave the bottom navigation clear")
	_expect(abode.more_menu.visible and not abode.motion_button.visible and not abode.save_button.visible, "portrait must move secondary actions into More")
	_expect(abode.toolbar.position.y >= 560.0 and is_equal_approx(abode.toolbar.size.x, 336.0), "portrait bottom navigation must fit the safe width")
	_expect(abode.header.position.y + abode.header.size.y + 8.0 <= abode.viewbar.position.y, "portrait status and zoom controls must not overlap")
	abode._toggle_resources()
	_expect(abode.resource_panel.visible and abode.resource_panel.position.y + abode.resource_panel.size.y <= 640.0, "portrait resource overview must fit the viewport")
	abode._toggle_resources()
	abode._toggle_building_catalog()
	await process_frame
	_expect(abode.building_catalog.visible and abode.building_catalog.size.x <= 336.0 and abode.building_catalog.position.y + abode.building_catalog.size.y <= 640.0, "portrait building catalogue must fit the viewport")
	var catalogue_close: Rect2 = abode.building_catalog.close_button.get_global_rect()
	_expect(catalogue_close.position.y >= 0.0 and catalogue_close.end.y <= 640.0, "catalogue close control must stay visible")
	abode.building_catalog.scroll.scroll_vertical = 300
	await process_frame
	_expect(abode.building_catalog.scroll.scroll_vertical > 0, "era 2 building catalogue must scroll on a small portrait viewport")
	abode.building_catalog.close_button.pressed.emit()
	_expect(not abode.building_catalog.visible, "catalogue close button signal must close the panel")

	abode._toggle_save_controls()
	abode._layout_for_size(Vector2(360, 640))
	_expect(abode.save_controls.visible, "save controls must open from the responsive layout")
	_expect(is_equal_approx(abode.save_controls.size.x, 336.0) and is_equal_approx(abode.save_controls.size.y, 616.0), "portrait save controls must fit the viewport")
	abode._toggle_save_controls()
	abode._layout_for_size(Vector2(360, 640))

	abode._open_nine_realms_overview()
	await process_frame
	var preview = abode.nine_realms_preview
	preview.size = Vector2(360, 480)
	preview._layout_for_viewport()
	_expect(preview._overview_panel.size.x <= 336.0 and preview._overview_panel.size.y <= 456.0, "short portrait nine-realms panel must fit the viewport")
	_expect(preview._grid_container.columns == 1, "portrait nine-realms cards must use one column")
	_expect(preview._scroll.mouse_filter == Control.MOUSE_FILTER_STOP and preview._scroll.size.y > 0.0, "nine-realms body must receive scrolling input")
	_expect(preview._scroll.position.y + preview._scroll.size.y <= preview._footer.position.y + 0.1, "nine-realms scrolling body must end before the fixed close row")
	preview._scroll.scroll_vertical = 400
	await process_frame
	_expect(preview._scroll.scroll_vertical > 0, "nine-realms content must actually scroll in a short viewport")
	var close_rect: Rect2 = preview._close_btn.get_global_rect()
	_expect(close_rect.position.y >= 0.0 and close_rect.end.y <= 480.0, "nine-realms close control must stay inside a short viewport")
	preview._on_close_pressed()

	var breakthrough = abode.breakthrough_seq
	breakthrough.size = Vector2(360, 640)
	breakthrough._layout_for_viewport()
	await process_frame
	var breakthrough_close: Rect2 = breakthrough._close_button.get_global_rect()
	var breakthrough_content: Rect2 = breakthrough._center.get_global_rect()
	_expect(breakthrough_content.position.x >= 0.0 and breakthrough_content.end.x <= 360.0 and breakthrough_content.end.y <= 640.0, "portrait breakthrough content must fit the viewport")
	_expect(breakthrough_close.position.x >= 0.0 and breakthrough_close.end.x <= 360.0, "portrait breakthrough close control must fit horizontally")
	_expect(breakthrough_close.position.y >= 0.0 and breakthrough_close.end.y <= 640.0, "portrait breakthrough close control must fit vertically")
	_expect(abode.save_controls._background.size == abode.save_controls.size, "save dialog background must cover the text area")
	_expect(abode.offline_summary._background.size == abode.offline_summary.size, "offline dialog background must cover the text area")

	abode.queue_free()
	slots.reset()
	abode_script.save_dir_override = ""
	if _failed:
		quit(1)
		return
	print("PASS: M2-D responsive HUD selects wide, compact, and portrait layouts with fitting drawers and overlays.")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("FAIL: " + message)