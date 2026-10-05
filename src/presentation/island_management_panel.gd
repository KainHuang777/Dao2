extends PanelContainer
## A single canonical management page; emits commands, never changes inventory.
signal action_requested(kind: String, payload: Dictionary)
signal legacy_requested()
signal close_requested()
signal world_requested(id: String)

var island := "home"
var body: VBoxContainer
var summary: Label
var message: Label
var inventory: Label
var job_status: Label
var activation: Button
var heading_label: Label
var opening: Button
var work_buttons: Array[Button] = []
var facility_buttons := {}
var route_widgets := {}
var _view := {}
var _catalog := {}

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("人界・空島產業")
	heading_label = title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_add_button(heading, "關閉", func(): close_requested.emit())
	message = _label("")
	message.visible = false
	column.add_child(message)
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
	# The shared Chinese fonts have no emoji glyphs; keep essential names textual.
	return {"foundation_pill": "築基丹", "stone_mid": "中品靈石", "golden_core_pill": "金丹丹藥", "liquid": "丹液", "talisman": "符咒"}.get(id, _catalog.get("resources", {}).get(id, {}).get("name", id))

func _add_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 18)
	UiMaterial.apply_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _rebuild() -> void:
	if body == null:
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	work_buttons.clear()
	facility_buttons.clear()
	route_widgets.clear()
	_add_button(body, "前往此島世界", func(): world_requested.emit(island))
	var islands := HBoxContainer.new()
	body.add_child(islands)
	for id in IslandProgression.NAMES:
		var button := _add_button(islands, IslandProgression.NAMES[id], func():
			island = id
			_rebuild()
			refresh(_view, _catalog))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary = _label("")
	body.add_child(summary)
	activation = _add_button(body, "保留原檔並啟用空島", func(): action_requested.emit("activate_islands", {}))
	opening = _add_button(body, "開拓：靈木20＋下品靈石10\n由祖島支付", func(): action_requested.emit("open_island", {"island_id": island}))
	inventory = _label("")
	body.add_child(inventory)
	job_status = _label("")
	body.add_child(job_status)
	var recipes: Array = IslandProgression.HOME_RECIPES if island == "home" else [IslandProgression.RECIPES[island]]
	for recipe_id in recipes:
		var recipe: String = recipe_id
		for entry in [["製作一批", false], ["持續製作", true]]:
			var repeating: bool = entry[1]
			var name: String = _resource_name(recipe)
			var button := _add_button(body, name + "・" + entry[0], func(): action_requested.emit("craft", {"island_id": island, "recipe_id": recipe, "count": 1, "repeat": repeating}))
			button.set_meta("recipe", recipe)
			work_buttons.append(button)
	var stop_work := _add_button(body, "本批完成後停止", func(): action_requested.emit("stop_processing", {"island_id": island}))
	stop_work.set_meta("recipe", "")
	work_buttons.append(stop_work)
	if island != "home":
		for id in IslandProgression.FACILITIES:
			facility_buttons[id] = _add_button(body, "", func(): action_requested.emit("upgrade_island_facility", {"island_id": island, "facility_id": id}))
	for route_id in IslandEconomy.ROUTES:
		var definition: Array = IslandEconomy.ROUTES[route_id]
		if island != "home" and definition[0] != island:
			continue
		var resource: String = _resource_name(definition[2])
		body.add_child(_label("%s→%s・%s" % [IslandProgression.NAMES[definition[0]], IslandProgression.NAMES[definition[1]], resource]))
		var status := _label("")
		body.add_child(status)
		var reserve := SpinBox.new()
		reserve.max_value = 1000000
		reserve.custom_minimum_size.y = 44
		reserve.prefix = "來源保留 "
		body.add_child(reserve)
		var target := SpinBox.new()
		target.max_value = 1000000
		target.value = 100
		target.custom_minimum_size.y = 44
		target.prefix = "目標庫存 "
		body.add_child(target)
		var apply := _add_button(body, "啟動／更新航線", func():
			var old: Dictionary = _view.get("economy", {}).get("routes", {}).get(route_id, {})
			action_requested.emit("configure_route", {"route_id": route_id, "enabled": true, "reserve": str(reserve.value), "target": str(target.value), "level": int(old.get("level", 1))}))
		var stop := _add_button(body, "停止新出航\n當趟仍會到貨", func():
			var old: Dictionary = _view.get("economy", {}).get("routes", {}).get(route_id, {})
			action_requested.emit("configure_route", {"route_id": route_id, "enabled": false, "reserve": str(reserve.value), "target": str(target.value), "level": int(old.get("level", 1))}))
		var upgrade := _add_button(body, "運力升階：靈材2＋銅精2\n由祖島支付", func(): action_requested.emit("configure_route", {"route_id": route_id, "enabled": true, "reserve": str(reserve.value), "target": str(target.value), "level": 2}))
		route_widgets[route_id] = {"status": status, "reserve": reserve, "target": target, "apply": apply, "stop": stop, "upgrade": upgrade, "initialized": false}
	_add_button(body, "靈界洞天", func(): legacy_requested.emit())

