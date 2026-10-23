extends SceneTree
const Scene = preload("res://scenes/living_abode.tscn")
const Abode = preload("res://src/abode/living_abode.gd")
const Fixture = preload("res://src/verification/trib0_fixture.gd")
const DIR := "user://tribc-isolated"
var failures: Array = []
var checks := 0
var capture := false

class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new(DIR)
	var deny := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok": false, "error": "TEST_WRITE_DENIED"} if deny else backend.write(key, value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func backend_name() -> String: return "trib0_test_only"

func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	Abode.save_dir_override = DIR
	var adapter := ToggleAdapter.new()
	var slots := SaveSlots.new(adapter)
	slots.reset()
	var abode = Scene.instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	abode.offline_summary.hide()
	Fixture.attach(abode.content)
	SaveManager.configure(abode.content, adapter)
	var seq = abode.breakthrough_seq
	seq.set_process(false)
	for success in [false, true]:
		abode.session = GameSession.create_new_game(abode.content)
		abode.state = abode.AbodeStateCompat.new(abode.session)
		Fixture.seed_state(abode.session.state, success)
		abode._last_breakthrough_result.clear()
		abode._refresh_hud()
		var before: Dictionary = abode.session.state.to_snapshot_dict()
		abode._request_breakthrough()
		expect(seq._preparing and seq._detail_label.text.contains("83.0%"), "prepare reads pill-adjusted probability")
		expect(abode.session.state.to_snapshot_dict() == before, "prepare never rolls")
		for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
			root.size = vp
			root.content_scale_size = vp
			abode._layout_for_size(Vector2(vp))
			for frame in 4: await process_frame
			expect(Rect2(Vector2.ZERO,Vector2(vp)).encloses(seq._result_panel.get_global_rect()), "preparation fits %s" % vp)
			await _capture("prepare-%s-%dx%d" % [success,vp.x,vp.y])
		seq._on_close_pressed()
		expect(not abode.camera.input_locked and abode.session.state.to_snapshot_dict() == before, "cancel restores camera without rolling")
		abode._request_breakthrough()
		adapter.deny = true
		abode.bgm_player.volume_db = -3.0
		seq._confirm_button.pressed.emit()
		expect(seq._tribulation_mode and seq._is_playing and seq._tribulation_stage.visible, "both outcomes enter accepted storm stage")
		expect(seq._tribulation_stage.failed == not success, "stage reads event outcome")
		expect(seq._storm_audio.playing and is_equal_approx(abode.bgm_player.volume_db, -15.0), "storm plays and ducks BGM once")
		expect(not abode.island_fx.active, "old island effect cannot overlap storm")
		seq._process(7.6)
		expect(seq._tribulation_stage.strike > .5, "first bolt hits the pose core")
		var stage_time: float = seq._tribulation_stage.clock
		for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
			root.size = vp
			root.content_scale_size = vp
			abode._layout_for_size(Vector2(vp))
			for frame in 4: await process_frame
			expect(seq._tribulation_stage.clock == stage_time, "resize preserves storm time")
			expect(Rect2(Vector2.ZERO,Vector2(vp)).encloses(seq._skip_button.get_global_rect()), "storm skip fits %s" % vp)
			expect(seq._skip_button.size.y >= 44, "storm skip retains 44px")
			await _capture("strike-%s-%dx%d" % [success,vp.x,vp.y])
		expect(abode.session.state.era_id == (4 if success else 2), "confirmed command commits correct era")
		expect(abode.session.state.tribulation_roll_index == int(before.tribulation_roll_index) + 1, "one roll per confirmation")
		expect(abode._last_breakthrough_result.kind == ("tribulation_passed" if success else "tribulation_failed"), "formal outcome event wins over ok")
		expect(abode._pending_breakthrough_save and seq._retry_button.visible, "failed storage exposes retry")
		seq._on_skip_pressed()
		expect(not seq._storm_audio.playing and is_equal_approx(abode.bgm_player.volume_db, -3.0), "skip stops audio and restores exact BGM gain")
		expect(not seq._tribulation_stage.visible and seq._tribulation_stage.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "skip disables background viewport")
		if not success:
			expect(not seq._subtitle_label.text.contains("功成") and seq._stage_label.text.contains("未成"), "failure never claims success")
			expect(seq._save_label.text.contains("未成") and seq._save_label.text.contains("保存失敗"), "outcome and durability are separate")
			expect(seq._detail_label.text.contains("123.0 → 0.0") and abode.session.state.pill_effects.get("stacks", {}).is_empty(), "failure shows actual training loss and stack reset")
		var committed: Dictionary = abode.session.state.to_snapshot_dict()
		seq._on_replay_pressed()
		seq._process(20.1)
		expect(not seq._is_playing and not seq._storm_audio.playing and seq._result_panel.visible, "natural end cleans storm and reveals result")
		expect(abode.session.state.to_snapshot_dict() == committed, "natural completion grants nothing")
		seq._on_replay_pressed()
		seq.reduced_motion = true
		expect(not seq._is_playing and not seq._storm_audio.playing, "mid-storm reduced setting cleans up immediately")
		seq._on_replay_pressed()
		expect(seq._tribulation_stage.reduced and not seq._storm_audio.playing, "reduced replay is static and quiet")
		seq._process(1.3)
		expect(not seq._is_playing, "reduced key pose returns within 1.3 seconds")
		seq.reduced_motion = false
		seq.sound_enabled = false
		seq._on_replay_pressed()
		expect(not seq._storm_audio.playing and is_equal_approx(abode.bgm_player.volume_db, -3.0), "muted storm never ducks or plays")
		seq._on_skip_pressed()
		seq.sound_enabled = true
		seq._on_replay_pressed()
		seq._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
		expect(not seq.visible and not abode.camera.input_locked and not seq._storm_audio.playing, "focus loss restores audio camera and HUD")
		abode._replay_breakthrough()
		abode._breakthrough_era()
		seq._on_replay_pressed()
		seq._on_skip_pressed()
		expect(abode.session.state.to_snapshot_dict() == committed, "double submit guard and result replay preserve all state")
		adapter.deny = false
		abode._retry_breakthrough_save()
		expect(not abode._pending_breakthrough_save and not seq._retry_button.visible, "retry recovers durability")
		expect(abode.session.state.to_snapshot_dict() == committed, "retry never rolls or changes state")
		for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
			root.size = vp
			root.content_scale_size = vp
			abode._layout_for_size(Vector2(vp))
			for frame in 4: await process_frame
			expect(Rect2(Vector2.ZERO,Vector2(vp)).encloses(seq._result_panel.get_global_rect()), "result fits %s: %s" % [vp, seq._result_panel.get_global_rect()])
			expect(seq._close_button.size.y >= 44 and seq._replay_button.size.y >= 44, "result controls retain 44px")
			await _capture("result-%s-%dx%d" % [success,vp.x,vp.y])
		seq._on_close_pressed()
		expect(is_equal_approx(abode.bgm_player.volume_db, -3.0), "return restores BGM gain")
		abode._replay_breakthrough()
		seq._on_skip_pressed()
		expect(seq._result_data.kind == abode._last_breakthrough_result.kind, "settings replay keeps same outcome")
		seq._on_close_pressed()
		# Reject below max level: no mutation or fake failure result.
		abode.session.state.level = 1
		before = abode.session.state.to_snapshot_dict()
		abode._breakthrough_era()
		expect(not seq.visible and abode.session.state.to_snapshot_dict() == before, "rejection never plays or rolls")
	# Reload has no memory receipt and must not invent one from era_id.
	seq.play_result(abode._last_breakthrough_result)
	seq.queue_free()
	await process_frame
	# Tree exit also cleans audio without relying on an animation callback.
	expect(is_equal_approx(abode.bgm_player.volume_db, -3.0), "scene exit restores BGM")
	abode.queue_free()
	await process_frame
	var reloaded = Scene.instantiate()
	root.add_child(reloaded)
	await process_frame
	reloaded.set_process(false)
	reloaded._replay_breakthrough()
	expect(reloaded._last_breakthrough_result.is_empty() and not reloaded.breakthrough_seq.visible, "reload cannot invent replay")
	reloaded.queue_free()
	await process_frame
	slots.reset()
	Abode.save_dir_override = ""
	print("TRIB-C checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png("res://docs/verification/artifacts/trib-c/native-" + label + ".png") == OK, "capture " + label)
