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
const FONT := preload("res://assets/fonts/NotoSerifTC-VF.ttf")

var _bg_overlay: ColorRect
var _cinematic_container: Control
var _cinematic_label: Label
var _skip_btn: Button

var _overview_panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _grid_container: GridContainer
var _close_btn: Button

var _camera: Camera2D
var _on_close_callback: Callable
var _is_cinematic_playing: bool = false
var _cinematic_elapsed: float = 0.0
var _cinematic_duration: float = 6.0
var _reduced_motion: bool = false
var _current_aspired_realm: String = ""

var _realms_data: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_realms_data()
	_build_ui()
	visible = false

func _load_realms_data() -> void:
	if FileAccess.file_exists(REALMS_DATA_PATH):
		var file := FileAccess.open(REALMS_DATA_PATH, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Array:
				_realms_data = parsed
	if _realms_data.is_empty():
		_realms_data = [
			{"id": "realm_human", "name": "人界", "title": "凡塵微光 · 修仙伊始", "description": "凡塵微光，萬靈繁衍生息之地。以一方洞府為基，吸納五行微靈，築百代仙基。", "law_summary": "五行恆定 · 洞府自足", "status": "active"},
			{"id": "realm_spirit", "name": "靈界", "title": "天地靈潮 · 五行洞天", "description": "天道靈機充沛，九幽靈脈交匯。五行靈潮盛衰變換，造就洞天福地與奇花異草。", "law_summary": "靈潮汐動 · 洞天互通", "status": "locked"},
			{"id": "realm_nether", "name": "幽冥界", "title": "九幽輪迴 · 生死參悟", "description": "黃泉冥土，百代魂歸之所。參透陰陽生死，以幽冥死氣鍛造無上神魂與輪迴宿命。", "law_summary": "輪迴因果 · 魂火不滅", "status": "locked"},
			{"id": "realm_beast", "name": "萬妖界", "title": "洪荒百族 · 血脈神通", "description": "萬山荒莽，大妖咆哮於天際。修煉肉身極致，吞吐日月精華，喚醒太古洪荒血脈。", "law_summary": "肉身橫煉 · 血脈傳承", "status": "locked"},
			{"id": "realm_demon", "name": "天魔界", "title": "無相幻境 · 道心試煉", "description": "天魔無形無相，化作七情六慾。歷經萬重執念幻象，鍛造金剛不壞之無瑕道心。", "law_summary": "執念幻化 · 道心淬煉", "status": "locked"},
			{"id": "realm_immortal", "name": "仙界", "title": "純陽九霄 · 飛升仙班", "description": "九天雲海之上，仙宮巍峨，純陽之氣無窮無盡。褪盡凡胎，與天地同壽，列入真仙之班。", "law_summary": "純陽無極 · 長生久視", "status": "locked"},
			{"id": "realm_buddha", "name": "佛界", "title": "三千淨土 · 因果菩提", "description": "梵音悠遠，三千世界皆為淨土。以慈悲願力照徹十方，參破虛妄，照見本來面目。", "law_summary": "因果無礙 · 功德金身", "status": "locked"},
			{"id": "realm_chaos", "name": "混沌界", "title": "大道初分 · 鴻蒙未定", "description": "混沌未闢，乾坤未明，陰陽五行融為一體。於暴烈亂流中截取開天闢地之玄機。", "law_summary": "逆轉五行 · 混沌重鑄", "status": "locked"},
			{"id": "realm_origin", "name": "太初界", "title": "創世之源 · 虛無終極", "description": "萬法起源，歸於無極。修士神識達此境者，可撥動宇宙法則，塑造自創之全新天地。", "law_summary": "宇宙造化 · 創世神念", "status": "locked"}
		]

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
	_cinematic_label.add_theme_font_override("font", FONT)
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
	_skip_btn.add_theme_font_override("font", FONT)
	_skip_btn.add_theme_font_size_override("font_size", 16)
	_skip_btn.pressed.connect(skip_cinematic)
	_cinematic_container.add_child(_skip_btn)

	# --- Overview Panel ---
	_overview_panel = PanelContainer.new()
	_overview_panel.set_anchors_preset(Control.PRESET_CENTER)
	_overview_panel.custom_minimum_size = Vector2(1100, 620)
	_overview_panel.position = Vector2(-550, -310)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.05, 0.07, 0.96)
	panel_style.border_color = Color(0.78, 0.68, 0.38, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	_overview_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_overview_panel)

	var v_box := VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 14)
	_overview_panel.add_child(v_box)

	var header := HBoxContainer.new()
	v_box.add_child(header)

	var title_box := VBoxContainer.new()
	header.add_child(title_box)

	_title_label = Label.new()
	_title_label.text = "九界諸天 · 神識星圖"
	_title_label.add_theme_font_override("font", FONT)
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color("fce2a6"))
	title_box.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "天地有九界，法則各異。此時神識初開，可標記心儀道途，待得修為精深，方可踏破虛空。"
	_subtitle_label.add_theme_font_override("font", FONT)
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", Color("a8c8b8"))
	title_box.add_child(_subtitle_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 440)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v_box.add_child(scroll)

	_grid_container = GridContainer.new()
	_grid_container.columns = 3
	_grid_container.add_theme_constant_override("h_separation", 16)
	_grid_container.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_grid_container)

	_rebuild_realm_cards()

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_child(footer)

	_close_btn = Button.new()
	_close_btn.text = "收回神識 · 回到洞府"
	_close_btn.custom_minimum_size = Vector2(240, 46)
	_close_btn.add_theme_font_override("font", FONT)
	_close_btn.add_theme_font_size_override("font_size", 18)
	_close_btn.pressed.connect(_on_close_pressed)
	footer.add_child(_close_btn)

