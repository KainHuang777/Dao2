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
	var formal_starts := [0]
	abode.text_transition.sequence_started.connect(func(): formal_starts[0] += 1)
	for era_id in abode.content.era_ids:
		for previous_level in [1, 9]:
			abode.session.state.era_id = era_id
			abode.session.state.level = previous_level
			abode.session.state.total_elapsed_seconds = 120.0
			var era: Dictionary = abode.content.era(era_id)
			abode.session.state.training_seconds = Cultivation.next_level_required_seconds(era, previous_level, 0.0, 1.0)
			for resource_id in Cultivation.level_up_cost(era, previous_level, 0.0):
				abode.session.state.resources[resource_id].value = Cultivation.level_up_cost(era, previous_level, 0.0)[resource_id]
			abode.camera.input_locked = false
			abode.reduced_motion = era_id % 2 == 0
			expect(abode._level_up_cultivation(), "Formal level command succeeds in Era %d" % era_id)
			expect(abode.session.state.era_id == era_id and abode.session.state.level == previous_level + 1, "Level gain keeps current Era")
			expect(abode.text_transition.title_label.text == "境界等級提升至 LV%d" % (previous_level + 1), "Title uses committed level")
			var remaining := maxf(0.0, float(abode.session.get_view().max_lifespan_seconds) - 120.0) / 60.0
			expect(abode.text_transition.subtitle_label.text == "%s ERA%d · 壽元剩餘 %.0f 祀" % [String(era.name), era_id, remaining], "Subtitle uses actual Era and remaining lifespan")
			expect(abode.text_transition.visible and abode.camera.input_locked and not abode.breakthrough_seq.visible, "Small level uses text only and locks camera")
			expect(abode.hud.get_child(-1) == abode.text_transition and abode.text_transition.z_index > abode.toolbar.z_index, "Overlay owns visual and input stacking above toolbar")
			var committed: Dictionary = abode.session.state.to_snapshot_dict()
			expect(not abode._level_up_cultivation(), "Playing sequence blocks another level command")
			abode._breakthrough_era()
			expect(committed == abode.session.state.to_snapshot_dict(), "Playing sequence cannot trigger Era command")
			abode.text_transition.advance_presentation(0.1)
			expect(abode.text_transition.modulate.a == 1.0, "Black remains opaque during entry")
			if previous_level == 1:
				abode.text_transition.skip()
			else:
				abode.text_transition.advance_presentation(10.0)
			expect(not abode.text_transition.visible and not abode.camera.input_locked, "Skip and natural completion restore camera")
			expect(committed == abode.session.state.to_snapshot_dict(), "Completion cannot grant or change state")
			expect(not abode._level_up_cultivation() and not abode.text_transition.visible, "Insufficient training or max level never starts sequence")
	expect(formal_starts[0] == abode.content.era_ids.size() * 2, "Exactly one sequence for each real level gain across configured Eras")
	abode.queue_free()
	await process_frame
	if not failed:
		print("PASS: text transition replay/skip/completion, reduced motion, fade and responsive long titles")
	quit(1 if failed else 0)
