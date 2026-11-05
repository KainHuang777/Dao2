extends SceneTree
var checks := 0
var failures: Array[String] = []
const VOICE_KEYS := ["hut", "wooden_house", "forest_farm", "stone_mine", "herb_farm", "storage_lingli", "foundation_reservoir", "cultivation", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "G1", "G2", "G3", "G4", "complete", "legacy"]
const HEADINGS := ["系統訊息", "系統訊息 · 新手引導", "系統訊息 · 築基準備", "系統訊息 · 雙島供給", "系統訊息 · 金丹首段", "操作說明"]
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 8: await process_frame
func _voice_lines(abode) -> Array[String]:
	var out: Array[String] = []
	for entry in abode._message_history:
		if String(entry).contains("青蘅：「"):
			out.append(String(entry))
	return out
func _early_view(step: String, text: String) -> Dictionary:
	return {
		"era_id": 2,
		"level": 1,
		"can_level_up": false,
		"next_objective": null,
		"resources": {"lingli": {"cap": "200"}},
		"early_guidance": {"step": step, "title": "下一步：測試" + step, "text": text, "route": "transport", "optional_alchemy": false},
	}
func _run() -> void:
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = RunnerResult.output_path("res://maid-guidance-voice-save")
	SaveSlots.new(FileStorageAdapter.new(abode_script.save_dir_override)).reset()
	var voice_table: Dictionary = load("res://src/presentation/abode_hud_controller.gd").get_script_constant_map().get("GUIDE_VOICE", {})
	check(voice_table.size() == 21, "guide voice table carries all 21 keys: %d" % voice_table.size())
	var seen_copy: Array = []
	for key in VOICE_KEYS:
		var line := String(voice_table.get(key, ""))
		check(not line.is_empty() and line.length() <= 30 and not seen_copy.has(line), "voice copy for %s is short, present and distinct" % key)
		seen_copy.append(line)
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	abode._refresh_hud()
	await frames()
	var hud = abode._hud_controller
	check(not hud._guide_avatar.visible, "guide avatar stays hidden before any maid is recruited")
	check(_voice_lines(abode).is_empty(), "fresh message log carries no guide voice line")
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(500.0)
	abode.session.state.revision += 1
	abode._refresh_hud()
	await frames()
	abode.session.submit({"command_id": "maid-voice-build-hut", "type": "upgrade_building", "expected_revision": abode.session.state.revision, "payload": {"building_id": "hut"}})
	abode._refresh_hud()
	await frames()
	check(int(abode.session.state.buildings.get("hut", 0)) == 1, "hut stands after the real build command")
	var recruit_result: Dictionary = abode.session.recruit_maid("qingheng")
	check(bool(recruit_result.get("ok", false)), "qingheng recruitment command is accepted")
	abode._refresh_hud()
	await frames()
	check(abode.hint_panel.visible, "message panel stays open on the wide layout")
	check(hud._guide_avatar.visible, "guide avatar shows once qingheng is recruited")
	check(String(hud._guide_name.text) == "青蘅", "guide name label reads 青蘅")
	check(hud._guide_avatar.texture != null, "guide portrait texture loaded from the character asset")
	var first_lines: Array[String] = _voice_lines(abode)
	check(first_lines.size() == 1, "exactly one guide voice line after recruitment: %d" % first_lines.size())
	if first_lines.size() == 1:
		check(first_lines[0] == "青蘅：「%s」" % String(voice_table.get("hut", "")), "recruitment speaks the current hut goal copy")
	check(hud._last_voice_key == "hut", "voice key tracks the current building goal")
	check(String(abode.hint.text).contains("茅屋"), "hint text still states the next hut objective: %s" % abode.hint.text)
	var title_row = abode.hint_heading.get_parent()
	var expand_button: Button = abode.hint_expand_button
	var close_button: Button = title_row.get_child(4)
	var avatar_rect: Rect2 = hud._guide_avatar.get_global_rect()
	var expand_rect: Rect2 = expand_button.get_global_rect()
	var close_rect: Rect2 = close_button.get_global_rect()
	check(avatar_rect.end.x <= expand_rect.position.x + 0.5, "avatar never rides over the expand button")
	check(expand_rect.end.x <= close_rect.position.x + 0.5, "expand and collapse buttons keep their side-by-side order")
	check(abode.hint_panel.get_global_rect().encloses(close_rect), "collapse button stays inside the message panel")
	var history_before: int = abode._message_history.size()
	var voice_before: int = _voice_lines(abode).size()
	abode._refresh_hud()
	await frames()
	check(abode._message_history.size() == history_before, "a repeat refresh with the same view pushes nothing new")
	check(_voice_lines(abode).size() == voice_before, "the recruitment line is not duplicated on refresh")
	abode._update_onboarding_guidance(_early_view("F2", "靈石已送達一半，航線繼續。"))
	await frames()
	var second_lines: Array[String] = _voice_lines(abode)
	check(second_lines.size() == 2, "advancing the goal adds a second voice line: %d" % second_lines.size())
	check(hud._last_voice_key == "F2", "voice key follows the new early step")
	if second_lines.size() == 2:
		check(second_lines[1] == "青蘅：「%s」" % String(voice_table.get("F2", "")), "second line matches the F2 voice copy")
		check(second_lines[0] != second_lines[1], "the two voice lines read differently")
	abode._update_onboarding_guidance(_early_view("F9", "未知步驟的測試文本。"))
	await frames()
	check(_voice_lines(abode).size() == 2, "an unknown step never pushes a voice line")
	check(hud._last_voice_key == "F2", "an unknown step leaves the voice key alone")
	check(HEADINGS.has(String(abode.hint_heading.text)), "heading keeps one of the exact existing strings: %s" % abode.hint_heading.text)
	abode.queue_free()
	await process_frame
	abode_script.save_dir_override = ""
	print("MAID-GUIDANCE-VOICE checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
