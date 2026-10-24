extends PanelContainer
## Island basics; commands are handled by the canonical navigation controller.
signal action_requested(kind: String, payload: Dictionary)
signal legacy_requested()
signal close_requested()
signal world_requested(id: String)
signal page_requested(route: String, island_id: String)
signal retry_requested()
signal context_changed()
const IslandTile = preload("res://src/presentation/recipe_material_tile.gd")
const NumberFormatter = preload("res://src/utils/number_formatter.gd")

var island := "home"
var body: VBoxContainer
var summary: Label
var message: Label
var inventory: Label
var job_status: Label
var activation: Button
var heading_label: Label
var heading_row: HBoxContainer
var opening: Button
var retry_button: Button
var facility_buttons := {}
var island_buttons := {}
var payment_stock: Label
var local_stock: Label
var stock_button: Button
var stock_expanded := true
var page_links: Array[Button] = []
var _success_until := 0
var _view := {}
var _catalog := {}
var selectors: HFlowContainer
var world_button: Button
var resource_cards: HFlowContainer
var local_cards: HFlowContainer
var cost_cards: HFlowContainer
var facility_cards := {}
var stock_cards := {}
var local_tiles := {}
var opening_tiles := {}
var island_picker: OptionButton
var short_world_button: Button
var _island_basics := false

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.scroll_shell())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var heading := HBoxContainer.new()
	heading_row = heading
	column.add_child(heading)
	heading_label = _label("空島")
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_label)
	island_picker = OptionButton.new()
	island_picker.custom_minimum_size = Vector2(104, 44)
	island_picker.visible = false
	for id in IslandProgression.NAMES:
		island_picker.add_item(IslandProgression.NAMES[id])
	island_picker.item_selected.connect(func(index: int): select_island(IslandProgression.NAMES.keys()[index]))
	heading.add_child(island_picker)
	short_world_button = _add_button(heading, "前往", func(): world_requested.emit(island))
	short_world_button.visible = false
	_add_button(heading, "關閉", func(): close_requested.emit())
	message = _label("")
	message.visible = false
	column.add_child(message)
	retry_button = _add_button(column, "重試保存", func(): retry_requested.emit())
	retry_button.visible = false
	selectors = HFlowContainer.new()
	selectors.visible = false
	column.add_child(selectors)
	for id in IslandProgression.NAMES:
		var button := _add_button(selectors, IslandProgression.NAMES[id], func(): select_island(id))
		button.toggle_mode = true
		island_buttons[id] = button
	world_button = _add_button(column, "前往此島世界", func(): world_requested.emit(island))
	world_button.visible = false
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	_rebuild()

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UiMaterial.INK)
	return label

func _resource_name(id: String) -> String:
	return {"foundation_pill": "築基丹", "stone_mid": "中品靈石", "golden_core_pill": "金丹丹藥", "liquid": "丹液", "talisman": "符咒"}.get(id, _catalog.get("resources", {}).get(id, {}).get("name", id))

func _add_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	if parent is VBoxContainer:
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.x = 100
	button.add_theme_font_size_override("font_size", 18)
	UiMaterial.apply_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _clear_body() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()

