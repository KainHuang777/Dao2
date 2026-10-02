extends RefCounted
## HUD construction, responsive layout, status and guidance presentation.
## The scene facade owns public properties; callbacks stay bound to the scene.
## Node references are non-owning; no second session or persistent state is created.

var _abode: Node
var _has_guidance: bool = true
var _messages_open: bool = true
var _messages_explicit: bool = false

func _init(abode: Node) -> void:
	_abode = abode

func _configure_more_menu() -> void:
	_abode.more_menu = MenuButton.new()
	_abode.more_menu.text = "更多功能"
	_abode.more_menu.custom_minimum_size = Vector2(132, 64)
	_abode.more_menu.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.more_menu.add_theme_font_size_override("font_size", 22)
	_abode.more_menu.add_theme_color_override("font_color", Color("f4e7be"))
	_abode.more_menu.add_theme_stylebox_override("normal", _abode._style())
	_abode.more_menu.visible = true
	var popup: PopupMenu = _abode.more_menu.get_popup()
	# Legacy facade retained for older callers; no visible gameplay menu.
	popup.id_pressed.connect(_abode._on_more_menu_pressed)
	_abode.toolbar.add_child(_abode.more_menu)

func _configure_settings_menu() -> void:
	_abode.settings_menu = MenuButton.new()
	_abode.settings_menu.name = "SettingsMenu"
	_abode.settings_menu.text = ""
	_abode.settings_menu.custom_minimum_size = Vector2(44, 44)
	_abode.settings_menu.tooltip_text = "系統設定"
	_abode.settings_menu.add_theme_stylebox_override("normal", _abode._style(Color(0.012, 0.055, 0.08, 0.95)))
	_abode.settings_menu.add_theme_stylebox_override("hover", _abode._style(Color(0.05, 0.12, 0.16, 0.98)))
	_abode.settings_menu.add_theme_stylebox_override("pressed", _abode._style(Color(0.08, 0.20, 0.24, 0.99)))
	_abode.settings_menu.visible = true

	var icon_script = preload("res://src/presentation/ui_icon.gd")
	var gear_icon = icon_script.new()
	gear_icon.kind = icon_script.Kind.GEAR
	gear_icon.icon_size = 22.0
	gear_icon.tint = UiMaterial.INK
	gear_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear_icon.position = Vector2(11, 11)
	_abode.settings_menu.add_child(gear_icon)

	var popup: PopupMenu = _abode.settings_menu.get_popup()
	var bgm_text: String = "背景音樂：開" if _abode.is_bgm_enabled else "背景音樂：關"
	popup.add_item(bgm_text, 101)
	var motion_text: String = "低特效：開" if _abode.reduced_motion else "低特效：關"
	popup.add_item(motion_text, 1)
	popup.add_item("存檔管理", 2)
	popup.add_item("操作說明", 4)
	popup.add_item("重溫突破", 5)
	popup.add_item("過場文字樣板（試播）", 102)
	popup.add_item("調試工具 (DEBUG)", 8)
	popup.id_pressed.connect(_abode._on_settings_menu_pressed)
	_abode.hud.add_child(_abode.settings_menu)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	_abode.add_child(layer)

	_abode.hud = Control.new()
	_abode.hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_abode.hud.theme = UiTypography.create_theme()
	layer.add_child(_abode.hud)

	_abode.header = PanelContainer.new()
	_abode.header.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	_abode.header.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_abode.hud.add_child(_abode.header)

	_abode.header_box = VBoxContainer.new()
	_abode.header_box.add_theme_constant_override("separation", 6)
	_abode.header.add_child(_abode.header_box)

	_abode.crumb = _abode._label("人界 / 無名山域 / 你的洞府", 19, Color("c0d8cc"), 1)
	_abode.header_box.add_child(_abode.crumb)

	_abode.title_label = _abode._label("一方洞府，自有生息", 34, Color("fff0ca"), 2)
	_abode.title_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.header_box.add_child(_abode.title_label)

	_abode.realm_label = _abode._label("境界：練氣期 · 1/10 層", 20, Color("fce2a6"), 1)
	_abode.header_box.add_child(_abode.realm_label)
	_abode.realm_progress_label = _abode._label("修煉 0/60 秒 · 壽元 80/80 祀", 16, Color("d9e4d0"), 1)
	_abode.header_box.add_child(_abode.realm_progress_label)
	_abode.chrono_label = _abode._label("天時：坎水運 · 子時", 16, Color("80deea"), 1)
	_abode.header_box.add_child(_abode.chrono_label)
	for text_label in [_abode.crumb, _abode.title_label, _abode.realm_label, _abode.realm_progress_label, _abode.chrono_label]:
		text_label.add_theme_constant_override("outline_size", 0)
		text_label.add_theme_color_override("font_color", Color("393e35"))
	_abode.realm_label.add_theme_font_override("font", UiTypography.emphasis_font())

	var realm_action_box := HBoxContainer.new()
	realm_action_box.add_theme_constant_override("separation", 8)
	_abode.header_box.add_child(realm_action_box)

	_abode.level_up_button = _abode._button("修為晉階", _abode._level_up_cultivation)
	_abode.level_up_button.custom_minimum_size = Vector2(120, 44)
	_abode.level_up_button.add_theme_font_size_override("font_size", 20)
	_abode.level_up_button.visible = false
	realm_action_box.add_child(_abode.level_up_button)

	_abode.breakthrough_button = _abode._button("突破至築基期", _abode._breakthrough_era)
	_abode.breakthrough_button.custom_minimum_size = Vector2(180, 44)
	_abode.breakthrough_button.add_theme_font_size_override("font_size", 20)
	_abode.breakthrough_button.visible = false
	realm_action_box.add_child(_abode.breakthrough_button)

	var buff_bar_script = preload("res://src/presentation/buff_hud_bar.gd")
	_abode.buff_hud_bar = buff_bar_script.new()
	_abode.header_box.add_child(_abode.buff_hud_bar)

	_abode.lifespan_banner = PanelContainer.new()
	_abode.lifespan_banner.name = "LifespanBanner"
	var banner_style := UiMaterial.card("warning")
	banner_style.content_margin_left = 10
	banner_style.content_margin_right = 10
	banner_style.content_margin_top = 8
	banner_style.content_margin_bottom = 8
	_abode.lifespan_banner.add_theme_stylebox_override("panel", banner_style)
	_abode.lifespan_banner.visible = false
	_abode.header_box.add_child(_abode.lifespan_banner)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.add_theme_constant_override("separation", 6)
	_abode.lifespan_banner.add_child(banner_vbox)

	_abode.lifespan_banner_label = Label.new()
	_abode.lifespan_banner_label.text = "【壽元已盡 · 天命難違】\n肉身大期已至，天地生息已止。請速入定轉世，再塑仙身！"
	_abode.lifespan_banner_label.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.lifespan_banner_label.add_theme_font_size_override("font_size", 13)
	_abode.lifespan_banner_label.add_theme_color_override("font_color", Color("ffd180"))
	_abode.lifespan_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_vbox.add_child(_abode.lifespan_banner_label)

	_abode.lifespan_banner_button = Button.new()
	_abode.lifespan_banner_button.text = "輪迴證道"
	_abode.lifespan_banner_button.icon = load("res://assets/ui/icons/lotus.svg")
	_abode.lifespan_banner_button.custom_minimum_size = Vector2(120, 38)
	_abode.lifespan_banner_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.lifespan_banner_button.add_theme_font_size_override("font_size", 15)
	var banner_btn_style := UiMaterial.card("warning")
	_abode.lifespan_banner_button.add_theme_stylebox_override("normal", banner_btn_style)
	_abode.lifespan_banner_button.pressed.connect(_abode._toggle_reincarnation_panel)
	banner_vbox.add_child(_abode.lifespan_banner_button)

	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	_abode.header_box.add_child(resource_row)
	_abode.resource_label = _abode._label("", 17, Color("e4f0dc"), 1)
	_abode.resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.add_child(_abode.resource_label)
	_abode.mini_gather_button = Button.new()
	_abode.mini_gather_button.custom_minimum_size = Vector2(82, 48)
	_abode.mini_gather_button.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.mini_gather_button.add_theme_font_size_override("font_size", 16)
	_abode.mini_gather_button.pressed.connect(func(): _abode._gather_resource(_abode.mini_resource_id))
	resource_row.add_child(_abode.mini_gather_button)
	resource_row.visible = false
	_abode.objective_button = Button.new()
	_abode.objective_button.custom_minimum_size.y = 48
	_abode.objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_abode.objective_button.add_theme_font_override("font", UiTypography.body_font())
	_abode.objective_button.add_theme_font_size_override("font_size", 16)
	_abode.objective_button.pressed.connect(_abode._toggle_guidance)
	_abode.header_box.add_child(_abode.objective_button)
	UiMaterial.apply_button(_abode.objective_button)
	UiMaterial.apply_button(_abode.level_up_button, "primary")
	UiMaterial.apply_button(_abode.breakthrough_button, "primary")

	_abode.viewbar = HBoxContainer.new()
	_abode.viewbar.name = "Viewbar"
	_abode.viewbar.add_theme_constant_override("separation", 8)
	_abode.hud.add_child(_abode.viewbar)

	_abode.viewbar.add_child(_abode._view_button("＋", func(): _abode.camera.change_zoom(1.25), 58))
	_abode.viewbar.add_child(_abode._view_button("－", func(): _abode.camera.change_zoom(0.8), 58))
	_abode.viewbar.add_child(_abode._view_button("歸家", _abode._return_home, 104))

	_abode.zoom_label = _abode._label("", 19, Color("e4e7c8"), 1)
	_abode.viewbar.add_child(_abode.zoom_label)

	_abode.toolbar = HBoxContainer.new()
	_abode.toolbar.add_theme_constant_override("separation", 12)
	_abode.hud.add_child(_abode.toolbar)

	_abode.island_mode_button = _abode._button("空島", _abode._close_building_catalog)
	_abode.toolbar.add_child(_abode.island_mode_button)
	_abode.building_catalog_button = _abode._button("營造", _abode._open_building_catalog)
	_abode.toolbar.add_child(_abode.building_catalog_button)

	_abode.overview_button = _abode._button("遊歷", func(): _abode.feature_navigation.open_group("journey"))
	_abode.toolbar.add_child(_abode.overview_button)

	_abode.motion_button = _abode._button("低特效", _abode._toggle_motion)
	_abode.toolbar.add_child(_abode.motion_button)

	_abode.save_button = _abode._button("存檔管理", _abode._toggle_save_controls)
	_abode.toolbar.add_child(_abode.save_button)

	_abode.replay_breakthrough_button = _abode._button("重溫突破", _abode._replay_breakthrough)
	_abode.replay_breakthrough_button.visible = false
	_abode.toolbar.add_child(_abode.replay_breakthrough_button)

	_abode.nine_realms_button = _abode._button("九界星圖", _abode._open_nine_realms_overview)
	_abode.toolbar.add_child(_abode.nine_realms_button)

	_abode.reincarnation_button = _abode._button("修行", func(): _abode.feature_navigation.open_group("cultivation"))
	_abode.toolbar.add_child(_abode.reincarnation_button)

	_abode.alchemy_button = _abode._button("煉丹房", _abode._toggle_alchemy_panel)
	_abode.toolbar.add_child(_abode.alchemy_button)

	_abode.sect_button = _abode._button("宗門外務", _abode._toggle_sect_panel)
	_abode.toolbar.add_child(_abode.sect_button)

	_abode.help_button = _abode._button("操作說明", _abode._show_help)
	_abode.toolbar.add_child(_abode.help_button)

	_abode._configure_more_menu()
	_abode._configure_settings_menu()
	UiMaterial.apply_button(_abode.settings_menu)
	UiMaterial.apply_button(_abode.island_mode_button, "plaque", true)
	UiMaterial.apply_button(_abode.building_catalog_button, "plaque", true)
	UiMaterial.apply_button(_abode.overview_button)
	UiMaterial.apply_button(_abode.more_menu)

	_abode.hint_panel = PanelContainer.new()
	var hint_style: StyleBoxTexture = _abode._style(Color(0.008, 0.035, 0.05, 0.88))
	hint_style.content_margin_left = 14
	hint_style.content_margin_right = 14
	hint_style.content_margin_top = 8
	hint_style.content_margin_bottom = 8
	_abode.hint_panel.add_theme_stylebox_override("panel", hint_style)
	_abode.hud.add_child(_abode.hint_panel)
	var hint_box := VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 4)
	hint_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_abode.hint_panel.add_child(hint_box)

	var hint_title_row := HBoxContainer.new()
	hint_title_row.add_theme_constant_override("separation", 6)
	hint_box.add_child(hint_title_row)

	_abode.hint_heading = _abode._label("系統訊息", 17, Color("f1d58d"), 0)
	_abode.hint_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_title_row.add_child(_abode.hint_heading)

	_abode.hint_expand_button = Button.new()
	_abode.hint_expand_button.text = "展開"
	_abode.hint_expand_button.custom_minimum_size = Vector2(64, 44)
	_abode.hint_expand_button.add_theme_font_size_override("font_size", 14)
	_abode.hint_expand_button.pressed.connect(_abode._toggle_hint_expand)
	hint_title_row.add_child(_abode.hint_expand_button)

	var hint_close := Button.new()
	hint_close.text = "收起"
	hint_close.custom_minimum_size = Vector2(56, 44)
	hint_close.add_theme_font_size_override("font_size", 14)
	hint_close.pressed.connect(_abode._toggle_guidance)
	hint_title_row.add_child(hint_close)

	_abode.hint_scroll = ScrollContainer.new()
	_abode.hint_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.hint_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_abode.hint_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hint_box.add_child(_abode.hint_scroll)

	_abode.hint_log_label = RichTextLabel.new()
	_abode.hint_log_label.bbcode_enabled = true
	_abode.hint_log_label.fit_content = true
	_abode.hint_log_label.scroll_active = false
	_abode.hint_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.hint_log_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_abode.hint_log_label.add_theme_font_override("normal_font", UiTypography.body_font())
	_abode.hint_log_label.add_theme_font_size_override("normal_font_size", 17)
	_abode.hint_log_label.add_theme_constant_override("line_separation", 6)
	_abode.hint_scroll.add_child(_abode.hint_log_label)

	_abode.hint = _abode._label("", 17, Color("f2e8c7"), 1)
	_abode.hint.visible = false
	hint_box.add_child(_abode.hint)
	_abode.hint_panel.visible = true

	_abode.footer = _abode._label("自動存檔運轉中", 18, Color("ffffff"), 0)
	var footer_style := UiMaterial.card("normal")
	footer_style.content_margin_left = 8
	footer_style.content_margin_right = 8
	_abode.footer.add_theme_stylebox_override("normal", footer_style)
	_abode.footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_abode.hud.add_child(_abode.footer)

	_abode.info_panel = PanelContainer.new()
	_abode.info_panel.add_theme_stylebox_override("panel", _abode._style(Color(0.008, 0.045, 0.07, 0.98)))
	_abode.info_panel.visible = false
	_abode.hud.add_child(_abode.info_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_abode.info_panel.add_child(box)

	var title_row := HBoxContainer.new()
	box.add_child(title_row)

	_abode.detail_title = _abode._label("", 28, Color("fff0c8"), 2)
	_abode.detail_title.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_abode.detail_title)
	title_row.add_child(_abode._button("收起", _abode._close_detail))

	_abode.detail_body = _abode._label("", 21, Color("eaf2ea"), 1)
	_abode.detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abode.detail_scroll = ScrollContainer.new()
	_abode.detail_scroll.custom_minimum_size = Vector2.ZERO
	_abode.detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_abode.detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_abode.detail_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	_abode.detail_scroll.add_child(detail_content)
	detail_content.add_child(_abode.detail_body)

	_abode.detail_actions = HFlowContainer.new()
	_abode.detail_actions.add_theme_constant_override("h_separation", 10)
	_abode.detail_actions.add_theme_constant_override("v_separation", 10)
	detail_content.add_child(_abode.detail_actions)

	_abode.gather_button = _abode._button("聚氣引靈", _abode._gather_lingli)
	_abode.detail_actions.add_child(_abode.gather_button)

	_abode.upgrade_button = _abode._button("", _abode._upgrade_selected)
	_abode.upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.detail_actions.add_child(_abode.upgrade_button)

	_abode.pause_button = _abode._button("暫停藥圃", _abode._toggle_garden)
	_abode.detail_actions.add_child(_abode.pause_button)

	_abode.building_catalog = _abode.BuildingCatalogScript.new()
	_abode.building_catalog.visible = false
	_abode.hud.add_child(_abode.building_catalog)
	_abode.building_catalog.call("configure_resources", _abode.RESOURCE_NAMES, _abode.RESOURCE_NAMES.keys())
	_abode.building_catalog.hud_paper_resources = true
	_abode.building_catalog.call("configure", _abode._catalog_groups())
	_abode.resource_ribbon = PanelContainer.new()
	var ribbon_style: StyleBoxTexture = UiMaterial.hud_paper()
	ribbon_style.content_margin_left = 8
	ribbon_style.content_margin_right = 8
	ribbon_style.content_margin_top = 6
	ribbon_style.content_margin_bottom = 6
	_abode.resource_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	_abode.hud.add_child(_abode.resource_ribbon)
	_abode.resource_ribbon_box = VBoxContainer.new()
	_abode.resource_ribbon_box.add_theme_constant_override("separation", 4)
	_abode.resource_ribbon.add_child(_abode.resource_ribbon_box)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 4)
	_abode.resource_ribbon_box.add_child(mode_row)
	for mode_name in ["關閉", "數量", "完整"]:
		var mode_button := Button.new()
		mode_button.text = mode_name
		mode_button.toggle_mode = true
		mode_button.custom_minimum_size.y = 44
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.add_theme_font_override("font", UiTypography.body_font())
		mode_button.add_theme_font_size_override("font_size", 15)
		mode_button.pressed.connect(_abode._set_resource_display_mode.bind(_abode.resource_mode_buttons.size()))
		mode_row.add_child(mode_button)
		_abode.resource_mode_buttons.append(mode_button)
	_abode.resource_scroll = ScrollContainer.new()
	_abode.resource_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.resource_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_abode.resource_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abode.resource_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_abode.resource_ribbon_box.add_child(_abode.resource_scroll)
	_abode.building_catalog.resource_grid.reparent(_abode.resource_scroll)
	_abode.building_catalog.resource_grid.columns = 1
	_abode.building_catalog.resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode._set_resource_display_mode(1)
	_abode.action_bar = HBoxContainer.new()
	_abode.action_bar.add_theme_constant_override("separation", 6)
	_abode.hud.add_child(_abode.action_bar)
	_abode.mini_gather_button.reparent(_abode.action_bar)
	_abode.mini_gather_button.custom_minimum_size = Vector2(112, 48)
	_abode.gather_menu = MenuButton.new()
	_abode.gather_menu.text = "選擇採集"
	_abode.gather_menu.custom_minimum_size = Vector2(104, 48)
	_abode.gather_menu.add_theme_font_override("font", UiTypography.emphasis_font())
	_abode.gather_menu.add_theme_font_size_override("font_size", 16)
	_abode.gather_menu.get_popup().id_pressed.connect(_abode._on_gather_resource_selected)
	_abode.action_bar.add_child(_abode.gather_menu)
	_abode.info_panel.reparent(_abode.building_catalog.detail_slot)
	_abode.info_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_abode.info_panel.custom_minimum_size = Vector2.ZERO
	_abode.info_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_abode.building_catalog.building_selected.connect(_abode._select_building_from_catalog)
	_abode.building_catalog.building_upgrade_requested.connect(_abode._upgrade_building_from_catalog)
	if _abode.building_catalog.has_signal("close_requested"):
		_abode.building_catalog.connect("close_requested", Callable(_abode, "_close_building_catalog"))
	if _abode.building_catalog.has_signal("gather_resource_requested"):
		_abode.building_catalog.connect("gather_resource_requested", Callable(_abode, "_gather_resource"))
	_abode.building_catalog.guidance_requested.connect(_abode._toggle_guidance)

	_abode._modal_manager.create_panels()
	_abode.feature_navigation = preload("res://src/presentation/feature_navigation.gd").new(_abode)
	_abode.feature_navigation.build()

	var prompt_script = preload("res://src/presentation/orientation_prompt.gd")
	_abode.orientation_prompt = prompt_script.new()
	_abode.orientation_prompt.z_index = 100
	_abode.hud.add_child(_abode.orientation_prompt)

	_abode.header.resized.connect(_abode._reflow_header)

