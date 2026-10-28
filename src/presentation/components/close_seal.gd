class_name CloseSeal
extends Button
## Shared vector close; no font glyph or texture dependency.

func _init() -> void:
	custom_minimum_size = Vector2(44, 44)
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "關閉"
	accessibility_name = "關閉"
	UiMaterial.mark_paper_tab(self, false)
	var pressed_style: StyleBoxFlat = get_theme_stylebox("hover").duplicate()
	pressed_style.bg_color = Color(0.36, 0.40, 0.30, 0.24)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("hover_pressed", pressed_style)
	for event in [mouse_entered, mouse_exited, button_down, button_up, focus_entered, focus_exited]:
		event.connect(queue_redraw)

func _draw() -> void:
	var ink := UiMaterial.INK
	if disabled: ink = UiMaterial.DISABLED_INK
	elif get_draw_mode() in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]: ink = Color("254e40")
	var center := size * 0.5
	var radius := 7.0
	draw_line(center + Vector2(-radius, -radius), center + Vector2(radius, radius), ink, 2.0, true)
	draw_line(center + Vector2(-radius, radius), center + Vector2(radius, -radius), ink, 2.0, true)

## Legacy dark dialogs use the same paper header, keeping ink contrast and hit area.
static func paper_header(parent: Node) -> HBoxContainer:
	var paper := PanelContainer.new()
	paper.name = "CloseHeader"
	paper.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	parent.add_child(paper)
	var row := HBoxContainer.new()
	row.name = "Header"
	row.add_theme_constant_override("separation", 8)
	paper.add_child(row)
	return row
