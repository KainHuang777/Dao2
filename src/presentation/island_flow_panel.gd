extends PanelContainer
## Era2 focused work surface. UI selections survive close/reopen; saves stay canonical.
const Flow = preload("res://src/presentation/island_flow_model.gd")
const Tile = preload("res://src/presentation/recipe_material_tile.gd")
signal action_requested(kind: String, payload: Dictionary)
signal navigate_requested(route: String, id: String)
signal full_requested()
signal retry_requested()
signal context_changed()
var view := {}
var catalog := {}
var page := "outposts"
var island := "ore"
var recipe := "bronze_essence"
var resume_recipe := ""
var route := ""
var _options: Array[String] = []
var _actions: Array[Dictionary] = []
var column: VBoxContainer
var picker: OptionButton
var facility: OptionButton
var mode: OptionButton
var title: Label
var status: Label
var notice: Label
var retry: Button
var materials: HBoxContainer
var buttons: Array[Button] = []
var cells: Array[Control] = []
var progress: ProgressBar
var _glow: Tween
var _glowing: Button
var reduced_motion := false
var steps := {}
var flow_arrow: UiIcon
var content_row: BoxContainer
var operation_box: VBoxContainer
var action_row: HBoxContainer
var full_button: Button
var compact_layout := false
var island_scroll: ScrollContainer
var island_rows := {}
var managing_island := false
var list_back: Button
var list_heading: Label
var work_surface: VBoxContainer
var work_selection: HFlowContainer
var _work_island := ""
var hub_upgrade: Button
var selection_header: HBoxContainer

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	for entry in [["outposts", "總覽"], ["manufacturing", "製造"], ["transport", "運輸"], ["facilities", "設施"]]:
		var button := GameTab.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(88,44)
		button.pressed.connect(func(): _select_work(entry[0]))
		head.add_child(button)
		steps[entry[0]] = button
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var full := _button(head, "完整管理", func(): full_requested.emit())
	full_button = full
	full.tooltip_text = "批數、保留量、航線目標與全部設施；原有設定保留"
	var selection := HBoxContainer.new()
	selection_header = selection
	column.add_child(selection)
	picker = OptionButton.new()
	picker.custom_minimum_size.y = 44
	picker.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	selection.add_child(picker)
	picker.item_selected.connect(func(index: int):
		if page == "outposts": island = _options[index]
		elif page == "manufacturing": recipe = _options[index]
		else: route = _options[index]
		refresh(view,catalog)
		context_changed.emit())
	facility = OptionButton.new()
	for text in ["開拓／概覽", "採集升級", "倉儲升級", "加工坊升級"]: facility.add_item(text)
	facility.custom_minimum_size.y = 44
	selection.add_child(facility)
	facility.item_selected.connect(func(_index: int):
		refresh(view,catalog)
		context_changed.emit())
	mode = OptionButton.new()
	mode.add_item("單批")
	mode.add_item("持續")
	mode.item_selected.connect(func(_index: int): refresh(view,catalog))
	mode.custom_minimum_size.y = 44
	selection.add_child(mode)
	full.reparent(selection)
	list_back = _button(selection, "返回空島清單", func():
		managing_island = false
		navigate_requested.emit("outposts", ""))
	selection.move_child(list_back,0)
	list_back.hide()
	list_heading = _label(selection)
	list_heading.text = "空島開拓"
	list_heading.add_theme_font_override("font",UiTypography.emphasis_font())
	list_heading.add_theme_font_size_override("font_size",22)
	list_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection.move_child(list_heading,0)
	list_heading.hide()
	hub_upgrade = _button(column,"改用祖島集中製造（保留原檔）",func(): action_requested.emit("activate_hub",{}))
	hub_upgrade.tooltip_text = "原料運回祖島加工；保留已開拓產地與並行產線。舊在途與加工批次仍會完成，舊庫存可回運。"
	hub_upgrade.hide()
	column.move_child(head,1)
	work_surface = VBoxContainer.new()
	work_surface.add_theme_constant_override("separation",8)
	column.add_child(work_surface)
	work_selection = HFlowContainer.new()
	work_selection.add_theme_constant_override("h_separation",8)
	work_surface.add_child(work_selection)
	for control in [picker,facility,mode,list_back]: control.reparent(work_selection)
	list_back.text = "收起操作"
	title = _label(column)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.reparent(work_surface)
	island_scroll = ScrollContainer.new()
	island_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	island_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(island_scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12)
	island_scroll.add_child(rows)
	for id in ["ore","home","wood","herb"]: _add_island_row(rows,id)
	island_scroll.hide()
	content_row = BoxContainer.new()
	content_row.vertical = true
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content_row)
	content_row.reparent(work_surface)
	materials = HBoxContainer.new()
	materials.alignment = BoxContainer.ALIGNMENT_BEGIN
	materials.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content_row.add_child(materials)
	for n in 7:
		var tile := Tile.new()
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		materials.add_child(tile)
		cells.append(tile)
	flow_arrow = UiIcon.new()
	flow_arrow.kind = UiIcon.Kind.ARROW
	flow_arrow.tint = UiMaterial.INK
	flow_arrow.icon_size = 24
	flow_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	materials.add_child(flow_arrow)
	operation_box = VBoxContainer.new()
	operation_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operation_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_row.add_child(operation_box)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 6
	operation_box.add_child(progress)
	status = _label(operation_box)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := HBoxContainer.new()
	action_row = actions
	operation_box.add_child(actions)
	for n in 3:
		var button := _button(actions, "", func(): _invoke(n))
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		buttons.append(button)
	# Feedback is fixed below the list as well as the focused work surface.
	notice = _label(column)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.hide()
	retry = _button(column, "重試保存", func(): retry_requested.emit())
	retry.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	retry.hide()
	visibility_changed.connect(func():
		if not is_visible_in_tree(): _stop_glow())

