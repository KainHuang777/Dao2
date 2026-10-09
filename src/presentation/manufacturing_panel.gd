extends "res://src/presentation/island_management_panel.gd"
## Presentation-only cards and one detail workspace for the existing island jobs.
const MaterialTile = preload("res://src/presentation/recipe_material_tile.gd")
var island_filter := ""
var category := "精煉"
var filter_picker: OptionButton
var category_row: HBoxContainer
var category_buttons := {}
var selected_recipe := ""
var cards := {}
var production_summary: Label
var detail_progress: ProgressBar
var grid: GridContainer
var list_box: VBoxContainer
var detail_box: VBoxContainer
var detail_title: Label
var detail_stock: Label
var detail_status: Label
var detail_materials: Dictionary = {}
var start_button: Button
var stop_button: Button
var workshop_button: Button
var supply_button: Button
var back_button: Button
var mode: OptionButton
var batch_count: SpinBox
var reserves := {}
var advanced: VBoxContainer
var list_scroll := 0
var compact_cards := false
signal transport_requested(route_id: String)

func _ready() -> void:
	super._ready()
	filter_picker = OptionButton.new()
	filter_picker.custom_minimum_size = Vector2(112, 44)
	filter_picker.add_item("全部空島")
	for id in IslandProgression.NAMES:
		filter_picker.add_item(IslandProgression.NAMES[id])
	filter_picker.item_selected.connect(func(index: int): island_filter = "" if index == 0 else String(IslandProgression.NAMES.keys()[index - 1]); _refresh_cards())
	heading_label.get_parent().add_child(filter_picker)
	heading_label.get_parent().move_child(filter_picker, 1)
	category_row = HBoxContainer.new()
	heading_label.get_parent().add_child(category_row)
	heading_label.get_parent().move_child(category_row, 2)
	for text in ["精煉", "合成"]:
		category_buttons[text] = _add_button(category_row, text, func(): category = text; _refresh_cards())
	back_button = _add_button(heading_label.get_parent(), "返回配方", back_to_list)
	back_button.visible = false

func _rebuild() -> void:
	if body == null:
		return
	_clear_body()
	cards.clear()
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	body.add_child(list_box)
	production_summary = _label("")
	list_box.add_child(production_summary)
	grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	list_box.add_child(grid)
	for id in IslandEconomy.DURATIONS:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
		grid.add_child(card)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(column)
		var row := HBoxContainer.new()
		column.add_child(row)
		var title := _add_button(row, "", func(): select_recipe(id))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size.x = 100
		var action := _add_button(row, "", func(): _card_action(id))
		action.custom_minimum_size.x = 112
		var materials := HBoxContainer.new()
		materials.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(materials)
		var time := _label("")
		column.add_child(time)
		var progress := ProgressBar.new()
		progress.show_percentage = false
		progress.custom_minimum_size.y = 8
		column.add_child(progress)
		column.move_child(progress, 1)
		var status := _label("")
		column.add_child(status)
		column.move_child(status, 2)
		var compact_row := HBoxContainer.new()
		compact_row.visible = false
		compact_row.add_theme_constant_override("separation", 12)
		column.add_child(compact_row)
		var sidebar := VBoxContainer.new()
		sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sidebar.custom_minimum_size.x = 220
		compact_row.add_child(sidebar)
		cards[id] = {"root": card, "column": column, "header": row, "compact_row": compact_row, "sidebar": sidebar, "title": title, "materials": materials, "tiles": {}, "time": time, "progress": progress, "status": status, "action": action}
		_layout_card(cards[id])
	detail_box = VBoxContainer.new()
	detail_box.visible = false
	detail_box.add_theme_constant_override("separation", 10)
	body.add_child(detail_box)