func _rebuild() -> void:
	if body == null:
		return
	selectors.visible = size.y >= 400
	world_button.visible = size.y >= 400
	island_picker.visible = size.y < 400
	_island_basics = true
	if opening != null and opening.get_parent() != body:
		opening.get_parent().remove_child(opening)
		opening.queue_free()
	_clear_body()
	facility_buttons.clear()
	facility_cards.clear()
	stock_cards.clear()
	local_tiles.clear()
	opening_tiles.clear()
	page_links.clear()
	short_world_button.visible = size.y < 400
	summary = _label("")
	body.add_child(summary)
	activation = _add_button(body, "保留原檔並啟用空島", func(): action_requested.emit("activate_islands", {}))
	cost_cards = HFlowContainer.new()
	body.add_child(cost_cards)
	for resource in (_islands().get(island, {}).get("cost", {"wood": 20, "stone_low": 10})):
		opening_tiles[resource] = _tile(cost_cards)
	opening = _add_button(body, "開拓此島", func(): action_requested.emit("open_island", {"island_id": island}))
	payment_stock = _label("")
	body.add_child(payment_stock)
	inventory = _label("")
	body.add_child(inventory)
	resource_cards = HFlowContainer.new()
	body.add_child(resource_cards)
	local_stock = _label("")
	body.add_child(local_stock)
	local_cards = HFlowContainer.new()
	body.add_child(local_cards)
	job_status = _label("")
	body.add_child(job_status)
	if island in ["wood", "ore", "herb"]:
		for id in ["extractor", "storage"]:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
			body.add_child(card)
			var column := VBoxContainer.new()
			card.add_child(column)
			var effect := _label("")
			column.add_child(effect)
			var row := HFlowContainer.new()
			column.add_child(row)
			var tiles := {}
			for resource in IslandProgression.upgrade_cost(id, 1):
				tiles[resource] = _tile(row)
			facility_buttons[id] = _add_button(column, "", func(): action_requested.emit("upgrade_island_facility", {"island_id": island, "facility_id": id}))
			facility_cards[id] = {"card": card, "effect": effect, "costs": row, "tiles": tiles}
	else:
		_add_button(body, "洞府建築", func(): page_requested.emit("buildings", "home"))
	page_links.append(_add_button(body, "製造・本島產線", func(): page_requested.emit("manufacturing", island)))
	page_links.append(_add_button(body, "運輸・本島航線", func(): page_requested.emit("transport", island)))
	page_links.append(_add_button(body, "靈界洞天", func(): legacy_requested.emit()))

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	_view = view
	_catalog = catalog
	if body == null:
		return
	var e: Dictionary = view.get("economy", {})
	var enabled: bool = e.get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION, IslandProgression.SUPPLY_VERSION]
	var info: Dictionary = view.get("manufacturing", {}).get("islands", {}).get(island, {})
	var opened := bool(info.get("opened", false))
	for id in island_buttons:
		island_buttons[id].visible = _islands().has(id)
		var locked: bool = int(view.get("era_id", 1)) < int(_islands().get(id, {}).get("era", 1))
		island_buttons[id].text = IslandProgression.NAMES[id] + ("・未開" if locked else "")
		island_buttons[id].self_modulate = Color(0.65, 0.65, 0.65, 1) if locked else Color.WHITE
		island_picker.set_item_text(IslandProgression.NAMES.keys().find(id), island_buttons[id].text)
		island_buttons[id].button_pressed = id == island
		UiMaterial.mark_paper_tab(island_buttons[id], id == island)
	heading_label.text = "空島" if size.y < 400 else "人界・%s" % IslandProgression.NAMES[island]
	island_picker.select(IslandProgression.NAMES.keys().find(island))
	activation.visible = false
	activation.text = "保留三島原檔並接續丹霞" if enabled else "保留原檔並啟用空島"
	activation.disabled = not bool(view.get("island_activation", {}).get("ok", false))
	opening.visible = not opened and island != "home"
	var can_initialize: bool = enabled or bool(view.get("island_activation", {}).get("ok", false))
	var definition: Dictionary = _islands().get(island, {})
	var costs: Dictionary = definition.get("cost", {"wood": 20, "stone_low": 10})
	opening.disabled = int(view.get("era_id", 1)) < int(definition.get("era", 1)) or not can_initialize
	for resource in costs:
		if _home_available(resource) < float(costs[resource]): opening.disabled = true
	var short: bool = size.y < 400
	var opening_host: Node = heading_row if short and opening.visible else body
	if opening.get_parent() != opening_host:
		opening.reparent(opening_host, false)
		opening_host.move_child(opening, 2 if opening_host == heading_row else cost_cards.get_index() + 1)
	opening.custom_minimum_size.x = 64 if opening_host == heading_row else 100
	opening.text = "開拓" if opening_host == heading_row else "開拓%s" % IslandProgression.NAMES[island]
	short_world_button.visible = short and (opened or island == "home")
	opening.tooltip_text = "祖島支付；境界需求 %d。首次開拓同時啟用產業，原檔歸檔；輪迴清除當世空島。" % int(definition.get("era", 1))
	cost_cards.visible = opening.visible
	if opening_tiles.keys() != costs.keys():
		for tile in opening_tiles.values(): tile.queue_free()
		opening_tiles.clear()
		for resource in costs: opening_tiles[resource] = _tile(cost_cards)
	for resource in opening_tiles:
		opening_tiles[resource].refresh(resource, _resource_name(resource), costs[resource], _home_available(resource), "祖島")
	var payment: Array[String] = []
	for resource in ["wood", "stone_low", "spirit_timber", "bronze_essence"]:
		payment.append("%s %.1f" % [_resource_name(resource), _home_available(resource)])
	payment_stock.text = "工程材料由祖島支付"
	payment_stock.tooltip_text = "祖島工程庫存：" + "・".join(payment)
	payment_stock.visible = enabled and island != "home" and size.y >= 400
	var role: String = {"home": "修行與合成・各配方共用一條產線", "wood": "林業・靈木採集", "ore": "採礦・靈石與玄銅", "herb": "藥業・靈草與百年草"}.get(island, "採集專島・地方容量300・無加工坊")
	summary.text = "%s・%s" % [role, "已開拓" if opened else ("金丹解鎖" if island == "herb" and int(view.get("era_id", 1)) < 3 else "先開拓第一座空島" if not enabled and island == "wood" else "待開拓")]
	if island in IslandEconomy.supply_data().islands:
		var focus: String = IslandEconomy.supply_data().dispatch[island]
		summary.text += "・境界需求%d・當島調度%s" % [int(definition.era), "已建（產率×2）" if int(view.get("buildings", {}).get(focus, {}).get("level", 0)) > 0 else "未建（營造簿查看）"]
	summary.visible = true
	island_picker.tooltip_text = summary.text
	for link in page_links:
		link.visible = opened
		if island in ["deep", "ancient", "void"] and link == page_links[0]: link.visible = false
	var lines: Array[String] = []
	for id in info.get("rates", {}):
		var slot: Dictionary = e.get("inventory", {}).get(island, {}).get(id, {})
		lines.append("%s %.1f／%.0f・採集 %.1f／秒" % [_resource_name(id), float(slot.get("available", 0)), float(info.capacity), float(info.rates[id])])
		if not stock_cards.has(id):
			var tile := _tile(resource_cards)
			var rate := _label("")
			tile.get_child(0).add_child(rate)
			var meter := ProgressBar.new()
			meter.show_percentage = false
			meter.custom_minimum_size.y = 6
			tile.get_child(0).add_child(meter)
			stock_cards[id] = {"tile": tile, "rate": rate, "meter": meter}
		var widgets: Dictionary = stock_cards[id]
		_stock_tile(widgets.tile, id, float(slot.get("available", 0)), _resource_name(id))
		widgets.rate.text = "＋%s／秒" % NumberFormatter.format_rate(float(info.rates[id]))
		widgets.meter.max_value = float(info.capacity)
		widgets.meter.value = float(slot.get("available", 0)) + float(slot.get("reserved", 0))
		widgets.tile.tooltip_text = lines[-1] + "\n容量預留 %s" % NumberFormatter.format_amount(slot.get("reserved", 0))
	inventory.text = "採集庫存・容量 %s" % NumberFormatter.format_amount(float(info.get("capacity", 0))) if opened and not lines.is_empty() else ""
	inventory.visible = size.y >= 400
	resource_cards.visible = opened
	stock_expanded = true
	local_stock.visible = opened
	local_cards.visible = opened
	var stock_lines: Array[String] = []
	for resource in e.get("inventory", {}).get(island, {}):
		var slot: Dictionary = e.inventory[island][resource]
		if float(slot.available) > 0 or float(slot.reserved) > 0 or info.get("rates", {}).has(resource):
			stock_lines.append("%s：可用%s・容量預留%s" % [_resource_name(resource), NumberFormatter.format_amount(slot.available), NumberFormatter.format_amount(slot.reserved)])
			if not local_tiles.has(resource):
				local_tiles[resource] = _tile(local_cards)
			_stock_tile(local_tiles[resource], resource, float(slot.available), _resource_name(resource))
			local_tiles[resource].tooltip_text = stock_lines[-1]
	for resource in local_tiles:
		var slot: Dictionary = e.get("inventory", {}).get(island, {}).get(resource, {})
		local_tiles[resource].visible = float(slot.get("available", 0)) > 0 or float(slot.get("reserved", 0)) > 0 or info.get("rates", {}).has(resource)
	local_stock.text = "本島可用庫存" if not stock_lines.is_empty() else "本島尚無庫存"
	local_stock.tooltip_text = "\n".join(stock_lines)
	var job: Dictionary = e.get("jobs", {}).get(island, {})
	job_status.text = "產線閒置" if job.is_empty() else "%s・%s" % [_recipe_name(job.recipe_id), status_text(job.status)]
	job_status.visible = opened and island in ["home", "wood", "ore", "herb"]
	for id in facility_buttons:
		var level := int(e.get("islands", {}).get(island, {}).get("facilities", {}).get(id, 1))
		var prices: Array[String] = []
		var cost := IslandProgression.upgrade_cost(id, level)
		for resource in cost:
			prices.append("%s%s（可用%s）" % [_resource_name(resource), NumberFormatter.format_amount(cost[resource]), NumberFormatter.format_amount(_home_available(resource))])
		var effects: Array[String] = []
		if id == "storage":
			effects.append("容量%d→%d" % [int(IslandProgression.capacity_for_level(level)), int(IslandProgression.capacity_for_level(mini(3, level + 1)))])
		else:
			for resource in IslandEconomy.ISLANDS[island].rates:
				var rate: int = IslandEconomy.ISLANDS[island].rates[resource]
				effects.append("%s %d→%d／秒" % [_resource_name(resource), rate * level, rate * mini(3, level + 1)])
		var widgets: Dictionary = facility_cards[id]
		widgets.card.visible = opened
		widgets.effect.text = "%s・%d階\n%s" % [IslandProgression.FACILITIES[id], level, "、".join(effects)]
		widgets.costs.visible = level < 3
		for resource in widgets.tiles:
			widgets.tiles[resource].refresh(resource, _resource_name(resource), float(cost[resource]), _home_available(resource), "祖島")
		facility_buttons[id].text = "已達上限" if level >= 3 else "升至 %d 階" % (level + 1)
		facility_buttons[id].tooltip_text = "祖島支付：" + "＋".join(prices)
		facility_buttons[id].visible = opened
		facility_buttons[id].disabled = level >= 3
	world_button.text = "世界場景未開放・此島以管理清單操作" if island in ["deep", "ancient", "void"] else "前往%s" % IslandProgression.NAMES[island]
	world_button.disabled = island not in ["home", "wood", "ore", "herb"] or (island != "home" and not opened)
	short_world_button.disabled = world_button.disabled
	short_world_button.tooltip_text = "此島目前以管理清單操作，世界美術尚未開放" if island not in ["home", "wood", "ore", "herb"] else world_button.text

