extends RefCounted
## Canonical ownership of player features. Routes share the existing Session.
const GROUPS := {
	"management": {"title": "經營", "pages": [["buildings", "洞府建築"], ["outposts", "洞天據點"]]},
	"cultivation": {"title": "修行", "pages": [["alchemy", "煉丹"], ["beasts", "靈獸"], ["achievements", "成就"], ["reincarnation", "輪迴天賦"]]},
	"journey": {"title": "遊歷", "pages": [["realms", "九界"], ["sect", "宗門"], ["fortune", "機緣"], ["decisions", "天道決策"]]},
}
const PANEL_KEYS := ["alchemy_panel", "reincarnation_panel", "realm_modal", "sect_panel", "fortune_modal", "achievement_panel"]
var abode: Node
var group := "home"
var page := ""
var remembered := {"management": "buildings", "cultivation": "alchemy", "journey": "realms"}
var bar: PanelContainer
var tabs: HBoxContainer
var tab_buttons: Dictionary = {}
var action_panel: Control
var _shared_resource_count := 0
var _changing := false
var _camera_before := false
var _tab_group := ""

func _init(scene: Node) -> void:
	abode = scene

func build() -> void:
	bar = PanelContainer.new()
	bar.name = "FeatureTabs"
	bar.add_theme_stylebox_override("panel", UiMaterial.surface("card"))
	bar.z_index = 40
	var row := HBoxContainer.new()
	bar.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	scroll.add_child(tabs)
	var back := Button.new()
	back.text = "返回洞府"
	back.custom_minimum_size = Vector2(96, 44)
	UiMaterial.apply_button(back)
	back.pressed.connect(home)
	row.add_child(back)
	abode.hud.add_child(bar)
	bar.visible = false
	action_panel = preload("res://src/presentation/system_actions_panel.gd").new()
	action_panel.action_requested.connect(_on_action)
	abode.hud.add_child(action_panel)
	action_panel.visible = false
	abode.toolbar.z_index = 45
	# Control hit testing follows tree order, not z_index: navigation stays above
	# the resource ribbon when a short landscape HUD reaches the bottom row.
	abode.hud.move_child(abode.toolbar, -1)
	abode.toolbar.move_child(abode.reincarnation_button, 2)
	abode.settings_menu.z_index = 46
	for key in PANEL_KEYS:
		abode.get(key).close_requested.connect(home)
	abode.nine_realms_preview.preview_closed.connect(_on_realms_closed)

func owner(route: String) -> String:
	for id in GROUPS:
		for entry in GROUPS[id].pages:
			if entry[0] == route:
				return id
	return ""

func open_group(id: String) -> void:
	open(String(remembered.get(id, "buildings")))

func open(route: String) -> void:
	var target := owner(route)
	if target.is_empty() or _changing:
		return
	_changing = true
	if group == "home":
		_camera_before = abode.camera.input_locked
	# Let the original overview restore its camera before replacing it.
	if abode.nine_realms_preview.visible:
		abode.nine_realms_preview._on_close_pressed()
	_hide_pages()
	group = target
	page = route
	remembered[group] = page
	abode.camera.input_locked = _camera_before or group != "management"
	abode.camera.dragging = false
	abode.camera.contacts.clear()
	abode.save_controls.visible = false
	abode.debug_panel.visible = false
	_make_tabs()
	match page:
		"buildings": abode.building_catalog.visible = true
		"outposts": abode.realm_modal.visible = true
		"alchemy": abode.alchemy_panel.visible = true
		"achievements": abode.achievement_panel.visible = true
		"reincarnation": abode.reincarnation_panel.visible = true
		"sect": abode.sect_panel.visible = true
		"fortune": abode.fortune_modal.visible = true
		"realms": abode._modal_manager._open_nine_realms_overview()
		"beasts", "decisions":
			action_panel.mode = page
			action_panel.visible = true
	_changing = false
	abode._refresh_hud()
	abode._layout_for_size(abode.hud.size)

func _hide_pages() -> void:
	abode._close_detail()
	abode.building_catalog.visible = false
	for key in PANEL_KEYS:
		abode.get(key).visible = false
	action_panel.visible = false

