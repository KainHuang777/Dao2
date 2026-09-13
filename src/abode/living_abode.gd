extends Node2D
## Native Godot scene prototype: art props, camera, simulation and HUD are separate.
const StateScript = preload("res://src/abode/abode_state.gd")
const CameraScript = preload("res://src/abode/abode_camera.gd")
const BuildingScript = preload("res://src/abode/abode_building.gd")
const FlowScript = preload("res://src/abode/abode_flows.gd")
const FONT: Font = preload("res://assets/fonts/NotoSerifTC-VF.ttf")
const TERRAIN: Texture2D = preload("res://assets/abode/terrain.png")
const SKY: Texture2D = preload("res://assets/abode/sky.png")
const HUT: Texture2D = preload("res://assets/abode/hut.png")
const GARDEN: Texture2D = preload("res://assets/abode/garden.png")
const ALTAR: Texture2D = preload("res://assets/abode/altar.png")

var state = StateScript.new()
var camera = CameraScript.new()
var flow = FlowScript.new()
var buildings: Dictionary = {}
var selected_id: String = ""
var reduced: bool = false
var region_visible: bool = false
var region_layer: Node2D
var home_marker: Label
var sky: TextureRect
var shade: ColorRect
var hud: Control
var header: PanelContainer
var info_panel: PanelContainer
var toolbar: HBoxContainer
var footer: Label
var hint: Label
var hint_panel: Panel
var title_label: Label
var resource_label: Label
var crumb: Label
var detail_title: Label
var detail_body: Label
var upgrade_button: Button
var pause_button: Button
var overview_button: Button
var motion_button: Button
var zoom_label: Label
var update_elapsed: float = 0.0
var intro_shown: bool = false

func _ready() -> void:
	_build_background()
	_build_region()
	var ground := Sprite2D.new()
	ground.name = "獨立地形"
	ground.texture = TERRAIN
	ground.scale = Vector2.ONE * 1200.0 / TERRAIN.get_width()
	add_child(ground)
	var props := Node2D.new()
	props.name = "可互動建築"
	props.y_sort_enabled = true
	add_child(props)
	_add_building(props, "hut", "茅屋", HUT, Vector2(-245, -210), 280)
	_add_building(props, "garden", "藥圃", GARDEN, Vector2(300, -98), 245)
	_add_building(props, "altar", "聚靈陣", ALTAR, Vector2(-8, -70), 215)
	flow.name = "獨立飛劍與靈氣"
	flow.z_index = 3
	add_child(flow)
	home_marker = _label("你的洞府 · 靈氣仍在運轉", 65, Color("ffe5a3"))
	home_marker.position = Vector2(-420, 410)
	home_marker.size.x = 840
	home_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_marker.z_index = 5
	add_child(home_marker)
	camera.name = "世界鏡頭"
	add_child(camera)
	camera.world_clicked.connect(_pick_world)
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_hud()
	print("ABODE_READY: native Camera2D, 3 independent buildings, autonomous state and flying swords")

func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	sky = TextureRect.new()
	sky.texture = SKY
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sky)
	shade = ColorRect.new()
	shade.color = Color(0.015, 0.085, 0.13, 0.24)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)

func _build_region() -> void:
	region_layer = Node2D.new()
	region_layer.name = "山域遠景"
	region_layer.z_index = -2
	add_child(region_layer)
	var locations: Array[Vector2] = [Vector2(-1260, -1070), Vector2(1500, -920), Vector2(420, -2020), Vector2(-1580, 830)]
	var titles: Array[String] = ["雲外山域", "靈界方向 · 未開放", "天外仍有天地", "人界群山"]
	for i in locations.size():
		var island := Sprite2D.new()
		island.texture = TERRAIN
		island.position = locations[i]
		island.scale = Vector2.ONE * (0.40 + i * 0.035)
		island.modulate = Color(0.60, 0.79, 0.78, 0.8)
		region_layer.add_child(island)
		var label := _label(titles[i], 65, Color("d1dfd1"))
		label.position = locations[i] + Vector2(-400, 300)
		label.size.x = 800
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		region_layer.add_child(label)
		var path := Line2D.new()
		path.width = 5.0
		path.default_color = Color(0.86, 0.78, 0.48, 0.40)
		for j in 40:
			var t: float = j / 39.0
			path.add_point(Vector2.ZERO.lerp(locations[i], t) + Vector2(120 * sin(t * PI), -110 * sin(t * PI)))
		path.z_index = -1
		region_layer.add_child(path)

func _add_building(parent: Node2D, id: String, display_name: String, texture: Texture2D, point: Vector2, width: float) -> void:
	var building = BuildingScript.new()
	building.position = point
	building.setup(id, display_name, texture, width, FONT)
	parent.add_child(building)
	buildings[id] = building