func _tile(parent: Node) -> Control:
	var tile := IslandTile.new()
	tile.caption.add_theme_font_size_override("font_size", 16)
	parent.add_child(tile)
	return tile

func _stock_tile(tile: Control, resource: String, available: float, title: String) -> void:
	tile.refresh(resource, _resource_name(resource), available, available, IslandProgression.NAMES[island], true)
	tile.quantity.text = NumberFormatter.format_amount(available)
	tile.caption.text = title

func _amount(value: float) -> String:
	return NumberFormatter.format_amount(value)

func _home_available(resource: String) -> float:
	if not _view.get("economy", {}).get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION, IslandProgression.SUPPLY_VERSION]:
		return float(_view.get("resources", {}).get(resource, {}).get("value", 0))
	var slot: Dictionary = _view.get("economy", {}).get("inventory", {}).get("home", {}).get(resource, {})
	return float(slot.get("available", 0))

func show_success(text: String) -> void:
	# A save fault persists until storage_recovered; a later success cannot hide it.
	if retry_button.visible:
		return
	show_result(text)
	_success_until = Time.get_ticks_msec() + 5000

func expire_success() -> void:
	if _success_until > 0 and Time.get_ticks_msec() >= _success_until:
		show_result("")

static func status_text(code: String) -> String:
	return {"running": "加工中", "ready": "準備加工", "INSUFFICIENT_RESOURCE": "缺料等待", "OUTPUT_FULL": "產物滿倉"}.get(code, code)

