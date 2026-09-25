extends Node2D
## Living Abode Controller: bridges Godot scene with GameSession, CommandProcessor, TimeAdvancer, and SaveManager.

const TERRAIN: Texture2D = preload("res://assets/abode/terrain.png")
const SKY: Texture2D = preload("res://assets/abode/sky.png")
const HUT: Texture2D = preload("res://assets/abode/hut.png")
const GARDEN: Texture2D = preload("res://assets/abode/garden.png")
const ALTAR: Texture2D = preload("res://assets/abode/altar.png")

const CameraScript = preload("res://src/abode/abode_camera.gd")
const BuildingScript = preload("res://src/abode/abode_building.gd")
const FlowScript = preload("res://src/abode/abode_flows.gd")
const BuildingCatalogScript = preload("res://src/presentation/building_catalog.gd")
const TreeScript = preload("res://src/abode/abode_tree.gd")

const BUILDING_NAMES := {
	"hut": "茅屋",
	"wooden_house": "木屋",
	"forest_farm": "林場",
	"stone_mine": "採石場",
	"herb_farm": "靈植場",
	"storage_lingli": "聚靈壇",
	"storage_money": "錢莊",
	"storage_wood": "木料庫",
	"storage_stone": "靈石庫",
	"storage_herb": "靈草庫",
}

const RESOURCE_NAMES := {
	"lingli": "靈氣",
	"money": "金錢",
	"wood": "靈木",
	"stone_low": "下品靈石",
	"black_copper": "玄銅",
	"spirit_grass_low": "靈草",
	"foundation_pill": "築基丹",
}

const BUILDING_DESCRIPTIONS := {
	"hut": "窗內一盞燈，是你的修行根基。初期手動引氣，升級後持續產出靈氣並提供容納空間。",
	"wooden_house": "簡樸居所。安身立命，產出並儲存金錢。",
	"forest_farm": "造林伐木，持續產出修築洞府必備之原木。",
	"stone_mine": "鑿岩掘礦，產出下品靈石與玄銅，為洞府奠定基石。",
	"herb_farm": "靈田自行萌芽吐納，孕育低階靈草。可手動暫停或恢復生息。",
	"storage_lingli": "聚天地之精華，大幅擴充靈氣儲量上限。",
	"storage_money": "經營錢莊，提升金錢儲存上限。",
	"storage_wood": "堆積木材原木，提升木料庫容上限。",
	"storage_stone": "封存下品靈石，提升其儲存上限。",
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
var spirit_tree: Node2D
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
var hint_heading: Label
var hint_panel: PanelContainer
var title_label: Label
var realm_label: Label
var realm_progress_label: Label
var resource_label: Label
var mini_gather_button: Button
var mini_resource_id: String = "lingli"
var selected_gather_id: String = ""
var gather_resource_ids: Array[String] = []
var last_visible_resource_count: int = -1
var gather_menu: MenuButton
var action_bar: HBoxContainer
var resource_ribbon: PanelContainer
var resource_ribbon_box: VBoxContainer
var resource_scroll: ScrollContainer
var resource_mode_buttons: Array[Button] = []
var resource_display_mode: int = 1
var objective_button: Button
var building_catalog_button: Button
var island_mode_button: Button
var building_catalog: PanelContainer
var last_guidance_key: String = ""
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
var reincarnation_button: Button

var nine_realms_preview: Control = null
var breakthrough_seq: Control = null
var save_controls: Control = null
var offline_summary: Control = null
var reincarnation_panel: Control = null

var update_elapsed: float = 0.0
var auto_save_elapsed: float = 0.0
enum HudLayout { WIDE, COMPACT, PORTRAIT }
var layout_mode: int = HudLayout.WIDE
var header_box: VBoxContainer
var viewbar: HBoxContainer
var detail_actions: HFlowContainer
var detail_scroll: ScrollContainer
var return_to_catalog_after_detail: bool = false
var help_button: Button
var more_menu: MenuButton

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

	print("ABODE_READY: native Camera2D, home landmark and managed building catalogue, autonomous state and flying swords")

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
	# Three rows of bounded build plots on the grassy upper surface.
	_add_building(props, "hut", "茅屋", HUT, Vector2(-245, -210), 225)
	_add_building(props, "forest_farm", "林場", GARDEN, Vector2(0, -240), 145)
	_add_building(props, "stone_mine", "採石場", ALTAR, Vector2(245, -220), 145)
	_add_building(props, "wooden_house", "木屋", HUT, Vector2(-335, -85), 155)
	_add_building(props, "herb_farm", "靈植場", GARDEN, Vector2(-90, -85), 160)
	_add_building(props, "storage_lingli", "聚靈壇", ALTAR, Vector2(175, -85), 160)
	_add_building(props, "storage_money", "錢莊", HUT, Vector2(-335, 35), 120)
	_add_building(props, "storage_wood", "木料庫", HUT, Vector2(-110, 35), 120)
	_add_building(props, "storage_stone", "靈石庫", ALTAR, Vector2(115, 35), 120)
	_add_building(props, "storage_herb", "靈草庫", GARDEN, Vector2(335, 35), 120)

	buildings["garden"] = buildings["herb_farm"]
	buildings["altar"] = buildings["storage_lingli"]

	spirit_tree = TreeScript.new()
	spirit_tree.position = Vector2(130, -190)
	spirit_tree.setup("靈木", GARDEN, 145.0, UiTypography.emphasis_font())
	props.add_child(spirit_tree)

func _add_building(parent: Node2D, id: String, display_name: String, texture: Texture2D, point: Vector2, width: float) -> void:
	var building: Node2D = BuildingScript.new()
	building.position = point
	building.setup(id, display_name, texture, width, UiTypography.emphasis_font())
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
	result.add_theme_font_override("font", UiTypography.body_font())
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
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(132, 56)
	button.add_theme_font_override("font", UiTypography.emphasis_font())
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("f4e7be"))
	button.add_theme_stylebox_override("normal", _style())
	button.add_theme_stylebox_override("hover", _style(Color(0.10, 0.25, 0.24, 0.99)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.17, 0.35, 0.28, 0.99)))
	button.pressed.connect(action)
	return button