func _add_island_row(parent: VBoxContainer, id: String) -> void:
	var group := VBoxContainer.new()
	parent.add_child(group)
	var row := BoxContainer.new()
	row.add_theme_constant_override("separation",16)
	group.add_child(row)
	var art := UiIllustration.new()
	art.custom_minimum_size = Vector2(128,96)
	var select := Button.new()
	select.custom_minimum_size = art.custom_minimum_size
	select.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	select.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	select.pressed.connect(func(): _select_island(id))
	row.add_child(select)
	select.add_child(art)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var heading := _label(info)
	heading.text = IslandProgression.NAMES[id]
	heading.add_theme_font_size_override("font_size",22)
	heading.add_theme_font_override("font",UiTypography.emphasis_font())
	var description := _label(info)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.text = {"home":"接收回運材料，合成修行與建設所需物品。", "wood":"採集木材，供應靈材加工。", "ore":"採集靈石與玄銅，供應精煉與跨島製造。", "herb":"採集靈草，供應丹液加工。"}[id]
	var state := _label(info)
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var work := VBoxContainer.new()
	work.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(work)
	var costs := HBoxContainer.new()
	costs.add_theme_constant_override("separation",8)
	work.add_child(costs)
	var tiles: Array = []
	for resource in ["wood","stone_low"]:
		var tile := Tile.new()
		costs.add_child(tile)
		tiles.append(tile)
	var action := _button(costs,"開拓",func(): _island_row_action(id))
	action.custom_minimum_size = Vector2(104,48)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var remedy := _button(work,"",func():
		var fix: Dictionary = Flow.opening(view,id)
		if not fix.is_empty(): navigate_requested.emit(fix.page,fix.id))
	remedy.hide()
	var payment := _label(work)
	payment.text = "祖島支付・開拓後自動採集"
	group.add_child(HSeparator.new())
	island_rows[id] = {"group":group,"row":row,"art":art,"select":select,"heading":heading,"state":state,"tiles":tiles,"costs":costs,"action":action,"payment":payment,"remedy":remedy}

func _island_route(id: String) -> String:
	for route_id in _routes():
		var ends: Array = _routes()[route_id]
		if Flow.hub(view) and bool(view.get("transport",{}).get(route_id,{}).get("legacy",false)): continue
		if not Flow.opened(view,ends[0]) or not Flow.opened(view,ends[1]): continue
		if ends[0] == id or (id == "home" and ends[1] == id):
			if Flow.hub(view) and id == "ore" and _routes().has("copper_home"): return "copper_home"
			return route_id
	return ""