func show_result(text: String) -> void:
	_success_until = 0
	message.text = text
	message.visible = not text.is_empty()
	retry_button.visible = text.begins_with("操作未保存：")

func storage_recovered() -> void:
	if message != null and message.text.begins_with("操作未保存："):
		show_result("保存已恢復，進度已存妥。")

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell() if bounds.size.y < 400 else UiMaterial.scroll_shell())
	if get_child_count() > 0:
		get_child(0).add_theme_constant_override("separation", 4 if bounds.size.y < 400 else 8)
	if _island_basics:
		var short := bounds.size.y < 400
		selectors.visible = not short
		world_button.visible = not short
		island_picker.visible = short
		short_world_button.visible = short
		refresh(_view, _catalog)

func select_island(id: String) -> void:
	if IslandProgression.NAMES.has(id) and island != id:
		island = id
		_rebuild()
	refresh(_view, _catalog)
	context_changed.emit()

func _islands() -> Dictionary:
	var defs := IslandEconomy.ISLANDS.duplicate(true)
	if _catalog.get("version") == IslandProgression.SUPPLY_VERSION:
		defs.merge(IslandEconomy.supply_data().islands)
	return defs

func _routes() -> Dictionary:
	var defs := IslandEconomy.ROUTES.duplicate(true)
	if _catalog.get("version") == IslandProgression.SUPPLY_VERSION:
		defs.merge(IslandEconomy.supply_data().routes)
	return defs

func _recipe_name(id: String) -> String:
	return "中品靈石・量產" if id == "stone_mid_bulk" else _resource_name(ProcessingCatalog.product_id(_catalog, id))
