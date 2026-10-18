extends VBoxContainer
## Presentation only: all costs, eligibility and effects come from Session.
signal action_requested(kind: String, id: String)
const ART_DIR := "res://assets/ui/decisions-painted/"
const ResourceIcon = preload("res://src/presentation/resource_icon.gd")
var buttons: Dictionary = {}
var cards: Dictionary = {}
var heading: Label
var scroll: ScrollContainer
var grid: GridContainer
var compact := false
var _realm := ""

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	heading = _label("界域法令", 20)
	add_child(heading)
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

func _card(item: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	grid.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(ART_DIR + str(item.id) + ".png"):
		art.texture = load(ART_DIR + str(item.id) + ".png")
	row.add_child(art)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var title := _label(str(item.name), 18)
	title.tooltip_text = str(item.description)
	info.add_child(title)
	var effect := _label("")
	info.add_child(effect)
	var costs := VBoxContainer.new()
	info.add_child(costs)
	var cost_rows: Array = []
	for id in item.get("costs", {}):
		var line := HBoxContainer.new()
		costs.add_child(line)
		var icon := ResourceIcon.new()
		icon.resource_id = str(id)
		line.add_child(icon)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.custom_minimum_size = Vector2(24, 24)
		var value := _label("")
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(value)
		cost_rows.append({"id":str(id), "need":float(item.costs[id]), "icon":icon, "label":value})
	var state := _label("")
	info.add_child(state)
	var action := Button.new()
	action.text = "施行"
	action.custom_minimum_size = Vector2(80, 44)
	action.size_flags_vertical = Control.SIZE_SHRINK_END
	UiMaterial.apply_button(action)
	action.pressed.connect(func(): action_requested.emit("decision", str(item.id)))
	row.add_child(action)
	buttons["decision:" + str(item.id)] = action
	cards[item.id] = {"card":card, "art":art, "title":title, "effect":effect, "costs":cost_rows, "state":state, "action":action}

func refresh(view: Dictionary) -> void:
	var realm: String = str(view.get("realm", {}).get("current_realm", "realm_human"))
	var items: Array = view.get("realm_decisions", [])
	var ids: Array = []
	for item in items: ids.append(str(item.id))
	for id in cards.keys():
		if id not in ids:
			grid.remove_child(cards[id].card)
			cards[id].card.queue_free()
			cards.erase(id)
			buttons.erase("decision:" + str(id))
	if _realm != realm:
		scroll.scroll_vertical = 0
		_realm = realm
	var realm_name: String = {"realm_human":"人界", "realm_spirit":"靈界"}.get(realm, realm)
	heading.text = "界域法令 · " + realm_name
	heading.tooltip_text = "目前所在界域；決策不會因預覽其他界域而解鎖。"
	for item in items:
		if not cards.has(item.id): _card(item)
		var row: Dictionary = cards[item.id]
		row.title.text = str(item.name)
		row.title.tooltip_text = str(item.description)
		row.effect.text = _effects(item.get("effects", {}), view.get("resources", {}))
		row.effect.tooltip_text = row.effect.text
		var buff_id: String = str(item.get("effects", {}).get("buff_id", ""))
		if BuffSystem.DEFINITIONS.has(buff_id):
			var buff: Dictionary = BuffSystem.DEFINITIONS[buff_id]
			row.effect.tooltip_text += "\n%s · 持續 %ds" % [buff.description, int(buff.default_duration)]
		for cost in row.costs:
			var key := RealmDecisionSystem.resource_key(view.get("resources", {}), cost.id)
			cost.icon.resource_id = key
			var available: String = str(view.get("resources", {}).get(key, {}).get("value", "0"))
			var need := AmountCompat.from_number(cost.need)
			var name: String = str({"wood":"靈木", "money":"金錢", "lingli":"靈力", "spirit_grass_low":"靈草"}.get(key, key))
			var parsed := AmountCompat.try_parse(available)
			var owned: AmountCompat = parsed.value if parsed.get("ok", false) else AmountCompat.zero()
			cost.label.text = "%s / %s" % [owned.to_display_string(), need.to_display_string()]
			if not ResourceIcon.TEXTURES.has(key): cost.label.text = name + " " + cost.label.text
			cost.label.tooltip_text = "%s：持有 %s / 需求 %s" % [name, available, need.serialize()]
			var enough := owned.compare_to(need) >= 0
			cost.label.add_theme_color_override("font_color", UiMaterial.INK if enough else Color("963e32"))
			if cost.id == "lifespan_seconds":
				cost.icon.hide()
				cost.label.text = "壽元消耗 %s 秒" % need.to_display_string()
				cost.label.tooltip_text = "增加已用壽元，沿現有規則結算。"
		var cd := float(item.get("cooldown_remaining", 0))
		row.state.text = "需第 %d 境" % int(item.get("min_era", 1)) if not item.get("era_met", false) else "冷卻 %ds" % int(ceil(cd)) if cd > 0 else "資糧不足" if not item.get("costs_met", false) else "就緒"
		if int(item.get("usage_count", 0)) > 0:
			row.state.text += " · 已施行 %d 次" % int(item.usage_count)
		row.state.tooltip_text = "每次施行後冷卻 %ds" % int(item.get("cooldown_seconds", 0))
		row.action.disabled = not bool(item.get("is_ready", false))
		row.action.tooltip_text = row.state.text + "；" + row.state.tooltip_text
	_layout()

func _effects(effects: Dictionary, resources: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("training_seconds"): parts.append("修煉 +%ss" % effects.training_seconds)
	if effects.has("dao_heart_bonus"): parts.append("道心 +%s" % effects.dao_heart_bonus)
	for id in effects.get("resources", {}):
		var key := RealmDecisionSystem.resource_key(resources, str(id))
		var name: String = {"lingli":"靈力", "spirit_grass_low":"靈草", "spirit_crystal":"極品靈晶"}.get(key, key)
		parts.append("%s +%s" % [name, effects.resources[id]])
	if effects.has("buff_id"):
		var config: Dictionary = BuffSystem.DEFINITIONS.get(effects.buff_id, {})
		parts.append(str(config.get("name", effects.buff_id)))
	return " · ".join(parts)

func _layout() -> void:
	if grid == null: return
	compact = size.y < 340
	grid.columns = 2 if size.x >= 1000 else 1
	for row in cards.values():
		row.art.custom_minimum_size = Vector2.ONE * (80 if compact else 112)
