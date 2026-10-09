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
	_expect(abode.cultivator != null and abode.cultivator.body.texture != null, "independent cloaked protagonist must be present")
	_expect(abode.cultivator.FEET == abode.island_fx.FOCUS and abode.cultivator.CORE == abode.island_fx.CORE, "actor and tribulation must share foot and chest anchors")
	abode.cultivator.present(true, 0.35)
	var frozen_clock: float = abode.cultivator.clock
	abode.cultivator._process(1.0)
	_expect(abode.cultivator.clock == frozen_clock and abode.cultivator.visible, "reduced motion freezes absorption but retains the protagonist")
	abode.cultivator.present(false, 0.0, 1)
	var early_absorption: Dictionary = abode.cultivator.absorption_profile()
	abode.cultivator.present(false, 0.0, 3)
	var later_absorption: Dictionary = abode.cultivator.absorption_profile()
	_expect(later_absorption.motes > early_absorption.motes and later_absorption.radius > early_absorption.radius, "normal absorption visibly grows with attained Era even outside tribulation")
	abode.cultivator.present(false, 0.0, 999)
	_expect(abode.cultivator.cultivation_era == 12 and abode.cultivator.absorption_profile().motes == 48, "absorption clamps Era and caps drawing budget")
	abode.cultivator.present(false, 0.0, abode.session.state.era_id)
	_expect(abode.session.state.to_snapshot_dict() == committed, "absorption tiers cannot award resources or change attained Era")
	abode.cultivator.present(false, abode.island_fx.energy)
	_expect(abode.vfx_environment.environment.glow_enabled and abode.vfx_environment.environment.background_canvas_max_layer < 10, "native world glow must exclude the HUD layer")
	_expect(abode.island_fx.sparks.emitting and abode.island_fx.lightning[0].visible, "climax activates engine particles and lightning shader")
	var fx_children: int = abode.island_fx.front_layer.get_child_count()
	for vp in [Vector2(1280, 720), Vector2(844, 390), Vector2(360, 640), Vector2(360, 480)]:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		abode._layout_for_size(vp)
		await process_frame
		await process_frame
		_expect(not abode.home_marker.visible, "sequence must hide the newer home world title even at distant camera zoom")
		for region_child in abode.region_layer.get_children():
			if region_child is Label:
				_expect(not region_child.visible, "region titles must not overlap the sequence heading")
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
	_expect(abode.island_fx.front_layer.get_child_count() == fx_children, "replays reuse bounded engine effects instead of accumulating nodes")
	abode.island_fx.set_era(2)
	var first_profile: Dictionary = abode.island_fx.visual_profile()
	for era in [4, 7, 10, 12]:
		abode.island_fx.set_era(era)
		var profile: Dictionary = abode.island_fx.visual_profile()
		_expect(profile.bolts > first_profile.bolts and profile.rings > first_profile.rings, "Higher Era presentation must add bounded lightning/ring layers")
		_expect(profile.bolts <= 6 and profile.sparks <= 84, "Highest Era must retain the bounded drawing budget")
	seq.play("前境", "高境試播", 12)
	seq._on_replay_pressed()
	_expect(abode.island_fx.era_id == 12, "Replay must preserve the target Era presentation tier")
	abode.island_fx.set_era(999)
	_expect(abode.island_fx.era_id == 12, "Presentation profile clamps unsupported Era input")
	_expect(abode.session.state.to_snapshot_dict() == committed, "Visual tiers and replay do not grant high Era progress")
	seq._on_close_pressed()
	_expect(not abode.camera.input_locked and abode.camera.position == original_position and abode.camera.target_position == original_target and abode.camera.zoom == original_zoom, "closing must restore the original camera and unlock input")
	_expect(abode.header.visible and abode.toolbar.visible, "closing must restore normal HUD")
	abode._toggle_motion()
	abode._replay_breakthrough()
	seq._process(1.1)
	_expect(not seq._is_playing and not abode.island_fx.active and abode.island_fx.reduced_motion, "low motion must finish in one second without moving VFX")
	_expect(not abode.island_fx.sparks.emitting and not abode.island_fx.sparks.visible and not abode.island_fx.lightning[0].visible and not abode.vfx_environment.environment.glow_enabled, "low effects disable particles, lightning and world bloom immediately")
	_expect(abode.cultivator.reduced_motion, "low effects stop protagonist absorption motion")
	_expect(not abode.has_node("獨立飛劍與靈氣"), "home has no legacy decorative flight emitter")
	seq._on_close_pressed()
	abode._toggle_motion()
	abode._replay_breakthrough()
	seq.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not seq.visible and not abode.camera.input_locked, "focus loss must release camera/modal locks")
	_expect(abode.session.state.to_snapshot_dict() == committed, "focus loss must not roll back or duplicate the committed result")
	abode.settings_menu.get_popup().id_pressed.emit(103)
	seq._process(2.6)
	_expect(seq._preview_mode and seq.visible and abode.camera.input_locked, "settings effect preview is clearly marked and owns its camera lock")
	seq.set_save_status(false)
	_expect(not seq._retry_button.visible and seq._save_label.text.begins_with("視覺試播"), "background save status cannot turn a visual preview into a reward or retry claim")
	seq.set_save_status(true)
	seq._on_skip_pressed()
	seq._on_replay_pressed()
	seq._on_close_pressed()
	_expect(abode.session.state.to_snapshot_dict() == committed and not abode.camera.input_locked, "preview, skip, replay and close cannot grant progress or leave a camera lock")
	abode.queue_free()
	await process_frame
	var reload = Scene.instantiate()
	root.add_child(reload)
	await process_frame
	reload.set_process(false)
	_expect(reload.session.state.era_id == 2 and reload.island_fx.attained and not reload.breakthrough_seq.visible, "reload must preserve realm/aura without forcing another sequence")
	_expect(reload.buildings.storage_lingli.visible and reload.buildings.storage_lingli.level == 2, "reload restores built right altar from existing building level")
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
