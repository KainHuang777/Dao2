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
	if not (abode.buildings.has("hut") and abode.buildings.has("garden") and abode.buildings.has("altar")):
		_fail("The living abode must expose hut, garden, and altar buildings")
		return
	var viewport: Vector2 = abode.get_viewport_rect().size
	if viewport.x < 1200 or viewport.y < 700:
		_fail("The desktop-first abode must use a 1280 x 720 class viewport")
		return
	if abode.header.size.x < 320 or abode.info_panel.position.x <= viewport.x * 0.55:
		_fail("Landscape HUD must keep state at left and detail at right")
		return
	abode.buildings["hut"].visible = true
	abode.session.state.buildings["hut"] = 1
	abode.state.qi = 100.0
	abode._refresh_hud()
	abode._pick_world(abode.buildings["hut"].position + Vector2(0, -60))
	if abode.selected_id != "hut" or not abode.info_panel.visible:
		_fail("Selecting the hut must open its detail panel")
		return
	var qi_before: float = abode.state.qi
	abode._upgrade_selected()
	if abode.state.levels["hut"] != 2 or abode.state.qi >= qi_before:
		_fail("The selected building upgrade must update the independent state")
		return
	abode.buildings["garden"].visible = true
	abode.session.state.buildings["herb_farm"] = 1
	abode._refresh_hud()
	abode._pick_world(abode.buildings["garden"].position + Vector2(0, -50))
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
