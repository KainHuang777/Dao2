extends Node2D
## Living Abode Controller: bridges Godot scene with GameSession, CommandProcessor, TimeAdvancer, and SaveManager.

const FONT: Font = preload("res://assets/fonts/NotoSerifTC-VF.ttf")
const TERRAIN: Texture2D = preload("res://assets/abode/terrain.png")
const SKY: Texture2D = preload("res://assets/abode/sky.png")
const HUT: Texture2D = preload("res://assets/abode/hut.png")
const GARDEN: Texture2D = preload("res://assets/abode/garden.png")
const ALTAR: Texture2D = preload("res://assets/abode/altar.png")

const CameraScript = preload("res://src/abode/abode_camera.gd")
const BuildingScript = preload("res://src/abode/abode_building.gd")
const FlowScript = preload("res://src/abode/abode_flows.gd")

const BUILDING_NAMES := {
	"hut": "茅屋",
	"wooden_house": "木屋",
	"forest_farm": "林場",
	"stone_mine": "採石場",
	"herb_farm": "靈植場",
	"storage_lingli": "聚靈壇",
	"storage_money": "靈石庫",
	"storage_wood": "木料庫",
	"storage_stone": "石材庫",
	"storage_herb": "靈草庫",
}

const RESOURCE_NAMES := {
	"lingli": "靈氣",
	"money": "靈石",
	"wood": "木材",
	"stone_low": "石材",
	"black_copper": "黑銅",
	"spirit_grass_low": "靈草",
	"foundation_pill": "築基丹",
}

const BUILDING_DESCRIPTIONS := {
	"hut": "窗內一盞燈，是你的修行根基。初期手動引氣，升級後持續產出靈氣並提供容納空間。",
	"wooden_house": "簡樸居所。安身立命，產出並儲存靈石錢幣。",
	"forest_farm": "造林伐木，持續產出修築洞府必備之原木。",
	"stone_mine": "鑿岩掘礦，產出石材與黑銅，為洞府奠定基石。",
	"herb_farm": "靈田自行萌芽吐納，孕育低階靈草。可手動暫停或恢復生息。",
	"storage_lingli": "聚天地之精華，大幅擴充靈氣儲量上限。",
	"storage_money": "深藏靈石寶庫，提升金錢上限。",
	"storage_wood": "堆積木材原木，提升木料庫容上限。",
	"storage_stone": "堆疊沉積石料，提升石材存儲上限。",
}

static func _parse_amount(raw: Variant) -> AmountCompat:
	if raw is AmountCompat:
		return raw
	var res: Dictionary = AmountCompat.try_parse(str(raw))
	if bool(res.get("ok", false)):
		return res["value"]
	return AmountCompat.zero()

class AbodeStateCompat extends RefCounted:
	var session: GameSession
	var garden_running: bool = true
	var elapsed: float = 0.0

	func _init(p_session: GameSession) -> void:
		session = p_session

	var qi: float:
		get:
			if session != null and session.state != null and session.state.resources.has("lingli"):
				return session.state.resources["lingli"].value.to_float()
			return 0.0
		set(val):
			if session != null and session.state != null and session.state.resources.has("lingli"):
				session.state.resources["lingli"].value = AmountCompat.from_number(val)

	var herbs: float:
		get:
			if session != null and session.state != null and session.state.resources.has("spirit_grass_low"):
				return session.state.resources["spirit_grass_low"].value.to_float()
			return 0.0

	var levels: Dictionary:
		get:
			var dict: Dictionary = {}
			if session != null and session.state != null:
				for k in session.state.buildings:
					dict[k] = session.state.buildings[k]
			dict["garden"] = dict.get("herb_farm", 0)
			dict["altar"] = dict.get("storage_lingli", 0)
			return dict

	static func _parse_amount(raw: Variant) -> AmountCompat:
		if raw is AmountCompat:
			return raw
		var res: Dictionary = AmountCompat.try_parse(str(raw))
		if bool(res.get("ok", false)):
			return res["value"]
		return AmountCompat.zero()

	func advance(delta: float) -> void:
		elapsed += delta

	func qi_rate() -> float:
		if session == null:
			return 0.0
		var view: Dictionary = session.get_view()
		if view.resources.has("lingli"):
			return _parse_amount(view.resources["lingli"].rate).to_float()
		return 0.0

	func cost(id: String) -> float:
		var target_id := "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
		var view: Dictionary = session.get_view()
		if view.buildings.has(target_id):
			var costs: Dictionary = view.buildings[target_id].costs
			if costs.has("lingli"):
				return _parse_amount(costs["lingli"]).to_float()
		return 0.0

	func upgrade(id: String) -> bool:
		var target_id := "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
		var cmd := {
			"command_id": "compat_upg_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
			"type": "upgrade_building",
			"expected_revision": session.state.revision,
			"payload": {"building_id": target_id}
		}
		var res: Dictionary = session.submit(cmd)
		return bool(res.get("ok", false))

