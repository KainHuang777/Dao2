class_name SegmentChips
extends HBoxContainer
## T3 Pills for segment filtering

signal segment_selected(index: int)

var _buttons: Array[Button] = []

func _init() -> void:
	add_theme_constant_override("separation", 8)

func set_segments(labels: PackedStringArray, current: int = 0) -> void:
	for c in get_children():
		c.queue_free()
	_buttons.clear()
	
	for i in range(labels.size()):
		var btn := Button.new()
		btn.text = labels[i]
		btn.toggle_mode = true
		btn.custom_minimum_size.y = 44
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", UiTypography.body_font())
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _on_button_pressed(i))
		_buttons.append(btn)
		add_child(btn)
		_apply_pill_style(btn, i == current)
		btn.set_pressed_no_signal(i == current)

func _on_button_pressed(idx: int) -> void:
	for i in range(_buttons.size()):
		var is_sel = (i == idx)
		_buttons[i].set_pressed_no_signal(is_sel)
		_apply_pill_style(_buttons[i], is_sel)
	segment_selected.emit(idx)

func _apply_pill_style(btn: Button, selected: bool) -> void:
	UiMaterial.mark_paper_tab(btn, selected)
