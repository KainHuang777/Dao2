extends SceneTree
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://island1_native_preview"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	root.size = Vector2i(1280, 720)
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.offline_summary.visible = false
	abode._toggle_guidance()
	abode.session.state.buildings.hut = 2
	for rid in ["wood", "spirit_grass_low", "stone_low"]:
		abode.session.state.resources[rid].unlocked = true
	AbodeScenery.advance(abode.session.state, 120)
	var dir := "res://docs/verification/artifacts/island1"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for era in [1, 2]:
		abode.session.state.era_id = era
		for viewport in [Vector2i(1280, 720), Vector2i(844, 390)]:
			root.size = viewport
			await process_frame
			for pair in [["wood", "herb"], ["stone", "wood"]]:
				for index in 2:
					var entry: Dictionary = abode.session.state.abode_scenery.active[index]
					entry.kind = pair[index]
					entry.slot = index if pair[0] == "wood" else index + 2
					entry.amount = AbodeScenery.DEFINITIONS[entry.kind].min
				for prop in abode.scenery_props.values():
					prop.queue_free()
				abode.scenery_props.clear()
				abode._refresh_hud()
				abode._layout()
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var path := dir + "/era%d-%s-%dx%d.png" % [era, pair[0], viewport.x, viewport.y]
				if root.get_texture().get_image().save_png(path) != OK:
					quit(1)
					return
				print("ISLAND1_CAPTURE ", path)
	# Isolated Web QA fixture; loaded only by the guarded docs fixture loader.
	abode.session.state.era_id = 2
	abode.session.state.revision += 1
	for index in 2:
		var entry: Dictionary = abode.session.state.abode_scenery.active[index]
		entry.kind = "wood" if index == 0 else "herb"
		entry.slot = index
		entry.amount = AbodeScenery.DEFINITIONS[entry.kind].min
	var now := str(int(Time.get_unix_time_from_system() * 1000))
	var encoded := SaveCodec.encode(abode.session.state, abode.content.content_version,
		{"save_id": "island1-test", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": "0"})
	var fixture := FileAccess.open("res://docs/verification/artifacts/island1/web-fixture.json", FileAccess.WRITE)
	fixture.store_string(encoded.json)
	fixture.close()
	abode.session.state.abode_scenery.active[0].kind = "stone"
	abode.session.state.abode_scenery.active[0].slot = 2
	abode.session.state.abode_scenery.active[0].amount = 2
	encoded = SaveCodec.encode(abode.session.state, abode.content.content_version,
		{"save_id": "island1-test", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": "0"})
	fixture = FileAccess.open("res://docs/verification/artifacts/island1/web-stone-fixture.json", FileAccess.WRITE)
	fixture.store_string(encoded.json)
	fixture.close()
	abode.queue_free()
	await process_frame
	slots.reset()
	quit(0)
