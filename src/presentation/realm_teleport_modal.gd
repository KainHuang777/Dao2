class_name RealmTeleportModal
extends Control

signal switch_realm_requested(target_realm: String)
signal upgrade_outpost_requested(outpost_id: String)
signal close_requested()

var _background: Panel
var _scroll: ScrollContainer
var _container: VBoxContainer
var _title_label: Label
var _status_summary: Label
var _teleport_button: Button
var _res_summary_label: Label
var _outpost_cards_box: VBoxContainer
var _target_realm_for_button: String = "realm_spirit"

func _ready() -> void:
	if _container == null:
		_build_ui()

func _build_ui() -> void:
	if _container != null:
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 10)
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_container)

	# 標題與關閉列
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	_container.add_child(header_row)

	_title_label = Label.new()
	_title_label.text = "跨界神遊 · 靈界天靈洞天"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color("ffd700"))
	header_row.add_child(_title_label)

	var close_btn := Button.new()
	close_btn.text = "關閉"
	close_btn.custom_minimum_size = Vector2(64, 36)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(func():
		visible = false
		close_requested.emit()
	)
	header_row.add_child(close_btn)

	# 狀態與法則說明
	_status_summary = Label.new()
	_status_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_summary.add_theme_font_override("font", UiTypography.body_font())
	_status_summary.add_theme_font_size_override("font_size", 14)
	_status_summary.add_theme_color_override("font_color", Color("d0e6df"))
	_container.add_child(_status_summary)

	# 傳送/切換按鈕
	_teleport_button = Button.new()
	_teleport_button.custom_minimum_size = Vector2(0, 48)
	_teleport_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_teleport_button.add_theme_font_size_override("font_size", 18)
	_teleport_button.pressed.connect(func():
		_on_teleport_pressed(_target_realm_for_button)
	)
	_container.add_child(_teleport_button)

	# 分隔線
	_container.add_child(HSeparator.new())

	# 靈界專屬資源讀數
	_res_summary_label = Label.new()
	_res_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_res_summary_label.add_theme_font_override("font", UiTypography.body_font())
	_res_summary_label.add_theme_font_size_override("font_size", 15)
	_res_summary_label.add_theme_color_override("font_color", Color("fff1c7"))
	_container.add_child(_res_summary_label)

	# 據點設施標題
	var outposts_title := Label.new()
	outposts_title.text = "【靈界三大活躍據點】"
	outposts_title.add_theme_font_override("font", UiTypography.emphasis_font())
	outposts_title.add_theme_font_size_override("font_size", 16)
	outposts_title.add_theme_color_override("font_color", Color("a8e6cf"))
	_container.add_child(outposts_title)

	# 據點清單容器
	_outpost_cards_box = VBoxContainer.new()
	_outpost_cards_box.add_theme_constant_override("separation", 8)
	_container.add_child(_outpost_cards_box)

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _scroll != null:
		_scroll.position = Vector2(16, 16)
		_scroll.size = Vector2(maxf(0.0, size.x - 32.0), maxf(0.0, size.y - 32.0))

func refresh(view: Dictionary) -> void:
	if _container == null:
		_build_ui()
	var realm_data: Dictionary = view.get("realm", {})
	var current_realm: String = String(realm_data.get("current_realm", "realm_human"))
	var is_spirit := (current_realm == "realm_spirit")

	if is_spirit:
		_status_summary.text = "【當前所在：靈界 · 天靈洞天】\n天地靈機充沛，九幽靈脈交匯。兩界並行運轉，切景不中斷收益。"
		_teleport_button.text = "➤ 返回祖基仙府（人界）"
		_target_realm_for_button = "realm_human"
	else:
		_status_summary.text = "【當前所在：人界 · 祖基洞府】\n法則：靈潮汐動 · 純靈轉化。天樞陣眼運轉耗費靈石轉化極品靈晶，化靈仙池凝練仙液反哺修煉！"
		_teleport_button.text = "➤ 跨界神遊 · 踏入天靈洞天（靈界）"
		_target_realm_for_button = "realm_spirit"

	var cur_crystal := float(realm_data.get("spirit_crystal", 0.0))
	var cur_nectar := float(realm_data.get("azure_nectar", 0.0))
	var crystal_cap := float(realm_data.get("crystal_cap", 100.0))
	var nectar_cap := float(realm_data.get("nectar_cap", 50.0))
	var feedback_boost := float(realm_data.get("cultivation_feedback_boost", 0.0)) * 100.0

	_res_summary_label.text = "極品靈晶：%.1f/%.0f  |  天青靈液：%.1f/%.0f\n跨界修煉反哺加成：+%.0f%%" % [
		cur_crystal, crystal_cap, cur_nectar, nectar_cap, feedback_boost
	]

	# 渲染三大據點
	_rebuild_outposts(realm_data.get("outposts", []))

func _on_teleport_pressed(target: String) -> void:
	switch_realm_requested.emit(target)

func _rebuild_outposts(outposts: Array) -> void:
	for child in _outpost_cards_box.get_children():
		child.queue_free()

	for op in outposts:
		var card := _create_outpost_card(op)
		_outpost_cards_box.add_child(card)

func _create_outpost_card(op: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.09, 0.85)
	style.border_color = Color("4fe3c1")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var op_name := Label.new()
	op_name.text = "%s (%d/%d 階)" % [op.get("name", ""), op.get("level", 0), op.get("max_level", 10)]
	op_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	op_name.add_theme_font_override("font", UiTypography.emphasis_font())
	op_name.add_theme_font_size_override("font_size", 15)
	op_name.add_theme_color_override("font_color", Color("ffd599"))
	title_row.add_child(op_name)

	var upg_btn := Button.new()
	var can_upg: bool = bool(op.get("can_upgrade", false))
	var cur_lvl: int = int(op.get("level", 0))
	var max_lvl: int = int(op.get("max_level", 10))
	if cur_lvl >= max_lvl:
		upg_btn.text = "已滿階"
		upg_btn.disabled = true
	elif can_upg:
		upg_btn.text = "晉升據點"
		upg_btn.disabled = false
	else:
		upg_btn.text = "材料不足"
		upg_btn.disabled = true
	upg_btn.custom_minimum_size = Vector2(88, 36)
	upg_btn.add_theme_font_size_override("font_size", 14)
	var op_id: String = String(op.get("id", ""))
	upg_btn.pressed.connect(func(): upgrade_outpost_requested.emit(op_id))
	title_row.add_child(upg_btn)

	var desc_label := Label.new()
	desc_label.text = String(op.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_override("font", UiTypography.body_font())
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color("b8d7ca"))
	vbox.add_child(desc_label)

	# 升級花費
	var costs: Dictionary = op.get("costs", {})
	if not costs.is_empty() and cur_lvl < max_lvl:
		var cost_strs := []
		for res_k in costs:
			var c_val: float = float(costs[res_k])
			var res_name: String = res_k
			if res_k == "spirit_crystal": res_name = "極品靈晶"
			elif res_k == "azure_nectar": res_name = "天青靈液"
			elif res_k == "stone_low": res_name = "下品靈石"
			elif res_k == "black_copper": res_name = "玄銅"
			elif res_k == "lingli": res_name = "靈氣"
			elif res_k == "money": res_name = "金錢"
			cost_strs.append("%s: %.1f" % [res_name, c_val])
		var cost_label := Label.new()
		cost_label.text = "晉升消耗：" + "，".join(cost_strs)
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color("e4c88a"))
		vbox.add_child(cost_label)

	return panel
