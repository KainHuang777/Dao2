extends Node2D
## Living Abode Controller: bridges Godot scene with GameSession, CommandProcessor, TimeAdvancer, and SaveManager.

const TERRAIN: Texture2D = preload("res://assets/abode/fx3art1/terrain.png")
const SKY: Texture2D = preload("res://assets/abode/fx3art1/sky.png")
const SKY_SHADER: Shader = preload("res://assets/abode/fx3art1/concept_sky.gdshader")
const CultivatorScript = preload("res://src/presentation/cloaked_cultivator.gd")
const IslandFxScript = preload("res://src/presentation/island_breakthrough_fx.gd")
const HUT: Texture2D = preload("res://assets/abode/hut.png")
const COURTYARD: Texture2D = preload("res://assets/abode/island1/courtyard.png")
const SCENERY_ART := {
	"wood": preload("res://assets/abode/island1/wood.png"),
	"herb": preload("res://assets/abode/island1/herb.png"),
	"stone": preload("res://assets/abode/island1/stone.png"),
}
const SceneryPropScript = preload("res://src/abode/abode_scenery_prop.gd")
const SCENERY_SLOTS := [Vector2(40, -220), Vector2(110, -210), Vector2(130, 0), Vector2(-100, -90)]
const GARDEN: Texture2D = preload("res://assets/abode/garden.png")
const ALTAR: Texture2D = preload("res://assets/abode/altar.png")
const GROUNDED_ALTAR: Texture2D = preload("res://assets/abode/altar-grounded/altar-grounded-v2.png")

const CameraScript = preload("res://src/abode/abode_camera.gd")
const BuildingScript = preload("res://src/abode/abode_building.gd")
const BuildingCatalogScript = preload("res://src/presentation/building_catalog.gd")

const BUILDING_NAMES := {
	"library": "藏經閣", "scripture_hall": "經書殿",
	"foundation_reservoir": "築基靈池",
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
	"skill_point": "技能點",
	"lingli": "靈氣",
	"money": "金錢",
	"wood": "靈木",
	"stone_low": "下品靈石",
	"black_copper": "玄銅",
	"spirit_grass_low": "靈草",
	"foundation_pill": "築基丹",
}

