extends SceneTree
## UI commands use isolated diagnostic clones; normal reachability remains in D2.
var checks := 0
var failures: Array[String] = []
var abode: Node
var base: GameState
var serial := 0

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var reject_write := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		if reject_write:
			return {"ok": false, "error": "injected UI1 quota"}
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _init() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
func snapshot() -> String:
	return JSON.stringify(SaveCodec._normalize_numbers(abode.session.state.to_snapshot_dict()), "", true)
func reset() -> void:
	abode.session.state = base.duplicate_state()
	abode._refresh_hud()
func send(kind: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return abode.session.submit({"command_id": "ui1b-test-" + str(serial), "type": kind, "expected_revision": abode.session.state.revision, "payload": payload})
func reject(kind: String, payload: Dictionary, reason: String) -> void:
	var before := snapshot()
	var result := send(kind, payload)
	check(not result.ok and result.error == reason, "atomic refusal " + reason)
	check(snapshot() == before, "refusal leaves inventory/jobs unchanged " + reason)

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://res1_ui1b_runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned fixture decodes")
	base = decoded.state.duplicate_state()
	base.economy.jobs = {}
	base.economy.routes = {}
	base.economy.trips = {}
	# Fund diagnostic success cases, clearly distinct from command-earned progression.
	for id in abode.content.processing_catalog.resources:
		ProcessingInventory.write(base, id, AmountCompat.from_number(1000 if id in IslandEconomy.GLOBAL else 100))
		base.resources[id].unlocked = true
	for id in ["wood", "ore", "herb"]:
		base.economy.islands[id].opened = true
		for resource in abode.content.processing_catalog.resources:
			if not resource in IslandEconomy.GLOBAL:
				base.economy.islands[id].inventory[resource] = "50"
	var adapter := MemoryAdapter.new()
	SaveManager.configure(abode.content, adapter)
	reset()
	var nav = abode.feature_navigation
	var panel = nav.transport_panel
	nav.open("transport")
	check(panel.route_widgets.size() == 7 and panel.selected_route.is_empty(), "seven rows without an expanded editor")
	for id in IslandEconomy.ROUTES:
		var def: Array = IslandEconomy.ROUTES[id]
		var visual: Dictionary = panel.route_widgets[id].visual
		check(visual.source.icon.resource_id == def[2] and visual.destination.icon.resource_id == def[2], "both ends show exact cargo icon " + id)
		check(visual.source.caption.text == IslandProgression.NAMES[def[0]] and visual.destination.caption.text == IslandProgression.NAMES[def[1]], "tile captions identify endpoints " + id)
		check(visual.destination.quantity.text != "" and not panel.route_widgets[id].progress.visible, "stock quantity and idle progress " + id)
	for id in IslandEconomy.ROUTES:
		reset()
		nav.open("transport")
		var widget: Dictionary = panel.route_widgets[id]
		widget.toggle.pressed.emit()
		var route: Dictionary = abode.session.state.economy.routes[id]
		check(route.enabled and route.reserve == "0" and route.target == "100" and route.level == 1, "first toggle uses existing defaults " + id)
		widget.settings.pressed.emit()
		check(panel.selected_route == id and panel.detail_box.visible and not panel.list_box.visible, "exact settings workspace " + id)
		edit(panel.reserve, "5.125")
		edit(panel.target, "83.75")
		for refresh_index in 4:
			abode._refresh_hud()
		check(panel.reserve.text == "5.125" and panel.target.text == "83.75", "refresh preserves decimal draft " + id)
		nav.back()
		check(nav.page == "transport" and panel.selected_route.is_empty() and panel.draft_notice.visible, "back explicitly retains draft " + id)
		nav.open("outposts")
		nav.open("transport")
		panel.select_route(id)
		check(panel.reserve.text == "5.125" and panel.target.text == "83.75", "page reopen retains draft " + id)
		panel.save_button.pressed.emit()
		route = abode.session.state.economy.routes[id]
		check(route.reserve == "5.125" and route.target == "83.75" and route.enabled and not panel.drafts[id].dirty, "save commits policy without changing enabled " + id)
		edit(panel.reserve, "9")
		widget.toggle.pressed.emit()
		route = abode.session.state.economy.routes[id]
		check(not route.enabled and route.reserve == "5.125" and panel.reserve.text == "9", "stop ignores but retains draft " + id)
		var timber := IslandEconomy.value(abode.session.state, "home", "spirit_timber")
		var bronze := IslandEconomy.value(abode.session.state, "home", "bronze_essence")
		panel.upgrade_button.pressed.emit()
		route = abode.session.state.economy.routes[id]
		check(route.level == 2 and not route.enabled and route.reserve == "5.125" and panel.reserve.text == "9", "upgrade preserves stop/committed policy/draft " + id)
		check(IslandEconomy.value(abode.session.state, "home", "spirit_timber") == timber - 2 and IslandEconomy.value(abode.session.state, "home", "bronze_essence") == bronze - 2, "upgrade charges home once " + id)
		widget.toggle.pressed.emit()
		check(abode.session.state.economy.routes[id].enabled and abode.session.state.economy.routes[id].reserve == "5.125", "restart uses committed custom policy " + id)
		# Real rule ticks, actual cargo, stop + restart + upgrade never clone the trip.
		reset()
		panel.drafts.clear()
		var def: Array = IslandEconomy.ROUTES[id]
		IslandEconomy._put(abode.session.state, def[1], def[2], 0)
		nav.open("transport")
		widget.toggle.pressed.emit()
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
		var trip: Dictionary = abode.session.state.economy.trips[id].duplicate(true)
		abode._refresh_hud()
		widget.toggle.pressed.emit()
		panel.select_route(id)
		panel.upgrade_button.pressed.emit()
		check(abode.session.state.economy.trips[id] == trip and not abode.session.state.economy.routes[id].enabled, "stop + upgrade leaves current cargo/timer intact " + id)
		check(panel.detail_status.text.contains("當趟仍會到貨"), "stopped in-flight explanation " + id)
		check(panel.detail_progress.visible and panel.detail_progress.value == (10 - int(trip.remaining)) * 10, "detail shows actual trip progress " + id)
		check(panel.route_widgets[id].progress.visible and panel.detail_toggle.text == "啟航", "stopped trip retains inline meter and detail restart " + id)
		widget.toggle.pressed.emit()
		check(abode.session.state.economy.trips[id] == trip, "restart does not duplicate current cargo " + id)
		widget.toggle.pressed.emit()
		for tick in int(trip.remaining):
			IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
		check(not abode.session.state.economy.trips.has(id) and IslandEconomy.value(abode.session.state, def[1], def[2]) >= float(trip.cargo), "stopped route delivers once and never redispatches " + id)
	# Pure views produce precise reasons and capacity evidence.
	reset()
	panel.drafts.clear()
	send("configure_route", {"route_id": "timber_home", "enabled": true})
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", 0)
	IslandEconomy._put(abode.session.state, "wood", "spirit_timber", 0)
	check(abode.session.get_view().transport.timber_home.reason == "NO_SURPLUS", "source has no surplus")
	abode._refresh_hud()
	check(panel.route_widgets.timber_home.visual.source.shortage and panel.route_widgets.timber_home.visual.source.quantity.text == "0", "empty source turns red without changing zero stock")
	IslandEconomy._put(abode.session.state, "wood", "spirit_timber", 50)
	abode._refresh_hud()
	check(not panel.route_widgets.timber_home.visual.source.shortage and panel.route_widgets.timber_home.visual.source.quantity.text == "50", "source warning recovers with actual stock")
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", 100)
	check(abode.session.get_view().transport.timber_home.reason == "TARGET_REACHED", "destination target reached")
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", float(abode.content.processing_catalog.resources.spirit_timber.cap))
	check(abode.session.get_view().transport.timber_home.reason == "DESTINATION_FULL", "destination actually full")
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", 0)
	check(abode.session.get_view().transport.timber_home.reason == "READY" and not abode.session.get_view().transport.timber_home.loaded_backlog, "empty trip is normal and not a capacity claim")
	IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(abode.session.get_view().transport.timber_home.loaded_backlog, "full real load with surplus and demand supports capacity hint")
	abode.session.state.economy.trips.timber_home.cargo = "3"
	check(not abode.session.get_view().transport.timber_home.loaded_backlog, "partial load does not imply capacity bottleneck")
	send("configure_route", {"route_id": "timber_home", "enabled": true, "target": "3"})
	check(abode.session.get_view().transport.timber_home.stock.need == 0 and abode.session.get_view().transport.timber_home.stock.reserved == 3, "target accounts for actual incoming reservation once")
	# Unopened endpoints remain inspectable; no command is issued by shortcuts.
	reset()
	abode.session.state.economy.islands.wood.opened = false
	abode._refresh_hud()
	nav.open_transport("ore_wood")
	check(panel.route_widgets.ore_wood.toggle.disabled and panel.save_button.disabled, "unopened destination blocks commands")
	check(panel.detail_visual.destination.quantity.text == "—", "closed endpoints do not imply measured zero stock")
	var before := snapshot()
	panel.supply_button.pressed.emit()
	check(nav.page == "outposts" and nav.island_panel.island == "wood" and snapshot() == before, "closed destination opening shortcut")
	# All supported imported inputs and exported outputs use the exact fixed route.
	for entry in [["spirit_timber", "stone_low", "ore_wood"], ["formation_core", "spirit_timber", "timber_home"], ["formation_core", "bronze_essence", "bronze_home"], ["foundation_pill", "spirit_grass_low", "grass_home"], ["golden_core_pill", "spirit_grass_100y", "herb_home"]]:
		reset()
		var owner: String = "wood" if entry[0] == "spirit_timber" else "home"
		IslandEconomy._put(abode.session.state, owner, entry[1], 0)
		nav.open_manufacturing(owner, entry[0])
		before = snapshot()
		nav.manufacturing_panel.supply_button.pressed.emit()
		check(nav.page == "transport" and panel.selected_route == entry[2] and snapshot() == before, "exact missing resource route " + entry[2])
	for entry in [["spirit_timber", "wood", "timber_home"], ["bronze_essence", "ore", "bronze_home"], ["liquid", "herb", "liquid_home"]]:
		reset()
		IslandEconomy._put(abode.session.state, entry[1], entry[0], 100)
		nav.open_manufacturing(entry[1], entry[0])
		nav.manufacturing_panel.supply_button.pressed.emit()
		check(nav.page == "transport" and panel.selected_route == entry[2], "exact output full route " + entry[2])
	reset()
	IslandEconomy._put(abode.session.state, "herb", "spirit_grass_low", 0)
	nav.open_manufacturing("herb", "liquid")
	nav.manufacturing_panel.supply_button.pressed.emit()
	check(nav.page == "outposts" and nav.island_panel.island == "herb", "local grass never points to outgoing grass route")
	reset()
	IslandEconomy._put(abode.session.state, "home", "black_copper", 0)
	nav.open_manufacturing("home", "foundation_pill")
	nav.manufacturing_panel.supply_button.pressed.emit()
	check(nav.page == "buildings", "missing raw copper with no fixed incoming route uses home buildings")
	reset()
	send("configure_route", {"route_id": "liquid_home", "enabled": true})
	IslandEconomy._put(abode.session.state, "herb", "liquid", 0)
	IslandEconomy._put(abode.session.state, "home", "liquid", 0)
	abode._refresh_hud()
	nav.open_transport("liquid_home")
	panel.supply_button.pressed.emit()
	check(nav.page == "manufacturing" and nav.manufacturing_panel.selected_recipe == "liquid", "route missing manufactured cargo opens exact source recipe")
	reset()
	send("configure_route", {"route_id": "ore_wood", "enabled": true})
	IslandEconomy._put(abode.session.state, "ore", "stone_low", 0)
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 0)
	abode._refresh_hud()
	nav.open_transport("ore_wood")
	panel.supply_button.pressed.emit()
	check(nav.page == "outposts" and nav.island_panel.island == "ore", "route missing raw cargo reaches source extraction")
	# Validation, bounded Amount, isolated persistence and retry.
	reset()
	panel.drafts.clear()
	adapter = MemoryAdapter.new()
	SaveManager.configure(abode.content, adapter)
	nav.open_transport("bronze_home")
	edit(panel.reserve, "1000000000000")
	edit(panel.target, "0.125")
	panel.save_button.pressed.emit()
	check(abode.session.state.economy.routes.bronze_home.reserve == "1000000000000", "settings retain full supported Amount upper bound")
	edit(panel.reserve, "-1")
	before = snapshot()
	panel.save_button.pressed.emit()
	check(snapshot() == before and panel.reserve.text == "-1" and panel.message.visible, "invalid draft is refused atomically and retained")
	edit(panel.reserve, "7.5")
	edit(panel.target, "92")
	adapter.reject_write = true
	panel.save_button.pressed.emit()
	check(panel.retry_button.visible and abode.session.state.economy.routes.bronze_home.reserve == "7.5", "save failure retains applied policy and retry")
	before = snapshot()
	adapter.reject_write = false
	panel.retry_button.pressed.emit()
	check(snapshot() == before and not panel.retry_button.visible, "retry saves without another route command")
	SaveManager.configure(abode.content, adapter)
	var restored = SaveManager.load_state()
	check(restored != null and restored.economy.routes.bronze_home.reserve == "7.5" and restored.economy.routes.bronze_home.target == "92" and not restored.economy.routes.bronze_home.enabled, "actual saved custom stopped settings restore")
	# Legacy economy keeps its existing wood upgrade fee.
	reset()
	panel.drafts.clear()
	abode.session.state.economy = IslandEconomy.initial()
	for id in ["wood", "ore"]:
		abode.session.state.economy.islands[id].opened = true
	abode._refresh_hud()
	nav.open_transport("bronze_home")
	var old_wood := IslandEconomy.value(abode.session.state, "home", "wood")
	panel.upgrade_button.pressed.emit()
	check(panel.upgrade_button.text.contains("已達上限") and IslandEconomy.value(abode.session.state, "home", "wood") == old_wood - 20 and not abode.session.state.economy.routes.bronze_home.enabled, "legacy stopped upgrade retains old fee")
	# Layout and node reuse are CLI evidence only.
	reset()
	panel.drafts.clear()
	before = snapshot()
	for vp in [Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360), Vector2(600, 360)]:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		await process_frame
		vp = root.get_visible_rect().size
		abode._layout_for_size(vp)
		nav.open("transport")
		nav.layout(vp)
		await process_frame
		panel.show_success("航線設定已保存；停航時在途貨物仍會到貨。")
		await process_frame
		if panel.size.y < 400:
			check(not panel.message.visible and panel.heading_label.text.contains("已保存"), "compact receipt uses fixed heading " + str(vp))
			check(panel.route_widgets.wood_ore.root.get_global_rect().end.y <= panel.body.get_parent().get_global_rect().end.y + 1, "compact receipt preserves full first card " + str(vp))
		panel.show_result("操作未保存：隔離驗證")
		check(panel.message.visible and panel.retry_button.visible, "storage failure remains explicit " + str(vp))
		panel.show_result("")
		check(panel.get_global_rect().end.x <= vp.x and panel.get_global_rect().end.y <= vp.y - 40, "list fits layout " + str(vp))
		check(panel.grid.columns == (2 if panel.size.x >= 800 and panel.size.y >= 400 else 1), "route grid follows allocated bounds " + str(vp))
		for widget in panel.route_widgets.values():
			check(widget.root.get_combined_minimum_size().x <= widget.root.size.x and widget.root.get_global_rect().end.x <= panel.get_global_rect().end.x, "route tiles and controls fit " + str(vp))
		panel.select_route("liquid_home")
		nav.layout(vp)
		await process_frame
		check(panel.get_combined_minimum_size().x <= panel.size.x, "settings minimum fits " + str(vp))
		nav.back()
		check(nav.page == "transport" and panel.selected_route.is_empty(), "Escape returns to route list " + str(vp))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for index in 50:
		nav.open_transport("bronze_home")
		nav.back()
		nav.open("outposts")
		nav.open("transport")
		await process_frame
	check(snapshot() == before and int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes, "50 route/page switches retain nodes and full rule state")
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-UI1-B ", checks, " checks; seven routes, drafts, exact supply, stop/upgrade/delivery and retry")
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)

func edit(field: LineEdit, text: String) -> void:
	field.text = text
	field.text_changed.emit(text)
