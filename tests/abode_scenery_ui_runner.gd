extends SceneTree
var failed := false
class FailOnceAdapter extends FileStorageAdapter:
	var failures_left := 1
	func write(key: String, data: String) -> Dictionary:
		if failures_left > 0:
			failures_left -= 1
			return {"ok": false, "error": "test_write_failure"}
		return super.write(key, data)
func _init() -> void:
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("ISLAND1_UI: " + message)
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://island1_ui_runner"
	var slots := SaveSlots.new(FileStorageAdapter.new(script.save_dir_override))
	slots.reset()
	var abode = script.new()
	root.add_child(abode)
	abode.set_process(false)
	await process_frame
	abode.session.state.buildings.hut = 2
	abode.session.state.resources.wood.unlocked = true
	AbodeScenery.advance(abode.session.state, 12)
	abode._refresh_hud()
	var prop = abode.scenery_props.values()[0]
	check(prop.kind == "wood" and prop.contains_point(prop.to_global(Vector2(0, -30))), "generated wood node has an actionable hit region")
	var old_art: Texture2D = abode.buildings.hut.sprite.texture
	abode.session.state.era_id = 2
	var view: Dictionary = abode.session.get_view()
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	abode._update_buildings_visual(view)
	check(abode.buildings.hut.sprite.texture != old_art and abode.buildings.hut.title == "築基小院", "Era 2 chooses courtyard on same hut ID")
	check(before == abode.session.state.to_snapshot_dict(), "appearance swap does not change rules")
	abode._pick_world(abode.buildings.hut.to_global(Vector2(0, -60)))
	check(abode.feature_navigation.page == "buildings" and abode.selected_id == "hut", "world courtyard opens canonical building route")
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	abode._unhandled_key_input(escape)
	check(abode.feature_navigation.group == "home" and not abode.building_catalog.visible, "Escape from landmark detail restores home")
	abode.session.state.era_id = 1
	abode._refresh_hud()
	check(abode.buildings.hut.sprite.texture == old_art, "new life appearance reverts to hut")
	# Short landscape home frame fits the full hut beside the actual left HUD.
	abode._layout_for_size(Vector2(844, 390))
	var hut = abode.buildings.hut
	var art_transform: Transform2D = hut.sprite.global_transform
	var top_left := art_transform * Vector2(-hut.sprite.texture.get_width() * 0.5, -hut.sprite.texture.get_height() * 0.5)
	var bottom_right := art_transform * Vector2(hut.sprite.texture.get_width() * 0.5, hut.sprite.texture.get_height() * 0.5)
	top_left = (top_left - abode.camera.position) * abode.camera.zoom + Vector2(422, 195)
	bottom_right = (bottom_right - abode.camera.position) * abode.camera.zoom + Vector2(422, 195)
	check(top_left.x > abode.header.get_global_rect().end.x and top_left.y >= 0 and bottom_right.y < abode.toolbar.position.y, "short home frame keeps full landmark in available world area")
	abode.camera.target_position += Vector2(30, 20)
	var user_position: Vector2 = abode.camera.target_position
	abode._layout_for_size(Vector2(800, 390))
	check(abode.camera.target_position == user_position, "resize preserves a manually panned view")
	abode._pick_world(prop.to_global(Vector2(0, -30)))
	check(abode.session.state.resources.wood.value.to_float() >= 5 and abode.scenery_props.is_empty(), "world route claims stored batch through Session")
	var saved: Dictionary = slots.read_best()
	check(saved.ok and SaveCodec.decode(saved.json).state.abode_scenery.active.is_empty(), "successful claim immediately persisted")
	AbodeScenery.advance(abode.session.state, 100)
	abode._refresh_hud()
	var retry_adapter := FailOnceAdapter.new("user://island1_ui_retry")
	var retry_slots := SaveSlots.new(retry_adapter)
	retry_slots.reset()
	SaveManager.configure(abode.content, retry_adapter)
	var retry_id: String = abode.scenery_props.keys()[0]
	var value_before: float = abode.session.state.resources.wood.value.to_float()
	abode._claim_scenery(retry_id)
	check(abode._pending_scenery_save and abode.hint.text.contains("重試"), "failed claim save is visible and pending retry")
	var credited: float = abode.session.state.resources.wood.value.to_float()
	check(credited > value_before, "claim commits once before feedback/save")
	check(abode._save_game().ok and not abode._pending_scenery_save, "next save retries successfully")
	check(abode.session.state.resources.wood.value.to_float() == credited, "retry does not replay reward")
	check(SaveCodec.decode(retry_slots.read_best().json).state.abode_scenery.active.is_empty(), "retry persists consumed find")
	AbodeScenery.advance(abode.session.state, 100)
	abode._refresh_hud()
	abode.camera.zoom = Vector2.ONE * 0.18
	abode._refresh_hud()
	check(not abode.scenery_props.values()[0].visible, "region zoom hides small props")
	abode.camera.zoom = Vector2.ONE * 0.7
	abode.session.state.current_realm = "realm_spirit"
	abode._refresh_hud()
	check(abode.scenery_props.is_empty(), "realm switch removes home prop nodes")
	abode.queue_free()
	await process_frame
	slots.reset()
	retry_slots.reset()
	print("ISLAND1_UI ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
