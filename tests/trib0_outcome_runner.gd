extends SceneTree
const Scene = preload("res://scenes/living_abode.tscn")
const Abode = preload("res://src/abode/living_abode.gd")
const Fixture = preload("res://src/verification/trib0_fixture.gd")
const DIR := "user://trib0-isolated"
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
		seq._confirm_button.pressed.emit()
		expect(abode.session.state.era_id == (4 if success else 2), "confirmed command commits correct era")
		expect(abode.session.state.tribulation_roll_index == int(before.tribulation_roll_index) + 1, "one roll per confirmation")
		expect(abode._last_breakthrough_result.kind == ("tribulation_passed" if success else "tribulation_failed"), "formal outcome event wins over ok")
		expect(abode._pending_breakthrough_save and seq._retry_button.visible, "failed storage exposes retry")
		seq._on_skip_pressed()
		if not success:
			expect(not seq._subtitle_label.text.contains("功成") and seq._stage_label.text.contains("未成"), "failure never claims success")
			expect(seq._save_label.text.contains("未成") and seq._save_label.text.contains("保存失敗"), "outcome and durability are separate")
			expect(seq._detail_label.text.contains("123.0 → 0.0") and abode.session.state.pill_effects.get("stacks", {}).is_empty(), "failure shows actual training loss and stack reset")
		var committed: Dictionary = abode.session.state.to_snapshot_dict()
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
	print("TRIB-0 checks=",checks," failures=",failures)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(RunnerResult.output_path("res://docs/verification/artifacts/trib0/native-" + label + ".png")) == OK, "capture " + label)
