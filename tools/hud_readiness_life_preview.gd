extends SceneTree
const OUT := "res://docs/verification/artifacts/hud-readiness-life-r1"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://hud-readiness-life-preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	var s: GameState = abode.session.state
	s.level = 5
	for id in ["hut","storage_lingli","storage_wood","storage_stone","stone_mine"]: s.buildings[id] = 1
	for id in ["lingli","wood","stone_low"]:
		s.resources[id].value = AmountCompat.from_number(200)
		s.resources[id].unlocked = true
	var req := Cultivation.next_level_required_seconds(abode.content.era(1),5,0.0,1.0)
	var samples := {"green":0.0,"yellow":1600.0,"orange":3200.0,"red":4320.0,"expired":4800.0,"ready":60.0,"near-full":60.0}
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		for id in samples:
			s.training_seconds = req - 0.1 if id == "near-full" else req
			s.total_elapsed_seconds = samples[id]
			s.resources.stone_low.value = AmountCompat.from_number(40 if id in ["ready","near-full"] else 38)
			abode._lifespan_prompted_cycle = s.reincarnation_count
			abode._refresh_hud()
			abode._layout_for_size(Vector2(vp))
			for frame in 14: await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(OUT+"/%s-%dx%d.png" % [id,vp.x,vp.y]) != OK:
				quit(1)
				return
	abode.queue_free()
	await process_frame
	quit(0)
