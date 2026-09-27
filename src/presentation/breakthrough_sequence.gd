class_name BreakthroughSequence
extends Control
## Results are committed before play(). Skip/replay never submit commands.

signal sequence_started
signal sequence_finished
signal save_retry_requested

var _bg: ColorRect
var _margin: MarginContainer
var _column: VBoxContainer
var _top_bar: HBoxContainer
var _left_spacer: Control
var _header_container: MarginContainer
var _heading_text: VBoxContainer
var _center: VBoxContainer
var _button_row: HFlowContainer
var _title_label: Label
var _subtitle_label: Label
var _couplet_label: Label
var _stage_label: Label
var _save_label: Label
var _result_panel: PanelContainer
var _skip_button: Button
var _replay_button: Button
var _close_button: Button
var _retry_button: Button
var _anim_time: float = 0.0
var _is_playing: bool = false
var _era_name: String = "築基期"
var _from_era_name: String = "練氣期"
var reduced_motion: bool = false
var world_fx: IslandBreakthroughFx

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTypography.create_theme()
	_build_ui()
	resized.connect(_layout_for_viewport)
	_layout_for_viewport()
	visible = false

func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.01, 0.04, 0.08, 0.04)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 12)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_column)

	# 頂部浮動標題區域（無黑色面板，全透明，減少對後方天幕雲海的遮蔽）
	_header_container = MarginContainer.new()
	_header_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_header_container)

	_top_bar = HBoxContainer.new()
	_top_bar.add_theme_constant_override("separation", 8)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_container.add_child(_top_bar)

	_left_spacer = Control.new()
	_left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_spacer.custom_minimum_size = Vector2(96, 48)
	_top_bar.add_child(_left_spacer)

	_heading_text = VBoxContainer.new()
	_heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading_text.add_theme_constant_override("separation", 6)
	_top_bar.add_child(_heading_text)

	_title_label = _make_label("天地同感 · 境界突破", 42, Color("fff1c7"))
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_label.add_theme_constant_override("outline_size", 6)
	_title_label.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06, 0.9))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_title_label.add_theme_constant_override("shadow_offset_x", 0)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	_title_label.add_theme_constant_override("shadow_outline_size", 8)
	_heading_text.add_child(_title_label)

	_stage_label = _make_label("凝聚靈息 · 法陣甦醒", 20, Color("e2f8ec"))
	_stage_label.add_theme_constant_override("outline_size", 4)
	_stage_label.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06, 0.85))
	_stage_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	_stage_label.add_theme_constant_override("shadow_offset_x", 0)
	_stage_label.add_theme_constant_override("shadow_offset_y", 2)
	_stage_label.add_theme_constant_override("shadow_outline_size", 5)
	_heading_text.add_child(_stage_label)

	_skip_button = Button.new()
	_skip_button.text = "跳過演出"
	_skip_button.custom_minimum_size = Vector2(96, 48)
	_skip_button.pressed.connect(_on_skip_pressed)
	_top_bar.add_child(_skip_button)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.add_child(spacer)
	_result_panel = PanelContainer.new()
	_result_panel.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_column.add_child(_result_panel)
	var result_margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		result_margin.add_theme_constant_override("margin_" + edge, 12)
	_result_panel.add_child(result_margin)
	_center = VBoxContainer.new()
	_center.add_theme_constant_override("separation", 8)
	result_margin.add_child(_center)
	_subtitle_label = _make_label("破關築基 · 靈息新生", 26, Color("fce2a6"))
	_subtitle_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_center.add_child(_subtitle_label)
	_couplet_label = _make_label("雲海深處，殘破石像在靈光中若隱若現。", 18, Color("d0e2d3"))
	_center.add_child(_couplet_label)
	_save_label = _make_label("境界已提升 · 進度已保存", 16, Color("aee2c1"))
	_center.add_child(_save_label)
	_button_row = HFlowContainer.new()
	_button_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_button_row.add_theme_constant_override("h_separation", 8)
	_button_row.add_theme_constant_override("v_separation", 8)
	_center.add_child(_button_row)
	_replay_button = Button.new()
	_replay_button.text = "重溫突破"
	_replay_button.custom_minimum_size = Vector2(112, 48)
	_replay_button.pressed.connect(_on_replay_pressed)
	_button_row.add_child(_replay_button)
	_close_button = Button.new()
	_close_button.text = "圓滿出關"
	_close_button.custom_minimum_size = Vector2(112, 48)
	_close_button.pressed.connect(_on_close_pressed)
	_button_row.add_child(_close_button)
	_retry_button = Button.new()
	_retry_button.text = "重試保存"
	_retry_button.custom_minimum_size = Vector2(112, 48)
	_retry_button.pressed.connect(func(): save_retry_requested.emit())
	_retry_button.visible = false
	_button_row.add_child(_retry_button)