func _layout_for_size(vp: Vector2) -> void:
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	if _abode.orientation_prompt != null:
		_abode.orientation_prompt.update_layout(vp)
	_abode.hud.position = Vector2.ZERO
	_abode.hud.size = vp
	_abode.sky.position = Vector2.ZERO
	_abode.sky.size = vp
	var viewport_aspect := vp.x / vp.y
	_abode.sky_material.set_shader_parameter("viewport_aspect", viewport_aspect)
	var background_focal_x := lerpf(0.39, 0.5, smoothstep(0.75, 1.65, viewport_aspect))
	_abode.sky_material.set_shader_parameter("background_focal_x", background_focal_x)
	_abode.shade.size = vp

	var ratio: float = vp.x / vp.y
	if vp.x >= 960.0 and ratio >= 1.45 and vp.y >= 500.0:
		_abode.layout_mode = _abode.HudLayout.WIDE
	elif vp.x < 640.0 or ratio < 1.25:
		_abode.layout_mode = _abode.HudLayout.PORTRAIT
	else:
		_abode.layout_mode = _abode.HudLayout.COMPACT

	var margin: float = 28.0 if _abode.layout_mode == _abode.HudLayout.WIDE else 16.0
	var portrait: bool = _abode.layout_mode == _abode.HudLayout.PORTRAIT
	var compact: bool = _abode.layout_mode != _abode.HudLayout.WIDE
	_abode.toolbar.visible = true
	_abode._apply_hud_density(compact, portrait)
	_abode.header.position = Vector2(margin, margin)
	_abode.header.size.x = (vp.x - margin * 2.0 - 52.0) if portrait else minf(320.0, vp.x * 0.38)
	_abode.toolbar.position = Vector2(margin, vp.y - margin - 56.0)
	_abode.toolbar.size = Vector2(vp.x - margin * 2.0 if portrait else minf(480.0, vp.x - margin * 2.0), 56)
	if _abode.building_catalog.visible and not portrait:
		_abode.toolbar.position.x = vp.x - margin - _abode.toolbar.size.x
	if _abode.settings_menu != null:
		_abode.settings_menu.size = Vector2(44, 44)
		_abode.settings_menu.position = Vector2(vp.x - margin - 44.0, margin)
	_abode.viewbar.size = Vector2(220, 48)
	_abode.footer.visible = false
	_abode.action_bar.visible = false
	_abode.action_bar.position = Vector2(margin, _abode.toolbar.position.y - 56.0)
	_abode.action_bar.size = Vector2(vp.x - margin * 2.0 if portrait else 232.0, 48.0)

	_abode._reflow_header()
	_abode._layout_overlay_panels(vp, margin, portrait)
	print("ABODE_LAYOUT mode=", _abode._layout_mode_name(), " size=", vp.round())

