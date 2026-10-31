extends VBoxContainer
## Persistent controls: cooldown and inventory refresh never replace a pressed button.
signal action_requested(kind: String, id: String)
const ART := "res://assets/ui/beasts-painted/"
const CostStrip = preload("res://src/presentation/cost_strip.gd")
const Icon = preload("res://src/presentation/resource_icon.gd")
var buttons: Dictionary = {}
var cards: Dictionary = {}
var scroll: ScrollContainer
var grid: GridContainer
var heading: Label
var compact := false
var tokens: Label
const GUARDIAN_ART := "res://assets/ui/beasts-painted/sect-reform/"

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	heading = label("本世僅能結契一獸，不能放生或更換；成熟後輪迴才得同種獸魂。")
	add_child(heading)
	tokens = label("")
	add_child(tokens)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for id in BeastSystem.BEAST_CONFIGS: make_card(id)
	for id in GuardianBeasts.SPECIES: make_card(id)
	resized.connect(layout)
	scroll.resized.connect(layout)
	layout()

func label(value: String, font_size: int = 16) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	return node

func art(id: String, edge: int) -> Control:
	if GuardianBeasts.SPECIES.has(id):
		var image := UiIllustration.new()
		image.custom_minimum_size = Vector2.ONE * edge
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_growth_art(image, id, "mature")
		return image
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
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.add_theme_constant_override("separation", 12)
	info.add_child(actions)
	var cost := CostStrip.new()
	cost.custom_minimum_size.x = 160
	actions.add_child(cost)
	var soul := label("", 15)
	info.add_child(soul)
	var permit := label("")
	info.add_child(permit)
	var redeem := action(info,"redeem",id)
	redeem.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var acquire := action(actions,"acquire",id)
	var feed := action(actions,"feed",id)
	# The public feed alias is kept for existing navigation/command consumers.
	var talents := {}
	var definitions := BeastSystem.BEAST_TALENTS.duplicate(true)
	for tid in GuardianBeasts.TALENTS:
		definitions[tid] = {"beast_id": GuardianBeasts.TALENTS[tid][0]}
	for tid in definitions:
		var t: Dictionary = definitions[tid]
		if t.beast_id != id: continue
		var tr := HBoxContainer.new()
		body.add_child(tr)
		if id in BeastSystem.P2_IDS: tr.add_child(art(id,44))
		var desc := label("")
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.add_child(desc)
		var learn := action(tr,"talent",tid)
		talents[tid] = {"desc":desc,"button":learn}
	cards[id] = {"permit":permit,"redeem":redeem,"card":card,"art":image,"title":title,"detail":detail,"cost":cost,"soul":soul,"acquire":acquire,"feed":feed,"talents":talents}

func layout() -> void:
	if grid == null: return
	compact = size.y < 350
	# A full beast includes four talent rows; keep each card readable in one column.
	grid.columns = 1
	grid.custom_minimum_size.x = minf(maxf(0, scroll.size.x - 14), 860)
	for id in cards:
		var c: Dictionary = cards[id]
		if c.art is TextureRect: c.art.custom_minimum_size = Vector2.ONE * (80 if compact else 112)
		c.card.custom_minimum_size.x = 0

