extends SceneTree

## Scene-level contract: the visible abode may change camera state, while its
## independent simulation and building interaction remain available.
const LivingAbodeScene = preload("res://scenes/living_abode.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var LivingAbodeScript = preload("res://src/abode/living_abode.gd")
	LivingAbodeScript.save_dir_override = "user://living_abode_test_saves"
	var adapter := FileStorageAdapter.new("user://living_abode_test_saves")
	var slots := SaveSlots.new(adapter)
	slots.reset()

	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame
	# Headless expand reports a square root viewport; exercise the desktop contract explicitly.
	abode._layout_for_size(Vector2(1280, 720))
	if not (abode.buildings.has("hut") and abode.buildings.has("garden") and abode.buildings.has("altar")):
		_fail("The living abode must expose hut, garden, and altar buildings")
		return
	var viewport: Vector2 = abode.get_viewport_rect().size
	if viewport.x < 1200 or viewport.y < 700:
		_fail("The desktop-first abode must use a 1280 x 720 class viewport")
		return
	if abode.header.size.x > 320 or abode.building_catalog.visible or abode.info_panel.get_parent() != abode.building_catalog.detail_slot:
		_fail("Landscape island mode must keep a compact HUD and embed building detail in management")
		return

	# Test ghost blueprint appearance when affordable and direct world-click construction
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(25.0)
	abode._refresh_hud()
	if not abode.buildings["hut"].visible:
		_fail("Unbuilt hut must be visible as a ghost blueprint when affordable")
		return
	abode._pick_world(abode.buildings["hut"].to_global(Vector2(0, -60)))
	if abode.session.state.buildings.get("hut", 0) != 1 or abode.selected_id != "hut" or not abode.info_panel.visible or not abode.building_catalog.visible:
		_fail("Clicking unbuilt hut blueprint must directly construct hut and open management detail")
		return

	abode.state.qi = 100.0
	abode._refresh_hud()
	var qi_before: float = abode.state.qi
	abode._upgrade_selected()
	if abode.state.levels["hut"] != 2 or abode.state.qi >= qi_before:
		_fail("The selected building upgrade must update the independent state")
		return
	# A core-generated spirit wood find replaces the former permanent +1 tree.
	AbodeScenery.advance(abode.session.state, 12)
	abode._refresh_hud()
	var wood_before: float = abode.session.state.resources["wood"].value.to_float()
	var prop = abode.scenery_props.values()[0]
	abode._pick_world(prop.to_global(Vector2(0, -30)))
	var wood_after: float = abode.session.state.resources["wood"].value.to_float()
	if wood_after <= wood_before:
		_fail("Clicking a spirit wood find must claim its stored batch")
		return
	abode.session.state.buildings["herb_farm"] = 1
	abode._refresh_hud()
	if abode.buildings["garden"].visible:
		_fail("Routine herb farm must not appear as an unplanned island prop")
		return
	abode._close_detail()
	if not abode.building_catalog.visible or not abode.building_catalog.rows["herb_farm"].visible:
		_fail("Returning from detail must expose the herb farm in the building catalogue")
		return
	abode._select_building_from_catalog("herb_farm")
	if abode.selected_id != "herb_farm" or not abode.info_panel.visible:
		_fail("Selecting a catalogue building must open its detail panel")
		return
	abode._toggle_garden()
	if abode.state.garden_running:
		_fail("The garden detail action must pause its production line")
		return
	abode._toggle_overview()
	if abode.camera.target_zoom >= 0.34:
		_fail("Overview must move the same camera to the region scale")
		return
	abode._return_home()
	if not is_equal_approx(abode.camera.target_zoom, 0.70):
		_fail("Returning home must restore the local abode camera scale")
		return
	abode.queue_free()
	slots.reset()
	LivingAbodeScript.save_dir_override = ""
	print("PASS: living abode selects buildings, upgrades, pauses production, and changes scale.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