func _label(text: String, font_size: int, color: Color = Color("eee4c9"), outline_size: int = 2) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color(0.01, 0.035, 0.05, 0.96))
	result.add_theme_constant_override("outline_size", outline_size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _style(color: Color = Color(0.018, 0.07, 0.10, 0.96)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.82, 0.73, 0.49, 0.80)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(132, 64)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color("f4e7be"))
	button.add_theme_stylebox_override("normal", _style())
	button.add_theme_stylebox_override("hover", _style(Color(0.10, 0.25, 0.24, 0.99)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.17, 0.35, 0.28, 0.99)))
	button.pressed.connect(action)
	return button

func _view_button(text: String, action: Callable, width: float) -> Button:
	var button := _button(text, action)
	button.custom_minimum_size = Vector2(width, 56)
	button.add_theme_font_size_override("font_size", 26)
	return button

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", _style(Color(0.012, 0.055, 0.08, 0.97)))
	hud.add_child(header)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 7)
	header.add_child(header_box)
	crumb = _label("人界 / 無名山域 / 你的洞府", 19, Color("c0d8cc"), 1)
	header_box.add_child(crumb)
	title_label = _label("一方洞府，自有生息", 36, Color("fff0ca"), 2)
	header_box.add_child(title_label)
	resource_label = _label("", 24, Color("e4f0dc"), 1)
	header_box.add_child(resource_label)
	var viewbar := HBoxContainer.new()
	viewbar.name = "Viewbar"
	viewbar.add_theme_constant_override("separation", 8)
	hud.add_child(viewbar)
	viewbar.add_child(_view_button("＋", func(): camera.change_zoom(1.25), 58))
	viewbar.add_child(_view_button("－", func(): camera.change_zoom(0.8), 58))
	viewbar.add_child(_view_button("歸家", _return_home, 104))
	zoom_label = _label("", 19, Color("e4e7c8"), 1)
	viewbar.add_child(zoom_label)
	toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	hud.add_child(toolbar)
	overview_button = _button("神識展開", _toggle_overview)
	toolbar.add_child(overview_button)
	motion_button = _button("低特效", _toggle_motion)
	toolbar.add_child(motion_button)
	toolbar.add_child(_button("操作說明", _show_help))
	hint_panel = Panel.new()
	hint_panel.add_theme_stylebox_override("panel", _style(Color(0.008, 0.035, 0.05, 0.91)))
	hud.add_child(hint_panel)
	hint = _label("拖曳山河 · 滾輪 / 雙指縮放 · 點選建築", 18, Color("f2e8c7"), 1)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_panel.add_child(hint)
	hint_panel.visible = false
	footer = _label("展示原型 · 本次進度不存檔", 16, Color("dce6dc"), 1)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(footer)
	info_panel = PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", _style(Color(0.008, 0.045, 0.07, 0.98)))
	info_panel.visible = false
	hud.add_child(info_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	info_panel.add_child(box)
	var title_row := HBoxContainer.new()
	box.add_child(title_row)
	detail_title = _label("", 30, Color("fff0c8"), 2)
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(detail_title)
	title_row.add_child(_button("收起", _close_detail))
	detail_body = _label("", 22, Color("eaf2ea"), 1)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_body)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	box.add_child(action_row)
	upgrade_button = _button("", _upgrade_selected)
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(upgrade_button)
	pause_button = _button("暫停藥圃", _toggle_garden)
	action_row.add_child(pause_button)

func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	hud.size = vp
	sky.position = Vector2(-75, -75)
	sky.size = vp + Vector2(150, 150)
	shade.size = vp
	header.position = Vector2(28, 28)
	header.size = Vector2(350, 192)
	hud.get_node("Viewbar").position = Vector2(28, 234)
	toolbar.position = Vector2(28, vp.y - 84)
	toolbar.size = Vector2(460, 64)
	hint_panel.position = Vector2(500, vp.y - 154)
	hint_panel.size = Vector2(500, 56)
	hint.position = Vector2(12, 4)
	hint.size = hint_panel.size - Vector2(24, 8)
	footer.position = Vector2(vp.x - 330, vp.y - 56)
	footer.size = Vector2(302, 22)
	info_panel.position = Vector2(vp.x - 390, 28)
	info_panel.size = Vector2(362, 316)