func _layout_for_viewport() -> void:
	if _margin == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var portrait := size.x < 640.0 or size.x / size.y < 1.25
	var compact := size.y < 480.0
	var inset := 12 if portrait or compact else 24
	for edge in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + edge, inset)

	if _left_spacer != null:
		_left_spacer.visible = (not portrait) and _skip_button.visible

	var title_size := 22 if (portrait and _skip_button.visible) else (28 if portrait else (34 if compact else 42))
	var title_outline := 4 if portrait else 6
	_title_label.add_theme_font_size_override("font_size", title_size)
	_title_label.add_theme_constant_override("outline_size", title_outline)

	var stage_size := 16 if portrait else (17 if compact else 20)
	var stage_outline := 3 if portrait else 4
	_stage_label.add_theme_font_size_override("font_size", stage_size)
	_stage_label.add_theme_constant_override("outline_size", stage_outline)

	_subtitle_label.add_theme_font_size_override("font_size", 22 if portrait else 26)
	_couplet_label.visible = size.y >= 480.0

func set_save_status(saved: bool) -> void:
	_save_label.text = "境界已提升 · 進度已保存" if saved else "境界已提升 · 保存失敗，請重試"
	_save_label.add_theme_color_override("font_color", Color("aee2c1") if saved else Color("ffd28a"))
	_retry_button.visible = not saved

func play(from_era: String, to_era: String) -> void:
	_from_era_name = from_era
	_era_name = to_era
	_subtitle_label.text = "%s → %s · 破關功成" % [from_era, to_era]
	_is_playing = true
	_anim_time = 0.0
	_result_panel.visible = false
	_skip_button.visible = true
	_stage_label.text = "靈息凝聚 · 法陣甦醒"
	if not visible:
		visible = true
		sequence_started.emit()
	if world_fx != null:
		world_fx.sample_sequence(0.0, reduced_motion)
	_layout_for_viewport()

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_anim_time += delta
	if world_fx != null:
		world_fx.sample_sequence(_anim_time, reduced_motion)
	_bg.color.a = 0.04 if reduced_motion else 0.04 + sin(clampf(_anim_time / IslandBreakthroughFx.DURATION, 0.0, 1.0) * PI) * 0.09
	if _anim_time >= 3.8:
		_stage_label.text = "雲海散開 · 萬象歸寧"
	elif _anim_time >= 1.6:
		_stage_label.text = "靈光貫天 · 空島共鳴"

	if not reduced_motion and _header_container != null:
		var float_offset := int(sin(_anim_time * 2.2) * 4.0)
		_header_container.add_theme_constant_override("margin_top", max(0, 4 + float_offset))

	if _anim_time >= (1.0 if reduced_motion else IslandBreakthroughFx.DURATION):
		_finish_animation()

func _finish_animation() -> void:
	_is_playing = false
	_bg.color.a = 0.04
	_stage_label.text = "境界突破 · 功成出關"
	_skip_button.visible = false
	if _left_spacer != null:
		_left_spacer.visible = false
	if _header_container != null:
		_header_container.add_theme_constant_override("margin_top", 4)
	_result_panel.visible = true
	_layout_for_viewport()
	if world_fx != null:
		world_fx.stop()

func _on_skip_pressed() -> void:
	_finish_animation()

func _on_replay_pressed() -> void:
	play(_from_era_name, _era_name)

func _on_close_pressed() -> void:
	if not visible:
		return
	_is_playing = false
	if world_fx != null:
		world_fx.stop()
	visible = false
	sequence_finished.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and visible:
		_on_close_pressed()
