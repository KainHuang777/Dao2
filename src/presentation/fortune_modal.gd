class_name FortuneModal
extends Control
## Presentation reads View; commands and persistence remain owned by Session.
signal trigger_requested()
signal resolve_requested(option_index: int)
signal close_requested()
signal retry_save_requested()

const ART_DIR := "res://assets/ui/fortune-painted/"
const ResourceIconScript = preload("res://src/presentation/resource_icon.gd")
var book_provider: Callable
var identity_provider: Callable
var displayed_instance := ""
var _book: DecisionBookView
var _book_button: Button
var _book_open := false
var _book_revision := -1
var _book_identity := -1
var _book_data: Dictionary = {}
var _background: Panel
var _margin: MarginContainer
var _content: VBoxContainer
var _body_scroll: ScrollContainer
var _title_row: HBoxContainer
var _title_label: Label
var _close_button: Button
var _encounter_panel: HBoxContainer
var _story: VBoxContainer
var _story_header: HBoxContainer
var _encounter_title: Label
var _encounter_desc: Label
var _encounter_bias_tag: Label
var _art: TextureRect
var _options_container: VBoxContainer
var _status_label: Label
var _trigger_btn: Button
var _stats_label: Label
var _feedback_row: HBoxContainer
var _feedback: Label
var _retry: Button
var _option_rows: Array[Dictionary] = []
var _last_view_data: Dictionary = {}
var _pending_key := ""
var _mapping: Dictionary = {}
var _compact := false
var _pending_save := false
var _submitted := false
var _result_message := ""

func _init() -> void:
	_build_ui()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ART_DIR + "manifest.json"))
	if parsed is Dictionary: _mapping = parsed.get("encounter_mapping", {})

func _label(parent: Node, font_size: int = 16) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _build_ui() -> void:
	theme = UiTypography.create_theme()
	_background = Panel.new()
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)
	_margin = MarginContainer.new()
	add_child(_margin)
	_margin.minimum_size_changed.connect(func(): _fit_margin.call_deferred())
	_content = VBoxContainer.new()
	_content.name = "FortuneContent"
	_content.add_theme_constant_override("separation", 8)
	_margin.add_child(_content)
	_title_row = HBoxContainer.new()
	_content.add_child(_title_row)
	_title_label = _label(_title_row, 20)
	_title_label.text = "天人感應 · 機緣奇遇"
	_title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_close_button = CloseSeal.new()
	_close_button.pressed.connect(func(): close_requested.emit())
	_title_row.add_child(_close_button)
	_stats_label = _label(_content)
	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_body_scroll)
	_encounter_panel = HBoxContainer.new()
	_encounter_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_encounter_panel.add_theme_constant_override("separation", 20)
	_body_scroll.add_child(_encounter_panel)
	_art = UiIllustration.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_encounter_panel.add_child(_art)
	_story = VBoxContainer.new()
	_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story.add_theme_constant_override("separation", 10)
	_encounter_panel.add_child(_story)
	_story_header = HBoxContainer.new()
	_story_header.add_theme_constant_override("separation", 12)
	_story.add_child(_story_header)
	_encounter_title = _label(_story_header, 20)
	_encounter_title.add_theme_font_override("font", UiTypography.emphasis_font())
	_encounter_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_encounter_desc = _label(_story)
	_encounter_bias_tag = _label(_story)
	_options_container = VBoxContainer.new()
	_options_container.name = "OptionsContainer"
	_options_container.add_theme_constant_override("separation", 8)
	_story.add_child(_options_container)
	_book = DecisionBookView.new()
	_story.add_child(_book)
	_book_button = GameTab.new()
	_book_button.text = "抉擇簿"
	_book_button.pressed.connect(func():
		_book_open = not _book_open
		_book_button.button_pressed = _book_open
		refresh(_last_view_data))
	_story_header.add_child(_book_button)
	_trigger_btn = Button.new()
	_trigger_btn.custom_minimum_size = Vector2(200,44)
	_trigger_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiMaterial.apply_button(_trigger_btn)
	_trigger_btn.pressed.connect(_request_trigger)
	_story.add_child(_trigger_btn)
	_status_label = _label(_content)
	_feedback_row = HBoxContainer.new()
	_content.add_child(_feedback_row)
	_feedback = _label(_feedback_row)
	_retry = Button.new()
	_retry.text = "重試保存"
	_retry.custom_minimum_size = Vector2(96,44)
	UiMaterial.apply_button(_retry)
	_retry.pressed.connect(func(): retry_save_requested.emit())
	_feedback_row.add_child(_retry)
	_feedback_row.hide()
	_retry.hide()

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	_background.size = size
	_compact = size.y < 350
	_background.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if _compact else UiMaterial.scroll_shell())
	UiMaterial.apply_scroll_content_margins(_margin, _compact)
	_margin.size = size
	_stats_label.visible = not _compact
	_title_row.visible = not _compact
	_content.add_theme_constant_override("separation", 4 if _compact else 8)
	_story.add_theme_constant_override("separation", 6 if _compact else 10)
	var wide := size.x >= 950 and not _compact
	var art_parent: Node = _encounter_panel if wide else _story_header
	if _art.get_parent() != art_parent: _art.reparent(art_parent)
	art_parent.move_child(_art,0)
	_art.custom_minimum_size = Vector2.ONE * (256 if wide else (64 if _compact else 112))
	_feedback.text = "保存失敗；請重試保存。" if _compact and _pending_save else _feedback.tooltip_text
	_fit_margin.call_deferred()

