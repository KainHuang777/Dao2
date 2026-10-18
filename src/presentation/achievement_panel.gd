class_name AchievementPanel
extends Control
## View-only achievement album. Claims remain owned by GameSession.
signal claim_requested(achievement_id: String)
signal close_requested()
signal save_retry_requested()

const BADGE_DIR := "res://assets/ui/achievements-painted/"
var _background: Panel
var _content: VBoxContainer
var _title_row: HBoxContainer
var _title_label: Label
var _close_button: Button
var _summary_label: Label
var _status_label: Label
var _scroll: ScrollContainer
var _filters_scroll: ScrollContainer
var _filters: SegmentChips
var _achievements_list: GridContainer
var _achievement_items: Dictionary = {}
var _category_ids: Array[String] = [""]
var _category := ""
var _retry_button: Button
var _feedback_row: HBoxContainer
var _margin: MarginContainer

func _ready() -> void:
	_build_ui()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _achievements_list != null:
		_background.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if size.y < 350 else UiMaterial.scroll_shell())
		UiMaterial.apply_scroll_content_margins(_margin, size.y < 350)
		_achievements_list.columns = 2 if size.x >= 1000 else 1
		_title_row.visible = size.y >= 350
		_summary_label.visible = size.y >= 350
		_filters_scroll.custom_minimum_size.y = 44 if size.y < 350 else 52
		_content.add_theme_constant_override("separation", 4 if size.y < 350 else 10)
		_fit_badges.call_deferred()

func _fit_badges() -> void:
	var edge := 128
	if size.y < 350:
		edge = clampi(int(_scroll.size.y) - 8, 44, 112)
	for card in _achievement_items.values():
		card.get_node("HBox/Badge").custom_minimum_size = Vector2.ONE * edge

func _label(node_name: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	return label

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiMaterial.scroll_shell())
	add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_margin = margin
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiMaterial.apply_scroll_content_margins(margin)
	_content = VBoxContainer.new()
	_content.name = "AchievementContent"
	margin.add_child(_content)
	_title_row = HBoxContainer.new()
	_content.add_child(_title_row)
	_title_label = _label("Title", 24)
	_title_label.text = "功業冊 · 累世道業"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_title_row.add_child(_title_label)
	_close_button = CloseSeal.new()
	_close_button.tooltip_text = "返回洞府"
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)
	_summary_label = _label("SummaryLabel")
	_content.add_child(_summary_label)
	_status_label = _label("StatusLabel")
	_status_label.visible = false
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback_row = HBoxContainer.new()
	_feedback_row.visible = false
	_feedback_row.add_theme_constant_override("separation", 8)
	_content.add_child(_feedback_row)
	_feedback_row.add_child(_status_label)
	_retry_button = Button.new()
	_retry_button.text = "重試保存"
	_retry_button.custom_minimum_size.y = 44
	_retry_button.visible = false
	UiMaterial.apply_button(_retry_button)
	_retry_button.pressed.connect(func(): save_retry_requested.emit())
	_feedback_row.add_child(_retry_button)
	_filters_scroll = ScrollContainer.new()
	_filters_scroll.resized.connect(func(): _keep_selected_filter_visible.call_deferred())
	_filters_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_filters_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_filters_scroll.custom_minimum_size.y = 52
	_content.add_child(_filters_scroll)
	_filters = SegmentChips.new()
	var labels := PackedStringArray(["全部"])
	for id in AchievementSystem.CATEGORIES:
		_category_ids.append(id)
		labels.append(AchievementSystem.CATEGORIES[id])
	_filters.set_segments(labels)
	var representatives := ["", "era_qi", "build_first_hut", "craft_first_pill", "join_first_sect", "bond_beast", "first_reincarnate"]
	for i in range(1, representatives.size()):
		var path: String = BADGE_DIR + representatives[i] + ".png"
		if ResourceLoader.exists(path):
			_filters._buttons[i].icon = load(path)
			_filters._buttons[i].expand_icon = false
			_filters._buttons[i].add_theme_constant_override("icon_max_width", 24)
	_filters.segment_selected.connect(_on_category_selected)
	_filters_scroll.add_child(_filters)
	_scroll = ScrollContainer.new()
	_scroll.name = "AchievementScroll"
	_scroll.resized.connect(_fit_badges)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_scroll)
	_achievements_list = GridContainer.new()
	_achievements_list.name = "AchievementsList"
	_achievements_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_achievements_list.add_theme_constant_override("h_separation", 10)
	_achievements_list.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_achievements_list)

