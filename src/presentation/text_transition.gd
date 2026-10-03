extends Control
## Original native presentation only. Completion never grants or saves game rewards.
signal sequence_started
signal sequence_finished(skipped: bool)

var title_label: Label
var subtitle_label: Label
var skip_button: Button
var content: VBoxContainer
var _elapsed := 0.0
var _playing := false
var _reduced := false
var _mode := "reveal"
var _hold := 1.8
const ENTER := 0.8
const EXIT := 0.45

func _ready() -> void:
	z_index = 90
	theme = UiTypography.create_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	for index in range(3):
		if index == 1:
			title_label = Label.new()
			title_label.add_theme_font_override("font", UiTypography.chapter_font())
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(title_label)
		else:
			var line := HSeparator.new()
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var style := StyleBoxLine.new()
			style.color = Color.WHITE
			style.thickness = 1
			line.add_theme_stylebox_override("separator", style)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(line)
	subtitle_label = Label.new()
	subtitle_label.add_theme_font_override("font", UiTypography.emphasis_font())
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(subtitle_label)
	for label in [title_label, subtitle_label]:
		label.add_theme_color_override("font_color", Color.WHITE)
	skip_button = Button.new()
	skip_button.text = "跳過 · Esc"
	skip_button.custom_minimum_size = Vector2(120, 44)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skip_button.offset_left = -140
	skip_button.offset_top = -64
	skip_button.offset_right = -20
	skip_button.offset_bottom = -20
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	skip_button.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	skip_button.pressed.connect(skip)
	add_child(skip_button)
	resized.connect(_fit)
	visible = false
	set_process(false)
	_fit()

## mode: reveal / fade. Data is copied into labels; no session reference is retained.
func play(main_text: String, detail_text: String = "", options: Dictionary = {}) -> void:
	if _playing:
		_finish(true)
	title_label.text = main_text
	subtitle_label.text = detail_text
	subtitle_label.visible = not detail_text.is_empty()
	_reduced = bool(options.get("reduced_motion", false))
	_mode = str(options.get("mode", "reveal"))
	_hold = clampf(float(options.get("hold", 1.8)), 0.5, 30.0)
	_elapsed = 0.0
	_playing = true
	visible = true
	_fit()
	_render()
	set_process(true)
	sequence_started.emit()

func _fit() -> void:
	if content == null:
		return
	var width := maxf(180.0, size.x * 0.88)
	content.custom_minimum_size.x = width
	title_label.custom_minimum_size.x = width * 0.78
	var font := UiTypography.chapter_font()
	var font_size := clampi(int(size.y * 0.105), 28, 76)
	while font_size > 28 and font.get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width * 0.78:
		font_size -= 1
	title_label.add_theme_font_size_override("font_size", font_size)
	subtitle_label.add_theme_font_size_override("font_size", clampi(int(size.y * 0.035), 17, 26))

func _process(delta: float) -> void:
	advance_presentation(delta)

func advance_presentation(delta: float) -> void:
	if not _playing:
		return
	_elapsed += maxf(0.0, delta)
	if _elapsed >= ENTER + _hold + EXIT:
		_finish(false)
	else:
		_render()

func _render() -> void:
	var enter := clampf(_elapsed / ENTER, 0.0, 1.0)
	var leave := clampf((_elapsed - ENTER - _hold) / EXIT, 0.0, 1.0)
	# Keep the backdrop opaque for the entire sequence, including text fades.
	modulate.a = 1.0
	title_label.visible_ratio = 1.0 if _reduced or _mode == "fade" else enter
	var text_alpha := enter if _reduced or _mode == "fade" else clampf(enter * 3.0, 0.0, 1.0)
	content.modulate.a = minf(text_alpha, 1.0 - leave)
	subtitle_label.modulate.a = clampf((enter - 0.45) / 0.55, 0.0, 1.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if _playing and event.is_action_pressed("ui_cancel"):
		skip()
		get_viewport().set_input_as_handled()

func skip() -> void:
	_finish(true)

func _finish(skipped: bool) -> void:
	if not _playing:
		return
	_playing = false
	set_process(false)
	visible = false
	sequence_finished.emit(skipped)
