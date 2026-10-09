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
	return abode.session.submit({"command_id": "ui1-test-" + str(serial), "type": kind, "expected_revision": abode.session.state.revision, "payload": payload})
func reject(kind: String, payload: Dictionary, reason: String) -> void:
	var before := snapshot()
	var result := send(kind, payload)
	check(not result.ok and result.error == reason, "atomic refusal " + reason)
	check(snapshot() == before, "refusal leaves inventory/jobs unchanged " + reason)

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://res1_ui1a_runner"
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
	var panel = nav.manufacturing_panel
	var starter := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	check(starter.ok and starter.state.economy.is_empty(), "earned Era2 activation source is still unconverted")
	abode.session.state = starter.state.duplicate_state()
	nav.open("outposts")
	check(not nav.island_panel.activation.disabled, "activation reachable from normal island route")
	nav.island_panel.activation.pressed.emit()
	check(abode.session.state.economy.get("version") == IslandProgression.VERSION, "UI activates with verified original archive")
	for id in ["wood", "ore"]:
		nav.island_panel.select_island(id)
		nav.island_panel.opening.pressed.emit()
		check(abode.session.state.economy.islands[id].opened, "UI opens " + id)
	nav.island_panel.select_island("herb")
	check(nav.island_panel.opening.disabled, "Era2 cannot open Danxia through basics")
	adapter = MemoryAdapter.new()
	SaveManager.configure(abode.content, adapter)
	reset()
	var before := snapshot()
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		await process_frame
		nav.open("manufacturing")
		abode._layout_for_size(Vector2(vp))
		await process_frame
		await process_frame
		check(panel.grid.columns == (2 if vp.x == 1280 else 1), "responsive recipe columns " + str(vp))
		if vp.x != 1280:
			check(not panel.production_summary.visible and panel.cards.bronze_essence.materials.get_global_rect().end.y <= panel.body.get_parent().get_global_rect().end.y, "short first card exposes materials without initial scroll " + str(vp))
		check(not abode.header.visible and abode.resource_ribbon.visible == (vp.x == 1280), "manufacturing keeps wide stock rail; short cards show sources")
		if vp.x == 1280:
			check(abode.resource_ribbon.get_global_rect().end.x < panel.position.x, "stock rail does not overlap manufacturing")
		check(panel.get_global_rect().end.x <= vp.x and panel.get_global_rect().end.y <= abode.toolbar.position.y, "workspace fits " + str(vp))
		panel.select_recipe("spirit_timber")
		await process_frame
		check(panel.back_button.size.y >= 44 and panel.start_button.size.y >= 44, "fixed back and action minimum44")
		check(panel.body.get_parent().get_global_rect().end.y <= panel.get_global_rect().end.y, "detail scroll fits " + str(vp))
		check(panel.get_global_rect().end.x <= vp.x, "detail fits after replacing list " + str(vp))
		nav.back()
		check(panel.selected_recipe.is_empty() and nav.page == "manufacturing", "Escape detail returns to recipe list")
		nav.back()
		check(nav.group == "home" and abode.header.visible, "Escape list restores home")
	check(snapshot() == before, "layouts and navigation leave full state unchanged")
	check(panel.cards.size() == 8 and panel.production_summary.text.contains("4閒置"), "eight recipes; one compact summary of four lines")
	check(panel.cards.bronze_essence.tiles.black_copper.tooltip_text.contains("玄銅") and panel.filter_picker.selected == 0, "initial graphical material refresh and island picker complete")
	nav.open("transport")
	check(nav.transport_panel.route_widgets.size() == 7, "all old transport actions remain reachable")
	nav.transport_panel.select_route("bronze_home")
	nav.transport_panel.upgrade_button.pressed.emit()
	check(abode.session.state.economy.routes.bronze_home.level == 2 and not abode.session.state.economy.routes.bronze_home.enabled, "relocated upgrade preserves stopped route")
	# Every recipe starts through the same presentation signal and completes once.
	for recipe in IslandEconomy.DURATIONS:
		reset()
		nav.open_manufacturing("", recipe)
		var island_id: String = panel.island
		var inputs: Dictionary = abode.content.processing_catalog.recipes[recipe].inputs
		var old := {}
		for resource in inputs:
			old[resource] = IslandEconomy.value(abode.session.state, island_id, resource)
		var output := IslandEconomy.value(abode.session.state, island_id, recipe)
		panel.start_button.pressed.emit()
		check(abode.session.state.economy.jobs[island_id].recipe_id == recipe, "UI starts " + recipe)
		check(panel.detail_progress.visible and panel.cards[recipe].progress.visible and panel.message.text.contains("原料已扣除"), "start feedback and inline progress " + recipe)
		check(panel.cards[recipe].tiles.size() == inputs.size(), "all graphical recipe inputs present " + recipe)
		for resource in inputs:
			var tile = panel.cards[recipe].tiles[resource]
			check(tile.quantity.text == str(int(inputs[resource])) and tile.tooltip_text.contains("需求") and tile.icon.resource_id == resource, "icon and required quantity " + recipe + ":" + resource)
			check(tile.shortage == (float(panel._view.manufacturing.recipes[recipe].inputs[resource].available) < float(inputs[resource])), "shortage color reads actual spendable input " + recipe + ":" + resource)
			check(IslandEconomy.value(abode.session.state, island_id, resource) == old[resource] - float(inputs[resource]), "one deduction from correct location " + recipe + ":" + resource)
		reject("craft", {"island_id": island_id, "recipe_id": recipe}, "JOB_BUSY")
		for tick in IslandEconomy.DURATIONS[recipe]:
			IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
			if tick == 2:
				abode._refresh_hud()
				check(panel.cards[recipe].progress.value > 0 and panel.detail_progress.value == panel.cards[recipe].progress.value, "actual ticks advance matching card/detail meters " + recipe)
		check(not abode.session.state.economy.jobs.has(island_id) and IslandEconomy.value(abode.session.state, island_id, recipe) == output + 1, "single completion " + recipe)
		abode._refresh_hud()
		check(not panel.cards[recipe].progress.visible, "completed job clears inline progress " + recipe)
	reset()
	nav.open_manufacturing("home", "stone_mid")
	panel.mode.select(1)
	panel.batch_count.value = 3
	panel.start_button.pressed.emit()
	check(abode.session.state.economy.jobs.home.batches == 2, "specified three batches queues two after first charge")
	var three_start := IslandEconomy.value(abode.session.state, "home", "stone_mid")
	for tick in 30:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(not abode.session.state.economy.jobs.has("home") and IslandEconomy.value(abode.session.state, "home", "stone_mid") == three_start + 3, "specified three batches complete exactly three outputs")
	reset()
	nav.open_manufacturing("home", "stone_mid")
	panel.start_button.pressed.emit()
	panel.select_recipe("formation_core")
	panel.start_button.pressed.emit()
	check(abode.session.state.economy.jobs.home.pending.recipe_id == "formation_core", "running line queues switch")
	check(panel.detail_status.text.contains("本批後切換"), "pending switch persists in detail")
	check(panel.cards.formation_core.status.text.contains("本批後切換") and not panel.cards.formation_core.progress.visible and panel.cards.stone_mid.progress.visible, "pending target cannot appear as second running recipe")
	for tick in 10:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(abode.session.state.economy.jobs.home.recipe_id == "formation_core", "switch starts only after current completion")
	abode._refresh_hud()
	panel.stop_button.pressed.emit()
	check(not abode.session.state.economy.jobs.home.repeat and not abode.session.state.economy.jobs.home.has("pending"), "stop clears future switch")
	check(panel.stop_button.disabled and panel.message.text.contains("當前加工繼續"), "stop receipt confirms scheduled completion and prevents no-op repeat")
	for tick in 20:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(not abode.session.state.economy.jobs.has("home"), "running stop preserves one completion and then stops")
	reset()
	# Prevent local extraction from replenishing the missing imported stone.
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 5)
	nav.open_manufacturing("wood", "spirit_timber")
	panel.mode.select(2)
	panel.start_button.pressed.emit()
	for tick in 10:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	abode._refresh_hud()
	check(abode.session.state.economy.jobs.wood.status == "INSUFFICIENT_RESOURCE", "continuous work waits after completed batch")
	panel.stop_button.pressed.emit()
	check(not abode.session.state.economy.jobs.has("wood"), "waiting stop immediately removes job")
	reset()
	nav.open_manufacturing("wood", "spirit_timber")
	panel.mode.select(2)
	panel.start_button.pressed.emit()
	for tick in 21:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(abode.session.state.economy.jobs.wood.repeat and IslandEconomy.value(abode.session.state, "wood", "spirit_timber") == 52, "continuous mode actually completes repeated batches")
	reset()
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 0)
	before = snapshot()
	abode._refresh_hud()
	nav.open_manufacturing("wood", "spirit_timber")
	check(panel.start_button.disabled and panel.detail_status.text.contains("尚未開始"), "first shortage is not a fake waiting job")
	reject("craft", {"island_id": "wood", "recipe_id": "spirit_timber"}, "INSUFFICIENT_RESOURCE")
	panel.supply_button.pressed.emit()
	check(nav.page == "transport" and nav.transport_panel.island == "ore", "imported stone shortage reaches source routes")
	reset()
	IslandEconomy._put(abode.session.state, "herb", "spirit_grass_low", 0)
	nav.open_manufacturing("herb", "liquid")
	var missing_tile = panel.cards.liquid.tiles.spirit_grass_low
	check(missing_tile.shortage and missing_tile.quantity.get_theme_color("font_color") == missing_tile.SHORTAGE and missing_tile.quantity.text == "5", "zero local stock turns required quantity red without changing requirement")
	check(panel.detail_materials.tiles.spirit_grass_low.shortage and not panel.cards.liquid.tiles.lingli.shortage, "detail and list agree; funded global input stays normal")
	IslandEconomy._put(abode.session.state, "herb", "spirit_grass_low", 5)
	abode._refresh_hud()
	check(not missing_tile.shortage and missing_tile.quantity.get_theme_color("font_color") == missing_tile.NORMAL, "exact requirement restores normal color")
	IslandEconomy._put(abode.session.state, "herb", "spirit_grass_low", 0)
	abode._refresh_hud()
	panel.supply_button.pressed.emit()
	check(nav.page == "outposts" and nav.island_panel.island == "herb", "local grass shortage reaches extraction instead of outgoing route")
	check(nav.island_panel.facility_buttons.size() == 2 and not nav.island_panel.facility_buttons.has("workshop"), "island basics retain only extraction and storage")
	check(not nav.island_panel.inventory.text.contains("丹液"), "basics exclude imported and crafted inventory")
	reset()
	nav.open("outposts")
	nav.island_panel.select_island("wood")
	nav.island_panel.facility_buttons.extractor.pressed.emit()
	nav.island_panel.facility_buttons.storage.pressed.emit()
	check(abode.session.state.economy.islands.wood.facilities.extractor == 2 and abode.session.state.economy.islands.wood.facilities.storage == 2, "basic upgrades submit canonical commands")
	check(nav.island_panel.island_buttons.wood.button_pressed and nav.island_panel.message.text.contains("已升階") and nav.island_panel.payment_stock.text.contains("祖島"), "island selection, paid stock and success feedback")
	nav.island_panel.stock_button.pressed.emit()
	check(nav.island_panel.local_stock.visible and nav.island_panel.local_stock.tooltip_text.contains("靈材") and nav.island_panel.local_tiles.has("spirit_timber"), "island inventory can reveal local crafted stock")
	var basics = nav.island_panel
	check(basics.stock_cards.wood.tile.icon.resource_id == "wood" and basics.stock_cards.wood.rate.text.contains("／秒"), "extraction cards show resource and real rate")
	check(basics.facility_cards.extractor.tiles.bronze_essence.icon.resource_id == "bronze_essence", "upgrade cards show actual cost resource")
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 0)
	abode._refresh_hud()
	check(basics.facility_cards.extractor.tiles.bronze_essence.shortage, "upgrade cost marks shortage")
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 4)
	abode._refresh_hud()
	check(not basics.facility_cards.extractor.tiles.bronze_essence.shortage, "upgrade cost clears shortage at exact required stock")
	for vp in [Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)]:
		abode._layout_for_size(vp)
		await process_frame
		await process_frame
		check(basics.get_combined_minimum_size().x <= basics.size.x, "island panel fits " + str(vp))
		var fixed_selector: Control = basics.selectors if basics.selectors.visible else basics.island_picker
		check(fixed_selector.get_global_rect().end.y <= basics.body.get_parent().get_global_rect().position.y, "island selector fixed above scroll " + str(vp))
	abode._layout_for_size(Vector2(1280, 720))
	reset()
	IslandEconomy._put(abode.session.state, "wood", "spirit_timber", 100)
	reject("craft", {"island_id": "wood", "recipe_id": "spirit_timber"}, "OUTPUT_FULL")
	reset()
	IslandEconomy._put(abode.session.state, "home", "stone_low", 5)
	nav.open_manufacturing("home", "stone_mid")
	panel.mode.select(2)
	panel.start_button.pressed.emit()
	for tick in 10:
		IslandEconomy.tick(abode.session.state, abode.content.processing_catalog)
	check(int(abode.session.state.economy.jobs.home.remaining) == 0, "home work waits at empty input")
	abode._refresh_hud()
	panel.select_recipe("formation_core")
	panel.start_button.pressed.emit()
	check(abode.session.state.economy.jobs.home.recipe_id == "formation_core" and not abode.session.state.economy.jobs.home.has("pending"), "waiting line switches immediately")
	reset()
	send("craft", {"island_id": "wood", "recipe_id": "spirit_timber"})
	abode.session.state.economy.trips.timber_home = {"remaining": 5, "cargo": "3"}
	nav.open_manufacturing("wood", "spirit_timber")
	check(panel.detail_stock.text.contains("加工待完成 1.0・容量預留 1.0"), "detail separates job output reservation from spendable inventory")
	panel.select_recipe("formation_core")
	check(panel.detail_stock.text.contains("在途到貨 3.0・5秒"), "recipe input shows actual arriving cargo once")
	reset()
	abode.session.state.era_id = 2
	reject("craft", {"island_id": "home", "recipe_id": "formation_core"}, "ERA_REQUIREMENT")
	reset()
	abode.session.state.economy.islands.wood.opened = false
	reject("craft", {"island_id": "wood", "recipe_id": "spirit_timber"}, "ISLAND_NOT_OPEN")
	reset()
	nav.open_manufacturing("wood", "spirit_timber")
	panel.reserves.stone_low.value = 49
	panel.mode.select(1)
	panel.batch_count.value = 7
	panel.refresh(abode.session.get_view(), abode.content.processing_catalog)
	check(panel.reserves.stone_low.value == 49 and panel.batch_count.value == 7 and panel.mode.selected == 1, "refresh preserves reserve/count/mode draft")
	reject("craft", {"island_id": "wood", "recipe_id": "spirit_timber", "reserves": {"stone_low": "49"}}, "INSUFFICIENT_RESOURCE")
	panel.reserves.stone_low.value = 0
	panel.workshop_button.pressed.emit()
	check(abode.session.state.economy.islands.wood.facilities.workshop == 2 and panel.detail_title.text.contains("5秒"), "workshop upgrade uses effective duration")
	# Legacy alchemy routes to the exact same home job without issuing a second command.
	reset()
	nav.open("alchemy")
	before = snapshot()
	abode.alchemy_panel.refine_requested.emit("foundation_pill", 1)
	check(nav.page == "manufacturing" and panel.selected_recipe == "foundation_pill" and snapshot() == before, "alchemy shortcut does not charge or start work")
	panel.start_button.pressed.emit()
	before = snapshot()
	var busy: Dictionary = abode.session.refine_pill("foundation_pill", 1)
	check(not busy.ok and busy.error == "JOB_BUSY" and snapshot() == before, "legacy API and cards share busy job with no double charge")
	var pills: int = abode.session.state.pills.foundation_pill
	abode._on_alchemy_consume_requested("foundation_pill", 1)
	check(abode.session.state.pills.foundation_pill == pills - 1, "existing consume entry retained")
	reset()
	abode.session.state.era_id = 1
	var era1: Dictionary = abode.session.refine_pill("foundation_pill", 1)
	check(era1.ok and not abode.session.state.economy.jobs.has("home"), "reborn Era1 retains instant starter path")
	adapter = MemoryAdapter.new()
	SaveManager.configure(abode.content, adapter)
	reset()
	nav.open_manufacturing("wood", "spirit_timber")
	adapter.reject_write = true
	panel.start_button.pressed.emit()
	check(panel.retry_button.visible and abode.session.state.economy.jobs.has("wood"), "failed save leaves applied job and explicit retry")
	before = snapshot()
	adapter.reject_write = false
	panel.retry_button.pressed.emit()
	check(snapshot() == before and not panel.retry_button.visible, "save retry does not reissue craft")
	SaveManager.configure(abode.content, adapter)
	var restored = SaveManager.load_state()
	check(restored != null and restored.economy.jobs.get("wood", {}).get("recipe_id") == "spirit_timber", "isolated save reload preserves one job")
	reset()
	before = snapshot()
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for index in 50:
		nav.open("manufacturing")
		nav.open("outposts")
		await process_frame
	check(snapshot() == before and int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes, "50 management switches preserve nodes and rule state")
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: RES1-UI1-A ", checks, " checks; diagnostic UI, job ownership, gates and save retry")
		quit(0)
	else:
		for label in failures:
			push_error(label)
		quit(1)
