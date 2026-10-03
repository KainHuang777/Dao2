class_name ReincarnationPanel
extends Control

signal reincarnate_requested(mode: String)
signal learn_talent_requested(talent_id: String)
signal close_requested()

var _body_scroll: ScrollContainer
var _background: Panel
var _content: VBoxContainer
var _title_row: HBoxContainer
var _tab_row: HBoxContainer
var _reincarnate_button: Button
var _talents_button: Button
var _close_button: Button

# 貨幣資訊
var _currency_label: Label

# 輪迴分頁
var _reincarnate_box: VBoxContainer
var _cycle_label: Label
var _eligibility_label: Label
var _preview_label: Label
var _reincarnate_action_button: Button
var _reincarnate_desc_label: Label

# 天賦分頁
var _talents_box: VBoxContainer
var _talents_list: VBoxContainer
var _talent_rows: Dictionary = {}

var _active_tab: String = "reincarnate" # "reincarnate" | "talents"

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _body_scroll != null:
		_body_scroll.position = Vector2(16, 16)
		_body_scroll.size = Vector2(maxf(0.0, size.x - 32.0), maxf(0.0, size.y - 32.0))

func _build_ui() -> void:
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_body_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.name = "ReincarnationContent"
	_content.add_theme_constant_override("separation", 12)
	_body_scroll.add_child(_content)

	# 頂部標題與貨幣
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_title_row)

	var title := Label.new()
	title.text = "輪迴天道"
	title.add_theme_font_override("font", UiTypography.chapter_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f4e7be"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(title)

	_close_button = Button.new()
	_close_button.text = "關閉"
	_close_button.custom_minimum_size = Vector2(80, 40)
	_close_button.add_theme_font_override("font", UiTypography.body_font())
	_close_button.add_theme_font_size_override("font_size", 16)
	_close_button.pressed.connect(_on_close_pressed)
	_title_row.add_child(_close_button)

	_currency_label = Label.new()
	_currency_label.text = "道心: 0  |  道證: 0"
	_currency_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_currency_label.add_theme_font_size_override("font_size", 17)
	_currency_label.add_theme_color_override("font_color", Color("7de0a8"))
	_content.add_child(_currency_label)


	# 標籤頁切換
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 8)
	_content.add_child(_tab_row)

	_reincarnate_button = Button.new()
	_reincarnate_button.text = "轉世輪迴"
	_reincarnate_button.custom_minimum_size = Vector2(120, 40)
	_reincarnate_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_reincarnate_button.add_theme_font_size_override("font_size", 16)
	_reincarnate_button.pressed.connect(func(): _switch_tab("reincarnate"))
	_tab_row.add_child(_reincarnate_button)

	_talents_button = Button.new()
	_talents_button.text = "道心天賦"
	_talents_button.custom_minimum_size = Vector2(120, 40)
	_talents_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_talents_button.add_theme_font_size_override("font_size", 16)
	_talents_button.pressed.connect(func(): _switch_tab("talents"))
	_tab_row.add_child(_talents_button)

	# 分頁容器一：輪迴轉世
	_reincarnate_box = VBoxContainer.new()
	_reincarnate_box.name = "ReincarnateBox"
	_reincarnate_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reincarnate_box.add_theme_constant_override("separation", 14)
	_content.add_child(_reincarnate_box)

	_cycle_label = Label.new()
	_cycle_label.add_theme_font_override("font", UiTypography.body_font())
	_cycle_label.add_theme_font_size_override("font_size", 18)
	_cycle_label.add_theme_color_override("font_color", Color("f4e7be"))
	_reincarnate_box.add_child(_cycle_label)

	_eligibility_label = Label.new()
	_eligibility_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_eligibility_label.add_theme_font_size_override("font_size", 18)
	_eligibility_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reincarnate_box.add_child(_eligibility_label)

	_preview_label = Label.new()
	_preview_label.add_theme_font_override("font", UiTypography.body_font())
	_preview_label.add_theme_font_size_override("font_size", 17)
	_preview_label.add_theme_color_override("font_color", Color("e4f0dc"))
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reincarnate_box.add_child(_preview_label)

	_reincarnate_desc_label = Label.new()
	_reincarnate_desc_label.text = "※ 轉世入定將重塑肉身與洞府營造，保留最高境界、道心與天賦加成。生生不息，道證長存。"
	_reincarnate_desc_label.add_theme_font_override("font", UiTypography.body_font())
	_reincarnate_desc_label.add_theme_font_size_override("font_size", 15)
	_reincarnate_desc_label.add_theme_color_override("font_color", Color("a8c0b2"))
	_reincarnate_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reincarnate_box.add_child(_reincarnate_desc_label)

	_reincarnate_action_button = Button.new()
	_reincarnate_action_button.text = "入定轉世"
	_reincarnate_action_button.custom_minimum_size = Vector2(160, 48)
	_reincarnate_action_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_reincarnate_action_button.add_theme_font_size_override("font_size", 18)
	_reincarnate_action_button.pressed.connect(_on_reincarnate_action_pressed)
	_reincarnate_box.add_child(_reincarnate_action_button)

	# 分頁容器二：道心天賦
	_talents_box = VBoxContainer.new()
	_talents_box.name = "TalentsBox"
	_talents_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_talents_box.add_theme_constant_override("separation", 10)
	_talents_box.visible = false
	_content.add_child(_talents_box)

	# The outer body owns scrolling. A nested expanding ScrollContainer inside
	# its content has no allocated height and makes all talent rows invisible.
	_talents_list = VBoxContainer.new()
	_talents_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talents_list.add_theme_constant_override("separation", 10)
	_talents_box.add_child(_talents_list)

	_switch_tab("reincarnate")

