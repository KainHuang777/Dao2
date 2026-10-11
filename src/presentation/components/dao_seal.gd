class_name DaoSeal
extends Control

var progress_ratio: float = 0.0:
	set(v):
		progress_ratio = clampf(v, 0.0, 1.0)
		queue_redraw()

var text: String = "道":
	set(v):
		text = v
		if _label != null:
			_label.text = v

var _label: Label

func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	
	var bg := Panel.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2a3f38")
	style.border_color = Color("ab9464")
	style.set_border_width_all(2)
	style.set_corner_radius_all(32)
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UiTypography.chapter_font())
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", UiMaterial.LIGHT_TEXT)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 7.0
	draw_arc(center, radius, 0, TAU, 64, Color("749b80"), 1.0, true)
	if progress_ratio > 0:
		draw_arc(center, radius, -PI/2, -PI/2 + PI * 2 * progress_ratio, 32, Color("537b66"), 4.0, true)
