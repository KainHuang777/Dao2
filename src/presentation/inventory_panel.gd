extends VBoxContainer
const Cell = preload("res://src/presentation/inventory_item_cell.gd")
const Icon = preload("res://src/presentation/resource_icon.gd")
const Numbers = preload("res://src/utils/number_formatter.gd")
var _title: Label
var _scroll: ScrollContainer
var _groups_box: VBoxContainer
var _detail_icon: Control
var _detail_name: Label
var _detail_line: RichTextLabel
var _meter: ProgressBar
var _cells := {}
var _items := {}
var _grids: Array[GridContainer] = []
var _signature: Array = []
var _selected_key := ""
var _context := ""
var _layout_generation := 0
var compact_hint := false

func _init() -> void:
	name = "InventoryPanel"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_title = Label.new()
	_title.add_theme_font_override("font", UiTypography.emphasis_font())
	_title.add_theme_font_size_override("font_size", 20)
	_title.add_theme_color_override("font_color", UiMaterial.INK)
	add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_groups_box = VBoxContainer.new()
	_groups_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_groups_box.add_theme_constant_override("separation", 12)
	_scroll.add_child(_groups_box)
	var readout_shell := PanelContainer.new()
	var readout_style := UiMaterial.rounded(Color("ece8d8"), 6)
	readout_style.set_content_margin_all(6)
	readout_shell.add_theme_stylebox_override("panel", readout_style)
	add_child(readout_shell)
	var readout := HBoxContainer.new()
	readout.add_theme_constant_override("separation", 8)
	readout_shell.add_child(readout)
	_detail_icon = Icon.new()
	_detail_icon.custom_minimum_size = Vector2(36, 36)
	_detail_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	readout.add_child(_detail_icon)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	readout.add_child(column)
	_detail_name = Label.new()
	_detail_name.add_theme_font_override("font", UiTypography.emphasis_font())
	_detail_name.add_theme_font_size_override("font_size", 16)
	_detail_name.add_theme_color_override("font_color", UiMaterial.INK)
	column.add_child(_detail_name)
	_detail_line = RichTextLabel.new()
	_detail_line.bbcode_enabled = false
	_detail_line.fit_content = false
	_detail_line.scroll_active = false
	_detail_line.custom_minimum_size = Vector2(0, 44)
	_detail_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_line.add_theme_font_size_override("normal_font_size", 16)
	_detail_line.add_theme_color_override("default_color", UiMaterial.INK)
	column.add_child(_detail_line)
	_meter = ProgressBar.new()
	_meter.custom_minimum_size.y = 5
	_meter.show_percentage = false
	_meter.add_theme_stylebox_override("background", UiMaterial.rounded(Color("d6d2c0"), 2))
	_meter.add_theme_stylebox_override("fill", UiMaterial.rounded(GraphicAction.JADE, 2))
	_meter.visible = false
	add_child(_meter)

func refresh(data: Dictionary) -> void:
	_title.text = String(data.get("title", "庫存"))
	var groups: Array = data.get("groups", [])
	var signature: Array = []
	for group in groups:
		signature.append(String(group.get("id", "")))
		signature.append(String(group.get("title", "")))
		for item in group.get("items", []):
			signature.append(String(item.get("key", "")))
			signature.append(String(item.get("display", "")))
	if signature != _signature:
		_rebuild(groups)
		_signature = signature
	else:
		_update(groups)
	var context := String(data.get("scope", data.get("context", "")))
	if context != _context:
		_context = context
		_layout_generation += 1
		_selected_key = _first_key(groups)
		_scroll.scroll_vertical = 0
	elif _selected_key.is_empty() or not _cells.has(_selected_key):
		_selected_key = _first_key(groups)
	_select(_selected_key)

func selected_key() -> String:
	return _selected_key

func _rebuild(groups: Array) -> void:
	_layout_generation += 1
	var scroll_position := _scroll.scroll_vertical
	var focused_key := ""
	if is_inside_tree():
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null and focused.has_meta("item_key"):
			focused_key = String(focused.get_meta("item_key"))
	for child in _groups_box.get_children():
		_groups_box.remove_child(child)
		child.queue_free()
	_cells.clear()
	_items.clear()
	_grids.clear()
	for group in groups:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 6)
		_groups_box.add_child(box)
		var heading := Label.new()
		heading.text = String(group.get("title", ""))
		heading.add_theme_font_override("font", UiTypography.emphasis_font())
		heading.add_theme_font_size_override("font_size", 16)
		heading.add_theme_color_override("font_color", GraphicAction.JADE)
		box.add_child(heading)
		var entries: Array = group.get("items", [])
		if entries.is_empty():
			var empty := Label.new()
			empty.text = "尚無庫存"
			empty.add_theme_font_size_override("font_size", 16)
			empty.add_theme_color_override("font_color", UiMaterial.DISABLED_INK)
			box.add_child(empty)
			continue
		var grid := GridContainer.new()
		grid.columns = _columns()
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		box.add_child(grid)
		_grids.append(grid)
		for item in entries:
			var cell := Cell.new()
			cell.apply(item)
			cell.pressed.connect(_select.bind(String(item.get("key", ""))))
			grid.add_child(cell)
			_cells[String(item.get("key", ""))] = cell
			_items[String(item.get("key", ""))] = item
	# Containers settle after the new grids have been laid out.
	_restore_position.call_deferred(scroll_position, focused_key, _layout_generation)