var session: GameSession
var content: GameContent
var state: AbodeStateCompat
var camera: CameraScript = CameraScript.new()
var flow: FlowScript = FlowScript.new()
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
var realm_label: Label
var resource_label: Label
var crumb: Label
var detail_title: Label
var detail_body: Label
var gather_button: Button
var upgrade_button: Button
var pause_button: Button
var overview_button: Button
var motion_button: Button
var save_button: Button
var zoom_label: Label
var level_up_button: Button
var breakthrough_button: Button
var replay_breakthrough_button: Button
var nine_realms_button: Button

var nine_realms_preview: Control = null
var breakthrough_seq: Control = null
var save_controls: Control = null
var offline_summary: Control = null
var update_elapsed: float = 0.0
var auto_save_elapsed: float = 0.0
var intro_shown: bool = false

func _ready() -> void:
	_init_core()
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

	_setup_buildings(props)

	flow.name = "獨立飛劍與靈氣"
	flow.z_index = 3
	add_child(flow)

	home_marker = _label("你的洞府 · 靈氣生生不息", 65, Color("ffe5a3"))
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

static var save_dir_override: String = ""

func _init_core() -> void:
	var content_loaded: Dictionary = ContentLoader.load_directory("res://content")
	if bool(content_loaded.get("ok", false)):
		content = content_loaded["content"]
	else:
		content = GameContent.new()

	var adapter: StorageAdapter = null
	if save_dir_override != "":
		adapter = FileStorageAdapter.new(save_dir_override)
	elif OS.has_feature("web"):
		adapter = WebStorageAdapter.new("dao2_saves")
	else:
		adapter = FileStorageAdapter.new(SaveManager.DEFAULT_SAVE_DIR)

	SaveManager.configure(content, adapter)

	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var offline_res: Dictionary = OfflineCoordinator.settle(now_ms)

	var loaded_state: GameState = SaveManager.current_state()
	if loaded_state != null and loaded_state.revision > 0:
		session = GameSession.new()
		session.content = content
		session.clock = GameClock.create(loaded_state.total_elapsed_seconds)
		session.state = loaded_state
	else:
		session = GameSession.create_new_game(content)

	state = AbodeStateCompat.new(session)

	if offline_res.get("committed", false):
		call_deferred("_display_offline_summary", offline_res.get("report", {}))

func _setup_buildings(props: Node2D) -> void:
	_add_building(props, "hut", "茅屋", HUT, Vector2(-245, -210), 280)
	_add_building(props, "wooden_house", "木屋", HUT, Vector2(-360, -30), 240)
	_add_building(props, "forest_farm", "林場", GARDEN, Vector2(-120, -280), 230)
	_add_building(props, "stone_mine", "採石場", ALTAR, Vector2(120, -260), 220)
	_add_building(props, "herb_farm", "靈植場", GARDEN, Vector2(300, -98), 245)

	_add_building(props, "storage_lingli", "聚靈壇", ALTAR, Vector2(-8, -70), 215)
	_add_building(props, "storage_money", "靈石庫", HUT, Vector2(-190, 80), 180)
	_add_building(props, "storage_wood", "木料庫", HUT, Vector2(-60, 130), 180)
	_add_building(props, "storage_stone", "石材庫", ALTAR, Vector2(80, 120), 180)
	_add_building(props, "storage_herb", "靈草庫", GARDEN, Vector2(210, 60), 180)

	buildings["garden"] = buildings["herb_farm"]
	buildings["altar"] = buildings["storage_lingli"]

