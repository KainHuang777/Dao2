extends RefCounted
## Single shared display owner for home and every canonical feature route.
const Policy = preload("res://src/presentation/ui_shell_policy.gd")
const State = preload("res://src/presentation/ui_shell_state.gd")
var state = State.new()
var abode: Node
var compact_hud: PanelContainer
var metrics: Label
var life_metrics: Label
var progress: ProgressBar
var actions: HBoxContainer
var entry: HBoxContainer
var resource_button: Button
var collapse_button: Button
var message_button: Button
var shield: ColorRect
var overlay_close: Button
var overlay_header: PanelContainer
var alert: HBoxContainer
var alert_text: Label
var save_failed := false
var effective := {}
var _applying := false
var _tool: Control
var _priority_token := 0
var _priority_kind := ""
var _action_home: Node
var _status_home: Node
var _overlay_z: Dictionary = {}
var context_paper: PanelContainer
var context_text: Label

func _init(scene: Node) -> void:
	abode = scene

func build() -> void:
	compact_hud = PanelContainer.new()
	compact_hud.name = "ShellCompactHud"
	var style := UiMaterial.hud_paper()
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	compact_hud.add_theme_stylebox_override("panel", style)
	abode.hud.add_child(compact_hud)
	var row := HBoxContainer.new()
	compact_hud.add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	metrics = Label.new()
	metrics.add_theme_font_size_override("font_size", 16)
	metrics.add_theme_color_override("font_color", UiMaterial.INK)
	var metric_row := HBoxContainer.new()
	column.add_child(metric_row)
	metric_row.add_child(metrics)
	life_metrics = Label.new()
	life_metrics.add_theme_font_size_override("font_size", 16)
	metric_row.add_child(life_metrics)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 5
	column.add_child(progress)
	actions = HBoxContainer.new()
	row.add_child(actions)
	_action_home = abode.level_up_button.get_parent()
	_status_home = abode._hud_controller._status_row.get_parent()
	state.set_home_preferences(abode.resource_display_mode, abode._hud_controller._messages_open)
	entry = HBoxContainer.new()
	entry.name = "ShellEntries"
	abode.hud.add_child(entry)
	resource_button = _button("資源", func(): toggle_overlay("resources"))
	entry.add_child(resource_button)
	collapse_button = _button("暫收", toggle_resources)
	entry.add_child(collapse_button)
	message_button = _button("訊息", func(): toggle_overlay("messages"))
	entry.add_child(message_button)
	shield = ColorRect.new()
	shield.name = "ShellInputShield"
	shield.color = Color(0.03, 0.07, 0.08, 0.72)
	shield.mouse_filter = Control.MOUSE_FILTER_STOP
	shield.z_index = 70
	abode.hud.add_child(shield)
	overlay_close = CloseSeal.new()
	overlay_header = PanelContainer.new()
	overlay_header.z_index = 80
	var close_paper := UiMaterial.hud_paper()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: close_paper.set_content_margin(side, 4)
	overlay_header.add_theme_stylebox_override("panel", close_paper)
	overlay_close.tooltip_text = "返回原頁"
	overlay_close.pressed.connect(close_overlay)
	overlay_header.add_child(overlay_close)
	abode.hud.add_child(overlay_header)
	alert = HBoxContainer.new()
	alert.z_index = 81
	alert.name = "ShellSaveAlert"
	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	alert.add_child(paper)
	alert_text = Label.new()
	alert_text.clip_text = true
	alert_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	alert_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alert_text.text = "保存失敗・進度尚未存妥"
	alert_text.add_theme_color_override("font_color", Color("a23e32"))
	paper.add_child(alert_text)
	alert.add_child(_button("重試保存", func(): abode._save_game()))
	abode.hud.add_child(alert)
	for control in [compact_hud, entry, shield, overlay_header, alert]:
		control.hide()
	for panel in [abode.hint_panel, abode.resource_ribbon, abode.save_controls, abode.debug_panel, abode.offline_summary, abode.v2_rules_notice, abode.nine_realms_preview]:
		_overlay_z[panel] = panel.z_index
	for panel in [abode.save_controls, abode.debug_panel]:
		panel.visibility_changed.connect(func():
			if panel == _tool and not panel.visible and not _applying:
				close_overlay())
	context_paper = PanelContainer.new()
	context_paper.name = "ShellContextResources"
	context_paper.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	abode.hud.add_child(context_paper)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	context_paper.add_child(scroll)
	context_text = Label.new()
	context_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_text.add_theme_font_size_override("font_size", 16)
	context_text.add_theme_color_override("font_color", UiMaterial.INK)
	scroll.add_child(context_text)
	context_paper.hide()
	for button in [abode.reincarnation_panel._talents_button, abode.reincarnation_panel._reincarnate_button, abode.sect_panel._tab_expeditions_btn, abode.sect_panel._tab_techniques_btn, abode.sect_panel._tab_market_btn]:
		button.pressed.connect(func(): abode._layout_for_size(abode.hud.size))
	for panel in [abode.feature_navigation.island_panel, abode.feature_navigation.manufacturing_panel, abode.feature_navigation.transport_panel]:
		panel.context_changed.connect(func(): abode._layout_for_size(abode.hud.size))