func show_status_message(msg: String) -> void:
	_status_label.text = msg
	_status_label.visible = not msg.is_empty()
	_feedback_row.visible = _status_label.visible or _retry_button.visible
	_fit_badges.call_deferred()

func set_save_result(result: Dictionary) -> void:
	_retry_button.visible = not bool(result.get("ok", false))
	show_status_message("領取結果已保存。" if not _retry_button.visible else "領取已生效；保存失敗（%s），請保留畫面並重試保存。" % result.get("error", "未知"))

func storage_recovered() -> void:
	if _retry_button.visible:
		set_save_result({"ok": true})

func update_view(view: Dictionary) -> void:
	var nested: Variant = view.get("achievements")
	refresh_achievements(nested if nested is Dictionary else view)

func refresh_achievements(view_data: Dictionary) -> void:
	_summary_label.text = "功業 %d / %d　·　待領 %d　·　已領 %d" % [view_data.get("unlocked_count", 0), view_data.get("total_count", 0), view_data.get("unclaimed_count", 0), view_data.get("claimed_count", 0)]
	var present := {}
	for ach in view_data.get("achievements", []):
		var id := String(ach.id)
		present[id] = true
		if not _achievement_items.has(id):
			var card := _create_achievement_card(ach)
			_achievement_items[id] = card
			_achievements_list.add_child(card)
		_update_card(_achievement_items[id], ach)
	for id in _achievement_items.keys():
		if not present.has(id):
			var removed: Control = _achievement_items[id]
			_achievements_list.remove_child(removed)
			removed.queue_free()
			_achievement_items.erase(id)
	_apply_filter()

func _on_category_selected(index: int) -> void:
	_category = _category_ids[index]
	_filters_scroll.ensure_control_visible(_filters._buttons[index])
	_scroll.scroll_vertical = 0
	_apply_filter()

func _keep_selected_filter_visible() -> void:
	var index := _category_ids.find(_category)
	if index >= 0:
		_filters_scroll.ensure_control_visible(_filters._buttons[index])

func _apply_filter() -> void:
	for card in _achievement_items.values():
		card.visible = _category.is_empty() or card.get_meta("category") == _category

func _create_achievement_card(ach: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_" + String(ach.id)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
	card.set_meta("category", String(ach.get("category", "")))
	var box := HBoxContainer.new()
	box.name = "HBox"
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var badge := TextureRect.new()
	badge.name = "Badge"
	badge.custom_minimum_size = Vector2.ONE * (112 if size.y < 350 else 128)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := BADGE_DIR + String(ach.id) + ".png"
	if ResourceLoader.exists(path):
		badge.texture = load(path)
	box.add_child(badge)
	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(info)
	for role in ["Title", "Reward"]:
		var label := _label(role, 18 if role == "Title" else 16)
		if role == "Title": label.add_theme_font_override("font", UiTypography.emphasis_font())
		info.add_child(label)
	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(100, 44)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.add_theme_font_override("font", UiTypography.body_font())
	action.add_theme_font_size_override("font_size", 16)
	UiMaterial.apply_button(action)
	action.pressed.connect(_on_card_action.bind(String(ach.id)))
	box.add_child(action)
	return card

func _update_card(card: PanelContainer, ach: Dictionary) -> void:
	card.get_node("HBox/Info/Title").text = String(ach.name)
	card.get_node("HBox/Info/Reward").text = "獎勵 · " + String(ach.rewards_desc)
	var action: Button = card.get_node("HBox/Action")
	var claimed := bool(ach.get("claimed", false))
	var ready := bool(ach.get("can_claim", false))
	action.text = "已領取" if claimed else ("領取獎勵" if ready else "未達成")
	action.disabled = not ready or claimed
	card.get_node("HBox/Badge").modulate = Color.WHITE if ready or claimed else Color(0.58, 0.63, 0.60)

func _on_card_action(ach_id: String) -> void:
	claim_requested.emit(ach_id)