func _apply_hud_density(compact: bool, portrait: bool) -> void:
	var short_compact: bool = _abode.layout_mode == _abode.HudLayout.COMPACT and _abode.hud.size.y < 500.0
	_abode.crumb.visible = false
	_abode.title_label.visible = false
	_abode.objective_button.visible = _has_guidance and not (_abode.building_catalog.visible or short_compact)
	_abode.resource_label.visible = false
	_abode.resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abode.resource_label.custom_minimum_size = Vector2.ZERO
	_abode.realm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abode.realm_label.custom_minimum_size = Vector2.ZERO
	_abode.realm_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abode.realm_progress_label.custom_minimum_size = Vector2.ZERO
	_abode.header_box.custom_minimum_size = Vector2.ZERO
	_abode.resource_label.add_theme_font_size_override("font_size", 16)
	_abode.toolbar.add_theme_constant_override("separation", 4 if portrait else 8)
	_abode.island_mode_button.custom_minimum_size = Vector2(72 if portrait else 96, 56)
	_abode.building_catalog_button.custom_minimum_size = Vector2(72 if portrait else 96, 56)
	_abode.overview_button.custom_minimum_size = Vector2(80 if portrait else 116, 56)
	_abode.more_menu.custom_minimum_size = Vector2(80 if portrait else 116, 56)
	_abode.building_catalog_button.text = "營造"
	_abode.island_mode_button.text = "空島"
	_abode.island_mode_button.disabled = not _abode.building_catalog.visible
	_abode.building_catalog_button.disabled = _abode.building_catalog.visible
	_abode.more_menu.text = ("★ 更多" if portrait else "★ 更多功能") if _abode.more_menu.text.begins_with("★") else ("更多" if portrait else "更多功能")
	_abode.building_catalog_button.add_theme_font_size_override("font_size", 18)
	_abode.island_mode_button.add_theme_font_size_override("font_size", 18)
	_abode.overview_button.add_theme_font_size_override("font_size", 18)
	_abode.more_menu.add_theme_font_size_override("font_size", 18)
	_abode.reincarnation_button.custom_minimum_size.x = 104 if portrait else 132
	_abode.reincarnation_button.add_theme_font_size_override("font_size", 18 if portrait else 22)
	_abode.realm_label.add_theme_font_size_override("font_size", 20 if not compact else 18)
	_abode.realm_progress_label.add_theme_font_size_override("font_size", 16)
	if "chrono_label" in _abode and _abode.chrono_label != null:
		_abode.chrono_label.add_theme_font_size_override("font_size", 15 if not compact else 13)
	_abode.detail_title.add_theme_font_size_override("font_size", 22)
	_abode.detail_body.add_theme_font_size_override("font_size", 16)
	_abode.more_menu.visible = true
	if _abode.settings_menu != null:
		_abode.settings_menu.visible = true
	_abode.motion_button.visible = false
	_abode.save_button.visible = false
	_abode.nine_realms_button.visible = false
	_abode.reincarnation_button.visible = false
	_abode.alchemy_button.visible = false
	if _abode.sect_button != null:
		_abode.sect_button.visible = false
	_abode.help_button.visible = false
	_abode.replay_breakthrough_button.visible = false

