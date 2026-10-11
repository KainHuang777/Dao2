class_name DockButton
extends Button

var _red_dot: ColorRect

func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(56, 56)
	
	_red_dot = ColorRect.new()
	_red_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_red_dot.color = Color.TRANSPARENT
	_red_dot.custom_minimum_size = Vector2(10, 10)
	_red_dot.visible = false
	_red_dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_red_dot.offset_left = -12
	_red_dot.offset_bottom = 12
	
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = Color("e0443e")
	dot_style.set_corner_radius_all(5)
	
	var dot_panel := Panel.new()
	dot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot_panel.add_theme_stylebox_override("panel", dot_style)
	dot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_red_dot.add_child(dot_panel)
	
	add_child(_red_dot)

func _notification(what: int) -> void:
	if what == NOTIFICATION_POST_ENTER_TREE or what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_style()

func _toggled(_toggled_on: bool) -> void:
	_update_style()

func _update_style() -> void:
	UiMaterial.apply_jade_navigation(self, button_pressed)
	
func set_red_dot(visible_dot: bool) -> void:
	_red_dot.visible = visible_dot
