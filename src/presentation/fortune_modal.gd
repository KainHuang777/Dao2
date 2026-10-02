class_name FortuneModal
extends Control

signal trigger_requested()
signal resolve_requested(option_index: int)
signal close_requested()

var _background: Panel
var _content: VBoxContainer
var _body_scroll: ScrollContainer
var _title_row: HBoxContainer
var _title_label: Label
var _close_button: Button

var _encounter_panel: PanelContainer
var _encounter_title: Label
var _encounter_desc: Label
var _encounter_bias_tag: Label

var _options_container: VBoxContainer
var _status_label: Label
var _trigger_btn: Button
var _stats_label: Label

var _last_view_data: Dictionary = {}

func _init() -> void:
	_build_ui()

func _ready() -> void:
	if _content == null:
		_build_ui()


func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	if _background != null:
		_background.size = size
	if _body_scroll != null:
		var pad := 16.0
		_body_scroll.position = Vector2(pad, pad)
		_body_scroll.size = Vector2(maxf(0.0, size.x - pad * 2.0), maxf(0.0, size.y - pad * 2.0))

func _build_ui() -> void:
	_background = Panel.new()
	_background.add_theme_stylebox_override("panel", UiTypography.dialog_surface())
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_body_scroll)
	_content = VBoxContainer.new()
	_content.name = "FortuneContent"
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.add_child(_content)

	# 標題列
	_title_row = HBoxContainer.new()
	_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_title_row)

	_title_label = Label.new()
	_title_label.text = "天人感應 · 機緣奇遇"
	_title_label.add_theme_font_override("font", UiTypography.chapter_font())
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_row.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_row.add_child(spacer)

	_close_button = Button.new()
	_close_button.text = "關閉"
	_close_button.custom_minimum_size = Vector2(80, 44)
	UiMaterial.apply_button(_close_button)
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)

	# 奇遇情境展示卡
	_encounter_panel = PanelContainer.new()
	_encounter_panel.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
	_content.add_child(_encounter_panel)

	var enc_vbox := VBoxContainer.new()
	enc_vbox.add_theme_constant_override("separation", 8)
	_encounter_panel.add_child(enc_vbox)

	_encounter_title = Label.new()
	_encounter_title.text = "天地寂寥，暫無天機降臨"
	_encounter_title.add_theme_font_override("font", UiTypography.emphasis_font())
	_encounter_title.add_theme_font_size_override("font_size", 18)
	_encounter_title.add_theme_color_override("font_color", UiMaterial.INK)
	enc_vbox.add_child(_encounter_title)

	_encounter_desc = Label.new()
	_encounter_desc.text = "靜候時辰推移與五行天象運轉。亦可在冷卻完畢時神識主動感應天地。"
	_encounter_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encounter_desc.add_theme_font_override("font", UiTypography.body_font())
	_encounter_desc.add_theme_font_size_override("font_size", 16)
	_encounter_desc.add_theme_color_override("font_color", UiMaterial.INK)
	enc_vbox.add_child(_encounter_desc)

	_encounter_bias_tag = Label.new()
	_encounter_bias_tag.text = ""
	_encounter_bias_tag.add_theme_font_override("font", UiTypography.body_font())
	_encounter_bias_tag.add_theme_font_size_override("font_size", 16)
	_encounter_bias_tag.add_theme_color_override("font_color", UiMaterial.INK)
	enc_vbox.add_child(_encounter_bias_tag)

	# 選項按鈕容器
	_options_container = VBoxContainer.new()
	_options_container.name = "OptionsContainer"
	_options_container.add_theme_constant_override("separation", 8)
	_content.add_child(_options_container)

	# 提示與推演按鈕
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", UiTypography.body_font())
	_status_label.add_theme_font_size_override("font_size", 14)
	_content.add_child(_status_label)

	_trigger_btn = Button.new()
	_trigger_btn.text = "神識推演機緣"
	_trigger_btn.custom_minimum_size = Vector2(160, 44)
	UiMaterial.apply_button(_trigger_btn)
	_trigger_btn.pressed.connect(func(): trigger_requested.emit())
	_content.add_child(_trigger_btn)

	# 底部統計
	_stats_label = Label.new()
	_stats_label.text = ""
	_stats_label.add_theme_font_override("font", UiTypography.body_font())
	_stats_label.add_theme_font_size_override("font_size", 13)
	_content.add_child(_stats_label)

