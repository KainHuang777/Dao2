class_name NineRealmsPreview
extends Control
## NineRealmsPreview: Godot first-minute hook & cosmos preview presentation.
## Implements:
## - 6-8s skippable zoom-out cinematic camera presentation
## - Cosmic light pulse identifying the player's abode as the home beacon
## - Nine Realms overview with law summaries and aspiration bookmarking
## - Deterministic return to abode with zero economic side effects
## - Safe for replays without re-granting rewards

signal aspiration_changed(realm_id: String)
signal preview_closed()

const REALMS_DATA_PATH := "res://content/realms/realms.json"
const FONT := UiTypography.BASE_FONT

var _bg_overlay: ColorRect
var _cinematic_container: Control
var _cinematic_label: Label
var _skip_btn: Button

var _overview_panel: Panel
var _content_root: Control
var _header_box: VBoxContainer
var _footer: HBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _grid_container: GridContainer
var _scroll: ScrollContainer
var _close_btn: Button

var _camera: Camera2D
var _on_close_callback: Callable
var _is_cinematic_playing: bool = false
var _cinematic_elapsed: float = 0.0
var _cinematic_duration: float = 6.0
var _reduced_motion: bool = false
var _current_aspired_realm: String = ""

var _workspace_bounds := Rect2()

func set_workspace_bounds(bounds: Rect2) -> void:
	_workspace_bounds = bounds
	_layout_for_viewport()

var _realms_data: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_realms_data()
	_build_ui()
	resized.connect(_layout_for_viewport)
	_layout_for_viewport()
	visible = false

