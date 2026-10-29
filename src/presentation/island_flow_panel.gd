extends PanelContainer
## Era2 focused work surface. UI selections survive close/reopen; saves stay canonical.
const Flow = preload("res://src/presentation/island_flow_model.gd")
const Tile = preload("res://src/presentation/recipe_material_tile.gd")
signal action_requested(kind: String, payload: Dictionary)
signal navigate_requested(route: String, id: String)
signal full_requested()
signal retry_requested()
var view := {}
var catalog := {}
var page := "outposts"
var island := "wood"
var recipe := "spirit_timber"
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

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	head.hide()
	for entry in [["outposts", "1 開拓"], ["manufacturing", "2 製造"], ["transport", "3 運輸"]]:
		var button := GameTab.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(88,44)
		button.pressed.connect(func(): navigate_requested.emit(entry[0], ""))
		head.add_child(button)
		steps[entry[0]] = button
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var full := _button(head, "完整管理", func(): full_requested.emit())
	full_button = full
	full.tooltip_text = "批數、保留量、航線目標與全部設施；原有設定保留"
	var selection := HBoxContainer.new()
	column.add_child(selection)
	picker = OptionButton.new()
	picker.custom_minimum_size.y = 44
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection.add_child(picker)
	picker.item_selected.connect(func(index: int):
		if page == "outposts": island = _options[index]
		elif page == "manufacturing": recipe = _options[index]
		else: route = _options[index]
		refresh(view,catalog))
	facility = OptionButton.new()
	for text in ["開拓／概覽", "採集升級", "倉儲升級", "加工坊升級"]: facility.add_item(text)
	facility.custom_minimum_size.y = 44
	selection.add_child(facility)
	facility.item_selected.connect(func(_index: int): refresh(view,catalog))
	mode = OptionButton.new()
	mode.add_item("單批")
	mode.add_item("持續")
	mode.custom_minimum_size.y = 44
	selection.add_child(mode)
	full.reparent(selection)
	title = _label(column)
	content_row = BoxContainer.new()
	content_row.vertical = true
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content_row)
	materials = HBoxContainer.new()
	materials.alignment = BoxContainer.ALIGNMENT_CENTER
	materials.size_flags_vertical = Control.SIZE_EXPAND_FILL
	materials.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	notice = _label(operation_box)
	notice.hide()
	retry = _button(operation_box, "重試保存", func(): retry_requested.emit())
	retry.hide()
	visibility_changed.connect(func():
		if not is_visible_in_tree(): _stop_glow())

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
	for key in steps:
		steps[key].visible = Flow.discovered(view,key) or page == key
		steps[key].button_pressed = key == page
		steps[key]._update_style()
	facility.visible = page == "outposts" and Flow.opened(view,island)
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
			labels.append(_name(String(info.get("product_id",id))) + " · " + IslandProgression.NAMES[info.island])
	else:
		for id in IslandEconomy.ROUTES:
			var def: Array = IslandEconomy.ROUTES[id]
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
	if page == "outposts": _island()
	elif page == "manufacturing" and not _options.is_empty(): _manufacture()
	elif page == "transport" and not _options.is_empty(): _transport()
	else:
		title.text = "先開拓空島"
		status.text = "完成眼前一步，再接通下一段。"
		_nav("開拓", "outposts", "wood")
	for index in buttons.size():
		var button := buttons[index]
		button.visible = index < _actions.size()
		if not button.visible: continue
		button.text = _actions[index].label
		var icon_id: String = recipe if page == "manufacturing" else String(IslandEconomy.ROUTES.get(route,["","","wood"])[2]) if page == "transport" else "wood" if island=="wood" else "stone_low"
		button.icon = preload("res://src/presentation/resource_icon.gd").TEXTURES.get(icon_id)
		button.add_theme_constant_override("icon_max_width",24)
		button.disabled = _actions[index].get("disabled",false)
		button.tooltip_text = _actions[index].get("tip", button.text)
	# At most one actionable recommendation. No clock/RNG/state writes.
	var next: Button = null
	for button in buttons:
		if button.visible and not button.disabled: next = button; break
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
		if not enough or not qualified: _nav("洞府建設", "buildings")
	elif facility.selected > 0:
		var id: String = ["extractor","storage","workshop"][facility.selected-1]
		var level := int(view.get("economy",{}).get("islands",{}).get(island,{}).get("facilities",{}).get(id,1))
		var enough := _prices(IslandProgression.upgrade_cost(id,level))
		title.text += " · " + IslandProgression.FACILITIES[id]
		status.text = "%d → %d階 · 祖島付款" % [level,mini(3,level+1)] if level < 3 else "已達上限"
		_command("升級", "upgrade_island_facility", {"island_id":island,"facility_id":id},level>=3 or not enough)
		if not enough: _nav("運回工程材料", "transport")
	else:
		for id in def.rates:
			var slot: Dictionary = view.get("economy",{}).get("inventory",{}).get(island,{}).get(id,{})
			_tile(id,float(slot.get("available",0)),float(slot.get("available",0)),IslandProgression.NAMES[island],true)
		status.text = "採集中 → 選擇產物開始製造"
		flow_arrow.hide()
		_nav("繼續製造" if not resume_recipe.is_empty() else "開始製造", "manufacturing", resume_recipe if not resume_recipe.is_empty() else "spirit_timber" if island == "wood" else "bronze_essence")
		if Flow.discovered(view,"transport"): _nav("運輸", "transport")

