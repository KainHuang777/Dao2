extends Control
## Isolated renderer specimen, reusing the production component and paper material.
const IDS := ["alchemical_past_wisdom", "artisan_past_wisdom", "beast_bond_past_wisdom"]
var pictures: Array[TextureRect] = []
var cells: Array[PanelContainer] = []
var column: VBoxContainer
var scroll: ScrollContainer
var selected_edge := 192

func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTypography.create_theme()
	var paper := Panel.new()
	paper.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	column = VBoxContainer.new()
	margin.add_child(column)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	for edge in [192, 112, 64, 28]:
		var button := Button.new()
		button.text = str(edge) + "px"
		button.custom_minimum_size = Vector2(100, 44)
		UiMaterial.apply_button(button)
		button.pressed.connect(set_edge.bind(edge))
		controls.add_child(button)
	var label := Label.new()
	label.text = "原圖 ／ 共用 B · 正式 Godot"
	label.add_theme_color_override("font_color", UiMaterial.INK)
	controls.add_child(label)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	for id in IDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		rows.add_child(row)
		for treated in [false, true]:
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
			row.add_child(cell)
			cells.append(cell)
			var image: TextureRect = UiIllustration.new() if treated else TextureRect.new()
			image.texture = load("res://assets/ui/reincarnation-painted/" + id + ".png")
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size = Vector2.ONE * selected_edge
			image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cell.add_child(image)
			pictures.append(image)
	set_edge(192)

func set_edge(edge: int) -> void:
	selected_edge = edge
	for picture in pictures: picture.custom_minimum_size = Vector2.ONE * edge
	for cell in cells: cell.custom_minimum_size.y = edge + 18
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.edgeSelection = " + str(edge))
