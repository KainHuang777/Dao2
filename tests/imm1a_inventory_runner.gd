extends SceneTree
const ShellResources = preload("res://src/presentation/ui_shell_resources.gd")
const ResourceIcon = preload("res://src/presentation/resource_icon.gd")
const ItemCell = preload("res://src/presentation/inventory_item_cell.gd")
var checks := 0
var failures: Array[String] = []
var abode: Node

class MemoryAdapter extends StorageAdapter:
	var data := {}
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
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

func frames() -> void:
	for n in 6:
		await process_frame

func _run() -> void:
	# Every named resource, all current catalog entries and the separate soul
	# counters must have real shared artwork rather than a silent empty image.
	for id in ResourceIcon.NAMES:
		check(ResourceIcon.get_resource_texture(id) != null, "IMM-4-R2 named icon coverage: " + id)
	for id in ShellResources.CURRENCY_IDS:
		check(ResourceIcon.get_resource_texture(id) != null, "IMM-4-R2 currency icon coverage: " + id)
	for id in BeastSystem.BEAST_CONFIGS:
		check(ResourceIcon.get_resource_texture(id) != null, "IMM-4-R2 soul icon coverage: " + id)
	for path in ["res://content/recipes/era1_3.json", "res://content/supply/era4_6.json"]:
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for id in catalog.resources:
			check(ResourceIcon.get_resource_texture(id) != null, "IMM-4-R2 catalog icon coverage: " + id)
	var tile = load("res://src/presentation/recipe_material_tile.gd").new()
	var tile_host := Control.new()
	root.add_child(tile_host)
	tile_host.add_child(tile)
	for small in [false, true]:
		tile.set_compact(small)
		tile.refresh("skill_point", "技能點", 1800, 2000, "當世")
		await frames()
		tile.size = tile.get_combined_minimum_size()
		await frames()
		check(is_equal_approx(tile.size.x, tile.size.y) and not tile.caption.visible, "IMM-4-R2 complete item frame stays square")
		check(tile.icon.visible and tile.quantity.anchor_right == 1 and tile.quantity.anchor_bottom == 1, "IMM-4-R2 amount overlays art at bottom right")
		tile.refresh("not_in_catalog", "未登錄物品全名", 3, 0, "測試來源")
		check(tile.fallback.visible and not tile.icon.visible and tile.tooltip_text.contains("未登錄物品全名"), "unknown future item keeps square seal and full name in tooltip")
	tile_host.queue_free()
	await process_frame
	var storage_root := OS.get_environment("DAO_TEST_STORAGE_ROOT")
	if storage_root.is_empty(): storage_root = "res://.test-output"
	var storage := storage_root.path_join("imm1a-inventory")
	load("res://src/abode/living_abode.gd").save_dir_override = storage
	SaveSlots.new(FileStorageAdapter.new(storage)).reset()
	abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames() # Let queued startup-report callbacks finish before injecting fixture state.
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	SaveManager.configure(abode.content, MemoryAdapter.new())
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned fixture decodes")
	abode.session.state = IslandProgression.prepare_supply(abode.content, decoded.state).state
	abode.session.state.economy.jobs = {}
	abode.session.state.economy.routes = {}
	abode.session.state.economy.trips = {}
	var nav = abode.feature_navigation
	for id in abode.content.processing_catalog.resources:
		ProcessingInventory.write(abode.session.state, id, AmountCompat.from_number(1000 if id in IslandEconomy.GLOBAL else 100))
		abode.session.state.resources[id].unlocked = true
	for id in ["wood", "ore", "herb"]:
		abode.session.state.economy.islands[id].opened = true
		for resource in abode.content.processing_catalog.resources:
			if not resource in IslandEconomy.GLOBAL:
				abode.session.state.economy.islands[id].inventory[resource] = "50"
	abode.session.state.economy.islands.wood.inventory.stone_low = "2"
	abode.session.state.buildings.herb_farm = 3
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	nav.open_manufacturing("wood", "spirit_timber")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	var shell = nav.shell
	var inventory = shell.context_inventory
	var view: Dictionary = abode.session.get_view()
	var data: Dictionary = ShellResources.inventory(shell.state.snapshot(), view, nav)
	check(shell.context_paper.visible and inventory.visible and not shell.context_scroll.visible, "scoped manufacturing uses shared inventory panel")
	check(data.supported and data.groups.size() >= 2, "structured inventory groups by island")
	var keys := {}
	var item_count := 0
	var provided_ok := true
	for group in data.groups:
		check(not String(group.id).is_empty() and not String(group.title).is_empty(), "group identity " + String(group.id))
		for item in group.items:
			item_count += 1
			check(not keys.has(item.key), "unique stable item key " + String(item.key))
			keys[item.key] = true
			var provided: Dictionary = item.provided
			for flag in provided:
				provided_ok = provided_ok and item.get(flag) != null
			for flag in ["available", "reserved", "capacity", "demand", "transit"]:
				if not provided.has(flag):
					provided_ok = provided_ok and item.get(flag) == null
			check(String(item.name) != String(item.id), "resolved display name " + String(item.id))
	check(provided_ok, "provided flags exactly match non-null fields")
	check(item_count >= 4, "pilot furniture exposes real materials")
	check(keys.has("wood:stone_low") and keys.has("home:lingli"), "recipe island and ancestral payment groups")
	var metrics: Dictionary = view.manufacturing.recipes.spirit_timber.inputs.stone_low
	var stone_item: Dictionary = {}
	for group in data.groups:
		for item in group.items:
			if item.key == "wood:stone_low":
				stone_item = item
	check(stone_item.get("demand") == metrics.required and bool(stone_item.provided.demand), "demand equals real recipe requirement without parsing text")
	check(stone_item.get("capacity") != null and bool(stone_item.provided.capacity), "island capacity provided")
	var wood_cell = inventory._cells.get("wood:stone_low")
	check(wood_cell != null and wood_cell.size.x >= 88 and is_equal_approx(wood_cell.size.x, wood_cell.size.y), "square readable item cell")
	var before := snapshot()
	wood_cell.pressed.emit()
	check(inventory.selected_key() == "wood:stone_low" and wood_cell._selected, "cell click selects detail only")
	check(inventory._detail_line.text.contains("需求") and inventory._detail_line.text.contains("容量"), "selected detail carries exact demand and capacity")
	check(snapshot() == before, "selection never mutates inventory")
	var cells_before: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 7.0)
	abode._refresh_hud()
	await frames()
	check(inventory._cells.get("wood:stone_low") == wood_cell and inventory._cells.size() == keys.size(), "tick refresh updates in place without rebuild")
	check(inventory.selected_key() == "wood:stone_low" and wood_cell._amount.text == "7", "selection and numeric refresh stay stable (%s, %s)" % [inventory.selected_key(), wood_cell._amount.text])
	check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == cells_before, "in-place refresh allocates no nodes")
	IslandEconomy._put(abode.session.state, "home", "lingli", 123456.0)
	abode._refresh_hud()
	await frames()
	var lingli_cell = inventory._cells.get("home:lingli")
	check(lingli_cell._amount.text == "12.3萬" and lingli_cell.tooltip_text.contains("123456"), "visible amount abbreviates while tip keeps exact value")
	var unknown = ItemCell.new()
	unknown.apply({"key": "x:unknown", "id": "imm1a_unknown_item", "name": "無圖示靈材", "source": "測試", "display": "available", "provided": {"available": true}, "available": 3.0})
	check(ResourceIcon.get_resource_texture("imm1a_unknown_item") == null and unknown._fallback.visible and unknown._fallback.text == "無圖示靈材", "unknown icon becomes text stamp")
	unknown.free()
	check(ShellResources.inventory({"route": "skills"}, view, nav).supported, "focused page has typed data independently of UI migration")
	check(ShellResources.inventory({"route": "home"}, view, nav).supported == false, "home keeps existing ribbon")
	for route in ["manufacturing", "outposts", "transport", "sect", "skills", "beasts", "fortune", "decisions", "reincarnation"]:
		check(ShellResources.inventory({"route": route, "subpage": "techniques" if route == "sect" else "talents"}, view, nav).supported, "nine structured contexts: " + route)
	var missing: Dictionary = ShellResources.inventory({"route": "skills"}, {}, nav).groups[0].items[0]
	check(missing.available == null and not missing.provided.has("available") and missing.capacity == null, "unknown currency amount/capacity never become fake zero")
	check(NumberFormatter.exact_amount(9007199254740993) == "9007199254740993", "integer exact tip does not pass through float")
	check(NumberFormatter.exact_amount(1.000001) != "1", "exact tip keeps small fractional differences")
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 0.0)
	var zero_data: Dictionary = ShellResources.inventory(shell.state.snapshot(), abode.session.get_view(), nav)
	var zero_required := false
	for group in zero_data.groups:
		for item in group.items:
			if item.key == "wood:stone_low": zero_required = float(item.available) == 0.0 and item.provided.demand
	check(zero_required, "zero-stock required material stays visible")
	IslandEconomy._put(abode.session.state, "wood", "stone_low", 7.0)
	abode._refresh_hud()
	await frames()
	wood_cell = inventory._cells["wood:stone_low"]
	wood_cell.grab_focus()
	inventory._scroll.scroll_vertical = 30
	var retained_scroll: int = inventory._scroll.scroll_vertical
	var changed: Dictionary = ShellResources.inventory(shell.state.snapshot(), abode.session.get_view(), nav).duplicate(true)
	changed.groups.append({"id": "test-topology", "title": "拓樸變更", "items": []})
	inventory.refresh(changed)
	await frames()
	check(inventory.get_viewport().gui_get_focus_owner() == inventory._cells["wood:stone_low"], "topology refresh restores keyboard focus by stable key")
	check(inventory.selected_key() == "wood:stone_low" and inventory._scroll.scroll_vertical == retained_scroll, "topology refresh preserves selection and scroll")
	if inventory._scroll.scroll_vertical != retained_scroll:
		print("IMM1A_SCROLL wanted=",retained_scroll," actual=",inventory._scroll.scroll_vertical," selected=",inventory.selected_key())
	abode._refresh_hud()
	await frames()
	var sect = ShellResources.inventory({"route": "sect", "subpage": "techniques"}, view, nav)
	check(sect.supported and not sect.groups.is_empty(), "sect techniques uses shared groups")
	check(sect.groups[0].items[0].key == "sect:contribution", "sect contribution keeps stable key")
	nav.open("transport")
	await frames()
	check(nav.transport_panel._routes().has("timber_home"), "timber route exists for transit evidence")
	nav.transport_panel.select_route("timber_home")
	abode.session.state.economy.trips.timber_home = {"remaining": 5, "cargo": "3"}
	abode._refresh_hud()
	await frames()
	var transit_data: Dictionary = ShellResources.inventory(shell.state.snapshot(), abode.session.get_view(), nav)
	var transit_group := {}
	for group in transit_data.groups:
		if group.id == "transit":
			transit_group = group
	if transit_group.is_empty():
		check(false, "arriving cargo stays a separate transit group")
	else:
		var first: Dictionary = transit_group.items[0]
		check(transit_data.supported and String(first.display) == "transit" and float(first.transit) == 3.0, "arriving cargo stays a separate transit group")
		check(str(first.get("eta")) == "5", "transit keeps real remaining seconds: " + str(first.get("eta")))
	nav.open("outposts")
	await frames()
	check(ShellResources.inventory(shell.state.snapshot(), abode.session.get_view(), nav).supported, "outposts shares structured inventory")
	nav.open_manufacturing("wood", "spirit_timber")
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		shell.resource_button.pressed.emit()
		await frames()
		check(shell.shield.visible and inventory.visible and shell.compact_hud.visible, "overlay opens shared inventory drawer")
		check(shell.context_paper.get_global_rect().end.y <= vp.y and shell.context_paper.get_global_rect().end.x <= vp.x, "drawer stays inside viewport")
		check(inventory._scroll.size.y >= 60.0 and inventory._scroll.get_v_scroll_bar().max_value > inventory._scroll.size.y, "drawer scrolls real groups")
		var first_cell = inventory._cells.values()[0]
		check(first_cell.size.x >= 88.0 and first_cell.size.y >= 88.0, "item hit target keeps accepted size")
		nav.back()
		check(nav.page == "manufacturing" and not shell.shield.visible, "drawer back retains page")
	abode.queue_free()
	await process_frame
	load("res://src/abode/living_abode.gd").save_dir_override = ""
	SaveManager.reset_for_tests()
	if failures.is_empty():
		print("PASS: IMM-1A ", checks, " checks; shared structured inventory, in-place refresh, exact tips, drawer")
		RunnerResult.finish(self, 0)
	else:
		for label in failures:
			push_error(label)
		RunnerResult.finish(self, 1)
