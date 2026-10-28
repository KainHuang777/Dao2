extends PanelContainer
## Read-only island destinations. All navigation is owned by island_world.
signal selected(id: String)
signal close_requested()
var buttons := {}
var _labels := {}
var _images := {}
var _selected := {}
var _order: Array[String] = []
var title: Label
var _column: VBoxContainer
var scroll: ScrollContainer
var rows: VBoxContainer
var footer: HBoxContainer
var _close: Button
var _compact := false

func _init() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel",UiMaterial.scroll_shell())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	_column = column
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var label := Label.new()
	label.text = "選擇空島"
	label.add_theme_font_override("font",UiTypography.emphasis_font())
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",UiMaterial.INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	_close = CloseSeal.new()
	_close.tooltip_text = "收起選島清單"
	_close.pressed.connect(func(): close_requested.emit())
	heading.add_child(_close)
	title = Label.new()
	title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",UiMaterial.INK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",6)
	scroll.add_child(rows)
	footer = HBoxContainer.new()
	column.add_child(footer)

func set_layout_bounds(bounds: Rect2) -> void:
	# Shared tool host supplies safe vertical bounds; the selector uses a right drawer.
	var parent_size: Vector2 = get_parent().size
	var width := minf(304.0,bounds.size.x)
	position = Vector2(parent_size.x-bounds.position.x-width,bounds.position.y)
	size = Vector2(width,bounds.size.y)
	set_compact(parent_size.y < 500)

func set_compact(compact: bool) -> void:
	if _compact == compact: return
	_compact = compact
	add_theme_stylebox_override("panel",UiMaterial.compact_scroll_shell() if compact else UiMaterial.scroll_shell())
	for id in buttons: buttons[id].custom_minimum_size.y = 80 if compact else 92
	title.visible = not compact
	footer.visible = not compact
	_column.add_theme_constant_override("separation",4 if compact else 8)
	queue_sort()

func refresh(items: Array, current: String, status: String) -> void:
	title.text = status
	var ids: Array[String] = []
	for item in items: ids.append(item.id)
	if ids != _order:
		for id in buttons.keys():
			if id not in ids:
				rows.remove_child(buttons[id]); buttons[id].queue_free()
				buttons.erase(id); _labels.erase(id); _images.erase(id); _selected.erase(id)
		for index in items.size():
			var item: Dictionary = items[index]
			if not buttons.has(item.id): _add_row(item.id)
			rows.move_child(buttons[item.id],index)
		_order = ids
	for item in items:
		var id: String = item.id
		var active: bool = id == current
		if not _selected.has(id) or _selected[id] != active:
			UiMaterial.apply_scroll_button(buttons[id],active)
			_selected[id] = active
		_labels[id].text = item.name + (" · 當前" if active else "") + "\n" + item.status
		buttons[id].tooltip_text = item.name + "\n" + item.status + "\n點選前往；查看條件或管理不會自動開拓。"
		if _images[id].texture != item.texture: _images[id].texture = item.texture

	if _compact and buttons.has(current) and rows.get_child_count() > 0 and rows.get_child(0) != buttons[current]:
		rows.move_child(buttons[current], 0)

func reveal_current(id: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_visible_in_tree() and buttons.has(id): scroll.ensure_control_visible(buttons[id])
	await get_tree().process_frame
	if is_visible_in_tree() and buttons.has(id): scroll.ensure_control_visible(buttons[id])

func _add_row(id: String) -> void:
	var hit := Button.new()
	hit.custom_minimum_size = Vector2(236,80 if _compact else 92)
	hit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hit.pressed.connect(func(): selected.emit(id))
	rows.add_child(hit)
	buttons[id] = hit
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: inset.add_theme_constant_override("margin_"+side,6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inset.add_child(row)
	var art := UiIllustration.new()
	art.custom_minimum_size = Vector2(88,64)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art)
	_images[id] = art
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font",UiTypography.body_font())
	name_label.add_theme_font_size_override("font_size",18)
	name_label.add_theme_color_override("font_color",UiMaterial.INK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	_labels[id] = name_label
