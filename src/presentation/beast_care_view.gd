extends VBoxContainer
## Persistent controls: cooldown and inventory refresh never replace a pressed button.
signal action_requested(kind: String, id: String)
const ART := "res://assets/ui/beasts-painted/"
var buttons: Dictionary = {}
var cards: Dictionary = {}
var scroll: ScrollContainer
var grid: GridContainer
var heading: Label
var compact := false

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	heading = label("本世僅能結契一獸，不能放生或更換；成熟後輪迴才得同種獸魂。")
	add_child(heading)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for id in BeastSystem.BEAST_CONFIGS: make_card(id)
	resized.connect(layout)
	layout()

func label(value: String, font_size: int = 16) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	return node

func art(id: String, edge: int) -> Control:
	if ResourceLoader.exists(ART+id+".png"):
		var image := UiIllustration.new()
		image.texture = load(ART+id+".png")
		image.custom_minimum_size = Vector2.ONE * edge
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return image
	var seal := label(String(BeastSystem.BEAST_CONFIGS[id].name), 18)
	seal.custom_minimum_size = Vector2(64,44)
	seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return seal

func action(parent: Node, kind: String, id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(112,44)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiMaterial.apply_button(button)
	button.pressed.connect(func(): action_requested.emit(kind,id))
	parent.add_child(button)
	buttons[kind+":"+id] = button
	return button

func make_card(id: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",UiMaterial.hud_paper())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(card)
	var body := VBoxContainer.new()
	card.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	body.add_child(row)
	var image := art(id,112)
	row.add_child(image)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title := label("",18)
	info.add_child(title)
	var detail := label("")
	info.add_child(detail)
	var cost := label("")
	info.add_child(cost)
	var acquire := action(row,"acquire",id)
	var feed := action(row,"feed",id)
	# The public feed alias is kept for existing navigation/command consumers.
	var talents := {}
	for tid in BeastSystem.BEAST_TALENTS:
		var t: Dictionary = BeastSystem.BEAST_TALENTS[tid]
		if t.beast_id != id: continue
		var tr := HBoxContainer.new()
		body.add_child(tr)
		if id in BeastSystem.P2_IDS: tr.add_child(art(id,44))
		var desc := label("")
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.add_child(desc)
		var learn := action(tr,"talent",tid)
		talents[tid] = {"desc":desc,"button":learn}
	cards[id] = {"card":card,"art":image,"title":title,"detail":detail,"cost":cost,"acquire":acquire,"feed":feed,"talents":talents}

func layout() -> void:
	if grid == null: return
	compact = size.y < 350
	# A full beast includes four talent rows; keep each card readable in one column.
	grid.columns = 1
	for id in cards:
		var c: Dictionary = cards[id]
		if c.art is TextureRect: c.art.custom_minimum_size = Vector2.ONE * (80 if compact else 112)
		c.card.custom_minimum_size.x = 0

func refresh(view: Dictionary) -> void:
	var data: Dictionary = view.get("beast",{})
	var active: Dictionary = data.get("active",{})
	var active_id: String = active.get("id", "")
	buttons.erase("feed:")
	for id in cards:
		var c: Dictionary = cards[id]
		var config: Dictionary = BeastSystem.BEAST_CONFIGS[id]
		var current: bool = id == active_id
		c.title.text = "%s · %s · 同種獸魂 %d" % [config.name, "本世結契" if current else "第%d境" % config.unlock_era, int(data.get("souls",{}).get(id,0))]
		var req: Dictionary = data.get("acquire_requirements",{}).get(id,{"ok":false})
		c.acquire.visible = not current
		c.acquire.disabled = not bool(req.get("ok",false))
		c.acquire.text = "結契" if req.get("ok",false) else requirement_text(req)
		c.acquire.tooltip_text = "本世僅能結契一獸，不能放生或更換。\n"+config.desc
		c.feed.visible = current
		c.feed.disabled = not bool(data.get("can_feed",false))
		c.feed.text = "餵養靈獸" if data.get("can_feed",false) else String(data.get("feed_reason","不可餵食"))
		if current: buttons["feed:"] = c.feed
		var stage: String = active.get("stage","egg") if current else "egg"
		var effect: String = config.desc
		if current and id not in BeastSystem.P2_IDS:
			effect += "\n%s · 累積XP %d / 1000" % [BeastSystem.STAGE_CONFIGS[stage].name,int(active.get("exp",0))]
		if id in BeastSystem.P2_IDS:
			var projection: Dictionary = data.get("care",{}).get(id,{})
			var scope := "寒銀島三礦" if id == "frost_stag" else "古藥島千年靈草"
			effect = "%s採集 +%s%%；永久地方容量 +%d" % [scope, str(snappedf(float(projection.get("rate_bonus",0))*100,0.01)), int(projection.get("capacity_bonus",0))]
			if current: effect += "\n%s · 累積XP %d / 1000 · 下次 +%dXP" % [BeastSystem.STAGE_CONFIGS[stage].name,int(active.get("exp",0)),int(projection.get("next_xp",50))]
			else: effect += "\n需當世第%d境及%s已開拓；成熟基礎 +20%%" % [config.unlock_era,"寒銀島" if id == "frost_stag" else "古藥島"]
		c.detail.text = effect
		var costs: Dictionary = data.get("care",{}).get(id,{}).get("costs",config.feed_resource)
		c.cost.text = "祖島餵料："+cost_text(costs)
		if current: c.cost.text += " · 冷卻 %d秒" % int(ceil(float(data.get("cooldown_remaining",0))))
		for talent in data.get("talents_view",[]):
			if talent.beast_id != id: continue
			var t: Dictionary = c.talents[talent.id]
			var description: String = talent.desc
			if id in BeastSystem.P2_IDS:
				match int(talent.tier):
					1: description = "幼獸 10→11%／成長 15→16%／成熟 20→21%；卵仍0"
					2: description = "每餵 50→65XP；成熟需20→16次手動餵養"
					3: description = "祖島每餵：精鐵10→6、靈草20→12" if id == "frost_stag" else "祖島每餵：百草5→3、千草2→1"
					4: description = "永久寒銀島各資源容量 +30；不加祖島" if id == "frost_stag" else "永久古藥島各資源容量 +30；不加祖島"
			t.desc.text = "T%d · %s\n%s" % [talent.tier,talent.name,description]
			t.button.disabled = not bool(talent.can_unlock)
			t.button.text = "已領悟" if talent.owned else "領悟 · %d魂" % int(talent.cost)
			t.button.tooltip_text = "支付同種獸魂；需已領悟前階。永久保留，無需本世持有該獸。\n"+talent.desc
	layout()

func requirement_text(req: Dictionary) -> String:
	return {"ALREADY_HAS_ACTIVE_BEAST":"本世已有靈獸","INSUFFICIENT_ERA":"境界未達","LIFESPAN_EXHAUSTED":"壽元已盡","BEAST_SAVE_REQUIRED":"需先保存","SUPPLY_REQUIRED":"需啟用供給","ISLAND_NOT_OPEN":"需先開島"}.get(req.get("error",""),"尚未開放")

func cost_text(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for id in costs:
		parts.append("%s %d" % [{"spirit_grass_low":"靈草","refined_iron":"精鐵","stone_low":"下品靈石","spirit_grass_100y":"百年靈草","spirit_grass_1000y":"千年靈草","void_essence":"虛空精華","star_metal":"星金"}.get(id,id),int(costs[id])])
	return "、".join(parts)