func _restore_position(scroll_position: int, focused_key: String, generation: int) -> void:
	if not is_inside_tree() or generation != _layout_generation: return
	if not focused_key.is_empty() and _cells.has(focused_key):
		_cells[focused_key].grab_focus()
	await get_tree().process_frame
	if generation == _layout_generation:
		_scroll.scroll_vertical = scroll_position

func _update(groups: Array) -> void:
	for group in groups:
		for item in group.get("items", []):
			var key := String(item.get("key", ""))
			_items[key] = item
			if _cells.has(key):
				_cells[key].apply(item)

func _select(key: String) -> void:
	_selected_key = key
	for entry in _cells:
		_cells[entry].set_selected(entry == key)
	var item: Dictionary = _items.get(key, {})
	if item.is_empty():
		_detail_icon.visible = false
		_detail_name.text = ""
		_detail_line.text = "選取物品以查看"
		_meter.visible = false
		return
	_detail_icon.visible = true
	_detail_icon.resource_id = String(item.get("id", ""))
	_detail_icon.queue_redraw()
	var name_text := String(item.get("name", ""))
	if Icon.get_resource_texture(String(item.get("id", ""))) == null:
		name_text += "（無圖示）"
	var compact := compact_hint
	_detail_name.visible = not compact
	_detail_name.text = name_text
	_detail_line.custom_minimum_size.y = 24 if compact else 44
	_detail_line.text = (name_text + "・" + _detail_summary(item)) if compact else _detail_text(item)
	var provided: Dictionary = item.get("provided", {})
	_meter.visible = bool(provided.get("available", false)) and bool(provided.get("capacity", false)) and _number(item.get("capacity")) > 0.0
	if _meter.visible:
		_meter.max_value = _number(item.get("capacity"))
		_meter.value = minf(_meter.max_value, _number(item.get("available")) + _number(item.get("reserved")))
		_meter.tooltip_text = "庫容使用：可用＋容量預留"

func _detail_summary(item: Dictionary) -> String:
	if String(item.get("display", "available")) == "transit":
		return "在途 %s・剩餘 %s 秒" % [Numbers.exact_amount(item.get("transit")), Numbers.exact_amount(item.get("eta"))]
	var provided: Dictionary = item.get("provided", {})
	return "可用 %s／容量 %s" % [
		Numbers.exact_amount(item.get("available")) if bool(provided.get("available", false)) else "未提供",
		Numbers.exact_amount(item.get("capacity")) if bool(provided.get("capacity", false)) else "未提供",
	]

func _detail_text(item: Dictionary) -> String:
	var provided: Dictionary = item.get("provided", {})
	if String(item.get("display", "available")) == "transit":
		return "在途 %s・剩餘 %s 秒\n%s" % [Numbers.exact_amount(item.get("transit")), Numbers.exact_amount(item.get("eta")), String(item.get("source", ""))]
	var lines: Array[String] = []
	lines.append("可用 %s／容量 %s" % [
		Numbers.exact_amount(item.get("available")) if bool(provided.get("available", false)) else "未提供",
		Numbers.exact_amount(item.get("capacity")) if bool(provided.get("capacity", false)) else "未提供",
	])
	if bool(provided.get("demand", false)):
		lines.append("需求 %s" % Numbers.exact_amount(item.get("demand")))
	if bool(provided.get("reserved", false)) and _number(item.get("reserved")) > 0.0:
		lines.append("容量預留 %s" % Numbers.exact_amount(item.get("reserved")))
	if bool(provided.get("transit", false)):
		lines.append("在途 %s" % Numbers.exact_amount(item.get("transit")))
	lines.append("來源：%s" % String(item.get("source", "未提供")))
	return "\n".join(lines)

func _first_key(groups: Array) -> String:
	for group in groups:
		for item in group.get("items", []):
			return String(item.get("key", ""))
	return ""

func _columns() -> int:
	return maxi(2, floori((maxf(1.0, size.x) - 34.0) / 98.0))

func _number(raw: Variant) -> float:
	return float(raw) if raw != null and typeof(raw) in [TYPE_FLOAT, TYPE_INT, TYPE_STRING] else 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not _grids.is_empty():
		var columns := _columns()
		for grid in _grids:
			grid.columns = columns
