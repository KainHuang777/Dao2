extends "res://src/presentation/island_management_panel.gd"
## Presentation-only recipe rows with one shared inline settings accordion.
const MaterialTile = preload("res://src/presentation/recipe_material_tile.gd")
const RecipeRow = preload("res://src/presentation/recipe_row.gd")
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
var detail_costs
var workshop_costs
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
var production := ProductionController.new()
var recipe_drafts := {}
signal transport_requested(route_id: String)

func _ready() -> void:
	super._ready()
	filter_picker = OptionButton.new()
	filter_picker.custom_minimum_size = Vector2(112, 44)
	filter_picker.add_item("全部產線")
	for id in IslandProgression.NAMES:
		filter_picker.add_item(IslandProgression.NAMES[id])
	filter_picker.item_selected.connect(func(index: int): island_filter = "" if index == 0 else String(IslandProgression.NAMES.keys()[index - 1]); _refresh_cards(); context_changed.emit())
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
	for id in (_catalog.get("recipes", IslandEconomy.DURATIONS)):
		var row := RecipeRow.new()
		row.setup(id, func(): toggle_recipe(id), func(): _card_action(id))
		row.mode_requested.connect(_set_recipe_mode)
		grid.add_child(row)
		cards[id] = row.as_card_dict()
		_layout_card(cards[id])
	detail_box = VBoxContainer.new()
	detail_box.visible = false
	detail_box.add_theme_constant_override("separation", 10)
	body.add_child(detail_box)

func select_recipe(id: String) -> void:
	if not cards.has(id) or _catalog.is_empty():
		return
	_store_draft()
	if selected_recipe.is_empty():
		list_scroll = body.get_parent().scroll_vertical
	selected_recipe = id
	var refining := id in ["spirit_timber", "bronze_essence", "liquid", "stone_mid", "stone_mid_bulk", "stone_high"]
	category = "精煉" if refining else "合成"
	if not island_filter.is_empty() and island_filter != _view.manufacturing.recipes[id].island:
		island_filter = ""
	detail_box.reparent(cards[id].column)
	for child in detail_box.get_children():
		detail_box.remove_child(child)
		child.queue_free()
	reserves.clear()
	var info: Dictionary = _view.manufacturing.recipes[id]
	island = info.island
	detail_title = _label("")
	detail_box.add_child(detail_title)
	detail_title.visible = false
	detail_costs = CostStrip.new()
	detail_box.add_child(detail_costs)
	detail_materials = cards[id]
	detail_stock = _label("")
	detail_box.add_child(detail_stock)
	detail_status = _label("")
	detail_box.add_child(detail_status)
	detail_progress = cards[id].progress
	mode = OptionButton.new()
	mode.custom_minimum_size.y = 44
	for text in ["單批", "指定批數", "持續製作"]:
		mode.add_item(text)
	detail_box.add_child(mode)
	# The mode is chosen on the row; keep its value here for the settings form.
	mode.visible = false
	mode.select(int(production.pref(id).mode))
	batch_count = SpinBox.new()
	batch_count.min_value = 1
	batch_count.max_value = 1000000
	batch_count.value = int(production.pref(id).count)
	batch_count.prefix = "批數 "
	batch_count.custom_minimum_size.y = 44
	batch_count.visible = mode.selected == ProductionController.Mode.COUNT
	detail_box.add_child(batch_count)
	detail_box.move_child(batch_count, 0)
	batch_count.value_changed.connect(func(value: float):
		production.set_pref(selected_recipe, mode.selected, int(value))
		_refresh_cards())
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
		field.value = float(recipe_drafts.get(id, {}).get(resource, job.get("reserves", {}).get(resource, 0) if job.get("recipe_id") == id else 0.0))
		advanced.add_child(field)
		reserves[resource] = field
	start_button = _add_button(detail_box, "開始製造", _submit_work)
	stop_button = _add_button(detail_box, "本批後停止", func(): action_requested.emit("stop_processing", {"island_id": island}))
	workshop_button = _add_button(detail_box, "", func():
		if island == "home":
			page_requested.emit("buildings", island)
		else:
			action_requested.emit("upgrade_island_facility", {"island_id": island, "facility_id": "workshop"}))
	workshop_costs = CostStrip.new()
	detail_box.add_child(workshop_costs)
	supply_button = _add_button(detail_box, "", _open_supply)
	list_box.visible = true
	detail_box.visible = true
	back_button.text = "收起"
	back_button.visible = true
	_refresh_cards()
	_refresh_detail()
	_reveal_settings.call_deferred(id)
	context_changed.emit()