func _view_button(text: String, action: Callable, width: float) -> Button:
	var button := _button(text, action)
	button.custom_minimum_size = Vector2(width, 56)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _configure_more_menu() -> void:
	more_menu = MenuButton.new()
	more_menu.text = "更多功能"
	more_menu.custom_minimum_size = Vector2(132, 64)
	more_menu.add_theme_font_override("font", UiTypography.emphasis_font())
	more_menu.add_theme_font_size_override("font_size", 22)
	more_menu.add_theme_color_override("font_color", Color("f4e7be"))
	more_menu.add_theme_stylebox_override("normal", _style())
	more_menu.visible = true
	var popup := more_menu.get_popup()
	popup.add_item("低特效", 1)
	popup.add_item("存檔管理", 2)
	popup.add_item("九界星圖", 3)
	popup.add_item("操作說明", 4)
	popup.add_item("重溫突破", 5)
	popup.add_item("輪迴天道", 6)
	popup.id_pressed.connect(_on_more_menu_pressed)
	toolbar.add_child(more_menu)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = UiTypography.create_theme()
	layer.add_child(hud)

	header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", _style(Color(0.012, 0.055, 0.08, 0.97)))
	hud.add_child(header)

	header_box = VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 6)
	header.add_child(header_box)

	crumb = _label("人界 / 無名山域 / 你的洞府", 19, Color("c0d8cc"), 1)
	header_box.add_child(crumb)

	title_label = _label("一方洞府，自有生息", 34, Color("fff0ca"), 2)
	title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	header_box.add_child(title_label)

	realm_label = _label("境界：練氣期 · 1/10 層", 20, Color("fce2a6"), 1)
	header_box.add_child(realm_label)
	realm_progress_label = _label("修煉 0/60 秒 · 壽元 80/80 祀", 16, Color("d9e4d0"), 1)
	header_box.add_child(realm_progress_label)

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

	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	header_box.add_child(resource_row)
	resource_label = _label("", 17, Color("e4f0dc"), 1)
	resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.add_child(resource_label)
	mini_gather_button = Button.new()
	mini_gather_button.custom_minimum_size = Vector2(82, 48)
	mini_gather_button.add_theme_font_override("font", UiTypography.emphasis_font())
	mini_gather_button.add_theme_font_size_override("font_size", 16)
	mini_gather_button.pressed.connect(func(): _gather_resource(mini_resource_id))
	resource_row.add_child(mini_gather_button)
	resource_row.visible = false
	objective_button = Button.new()
	objective_button.custom_minimum_size.y = 48
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.add_theme_font_override("font", UiTypography.body_font())
	objective_button.add_theme_font_size_override("font_size", 16)
	objective_button.pressed.connect(_toggle_guidance)
	header_box.add_child(objective_button)

	viewbar = HBoxContainer.new()
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

	island_mode_button = _button("空島", _close_building_catalog)
	toolbar.add_child(island_mode_button)
	building_catalog_button = _button("營造", _open_building_catalog)
	toolbar.add_child(building_catalog_button)

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

	reincarnation_button = _button("輪迴天道", _toggle_reincarnation_panel)
	toolbar.add_child(reincarnation_button)

	help_button = _button("操作說明", _show_help)
	toolbar.add_child(help_button)

	_configure_more_menu()

	hint_panel = PanelContainer.new()
	var hint_style := _style(Color(0.008, 0.035, 0.05, 0.93))
	hint_style.content_margin_left = 18
	hint_style.content_margin_right = 18
	hint_style.content_margin_top = 12
	hint_style.content_margin_bottom = 12
	hint_panel.add_theme_stylebox_override("panel", hint_style)
	hud.add_child(hint_panel)
	var hint_box := VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 5)
	hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint_panel.add_child(hint_box)
	var hint_title_row := HBoxContainer.new()
	hint_box.add_child(hint_title_row)
	hint_heading = _label("系統訊息 · 新手引導", 16, Color("f1d58d"), 1)
	hint_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_title_row.add_child(hint_heading)
	var hint_close := Button.new()
	hint_close.text = "收起"
	hint_close.custom_minimum_size = Vector2(64, 48)
	hint_close.pressed.connect(_toggle_guidance)
	hint_title_row.add_child(hint_close)
	hint = _label("", 17, Color("f2e8c7"), 1)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hint_scroll := ScrollContainer.new()
	hint_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hint_box.add_child(hint_scroll)
	hint_scroll.add_child(hint)
	hint_panel.visible = false

	footer = _label("自動存檔運轉中", 18, Color("ffffff"), 0)
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color(0.008, 0.035, 0.05, 0.96)
	footer_style.set_corner_radius_all(6)
	footer_style.content_margin_left = 8
	footer_style.content_margin_right = 8
	footer.add_theme_stylebox_override("normal", footer_style)
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
	detail_title.add_theme_font_override("font", UiTypography.emphasis_font())
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(detail_title)
	title_row.add_child(_button("收起", _close_detail))

	detail_body = _label("", 21, Color("eaf2ea"), 1)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_scroll = ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2.ZERO
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(detail_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail_content)
	detail_content.add_child(detail_body)

	detail_actions = HFlowContainer.new()
	detail_actions.add_theme_constant_override("h_separation", 10)
	detail_actions.add_theme_constant_override("v_separation", 10)
	detail_content.add_child(detail_actions)

	gather_button = _button("聚氣引靈", _gather_lingli)
	detail_actions.add_child(gather_button)

	upgrade_button = _button("", _upgrade_selected)
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_actions.add_child(upgrade_button)

	pause_button = _button("暫停藥圃", _toggle_garden)
	detail_actions.add_child(pause_button)

	building_catalog = BuildingCatalogScript.new()
	building_catalog.visible = false
	hud.add_child(building_catalog)
	building_catalog.call("configure_resources", RESOURCE_NAMES, RESOURCE_NAMES.keys())
	building_catalog.call("configure", _catalog_groups())
	resource_ribbon = PanelContainer.new()
	var ribbon_style := _style(Color(0.018, 0.065, 0.075, 0.97))
	ribbon_style.content_margin_left = 8
	ribbon_style.content_margin_right = 8
	ribbon_style.content_margin_top = 6
	ribbon_style.content_margin_bottom = 6
	resource_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	hud.add_child(resource_ribbon)
	resource_ribbon_box = VBoxContainer.new()
	resource_ribbon_box.add_theme_constant_override("separation", 4)
	resource_ribbon.add_child(resource_ribbon_box)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 4)
	resource_ribbon_box.add_child(mode_row)
	for mode_name in ["關閉", "數量", "完整"]:
		var mode_button := Button.new()
		mode_button.text = mode_name
		mode_button.toggle_mode = true
		mode_button.custom_minimum_size.y = 44
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.add_theme_font_override("font", UiTypography.body_font())
		mode_button.add_theme_font_size_override("font_size", 15)
		mode_button.pressed.connect(_set_resource_display_mode.bind(resource_mode_buttons.size()))
		mode_row.add_child(mode_button)
		resource_mode_buttons.append(mode_button)
	resource_scroll = ScrollContainer.new()
	resource_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resource_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	resource_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	resource_ribbon_box.add_child(resource_scroll)
	building_catalog.resource_grid.reparent(resource_scroll)
	building_catalog.resource_grid.columns = 1
	building_catalog.resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_resource_display_mode(1)
	action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 6)
	hud.add_child(action_bar)
	mini_gather_button.reparent(action_bar)
	mini_gather_button.custom_minimum_size = Vector2(112, 48)
	gather_menu = MenuButton.new()
	gather_menu.text = "選擇採集"
	gather_menu.custom_minimum_size = Vector2(104, 48)
	gather_menu.add_theme_font_override("font", UiTypography.emphasis_font())
	gather_menu.add_theme_font_size_override("font_size", 16)
	gather_menu.get_popup().id_pressed.connect(_on_gather_resource_selected)
	action_bar.add_child(gather_menu)
	info_panel.reparent(building_catalog.detail_slot)
	info_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	info_panel.custom_minimum_size = Vector2.ZERO
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	building_catalog.building_selected.connect(_select_building_from_catalog)
	building_catalog.building_upgrade_requested.connect(_upgrade_building_from_catalog)
	if building_catalog.has_signal("close_requested"):
		building_catalog.connect("close_requested", Callable(self, "_close_building_catalog"))
	if building_catalog.has_signal("gather_resource_requested"):
		building_catalog.connect("gather_resource_requested", Callable(self, "_gather_resource"))
	building_catalog.guidance_requested.connect(_toggle_guidance)

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

	var rc_script = preload("res://src/presentation/reincarnation_panel.gd")
	reincarnation_panel = rc_script.new()
	reincarnation_panel.visible = false
	reincarnation_panel.reincarnate_requested.connect(_on_reincarnate_requested)
	reincarnation_panel.learn_talent_requested.connect(_on_learn_talent_requested)
	reincarnation_panel.close_requested.connect(_on_reincarnation_closed)
	hud.add_child(reincarnation_panel)

	header.resized.connect(_reflow_header)