const BUILDING_DESCRIPTIONS := {
	"foundation_reservoir": "築基後拓建靈池，每階增加1000靈氣容量，最高三階。金丹突破需容量2000；使用祖島木石與金錢建造。",
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
		if session != null and session.state != null:
			ChronoSystem.unlock_chrono(session.state)

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

# Controllers read/write the existing facade; public properties and callback identities remain stable.
var _hud_controller = preload("res://src/presentation/abode_hud_controller.gd").new(self)
var _modal_manager = preload("res://src/presentation/abode_modal_manager.gd").new(self)

var session: GameSession
var content: GameContent
var state: AbodeStateCompat
var camera: CameraScript = CameraScript.new()
var buildings: Dictionary = {}
var scenery_props: Dictionary = {}
var scenery_parent: Node2D
var _pending_scenery_save := false
var _home_frame_size := Vector2.ZERO
var spirit_tree: Node2D
var vfx_environment: WorldEnvironment
var selected_id: String = ""
var reduced: bool = false
var reduced_motion: bool:
	get:
		return reduced
	set(v):
		reduced = v
var region_visible: bool = false
var region_layer: Node2D
var home_marker: Label
var sky: TextureRect
var shade: ColorRect
var sky_material: ShaderMaterial
var island_fx: IslandBreakthroughFx
var cultivator: CloakedCultivator
var _sky_flow_time: float = 0.0
var _last_sky_energy: float = -1.0
var _last_sky_reduced: int = -1
var _last_shade_a: float = -1.0
var _breakthrough_camera_snapshot: Dictionary = {}
var _breakthrough_hud_snapshot: Dictionary = {}
var _pending_breakthrough_save: bool = false

var hud: Control
var header: PanelContainer
var info_panel: PanelContainer
var toolbar: HBoxContainer
var footer: Label
var hint: Label
var hint_heading: Label
var hint_panel: PanelContainer
var hint_expand_button: Button
var hint_log_label: RichTextLabel
var hint_scroll: ScrollContainer
var _hint_expanded: bool = false
var _last_hint_text: String = ""
var _message_history: Array[String] = []
var title_label: Label
var realm_label: Label
var realm_progress_label: Label
var chrono_label: Label
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
var alchemy_panel: Control = null
var alchemy_button: Button
var sect_panel: Control = null
var sect_button: Button = null
var buff_hud_bar: BuffHudBar = null
var realm_modal: Control = null
var fortune_modal: Control = null
var spirit_realm_region_label: Label = null
var lifespan_banner: PanelContainer = null
var lifespan_banner_label: Label = null
var lifespan_banner_button: Button = null
var reincarnation_seq: Control = null
var text_transition: Control = null
var orientation_prompt: Control = null
var _reincarnation_hud_snapshot: Dictionary = {}
var _is_reincarnating: bool = false

var update_elapsed: float = 0.0
var auto_save_elapsed: float = 0.0
var _background_retry_cursor: int = 0
var _storage_block_layer: CanvasLayer = null
enum HudLayout { WIDE, COMPACT, PORTRAIT }
var layout_mode: int = HudLayout.WIDE
var header_box: VBoxContainer
var viewbar: HBoxContainer
var detail_actions: HFlowContainer
var detail_scroll: ScrollContainer
var return_to_catalog_after_detail: bool = false
var help_button: Button
var island_world: Node2D
var feature_navigation: RefCounted
var more_menu: MenuButton
var settings_menu: MenuButton
var bgm_player: AudioStreamPlayer
var is_bgm_enabled: bool = true
var _bgm_tracks: Array[Dictionary] = []
var _current_bgm_index: int = -1
var _last_known_era_id: int = 1
var debug_panel: Control
var achievement_panel: Control
var debug_auto_build_active: bool = false
var debug_auto_build_timer: float = 30.0
var _last_process_ticks_msec: int = 0
var _process_ticks_initialized: bool = false
var _frame_view: Dictionary = {}
var _frame_view_state: GameState
var _frame_view_revision: int = -1

func _ready() -> void:
	RuntimeProfile.configure_web()
	if OS.has_feature("web") and save_dir_override.is_empty():
		var web_adapter := WebStorageAdapter.new("dao2_islands_preview" if OS.has_feature("island_progression_preview") else "dao2_saves")
		var status := web_adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = web_adapter.session_status()
		if status != "ready":
			_show_storage_block("另一個分頁正在遊玩，請先關閉它再重試。" if status == "writer_busy" else "瀏覽器無法取得存檔保護，請以支援的安全連線瀏覽器重試。")
			return
	await _init_core()
	if session == null:
		_show_storage_block("存檔讀取或離線保存失敗，原有進度已保留。請恢復儲存權限或空間後重試。")
		return
	_build_background()
	# Compatibility 4.7: LDR world bloom; HUD stays above Canvas Max Layer.
	vfx_environment = WorldEnvironment.new()
	vfx_environment.name = "世界柔光"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.background_canvas_max_layer = 0
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	environment.glow_bloom = 0.03
	environment.glow_hdr_threshold = 0.96
	vfx_environment.environment = environment
	add_child(vfx_environment)
	_build_region()

	var island_composition := Node2D.new()
	island_composition.name = "洞府浮島構圖"
	island_composition.position = Vector2(0, 18)
	island_composition.scale = Vector2.ONE * 0.92
	add_child(island_composition)

	var ground := Sprite2D.new()
	ground.name = "獨立地形"
	ground.texture = TERRAIN
	ground.scale = Vector2.ONE * 1200.0 / TERRAIN.get_width()
	island_composition.add_child(ground)

	island_fx = IslandFxScript.new()
	island_fx.name = "空島突破法陣"
	island_composition.add_child(island_fx)
	cultivator = CultivatorScript.new()
	island_composition.add_child(cultivator)
	island_fx.cultivator = cultivator

	var props := Node2D.new()
	props.name = "可互動建築"
	props.y_sort_enabled = true
	island_composition.add_child(props)

	_setup_buildings(props)


	home_marker = _label("你的洞府 · 靈氣生生不息", 65, Color("ffe5a3"))
	UiMaterial.apply_world_caption(home_marker, UiTypography.chapter_font(), 65)
	home_marker.position = Vector2(-420, 410)
	home_marker.size.x = 840
	home_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_marker.z_index = 5
	island_composition.add_child(home_marker)

	camera.name = "世界鏡頭"
	add_child(camera)
	camera.world_clicked.connect(_pick_world)

	_build_hud()
	if not content.processing_catalog.is_empty():
		island_world = preload("res://src/presentation/island_world.gd").new()
		add_child(island_world)
		island_world.build(self)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_hud()

	print("ABODE_READY: native Camera2D, home landmark and managed building catalogue, autonomous state and flying swords")
	_last_process_ticks_msec = Time.get_ticks_msec()
	_process_ticks_initialized = true

static var save_dir_override: String = ""
static var island_preview_override := false

func _init_core() -> void:
	var content_loaded: Dictionary = ContentLoader.load_directory("res://content")
	if bool(content_loaded.get("ok", false)):
		content = content_loaded["content"]
	else:
		content = GameContent.new()
	# RES1-C3: normal play exposes islands; activation still archives the original
	# save and requires the player's Era-2 management command. Preview builds only
	# change the storage namespace, never the rules or available art.
	var attached := IslandProgression.attach(content)
	if not attached.ok:
		push_error("Island progression content invalid: " + str(attached))
		return

	var adapter: StorageAdapter = null
	if save_dir_override != "":
		adapter = FileStorageAdapter.new(save_dir_override)
	elif OS.has_feature("web"):
		adapter = WebStorageAdapter.new("dao2_islands_preview" if OS.has_feature("island_progression_preview") else "dao2_saves")
	else:
		adapter = FileStorageAdapter.new(SaveManager.DEFAULT_SAVE_DIR)

	SaveManager.configure(content, adapter)

	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var offline_res: Dictionary
	if OS.has_feature("web"):
		_begin_settlement_progress()
		print("OFFLINE_SETTLEMENT_BEGIN")
		offline_res = await OfflineCoordinator.settle_async(now_ms, get_tree(), _settlement_progress)
		print("OFFLINE_SETTLEMENT_END: ok=", offline_res.get("ok", false))
		_end_settlement_progress()
	else:
		offline_res = OfflineCoordinator.settle(now_ms)

	var loaded_state: GameState = SaveManager.current_state()
	if loaded_state == null or not bool(offline_res.get("ok", false)):
		print("STORAGE_STARTUP_FAILED: ", offline_res.get("error", ""), " detail=", offline_res.get("detail", ""), " load=", SaveManager.load_error())
		return
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
	_init_bgm()

func _show_storage_block(message: String) -> void:
	if is_instance_valid(_storage_block_layer):
		return
	set_process(false)
	_adapt_viewport_scale()
	var adapt_callback := Callable(self, "_adapt_viewport_scale")
	if not get_viewport().size_changed.is_connected(adapt_callback):
		get_viewport().size_changed.connect(adapt_callback)
	var layer := CanvasLayer.new()
	_storage_block_layer = layer
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 120
	add_child(layer)
	var panel := PanelContainer.new()
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.theme = UiTypography.create_theme()
	var center := CenterContainer.new()
	panel.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	center.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 280
	label.add_theme_font_override("font", UiTypography.body_font())
	label.add_theme_font_size_override("font_size", 18)
	column.add_child(label)
	var retry := Button.new()
	retry.text = "重試保存" if _background_retry_cursor > 0 else "重新載入並重試"
	retry.custom_minimum_size.y = 44
	column.add_child(retry)
	retry.pressed.connect(func() -> void:
		if OS.has_feature("web") and SaveManager.adapter() is WebStorageAdapter and SaveManager.adapter().session_status() != "ready":
			Engine.get_singleton("JavaScriptBridge").eval("window.location.reload()")
			return
		if _background_retry_cursor > 0:
			if await _settle_web_background(_background_retry_cursor):
				_background_retry_cursor = 0
				layer.queue_free()
				_storage_block_layer = null
				get_tree().paused = false
				set_process(true)
				_last_process_ticks_msec = Time.get_ticks_msec()
				_layout()
			return
		if OS.has_feature("web"):
			Engine.get_singleton("JavaScriptBridge").eval("window.location.reload()")
	)

func _setup_buildings(props: Node2D) -> void:
	# Home landmarks: residence on the left, cultivator at centre, built altar on the right.
	scenery_parent = props
	_add_building(props, "hut", "茅屋", HUT, Vector2(-245, -210), 225)
	_add_building(props, "forest_farm", "林場", GARDEN, Vector2(0, -240), 145)
	_add_building(props, "stone_mine", "採石場", ALTAR, Vector2(245, -220), 145)
	_add_building(props, "wooden_house", "木屋", HUT, Vector2(-335, -85), 155)
	_add_building(props, "herb_farm", "靈植場", GARDEN, Vector2(-90, -85), 160)
	_add_building(props, "storage_lingli", "聚靈壇", GROUNDED_ALTAR, Vector2(290, -100), 250)
	_add_building(props, "storage_money", "錢莊", HUT, Vector2(-335, 35), 120)
	_add_building(props, "storage_wood", "木料庫", HUT, Vector2(-110, 35), 120)
	_add_building(props, "storage_stone", "靈石庫", ALTAR, Vector2(115, 35), 120)
	_add_building(props, "storage_herb", "靈草庫", GARDEN, Vector2(335, 35), 120)

	buildings["garden"] = buildings["herb_farm"]
	buildings["altar"] = buildings["storage_lingli"]


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
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky_material = ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	sky_material.set_shader_parameter("source_aspect", float(SKY.get_width()) / float(SKY.get_height()))
	sky.material = sky_material
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sky)

	shade = ColorRect.new()
	shade.color = Color(0.055, 0.045, 0.065, 0.10)
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
		UiMaterial.apply_world_caption(label, UiTypography.emphasis_font(), 65)
		label.position = locations[i] + Vector2(-400, 300)
		label.size.x = 800
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		region_layer.add_child(label)
		if i == 1:
			spirit_realm_region_label = label

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

func _style(_color: Color = Color(0.018, 0.07, 0.10, 0.96)) -> StyleBoxTexture:
	var style := UiMaterial.card()
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
	UiMaterial.apply_button(button)
	button.pressed.connect(action)
	return button

