extends Button
const Icon = preload("res://src/presentation/resource_icon.gd")
const Numbers = preload("res://src/utils/number_formatter.gd")
const ACCENT := Color("2f6b5a")
const SELECTED_BG := Color("dbe5d8")
var key := ""
var item: Dictionary = {}
var _states := {}
var _art: Control
var _fallback: Label
var _amount: Label
var _reserved: Control
var _selected := false

func _init() -> void:
	custom_minimum_size = Vector2(88, 88)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var base := StyleBoxFlat.new()
	base.set_corner_radius_all(8)
	base.set_border_width_all(2)
	base.bg_color = Color("e7e4d4")
	base.border_color = Color("89917d")
	base.shadow_color = Color(0.16, 0.20, 0.17, 0.14)
	base.shadow_size = 2
	base.shadow_offset = Vector2(0, 1)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = base.duplicate()
		if state == "hover":
			style.bg_color = Color("eef0e2")
			style.border_color = ACCENT
		elif state == "pressed":
			style.bg_color = SELECTED_BG
			style.border_color = ACCENT
		elif state == "disabled":
			style.bg_color = Color("d8d6c8")
		elif state == "focus":
			style.border_color = ACCENT
			style.set_border_width_all(3)
		_states[state] = style
		add_theme_stylebox_override(state, style)
	_art = Icon.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.offset_left = 7
	_art.offset_right = -7
	_art.offset_top = 5
	_art.offset_bottom = -5
	_fallback = Label.new()
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback.add_theme_font_size_override("font_size", 16)
	_fallback.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(_fallback)
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fallback.offset_left = 5
	_fallback.offset_right = -5
	_fallback.offset_top = 4
	_fallback.offset_bottom = -18
	_amount = Label.new()
	_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_amount.add_theme_font_override("font", UiTypography.emphasis_font())
	_amount.add_theme_font_size_override("font_size", 20)
	_amount.add_theme_color_override("font_color", Color.WHITE)
	_amount.add_theme_color_override("font_outline_color", Color("24372f"))
	_amount.add_theme_constant_override("outline_size", 5)
	add_child(_amount)
	_amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_amount.offset_left = 5
	_amount.offset_right = -5
	_amount.offset_bottom = -3
	resized.connect(_refresh_amount)
	_reserved = UiIcon.new()
	_reserved.kind = UiIcon.Kind.HOURGLASS
	_reserved.icon_size = 16
	_reserved.tint = GraphicAction.COOL
	_reserved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reserved.visible = false
	add_child(_reserved)
	_reserved.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_reserved.position = Vector2(6, 5)

func apply(data: Dictionary) -> void:
	item = data
	key = String(data.get("key", ""))
	set_meta("item_key", key)
	var id := String(data.get("id", ""))
	var texture := Icon.get_resource_texture(id)
	_art.visible = texture != null
	if texture != null and _art.resource_id != id:
		_art.resource_id = id
		_art.queue_redraw()
	_fallback.visible = texture == null
	_fallback.text = "未識"
	_refresh_amount()
	var provided: Dictionary = data.get("provided", {})
	_reserved.visible = bool(provided.get("reserved", false)) and _number(data.get("reserved")) > 0.0
	tooltip_text = _tip(data)
	set_selected(_selected)

func _refresh_amount() -> void:
	if _amount == null: return
	_amount.text = Numbers.fit_amount(_shown_value(item), _amount.get_theme_font("font"), 20, maxf(size.x, custom_minimum_size.x) - 20)
	_amount.visible = true

func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	var style: StyleBoxFlat = _states["normal"].duplicate()
	if value:
		style.bg_color = SELECTED_BG
		style.border_color = ACCENT
		style.set_border_width_all(3)
	add_theme_stylebox_override("normal", style)
	var focus: StyleBoxFlat = _states["focus"].duplicate()
	if value:
		focus.bg_color = SELECTED_BG
		focus.border_color = ACCENT
		focus.set_border_width_all(3)
	add_theme_stylebox_override("focus", focus)

func _shown_value(data: Dictionary) -> Variant:
	if String(data.get("display", "available")) == "transit":
		return data.get("transit")
	return data.get("available")

func _number(raw: Variant) -> float:
	return float(raw) if raw != null and typeof(raw) in [TYPE_FLOAT, TYPE_INT, TYPE_STRING] else 0.0

func _tip(data: Dictionary) -> String:
	var provided: Dictionary = data.get("provided", {})
	var lines: Array[String] = [String(data.get("name", ""))]
	lines.append("來源：%s" % String(data.get("source", "未提供")))
	if String(data.get("display", "available")) == "transit":
		lines.append("在途：%s" % Numbers.exact_amount(data.get("transit")))
		lines.append("剩餘：%s 秒" % Numbers.exact_amount(data.get("eta")))
		return "\n".join(lines)
	lines.append("可用：%s" % (Numbers.exact_amount(data.get("available")) if bool(provided.get("available", false)) else "未提供"))
	if bool(provided.get("demand", false)):
		lines.append("需求：%s" % Numbers.exact_amount(data.get("demand")))
	if bool(provided.get("reserved", false)):
		lines.append("容量預留：%s" % Numbers.exact_amount(data.get("reserved")))
	lines.append("容量：%s" % (Numbers.exact_amount(data.get("capacity")) if bool(provided.get("capacity", false)) else "未提供"))
	if bool(provided.get("transit", false)):
		lines.append("在途：%s" % Numbers.exact_amount(data.get("transit")))
	return "\n".join(lines)
