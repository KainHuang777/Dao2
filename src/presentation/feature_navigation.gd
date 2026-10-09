extends RefCounted
## Canonical ownership of player features. Routes share the existing Session.
const GROUPS := {
	"management": {"title": "經營", "pages": [["buildings", "洞府建築"], ["outposts", "空島"], ["manufacturing", "製造"], ["transport", "運輸"]]},
	"cultivation": {"title": "修行", "pages": [["skills", "技能"], ["alchemy", "煉丹"], ["beasts", "靈獸"], ["achievements", "成就"], ["reincarnation", "輪迴天賦"]]},
	"journey": {"title": "遊歷", "pages": [["realms", "九界"], ["sect", "宗門"], ["fortune", "機緣"], ["decisions", "天道決策"]]},
}
const PANEL_KEYS := ["alchemy_panel", "reincarnation_panel", "realm_modal", "sect_panel", "fortune_modal", "achievement_panel"]
var abode: Node
var group := "home"
var page := ""
var remembered := {"management": "buildings", "cultivation": "alchemy", "journey": "realms"}
var bar: PanelContainer
var back_button: Button
var tabs: HBoxContainer
var tab_buttons: Dictionary = {}
var action_panel: Control
var island_panel: Control
var manufacturing_panel: Control
var transport_panel: Control
var _legacy_outposts := false
var _shared_resource_count := 0
var _changing := false
var _camera_before := false
var _tab_group := ""
var _main_selected: Dictionary = {}

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
	back_button = back
	back.text = "返回洞府"
	back.custom_minimum_size = Vector2(96, 44)
	UiMaterial.apply_button(back)
	UiIcon.decorate_button(back, UiIcon.Kind.RETURN_ARROW, UiMaterial.INK, 16)
	back.pressed.connect(home)
	row.add_child(back)
	abode.hud.add_child(bar)
	bar.visible = false
	action_panel = preload("res://src/presentation/system_actions_panel.gd").new()
	action_panel.action_requested.connect(_on_action)
	abode.hud.add_child(action_panel)
	action_panel.visible = false
	island_panel = preload("res://src/presentation/island_management_panel.gd").new()
	abode.hud.add_child(island_panel)
	island_panel.visible = false
	island_panel.action_requested.connect(_on_island_action)
	island_panel.page_requested.connect(_open_island_page)
	island_panel.retry_requested.connect(_retry_island_save)
	island_panel.close_requested.connect(home)
	island_panel.world_requested.connect(func(id: String): abode.island_world.enter(id))
	island_panel.legacy_requested.connect(func():
		island_panel.visible = false
		_legacy_outposts = true
		abode.realm_modal.visible = true
		layout(abode.hud.size))
	manufacturing_panel = preload("res://src/presentation/manufacturing_panel.gd").new()
	transport_panel = preload("res://src/presentation/island_transport_panel.gd").new()
	manufacturing_panel.transport_requested.connect(open_transport)
	transport_panel.manufacturing_requested.connect(open_manufacturing)
	for panel in [manufacturing_panel, transport_panel]:
		abode.hud.add_child(panel)
		panel.visible = false
		panel.action_requested.connect(_on_island_action)
		panel.close_requested.connect(home)
		panel.page_requested.connect(_open_island_page)
		panel.retry_requested.connect(_retry_island_save)
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
	_legacy_outposts = false
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
		"outposts":
			if not abode.content.processing_catalog.is_empty():
				island_panel.visible = true
			else:
				abode.realm_modal.visible = true
		"alchemy": abode.alchemy_panel.visible = true
		"manufacturing":
			manufacturing_panel.reset_context()
			manufacturing_panel.visible = true
		"transport":
			transport_panel.reset_context()
			transport_panel.visible = true
		"achievements": abode.achievement_panel.visible = true
		"reincarnation": abode.reincarnation_panel.visible = true
		"sect": abode.sect_panel.visible = true
		"fortune": abode.fortune_modal.visible = true
		"realms": abode._modal_manager._open_nine_realms_overview()
		"beasts", "decisions", "skills":
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
	island_panel.visible = false
	manufacturing_panel.visible = false
	transport_panel.visible = false

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

