class_name BreakthroughSequence
extends Control
## BreakthroughSequence: Playable / Replayable celebration sequence for realm breakthroughs.
## Guarantees: skippable, replayable without re-granting rewards, pure presentation.

signal sequence_finished

var _bg: ColorRect
var _center: VBoxContainer
var _button_row: HBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _couplet_label: Label
var _skip_button: Button
var _replay_button: Button
var _close_button: Button

var _anim_time: float = 0.0
var _is_playing: bool = false
var _era_name: String = "築基期"
var _from_era_name: String = "練氣期"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	resized.connect(_layout_for_viewport)
	_layout_for_viewport()
	visible = false

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.01, 0.05, 0.08, 0.92)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_center = VBoxContainer.new()
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_center.custom_minimum_size = Vector2.ZERO
	_center.position = Vector2.ZERO
	_center.add_theme_constant_override("separation", 18)
	add_child(_center)

	_title_label = Label.new()
	_title_label.text = "天地同感 · 境界突破"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color("fce2a6"))
	_center.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "破除凡胎桎梏，邁入【築基期】"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_override("font", UiTypography.body_font())
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_subtitle_label.add_theme_font_size_override("font_size", 28)
	_subtitle_label.add_theme_color_override("font_color", Color("e2f8ec"))
	_center.add_child(_subtitle_label)

	_couplet_label = Label.new()
	_couplet_label.text = "「金鱗豈是池中物，一朝築基跨仙凡」"
	_couplet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_couplet_label.add_theme_font_override("font", UiTypography.body_font())
	_couplet_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_couplet_label.add_theme_font_size_override("font_size", 24)
	_couplet_label.add_theme_color_override("font_color", Color("ffe082"))
	_center.add_child(_couplet_label)

	_button_row = HBoxContainer.new()
	_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_row.add_theme_constant_override("separation", 24)
	_center.add_child(_button_row)

	_skip_button = Button.new()
	_skip_button.text = "跳過演出"
	_skip_button.custom_minimum_size = Vector2(130, 50)
	_skip_button.pressed.connect(_on_skip_pressed)
	_button_row.add_child(_skip_button)

	_replay_button = Button.new()
	_replay_button.text = "重溫突破"
	_replay_button.custom_minimum_size = Vector2(130, 50)
	_replay_button.pressed.connect(_on_replay_pressed)
	_button_row.add_child(_replay_button)

	_close_button = Button.new()
	_close_button.text = "圓滿出關"
	_close_button.custom_minimum_size = Vector2(130, 50)
	_close_button.pressed.connect(_on_close_pressed)
	_button_row.add_child(_close_button)

func _layout_for_viewport() -> void:
	if _center == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var portrait: bool = size.x < 640.0 or size.x / size.y < 1.25
	var content_size := Vector2(minf(700.0, size.x - 24.0), minf(400.0, size.y - 24.0))
	_center.custom_minimum_size = Vector2.ZERO
	_center.position = (size - content_size) * 0.5
	_center.size = content_size
	_title_label.add_theme_font_size_override("font_size", 28 if portrait else 42)
	_subtitle_label.add_theme_font_size_override("font_size", 20 if portrait else 28)
	_couplet_label.add_theme_font_size_override("font_size", 18 if portrait else 24)
	_couplet_label.text = "「金鱗豈是池中物，\n一朝築基跨仙凡」" if portrait else "「金鱗豈是池中物，一朝築基跨仙凡」"
	_button_row.add_theme_constant_override("separation", 8 if portrait else 24)
	for button in [_skip_button, _replay_button, _close_button]:
		button.custom_minimum_size = Vector2(96 if portrait else 130, 50)

func play(from_era: String, to_era: String) -> void:
	_from_era_name = from_era
	_era_name = to_era
	_subtitle_label.text = "破除%s桎梏，邁入【%s】" % [from_era, to_era]
	visible = true
	_is_playing = true
	_anim_time = 0.0
	_bg.color = Color(0.01, 0.05, 0.08, 0.0)

func _process(delta: float) -> void:
	if not _is_playing:
		return
	_anim_time += delta
	var alpha: float = minf(0.92, _anim_time * 0.8)
	_bg.color = Color(0.02 + sin(_anim_time * 2.0) * 0.01, 0.07, 0.11, alpha)
	var glow: float = 1.0 + sin(_anim_time * 3.0) * 0.15
	_title_label.modulate = Color(glow, glow, glow, 1.0)
	if _anim_time >= 5.0:
		_is_playing = false

func _on_skip_pressed() -> void:
	_is_playing = false
	_bg.color = Color(0.01, 0.05, 0.08, 0.92)
	_title_label.modulate = Color.WHITE

func _on_replay_pressed() -> void:
	play(_from_era_name, _era_name)

func _on_close_pressed() -> void:
	_is_playing = false
	visible = false
	sequence_finished.emit()