func _add_building(parent: Node2D, id: String, display_name: String, texture: Texture2D, point: Vector2, width: float) -> void:
	var building: Node2D = BuildingScript.new()
	building.position = point
	building.setup(id, display_name, texture, width, FONT)
	parent.add_child(building)
	buildings[id] = building

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

	var locations: Array[Vector2] = [
		Vector2(-1260, -1070),
		Vector2(1500, -920),
		Vector2(420, -2020),
		Vector2(-1580, 830)
	]
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
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("f4e7be"))
	button.add_theme_stylebox_override("normal", _style())
	button.add_theme_stylebox_override("hover", _style(Color(0.10, 0.25, 0.24, 0.99)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.17, 0.35, 0.28, 0.99)))
	button.pressed.connect(action)
	return button

func _view_button(text: String, action: Callable, width: float) -> Button:
	var button := _button(text, action)
	button.custom_minimum_size = Vector2(width, 56)
	button.add_theme_font_size_override("font_size", 24)
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
	header_box.add_theme_constant_override("separation", 6)
	header.add_child(header_box)

	crumb = _label("人界 / 無名山域 / 你的洞府", 19, Color("c0d8cc"), 1)
	header_box.add_child(crumb)

	title_label = _label("一方洞府，自有生息", 34, Color("fff0ca"), 2)
	header_box.add_child(title_label)

	realm_label = _label("練氣 · 1層", 20, Color("fce2a6"), 1)
	header_box.add_child(realm_label)

	var realm_action_box := HBoxContainer.new()
	realm_action_box.add_theme_constant_override("separation", 8)
	header_box.add_child(realm_action_box)

	level_up_button = _button("修為晉階", _level_up_cultivation)
	level_up_button.custom_minimum_size = Vector2(120, 44)
	level_up_button.add_theme_font_size_override("font_size", 20)
	level_up_button.visible = false
	realm_action_box.add_child(level_up_button)

	breakthrough_button = _button("突破至築基期", _breakthrough_era)
	breakthrough_button.custom_minimum_size = Vector2(180, 44)
	breakthrough_button.add_theme_font_size_override("font_size", 20)
	breakthrough_button.visible = false
	realm_action_box.add_child(breakthrough_button)

	resource_label = _label("", 21, Color("e4f0dc"), 1)
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

	save_button = _button("存檔管理", _toggle_save_controls)
	toolbar.add_child(save_button)

	replay_breakthrough_button = _button("重溫突破", _replay_breakthrough)
	replay_breakthrough_button.visible = false
	toolbar.add_child(replay_breakthrough_button)

	nine_realms_button = _button("九界星圖", _open_nine_realms_overview)
	toolbar.add_child(nine_realms_button)

	toolbar.add_child(_button("操作說明", _show_help))

	hint_panel = Panel.new()
	hint_panel.add_theme_stylebox_override("panel", _style(Color(0.008, 0.035, 0.05, 0.91)))
	hud.add_child(hint_panel)

	hint = _label("拖曳山河 · 滾輪 / 雙指縮放 · 點選建築", 18, Color("f2e8c7"), 1)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_panel.add_child(hint)
	hint_panel.visible = true

	footer = _label("正式核心接入 · 自動存檔運轉中", 16, Color("dce6dc"), 1)
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

	detail_title = _label("", 28, Color("fff0c8"), 2)
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(detail_title)
	title_row.add_child(_button("收起", _close_detail))

	detail_body = _label("", 21, Color("eaf2ea"), 1)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_body)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	box.add_child(action_row)

	gather_button = _button("聚氣引靈", _gather_lingli)
	action_row.add_child(gather_button)

	upgrade_button = _button("", _upgrade_selected)
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(upgrade_button)

	pause_button = _button("暫停藥圃", _toggle_garden)
	action_row.add_child(pause_button)

	var save_ctrl_script = preload("res://src/presentation/save_controls.gd")
	save_controls = save_ctrl_script.new()
	save_controls.visible = false
	save_controls.position = Vector2(300, 100)
	hud.add_child(save_controls)

	var offline_sum_script = preload("res://src/presentation/offline_summary.gd")
	offline_summary = offline_sum_script.new()
	offline_summary.visible = false
	offline_summary.position = Vector2(300, 100)
	hud.add_child(offline_summary)

	var bt_seq_script = preload("res://src/presentation/breakthrough_sequence.gd")
	breakthrough_seq = bt_seq_script.new()
	hud.add_child(breakthrough_seq)

	var nr_script = preload("res://src/presentation/nine_realms_preview.gd")
	nine_realms_preview = nr_script.new()
	nine_realms_preview.aspiration_changed.connect(_on_nine_realms_aspiration_changed)
	hud.add_child(nine_realms_preview)