func _switch_tab(tab_name: String) -> void:
	_active_tab = tab_name
	_reincarnate_box.visible = (_active_tab == "reincarnate")
	_talents_box.visible = (_active_tab == "talents")
	UiMaterial.mark_selected(_reincarnate_button, _active_tab == "reincarnate")
	UiMaterial.mark_selected(_talents_button, _active_tab == "talents")

	# 高亮當前標籤按鈕
	var active_color := UiMaterial.LIGHT_TEXT
	var inactive_color := UiMaterial.INK
	_reincarnate_button.add_theme_color_override("font_color", active_color if _active_tab == "reincarnate" else inactive_color)
	_talents_button.add_theme_color_override("font_color", active_color if _active_tab == "talents" else inactive_color)

func refresh(view: Dictionary) -> void:
	var dh: String = String(view.get("dao_heart", "0"))
	var dp: int = int(view.get("dao_proof", 0))
	_currency_label.text = "道心: %s  |  道證: %d" % [dh, dp]

	# 1. 刷新輪迴轉世分頁
	var preview: Dictionary = view.get("reincarnation_preview", {})
	var r_count: int = int(preview.get("current_reincarnation_count", 0))
	var highest_era: int = int(view.get("highest_era", 1))
	_cycle_label.text = "當前世次：第 %d 世   最高境界：%d 階" % [r_count + 1, highest_era]

	var eligible: bool = bool(preview.get("eligible", false))
	var reason: String = String(preview.get("reason", ""))
	if eligible:
		if reason == "lifespan_exhausted":
			_eligibility_label.text = "資格狀態：壽元已盡，天命難違，請速入定轉世！"
			_eligibility_label.add_theme_color_override("font_color", Color("e67e22"))
		elif reason == "rebirth_lotus":
			_eligibility_label.text = "資格狀態：已築造【往生蓮臺】，可於大期未至時提前遁入輪迴！"
			_eligibility_label.add_theme_color_override("font_color", Color("7de0a8"))
		else:
			_eligibility_label.text = "資格狀態：契機已至，道心澄澈，可轉世重修！"
			_eligibility_label.add_theme_color_override("font_color", Color("7de0a8"))
		_reincarnate_action_button.disabled = false
	else:
		_eligibility_label.text = "資格狀態：修為尚淺。需修築【往生蓮臺】或待壽元耗盡，方可遁入輪迴。"
		_eligibility_label.add_theme_color_override("font_color", Color("e6c280"))
		_reincarnate_action_button.disabled = true

	var b_sum: int = int(preview.get("building_sum", 0))
	var gain_dh: String = String(preview.get("dao_heart", "0"))
	var gain_dp: int = int(preview.get("dao_proof", 0))
	var floor_val: int = int(preview.get("era_floor", 0))

	# 起手傳承比例計算
	var talents: Dictionary = view.get("talents", {})
	var inher_lvl: int = int(talents.get("resource_inheritance", 0))
	var next_r: int = r_count + 1
	var inher_ratio := ReincarnationRules.inheritance_ratio(next_r, float(inher_lvl) * 0.1) * 100.0

	_preview_label.text = (
		"• 本世島上建築等階總和：%d\n" % b_sum
		+ "• 轉世預期獲得道心：+%s（含境界保底 %d）\n" % [gain_dh, floor_val]
		+ "• 轉世預期獲得道證：+%d\n" % gain_dp
		+ "• 資源傳承天賦：新開局庫容的 %.0f%%（無自動補給）" % inher_ratio
	)

	# 2. 刷新道心天賦分頁
	_refresh_talents(talents, dh)