func _select_island(id: String) -> void:
	if id != island: resume_recipe = ""
	island = id
	if not Flow.opened(view,id):
		managing_island = false
		navigate_requested.emit("outposts", "")
	elif Flow.hub(view) and id != "home" and not _island_route(id).is_empty(): _select_work("transport")
	elif page == "transport" and not _island_route(id).is_empty(): _select_work("transport")
	elif page == "outposts" and managing_island and id != "home": _select_work("facilities")
	else: _select_work("manufacturing")

func _select_work(kind: String) -> void:
	if kind != "outposts" and not Flow.opened(view,island): return
	if kind == "facilities" and island == "home": return
	if kind == "transport" and _island_route(island).is_empty(): return
	if kind == "manufacturing":
		var target: String = resume_recipe if not resume_recipe.is_empty() else _island_recipe(island)
		navigate_requested.emit(kind,target)
	elif kind == "transport": navigate_requested.emit(kind,_island_route(island))
	elif kind == "facilities": navigate_requested.emit("outposts",island)
	else:
		managing_island = false
		navigate_requested.emit("outposts", "")

func _island_recipe(id: String) -> String:
	if id in IslandProgression.RECIPES: return IslandProgression.RECIPES[id]
	for recipe_id in view.get("manufacturing",{}).get("recipes",{}):
		if view.manufacturing.recipes[recipe_id].island == id: return recipe_id
	return recipe

func _island_row_action(id: String) -> void:
	var entry: Dictionary = island_rows[id]
	if entry.action.disabled: return
	island = id
	if Flow.opened(view,id):
		managing_island = true
		facility.select(0)
		refresh(view,catalog)
	else:
		action_requested.emit("open_island",{"island_id":id})

func _refresh_island_list() -> void:
	for id in island_rows:
		var entry: Dictionary = island_rows[id]
		var def: Dictionary = IslandEconomy.ISLANDS.get(id,{"era":1,"facility":{},"cost":{"wood":0,"stone_low":0}})
		var opened := Flow.opened(view,id)
		entry.group.visible = id != "home" or Flow.discovered(view,"manufacturing")
		var qualified := true
		var requirements: Array[String] = []
		for building in def.facility:
			var value: Variant = view.get("buildings",{}).get(building,{})
			var level := int(value.get("level",0)) if value is Dictionary else int(value)
			if level < int(def.facility[building]):
				qualified = false
				requirements.append(String({"hut":"居所","stone_mine":"採石場","herb_farm":"靈植場"}.get(building,building)) + "%d階" % int(def.facility[building]))
		var enough := true
		var cost: Dictionary = def.get("cost",{"wood":20,"stone_low":10})
		for index in 2:
			var resource: String = ["wood","stone_low"][index]
			var tile = entry.tiles[index]
			tile.visible = not opened
			tile.set_compact(compact_layout)
			tile.refresh(resource,_name(resource),float(cost[resource]),_home(resource),"祖島付款")
			if _home(resource) < float(cost[resource]): enough = false
		var locked := int(view.get("era_id",1)) < int(def.era)
		var active: bool = view.get("economy",{}).get("version","") in [IslandProgression.VERSION,IslandProgression.LEGACY_VERSION,IslandProgression.SUPPLY_VERSION]
		var can_initialize := active or bool(view.get("island_activation",{}).get("ok",false))
		entry.action.text = "設施" if opened else "金丹解鎖" if locked else "開拓"
		entry.action.visible = not opened
		entry.action.disabled = not opened and (locked or not qualified or not enough or not can_initialize)
		entry.state.text = "修行與合成・各配方共用一條產線" if id == "home" else "已開拓・自動採集中" if opened else "待開拓・金丹期解鎖" if locked else "前置不足・需" + "、".join(requirements) if not qualified else "材料不足・請補足祖島庫存" if not enough else "待開拓・材料已備齊" if can_initialize else "尚未符合空島啟用條件・請查看完整管理"
		var remedy: Dictionary = Flow.opening(view,id) if not opened and not locked else {}
		entry.remedy.visible = not remedy.is_empty()
		entry.remedy.text = String(remedy.get("label",""))
		entry.action.tooltip_text = entry.state.text
		entry.payment.visible = not opened and not compact_layout
		entry.costs.visible = not opened
		if opened and Flow.hub(view):
			entry.state.text = "祖島集中製造・原料與產物共用祖島庫存" if id == "home" else "自動採集・運回祖島供製造"
		if opened:
			var job: Dictionary = view.get("economy",{}).get("jobs",{}).get(id,{})
			if not job.is_empty(): entry.state.text += "・%s %d秒" % [_name(job.recipe_id),int(job.get("remaining",0))]
		if entry.art.texture == null and int(view.get("era_id",1)) >= 2:
			entry.art.texture = load("res://assets/abode/fx3art1/terrain.png" if id == "home" else "res://assets/abode/%s/%s_body.png" % ["res1d2" if id=="herb" else "res1c3",id])
		entry.art.modulate = Color(1,1,1,0.55) if locked else Color.WHITE
		entry.art.custom_minimum_size = Vector2(88,64) if compact_layout else Vector2(128,96)
		entry.select.custom_minimum_size = entry.art.custom_minimum_size
		entry.heading.text = IslandProgression.NAMES[id] + ("・當前" if id == island else "")
		entry.select.tooltip_text = "選擇%s・%s" % [IslandProgression.NAMES[id],entry.state.text]
		var selected: bool = id == island
		if not entry.select.has_meta("selected") or bool(entry.select.get_meta("selected")) != selected:
			UiMaterial.apply_scroll_button(entry.select,selected)
			entry.select.set_meta("selected",selected)
		entry.row.vertical = size.x < 580