func refresh(view: Dictionary) -> void:
	var data: Dictionary = view.get("beast",{})
	var active: Dictionary = data.get("active",{})
	var active_id: String = active.get("id", "")
	buttons.erase("feed:")
	var ledger: Dictionary = data.get("guardian_permits", {})
	tokens.text = "守護信物 %d／120 · 每12枚指定兌換；合格新委託領取+1、重複資格再+2，滿額溢出不補償。\n發現／兌換只得永久資格，跨世保留；結契不消耗資格，仍須當世境界、供給及空名額。" % int(ledger.get("guardian_tokens", 0))
	tokens.visible = not ledger.is_empty()
	for id in cards:
		var c: Dictionary = cards[id]
		var guardian: bool = GuardianBeasts.SPECIES.has(id)
		var config: Dictionary = BeastSystem.BEAST_CONFIGS.get(id, {})
		if guardian: config = {"name": GuardianBeasts.SPECIES[id][0], "unlock_era": 3, "desc": guardian_effect(id), "feed_resource": {"spirit_grass_low": 50}}
		var current: bool = id == active_id
		c.title.text = "%s · %s · 同種獸魂 %d" % [config.name, "本世結契" if current else "第%d境" % config.unlock_era, int(data.get("souls",{}).get(id,0))]
		var req: Dictionary = data.get("acquire_requirements",{}).get(id,{"ok":false})
		var owned: bool = ledger.get("permits", {}).has(id)
		var legacy: bool = ledger.get("legacy_permits", {}).has(id)
		c.permit.text = "資格來源：" + ("新手免費靈狐" if id == "jade_fox" else ("舊檔既有權利" if legacy else ("委託發現／信物兌換（永久）" if owned else "尚未取得；由宗門合格委託發現或12信物兌換")))
		c.permit.visible = not ledger.is_empty()
		c.redeem.visible = id != "jade_fox" and not ledger.is_empty()
		var redeem_req: Dictionary = data.get("redeem_requirements", {}).get(id, {"ok": false, "error": "GUARDIAN_RELEASE_REQUIRED"})
		c.redeem.disabled = not redeem_req.ok
		c.redeem.text = "已持永久資格" if owned or legacy else "兌換資格 · 12信物"
		c.redeem.tooltip_text = requirement_text(redeem_req) if not redeem_req.ok else "只取得資格，不自動結契；不須加入該代表獸宗門。"
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
		if guardian:
			if current: effect += "\n%s · XP %d／1000 · 下餵 +%dXP" % [BeastSystem.STAGE_CONFIGS[stage].name, int(active.get("exp", 0)), int(data.get("guardian_care", {}).get(id, {}).get("next_xp", 50))]
			set_growth_art(c.art, id, stage if current else "mature")
		c.detail.text = effect
		var costs: Dictionary = data.get("guardian_care" if guardian else "care",{}).get(id,{}).get("costs",config.feed_resource)
		var names := {}
		var available := {}
		var sources := {}
		for resource in costs:
			names[resource] = Icon.get_resource_name(String(resource))
			available[resource] = _amount(view.get("resources",{}).get(resource,{}).get("value","0"))
			sources[resource] = "祖島"
		var note := CostStrip.shortage_text(costs, available, names, "祖島餵料不足")
		if current and float(data.get("cooldown_remaining",0)) > 0:
			note = (note + " · " if not note.is_empty() else "") + "冷卻 %d秒" % int(ceil(float(data.get("cooldown_remaining",0))))
		c.cost.show_costs(costs, names, available, sources, "祖島餵料", note, UiMaterial.INK)
		var souls := int(data.get("souls",{}).get(id,0))
		c.soul.text = "同種獸魂 %d · 輪迴成熟後取得，不用於餵養" % souls
		c.soul.add_theme_color_override("font_color", Color("355f58"))
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
	return {"ALREADY_HAS_ACTIVE_BEAST":"本世已有靈獸","INSUFFICIENT_ERA":"境界未達","LIFESPAN_EXHAUSTED":"壽元已盡","BEAST_SAVE_REQUIRED":"需先保存","SUPPLY_REQUIRED":"需啟用供給","ISLAND_NOT_OPEN":"需先開島", "GUARDIAN_PERMIT_REQUIRED":"需永久資格", "GUARDIAN_SUPPLY_REQUIRED":"需當世境界與餵料產地", "INSUFFICIENT_GUARDIAN_TOKENS":"信物不足12枚", "GUARDIAN_PERMIT_OWNED":"已有永久資格", "SECT_LOCKED":"需先入宗", "SECT_IDENTITY_PENDING":"需確認宗門身分", "GUARDIAN_RELEASE_REQUIRED":"需完成改版保存"}.get(req.get("error",""),"尚未開放")

func cost_text(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for id in costs:
		parts.append("%s %d" % [{"spirit_grass_low":"靈草","refined_iron":"精鐵","stone_low":"下品靈石","spirit_grass_100y":"百年靈草","spirit_grass_1000y":"千年靈草","void_essence":"虛空精華","star_metal":"星金"}.get(id,id),int(costs[id])])
	return "、".join(parts)

func _amount(raw: Variant) -> float:
	var parsed := AmountCompat.try_parse(str(raw))
	return parsed.value.to_float() if bool(parsed.get("ok", false)) else 0.0

func guardian_effect(id: String) -> String:
	return {"taixu_baize":"成熟修速 +4%", "tianjian_suanni":"成熟玄礦下石／玄銅、寒銀精鐵／秘銀／寒鐵採集 +8%", "piaomiao_jade_hare":"成熟丹霞低草／百草、古藥千草採集 +8%", "wanfo_lotus_elephant":"成熟壽元比例 +4%", "zixiao_star_tapir":"成熟祖島靈力容量 +8%"}[id] + "；卵無被動，幼獸50%、成長75%倍率；獸固有被動不限宗門。需金丹及丹霞已開拓。"

func set_growth_art(image: TextureRect, id: String, stage: String) -> void:
	var path := GUARDIAN_ART + id + ".png"
	if not ResourceLoader.exists(path): return
	var index: int = ["egg", "young", "growing", "mature"].find(stage)
	if index < 0: index = 2
	if image.has_meta("stage") and image.get_meta("stage") == index: return
	var source: Texture2D = load(path)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var cell := source.get_size() / 2
	atlas.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
	image.texture = atlas
	image.set_meta("stage", index)
