class_name OrientationPrompt
extends Control
## Portrait mode orientation prompt overlay.
## Displays an elegant Xianxia-styled prompt when device/viewport is in portrait (width < height),
## guiding the cultivator to rotate the device into landscape for the optimal Dao2 experience.

var _bg: ColorRect
var _container: VBoxContainer
var _title_label: Label
var _desc_label: Label
var _icon_control: Control
var _dismiss_button: Button
var _temporarily_dismissed: bool = false
var _rotation_angle: float = 0.0

func _init() -> void:
	name = "OrientationPrompt"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	_bg = ColorRect.new()
	_bg.color = Color(0.02, 0.04, 0.07, 0.94)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_container = VBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 16)
	add_child(_container)

	# Animated / vector phone rotation icon
	_icon_control = Control.new()
	_icon_control.custom_minimum_size = Vector2(64, 64)
	_icon_control.draw.connect(_on_draw_icon)
	_container.add_child(_icon_control)

	_title_label = Label.new()
	_title_label.text = "大道周天 · 請橫屏靜修"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color("ffd700"))
	_container.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.text = "洞府山河仙境專為橫式天地造設\n請旋轉您的設備以暢享完整修行"
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.add_theme_font_size_override("font_size", 16)
	_desc_label.add_theme_color_override("font_color", Color("d0e2d3"))
	_container.add_child(_desc_label)

	_dismiss_button = Button.new()
	_dismiss_button.text = "暫留直屏預覽（不建議）"
	_dismiss_button.add_theme_font_size_override("font_size", 14)
	_dismiss_button.custom_minimum_size = Vector2(160, 36)
	_dismiss_button.pressed.connect(_on_dismiss_pressed)
	_container.add_child(_dismiss_button)

func _process(delta: float) -> void:
	if visible:
		_rotation_angle += delta * 2.0
		if _rotation_angle > PI * 2.0:
			_rotation_angle -= PI * 2.0
		_icon_control.queue_redraw()

func _on_draw_icon() -> void:
	var center := _icon_control.size * 0.5
	var stroke := 2.5
	var gold := Color("ffd700")
	var cyan := Color("77f2de")

	# Draw phone frame
	var w := 24.0
	var h := 38.0
	var rect := Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h)
	_icon_control.draw_rect(rect, gold, false, stroke)

	# Draw rotation arrows around the phone
	var radius := 28.0
	var arc_start := _rotation_angle
	var arc_end := _rotation_angle + 1.2
	_icon_control.draw_arc(center, radius, arc_start, arc_end, 16, cyan, stroke, true)
	_icon_control.draw_arc(center, radius, arc_start + PI, arc_end + PI, 16, cyan, stroke, true)

func _on_dismiss_pressed() -> void:
	_temporarily_dismissed = true
	visible = false

func update_layout(vp: Vector2) -> void:
	size = vp
	_bg.size = vp
	_container.size = Vector2(minf(vp.x - 32.0, 360.0), 240.0)
	_container.position = (vp - _container.size) * 0.5

	var is_portrait: bool = vp.x < vp.y
	if not is_portrait:
		# Reset dismissal when user rotates to landscape
		_temporarily_dismissed = false
		visible = false
	else:
		visible = not _temporarily_dismissed
