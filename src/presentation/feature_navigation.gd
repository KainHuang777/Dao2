extends RefCounted
## Canonical ownership of player features. Routes share the existing Session.
const ShellPolicy = preload("res://src/presentation/ui_shell_policy.gd")
const GROUPS := ShellPolicy.GROUPS
const PANEL_KEYS := ["alchemy_panel", "reincarnation_panel", "realm_modal", "sect_panel", "fortune_modal", "achievement_panel"]
## Page presentation policy; costs and command eligibility remain in Session.
const PAGE_POLICY := {
	"decisions": {"workspace": "large", "resources": "inline", "max_width": 1120.0},
	"fortune": {"workspace": "large", "resources": "inline", "max_width": 1120.0},
	"sect": {"workspace": "large", "resources": "inline", "max_width": 1120.0},
	"skills": {"workspace": "large", "resources": "inline", "max_width": 1120.0},
	"buildings": {"workspace": "rail", "resources": "shared"},
	"outposts": {"workspace": "rail", "resources": "shared"},
	"manufacturing": {"workspace": "large", "resources": "wide_stock"},
	"transport": {"workspace": "large", "resources": "inline"},
	"alchemy": {"workspace": "large", "resources": "hud_stock"},
	"achievements": {"workspace": "large", "resources": "inline", "max_width": 1120.0},
}
const DEFAULT_POLICY := {"workspace": "central", "resources": "inline"}
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
var _home_resource_mode := 0
var _tab_signature := ""
var shell: RefCounted

func _init(scene: Node) -> void:
	abode = scene

func build() -> void:
	bar = PanelContainer.new()
	bar.name = "FeatureTabs"
	var tab_shell := UiMaterial.compact_scroll_shell()
	tab_shell.content_margin_top = 8
	tab_shell.content_margin_bottom = 8
	bar.add_theme_stylebox_override("panel", tab_shell)
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
	var back := CloseSeal.new()
	back_button = back
	back.tooltip_text = "返回洞府"
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
	shell = preload("res://src/presentation/ui_shell_controller.gd").new(abode)
	shell.build()

func owner(route: String) -> String:
	return ShellPolicy.owner(route)

func open_group(id: String) -> void:
	if not GROUPS.has(id):
		return
	var view: Dictionary = abode._presentation_view()
	var route := String(remembered.get(id, ""))
	if FeatureUnlocks.check(route, view).state == FeatureUnlocks.State.HIDDEN:
		route = ""
		for entry in GROUPS[id].pages:
			if FeatureUnlocks.check(entry[0], view).state == FeatureUnlocks.State.AVAILABLE:
				route = entry[0]
				break
		for entry in GROUPS[id].pages:
			if route.is_empty() and FeatureUnlocks.check(entry[0], view).state != FeatureUnlocks.State.HIDDEN:
				route = entry[0]
				break
	open(route)

func open(route: String) -> void:
	# Contextual links must obey the same early island discovery gate.
	if route in ["outposts", "manufacturing", "transport"] and abode.session.state.era_id < 2:
		open("buildings")
		return
	var target := owner(route)
	if target.is_empty() or _changing:
		return
	if shell != null:
		if not shell.navigate(route):
			return
		route = shell.state.snapshot().route
		target = owner(route)
	if route == "home":
		home()
		return
	_changing = true
	if group == "home":
		_camera_before = abode.camera.input_locked
		_home_resource_mode = abode.resource_display_mode
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
				if not IslandProgression.active(abode.session.state) or (island_panel.island == "home" and not bool(abode.session.state.economy.get("islands", {}).get("wood", {}).get("opened", false))):
					island_panel.select_island("wood")
			else:
				abode.realm_modal.visible = true
		"alchemy":
			abode.alchemy_panel.visible = true
		"manufacturing":
			manufacturing_panel.visible = true
		"transport":
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
	if shell != null and not shell.navigate("home"):
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
	_changing = false
	if shell != null:
		abode._set_resource_display_mode(int(shell.state.snapshot().home_preferences.resource_mode))
	abode._layout_for_size(abode.hud.size)

func _on_realms_closed() -> void:
	if page == "realms" and not _changing:
		home()

func _make_tabs() -> void:
	if _tab_group == group:
		for route in tab_buttons:
			tab_buttons[route].button_pressed = route == page
			if tab_buttons[route].get_meta("selected", false) != (route == page):
				tab_buttons[route]._update_style()
				tab_buttons[route].set_meta("selected", route == page)
		return
	_tab_group = group
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	tab_buttons.clear()
	for entry in GROUPS[group].pages:
		var route: String = entry[0]
		var button := GameTab.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(80, 44)
		button.toggle_mode = true
		button.button_pressed = route == page
		button._update_style()
		button.set_meta("selected", route == page)
		button.pressed.connect(func(): open(route))
		tabs.add_child(button)
		tab_buttons[route] = button
	_tab_signature = ""
	_refresh_tabs(abode._presentation_view())

