class_name SectLifeFolio
extends VBoxContainer
## Native paper folio. Only emits commands; all rewards come from the frozen View.
signal story_requested(instance_id: String, option_id: String)
signal join_requested(sect_name: String)
const ART := "res://assets/ui/sect-life/"
const SECT_ART := {
 "taixu_sect": ["taixu-gate", "shen-zhaowei", "lu-jingxing", "tang-xihe"],
 "tianjian_sect": ["tianjian-gate", "gu-yanshuang", "pei-chengfeng", "lin-sui"],
 "piaomiao_sect": ["piaomiao-gate", "wen-shuying", "ji-heng", "su-yingzhou"],
 "wanfo_sect": ["wanfo-gate", "mingzhao", "xingyuan", "yuanqing"],
 "zixiao_sect": ["zixiao-gate", "xie-guichen", "zhou-wenxu", "ning-zhaoye"],
}
var selected_sect := "太虛天闕"
var selected_npc := 0
var records := false
var comparison := false
var gate := false
var view: Dictionary = {}
var eligible := false
var blocked := false
var _body: BoxContainer
var _art: TextureRect
var _reading: VBoxContainer
var _actions: HFlowContainer
var _last_signature := ""
var _response := ""
var _response_npc := -1
var _name_label: Label
var _person_name := ""
var _scroll: ScrollContainer
var _scroll_hint: Label
var external_selector_host: Control
var _visual_col: VBoxContainer
var _reading_col: VBoxContainer

func _ready() -> void:
	resized.connect(adapt)

func refresh(data: Dictionary, show_gate: bool, can_join: bool, locked: bool) -> void:
	if view.get("life_seq", -1) != data.get("life_seq", -1) or view.get("sect_id", "") != data.get("sect_id", ""):
		_response = ""
		_response_npc = -1
	view = data.duplicate(true)
	gate = show_gate
	eligible = can_join
	blocked = locked
	var stable := view.duplicate(true)
	for key in ["tenure_seconds", "reward_epoch", "story_reserved", "rng"]: stable.erase(key)
	var signature := JSON.stringify([stable, gate, eligible, blocked, selected_sect, selected_npc, records, comparison, _response])
	if signature == _last_signature: return
	_last_signature = signature
	_build()

func _label(parent: Node, value: String) -> Label:
	return SectReformUi.text(parent, value)