func refresh(view: Dictionary, catalog: Dictionary) -> void:
	var first_catalog := _catalog.is_empty() and not catalog.is_empty()
	_view = view
	_catalog = catalog
	if body == null:
		return
	if first_catalog:
		_rebuild()
	var e: Dictionary = view.get("economy", {})
	var enabled: bool = e.get("version") in [IslandProgression.VERSION, IslandProgression.LEGACY_VERSION]
	var opened: bool = enabled and bool(e.islands[island].opened)
	heading_label.text = "人界・%s" % IslandProgression.NAMES[island]
	activation.visible = e.get("version") != IslandProgression.VERSION
	activation.text = "保留三島原檔並接續丹霞" if enabled else "保留原檔並啟用空島"
	activation.disabled = int(view.get("era_id", 1)) < 2 or not bool(view.get("island_activation", {}).get("ok", false))
	opening.visible = enabled and not opened
	opening.disabled = int(view.get("era_id", 1)) < int(IslandEconomy.ISLANDS[island].era) or (island == "herb" and e.get("version") != IslandProgression.VERSION)
	var role := {"home": "陣芯、丹藥、靈石與符咒加工", "wood": "林業・靈材加工", "ore": "採礦・銅精精煉", "herb": "金丹解鎖・丹液加工、靈草與百年草採集"}
	summary.text = "人界・%s｜%s\n%s" % [IslandProgression.NAMES[island], role[island], "運轉中" if opened else ("待開拓" if enabled else "築基解鎖・啟用前保留原檔")]
	if not enabled:
		var preview: Dictionary = view.get("island_activation", {})
		summary.text += "\n" + String(preview.get("home_policy", "先完成練氣修行與築基，再開拓兩座產業島。")) + "\n" + String(preview.get("cost_policy", "")) + "\n" + String(preview.get("reset_policy", ""))
		summary.text += "\n首批開放祖島、青木島、玄礦島；後續島群將隨境界擴充。"
	var lines: Array[String] = []
	var shown: Array = catalog.get("resources", {}).keys() if island == "home" else {"wood": ["wood", "stone_low", "spirit_timber"], "ore": ["wood", "stone_low", "black_copper", "bronze_essence"], "herb": ["spirit_grass_low", "spirit_grass_100y", "liquid"]}[island]
	for id in shown:
		var quantities: Dictionary = e.get("inventory", {}).get(island, {}).get(id, {})
		lines.append("%s：可用 %.1f・在途／加工預留 %.1f" % [_resource_name(id), float(quantities.get("available", 0)), float(quantities.get("reserved", 0))])
	if island == "herb":
		lines.append("加工共用祖島靈力：可用 %.1f" % float(e.get("inventory", {}).get("home", {}).get("lingli", {}).get("available", 0)))
	inventory.text = "\n".join(lines) if enabled else ""
	var job: Dictionary = e.get("jobs", {}).get(island, {})
	job_status.text = ""
	if island in IslandProgression.RECIPES:
		var recipe: String = IslandProgression.RECIPES[island]
		var def: Dictionary = catalog.get("recipes", {}).get(recipe, {})
		var inputs: Array[String] = []
		for id in def.get("inputs", {}):
			inputs.append("%s%s" % [_resource_name(id), def.inputs[id]])
		job_status.text = "每批 %s → %s1；基礎10秒\n%s" % ["＋".join(inputs), _resource_name(recipe), "尚未加工" if job.is_empty() else "%s・剩餘%d秒" % [status_text(String(job.status)), int(job.remaining)]]
	else:
		var recipe_lines: Array[String] = []
		for recipe in IslandProgression.HOME_RECIPES:
			var def: Dictionary = catalog.get("recipes", {}).get(recipe, {})
			var inputs: Array[String] = []
			for id in def.get("inputs", {}):
				inputs.append("%s%s" % [_resource_name(id), def.inputs[id]])
			recipe_lines.append("%s：%s；%d秒／批・境界%d" % [_resource_name(recipe), "＋".join(inputs), IslandEconomy.DURATIONS[recipe], int(def.get("era", 1))])
		job_status.text = "\n".join(recipe_lines) + "\n" + ("尚未加工" if job.is_empty() else "%s・剩餘%d秒" % [status_text(String(job.status)), int(job.remaining)])
	for button in work_buttons:
		var recipe: String = button.get_meta("recipe")
		button.visible = opened
		button.disabled = job.is_empty() if recipe.is_empty() else (not job.is_empty() or int(view.get("era_id", 1)) < int(catalog.recipes[recipe].era) or (e.get("version") == IslandProgression.LEGACY_VERSION and island in ["home", "herb"]))
	for id in facility_buttons:
		var level := int(e.get("islands", {}).get(island, {}).get("facilities", {}).get(id, 1))
		var cost := IslandProgression.upgrade_cost(id, level)
		var prices: Array[String] = []
		for resource in cost:
			prices.append("%s%d" % [_resource_name(resource), cost[resource]])
		var effect := {"extractor": "採集每秒%d" % (2 * level), "workshop": "每批%d秒" % int(ceil(10.0 / level)), "storage": "各項容量%d" % (100 * level)}
		facility_buttons[id].text = "%s%d階・%s\n%s" % [IslandProgression.FACILITIES[id], level, effect[id], "已達上限" if level >= 3 else "升階：" + "＋".join(prices)]
		facility_buttons[id].visible = opened
		facility_buttons[id].disabled = level >= 3
	for id in route_widgets:
		var widget: Dictionary = route_widgets[id]
		var route: Dictionary = e.get("routes", {}).get(id, {})
		var trip: Dictionary = e.get("trips", {}).get(id, {})
		var ready: bool = enabled and bool(e.islands[IslandEconomy.ROUTES[id][0]].opened) and bool(e.islands[IslandEconomy.ROUTES[id][1]].opened)
		widget.apply.disabled = not ready
		widget.stop.disabled = not ready or route.is_empty()
		widget.upgrade.disabled = not ready or int(route.get("level", 1)) >= 2
		widget.status.text = "%s・最多%d／10秒\n%s" % ["啟用" if route.get("enabled", false) else "停航", 10 * int(route.get("level", 1)), "無在途貨物；檢查來源保留量、目標庫存或容量" if trip.is_empty() else "載貨%s・%d秒後到達" % [trip.cargo, int(trip.remaining)]]
		if not widget.initialized and not route.is_empty():
			widget.reserve.value = float(route.reserve)
			widget.target.value = float(route.target)
			widget.initialized = true

static func status_text(code: String) -> String:
	return {"running": "加工中", "INSUFFICIENT_RESOURCE": "缺料等待航運", "OUTPUT_FULL": "產物滿倉，請運回祖島"}.get(code, code)

func show_result(text: String) -> void:
	message.text = text
	message.visible = not text.is_empty()

func storage_recovered() -> void:
	if message != null and message.text.begins_with("操作未保存："):
		show_result("保存已恢復，進度已存妥。")

func set_layout_bounds(bounds: Rect2) -> void:
	position = bounds.position
	size = bounds.size

func select_island(id: String) -> void:
	if IslandProgression.NAMES.has(id):
		island = id
		_rebuild()
		refresh(_view, _catalog)
