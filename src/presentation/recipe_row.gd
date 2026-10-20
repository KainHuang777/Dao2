class_name RecipeRow
extends PanelContainer
## Shared presentation row for manufacturing and alchemy recipes.
## Features prominent product badge with island crest, state illumination,
## graphical material flow (MaterialTile), progress indicator, and action buttons.

const MaterialTile = preload("res://src/presentation/recipe_material_tile.gd")
const ResourceIcon = preload("res://src/presentation/resource_icon.gd")

# Colors for state border/illumination
const COLOR_IDLE := Color("89917d")
const COLOR_RUNNING := Color("4e7c6c")
const COLOR_SHORTAGE := Color("ad6552")
const COLOR_OUTPUT_FULL := Color("c69234")
const COLOR_PENDING := Color("5b8098")

var recipe_id := ""
var island_id := "home"

# Core controls exposed for full backwards compatibility with manufacturing_panel and tests
var column: VBoxContainer
var header: HBoxContainer
var compact_row: HBoxContainer
var sidebar: VBoxContainer
var title: Button
var materials: HBoxContainer
var tiles: Dictionary = {}
var output_tile: Control
var time: Label
var progress: ProgressBar
var status: Label
var action: Button

# Graphical enhancements (MFG-2)
var recipe_badge: Button
var badge_island_icon: UiIcon
var hourglass_icon: UiIcon
var status_icon: UiIcon
var time_box: HBoxContainer
var status_box: HBoxContainer
var info_box: VBoxContainer
var controls: HBoxContainer
var modes: SegmentChips
var settings: Button

var _state_border_color := COLOR_IDLE
var _state_glow := false

signal select_requested(recipe_id: String)
signal action_requested(recipe_id: String)
signal mode_requested(recipe_id: String, index: int)

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())

	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	# 1. Prominent product badge with state border and island crest
	recipe_badge = Button.new()
	recipe_badge.custom_minimum_size = Vector2(56, 56)
	recipe_badge.flat = true
	recipe_badge.focus_mode = Control.FOCUS_NONE
	recipe_badge.pressed.connect(func(): select_requested.emit(recipe_id))
	recipe_badge.draw.connect(_draw_badge)
	header.add_child(recipe_badge)

	# Corner badge for island emblem
	badge_island_icon = UiIcon.new()
	badge_island_icon.kind = UiIcon.Kind.ISLAND_HOME
	badge_island_icon.icon_size = 18
	badge_island_icon.tint = Color("f0e6cf")
	badge_island_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_island_icon.position = Vector2(36, 36)
	recipe_badge.add_child(badge_island_icon)

	# 2. Information area (Title + Time/Stock + Status)
	info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 2)
	header.add_child(info_box)

	title = Button.new()
	title.custom_minimum_size.y = 44
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.flat = true
	title.focus_mode = Control.FOCUS_NONE
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UiMaterial.INK)
	title.pressed.connect(func(): select_requested.emit(recipe_id))
	info_box.add_child(title)

	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 12)
	info_box.add_child(sub_row)

	time_box = HBoxContainer.new()
	time_box.add_theme_constant_override("separation", 4)
	sub_row.add_child(time_box)

	hourglass_icon = UiIcon.new()
	hourglass_icon.kind = UiIcon.Kind.HOURGLASS
	hourglass_icon.icon_size = 14
	hourglass_icon.tint = Color("706b5b")
	time_box.add_child(hourglass_icon)

	time = Label.new()
	time.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time.add_theme_font_size_override("font_size", 16)
	time.add_theme_color_override("font_color", Color("706b5b"))
	time_box.add_child(time)

	status_box = HBoxContainer.new()
	status_box.add_theme_constant_override("separation", 4)
	sub_row.add_child(status_box)

	status_icon = UiIcon.new()
	status_icon.kind = UiIcon.Kind.PLAY
	status_icon.icon_size = 14
	status_icon.tint = COLOR_RUNNING
	status_icon.visible = false
	status_box.add_child(status_icon)

	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color("505856"))
	status_box.add_child(status)

	# 3. Action button
	action = Button.new()
	action.custom_minimum_size = Vector2(100, 44)
	action.pressed.connect(func(): action_requested.emit(recipe_id))
	controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	modes = SegmentChips.new()
	modes.add_theme_constant_override("separation", 2)
	modes.set_segments(["單批", "批數", "持續"])
	modes.segment_selected.connect(func(index: int): mode_requested.emit(recipe_id, index))
	controls.add_child(modes)
	action.custom_minimum_size.x = 88
	action.add_theme_font_size_override("font_size", 16)
	UiMaterial.apply_button(action)
	controls.add_child(action)
	settings = Button.new()
	settings.text = "設定"
	settings.custom_minimum_size = Vector2(44, 44)
	settings.add_theme_font_size_override("font_size", 16)
	settings.tooltip_text = "展開或收起此配方的批數、原料保留量與切方設定"
	UiMaterial.apply_button(settings)
	settings.pressed.connect(func(): select_requested.emit(recipe_id))
	controls.add_child(settings)

	# 4. Progress bar
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 6
	var prog_bg := StyleBoxFlat.new()
	prog_bg.bg_color = Color(0.8, 0.78, 0.72, 0.5)
	prog_bg.set_corner_radius_all(3)
	var prog_fill := StyleBoxFlat.new()
	prog_fill.bg_color = COLOR_RUNNING
	prog_fill.set_corner_radius_all(3)
	progress.add_theme_stylebox_override("background", prog_bg)
	progress.add_theme_stylebox_override("fill", prog_fill)
	column.add_child(progress)

	# 5. Materials container (horizontal layout)
	materials = HBoxContainer.new()
	materials.alignment = BoxContainer.ALIGNMENT_CENTER
	materials.add_theme_constant_override("separation", 6)
	column.add_child(materials)

	# 6. Compact row & sidebar for short mobile landscape displays
	compact_row = HBoxContainer.new()
	compact_row.visible = false
	compact_row.add_theme_constant_override("separation", 12)
	column.add_child(compact_row)

	sidebar = VBoxContainer.new()
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.custom_minimum_size.x = 220
	compact_row.add_child(sidebar)
	column.add_child(controls)

