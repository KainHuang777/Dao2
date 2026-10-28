class_name InscriptionAction
extends Button
## Native text, sized to its wording. Shared frameless action for quiet/ceremonial entries.
var on_dark := false:
	set(value):
		on_dark = value
		_apply_ink()

func _init() -> void:
	custom_minimum_size = Vector2(44, 48)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", UiTypography.emphasis_font())
	add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_left = 16
		empty.content_margin_right = 16
		empty.content_margin_top = 10
		empty.content_margin_bottom = 12
		add_theme_stylebox_override(state, empty)
	_apply_ink()
	for changed in [mouse_entered, mouse_exited, focus_entered, focus_exited, button_down, button_up]:
		changed.connect(queue_redraw)

func _apply_ink() -> void:
	var ink := Color("ead59d") if on_dark else Color("326b59")
	add_theme_color_override("font_color", ink)
	add_theme_color_override("font_hover_color", Color("fff4d0") if on_dark else Color("194c3a"))
	add_theme_color_override("font_focus_color", ink)
	add_theme_color_override("font_pressed_color", Color("bda36c") if on_dark else Color("416b82"))
	add_theme_color_override("font_hover_pressed_color", Color("bda36c") if on_dark else Color("416b82"))
	add_theme_color_override("font_disabled_color", Color("9ba69e") if on_dark else Color("68665e"))
	queue_redraw()

func _draw() -> void:
	# A small permanent stroke signals the action; focus extends it and adds two marks.
	# No rectangular outline, hover plate or frame is inherited from the theme.
	var ink := get_theme_color("font_disabled_color" if disabled else "font_color")
	var hot := not disabled and (is_hovered() or has_focus())
	var half := minf(size.x * (0.36 if hot else 0.18), 100.0)
	var center := Vector2(size.x * 0.5, size.y - 6.0)
	draw_line(center - Vector2(half, 0), center + Vector2(half, 0), Color(ink, 0.95 if hot else 0.5), 2.0 if hot or is_pressed() else 1.0, true)
	if has_focus() and not disabled:
		for direction in [-1.0, 1.0]:
			var point := center + Vector2(direction * (half + 6.0), 0)
			draw_circle(point, 2.0, ink)
