extends SceneTree
var checks := 0
var failures: Array[String] = []
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for n in 10: await process_frame
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://early16-ui-shell-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var nav = abode.feature_navigation
	var shell = nav.shell
	nav.open("buildings")
	await frames()
	check(not nav.tab_buttons.has("manufacturing") or not nav.tab_buttons.manufacturing.visible, "Era1 manufacturing stays hidden")
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned diagnostic state decodes")
	abode.session.state = decoded.state.duplicate_state()
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		for route in ["buildings", "outposts", "manufacturing", "transport"]:
			nav.open(route)
			abode._layout_for_size(Vector2(vp))
			await frames()
			var work = shell.workbench
			check(work.panel.visible and nav.bar.get_parent() == work.column, "shared container " + route)
			check(work.panel.get_global_rect().encloses(nav.bar.get_global_rect()), "tabs inside paper " + route)
			check(work.panel.get_global_rect().encloses(work.pages.get_global_rect()), "content inside paper " + route)
			check(work.pages.size.y >= 80, "scroll viewport retained " + route)
			check(not abode.building_catalog.close_button.is_visible_in_tree(), "no catalog duplicate close")
			for child in [nav.island_panel, nav.manufacturing_panel, nav.transport_panel]:
				check(not child.close_button.is_visible_in_tree(), "no page duplicate close")
			check(nav.back_button.is_visible_in_tree() and nav.back_button.size.y >= 44, "single header close remains")
			check(shell.compact_hud.size.x < vp.x * 0.65, "HUD stays local")
			check(shell.compact_hud.get_global_rect().encloses(abode.header_box.get_global_rect()) if shell.integrated_identity else shell.life_metrics.global_position.y > shell.metrics.global_position.y, "identity content stays grouped")
			check(work.panel.get_global_rect().encloses(shell.compact_hud.get_global_rect()) if shell.integrated_identity else shell.compact_hud.get_global_rect().end.y <= work.panel.global_position.y, "HUD shares workbench paper or clears it")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(RunnerResult.output_path("res://docs/verification/artifacts/early16-ui-shell/%s-%dx%d.png" % [route, vp.x, vp.y]))
			# Open a real overlay and return: no stale parent, loss of route or stock.
			shell.resource_button.pressed.emit()
			await frames()
			check(shell.shield.visible and not work.panel.visible, "stock overlay owns input")
			nav.back()
			await frames()
			check(nav.page == route and work.panel.visible, "overlay restores workbench " + route)
			nav.back_button.pressed.emit()
			await frames()
			check(nav.group == "home" and not work.panel.visible and abode.resource_ribbon.get_parent() == abode.hud, "close restores home")
		# Other feature routes still use their existing shell and action ownership.
		nav.open("alchemy")
		await frames()
		check(not shell.workbench.panel.visible and nav.bar.get_parent() == abode.hud, "non-management ownership restored")
	abode.queue_free()
	await process_frame
	print("EARLY16-UI-SHELL checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
