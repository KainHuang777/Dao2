extends SceneTree
var checks := 0
var failures: Array[String] = []
var captured_kind := ""
var captured_payload: Dictionary = {}
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 8: await process_frame
func fits(outer, inner) -> bool:
	if outer == null or inner == null:
		return false
	return outer.get_global_rect().encloses(inner.get_global_rect())
func _capture(kind: String, payload: Dictionary) -> void:
	captured_kind = kind
	captured_payload = payload
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-duty-preset-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	var state = abode.session.state
	state.buildings["hut"] = 1
	state.buildings["herb_farm"] = 3
	for pair in [["spirit_grass_low", 200.0], ["black_copper", 200.0], ["lingli", 2000.0]]:
		state.resources[pair[0]] = {"value": AmountCompat.from_number(pair[1]), "unlocked": true, "ever_obtained": true}
	check(bool(abode.session.recruit_maid("qingheng").get("ok", false)), "setup recruits qingheng")
	check(bool(abode.session.assign_maid_duty("qingheng", {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": 2, "reserve": {}}).get("ok", false)), "setup assigns steward duty")
	abode._refresh_hud()
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	panel.action_requested.connect(_capture)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var viewports := ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)])
	if "--maid-duty-preset-short" in OS.get_cmdline_user_args(): viewports = [Vector2i(800,360)]
	var logic_done := false
	for vp in viewports:
		state = abode.session.state
		root.size = vp
		root.content_scale_size = vp
		nav.open("characters")
		abode._layout_for_size(Vector2(vp))
		await frames()
		panel.tabs.work.pressed.emit()
		await frames()
		check(panel.work.visible, "work page opens")
		check(panel.preset_row.visible, "preset row visible for the steward")
		check(panel.preset_buttons.size() == 3, "preset row lists three presets")
		for button in panel.preset_buttons:
			check((button as Control).size.y >= 44, "preset button reaches 44px")
		check(panel.reserve_row.visible and panel.reserve_entries.size() == 3, "reserve row lists every recipe input")
		for entry in panel.reserve_entries:
			var spin: SpinBox = entry.get("spin")
			check(spin != null and spin.size.y >= 44 and spin.size.x >= 150, "reserve stepper reaches 44px " + String(entry.get("id", "")))
		if not logic_done:
			var before_preset: Dictionary = state.to_snapshot_dict().duplicate(true)
			(panel.preset_buttons[0] as Control).pressed.emit()
			await frames()
			check(int(panel.duty_target.value) == 5, "steady preset sets target five")
			check(is_equal_approx(panel._reserve_value("spirit_grass_low"), 40.0), "steady preset reserves 20% of herbs")
			check(is_equal_approx(panel._reserve_value("black_copper"), 40.0), "steady preset reserves 20% of copper")
			check(is_equal_approx(panel._reserve_value("lingli"), 400.0), "steady preset reserves 20% of lingli")
			check(state.to_snapshot_dict() == before_preset, "applying a preset never mutates state")
			panel.duty_target.value = 20
			await frames()
			check(panel.duty_hint.visible, "preview shortage appears when the preset cannot be met")
			check(String(panel.duty_hint.text).contains("低階靈草不足") and String(panel.duty_hint.text).contains("保留"), "preview shortage names the limited material and reserve")
			panel.duty_target.value = 2
			await frames()
			check(not panel.duty_hint.visible, "preview shortage hides when the goal fits")
			panel.duty_target.value = 5
			await frames()
			captured_kind = ""
			captured_payload = {}
			panel.assign_button.pressed.emit()
			await frames()
			state = abode.session.state
			check(captured_kind == "assign_maid_duty", "assign emits the maid duty command")
			var sent: Dictionary = captured_payload.get("duty", {})
			var sent_reserve: Dictionary = sent.get("reserve", {})
			check(int(sent.get("target", 0)) == 5, "assign sends the preset target")
			check(int(sent_reserve.get("spirit_grass_low", 0)) == 40 and int(sent_reserve.get("black_copper", 0)) == 40 and int(sent_reserve.get("lingli", 0)) == 400, "assign sends the reserve payload")
			var stored: Dictionary = state.maid.get("maids", {}).get("qingheng", {}).get("duty", {})
			check(int(stored.get("reserve", {}).get("spirit_grass_low", 0)) == 40, "reserve payload persists through the session")
			panel.duty_target.value = 20
			state = abode.session.state
			state.resources["spirit_grass_low"] = {"value": AmountCompat.from_number(50.0), "unlocked": true, "ever_obtained": true}
			check(bool(abode.session.assign_maid_duty("qingheng", {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": 20, "reserve": {"spirit_grass_low": 190}}).get("ok", false)), "server shortage duty assigned")
			abode._refresh_hud()
			await frames()
			check(panel.duty_hint.visible and String(panel.duty_hint.text).contains("保留") and String(panel.duty_hint.text).contains("不足"), "view shortage reaches the work page")
			check(String(panel.duty_hint.text).contains("低階靈草"), "view shortage names the material")
			state = abode.session.state
			state.resources["spirit_grass_low"] = {"value": AmountCompat.from_number(200.0), "unlocked": true, "ever_obtained": true}
			check(bool(abode.session.assign_maid_duty("qingheng", {"kind": "steward_stock", "recipe_id": "foundation_pill", "target": 2, "reserve": {}}).get("ok", false)), "sufficient duty assigned")
			abode._refresh_hud()
			await frames()
			state = abode.session.state
			check(not panel.duty_hint.visible, "view shortage clears when materials recover")
			check(MaidSaveContract.validate(state.maid) == "", "save block stays valid after reserve duties")
			panel.select_maid("nuomeizi")
			await frames()
			check(not panel.preset_row.visible and not panel.reserve_row.visible, "overseer hides presets and reserves")
			check(not panel.duty_target.visible, "overseer hides the target stepper")
			panel.select_maid("qingheng")
			await frames()
			check(panel.preset_row.visible and panel.reserve_row.visible, "steward restores presets after switching back")
			logic_done = true
		if vp.y < 400:
			check(panel.preset_row.vertical, "compact work stacks the preset row")
			check(panel.reserve_row.vertical, "compact work stacks the reserve row")
			check(fits(panel, panel.work), "compact work scroll stays enclosed with presets")
	panel.refresh({})
	await frames()
	check(not String(panel.work_status.text).is_empty(), "empty view keeps a readable work status")
	abode.queue_free()
	await process_frame
	print("MAID-DUTY-PRESET checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
