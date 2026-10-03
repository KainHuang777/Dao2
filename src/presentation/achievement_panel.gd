class_name AchievementPanel
extends Control

signal claim_requested(achievement_id: String)
signal close_requested()

var _background: Panel
var _content: VBoxContainer
var _title_row: HBoxContainer
var _title_label: Label
var _close_button: Button

var _summary_panel: PanelContainer
var _summary_label: Label
var _status_label: Label

var _scroll: ScrollContainer
var _achievements_list: VBoxContainer
var _achievement_items: Dictionary = {}

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _scroll != null:
		var pad := 16.0
		_scroll.position = Vector2(pad, pad)
		_scroll.size = Vector2(maxf(0.0, size.x - pad * 2.0), maxf(0.0, size.y - pad * 2.0))

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_content = VBoxContainer.new()
	_content.name = "AchievementContent"
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	# 頂部標題列
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_title_row)

	_title_label = Label.new()
	_title_label.text = "仙道成就 · 功業圖鑑"
	_title_label.add_theme_font_override("font", UiTypography.chapter_font())
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color("a99768"))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "返回"
	_close_button.custom_minimum_size = Vector2(72, 36)
	_close_button.add_theme_font_size_override("font_size", 14)
	UiMaterial.apply_button(_close_button)
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)

	# 摘要面板
	_summary_panel = PanelContainer.new()
	_summary_panel.add_theme_stylebox_override("panel", UiMaterial.surface("card"))
	_content.add_child(_summary_panel)

	var sum_box := VBoxContainer.new()
	sum_box.add_theme_constant_override("separation", 4)
	_summary_panel.add_child(sum_box)

	_summary_label = Label.new()
	_summary_label.name = "SummaryLabel"
	_summary_label.text = "成就載入中..."
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_font_size_override("font_size", 15)
	_summary_label.add_theme_color_override("font_color", UiMaterial.INK)
	sum_box.add_child(_summary_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("5fb588"))
	sum_box.add_child(_status_label)

	# 列表容器
	_achievements_list = VBoxContainer.new()
	_achievements_list.name = "AchievementsList"
	_achievements_list.add_theme_constant_override("separation", 10)
	_achievements_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_achievements_list)

func show_status_message(msg: String) -> void:
	if _status_label != null:
		_status_label.text = msg
		_status_label.visible = true

func update_view(view: Dictionary) -> void:
	var ach_data: Dictionary = view.get("achievements", view)
	refresh_achievements(ach_data)

func refresh_achievements(view_data: Dictionary) -> void:
	var total := int(view_data.get("total_count", 0))
	var unlocked := int(view_data.get("unlocked_count", 0))
	var claimed := int(view_data.get("claimed_count", 0))
	var unclaimed := int(view_data.get("unclaimed_count", 0))
	var percent := float(view_data.get("completion_percent", 0.0))

	if _summary_label != null:
		var unclaimed_hint := (" ｜ 待領取獎勵：%d" % unclaimed) if unclaimed > 0 else ""
		_summary_label.text = "功業達成：%d / %d（%.1f%%） ｜ 已領獎勵：%d%s\n成就乃修士累世道業，六道輪迴亦不泯滅。" % [
			unlocked, total, percent, claimed, unclaimed_hint
		]

	var achievements: Array = view_data.get("achievements", [])
	_sync_achievement_items(achievements)

func _sync_achievement_items(achievements: Array) -> void:
	for ach in achievements:
		var ach_id: String = String(ach.id)
		var card: PanelContainer
		if _achievement_items.has(ach_id):
			card = _achievement_items[ach_id]
		else:
			card = _create_achievement_card(ach)
			_achievement_items[ach_id] = card
			_achievements_list.add_child(card)

		_update_card(card, ach)

func _create_achievement_card(ach: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_" + String(ach.id)
	card.add_theme_stylebox_override("panel", UiMaterial.surface("card"))

	var box := HBoxContainer.new()
	box.name = "HBox"
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	var info_box := VBoxContainer.new()
	info_box.name = "Info"
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(info_box)

	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
	title_lbl.add_theme_font_size_override("font_size", 16)
	info_box.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.name = "Desc"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", UiMaterial.INK)
	info_box.add_child(desc_lbl)

	var reward_lbl := Label.new()
	reward_lbl.name = "Reward"
	reward_lbl.add_theme_font_size_override("font_size", 13)
	reward_lbl.add_theme_color_override("font_color", Color("a99768"))
	info_box.add_child(reward_lbl)

	var action_btn := Button.new()
	action_btn.name = "Action"
	action_btn.custom_minimum_size = Vector2(96, 44)
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiMaterial.apply_button(action_btn)
	box.add_child(action_btn)

	return card

func _update_card(card: PanelContainer, ach: Dictionary) -> void:
	var info_box: VBoxContainer = card.get_node("HBox/Info")
	var title_lbl: Label = info_box.get_node("Title")
	var desc_lbl: Label = info_box.get_node("Desc")
	var reward_lbl: Label = info_box.get_node("Reward")
	var action_btn: Button = card.get_node("HBox/Action")

	var is_unlocked: bool = bool(ach.get("unlocked", false))
	var is_claimed: bool = bool(ach.get("claimed", false))
	var can_claim: bool = bool(ach.get("can_claim", false))

	var cat_name: String = String(ach.get("category_name", "仙道"))
	title_lbl.text = "【%s】%s" % [cat_name, String(ach.name)]
	desc_lbl.text = String(ach.desc)
	reward_lbl.text = "功業獎勵：%s" % String(ach.rewards_desc)

	if is_claimed:
		title_lbl.add_theme_color_override("font_color", UiMaterial.INK)
		action_btn.text = "已領取"
		action_btn.disabled = true
	elif can_claim:
		title_lbl.add_theme_color_override("font_color", Color("ffd599"))
		action_btn.text = "領取獎勵"
		action_btn.disabled = false
	else:
		title_lbl.add_theme_color_override("font_color", Color("8a9e96"))
		action_btn.text = "未達成"
		action_btn.disabled = true

	if not action_btn.pressed.is_connected(_on_card_action.bind(String(ach.id))):
		action_btn.pressed.connect(_on_card_action.bind(String(ach.id)))

func _on_card_action(ach_id: String) -> void:
	claim_requested.emit(ach_id)
