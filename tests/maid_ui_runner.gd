extends SceneTree
var checks := 0
var failures: Array[String] = []
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 8: await process_frame
func capture(label: String, vp: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-ui/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-ui-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	check(panel.meeting_image.texture == null, "CG loads only on first replay")
	check(nav.owner("characters") == "journey", "single narrative route belongs to journey")
	check(FeatureUnlocks.check("characters", {"era_id": 1}).state == FeatureUnlocks.State.AVAILABLE, "early art presentation available without recruitment")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var viewports := ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)])
	# Optional one-size native diagnostic for the new compact composition.
	if "--maid-short" in OS.get_cmdline_user_args(): viewports = [Vector2i(800,360)]
	for vp in viewports:
		root.size = vp
		root.content_scale_size = vp
		nav.open("characters")
		panel.show_mode("person")
		abode._layout_for_size(Vector2(vp))
		await frames()
		check(nav.page == "characters" and panel.visible and not nav.action_panel.visible, "route and single page")
		check(nav.tab_buttons.characters.button_pressed, "canonical shared tab selected")
		check(not nav.shell.effective.resource_entry, "narrative presentation has no unrelated inventory")
		check(not panel.tabs.work.disabled and not panel.tabs.bond.disabled, "duty and bond tabs are open")
		check(panel.name_label.get_theme_font("font") == UiTypography.character_title_font(), "vertical title uses central WenKai role")
		check(panel.line.get_theme_font("font") == UiTypography.body_font() and panel.line.get_theme_font_size("font_size") >= 18, "dialogue retains sans18")
		check(panel.portrait_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "portrait contains whole artwork")
		check(panel.get_global_rect().encloses(panel.copy_scroll.get_global_rect()), "single biography scroll fits workspace")
		check(nav.bar.get_global_rect().end.y <= panel.global_position.y + 1, "fixed shared navigation clears content")
		check(panel.get_global_rect().end.y <= abode.toolbar.global_position.y + 1, "page clears main navigation")
		await capture("person", vp)
		panel.portrait_button.pressed.emit()
		await frames()
		check(nav.portrait_viewer.visible and nav.shell.state.snapshot().overlay == "tool", "portrait uses shared blocking viewer overlay")
		check(nav.portrait_viewer.image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "full viewer contains the whole illustration")
		check(nav.portrait_viewer.size.y > panel.size.y, "viewer gains height beyond the page workspace")
		await capture("full-art", vp)
		nav.back()
		check(not nav.portrait_viewer.visible and panel.person.visible and nav.page == "characters", "Escape first closes viewer")
		for maid_id in panel.MAID_ORDER:
			panel.select_maid(maid_id)
			await frames()
			check(panel.selected_maid == maid_id and panel.maid_row.visible, "roster switches to %s before recruitment" % maid_id)
			check(panel.portrait_image.texture != null and not panel.portrait_placeholder.visible, "unrecruited %s keeps its full portrait" % maid_id)
			check(not String(panel.bio_text_label.text).is_empty(), "unrecruited %s keeps a readable biography" % maid_id)
			check(panel.recruit_box.visible and panel.recruit_button.disabled, "unrecruited %s previews the recruit gate" % maid_id)
			check(String(panel.maid_buttons[maid_id].tooltip_text).contains("尚未招募"), "roster marks %s as not recruited" % maid_id)
		panel.select_maid("qingheng")
		await frames()
		check(String(panel.maid_buttons.qingheng.tooltip_text).contains("尚未招募"), "fresh save also marks qingheng as not recruited")
		panel.tabs.meeting.pressed.emit()
		await frames()
		check(panel.meeting.visible and panel.meeting_image.texture != null and panel.line.text == panel.OPENING, "replay opens scene and native dialogue")
		check(panel.get_global_rect().encloses(panel.meeting.get_global_rect()), "scene and dialogue fit workspace")
		check(panel.get_global_rect().encloses(panel.line_scroll.get_global_rect()), "dialogue scrolling stays internal")
		check(panel.line_scroll.size.y >= 40, "dialogue retains a readable two-line viewport")
		check(panel.get_global_rect().end.y <= abode.toolbar.global_position.y + 1, "meeting clears main navigation")
		for choice in panel.choices.get_children():
			check(choice.size.y >= 44 and panel.get_global_rect().encloses(choice.get_global_rect()), "response remains visible and44px")
		await capture("meeting", vp)
		for index in panel.REPLIES.size():
			panel.choices.get_child(index).pressed.emit()
			await frames()
			check(panel.selected_reply == index and panel.line.text == panel.REPLIES[index], "native response changes only presentation")
			check(not panel.choices.visible and panel.replay.visible, "reply ends with replay action")
			panel.replay.pressed.emit()
			await frames()
			check(panel.selected_reply == -1 and panel.line.text == panel.OPENING, "replay resets transient dialogue")
		check(abode.session.state.to_snapshot_dict() == before, "art and every response leave state unchanged")
		# Existing tools own input and Escape, then return to this same page.
		nav.shell.open_tool(abode.save_controls)
		await frames()
		check(nav.shell.state.snapshot().overlay == "tool", "save tool can cover character page")
		nav.back()
		await frames()
		check(nav.page == "characters" and panel.meeting.visible and not abode.save_controls.visible, "tool return preserves scene")
		nav.back()
		check(nav.page == "characters" and panel.person.visible, "scene Escape returns to person")
		nav.back()
		await frames()
		check(nav.group == "home" and not panel.visible and not abode.camera.input_locked, "second Escape restores home camera")
		nav.open_group("journey")
		check(nav.page == "characters", "group remembers character route in memory")
		nav.open("alchemy")
		check(not panel.visible and abode.alchemy_panel.visible, "changing feature hides character page")
		nav.home()
	abode.queue_free()
	await process_frame
	print("MAID-UI checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