func home() -> void:
	if _changing or group == "home":
		return
	_changing = true
	if abode.nine_realms_preview.visible:
		abode.nine_realms_preview._on_close_pressed()
	_hide_pages()
	abode.camera.input_locked = _camera_before
	abode.camera.dragging = false
	abode.camera.contacts.clear()
	group = "home"
	page = ""
	bar.visible = false
	_changing = false
	abode._layout_for_size(abode.hud.size)

func _on_realms_closed() -> void:
	if page == "realms" and not _changing:
		home()

func _make_tabs() -> void:
	if _tab_group == group:
		for route in tab_buttons:
			tab_buttons[route].button_pressed = route == page
			UiMaterial.mark_selected(tab_buttons[route], route == page)
		return
	_tab_group = group
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	tab_buttons.clear()
	for entry in GROUPS[group].pages:
		var route: String = entry[0]
		var button := Button.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(80, 44)
		button.toggle_mode = true
		button.button_pressed = route == page
		UiMaterial.apply_button(button)
		UiMaterial.mark_selected(button, route == page)
		button.pressed.connect(func(): open(route))
		tabs.add_child(button)
		tab_buttons[route] = button

func layout(vp: Vector2) -> void:
	var main_buttons := [abode.island_mode_button, abode.building_catalog_button, abode.reincarnation_button, abode.overview_button]
	var ids := ["home", "management", "cultivation", "journey"]
	for i in main_buttons.size():
		var button: Button = main_buttons[i]
		button.visible = true
		button.disabled = ids[i] == group
		button.custom_minimum_size = Vector2(72 if vp.x < 640.0 else 88, 56)
		UiMaterial.mark_selected(button, ids[i] == group)
	abode.island_mode_button.text = "洞府"
	abode.building_catalog_button.text = "經營"
	var view: Dictionary = abode.session.get_view()
	_refresh_main_notifications(view)
	abode.more_menu.visible = false
	# Reapply bounds after labels/visibility invalidate the container minimum size.
	var nav_margin: float = 28.0 if abode.layout_mode == abode.HudLayout.WIDE else 16.0
	abode.toolbar.size.x = minf(480.0, vp.x - nav_margin * 2.0)
	bar.visible = group != "home"
	if group == "home":
		return
	var margin := 16.0
	var right_rail := group == "management" and vp.x >= 640.0
	var width := minf(400.0, vp.x * 0.44) if right_rail else minf(680.0, vp.x - 2.0 * margin)
	var x := vp.x - margin - width if right_rail else (vp.x - width) * 0.5
	bar.position = Vector2(x, margin)
	bar.size = Vector2(width - 56.0 if x + width > abode.settings_menu.position.x else width, 60)
	if group == "management":
		tab_buttons.buildings.text = "建築" if vp.x < 960.0 else "洞府建築"
		tab_buttons.outposts.text = "洞天" if vp.x < 960.0 else "洞天據點"
		tab_buttons.buildings.tooltip_text = "洞府建築"
		tab_buttons.outposts.tooltip_text = "洞天據點"
	var bounds := Rect2(x, margin + 68.0, width, maxf(80.0, abode.toolbar.position.y - margin - 76.0))
	if page == "buildings":
		abode.building_catalog.set_layout_bounds(bounds)
	elif page == "realms":
		abode.nine_realms_preview.set_workspace_bounds(bounds)
	else:
		var panel: Control = action_panel
		match page:
			"outposts": panel = abode.realm_modal
			"alchemy": panel = abode.alchemy_panel
			"achievements": panel = abode.achievement_panel
			"reincarnation": panel = abode.reincarnation_panel
			"sect": panel = abode.sect_panel
			"fortune": panel = abode.fortune_modal
		panel.set_layout_bounds(bounds)
	# Central pages temporarily replace HUD space; resource management retains its rail.
	if group != "management":
		abode.header.visible = false
		abode.resource_ribbon.visible = false
	# The building rail shares the world HUD; its message layout and user choice
	# are already handled by AbodeHudController. Other pages replace that space.
	if page != "buildings":
		abode.hint_panel.visible = false

