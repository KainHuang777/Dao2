extends PanelContainer
## Island basics; commands are handled by the canonical navigation controller.
signal action_requested(kind: String, payload: Dictionary)
signal legacy_requested()
signal close_requested()
signal world_requested(id: String)
signal page_requested(route: String, island_id: String)
signal retry_requested()
const IslandTile = preload("res://src/presentation/recipe_material_tile.gd")

var island := "home"
var body: VBoxContainer
var summary: Label
var message: Label
var inventory: Label
var job_status: Label
var activation: Button
var heading_label: Label
var opening: Button
var retry_button: Button
var facility_buttons := {}
var island_buttons := {}
var payment_stock: Label
var local_stock: Label
var stock_button: Button
var stock_expanded := false
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
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var heading := HBoxContainer.new()
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
	_clear_body()
	facility_buttons.clear()
	facility_cards.clear()
	stock_cards.clear()
	local_tiles.clear()
	opening_tiles.clear()
	short_world_button.visible = size.y < 400
	summary = _label("")
	body.add_child(summary)
	activation = _add_button(body, "保留原檔並啟用空島", func(): action_requested.emit("activate_islands", {}))
	cost_cards = HFlowContainer.new()
	body.add_child(cost_cards)
	for resource in ["wood", "stone_low"]:
		opening_tiles[resource] = _tile(cost_cards)
	opening = _add_button(body, "開拓此島", func(): action_requested.emit("open_island", {"island_id": island}))
	payment_stock = _label("")
	body.add_child(payment_stock)
	inventory = _label("")
	body.add_child(inventory)
	resource_cards = HFlowContainer.new()
	body.add_child(resource_cards)
	stock_button = _add_button(body, "", func(): stock_expanded = not stock_expanded; refresh(_view, _catalog))
	local_stock = _label("")
	body.add_child(local_stock)
	local_cards = HFlowContainer.new()
	body.add_child(local_cards)
	job_status = _label("")
	body.add_child(job_status)
	if island != "home":
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
	_add_button(body, "製造・本島產線", func(): page_requested.emit("manufacturing", island))
	_add_button(body, "運輸・本島航線", func(): page_requested.emit("transport", island))
	_add_button(body, "靈界洞天", func(): legacy_requested.emit())

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	_view = view
	_catalog = catalog
	if body == null:
		return
	var e: Dictionary = view.get("economy", {})
	var enabled: bool = e.get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION]
	var info: Dictionary = view.get("manufacturing", {}).get("islands", {}).get(island, {})
	var opened := bool(info.get("opened", false))
	for id in island_buttons:
		island_buttons[id].button_pressed = id == island
		UiMaterial.mark_selected(island_buttons[id], id == island)
	heading_label.text = "空島" if size.y < 400 else "人界・%s" % IslandProgression.NAMES[island]
	island_picker.select(IslandProgression.NAMES.keys().find(island))
	activation.visible = e.get("version") != IslandProgression.VERSION
	activation.text = "保留三島原檔並接續丹霞" if enabled else "保留原檔並啟用空島"
	activation.disabled = not bool(view.get("island_activation", {}).get("ok", false))
	opening.visible = enabled and not opened and island != "home"
	opening.disabled = int(view.get("era_id", 1)) < int(IslandEconomy.ISLANDS[island].era) or (island == "herb" and e.get("version") != IslandProgression.VERSION)
	cost_cards.visible = opening.visible
	for resource in opening_tiles:
		opening_tiles[resource].refresh(resource, _resource_name(resource), 20 if resource == "wood" else 10, _home_available(resource), "祖島")
	var payment: Array[String] = []
	for resource in ["wood", "stone_low", "spirit_timber", "bronze_essence"]:
		payment.append("%s %.1f" % [_resource_name(resource), _home_available(resource)])
	payment_stock.text = "工程材料由祖島支付"
	payment_stock.tooltip_text = "祖島工程庫存：" + "・".join(payment)
	payment_stock.visible = enabled and island != "home" and size.y >= 400
	var role: String = {"home": "修行與合成・各配方共用一條產線", "wood": "林業・靈木採集", "ore": "採礦・靈石與玄銅", "herb": "藥業・靈草與百年草"}[island]
	summary.text = "%s・%s" % [role, "已開拓" if opened else ("金丹解鎖" if island == "herb" and int(view.get("era_id", 1)) < 3 else "待開拓" if enabled else "築基解鎖")]
	summary.visible = not opened or size.y >= 400
	island_picker.tooltip_text = summary.text
	if not enabled:
		var preview: Dictionary = view.get("island_activation", {})
		summary.text += "\n" + String(preview.get("home_policy", "先完成練氣與築基，再保留原檔啟用空島。")) + "\n" + String(preview.get("cost_policy", "")) + "\n" + String(preview.get("reset_policy", ""))
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
		widgets.rate.text = "＋%s／秒" % _amount(float(info.rates[id]))
		widgets.meter.max_value = float(info.capacity)
		widgets.meter.value = float(slot.get("available", 0)) + float(slot.get("reserved", 0))
		widgets.tile.tooltip_text = lines[-1] + "\n容量預留 %s" % str(slot.get("reserved", 0))
	inventory.text = "採集庫存・容量 %s" % _amount(float(info.get("capacity", 0))) if opened and not lines.is_empty() else ""
	inventory.visible = size.y >= 400
	resource_cards.visible = opened
	stock_button.visible = opened
	stock_button.text = "收起本島庫存" if stock_expanded else "展開本島庫存・原料與產物"
	local_stock.visible = opened and stock_expanded
	local_cards.visible = opened and stock_expanded
	var stock_lines: Array[String] = []
	for resource in e.get("inventory", {}).get(island, {}):
		var slot: Dictionary = e.inventory[island][resource]
		if float(slot.available) > 0 or float(slot.reserved) > 0 or info.get("rates", {}).has(resource):
			stock_lines.append("%s：可用%.1f・容量預留%.1f" % [_resource_name(resource), float(slot.available), float(slot.reserved)])
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
	job_status.text = "產線閒置" if job.is_empty() else "%s・%s" % [_resource_name(job.recipe_id), status_text(job.status)]
	for id in facility_buttons:
		var level := int(e.get("islands", {}).get(island, {}).get("facilities", {}).get(id, 1))
		var prices: Array[String] = []
		var cost := IslandProgression.upgrade_cost(id, level)
		for resource in cost:
			prices.append("%s%d（可用%.1f）" % [_resource_name(resource), cost[resource], _home_available(resource)])
		var effects: Array[String] = []
		if id == "storage":
			effects.append("容量%d→%d" % [100 * level, 100 * mini(3, level + 1)])
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
	world_button.text = "前往%s" % IslandProgression.NAMES[island]
	short_world_button.tooltip_text = world_button.text

func _tile(parent: Node) -> Control:
	var tile := IslandTile.new()
	tile.caption.add_theme_font_size_override("font_size", 16)
	parent.add_child(tile)
	return tile

func _stock_tile(tile: Control, resource: String, available: float, title: String) -> void:
	tile.refresh(resource, _resource_name(resource), available, available, IslandProgression.NAMES[island], true)
	tile.quantity.text = _amount(available)
	tile.caption.text = title

func _amount(value: float) -> String:
	if value >= 10000:
		return "%.1f萬" % (value / 10000.0)
	return str(int(value)) if value == floorf(value) else "%.1f" % value

func _home_available(resource: String) -> float:
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