func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	hud.size = vp
	sky.position = Vector2(-75, -75)
	sky.size = vp + Vector2(150, 150)
	shade.size = vp

	header.position = Vector2(28, 28)
	header.size = Vector2(380, 210)

	hud.get_node("Viewbar").position = Vector2(28, 250)

	toolbar.position = Vector2(28, vp.y - 84)
	toolbar.size = Vector2(600, 64)

	hint_panel.position = Vector2(28, vp.y - 154)
	hint_panel.size = Vector2(620, 56)
	hint.position = Vector2(12, 4)
	hint.size = hint_panel.size - Vector2(24, 8)

	footer.position = Vector2(vp.x - 330, vp.y - 56)
	footer.size = Vector2(302, 22)

	info_panel.position = Vector2(vp.x - 420, 28)
	info_panel.size = Vector2(392, 340)

func _process(delta: float) -> void:
	state.advance(delta)
	session.advance_time(delta)

	var view: Dictionary = session.get_view()

	flow.garden_running = state.garden_running
	var altar_level: int = int(view.buildings.get("storage_lingli", {}).get("level", 0))
	flow.intensity = float(altar_level) + float(view.buildings.get("hut", {}).get("level", 0))
	flow.reduced_motion = reduced

	_update_buildings_visual(view)

	var distant: float = clampf((0.42 - camera.zoom.x) / 0.18, 0.0, 1.0)
	region_layer.modulate.a = distant
	home_marker.modulate.a = distant

	for building in buildings.values():
		if building.has_node("caption"):
			building.caption.modulate.a = 1.0 - distant

	sky.position = Vector2(-75, -75) - camera.position * 0.016
	shade.color.a = 0.18 + distant * 0.34

	update_elapsed += delta
	if update_elapsed >= 0.25:
		update_elapsed = 0.0
		_refresh_hud()

	auto_save_elapsed += delta
	if auto_save_elapsed >= 15.0:
		auto_save_elapsed = 0.0
		_save_game()

	if state.elapsed > 7.0 and not intro_shown:
		intro_shown = true
		if view.next_objective != null:
			hint.text = "洞府運轉中。當前指引：提升【%s】。" % BUILDING_NAMES.get(String(view.next_objective.id), String(view.next_objective.id))

func _update_buildings_visual(view: Dictionary) -> void:
	for id in buildings:
		var target_id: String = "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
		var b_view: Dictionary = view.buildings.get(target_id, {})
		var b_node = buildings[id]
		var is_vis: bool = bool(b_view.get("visible", false))

		b_node.visible = is_vis
		b_node.level = int(b_view.get("level", 0))
		b_node.selected = (id == selected_id or target_id == selected_id)
		b_node.running = state.garden_running if (target_id == "herb_farm") else true
		b_node.reduced_motion = reduced

