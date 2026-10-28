extends SceneTree
## Synthetic visual/navigation fixture; never claims earned progression.
var failures: Array[String] = []
var checks := 0
var abode
var first_size := Vector2i(1280,720)
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	var storage := OS.get_environment("DAO_TEST_STORAGE_ROOT")
	if storage.is_empty(): storage = "res://.test-output"
	script.save_dir_override = storage.path_join("imm1c-selector")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	abode = script.new()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var session := GameSession.create_new_game(abode.content)
	session.state.era_id = 6
	check(session.submit({"type":"activate_islands","command_id":"imm1c-init","expected_revision":session.state.revision,"payload":{}}).ok,"synthetic supply activation")
	abode.session.state = session.state
	for id in ["wood","ore","herb","deep","ancient","void"]: session.state.economy.islands[id].opened = true
	abode._refresh_hud()
	var world = abode.island_world
	var shell = abode.feature_navigation.shell
	var before := JSON.stringify(session.state.to_snapshot_dict())
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [first_size]):
		root.size = vp
		await frames()
		abode._layout_for_size(Vector2(vp))
		world.enter("home")
		world.show_selector()
		await frames()
		check(world.selector.visible and world.destination_ids.size() == 7,"all destinations available " + str(vp))
		var stable = world.buttons.void
		world.refresh()
		check(stable == world.buttons.void,"rows retained across refresh")
		for id in world.destination_ids:
			check(world.selector._images[id].texture != null,"authored thumbnail " + id)
			check(world.buttons[id].size.y >= 80,"large full row hit " + id)
		world.selector.reveal_current("void")
		await frames()
		var last: Rect2 = world.buttons.void.get_global_rect()
		check(last.position.y >= world.selector.scroll.global_position.y and last.end.y <= world.selector.scroll.get_global_rect().end.y+1,"last destination reachable by scrolling")
		world.buttons.void.pressed.emit()
		await frames()
		check(world.current == "void" and shell.state.snapshot().overlay.is_empty(),"selection navigates and closes compact overlay")
		check(world.selector._labels.void.text.contains("當前"),"selected island marked")
		var body: Sprite2D = world.bodies.void
		var terrain: Rect2 = body.global_transform * body.get_rect()
		var projected := Rect2((terrain.position-abode.camera.target_position)*abode.camera.target_zoom+Vector2(vp)*0.5,terrain.size*abode.camera.target_zoom)
		check(world.world_safe_rect(Vector2(vp)).grow(1).encloses(projected),"remote terrain fits visible world area " + str(vp))
		world.manage_current()
		check(abode.feature_navigation.page == "outposts" and abode.feature_navigation.island_panel.island == "void","manage selected destination")
		check(not world.selector.visible,"feature page hides world selector")
		abode.feature_navigation.island_panel.world_requested.emit("void")
		await frames()
		check(world.current == "void" and abode.feature_navigation.group == "home","management returns to same world")
		world.enter("home")
		world.close_selector()
		check(world.selector_button.is_visible_in_tree(),"collapsed selector retains entry")
		world.show_selector()
		await frames()
		check(world.selector.is_visible_in_tree(),"entry reopens selector")
		check(not abode.hint_panel.visible,"automatic tips yield after deferred layout")
		if vp.y < 500:
			check(shell.state.snapshot().overlay == "tool" and abode.camera.input_locked,"compact selector owns shared overlay and blocks world input")
			check(world.selector.get_global_rect().end.y <= vp.y,"compact selector inside viewport")
			shell.back()
			world.refresh()
			check(not world.selector.visible and not abode.camera.input_locked,"back restores world input")
		else:
			check(world.selector.get_global_rect().end.y < abode.toolbar.global_position.y,"wide selector above navigation")
			var safe: Rect2 = world.world_safe_rect(Vector2(vp))
			check(safe.end.x <= world.selector.position.x,"camera avoids wide list")
		if DisplayServer.get_name() != "headless":
			await frames()
			root.get_texture().get_image().save_png(RunnerResult.output_path("res://docs/verification/artifacts/imm1c-home-"+str(vp.x)+".png"))
	check(before == JSON.stringify(session.state.to_snapshot_dict()),"selection and management preserve complete rule state")
	session.state.era_id = 2
	world.refresh()
	check(world.destination_ids.size() == 4 and world.selector._labels.herb.text.contains("金丹解鎖"),"Era2 retains existing Danxia preview")
	session.state.era_id = 1
	world.refresh()
	check(not world.selector.visible and not world.rail.visible,"Era1 has no island selector")
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	SaveManager.reset_for_tests()
	for label in failures: push_error(label)
	print("IMM1C checks=",checks," failures=",failures)
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