func _reflow_header() -> void:
	var base_height: float = 88.0 if _abode.layout_mode == _abode.HudLayout.WIDE else 80.0
	var needed: float = maxf(_abode.header.get_combined_minimum_size().y, _abode.header_box.get_combined_minimum_size().y + 28.0)
	_abode.header.size.y = maxf(base_height, needed)
	_abode.viewbar.position = Vector2(_abode.header.position.x, _abode.header.position.y + _abode.header.size.y + 8.0)
	_abode.viewbar.visible = false
	_abode._reflow_resource_ribbon()
	if _abode.building_catalog != null and _abode.building_catalog.visible and _abode.layout_mode == _abode.HudLayout.PORTRAIT and _abode.hud != null:
		_abode._layout_overlay_panels(_abode.hud.size, (28.0 if _abode.layout_mode == _abode.HudLayout.WIDE else 16.0), true)

func _reflow_resource_ribbon() -> void:
	if _abode.resource_ribbon == null or _abode.building_catalog == null or _abode.hud == null:
		return
	var vp: Vector2 = _abode.hud.size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var portrait: bool = _abode.layout_mode == _abode.HudLayout.PORTRAIT
	var margin: float = 28.0 if _abode.layout_mode == _abode.HudLayout.WIDE else 16.0
	_abode.building_catalog.resource_grid.columns = 1
	_abode.building_catalog.resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abode.resource_ribbon.position = Vector2(margin, _abode.header.position.y + _abode.header.size.y + 8.0)
	var resource_width: float = vp.x - margin * 2.0 if portrait else _abode.header.size.x
	var resource_bottom: float = _abode.toolbar.position.y - 8.0
	var resource_available: float = maxf(44.0, resource_bottom - _abode.resource_ribbon.position.y)
	var visible_count: int = 0
	for resource_id in _abode.building_catalog.resource_order:
		if bool(_abode.building_catalog._last_resources.get(resource_id, {}).get("visible", false)):
			visible_count += 1
	var wanted_height: float = 56.0
	if _abode.resource_display_mode != 0 and visible_count > 0:
		var card_h: float = 38.0 if _abode.resource_display_mode == 1 else 56.0
		var v_sep: float = 6.0
		var grid_content_height: float = float(visible_count) * card_h + float(maxi(0, visible_count - 1)) * v_sep
		# 6 (top margin) + 44 (mode_row) + 4 (separation) + grid_content_height + 6 (bottom margin) + 2 (subpixel buffer)
		wanted_height = 62.0 + grid_content_height
	var portrait_max: float = 132.0 if _abode.building_catalog.visible else minf(resource_available, 280.0)
	var max_resource_height: float = minf(resource_available, portrait_max if portrait else resource_available)
	_abode.resource_ribbon.size = Vector2(resource_width, minf(wanted_height, max_resource_height))
	_abode.resource_scroll.visible = _abode.resource_display_mode != 0

