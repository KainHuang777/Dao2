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
const ART_DIR := "res://assets/ui/reincarnation-painted/"
var _root_box: VBoxContainer
var _hero: TextureRect
var _footer: HBoxContainer
var _cancel_button: Button
var _confirm_label: Label
var _feedback: Label
var _feedback_row: HBoxContainer
var _retry_button: Button
var _confirming := false
var _pending_save := false
var _life_title: Label
var _life_card: PanelContainer
var _details_button: Button
var _reward_heart: Label
var _reward_proof: Label
var _exhausted := false
var _reward_cards: HBoxContainer
var _compact_rewards: Label
var _life_info: VBoxContainer
var _last_view: Dictionary = {}
var _margin: MarginContainer
signal retry_save_requested()

func _ready() -> void:
	_build_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _cancel_button != null:
		_cancel_confirmation()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _body_scroll != null:
		var compact := bounds.size.y < 350
		_background.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if compact else UiMaterial.scroll_shell())
		UiMaterial.apply_scroll_content_margins(_margin, compact)
		_hero.visible = true
		_hero.custom_minimum_size = Vector2.ONE * (56 if compact else 300)
		_preview_label.visible = not compact
		var details_parent: Node = _reincarnate_box if compact else _life_info
		if _details_button.get_parent() != details_parent:
			_details_button.reparent(details_parent)
		_life_info.add_theme_constant_override("separation", 0 if compact else 4)
		_cycle_label.visible = not compact
		_life_title.add_theme_font_size_override("font_size", 22 if compact else 28)
		_eligibility_label.visible = not compact
		_reward_cards.visible = not compact
		_compact_rewards.visible = compact
		_title_row.visible = not compact
		_root_box.add_theme_constant_override("separation", 4 if compact else 10)
		for row in _talent_rows.values():
			_update_talent_description(row)
		_fit_talents.call_deferred()
		if not _last_view.is_empty(): refresh(_last_view)

func _fit_talents() -> void:
	var edge := 112 if size.y >= 350 else clampi(int(_body_scroll.size.y) - 16, 44, 80)
	for row in _talent_rows.values():
		row.find_child("TalentArt", true, false).custom_minimum_size = Vector2.ONE * edge

func _update_talent_description(row: PanelContainer) -> void:
	if not row.has_meta("talent_id"): return
	var id: String = row.get_meta("talent_id")
	var level: int = row.get_meta("level", 0)
	var label: Label = row.find_child("TalentDesc", true, false)
	var definition: Dictionary = TalentSystem.TALENTS[id]
	if size.y >= 350:
		label.text = "%s\n目前加成：%d%%" % [definition.description, level * 10]
	else:
		var effects := {"resource_inheritance":"轉世開局資源 +%d%% 庫容\n下次轉世生效", "lifespan_extension":"壽元上限 +%d%%", "innate_dao_body":"修行積累速度 +%d%%"}
		label.text = effects[id] % (level * 10)
	label.tooltip_text = definition.description