func _fit_margin() -> void:
	# Wrapped text can report its old narrow-width minimum for one layout pass.
	# Fit again after containers settle so the viewport remains a real inner scroll.
	_margin.size = size

func _request_trigger() -> void:
	if _submitted: return
	_submitted = true
	_trigger_btn.disabled = true
	trigger_requested.emit()

func _request_option(index: int) -> void:
	if _submitted: return
	_submitted = true
	for row in _option_rows: row.button.disabled = true
	resolve_requested.emit(index)

func _build_options(options: Array) -> void:
	for child in _options_container.get_children():
		_options_container.remove_child(child)
		child.queue_free()
	_option_rows.clear()
	for idx in options.size():
		var opt: Dictionary = options[idx]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
		_options_container.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		card.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var title := _label(copy,18)
		title.text = str(opt.get("text",""))
		var desc := _label(copy)
		desc.text = str(opt.get("desc",""))
		desc.visible = not desc.text.is_empty()
		var effect := _label(copy)
		effect.text = "固定效果：不支付、不取得額外收益" if _last_view_data.get("fortune", {}).get("pending_encounter", {}).get("content_batch") == "content-p1-story" and idx == 2 else DecisionBookView.preview_text(opt.get("rewards", {}))
		var cost_box := VBoxContainer.new()
		copy.add_child(cost_box)
		var costs: Array[Dictionary] = []
		for id in opt.get("costs",{}):
			var required := float(opt.costs[id])
			if required <= 0: continue
			var cost_row := HBoxContainer.new()
			cost_box.add_child(cost_row)
			var icon := ResourceIconScript.new()
			icon.resource_id = FortuneSystem.resource_key(_last_view_data.get("resources",{}),str(id))
			cost_row.add_child(icon)
			var cost_label := _label(cost_row)
			costs.append({"id":str(id),"need":required,"label":cost_label})
		var reason := _label(copy)
		reason.hide()
		var button := Button.new()
		button.text = "選擇"
		button.custom_minimum_size = Vector2(72,44)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UiMaterial.apply_button(button)
		button.pressed.connect(_request_option.bind(idx))
		row.add_child(button)
		_option_rows.append({"card":card,"button":button,"costs":costs,"reason":reason})