func _refresh_talents(current_talents: Dictionary, current_dh_str: String) -> void:
	for talent_id in TalentSystem.TALENTS:
		var def: Dictionary = TalentSystem.TALENTS[talent_id]
		var cur_lvl: int = int(current_talents.get(talent_id, 0))
		var max_lvl: int = int(def["max_level"])

		var row: PanelContainer
		if _talent_rows.has(talent_id):
			row = _talent_rows[talent_id]
		else:
			row = _create_talent_row(talent_id, def)
			_talents_list.add_child(row)
			_talent_rows[talent_id] = row

		_update_talent_row(row, talent_id, def, cur_lvl, max_lvl, current_dh_str)

func _create_talent_row(talent_id: String, def: Dictionary) -> PanelContainer:
	var container := PanelContainer.new()
	var style := UiMaterial.card()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.name = "TalentName"
	name_label.add_theme_font_override("font", UiTypography.emphasis_font())
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("f4e7be"))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "TalentDesc"
	desc_label.text = String(def.get("description", ""))
	desc_label.add_theme_font_override("font", UiTypography.body_font())
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color("c0d6c8"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	var action_box := VBoxContainer.new()
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	action_box.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(action_box)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_override("font", UiTypography.body_font())
	cost_label.add_theme_font_size_override("font_size", 14)
	action_box.add_child(cost_label)

	var learn_btn := Button.new()
	learn_btn.name = "LearnButton"
	learn_btn.text = "參悟"
	learn_btn.custom_minimum_size = Vector2(90, 44)
	learn_btn.add_theme_font_override("font", UiTypography.body_font())
	learn_btn.add_theme_font_size_override("font_size", 15)
	learn_btn.pressed.connect(func(): learn_talent_requested.emit(talent_id))
	action_box.add_child(learn_btn)

	return container

func _update_talent_row(row: PanelContainer, _talent_id: String, def: Dictionary, cur_lvl: int, max_lvl: int, current_dh_str: String) -> void:
	var name_label: Label = row.find_child("TalentName", true, false)
	var cost_label: Label = row.find_child("CostLabel", true, false)
	var learn_btn: Button = row.find_child("LearnButton", true, false)

	name_label.text = "%s   [%d / %d 階]" % [String(def.get("name", "")), cur_lvl, max_lvl]

	if cur_lvl >= max_lvl:
		cost_label.text = "已圓滿"
		cost_label.add_theme_color_override("font_color", Color("7de0a8"))
		learn_btn.disabled = true
		learn_btn.text = "圓滿"
	else:
		var cost_amount: AmountCompat = TalentSystem.get_cost(_talent_id, cur_lvl)
		var cost_str := cost_amount.serialize()
		cost_label.text = "需道心: %s" % cost_str

		var parse_dh := AmountCompat.try_parse(current_dh_str)
		var has_enough := false
		if parse_dh.get("ok", false):
			var cur_dh: AmountCompat = parse_dh["value"]
			has_enough = (cur_dh.compare_to(cost_amount) >= 0)

		if has_enough:
			cost_label.add_theme_color_override("font_color", Color("f4e7be"))
			learn_btn.disabled = false
			learn_btn.text = "參悟"
		else:
			cost_label.add_theme_color_override("font_color", Color("e06666"))
			learn_btn.disabled = true
			learn_btn.text = "道心不足"

func _on_reincarnate_action_pressed() -> void:
	reincarnate_requested.emit("normal")

func _on_close_pressed() -> void:
	visible = false
	close_requested.emit()