func _button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(64, 44)
	button.pressed.connect(callback)
	return button

func managed() -> bool:
	return true

func navigate(route: String) -> bool:
	_priority()
	if not state.navigate(route, abode._presentation_view()):
		return false
	return true

func home_preferences(mode: int, messages: bool) -> void:
	state.set_home_preferences(mode, messages)

func toggle_resources() -> void:
	state.collapse_resources(not state.snapshot().resources_collapsed)
	abode._layout_for_size(abode.hud.size)

func toggle_overlay(kind: String) -> void:
	_priority()
	if state.snapshot().overlay == kind:
		close_overlay()
		return
	var token: int = state.open_overlay(kind)
	if token == 0: return
	abode.get_viewport().gui_release_focus()
	_applying = true
	if is_instance_valid(_tool): _tool.hide()
	_tool = null
	_applying = false
	abode._layout_for_size(abode.hud.size)

func open_tool(panel: Control) -> void:
	_priority()
	if panel == _tool and state.snapshot().overlay == "tool":
		close_overlay()
		return
	var token: int = state.open_overlay("tool")
	if token == 0: return
	_applying = true
	if is_instance_valid(_tool): _tool.hide()
	_tool = panel
	abode.get_viewport().gui_release_focus()
	panel.show()
	_applying = false
	abode._layout_for_size(abode.hud.size)

func close_overlay() -> void:
	var snapshot: Dictionary = state.snapshot()
	if snapshot.overlay in ["protection", "report", "sequence"]: return
	if not state.finish_overlay(int(snapshot.overlay_token), abode._presentation_view()): return
	_applying = true
	if is_instance_valid(_tool): _tool.hide()
	_tool = null
	_applying = false
	var route: String = state.snapshot().route
	var nav = abode.feature_navigation
	if route != ("home" if nav.group == "home" else nav.page):
		if route == "home": nav.home()
		else: nav.open(route)
		return
	abode._layout_for_size(abode.hud.size)

func back() -> bool:
	if state.snapshot().overlay.is_empty(): return false
	close_overlay()
	return true

func set_save_result(result: Dictionary) -> void:
	save_failed = not bool(result.get("ok", false))
	if save_failed:
		alert_text.text = "保存失敗・%s" % str(result.get("error", "SAVE_FAILED"))
		alert_text.tooltip_text = alert_text.text
	if managed(): apply(abode.hud.size)

func _priority() -> void:
	# Legacy report/sequence lifecycle is observed at the adapter boundary only.
	# Finishing an old tool never finishes the newer protection token.
	var kind := ""
	if is_instance_valid(abode._storage_block_layer): kind = "protection"
	elif abode.breakthrough_seq.visible or abode.reincarnation_seq.visible or abode.text_transition.visible or abode.nine_realms_preview._is_cinematic_playing: kind = "sequence"
	elif abode.offline_summary.visible or abode.v2_rules_notice.visible or (abode.nine_realms_preview.visible and abode.feature_navigation.page != "realms"): kind = "report"
	if kind == _priority_kind: return
	if _priority_token != 0:
		state.finish_overlay(_priority_token, abode._presentation_view())
		_priority_token = 0
	if not kind.is_empty():
		_priority_token = state.open_overlay(kind)
		if _priority_token != 0:
			_applying = true
			if is_instance_valid(_tool): _tool.hide()
			_tool = null
			_applying = false
	_priority_kind = kind