func _view_button(text: String, action: Callable, width: float) -> Button:
	var button := _button(text, action)
	button.custom_minimum_size = Vector2(width, 56)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _configure_more_menu() -> void:
	_hud_controller._configure_more_menu()

func _build_hud() -> void:
	_hud_controller._build_hud()

func _layout() -> void:
	_adapt_viewport_scale()
	_layout_for_size(get_viewport_rect().size)

func _adapt_viewport_scale() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := get_tree()
	if tree == null:
		return
	var root_win := tree.root
	if root_win == null:
		return
	var win_size := root_win.size
	if win_size.x <= 0 or win_size.y <= 0:
		return
	# When height is compact (e.g. mobile landscape 844x390, 800x360),
	# adapt content scale size to 640x360 to keep 1:1 crisp CSS pixel readability and 44px+ touch targets.
	if win_size.x > win_size.y and win_size.y <= 500:
		if root_win.content_scale_size != Vector2i(640, 360):
			root_win.content_scale_size = Vector2i(640, 360)
	elif win_size.x >= win_size.y:
		if root_win.content_scale_size != Vector2i(1280, 720):
			root_win.content_scale_size = Vector2i(1280, 720)

func _layout_for_size(vp: Vector2) -> void:
	_hud_controller._layout_for_size(vp)
	if camera == null or vp == _home_frame_size or vp.x <= vp.y:
		return
	var was_home: bool = camera.target_position.distance_to(camera.home_position) < 1.0 and absf(camera.target_zoom - camera.home_zoom) < 0.01
	_home_frame_size = vp
	camera.home_position = Vector2(0, -40)
	camera.home_zoom = 0.70
	if vp.y < 540.0:
		# Fit the residence, central actor, right altar and finds beside the actual left HUD.
		var left: float = maxf(header.get_global_rect().end.x, resource_ribbon.get_global_rect().end.x) + 12.0
		var safe := Rect2(Vector2(left, 16), Vector2(maxf(160.0, vp.x - left - 16.0), maxf(140.0, toolbar.position.y - 28.0)))
		var bounds := Rect2(Vector2(-330, -350), Vector2(775, 400))
		camera.home_zoom = clampf(minf(safe.size.x / bounds.size.x, safe.size.y / bounds.size.y), 0.34, 0.70)
		camera.home_position = bounds.get_center() - (safe.get_center() - vp * 0.5) / camera.home_zoom
	if was_home:
		camera.focus_home()
		camera.position = camera.target_position
		camera.zoom = Vector2.ONE * camera.target_zoom

func _apply_hud_density(compact: bool, portrait: bool) -> void:
	_hud_controller._apply_hud_density(compact, portrait)

func _reflow_header() -> void:
	_hud_controller._reflow_header()

func _reflow_resource_ribbon() -> void:
	_hud_controller._reflow_resource_ribbon()

func _toggle_building_catalog() -> void:
	if building_catalog.visible:
		_close_building_catalog()
	else:
		_open_building_catalog()

func _open_building_catalog() -> void:
	feature_navigation.open("buildings")
	building_catalog.visible = true
	var view: Dictionary = session.get_view()
	building_catalog.call("refresh", view.buildings, view.resources, int(view.era_id))
	_layout_for_size(hud.size)

func _close_building_catalog() -> void:
	if feature_navigation != null:
		feature_navigation.home()
	_close_detail()
	building_catalog.visible = false
	_layout_for_size(hud.size)

func _set_resource_display_mode(mode: int) -> void:
	_hud_controller._set_resource_display_mode(mode)

func _select_building_from_catalog(id: String) -> void:
	var view: Dictionary = session.get_view()
	if not view.buildings.has(id) or not bool(view.buildings[id].visible):
		return
	if feature_navigation != null and (feature_navigation.group != "management" or feature_navigation.page != "buildings"):
		feature_navigation.open("buildings")
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
		"foundation_reservoir": "築基擴容・每階靈氣容量1000",
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
		elif id.begins_with("storage_") or id == "foundation_reservoir":
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
	_hud_controller._layout_overlay_panels(vp, margin, portrait)

func _layout_mode_name() -> String:
	return _hud_controller._layout_mode_name()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if OS.has_feature("web"):
			return # Web recovery is performed once by _process through OfflineCoordinator.
		if _process_ticks_initialized:
			var now_ticks: int = Time.get_ticks_msec()
			var elapsed_real: float = float(now_ticks - _last_process_ticks_msec) / 1000.0
			if elapsed_real > 0.05:
				var step_time := clampf(elapsed_real, 0.05, 86400.0)
				_last_process_ticks_msec = now_ticks
				if session != null and not _is_reincarnating and (reincarnation_seq == null or not reincarnation_seq.visible):
					state.advance(step_time)
					session.advance_time(step_time)
					if debug_auto_build_active:
						debug_auto_build_timer -= step_time
						if debug_auto_build_timer <= 0.0:
							debug_auto_build_timer = 30.0
							_debug_perform_random_upgrade()
					_refresh_hud()

