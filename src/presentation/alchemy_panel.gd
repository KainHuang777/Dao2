class_name AlchemyPanel
extends Control

signal refine_requested(pill_id: String, count: int)
signal consume_requested(pill_id: String, count: int)
signal close_requested()

var _background: Panel
var _content: VBoxContainer
var _title_row: HBoxContainer
var _title_label: Label
var _close_button: Button

# 丹道統計摘要
var _summary_panel: PanelContainer
var _summary_label: Label

# 丹藥列表
var _scroll: ScrollContainer
var _pills_list: VBoxContainer
var _pill_rows: Dictionary = {}

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _scroll != null:
		_scroll.custom_minimum_size.y = 0.0
	if _background != null:
		_background.size = size
	if _scroll != null:
		var pad := 16.0
		_scroll.position = Vector2(pad, pad)
		_scroll.size = Vector2(maxf(0.0, size.x - pad * 2.0), maxf(0.0, size.y - pad * 2.0))

func _build_ui() -> void:
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_content = VBoxContainer.new()
	_content.name = "AlchemyContent"
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	# 頂部標題與關閉
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_title_row)

	_title_label = Label.new()
	_title_label.text = "洞府煉丹房"
	_title_label.add_theme_font_override("font", UiTypography.chapter_font())
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "關閉"
	_close_button.custom_minimum_size = Vector2(80, 44)
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)

	# 丹道統計摘要橫幅
	_summary_panel = PanelContainer.new()
	var sum_box := UiMaterial.card()
	sum_box.content_margin_left = 12
	sum_box.content_margin_right = 12
	sum_box.content_margin_top = 8
	sum_box.content_margin_bottom = 8
	_summary_panel.add_theme_stylebox_override("panel", sum_box)
	_content.add_child(_summary_panel)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_label.text = "當前丹道加成：壽元 +0 祀 | 全局產率 +0% | 累計服丹 0 顆"
	_summary_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_summary_panel.add_child(_summary_label)

	# 丹藥列表滾動容器

	_pills_list = VBoxContainer.new()
	_pills_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pills_list.add_theme_constant_override("separation", 10)
	_content.add_child(_pills_list)

func update_view(view: Dictionary) -> void:
	var alchemy_data: Dictionary = view.get("alchemy", {})
	var effects: Dictionary = alchemy_data.get("effects", {})
	var lifespan_bonus := float(effects.get("lifespan_bonus_years", 0.0))
	var prod_bonus := float(effects.get("production_multiplier", 0.0)) * 100.0
	var total_consumed := int(effects.get("total_consumed", 0))

	_summary_label.text = "當前丹道加成：當世壽元 +%d 祀 | 全局產率 +%.0f%% | 累計服丹 %d 顆" % [
		int(lifespan_bonus),
		prod_bonus,
		total_consumed
	]

	var pills: Array = alchemy_data.get("pills", [])
	for p in pills:
		var p_id: String = String(p["id"])
		var row: PanelContainer
		if _pill_rows.has(p_id):
			row = _pill_rows[p_id]
		else:
			row = _create_pill_row(p)
			_pill_rows[p_id] = row
			_pills_list.add_child(row)
		_update_pill_row(row, p, view)

func _create_pill_row(p: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	var box := UiMaterial.card()
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	row.add_theme_stylebox_override("panel", box)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	hbox.add_child(info_box)

	var top_line := HBoxContainer.new()
	info_box.add_child(top_line)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = String(p["name"])
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	name_label.add_theme_font_override("font", UiTypography.emphasis_font())
	name_label.add_theme_font_size_override("font_size", 18)
	top_line.add_child(name_label)

	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.text = " (持有: 0)"
	count_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	top_line.add_child(count_label)

	var desc_label := Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = String(p["description"])
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	info_box.add_child(desc_label)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
	info_box.add_child(cost_label)

	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 6)
	hbox.add_child(btn_box)

	var refine_btn := Button.new()
	refine_btn.name = "RefineButton"
	refine_btn.text = "煉製"
	refine_btn.custom_minimum_size = Vector2(72, 44)
	var p_id: String = String(p["id"])
	refine_btn.pressed.connect(func(): refine_requested.emit(p_id, 1))
	btn_box.add_child(refine_btn)

	var consume_btn := Button.new()
	consume_btn.name = "ConsumeButton"
	consume_btn.text = "服用"
	consume_btn.custom_minimum_size = Vector2(72, 44)
	consume_btn.pressed.connect(func(): consume_requested.emit(p_id, 1))
	btn_box.add_child(consume_btn)

	return row

func _update_pill_row(row: PanelContainer, p: Dictionary, view: Dictionary) -> void:
	var count: int = int(p["count"])
	var count_lbl: Label = row.find_child("CountLabel", true, false)
	if count_lbl != null:
		count_lbl.text = " (持有: %d)" % count
		if count > 0:
			count_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			count_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	var cost_lbl: Label = row.find_child("CostLabel", true, false)
	if cost_lbl != null:
		var cost_parts: Array = []
		var cost_def: Dictionary = p.get("cost", {})
		var res_names := {
			"lingli": "靈氣",
			"money": "金錢",
			"wood": "靈木",
			"stone_low": "靈石",
			"black_copper": "玄銅",
			"spirit_grass_low": "下品靈草",
		}
		for r_id in cost_def:
			var r_name: String = res_names.get(r_id, r_id)
			cost_parts.append("%s %d" % [r_name, int(cost_def[r_id])])
		cost_lbl.text = "煉製消耗: " + "、".join(PackedStringArray(cost_parts))

	var refine_btn: Button = row.find_child("RefineButton", true, false)
	if refine_btn != null:
		var linked := bool(p.get("manufacturing_link", false))
		refine_btn.text = "製造" if linked else "煉製"
		refine_btn.disabled = not linked and not bool(p["can_refine"])
		if linked and cost_lbl != null:
			cost_lbl.text = "祖島產線・前往製造查看材料與工作"

	var consume_btn: Button = row.find_child("ConsumeButton", true, false)
	if consume_btn != null:
		consume_btn.disabled = not bool(p["can_consume"])