func _mount_work_surface(active: bool) -> void:
	work_surface.visible = active
	if not active:
		_work_island = ""
		return
	var id := island
	if page == "manufacturing": id = "home" if Flow.hub(view) else String(view.get("manufacturing",{}).get("recipes",{}).get(recipe,{}).get("island",island))
	elif page == "transport": id = String(_routes().get(route,[island])[0])
	if not island_rows.has(id): return
	island = id
	var entry: Dictionary = island_rows[id]
	if work_surface.get_parent() != entry.group:
		work_surface.reparent(entry.group)
		entry.group.move_child(work_surface,1)
	if _work_island != id:
		_work_island = id
		_scroll_to_work.call_deferred()

func _scroll_to_work() -> void:
	# Wait for container layout; reveal the row heading together with its controls.
	await get_tree().process_frame
	await get_tree().process_frame
	if _work_island.is_empty() or not is_visible_in_tree(): return
	if compact_layout and work_surface.visible:
		island_scroll.ensure_control_visible(operation_box)
	else: island_scroll.scroll_vertical = int(island_rows[_work_island].group.position.y)

func _label(parent: Node) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color",UiMaterial.INK)
	label.add_theme_font_size_override("font_size",16)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	UiMaterial.apply_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _name(id: String) -> String:
	return String(catalog.get("resources",{}).get(id,{}).get("name",id))

func _tile(id: String, amount: float, available: float, source: String, output := false) -> void:
	var index: int = materials.get_meta("used",0)
	if index >= cells.size(): return
	var cell = cells[index]
	cell.show()
	if output and index > 0:
		materials.move_child(flow_arrow,cell.get_index() - (1 if flow_arrow.get_index() < cell.get_index() else 0))
		flow_arrow.show()
	cell.refresh(id,_name(id),amount,available,source,output)
	cell.tooltip_text += "\n" + source
	materials.set_meta("used",index+1)

func _nav(label: String, target: String, id := "") -> void:
	_actions.append({"label":label,"page":target,"id":id})

func _command(label: String, kind: String, payload: Dictionary, disabled := false) -> void:
	_actions.append({"label":label,"kind":kind,"payload":payload,"disabled":disabled})

func _invoke(index: int) -> void:
	if index >= _actions.size() or buttons[index].disabled: return
	var action := _actions[index]
	if action.has("page"): navigate_requested.emit(action.page,action.id)
	else: action_requested.emit(action.kind,action.payload)