func _action(parent: Node, value: String, callback: Callable, disabled: bool = false) -> Button:
	var button := InscriptionAction.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.disabled = disabled
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _paper_action(parent: Node, value: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", UiTypography.emphasis_font())
	button.add_theme_font_size_override("font_size", 18)
	UiMaterial.apply_button(button, "paper")
	button.disabled = disabled
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _heading(value: String, font_size: int = 22) -> Label:
	var label := _label(_reading, value)
	label.add_theme_font_override("font", UiTypography.epilogue_title_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("88483b"))
	return label

func _prose(value: String) -> Label:
	var label := _label(_reading, value)
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("line_spacing", 6)
	return label

func _rebuild() -> void:
	_last_signature = ""
	refresh(view, gate, eligible, blocked)

func _build() -> void:
	_name_label = null
	for child in get_children(): remove_child(child); child.queue_free()
	if is_instance_valid(external_selector_host):
		for child in external_selector_host.get_children():
			external_selector_host.remove_child(child)
			child.queue_free()
	add_theme_constant_override("separation", 8)
	_body = HBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
	add_child(_body)
	_visual_col = VBoxContainer.new()
	_visual_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_visual_col.add_theme_constant_override("separation", 8)
	_body.add_child(_visual_col)
	_reading_col = VBoxContainer.new()
	_reading_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_col.add_theme_constant_override("separation", 6)
	_body.add_child(_reading_col)
	if gate:
		var host: Node = external_selector_host if is_instance_valid(external_selector_host) else _visual_col
		if is_instance_valid(external_selector_host): external_selector_host.show()
		for sect in SectSystem.SECT_NAMES:
			var tab := GameTab.new()
			tab.text = sect
			tab.secondary = true
			tab.focus_mode = Control.FOCUS_ALL
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab.custom_minimum_size.y = 44
			tab.set_pressed_no_signal(sect == selected_sect)
			tab.pressed.connect(func(): selected_sect = sect; _rebuild())
			host.add_child(tab)
	elif view.get("available", false):
		if is_instance_valid(external_selector_host): external_selector_host.hide()
		var selectors := HFlowContainer.new()
		_visual_col.add_child(selectors)
		for i in 3:
			var tab := GameTab.new()
			tab.text = names()[i]
			tab.focus_mode = Control.FOCUS_ALL
			tab.set_pressed_no_signal(selected_npc == i)
			tab.pressed.connect(func(): selected_npc = i; records = false; _rebuild())
			selectors.add_child(tab)
		_action(selectors, "返回同門" if records else "最近記錄", func(): records = not records; _rebuild())
	else:
		if is_instance_valid(external_selector_host): external_selector_host.hide()
	var art_stage := HBoxContainer.new()
	art_stage.name = "ArtStage"
	art_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_stage.add_theme_constant_override("separation", 10)
	_visual_col.add_child(art_stage)
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_stage.add_child(_art)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_col.add_child(scroll)
	_reading = VBoxContainer.new()
	_reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading.add_theme_constant_override("separation", 12)
	scroll.add_child(_reading)
	_scroll_hint = _label(_reading_col, "")
	_scroll_hint.name = "ReadingHint"
	_scroll_hint.custom_minimum_size.y = 24
	_scroll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_scroll_hint.add_theme_color_override("font_color", Color("356452"))
	scroll.get_v_scroll_bar().changed.connect(_update_reading_hint)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): _update_reading_hint())
	scroll.resized.connect(func(): _update_reading_hint.call_deferred())
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("h_separation", 8)
	_actions.add_theme_constant_override("v_separation", 6)
	(_visual_col if gate else _reading_col).add_child(_actions)
	if gate: _gate_page()
	else: _people_page()
	if blocked: _label(_reading, view.get("blocked_reason", "操作暫不可用。"))
	adapt()
	_update_reading_hint.call_deferred()

func _update_reading_hint() -> void:
	if not is_instance_valid(_scroll_hint) or not is_instance_valid(_scroll): return
	_scroll_hint.visible = gate or bool(view.get("available", false))
	var bar := _scroll.get_v_scroll_bar()
	var overflow := bar.max_value > bar.page + 1
	var remaining := bar.value + bar.page < bar.max_value - 1
	_scroll_hint.text = ("下方尚有內文，請向下捲動 ↓" if remaining else "已讀至內文末尾") if overflow else ""

func adapt() -> void:
	if _art == null: return
	var short := size.y < 300
	if is_instance_valid(_name_label):
		_name_label.text = "【%s】" % _person_name if short else "·\n%s\n·" % "\n".join(_person_name.split("", false))
		_name_label.add_theme_font_size_override("font_size", 22 if short else 24)
	if is_instance_valid(_visual_col):
		_visual_col.custom_minimum_size.x = 120.0 if short else clampf(size.x * (0.34 if gate else 0.28), 200.0, 360.0 if gate else 300.0)
	_art.custom_minimum_size = Vector2(80 if short else 160, 64 if short else 120)
	_art.visible = gate or (view.get("available", false) and not records)
	if gate: _update_gate_art()

func _update_gate_art() -> void:
	# Tall folios use a composed portrait; low-height folios retain the panorama.
	# Both are contained in full, so roofs and sect landmarks are never cropped.
	var id := SectIdentity.canonical_id(selected_sect)
	var suffix := "-portrait" if size.y >= 300 else ""
	var filename: String = ART + SECT_ART[id][0] + suffix + ".png"
	if _art.texture != null and _art.texture.resource_path == filename: return
	if ResourceLoader.exists(filename): _art.texture = load(filename)