func _load_realms_data() -> void:
	var result := ContentLoader.load_realms(REALMS_DATA_PATH)
	if bool(result.get("ok", false)) and not (result.get("realms", []) as Array).is_empty():
		_realms_data = result["realms"]
	elif FileAccess.file_exists(REALMS_DATA_PATH):
		var file := FileAccess.open(REALMS_DATA_PATH, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Array:
				_realms_data = parsed
	if _realms_data.is_empty():
		_realms_data = [
			{"id": "realm_human", "name": "人界", "title": "凡塵微光 · 修仙伊始", "description": "凡塵微光，萬靈繁衍生息之地。以一方洞府為基，吸納五行微靈，築百代仙基。", "law_summary": "五行恆定 · 洞府自足", "status": "active", "cultivation_factor": 1.0, "lifespan_flow_ratio": 1.0, "lingqi_pool_scale": 1.0},
			{"id": "realm_spirit", "name": "靈界", "title": "天地靈潮 · 五行洞天", "description": "天道靈機充沛，九幽靈脈交匯。五行靈潮盛衰變換，造就洞天福地與奇花異草。", "law_summary": "靈潮汐動 · 純靈轉化", "status": "locked", "cultivation_factor": 1.5, "lifespan_flow_ratio": 0.85, "lingqi_pool_scale": 10.0},
			{"id": "realm_nether", "name": "幽冥界", "title": "九幽輪迴 · 生死參悟", "description": "黃泉冥土，百代魂歸之所。參透陰陽生死，以幽冥死氣鍛造無上神魂與輪迴宿命。", "law_summary": "輪迴因果 · 魂火不滅", "status": "locked", "cultivation_factor": 0.8, "lifespan_flow_ratio": 0.5, "lingqi_pool_scale": 5.0},
			{"id": "realm_beast", "name": "萬妖界", "title": "洪荒百族 · 血脈神通", "description": "萬山荒莽，大妖咆哮於天際。修煉肉身極致，吞吐日月精華，喚醒太古洪荒血脈。", "law_summary": "肉身橫煉 · 血脈傳承", "status": "locked", "cultivation_factor": 0.85, "lifespan_flow_ratio": 0.7, "lingqi_pool_scale": 8.0},
			{"id": "realm_demon", "name": "天魔界", "title": "無相幻境 · 道心試煉", "description": "天魔無形無相，化作七情六慾。歷經萬重執念幻象，鍛造金剛不壞之無瑕道心。", "law_summary": "執念幻化 · 道心淬煉", "status": "locked", "cultivation_factor": 2.5, "lifespan_flow_ratio": 1.6, "lingqi_pool_scale": 15.0},
			{"id": "realm_immortal", "name": "仙界", "title": "純陽九霄 · 飛升仙班", "description": "九天雲海之上，仙宮巍峨，純陽之氣無窮無盡。褪盡凡胎，與天地同壽，列入真仙之班。", "law_summary": "純陽無極 · 長生久視", "status": "locked", "cultivation_factor": 3.0, "lifespan_flow_ratio": 0.2, "lingqi_pool_scale": 100.0},
			{"id": "realm_buddha", "name": "佛界", "title": "三千淨土 · 因果菩提", "description": "梵音悠遠，三千世界皆為淨土。以慈悲願力照徹十方，參破虛妄，照見本來面目。", "law_summary": "因果無礙 · 功德金身", "status": "locked", "cultivation_factor": 1.2, "lifespan_flow_ratio": 0.6, "lingqi_pool_scale": 50.0},
			{"id": "realm_chaos", "name": "混沌界", "title": "大道初分 · 鴻蒙未定", "description": "混沌未闢，乾坤未明，陰陽五行融為一體。於暴烈亂流中截取開天闢地之玄機。", "law_summary": "逆轉五行 · 混沌重鑄", "status": "locked", "cultivation_factor": 2.0, "lifespan_flow_ratio": 1.2, "lingqi_pool_scale": 200.0},
			{"id": "realm_origin", "name": "太初界", "title": "創世之源 · 虛無終極", "description": "萬法起源，歸於無極。修士神識達此境者，可撥動宇宙法則，塑造自創之全新天地。", "law_summary": "宇宙造化 · 創世神念", "status": "locked", "cultivation_factor": 5.0, "lifespan_flow_ratio": 0.1, "lingqi_pool_scale": 1000.0}
		]
	ScaleLawContract.set_custom_realm_laws(_realms_data)

func _build_ui() -> void:
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0.005, 0.02, 0.04, 0.70)
	_bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_overlay)

	# --- Cinematic overlay ---
	_cinematic_container = Control.new()
	_cinematic_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cinematic_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cinematic_container)

	_cinematic_label = Label.new()
	_cinematic_label.text = "丹田一息初生，神識直沖雲霄……\n群星浩瀚，那一星微芒，便是你的洞府。"
	_cinematic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cinematic_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_cinematic_label.position = Vector2(-400, -160)
	_cinematic_label.size = Vector2(800, 80)
	_cinematic_label.add_theme_font_override("font", UiTypography.body_font())
	_cinematic_label.add_theme_font_size_override("font_size", 22)
	_cinematic_label.add_theme_color_override("font_color", Color("e2f0e8"))
	_cinematic_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.95))
	_cinematic_label.add_theme_constant_override("outline_size", 4)
	_cinematic_container.add_child(_cinematic_label)

	_skip_btn = Button.new()
	_skip_btn.text = "跳過神識抽遠 (ESC)"
	_skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_btn.position = Vector2(-220, 24)
	_skip_btn.size = Vector2(190, 44)
	_skip_btn.add_theme_font_override("font", UiTypography.body_font())
	_skip_btn.add_theme_font_size_override("font_size", 18)
	_skip_btn.pressed.connect(skip_cinematic)
	_cinematic_container.add_child(_skip_btn)

	# --- Overview Panel ---
	# Keep the header and close control outside the scroll viewport.  Long realm
	# content may scroll, but closing the overlay must always remain possible.
	_overview_panel = Panel.new()
	_overview_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_overview_panel.custom_minimum_size = Vector2.ZERO
	_overview_panel.position = Vector2(-550, -310)
	var panel_style := UiMaterial.card()
	_overview_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_overview_panel)

	_content_root = Control.new()
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overview_panel.add_child(_content_root)

	_header_box = VBoxContainer.new()
	_header_box.add_theme_constant_override("separation", 4)
	_header_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_header_box)

	_title_label = Label.new()
	_title_label.text = "九界諸天 · 神識星圖"
	_title_label.add_theme_font_override("font", UiTypography.chapter_font())
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color("fce2a6"))
	_header_box.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "天地有九界，法則各異。此時神識初開，可標記心儀道途，待得修為精深，方可踏破虛空。"
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.add_theme_font_override("font", UiTypography.body_font())
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_color_override("font_color", Color("e8f3ec"))
	_header_box.add_child(_subtitle_label)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2.ZERO
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_root.add_child(_scroll)

	_grid_container = GridContainer.new()
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_container.columns = 3
	_grid_container.add_theme_constant_override("h_separation", 16)
	_grid_container.add_theme_constant_override("v_separation", 16)
	_scroll.add_child(_grid_container)

	_build_realm_cards()

	_footer = HBoxContainer.new()
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.mouse_filter = Control.MOUSE_FILTER_STOP
	_content_root.add_child(_footer)

	_close_btn = Button.new()
	_close_btn.text = "收回神識 · 回到洞府"
	_close_btn.custom_minimum_size = Vector2(240, 46)
	_close_btn.add_theme_font_override("font", UiTypography.emphasis_font())
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.pressed.connect(_on_close_pressed)
	_footer.add_child(_close_btn)

