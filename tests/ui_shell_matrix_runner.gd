extends SceneTree
## Full canonical matrix on isolated earned-era3 diagnostic state.
var checks := 0
var failures: Array[String] = []
var abode: Node
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 7: await process_frame
func capture(route: String, vp: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/verification/artifacts/ui-shell-2/%s-%dx%d.png" % [route, vp.x, vp.y])
func _run() -> void:
	load("res://src/abode/living_abode.gd").save_dir_override = "user://ui-shell-2-matrix"
	SaveSlots.new(FileStorageAdapter.new("user://ui-shell-2-matrix")).reset()
	abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned era3 fixture decodes")
	abode.session.state = decoded.state.duplicate_state()
	abode.session.state.reincarnation_count = 1
	StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
	abode.session.state.tutorial_flags.seen_nine_realms_hook = true
	abode._refresh_hud()
	var nav = abode.feature_navigation
	var shell = nav.shell
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for mode in [0, 1, 2]:
		nav.home()
		abode._set_resource_display_mode(mode)
		var prefs: Dictionary = shell.state.snapshot().home_preferences
		for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
			root.size = vp
			root.content_scale_size = vp
			for group in nav.GROUPS:
				for entry in nav.GROUPS[group].pages:
					var route: String = entry[0]
					nav.open(route)
					abode._layout_for_size(Vector2(vp))
					await frames()
					check(nav.page == route and shell.state.snapshot().route == route, "canonical " + route)
					check(shell.compact_hud.visible and not abode.header.visible, "compact HUD " + route)
					check(not abode.hint_panel.visible, "no home messages " + route)
					check(not abode._hud_controller._goal_scroll.visible, "home goal hidden in workspace " + route)
					check(shell.state.snapshot().home_preferences == prefs, "preferences " + route)
					check(shell.compact_hud.get_global_rect().end.y <= nav.bar.position.y, "HUD clears tabs " + route)
					check(nav.bar.get_global_rect().end.y <= 136, "tabs clear content " + route)
					check(abode.level_up_button.get_parent() == shell.actions, "single action host " + route)
					check(abode.camera.input_locked, "workspace locks world " + route)
					if mode == 0: await capture(route, vp)
					abode._toggle_save_controls()
					check(nav.page == route and shell.shield.visible, "tool preserves " + route)
					nav.back()
					check(nav.page == route and not shell.shield.visible, "tool returns " + route)
					shell.toggle_overlay("messages")
					check(shell.shield.visible and abode.hint_panel.visible, "reading " + route)
					nav.back()
					check(nav.page == route, "reading returns " + route)
					if shell.effective.resource_entry:
						shell.toggle_resources()
						abode._refresh_hud()
						check(shell.state.snapshot().resources_collapsed and not abode.resource_ribbon.visible and not shell.context_paper.visible, "collapse survives tick " + route)
						shell.toggle_overlay("resources")
						check(shell.shield.visible and (abode.resource_ribbon.visible or shell.context_paper.visible), "scoped drawer " + route)
						nav.back()
						shell.toggle_resources()
			nav.home()
			check(abode.resource_display_mode == mode and shell.state.snapshot().home_preferences == prefs, "home restores mode %d" % mode)
	# Tabs are observed without clearing temporary collapse, drafts, or scroll.
	nav.open("reincarnation")
	abode.reincarnation_panel._switch_tab("talents")
	abode._layout_for_size(Vector2(800,360))
	check(shell.effective.resource_context == "focused" and shell.resource_button.visible, "talent currency context")
	shell.toggle_resources()
	abode.reincarnation_panel._switch_tab("reincarnate")
	abode._layout_for_size(Vector2(800,360))
	check(shell.effective.resource_context == "none" and shell.state.snapshot().resources_collapsed, "reading tab retains override")
	nav.open("sect")
	for tab in [0, 1, 2]:
		abode.sect_panel._switch_tab(tab)
		abode._layout_for_size(Vector2(800,360))
		check(shell.effective.resource_context == ("focused" if tab == 0 else "inventory"), "sect subpage resource context %d" % tab)
	# Unsubmitted production/transport fields survive tools, routes and resize.
	nav.open("manufacturing")
	var manufacturing = nav.manufacturing_panel
	var recipe: String = manufacturing.cards.keys()[0]
	manufacturing.select_recipe(recipe)
	manufacturing.batch_count.value = 27
	manufacturing._store_draft()
	var draft: Dictionary = manufacturing.recipe_drafts.duplicate(true)
	nav.open("transport")
	var transport = nav.transport_panel
	var route_id: String = IslandEconomy.ROUTES.keys()[0]
	transport.select_route(route_id)
	transport.reserve.text = "17"
	transport.target.text = "89"
	transport._edit_draft()
	var transport_drafts: Dictionary = transport.drafts.duplicate(true)
	shell.open_tool(abode.save_controls)
	nav.back()
	nav.open("manufacturing")
	abode._layout_for_size(Vector2(1280,720))
	check(manufacturing.selected_recipe == recipe and manufacturing.batch_count.value == 27 and manufacturing.recipe_drafts == draft, "manufacturing draft and settings survive route/resize")
	nav.open("transport")
	check(transport.selected_route == route_id and transport.reserve.text == "17" and transport.target.text == "89" and transport.drafts == transport_drafts, "transport unsaved draft survives tools/route")
	# Pending encounter is unchanged by shelving; affordability uses current View.
	for encounter in FortuneSystem.get_encounters():
		if encounter.id == "enc_wandering_taoist": abode.session.state.fortune.pending_encounter = encounter.duplicate(true)
	abode.session.state.resources.spirit_grass_low.value = AmountCompat.from_number(1000)
	abode._refresh_hud()
	nav.open("fortune")
	var pending: Dictionary = abode.session.state.fortune.pending_encounter.duplicate(true)
	check(shell.effective.resource_context == "focused" and shell.resource_button.visible, "paid fortune resources visible")
	check(not abode.fortune_modal._option_rows[0].button.disabled, "paid choice initially affordable")
	nav.open("buildings")
	abode.session.state.resources.spirit_grass_low.value = AmountCompat.zero()
	abode._refresh_hud()
	nav.open("fortune")
	check(abode.session.state.fortune.pending_encounter == pending and abode.fortune_modal._option_rows[0].button.disabled, "same encounter refreshes affordability after spending")
	# Contextual shortcuts cannot mutate a background draft under a modal shield.
	shell.open_tool(abode.save_controls)
	nav.open_transport(route_id)
	check(nav.page == "fortune" and transport.drafts == transport_drafts, "blocked shortcut preserves background draft")
	nav.back()
	# First click opens confirmation, Escape cancels without leaving or paying.
	abode.session.state.total_elapsed_seconds = float(abode.session.get_view().max_lifespan_seconds)
	abode._refresh_hud()
	nav.open("reincarnation")
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	abode.reincarnation_panel._reincarnate_action_button.pressed.emit()
	check(abode.reincarnation_panel._confirming, "first click confirms only")
	nav.back()
	check(not abode.reincarnation_panel._confirming and nav.page == "reincarnation", "Escape cancels confirmation only")
	check(before == abode.session.state.to_snapshot_dict(), "confirmation no state mutation")
	abode.reincarnation_panel._reincarnate_action_button.pressed.emit()
	nav.open("buildings")
	check(not abode.reincarnation_panel._confirming and before == abode.session.state.to_snapshot_dict(), "route change cancels confirmation")
	# Route revalidation must align both state and visible page after eligibility loss.
	abode.session.state.era_id = 1
	abode.session.state.reincarnation_count = 0
	StoryProgress.next_life(abode.session.state) # Keep synthetic life fixture consistent with story v1.
	abode.session.state.total_elapsed_seconds = 0
	abode._refresh_hud()
	nav.open("beasts")
	check(nav.page == shell.state.snapshot().route and nav.page != "beasts", "hidden contextual route uses legal fallback")
	abode.queue_free()
	await process_frame
	print("UI-SHELL-2 checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