func _label(text_value: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	return label

func _art(id: String, edge: int) -> TextureRect:
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2.ONE * edge
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(ART_DIR + id + ".png"):
		image.texture = load(ART_DIR + id + ".png")
	return image

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
	_root_box = VBoxContainer.new()
	margin.add_child(_root_box)
	_title_row = HBoxContainer.new()
	_root_box.add_child(_title_row)
	var title := _label("輪迴 · 累世傳承", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(title)
	_close_button = CloseSeal.new()
	_close_button.pressed.connect(_on_close_pressed)
	_title_row.add_child(_close_button)
	_currency_label = _label("道心: 0  |  道證: 0", 17)
	_tab_row = HBoxContainer.new()
	_root_box.add_child(_tab_row)
	_reincarnate_button = GameTab.new()
	_reincarnate_button.text = "轉世輪迴"
	_reincarnate_button.pressed.connect(func(): _switch_tab("reincarnate"))
	_tab_row.add_child(_reincarnate_button)
	_talents_button = GameTab.new()
	_talents_button.text = "道心天賦"
	_talents_button.pressed.connect(func(): _switch_tab("talents"))
	_tab_row.add_child(_talents_button)
	_currency_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tab_row.add_child(_currency_label)
	_body_scroll = ScrollContainer.new()
	_body_scroll.resized.connect(_fit_talents)
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_box.add_child(_body_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_body_scroll.add_child(_content)
	_reincarnate_box = VBoxContainer.new()
	_reincarnate_box.add_theme_constant_override("separation", 10)
	_content.add_child(_reincarnate_box)
	_life_card = PanelContainer.new()
	_reincarnate_box.add_child(_life_card)
	var overview := HBoxContainer.new()
	_life_card.add_child(overview)
	_hero = preload("res://src/presentation/reincarnation_mandala.gd").new()
	_hero.texture = load(ART_DIR + "reincarnation_wheel.png")
	_hero.custom_minimum_size = Vector2.ONE * 300
	_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	overview.add_child(_hero)
	var life := VBoxContainer.new()
	_life_info = life
	life.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	life.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	overview.add_child(life)
	_cycle_label = _label("", 18)
	life.add_child(_cycle_label)
	_life_title = _label("再續仙途", 28)
	_life_title.add_theme_font_override("font", UiTypography.emphasis_font())
	life.add_child(_life_title)
	_eligibility_label = _label("")
	life.add_child(_eligibility_label)
	_compact_rewards = _label("", 16)
	_compact_rewards.visible = false
	life.add_child(_compact_rewards)
	var rewards := HBoxContainer.new()
	_reward_cards = rewards
	life.add_child(rewards)
	for id in ["heart", "proof"]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
		rewards.add_child(card)
		var label := _label("", 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
		if id == "heart": _reward_heart = label
		else: _reward_proof = label
	_preview_label = _label("")
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	life.add_child(_preview_label)
	_details_button = Button.new()
	_details_button.text = "傳承與重置詳情"
	_details_button.custom_minimum_size.y = 44
	_details_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiMaterial.apply_button(_details_button)
	_details_button.pressed.connect(func(): _reincarnate_desc_label.visible = not _reincarnate_desc_label.visible)
	life.add_child(_details_button)
	_reincarnate_desc_label = _label("保留 · 最高境界、道心、道證、天賦與已記錄功業；靈界據點、靈晶與靈液獨立跨世保留，不受資源傳承天賦影響。\n重置 · 境界／修行、年歲、人界建築、技能、丹藥與當世產業；資源依傳承天賦重新起算。宗門需重新加入；靈獸重置，成熟靈獸化為獸魂。")
	_reincarnate_box.add_child(_reincarnate_desc_label)
	_reincarnate_desc_label.hide()
	_talents_box = VBoxContainer.new()
	_content.add_child(_talents_box)
	_talents_list = VBoxContainer.new()
	_talents_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talents_list.add_theme_constant_override("separation", 10)
	_talents_box.add_child(_talents_list)
	_feedback_row = HBoxContainer.new()
	_feedback_row.visible = false
	_root_box.add_child(_feedback_row)
	_feedback = _label("")
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback.visible = false
	_feedback_row.add_child(_feedback)
	_retry_button = Button.new()
	_retry_button.text = "重試保存"
	_retry_button.custom_minimum_size.y = 44
	UiMaterial.apply_button(_retry_button)
	_retry_button.visible = false
	_retry_button.pressed.connect(func(): retry_save_requested.emit())
	_feedback_row.add_child(_retry_button)
	_footer = HBoxContainer.new()
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_root_box.add_child(_footer)
	_confirm_label = _label("將重置本世進度，請確認。")
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.visible = false
	_reincarnate_box.add_child(_confirm_label)
	_cancel_button = Button.new()
	_cancel_button.text = "取消"
	_cancel_button.custom_minimum_size = Vector2(64,44)
	UiMaterial.apply_button(_cancel_button)
	_cancel_button.pressed.connect(_cancel_confirmation)
	_cancel_button.visible = false
	_footer.add_child(_cancel_button)
	_reincarnate_action_button = Button.new()
	_reincarnate_action_button.text = "入定轉世"
	_reincarnate_action_button.custom_minimum_size = Vector2(128,44)
	UiMaterial.apply_button(_reincarnate_action_button)
	_reincarnate_action_button.pressed.connect(_on_reincarnate_action_pressed)
	_footer.add_child(_reincarnate_action_button)
	_switch_tab("reincarnate")

func _cancel_confirmation() -> void:
	if _confirming:
		_reincarnate_desc_label.hide()
		_body_scroll.scroll_vertical = 0
	_confirming = false
	_cancel_button.hide()
	_confirm_label.hide()
	_reincarnate_action_button.text = "入定轉世"

func _switch_tab(tab_name: String) -> void:
	_cancel_confirmation()
	_active_tab = tab_name
	if not _pending_save and tab_name == "reincarnate": _feedback_row.hide()
	_reincarnate_box.visible = tab_name == "reincarnate"
	_talents_box.visible = tab_name == "talents"
	_footer.visible = tab_name == "reincarnate"
	_reincarnate_button.set_pressed_no_signal(tab_name == "reincarnate")
	_talents_button.set_pressed_no_signal(tab_name == "talents")
	UiMaterial.mark_paper_tab(_reincarnate_button, tab_name == "reincarnate")
	UiMaterial.mark_paper_tab(_talents_button, tab_name == "talents")
	_body_scroll.scroll_vertical = 0

func set_save_result(result: Dictionary) -> void:
	_pending_save = not bool(result.get("ok", false))
	_feedback.text = "操作已生效；保存失敗，請保留畫面並重試保存。" if _pending_save else "操作結果已保存。"
	_feedback.show()
	_feedback_row.show()
	_retry_button.visible = _pending_save
	if not _pending_save and _active_tab == "reincarnate" and size.y < 350:
		_feedback_row.hide()

func storage_recovered() -> void:
	if _pending_save:
		set_save_result({"ok":true})

func refresh(view: Dictionary) -> void:
	_last_view = view
	var dh: String = String(view.get("dao_heart", "0"))
	var dp: int = int(view.get("dao_proof", 0))
	_currency_label.text = "道心: %s  |  道證: %d" % [_format_amount_str(dh), dp]

	# 1. 刷新輪迴轉世分頁
	var preview: Dictionary = view.get("reincarnation_preview", {})
	var r_count: int = int(preview.get("current_reincarnation_count", 0))
	var highest_era: int = int(view.get("highest_era", 1))
	_cycle_label.text = "第 %d 世  ·  最高 %d 階" % [r_count + 1, highest_era]

	var eligible: bool = bool(preview.get("eligible", false))
	var reason: String = String(preview.get("reason", ""))
	_exhausted = reason == "lifespan_exhausted"
	_life_title.text = "命燈已熄" if _exhausted else "再續仙途"
	if size.y < 350 and not _exhausted:
		_life_title.text = "可轉世重修" if eligible else "輪迴尚未開啟"
	_life_title.add_theme_color_override("font_color", Color("9b3e30") if _exhausted else UiMaterial.INK)
	_hero.texture = load(ART_DIR + ("life_lamp_spent.png" if _exhausted else "reincarnation_wheel.png"))
	var life_style := StyleBoxFlat.new()
	life_style.bg_color = Color("e5d7ca") if _exhausted else Color("e9e4cf")
	life_style.border_color = Color("9b685b") if _exhausted else Color("8a987d")
	life_style.set_border_width_all(1)
	life_style.set_corner_radius_all(12)
	for side in ["left", "right", "top", "bottom"]:
		life_style.set("content_margin_" + side, 4.0 if size.y < 350 else 8.0)
	_life_card.add_theme_stylebox_override("panel", life_style)
	if eligible:
		if reason == "lifespan_exhausted":
			_eligibility_label.text = "壽元已盡 · 修行停滯" if size.y < 350 else "壽元已盡 · 修行停滯\n攜此世道果，重入輪迴。"
			_eligibility_label.add_theme_color_override("font_color", Color("9b3e30"))
		elif reason == "rebirth_lotus":
			_eligibility_label.text = "往生蓮臺已成 · 可提前轉世"
			_eligibility_label.add_theme_color_override("font_color", Color("29604c"))
		else:
			_eligibility_label.text = "契機已至 · 可轉世重修"
			_eligibility_label.add_theme_color_override("font_color", Color("29604c"))
		_reincarnate_action_button.disabled = false
	else:
		_eligibility_label.text = "修築往生蓮臺，或壽盡後開啟。"
		_eligibility_label.add_theme_color_override("font_color", Color("77572d"))
		_reincarnate_action_button.disabled = true
		_cancel_confirmation()

	var b_sum: int = int(preview.get("building_sum", 0))
	var gain_dh: String = String(preview.get("dao_heart", "0"))
	var gain_dp: int = int(preview.get("dao_proof", 0))
	var floor_val: int = int(preview.get("era_floor", 0))

	# 起手傳承比例計算
	var talents: Dictionary = view.get("talents", {})
	var inher_lvl: int = int(talents.get("resource_inheritance", 0))
	var next_r: int = r_count + 1
	var inher_ratio := ReincarnationRules.inheritance_ratio(next_r, float(inher_lvl) * 0.1) * 100.0

	_reward_heart.text = "道心  +%s" % _format_amount_str(gain_dh)
	_reward_proof.text = "道證  +%d" % gain_dp
	_compact_rewards.text = "道心 +%s    道證 +%d" % [_format_amount_str(gain_dh), gain_dp]
	_reward_heart.tooltip_text = "預期道心；建築等階總和 %d，境界保底 %d。" % [b_sum, floor_val]
	_reward_proof.tooltip_text = "本次轉世預期獲得的道證。"
	_preview_label.text = "資源傳承 %.0f%% · 道心與天賦長存" % inher_ratio
	_preview_label.tooltip_text = "資源按新開局庫容的 %.0f%% 起算，無自動補給。" % inher_ratio

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
	container.set_meta("talent_id", talent_id)
	var style := UiMaterial.surface("paper").duplicate()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var image := _art(talent_id, 80 if size.y < 350 else 112)
	image.name = "TalentArt"
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(image)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.name = "TalentName"
	name_label.add_theme_font_override("font", UiTypography.emphasis_font())
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", UiMaterial.INK)
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "TalentDesc"
	desc_label.text = String(def.get("description", ""))
	desc_label.add_theme_font_override("font", UiTypography.body_font())
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", UiMaterial.INK)
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
	cost_label.add_theme_font_size_override("font_size", 16)
	action_box.add_child(cost_label)

	var learn_btn := Button.new()
	learn_btn.name = "LearnButton"
	learn_btn.text = "參悟"
	learn_btn.custom_minimum_size = Vector2(90, 44)
	learn_btn.add_theme_font_override("font", UiTypography.body_font())
	learn_btn.add_theme_font_size_override("font_size", 16)
	UiMaterial.apply_button(learn_btn)
	learn_btn.pressed.connect(func(): learn_talent_requested.emit(talent_id))
	action_box.add_child(learn_btn)

	return container

func _update_talent_row(row: PanelContainer, _talent_id: String, def: Dictionary, cur_lvl: int, max_lvl: int, current_dh_str: String) -> void:
	var name_label: Label = row.find_child("TalentName", true, false)
	var cost_label: Label = row.find_child("CostLabel", true, false)
	var learn_btn: Button = row.find_child("LearnButton", true, false)

	name_label.text = "%s   [%d / %d 階]" % [String(def.get("name", "")), cur_lvl, max_lvl]
	row.set_meta("level", cur_lvl)
	_update_talent_description(row)

	if cur_lvl >= max_lvl:
		cost_label.text = "已圓滿"
		cost_label.add_theme_color_override("font_color", Color("29604c"))
		learn_btn.disabled = true
		learn_btn.text = "圓滿"
	else:
		var cost_amount: AmountCompat = TalentSystem.get_cost(_talent_id, cur_lvl)
		var cost_str := cost_amount.serialize()
		cost_label.text = "需道心: %s" % _format_amount_str(cost_str)

		var parse_dh := AmountCompat.try_parse(current_dh_str)
		var has_enough := false
		if parse_dh.get("ok", false):
			var cur_dh: AmountCompat = parse_dh["value"]
			has_enough = (cur_dh.compare_to(cost_amount) >= 0)

		if has_enough:
			cost_label.add_theme_color_override("font_color", UiMaterial.INK)
			learn_btn.disabled = false
			learn_btn.text = "參悟"
		else:
			cost_label.add_theme_color_override("font_color", Color("9b3e30"))
			learn_btn.disabled = true
			learn_btn.text = "道心不足"

func _on_reincarnate_action_pressed() -> void:
	if _reincarnate_action_button.disabled:
		return
	if not _confirming:
		_confirming = true
		_reincarnate_desc_label.show()
		_cancel_button.show()
		_confirm_label.show()
		_reincarnate_action_button.text = "確認轉世"
		return
	_cancel_confirmation()
	reincarnate_requested.emit("normal")

func _on_close_pressed() -> void:
	_cancel_confirmation()
	visible = false
	close_requested.emit()

static func _format_amount_str(raw: Variant) -> String:
	var parsed := AmountCompat.try_parse(str(raw))
	if not parsed.get("ok", false):
		return str(raw)
	var amount: AmountCompat = parsed["value"]
	if amount.layer == 0 and absf(amount.to_float()) < 1000000.0:
		return ("%.2f" % amount.to_float()).rstrip("0").trim_suffix(".")
	return amount.to_display_string()