func refresh(view: Dictionary) -> void:
	var realm: Dictionary = view.get("realm", {})
	var entries := {}
	var names := {"realm_crystal": "極品靈晶", "realm_nectar": "天青靈液", "dao_heart": "道心", "dao_proof": "道證"}
	if bool(realm.get("unlocked", false)):
		var status := "靈界庫存 · EAR1 暫停" if int(view.get("era_id", 1)) < 2 else "靈界庫存"
		entries.realm_crystal = {"value": str(realm.get("spirit_crystal", 0.0)), "cap": str(realm.get("crystal_cap", 0.0)), "visible": true, "status_text": status}
		entries.realm_nectar = {"value": str(realm.get("azure_nectar", 0.0)), "cap": str(realm.get("nectar_cap", 0.0)), "visible": true, "status_text": status}
	var beast: Dictionary = view.get("beast", {})
	if int(view.get("reincarnation_count", 0)) > 0 or String(view.get("dao_heart", "0")) != "0":
		entries.dao_heart = {"value": view.get("dao_heart", "0"), "visible": true, "uncapped": true, "status_text": "跨世保留 · 輪迴天賦"}
		entries.dao_proof = {"value": str(view.get("dao_proof", 0)), "visible": true, "uncapped": true, "status_text": "跨世保留 · 輪迴天賦"}
	for id in beast.get("souls", {}):
		if int(beast.souls[id]) > 0:
			var key := "soul_" + String(id)
			names[key] = "%s獸魂" % BeastSystem.BEAST_CONFIGS.get(id, {}).get("name", id)
			entries[key] = {"value": str(beast.souls[id]), "visible": true, "uncapped": true, "status_text": "跨世保留 · 靈獸天賦"}
	abode.building_catalog.refresh_shared_resources(entries, names)
	if entries.size() != _shared_resource_count:
		_shared_resource_count = entries.size()
		abode.call_deferred("_layout")
	abode.sect_button.visible = false
	_refresh_main_notifications(view)
	if action_panel.visible:
		action_panel.refresh(view)
	if bar.visible:
		if tab_buttons.has("reincarnation"):
			tab_buttons.reincarnation.text = "輪迴可用" if bool(view.get("reincarnation_preview", {}).get("eligible", false)) else "輪迴天賦"
		if tab_buttons.has("achievements"):
			var unclaimed := int(view.get("achievements", {}).get("unclaimed_count", 0))
			tab_buttons.achievements.text = ("成就•%d" % unclaimed) if unclaimed > 0 else "成就"
		if tab_buttons.has("fortune"):
			tab_buttons.fortune.text = "機緣待決" if bool(view.get("fortune", {}).get("has_pending", false)) else "機緣"

func _refresh_main_notifications(view: Dictionary) -> void:
	var narrow: bool = abode.hud.size.x < 640.0
	var reincarnation_ready := bool(view.get("reincarnation_preview", {}).get("eligible", false))
	var fortune_pending := bool(view.get("fortune", {}).get("has_pending", false))
	var has_unclaimed_ach := int(view.get("achievements", {}).get("unclaimed_count", 0)) > 0
	var cult_notify := reincarnation_ready or has_unclaimed_ach
	abode.reincarnation_button.text = ("修行•" if narrow else ("修行・輪迴" if reincarnation_ready else "修行・成就")) if cult_notify else "修行"
	abode.reincarnation_button.tooltip_text = "已符合輪迴資格或有成就獎勵可領取。" if cult_notify else "煉丹、靈獸、成就與輪迴天賦"
	abode.overview_button.text = ("遊歷•" if narrow else "遊歷・機緣") if fortune_pending else "遊歷"
	abode.overview_button.tooltip_text = "有待決機緣，可至「機緣」查看並選擇。" if fortune_pending else "九界、宗門、機緣與天道決策"

func _on_action(kind: String, id: String) -> void:
	var result: Dictionary
	match kind:
		"acquire": result = abode.session.acquire_beast(id)
		"feed": result = abode.session.feed_beast()
		"talent": result = abode.session.unlock_beast_talent(id)
		"decision": result = abode.session.execute_realm_decision(abode.session.state.current_realm, id)
		_: return
	action_panel.show_result("操作完成，進度已更新。" if bool(result.get("ok", false)) else "操作未完成：%s" % result.get("message", result.get("error", "原因不明")))
	if bool(result.get("ok", false)):
		abode._save_game()
	abode._refresh_hud()
