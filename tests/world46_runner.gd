extends SceneTree
## Synthetic presentation contracts; no claim of earned or natural-time progression.
var checks := 0
var failures: Array[String] = []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("world46")
	if script.save_dir_override == "world46": script.save_dir_override = "user://world46_runner"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	for i in 6: await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var session := GameSession.create_new_game(abode.content)
	session.state.era_id = 6
	check(session.submit({"type":"activate_islands","command_id":"world46-init","expected_revision":session.state.revision,"payload":{}}).ok,"diagnostic activation")
	abode.session.state = session.state
	var world = abode.island_world
	world.refresh()
	for id in ["deep","ancient","void"]:
		check(world.bodies[id].texture != null and world.bodies[id].texture.resource_path.ends_with("world46/"+id+"_body.png"),"dedicated terrain "+id)
		check(not world.landmarks[id].visible,"unopened landmark hidden "+id)
		session.state.economy.islands[id].opened = true
	abode._refresh_hud()
	var before := JSON.stringify(session.state.to_snapshot_dict())
	for size in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = size
		await process_frame
		abode._layout_for_size(Vector2(size))
		for id in ["deep","ancient","void"]:
			world.enter(id)
			for i in 4: await process_frame
			world.refresh()
			check(world.current == id and world.landmarks[id].visible,"remote entry "+id)
			check(world.destination_ids.size() == 7,"seven destinations")
			check(world.destination_picker.size.y >= 44,"picker hit height")
			check(world.destination_picker.get_global_rect().end.x <= size.x and world.manage_button.get_global_rect().end.y <= abode.toolbar.get_global_rect().position.y,"safe rail "+str(size))
			var art: Sprite2D = world.landmarks[id]
			var mask: BitMap = world.landmark_masks[id]
			var hit := false
			for y in range(0,mask.get_size().y,16):
				for x in range(0,mask.get_size().x,16):
					if mask.get_bitv(Vector2i(x,y)):
						hit = world.pick(art.global_transform * (art.get_rect().position+Vector2(x,y)))
						break
				if hit: break
			check(hit and abode.feature_navigation.page == "outposts" and abode.feature_navigation.island_panel.island == id,"opaque raw landmark routes to management "+id)
			var panel = abode.feature_navigation.island_panel
			check(not panel.world_button.disabled,"management reverse route "+id)
			panel.world_requested.emit(id)
			check(world.current == id and abode.feature_navigation.group == "home","reverse route home shell "+id)
			if DisplayServer.get_name() != "headless":
				await process_frame
				get_root().get_texture().get_image().save_png(RunnerResult.output_path("res://docs/verification/artifacts/world46-"+id+"-"+str(size.x)+".png"))
	var after := session.state.to_snapshot_dict()
	var prior: Dictionary = JSON.parse_string(before)
	for key in after:
		if JSON.stringify(prior.get(key)) != JSON.stringify(after[key]): print("WORLD46_CHANGED ",key," before=",JSON.stringify(prior.get(key))," after=",JSON.stringify(after[key]))
	check(before == JSON.stringify(session.state.to_snapshot_dict()),"world and management leave complete rule snapshot unchanged")
	for route_id in IslandEconomy.supply_data().routes:
		var route: Array = IslandEconomy.route_defs(session.state)[route_id]
		session.state.economy.trips = {route_id:{"cargo":"1","remaining":10}}
		world.refresh()
		check(world.cargo_swords[route_id].visible,"loaded supply flight "+route_id)
		var leg: Dictionary = world._cargo_leg(route_id)
		check(leg.start == world.LOCATIONS[route[0]]+Vector2(-280,40) and leg.finish == Vector2(-280,40),"catalog endpoint "+route_id)
		session.state.economy.trips[route_id].cargo = "0"
		world.refresh()
		check(not world.cargo_swords[route_id].visible,"no empty flight "+route_id)
	session.state.economy.trips = {}
	for era in [5,4,3]:
		session.state.era_id = era
		world.refresh()
		check(not world.roots.void.visible and not world.destination_ids.has("void"),"era gate "+str(era))
	world.enter("deep")
	check(world.current == "home","locked direct entry refused")
	session.state.era_id = 6
	session.state.economy.version = IslandProgression.VERSION
	world.refresh()
	check(not world.roots.deep.visible and not world.pick(world.LOCATIONS.deep),"old profile hidden and unpickable")
	session.state.economy.version = IslandProgression.SUPPLY_VERSION
	world.enter("void")
	session.state.era_id = 1
	world.refresh()
	check(world.current == "home" and not world.rail.visible,"rebirth returns home")
	abode.queue_free()
	await process_frame
	SaveManager.reset_for_tests()
	script.save_dir_override = ""
	for label in failures: push_error(label)
	print("WORLD46 checks=",checks," failures=",failures)
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