func _refresh_tabs(view: Dictionary) -> void:
	if group == "home":
		return
	var signature := group + ":" + page + ":" + str(view.get("achievements", {}).get("unclaimed_count", 0)) + ":" + str(view.get("fortune", {}).get("has_pending", false)) + ":" + str(view.get("reincarnation_preview", {}).get("eligible", false))
	for route in tab_buttons:
		var availability := FeatureUnlocks.check(route, view)
		signature += ":%s:%s:%s" % [route, availability.state, availability.reason]
	if signature == _tab_signature:
		return
	_tab_signature = signature
	for route in tab_buttons:
		var availability := FeatureUnlocks.check(route, view)
		var button: Button = tab_buttons[route]
		var label := ""
		for entry in GROUPS[group].pages:
			if entry[0] == route:
				label = entry[1]
		if group != "management":
			for entry in GROUPS[group].pages:
				if entry[0] == route:
					label = entry[1]
			if availability.state == FeatureUnlocks.State.AVAILABLE:
				if route == "achievements" and int(view.get("achievements", {}).get("unclaimed_count", 0)) > 0:
					label = "成就•%d" % int(view.achievements.unclaimed_count)
				elif route == "fortune" and bool(view.get("fortune", {}).get("has_pending", false)):
					label = "機緣待決"
				elif route == "reincarnation" and bool(view.get("reincarnation_preview", {}).get("eligible", false)):
					label = "輪迴可用"
		# Explicit contextual links may still open existing read-only previews.
		# Hiding a tab is discovery policy, never a replacement for core gates.
		button.visible = availability.state != FeatureUnlocks.State.HIDDEN or route == page
		button.modulate = Color(0.72, 0.72, 0.72) if availability.state == FeatureUnlocks.State.PREVIEW else Color.WHITE
		button.tooltip_text = ""
		button.set_meta("availability", availability.state)
		button.text = label + ("·未開" if availability.state == FeatureUnlocks.State.PREVIEW else "")
	# Stable partition: keep the canonical order inside each availability group.
	# Reuse buttons so unlock refreshes preserve input connections and page state.
	var index := 0
	for state in [FeatureUnlocks.State.AVAILABLE, FeatureUnlocks.State.PREVIEW, FeatureUnlocks.State.HIDDEN]:
		for entry in GROUPS[group].pages:
			var button: Button = tab_buttons[entry[0]]
			if button.get_meta("availability") == state:
				if button.get_index() != index:
					tabs.move_child(button, index)
				index += 1

static func presentation_policy(route: String, vp: Vector2) -> Dictionary:
	var policy: Dictionary = PAGE_POLICY.get(route, DEFAULT_POLICY)
	return {
		"central": policy.workspace != "rail",
		"large": policy.workspace == "large",
		"max_width": policy.get("max_width", 820.0 if policy.workspace == "large" else 680.0),
		"wide_stock": policy.resources == "wide_stock" and vp.x >= 1100.0 and vp.y >= 500.0,
		"hud_stock": policy.resources == "hud_stock" and vp.x >= vp.y,
	}

func layout(vp: Vector2, view: Dictionary = {}) -> void:
	var main_buttons := [abode.island_mode_button, abode.building_catalog_button, abode.reincarnation_button, abode.overview_button]
	var ids := ["home", "management", "cultivation", "journey"]
	for i in main_buttons.size():
		var button: Button = main_buttons[i]
		button.visible = true
		button.disabled = ids[i] == group
		button.set_pressed_no_signal(ids[i] == group)
		button.custom_minimum_size = Vector2(72 if vp.x < 640.0 else 88, 56)
		var selected: bool = ids[i] == group
		if _main_selected.get(button) != selected:
			UiMaterial.apply_jade_navigation(button, selected)
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
	if shell != null and shell.managed():
		if group != "home": _refresh_tabs(view)
		shell.apply(vp)
		return

static func building_workspace_width(vp: Vector2, show_messages: bool = false) -> float:
	if vp.y < 500.0:
		return vp.x - 32.0
	if show_messages and vp.y >= 500.0:
		return minf(400.0, vp.x * 0.44)
	return minf(620.0, vp.x - 280.0)

func refresh(view: Dictionary) -> void:
	if shell != null and shell.state.snapshot().overlay.is_empty() and group != "home":
		var legal := ShellPolicy.legal_route(page, view)
		if legal != page:
			if legal == "home": home()
			else: open(legal)
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
	_refresh_tabs(view)
	if is_instance_valid(action_panel) and action_panel.visible:
		action_panel.refresh(view)
	if is_instance_valid(island_panel) and island_panel.visible:
		island_panel.expire_success()
		island_panel.refresh(view, abode.content.processing_catalog)
	for panel in [manufacturing_panel, transport_panel]:
		if is_instance_valid(panel) and panel.visible:
			panel.expire_success()
			panel.refresh(view, abode.content.processing_catalog)

