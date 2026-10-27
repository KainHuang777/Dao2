extends SceneTree
var OUT := RunnerResult.output_path("res://docs/verification/artifacts/content-p2-pills-ui/")
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("UI FAILURE ",label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	load("res://src/abode/living_abode.gd").save_dir_override = "user://pill2-ui-runner"
	SaveSlots.new(FileStorageAdapter.new("user://pill2-ui-runner")).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var s: GameState = abode.session.state
	s.era_id = 5
	s.highest_era = 6
	abode.session.submit({"type":"activate_islands","payload":{},"command_id":"pill2-ui-activate","expected_revision":s.revision})
	for island in s.economy.islands: s.economy.islands[island].opened = true
	for id in ["core_storehouse_4","core_storehouse_5"]: s.buildings[id] = 1
	for id in s.resources: s.resources[id].value = AmountCompat.from_number(1000000)
	for id in AlchemySystem.P2_IDS: s.pills[id] = 5
	var page: AlchemyPanel = abode.alchemy_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode.feature_navigation.open("alchemy")
		page.update_view(abode.session.get_view())
		await frames()
		check(page._pill_rows.size() == 20,"20 cards")
		check(page._close_button is CloseSeal,"shared close")
		for id in AlchemySystem.P2_IDS:
			var row: Control = page._pill_rows[id]
			var w: Dictionary = page._widgets[id]
			check(w.output.icon.resource_texture() != null,"own art "+id)
			check(w.output.icon.resource_id == id,"own ID "+id)
			check(w.status.visible and not w.status.text.is_empty(),"visible preview "+id)
			check(not "PILL_" in w.status.text,"translated reason "+id)
			var p: Dictionary = {}
			for entry in abode.session.get_view().alchemy.pills:
				if entry.id == id: p = entry
			check(w.refine.disabled == not p.can_refine and w.consume.disabled == not p.can_consume,"authoritative gate "+id)
			page._scroll.ensure_control_visible(row)
			await frames()
			check(row.size.x <= page._scroll.size.x+1,"width "+id)
			check(row.size.y <= page._scroll.size.y,"height "+id+" "+str(row.size)+" scroll "+str(page._scroll.size))
			for button in [w.refine,w.consume]:
				check(button.size.x >= 44 and button.size.y >= 44,"44px "+id)
				check(page._scroll.get_global_rect().encloses(button.get_global_rect()),"reachable "+id)
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"native-"+str(vp.x)+"-"+id+".png")
		# Verify previews against core fields across important refusal states.
		for gate in ["era","training","duration","capacity","ward"]:
			var original := s.duplicate_state()
			if gate == "era": s.era_id = 3
			if gate == "training": s.pill_effects.stacks = {"p2_training":99}
			if gate == "duration": BuffSystem.apply_buff(s,"p2_ancient_dew",600)
			if gate == "capacity": s.pill_effects.p2_capacity_counts = {"spirit_vessel_pill":5}
			if gate == "ward": s.pill_effects.stacks = {"calm_tribulation_pill":1}
			page.update_view(abode.session.get_view())
			var target: String = {"era":"void_meditation_pill","training":"nascent_breath_pill","duration":"ancient_herb_dew_pill","capacity":"spirit_vessel_pill","ward":"calm_tribulation_pill"}[gate]
			check(page._widgets[target].consume.disabled,"refusal "+gate)
			abode.session.state = original
			s = original
		abode.feature_navigation.home()
		check(not page.visible,"return home")
	var file := FileAccess.open(OUT+"ui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("PILL2 UI ",checks," checks failures=",JSON.stringify(failures))
	abode.queue_free()
	await frames()
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