func layout(vp: Vector2, view: Dictionary = {}) -> void:
	var main_buttons := [abode.island_mode_button, abode.building_catalog_button, abode.reincarnation_button, abode.overview_button]
	var ids := ["home", "management", "cultivation", "journey"]
	for i in main_buttons.size():
		var button: Button = main_buttons[i]
		button.visible = true
		button.disabled = ids[i] == group
		button.custom_minimum_size = Vector2(72 if vp.x < 640.0 else 88, 56)
		var selected: bool = ids[i] == group
		if _main_selected.get(button) != selected:
			UiMaterial.mark_selected(button, selected)
			_main_selected[button] = selected
	abode.island_mode_button.text = "洞府"
	abode.building_catalog_button.text = "經營"
	# Resize/page callers use the state-identity/revision guarded presentation View.
	# HUD refresh already owns the current View and must not rebuild it here.
	if view.is_empty():
		view = abode._presentation_view()
	_refresh_main_notifications(view)
	abode.more_menu.visible = false
	# Reapply bounds after labels/visibility invalidate the container minimum size.
	var nav_margin: float = 28.0 if abode.layout_mode == abode.HudLayout.WIDE else 16.0
	abode.toolbar.size.x = minf(480.0, vp.x - nav_margin * 2.0)
	bar.visible = group != "home"
	if group == "home":
		return
	var margin := 16.0
	var central := page in ["manufacturing", "transport"] or group != "management"
	var right_rail := not central and vp.x >= 640.0
	var width := minf(400.0, vp.x * 0.44) if right_rail else minf(820.0 if page in ["manufacturing", "transport"] else 680.0, vp.x - 2.0 * margin)
	var x := vp.x - margin - width if right_rail else (vp.x - width) * 0.5
	var manufacturing_stock := page == "manufacturing" and vp.x >= 1100.0 and vp.y >= 500.0
	if manufacturing_stock:
		var stock_width := minf(300.0, abode.header.size.x)
		width = minf(820.0, vp.x - stock_width - margin * 3.0)
		x = vp.x - margin - width
		abode.resource_ribbon.position = Vector2(margin, margin + 68.0)
		abode.resource_ribbon.size = Vector2(stock_width, maxf(80.0, abode.toolbar.position.y - margin - 76.0))
	bar.position = Vector2(x, margin)
	bar.size = Vector2(width - 56.0 if x + width > abode.settings_menu.position.x else width, 60)
	if right_rail:
		# Keep the four management tabs visible above the world safe region.
		var nav_width := minf(560.0, vp.x - abode.header.size.x - 2.0 * margin)
		bar.position.x = vp.x - margin - nav_width
		bar.size.x = nav_width - 56.0
	back_button.text = "返回" if right_rail and vp.x < 960.0 else "返回洞府"
	back_button.tooltip_text = "返回洞府"
	back_button.custom_minimum_size.x = 64 if right_rail and vp.x < 960.0 else 96
	if group == "management":
		for button in tab_buttons.values():
			button.custom_minimum_size.x = 64 if right_rail and vp.x < 960.0 else 80
		tab_buttons.buildings.text = "建築" if vp.x < 960.0 else "洞府建築"
		tab_buttons.outposts.text = "洞天" if vp.x < 960.0 else "洞天據點"
		tab_buttons.buildings.tooltip_text = "洞府建築"
		tab_buttons.outposts.tooltip_text = "洞天據點"
		if not abode.content.processing_catalog.is_empty():
			tab_buttons.outposts.text = "空島"
			tab_buttons.outposts.tooltip_text = "空島產業與靈界洞天・築基開拓首批產業島"
	var bounds := Rect2(x, margin + 68.0, width, maxf(80.0, abode.toolbar.position.y - margin - 76.0))
	if page == "buildings":
		abode.building_catalog.set_layout_bounds(bounds)
	elif page == "realms":
		abode.nine_realms_preview.set_workspace_bounds(bounds)
	else:
		var panel: Control = action_panel
		match page:
			"manufacturing": panel = manufacturing_panel
			"transport": panel = transport_panel
			"outposts": panel = abode.realm_modal if _legacy_outposts or abode.content.processing_catalog.is_empty() else island_panel
			"alchemy": panel = abode.alchemy_panel
			"achievements": panel = abode.achievement_panel
			"reincarnation": panel = abode.reincarnation_panel
			"sect": panel = abode.sect_panel
			"fortune": panel = abode.fortune_modal
		panel.set_layout_bounds(bounds)
	# Central pages temporarily replace HUD space; resource management retains its rail.
	if central:
		abode.header.visible = false
		abode.resource_ribbon.visible = manufacturing_stock
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
	if island_panel.visible:
		island_panel.expire_success()
		island_panel.refresh(view, abode.content.processing_catalog)
	for panel in [manufacturing_panel, transport_panel]:
		if panel.visible:
			panel.expire_success()
			panel.refresh(view, abode.content.processing_catalog)
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
	abode.reincarnation_button.tooltip_text = "已符合輪迴資格或有成就獎勵可領取。" if cult_notify else "技能、煉丹、靈獸、成就與輪迴天賦"
	abode.overview_button.text = ("遊歷•" if narrow else "遊歷・機緣") if fortune_pending else "遊歷"
	abode.overview_button.tooltip_text = "有待決機緣，可至「機緣」查看並選擇。" if fortune_pending else "九界、宗門、機緣與天道決策"

