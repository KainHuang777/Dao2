extends PanelContainer
## MAID-UI-2 presentation: reads the maid View, sends commands, owns no state or rewards.
signal portrait_requested(texture: Texture2D, owner: String)
signal memory_requested(texture: Texture2D, title: String, lines: Array)
signal action_requested(kind: String, payload: Dictionary)
const PORTRAIT := "res://assets/characters/qingheng/portrait.png"
const MEETING := "res://assets/characters/qingheng/first-meeting.png"
const OPENING := "冒昧叨擾。這一路只顧護著書，倒忘了替自己避雨……可容我借一角簷下，理好這幾頁？"
const REPLIES := ["那便叨擾了。等雨停，我再慢慢說給你聽。", "一路所見，還有幾件我不願忘的小事。你若有興趣，我們可慢慢翻。"]
const ART := {
	"qingheng": {"portrait": PORTRAIT, "meeting": MEETING},
	"nuomeizi": {"portrait": "res://assets/characters/nuomeizi/portrait-r2.png", "meeting": "res://assets/characters/nuomeizi/first-meeting-r2.png"},
	"danxia": {"portrait": "res://assets/characters/danxia/portrait-r2.png", "meeting": "res://assets/characters/danxia/first-meeting-r2.png"},
}
const STORIES := {
	"qingheng": {
		"role_note": "青藍書卷 · 洞府侍女",
		"quote": "「書可慢慢讀，\n眼前的風雨，先一起避過吧。」",
		"bio": "溫柔而有主見，習慣先理清眼前的事。她珍惜書頁，也記得與人許下的小小約定。",
		"tags": ["書卷", "細心", "溫柔有主見"],
		"closing": "一冊書，一枝筆。\n此後簷下燈明，便多了一個可以說話的人。",
		"seal": "書香",
		"scene": "雨過書未濕",
		"opening": OPENING,
		"replies": REPLIES,
		"choices": ["先進來避雨吧。", "書裡記著甚麼？"],
	},
	"nuomeizi": {
		"role_note": "墨紅劍影 · 洞府劍侍",
		"quote": "「劍要握穩，\n話也要說得明白。」",
		"bio": "爽朗而好勝，出劍時比誰都專注。她護人從不繞彎，笑起來卻像春日初晴。",
		"tags": ["劍術", "爽朗", "護短"],
		"closing": "一柄劍，一身短披。\n自雲海試劍之後，院裡便多了一陣清亮的劍鳴。",
		"seal": "劍心",
		"scene": "雲海試劍",
		"opening": "這片雲海最適合試劍。你若站穩了，我便把這一式慢些使給你看——先說好，輸了可不許賴。",
		"replies": ["那便請你慢些使，我看仔細。", "劍勢未收，雲海先起了風。你這一式，記住了。"],
		"choices": ["先請你露一手。", "這劍，是怎麼練成的？"],
	},
	"danxia": {
		"role_note": "藕紫丹心 · 洞府丹師",
		"quote": "「火候不到，\n急也無用。」",
		"bio": "沉穩從容，看火候也看人心。她話不多，卻總在該開口時說中要緊處。",
		"tags": ["丹道", "沉穩", "外冷內熱"],
		"closing": "一爐丹，一盞茶。\n丹房夜話之後，燈下便多了一道不疾不徐的身影。",
		"seal": "丹心",
		"scene": "丹房夜話",
		"opening": "丹爐的火不能急，人的話也不必急。坐罷——這爐丹還要一炷香，正好聽你說說來意。",
		"replies": ["那我便等這一爐丹，也等你的下文。", "火候到了，話也到了。今晚這一爐，算我陪你守的。"],
		"choices": ["這爐丹，煉的是甚麼？", "夜還長，慢慢說。"],
	},
}
const BOND_CG := {
	"qingheng": {
		"path": "res://assets/characters/qingheng/bond-lamplight-r1.png",
		"title": "前世燈火",
		"lines": ["燈火照著舊時的書案。她說，前世也曾這樣等一個人回來。", "這一世，她記得的不只是書頁，還有一盞不肯熄的燈。"],
	},
	"nuomeizi": {
		"path": "res://assets/characters/nuomeizi/bond-sword-rain-r1.png",
		"title": "劍鳴舊世",
		"lines": ["劍鳴穿過雨幕。她說，這一式在很久以前也曾在同一場雨裡響過。", "舊世未竟的劍，如今在她手中終於有了收勢。"],
	},
	"danxia": {
		"path": "res://assets/characters/danxia/bond-night-vigil-r1.png",
		"title": "丹心照夜",
		"lines": ["丹爐的火照著長夜。她說，前世也是這樣守著一爐未成的丹。", "這一夜，火候終於到了，人也終於等到。"],
	},
}
const MODES := ["person", "meeting", "work", "bond"]
const MAID_ORDER := ["qingheng", "nuomeizi", "danxia"]
const MAID_NAMES := {"qingheng": "青蘅", "nuomeizi": "糯美子", "danxia": "丹霞"}
const MAID_ROLES := {"qingheng": "侍女", "nuomeizi": "劍侍", "danxia": "丹師"}
const DUTY_KINDS := {"qingheng": "steward_stock", "nuomeizi": "oversee_build", "danxia": "restock_pills"}
const TARGET_DUTIES := ["steward_stock", "restock_pills"]
const DUTY_FIELDS := {"qingheng": "recipe_id", "nuomeizi": "building_id", "danxia": "pill_id"}
const OPTION_FIELDS := {"qingheng": "recipes", "nuomeizi": "buildings", "danxia": "pills"}
const DUTY_PLAIN := {"qingheng": "定量備料", "nuomeizi": "定量監造", "danxia": "定量煉丹"}
const REASONS := {
	"CHAPTER_CLAIMED": "已領取",
	"CHAPTER_LOCKED": "需先領前一章",
	"CHAPTER_REQUIREMENT": "尚未達成條件",
	"CHAPTER_UNKNOWN": "尚未開放",
	"MAID_REQUIREMENT": "條件尚未足",
	"ALCHEMY_LOCKED": "丹道未開",
	"ALREADY_RECRUITED": "已在洞府",
	"UNKNOWN_MAID": "尚未可招募",
	"DUTY_BUSY": "另有仙侍值守中",
	"DUTY_NONE": "尚未指派",
}
const RECRUIT_TEXTS := {
	"qingheng": {"MAID_REQUIREMENT": "先建成茅屋，青蘅便會進府。"},
	"nuomeizi": {"MAID_REQUIREMENT": "青蘅羈絆達相知、境界築基後，糯美子方可入府。"},
	"danxia": {"MAID_REQUIREMENT": "青蘅羈絆達相知、境界築基後，丹霞方可入府。", "ALCHEMY_LOCKED": "丹道尚未解鎖，丹霞無法開爐。"},
}
const REUNION_LINE := "久別重逢。燈還亮著，舊約也還算數。"
var mode := "person"
var selected_maid := "qingheng"
var selected_reply := -1
var column: VBoxContainer
var person: HBoxContainer
var portrait_frame: PanelContainer
var portrait_button: Button
var portrait_image: TextureRect
var portrait_placeholder: Label
var name_column: BoxContainer
var role_label: Label
var name_label: Label
var seal: Label
var copy_scroll: ScrollContainer
var copy_box: VBoxContainer
var bookmark: PanelContainer
var bio_placeholder: Label
var bio_role_label: Label
var bio_quote_label: Label
var bio_text_label: Label
var bio_tags_label: Label
var bio_closing_label: Label
var meeting: BoxContainer
var meeting_image: TextureRect
var missing_meeting: Label
var dialogue: BoxContainer
var reading: VBoxContainer
var speaker: Label
var line_scroll: ScrollContainer
var line: Label
var choices: BoxContainer
var choice_buttons: Array = []
var replay: Button
var work: ScrollContainer
var work_box: VBoxContainer
var work_heading: Label
var work_fields: BoxContainer
var work_status: Label
var work_owner: Label
var duty_picker: OptionButton
var duty_target: SpinBox
var duty_hint: Label
var action_row: BoxContainer
var assign_button: InscriptionAction
var pause_button: InscriptionAction
var execute_button: InscriptionAction
var clear_button: InscriptionAction
var bond: ScrollContainer
var bond_box: VBoxContainer
var bond_heading: Label
var bond_status: Label
var bond_next: Label
var chapter_box: VBoxContainer
var chapter_rows: Array = []
var reunion_box: BoxContainer
var reunion_label: Label
var reunion_button: InscriptionAction
var recruit_box: BoxContainer
var recruit_label: Label
var recruit_button: InscriptionAction
var feedback: Label
var bond_feedback: Label
var tabs: Dictionary = {}
var maid_row: BoxContainer
var maid_buttons: Dictionary = {}
var title: Label
var _maid_view: Dictionary = {}
var _duty_ids: Array[String] = []
var _duty_choice := ""
var _option_signature := ""
var _last_duty_target := -1
var _portrait_id := "qingheng"
var _meeting_id := ""
var _compact := false
var _bounds := Rect2()