func _layout_for_viewport() -> void:
	var vp: Vector2 = size
	if vp.x <= 0.0 or vp.y <= 0.0 or _overview_panel == null:
		return
	var portrait: bool = vp.x < 640.0 or vp.x / vp.y < 1.25
	var margin: float = 12.0 if portrait else 28.0
	var panel_size := Vector2(minf(1100.0, vp.x - margin * 2.0), minf(620.0, vp.y - margin * 2.0))
	if _workspace_bounds.size.x > 0.0 and not _is_cinematic_playing:
		panel_size = _workspace_bounds.size
	_overview_panel.custom_minimum_size = Vector2.ZERO
	_overview_panel.position = _workspace_bounds.position if _workspace_bounds.size.x > 0.0 and not _is_cinematic_playing else (vp - panel_size) * 0.5
	_overview_panel.size = panel_size

	var side_margin: float = 16.0 if portrait else 28.0
	var top_margin: float = 16.0 if portrait else 20.0
	var bottom_margin: float = 16.0 if portrait else 20.0
	var header_height: float = 64.0 if panel_size.y < 300.0 else (112.0 if portrait else 78.0)
	var hosted := _workspace_bounds.size != Vector2.ZERO and not _is_cinematic_playing
	_footer.visible = not hosted
	var footer_height: float = 0.0 if hosted else 46.0
	var section_gap: float = 10.0
	var inner_width: float = maxf(0.0, panel_size.x - side_margin * 2.0)
	var scroll_height: float = maxf(32.0 if hosted else 72.0, panel_size.y - top_margin - header_height - section_gap * 2.0 - footer_height - bottom_margin)

	_content_root.position = Vector2.ZERO
	_content_root.size = panel_size
	_header_box.position = Vector2(side_margin, top_margin)
	_header_box.size = Vector2(inner_width, header_height)
	_title_label.add_theme_font_size_override("font_size", 24 if portrait else 28)
	_subtitle_label.visible = panel_size.y >= 300.0
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_scroll.position = Vector2(side_margin, top_margin + header_height + section_gap)
	_scroll.size = Vector2(inner_width, scroll_height)
	_scroll.custom_minimum_size = Vector2.ZERO
	_footer.position = Vector2(side_margin, panel_size.y - bottom_margin - footer_height)
	_footer.size = Vector2(inner_width, footer_height)

	_cinematic_label.position = Vector2(-minf(400.0, vp.x * 0.45), -150)
	_cinematic_label.size = Vector2(minf(800.0, vp.x * 0.90), 92)
	_cinematic_label.add_theme_font_size_override("font_size", 18 if portrait else 22)
	_skip_btn.position = Vector2(-minf(210.0, vp.x - 24.0), 16)
	_skip_btn.size = Vector2(minf(190.0, vp.x - 32.0), 44)
	if _grid_container != null:
		_grid_container.columns = 1 if inner_width < 560.0 else (2 if inner_width < 920.0 else 3)
		for entry in _card_nodes.values():
			var card: PanelContainer = entry.get("card", null)
			if card != null:
				card.custom_minimum_size = Vector2(0, 210)