func toggle_recipe(id: String) -> void:
	if selected_recipe == id:
		back_to_list()
	else:
		select_recipe(id)

func _reveal_settings(id: String) -> void:
	await get_tree().process_frame
	if selected_recipe == id:
		body.get_parent().ensure_control_visible(cards[id].header)

func _store_draft() -> void:
	if selected_recipe.is_empty() or not is_instance_valid(mode):
		return
	production.set_pref(selected_recipe, mode.selected, int(batch_count.value))
	var policy := {}
	for resource in reserves:
		policy[resource] = reserves[resource].value
	recipe_drafts[selected_recipe] = policy

func _set_recipe_mode(id: String, index: int) -> void:
	_store_draft()
	production.set_pref(id, index, int(production.pref(id).count))
	if selected_recipe == id:
		mode.select(index)
		batch_count.visible = index == ProductionController.Mode.COUNT
	elif index == ProductionController.Mode.COUNT:
		select_recipe(id)
	_refresh_cards()

func back_to_list() -> void:
	_store_draft()
	selected_recipe = ""
	detail_box.visible = false
	detail_box.reparent(body)
	list_box.visible = true
	back_button.visible = false
	filter_picker.visible = true
	category_row.visible = true
	body.get_parent().set_deferred("scroll_vertical", list_scroll)
	_refresh_cards()

func _submit_work() -> void:
	if selected_recipe.is_empty() or start_button.disabled:
		return
	_store_draft()
	var policy := {}
	for resource in reserves:
		policy[resource] = str(reserves[resource].value)
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(island, {})
	action_requested.emit(ProductionController.start_command(job), ProductionController.work_payload(island, selected_recipe, mode.selected, int(batch_count.value), policy))

func _card_action(id: String) -> void:
	var info: Dictionary = _view.get("manufacturing", {}).get("recipes", {}).get(id, {})
	var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(info.get("island", "home"), {})
	if ProductionController.is_running(job, id):
		if not ProductionController.finishing(job):
			_stop(info.island, job)
	elif job.is_empty() and String(info.get("reason", "")).is_empty():
		_start(id, info, job)

func _start(id: String, info: Dictionary, job: Dictionary) -> void:
	_store_draft()
	var action := ProductionController.start_action(job, info, id, production.pref(id))
	if not String(action.command).is_empty():
		# Settings and quick-start use the same per-recipe reserve draft.
		var policy := {}
		for resource in recipe_drafts.get(id, {}):
			policy[resource] = str(recipe_drafts[id][resource])
		action.payload.reserves = policy
		action_requested.emit(action.command, action.payload)

func _stop(island_id: String, job: Dictionary) -> void:
	var action := ProductionController.stop_action(job, island_id)
	if not String(action.command).is_empty():
		action_requested.emit(action.command, action.payload)

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	_view = view
	_catalog = catalog
	if body == null:
		return
	if cards.size() != _catalog.get("recipes", {}).size(): _rebuild()
	heading_label.text = "製造"
	_refresh_cards()
	if not selected_recipe.is_empty():
		_refresh_detail()

