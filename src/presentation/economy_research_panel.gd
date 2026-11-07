extends PanelContainer
## The workbench owns the outer paper, tabs and CloseSeal.

signal close_requested()
signal action_requested(kind: String, payload: Dictionary)
signal target_requested(route: String, id: String)

const TITLES := {
	"R01":"靈材精煉", "R02":"銅精冶製", "R03":"工坊工程", "R04":"倉儲整備",
	"R05":"陣芯與符咒", "R06":"丹霞藥理", "R07":"凝煉靈石", "R08":"靈石量產",
	"R09":"深採精鐵", "R10":"深採寒鐵", "R11":"深採秘銀", "R12":"化神丹法",
	"R13":"上品凝石", "R14":"太虛工藝",
}
const REASONS := {
	"RESEARCH_BUSY":"研習槽使用中", "RESEARCH_COMPLETED":"當世已完成",
	"RESEARCH_ERA":"境界未達", "RESEARCH_FACILITY":"先建造研習席",
	"RESEARCH_ISLAND":"先開拓所需空島", "RESEARCH_PREREQUISITE":"先完成前置研習",
	"RESEARCH_SAMPLE_REQUIRED":"須先取得樣品", "RESEARCH_LIFESPAN":"當世壽元已盡",
	"RESOURCE_LOCKED":"材料尚未開放", "INSUFFICIENT_RESOURCE":"祖島材料不足",
	"PROFILE_SAVE_REQUIRED":"進度尚未存妥，請重試保存",
}

var _heading: Label
var _guidance: Label
var _feedback: Label
var _cancel: Button
var _close: Button
var _list: VBoxContainer
var _rows := {}
var _job_id := ""
var _confirm_cancel := false
var resource_names: Dictionary
var building_names: Dictionary

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_heading = _label(header, 18)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel = _button(header, "取消研習", _cancel_job)
	_cancel.hide()
	_close = CloseSeal.new()
	header.add_child(_close)
	_close.pressed.connect(func(): close_requested.emit())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	_guidance = _label(_list, 18)
	_feedback = _label(_list, 16)
	_feedback.hide()

func set_embedded(value: bool) -> void:
	_close.visible = not value
	if value: add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

func refresh(view: Dictionary, content: GameContent) -> void:
	var research: Dictionary = view.research
	var job: Dictionary = research.state.job
	var pending_job := String(job.get("id", ""))
	if _job_id != pending_job:
		_confirm_cancel = false
	_job_id = pending_job
	_cancel.visible = not job.is_empty()
	_cancel.text = "確認取消・不退材料" if _confirm_cancel else "取消研習"
	_heading.text = "研習槽空閒" if job.is_empty() else "%s｜剩餘 %d 秒" % [TITLES[_job_id], int(job.remaining)]
	var effect: Dictionary = research.inheritance
	var next := ""
	for node in research.nodes:
		var id: String = node.id
		if not _rows.has(id): _add_research(id)
		var row: Dictionary = _rows[id]
		row.root.visible = int(node.era) <= int(view.era_id)
		if not row.root.visible: continue
		var code: String = research.readiness[id]
		var running := _job_id == id
		var completed: bool = research.state.completed.has(id)
		var timing := EconomyEffects.duration(int(node.seconds), effect, 10)
		var unlocks := _unlocks(node, content)
		var costs := _costs(job.paid if running else node.cost, view.resources, running)
		row.title.text = "%s · %s｜%s" % [id, TITLES[id], "研習中" if running else "當世已完成" if completed else REASONS.get(code, "可研習")]
		row.detail.text = "%s\n%s\n工時 %d → %d 秒" % [unlocks, costs, int(node.seconds), int(job.duration if running else timing.seconds)]
		if running:
			row.detail.text += "（本次已鎖定；取消不退材料）"
		elif code == "RESEARCH_PREREQUISITE":
			var missing := PackedStringArray()
			for prerequisite in node.prerequisites:
				if not research.state.completed.has(prerequisite):
					missing.append(prerequisite + " " + TITLES[prerequisite])
			row.detail.text += "\n前置研習 " + "、".join(missing)
		elif code == "RESEARCH_SAMPLE_REQUIRED":
			var samples := PackedStringArray()
			for resource in node.get("produced", []):
				if not view.resources[resource].ever_obtained: samples.append(_resource(resource))
			row.detail.text += "\n待取得樣品 " + "、".join(samples)
		row.start.visible = not running and not completed
		row.start.disabled = not code.is_empty()
		row.link.visible = code in ["RESEARCH_FACILITY", "RESEARCH_ISLAND", "INSUFFICIENT_RESOURCE", "RESEARCH_SAMPLE_REQUIRED", "RESOURCE_LOCKED"]
		var target := _target(node, code, view, content)
		row.link.text = target.label
		row.link.set_meta("target", target)
		if next.is_empty() and not completed and code != "RESEARCH_PREREQUISITE":
			next = "%s %s" % [id, TITLES[id]]
	_guidance.text = "下一項研習  %s\n研究傳承 · 歷世深度 %d · 工時縮短 %s%%\n每世重新研習，材料照原額支付。" % [
		next if not next.is_empty() else "當前境界的研習已完成", int(research.state.inherited_depth),
		String.num(float(effect.effective) * 100.0, 1),
	]