var _card_nodes: Dictionary = {}

func _build_realm_cards() -> void:
	for realm in _realms_data:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 210)
		var card_style := UiMaterial.card()
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 6)
		card.add_child(card_vbox)

		var top_row := HBoxContainer.new()
		card_vbox.add_child(top_row)

		var name_lbl := Label.new()
		name_lbl.text = realm.name
		name_lbl.add_theme_font_override("font", UiTypography.emphasis_font())
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(name_lbl)

		var status_lbl := Label.new()
		status_lbl.add_theme_font_override("font", UiTypography.body_font())
		status_lbl.add_theme_font_size_override("font_size", 16)
		top_row.add_child(status_lbl)

		var law_lbl := Label.new()
		law_lbl.text = realm.title + " · " + realm.law_summary
		law_lbl.add_theme_font_override("font", UiTypography.body_font())
		law_lbl.add_theme_font_size_override("font_size", 17)
		law_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		law_lbl.add_theme_color_override("font_color", Color("d9e3ff"))
		card_vbox.add_child(law_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = realm.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_override("font", UiTypography.body_font())
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color("eef4fa"))
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(desc_lbl)

		var cult_mult := float(realm.get("cultivation_factor", 1.0))
		var life_ratio := float(realm.get("lifespan_flow_ratio", 1.0))
		var pool_scale := float(realm.get("lingqi_pool_scale", 1.0))
		var metrics_lbl := Label.new()
		metrics_lbl.text = "【法則契約】修煉 %.1fx · 壽元流速 %.2fx · 靈池容量 %.0fx" % [cult_mult, life_ratio, pool_scale]
		metrics_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		metrics_lbl.add_theme_font_override("font", UiTypography.body_font())
		metrics_lbl.add_theme_font_size_override("font_size", 14)
		metrics_lbl.add_theme_color_override("font_color", Color("ffd166"))
		card_vbox.add_child(metrics_lbl)

		var is_human: bool = (realm.id == "realm_human")
		var aspire_btn: Button = null
		if not is_human:
			var action_row := HBoxContainer.new()
			action_row.alignment = BoxContainer.ALIGNMENT_END
			card_vbox.add_child(action_row)

			aspire_btn = Button.new()
			aspire_btn.add_theme_font_override("font", UiTypography.emphasis_font())
			aspire_btn.add_theme_font_size_override("font_size", 18)
			aspire_btn.custom_minimum_size = Vector2(150, 44)
			var r_id: String = realm.id
			aspire_btn.pressed.connect(func(): _on_aspire_pressed(r_id))
			action_row.add_child(aspire_btn)

		_card_nodes[realm.id] = {
			"card": card,
			"style": card_style,
			"name_lbl": name_lbl,
			"status_lbl": status_lbl,
			"aspire_btn": aspire_btn
		}
		_grid_container.add_child(card)

	_update_realm_cards()

