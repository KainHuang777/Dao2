extends Control
## Native scrollable command views for existing beasts and realm decisions.
signal action_requested(kind: String, id: String)
var mode := "beasts"
var box: VBoxContainer
var _right_stage: VBoxContainer
var _main_split: HBoxContainer
var _left_scroll: ScrollContainer
var _left_rail: VBoxContainer
var left_nav_host: VBoxContainer
var _nav_sep: HSeparator
var _rail_title: Label
var _rail_subtitle: Label
var left_entry_host: VBoxContainer
var _split_sep: VSeparator
var close_host: HBoxContainer
var _margin: MarginContainer
var content: VBoxContainer
var status: Label
var _signature := ""
var _last_mode := ""
var buttons: Dictionary = {}
var save_failed := false
var _scroll: ScrollContainer
var _surface: PanelContainer
var embedded := false

func set_embedded(value: bool) -> void:
	embedded = value
	if _surface != null:
		set_layout_bounds(Rect2(position, size))
var skill_view: Control
var decision_view: Control
var retry_button: Button
var beast_view: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTypography.create_theme()
	theme.set_color("font_color", "Label", UiMaterial.INK)
	var surface := PanelContainer.new()
	_surface = surface
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", UiMaterial.scroll_shell())
	add_child(surface)
	_margin = MarginContainer.new()
	_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.add_child(_margin)
	_main_split = HBoxContainer.new()
	_main_split.name = "ActionMainSplit"
	_main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_split.add_theme_constant_override("separation", 14)
	_margin.add_child(_main_split)
	_left_scroll = ScrollContainer.new()
	_left_scroll.name = "DecisionLeftRail"
	_left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_scroll.custom_minimum_size = Vector2(168, 0)
	_main_split.add_child(_left_scroll)
	_left_rail = VBoxContainer.new()
	_left_rail.name = "DecisionLeftRailBox"
	_left_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_rail.add_theme_constant_override("separation", 8)
	_left_scroll.add_child(_left_rail)
	left_nav_host = VBoxContainer.new()
	left_nav_host.name = "LeftNavHost"
	left_nav_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_nav_host.add_theme_constant_override("separation", 4)
	_left_rail.add_child(left_nav_host)
	_nav_sep = HSeparator.new()
	_nav_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_rail.add_child(_nav_sep)
	_rail_title = Label.new()
	_rail_title.text = "天道決策"
	_rail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rail_title.add_theme_font_override("font", UiTypography.chapter_font())
	_rail_title.add_theme_font_size_override("font_size", 18)
	_rail_title.add_theme_color_override("font_color", UiMaterial.INK)
	_rail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_rail.add_child(_rail_title)
	_rail_subtitle = Label.new()
	_rail_subtitle.text = "施行界域法令，引動天地氣機。"
	_rail_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rail_subtitle.add_theme_font_size_override("font_size", 15)
	_rail_subtitle.add_theme_color_override("font_color", UiMaterial.INK)
	_rail_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_rail.add_child(_rail_subtitle)
	var rail_spacer := Control.new()
	rail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_rail.add_child(rail_spacer)
	left_entry_host = VBoxContainer.new()
	left_entry_host.name = "LeftEntryHost"
	left_entry_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_entry_host.add_theme_constant_override("separation", 6)
	_left_rail.add_child(left_entry_host)
	_split_sep = VSeparator.new()
	_split_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main_split.add_child(_split_sep)
	box = VBoxContainer.new()
	box.name = "ActionRightStage"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_split.add_child(box)
	_right_stage = box
	close_host = HBoxContainer.new()
	close_host.name = "CloseHost"
	close_host.alignment = BoxContainer.ALIGNMENT_END
	close_host.z_index = 20
	add_child(close_host)
	_left_scroll.hide()
	_split_sep.hide()
	close_host.hide()
	var feedback_row := HBoxContainer.new()
	box.add_child(feedback_row)
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.visible = false
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	feedback_row.add_child(status)
	retry_button = Button.new()
	retry_button.text = "重試保存"
	retry_button.custom_minimum_size = Vector2(0, 44)
	UiMaterial.apply_button(retry_button)
	retry_button.hide()
	retry_button.pressed.connect(func(): action_requested.emit("retry_save", ""))
	feedback_row.add_child(retry_button)
	retry_button.custom_minimum_size.x = 112
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	skill_view = preload("res://src/presentation/skill_study_view.gd").new()
	box.add_child(skill_view)
	skill_view.action_requested.connect(func(kind: String, id: String): action_requested.emit(kind, id))
	skill_view.hide()
	decision_view = preload("res://src/presentation/realm_decision_view.gd").new()
	box.add_child(decision_view)
	decision_view.action_requested.connect(func(kind: String, id: String): action_requested.emit(kind, id))
	decision_view.hide()

	beast_view = preload("res://src/presentation/beast_care_view.gd").new()
	box.add_child(beast_view)
	beast_view.action_requested.connect(func(kind: String, id: String): action_requested.emit(kind, id))
	beast_view.hide()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	var compact := bounds.size.y < 350
	_surface.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if embedded else (UiMaterial.compact_scroll_shell() if compact else UiMaterial.scroll_shell()))
	if is_instance_valid(_margin):
		if embedded:
			UiMaterial.apply_scroll_content_margins(_margin, compact)
		else:
			for side in ["left", "top", "right", "bottom"]:
				_margin.add_theme_constant_override("margin_" + side, 0)
	var decision_rail: bool = embedded and mode == "decisions"
	if is_instance_valid(_main_split):
		_main_split.add_theme_constant_override("separation", (8 if compact else 14) if decision_rail else 0)
	if is_instance_valid(_left_scroll):
		_left_scroll.visible = decision_rail
		_left_scroll.custom_minimum_size.x = 112.0 if bounds.size.x < 500.0 else (140.0 if compact else 168.0)
	if is_instance_valid(_left_rail):
		_left_rail.add_theme_constant_override("separation", 4 if compact else 8)
	if is_instance_valid(_nav_sep):
		_nav_sep.visible = is_instance_valid(left_nav_host) and left_nav_host.get_child_count() > 0
	if is_instance_valid(_rail_subtitle):
		_rail_subtitle.visible = not compact
	if is_instance_valid(_split_sep):
		_split_sep.visible = decision_rail
	if is_instance_valid(close_host):
		close_host.visible = decision_rail
		close_host.position = Vector2(maxf(0.0, bounds.size.x - (12.0 if compact else 18.0) - 44.0), 6.0 if compact else 10.0)
		close_host.size = Vector2(44.0, 44.0)
	box.add_theme_constant_override("separation", 0 if compact else 4)
	decision_view.add_theme_constant_override("separation", 0 if compact else 6)
	_sync_skill_feedback()