func refresh(next_view: Dictionary, next_catalog: Dictionary) -> void:
	view = next_view
	catalog = next_catalog
	if picker == null or view.is_empty(): return
	hub_upgrade.visible = not Flow.hub(view) and not String(view.get("economy",{}).get("version","")).is_empty()
	var listing := page == "outposts" and not managing_island
	island_scroll.show()
	content_row.visible = not listing
	picker.visible = page != "outposts"
	list_back.visible = not listing
	list_heading.visible = not compact_layout
	list_heading.text = "空島經營"
	facility.visible = page == "outposts" and managing_island and Flow.opened(view,island)
	mode.visible = page == "manufacturing"
	_options.clear()
	var labels: Array[String] = []
	if page == "outposts":
		for id in ["wood","ore"]:
			_options.append(id)
			labels.append(IslandProgression.NAMES[id] + (" · 已開拓" if Flow.opened(view,id) else " · 待開拓"))
	elif page == "manufacturing":
		for id in view.get("manufacturing",{}).get("recipes",{}):
			var info: Dictionary = view.manufacturing.recipes[id]
			if int(catalog.get("recipes",{}).get(id,{}).get("era",1)) > 2 or info.get("reason") in ["ERA_REQUIREMENT","RESOURCE_LOCKED","RECIPE_ISLAND_REQUIREMENT"]: continue
			_options.append(id)
			labels.append(_name(String(info.get("product_id",id))) + " · " + ("祖島" if Flow.hub(view) else IslandProgression.NAMES[info.island]))
	else:
		for id in _routes():
			var def: Array = _routes()[id]
			if Flow.hub(view) and bool(view.get("transport",{}).get(id,{}).get("legacy",false)): continue
			if not Flow.opened(view,def[0]) or not Flow.opened(view,def[1]): continue
			_options.append(id)
			labels.append(_name(def[2])+" · "+IslandProgression.NAMES[def[0]]+" → "+IslandProgression.NAMES[def[1]])
	var key: String = island if page == "outposts" else recipe if page == "manufacturing" else route
	if not _options.is_empty() and not key in _options:
		key = _options[0]
		if page == "manufacturing": recipe = key
		elif page == "transport": route = key
	var signature := "|".join(labels)
	if picker.get_meta("items", "") != signature:
		picker.clear()
		for label in labels: picker.add_item(label)
		picker.set_meta("items",signature)
	if key in _options: picker.select(_options.find(key))
	_actions.clear()
	materials.set_meta("used",0)
	for cell in cells: cell.hide()
	flow_arrow.hide()
	progress.hide()
	if listing:
		title.text = "開拓產地 → 原料運回祖島 → 集中製造" if Flow.hub(view) else "選擇空島・祖島支付材料，開拓後自動採集。"
	elif page == "outposts": _island()
	elif page == "manufacturing" and not _options.is_empty(): _manufacture()
	elif page == "transport" and not _options.is_empty(): _transport()
	else:
		title.text = "先開拓空島"
		status.text = "完成眼前一步，再接通下一段。"
		_nav("開拓玄礦", "outposts", "ore")
	for index in buttons.size():
		var button := buttons[index]
		button.visible = index < _actions.size()
		if not button.visible: continue
		button.text = _actions[index].label
		var icon_id: String = recipe if page == "manufacturing" else String(_routes().get(route,["","","wood"])[2]) if page == "transport" else "wood" if island=="wood" else "stone_low"
		button.icon = preload("res://src/presentation/resource_icon.gd").TEXTURES.get(icon_id)
		button.add_theme_constant_override("icon_max_width",24)
		button.disabled = _actions[index].get("disabled",false)
		button.tooltip_text = _actions[index].get("tip", button.text)
	_mount_work_surface(not listing)
	_refresh_island_list()
	for phase_key in steps:
		var selected: bool = phase_key == ("facilities" if managing_island and page == "outposts" else page)
		steps[phase_key].set_pressed_no_signal(selected)
		steps[phase_key].disabled = phase_key != "outposts" and not Flow.opened(view,island)
		if phase_key == "transport": steps[phase_key].disabled = _island_route(island).is_empty()
		if phase_key == "facilities": steps[phase_key].disabled = island == "home" or not Flow.opened(view,island)
		steps[phase_key].tooltip_text = "祖島設施請至洞府建築" if phase_key == "facilities" and island == "home" else "先開拓所選空島" if not Flow.opened(view,island) else "尚無已開通兩端的航線" if phase_key == "transport" and steps[phase_key].disabled else IslandProgression.NAMES[island] + "・" + steps[phase_key].text
		steps[phase_key]._update_style()
	# At most one actionable recommendation. No clock/RNG/state writes.
	var next: Button = null
	for button in buttons:
		if button.visible and not button.disabled and not button.text in ["停止","本批後停止","停航"]: next = button; break
	if listing:
		var entry: Dictionary = island_rows.get(island,island_rows.wood)
		next = steps.manufacturing if Flow.opened(view,island) else entry.action
		if next.disabled: next = null
	if reduced_motion and _glow != null and _glow.is_valid(): _stop_glow()
	if next != _glowing:
		_stop_glow()
		_glowing = next
		if next != null:
			UiMaterial.mark_selected(next,true)
			if is_visible_in_tree() and not reduced_motion:
				_glow = create_tween().set_loops()
				_glow.tween_property(next,"self_modulate",Color(1.3,1.2,0.8),0.7)
				_glow.tween_property(next,"self_modulate",Color.WHITE,0.7)