func refresh(view_data: Dictionary) -> void:
	_last_view_data = view_data
	var f_data: Dictionary = view_data.get("fortune", {})
	if f_data.is_empty():
		return

	var has_pending: bool = bool(f_data.get("has_pending", false))
	var pending: Dictionary = f_data.get("pending_encounter", {})
	var cd: float = float(f_data.get("cooldown_remaining", 0.0))
	var max_per_hour: int = int(f_data.get("max_per_hour", 1))
	var claimed: int = int(f_data.get("total_fortunes_claimed", 0))

	_stats_label.text = "當前境界上限：每小時 %d 次 · 累計獲取機緣：%d 次" % [max_per_hour, claimed]

	for child in _options_container.get_children():
		child.queue_free()

	if has_pending and not pending.is_empty():
		_trigger_btn.visible = false
		_encounter_title.text = String(pending.get("title", "機緣降臨"))
		_encounter_desc.text = String(pending.get("desc", ""))
		
		var tags: Array = []
		var r_bias: String = String(pending.get("realm_bias", ""))
		var w_bias: String = String(pending.get("weather_bias", ""))
		var s_bias: String = String(pending.get("shichen_bias", ""))
		if not r_bias.is_empty():
			tags.append("契合界域: " + r_bias)
		if not w_bias.is_empty():
			tags.append("契合天候: " + w_bias)
		if not s_bias.is_empty():
			tags.append("契合時辰: " + s_bias)
		_encounter_bias_tag.text = " · ".join(tags)
		_encounter_bias_tag.visible = not tags.is_empty()

		var options: Array = pending.get("options", [])
		var resources: Dictionary = view_data.get("resources", {})

		for idx in range(options.size()):
			var opt: Dictionary = options[idx]
			var opt_btn := Button.new()
			opt_btn.custom_minimum_size = Vector2(0, 48)
			UiMaterial.apply_button(opt_btn)

			var btn_text: String = "【抉擇 %d】%s\n%s" % [idx + 1, opt.get("text", ""), opt.get("desc", "")]
			var costs: Dictionary = opt.get("costs", {})
			var can_afford: bool = true
			var cost_texts: Array = []

			for res_id in costs:
				var cost_val: float = float(costs[res_id])
				if cost_val > 0.0:
					cost_texts.append("需消耗 %s × %.0f" % [res_id, cost_val])
					if resources.has(res_id):
						var cur_val: float = float(resources[res_id].get("value", 0.0))
						if cur_val < cost_val:
							can_afford = false
					else:
						can_afford = false

			if not cost_texts.is_empty():
				btn_text += " (" + ", ".join(cost_texts) + ")"

			opt_btn.text = btn_text
			opt_btn.disabled = not can_afford

			var opt_index := idx
			opt_btn.pressed.connect(func(): resolve_requested.emit(opt_index))
			_options_container.add_child(opt_btn)

		_status_label.text = "請選擇一項道法決策以結算機緣。"
	else:
		_encounter_title.text = "天地寂寥，暫無天機"
		_encounter_desc.text = "靜候天地陰陽五行運轉。亦可在冷卻就緒時主動引動神識推演。"
		_encounter_bias_tag.visible = false
		_trigger_btn.visible = true

		if cd <= 0.0:
			_trigger_btn.disabled = false
			_trigger_btn.text = "神識推演機緣 (就緒)"
			_status_label.text = "神識感應已積蓄圓滿，可主動推演天機。"
		else:
			_trigger_btn.disabled = true
			var minutes := int(ceil(cd / 60.0))
			_trigger_btn.text = "感應蓄力中 (約 %d 分鐘)" % minutes
			_status_label.text = "距離下次天人感應約需 %d 秒。" % int(cd)

func set_result_message(msg: String) -> void:
	_status_label.text = msg