func _set_resource_display_mode(mode: int) -> void:
	_abode.resource_display_mode = clampi(mode, 0, 2)
	for index in _abode.resource_mode_buttons.size():
		_abode.resource_mode_buttons[index].button_pressed = index == _abode.resource_display_mode
		UiMaterial.mark_paper_tab(_abode.resource_mode_buttons[index], index == _abode.resource_display_mode)
	if _abode.building_catalog != null:
		_abode.building_catalog.set_resource_display_mode(_abode.resource_display_mode)
	if _abode.resource_scroll != null:
		_abode.resource_scroll.visible = _abode.resource_display_mode != 0
	if _abode.hud != null and _abode.hud.size.x > 0.0:
		_abode._layout_for_size(_abode.hud.size)

func _layout_overlay_panels(vp: Vector2, margin: float, portrait: bool) -> void:
	var management: bool = _abode.building_catalog != null and _abode.building_catalog.visible
	var detail_focus: bool = management and portrait and vp.y < 560.0 and _abode.info_panel.visible
	_abode.header.visible = not detail_focus
	_abode.resource_ribbon.visible = not detail_focus
	_abode.viewbar.visible = _abode.viewbar.visible and not management
	_abode.footer.visible = false
	if management:
		var rail_width: float = vp.x - margin * 2.0 if portrait else minf(400.0, vp.x * 0.44)
		var rail_top: float = margin if detail_focus else (_abode.resource_ribbon.position.y + _abode.resource_ribbon.size.y + 8.0 if portrait else margin)
		var rail_bottom: float = _abode.action_bar.position.y - 8.0 if portrait and _abode.action_bar.visible else _abode.toolbar.position.y - 8.0
		if portrait and rail_bottom - rail_top < 104.0:
			_abode.resource_ribbon.size.y = 56.0
			_abode.resource_scroll.visible = false
			rail_top = _abode.resource_ribbon.position.y + _abode.resource_ribbon.size.y + 8.0
		_abode.building_catalog.call("set_short_mode", vp.y < 560.0)
		_abode.building_catalog.call("set_layout_bounds", Rect2(margin if portrait else vp.x - margin - rail_width, rail_top, rail_width, maxf(72.0, rail_bottom - rail_top)))
	# Retain the user's open/closed choice while a short management drawer needs the space.
	var short_management := management and vp.y < 500.0
	_abode.hint_panel.visible = _messages_open and not portrait and (not short_management or _messages_explicit)
	if _abode.hint_panel.visible:
		var left_limit: float = _abode.header.get_global_rect().end.x + 12.0
		var right_limit: float = _abode.building_catalog.position.x - 12.0 if management else vp.x - margin
		if short_management:
			left_limit = margin
			right_limit = vp.x - margin
		var hint_width: float = minf(540.0, right_limit - left_limit)
		var hint_h: float = minf(300.0 if _abode._hint_expanded else 220.0, vp.y * 0.48)
		var hint_x: float = left_limit + (right_limit - left_limit - hint_width) * 0.5
		var bottom_anchor: float = (_abode.action_bar.position.y if _abode.action_bar.visible else _abode.toolbar.position.y)
		var hint_y: float = bottom_anchor - hint_h - 6.0
		_abode.hint_panel.size = Vector2(hint_width, hint_h)
		_abode.hint_panel.position = Vector2(hint_x, hint_y)

	_abode._modal_manager.layout_panels(vp, margin, portrait)
	if _abode.feature_navigation != null:
		_abode.feature_navigation.layout(vp)

func _layout_mode_name() -> String:
	match _abode.layout_mode:
		_abode.HudLayout.WIDE:
			return "wide"
		_abode.HudLayout.COMPACT:
			return "compact"
		_:
			return "portrait"

