extends PanelContainer
## Required quantity stays legible; shortage changes only the tile's colors.
const Icon = preload("res://src/presentation/resource_icon.gd")
const NORMAL := Color("355f58")
const SHORTAGE := Color("a23e32")
var quantity: Label
var caption: Label
var icon: Control
var style: StyleBoxFlat
var shortage := false

func _init() -> void:
	custom_minimum_size.x = 72
	style = StyleBoxFlat.new()
	style.set_corner_radius_all(7)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.20, 0.24, 0.20, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	icon = Icon.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	quantity = Label.new()
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity.add_theme_font_size_override("font_size", 18)
	column.add_child(quantity)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	column.add_child(caption)
	for child in [column, quantity, caption]:
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh(resource: String, name_text: String, amount: float, available: float, source: String, output: bool = false) -> void:
	if icon.resource_id != resource:
		icon.resource_id = resource
		icon.queue_redraw()
	shortage = not output and available < amount
	var color := SHORTAGE if shortage else NORMAL
	# Enclose art, quantity and source as one item; output has a jade finish.
	style.bg_color = Color("f0ddd0") if shortage else Color("dbe7dc") if output else Color("eee8d8")
	style.border_color = Color("ad6552") if shortage else Color("4e7c6c") if output else Color("89917d")
	quantity.add_theme_color_override("font_color", color)
	caption.add_theme_color_override("font_color", color)
	quantity.text = str(amount) if amount != floorf(amount) else str(int(amount))
	caption.text = "產出" if output else source
	tooltip_text = "%s\n%s：可用 %s／%s %s" % [name_text, source, str(available), "產出" if output else "需求", str(amount)]