func _layout() -> void:
	_layout_for_size(get_viewport_rect().size)

func _layout_for_size(vp: Vector2) -> void:
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	hud.position = Vector2.ZERO
	hud.size = vp
	sky.position = Vector2(-75, -75)
	sky.size = vp + Vector2(150, 150)
	shade.size = vp

	var ratio: float = vp.x / vp.y
	if vp.x >= 960.0 and ratio >= 1.45:
		layout_mode = HudLayout.WIDE
	elif vp.x < 640.0 or ratio < 1.25:
		layout_mode = HudLayout.PORTRAIT
	else:
		layout_mode = HudLayout.COMPACT

	var margin: float = 28.0 if layout_mode == HudLayout.WIDE else 16.0
	var portrait: bool = layout_mode == HudLayout.PORTRAIT
	var compact: bool = layout_mode != HudLayout.WIDE
	toolbar.visible = true
	_apply_hud_density(compact, portrait)
	header.position = Vector2(margin, margin)
	header.size.x = vp.x - margin * 2.0 if portrait else minf(320.0, vp.x * 0.38)
	toolbar.position = Vector2(margin, vp.y - margin - 56.0)
	toolbar.size = Vector2(vp.x - margin * 2.0 if portrait else minf(480.0, vp.x - margin * 2.0), 56)
	if building_catalog.visible and not portrait:
		toolbar.position.x = vp.x - margin - toolbar.size.x
	viewbar.size = Vector2(220, 48)
	footer.visible = false
	action_bar.visible = false
	action_bar.position = Vector2(margin, toolbar.position.y - 56.0)
	action_bar.size = Vector2(vp.x - margin * 2.0 if portrait else 232.0, 48.0)

	_reflow_header()
	_layout_overlay_panels(vp, margin, portrait)
	print("ABODE_LAYOUT mode=", _layout_mode_name(), " size=", vp.round())