func select_recipe(id: String) -> void:
	if not cards.has(id) or _catalog.is_empty():
		return
	if selected_recipe.is_empty():
		list_scroll = body.get_parent().scroll_vertical
	selected_recipe = id
	for child in detail_box.get_children():
		detail_box.remove_child(child)
		child.queue_free()
	reserves.clear()
	var info: Dictionary = _view.manufacturing.recipes[id]
	island = info.island
	detail_title = _label("")
	detail_box.add_child(detail_title)
	var materials := HBoxContainer.new()
	materials.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_box.add_child(materials)
	detail_materials = {"materials": materials, "tiles": {}}
	detail_stock = _label("")
	detail_box.add_child(detail_stock)
	detail_status = _label("")
	detail_box.add_child(detail_status)
	detail_progress = ProgressBar.new()
	detail_progress.show_percentage = false
	detail_progress.custom_minimum_size.y = 8
	detail_box.add_child(detail_progress)
	mode = OptionButton.new()
	mode.custom_minimum_size.y = 44
	for text in ["單批", "指定批數", "持續製作"]:
		mode.add_item(text)
	detail_box.add_child(mode)
	batch_count = SpinBox.new()
	batch_count.min_value = 1
	batch_count.max_value = 1000000
	batch_count.value = 1
	batch_count.prefix = "批數 "
	batch_count.custom_minimum_size.y = 44
	batch_count.visible = false
	detail_box.add_child(batch_count)
	mode.item_selected.connect(func(index: int): batch_count.visible = index == 1)
	_add_button(detail_box, "進階設定・原料保留量", func(): advanced.visible = not advanced.visible)
	advanced = VBoxContainer.new()
	advanced.visible = false
	detail_box.add_child(advanced)
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(island, {})
	for resource in _catalog.recipes[id].inputs:
		var field := SpinBox.new()
		field.max_value = 1000000000000
		field.prefix = _resource_name(resource) + "保留 "
		field.custom_minimum_size.y = 44
		field.value = float(job.get("reserves", {}).get(resource, 0)) if job.get("recipe_id") == id else 0.0
		advanced.add_child(field)
		reserves[resource] = field
	start_button = _add_button(detail_box, "開始製造", _submit_work)
	stop_button = _add_button(detail_box, "本批後停止", func(): action_requested.emit("stop_processing", {"island_id": island}))
	workshop_button = _add_button(detail_box, "", func():
		if island == "home":
			page_requested.emit("buildings", island)
		else:
			action_requested.emit("upgrade_island_facility", {"island_id": island, "facility_id": "workshop"}))
	supply_button = _add_button(detail_box, "", _open_supply)
	list_box.visible = false
	detail_box.visible = true
	back_button.visible = true
	filter_picker.visible = false
	category_row.visible = false
	body.get_parent().scroll_vertical = 0
	_refresh_detail()

func back_to_list() -> void:
	selected_recipe = ""
	detail_box.visible = false
	list_box.visible = true
	back_button.visible = false
	filter_picker.visible = true
	category_row.visible = true
	body.get_parent().set_deferred("scroll_vertical", list_scroll)
	_refresh_cards()

func _submit_work() -> void:
	var policy := {}
	for resource in reserves:
		policy[resource] = str(reserves[resource].value)
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(island, {})
	action_requested.emit("craft" if job.is_empty() else "switch_processing", {"island_id": island, "recipe_id": selected_recipe, "count": int(batch_count.value) if mode.selected == 1 else 1, "repeat": mode.selected == 2, "reserves": policy})

func _card_action(id: String) -> void:
	var info: Dictionary = _view.get("manufacturing", {}).get("recipes", {}).get(id, {})
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(info.get("island", "home"), {})
	if not job.is_empty() and job.recipe_id == id:
		if int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false):
			select_recipe(id)
		else:
			action_requested.emit("stop_processing", {"island_id": info.island})
	elif job.is_empty() and String(info.get("reason", "")).is_empty():
		action_requested.emit("craft", {"island_id": info.island, "recipe_id": id, "count": 1, "repeat": false})
	else:
		select_recipe(id)

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	_view = view
	_catalog = catalog
	if body == null:
		return
	heading_label.text = "製造"
	_refresh_cards()
	if not selected_recipe.is_empty():
		_refresh_detail()

func _job_text(job: Dictionary) -> String:
	var text := "%s・%s・%d秒" % [_resource_name(job.recipe_id), status_text(String(job.status)), int(job.remaining)]
	if job.has("pending"):
		text += "\n本批後切換：" + _resource_name(job.pending.recipe_id)
	elif int(job.get("batches", 0)) == 0 and not bool(job.get("repeat", false)):
		text += "・完成本批後閒置"
	else:
		text += "・持續" if job.get("repeat", false) else "・後續%d批" % int(job.batches)
	return text

