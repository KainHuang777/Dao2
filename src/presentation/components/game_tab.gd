class_name GameTab
extends Button
## 共用紙面分頁；與資源三態共用青玉選中樣式及黑體。

func _init() -> void:
	toggle_mode = true
	custom_minimum_size = Vector2(80, 44)
	add_theme_font_override("font", UiTypography.body_font())
	toggled.connect(_toggled)
	_update_style()
	focus_mode = Control.FOCUS_NONE

func _notification(what: int) -> void:
	if what == NOTIFICATION_POST_ENTER_TREE or what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_style()

func _toggled(_toggled_on: bool) -> void:
	_update_style()

func _update_style() -> void:
	UiMaterial.mark_paper_tab(self, button_pressed)