func _add_research(id: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
	_list.add_child(card)
	var column := VBoxContainer.new()
	card.add_child(column)
	var title := _label(column, 18)
	var detail := _label(column, 16)
	var actions := HFlowContainer.new()
	column.add_child(actions)
	var start := _button(actions, "開始研習", func(): action_requested.emit("start_research", {"research_id": id}))
	var link := _button(actions, "", func():
		var target: Dictionary = _rows[id].link.get_meta("target")
		target_requested.emit(target.route, target.id))
	_rows[id] = {"root":card, "title":title, "detail":detail, "start":start, "link":link}

func _target(node: Dictionary, code: String, view: Dictionary, content: GameContent) -> Dictionary:
	if code == "RESEARCH_FACILITY": return {"route":"buildings", "id":node.facility, "label":"前往營造研習席"}
	if code == "RESEARCH_ISLAND": return {"route":"outposts", "id":node.island, "label":"前往" + IslandProgression.NAMES[node.island]}
	var resources: Array = node.get("produced", []) if code == "RESEARCH_SAMPLE_REQUIRED" else node.cost.keys()
	for resource in resources:
		var stock: Dictionary = view.resources[resource]
		if code != "RESEARCH_SAMPLE_REQUIRED" and stock.unlocked and _value(stock.value) >= float(node.cost[resource]): continue
		for recipe in content.processing_catalog.recipes:
			if ProcessingCatalog.product_id(content.processing_catalog, recipe) == resource:
				return {"route":"manufacturing", "id":recipe, "label":"前往製造" + _resource(resource)}
		var routes: Dictionary = IslandEconomy.supply_data().routes.duplicate()
		routes.merge(IslandEconomy.ROUTES)
		routes.merge(IslandEconomy.HUB_ROUTES)
		for route in routes:
			if routes[route][2] == resource and routes[route][1] == "home":
				return {"route":"transport", "id":route, "label":"查看" + _resource(resource) + "航線"}
	return {"route":"buildings", "id":"", "label":"查看祖島生產與容量"}

func _unlocks(node: Dictionary, content: GameContent) -> String:
	var uses := PackedStringArray()
	for unlock in node.unlocks:
		var id: String = unlock.get_slice(":", 1)
		match unlock.get_slice(":", 0):
			"recipe": uses.append("製造" + ("量產中品靈石（元嬰啟用）" if id == "stone_mid_bulk" else _resource(ProcessingCatalog.product_id(content.processing_catalog, id))))
			"gather": uses.append("開採" + _resource(id))
			"building": uses.append("營造" + _building(id))
			"engineering":
				uses.append("工藝坊二階、空島工坊與採集升階、築基後段晉階" if id == "workshop" else "空島倉儲升階、三階聚靈庫與指定倉儲建設減耗")
	for id in EconomySlice.FRONTIER_GATES:
		if EconomySlice.FRONTIER_GATES[id] == node.id and not "recipe:" + id in node.unlocks:
			uses.append("製造" + _resource(ProcessingCatalog.product_id(content.processing_catalog, id)))
	for id in EconomySlice.FRONTIER_BUILDINGS:
		if EconomySlice.FRONTIER_BUILDINGS[id] == node.id: uses.append("營造" + _building(id))
	for entry in [["R08", "cultivation_focus_4"], ["R09", "mineral_focus"], ["R10", "core_storehouse_4"]]:
		if entry[0] == node.id: uses.append("營造" + _building(entry[1]))
	return "用途  " + "、".join(uses)

func _costs(cost: Dictionary, resources: Dictionary, paid: bool) -> String:
	var lines := PackedStringArray()
	for id in cost:
		var stock: Dictionary = resources.get(id, {})
		var available := _value(stock.get("value", "0"))
		var capacity := _value(stock.get("cap", "0"))
		var need := float(cost[id])
		var status := "（庫容不足）" if need > capacity else "（缺 %s）" % String.num(need - available, 2) if need > available else ""
		lines.append("%s %s" % [_resource(id), String.num(need)] if paid else "%s %s／%s%s" % [_resource(id), String.num(available, 2), String.num(need), status])
	return ("已付  " if paid else "祖島持有／需求  ") + "・".join(lines)

func _cancel_job() -> void:
	if _confirm_cancel:
		_confirm_cancel = false
		action_requested.emit("cancel_research", {})
	else:
		_confirm_cancel = true
		_cancel.text = "確認取消・不退材料"

func show_result(result: Dictionary) -> void:
	var error: String = result.get("error", "")
	_feedback.text = "" if result.ok else REASONS.get(error, "研習操作受阻 · " + error)
	_feedback.visible = not _feedback.text.is_empty()

func storage_recovered() -> void:
	_feedback.hide()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 44
	UiMaterial.apply_button(button)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

static func _value(text: String) -> float:
	var parsed := AmountCompat.try_parse(text)
	return parsed.value.to_float() if parsed.ok else 0.0

func _resource(id: String) -> String:
	return resource_names.get(id, id)

func _building(id: String) -> String:
	return building_names.get(id, id)
