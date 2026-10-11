class_name CloseSeal
extends Button

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(44, 44)
	text = "×"
	add_theme_font_override("font", UiTypography.body_font())
	add_theme_font_size_override("font_size", 18)

	# 紙面深墨叉號；僅 hover／按下帶淡墨回饋，不另鋪黑色方塊。
	UiMaterial.mark_paper_tab(self, false)