class BookmarkPaper extends StyleBox:
	var bg_color := Color("ebe8d9")
	var border_color := Color("657f79")
	func _init() -> void:
		content_margin_left = 24
		content_margin_right = 24
		content_margin_top = 18
		content_margin_bottom = 32
	func _draw(canvas_item: RID, rect: Rect2) -> void:
		var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.get_center().x, rect.end.y - 16), Vector2(rect.position.x, rect.end.y)])
		RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([bg_color]))
		RenderingServer.canvas_item_add_line(canvas_item, rect.position, Vector2(rect.end.x, rect.position.y), border_color, 3, true)

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	title = _label("侍女 · 青蘅", 22)
	title.add_theme_font_override("font", UiTypography.emphasis_font())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for entry in [["person", "人物"], ["meeting", "初遇重溫"], ["work", "職掌"], ["bond", "羈絆"]]:
		var button := GameTab.new()
		button.text = entry[1]
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(show_mode.bind(entry[0]))
		header.add_child(button)
		tabs[entry[0]] = button
	maid_row = BoxContainer.new()
	maid_row.add_theme_constant_override("separation", 6)
	column.add_child(maid_row)
	for id in MAID_ORDER:
		var selector := GameTab.new()
		selector.text = String(MAID_NAMES.get(id, id))
		selector.focus_mode = Control.FOCUS_ALL
		selector.pressed.connect(select_maid.bind(id))
		maid_row.add_child(selector)
		maid_buttons[id] = selector
	person = HBoxContainer.new()
	person.size_flags_vertical = Control.SIZE_EXPAND_FILL
	person.add_theme_constant_override("separation", 24)
	column.add_child(person)
	portrait_frame = PanelContainer.new()
	portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_frame.size_flags_stretch_ratio = 1.3
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("e4e9df")
	frame.border_color = Color("9ca99b")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(12)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	person.add_child(portrait_frame)
	var stage := HBoxContainer.new()
	portrait_frame.add_child(stage)
	name_column = BoxContainer.new()
	name_column.vertical = true
	name_column.custom_minimum_size.x = 72
	name_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage.add_child(name_column)
	role_label = _label("侍\n女", 24, true)
	name_label = _label("青\n蘅", 60, true)
	seal = _label("書香", 18, true)
	seal.add_theme_color_override("font_color", Color("914d42"))
	for label in [role_label, name_label, seal]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_column.add_child(label)
	portrait_button = Button.new()
	portrait_button.name = "FullPortrait"
	portrait_button.tooltip_text = "查看完整立繪"
	portrait_button.accessibility_name = "查看青蘅完整立繪"
	portrait_button.custom_minimum_size = Vector2(44, 44)
	portrait_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]:
		portrait_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	stage.add_child(portrait_button)
	portrait_image = _image(PORTRAIT)
	portrait_button.add_child(portrait_image)
	portrait_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_button.pressed.connect(open_art)
	portrait_placeholder = _label("立繪待 Codex 補完", 18)
	portrait_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(portrait_placeholder)
	copy_scroll = _scroll()
	copy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	person.add_child(copy_scroll)
	copy_box = VBoxContainer.new()
	copy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_box.add_theme_constant_override("separation", 18)
	copy_scroll.add_child(copy_box)
	bookmark = PanelContainer.new()
	bookmark.add_theme_stylebox_override("panel", BookmarkPaper.new())
	copy_box.add_child(bookmark)
	var bio := VBoxContainer.new()
	bio.add_theme_constant_override("separation", 14)
	bookmark.add_child(bio)
	bio.add_child(_label("人物小傳", 20, true))
	bio_role_label = _label("青藍書卷 · 洞府侍女", 18)
	bio.add_child(bio_role_label)
	bio_quote_label = _label("「書可慢慢讀，\n眼前的風雨，先一起避過吧。」", 22)
	bio.add_child(bio_quote_label)
	bio_text_label = _label("溫柔而有主見，習慣先理清眼前的事。她珍惜書頁，也記得與人許下的小小約定。", 18)
	bio.add_child(bio_text_label)
	bio_tags_label = _label("書卷　·　細心　·　溫柔有主見", 18)
	bio.add_child(bio_tags_label)
	bio_closing_label = _label("一冊書，一枝筆。\n此後簷下燈明，便多了一個可以說話的人。", 18)
	copy_box.add_child(bio_closing_label)
	bio_placeholder = _label("人物小傳待 Codex 補完。", 18)
	copy_box.add_child(bio_placeholder)
	meeting = BoxContainer.new()
	meeting.vertical = true
	meeting.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meeting.add_theme_constant_override("separation", 14)
	column.add_child(meeting)
	meeting_image = _image("")
	meeting_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meeting_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(meeting_image)
	missing_meeting = _label("初遇 CG 待 Codex 補完", 18)
	missing_meeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_meeting.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	missing_meeting.size_flags_vertical = Control.SIZE_EXPAND_FILL
	missing_meeting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(missing_meeting)
	dialogue = BoxContainer.new()
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting.add_child(dialogue)
	reading = VBoxContainer.new()
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.add_child(reading)
	speaker = _label("青蘅 · 雨過書未濕", 20)
	reading.add_child(speaker)
	line_scroll = _scroll()
	line_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reading.add_child(line_scroll)
	line = _label(OPENING, 18)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_scroll.add_child(line)
	var responses := VBoxContainer.new()
	dialogue.add_child(responses)
	choices = BoxContainer.new()
	choices.vertical = true
	responses.add_child(choices)
	var choice_labels := _choice_labels()
	for index in REPLIES.size():
		var choice := InscriptionAction.new()
		choice.text = String(choice_labels[index]) if index < choice_labels.size() else ""
		choice.add_theme_font_size_override("font_size", 18)
		choice.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		choice.pressed.connect(reply.bind(index))
		choices.add_child(choice)
		choice_buttons.append(choice)
	replay = InscriptionAction.new()
	replay.text = "重新相遇"
	replay.add_theme_font_size_override("font_size", 18)
	replay.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	replay.pressed.connect(restart_meeting)
	responses.add_child(replay)
	work = _page("work")
	work_box = VBoxContainer.new()
	work_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_box.add_theme_constant_override("separation", 10)
	work.add_child(work_box)
	work_heading = _head("職掌")
	work_box.add_child(work_heading)
	work_status = _label("尚未取得仙侍狀態。", 18)
	work_status.add_theme_font_override("font", UiTypography.emphasis_font())
	work_box.add_child(work_status)
	work_owner = _label("目前沒有生效中的職掌。", 18)
	work_box.add_child(work_owner)
	work_fields = BoxContainer.new()
	work_fields.add_theme_constant_override("separation", 8)
	work_box.add_child(work_fields)
	duty_picker = OptionButton.new()
	duty_picker.custom_minimum_size = Vector2(220, 44)
	duty_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duty_picker.item_selected.connect(_on_option_selected)
	duty_picker.add_theme_font_override("font", UiTypography.body_font())
	duty_picker.add_theme_font_size_override("font_size", 16)
	duty_picker.get_popup().add_theme_font_override("font", UiTypography.body_font())
	duty_picker.get_popup().add_theme_font_size_override("font_size", 16)
	duty_picker.get_popup().add_theme_constant_override("v_separation", 28)
	work_fields.add_child(duty_picker)
	duty_target = SpinBox.new()
	duty_target.min_value = 1
	duty_target.max_value = 999
	duty_target.step = 1
	duty_target.value = 1
	duty_target.prefix = "目標 "
	duty_target.suffix = " 個"
	duty_target.custom_minimum_size.y = 44
	duty_target.value_changed.connect(func(_value: float): _update_actions())
	work_fields.add_child(duty_target)
	duty_hint = _label("尚無可用目標", 18)
	work_box.add_child(duty_hint)
	action_row = BoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	work_box.add_child(action_row)
	assign_button = _action(action_row, "指派", _assign)
	pause_button = _action(action_row, "暫停", _toggle_pause)
	execute_button = _action(action_row, "立即執行", _execute)
	clear_button = _action(action_row, "清除", _clear)
	feedback = _label("", 18)
	feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_box.add_child(feedback)
	bond = _page("bond")
	bond_box = VBoxContainer.new()
	bond_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_box.add_theme_constant_override("separation", 10)
	bond.add_child(bond_box)
	bond_heading = _head("羈絆")
	bond_box.add_child(bond_heading)
	bond_status = _label("初識　0 點", 18)
	bond_status.add_theme_font_override("font", UiTypography.emphasis_font())
	bond_box.add_child(bond_status)
	bond_next = _label("尚無下一階段。", 18)
	bond_box.add_child(bond_next)
	chapter_box = VBoxContainer.new()
	chapter_box.add_theme_constant_override("separation", 6)
	bond_box.add_child(chapter_box)
	for index in 3:
		var row := BoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := _label("", 18)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var claim := _action(row, "領取", _claim.bind(index))
		var memory := _action(row, "回憶", _memory.bind(index))
		memory.tooltip_text = "重溫此章羈絆 CG"
		memory.visible = false
		chapter_box.add_child(row)
		chapter_rows.append({"row": row, "info": info, "claim": claim, "memory": memory, "id": ""})
	reunion_box = BoxContainer.new()
	reunion_box.add_theme_constant_override("separation", 8)
	bond_box.add_child(reunion_box)
	reunion_label = _label(REUNION_LINE, 18)
	reunion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reunion_box.add_child(reunion_label)
	reunion_button = _action(reunion_box, "重逢", _reunion)
	recruit_box = BoxContainer.new()
	recruit_box.add_theme_constant_override("separation", 8)
	bond_box.add_child(recruit_box)
	recruit_label = _label("尚未招募。", 18)
	recruit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recruit_box.add_child(recruit_label)
	recruit_button = _action(recruit_box, "招募", _recruit)
	bond_feedback = _label("", 18)
	bond_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bond_box.add_child(bond_feedback)
	minimum_size_changed.connect(func(): _fit_bounds.call_deferred())
	_sync_view()
	show_mode("person")