func _home(resource: String) -> float:
	if not view.get("economy",{}).get("version", "").is_empty():
		return float(view.get("economy",{}).get("inventory",{}).get("home",{}).get(resource,{}).get("available",0))
	var entry: Variant = view.get("resources",{}).get(resource,{})
	if entry is Dictionary:
		var value: Variant = entry.get("value",0)
		return value.to_float() if value is AmountCompat else float(value)
	return 0.0

func _prices(costs: Dictionary) -> bool:
	var enough := true
	for id in costs:
		var available := _home(id)
		_tile(id,float(costs[id]),available,"祖島付款")
		if available < float(costs[id]): enough = false
	return enough

func _island() -> void:
	var opened := Flow.opened(view,island)
	var def: Dictionary = IslandEconomy.ISLANDS[island]
	title.text = IslandProgression.NAMES[island]
	if not opened:
		var enough := _prices(def.get("cost",{"wood":20,"stone_low":10}))
		var qualified := true
		for id in def.get("facility",{}):
			var entry: Variant = view.get("buildings",{}).get(id,{})
			var level := int(entry.get("level",0)) if entry is Dictionary else int(entry)
			if level < int(def.facility[id]): qualified = false
		status.text = "先完成祖島設施" if not qualified else "祖島付款 → 開拓後自動採集" if enough else "祖島工程材料不足"
		var active: bool = view.get("economy",{}).get("version","") in [IslandProgression.VERSION,IslandProgression.LEGACY_VERSION,IslandProgression.SUPPLY_VERSION]
		_command("開拓", "open_island", {"island_id":island}, not enough or not qualified or (not active and not bool(view.get("island_activation",{}).get("ok",false))))
		if not enough or not qualified:
			var fix: Dictionary = Flow.opening(view,island)
			if not fix.is_empty(): _nav(fix.label,fix.page,fix.id)
	elif facility.selected > 0:
		var id: String = ["extractor","storage","workshop"][facility.selected-1]
		var level := int(view.get("economy",{}).get("islands",{}).get(island,{}).get("facilities",{}).get(id,1))
		var enough := _prices(IslandProgression.upgrade_cost(id,level))
		title.text += " · " + IslandProgression.FACILITIES[id]
		status.text = "%d → %d階 · 祖島付款" % [level,mini(3,level+1)] if level < 3 else "已達上限"
		_command("升級", "upgrade_island_facility", {"island_id":island,"facility_id":id},level>=3 or not enough)
		if not enough:
			for resource in IslandProgression.upgrade_cost(id,level):
				var required: float = float(IslandProgression.upgrade_cost(id,level)[resource])
				if _home(resource) < required:
					var fix: Dictionary = Flow.resource_fix(view,resource,required,_routes())
					_nav(fix.label,fix.page,fix.id)
					break
	else:
		facility.select(1)
		_island()

func _routes() -> Dictionary:
	return Flow.routes(view)