func _process(delta: float) -> void:
	RuntimeProfile.begin_frame()
	var profile_preflight := RuntimeProfile.begin()
	if session == null:
		RuntimeProfile.end("preflight", profile_preflight)
		RuntimeProfile.end_frame()
		return
	if OS.has_feature("web") and SaveManager.adapter() is WebStorageAdapter and SaveManager.adapter().session_status() != "ready":
		get_tree().paused = true
		_show_storage_block("存檔保護已釋放，請重新載入以讀取最新進度。")
		RuntimeProfile.end("preflight", profile_preflight)
		RuntimeProfile.end_frame()
		return
	if _is_reincarnating or (reincarnation_seq != null and reincarnation_seq.visible):
		_last_process_ticks_msec = Time.get_ticks_msec()
		RuntimeProfile.end("preflight", profile_preflight)
		RuntimeProfile.end_frame()
		return

	var now_ticks: int = Time.get_ticks_msec()
	var step_delta := delta
	if _process_ticks_initialized:
		var elapsed_real: float = float(now_ticks - _last_process_ticks_msec) / 1000.0
		if elapsed_real > delta:
			step_delta = elapsed_real if OS.has_feature("web") else clampf(elapsed_real, delta, 86400.0)
	_last_process_ticks_msec = now_ticks
	RuntimeProfile.end("preflight", profile_preflight)
	if OS.has_feature("web") and step_delta > 2.0:
		# A suspended coroutine is not synchronous CPU work. End before await.
		RuntimeProfile.end_frame()
		var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
		_background_retry_cursor = maxi(SaveManager.last_settled_utc_ms(), now_ms - int(step_delta * 1000.0))
		if not await _settle_web_background(_background_retry_cursor):
			get_tree().paused = true
			_show_storage_block("背景結算尚未存妥，請保留此畫面。恢復儲存權限或空間後，按重試完成結算。")
			return
		_background_retry_cursor = 0
		step_delta = 0.0
		RuntimeProfile.begin_frame()

	var profile_advance := RuntimeProfile.begin()
	state.advance(step_delta)
	var advance_result: Dictionary = session.advance_time(step_delta)
	RuntimeProfile.end("advance_tick" if int(advance_result.get("ticks_advanced", 0)) > 0 else "advance_idle", profile_advance)
	for event in advance_result.get("events", []):
		if event.get("kind", "") == "abode_scenery_spawned":
			_pending_scenery_save = true
	if _pending_scenery_save and not advance_result.get("events", []).is_empty():
		_save_game()

	if hint != null and hint.text != _last_hint_text:
		_last_hint_text = hint.text
		if not _last_hint_text.is_empty():
			_push_hint_log(_last_hint_text)

	if debug_auto_build_active:
		debug_auto_build_timer -= step_delta
		if debug_panel != null and debug_panel.visible:
			debug_panel.call("update_auto_build_ui", debug_auto_build_timer)
		if debug_auto_build_timer <= 0.0:
			debug_auto_build_timer = 30.0
			_debug_perform_random_upgrade()

	var view: Dictionary = _presentation_view()

	# 當 Era 可以突破或達到圓滿時，停止增加修煉秒數；當前層可晉階時封頂在所需秒數
	var cur_lvl := int(view.get("level", 1))
	var max_era_lvl := int(view.get("era", {}).get("max_level", 10))
	var can_bt_flag: bool = bool(view.get("can_breakthrough", false))
	var can_lvl_flag: bool = bool(view.get("can_level_up", false))
	if can_bt_flag or cur_lvl >= max_era_lvl:
		if session.state.training_seconds != 0.0:
			session.state.training_seconds = 0.0
			_frame_view = {}
	elif can_lvl_flag:
		var needed_sec := float(view.get("next_level_required_seconds", 0.0))
		if needed_sec > 0.0 and session.state.training_seconds > needed_sec:
			session.state.training_seconds = needed_sec
			_frame_view = {}


	var distant: float = clampf((0.42 - camera.zoom.x) / 0.18, 0.0, 1.0)
	var viewing_remote_island: bool = island_world != null and island_world.current != "home"
	var sequence_visible: bool = breakthrough_seq != null and breakthrough_seq.visible
	for child in region_layer.get_children():
		if child is Label:
			child.visible = not sequence_visible and not viewing_remote_island and camera.zoom.x >= 0.12 and camera.zoom.x < 0.34
			UiMaterial.keep_world_text_readable(child, 18)
		else:
			child.modulate.a = distant * (0.8 if child is Sprite2D else 1.0)
	# Avoid fading essential text into the scenery at the LOD hand-off.
	home_marker.visible = not sequence_visible and not viewing_remote_island and camera.zoom.x < 0.34
	UiMaterial.keep_world_text_readable(home_marker, 24)

	for building in buildings.values():
		building.caption.visible = not sequence_visible and camera.zoom.x >= 0.34

	if not reduced:
		_sky_flow_time += delta
		sky_material.set_shader_parameter("flow_time", _sky_flow_time)
	cultivator.present(reduced, island_fx.energy, session.state.era_id)
	if absf(_last_sky_energy - island_fx.energy) > 0.001:
		_last_sky_energy = island_fx.energy
		sky_material.set_shader_parameter("energy", island_fx.energy)
	var reduced_int: int = 1 if reduced else 0
	if _last_sky_reduced != reduced_int:
		_last_sky_reduced = reduced_int
		sky_material.set_shader_parameter("reduced_motion", reduced)
	island_fx.set_attained(session.state.era_id >= 2)
	_check_and_update_bgm_era()
	var target_shade_a: float = snappedf(0.18 + distant * 0.34, 0.005)
	if absf(_last_shade_a - target_shade_a) > 0.004:
		_last_shade_a = target_shade_a
		shade.color.a = target_shade_a

	update_elapsed += delta
	if update_elapsed >= 0.25:
		update_elapsed = 0.0
		_refresh_hud(false)

	auto_save_elapsed += delta
	if auto_save_elapsed >= 15.0:
		auto_save_elapsed = 0.0
		_save_game()
	_mask_breakthrough_hud()
	RuntimeProfile.end_frame()

func _update_buildings_visual(view: Dictionary) -> void:
	_sync_scenery(view.get("abode_scenery", []))
	for id in buildings:
		var target_id: String = "herb_farm" if id == "garden" else ("storage_lingli" if id == "altar" else id)
		var b_view: Dictionary = view.buildings.get(target_id, {})
		var b_node = buildings[id]
		var is_vis: bool = bool(b_view.get("visible", false))

		# Only the hut offers a starter blueprint. An unbuilt altar leaves its platform empty.
		b_node.level = int(b_view.get("level", 0))
		var affordable: bool = bool(b_view.get("affordable", false))
		b_node.visible = (is_vis and (b_node.level > 0 or affordable)) if target_id == "hut" else (target_id == "storage_lingli" and b_node.level > 0)
		b_node.selected = (id == selected_id or target_id == selected_id)
		b_node.running = state.garden_running if (target_id == "herb_farm") else true
		b_node.reduced_motion = reduced
		if target_id == "hut":
			var attained := int(view.get("era_id", 1)) >= 2
			var art: Texture2D = COURTYARD if attained else HUT
			if b_node.sprite.texture != art:
				b_node.sprite.texture = art
				b_node.sprite.scale = Vector2.ONE * b_node.body_size.x / art.get_width()
				b_node.base_scale = b_node.sprite.scale
			b_node.title = "築基小院" if attained else "茅屋"

func _sync_scenery(entries: Array) -> void:
	if scenery_parent == null:
		return
	var active_ids: Array = []
	for entry in entries:
		var id: String = entry.id
		active_ids.append(id)
		if not scenery_props.has(id):
			var prop := SceneryPropScript.new()
			prop.position = SCENERY_SLOTS[int(entry.slot)]
			prop.setup(entry, SCENERY_ART[entry.kind])
			scenery_parent.add_child(prop)
			scenery_props[id] = prop
		var prop = scenery_props[id]
		prop.reduced_motion = reduced
		prop.visible = camera.zoom.x >= 0.34
	for id in scenery_props.keys():
		if not active_ids.has(id):
			scenery_props[id].queue_free()
			scenery_props.erase(id)

func _refresh_hud(force_view: bool = true) -> void:
	var profile_hud := RuntimeProfile.begin()
	# Explicit refreshes cover commands, debug edits, load/retry and session replacement.
	if force_view:
		var profile_view := RuntimeProfile.begin()
		_frame_view = session.get_view()
		RuntimeProfile.end("view_build", profile_view)
		_frame_view_state = session.state
		_frame_view_revision = session.state.revision
	else:
		_frame_view = _presentation_view()
	_hud_controller._refresh_hud(_frame_view)
	if island_world != null:
		var profile_island := RuntimeProfile.begin()
		island_world.refresh()
		RuntimeProfile.end("island_refresh", profile_island)
	RuntimeProfile.end("hud_total", profile_hud)

func _presentation_view() -> Dictionary:
	# Simulation changes whole-second state/revision, not on every rendered frame.
	if _frame_view.is_empty() or _frame_view_state != session.state or _frame_view_revision != session.state.revision:
		var profile_view := RuntimeProfile.begin()
		_frame_view = session.get_view()
		RuntimeProfile.end("view_build", profile_view)
		_frame_view_state = session.state
		_frame_view_revision = session.state.revision
	return _frame_view

