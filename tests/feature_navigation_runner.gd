extends SceneTree
var failed := false
const TEST_DIR := "user://nav1_runner"
func _init() -> void:
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("NAV1: " + message)
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = TEST_DIR
	var slots := SaveSlots.new(FileStorageAdapter.new(TEST_DIR))
	slots.reset()
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.offline_summary.visible = false
	var nav = abode.feature_navigation
	# Discovery uses current View, survives unlocks and never rebuilds unchanged tabs.
	nav.open_group("cultivation")
	check(not nav.tab_buttons.beasts.visible and not nav.tab_buttons.reincarnation.visible, "Era1 hides distant beast/reincarnation tabs")
	check(nav.tab_buttons.skills.visible and nav.tab_buttons.skills.text.ends_with("·未開") and nav.tab_buttons.skills.tooltip_text.is_empty(), "Era1 skill preview shows locked state without tooltip")
	check(nav.tab_buttons.alchemy.get_index() < nav.tab_buttons.achievements.get_index() and nav.tab_buttons.achievements.get_index() < nav.tab_buttons.skills.get_index(), "available pages precede previews in canonical order")
	check(nav.back_button is CloseSeal and nav.back_button.custom_minimum_size == Vector2(44, 44), "shell uses fixed44 close seal")
	var original_tab: Button = nav.tab_buttons.skills
	nav.refresh({"era_id": 2, "buildings": {"library": {"level": 0}}})
	check(nav.tab_buttons.beasts.visible and nav.tab_buttons.beasts.text.ends_with("·未開") and nav.tab_buttons.beasts.tooltip_text.is_empty(), "Era2 reveals visibly locked beast preview")
	nav.refresh({"era_id": 3, "buildings": {"library": {"level": 1}}})
	check(nav.tab_buttons.skills == original_tab and nav.tab_buttons.skills.modulate == Color.WHITE, "unlock updates reused tab in place")
	check(nav.tab_buttons.beasts.get_meta("availability") == FeatureUnlocks.State.AVAILABLE, "Era3 beast tab available")
	check(nav.tab_buttons.skills.get_index() == 0 and nav.tab_buttons.beasts.get_index() < nav.tab_buttons.achievements.get_index(), "newly unlocked pages return to canonical available order")
	check(nav.tab_buttons.alchemy.get_theme_stylebox("normal") == UiMaterial.surface("jade"), "selected feature tab shares resource jade style")
	check(nav.tab_buttons.alchemy.get_theme_font("font") == UiTypography.body_font(), "feature tabs use shared sans font")
	nav.refresh({"era_id": 1, "reincarnation_preview": {"reason": "lifespan_exhausted", "eligible": true}})
	check(nav.tab_buttons.reincarnation.visible, "exhausted life reveals reincarnation immediately")
	nav.home()
	nav.remembered.cultivation = "beasts"
	nav.open_group("cultivation")
	check(nav.page == "alchemy", "hidden remembered page falls back to available page")
	nav.open("achievements")
	nav.home()
	nav.open_group("cultivation")
	check(nav.page == "achievements", "available remembered page restored")
	nav.home()
	nav.open_group("journey")
	check(nav.page == "sect" and nav.tab_buttons.sect.text.ends_with("·未開"), "Era1 journey falls back to visibly locked sect preview")
	nav.home()
	nav.open_group("management")
	for route in ["outposts", "manufacturing", "transport"]:
		check(not nav.tab_buttons[route].visible, "Era1 hides island entry " + route)
		nav.open(route)
		check(nav.page == "buildings", "Era1 contextual island link returns to buildings " + route)
	check(nav.back_button.get_theme_stylebox("normal").bg_color == Color.TRANSPARENT, "close button has no black background")
	nav.refresh({"era_id": 2})
	for route in ["outposts", "manufacturing", "transport"]:
		check(nav.tab_buttons[route].visible, "Era2 reveals island entry " + route)
	nav.home()
	for viewport in ([Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]):
		var wide: Dictionary = nav.presentation_policy("manufacturing", viewport)
		check(wide.central and wide.wide_stock == (viewport.x >= 1100), "manufacturing resource policy follows viewport")
		check(not nav.presentation_policy("buildings", viewport).central, "building policy retains shared resource rail")
		check(not nav.presentation_policy("transport", viewport).wide_stock, "transport uses inline stock")
	# Warm pre-existing lazy sect/realm views before asserting navigation neutrality.
	abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	for viewport in ([Vector2(1280, 720), Vector2(844, 390), Vector2(640, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]):
		abode._layout_for_size(viewport)
		for button in [abode.island_mode_button, abode.building_catalog_button, abode.reincarnation_button, abode.overview_button]:
			check(button.get_theme_font_size("font_size") == 18, "all four main entries use the same font size")
		for route in ["buildings", "outposts", "manufacturing", "transport", "alchemy", "beasts", "reincarnation", "realms", "sect", "fortune", "decisions"]:
			nav.open(route)
			abode._layout_for_size(viewport)
			await process_frame
			check(nav.bar.get_global_rect().end.y <= abode.toolbar.position.y, "fixed page navigation fits " + route)
			check(abode.toolbar.get_global_rect().end.x <= viewport.x, "main navigation fits landscape")
			var count := int(abode.building_catalog.visible) + int(nav.action_panel.visible) + int(abode.nine_realms_preview.visible) + int(nav.island_panel.visible) + int(nav.manufacturing_panel.visible) + int(nav.transport_panel.visible)
			for key in nav.PANEL_KEYS:
				count += int(abode.get(key).visible)
			check(count == 1, "exactly one gameplay page is visible: " + route)
			if route == "alchemy":
				check(abode.alchemy_panel._scroll.get_global_rect().end.y <= abode.alchemy_panel.get_global_rect().end.y + 1.0, "alchemy scroll stays inside short workspace")
			if route == "fortune":
				check(abode.fortune_modal._body_scroll.get_global_rect().end.y <= abode.fortune_modal.get_global_rect().end.y + 1.0, "fortune scroll stays inside short workspace")
			check(abode.session.state.to_snapshot_dict() == before, "page navigation does not alter rules: " + route)
		nav.home()
		check(not nav.bar.visible and abode.header.visible, "home restores cultivation HUD")
	check(not abode.more_menu.visible and abode.more_menu.get_popup().item_count == 0, "no duplicate More feature list")
	abode._layout_for_size(Vector2(1280, 720))
	nav.open("buildings")
	await process_frame
	check(not abode.hint_panel.visible and abode.building_catalog.group_grids.core.columns == 2, "two-column catalog prioritizes cards over automatic messages")
	abode._hud_controller.show_messages()
	await process_frame
	check(abode.hint_panel.visible, "explicit messages remain available from a two-column catalog")
	abode._toggle_guidance()
	await process_frame
	check(not abode.hint_panel.visible, "desktop messages can close beside the compact catalog")
	abode._toggle_guidance()
	await process_frame
	check(abode.hint_panel.visible and nav.shell.shield.visible and abode.building_catalog.group_grids.core.columns == 2, "explicit messages reopen as modal without resizing catalog")
	check(not nav.shell.effective.page_input, "desktop reading blocks covered work actions")
	abode._toggle_guidance()
	abode._refresh_hud()
	abode._layout_for_size(Vector2(1280, 720))
	check(not abode.hint_panel.visible, "building rail preserves user's closed-message choice")
	abode._toggle_guidance()
	check(abode.hint_panel.visible, "messages can reopen while the building rail stays open")
	abode._layout_for_size(Vector2(844, 390))
	abode._hud_controller.show_messages()
	check(abode.hint_panel.visible and abode.building_catalog.visible, "explicit short-landscape messages are not forcibly hidden by navigation")
	nav.back()
	nav.home()
	abode._layout_for_size(Vector2(1280, 720))
	check(abode.hint_panel.visible and is_equal_approx(abode.hint_panel.get_global_rect().get_center().x, 640.0), "return home restores viewport-centered messages")
	for ready in [false, true]:
		for pending in [false, true]:
			nav.refresh({"era_id": 6, "reincarnation_preview": {"eligible": ready}, "fortune": {"has_pending": pending}})
			check(abode.reincarnation_button.text == "修行" and abode.reincarnation_button._red_dot.visible == ready, "cultivation uses real reincarnation badge")
			check(abode.overview_button.text == "遊歷" and abode.overview_button._red_dot.visible == pending, "journey uses real fortune badge")
			check(abode.reincarnation_button.tooltip_text.contains("輪迴") and abode.overview_button.tooltip_text.contains("機緣"), "reminders explain their distinct destinations")
	abode._refresh_hud()
	check(abode.orientation_prompt.z_index > abode.toolbar.z_index and abode.orientation_prompt.z_index > nav.bar.z_index, "rotation guidance covers navigation visually")
	check(nav.owner("outposts") == "management" and nav.owner("reincarnation") == "cultivation", "management and cultivation have distinct homes")
	abode.camera.input_locked = true
	nav.home()
	check(abode.camera.input_locked, "home no-op preserves another presentation's camera lock")
	nav.open("beasts")
	nav.home()
	check(abode.camera.input_locked == not nav.shell.effective.world_input, "page close recalculates current shell input instead of restoring a stale lock bit")
	abode.camera.input_locked = false
	# Session-backed interactions through the real UI signal, in isolated data only.
	abode.session.state.era_id = 3
	abode.session.state.resources["spirit_grass_low"] = {"value": AmountCompat.from_number(500), "unlocked": true, "ever_obtained": true}
	abode._refresh_hud()
	nav.open("beasts")
	nav.action_panel.buttons["acquire:jade_fox"].pressed.emit()
	check(abode.session.state.beasts.get("active", {}).get("id", "") == "jade_fox", "UI acquires via Session")
	var herb: float = abode.session.state.resources.spirit_grass_low.value.to_float()
	nav.action_panel.buttons["feed:"].pressed.emit()
	check(abode.session.state.resources.spirit_grass_low.value.to_float() == herb - 50, "UI feed charges exactly the shared preview cost")
	check(nav.action_panel.buttons["feed:"].disabled, "cooldown disables repeat feeding")
	abode.session.state.beast_souls.jade_fox = 1
	abode._refresh_hud()
	nav.action_panel.buttons["talent:fox_t1_boost"].pressed.emit()
	check(int(abode.session.state.beast_talents.get("fox_t1_boost", 0)) == 1, "UI learns a talent via Session")
	nav.open("decisions")
	var decisions: Array = abode.session.get_view().realm_decisions
	for item in decisions:
		for id in item.get("costs", {}):
			if id != "lifespan_seconds":
				abode.session.state.resources[id] = {"value": AmountCompat.from_number(100000), "unlocked": true, "ever_obtained": true}
	abode._refresh_hud()
	var first: Dictionary = abode.session.get_view().realm_decisions[0]
	var revision: int = abode.session.state.revision
	nav.action_panel.buttons["decision:" + first.id].pressed.emit()
	check(abode.session.state.revision == revision + 1, "realm decision UI commits one Session command")
	check(nav.action_panel.buttons["decision:" + first.id].disabled, "decision cooldown prevents repeat action")
	nav.home()
	abode._refresh_hud()
	check(abode.building_catalog.resource_value_labels["realm_crystal"].text.contains("極品靈晶"), "shared resource area contains realm resource cards")
	abode.queue_free()
	await process_frame
	slots.reset()
	print("NAV1 navigation, neutrality, resource integration and UI command checks completed")
	quit(1 if failed else 0)