func _refresh_hud() -> void:
	var view: Dictionary = _abode.session.get_view()
	_abode._update_buildings_visual(view)

	var era_info: Dictionary = view.get("era", {})
	var era_name: String = era_info.get("name", "練氣")
	var cur_level: int = int(view.get("level", 1))
	var train_sec: float = float(view.get("training_seconds", 0.0))
	var req_sec: float = float(view.get("next_level_required_seconds", 0.0))
	var max_life: float = float(view.get("max_lifespan_seconds", 0.0))
	var elapsed_sec: float = float(view.get("total_elapsed_seconds", 0.0))
	var remain_life: float = maxf(0.0, max_life - elapsed_sec)

	var can_lvl: bool = bool(view.get("can_level_up", false))
	var can_bt: bool = bool(view.get("can_breakthrough", false))
	var is_max_lvl: bool = cur_level >= int(era_info.get("max_level", 10))

	var is_wide_screen: bool = _abode.layout_mode == _abode.HudLayout.WIDE and _abode.header.size.x >= 350.0
	var badge_sep: String = "\u00A0" if is_wide_screen else "\n"

	if can_bt:
		_abode.realm_label.text = "境界：%s · %d/%d 層%s【★\u00A0可突破】" % [era_name, cur_level, int(era_info.get("max_level", 10)), badge_sep]
		_abode.realm_label.add_theme_color_override("font_color", Color("805321"))
		_abode.realm_progress_label.text = "修煉大圓滿 · 靈氣飽和可破境 · 壽元 %.0f/%.0f 祀" % [remain_life / 60.0, max_life / 60.0]
		_abode.realm_progress_label.add_theme_color_override("font_color", Color("805321"))
	elif is_max_lvl:
		_abode.realm_label.text = "境界：%s · %d/%d 層%s（圓滿）" % [era_name, cur_level, int(era_info.get("max_level", 10)), badge_sep]
		_abode.realm_label.add_theme_color_override("font_color", Color("343d34"))
		_abode.realm_progress_label.text = "修煉圓滿（需擴充靈氣容量以突破）· 壽元 %.0f/%.0f 祀" % [remain_life / 60.0, max_life / 60.0]
		_abode.realm_progress_label.add_theme_color_override("font_color", Color("555a4c"))
	elif can_lvl:
		_abode.realm_label.text = "境界：%s · %d/%d 層%s【★\u00A0可晉階】" % [era_name, cur_level, int(era_info.get("max_level", 10)), badge_sep]
		_abode.realm_label.add_theme_color_override("font_color", Color("285c45"))
		_abode.realm_progress_label.text = "修煉滿階 %.0f/%.0f 秒 · 壽元 %.0f/%.0f 祀" % [train_sec, req_sec, remain_life / 60.0, max_life / 60.0]
		_abode.realm_progress_label.add_theme_color_override("font_color", Color("285c45"))
	else:
		_abode.realm_label.text = "境界：%s · %d/%d 層" % [era_name, cur_level, int(era_info.get("max_level", 10))]
		_abode.realm_label.add_theme_color_override("font_color", Color("343d34"))
		_abode.realm_progress_label.text = "修煉 %.0f/%.0f 秒 · 壽元 %.0f/%.0f 祀" % [
			train_sec, req_sec, remain_life / 60.0, max_life / 60.0
		]
		_abode.realm_progress_label.add_theme_color_override("font_color", Color("555a4c"))

	if "chrono_label" in _abode and _abode.chrono_label != null and view.has("chrono"):
		var chrono_info: Dictionary = view["chrono"]
		var sc_info: Dictionary = chrono_info.get("shichen", {})
		var wt_info: Dictionary = chrono_info.get("weather", {})
		var sc_name: String = String(sc_info.get("name", "子時"))
		var wt_name: String = String(wt_info.get("name", "坎水運"))
		var wt_color: String = String(wt_info.get("color", "#80deea"))
		_abode.chrono_label.text = "天時：%s · %s" % [wt_name, sc_name]
		_abode.chrono_label.tooltip_text = "%s\n%s" % [String(wt_info.get("desc", "")), String(sc_info.get("desc", ""))]
		_abode.chrono_label.add_theme_color_override("font_color", Color(wt_color).darkened(0.55))

	_abode.level_up_button.visible = can_lvl
	if can_lvl:
		var cost_dict: Dictionary = view.get("level_up_costs", {})
		var cost_strs := []
		for r_id in cost_dict:
			var req_val: float = _abode._parse_amount(cost_dict[r_id]).to_float()
			cost_strs.append("%d %s" % [int(req_val), _abode.RESOURCE_NAMES.get(r_id, r_id)])
		_abode.level_up_button.text = "修為晉階（消耗 %s）" % (" · ".join(cost_strs) if cost_strs.size() > 0 else "功滿")

	var cur_era: int = int(view.get("era_id", 1))
	_abode.breakthrough_button.visible = (cur_level >= 10 and cur_era == 1)
	if _abode.breakthrough_button.visible:
		_abode.breakthrough_button.disabled = not can_bt
		if can_bt:
			_abode.breakthrough_button.text = "★ 突破至築基期 ★"
		else:
			var req_caps: Dictionary = view.get("breakthrough_requirements", {})
			var req_lingli: int = int(req_caps.get("lingli", 500))
			var cur_cap: int = int(_abode._parse_amount(view.resources.get("lingli", {}).get("cap", 0)).to_float())
			_abode.breakthrough_button.text = "突破需靈氣容量 %d（當前 %d）" % [req_lingli, cur_cap]

	_abode.replay_breakthrough_button.visible = false
	_abode.settings_menu.get_popup().set_item_disabled(_abode.settings_menu.get_popup().get_item_index(5), cur_era < 2)

	var rc_eligible: bool = false
	var is_lifespan_exhausted: bool = false
	if view.has("reincarnation_preview"):
		rc_eligible = bool(view.reincarnation_preview.get("eligible", false))
		is_lifespan_exhausted = (String(view.reincarnation_preview.get("reason", "")) == "lifespan_exhausted")

	if _abode.lifespan_banner != null:
		var was_visible: bool = _abode.lifespan_banner.visible
		_abode.lifespan_banner.visible = is_lifespan_exhausted
		if was_visible != is_lifespan_exhausted:
			_abode._reflow_header()

	if _abode.reincarnation_panel != null and _abode.reincarnation_panel.visible:
		_abode.reincarnation_panel.call("refresh", view)
	if _abode.fortune_modal != null and _abode.fortune_modal.visible:
		_abode.fortune_modal.call("refresh", view)
	var f_info: Dictionary = view.get("fortune", {})
	var has_pending_fortune: bool = bool(f_info.get("has_pending", false))
	var fortune_popup_idx: int = _abode.more_menu.get_popup().get_item_index(11)
	if fortune_popup_idx >= 0:
		_abode.more_menu.get_popup().set_item_text(fortune_popup_idx, "★ 機緣奇遇" if has_pending_fortune else "機緣奇遇")
	if _abode.alchemy_panel != null and _abode.alchemy_panel.visible:
		_abode.alchemy_panel.call("update_view", view)
	if _abode.buff_hud_bar != null:
		_abode.buff_hud_bar.update_buffs(view.get("buffs", []))
	if _abode.realm_modal != null and _abode.realm_modal.visible:
		_abode.realm_modal.call("refresh", view)
	if _abode.sect_panel != null and _abode.sect_panel.visible and _abode.session != null and _abode.session.state != null:
		_abode.sect_panel.call("update_view", _abode.session.state)
	if _abode.sect_button != null and _abode.session != null and _abode.session.state != null:
		_abode.sect_button.visible = false

	if _abode.spirit_realm_region_label != null and _abode.session != null and _abode.session.state != null:
		if RealmSystem.is_spirit_realm_unlocked(_abode.session.state):
			_abode.spirit_realm_region_label.text = "靈界方向 · 【跨界神遊】"
			_abode.spirit_realm_region_label.add_theme_color_override("font_color", Color("ffd700"))
		else:
			_abode.spirit_realm_region_label.text = "靈界方向 · 未開放"
			_abode.spirit_realm_region_label.add_theme_color_override("font_color", Color("d1dfd1"))

	var cur_realm := String(view.get("realm", {}).get("current_realm", "realm_human"))
	if cur_realm == "realm_spirit":
		_abode.crumb.text = "靈界 / 天靈洞天 / 靈潮聚所"
		_abode.shade.color = Color(0.06, 0.03, 0.15, 0.28)
		_abode.home_marker.text = "天靈洞天 · 靈潮汐動 純靈長存"
	elif cur_era >= 2:
		_abode.crumb.text = "人界 / 無名山域 / 你的洞府"
		_abode.shade.color = Color(0.04, 0.08, 0.16, 0.22)
		_abode.home_marker.text = "你的洞府 · 築基功成 祥雲瑞靄"
	else:
		_abode.crumb.text = "人界 / 無名山域 / 你的洞府"
		_abode.shade.color = Color(0.015, 0.085, 0.13, 0.24)
		_abode.home_marker.text = "你的洞府 · 靈氣生生不息"
	_abode.island_fx.set_attained(cur_era >= 2)


	var res_lines := []
	var res_order := ["lingli", "money", "wood", "stone_low", "black_copper", "spirit_grass_low", "foundation_pill"]
	for r_id in res_order:
		if view.resources.has(r_id) and bool(view.resources[r_id].visible):
			var r_data: Dictionary = view.resources[r_id]
			var val: float = _abode._parse_amount(r_data.value).to_float()
			var cap: float = _abode._parse_amount(r_data.cap).to_float()
			var rate: float = _abode._parse_amount(r_data.rate).to_float()
			var r_name: String = _abode.RESOURCE_NAMES.get(r_id, r_id)
			var rate_str := (" · +%.2f/s" % rate) if rate > 0.0 else ""
			res_lines.append("%s %.2f/%d%s" % [r_name, val, int(cap), rate_str])

	_abode.mini_resource_id = "lingli"
	var objective_value: Variant = view.get("next_objective", null)
	_has_guidance = objective_value is Dictionary
	var short_compact: bool = _abode.layout_mode == _abode.HudLayout.COMPACT and _abode.hud.size.y < 500.0
	_abode.objective_button.visible = _has_guidance and not (_abode.building_catalog.visible or short_compact)
	if objective_value is Dictionary:
		var next_building: Dictionary = view.get("buildings", {}).get(String(objective_value.get("id", "")), {})
		for cost_id in next_building.get("costs", {}):
			var candidate: Dictionary = view.resources.get(cost_id, {})
			if int(view.era_id) == 1 and bool(candidate.get("unlocked", false)) and String(candidate.get("type", "")) == "basic" and _abode._parse_amount(candidate.get("value", "0")).compare_to(_abode._parse_amount(next_building.costs[cost_id])) < 0:
				_abode.mini_resource_id = String(cost_id)
				break
	var mini_entry: Dictionary = view.resources.get(_abode.mini_resource_id, {})
	var mini_current: float = _abode._parse_amount(mini_entry.get("value", "0")).to_float()
	var mini_cap: float = _abode._parse_amount(mini_entry.get("cap", "0")).to_float()
	var mini_rate: float = _abode._parse_amount(mini_entry.get("rate", "0")).to_float()
	_abode.resource_label.text = "%s %.2f/%.0f" % [_abode.RESOURCE_NAMES.get(_abode.mini_resource_id, _abode.mini_resource_id), mini_current, mini_cap]
	if mini_rate > 0.0:
		_abode.resource_label.text += " · +%.2f/s" % mini_rate
	_abode.mini_gather_button.visible = int(view.era_id) == 1 and bool(mini_entry.get("unlocked", false)) and String(mini_entry.get("type", "")) == "basic"
	_abode.mini_gather_button.disabled = mini_current >= mini_cap
	_abode.gather_resource_ids.clear()
	var gather_popup: PopupMenu = _abode.gather_menu.get_popup()
	gather_popup.clear()
	for r_id in res_order:
		var entry: Dictionary = view.resources.get(r_id, {})
		if int(view.era_id) == 1 and bool(entry.get("unlocked", false)) and String(entry.get("type", "")) == "basic":
			_abode.gather_resource_ids.append(r_id)
			gather_popup.add_item(String(_abode.RESOURCE_NAMES.get(r_id, r_id)), _abode.gather_resource_ids.size() - 1)
	if not _abode.gather_resource_ids.has(_abode.selected_gather_id):
		_abode.selected_gather_id = _abode.mini_resource_id
	_abode.mini_resource_id = _abode.selected_gather_id
	mini_entry = view.resources.get(_abode.mini_resource_id, {})
	mini_current = _abode._parse_amount(mini_entry.get("value", "0")).to_float()
	mini_cap = _abode._parse_amount(mini_entry.get("cap", "0")).to_float()
	_abode.mini_gather_button.visible = false
	_abode.mini_gather_button.disabled = mini_current >= mini_cap
	_abode.mini_gather_button.text = "採集%s +1" % _abode.RESOURCE_NAMES.get(_abode.mini_resource_id, _abode.mini_resource_id)
	_abode.gather_menu.visible = false
	_abode.action_bar.visible = false
	_abode.building_catalog.call("refresh", view.buildings, view.resources, int(view.era_id))
	var visible_resource_count: int = 0
	for entry in view.resources.values():
		if bool(entry.get("visible", false)):
			visible_resource_count += 1
	if visible_resource_count != _abode.last_visible_resource_count:
		_abode.last_visible_resource_count = visible_resource_count
		_abode.call_deferred("_layout")
	_abode._update_onboarding_guidance(view)
	if _abode._message_history.is_empty():
		_push_hint_log(_abode.hint.text)
	var objective_text := ""
	if objective_value is Dictionary:
		var objective_id: String = String(objective_value.get("id", ""))
		var target_level: int = 1
		for milestone in Onboarding.MILESTONES:
			if String(milestone.building) == objective_id:
				target_level = int(milestone.level)
				break
		objective_text = "下一步：將%s升至 %d 階" % [_abode.BUILDING_NAMES.get(objective_id, "營造設施"), target_level]
	_abode.objective_button.text = objective_text
	_abode.objective_button.tooltip_text = _abode.hint.text
	_abode.building_catalog.call("set_context", _abode.realm_label.text, objective_text)
	_abode._reflow_header()

	_abode.zoom_label.text = "%d%%" % int(_abode.camera.zoom.x * 100)
	_abode.region_visible = _abode.camera.target_zoom < 0.34
	_abode.overview_button.text = ("歸家" if _abode.region_visible else "神識") if _abode.layout_mode == _abode.HudLayout.PORTRAIT else ("回到洞府" if _abode.region_visible else "神識展開")
	_abode.crumb.text = "人界 / 山域總覽 · 遠景尚未開放" if _abode.region_visible else "人界 / 無名山域 / 你的洞府"
	_abode.title_label.text = "群山之間，認得自己的燈火" if _abode.region_visible else "一方洞府，自有生息"

	if _abode.selected_id != "" and _abode.info_panel.visible:
		_abode._refresh_detail()

	if _abode.feature_navigation != null:
		_abode.feature_navigation.refresh(view)
		_abode.feature_navigation.layout(_abode.hud.size)