func _update_onboarding_guidance(view: Dictionary) -> void:
	_hud_controller._update_onboarding_guidance(view)

func _pick_world(point: Vector2) -> void:
	if island_world != null and island_world.pick(point):
		return
	if camera.zoom.x < 0.34:
		if point.distance_to(Vector2.ZERO) < 800:
			_return_home()
		else:
			hint.text = "遠處是未開放的山域。點自己的洞府，可回到近景。"
		return

	for prop in scenery_props.values():
		if prop.contains_point(point):
			_claim_scenery(prop.find_id)
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

func _claim_scenery(find_id: String) -> void:
	var res: Dictionary = session.submit({"command_id": "scenery_" + find_id + "_" + str(session.state.revision),
		"type": "claim_abode_scenery", "expected_revision": session.state.revision, "payload": {"find_id": find_id}})
	if bool(res.get("ok", false)) and not bool(res.get("duplicate", false)):
		var event: Dictionary = res.events[0]
		var text := "%s +%s" % [RESOURCE_NAMES.get(event.resource_id, event.resource_id), event.amount]
		if scenery_props.has(find_id):
			var prop = scenery_props[find_id]
			scenery_props.erase(find_id)
			prop.harvest_feedback(text, UiTypography.emphasis_font())
		hint.text = "%s：%s。" % [event.name, text]
		_pending_scenery_save = true
		_save_game()
		_refresh_hud()
		print("ABODE_SCENERY_CLAIM ", event.name, " ", text)
	else:
		hint.text = "庫容已滿，小景仍會保留；可先消耗資源或擴建。" if res.get("error") == "SCENERY_CAPACITY_FULL" else "此處小景暫時無法採收。"

func _refresh_detail() -> void:
	_hud_controller._refresh_detail()

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

func _level_up_cultivation() -> bool:
	if (text_transition != null and text_transition.visible) or (breakthrough_seq != null and breakthrough_seq.visible):
		return false
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
		for event in res.get("events", []):
			if event.get("kind", "") == "cultivation_leveled_up" and text_transition != null:
				var view := session.get_view()
				var remaining := maxf(0.0, float(view.max_lifespan_seconds) - session.state.total_elapsed_seconds) / 60.0
				text_transition.play("境界等級提升至 LV%d" % int(event.new_level),
					"%s ERA%d · 壽元剩餘 %.0f 祀" % [String(view.era.name), int(event.era_id), remaining],
					{"reduced_motion": reduced_motion})
		return true
	return false

func _breakthrough_era() -> void:
	if text_transition != null and text_transition.visible:
		return
	if breakthrough_seq != null and breakthrough_seq.visible:
		return
	var from_era: int = session.state.era_id
	var cmd := {
		"command_id": "bt_" + str(Time.get_ticks_usec()) + "_" + str(randi()),
		"type": "breakthrough_era",
		"expected_revision": session.state.revision,
		"payload": {}
	}
	var res: Dictionary = session.submit(cmd)
	if bool(res.get("ok", false)):
		hint.text = "破關功成，天地共感，空島靈息煥然一新！"
		_pending_breakthrough_save = true
		_save_game()
		_refresh_hud()
		if breakthrough_seq != null:
			breakthrough_seq.reduced_motion = reduced
			breakthrough_seq.set_save_status(not _pending_breakthrough_save)
			breakthrough_seq.play(String(content.era(from_era).name), String(content.era(session.state.era_id).name), session.state.era_id)
	else:
		hint.text = "突破受阻：%s。請確認已達本境圓滿，並滿足容量門檻。" % str(res.get("error", "FAIL"))
		_hud_controller.show_messages()
		_layout_for_size(hud.size)

func _replay_breakthrough() -> void:
	if breakthrough_seq != null and session.state.era_id >= 2:
		breakthrough_seq.reduced_motion = reduced
		breakthrough_seq.set_save_status(not _pending_breakthrough_save)
		var target_era: int = session.state.era_id
		breakthrough_seq.play(String(content.era(target_era - 1).name), String(content.era(target_era).name), target_era)

func trigger_nine_realms_hook(is_replay: bool = false) -> void:
	_modal_manager.trigger_nine_realms_hook(is_replay)

func _open_nine_realms_overview() -> void:
	feature_navigation.open("realms")

func _on_nine_realms_aspiration_changed(realm_id: String) -> void:
	_modal_manager._on_nine_realms_aspiration_changed(realm_id)

func _on_nine_realms_closed() -> void:
	_modal_manager._on_nine_realms_closed()

func _upgrade_selected() -> void:
	if selected_id == "":
		return
	_upgrade_building_from_catalog(selected_id)

func _upgrade_building_from_catalog(building_id: String) -> bool:
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
		return true
	else:
		hint.text = "建造受阻：%s" % str(res.get("error", "FAIL"))
		return false

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
	if island_world != null:
		island_world.current = "home"
	_close_detail()
	building_catalog.visible = false
	_layout_for_size(hud.size)
	camera.focus_home()
	hint.text = "回到洞府。點茅屋聚氣引靈；建造升級請開啟「經營」（營造簿）。"
	print("ABODE_HOME")

func _toggle_motion() -> void:
	reduced = not reduced
	if vfx_environment != null:
		vfx_environment.environment.glow_enabled = not reduced
	camera.reduced_motion = reduced
	island_fx.set_reduced_motion(reduced)
	cultivator.present(reduced, island_fx.energy, session.state.era_id)
	if breakthrough_seq != null:
		breakthrough_seq.reduced_motion = reduced
	motion_button.text = "標準特效" if reduced else "低特效"
	print("ABODE_MOTION reduced=", reduced)

func _toggle_save_controls() -> void:
	_modal_manager._toggle_save_controls()

func _display_offline_summary(report: Dictionary) -> void:
	_modal_manager._display_offline_summary(report)

func _on_more_menu_pressed(id: int) -> void:
	_modal_manager._on_more_menu_pressed(id)

func _configure_settings_menu() -> void:
	_hud_controller._configure_settings_menu()

func _on_settings_menu_pressed(id: int) -> void:
	_modal_manager._on_settings_menu_pressed(id)

func _init_bgm() -> void:
	if bgm_player != null:
		return
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BgmPlayer"
	bgm_player.bus = "Master"
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)
	_load_bgm_library()
	var cur_era: int = session.state.era_id if (session != null and session.state != null) else 1
	_last_known_era_id = cur_era
	if is_bgm_enabled:
		_play_bgm_track_at_index(0)