func _on_action(kind: String, id: String) -> void:
	if kind == "study":
		open("buildings")
		return
	var result: Dictionary
	match kind:
		"skill": result = abode.session.submit({"command_id": "skill-" + str(Time.get_ticks_usec()), "type": "learn_skill", "expected_revision": abode.session.state.revision, "payload": {"skill_id": id}})
		"acquire": result = abode.session.acquire_beast(id)
		"feed": result = abode.session.feed_beast()
		"talent": result = abode.session.unlock_beast_talent(id)
		"decision": result = abode.session.execute_realm_decision(abode.session.state.current_realm, id)
		_: return
	action_panel.show_result("操作完成，進度已更新。" if bool(result.get("ok", false)) else "操作未完成：%s" % result.get("message", result.get("error", "原因不明")))
	if bool(result.get("ok", false)):
		var saved: Dictionary = abode._save_game()
		if not saved.ok:
			action_panel.show_save_failure("操作已生效，但保存失敗：%s；恢復儲存後請重試保存。" % saved.get("error", "未知"))
	abode._refresh_hud()

func _on_island_action(kind: String, payload: Dictionary) -> void:
	var target_panel: Control = manufacturing_panel if page == "manufacturing" else transport_panel if page == "transport" else island_panel
	var result: Dictionary
	var save_failed := false
	if kind == "activate_islands":
		var now := str(int(Time.get_unix_time_from_system() * 1000.0))
		result = SaveManager.activate_islands(abode.session, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": str(int(abode.session.state.total_elapsed_seconds))})
		if result.ok:
			abode.state = abode.AbodeStateCompat.new(abode.session)
	else:
		result = abode.session.submit({"command_id": "island-" + str(Time.get_ticks_usec()), "type": kind, "expected_revision": abode.session.state.revision, "payload": payload})
		if result.ok:
			var saved: Dictionary = abode._save_game()
			if not saved.ok:
				result = saved
				save_failed = true
	var errors := {"INSUFFICIENT_RESOURCE": "加工原料或工程材料不足；請查看當地庫存、祖島靈氣與航線。", "ERA_REQUIREMENT": "築基開放青木／玄礦，金丹開放丹霞；配方另有境界條件。", "RECIPE_ISLAND_REQUIREMENT": "丹液在丹霞加工，靈材在青木、銅精在玄礦，其餘配方在祖島。", "ISLAND_NOT_OPEN": "請先開拓航線兩端島嶼。", "JOB_BUSY": "已有工作，請等本批完成後停止。", "OUTPUT_FULL": "產物滿倉；請啟動回祖島航線。"}
	errors.merge({"FACILITY_REQUIREMENT": "洞府設施未達配方門檻，請至洞府建築升級。", "ECONOMY_NOT_MIGRATED": "請至空島保留原檔並啟用。", "RESOURCE_LOCKED": "資源尚未解鎖。", "NO_JOB": "此島目前沒有加工工作。", "LEVEL_CAP": "設施已達上限。", "INVALID_COUNT": "批數不符合規則。", "INVALID_RESERVE": "原料保留量不符合規則。"})
	var error: String = String(result.get("error", "原因不明"))
	var feedback := ""
	if not result.ok:
		feedback = "操作未保存：%s。恢復儲存後重試保存。" % error if save_failed else errors.get(error, "啟用未完成：%s。原檔保留，修復後再次啟用。" % error if kind == "activate_islands" else "操作未完成：%s" % error)
	if not result.ok:
		target_panel.show_result(feedback)
	else:
		var island_name: String = IslandProgression.NAMES.get(payload.get("island_id", "home"), "祖島")
		var success := "操作完成，進度已更新。"
		match kind:
			"activate_islands": success = "空島已啟用，原檔已保留。"
			"open_island": success = island_name + "已開拓，採集已開始。"
			"upgrade_island_facility": success = island_name + IslandProgression.FACILITIES.get(payload.get("facility_id", ""), "設施") + "已升階，祖島材料已支付。"
			"craft": success = "製作已開始，原料已扣除；完成後產物入庫。"
			"switch_processing":
				var job: Dictionary = abode.session.state.economy.jobs.get(payload.get("island_id", "home"), {})
				success = "已安排本批後切換，當前加工繼續。" if job.has("pending") else "產線已切換，等待原料與倉位。"
			"stop_processing":
				success = "已安排本批後停止，當前加工繼續。" if abode.session.state.economy.jobs.has(payload.get("island_id", "home")) else "產線已停止。"
			"configure_route": success = "航線設定已保存；停航時在途貨物仍會到貨。"
		target_panel.show_success(success)
	abode._refresh_hud()

func open_manufacturing(island_id: String, recipe_id: String = "") -> void:
	open("manufacturing")
	manufacturing_panel.reset_context(island_id)
	if not recipe_id.is_empty():
		manufacturing_panel.select_recipe(recipe_id)

func _open_island_page(route: String, island_id: String) -> void:
	if route == "manufacturing":
		open_manufacturing(island_id)
	else:
		open(route)
		if route == "outposts":
			island_panel.select_island(island_id)
		elif route == "transport":
			transport_panel.select_island(island_id)

func open_transport(route_id: String) -> void:
	if not IslandEconomy.ROUTES.has(route_id):
		return
	open("transport")
	transport_panel.select_island(IslandEconomy.ROUTES[route_id][0])
	transport_panel.select_route(route_id)

func back() -> void:
	if page == "manufacturing" and not manufacturing_panel.selected_recipe.is_empty():
		manufacturing_panel.back_to_list()
	elif page == "transport" and not transport_panel.selected_route.is_empty():
		transport_panel.back_to_list()
	else:
		home()

func storage_recovered() -> void:
	for panel in [island_panel, manufacturing_panel, transport_panel]:
		panel.storage_recovered()

func _retry_island_save() -> void:
	var result: Dictionary = abode._save_game()
	if result.ok:
		storage_recovered()