func _label(value: String, font_size: int, decorative: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	if decorative: label.add_theme_font_override("font", UiTypography.character_title_font())
	if decorative: label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label

func _head(value: String) -> Label:
	var label := _label(value, 20)
	label.add_theme_font_override("font", UiTypography.emphasis_font())
	return label

func _page(key: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = key
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	return scroll

func _action(parent: BoxContainer, value: String, handler: Callable) -> InscriptionAction:
	var button := InscriptionAction.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button

func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll

func _image(path: String) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not path.is_empty(): image.texture = load(path)
	return image

func show_mode(value: String) -> void:
	if value not in MODES: return
	if mode != value: _clear_feedback()
	mode = value
	if mode == "meeting" and _has_art(): _load_meeting()
	_sync()

func select_maid(value: String) -> void:
	if value not in MAID_ORDER or value == selected_maid: return
	selected_maid = value
	_duty_choice = ""
	_option_signature = ""
	_last_duty_target = -1
	selected_reply = -1
	_clear_feedback()
	if line != null: line.text = _opening()
	_sync_view()

func refresh(view: Dictionary) -> void:
	_maid_view = _as_dict(view.get("maid", {}))
	if column == null: return
	_sync_view()

func show_result(text: String) -> void:
	if feedback == null: return
	feedback.text = text
	feedback.tooltip_text = text
	bond_feedback.text = text
	bond_feedback.tooltip_text = text
	_sync()

func _clear_feedback() -> void:
	if feedback == null: return
	feedback.text = ""
	feedback.tooltip_text = ""
	bond_feedback.text = ""
	bond_feedback.tooltip_text = ""

func open_art() -> void:
	if not _has_art() or portrait_image.texture == null: return
	portrait_requested.emit(portrait_image.texture, _maid_name(_maid_entry()))

func back() -> bool:
	if mode == "person": return false
	show_mode("person")
	tabs.person.grab_focus()
	return true

func reply(index: int) -> void:
	var replies := _replies()
	if index < 0 or index >= replies.size(): return
	selected_reply = index
	line.text = String(replies[index])
	line_scroll.scroll_vertical = 0
	_sync()
	replay.grab_focus()

func restart_meeting() -> void:
	selected_reply = -1
	line.text = _opening()
	line_scroll.scroll_vertical = 0
	_sync()
	choices.get_child(0).grab_focus()

func _as_dict(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return raw
	return {}

func _as_array(raw: Variant) -> Array:
	if raw is Array:
		return raw
	return []

func _maid_entry() -> Dictionary:
	var maids := _as_dict(_maid_view.get("maids", {}))
	return _as_dict(maids.get(selected_maid, {}))

func _maid_name(entry: Dictionary) -> String:
	var value := String(entry.get("name", ""))
	if not value.is_empty(): return value
	return String(MAID_NAMES.get(selected_maid, selected_maid))

func _maid_role(entry: Dictionary) -> String:
	var value := String(entry.get("role", ""))
	if value.is_empty(): return String(MAID_ROLES.get(selected_maid, "侍女"))
	if value.length() > 2: return value.right(2)
	return value

func _story() -> Dictionary:
	return _as_dict(STORIES.get(selected_maid, STORIES.get("qingheng", {})))

func _art() -> Dictionary:
	return _as_dict(ART.get(selected_maid, {}))

func _art_path(key: String) -> String:
	return String(_art().get(key, ""))

func _choice_labels() -> Array:
	return _as_array(_story().get("choices", []))

func _replies() -> Array:
	return _as_array(_story().get("replies", REPLIES))

func _opening() -> String:
	return String(_story().get("opening", OPENING))

func _has_art() -> bool:
	var entry := _maid_entry()
	if entry.is_empty(): return ART.has(selected_maid)
	return bool(entry.get("art_ready", ART.has(selected_maid)))

func _load_portrait() -> void:
	if _portrait_id == selected_maid: return
	_portrait_id = selected_maid
	var path := _art_path("portrait")
	portrait_image.texture = load(path) if not path.is_empty() else null

func _load_meeting() -> void:
	_meeting_id = selected_maid
	var path := _art_path("meeting")
	meeting_image.texture = load(path) if not path.is_empty() else null

func _sync_story(entry: Dictionary) -> void:
	var story := _story()
	bio_role_label.text = String(story.get("role_note", ""))
	bio_quote_label.text = String(story.get("quote", ""))
	bio_text_label.text = String(story.get("bio", ""))
	var tags := PackedStringArray()
	for tag in _as_array(story.get("tags", [])):
		tags.append(String(tag))
	bio_tags_label.text = "　·　".join(tags)
	bio_closing_label.text = String(story.get("closing", ""))
	seal.text = String(story.get("seal", ""))
	var scene := String(story.get("scene", ""))
	speaker.text = ("%s · %s" % [_maid_name(entry), scene]) if not scene.is_empty() else _maid_name(entry)

func _sync_choices() -> void:
	var labels := _choice_labels()
	for index in choice_buttons.size():
		var button: InscriptionAction = choice_buttons[index]
		button.text = String(labels[index]) if index < labels.size() else ""

func _duty() -> Dictionary:
	var duty := _as_dict(_maid_entry().get("duty", {}))
	if duty.is_empty(): return {}
	if String(duty.get("kind", "")) != String(DUTY_KINDS.get(selected_maid, "")): return {}
	return duty

func _vertical(value: String) -> String:
	var chars := PackedStringArray()
	for index in value.length():
		chars.append(value[index])
	return "\n".join(chars)

func _reason_text(code: String) -> String:
	var texts := _as_dict(RECRUIT_TEXTS.get(selected_maid, {}))
	if not code.is_empty() and texts.has(code):
		return String(texts[code])
	if code.is_empty(): return "條件尚未足"
	return String(REASONS.get(code, code))

func _sync_view() -> void:
	if column == null: return
	var entry := _maid_entry()
	var display_name := _maid_name(entry)
	role_label.text = _vertical(_maid_role(entry))
	name_label.text = _vertical(display_name)
	_load_portrait()
	if mode == "meeting" or not _meeting_id.is_empty(): _load_meeting()
	_sync_story(entry)
	_sync_choices()
	portrait_button.tooltip_text = "查看完整立繪" if _has_art() else "立繪尚未完成"
	portrait_button.accessibility_name = ("查看%s完整立繪" % display_name) if _has_art() else ("%s立繪尚未完成" % display_name)
	_sync_work(entry)
	_sync_bond(entry)
	_sync()

func _sync_work(entry: Dictionary) -> void:
	var display_name := _maid_name(entry)
	var duty := _duty()
	var recruited := bool(entry.get("recruited", false))
	var plain := String(DUTY_PLAIN.get(selected_maid, "職掌"))
	if duty.is_empty():
		var tail := "・尚未招募"
		if recruited: tail = "・已執行 %d 次" % int(entry.get("duty_actions", 0))
		work_status.text = "%s（%s）・尚未指派%s" % [display_name, plain, tail]
	else:
		var status := String(duty.get("status_text", ""))
		if status.is_empty():
			var code := String(duty.get("status", "RUNNING"))
			status = code
			if code == "RUNNING": status = "運作中"
			elif code == "TARGET_REACHED": status = "已達目標"
		var count := "・累計 %d 次" % int(entry.get("duty_actions", 0))
		var cooldown := int(duty.get("cooldown", 0))
		if cooldown > 0: count += "・倒數 %d 秒" % cooldown
		work_status.text = "%s（%s）・%s%s" % [display_name, plain, status, count]
	var active := String(_maid_view.get("active_duty", ""))
	if active.is_empty():
		work_owner.text = "目前沒有生效中的職掌。"
	else:
		var active_name := String(MAID_NAMES.get(active, active))
		var note := "（就是眼前這位）" if active == selected_maid else "；同一時間只能有一位仙侍值守"
		work_owner.text = "生效中：%s%s" % [active_name, note]
	_fill_options(entry, duty)
	duty_target.visible = String(DUTY_KINDS.get(selected_maid, "")) in TARGET_DUTIES
	_update_actions_state(recruited, duty)

func _options(entry: Dictionary) -> Array:
	var options := _as_dict(entry.get("options", {}))
	return _as_array(options.get(String(OPTION_FIELDS.get(selected_maid, "")), []))

func _fill_options(entry: Dictionary, duty: Dictionary) -> void:
	var options := _options(entry)
	var signature := ""
	for option in options:
		var id := String(_as_dict(option).get("id", ""))
		if not id.is_empty(): signature += id + "|"
	if signature != _option_signature:
		_option_signature = signature
		_duty_ids.clear()
		duty_picker.clear()
		for option in options:
			var item := _as_dict(option)
			var id := String(item.get("id", ""))
			if id.is_empty(): continue
			_duty_ids.append(id)
			duty_picker.add_item(String(item.get("name", id)))
	var preferred := String(duty.get(String(DUTY_FIELDS.get(selected_maid, "")), ""))
	if _duty_choice.is_empty() or not _duty_ids.has(_duty_choice):
		if _duty_ids.has(preferred):
			_duty_choice = preferred
		elif not _duty_ids.is_empty():
			_duty_choice = String(_duty_ids[0])
		else:
			_duty_choice = ""
	var index := _duty_ids.find(_duty_choice)
	if index >= 0:
		if duty_picker.selected != index: duty_picker.select(index)
		duty_picker.tooltip_text = duty_picker.get_item_text(index)
	var wanted := -1.0
	if not duty.is_empty() and duty.has("target"):
		wanted = clampf(float(duty.get("target", 1)), 1.0, 999.0)
		if wanted != float(_last_duty_target) and not duty_target.has_focus():
			duty_target.value = wanted
	_last_duty_target = int(wanted)
	duty_hint.text = "尚無可用目標"
	duty_hint.visible = _duty_ids.is_empty()
	duty_picker.visible = not _duty_ids.is_empty()

func _update_actions_state(recruited: bool, duty: Dictionary) -> void:
	var has_options := not _duty_ids.is_empty()
	assign_button.disabled = not recruited or not has_options or _chosen_id().is_empty()
	var assign_note := "以所選目標指派%s。" % String(DUTY_PLAIN.get(selected_maid, "職掌"))
	if not recruited:
		assign_note = "尚未招募，無法指派職掌。"
	elif not has_options:
		assign_note = "尚無可用目標；需先有可指派的配方、建築或丹藥。"
	assign_button.tooltip_text = assign_note
	var paused := bool(duty.get("paused", false))
	pause_button.disabled = duty.is_empty()
	pause_button.text = "恢復" if paused else "暫停"
	pause_button.tooltip_text = "恢復此職掌的推進節奏。" if paused else "暫停此職掌，進行中的批次不回收。"
	execute_button.disabled = duty.is_empty()
	execute_button.tooltip_text = "立即執行一次有界動作，忽略冷卻。"
	clear_button.disabled = duty.is_empty()
	clear_button.tooltip_text = "清除工作設定，保留累計次數。"

func _update_actions() -> void:
	var entry := _maid_entry()
	_update_actions_state(bool(entry.get("recruited", false)), _duty())

func _chosen_id() -> String:
	var index := duty_picker.selected
	if index >= 0 and index < _duty_ids.size(): return String(_duty_ids[index])
	if _duty_ids.has(_duty_choice): return _duty_choice
	return ""

func _on_option_selected(index: int) -> void:
	if index < 0 or index >= _duty_ids.size(): return
	_duty_choice = String(_duty_ids[index])
	_update_actions()

func _sync_bond(entry: Dictionary) -> void:
	var recruited := bool(entry.get("recruited", false))
	var bond_name := String(entry.get("bond_name", ""))
	if bond_name.is_empty(): bond_name = "初識"
	var points := int(entry.get("bond", 0))
	bond_status.text = "%s・%s　%d 點" % [_maid_name(entry), bond_name, points]
	var next_at := int(entry.get("next_bond_at", -1))
	if next_at >= 0:
		var next_name := String(entry.get("next_bond_name", ""))
		bond_next.text = "下一階段：%s（%d 點）" % [next_name if not next_name.is_empty() else "未名", next_at]
	else:
		bond_next.text = "已達最高羈絆。"
	var chapters := _as_array(entry.get("chapters", []))
	for index in chapter_rows.size():
		var row_data: Dictionary = chapter_rows[index]
		var row: BoxContainer = row_data["row"]
		var info: Label = row_data["info"]
		var claim: InscriptionAction = row_data["claim"]
		var memory: InscriptionAction = row_data["memory"]
		if index >= chapters.size():
			row.visible = false
			memory.visible = false
			row_data["id"] = ""
			continue
		var chapter := _as_dict(chapters[index])
		var claimed := bool(chapter.get("claimed", false))
		var can_claim := bool(chapter.get("can_claim", false))
		var chapter_id := String(chapter.get("id", ""))
		row_data["id"] = chapter_id
		row.visible = recruited
		info.visible = recruited
		var state := _reason_text(String(chapter.get("reason", "")))
		if claimed: state = "已領取"
		elif can_claim: state = "可領取"
		info.text = "%s・+%d 點・%s" % [String(chapter.get("title", chapter_id)), int(chapter.get("bond", 0)), state]
		claim.visible = recruited and can_claim
		claim.disabled = not can_claim
		var final_chapter := index == chapters.size() - 1
		memory.visible = recruited and claimed and final_chapter
		memory.disabled = not memory.visible
	reunion_box.visible = recruited and bool(entry.get("reunion_pending", false))
	recruit_box.visible = not recruited
	var recruit := _as_dict(entry.get("recruit", {}))
	var can := bool(recruit.get("can", false))
	var ready := "條件已足，可招募 %s。" % _maid_name(entry)
	recruit_label.text = ready if can else _reason_text(String(recruit.get("reason", "")))
	recruit_button.disabled = not can

func _sync() -> void:
	if column == null: return
	var art := _has_art()
	person.visible = mode == "person"
	maid_row.visible = mode != "meeting" or not _compact
	meeting.visible = mode == "meeting"
	work.visible = mode == "work"
	bond.visible = mode == "bond"
	if mode == "person":
		title.text = "%s · %s" % [_maid_role(_maid_entry()), _maid_name(_maid_entry())]
	elif mode == "meeting":
		var scene := String(_story().get("scene", ""))
		title.text = ("初遇 · %s" % scene) if art and not scene.is_empty() else "初遇 · 尚未補完"
	elif mode == "work":
		title.text = "職掌 · %s" % _maid_name(_maid_entry())
	else:
		title.text = "羈絆 · %s" % _maid_name(_maid_entry())
	for key in tabs:
		tabs[key].set_pressed_no_signal(key == mode)
		tabs[key]._update_style()
	var maids := _as_dict(_maid_view.get("maids", {}))
	for id in maid_buttons:
		var recruited := bool(_as_dict(maids.get(id, {})).get("recruited", false))
		maid_buttons[id].tooltip_text = "" if recruited else "尚未招募 · 可先閱覽人物與初遇"
		maid_buttons[id].set_pressed_no_signal(id == selected_maid)
		maid_buttons[id]._update_style()
	portrait_image.visible = art
	portrait_placeholder.visible = not art
	portrait_button.disabled = not art
	seal.visible = art and not _compact
	bookmark.visible = art
	bio_placeholder.visible = not art
	meeting_image.visible = art
	missing_meeting.visible = not art
	dialogue.visible = art
	choices.visible = art and selected_reply < 0
	replay.visible = art and selected_reply >= 0
	var active := String(_maid_view.get("active_duty", ""))
	work_owner.visible = not _compact or not active.is_empty()
	feedback.visible = mode == "work" and not feedback.text.is_empty()
	bond_feedback.visible = mode == "bond" and not bond_feedback.text.is_empty()

func _assign() -> void:
	var option_id := _chosen_id()
	if option_id.is_empty(): return
	var duty := {}
	match selected_maid:
		"qingheng": duty = {"kind": "steward_stock", "recipe_id": option_id, "target": int(duty_target.value), "reserve": {}}
		"nuomeizi": duty = {"kind": "oversee_build", "building_id": option_id}
		"danxia": duty = {"kind": "restock_pills", "pill_id": option_id, "target": int(duty_target.value), "reserve": {}}
		_: return
	action_requested.emit("assign_maid_duty", {"maid_id": selected_maid, "duty": duty})

func _toggle_pause() -> void:
	var duty := _duty()
	if duty.is_empty(): return
	action_requested.emit("set_maid_duty_paused", {"maid_id": selected_maid, "paused": not bool(duty.get("paused", false))})

func _execute() -> void:
	if _duty().is_empty(): return
	action_requested.emit("execute_maid_duty", {"maid_id": selected_maid})

func _clear() -> void:
	if _duty().is_empty(): return
	action_requested.emit("clear_maid_duty", {"maid_id": selected_maid})

func _claim(index: int) -> void:
	if index < 0 or index >= chapter_rows.size(): return
	var row_data: Dictionary = chapter_rows[index]
	var chapter_id := String(row_data.get("id", ""))
	if chapter_id.is_empty(): return
	action_requested.emit("claim_maid_chapter", {"maid_id": selected_maid, "chapter_id": chapter_id})

func _memory(index: int) -> void:
	if index != chapter_rows.size() - 1: return
	var chapters := _as_array(_maid_entry().get("chapters", []))
	if index >= chapters.size(): return
	if not bool(_as_dict(chapters[index]).get("claimed", false)): return
	var def: Dictionary = BOND_CG.get(selected_maid, {})
	var path := String(def.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path): return
	var texture := load(path) as Texture2D
	if texture == null: return
	memory_requested.emit(texture, "%s · %s" % [_maid_name(_maid_entry()), String(def.get("title", ""))], _as_array(def.get("lines", [])))

func _reunion() -> void:
	action_requested.emit("maid_reunion", {"maid_id": selected_maid})

func _recruit() -> void:
	var recruit := _as_dict(_maid_entry().get("recruit", {}))
	if not bool(recruit.get("can", false)): return
	action_requested.emit("recruit_maid", {"maid_id": selected_maid})

func set_layout_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	position = bounds.position
	size = bounds.size
	if column == null: return
	_compact = bounds.size.y < 400 or bounds.size.x < 960
	var paper := UiMaterial.hud_paper()
	paper.content_margin_top = 4 if _compact else 10
	paper.content_margin_bottom = 4 if _compact else 10
	add_theme_stylebox_override("panel", paper)
	var frame: StyleBoxFlat = portrait_frame.get_theme_stylebox("panel").duplicate()
	frame.set_content_margin_all(4 if _compact else 12)
	portrait_frame.add_theme_stylebox_override("panel", frame)
	column.add_theme_constant_override("separation", 4 if _compact else 10)
	name_column.vertical = not _compact
	name_column.custom_minimum_size.x = 44 if _compact else 72
	person.add_theme_constant_override("separation", 12 if _compact else 24)
	portrait_frame.size_flags_stretch_ratio = 0.85 if _compact else 1.3
	role_label.visible = not _compact
	name_label.add_theme_font_size_override("font_size", 28 if _compact else 60)
	seal.visible = not _compact and _has_art()
	meeting.vertical = not _compact
	dialogue.vertical = _compact
	dialogue.add_theme_constant_override("separation", 4 if _compact else 18)
	speaker.visible = not _compact
	choices.vertical = not _compact
	meeting_image.size_flags_stretch_ratio = 0.8 if _compact else 1.0
	dialogue.size_flags_stretch_ratio = 1.2 if _compact else 1.0
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL if _compact else Control.SIZE_FILL
	line_scroll.custom_minimum_size.y = 0 if _compact else 64
	maid_row.add_theme_constant_override("separation", 2 if _compact else 6)
	_copy_scroll_layout()
	work_box.add_theme_constant_override("separation", 4 if _compact else 10)
	bond_box.add_theme_constant_override("separation", 4 if _compact else 10)
	action_row.vertical = _compact
	_apply_field_layout()
	for row_data in chapter_rows:
		var row: BoxContainer = row_data["row"]
		row.vertical = _compact
		row.add_theme_constant_override("separation", 2 if _compact else 8)
	reunion_box.vertical = _compact
	recruit_box.vertical = _compact
	reunion_box.add_theme_constant_override("separation", 2 if _compact else 8)
	recruit_box.add_theme_constant_override("separation", 2 if _compact else 8)
	_compact_labels()
	title.visible = not _compact
	_sync()
	_fit_bounds.call_deferred()

func _copy_scroll_layout() -> void:
	copy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_box.add_theme_constant_override("separation", 6 if _compact else 18)

func _apply_field_layout() -> void:
	duty_picker.custom_minimum_size = Vector2(140 if _compact else 220, 44)
	duty_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duty_target.custom_minimum_size = Vector2(110 if _compact else 140, 44)
	work_fields.vertical = _compact
	work_fields.add_theme_constant_override("separation", 4 if _compact else 8)

func _compact_labels() -> void:
	var heading_size := 18 if _compact else 20
	var body_size := 18
	work_status.add_theme_font_size_override("font_size", body_size)
	work_owner.add_theme_font_size_override("font_size", body_size)
	duty_hint.add_theme_font_size_override("font_size", body_size)
	bond_status.add_theme_font_size_override("font_size", body_size)
	bond_next.add_theme_font_size_override("font_size", body_size)
	reunion_label.add_theme_font_size_override("font_size", body_size)
	recruit_label.add_theme_font_size_override("font_size", body_size)
	feedback.add_theme_font_size_override("font_size", body_size)
	bond_feedback.add_theme_font_size_override("font_size", body_size)
	work_heading.add_theme_font_size_override("font_size", heading_size)
	bond_heading.add_theme_font_size_override("font_size", heading_size)
	for row_data in chapter_rows:
		(row_data["info"] as Label).add_theme_font_size_override("font_size", body_size)

func _fit_bounds() -> void:
	if not _bounds.has_area(): return
	if size != _bounds.size: size = _bounds.size