func _update_onboarding_guidance(view: Dictionary) -> void:
	var objective_value: Variant = view.get("next_objective", null)
	if objective_value == null:
		var done_key := "complete:%d" % int(view.get("era_id", 1))
		if done_key == _abode.last_guidance_key:
			return
		_abode.last_guidance_key = done_key
		_abode.hint_heading.text = "系統訊息 · 新手引導"
		_abode.hint.text = "入門建築引導已完成。可在「營造設施」查看資源庫存、每秒產率與後續設施需求。"
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
		var current: AmountCompat = _abode._parse_amount(resource.get("value", "0"))
		var required: AmountCompat = _abode._parse_amount(costs[resource_id])
		if current.compare_to(required) < 0:
			missing.append(String(resource_id))
			if int(view.get("era_id", 1)) == 1 and bool(resource.get("unlocked", false)) and String(resource.get("type", "")) == "basic":
				gatherable_missing.append(String(resource_id))

	missing.sort()
	var state_key := "ready" if missing.is_empty() else "need:" + ",".join(missing)
	var guidance_key := "%s:%s" % [building_id, state_key]
	if guidance_key == _abode.last_guidance_key:
		return
	_abode.last_guidance_key = guidance_key
	_abode.hint_heading.text = "系統訊息 · 新手引導"
	var building_name: String = _abode.BUILDING_NAMES.get(building_id, building_id)
	var level: int = int(building.get("level", 0))
	var action: String = "建造" if level == 0 else "升級"
	if building_id == "hut" and "lingli" in missing and "lingli" in gatherable_missing:
		_abode.hint.text = "初入道途，先使用空島下方的「採集靈氣」動作；累積足夠後在營造簿建造茅屋。茅屋啟動後會逐秒產生靈氣。"
	elif building_id == "wooden_house" and "money" in missing and "money" in gatherable_missing:
		_abode.hint.text = "茅屋已立，接下來需要第一筆金錢。請在空島下方選擇採集金錢，足額後於營造簿建造木屋以啟動金錢產線。"
	elif missing.is_empty():
		_abode.hint.text = "下一步：資源已足，前往「營造設施」選擇【%s】並%s。完成後再依清單提示推進下一段建築流程。" % [building_name, action]
	else:
		var missing_names: Array[String] = []
		for resource_id in missing:
			missing_names.append(String(_abode.RESOURCE_NAMES.get(resource_id, resource_id)))
		var gather_text := "可手動採集已解鎖項目；其他需求等待現有產線入庫。" if not gatherable_missing.is_empty() else "請等待已建產線入庫。"
		_abode.hint.text = "下一步：前往「營造設施」%s【%s】。尚缺：%s。%s" % [action, building_name, "、".join(missing_names), gather_text]

