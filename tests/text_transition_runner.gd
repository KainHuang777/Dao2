extends SceneTree
var failed := false
var starts := 0
var ends: Array[bool] = []

func _init() -> void:
	_run.call_deferred()

func expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var panel = load("res://src/presentation/text_transition.gd").new()
	root.add_child(panel)
	panel.sequence_started.connect(func(): starts += 1)
	panel.sequence_finished.connect(func(skipped: bool): ends.append(skipped))
	panel.play("境界等級提升至 LV2", "築基期 ERA2 — 壽元剩餘 80祀")
	panel.set_process(false)
	panel.advance_presentation(0.4)
	expect(panel.title_label.visible_ratio > 0 and panel.title_label.visible_ratio < 1, "Reveal has an intermediate character state")
	panel.skip()
	panel.skip()
	panel.advance_presentation(10)
	expect(starts == 1 and ends == [true] and not panel.visible, "Skip completes exactly once; stale elapsed time cannot complete again")
	panel.play("重播", "", {"mode": "fade", "hold": 0.5})
	panel.set_process(false)
	panel.advance_presentation(0.4)
	expect(panel.title_label.visible_ratio == 1 and not panel.subtitle_label.visible, "Fade supports an absent subtitle")
	panel.play("低動態", "修行不息", {"reduced_motion": true})
	panel.set_process(false)
	panel.advance_presentation(0.4)
	expect(ends == [true, true] and panel.title_label.visible_ratio == 1, "Replay cancels its predecessor; reduced motion has no character reveal")
	for viewport in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport
		await process_frame
		panel.title_label.text = "境界等級提升至 LV2・大道初成"
		panel._fit()
		await process_frame
		await process_frame
		var bounds: Rect2 = panel.content.get_global_rect()
		expect(bounds.position.x >= 0 and bounds.end.x <= viewport.x + 1 and bounds.position.y >= 0 and bounds.end.y <= viewport.y + 1, "Long title remains within resized viewport %s" % viewport)
		expect(panel.skip_button.size.y >= 44 and panel.skip_button.get_global_rect().end.y <= viewport.y, "Skip target stays reachable")
	panel.advance_presentation(10)
	expect(ends == [true, true, false] and not panel.visible, "Natural completion fires once after restart")
	panel.queue_free()
	await process_frame
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://text_transition_tests"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	var initial: Dictionary = abode.session.state.to_snapshot_dict()
	for was_locked in [false, true]:
		abode.camera.input_locked = was_locked
		abode.settings_menu.get_popup().id_pressed.emit(102)
		expect(abode.text_transition.visible and abode.camera.input_locked, "Settings preview opens native overlay and locks camera")
		abode.text_transition.skip()
		expect(abode.camera.input_locked == was_locked, "Skip restores prior camera lock ownership")
	expect(initial == abode.session.state.to_snapshot_dict(), "Preview and skip cannot change inventory, Era or save state")
	abode.queue_free()
	await process_frame
	if not failed:
		print("PASS: text transition replay/skip/completion, reduced motion, fade and responsive long titles")
	quit(1 if failed else 0)
