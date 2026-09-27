extends SceneTree
## Isolated integration test; -- --capture also renders desktop evidence.

const Scene = preload("res://scenes/living_abode.tscn")
const AbodeScript = preload("res://src/abode/living_abode.gd")
const TEST_DIR := "user://island_breakthrough_v1"
var failures: Array[String] = []
var capture: bool = false

class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new(TEST_DIR)
	var fail_writes: bool = false
	func read(key: String) -> Dictionary:
		return backend.read(key)
	func write(key: String, data: String) -> Dictionary:
		return {"ok": false, "error": "TEST_WRITE_DENIED"} if fail_writes else backend.write(key, data)
	func erase(key: String) -> Dictionary:
		return backend.erase(key)
	func exists(key: String) -> bool:
		return backend.exists(key)
	func backend_name() -> String:
		return "breakthrough_test_only"

func _init() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("_run")

func _run() -> void:
	AbodeScript.save_dir_override = TEST_DIR
	var adapter := ToggleAdapter.new()
	var slots := SaveSlots.new(adapter)
	slots.reset()
	var abode = Scene.instantiate()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.session = GameSession.create_new_game(abode.content)
	abode.state = abode.AbodeStateCompat.new(abode.session)
	SaveManager.configure(abode.content, adapter)
	abode._refresh_hud()
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	abode._breakthrough_era()
	_expect(not abode.breakthrough_seq.visible, "rejected command must not play a success sequence")
	_expect(abode.session.state.to_snapshot_dict() == before, "failed breakthrough must preserve progress")
	abode.session.state.level = 10
	abode.session.state.buildings["hut"] = 2
	abode.session.state.buildings["storage_lingli"] = 2
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(88.0)
	abode._layout_for_size(Vector2(1280, 720))
	abode.camera.position = Vector2(150, -80)
	abode.camera.target_position = Vector2(180, -100)
	abode.camera.zoom = Vector2.ONE * 0.86
	abode.camera.target_zoom = 0.92
	var original_position: Vector2 = abode.camera.position
	var original_target: Vector2 = abode.camera.target_position
	var original_zoom: Vector2 = abode.camera.zoom
	adapter.fail_writes = true
	abode._breakthrough_era()
	_expect(abode.session.state.era_id == 2 and abode.session.state.level == 1, "real UI command must commit era 2 exactly once")
	_expect(abode.session.state.resources["lingli"].value.to_float() == 88.0, "capacity breakthrough must not spend stock")
	_expect(abode.breakthrough_seq.visible and abode.camera.input_locked, "sequence must lock world input")
	_expect(not abode.header.visible and not abode.toolbar.visible, "sequence must leave island visible without management panels")
	_expect(abode._pending_breakthrough_save and abode.breakthrough_seq._retry_button.visible, "failed save must expose retry without claiming durability")
	var committed: Dictionary = abode.session.state.to_snapshot_dict()
	abode._breakthrough_era()
	_expect(abode.session.state.to_snapshot_dict() == committed, "second click during sequence must not submit another breakthrough")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(140, 200)
	abode.camera._input(touch)
	_expect(abode.camera.contacts.is_empty(), "touch must not begin a world gesture behind the sequence")
	adapter.fail_writes = false
	abode._retry_breakthrough_save()
	_expect(not abode._pending_breakthrough_save and not abode.breakthrough_seq._retry_button.visible, "retry must save existing result without another reward")
	_expect(abode.session.state.to_snapshot_dict() == committed, "retry must not change GameState")
	var seq = abode.breakthrough_seq
	seq.set_process(false)
	seq._process(2.6)
	_expect(abode.island_fx.active and abode.island_fx.energy > 0.8, "climax must drive the actual island effect")
	for vp in [Vector2(1280, 720), Vector2(844, 390), Vector2(360, 640), Vector2(360, 480)]:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		abode._layout_for_size(vp)
		await process_frame
		await process_frame
		_check_bounds(seq._skip_button, vp, "skip")
		_expect(abode.camera.zoom.x * 1450.0 <= vp.x - 30.0, "formation must fit viewport width")
		if capture:
			abode.sky_material.set_shader_parameter("energy", abode.island_fx.energy)
			await _capture("climax-%dx%d" % [int(vp.x), int(vp.y)])
		seq._on_skip_pressed()
		await process_frame
		await process_frame
		_check_bounds(seq._close_button, vp, "close")
		_check_bounds(seq._replay_button, vp, "replay")
		_expect(not abode.island_fx.active and abode.island_fx.attained, "skip must leave the earned persistent aura")
		if capture:
			abode.sky_material.set_shader_parameter("energy", 0.0)
			await _capture("result-%dx%d" % [int(vp.x), int(vp.y)])
		seq._on_replay_pressed()
		seq._process(2.6)
	_expect(abode.session.state.to_snapshot_dict() == committed, "skip and multiple replays must preserve all state, inventory and revision")
	seq._on_close_pressed()
	_expect(not abode.camera.input_locked and abode.camera.position == original_position and abode.camera.target_position == original_target and abode.camera.zoom == original_zoom, "closing must restore the original camera and unlock input")
	_expect(abode.header.visible and abode.toolbar.visible, "closing must restore normal HUD")
	abode._toggle_motion()
	abode._replay_breakthrough()
	seq._process(1.1)
	_expect(not seq._is_playing and not abode.island_fx.active and abode.island_fx.reduced_motion, "low motion must finish in one second without moving VFX")
	seq._on_close_pressed()
	abode._toggle_motion()
	abode._replay_breakthrough()
	seq.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not seq.visible and not abode.camera.input_locked, "focus loss must release camera/modal locks")
	_expect(abode.session.state.to_snapshot_dict() == committed, "focus loss must not roll back or duplicate the committed result")
	abode.queue_free()
	await process_frame
	var reload = Scene.instantiate()
	root.add_child(reload)
	await process_frame
	reload.set_process(false)
	_expect(reload.session.state.era_id == 2 and reload.island_fx.attained and not reload.breakthrough_seq.visible, "reload must preserve realm/aura without forcing another sequence")
	if capture:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		reload._layout_for_size(Vector2(1280, 720))
		await process_frame
		await _capture("home-after-breakthrough")
	reload.queue_free()
	await process_frame
	slots.reset()
	AbodeScript.save_dir_override = ""
	if failures.is_empty():
		print("PASS: island breakthrough real command, capacity, failed-save retry, zero-state replay, skip, focus recovery, low motion, four layouts and reload aura.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _check_bounds(control: Control, vp: Vector2, label: String) -> void:
	var bounds := control.get_global_rect()
	_expect(bounds.position.x >= 0.0 and bounds.position.y >= 0.0 and bounds.end.x <= vp.x + 1.0 and bounds.end.y <= vp.y + 1.0, "%s must fit %s: %s" % [label, vp, bounds])
	_expect(bounds.size.x >= 44.0 and bounds.size.y >= 44.0, label + " must retain a usable touch target")

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := "res://docs/verification/artifacts/island-breakthrough"
	DirAccess.make_dir_recursive_absolute(directory)
	var picture := root.get_texture().get_image()
	_expect(picture != null and not picture.is_empty(), "desktop capture must contain rendered pixels")
	if picture != null and not picture.is_empty():
		var result := picture.save_png(directory + "/" + label + ".png")
		_expect(result == OK, "desktop capture must save successfully")