func apply(vp: Vector2) -> void:
	if _applying or not managed(): return
	_applying = true
	_priority()
	_sync_subpage()
	var snapshot: Dictionary = state.snapshot()
	var starter: Node = abode.buildings.get("hut")
	var obstructs: bool = vp.y < 500 and not abode._hud_controller._messages_explicit and starter != null and starter.visible and starter.level == 0
	var view: Dictionary = abode._presentation_view()
	var context: Dictionary = preload("res://src/presentation/ui_shell_resources.gd").describe(snapshot, view, abode.feature_navigation)
	effective = Policy.resolve(snapshot, vp, {"save_failed": save_failed, "lifespan_exhausted": abode.lifespan_banner.visible, "home_message_obstructs": obstructs, "has_costs": context.has_costs})
	var home: bool = snapshot.route == "home"
	var wide: bool = effective.layout == "wide"
	var skill_view = abode.feature_navigation.action_panel.skill_view
	var study: Button = skill_view.buttons["study:"]
	var skill_top: Control = skill_view.heading.get_parent().get_parent()
	var short_skills: bool = snapshot.route == "skills" and not wide
	var study_host: Node = entry if short_skills else skill_top
	if study.get_parent() != study_host: study.reparent(study_host, false)
	study.custom_minimum_size.x = 64 if short_skills else 112
	study.text = "藏經閣" if short_skills else "經營建築"
	skill_top.visible = not short_skills
	var portrait: bool = effective.layout == "portrait"
	var cinematic: bool = snapshot.overlay == "sequence"
	var margin := 16.0
	var bottom: float = abode.toolbar.position.y - 8.0
	var hc = abode._hud_controller
	for panel in _overlay_z: panel.z_index = _overlay_z[panel]
	context_paper.z_index = 0
	# Exactly one active action host; the original buttons and callbacks survive.
	var host: Node = _action_home if home else actions
	for button in [abode.level_up_button, abode.breakthrough_button]:
		if button.get_parent() != host: button.reparent(host, false)
	var status_host: Node = _status_home if home else compact_hud.get_child(0)
	if hc._status_row.get_parent() != status_host: hc._status_row.reparent(status_host, false)
	if not home: hc._status_row.visible = abode.buff_hud_bar.visible or abode.lifespan_banner.visible
	if home: hc._reflow_header()
	metrics.text = "%s %s　" % [abode.realm_label.text, hc._rank_compact_text]
	life_metrics.text = "壽元已盡" if abode.lifespan_banner.visible else hc._lifespan_text.text
	life_metrics.add_theme_color_override("font_color", hc._lifespan_text.get_theme_color("font_color"))
	life_metrics.tooltip_text = hc._lifespan_text.tooltip_text
	metrics.tooltip_text = abode.realm_progress_label.text + "\n" + hc._lifespan_text.tooltip_text
	progress.max_value = hc._training_bar.max_value
	progress.value = hc._training_bar.value
	compact_hud.position = Vector2(margin, 12)
	compact_hud.size = Vector2(vp.x - margin * 2.0 - 56.0, 44)
	compact_hud.visible = not home and effective.hud == "compact"
	abode.header.visible = home and effective.hud == "full"
	abode.toolbar.visible = effective.navigation
	abode.settings_menu.visible = effective.navigation
	abode.feature_navigation.bar.visible = not home and effective.navigation
	entry.visible = not portrait and not cinematic and snapshot.overlay != "protection"
	resource_button.visible = effective.resource_entry
	collapse_button.visible = not home and effective.resource_entry and not short_skills
	collapse_button.text = "展開" if snapshot.resources_collapsed else "暫收"
	resource_button.text = "資源" if home or (wide and effective.resource_presentation == "rail") else context.summary
	resource_button.tooltip_text = context.details + "\n點開資源；費用與資格以操作旁即時資料為準。"
	if short_skills:
		var feedback: String = abode.feature_navigation.action_panel.status.text
		if not feedback.is_empty():
			resource_button.text = "點數 %s・%s" % [context.summary.trim_prefix("技能點 "), "未完成" if feedback.begins_with("操作未完成") else "已更新"]
			resource_button.tooltip_text += "\n" + feedback
	resource_button.custom_minimum_size.x = 64 if home or wide else (176 if short_skills else 156)
	resource_button.clip_text = true
	resource_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var entry_width: float = maxf(216, entry.get_combined_minimum_size().x)
	entry.position = Vector2(vp.x - margin - entry_width, vp.y - margin - 48)
	entry.size = Vector2(entry_width, 44)
	var overlay: String = snapshot.overlay
	var modal: bool = overlay in ["resources", "messages", "tool", "report"]
	shield.visible = modal and not portrait
	shield.position = Vector2.ZERO
	shield.size = vp
	overlay_header.visible = shield.visible and overlay != "report"
	overlay_header.position = Vector2(vp.x - margin - 52, 8)
	overlay_header.size = Vector2(52, 52)
	var rail: bool = effective.resource_presentation == "rail"
	var drawer: bool = effective.resource_presentation == "drawer"
	var scoped: bool = not home and snapshot.route not in ["buildings", "alchemy"]
	abode.resource_ribbon.visible = (rail or drawer) and not scoped
	context_paper.visible = (rail or drawer) and scoped
	context_text.text = context.details
	# Work resources never overwrite home display preferences.
	var mode: int = int(snapshot.home_preferences.resource_mode) if home else 1
	abode.building_catalog.set_resource_display_mode(maxi(1, mode) if drawer else mode)
	abode.resource_scroll.visible = mode > 0 or drawer
	abode.resource_mode_buttons[0].get_parent().visible = home
	if not home:
		var left := 276.0 if rail else margin
		var width := vp.x - left - margin
		var tab_top := 68.0
		var tab_height := 60.0 if wide else 52.0
		var content_top := tab_top + tab_height + (8.0 if wide else 4.0)
		var tab_style := UiMaterial.compact_scroll_shell()
		tab_style.content_margin_top = 8 if wide else 4
		tab_style.content_margin_bottom = 8 if wide else 4
		abode.feature_navigation.bar.add_theme_stylebox_override("panel", tab_style)
		abode.feature_navigation.bar.position = Vector2(left, tab_top)
		abode.feature_navigation.bar.size = Vector2(width - 56, tab_height)
		var bounds := Rect2(left, content_top, width, maxf(80, bottom - content_top - (52 if save_failed else 0)))
		abode.feature_navigation.layout_page(bounds)
		abode.resource_ribbon.position = Vector2(margin, 68)
		abode.resource_ribbon.size = Vector2(248, bottom - 68)
		context_paper.position = abode.resource_ribbon.position
		context_paper.size = abode.resource_ribbon.size
	if drawer:
		abode.resource_ribbon.position = Vector2(margin, 68)
		abode.resource_ribbon.size = Vector2(minf(440, vp.x - margin * 2), vp.y - 84)
		abode.resource_scroll.visible = true
		context_paper.position = abode.resource_ribbon.position
		context_paper.size = abode.resource_ribbon.size
	var reading: bool = effective.messages == "reading"
	abode.hint_panel.visible = reading or effective.messages == "home"
	if abode.hint_panel.visible:
		var width := minf(540, vp.x - (abode.header.size.x + 64 if home and not reading else 32))
		var height := minf(300 if abode._hint_expanded else 220, bottom - 84)
		abode.hint_panel.position = Vector2((vp.x - width) * 0.5 if reading else maxf(abode.header.get_rect().end.x + 12, (vp.x - width) * 0.5), bottom - height)
		abode.hint_panel.size = Vector2(width, height)
	alert.visible = save_failed and not portrait and not cinematic and overlay != "protection"
	alert.position = Vector2(276 if not home and rail else margin, bottom - 44)
	alert.size = Vector2(vp.x - margin - alert.position.x, 44)
	if modal:
		abode.hud.move_child(shield, -1)
		if overlay == "report":
			for panel in [abode.offline_summary, abode.v2_rules_notice, abode.nine_realms_preview]:
				if panel.visible:
					panel.z_index = 75
					abode.hud.move_child(panel, -1)
		if drawer:
			var resource_panel: Control = context_paper if scoped else abode.resource_ribbon
			resource_panel.z_index = 75
			abode.hud.move_child(resource_panel, -1)
		if reading:
			abode.hint_panel.z_index = 75
			abode.hud.move_child(abode.hint_panel, -1)
		if overlay == "tool" and is_instance_valid(_tool):
			_tool.z_index = 75
			_tool.set_layout_bounds(Rect2(margin, 68, minf(600, vp.x - 32), vp.y - 84))
			abode.hud.move_child(_tool, -1)
		abode.hud.move_child(overlay_header, -1)
		if alert.visible: abode.hud.move_child(alert, -1)
	abode.camera.input_locked = not effective.world_input
	if abode.camera.input_locked:
		abode.camera.dragging = false
		abode.camera.contacts.clear()
	_applying = false

func _sync_subpage() -> void:
	var route: String = state.snapshot().route
	var subpage := ""
	if route == "reincarnation": subpage = abode.reincarnation_panel._active_tab
	elif route == "sect": subpage = ["expeditions", "techniques", "market"][abode.sect_panel._current_tab]
	state.set_subpage(subpage)
