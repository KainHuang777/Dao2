extends VBoxContainer
## Presentation-only reminders. No commands, rewards, game clock or RNG.
const INTERVAL := 50.0
const DURATION := 7.0
var abode: Node
var bubble: PanelContainer
var message: Label
var guide_button: Button
var target_button: Button
var details_button: Button
var auto_check: CheckBox
var close_button: Button
var _key := ""
var _counts := {}
var _elapsed := 0.0
var _remaining := 0.0
var _pending := false
var _manual := false
var _actionable := false
var _text := ""
var _speaker := "修行指引"
var _title: Label
var reader: VBoxContainer

class ReadingHost extends VBoxContainer:
	func set_layout_bounds(bounds: Rect2) -> void:
		position = bounds.position
		size = bounds.size

func _init(scene: Node) -> void:
	abode = scene
	name = "MaidGuidanceDock"
	add_theme_constant_override("separation", 6)
	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	add_child(bubble)
	var column := VBoxContainer.new()
	bubble.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.add_theme_font_override("font", UiTypography.emphasis_font())
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", UiMaterial.INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	close_button = CloseSeal.new()
	close_button.tooltip_text = "收起本步提示；本步不再自動提醒"
	close_button.pressed.connect(close_current)
	header.add_child(close_button)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 76
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	message = Label.new()
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_override("font", UiTypography.body_font())
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", UiMaterial.INK)
	scroll.add_child(message)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	target_button = _button("查看目標", "前往當前目標", func():
		dismiss()
		abode._hud_controller._open_current_goal())
	actions.add_child(target_button)
	details_button = _button("詳情", "查看完整引導與條件", func():
		dismiss()
		abode.last_guidance_key = ""
		abode._hud_controller._update_onboarding_guidance(abode._presentation_view())
		abode.feature_navigation.shell.toggle_overlay("messages"))
	actions.add_child(details_button)
	auto_check = CheckBox.new()
	auto_check.text = "自動提示"
	auto_check.tooltip_text = "關閉本次遊玩的自動提醒；仍可點引導圖印查看"
	auto_check.custom_minimum_size.y = 44
	auto_check.button_pressed = true
	auto_check.add_theme_font_size_override("font_size", 16)
	auto_check.toggled.connect(func(_enabled: bool):
		_elapsed = 0.0
		if not _manual: dismiss())
	column.add_child(auto_check)
	guide_button = _button("引", "修行指引：查看當前目標、缺少條件與提示設定", toggle_manual)
	guide_button.accessibility_name = "修行指引"
	guide_button.custom_minimum_size = Vector2(44, 44)
	guide_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_child(guide_button)
	bubble.hide()

func _button(value: String, tip: String, callback: Callable) -> Button:
	var button := InscriptionAction.new()
	button.text = value
	button.tooltip_text = tip
	button.custom_minimum_size = Vector2(44, 44)
	button.pressed.connect(callback)
	return button

func _ready() -> void:
	reader = ReadingHost.new()
	reader.name = "MaidGuidanceReader"
	abode.hud.add_child(reader)
	reader.hide()
	reader.visibility_changed.connect(func():
		if not reader.visible:
			bubble.hide()
			_manual = false
			_counts[_key] = 2
			_pending = false)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(func(): advance(1.0))
	add_child(timer)
	timer.start()

func refresh(view: Dictionary, selected: String) -> void:
	var early: Dictionary = view.get("early_guidance", {})
	var objective: Variant = view.get("next_objective")
	var key := ""
	_actionable = not early.is_empty() or objective is Dictionary
	if not early.is_empty():
		key = "early:%s:%s:%s:%s" % [view.get("era_id", 1), early.get("step", ""), early.get("route", ""), view.get("can_level_up", false)]
	elif objective is Dictionary:
		key = "%s:%s" % [view.get("era_id", 1), abode.last_guidance_key]
	_text = abode._hud_controller._current_guidance_text
	if _text.is_empty(): _text = "暫無新的引導目標，可到經營查看設施與資源。"
	var entry: Dictionary = view.get("maid", {}).get("maids", {}).get(selected, {})
	_speaker = String(entry.get("name", "仙侍")) if bool(entry.get("recruited", false)) else "修行指引"
	_title.text = _speaker
	message.text = _summary(view)
	message.tooltip_text = _text
	target_button.visible = _actionable
	if key != _key:
		_key = key
		_elapsed = 0.0
		_pending = _actionable and int(_counts.get(_key, 0)) < 2
		if not _manual: dismiss()
	if not _actionable and not _manual: dismiss()