func _apply_hud_density(compact: bool, portrait: bool) -> void:
	var short_compact: bool = layout_mode == HudLayout.COMPACT and hud.size.y < 500.0
	crumb.visible = false
	title_label.visible = false
	objective_button.visible = not (building_catalog.visible or short_compact)
	resource_label.visible = false
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_label.custom_minimum_size = Vector2.ZERO
	realm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_label.custom_minimum_size = Vector2.ZERO
	realm_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	realm_progress_label.custom_minimum_size = Vector2.ZERO
	header_box.custom_minimum_size = Vector2.ZERO
	resource_label.add_theme_font_size_override("font_size", 16)
	toolbar.add_theme_constant_override("separation", 4 if portrait else 8)
	island_mode_button.custom_minimum_size = Vector2(72 if portrait else 96, 56)
	building_catalog_button.custom_minimum_size = Vector2(72 if portrait else 96, 56)
	overview_button.custom_minimum_size = Vector2(80 if portrait else 116, 56)
	more_menu.custom_minimum_size = Vector2(80 if portrait else 116, 56)
	building_catalog_button.text = "營造"
	island_mode_button.text = "空島"
	island_mode_button.disabled = not building_catalog.visible
	building_catalog_button.disabled = building_catalog.visible
	more_menu.text = ("★ 更多" if portrait else "★ 更多功能") if more_menu.text.begins_with("★") else ("更多" if portrait else "更多功能")
	building_catalog_button.add_theme_font_size_override("font_size", 18)
	island_mode_button.add_theme_font_size_override("font_size", 18)
	overview_button.add_theme_font_size_override("font_size", 18)
	more_menu.add_theme_font_size_override("font_size", 18)
	reincarnation_button.custom_minimum_size.x = 104 if portrait else 132
	reincarnation_button.add_theme_font_size_override("font_size", 18 if portrait else 22)
	realm_label.add_theme_font_size_override("font_size", 22 if not compact else 18)
	realm_progress_label.add_theme_font_size_override("font_size", 16)
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_body.add_theme_font_size_override("font_size", 16)
	more_menu.visible = true
	motion_button.visible = false
	save_button.visible = false
	nine_realms_button.visible = false
	reincarnation_button.visible = false
	help_button.visible = false
	replay_breakthrough_button.visible = false


func _reflow_header() -> void:
	var base_height: float = 88.0 if layout_mode == HudLayout.WIDE else 80.0
	var needed: float = maxf(header.get_combined_minimum_size().y, header_box.get_combined_minimum_size().y + 28.0)
	header.size.y = maxf(base_height, needed)
	viewbar.position = Vector2(header.position.x, header.position.y + header.size.y + 8.0)
	viewbar.visible = false
	_reflow_resource_ribbon()
	if building_catalog != null and building_catalog.visible and layout_mode == HudLayout.PORTRAIT and hud != null:
		_layout_overlay_panels(hud.size, (28.0 if layout_mode == HudLayout.WIDE else 16.0), true)

func _reflow_resource_ribbon() -> void:
	if resource_ribbon == null or building_catalog == null or hud == null:
		return
	var vp := hud.size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var portrait: bool = layout_mode == HudLayout.PORTRAIT
	var margin: float = 28.0 if layout_mode == HudLayout.WIDE else 16.0
	building_catalog.resource_grid.columns = 1
	building_catalog.resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_ribbon.position = Vector2(margin, header.position.y + header.size.y + 8.0)
	var resource_width: float = vp.x - margin * 2.0 if portrait else header.size.x
	var resource_bottom: float = toolbar.position.y - 8.0
	var resource_available: float = maxf(44.0, resource_bottom - resource_ribbon.position.y)
	var visible_count: int = 0
	for resource_id in building_catalog.resource_order:
		if bool(building_catalog._last_resources.get(resource_id, {}).get("visible", false)):
			visible_count += 1
	var wanted_height: float = 56.0
	if resource_display_mode != 0 and visible_count > 0:
		var card_h: float = 38.0 if resource_display_mode == 1 else 56.0
		var v_sep: float = 6.0
		var grid_content_height: float = float(visible_count) * card_h + float(maxi(0, visible_count - 1)) * v_sep
		# 6 (top margin) + 44 (mode_row) + 4 (separation) + grid_content_height + 6 (bottom margin) + 2 (subpixel buffer)
		wanted_height = 62.0 + grid_content_height
	var portrait_max: float = 132.0 if building_catalog.visible else minf(resource_available, 280.0)
	var max_resource_height: float = minf(resource_available, portrait_max if portrait else resource_available)
	resource_ribbon.size = Vector2(resource_width, minf(wanted_height, max_resource_height))
	resource_scroll.visible = resource_display_mode != 0

func _toggle_building_catalog() -> void:
	if building_catalog.visible:
		_close_building_catalog()
	else:
		_open_building_catalog()

func _open_building_catalog() -> void:
	building_catalog.visible = true
	var view: Dictionary = session.get_view()
	building_catalog.call("refresh", view.buildings, view.resources, int(view.era_id))
	_layout_for_size(hud.size)

func _close_building_catalog() -> void:
	_close_detail()
	building_catalog.visible = false
	_layout_for_size(hud.size)

func _set_resource_display_mode(mode: int) -> void:
	resource_display_mode = clampi(mode, 0, 2)
	for index in resource_mode_buttons.size():
		resource_mode_buttons[index].button_pressed = index == resource_display_mode
	if building_catalog != null:
		building_catalog.set_resource_display_mode(resource_display_mode)
	if resource_scroll != null:
		resource_scroll.visible = resource_display_mode != 0
	if hud != null and hud.size.x > 0.0:
		_layout_for_size(hud.size)

func _select_building_from_catalog(id: String) -> void:
	var view: Dictionary = session.get_view()
	if not view.buildings.has(id) or not bool(view.buildings[id].visible):
		return
	selected_id = id
	building_catalog.visible = true
	info_panel.visible = true
	building_catalog.call("show_detail", true)
	_refresh_detail()
	_layout_for_size(hud.size)