func _manufacture() -> void:
	var info: Dictionary = view.manufacturing.recipes[recipe]
	var central := Flow.hub(view)
	var owner: String = info.get("output_island",info.island)
	title.text = ("祖島製造" if central else IslandProgression.NAMES[info.island]) + " · 原料 → " + _name(String(info.get("product_id",recipe)))
	for id in info.inputs:
		var input: Dictionary = info.inputs[id]
		_tile(id,float(input.required),float(input.available),IslandProgression.NAMES[input.source])
	var slot: Dictionary = view.get("economy",{}).get("inventory",{}).get(owner,{}).get(info.get("product_id",recipe),{})
	_tile(String(info.get("product_id",recipe)),float(info.output),float(slot.get("available",0)),"產物 · "+IslandProgression.NAMES[owner],true)
	var job: Dictionary = view.get("economy",{}).get("jobs",{}).get(info.island,{})
	var reason := String(info.get("reason",""))
	var fix := Flow.shortage(view,info,_routes())
	if not job.is_empty():
		status.text = ("持續製造・" if bool(job.get("repeat",false)) else "") + "%s · %d秒 · %s庫存%s" % [_name(job.recipe_id),int(job.get("remaining",0)),IslandProgression.NAMES[owner],str(slot.get("available",0))]
		progress.visible = int(job.get("remaining",0)) > 0
		progress.value = 100.0*(1.0-float(job.get("remaining",0))/maxf(1,float(info.duration))) if job.recipe_id == recipe else 0
		if int(job.get("remaining",0)) == 0 and not fix.is_empty():
			status.text = "持續製造等待原料・" + String(fix.get("status",fix.label))
			_nav(fix.label,fix.page,fix.id)
		var action := ProductionController.stop_action(job,info.island)
		_command("本批後停止" if int(job.get("remaining",0))>0 else "停止", "stop_processing", {"island_id":info.island},String(action.command).is_empty())
	else:
		status.text = "%d秒／批 · 產物直接存入%s" % [int(info.duration),IslandProgression.NAMES[owner]] if central else "%d秒／批 · 本島 %s · 祖島 %s" % [int(info.duration),str(slot.get("available",0)),str(_home(String(info.get("product_id",recipe))))]
		if reason == "OUTPUT_FULL":
			status.text = "祖島產物滿倉・先使用材料或擴充容量" if central else "產物滿倉 → 運回祖島"
			_nav("查看祖島建設","buildings","home") if central else _nav("運回產物", "transport", _outbound(info.island,String(info.get("product_id",recipe))))
		elif not fix.is_empty():
			status.text = String(fix.get("status","缺料 → " + String(fix.label)))
			if central and bool(fix.get("quick",false)):
				var settings: Dictionary = view.get("transport",{}).get(fix.id,{}).get("settings",{})
				_command("啟用補給","configure_route",{"route_id":fix.id,"enabled":true,"reserve":String(settings.get("reserve","0")),"target":String(settings.get("target","100")),"level":int(settings.get("level",1))})
				_nav("查看航線","transport",fix.id)
			else: _nav(fix.label,fix.page,fix.id)
		elif not reason.is_empty():
			status.text = "先升級祖島設施" if reason == "FACILITY_REQUIREMENT" else reason
			_nav("洞府建築", "buildings")
		else:
			_command("開始製造", "craft", ProductionController.work_payload(info.island,recipe,ProductionController.Mode.REPEAT if mode.selected==1 else ProductionController.Mode.SINGLE,1,{}))
	if central:
		if not job.is_empty() and owner != "home": _nav("清空舊島產物","transport",_outbound(info.island,String(info.get("product_id",recipe))))
	elif info.island != "home" and not (reason == "OUTPUT_FULL" and job.is_empty()): _nav("運回產物", "transport", _outbound(info.island,String(info.get("product_id",recipe))))

func _outbound(source: String, resource: String) -> String:
	for id in _routes():
		var def: Array = _routes()[id]
		if def[0] == source and def[1] == "home" and def[2] == resource: return id
	return ""