func _rebuild_realm_cards() -> void:
	for child in _grid_container.get_children():
		_grid_container.remove_child(child)
		child.queue_free()

	for realm in _realms_data:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(330, 130)
		var card_style := StyleBoxFlat.new()
		var is_human: bool = (realm.id == "realm_human")
		var is_aspired: bool = (realm.id == _current_aspired_realm)

		if is_human:
			card_style.bg_color = Color(0.04, 0.12, 0.11, 0.90)
			card_style.border_color = Color(0.40, 0.85, 0.65, 0.80)
		elif is_aspired:
			card_style.bg_color = Color(0.12, 0.10, 0.04, 0.90)
			card_style.border_color = Color(0.95, 0.80, 0.25, 0.90)
		else:
			card_style.bg_color = Color(0.02, 0.05, 0.07, 0.85)
			card_style.border_color = Color(0.20, 0.35, 0.40, 0.50)

		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(6)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 6)
		card.add_child(card_vbox)

		var top_row := HBoxContainer.new()
		card_vbox.add_child(top_row)

		var name_lbl := Label.new()
		name_lbl.text = realm.name
		name_lbl.add_theme_font_override("font", FONT)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color("ffd166") if is_aspired else Color("ffffff"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(name_lbl)

		var status_lbl := Label.new()
		if is_human:
			status_lbl.text = "【當前洞府】"
			status_lbl.add_theme_color_override("font_color", Color("6ee7b7"))
		elif is_aspired:
			status_lbl.text = "【心之所向】"
			status_lbl.add_theme_color_override("font_color", Color("fcd34d"))
		else:
			status_lbl.text = "【神識遠眺 · 未解鎖】"
			status_lbl.add_theme_color_override("font_color", Color("94a3b8"))
		status_lbl.add_theme_font_override("font", FONT)
		status_lbl.add_theme_font_size_override("font_size", 13)
		top_row.add_child(status_lbl)

		var law_lbl := Label.new()
		law_lbl.text = realm.title + " · " + realm.law_summary
		law_lbl.add_theme_font_override("font", FONT)
		law_lbl.add_theme_font_size_override("font_size", 13)
		law_lbl.add_theme_color_override("font_color", Color("a5b4fc"))
		card_vbox.add_child(law_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = realm.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_override("font", FONT)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color("cbd5e1"))
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(desc_lbl)

		if not is_human:
			var action_row := HBoxContainer.new()
			action_row.alignment = BoxContainer.ALIGNMENT_END
			card_vbox.add_child(action_row)

			var aspire_btn := Button.new()
			aspire_btn.text = "★ 已標記嚮往" if is_aspired else "標記嚮往"
			aspire_btn.disabled = is_aspired
			aspire_btn.add_theme_font_override("font", FONT)
			aspire_btn.add_theme_font_size_override("font_size", 13)
			aspire_btn.pressed.connect(func(): _on_aspire_pressed(realm.id))
			action_row.add_child(aspire_btn)

		_grid_container.add_child(card)

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
	_rebuild_realm_cards()
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
	_rebuild_realm_cards()
	print("NINE_REALMS_CINEMATIC_DONE")

func _on_aspire_pressed(realm_id: String) -> void:
	_current_aspired_realm = realm_id
	_rebuild_realm_cards()
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