func _load_bgm_library() -> void:
	_bgm_tracks.clear()
	if OS.has_feature("web"):
		# Web exports stream the unchanged soundtrack separately from the core PCK.
		# Era filtering still uses the same metadata and playback never grants rewards.
		var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/bgm/library.json"))
		if catalog is Array:
			for entry in catalog:
				_bgm_tracks.append({"era_req": int(entry.era_req), "filename": String(entry.filename), "path": String(entry.path), "stream": null})
			return
	var dir_path := "res://src/BGM/"
	var files := DirAccess.get_files_at(dir_path)
	var discovered: Array[Dictionary] = []
	var seen_paths: Dictionary = {}
	for file_name in files:
		var clean_name := file_name.trim_suffix(".remap").trim_suffix(".import")
		if clean_name.ends_with(".mp3"):
			var res_path := dir_path + clean_name
			if seen_paths.has(res_path):
				continue
			seen_paths[res_path] = true
			var prefix_str := clean_name.substr(0, 2)
			var era_req := prefix_str.to_int()
			var stream: AudioStream = load(res_path)
			if stream != null:
				if stream is AudioStreamMP3:
					(stream as AudioStreamMP3).loop = false
				discovered.append({
					"era_req": era_req,
					"filename": clean_name,
					"path": res_path,
					"stream": stream
				})
	discovered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["era_req"]) < int(b["era_req"])
	)
	_bgm_tracks = discovered
	if _bgm_tracks.is_empty():
		var fb: AudioStream = load("res://assets/audio/bgm/abode_theme.ogg")
		if fb != null:
			if fb is AudioStreamOggVorbis:
				(fb as AudioStreamOggVorbis).loop = false
			_bgm_tracks.append({
				"era_req": 1,
				"filename": "abode_theme.ogg",
				"path": "res://assets/audio/bgm/abode_theme.ogg",
				"stream": fb
			})

func _get_bgm_playlist_for_era(era_id: int) -> Array[Dictionary]:
	var playlist: Array[Dictionary] = []
	var max_era_req := mini(era_id, 4) if era_id >= 4 else era_id
	for track in _bgm_tracks:
		var req: int = int(track.get("era_req", 1))
		if req <= max_era_req:
			playlist.append(track)
	if playlist.is_empty() and not _bgm_tracks.is_empty():
		playlist.append(_bgm_tracks[0])
	return playlist

func _play_bgm_track_at_index(playlist_index: int) -> void:
	if not is_bgm_enabled or bgm_player == null:
		return
	var cur_era: int = session.state.era_id if (session != null and session.state != null) else 1
	var playlist := _get_bgm_playlist_for_era(cur_era)
	if playlist.is_empty():
		return
	_current_bgm_index = playlist_index % playlist.size()
	var track: Dictionary = playlist[_current_bgm_index]
	_bgm_selected_path = String(track.path)
	var stream: AudioStream = track.get("stream")
	if stream == null and OS.has_feature("web"):
		_request_web_bgm(track)
		return
	if stream != null:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = false
		bgm_player.stream = stream
		if bgm_player.is_inside_tree():
			bgm_player.play()

var _bgm_requests: Dictionary = {}
var _bgm_selected_path := ""

func _request_web_bgm(track: Dictionary) -> void:
	_bgm_selected_path = String(track.path)
	if _bgm_requests.has(track.path):
		return
	var request := HTTPRequest.new()
	request.timeout = 30.0
	request.body_size_limit = 4000000
	add_child(request)
	_bgm_requests[track.path] = request
	request.request_completed.connect(func(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray):
		_bgm_requests.erase(track.path)
		request.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or status != 200 or body.is_empty():
			push_warning("BGM download failed; toggle music to retry: " + String(track.filename))
			return
		var audio := AudioStreamMP3.new()
		audio.data = body
		audio.loop = false
		if audio.get_length() <= 0.0:
			push_warning("BGM data invalid; toggle music to retry")
			return
		track.stream = audio
		print("BGM_WEB_READY: ", track.filename, " seconds=", audio.get_length())
		if is_bgm_enabled and _bgm_selected_path == String(track.path) and bgm_player != null:
			bgm_player.stream = audio
			bgm_player.play()
	)
	var base := String(JavaScriptBridge.eval("new URL('./audio/bgm/', window.location.href).href"))
	var error := request.request(base + String(track.filename).uri_encode())
	if error != OK:
		_bgm_requests.erase(track.path)
		request.queue_free()
		push_warning("BGM request failed; toggle music to retry")

func _on_bgm_finished() -> void:
	if not is_bgm_enabled or bgm_player == null:
		return
	var cur_era: int = session.state.era_id if (session != null and session.state != null) else 1
	var playlist := _get_bgm_playlist_for_era(cur_era)
	if playlist.is_empty():
		return
	var next_index := (_current_bgm_index + 1) % playlist.size()
	_play_bgm_track_at_index(next_index)

func _check_and_update_bgm_era() -> void:
	if session == null or session.state == null:
		return
	var cur_era: int = session.state.era_id
	if cur_era == _last_known_era_id:
		return
	_last_known_era_id = cur_era
	var playlist := _get_bgm_playlist_for_era(cur_era)
	if playlist.is_empty():
		return
	var current_still_valid: bool = false
	for i in range(playlist.size()):
		if bgm_player != null and bgm_player.stream == playlist[i].get("stream"):
			_current_bgm_index = i
			current_still_valid = true
			break
	if not current_still_valid:
		_play_bgm_track_at_index(0)

func _toggle_bgm() -> void:
	_set_bgm_enabled(not is_bgm_enabled)

func _set_bgm_enabled(enabled: bool) -> void:
	is_bgm_enabled = enabled
	if bgm_player != null:
		if is_bgm_enabled:
			if not bgm_player.playing:
				var idx := _current_bgm_index if _current_bgm_index >= 0 else 0
				_play_bgm_track_at_index(idx)
		else:
			if bgm_player.playing:
				bgm_player.stop()
	if _modal_manager != null:
		_modal_manager._update_settings_menu_labels()

func _input(event: InputEvent) -> void:
	if is_bgm_enabled and bgm_player != null and not bgm_player.playing:
		if event is InputEventMouseButton and event.pressed:
			var idx := _current_bgm_index if _current_bgm_index >= 0 else 0
			_play_bgm_track_at_index(idx)
		elif event is InputEventScreenTouch and event.pressed:
			var idx := _current_bgm_index if _current_bgm_index >= 0 else 0
			_play_bgm_track_at_index(idx)

func _toggle_sect_panel() -> void:
	feature_navigation.open("sect")

func _on_sect_join_requested(sect_name: String) -> void:
	_modal_manager._on_sect_join_requested(sect_name)

func _on_sect_refresh_tasks_requested() -> void:
	_modal_manager._on_sect_refresh_tasks_requested()

func _on_sect_start_expedition_requested(task_id: String) -> void:
	_modal_manager._on_sect_start_expedition_requested(task_id)

func _on_sect_claim_expedition_requested() -> void:
	_modal_manager._on_sect_claim_expedition_requested()

func _on_sect_learn_technique_requested(tech_id: String) -> void:
	_modal_manager._on_sect_learn_technique_requested(tech_id)

func _on_sect_buy_market_item_requested(item_id: String) -> void:
	_modal_manager._on_sect_buy_market_item_requested(item_id)

func _on_sect_closed() -> void:
	_modal_manager._on_sect_closed()

func _toggle_realm_modal() -> void:
	feature_navigation.open("outposts")

func _on_switch_realm_requested(target_realm: String) -> void:
	_modal_manager._on_switch_realm_requested(target_realm)

func _on_upgrade_outpost_requested(outpost_id: String) -> void:
	_modal_manager._on_upgrade_outpost_requested(outpost_id)

func _on_realm_modal_closed() -> void:
	_modal_manager._on_realm_modal_closed()

func _toggle_alchemy_panel() -> void:
	feature_navigation.open("alchemy")