func _job_text(job: Dictionary) -> String:
	var text := "%s・%s・%d秒" % [_recipe_name(job.recipe_id), status_text(String(job.status)), int(job.remaining)]
	if job.has("pending"):
		text += "\n本批後切換：" + _recipe_name(job.pending.recipe_id)
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
			UiMaterial.mark_paper_tab(category_buttons[text], text == category)
			category_buttons[text].set_meta("selection", text == category)
	var running := 0
	var waiting := 0
	var total := 0
	var jobs: Dictionary = _view.get("economy", {}).get("jobs", {})
	var active_names: Array[String] = []
	for id in ["home", "wood", "ore", "herb"]:
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
		active_names.append(_recipe_name(job.recipe_id))
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
		var refining: bool = id in ["spirit_timber", "bronze_essence", "liquid", "stone_mid", "stone_mid_bulk", "stone_high"]
		card.root.visible = (island_filter.is_empty() or info.island == island_filter) and (refining if category == "精煉" else not refining)
		card.title.text = "%s・%s" % [_recipe_name(id), _production_label(info.island)]
		_refresh_materials(card, id, info)
		card.time.text = "%d秒／批" % int(info.duration)
		var job: Dictionary = _view.get("economy", {}).get("jobs", {}).get(info.island, {})
		var current: bool = job.get("recipe_id") == id
		var pending: bool = job.get("pending", {}).get("recipe_id") == id
		_update_progress(card.progress, job if current else {}, float(info.duration))
		var stock: Dictionary = _view.get("economy", {}).get("inventory", {}).get(info.get("output_island",info.island), {}).get(info.get("product_id", id), {})
		card.time.text += "・庫存%.1f" % float(stock.get("available", 0))
		card.status.text = _job_text(job) if current else "本批後切換至此配方" if pending else "產線使用中：" + _recipe_name(job.recipe_id) if not job.is_empty() else "" if String(info.reason).is_empty() or info.reason == "INSUFFICIENT_RESOURCE" else reason_text(info.reason)
		card.status.visible = not card.status.text.is_empty()
		if compact_cards and current:
			card.status.text = "%s・%d秒" % [status_text(String(job.status)), int(job.remaining)]
			if job.has("pending"):
				card.status.text += "・待切方"
			elif finishing_job(job):
				card.status.text += "・收尾"
		var finishing: bool = current and int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)
		card.action.text = "本批收尾" if finishing else ("停止" if int(job.get("remaining", 0)) == 0 else "批後停止") if current else "開始"
		card.action.disabled = finishing or (not current and (not job.is_empty() or not String(info.reason).is_empty()))
		card.action.tooltip_text = "完成本批後閒置" if finishing else "停止後續批次，當前加工仍會完成" if current else "同島產線使用中；展開設定可明確切方" if not job.is_empty() else reason_text(info.reason) if not String(info.reason).is_empty() else "依列上模式開始製造"
		if card.has("row"):
			var pref_state := production.pref(id)
			var shown_mode: int = ProductionController.Mode.REPEAT if current and job.get("repeat", false) else ProductionController.Mode.COUNT if current and int(job.get("batches", 0)) > 0 else ProductionController.Mode.SINGLE if current else int(pref_state.mode)
			card.row.show_mode(shown_mode, int(job.get("batches", 0)) + 1 if current else int(pref_state.count))
			for chip in card.row.modes._buttons:
				chip.disabled = current
				chip.tooltip_text = "加工中的模式由當前產線決定；停止後可重新選擇" if current else "選擇模式；批數可於就地設定調整"
			card.row.settings.text = "收起" if selected_recipe == id else "設定"
			card.row.set_island("home" if _central() else info.island)
			card.row.recipe_badge.tooltip_text += "\n" + card.time.text
			var row_obj: RecipeRow = card.row
			if current:
				row_obj.set_state_visual(RecipeRow.COLOR_RUNNING, true)
				row_obj.status_icon.visible = true
				row_obj.status_icon.kind = UiIcon.Kind.PLAY
				row_obj.status_icon.tint = RecipeRow.COLOR_RUNNING
			elif pending:
				row_obj.set_state_visual(RecipeRow.COLOR_PENDING, true)
				row_obj.status_icon.visible = true
				row_obj.status_icon.kind = UiIcon.Kind.REFRESH
				row_obj.status_icon.tint = RecipeRow.COLOR_PENDING
			elif info.get("reason") == "INSUFFICIENT_RESOURCE":
				row_obj.set_state_visual(RecipeRow.COLOR_SHORTAGE, false)
				row_obj.status_icon.visible = false
			elif info.get("reason") == "OUTPUT_FULL":
				row_obj.set_state_visual(RecipeRow.COLOR_OUTPUT_FULL, false)
				row_obj.status_icon.visible = false
			else:
				row_obj.set_state_visual(RecipeRow.COLOR_IDLE, false)
				row_obj.status_icon.visible = false
		if card.has("row"): card.row.set_product(String(info.get("product_id", id)), _recipe_name(id))

