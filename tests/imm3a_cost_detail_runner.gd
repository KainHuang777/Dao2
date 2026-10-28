extends SceneTree
## IMM-3A: icon-based cost/detail strips on operating surfaces.
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
const RealmModal = preload("res://src/presentation/realm_teleport_modal.gd")
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

func frames() -> void:
	for n in 4:
		await process_frame

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/imm3a/imm3a_cost_detail_runner")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned fixture decodes")
	var state = IslandProgression.prepare_supply(abode.content, decoded.state).state
	state.economy.jobs = {}
	state.economy.routes = {}
	state.economy.trips = {}
	for id in abode.content.processing_catalog.resources:
		ProcessingInventory.write(state, id, AmountCompat.from_number(1000 if id in IslandEconomy.GLOBAL else 100))
		state.resources[id].unlocked = true
	for id in ["wood", "ore", "herb"]:
		state.economy.islands[id].opened = true
		for resource in abode.content.processing_catalog.resources:
			if not resource in IslandEconomy.GLOBAL:
				state.economy.islands[id].inventory[resource] = "50"
	state.economy.islands.wood.facilities.workshop = 1
	abode.session.state = state
	SaveManager.configure(abode.content, MemoryAdapter.new())
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var nav = abode.feature_navigation
	var sizes: Array = [Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]
	for vp in sizes:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		abode._layout_for_size(vp)
		await frames()
		_check_manufacturing(nav, vp)
		_check_transport(nav, vp)
		_check_islands(nav, vp)
		_check_abode_detail(vp)
		_check_alchemy(nav, vp)
	_check_realm_modal()
	if failures.is_empty():
		print("PASS: IMM-3A ", checks, " checks; icon cost/detail strips across operating surfaces")
		RunnerResult.finish(self, 0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		RunnerResult.finish(self, 1)

func _check_manufacturing(nav, vp: Vector2) -> void:
	nav.open_manufacturing("wood", "spirit_timber")
	abode._layout_for_size(vp)
	var panel = nav.manufacturing_panel
	var view: Dictionary = abode.session.get_view()
	var info: Dictionary = view.manufacturing.recipes.spirit_timber
	check(panel.detail_costs != null and panel.detail_costs.visible, "manufacturing cost strip visible " + str(vp))
	check(panel.detail_costs.visible_tiles() == info.inputs.size(), "manufacturing one icon cell per input " + str(vp))
	var exact := true
	for resource in info.inputs:
		var tile = panel.detail_costs.tiles.get(resource)
		exact = exact and tile != null and tile.visible and tile.quantity.text == NumberFormatter.format_amount(info.inputs[resource].required)
	check(exact, "manufacturing cell shows actual requirement " + str(vp))
	IslandEconomy._put(abode.session.state, "wood", "wood", 0)
	abode._refresh_hud()
	check(panel.detail_costs.note.visible and panel.detail_costs.note.text.contains("缺"), "manufacturing names missing amount and source " + str(vp))
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", 0)
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 0)
	abode._refresh_hud()
	var workshop: Dictionary = IslandProgression.upgrade_cost("workshop", int(abode.session.state.economy.islands.wood.facilities.workshop))
	check(panel.workshop_costs.visible and panel.workshop_costs.visible_tiles() == workshop.size(), "workshop upgrade costs use icon cells " + str(vp))
	check(panel.workshop_costs.heading.text.contains("加工坊"), "workshop strip labels the purchase " + str(vp))
	check(panel.workshop_costs.note.visible and panel.workshop_costs.note.text.contains("缺"), "workshop shortage is explicit " + str(vp))
	IslandEconomy._put(abode.session.state, "wood", "wood", 100)
	IslandEconomy._put(abode.session.state, "home", "spirit_timber", 100)
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 100)

func _check_transport(nav, vp: Vector2) -> void:
	nav.open_transport("timber_home")
	abode._layout_for_size(vp)
	var panel = nav.transport_panel
	var info: Dictionary = panel._info("timber_home")
	check(panel.detail_stock.text.contains("來源餘貨") and panel.detail_stock.text.contains("目的容量預留") and panel.detail_stock.text.contains("已保存目標"), "transport facts stay labelled " + str(vp))
	check(panel.detail_stock.text.contains("運力"), "transport capacity remains an explicit setting " + str(vp))
	check(panel.upgrade_costs.visible and panel.upgrade_costs.visible_tiles() == info.upgrade_cost.size(), "transport upgrade costs use icon cells " + str(vp))
	check(panel.upgrade_costs.heading.text.contains("升級運力"), "transport strip labels capacity upgrade " + str(vp))