func _refresh_detail() -> void:
	var view: Dictionary = _abode.session.get_view()
	var b_id: String = _abode.selected_id
	if not view.buildings.has(b_id):
		return

	var b_data: Dictionary = view.buildings[b_id]
	var b_name: String = _abode.BUILDING_NAMES.get(b_id, b_id)
	var cur_lvl: int = int(b_data.level)
	var lvl_cap: int = int(b_data.level_cap)

	_abode.detail_title.text = "%s · %s" % [b_name, "未建造" if cur_lvl == 0 else str(cur_lvl) + "階"]
	_abode.detail_body.text = _abode.BUILDING_DESCRIPTIONS.get(b_id, "")

	_abode.gather_button.visible = (b_id == "hut" and int(view.era_id) == 1)

	if cur_lvl >= lvl_cap:
		_abode.upgrade_button.text = "已達當前上限"
		_abode.upgrade_button.disabled = true
	else:
		var cost_strs := []
		for r_id in b_data.costs:
			var req_val: float = _abode._parse_amount(b_data.costs[r_id]).to_float()
			var r_name: String = _abode.RESOURCE_NAMES.get(r_id, r_id)
			cost_strs.append("%d %s" % [int(req_val), r_name])
		var cost_text := " · ".join(cost_strs)
		_abode.upgrade_button.text = ("建造 · %s" if cur_lvl == 0 else "升級 · %s") % cost_text
		_abode.upgrade_button.disabled = not bool(b_data.affordable)
		if cur_lvl == 0 and b_data.prereq != null:
			var prereq_id := String(b_data.prereq.building)
			var prereq_level := int(b_data.prereq.level)
			if int(view.buildings.get(prereq_id, {}).get("level", 0)) < prereq_level:
				_abode.upgrade_button.text = "需先將%s升至 %d 階" % [_abode.BUILDING_NAMES.get(prereq_id, prereq_id), prereq_level]

	_abode.pause_button.visible = (b_id == "herb_farm")
	_abode.pause_button.text = "恢復藥圃" if not _abode.state.garden_running else "暫停藥圃"

func _show_help() -> void:
	_abode.hint_heading.text = "操作說明"
	_abode.hint.text = "滑鼠拖曳／單指平移；滾輪／雙指縮放。\n營造設施可建造與升級；M 展開山域，Home 歸家。"
	_messages_open = true
	_messages_explicit = true
	_abode._layout_for_size(_abode.hud.size)

func _toggle_guidance() -> void:
	_messages_open = not _abode.hint_panel.visible
	_messages_explicit = _messages_open
	_abode._layout_for_size(_abode.hud.size)

func show_messages() -> void:
	_messages_open = true
	_messages_explicit = true
	_abode._layout_for_size(_abode.hud.size)

func _toggle_hint_expand() -> void:
	_abode._hint_expanded = not _abode._hint_expanded
	if _abode.hint_expand_button != null:
		_abode.hint_expand_button.text = "縮小" if _abode._hint_expanded else "展開"
	_abode._layout_for_size(_abode.hud.size)
	if _abode.hint_scroll != null:
		_abode.hint_scroll.call_deferred("set_v_scroll", 999999)

func _push_hint_log(msg: String) -> void:
	var clean_msg: String = msg.strip_edges()
	if clean_msg.is_empty():
		return
	if _abode._message_history.is_empty() or _abode._message_history.back() != clean_msg:
		_abode._message_history.append(clean_msg)
		if _abode._message_history.size() > 50:
			_abode._message_history.pop_front()
		_abode._rebuild_hint_log_display()

func _rebuild_hint_log_display() -> void:
	if _abode.hint_log_label == null:
		return
	var lines := []
	for entry in _abode._message_history:
		var col: String = "e8e1d2"
		if entry.contains("受阻") or entry.contains("不足"):
			col = "e4aea0"
		elif entry.contains("突破") or entry.contains("大圓滿"):
			col = "dfc38a"
		elif entry.contains("建造") or entry.contains("升級"):
			col = "b8cec1"
		elif entry.contains("煉製") or entry.contains("靈丹"):
			col = "c7cbd5"
		elif entry.contains("採集") or entry.contains("採伐"):
			col = "b8cec1"
		elif entry.contains("[DEBUG]"):
			col = "dfc38a"
		lines.append("[color=#%s]%s[/color]" % [col, entry])
	_abode.hint_log_label.text = "\n".join(lines)
	if _abode.hint_scroll != null:
		_abode.hint_scroll.call_deferred("set_v_scroll", 999999)