func _catalog_groups() -> Array:
	var groups := [
		{"id": "core", "title": "洞府核心", "entries": []},
		{"id": "production", "title": "生產設施", "entries": []},
		{"id": "storage", "title": "倉儲設施", "entries": []},
		{"id": "other", "title": "其他設施", "entries": []},
	]
	var roles := {
		"hut": "靈氣與居所", "wooden_house": "金錢產出",
		"forest_farm": "靈木產出", "stone_mine": "下品靈石與玄銅",
		"herb_farm": "靈草產出", "storage_lingli": "靈氣容量",
		"storage_money": "金錢容量", "storage_wood": "靈木容量",
		"storage_stone": "下品靈石容量", "storage_herb": "靈草容量",
	}
	for id in content.building_ids:
		var group_index := 3
		if id == "hut" or id == "storage_lingli":
			group_index = 0
		elif id.begins_with("storage_"):
			group_index = 2
		elif roles.has(id):
			group_index = 1
		groups[group_index].entries.append({
			"id": id,
			"title": BUILDING_NAMES.get(id, id),
			"role": roles.get(id, "設施"),
		})
	return groups

func _layout_overlay_panels(vp: Vector2, margin: float, portrait: bool) -> void:
	var management: bool = building_catalog != null and building_catalog.visible
	var detail_focus: bool = management and portrait and vp.y < 560.0 and info_panel.visible
	header.visible = not detail_focus
	resource_ribbon.visible = not detail_focus
	viewbar.visible = viewbar.visible and not management
	footer.visible = false
	if management:
		var rail_width: float = vp.x - margin * 2.0 if portrait else minf(400.0, vp.x * 0.44)
		var rail_top: float = margin if detail_focus else (resource_ribbon.position.y + resource_ribbon.size.y + 8.0 if portrait else margin)
		var rail_bottom: float = action_bar.position.y - 8.0 if portrait and action_bar.visible else toolbar.position.y - 8.0
		if portrait and rail_bottom - rail_top < 104.0:
			resource_ribbon.size.y = 56.0
			resource_scroll.visible = false
			rail_top = resource_ribbon.position.y + resource_ribbon.size.y + 8.0
		building_catalog.call("set_short_mode", vp.y < 560.0)
		building_catalog.call("set_layout_bounds", Rect2(margin if portrait else vp.x - margin - rail_width, rail_top, rail_width, maxf(72.0, rail_bottom - rail_top)))
	if hint_panel.visible:
		var hint_width: float = minf(420.0, vp.x - margin * 2.0)
		hint_panel.size = Vector2(hint_width, minf(132.0, vp.y * 0.28))
		hint_panel.position = Vector2(vp.x - margin - hint_width, margin)

	if save_controls != null:
		var save_rect := Rect2(margin, margin, minf(480.0, vp.x - margin * 2.0), minf(460.0, vp.y - margin * 2.0))
		if portrait:
			save_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		save_controls.call("set_layout_bounds", save_rect)
	if offline_summary != null:
		var offline_rect := Rect2(margin, margin, minf(480.0, vp.x - margin * 2.0), minf(300.0, vp.y - margin * 2.0))
		if portrait:
			offline_rect = Rect2(12, vp.y * 0.32, vp.x - 24, vp.y * 0.60)
		offline_summary.call("set_layout_bounds", offline_rect)
	if nine_realms_preview != null:
		nine_realms_preview.position = Vector2.ZERO
		nine_realms_preview.size = vp
	if breakthrough_seq != null:
		breakthrough_seq.position = Vector2.ZERO
		breakthrough_seq.size = vp
	if reincarnation_panel != null:
		var rc_rect := Rect2(margin, margin, minf(540.0, vp.x - margin * 2.0), minf(560.0, vp.y - margin * 2.0))
		if portrait:
			rc_rect = Rect2(12, 12, vp.x - 24, vp.y - 24)
		reincarnation_panel.call("set_layout_bounds", rc_rect)


func _layout_mode_name() -> String:
	match layout_mode:
		HudLayout.WIDE:
			return "wide"
		HudLayout.COMPACT:
			return "compact"
		_:
			return "portrait"
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

