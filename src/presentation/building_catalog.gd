extends PanelContainer
## Bounded management view for buildings that do not have authored world footprints.

signal building_selected(building_id: String)
signal density_changed(is_compact: bool)
signal resource_toggle_requested()

var rows: Dictionary = {}
var group_rows: Dictionary = {}
var scroll: ScrollContainer
var resource_button: Button
var density_button: Button
var close_button: Button
var _content: VBoxContainer
var is_compact: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var surface := UiTypography.dialog_surface()
	surface.content_margin_left = 12
	surface.content_margin_right = 12
	surface.content_margin_top = 12
	surface.content_margin_bottom = 12
	add_theme_stylebox_override("panel", surface)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	box.add_child(title_row)
	var heading := Label.new()
	heading.text = "營造設施"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", UiTypography.emphasis_font())
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("fff0c8"))
	title_row.add_child(heading)

	resource_button = Button.new()
	resource_button.text = "資源"
	resource_button.custom_minimum_size = Vector2(60, 40)
	resource_button.add_theme_font_override("font", UiTypography.body_font())
	resource_button.add_theme_font_size_override("font_size", 16)
	resource_button.pressed.connect(func(): resource_toggle_requested.emit())
	title_row.add_child(resource_button)

	density_button = Button.new()
	density_button.text = "緊湊"
	density_button.custom_minimum_size = Vector2(60, 40)
	density_button.add_theme_font_override("font", UiTypography.body_font())
	density_button.add_theme_font_size_override("font_size", 16)
	density_button.pressed.connect(_on_density_pressed)
	title_row.add_child(density_button)

	close_button = Button.new()
	close_button.text = "收起"
	close_button.custom_minimum_size = Vector2(64, 40)
	close_button.add_theme_font_override("font", UiTypography.emphasis_font())
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(hide)
	title_row.add_child(close_button)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)

func configure(groups: Array) -> void:
	for group in groups:
		var group_id: String = String(group.get("id", ""))
		var group_box := VBoxContainer.new()
		group_box.add_theme_constant_override("separation", 6)
		_content.add_child(group_box)
		group_rows[group_id] = group_box
		var group_title := Label.new()
		group_title.text = String(group.get("title", ""))
		group_title.add_theme_font_override("font", UiTypography.emphasis_font())
		group_title.add_theme_font_size_override("font_size", 20)
		group_title.add_theme_color_override("font_color", Color("d9c58b"))
		group_box.add_child(group_title)
		for entry in group.get("entries", []):
			var id: String = String(entry.get("id", ""))
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, 54)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_override("font", UiTypography.body_font())
			button.add_theme_font_size_override("font_size", 19)
			button.add_theme_color_override("font_color", Color("f4e7be"))
			button.add_theme_stylebox_override("normal", _row_style(Color(0.02, 0.08, 0.10, 0.98)))
			button.add_theme_stylebox_override("hover", _row_style(Color(0.08, 0.19, 0.19, 0.99)))
			button.add_theme_stylebox_override("pressed", _row_style(Color(0.12, 0.27, 0.23, 0.99)))
			button.pressed.connect(_select.bind(id))
			button.set_meta("title", String(entry.get("title", id)))
			button.set_meta("role", String(entry.get("role", "")))
			group_box.add_child(button)
			rows[id] = button
	_apply_density()

func set_compact_mode(compact: bool) -> void:
	if is_compact == compact and density_button != null and density_button.text != "":
		return
	is_compact = compact
	if density_button != null:
		density_button.text = "標準" if is_compact else "緊湊"
	_apply_density()

func _on_density_pressed() -> void:
	set_compact_mode(not is_compact)
	density_changed.emit(is_compact)

func _apply_density() -> void:
	var btn_height: float = 40.0 if is_compact else 54.0
	var font_size: int = 16 if is_compact else 19
	var group_font_size: int = 17 if is_compact else 20
	var v_sep: int = 4 if is_compact else 8
	var group_sep: int = 3 if is_compact else 6

	if _content != null:
		_content.add_theme_constant_override("separation", v_sep)

	for group_id in group_rows:
		var group_box: VBoxContainer = group_rows[group_id]
		group_box.add_theme_constant_override("separation", group_sep)
		for child in group_box.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", group_font_size)
			elif child is Button:
				child.custom_minimum_size.y = btn_height
				child.add_theme_font_size_override("font_size", font_size)

func refresh(buildings: Dictionary) -> void:
	for id in rows:
		var button: Button = rows[id]
		var view: Dictionary = buildings.get(id, {})
		button.visible = bool(view.get("visible", false))
		if not button.visible:
			continue
		var level: int = int(view.get("level", 0))
		var status := "待建" if level == 0 else "%d階" % level
		if level == 0 and bool(view.get("affordable", false)):
			status = "可建"
		var role: String = button.get_meta("role")
		button.text = "%s  ·  %s  ·  %s" % [button.get_meta("title"), status, role]
	for group_id in group_rows:
		var group_box: VBoxContainer = group_rows[group_id]
		var has_visible := false
		for child in group_box.get_children():
			if child is Button and child.visible:
				has_visible = true
				break
		group_box.visible = has_visible

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

func _select(id: String) -> void:
	building_selected.emit(id)

func _row_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.70, 0.63, 0.43, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4 if is_compact else 6
	style.content_margin_bottom = 4 if is_compact else 6
	return style