func finishing_job(job: Dictionary) -> bool:
	return int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)

func _layout_card(card: Dictionary) -> void:
	if card.has("row"):
		card.row.apply_layout(compact_cards)
		return
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
			tile.show_source_caption = false
			widgets.materials.add_child(tile)
			widgets.tiles[resource] = tile
		var arrow := UiIcon.new()
		arrow.kind = UiIcon.Kind.ARROW
		arrow.tint = UiMaterial.INK
		arrow.icon_size = 24
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		widgets.materials.add_child(arrow)
		var output := MaterialTile.new()
		output.show_source_caption = false
		widgets.materials.add_child(output)
		widgets["output_tile"] = output
	for resource in info.inputs:
		var input: Dictionary = info.inputs[resource]
		widgets.tiles[resource].refresh(resource, _resource_name(resource), float(input.required), float(input.available), IslandProgression.NAMES[input.source])
		widgets.tiles[resource].set_reserved(0.0)
	var stock: Dictionary = _view.get("economy", {}).get("inventory", {}).get(info.get("output_island",info.island), {}).get(info.get("product_id", id), {})
	widgets.output_tile.refresh(String(info.get("product_id", id)), _resource_name(String(info.get("product_id", id))), float(info.output), float(stock.get("available", 0)), IslandProgression.NAMES[info.get("output_island",info.island)], true)
	widgets.output_tile.set_reserved(float(stock.get("reserved", 0)))

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
	detail_title.text = "%s・%s・%d秒／批" % [_recipe_name(selected_recipe), _production_label(island), int(info.duration)]
	var stock: Array[String] = []
	for resource in info.inputs:
		for route in _routes():
			if _routes()[route][1] == String(info.inputs[resource].source) and _routes()[route][2] == resource:
				var trip: Dictionary = _view.get("economy", {}).get("trips", {}).get(route, {})
				if not trip.is_empty():
					stock.append("在途到貨 %.1f・%d秒" % [float(trip.cargo), int(trip.remaining)])
	var slot: Dictionary = _view.get("economy", {}).get("inventory", {}).get(info.get("output_island",island), {}).get(info.get("product_id", selected_recipe), {})
	var incoming := 0.0
	for route in _view.get("economy", {}).get("trips", {}):
		if _routes()[route][1] == info.get("output_island",island) and _routes()[route][2] == info.get("product_id", selected_recipe):
			incoming += float(_view.economy.trips[route].cargo)
	var processing := float(_catalog.recipes[selected_recipe].output) if job.get("recipe_id") == selected_recipe and int(job.get("remaining", 0)) > 0 else 0.0
	stock.append("產物可用 %.1f／容量 %.0f\n在途 %.1f・加工待完成 %.1f・容量預留 %.1f" % [float(slot.get("available", 0)), float(info.capacity), incoming, processing, float(slot.get("reserved", 0))])
	detail_stock.text = "\n".join(stock)
	_refresh_detail_costs(info)
	detail_status.text = "尚未開始" if job.is_empty() else _job_text(job)
	var duration: float = _view.manufacturing.recipes.get(job.get("recipe_id", ""), {}).get("duration", info.duration)
	_update_progress(detail_progress, job, duration)
	if not String(info.reason).is_empty():
		detail_status.text += "\n" + ("下一批：" if job.get("recipe_id") == selected_recipe and int(job.get("remaining", 0)) > 0 else "") + reason_text(info.reason)
	start_button.text = "開始製造" if job.is_empty() else "立即切換" if int(job.remaining) == 0 else "本批後切換"
	start_button.disabled = job.get("recipe_id") == selected_recipe or (not String(info.reason).is_empty() and (job.is_empty() or not info.reason in ["INSUFFICIENT_RESOURCE", "OUTPUT_FULL"]))
	if job.get("recipe_id") == selected_recipe:
		start_button.text = "此配方加工中"
	stop_button.visible = not job.is_empty()
	stop_button.text = "立即停止" if int(job.get("remaining", 0)) == 0 else "本批後停止"
	stop_button.disabled = not job.is_empty() and int(job.get("remaining", 0)) > 0 and not job.has("pending") and int(job.get("batches", 0)) == 0 and not job.get("repeat", false)
	if stop_button.disabled:
		stop_button.text = "完成本批後閒置"
	var level := int(_view.get("economy", {}).get("islands", {}).get(island, {}).get("facilities", {}).get("workshop", 1))
	var workshop_text := "加工坊%d階・%d→%d秒／批" % [level, int(info.duration), int(ceil(10.0 / mini(3, level + 1)))]
	workshop_button.text = "祖島設施・洞府建築" if island == "home" else workshop_text + ("\n已達上限" if level >= 3 else "")
	workshop_button.disabled = island != "home" and (level >= 3 or not bool(_view.manufacturing.islands[island].opened))
	_refresh_workshop_costs(level)
	supply_button.text = "處理缺料／滿倉"
	supply_button.visible = not String(info.reason).is_empty()