func _on_alchemy_refine_requested(pill_id: String, count: int) -> void:
	_modal_manager._on_alchemy_refine_requested(pill_id, count)

func _on_alchemy_consume_requested(pill_id: String, count: int) -> void:
	_modal_manager._on_alchemy_consume_requested(pill_id, count)

func _on_alchemy_closed() -> void:
	_modal_manager._on_alchemy_closed()

func _toggle_fortune_modal() -> void:
	feature_navigation.open("fortune")

func _on_fortune_trigger_requested() -> void:
	_modal_manager._on_fortune_trigger_requested()

func _on_fortune_resolve_requested(option_index: int) -> void:
	_modal_manager._on_fortune_resolve_requested(option_index)

func _on_fortune_closed() -> void:
	_modal_manager._on_fortune_closed()


func _toggle_debug_panel() -> void:
	_modal_manager._toggle_debug_panel()

func _on_debug_closed() -> void:
	_modal_manager._on_debug_closed()

func _on_debug_auto_build_toggled(enabled: bool) -> void:
	_modal_manager._on_debug_auto_build_toggled(enabled)

func _on_debug_manual_upgrade_requested() -> void:
	_modal_manager._on_debug_manual_upgrade_requested()

func _on_debug_boost_era_level_requested() -> void:
	_modal_manager._on_debug_boost_era_level_requested()

func _on_debug_add_resources_requested() -> void:
	_modal_manager._on_debug_add_resources_requested()

func _on_debug_apply_buff_requested(buff_id: String) -> void:
	_modal_manager._on_debug_apply_buff_requested(buff_id)

func _debug_perform_random_upgrade() -> void:
	if session == null or session.state == null:
		return
	var view: Dictionary = session.get_view()

	# 1. 檢查修為小境界升級（除渡劫外）
	var era_upgraded := false
	var can_lvl := bool(view.get("can_level_up", false))
	var can_bt := bool(view.get("can_breakthrough", false))
	var cur_lvl := int(view.get("level", 1))
	var era_info: Dictionary = view.get("era", {})
	var era_name: String = String(era_info.get("name", "當前境界"))

	if can_lvl:
		if _level_up_cultivation():
			era_upgraded = true
			view = session.get_view()

	# 2. 檢查建築建造與升級候選
	var candidates: Array[String] = []
	for b_id in view.buildings:
		var b_info: Dictionary = view.buildings[b_id]
		var is_visible: bool = bool(b_info.get("visible", false))
		var is_affordable: bool = bool(b_info.get("affordable", false))
		var cur_b_level: int = int(b_info.get("level", 0))
		var cap_level: int = int(b_info.get("level_cap", 0))
		if is_visible and is_affordable and cur_b_level < cap_level:
			candidates.append(b_id)

	var building_upgraded := false
	var build_desc := ""
	if not candidates.is_empty():
		var chosen_id: String = candidates[randi() % candidates.size()]
		var old_level := int(view.buildings[chosen_id].get("level", 0))
		if _upgrade_building_from_catalog(chosen_id):
			building_upgraded = true
			var b_name: String = BUILDING_NAMES.get(chosen_id, chosen_id)
			var action_name := "建造" if old_level == 0 else "升級"
			build_desc = "%s「%s」至 %d 階" % [action_name, b_name, old_level + 1]

	# 3. 匯總狀態與反饋
	var status_parts: Array[String] = []
	if era_upgraded:
		status_parts.append("自動晉階：%s 提升至第 %d 層" % [era_name, cur_lvl + 1])
	if building_upgraded:
		status_parts.append("自動建造：%s" % build_desc)

	if not status_parts.is_empty():
		var final_msg := "[DEBUG] %s！" % " · ".join(status_parts)
		hint.text = final_msg
		if debug_panel != null:
			debug_panel.call("set_status_message", final_msg)
	else:
		var reason := ""
		if can_bt:
			reason = "修為已達大圓滿（請道友親自點擊突破渡劫）；無滿足條件之建築。"
		else:
			reason = "目前無建築滿足建造條件，且修為未達晉階條件。可點擊【獲得全基礎資源】補充物資。"
		var skip_msg := "[DEBUG] 自動建造跳過：%s" % reason
		hint.text = skip_msg
		if debug_panel != null:
			debug_panel.call("set_status_message", skip_msg)

func _debug_boost_era_level_10() -> void:
	if session == null or session.state == null:
		return
	var cur_era_id := session.state.era_id
	var era_def: Variant = content.era(cur_era_id)
	var max_lvl := 10
	if era_def != null and era_def.has("max_level"):
		max_lvl = int(era_def["max_level"])

	session.state.level = max_lvl
	session.state.training_seconds = 0.0

	_save_game()
	_refresh_hud()

	var era_name: String = era_def.get("name", "當前境界") if era_def != null else "當前境界"
	var msg := "[DEBUG] 境界躍遷成功：%s 已提升至 LV %d (大圓滿)！" % [era_name, max_lvl]
	hint.text = msg
	if debug_panel != null:
		debug_panel.call("set_status_message", msg)

func _debug_add_resources() -> void:
	if session == null or session.state == null:
		return
	var add_amt := AmountCompat.from_number(1000.0)
	for r_id in session.state.resources:
		var entry: Dictionary = session.state.resources[r_id]
		entry.value = entry.value.add(add_amt)
		entry.unlocked = true
		entry.ever_obtained = true
	_save_game()
	_refresh_hud()
	var msg := "[DEBUG] 資源調試成功：所有基礎資源已增加 +1,000！"
	hint.text = msg
	if debug_panel != null:
		debug_panel.call("set_status_message", msg)

func _on_debug_reset_achievements_requested() -> void:
	if session == null or session.state == null:
		return
	AchievementSystem.reset_achievements(session.state)
	_save_game()
	_refresh_hud()
	var msg := "[DEBUG] 成就進度已全數重置（解鎖/領取/統計均已清空）。"
	hint.text = msg
	if debug_panel != null:
		debug_panel.call("set_status_message", msg)

func _on_achievement_claim_requested(achievement_id: String) -> void:
	if session == null or session.state == null:
		return
	var res := session.claim_achievement(achievement_id)
	if bool(res.get("ok", false)):
		_save_game()
		_refresh_hud()
		if achievement_panel != null:
			achievement_panel.call("show_status_message", String(res.get("message", "領取成功！")))
	else:
		if achievement_panel != null:
			achievement_panel.call("show_status_message", String(res.get("message", "領取失敗")))

func _on_achievement_closed() -> void:
	feature_navigation.home()

func _toggle_reincarnation_panel() -> void:
	feature_navigation.open("reincarnation")

func _on_reincarnate_requested(mode: String) -> void:
	_modal_manager._on_reincarnate_requested(mode)

func _on_learn_talent_requested(talent_id: String) -> void:
	_modal_manager._on_learn_talent_requested(talent_id)

func _on_reincarnation_closed() -> void:
	_modal_manager._on_reincarnation_closed()