func _manufacture() -> void:
	var info: Dictionary = view.manufacturing.recipes[recipe]
	title.text = IslandProgression.NAMES[info.island] + " · 原料 → " + _name(String(info.get("product_id",recipe)))
	for id in info.inputs:
		var input: Dictionary = info.inputs[id]
		_tile(id,float(input.required),float(input.available),IslandProgression.NAMES[input.source])
	var slot: Dictionary = view.get("economy",{}).get("inventory",{}).get(info.island,{}).get(info.get("product_id",recipe),{})
	_tile(String(info.get("product_id",recipe)),float(info.output),float(slot.get("available",0)),"產物 · "+IslandProgression.NAMES[info.island],true)
	var job: Dictionary = view.get("economy",{}).get("jobs",{}).get(info.island,{})
	var reason := String(info.get("reason",""))
	if not job.is_empty():
		status.text = "%s · %d秒 · 本地庫存%s" % [_name(job.recipe_id),int(job.get("remaining",0)),str(slot.get("available",0))]
		progress.show()
		progress.value = 100.0*(1.0-float(job.get("remaining",0))/maxf(1,float(info.duration))) if job.recipe_id == recipe else 0
		var action := ProductionController.stop_action(job,info.island)
		_command("本批後停止" if int(job.get("remaining",0))>0 else "停止", "stop_processing", {"island_id":info.island},String(action.command).is_empty())
	else:
		status.text = "%d秒／批 · 產物留在%s" % [int(info.duration),IslandProgression.NAMES[info.island]]
		var fix := Flow.shortage(view,info,IslandEconomy.ROUTES)
		if reason == "OUTPUT_FULL":
			status.text = "產物滿倉 → 運回祖島"
			_nav("運回產物", "transport", _outbound(info.island,String(info.get("product_id",recipe))))
		elif not fix.is_empty():
			status.text = "缺料 → " + String(fix.label)
			_nav(fix.label,fix.page,fix.id)
		elif not reason.is_empty():
			status.text = "先升級祖島設施" if reason == "FACILITY_REQUIREMENT" else reason
			_nav("洞府建築", "buildings")
		else:
			_command("開始製造", "craft", ProductionController.work_payload(info.island,recipe,ProductionController.Mode.REPEAT if mode.selected==1 else ProductionController.Mode.SINGLE,1,{}))
	if info.island != "home": _nav("運回產物", "transport", _outbound(info.island,String(info.get("product_id",recipe))))

func _outbound(source: String, resource: String) -> String:
	for id in IslandEconomy.ROUTES:
		var def: Array = IslandEconomy.ROUTES[id]
		if def[0] == source and def[1] == "home" and def[2] == resource: return id
	return ""

func _transport() -> void:
	var def: Array = IslandEconomy.ROUTES[route]
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
	notice.visible = not compact_layout
	retry.visible = text.begins_with("操作未保存")
	if compact_layout:
		status.text = "未保存・請重試" if retry.visible else "操作未完成・查看提示"
		status.tooltip_text = text
		for button in buttons: button.hide()
func show_success(text: String) -> void:
	# Long receipts stay in TIP; no temporary line pushes primary actions offscreen.
	notice.text = "已保存"
	notice.tooltip_text = text
	notice.visible = not compact_layout
	retry.hide()
func storage_recovered() -> void:
	if retry.visible: show_success("保存已恢復")
func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size
	title.visible = bounds.size.y >= 300
	var compact := bounds.size.y < 300
	compact_layout = compact
	notice.visible = not compact and not notice.text.is_empty()
	if retry.get_parent() != (action_row if compact else operation_box): retry.reparent(action_row if compact else operation_box)
	if compact and retry.visible:
		status.text = "未保存・請重試"
		status.tooltip_text = notice.tooltip_text
		for button in buttons: button.hide()
	content_row.vertical = not compact
	materials.size_flags_vertical = Control.SIZE_SHRINK_CENTER if compact else Control.SIZE_EXPAND_FILL
	operation_box.custom_minimum_size.x = 280 if compact else 0
	full_button.text = "管理" if compact else "完整管理"
	column.add_theme_constant_override("separation",4 if compact else 8)
	for cell in cells: cell.set_compact(compact)