func refresh(view_data: Dictionary) -> void:
	_last_view_data = view_data
	var revision := int(view_data.get("revision", -1))
	var identity := int(identity_provider.call()) if identity_provider.is_valid() else 0
	if book_provider.is_valid() and (revision != _book_revision or identity != _book_identity):
		_book_data = book_provider.call()
		_book_revision = revision
		_book_identity = identity
	var fortune: Dictionary = view_data.get("fortune",{})
	var pending: Dictionary = fortune.get("pending_encounter",{})
	var has_pending := bool(fortune.get("has_pending",false)) and not pending.is_empty()
	var options: Array = pending.get("options",[]) if has_pending else []
	displayed_instance = str(fortune.get("instance_id", ""))
	var key := JSON.stringify(pending) if has_pending else ""
	if key != _pending_key:
		_pending_key = key
		_submitted = false
		_build_options(options)
		_body_scroll.scroll_vertical = 0
	_book.visible = _book_open or (not has_pending and not _book_data.get("receipts", []).is_empty())
	_book.show_book(_book_data, not _book_open)
	_book_button.button_pressed = _book_open
	_stats_label.text = "每小時 %d 次 · 已結算 %d 次" % [int(fortune.get("max_per_hour",1)),int(fortune.get("total_fortunes_claimed",0))]
	_options_container.visible = has_pending
	_trigger_btn.visible = not has_pending
	var art_id := str(pending.get("art", _mapping.get(str(pending.get("id","")),"omen"))) if has_pending else "sensing"
	_art.texture = load(ART_DIR + art_id + ".png")
	if has_pending:
		_encounter_title.text = str(pending.get("title","機緣降臨"))
		_encounter_desc.text = str(pending.get("desc",""))
		var realm_names := {"realm_human":"人界","realm_spirit":"靈界","realm_nether":"幽冥界","realm_beast":"妖界","realm_demon":"魔界","realm_immortal":"仙界","realm_buddha":"佛界","realm_chaos":"混沌界","realm_origin":"本源界"}
		var weather_names := {"wood":"木","fire":"火","earth":"土","metal":"金","water":"水"}
		var tags: Array[String] = []
		var realm_id := str(pending.get("realm_bias",""))
		var weather_id := str(pending.get("weather_bias",""))
		if not realm_id.is_empty(): tags.append(str(realm_names.get(realm_id,realm_id)))
		if not weather_id.is_empty(): tags.append(str(weather_names.get(weather_id,weather_id)) + "行天候")
		if not str(pending.get("shichen_bias","")).is_empty(): tags.append(str(pending.shichen_bias) + "時")
		_encounter_bias_tag.text = "契合條件：" + " · ".join(tags)
		_encounter_bias_tag.visible = not tags.is_empty()
		_status_label.text = "待決 · 返回可暫收（無期限）"
		_status_label.tooltip_text = "世界繼續運行；待決只暫停下次機緣倒數。轉世會清除待決。"
		var resources: Dictionary = view_data.get("resources",{})
		for index in range(_option_rows.size()):
			var row: Dictionary = _option_rows[index]
			var can_afford := true
			for cost in row.costs:
				var resource: Dictionary = resources.get(FortuneSystem.resource_key(resources,cost.id),{})
				var parsed := AmountCompat.try_parse(str(resource.get("value","0")))
				var enough: bool = bool(parsed.get("ok",false)) and parsed.value.compare_to(AmountCompat.from_number(cost.need)) >= 0
				can_afford = can_afford and enough
				var resource_id := FortuneSystem.resource_key(resources,cost.id)
				var resource_name := ResourceIconScript.get_resource_name(resource_id)
				var available: String = parsed.value.to_display_string() if bool(parsed.get("ok",false)) else "0"
				cost.label.text = "%s／%s" % [available,AmountCompat.from_number(cost.need).to_display_string()]
				if not ResourceIconScript.TEXTURES.has(resource_id): cost.label.text = resource_name + " " + cost.label.text
				cost.label.tooltip_text = "%s：持有 %s／需要 %s" % [resource_name,str(resource.get("value","0")),str(cost.need)]
				cost.label.add_theme_color_override("font_color",UiMaterial.INK if enough else Color("a83932"))
			var errors: Array = fortune.get("option_errors", [])
			var error := str(errors[index]) if index < errors.size() else ""
			row.button.disabled = not can_afford or _submitted or not error.is_empty()
			row.button.tooltip_text = StoryProgress.reason(error)
			row.reason.text = StoryProgress.reason(error)
			row.reason.visible = not error.is_empty()
	else:
		_encounter_title.text = "靜候天機"
		_encounter_desc.text = "靜心感應天地流轉，機緣將隨時辰降臨。"
		_encounter_bias_tag.hide()
		var cooldown := maxf(0,float(fortune.get("cooldown_remaining",0)))
		_trigger_btn.disabled = cooldown > 0 or _submitted
		_trigger_btn.text = "神識推演 · 就緒" if cooldown <= 0 else "感應蓄力 · %ds" % int(ceil(cooldown))
		_status_label.text = "感應就緒" if cooldown <= 0 else "冷卻中 · %ds" % int(ceil(cooldown))
		if not _result_message.is_empty():
			_encounter_desc.text = _result_message
			_encounter_title.text = "機緣已結算"

func set_result_message(msg: String) -> void:
	_result_message = msg

func set_command_result(result: Dictionary, saved: Dictionary = {}) -> void:
	_submitted = false
	_feedback_row.show()
	if not bool(result.get("ok",false)):
		_feedback.text = "操作未完成：" + str(result.get("error","未知"))
		_retry.visible = _pending_save
	elif not bool(saved.get("ok",false)):
		_pending_save = true
		_feedback.text = "操作已生效，保存失敗：" + str(saved.get("error","未知")) + "；請重試保存。"
		_retry.show()
	else:
		_pending_save = false
		_feedback.text = "操作已完成並保存。"
		_retry.hide()
	_feedback.tooltip_text = _feedback.text
	if _compact and _pending_save: _feedback.text = "保存失敗；請重試保存。"

func set_save_result(result: Dictionary) -> void:
	if bool(result.get("ok",false)): storage_recovered()
	else: set_command_result({"ok":true},result)

func storage_recovered() -> void:
	if not _pending_save: return
	_pending_save = false
	_feedback.text = "保存已恢復，操作結果已保存。"
	_feedback.tooltip_text = _feedback.text
	_retry.hide()
