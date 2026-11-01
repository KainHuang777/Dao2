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
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-stand/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-stand-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	var stand = abode.maid_stand
	check(stand != null, "abode mounts the maid stand")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var vp := Vector2i(1280, 720)
	root.size = vp
	root.content_scale_size = vp
	abode._layout_for_size(Vector2(vp))
	await frames()
	check(stand.visible and stand.panel.visible and not stand.tab.visible, "wide abode shows the expanded half-body stand")
	check(stand.portrait.texture is AtlasTexture and stand.portrait.texture.region == stand.CROP, "stand crops the accepted full-body portrait")
	check(stand.portrait.texture.atlas != null, "portrait artwork is loaded")
	check(String(stand.name_label.text) == "青蘅", "fresh save previews the first maid")
	check(not String(stand.status_label.text).is_empty(), "stand explains its current status")
	var rect: Rect2 = stand.panel.get_global_rect()
	check(rect.end.x <= float(vp.x) + 0.5 and rect.end.y <= abode.toolbar.global_position.y + 0.5, "expanded stand stays above navigation and inside the viewport")
	if abode.hint_panel.visible:
		check(rect.position.x >= abode.hint_panel.get_global_rect().end.x, "expanded stand clears the message panel")
	for button in [stand.prev_button, stand.next_button, stand.open_button, stand.collapse_button]:
		check(button.size.y >= 44.0, "stand action keeps a 44px target")
	await capture("stand", vp)
	stand.next_button.pressed.emit()
	await frames()
	check(stand.selected_id() == "nuomeizi" and String(stand.name_label.text) == "糯美子", "next switches the displayed maid")
	check(String(stand.portrait.texture.atlas.resource_path).contains("nuomeizi"), "switching the display loads that maid's artwork")
	stand.prev_button.pressed.emit()
	await process_frame
	check(stand.selected_id() == "qingheng", "previous returns to the first maid")
	stand.refresh({"maid": {"active_duty": "danxia", "maids": {"danxia": {"name": "丹霞", "role": "丹師", "recruited": true, "duty": {}, "duty_actions": 0}}}})
	check(stand.selected_id() == "qingheng", "manual display choice outranks the on-duty default")
	var probe = load("res://src/presentation/maid_stand_display.gd").new(abode)
	abode.hud.add_child(probe)
	probe.refresh({"maid": {"active_duty": "danxia", "maids": {"danxia": {"name": "丹霞", "role": "丹師", "recruited": true, "duty": {}, "duty_actions": 0}}}})
	check(probe.selected_id() == "danxia", "without a manual choice the on-duty maid is shown")
	probe.queue_free()
	await process_frame
	stand.refresh(abode.session.get_view())
	stand.collapse_button.pressed.emit()
	await frames()
	check(stand.visible and not stand.panel.visible and stand.tab.visible, "collapse leaves a lone reopen tab")
	check(stand.tab.get_global_rect().end.y <= abode.toolbar.global_position.y + 0.5, "collapsed tab clears navigation")
	check(stand.tab_button.size.y >= 44.0, "reopen tab keeps a 44px target")
	await capture("collapsed", vp)
	stand.tab_button.pressed.emit()
	await frames()
	check(stand.panel.visible and not stand.tab.visible, "tab reopens the half-body stand")
	stand.open_button.pressed.emit()
	await frames()
	check(abode.feature_navigation.group == "journey" and abode.feature_navigation.page == "characters", "stand opens the canonical character page")
	check(not stand.visible, "stand yields to feature pages")
	abode.feature_navigation.home()
	await frames()
	abode._layout_for_size(Vector2(vp))
	check(stand.visible and stand.panel.visible, "stand returns with the abode")
	check(abode.session.state.to_snapshot_dict() == before, "display, switching and navigation never change state")
	vp = Vector2i(844, 390)
	root.size = vp
	root.content_scale_size = vp
	abode._layout_for_size(Vector2(vp))
	await frames()
	check(not stand.visible, "short landscape keeps the world and messages unobstructed")
	abode.queue_free()
	await process_frame
	print("MAID-STAND checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