func _transport() -> void:
	var def: Array = _routes()[route]
	var info: Dictionary = view.get("transport",{}).get(route,{})
	var stock: Dictionary = info.get("stock",{})
	var settings: Dictionary = info.get("settings",{"enabled":false,"reserve":"0","target":"100","level":1})
	title.text = IslandProgression.NAMES[def[0]] + " → " + IslandProgression.NAMES[def[1]]
	_tile(def[2],float(stock.get("source",0)),float(stock.get("source",0)),"來源 · "+IslandProgression.NAMES[def[0]])
	_tile(def[2],float(stock.get("destination",0)),float(stock.get("destination",0)),"目的 · "+IslandProgression.NAMES[def[1]],true)
	var reason := String(info.get("reason",""))
	status.text = {"STOPPED":"停航", "READY":"等待出航", "NO_SURPLUS":"來源缺貨", "TARGET_REACHED":"資源已滿足", "DESTINATION_FULL":"目的倉滿"}.get(reason,"運輸準備中")
	var trip: Dictionary = info.get("trip",{})
	if not trip.is_empty():
		status.text = "運送%s · %d秒到達%s" % [str(trip.cargo),int(trip.remaining),IslandProgression.NAMES[def[1]]]
		progress.show()
		progress.value = 100.0*(1.0-float(trip.remaining)/10.0)
	_command("停航" if settings.enabled else "啟航", "configure_route", {"route_id":route,"enabled":not bool(settings.enabled),"reserve":String(settings.reserve),"target":String(settings.target),"level":int(settings.level)},not bool(info.get("ready",false)))
	if Flow.hub(view):
		if reason == "NO_SURPLUS":
			status.text = "來源保留量限制出貨・完整管理可調整" if float(settings.reserve) > 0 and float(stock.get("source",0)) > 0 else "來源採集中・等待可運原料"
			_nav("查看產地","outposts",def[0])
		elif reason == "DESTINATION_FULL": _nav("查看祖島容量","buildings",Flow.STORAGE.get(def[2],"home"))
		elif reason == "TARGET_REACHED": status.text = "已達航線目標・可返回祖島製造"
		if not resume_recipe.is_empty(): _nav("繼續原配方","manufacturing",resume_recipe)
		else: _nav("祖島製造","manufacturing",recipe)
		return
	if reason == "NO_SURPLUS":
		if def[2] in ["spirit_timber","bronze_essence"]: _nav("製造補貨", "manufacturing",def[2])
		else: _nav("提升採集", "outposts",def[0])
	elif reason == "DESTINATION_FULL": _nav("提升倉儲", "buildings" if def[1]=="home" else "outposts",def[1])
	else: _nav("返回製造", "manufacturing", "spirit_timber" if def[1]=="wood" else "bronze_essence" if def[1]=="ore" else recipe)
	if _actions.size()>1 and reason in ["NO_SURPLUS","DESTINATION_FULL"]:
		var fix: Dictionary = _actions.pop_back()
		_actions.push_front(fix)

func _stop_glow() -> void:
	if _glow != null and _glow.is_valid(): _glow.kill()
	if is_instance_valid(_glowing):
		_glowing.self_modulate = Color.WHITE
		UiMaterial.mark_selected(_glowing,false)
	_glowing = null

func show_result(text: String) -> void:
	notice.text = text
	notice.tooltip_text = text
	var listing := page == "outposts" and not managing_island
	notice.visible = listing or not compact_layout
	retry.visible = text.begins_with("操作未保存")
	if compact_layout and not listing:
		status.text = "未保存・請重試" if retry.visible else "操作未完成・查看提示"
		status.tooltip_text = text
		for button in buttons: button.hide()
func show_success(text: String) -> void:
	# Long receipts stay in TIP; no temporary line pushes primary actions offscreen.
	notice.text = text if page == "outposts" and not managing_island else "已保存"
	notice.tooltip_text = text
	notice.visible = (page == "outposts" and not managing_island) or not compact_layout
	retry.hide()
func storage_recovered() -> void:
	if retry.visible: show_success("保存已恢復")
func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	var listing := page == "outposts" and not managing_island
	var compact := bounds.size.y < 300
	title.visible = not compact
	var changed_compact := compact_layout != compact
	compact_layout = compact
	list_heading.visible = not compact
	var full_parent: Node = steps.outposts.get_parent() if compact else selection_header
	if full_button.get_parent() != full_parent: full_button.reparent(full_parent)
	selection_header.visible = not compact
	if changed_compact and work_surface.visible: _scroll_to_work.call_deferred()
	notice.visible = (listing or not compact) and not notice.text.is_empty()
	var retry_parent: Node = column
	if retry.get_parent() != retry_parent: retry.reparent(retry_parent)
	if compact and retry.visible and not listing:
		status.text = "未保存・請重試"
		status.tooltip_text = notice.tooltip_text
		for button in buttons: button.hide()
	content_row.vertical = bounds.size.x < 760
	content_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	materials.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	operation_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	operation_box.custom_minimum_size.x = 0
	full_button.text = "管理" if compact else "完整管理"
	column.add_theme_constant_override("separation",4 if compact else 8)
	for cell in cells: cell.set_compact(compact)
	for id in island_rows:
		var entry: Dictionary = island_rows[id]
		entry.art.custom_minimum_size = Vector2(88,64) if compact else Vector2(128,96)
		entry.select.custom_minimum_size = entry.art.custom_minimum_size
		entry.row.vertical = bounds.size.x < 580
		entry.payment.visible = not compact and not Flow.opened(view,id)
		for tile in entry.tiles: tile.set_compact(compact)