func _gate_page() -> void:
	var id := SectIdentity.canonical_id(selected_sect)
	_update_gate_art()
	_heading(selected_sect, 28).name = "GateTitle"
	var flavor := _label(_reading, SectPanel.SECT_FLAVORS[selected_sect])
	flavor.name = "GateFlavor"
	flavor.add_theme_font_override("font", UiTypography.biography_font())
	flavor.add_theme_font_size_override("font_size", 20)
	flavor.add_theme_color_override("font_color", Color("55594b"))
	if comparison:
		_heading("五宗比較")
		for sect in SectSystem.SECT_NAMES:
			var name_label := _label(_reading, sect)
			name_label.add_theme_font_override("font", UiTypography.emphasis_font())
			name_label.add_theme_font_size_override("font_size", 20)
			name_label.add_theme_color_override("font_color", Color("356452"))
			_prose(SectReformUi.TRADEOFFS[SectIdentity.canonical_id(sect)])
	_heading("宗門特色")
	_prose(SectReformUi.TRADEOFFS[id])
	_heading("專屬功法")
	for method in SectSpecialization.METHODS:
		var definition: Array = SectSpecialization.METHODS[method]
		if definition[0] == id:
			var method_label := _prose("%s法 · %s" % [definition[1], definition[2]])
			method_label.add_theme_font_override("font", UiTypography.emphasis_font())
			method_label.add_theme_color_override("font_color", Color("356452"))
			_label(_reading, "研習門檻 · %s" % ("築基" if definition[1] == "A" else "金丹"))
	_heading("修行與規矩")
	_prose("每世擇一山門。八項共通功法保留，專法僅當世同宗啟用。歷練獲取貢獻，可參悟功法、兌換坊市物品；守護獸沿各宗既有許可。")
	_heading("同門")
	_prose("、".join(SectLife.table(id, "names")))
	var guardians := {"taixu_sect":"太虛白澤", "tianjian_sect":"天劍狻猊", "piaomiao_sect":"縹緲芝靈兔", "wanfo_sect":"萬佛蓮心象", "zixiao_sect":"紫霄星紋貘"}
	_heading("守護獸 · %s" % guardians[id])
	_prose("委託累積信物以換取發現許可；不因拜入自動結契。")
	_paper_action(_actions, "收起比較" if comparison else "五宗比較", func(): comparison = not comparison; _rebuild())
	_paper_action(_actions, "立誓拜入「%s」" % selected_sect, func(): join_requested.emit(selected_sect), not eligible or blocked)
	if not eligible: _label(_reading, "需達築基或歷經轉世，方可拜入山門。")

func _people_page() -> void:
	if not view.get("available", false):
		_label(_reading, "同門篇章尚未開放。可繼續使用歷練、功法與坊市。")
		return
	var npc: String = SectLife.table(String(view.sect_id), "npcs")[selected_npc]
	_art.texture = load(ART + SECT_ART[view.sect_id][selected_npc + 1] + ".png")
	var affinity := int(view.npcs[npc].affinity)
	_person_heading(affinity)
	if records:
		_label(_reading, "本世最近四次相會")
		var recent: Array = view.get("recent", [])
		if recent.is_empty(): _label(_reading, "尚無相會記錄。")
		for item in recent:
			var text := SectLifeContent.read(item.id, view.choice_flags)
			_label(_reading, "%s · 宗齡 %d 祀 · %s\n%s" % [text.title, int(item.tick) / 60, text[item.option], text.responses[item.option]])
		return
	if not _response.is_empty() and _response_npc == selected_npc: _label(_reading, _response)
	elif not view.get("recent", []).is_empty():
		var latest: Dictionary = view.recent.back()
		var chapter_index := SectLife.table(String(view.sect_id), "chapters").find(latest.id)
		var daily_index := SectLife.table(String(view.sect_id), "daily").find(latest.id)
		var latest_owner: int = [0, 2, 1, 0, 2, 1][chapter_index] if chapter_index >= 0 else [0, 2, 1][daily_index]
		if latest_owner == selected_npc:
			var latest_text := SectLifeContent.read(latest.id, view.choice_flags)
			_label(_reading, "上回相會 · " + latest_text.responses[latest.option])
	var pending: Variant = view.get("pending_story")
	if pending == null:
		_label(_reading, "暫無待決相會。宗齡達到時，同門會留下訪帖；入門見禮與首務後可讀首章，也可略過導覽。")
		return
	var chapter := SectLife.table(String(view.sect_id), "chapters").find(pending.template_id)
	var daily := SectLife.table(String(view.sect_id), "daily").find(pending.template_id)
	var owner: int = [0, 2, 1, 0, 2, 1][chapter] if chapter >= 0 else [0, 2, 1][daily]
	if selected_npc != owner:
		_action(_actions, "查看%s的訪帖" % names()[owner], func(): selected_npc = owner; _rebuild())
		return
	var text: Dictionary = view.story_text
	var title := _heading(text.title)
	title.name = "StoryTitle"
	var prose := _prose(text.text)
	prose.name = "StoryProse"
	if not pending.paid: _label(_reading, "本期貢獻已滿，仍可增進交情。")
	for option in ["A", "B", "decline"]:
		var reward: Dictionary = pending.options[option]
		var details := "貢獻 +%d" % int(reward.contribution)
		for who in reward.affinity: details += " · %s交情 +%d" % [names()[SectLife.table(String(view.sect_id), "npcs").find(who)], int(reward.affinity[who])]
		var choice := VBoxContainer.new()
		choice.custom_minimum_size.x = 220
		choice.add_theme_constant_override("separation", 4)
		_actions.add_child(choice)
		var button := _paper_action(choice, text[option], func(): story_requested.emit(pending.instance_id, option), blocked)
		button.tooltip_text = details
		var reward_label := _label(choice, "收穫  " + details.replace(" · ", "\n"))
		reward_label.name = "ChoiceReward"
		reward_label.add_theme_color_override("font_color", Color("356452"))
		reward_label.add_theme_font_override("font", UiTypography.emphasis_font())