func _update_buildings_visual(view: Dictionary) -> void:
	for id in buildings:
		var target_id: String = "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
		var b_view: Dictionary = view.buildings.get(target_id, {})
		var b_node = buildings[id]
		var is_vis: bool = bool(b_view.get("visible", false))

		# The island shows built landmarks or unbuilt ghost blueprints when affordable.
		b_node.level = int(b_view.get("level", 0))
		var affordable: bool = bool(b_view.get("affordable", false))
		b_node.visible = is_vis and target_id == "hut" and (b_node.level > 0 or affordable)
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

	realm_label.text = "境界：%s · %d/%d 層" % [era_name, cur_level, int(era_info.get("max_level", 10))]
	if cur_level >= int(era_info.get("max_level", 10)):
		realm_progress_label.text = "修煉圓滿 · 壽元 %.0f/%.0f 祀" % [remain_life / 60.0, max_life / 60.0]
	else:
		realm_progress_label.text = "修煉 %.0f/%.0f 秒 · 壽元 %.0f/%.0f 祀" % [
			train_sec, req_sec, remain_life / 60.0, max_life / 60.0
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

	replay_breakthrough_button.visible = false
	more_menu.get_popup().set_item_disabled(more_menu.get_popup().get_item_index(5), cur_era < 2)

	var rc_eligible: bool = false
	if view.has("reincarnation_preview"):
		rc_eligible = bool(view.reincarnation_preview.get("eligible", false))
	if rc_eligible:
		reincarnation_button.text = "★ 輪迴天道 ★" if layout_mode != HudLayout.PORTRAIT else "★ 輪迴"
		reincarnation_button.add_theme_color_override("font_color", Color("7de0a8"))
		more_menu.text = "★ 更多" if layout_mode == HudLayout.PORTRAIT else "★ 更多功能"
		more_menu.get_popup().set_item_text(more_menu.get_popup().get_item_index(6), "★ 輪迴天道")
	else:
		reincarnation_button.text = "輪迴天道" if layout_mode != HudLayout.PORTRAIT else "輪迴"
		reincarnation_button.add_theme_color_override("font_color", Color("f4e7be"))
		more_menu.text = "更多" if layout_mode == HudLayout.PORTRAIT else "更多功能"
		more_menu.get_popup().set_item_text(more_menu.get_popup().get_item_index(6), "輪迴天道")

	if reincarnation_panel != null and reincarnation_panel.visible:
		reincarnation_panel.call("refresh", view)

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
			var rate_str := (" · +%.2f/s" % rate) if rate > 0.0 else ""
			res_lines.append("%s %.2f/%d%s" % [r_name, val, int(cap), rate_str])

	mini_resource_id = "lingli"
	var objective_value: Variant = view.get("next_objective", null)
	if objective_value is Dictionary:
		var next_building: Dictionary = view.get("buildings", {}).get(String(objective_value.get("id", "")), {})
		for cost_id in next_building.get("costs", {}):
			var candidate: Dictionary = view.resources.get(cost_id, {})
			if int(view.era_id) == 1 and bool(candidate.get("unlocked", false)) and String(candidate.get("type", "")) == "basic" and _parse_amount(candidate.get("value", "0")).compare_to(_parse_amount(next_building.costs[cost_id])) < 0:
				mini_resource_id = String(cost_id)
				break
	var mini_entry: Dictionary = view.resources.get(mini_resource_id, {})
	var mini_current: float = _parse_amount(mini_entry.get("value", "0")).to_float()
	var mini_cap: float = _parse_amount(mini_entry.get("cap", "0")).to_float()
	var mini_rate: float = _parse_amount(mini_entry.get("rate", "0")).to_float()
	resource_label.text = "%s %.2f/%.0f" % [RESOURCE_NAMES.get(mini_resource_id, mini_resource_id), mini_current, mini_cap]
	if mini_rate > 0.0:
		resource_label.text += " · +%.2f/s" % mini_rate
	mini_gather_button.visible = int(view.era_id) == 1 and bool(mini_entry.get("unlocked", false)) and String(mini_entry.get("type", "")) == "basic"
	mini_gather_button.disabled = mini_current >= mini_cap
	gather_resource_ids.clear()
	var gather_popup: PopupMenu = gather_menu.get_popup()
	gather_popup.clear()
	for r_id in res_order:
		var entry: Dictionary = view.resources.get(r_id, {})
		if int(view.era_id) == 1 and bool(entry.get("unlocked", false)) and String(entry.get("type", "")) == "basic":
			gather_resource_ids.append(r_id)
			gather_popup.add_item(String(RESOURCE_NAMES.get(r_id, r_id)), gather_resource_ids.size() - 1)
	if not gather_resource_ids.has(selected_gather_id):
		selected_gather_id = mini_resource_id
	mini_resource_id = selected_gather_id
	mini_entry = view.resources.get(mini_resource_id, {})
	mini_current = _parse_amount(mini_entry.get("value", "0")).to_float()
	mini_cap = _parse_amount(mini_entry.get("cap", "0")).to_float()
	mini_gather_button.visible = false
	mini_gather_button.disabled = mini_current >= mini_cap
	mini_gather_button.text = "採集%s +1" % RESOURCE_NAMES.get(mini_resource_id, mini_resource_id)
	gather_menu.visible = false
	action_bar.visible = false
	building_catalog.call("refresh", view.buildings, view.resources, int(view.era_id))
	var visible_resource_count: int = 0
	for entry in view.resources.values():
		if bool(entry.get("visible", false)):
			visible_resource_count += 1
	if visible_resource_count != last_visible_resource_count:
		last_visible_resource_count = visible_resource_count
		call_deferred("_layout")
	_update_onboarding_guidance(view)
	var objective_text := "營造引導已完成"
	if objective_value is Dictionary:
		var objective_id: String = String(objective_value.get("id", ""))
		var target_level: int = 1
		for milestone in Onboarding.MILESTONES:
			if String(milestone.building) == objective_id:
				target_level = int(milestone.level)
				break
		objective_text = "下一步：將%s升至 %d 階" % [BUILDING_NAMES.get(objective_id, "營造設施"), target_level]
	objective_button.text = objective_text
	objective_button.tooltip_text = hint.text
	building_catalog.call("set_context", realm_label.text, objective_text)
	_reflow_header()

	zoom_label.text = "%d%%" % int(camera.zoom.x * 100)
	region_visible = camera.target_zoom < 0.34
	overview_button.text = ("歸家" if region_visible else "神識") if layout_mode == HudLayout.PORTRAIT else ("回到洞府" if region_visible else "神識展開")
	crumb.text = "人界 / 山域總覽 · 遠景尚未開放" if region_visible else "人界 / 無名山域 / 你的洞府"
	title_label.text = "群山之間，認得自己的燈火" if region_visible else "一方洞府，自有生息"

	if selected_id != "" and info_panel.visible:
		_refresh_detail()

func _update_onboarding_guidance(view: Dictionary) -> void:
	var objective_value: Variant = view.get("next_objective", null)
	if objective_value == null:
		var done_key := "complete:%d" % int(view.get("era_id", 1))
		if done_key == last_guidance_key:
			return
		last_guidance_key = done_key
		hint_heading.text = "系統訊息 · 新手引導"
		hint.text = "入門建築引導已完成。可在「營造設施」查看資源庫存、每秒產率與後續設施需求。"
		return

	var objective: Dictionary = objective_value
	var building_id := String(objective.get("id", ""))
	var building: Dictionary = view.get("buildings", {}).get(building_id, {})
	var costs: Dictionary = building.get("costs", {})
	var resources: Dictionary = view.get("resources", {})
	var missing: Array[String] = []
	var gatherable_missing: Array[String] = []
	for resource_id in costs:
		var resource: Dictionary = resources.get(resource_id, {})
		var current: AmountCompat = _parse_amount(resource.get("value", "0"))
		var required: AmountCompat = _parse_amount(costs[resource_id])
		if current.compare_to(required) < 0:
			missing.append(String(resource_id))
			if int(view.get("era_id", 1)) == 1 and bool(resource.get("unlocked", false)) and String(resource.get("type", "")) == "basic":
				gatherable_missing.append(String(resource_id))

	missing.sort()
	var state_key := "ready" if missing.is_empty() else "need:" + ",".join(missing)
	var guidance_key := "%s:%s" % [building_id, state_key]
	if guidance_key == last_guidance_key:
		return
	last_guidance_key = guidance_key
	hint_heading.text = "系統訊息 · 新手引導"
	var building_name: String = BUILDING_NAMES.get(building_id, building_id)
	var level: int = int(building.get("level", 0))
	var action: String = "建造" if level == 0 else "升級"
	if building_id == "hut" and "lingli" in missing and "lingli" in gatherable_missing:
		hint.text = "初入道途，先使用空島下方的「採集靈氣」動作；累積足夠後在營造簿建造茅屋。茅屋啟動後會逐秒產生靈氣。"
	elif building_id == "wooden_house" and "money" in missing and "money" in gatherable_missing:
		hint.text = "茅屋已立，接下來需要第一筆金錢。請在空島下方選擇採集金錢，足額後於營造簿建造木屋以啟動金錢產線。"
	elif missing.is_empty():
		hint.text = "下一步：資源已足，前往「營造設施」選擇【%s】並%s。完成後再依清單提示推進下一段建築流程。" % [building_name, action]
	else:
		var missing_names: Array[String] = []
		for resource_id in missing:
			missing_names.append(String(RESOURCE_NAMES.get(resource_id, resource_id)))
		var gather_text := "可手動採集已解鎖項目；其他需求等待現有產線入庫。" if not gatherable_missing.is_empty() else "請等待已建產線入庫。"
		hint.text = "下一步：前往「營造設施」%s【%s】。尚缺：%s。%s" % [action, building_name, "、".join(missing_names), gather_text]

func _pick_world(point: Vector2) -> void:
	if camera.zoom.x < 0.34:
		if point.distance_to(Vector2.ZERO) < 800:
			_return_home()
		else:
			hint.text = "遠處是未開放的山域。點自己的洞府，可回到近景。"
		return

	if spirit_tree != null and spirit_tree.visible and spirit_tree.call("contains_point", point):
		_chop_spirit_tree()
		print("ABODE_CHOP_TREE")
		return

	var ids: Array = buildings.keys()
	ids.reverse()
	for id in ids:
		if buildings[id].visible and buildings[id].contains_point(point):
			var target_id: String = "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
			var b_node = buildings[id]
			if b_node.level == 0:
				var b_view: Dictionary = session.get_view().buildings.get(target_id, {})
				if bool(b_view.get("affordable", false)):
					_upgrade_building_from_catalog(target_id)
					b_node.pulse_upgrade()
					print("ABODE_DIRECT_BUILD: ", target_id)
			_select_building_from_catalog(target_id)
			print("ABODE_SELECT: ", id)
			return

	_close_detail()

func _chop_spirit_tree() -> void:
	if session == null or session.state == null:
		return
	var wood_entry: Dictionary = session.state.resources.get("wood", {})
	var wood_unlocked: bool = bool(wood_entry.get("unlocked", false))
	if not wood_unlocked:
		if spirit_tree != null and spirit_tree.has_method("deny_feedback"):
			spirit_tree.call("deny_feedback")
		hint.text = "茅屋立足後，方得洞府靈氣滋養靈木，始可採伐。"
		return

	var caps: Dictionary = Production.compute_caps(content, session.state.buildings, session.state.era_id, session.state.onboarding_version)
	var wood_val: AmountCompat = wood_entry.get("value", AmountCompat.zero())
	var wood_cap: AmountCompat = caps.get("wood", AmountCompat.zero())
	if wood_cap.compare_to(AmountCompat.zero()) > 0 and wood_val.compare_to(wood_cap) >= 0:
		if spirit_tree != null and spirit_tree.has_method("deny_feedback"):
			spirit_tree.call("deny_feedback")
		hint.text = "木材儲存已達上限，請先擴建或消耗木材。"
		return

	var cmd := {
		"command_id": "gather_wood_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "gather",
		"expected_revision": session.state.revision,
		"payload": {"resource_id": "wood"}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		if spirit_tree != null and spirit_tree.has_method("chop_feedback"):
			spirit_tree.call("chop_feedback", 1)
		hint.text = "採伐靈木，獲得木材 +1"
		_refresh_hud()
	else:
		hint.text = "靈木採伐受阻：%s" % str(res.get("error", "FAIL"))

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

	gather_button.visible = (b_id == "hut" and int(view.era_id) == 1)

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
		if cur_lvl == 0 and b_data.prereq != null:
			var prereq_id := String(b_data.prereq.building)
			var prereq_level := int(b_data.prereq.level)
			if int(view.buildings.get(prereq_id, {}).get("level", 0)) < prereq_level:
				upgrade_button.text = "需先將%s升至 %d 階" % [BUILDING_NAMES.get(prereq_id, prereq_id), prereq_level]

	pause_button.visible = (b_id == "herb_farm")
	pause_button.text = "恢復藥圃" if not state.garden_running else "暫停藥圃"

func _gather_lingli() -> void:
	_gather_resource("lingli")

func _on_gather_resource_selected(index: int) -> void:
	if index < 0 or index >= gather_resource_ids.size():
		return
	selected_gather_id = gather_resource_ids[index]
	mini_resource_id = selected_gather_id
	mini_gather_button.text = "採集%s +1" % RESOURCE_NAMES.get(mini_resource_id, mini_resource_id)
	var view: Dictionary = session.get_view()
	var entry: Dictionary = view.resources.get(mini_resource_id, {})
	mini_gather_button.disabled = _parse_amount(entry.get("value", "0")).compare_to(_parse_amount(entry.get("cap", "0"))) >= 0

func _gather_resource(resource_id: String) -> void:
	var cmd := {
		"command_id": "gather_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "gather",
		"expected_revision": session.state.revision,
		"payload": {"resource_id": resource_id}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		hint.text = "採集%s＋1。" % RESOURCE_NAMES.get(resource_id, resource_id)
		_refresh_hud()
	else:
		hint.text = "採集受阻：%s" % str(res.get("error", "FAIL"))

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
	_upgrade_building_from_catalog(selected_id)

func _upgrade_building_from_catalog(building_id: String) -> void:
	var cmd := {
		"command_id": "upg_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "upgrade_building",
		"expected_revision": session.state.revision,
		"payload": {"building_id": building_id}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		if buildings.has(building_id):
			buildings[building_id].pulse_upgrade()
		hint.text = "建造／升級完成！產出與洞府生息已擴展。"
		_save_game()
		_refresh_hud()
		print("ABODE_UPGRADE: ", building_id, " level=", session.state.buildings.get(building_id, 0))
	else:
		hint.text = "建造受阻：%s" % str(res.get("error", "FAIL"))

func _toggle_garden() -> void:
	state.garden_running = not state.garden_running
	_refresh_hud()
	print("ABODE_GARDEN_RUNNING: ", state.garden_running)

func _close_detail() -> void:
	selected_id = ""
	if info_panel:
		info_panel.visible = false
		if building_catalog != null:
			building_catalog.call("show_detail", false)
		_layout_for_size(hud.size)

func _toggle_overview() -> void:
	_close_detail()
	building_catalog.visible = false
	_layout_for_size(hud.size)
	if camera.target_zoom < 0.34:
		_return_home()
	else:
		camera.focus_region()
		hint.text = "那一點仍在發光的地方，就是你的洞府。點它即可返回。"
		print("ABODE_REGION: same world and simulation retained")

func _return_home() -> void:
	_close_detail()
	building_catalog.visible = false
	_layout_for_size(hud.size)
	camera.focus_home()
	hint.text = "回到洞府。點茅屋引氣；其他建築請開啟營造設施。"
	print("ABODE_HOME")

func _toggle_motion() -> void:
	reduced = not reduced
	camera.reduced_motion = reduced
	motion_button.text = "標準特效" if reduced else "低特效"
	print("ABODE_MOTION reduced=", reduced)

func _toggle_save_controls() -> void:
	if save_controls:
		save_controls.visible = not save_controls.visible
		_layout()

func _display_offline_summary(report: Dictionary) -> void:
	if offline_summary and not report.is_empty():
		offline_summary.show_report(report)
		_layout()

func _on_more_menu_pressed(id: int) -> void:
	match id:
		1:
			_toggle_motion()
		2:
			_toggle_save_controls()
		3:
			_open_nine_realms_overview()
		4:
			_show_help()
		5:
			if session != null and session.state != null and session.state.era_id >= 2:
				_replay_breakthrough()
		6:
			_toggle_reincarnation_panel()

func _toggle_reincarnation_panel() -> void:
	if reincarnation_panel == null:
		return
	reincarnation_panel.visible = not reincarnation_panel.visible
	if reincarnation_panel.visible:
		if session != null:
			reincarnation_panel.call("refresh", session.get_view())
		_layout()

func _on_reincarnate_requested(mode: String) -> void:
	if session == null:
		return
	var res: Dictionary = session.reincarnate(mode)
	if bool(res.get("ok", false)):
		hint.text = "天地玄黃，轉世功成！重塑肉身，再續大道仙途。"
		_save_game()
		if reincarnation_panel != null:
			reincarnation_panel.visible = false
		_return_home()
		_refresh_hud()
		print("ABODE_REINCARNATION: cycle=", session.state.reincarnation_count)
		if not session.state.tutorial_flags.get("seen_nine_realms_hook", false):
			session.state.tutorial_flags["seen_nine_realms_hook"] = true
			_save_game()
			trigger_nine_realms_hook(false)
	else:
		hint.text = "轉世受阻：%s" % str(res.get("error", "FAIL"))

func _on_learn_talent_requested(talent_id: String) -> void:
	if session == null:
		return
	var res: Dictionary = session.learn_talent(talent_id)
	if bool(res.get("ok", false)):
		hint.text = "參悟成功！道心感應，玄妙自生。"
		_save_game()
		_refresh_hud()
		if reincarnation_panel != null and reincarnation_panel.visible:
			reincarnation_panel.call("refresh", session.get_view())
		print("ABODE_TALENT_LEARNED: ", talent_id, " level=", session.state.talents.get(talent_id, 0))
	else:
		hint.text = "參悟受阻：%s" % str(res.get("error", "FAIL"))

func _on_reincarnation_closed() -> void:
	_refresh_hud()

func _save_game() -> void:
	if session == null or session.state == null:
		return
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var sim_tick: int = int(floor(session.state.total_elapsed_seconds / float(TimeAdvancer.SECONDS_PER_TICK)))
	var meta: Dictionary = {
		"save_id": "local",
		"saved_at_utc_ms": str(now_ms),
		"settled_until_utc_ms": str(now_ms),
		"sim_tick": str(sim_tick),
	}
	SaveManager.save(session.state, meta)

func _show_help() -> void:
	hint_heading.text = "操作說明"
	hint.text = "滑鼠拖曳／單指平移；滾輪／雙指縮放。\n營造設施可建造與升級；M 展開山域，Home 歸家。"
	hint_panel.visible = true
	_layout_for_size(hud.size)

func _toggle_guidance() -> void:
	hint_panel.visible = not hint_panel.visible
	_layout_for_size(hud.size)