func _refresh_cards() -> void:
	if grid == null:
		return
	if filter_picker != null:
		filter_picker.select(0 if island_filter.is_empty() else IslandProgression.NAMES.keys().find(island_filter) + 1)
	for text in category_buttons:
		if not category_buttons[text].has_meta("selection") or bool(category_buttons[text].get_meta("selection", false)) != (text == category):
			category_buttons[text].toggle_mode = true
			category_buttons[text].button_pressed = text == category
			UiMaterial.mark_selected(category_buttons[text], text == category)
			category_buttons[text].set_meta("selection", text == category)
	var running := 0
	var waiting := 0
	var total := 0
	var jobs: Dictionary = _view.get("economy", {}).get("jobs", {})
	var active_names: Array[String] = []
	for id in IslandProgression.NAMES:
		if not island_filter.is_empty() and island_filter != id:
			continue
		if _view.get("manufacturing", {}).get("islands", {}).get(id, {}).get("opened", false):
			total += 1
		var job: Dictionary = jobs.get(id, {})
		if job.is_empty():
			continue
		if int(job.get("remaining", 0)) > 0:
			running += 1
		else:
			waiting += 1
		active_names.append(_resource_name(job.recipe_id))
	production_summary.text = "產線：%d加工・%d等待・%d閒置" % [running, waiting, maxi(0, total - running - waiting)]
	if not active_names.is_empty():
		production_summary.text += "｜" + "、".join(active_names)
	# Short workspaces show each line on its card, keeping the icon row visible.
	production_summary.visible = size.y >= 400.0
	for id in cards:
		var card: Dictionary = cards[id]
		var info: Dictionary = _view.get("manufacturing", {}).get("recipes", {}).get(id, {})
		if info.is_empty():
			continue
		var refining: bool = id in ["spirit_timber", "bronze_essence", "liquid", "stone_mid"]
		card.root.visible = (island_filter.is_empty() or info.island == island_filter) and (refining if category == "精煉" else not refining)
		card.title.text = "%s・%s" % [_resource_name(id), IslandProgression.NAMES[info.island]]
		_refresh_materials(card, id, info)
		card.time.text = "%d秒／批" % int(info.duration)
		var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(info.island, {})
		var current: bool = job.get("recipe_id") == id
		var pending: bool = job.get("pending", {}).get("recipe_id") == id
		_update_progress(card.progress, job if current else {}, float(info.duration))
		var stock: Dictionary = _view.get("economy", {}).get("inventory", {}).get(info.island, {}).get(id, {})
		card.time.text += "・庫存%.1f" % float(stock.get("available", 0))
		card.status.text = _job_text(job) if current else "本批後切換至此配方" if pending else "產線使用中：" + _resource_name(job.recipe_id) if not job.is_empty() else "" if String(info.reason).is_empty() or info.reason == "INSUFFICIENT_RESOURCE" else reason_text(info.reason)
		card.status.visible = not card.status.text.is_empty()
		if compact_cards and current:
			card.status.text = "%s・%d秒" % [status_text(String(job.status)), int(job.remaining)]
			if job.has("pending"):
				card.status.text += "・待切方"
			elif finishing_job(job):
				card.status.text += "・收尾"
		var finishing: bool = current and int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)
		card.action.text = "單批收尾・設定" if finishing else ("立即停止" if int(job.get("remaining", 0)) == 0 else "本批後停止") if current else "查看／切方" if not job.is_empty() else "製作一批" if String(info.reason).is_empty() else "查看詳情"
		card.action.disabled = false

func finishing_job(job: Dictionary) -> bool:
	return int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)

func _layout_card(card: Dictionary) -> void:
	card.compact_row.visible = compact_cards
	if compact_cards:
		if card.materials.get_parent() != card.compact_row:
			card.materials.reparent(card.compact_row)
			card.compact_row.move_child(card.materials, 0)
			card.header.reparent(card.sidebar)
			card.status.reparent(card.sidebar)
			card.time.reparent(card.sidebar)
		card.column.move_child(card.compact_row, 0)
	else:
		for child in [card.header, card.status, card.materials, card.time]:
			if child.get_parent() != card.column:
				child.reparent(card.column)
		for index in 5:
			card.column.move_child([card.header, card.progress, card.status, card.materials, card.time][index], index)