func _person_heading(affinity: int) -> void:
	var heading := HBoxContainer.new()
	heading.name = "PersonHeading"
	heading.add_theme_constant_override("separation", 20)
	_reading.add_child(heading)
	_person_name = names()[selected_npc]
	var name_host: Node = _art.get_parent() if is_instance_valid(_art) and _art.get_parent() != null else _body
	_name_label = _label(name_host, "")
	if name_host.get_child_count() > 1:
		name_host.move_child(_name_label, 1)
	_name_label.name = "PersonName"
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.add_theme_font_override("font", UiTypography.character_title_font())
	_name_label.add_theme_color_override("font_color", UiMaterial.INK)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 8)
	heading.add_child(identity)
	var affinity_row := HFlowContainer.new()
	affinity_row.add_theme_constant_override("h_separation", 12)
	identity.add_child(affinity_row)
	var rank := _label(affinity_row, "〔%s〕" % ["初識", "熟識", "相知", "知交"][0 if affinity < 20 else (1 if affinity < 50 else (2 if affinity < 80 else 3))])
	rank.autowrap_mode = TextServer.AUTOWRAP_OFF
	rank.name = "AffinityRank"
	rank.add_theme_font_override("font", UiTypography.emphasis_font())
	rank.add_theme_font_size_override("font_size", 20)
	rank.add_theme_color_override("font_color", Color("356452"))
	var amount := _label(affinity_row, "交情  %d／100" % affinity)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.name = "AffinityAmount"
	amount.add_theme_font_override("font", UiTypography.body_font())
	var progress := ProgressBar.new()
	progress.name = "AffinityProgress"
	progress.show_percentage = false
	progress.value = affinity
	progress.custom_minimum_size = Vector2(96, 4)
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", UiMaterial.rounded(Color(0.21, 0.39, 0.32, 0.12), 2))
	progress.add_theme_stylebox_override("fill", UiMaterial.rounded(Color("527864"), 2))
	affinity_row.add_child(progress)
	var motto := _label(identity, "「%s」" % SectLife.table(String(view.sect_id), "greetings")[selected_npc])
	motto.name = "PersonMotto"
	motto.add_theme_font_override("font", UiTypography.biography_font())
	motto.add_theme_font_size_override("font_size", 20)
	motto.add_theme_color_override("font_color", Color("55594b"))
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reading.add_child(divider)

func resolved(response: String) -> void:
	_response = response
	_response_npc = selected_npc
	_last_signature = ""

func names() -> Array:
	return SectLife.table(String(view.get("sect_id", "taixu_sect")), "names")