func _save_game() -> Dictionary:
	if session == null or session.state == null:
		return {"ok": false, "error": "STATE_MISSING"}
	var profile_save := RuntimeProfile.begin()
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var sim_tick: int = int(floor(session.state.total_elapsed_seconds / float(TimeAdvancer.SECONDS_PER_TICK)))
	var meta: Dictionary = {
		"save_id": "local",
		"saved_at_utc_ms": str(now_ms),
		"settled_until_utc_ms": str(now_ms),
		"sim_tick": str(sim_tick),
	}
	var result: Dictionary = SaveManager.save(session.state, meta)
	if not bool(result.get("ok", false)) and OS.has_feature("web"):
		_background_retry_cursor = maxi(SaveManager.last_settled_utc_ms(), now_ms)
		get_tree().paused = true
		_show_storage_block("進度尚未存妥，請保留此畫面。恢復儲存權限或空間後，按重試保存；操作不會再次扣料。")
	if not bool(result.get("ok", false)) and hint != null:
		hint.text = "進度尚未存妥；請保留此畫面，並檢查儲存權限或空間。" if OS.has_feature("web") else "進度尚未存妥，15 秒後自動重試；請保留此畫面。"
	if _pending_scenery_save:
		_pending_scenery_save = not bool(result.get("ok", false))
		if _pending_scenery_save and hint != null:
			hint.text = "小景進度尚未存妥；請先保留遊戲畫面並重試保存。" if OS.has_feature("web") else "小景進度尚未存妥，15 秒後自動重試；請先保留遊戲畫面。"
	if _pending_breakthrough_save:
		_pending_breakthrough_save = not bool(result.get("ok", false))
		if breakthrough_seq != null:
			breakthrough_seq.set_save_status(not _pending_breakthrough_save)
	RuntimeProfile.end("save_total", profile_save)
	return result

func _settle_web_background(cursor: int) -> bool:
	_begin_settlement_progress()
	var result := await OfflineCoordinator.settle_state_async(session.state, content, int(Time.get_unix_time_from_system() * 1000.0), cursor, get_tree(), _settlement_progress)
	_end_settlement_progress()
	if not result.ok:
		print("WEB_BACKGROUND_SAVE_FAILED: ", result.get("detail", ""))
		return false
	session.state = result.state
	session.clock = GameClock.create(session.state.total_elapsed_seconds)
	state = AbodeStateCompat.new(session)
	_pending_scenery_save = false
	_pending_breakthrough_save = false
	if breakthrough_seq != null:
		breakthrough_seq.set_save_status(true)
	_refresh_hud()
	if feature_navigation != null and feature_navigation.island_panel != null:
		feature_navigation.storage_recovered()
		feature_navigation.action_panel.storage_recovered()
	print("WEB_BACKGROUND_SETTLED: ", JSON.stringify(result.report))
	return true

func _show_help() -> void:
	_hud_controller._show_help()

func _toggle_guidance() -> void:
	_hud_controller._toggle_guidance()

func _toggle_hint_expand() -> void:
	_hud_controller._toggle_hint_expand()

func _push_hint_log(msg: String) -> void:
	_hud_controller._push_hint_log(msg)

func _rebuild_hint_log_display() -> void:
	_hud_controller._rebuild_hint_log_display()

# This presentation scope owns its camera/input lock until the result is closed.
func _on_breakthrough_sequence_started() -> void:
	if not _breakthrough_camera_snapshot.is_empty():
		return
	_breakthrough_camera_snapshot = {
		"position": camera.position, "zoom": camera.zoom,
		"target_position": camera.target_position, "target_zoom": camera.target_zoom,
		"input_locked": camera.input_locked,
	}
	for child in hud.get_children():
		if child is Control and child != breakthrough_seq:
			_breakthrough_hud_snapshot[child] = child.visible
	camera.dragging = false
	camera.dragged = false
	camera.contacts.clear()
	camera.zoom_anchor_active = false
	camera.input_locked = true
	_fit_breakthrough_camera(hud.size)
	_mask_breakthrough_hud()

func _fit_breakthrough_camera(vp: Vector2) -> void:
	camera.target_zoom = minf(0.62, minf((vp.x - 32.0) / 1450.0, (vp.y - 110.0) / 1100.0))
	camera.target_zoom = maxf(CameraScript.MIN_ZOOM, camera.target_zoom)
	camera.target_position = Vector2(0, -120)
	camera.position = camera.target_position
	camera.zoom = Vector2.ONE * camera.target_zoom

func _mask_breakthrough_hud() -> void:
	if breakthrough_seq == null or not breakthrough_seq.visible:
		return
	home_marker.visible = false
	for child in region_layer.get_children():
		if child is Label:
			child.visible = false
	for building in buildings.values():
		building.caption.visible = false
	for child in _breakthrough_hud_snapshot:
		if is_instance_valid(child):
			child.visible = false

func _on_breakthrough_sequence_finished() -> void:
	if _breakthrough_camera_snapshot.is_empty():
		return
	camera.position = _breakthrough_camera_snapshot.position
	camera.zoom = _breakthrough_camera_snapshot.zoom
	camera.target_position = _breakthrough_camera_snapshot.target_position
	camera.target_zoom = _breakthrough_camera_snapshot.target_zoom
	camera.input_locked = bool(_breakthrough_camera_snapshot.input_locked)
	camera.dragging = false
	camera.contacts.clear()
	camera.zoom_anchor_active = false
	for child in _breakthrough_hud_snapshot:
		if is_instance_valid(child):
			child.visible = bool(_breakthrough_hud_snapshot[child])
	_breakthrough_camera_snapshot.clear()
	_breakthrough_hud_snapshot.clear()
	_layout_for_size(hud.size)
	_refresh_hud()
	sky_material.set_shader_parameter("energy", 0.0)

func _retry_breakthrough_save() -> void:
	if _pending_breakthrough_save:
		_save_game()

func _on_reincarnation_sequence_started() -> void:
	_is_reincarnating = true
	_reincarnation_hud_snapshot.clear()
	for child in hud.get_children():
		if child is Control and child != reincarnation_seq and child != nine_realms_preview:
			_reincarnation_hud_snapshot[child] = child.visible
			child.visible = false

func _on_reincarnation_sequence_finished() -> void:
	_is_reincarnating = false
	for child in _reincarnation_hud_snapshot:
		if is_instance_valid(child):
			child.visible = bool(_reincarnation_hud_snapshot[child])
	_reincarnation_hud_snapshot.clear()
	_layout_for_size(hud.size)
	_refresh_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and feature_navigation != null and feature_navigation.group != "home":
		feature_navigation.back()
		get_viewport().set_input_as_handled()

var _settlement_layer: CanvasLayer
var _settlement_label: Label
func _begin_settlement_progress() -> void:
	set_process(false)
	_settlement_layer = CanvasLayer.new()
	_settlement_layer.layer = 119
	_settlement_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settlement_layer)
	var panel := PanelContainer.new()
	_settlement_layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.theme = UiTypography.create_theme()
	var center := CenterContainer.new()
	panel.add_child(center)
	_settlement_label = Label.new()
	_settlement_label.text = "正在結算離線產業…原進度保留中"
	center.add_child(_settlement_label)

func _settlement_progress(done: int, planned: int) -> void:
	_settlement_label.text = "離線結算 %d / %d 秒\n完成保存後恢復操作" % [done, planned]

func _end_settlement_progress() -> void:
	_settlement_layer.queue_free()
	_settlement_label = null
	set_process(true)
	_last_process_ticks_msec = Time.get_ticks_msec()