func _update_realm_cards() -> void:
	for realm in _realms_data:
		var entry: Dictionary = _card_nodes.get(realm.id, {})
		if entry.is_empty():
			continue
		var is_human: bool = (realm.id == "realm_human")
		var is_aspired: bool = (realm.id == _current_aspired_realm)
		var style: StyleBoxTexture = entry["style"]
		var status_lbl: Label = entry["status_lbl"]
		var name_lbl: Label = entry["name_lbl"]
		var aspire_btn: Button = entry["aspire_btn"]

		if is_human:
			style.modulate_color = Color(0.92, 1.10, 0.94)
			name_lbl.add_theme_color_override("font_color", Color("ffffff"))
			status_lbl.text = "【當前洞府】"
			status_lbl.add_theme_color_override("font_color", Color("6ee7b7"))
		elif is_aspired:
			style.modulate_color = Color(1.12, 1.06, 0.82)
			name_lbl.add_theme_color_override("font_color", Color("ffd166"))
			status_lbl.text = "【心之所向】"
			status_lbl.add_theme_color_override("font_color", Color("fcd34d"))
			if aspire_btn:
				aspire_btn.text = "★ 已標記嚮往"
				aspire_btn.disabled = true
		else:
			style.modulate_color = Color(0.83, 0.91, 0.94)
			name_lbl.add_theme_color_override("font_color", Color("ffffff"))
			status_lbl.text = "【神識遠眺 · 未解鎖】"
			status_lbl.add_theme_color_override("font_color", Color("d5e2ec"))
			if aspire_btn:
				aspire_btn.text = "標記嚮往"
				aspire_btn.disabled = false

func _process(delta: float) -> void:
	if not _is_cinematic_playing:
		return
	_cinematic_elapsed += delta
	var progress: float = clampf(_cinematic_elapsed / _cinematic_duration, 0.0, 1.0)

	# Drive camera zoom out to cosmos
	if _camera and not _reduced_motion:
		_camera.target_zoom = lerpf(0.70, 0.08, progress)
		_camera.target_position = Vector2(0, -40).lerp(Vector2(0, -100), progress)

	if progress >= 1.0:
		_finish_cinematic()

func play_hook(camera: Camera2D, aspired_realm: String, on_close: Callable, reduced_motion: bool = false, is_replay: bool = false) -> void:
	_camera = camera
	_current_aspired_realm = aspired_realm
	_on_close_callback = on_close
	_reduced_motion = reduced_motion
	_workspace_bounds = Rect2()
	_is_cinematic_playing = true
	_cinematic_elapsed = 0.0
	_cinematic_duration = 0.2 if reduced_motion else 6.0

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cinematic_container.visible = true
	_overview_panel.visible = false
	_bg_overlay.color.a = 0.2

	if is_replay:
		print("NINE_REALMS_REPLAY")
	else:
		print("NINE_REALMS_HOOK_TRIGGERED")

	if _camera:
		_camera.focus_cosmos()

func show_overview(camera: Camera2D, aspired_realm: String, on_close: Callable) -> void:
	_camera = camera
	_current_aspired_realm = aspired_realm
	_on_close_callback = on_close
	_is_cinematic_playing = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cinematic_container.visible = false
	_overview_panel.visible = true
	_bg_overlay.color.a = 0.75
	_update_realm_cards()
	if _camera:
		_camera.focus_cosmos()

func skip_cinematic() -> void:
	if _is_cinematic_playing:
		_finish_cinematic()

func _finish_cinematic() -> void:
	_is_cinematic_playing = false
	_cinematic_container.visible = false
	_overview_panel.visible = true
	_bg_overlay.color.a = 0.75
	if _camera:
		_camera.target_zoom = 0.08
		_camera.target_position = Vector2(0, -100)
	_update_realm_cards()
	print("NINE_REALMS_CINEMATIC_DONE")

func _on_aspire_pressed(realm_id: String) -> void:
	_current_aspired_realm = realm_id
	_update_realm_cards()
	aspiration_changed.emit(realm_id)
	print("NINE_REALMS_ASPIRE: ", realm_id)

func _on_close_pressed() -> void:
	_is_cinematic_playing = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _camera:
		_camera.focus_home()
	print("NINE_REALMS_HOOK_FINISHED")
	preview_closed.emit()
	if _on_close_callback.is_valid():
		_on_close_callback.call()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _is_cinematic_playing:
			skip_cinematic()
		elif _overview_panel.visible:
			_on_close_pressed()
