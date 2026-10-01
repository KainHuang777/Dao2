extends SceneTree
## Render-only preview. Isolated saves; no browser or input-test claims.
var OUT := "res://docs/verification/artifacts/ui-core"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var world_only := OS.get_cmdline_user_args().has("--world-captions")
	var guidance_only := OS.get_cmdline_user_args().has("--guidance-hud")
	var hud_only := OS.get_cmdline_user_args().has("--paper-hud") or guidance_only
	if world_only:
		OUT = "res://docs/verification/artifacts/ui-world"
	elif hud_only:
		OUT = "res://docs/verification/artifacts/ui-guidance" if guidance_only else "res://docs/verification/artifacts/ui-paper"
	if OS.get_cmdline_user_args().has("--font-trial"):
		OUT = "res://docs/verification/artifacts/ui-sans/guidance" if guidance_only else "res://docs/verification/artifacts/ui-sans/core"
	if OS.get_cmdline_user_args().has("--mixed-font"):
		OUT = "res://docs/verification/artifacts/ui-mixed/guidance" if guidance_only else "res://docs/verification/artifacts/ui-mixed/core"
	if OS.get_cmdline_user_args().has("--quiet-material"):
		OUT = "res://docs/verification/artifacts/ui-quiet/guidance" if guidance_only else "res://docs/verification/artifacts/ui-quiet/core"
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://ui_material_preview"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	var abode = script.new()
	root.size = Vector2i(1280, 720)
	root.add_child(abode)
	abode.set_process(false)
	# The normal boot summary is not part of the three material samples.
	await process_frame
	if abode.offline_summary != null:
		abode.offline_summary.visible = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if hud_only:
		await _capture("hud-quantity-1280x720")
		if OS.get_cmdline_user_args().has("--quiet-material"):
			# Style-only CTA fixture, no command or progression change.
			abode.breakthrough_button.visible = true
			abode.breakthrough_button.disabled = false
			abode._reflow_header()
			await _capture("primary-action-1280x720")
			abode._refresh_hud()
		if guidance_only:
			# Only this isolated preview Session is advanced to completed onboarding.
			for milestone in Onboarding.MILESTONES:
				abode.session.state.buildings[milestone.building] = milestone.level
			abode._refresh_hud()
			abode._push_hint_log(abode.hint.text)
			abode._layout()
			await _capture("completed-island-1280x720")
			abode._open_building_catalog()
			await _capture("completed-management-1280x720")
			abode._close_building_catalog()
			root.size = Vector2i(844, 390)
			await process_frame
			abode._layout()
			await _capture("messages-844x390")
			abode.queue_free()
			await process_frame
			slots.reset()
			quit(0)
			return
		# Extra rows and full storage are presentation fixtures only.
		var fixture_view: Dictionary = abode.session.get_view()
		var resources := {"lingli": {"value": "25", "cap": "100", "rate": "1", "visible": true, "unlocked": true, "type": "basic"}, "money": {"value": "100", "cap": "100", "rate": "0.5", "visible": true, "unlocked": true, "type": "basic"}, "wood": {"value": "12", "cap": "100", "rate": "0", "visible": true, "unlocked": true, "type": "basic"}}
		abode.building_catalog.refresh(fixture_view.buildings, resources, 1)
		abode._set_resource_display_mode(2)
		await _capture("hud-full-1280x720")
		abode._set_resource_display_mode(0)
		await _capture("hud-closed-1280x720")
		abode._set_resource_display_mode(1)
		root.size = Vector2i(844, 390)
		await process_frame
		abode._layout()
		await _capture("hud-quantity-844x390")
		abode.queue_free()
		await process_frame
		slots.reset()
		quit(0)
		return
	if world_only:
		# Built hut is a render fixture, without changing GameSession or user saves.
		var hut = abode.buildings["hut"]
		hut.level = 1
		hut.visible = true
		await _capture("island-1280x720")
		abode.spirit_tree._spawn_floating_text("+1 木材")
		await _capture("harvest-1280x720")
		root.size = Vector2i(844, 390)
		await process_frame
		abode._layout()
		await _capture("island-844x390")
		root.size = Vector2i(1280, 720)
		await process_frame
		abode._layout()
		abode.camera.set_process(false)
		abode.camera.zoom = Vector2.ONE * 1.25
		abode.camera.position = hut.global_position + Vector2(150, -30)
		await _capture("captions-close-1280x720")
		abode.queue_free()
		await process_frame
		slots.reset()
		quit(0)
		return
	await _capture("home-1280x720")
	abode._open_building_catalog()
	await _capture("catalog-1280x720")
	_catalog_states(abode)
	await _capture("catalog-states-1280x720")
	root.size = Vector2i(844, 390)
	await process_frame
	abode._layout()
	_catalog_states(abode)
	await _capture("catalog-844x390")
	abode._close_building_catalog()
	await _capture("home-844x390")
	root.size = Vector2i(1280, 720)
	await process_frame
	abode._layout()
	for key in ["alchemy_panel", "reincarnation_panel", "realm_modal", "sect_panel", "save_controls"]:
		var panel = abode.get(key)
		panel.visible = true
		if key == "alchemy_panel": panel.update_view(abode.session.get_view())
		if key == "reincarnation_panel":
			panel.refresh(abode.session.get_view())
			panel._switch_tab("talents")
		if key == "realm_modal": panel.refresh(abode.session.get_view())
		if key == "sect_panel":
			var state := GameState.new()
			state.era_id = 2
			SectSystem.join_sect(state, "紫霄玄門")
			panel.update_view(state)
		abode._layout()
		await _capture(key + "-1280x720")
		if key == "sect_panel":
			print("SECT_PREVIEW scroll=", panel._scroll.size, " content=", panel._tab_content_container.size, " min=", panel._tab_content_container.get_combined_minimum_size(), " children=", panel._tab_content_container.get_child_count())
		root.size = Vector2i(844, 390)
		await process_frame
		abode._layout()
		await _capture(key + "-844x390")
		panel.visible = false
		root.size = Vector2i(1280, 720)
		await process_frame
	abode._open_nine_realms_overview()
	await _capture("nine-realms-1280x720")
	abode.queue_free()
	await process_frame
	slots.reset()
	quit(0)

func _catalog_states(abode: Node) -> void:
	# Presentation fixture only. Never changes GameSession or the save snapshot.
	var resources := {"money": {"value": "100", "cap": "200", "visible": true}, "wood": {"value": "25", "cap": "100", "visible": true}}
	var buildings := {
		"hut": {"visible": true, "level": 1, "level_cap": 10, "affordable": true, "costs": {"money": "100"}},
		"wooden_house": {"visible": true, "level": 0, "level_cap": 10, "affordable": false, "costs": {"wood": "100", "money": "100"}},
		"forest_farm": {"visible": true, "level": 0, "level_cap": 10, "affordable": false, "costs": {"money": "100"}, "prereq": {"building": "wooden_house", "level": 2}},
		"stone_mine": {"visible": true, "level": 10, "level_cap": 10, "affordable": false, "costs": {"money": "100"}},
	}
	abode.building_catalog.refresh(buildings, resources)

func _capture(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT + "/" + filename + ".png")
	if err != OK:
		push_error("Preview save failed: " + filename)
		quit(1)
	print("UI_MATERIAL_CAPTURE ", filename, " viewport=", root.get_visible_rect().size)