func _summary(view: Dictionary) -> String:
	var objective: Variant = view.get("next_objective")
	if objective is Dictionary and view.get("buildings", {}).has(objective.get("id", "")):
		var id := String(objective.id)
		var building: Dictionary = view.buildings[id]
		var missing: Array[String] = []
		for resource_id in building.get("costs", {}):
			var owned = abode._parse_amount(view.get("resources", {}).get(resource_id, {}).get("value", "0"))
			if owned.compare_to(abode._parse_amount(building.costs[resource_id])) < 0:
				missing.append(String(abode.RESOURCE_NAMES.get(resource_id, resource_id)))
		var action := "建造" if int(building.get("level", 0)) == 0 else "升級"
		var title := "%s【%s】" % [action, String(abode.BUILDING_NAMES.get(id, id))]
		return "下一步：%s。%s" % [title, ("材料已足，可前往查看。" if missing.is_empty() else "尚缺%s，點詳情查看取得方式。" % "、".join(missing))]
	var early: Dictionary = view.get("early_guidance", {})
	var title := String(early.get("title", ""))
	if not title.is_empty(): return title + "。點詳情查看條件。"
	var first := _text.split("。")[0]
	return first + "。" if first.length() <= 70 else "目前目標已更新，點詳情查看條件。"

func allowed() -> bool:
	if not is_visible_in_tree(): return false
	var nav = abode.feature_navigation
	return nav != null and nav.group in ["home", "management"] and nav.shell.state.snapshot().overlay.is_empty() and not abode.settings_menu.get_popup().visible

func advance(seconds: float) -> void:
	# Hidden/blocked time never creates a backlog or expires a manual reading.
	if not allowed():
		if not _manual: dismiss()
		return
	if bubble.visible:
		if not _manual:
			_remaining -= seconds
			if _remaining <= 0.0: dismiss()
		return
	if not auto_check.button_pressed or not _actionable: return
	if abode.maid_stand.bubble_bounds(abode.hud.size).size.x <= 0.0: return
	if int(_counts.get(_key, 0)) >= 2: return
	_elapsed += seconds
	if _pending or _elapsed >= INTERVAL:
		_pending = false
		_counts[_key] = int(_counts.get(_key, 0)) + 1
		_elapsed = 0.0
		_remaining = DURATION
		show_bubble(false)

func toggle_manual() -> void:
	if _manual and bubble.visible:
		dismiss()
	else:
		show_bubble(true)

func show_bubble(manual: bool) -> void:
	_manual = manual
	if manual:
		_pending = false
		_elapsed = 0.0
	bubble.show()
	if manual and abode.maid_stand.bubble_bounds(abode.hud.size).size.x <= 0.0:
		close_button.hide()
		bubble.reparent(reader, false)
		abode.feature_navigation.shell.open_tool(reader)
		return
	if bubble.get_parent() != self: bubble.reparent(self, false)
	close_button.show()
	abode.maid_stand.update_layout(abode.hud.size)

func layout_bubble(bounds: Rect2) -> void:
	if is_instance_valid(reader) and reader.visible: return
	if bubble.get_parent() != self: bubble.reparent(self, false)
	if bounds.size.x <= 0.0:
		bubble.hide()
		_manual = false
		return
	position = bounds.position
	size = bounds.size

func close_current() -> void:
	_counts[_key] = 2
	_pending = false
	dismiss()

func dismiss() -> void:
	_manual = false
	_remaining = 0.0
	bubble.hide()
	if is_instance_valid(reader) and reader.visible and abode.feature_navigation.shell._tool == reader:
		abode.feature_navigation.shell.close_overlay()
	if is_instance_valid(abode.maid_stand): abode.maid_stand.update_layout(abode.hud.size)

func _exit_tree() -> void:
	if is_instance_valid(reader): reader.queue_free()
