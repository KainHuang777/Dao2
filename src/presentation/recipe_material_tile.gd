extends PanelContainer
const Icon = preload("res://src/presentation/resource_icon.gd")
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
const NORMAL := Color("355f58")
const SHORTAGE := Color("a23e32")
var quantity: Label
var caption: Label
var icon: Control
var fallback: Label
var cell: Control
var style: StyleBoxFlat
var shortage := false
var show_source_caption := false
var compact := false
var _reserved: Control
var _reserved_value := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(72, 72)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	style = StyleBoxFlat.new()
	style.set_corner_radius_all(7)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.20, 0.24, 0.20, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var cell_control := Control.new()
	cell = cell_control
	cell.custom_minimum_size = Vector2(56, 56)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cell)
	var icon_frame := CenterContainer.new()
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cell.add_child(icon_frame)
	icon = Icon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(48, 48)
	icon_frame.add_child(icon)
	fallback = Label.new()
	fallback.text = "未識"
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.add_theme_font_size_override("font_size", 16)
	fallback.add_theme_color_override("font_color", UiMaterial.INK)
	fallback.hide()
	cell.add_child(fallback)
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quantity = Label.new()
	quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity.add_theme_font_override("font", UiTypography.emphasis_font())
	quantity.add_theme_font_size_override("font_size", 16)
	quantity.add_theme_color_override("font_color", NORMAL)
	quantity.add_theme_color_override("font_outline_color", Color.WHITE)
	quantity.add_theme_constant_override("outline_size", 4)
	cell.add_child(quantity)
	quantity.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quantity.offset_right = -4
	quantity.offset_bottom = -2
	_reserved = UiIcon.new()
	_reserved.kind = UiIcon.Kind.HOURGLASS
	_reserved.icon_size = 14
	_reserved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reserved.visible = false
	cell.add_child(_reserved)
	_reserved.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_reserved.position = Vector2(3, 3)
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	column.add_child(caption)
	caption.hide()

func refresh(resource: String, name_text: String, amount: float, available: float, source: String, output: bool = false) -> void:
	if icon.resource_id != resource:
		icon.resource_id = resource
		icon.queue_redraw()
	shortage = not output and available < amount
	var color := SHORTAGE if shortage else NORMAL
	style.bg_color = Color("f0ddd0") if shortage else Color("dbe7dc") if output else Color("eee8d8")
	style.border_color = Color("ad6552") if shortage else Color("4e7c6c") if output else Color("89917d")
	quantity.add_theme_color_override("font_color", color)
	caption.add_theme_color_override("font_color", color)
	var amount_str := NumberFormatter.format_amount(amount)
	var avail_str := NumberFormatter.format_amount(available)
	quantity.text = amount_str
	caption.text = "產出" if output else source
	var texture := Icon.get_resource_texture(resource)
	icon.visible = texture != null
	fallback.visible = texture == null
	# Sources belong to the tooltip, never an extra row stretching the item square.
	caption.hide()
	tooltip_text = "%s\n%s：可用 %s／%s %s" % [name_text, source, avail_str, "產出" if output else "需求", amount_str]
	set_reserved(0.0)

func set_compact(enabled: bool) -> void:
	if compact == enabled:
		return
	compact = enabled
	cell.custom_minimum_size = Vector2(36, 36) if enabled else Vector2(56, 56)
	icon.custom_minimum_size = Vector2(28, 28) if enabled else Vector2(48, 48)
	custom_minimum_size = Vector2(48, 48) if enabled else Vector2(72, 72)
	style.content_margin_left = 6 if enabled else 8
	style.content_margin_right = 6 if enabled else 8
	style.content_margin_top = 6 if enabled else 8
	style.content_margin_bottom = 6 if enabled else 8
	quantity.add_theme_font_size_override("font_size", 12 if enabled else 16)
	quantity.add_theme_constant_override("outline_size", 3 if enabled else 4)
	_reserved.icon_size = 10 if enabled else 14
	caption.hide()
	icon.queue_redraw()

func set_reserved(value: float) -> void:
	_reserved_value = value
	_reserved.visible = value > 0.0

func reserved_visible() -> bool:
	return _reserved.visible
