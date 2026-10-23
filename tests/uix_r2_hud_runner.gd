extends SceneTree
var failures := 0
var checks := 0

func _init() -> void:
	_run()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://uix-r2-hud-isolated"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.offline_summary.visible = false
	var nav = abode.feature_navigation
	var summary = abode.settings_menu.get_parent()
	check(abode.resource_display_mode == 0, "fresh home defaults to one summary")
	check(abode.hud.get_node("BronzeFrame").mouse_filter == Control.MOUSE_FILTER_IGNORE, "bronze corners never intercept world input")
	var dock: Button = abode.building_catalog_button
	check(dock.get_theme_stylebox("pressed").modulate_color != dock.get_theme_stylebox("normal").modulate_color, "jade press has distinct feedback")
	check(dock.get_theme_stylebox("hover").modulate_color != dock.get_theme_stylebox("disabled").modulate_color, "jade hover and disabled differ")
	for vp in ([Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]):
		abode._layout_for_size(vp)
		await process_frame
		abode._layout_for_size(vp)
		check(not abode.resource_scroll.visible, "home full list folded %s" % vp)
		check(not summary.get_global_rect().intersects(abode.header.get_global_rect()), "summary clears identity %s" % vp)
		check(Rect2(Vector2.ZERO, vp).encloses(summary.get_global_rect()), "summary bounded %s" % vp)
		check(abode._hud_controller._lifespan_text.get_line_count() == 1, "lifespan unit stays on one row %s" % vp)
		check(abode.chrono_label.get_parent() != abode._hud_controller._lifespan_text.get_parent(), "weather does not compete with lifespan %s" % vp)
		var goal: Control = abode.hud.get_node("GoalScroll")
		if goal.visible:
			check(goal.position.y >= abode.header.get_rect().end.y and goal.get_rect().end.y <= abode.resource_ribbon.position.y, "hanging goal separates identity and resource controls")
		for button in [abode.island_mode_button, abode.building_catalog_button, abode.reincarnation_button, abode.overview_button]:
			check(button is DockButton and button.size.y >= 44, "jade dock hit area %s" % vp)
		# Manufacturing is a foundation workspace; use isolated Era2 for layout.
		var home_dock: Rect2 = abode.toolbar.get_global_rect()
		abode.session.state.era_id = 2
		abode._refresh_hud()
		nav.open("manufacturing")
		await process_frame
		nav.layout(vp)
		check(not summary.get_child(0).visible, "workspace suppresses home summary %s" % vp)
		check(not nav.bar.get_global_rect().intersects(abode.settings_menu.get_global_rect()), "fixed return clears settings %s" % vp)
		check(nav.bar.get_global_rect().end.y <= nav.manufacturing_panel.position.y, "fixed tabs clear scroll shell %s" % vp)
		check(nav.manufacturing_panel.get_theme_stylebox("panel").texture == (UiMaterial.UIX_SCROLL_COMPACT if nav.manufacturing_panel.size.y < 400 else UiMaterial.UIX_SCROLL), "shared manufacturing scroll shell follows R7 rod safety")
		nav.home()
		abode.session.state.era_id = 1
		abode._refresh_hud()
		abode._set_resource_display_mode(0)
		await process_frame
		nav.open("buildings")
		await process_frame
		abode._layout_for_size(vp)
		await process_frame
		check(abode.resource_scroll.size.y >= 38, "management retains a readable resource row %s" % vp)
		check(abode.toolbar.get_global_rect() == home_dock, "building list preserves home dock bounds %s" % vp)
		for mode in [1, 2]:
			abode._set_resource_display_mode(mode)
			await process_frame
			for id in abode.building_catalog.resource_buttons:
				var card: Control = abode.building_catalog.resource_buttons[id]
				if card.visible:
					var icon: Control = card.get_child(0).get_node("ResourceIcon")
					check(icon.size.x >= 24 and ((icon is TextureRect and icon.texture != null) or (icon is Label and not icon.text.is_empty())), "visible resource has art or currency seal %s mode%d %s" % [id, mode, vp])
		nav.home()
		abode._set_resource_display_mode(0)
	# Notification navigation must not acknowledge or clear pending domain state.
	var view: Dictionary = abode._presentation_view().duplicate(true)
	view.era_id = 2
	view.fortune = {"has_pending": true}
	view.reincarnation_preview = {"eligible": false}
	view.achievements = {"unclaimed_count": 1}
	nav._refresh_main_notifications(view)
	check(abode.overview_button._red_dot.visible and abode.reincarnation_button._red_dot.visible, "real pending View enables dots")
	nav.open("fortune")
	nav._refresh_main_notifications(view)
	check(abode.overview_button._red_dot.visible, "opening page does not acknowledge pending state")
	view.fortune.has_pending = false
	view.achievements.unclaimed_count = 0
	nav._refresh_main_notifications(view)
	check(not abode.overview_button._red_dot.visible and not abode.reincarnation_button._red_dot.visible, "resolved View removes dots")
	# Stale ready flags must not advertise features locked in the current life.
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	var sect := {"unlocked": true, "active_expedition": {"duration": 10, "elapsed": 10}}
	view.era_id = 1
	view.reincarnation_count = 0
	view.beast = {"can_feed": true}
	view.fortune.has_pending = true
	view.reincarnation_preview = {"eligible": true, "reason": "rebirth_lotus"}
	view.achievements.unclaimed_count = 1
	nav._refresh_main_notifications(view)
	check(abode.reincarnation_button._red_dot.visible, "Era1 achievements still notify")
	check(abode.reincarnation_button.tooltip_text == "成就待領；前往修行查看。", "Era1 tooltip only lists actual accessible achievement")
	check(not abode.overview_button._red_dot.visible, "Era1 locked fortune never enables journey dot")
	check(BuffHudBar.status_items(view, sect).is_empty(), "Era1 locked reminders suppressed in status strip too")
	view.achievements.unclaimed_count = 0
	nav._refresh_main_notifications(view)
	check(not abode.reincarnation_button._red_dot.visible, "locked features alone never enable cultivation dot")
	view.era_id = 2
	nav._refresh_main_notifications(view)
	check(not abode.reincarnation_button._red_dot.visible, "Era2 beast preview never enables dot")
	check(abode.overview_button.tooltip_text == "機緣待決；前往遊歷查看。", "fortune tooltip does not falsely list sect")
	check(BuffHudBar.status_items(view, sect).size() == 2, "Era2 permits sect and fortune but excludes beast")
	view.era_id = 3
	nav._refresh_main_notifications(view)
	check(abode.reincarnation_button.tooltip_text == "靈獸可餵養；前往修行查看。", "Era3 feed tooltip only lists feeding")
	check(BuffHudBar.status_items(view, sect).size() == 3, "Era3 permits all three status reminders")
	view.era_id = 1
	view.reincarnation_preview.reason = "lifespan_exhausted"
	nav._refresh_main_notifications(view)
	check(abode.reincarnation_button.tooltip_text == "輪迴可用；前往修行查看。", "Era1 exhaustion keeps actionable reincarnation reminder")
	check(FeatureUnlocks.check("reincarnation", view).state == FeatureUnlocks.State.AVAILABLE, "exhaustion exposes reincarnation route")
	view.reincarnation_count = 1
	check(FeatureUnlocks.notification_flags(view, sect).sect, "reincarnated Era1 retains unlocked sect reminder")
	view.era_id = 6
	view.achievements.unclaimed_count = 1
	nav._refresh_main_notifications(view)
	check(abode.reincarnation_button.tooltip_text == "輪迴可用／成就待領／靈獸可餵養；前往修行查看。", "multiple real reminders combine without dropping items")
	check(abode.session.state.to_snapshot_dict() == before, "notification refresh never changes player state")
	nav.home()
	for vp in [Vector2(360, 640), Vector2(800, 360)]:
		abode._layout_for_size(vp)
		await process_frame
		check(abode.orientation_prompt.visible == (vp.x < vp.y), "rotation recovery %s" % vp)
	BuffSystem.apply_buff(abode.session.state, "spirit_surge", 600.0)
	abode._refresh_hud()
	abode._layout_for_size(Vector2(1280, 720))
	await process_frame
	check(abode.buff_hud_bar.is_visible_in_tree(), "active buff appears in home HUD")
	check(abode.buff_hud_bar.badges.has("buff:spirit_surge"), "active buff badge retained")
	nav.open("buildings")
	await process_frame
	check(abode.buff_hud_bar.is_visible_in_tree(), "desktop buildings retain active buff")
	nav.home()
	await process_frame
	check(abode.buff_hud_bar.is_visible_in_tree(), "return home restores active buff")
	abode.set_process(false)
	var debug_before: Dictionary = abode.session.state.to_snapshot_dict()
	abode._on_debug_auto_build_toggled(true)
	check(abode.buff_hud_bar.badges.has("debug:auto_build"), "enabling debug auto build immediately adds a status badge")
	check(abode.buff_hud_bar.badges.has("buff:spirit_surge"), "debug status coexists with gameplay buff")
	var debug_badge: Button = abode.buff_hud_bar.badges["debug:auto_build"]
	check(debug_badge.tooltip_text.contains("30 秒") and debug_badge.tooltip_text.contains("Debug"), "debug badge explains its interval and source")
	debug_badge.pressed.emit()
	check(debug_badge.get_child(1).visible, "debug badge opens the shared buff detail popup")
	check(abode.session.state.to_snapshot_dict() == debug_before, "debug status toggle and badge click do not build or mutate gameplay state")
	debug_badge.get_child(1).hide()
	abode._on_debug_auto_build_toggled(false)
	check(not abode.buff_hud_bar.badges.has("debug:auto_build"), "disabling debug auto build immediately removes its badge")
	check(abode.buff_hud_bar.badges.has("buff:spirit_surge"), "disabling debug leaves gameplay buff intact")
	check(BuffHudBar.status_items({"buffs": []}, {}, true).size() == 1, "debug auto build alone is sufficient to show the status bar")
	abode.queue_free()
	await process_frame
	print("UIX-R2 HUD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