func _refresh_materials(widgets: Dictionary, id: String, info: Dictionary) -> void:
	if widgets.tiles.is_empty():
		for resource in info.inputs:
			var tile := MaterialTile.new()
			widgets.materials.add_child(tile)
			widgets.tiles[resource] = tile
		var arrow := UiIcon.new()
		arrow.kind = UiIcon.Kind.ARROW
		arrow.tint = UiMaterial.INK
		arrow.icon_size = 24
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		widgets.materials.add_child(arrow)
		var output := MaterialTile.new()
		widgets.materials.add_child(output)
		widgets["output_tile"] = output
	for resource in info.inputs:
		var input: Dictionary = info.inputs[resource]
		widgets.tiles[resource].refresh(resource, _resource_name(resource), float(input.required), float(input.available), IslandProgression.NAMES[input.source])
	var stock: Dictionary = _view.get("economy", {}).get("inventory", {}).get(info.island, {}).get(id, {})
	widgets.output_tile.refresh(id, _resource_name(id), float(info.output), float(stock.get("available", 0)), IslandProgression.NAMES[info.island], true)

func _update_progress(bar: ProgressBar, job: Dictionary, duration: float) -> void:
	bar.visible = not job.is_empty() and int(job.get("remaining", 0)) > 0
	var value := 100.0 * clampf(1.0 - float(job.get("remaining", 0)) / maxf(1.0, duration), 0.0, 1.0) if bar.visible else 0.0
	if bar.value != value:
		bar.value = value

static func reason_text(code: String) -> String:
	return {"ECONOMY_NOT_MIGRATED": "先啟用空島", "ISLAND_NOT_OPEN": "先開拓此島", "ERA_REQUIREMENT": "境界未解鎖", "FACILITY_REQUIREMENT": "先升級洞府設施", "RESOURCE_LOCKED": "資源未解鎖", "RECIPE_ISLAND_REQUIREMENT": "先接續丹霞版本", "INSUFFICIENT_RESOURCE": "缺料・查看詳情", "OUTPUT_FULL": "產物滿倉"}.get(code, code)