func _check_islands(nav, vp: Vector2) -> void:
	nav.open("outposts")
	var panel = nav.island_panel
	panel.select_island("deep")
	abode._layout_for_size(vp)
	check(panel.opening_note.visible and panel.opening_note.text.contains("境界需求 4"), "unopened island states era requirement " + str(vp))
	panel.select_island("wood")
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 0)
	abode._refresh_hud()
	check(panel.facility_cards.extractor.card.visible, "facility card remains in operating island " + str(vp))
	check(panel.facility_cards.extractor.note.visible and panel.facility_cards.extractor.note.text.contains("缺"), "facility upgrade names shortage " + str(vp))
	IslandEconomy._put(abode.session.state, "home", "bronze_essence", 100)

func _check_abode_detail(vp: Vector2) -> void:
	abode._layout_for_size(vp)
	var view: Dictionary = abode.session.get_view()
	var target := ""
	for id in view.buildings:
		var data: Dictionary = view.buildings[id]
		if bool(data.get("visible", false)) and not data.get("costs", {}).is_empty() and int(data.level) < int(data.level_cap):
			target = id
			break
	check(not target.is_empty(), "an upgradeable building exists for detail check " + str(vp))
	if target.is_empty():
		return
	abode._select_building_from_catalog(target)
	abode._layout_for_size(vp)
	var data: Dictionary = view.buildings[target]
	check(abode.detail_costs.visible and abode.detail_costs.visible_tiles() == data.costs.size(), "building detail costs use icon cells " + str(vp))
	check(abode.detail_costs.heading.text.contains("材料"), "building detail labels construction materials " + str(vp))

func _check_alchemy(nav, vp: Vector2) -> void:
	nav.open("alchemy")
	abode._layout_for_size(vp)
	var panel = abode.alchemy_panel
	check(not panel._pill_rows.is_empty(), "alchemy rows exist " + str(vp))
	if panel._pill_rows.is_empty():
		return
	var pill_id: String = panel._pill_rows.keys()[0]
	var widget: Dictionary = panel._widgets[pill_id]
	var view: Dictionary = abode.session.get_view()
	var pill := {}
	for entry in view.alchemy.pills:
		if String(entry.id) == pill_id:
			pill = entry
			break
	check(not pill.is_empty() and widget.tiles.size() == pill.cost.size(), "alchemy material cells match recipe costs " + str(vp))
	var cells_ok := true
	for resource in pill.cost:
		var tile = widget.tiles.get(resource)
		cells_ok = cells_ok and tile != null and not tile.quantity.text.is_empty()
	check(cells_ok, "alchemy cells keep requirement or availability readout " + str(vp))

func _check_realm_modal() -> void:
	var modal = RealmModal.new()
	root.add_child(modal)
	var view := {
		"realm": {
			"current_realm": "realm_human",
			"unlocked": true,
			"cultivation_feedback_boost": 0.2,
			"outposts": [
				{"id": "celestial_hub", "name": "天樞陣眼", "description": "維繫跨界靈脈", "level": 2, "max_level": 10, "costs": {"stone_low": 20.0}, "can_upgrade": false, "upgrade_reason": "INSUFFICIENT_CRYSTAL"},
				{"id": "pure_pool", "name": "化靈仙池", "description": "凝練仙液", "level": 1, "max_level": 10, "costs": {"spirit_crystal": 10.0}, "can_upgrade": true}
			]
		},
		"resources": {"stone_low": {"value": "5"}, "spirit_crystal": {"value": "50"}}
	}
	modal.refresh(view)
	check(modal._outpost_cards_box.get_child_count() == 2, "realm modal renders outposts")
	var strips: Array = []
	_find_strips(modal._outpost_cards_box, strips)
	check(strips.size() == 2, "each outpost carries an icon cost strip")
	if strips.size() == 2:
		check(strips[0].visible_tiles() == 1 and strips[0].tiles.stone_low.quantity.text == "20", "outpost cost cell shows requirement")
		check(strips[0].note.visible and strips[0].note.text.contains("缺"), "outpost names shortage amount")
		check(strips[1].tiles.spirit_crystal.icon.visible and not strips[1].tiles.spirit_crystal.caption.visible, "supreme crystal has real art without an extra caption row")
		check(strips[1].tiles.spirit_crystal.tooltip_text.contains("可用 50"), "outpost tooltip exposes availability")
	view["resources"]["stone_low"]["value"] = "80"
	modal.refresh(view)
	strips.clear()
	_find_strips(modal._outpost_cards_box, strips)
	check(strips.size() == 2 and not strips[0].note.visible, "outpost shortage clears when funded")
	modal.queue_free()

func _find_strips(node: Node, out: Array) -> void:
	if node.has_method("show_costs") and node.has_method("visible_tiles") and not node.is_queued_for_deletion():
		out.append(node)
	for child in node.get_children():
		_find_strips(child, out)