func _refresh_main_notifications(view: Dictionary) -> void:
	var flags := FeatureUnlocks.notification_flags(view, abode.session.state.sect)
	var cultivation: Array[String] = []
	var journey: Array[String] = []
	if flags.reincarnation:
		cultivation.append("輪迴可用")
	if flags.achievements:
		cultivation.append("成就待領")
	if flags.beasts:
		cultivation.append("靈獸可餵養")
	if flags.fortune:
		journey.append("機緣待決")
	if flags.sect:
		journey.append("宗門任務待領")
	abode.reincarnation_button.text = "修行"
	abode.reincarnation_button.set_red_dot(not cultivation.is_empty())
	abode.reincarnation_button.tooltip_text = "／".join(cultivation) + "；前往修行查看。" if not cultivation.is_empty() else "技能、煉丹、靈獸、成就與輪迴天賦"
	abode.overview_button.text = "遊歷"
	abode.overview_button.set_red_dot(not journey.is_empty())
	abode.overview_button.tooltip_text = "／".join(journey) + "；前往遊歷查看。" if not journey.is_empty() else "九界、宗門、機緣與天道決策"

func _on_action(kind: String, id: String) -> void:
	if kind == "retry_save":
		var retry: Dictionary = abode._save_game()
		if retry.ok:
			action_panel.storage_recovered()
		else:
			action_panel.show_save_failure("保存仍失敗；恢復儲存後請重試保存。")
		return
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
	if kind == "decision" and bool(result.get("ok", false)):
		for event in result.get("events", []):
			if event.get("kind", "") == "realm_decision_executed":
				action_panel.show_result(str(event.get("log_text", "法令已施行。")))
	if bool(result.get("ok", false)):
		var saved: Dictionary = abode._save_game()
		if not saved.ok:
			action_panel.show_save_failure("操作已生效，但保存失敗：%s；恢復儲存後請重試保存。" % saved.get("error", "未知"))
	abode._refresh_hud()

func _on_island_action(kind: String, payload: Dictionary) -> void:
	var target_panel: Control = manufacturing_panel if page == "manufacturing" else transport_panel if page == "transport" else island_panel
	var result: Dictionary
	var save_failed := false
	var first_open: bool = kind == "open_island" and not IslandProgression.active(abode.session.state)
	if kind == "activate_islands" or first_open:
		var now := str(int(Time.get_unix_time_from_system() * 1000.0))
		result = SaveManager.activate_islands(abode.session, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": str(int(abode.session.state.total_elapsed_seconds))}, String(payload.get("island_id", "")) if first_open else "")
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
		if first_open:
			feedback = "開拓未完成：%s。原檔與材料保留，可再次按開拓重試。" % errors.get(error, error)
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
	if page != "manufacturing" or not shell.state.snapshot().overlay.is_empty(): return
	manufacturing_panel.reset_context(island_id)
	if not recipe_id.is_empty():
		manufacturing_panel.select_recipe(recipe_id)

func _open_island_page(route: String, island_id: String) -> void:
	if route == "manufacturing":
		open_manufacturing(island_id)
	else:
		open(route)
		if page != route or not shell.state.snapshot().overlay.is_empty(): return
		if route == "outposts":
			island_panel.select_island(island_id)
		elif route == "transport":
			transport_panel.select_island(island_id)

func open_transport(route_id: String) -> void:
	if not transport_panel._routes().has(route_id):
		return
	open("transport")
	if page != "transport" or not shell.state.snapshot().overlay.is_empty(): return
	transport_panel.select_island(transport_panel._routes()[route_id][0])
	transport_panel.select_route(route_id)

func back() -> void:
	if shell != null and shell.managed() and shell.back():
		return
	if page == "reincarnation" and abode.reincarnation_panel._confirming:
		abode.reincarnation_panel._cancel_confirmation()
	elif abode.info_panel.visible:
		abode._close_detail()
	elif page == "manufacturing" and not manufacturing_panel.selected_recipe.is_empty():
		manufacturing_panel.back_to_list()
	elif page == "transport" and not transport_panel.selected_route.is_empty():
		transport_panel.back_to_list()
	else:
		home()

func layout_page(bounds: Rect2) -> void:
	if page == "buildings":
		abode.building_catalog.set_short_mode(bounds.size.y < 400)
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

func storage_recovered() -> void:
	for panel in [island_panel, manufacturing_panel, transport_panel]:
		panel.storage_recovered()

func _retry_island_save() -> void:
	var result: Dictionary = abode._save_game()
	if result.ok:
		storage_recovered()