func _refresh_detail() -> void:
	var info: Dictionary = _view.manufacturing.recipes[selected_recipe]
	_refresh_materials(detail_materials, selected_recipe, info)
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(island, {})
	detail_title.text = "%s・%s・%d秒／批" % [_resource_name(selected_recipe), IslandProgression.NAMES[island], int(info.duration)]
	var stock: Array[String] = []
	for resource in info.inputs:
		var input: Dictionary = info.inputs[resource]
		stock.append("%s：%s可用 %.1f／需求 %.1f" % [_resource_name(resource), "祖島" if input.source == "home" else "當地", float(input.available), float(input.required)])
		for route in IslandEconomy.ROUTES:
			if IslandEconomy.ROUTES[route][1] == island and IslandEconomy.ROUTES[route][2] == resource:
				var trip: Dictionary = _view.get("economy", {}).get("trips", {}).get(route, {})
				if not trip.is_empty():
					stock.append("在途到貨 %.1f・%d秒" % [float(trip.cargo), int(trip.remaining)])
	var slot: Dictionary = _view.get("economy", {}).get("inventory", {}).get(island, {}).get(selected_recipe, {})
	var incoming := 0.0
	for route in _view.get("economy", {}).get("trips", {}):
		if IslandEconomy.ROUTES[route][1] == island and IslandEconomy.ROUTES[route][2] == selected_recipe:
			incoming += float(_view.economy.trips[route].cargo)
	var processing := float(_catalog.recipes[selected_recipe].output) if job.get("recipe_id") == selected_recipe and int(job.get("remaining", 0)) > 0 else 0.0
	stock.append("產物可用 %.1f／容量 %.0f\n在途 %.1f・加工待完成 %.1f・容量預留 %.1f" % [float(slot.get("available", 0)), float(info.capacity), incoming, processing, float(slot.get("reserved", 0))])
	detail_stock.text = "\n".join(stock)
	detail_status.text = "尚未開始" if job.is_empty() else _job_text(job)
	var duration: float = _view.manufacturing.recipes.get(job.get("recipe_id", ""), {}).get("duration", info.duration)
	_update_progress(detail_progress, job, duration)
	if not String(info.reason).is_empty():
		detail_status.text += "\n" + ("下一批：" if job.get("recipe_id") == selected_recipe and int(job.get("remaining", 0)) > 0 else "") + reason_text(info.reason)
	start_button.text = "開始製造" if job.is_empty() else "立即切換" if int(job.remaining) == 0 else "本批後切換"
	start_button.disabled = not String(info.reason).is_empty() and (job.is_empty() or not info.reason in ["INSUFFICIENT_RESOURCE", "OUTPUT_FULL"])
	stop_button.visible = not job.is_empty()
	stop_button.text = "立即停止" if int(job.get("remaining", 0)) == 0 else "本批後停止"
	stop_button.disabled = not job.is_empty() and int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)
	if stop_button.disabled:
		stop_button.text = "完成本批後閒置"
	var level := int(_view.get("economy", {}).get("islands", {}).get(island, {}).get("facilities", {}).get("workshop", 1))
	var prices: Array[String] = []
	for resource in IslandProgression.upgrade_cost("workshop", level):
		prices.append("%s%d" % [_resource_name(resource), IslandProgression.upgrade_cost("workshop", level)[resource]])
	workshop_button.text = "祖島設施・洞府建築" if island == "home" else "加工坊%d階・%d→%d秒／批\n%s" % [level, int(info.duration), int(ceil(10.0 / mini(3, level + 1))), "已達上限" if level >= 3 else "祖島支付：" + "＋".join(prices)]
	workshop_button.disabled = island != "home" and (level >= 3 or not bool(_view.manufacturing.islands[island].opened))
	supply_button.text = "處理缺料／滿倉"
	supply_button.visible = not String(info.reason).is_empty()

func _open_supply() -> void:
	var info: Dictionary = _view.manufacturing.recipes[selected_recipe]
	if info.reason in ["ECONOMY_NOT_MIGRATED", "ISLAND_NOT_OPEN", "RECIPE_ISLAND_REQUIREMENT", "ERA_REQUIREMENT"]:
		page_requested.emit("outposts", island)
		return
	if info.reason in ["FACILITY_REQUIREMENT", "RESOURCE_LOCKED"]:
		page_requested.emit("buildings", "home")
		return
	if info.reason == "OUTPUT_FULL":
		for route in IslandEconomy.ROUTES:
			var def: Array = IslandEconomy.ROUTES[route]
			if def[0] == island and def[2] == selected_recipe:
				transport_requested.emit(route)
				return
		page_requested.emit("buildings" if island == "home" else "outposts", island)
		return
	for resource in info.inputs:
		var input: Dictionary = info.inputs[resource]
		if float(input.available) < float(input.required):
			if resource in IslandEconomy.GLOBAL:
				page_requested.emit("buildings", "home")
			elif IslandEconomy.ISLANDS[island].rates.has(resource):
				page_requested.emit("outposts", island)
			else:
				for route in IslandEconomy.ROUTES:
					var def: Array = IslandEconomy.ROUTES[route]
					if def[1] == island and def[2] == resource:
						transport_requested.emit(route)
						return
				# Some recipes have no fixed incoming route for this material.
				page_requested.emit("buildings" if island == "home" else "outposts", island)
			return

func set_layout_bounds(bounds: Rect2) -> void:
	super.set_layout_bounds(bounds)
	compact_cards = bounds.size.y < 400.0 and bounds.size.x >= 620.0
	if production_summary != null:
		production_summary.visible = bounds.size.y >= 400.0
	if grid != null:
		var columns := 2 if bounds.size.x >= 800 and bounds.size.y >= 400 else 1
		if grid.columns != columns:
			grid.columns = columns
		for card in cards.values():
			_layout_card(card)
		_refresh_cards()

func reset_context(filter_id: String = "") -> void:
	island_filter = filter_id
	if not selected_recipe.is_empty():
		back_to_list()
	_refresh_cards()
