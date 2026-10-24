extends VBoxContainer
## Skills-only presentation. Values and eligibility come from the Session view.
signal action_requested(kind: String, id: String)
const ART_DIR := "res://assets/ui/skills-painted/"
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
var buttons: Dictionary = {}
var cards: Dictionary = {}
var heading: Label
var source: Label
var hero: TextureRect
var scroll: ScrollContainer
var grid: GridContainer
var compact := false
var _heading_full := ""
var _heading_short := ""
var feedback_message := ""

func set_feedback(message: String) -> void:
	feedback_message = message
	_layout()

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	add_child(top)
	hero = _art("study_scroll", 64)
	top.add_child(hero)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	heading = _label("研習卷冊 · 技能點 0 / 200", 20)
	info.add_child(heading)
	source = _label("藏經閣產點 · 經書殿擴容 · 當世選修，輪迴重置")
	info.add_child(source)
	var study := Button.new()
	study.text = "經營建築"
	study.tooltip_text = "前往建造／升級藏經閣與經書殿；技能為選修，不限制空島或配方。"
	study.custom_minimum_size = Vector2(112, 44)
	UiMaterial.apply_button(study)
	study.pressed.connect(func(): action_requested.emit("study", ""))
	top.add_child(study)
	buttons["study:"] = study
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	resized.connect(_layout)

func _label(value: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	return label

func _art(id: String, edge: int) -> TextureRect:
	var art := UiIllustration.new()
	art.custom_minimum_size = Vector2.ONE * edge
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(ART_DIR + id + ".png"):
		art.texture = load(ART_DIR + id + ".png")
	return art

func _card(item: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	grid.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var art := _art(item.id, 112)
	row.add_child(art)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var title := _label("", 18)
	info.add_child(title)
	var scope := _label("", 15)
	info.add_child(scope)
	var effect := _label("")
	info.add_child(effect)
	var cost := _label("")
	info.add_child(cost)
	var action := Button.new()
	action.custom_minimum_size = Vector2(112, 44)
	UiMaterial.apply_button(action)
	action.pressed.connect(func(): action_requested.emit("skill", item.id))
	row.add_child(action)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons["skill:" + item.id] = action
	cards[item.id] = {"card":card, "art":art, "title":title, "scope":scope, "effect":effect, "cost":cost, "action":action}

func refresh(view: Dictionary) -> void:
	var data: Dictionary = view.get("skills", {})
	var points := "%s / %s" % [NumberFormatter.format_amount(data.get("available", "0")), NumberFormatter.format_amount(view.get("resources", {}).get("skill_point", {}).get("cap", "200"))]
	_heading_full = "研習卷冊 · 技能點 " + points
	_heading_short = "技能點 " + points + (" · 藏經閣產點" if data.get("opened", false) else " · 研習未開")
	heading.tooltip_text = _heading_full + "\n築基後建藏經閣產點，經書殿擴容；當世選修，輪迴重置。"
	source.text = "藏經閣產點 · 經書殿擴容 · 當世選修，輪迴重置" if data.get("opened", false) else "築基並建藏經閣後開放 · 經書殿擴容 · 輪迴重置"
	for item in data.get("items", []):
		if not cards.has(item.id): _card(item)
		var row: Dictionary = cards[item.id]
		row.title.text = "%s · %d/%d" % [item.name, item.level, item.max_level]
		var scope_text := String(item.get("scope", ""))
		var scope_note := String(item.get("scope_note", ""))
		row.scope.text = "" if scope_text.is_empty() else "作用：" + scope_text + (" · " + scope_note if not scope_note.is_empty() else "")
		row.scope.visible = not scope_text.is_empty()
		row.effect.text = item.get("current_effect", item.description)
		if item.level < item.max_level:
			row.effect.text += "\n下階：" + item.get("next_effect", item.description)
		row.effect.tooltip_text = item.description if scope_text.is_empty() else item.description + "\n作用：" + scope_text + ("\n" + scope_note if not scope_note.is_empty() else "")
		row.cost.text = "每階 %s 技能點" % item.cost
		row.action.text = {"SKILL_STUDY_LOCKED":"研習未開", "SKILL_ERA_LOCKED":"境界未達", "SKILL_PREREQ_LOCKED":"前置未足", "SKILL_MAX_LEVEL":"已滿級", "INSUFFICIENT_SKILL_POINT":"點數不足"}.get(item.reason, "研習")
		row.action.disabled = not item.can_learn
		row.action.tooltip_text = "築基並建藏經閣後開放" if item.reason == "SKILL_STUDY_LOCKED" else "境界晉升至結丹期後可研習" if item.reason == "SKILL_ERA_LOCKED" else "前置技能未達門檻" if item.reason == "SKILL_PREREQ_LOCKED" else item.description
	_layout()

func _layout() -> void:
	if grid == null: return
	compact = size.y < 340
	add_theme_constant_override("separation", 2 if compact else 6)
	grid.columns = 2 if size.x >= 1000 else 1
	hero.visible = not compact
	source.visible = not compact
	heading.text = _heading_short if compact else _heading_full
	if compact and not feedback_message.is_empty():
		heading.text = _heading_short.get_slice(" · ", 0) + " · " + feedback_message
		heading.tooltip_text = _heading_full + "\n藏經閣產點 · 經書殿擴容\n" + feedback_message
	heading.add_theme_font_size_override("font_size", 18 if compact else 20)
	for row in cards.values():
		row.art.custom_minimum_size = Vector2.ONE * (80 if compact else 112)