func _refresh_hud() -> void:
	var view: Dictionary = session.get_view()
	_update_buildings_visual(view)

	var era_info: Dictionary = view.get("era", {})
	var era_name: String = era_info.get("name", "練氣")
	var cur_level: int = int(view.get("level", 1))
	var train_sec: float = float(view.get("training_seconds", 0.0))
	var req_sec: float = float(view.get("next_level_required_seconds", 0.0))
	var max_life: float = float(view.get("max_lifespan_seconds", 0.0))
	var elapsed_sec: float = float(view.get("total_elapsed_seconds", 0.0))
	var remain_life: float = maxf(0.0, max_life - elapsed_sec)

	realm_label.text = "%s · %d層  (修煉 %.0f/%.0f 秒) · 壽元剩餘 %.0f 祀" % [
		era_name, cur_level, train_sec, req_sec, remain_life / 60.0
	]

	var can_lvl: bool = bool(view.get("can_level_up", false))
	level_up_button.visible = can_lvl
	if can_lvl:
		var cost_dict: Dictionary = view.get("level_up_costs", {})
		var cost_strs := []
		for r_id in cost_dict:
			var req_val: float = _parse_amount(cost_dict[r_id]).to_float()
			cost_strs.append("%d %s" % [int(req_val), RESOURCE_NAMES.get(r_id, r_id)])
		level_up_button.text = "修為晉階（消耗 %s）" % (" · ".join(cost_strs) if cost_strs.size() > 0 else "功滿")

	var cur_era: int = int(view.get("era_id", 1))
	breakthrough_button.visible = (cur_level >= 10 and cur_era == 1)
	if breakthrough_button.visible:
		var can_bt: bool = bool(view.get("can_breakthrough", false))
		breakthrough_button.disabled = not can_bt
		if can_bt:
			breakthrough_button.text = "★ 突破至築基期 ★"
		else:
			var req_caps: Dictionary = view.get("breakthrough_requirements", {})
			var req_lingli: int = int(req_caps.get("lingli", 500))
			var cur_cap: int = int(_parse_amount(view.resources.get("lingli", {}).get("cap", 0)).to_float())
			breakthrough_button.text = "突破需靈氣容量 %d（當前 %d）" % [req_lingli, cur_cap]

	replay_breakthrough_button.visible = (cur_era >= 2)
	if cur_era >= 2:
		shade.color = Color(0.04, 0.08, 0.16, 0.22)
		home_marker.text = "你的洞府 · 築基功成 祥雲瑞靄"

	var res_lines := []
	var res_order := ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low", "foundation_pill"]
	for r_id in res_order:
		if view.resources.has(r_id) and bool(view.resources[r_id].visible):
			var r_data: Dictionary = view.resources[r_id]
			var val: float = _parse_amount(r_data.value).to_float()
			var cap: float = _parse_amount(r_data.cap).to_float()
			var rate: float = _parse_amount(r_data.rate).to_float()
			var r_name: String = RESOURCE_NAMES.get(r_id, r_id)
			var rate_str := (" · +%.1f/s" % rate) if rate > 0.0 else ""
			res_lines.append("%s %d/%d%s" % [r_name, int(val), int(cap), rate_str])

	resource_label.text = "\n".join(res_lines)

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
		if buildings[id].visible and buildings[id].contains_point(point):
			selected_id = "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
			info_panel.visible = true
			_refresh_detail()
			print("ABODE_SELECT: ", id)
			return

	_close_detail()

func _refresh_detail() -> void:
	var view: Dictionary = session.get_view()
	var b_id := selected_id
	if not view.buildings.has(b_id):
		return

	var b_data: Dictionary = view.buildings[b_id]
	var b_name: String = BUILDING_NAMES.get(b_id, b_id)
	var cur_lvl: int = int(b_data.level)
	var lvl_cap: int = int(b_data.level_cap)

	detail_title.text = "%s · %s" % [b_name, "未建造" if cur_lvl == 0 else str(cur_lvl) + "階"]
	detail_body.text = BUILDING_DESCRIPTIONS.get(b_id, "")

	gather_button.visible = (b_id == "hut")

	if cur_lvl >= lvl_cap:
		upgrade_button.text = "已達當前上限"
		upgrade_button.disabled = true
	else:
		var cost_strs := []
		for r_id in b_data.costs:
			var req_val: float = _parse_amount(b_data.costs[r_id]).to_float()
			var r_name: String = RESOURCE_NAMES.get(r_id, r_id)
			cost_strs.append("%d %s" % [int(req_val), r_name])
		var cost_text := " · ".join(cost_strs)
		upgrade_button.text = ("建造 · %s" if cur_lvl == 0 else "升級 · %s") % cost_text
		upgrade_button.disabled = not bool(b_data.affordable)

	pause_button.visible = (b_id == "herb_farm")
	pause_button.text = "恢復藥圃" if not state.garden_running else "暫停藥圃"