func setup(p_recipe_id: String, on_select: Callable = Callable(), on_act: Callable = Callable()) -> void:
	recipe_id = p_recipe_id
	if on_select.is_valid():
		select_requested.connect(func(_id = ""): on_select.call())
	if on_act.is_valid():
		action_requested.connect(func(_id = ""): on_act.call())

func show_mode(index: int, count: int) -> void:
	for i in modes._buttons.size():
		var button: Button = modes._buttons[i]
		var selected := i == index
		button.set_pressed_no_signal(selected)
		if not button.has_meta("selected") or button.get_meta("selected") != selected:
			UiMaterial.mark_paper_tab(button, selected)
			button.set_meta("selected", selected)
	modes._buttons[1].text = "%d批" % count if index == ProductionController.Mode.COUNT and count <= 999 else "批數"

func _draw_badge() -> void:
	var b_size: Vector2 = recipe_badge.size
	var r := Rect2(Vector2.ZERO, b_size)

	# 1. Background tile with rounded corners
	var bg_color := Color("f7f3e8")
	recipe_badge.draw_rect(r, bg_color, true, -1.0)

	# 2. Draw product texture centered
	var tex: Texture2D = ResourceIcon.get_resource_texture(recipe_id)
	if tex != null:
		var tex_size := Vector2(minf(36, b_size.x - 16), minf(36, b_size.y - 16))
		var tex_rect := Rect2((b_size - tex_size) * 0.5, tex_size)
		recipe_badge.draw_texture_rect(tex, tex_rect, false)

	# 3. Outer border and status glow
	if _state_glow:
		recipe_badge.draw_rect(r.grow(2.0), Color(_state_border_color.r, _state_border_color.g, _state_border_color.b, 0.3), false, 2.0)
	recipe_badge.draw_rect(r, _state_border_color, false, 2.0)

	# 4. Island crest circular background at bottom-right
	var crest_center := b_size - Vector2(10, 10)
	recipe_badge.draw_circle(crest_center, 11, Color("2d3b38"))
	recipe_badge.draw_circle(crest_center, 11, Color("8d978a"), false, 1.0)

func set_island(p_island: String) -> void:
	island_id = p_island
	match island_id:
		"home": badge_island_icon.kind = UiIcon.Kind.ISLAND_HOME
		"wood": badge_island_icon.kind = UiIcon.Kind.WOOD
		"ore": badge_island_icon.kind = UiIcon.Kind.ORE
		"herb": badge_island_icon.kind = UiIcon.Kind.HERB
		_: badge_island_icon.kind = UiIcon.Kind.ISLAND_HOME
	badge_island_icon.queue_redraw()
	var island_name: String = IslandProgression.NAMES.get(island_id, island_id)
	recipe_badge.tooltip_text = "%s\n空島：%s" % [ResourceIcon.get_resource_name(recipe_id), island_name]

func set_state_visual(p_color: Color, glow: bool = false) -> void:
	_state_border_color = p_color
	_state_glow = glow
	recipe_badge.queue_redraw()

## Backwards-compatible layout helper for compact landscape mode.
func apply_layout(compact: bool) -> void:
	compact_row.visible = compact
	time_box.visible = not compact
	if compact:
		if materials.get_parent() != compact_row:
			materials.reparent(compact_row)
		compact_row.move_child(materials, 0)
		for child in [header, controls, status_box, time_box]:
			if child.get_parent() != sidebar:
				child.reparent(sidebar)
		sidebar.move_child(header, 0)
		sidebar.move_child(controls, 1)
		column.move_child(compact_row, 0)
		recipe_badge.custom_minimum_size = Vector2(44, 44)
		badge_island_icon.position = Vector2(26, 26)
	else:
		if materials.get_parent() != column:
			materials.reparent(column)
		for child in [header, status_box, time_box, controls]:
			if child.get_parent() != column:
				child.reparent(column)
		# Restore standard order inside column
		column.move_child(header, 0)
		column.move_child(progress, 1)
		column.move_child(status_box, 2)
		column.move_child(materials, 3)
		column.move_child(time_box, 4)
		recipe_badge.custom_minimum_size = Vector2(56, 56)
		badge_island_icon.position = Vector2(36, 36)
	recipe_badge.queue_redraw()

## Provides backwards-compatible dictionary representation for manufacturing_panel cards collection
func as_card_dict() -> Dictionary:
	return {
		"root": self,
		"column": column,
		"header": header,
		"compact_row": compact_row,
		"sidebar": sidebar,
		"title": title,
		"materials": materials,
		"tiles": tiles,
		"time": time,
		"progress": progress,
		"status": status,
		"action": action,
		"recipe_badge": recipe_badge,
		"row": self
	}