func _refresh_detail_costs(info: Dictionary) -> void:
	if detail_costs == null:
		return
	var costs := {}
	var available := {}
	var sources := {}
	var names := {}
	for resource in info.inputs:
		var input: Dictionary = info.inputs[resource]
		costs[resource] = float(input.required)
		available[resource] = float(input.available)
		sources[resource] = "祖島" if String(input.source) == "home" else "當地"
		names[resource] = _resource_name(resource)
	detail_costs.show_costs(costs, names, available, sources, "材料需求", CostStrip.shortage_text(costs, available, names, "缺料"))

func _refresh_workshop_costs(level: int) -> void:
	if workshop_costs == null:
		return
	var opened := bool(_view.get("manufacturing", {}).get("islands", {}).get(island, {}).get("opened", false))
	if island == "home" or level >= 3:
		workshop_costs.clear_costs()
		workshop_costs.visible = false
		return
	var upgrade: Dictionary = IslandProgression.upgrade_cost("workshop", level)
	var home := _home_stock(upgrade)
	var names := {}
	var sources := {}
	for resource in upgrade:
		names[resource] = _resource_name(resource)
		sources[resource] = "祖島"
	var note := "" if opened else "此島尚未開拓"
	if note.is_empty():
		note = CostStrip.shortage_text(upgrade, home, names, "祖島材料不足")
	workshop_costs.visible = true
	workshop_costs.show_costs(upgrade, names, home, sources, "升級加工坊 %d→%d 階" % [level, level + 1], note)

func _central() -> bool:
	return preload("res://src/presentation/island_flow_model.gd").hub(_view)

func _production_label(lane: String) -> String:
	return "祖島・" + ("合成線" if lane == "home" else {"wood":"靈材線","ore":"銅精線","herb":"丹液線"}.get(lane,lane)) if _central() else String(IslandProgression.NAMES[lane])

func _open_supply() -> void:
	var info: Dictionary = _view.manufacturing.recipes[selected_recipe]
	if info.reason == "OUTPUT_FULL":
		page_requested.emit("buildings" if _central() or island == "home" else "outposts","home" if _central() else island)
		return
	var fix := preload("res://src/presentation/island_flow_model.gd").shortage(_view,info,_routes())
	if fix.is_empty():
		page_requested.emit("buildings","home")
	elif fix.page == "transport": transport_requested.emit(fix.id)
	elif fix.page == "manufacturing": select_recipe(fix.id)
	else: page_requested.emit(fix.page,fix.id)

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
	context_changed.emit()