func _sync_skill_feedback() -> void:
	if skill_view == null or status == null: return
	var merged := mode == "skills" and size.y < 350 and not save_failed and not status.text.is_empty()
	skill_view.set_feedback(status.text if merged else "")
	status.visible = not status.text.is_empty() and not merged

func show_result(message: String) -> void:
	status.text = message
	status.visible = true
	_sync_skill_feedback()

func _text(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)

func _action(text: String, kind: String, id: String, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.disabled = not enabled
	UiMaterial.apply_button(button)
	button.pressed.connect(func(): action_requested.emit(kind, id))
	content.add_child(button)
	buttons[kind + ":" + id] = button

func refresh(view: Dictionary) -> void:
	if _last_mode != mode:
		if not save_failed: status.text = ""
		status.visible = save_failed
		_last_mode = mode
		if embedded: set_layout_bounds(Rect2(position, size))
	skill_view.visible = mode == "skills"
	decision_view.visible = mode == "decisions"
	_scroll.visible = mode not in ["skills", "decisions", "beasts"]
	beast_view.visible = mode == "beasts"
	retry_button.visible = save_failed
	if mode == "decisions":
		decision_view.refresh(view)
		buttons = decision_view.buttons.duplicate()
		_signature = ""
		return
	if mode == "skills":
		_sync_skill_feedback()
		skill_view.refresh(view)
		buttons = skill_view.buttons.duplicate()
		_signature = ""
		return
	if mode == "beasts":
		beast_view.refresh(view)
		buttons = beast_view.buttons.duplicate()
		_signature = ""
		return

func _costs(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for id in costs:
		var name: String = {"lifespan_seconds": "壽元（秒）", "money": "金錢", "wood": "靈木", "herb": "靈草", "mineral": "礦材", "lingqi": "靈氣", "spirit_crystal": "極品靈晶", "azure_nectar": "天青靈液", "stone_low": "下品靈石", "spirit_grass_low": "靈草", "lingli": "靈氣", "refined_iron": "精鐵", "void_essence": "虛空精華", "star_metal": "星金", "spirit_grass_1000y": "千年靈草"}.get(id, id)
		parts.append("%s %s" % [name, costs[id]])
	return "、".join(parts) if not parts.is_empty() else "無"

func show_save_failure(message: String) -> void:
	save_failed = true
	retry_button.show()
	show_result(message)
func storage_recovered() -> void:
	if save_failed:
		save_failed = false
		retry_button.hide()
		show_result("已恢復保存，進度已寫入。")