func _gather_lingli() -> void:
	var cmd := {
		"command_id": "gather_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "gather",
		"expected_revision": session.state.revision,
		"payload": {"resource_id": "lingli"}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		hint.text = "聚氣吐納，靈氣＋1。"
		_refresh_hud()
		if not session.state.tutorial_flags.get("seen_nine_realms_hook", false):
			session.state.tutorial_flags["seen_nine_realms_hook"] = true
			_save_game()
			trigger_nine_realms_hook(false)

func _level_up_cultivation() -> void:
	var cmd := {
		"command_id": "lvl_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "level_up_cultivation",
		"expected_revision": session.state.revision,
		"payload": {}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		hint.text = "修為突破一層！洞府靈息更為充沛。"
		_save_game()
		_refresh_hud()

func _breakthrough_era() -> void:
	var cmd := {
		"command_id": "bt_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "breakthrough_era",
		"expected_revision": session.state.revision,
		"payload": {}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		hint.text = "破關築基，天地共感，壽元大增！"
		_save_game()
		_refresh_hud()
		if breakthrough_seq != null:
			breakthrough_seq.play("練氣期", "築基期")

func _replay_breakthrough() -> void:
	if breakthrough_seq != null:
		breakthrough_seq.play("練氣期", "築基期")

func trigger_nine_realms_hook(is_replay: bool = false) -> void:
	if nine_realms_preview == null:
		return
	var current_aspire: String = String(session.state.tutorial_flags.get("aspired_realm", ""))
	nine_realms_preview.play_hook(camera, current_aspire, Callable(self, "_on_nine_realms_closed"), reduced, is_replay)

func _open_nine_realms_overview() -> void:
	if nine_realms_preview == null:
		return
	var current_aspire: String = String(session.state.tutorial_flags.get("aspired_realm", ""))
	nine_realms_preview.show_overview(camera, current_aspire, Callable(self, "_on_nine_realms_closed"))

func _on_nine_realms_aspiration_changed(realm_id: String) -> void:
	if session and session.state:
		session.state.tutorial_flags["aspired_realm"] = realm_id
		_save_game()
		hint.text = "已標記心之所向，大道在前，且行眼前事。"

func _on_nine_realms_closed() -> void:
	_refresh_hud()

func _upgrade_selected() -> void:
	if selected_id == "":
		return
	var cmd := {
		"command_id": "upg_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "upgrade_building",
		"expected_revision": session.state.revision,
		"payload": {"building_id": selected_id}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		if buildings.has(selected_id):
			buildings[selected_id].pulse_upgrade()
		hint.text = "建造／升級完成！產出與洞府生息已擴展。"
		_save_game()
		_refresh_hud()
		print("ABODE_UPGRADE: ", selected_id, " level=", session.state.buildings.get(selected_id, 0))

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
	hint.text = "回到洞府。點選建築可查看營造、引氣或升階。"
	print("ABODE_HOME")

func _toggle_motion() -> void:
	reduced = not reduced
	camera.reduced_motion = reduced
	motion_button.text = "標準特效" if reduced else "低特效"
	print("ABODE_MOTION reduced=", reduced)

func _toggle_save_controls() -> void:
	if save_controls:
		save_controls.visible = not save_controls.visible

func _display_offline_summary(report: Dictionary) -> void:
	if offline_summary and not report.is_empty():
		offline_summary.show_report(report)

func _save_game() -> void:
	if session == null or session.state == null:
		return
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var sim_tick: int = int(floor(session.state.total_elapsed_seconds / 60.0))
	var meta: Dictionary = {
		"save_id": "local",
		"saved_at_utc_ms": str(now_ms),
		"settled_until_utc_ms": str(now_ms),
		"sim_tick": str(sim_tick),
	}
	SaveManager.save(session.state, meta)

func _show_help() -> void:
	hint.text = "滑鼠拖曳／單指平移；滾輪／雙指縮放。\n點建築看供給；M 展開山域，Home 歸家。"
