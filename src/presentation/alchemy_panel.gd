class_name AlchemyPanel
extends Control
signal refine_requested(pill_id: String, count: int)
signal consume_requested(pill_id: String, count: int)
signal close_requested()
const Tile = preload("res://src/presentation/recipe_material_tile.gd")
const RESOURCE_NAMES := {"lingli": "靈氣", "money": "金錢", "wood": "靈木", "black_copper": "玄銅", "spirit_grass_low": "下品靈草", "spirit_grass_100y": "百年靈草", "liquid": "丹液", "stone_low": "下品靈石"}
var _background: Panel
var _content: VBoxContainer
var _close_button: Button
var _title_row: HBoxContainer
var _summary_label: Label
var _feedback: Label
var _scroll: ScrollContainer
var _pills_list: GridContainer
var _pill_rows: Dictionary = {}
var _widgets: Dictionary = {}
var _margin: MarginContainer

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _pills_list != null:
		_background.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if size.y < 350 else UiMaterial.scroll_shell())
		UiMaterial.apply_scroll_content_margins(_margin, size.y < 350)
		_pills_list.columns = 2 if size.x >= 850.0 else 1
		_summary_label.visible = size.y >= 350.0
		_title_row.visible = size.y >= 350.0

func _build_ui() -> void:
	_background = Panel.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.add_theme_stylebox_override("panel", UiMaterial.scroll_shell())
	add_theme_color_override("font_color", UiMaterial.INK)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	var margin := MarginContainer.new()
	_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiMaterial.apply_scroll_content_margins(margin)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	margin.add_child(_content)
	var title_row := HBoxContainer.new()
	_title_row = title_row
	_content.add_child(title_row)
	var title := Label.new()
	title.text = "洞府煉丹房"
	title.add_theme_color_override("font_color", UiMaterial.INK)
	title.add_theme_font_override("font", UiTypography.emphasis_font())
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_close_button = CloseSeal.new()
	_close_button.tooltip_text = "返回洞府"
	_close_button.pressed.connect(func(): close_requested.emit())
	title_row.add_child(_close_button)
	_summary_label = Label.new()
	_summary_label.add_theme_color_override("font_color", UiMaterial.INK)
	_summary_label.add_theme_font_size_override("font_size", 16)
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_summary_label)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.add_theme_font_size_override("font_size", 16)
	_feedback.visible = false
	_content.add_child(_feedback)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_scroll)
	_pills_list = GridContainer.new()
	_pills_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pills_list.add_theme_constant_override("h_separation", 10)
	_pills_list.add_theme_constant_override("v_separation", 10)
	_scroll.add_child(_pills_list)

func show_feedback(text: String, success: bool) -> void:
	_feedback.text = text
	_feedback.tooltip_text = text
	_feedback.add_theme_color_override("font_color", UiMaterial.INK if success else Color("a23e32"))
	_feedback.visible = true

func update_view(view: Dictionary) -> void:
	var data: Dictionary = view.get("alchemy", {})
	var effects: Dictionary = data.get("effects", {})
	_summary_label.text = "壽元 +%s祀 · 產率 +%.0f%% · 服丹 %d顆" % [str(effects.get("lifespan_bonus_years", 0)), float(effects.get("production_multiplier", 0)) * 100.0, int(effects.get("total_consumed", 0))]
	_summary_label.tooltip_text = "當世丹道加成；延壽與產率加成於輪迴後清除。即時效果請參考左側修行與 BUFF。"
	for p in data.get("pills", []):
		var id := String(p.id)
		if not _pill_rows.has(id):
			_pill_rows[id] = _create_pill_row(p)
			_pills_list.add_child(_pill_rows[id])
		_update_pill_row(p, view)

func _create_pill_row(p: Dictionary) -> PanelContainer:
	var id := String(p.id)
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	row.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := Label.new()
	title.text = String(p.name)
	title.add_theme_color_override("font_color", UiMaterial.INK)
	title.add_theme_font_override("font", UiTypography.emphasis_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var count := Label.new()
	count.name = "CountLabel"
	count.add_theme_color_override("font_color", UiMaterial.INK)
	title_row.add_child(count)
	var recipe := HBoxContainer.new()
	recipe.add_theme_constant_override("separation", 6)
	column.add_child(recipe)
	var materials := HFlowContainer.new()
	materials.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	materials.add_theme_constant_override("h_separation", 6)
	materials.add_theme_constant_override("v_separation", 6)
	recipe.add_child(materials)
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_color_override("font_color", UiMaterial.INK)
	recipe.add_child(arrow)
	var output := Tile.new()
	output.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	recipe.add_child(output)
	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 6)
	recipe.add_child(actions)
	var refine := Button.new()
	refine.name = "RefineButton"
	refine.text = "煉製"
	refine.custom_minimum_size = Vector2(64, 44)
	UiMaterial.apply_button(refine)
	refine.pressed.connect(func(): refine_requested.emit(id, 1))
	actions.add_child(refine)
	var consume := Button.new()
	consume.name = "ConsumeButton"
	consume.text = "服用"
	consume.custom_minimum_size = Vector2(64, 44)
	UiMaterial.apply_button(consume)
	consume.pressed.connect(func(): consume_requested.emit(id, 1))
	actions.add_child(consume)
	_widgets[id] = {"title": title, "count": count, "materials": materials, "tiles": {}, "output": output, "refine": refine, "consume": consume}
	return row

func _update_pill_row(p: Dictionary, view: Dictionary) -> void:
	var w: Dictionary = _widgets[String(p.id)]
	var description := String(p.description)
	_pill_rows[String(p.id)].tooltip_text = String(p.name) + "\n" + description
	w.title.tooltip_text = description
	w.count.text = "持有 %d" % int(p.count)
	w.consume.disabled = not bool(p.can_consume)
	w.consume.tooltip_text = description if p.can_consume else "尚未持有此丹藥。\n" + description
	var linked := bool(p.get("manufacturing_link", false))
	w.refine.text = "製造" if linked else "煉製"
	w.refine.disabled = not linked and not bool(p.can_refine)
	w.refine.tooltip_text = "前往祖島製造產線；在製造頁選擇批數與啟動工作。" if linked else "煉製一顆；材料由祖島庫存扣除。" if p.can_refine else "材料不足或尚未開放；需靈植場3階或築基期。"
	var inputs: Dictionary = view.get("manufacturing", {}).get("recipes", {}).get(String(p.id), {}).get("inputs", {}) if linked else {}
	var costs: Dictionary = inputs if linked else p.get("cost", {})
	for resource in w.tiles:
		w.tiles[resource].visible = costs.has(resource)
	for resource in costs:
		if not w.tiles.has(resource):
			w.tiles[resource] = Tile.new()
			w.materials.add_child(w.tiles[resource])
		var stock: Dictionary = view.get("resources", {}).get(resource, {})
		var available := float(stock.get("value", 0))
		var required := float(costs[resource]) if not linked else float(inputs[resource].required)
		if linked:
			available = float(inputs[resource].available)
		w.tiles[resource].refresh(resource, String(RESOURCE_NAMES.get(resource, resource)), required, available, "祖島")
		w.tiles[resource].quantity.text = "%s/%s" % [_number(available), _number(required)]
	# Early pills share the existing pill-family illustration; names and TIP identify effects.
	w.output.refresh("foundation_pill", String(p.name), 1, float(p.count), "丹藥", true)
	w.output.quantity.text = "×%d" % int(p.count)
	w.output.caption.text = "丹藥"
	w.output.tooltip_text = "%s\n持有 %d顆\n%s" % [String(p.name), int(p.count), description]

func _number(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