func _process(delta: float) -> void:
	state.advance(delta)
	flow.garden_running = state.garden_running
	flow.intensity = float(state.levels["altar"])
	flow.reduced_motion = reduced
	for id in buildings:
		buildings[id].level = int(state.levels[id])
		buildings[id].selected = id == selected_id
		buildings[id].running = state.garden_running if id == "garden" else true
		buildings[id].reduced_motion = reduced
	var distant: float = clampf((0.42 - camera.zoom.x) / 0.18, 0.0, 1.0)
	region_layer.modulate.a = distant
	home_marker.modulate.a = distant
	for building in buildings.values():
		building.caption.modulate.a = 1.0 - distant
	sky.position = Vector2(-75, -75) - camera.position * 0.016
	shade.color.a = 0.18 + distant * 0.34
	update_elapsed += delta
	if update_elapsed >= 0.25:
		update_elapsed = 0
		_refresh_hud()
	if state.elapsed > 7 and not intro_shown:
		intro_shown = true
		hint.text = "洞府已自行運轉。試著「神識展開」，找回你的起點。"

func _refresh_hud() -> void:
	resource_label.text = "靈氣 %d  · +%.0f／秒\n靈草 %d  · +%d／秒" % [int(state.qi), state.qi_rate(), int(state.herbs), int(state.levels["garden"]) if state.garden_running else 0]
	zoom_label.text = "%d%%" % int(camera.zoom.x * 100)
	region_visible = camera.target_zoom < 0.34
	overview_button.text = "回到洞府" if region_visible else "神識展開"
	crumb.text = "人界 / 山域總覽 · 遠景尚未開放" if region_visible else "人界 / 無名山域 / 你的洞府"
	title_label.text = "群山之間，認得自己的燈火" if region_visible else "一方洞府，自有生息"
	if selected_id != "" and info_panel.visible:
		_refresh_detail()

func _pick_world(point: Vector2) -> void:
	if camera.zoom.x < 0.34:
		if point.distance_to(Vector2.ZERO) < 800:
			_return_home()
		else:
			hint.text = "遠處是未開放的山域。點自己的洞府，可回到近景。"
		return
	var ids: Array = buildings.keys()
	ids.reverse()
	for id in ids:
		if buildings[id].contains_point(point):
			selected_id = id
			info_panel.visible = true
			_refresh_detail()
			print("ABODE_SELECT: ", id)
			return
	_close_detail()

func _refresh_detail() -> void:
	var names: Dictionary = {"hut": "茅屋", "garden": "藥圃", "altar": "聚靈陣"}
	var descriptions: Dictionary = {
		"hut": "窗內一盞燈，是你的修行根基。升級提高靈氣供給，飛劍持續往返聚靈陣。",
		"garden": "靈草自行生長。暫停後停止產出，這條供給線上的飛劍也會停駐。",
		"altar": "靈氣沿供給路線匯聚。升級提高修行供給，陣紋與飛劍流動會更明顯。"
	}
	detail_title.text = "%s · %d階" % [names[selected_id], int(state.levels[selected_id])]
	detail_body.text = descriptions[selected_id]
	upgrade_button.text = "升級 · %d 靈氣" % int(state.cost(selected_id))
	upgrade_button.disabled = state.qi < state.cost(selected_id) or int(state.levels[selected_id]) >= 5
	if int(state.levels[selected_id]) >= 5:
		upgrade_button.text = "本次示範已滿階"
	pause_button.visible = selected_id == "garden"
	pause_button.text = "恢復藥圃" if not state.garden_running else "暫停藥圃"

func _upgrade_selected() -> void:
	if state.upgrade(selected_id):
		buildings[selected_id].pulse_upgrade()
		hint.text = "升級完成。產出已提高，切換鏡頭也會繼續運作。"
		_refresh_hud()
		print("ABODE_UPGRADE: ", selected_id, " level=", state.levels[selected_id])

func _toggle_garden() -> void:
	state.garden_running = not state.garden_running
	_refresh_hud()
	print("ABODE_GARDEN_RUNNING: ", state.garden_running)

func _close_detail() -> void:
	selected_id = ""
	if info_panel:
		info_panel.visible = false

func _toggle_overview() -> void:
	_close_detail()
	if camera.target_zoom < 0.34:
		_return_home()
	else:
		camera.focus_region()
		hint.text = "那一點仍在發光的地方，就是你的洞府。點它即可返回。"
		print("ABODE_REGION: same world and simulation retained")

func _return_home() -> void:
	_close_detail()
	camera.focus_home()
	hint.text = "回到洞府。試著點藥圃，觀察暫停與恢復供給。"
	print("ABODE_HOME")

func _toggle_motion() -> void:
	reduced = not reduced
	camera.reduced_motion = reduced
	motion_button.text = "標準特效" if reduced else "低特效"
	print("ABODE_MOTION reduced=", reduced)

func _show_help() -> void:
	hint.text = "滑鼠拖曳／單指平移；滾輪／雙指縮放。\n點建築看供給；M 展開山域，Home 歸家。"
