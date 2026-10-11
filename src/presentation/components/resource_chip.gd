class_name ResourceChip
extends PanelContainer

var icon_rect: TextureRect
var value_label: Label

func _init() -> void:
	var style := UiMaterial.rounded(Color("273e36"), 6)
	style.border_color = Color("9b8357")
	style.set_border_width_all(1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)
	
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)
	
	value_label = Label.new()
	value_label.add_theme_font_override("font", UiTypography.body_font())
	value_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(value_label)

func setup(res_id: String, amount: float, is_full: bool) -> void:
	var tex_path := "res://assets/ui/resources-painted/%s.png" % res_id
	if ResourceLoader.exists(tex_path):
		icon_rect.texture = load(tex_path)
	else:
		icon_rect.texture = null
	
	if amount >= 10000:
		value_label.text = "%.1fw" % (amount / 10000.0)
	else:
		value_label.text = str(int(floor(amount)))
		
	if is_full:
		value_label.add_theme_color_override("font_color", Color("f3d48c"))
	else:
		value_label.add_theme_color_override("font_color", Color("efe7d1"))
