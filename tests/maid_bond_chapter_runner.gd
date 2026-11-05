extends SceneTree
var checks := 0
var failures: Array[String] = []
const IDS := ["qingheng", "nuomeizi", "danxia"]
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
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-bond-chapter/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _strings(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for value in raw: out.append(String(value))
	return out
func _text(raw: Variant) -> String:
	return "".join(_strings(raw))
func _prepare(state, maid_id: String, claimed: Array) -> void:
	var entry: Dictionary = MaidSystem._ensure_entry(state, maid_id)
	entry.recruited = true
	entry.bond = 50
	var flags := {}
	for chapter_id in claimed: flags[String(chapter_id)] = true
	entry.chapters = flags
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-bond-chapter-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	nav.open("characters")
	panel.show_mode("bond")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	check(nav.portrait_viewer.choices != null and not nav.portrait_viewer.choices.visible, "chapter choices stay hidden before any replay")
	for id in IDS:
		var chapters: Array = MaidRules.chapters(id)
		check(chapters.size() == 4, "bond chapter list holds the four entries for " + id)
		var seen_titles: Array = []
		var seen_lines: Array = []
		for chapter_def in chapters:
			var chapter_id := String(chapter_def.get("id", ""))
			var chapter_title := String(chapter_def.get("title", ""))
			var script_def: Dictionary = panel.chapter_script(id, chapter_id)
			check(not script_def.is_empty(), "chapter dialogue exists for " + chapter_id)
			check(String(script_def.get("title", "")) == chapter_title, "chapter dialogue title matches the rule title for " + chapter_id)
			var lines := _strings(script_def.get("lines", []))
			check(lines.size() >= 2 and _text(lines) != "", "chapter dialogue opens with at least two lines for " + chapter_id)
			var choices := _strings(script_def.get("choices", []))
			check(choices.size() == 2, "chapter dialogue offers exactly two branches for " + chapter_id)
			check(choices.size() == 2 and choices[0] != choices[1], "chapter branches read differently for " + chapter_id)
			var branches: Variant = script_def.get("branches", [])
			check(branches is Array and (branches as Array).size() == choices.size(), "every branch keeps its own reply for " + chapter_id)
			var branch_texts: Array = []
			if branches is Array:
				for branch in (branches as Array):
					var branch_text := _text(branch)
					branch_texts.append(branch_text)
					check(not branch_text.is_empty(), "branch reply is not empty for " + chapter_id)
			check(branch_texts.size() == 2 and branch_texts[0] != branch_texts[1], "branch replies diverge for " + chapter_id)
			check(not String(script_def.get("closing", "")).is_empty(), "chapter dialogue converges on a closing line for " + chapter_id)
			check(not seen_titles.has(chapter_title) and not seen_lines.has(_text(lines)), "chapters of " + id + " do not reuse copy")
			seen_titles.append(chapter_title)
			seen_lines.append(_text(lines))
	_prepare(abode.session.state, "qingheng", ["qingheng_1"])
	abode._refresh_hud()
	await frames()
	panel.select_maid("qingheng")
	await frames()
	var row0: Dictionary = panel.chapter_rows[0]
	var replay0: InscriptionAction = row0["replay"]
	check(replay0.visible and not replay0.disabled, "a claimed chapter exposes replay for qingheng_1")
	check(replay0.size.y >= 44, "chapter replay keeps a 44px target")
	check(not (panel.chapter_rows[1] as Dictionary)["replay"].visible, "unclaimed chapters keep replay hidden")
	check(not (panel.chapter_rows[2] as Dictionary)["replay"].visible, "the third chapter keeps replay hidden before its claim")
	check(not (panel.chapter_rows[3] as Dictionary)["replay"].visible, "the fourth chapter keeps replay hidden before its claim")
	check(not (row0["claim"] as InscriptionAction).visible, "claimed chapter hides its claim action")
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	replay0.pressed.emit()
	await frames()
	var viewer = nav.portrait_viewer
	check(viewer.visible and nav.shell.state.snapshot().overlay == "tool", "chapter replay uses the shared blocking viewer overlay")
	check(not viewer.image.visible, "chapter replay hides the portrait image")
	check(String(viewer.title_label.text) == "青蘅 · 一盞燈", "viewer title names the maid and chapter")
	check(String(viewer.body.text).contains("替晚歸的人留的"), "viewer renders the chapter opening")
	check(viewer.choices.visible and viewer.choice_buttons.size() == 2, "chapter replay shows two branch actions")
	var first_choice: InscriptionAction = viewer.choice_buttons[0]
	check(first_choice.size.y >= 44, "chapter branch keeps a 44px target")
	await capture("chapter-open", Vector2i(1280, 720))
	first_choice.pressed.emit()
	await frames()
	check(String(viewer.body.text).contains("燈芯也剪短些"), "first branch reveals its own reply")
	check(String(viewer.body.text).contains("影子落在同一處"), "first branch reaches the shared closing line")
	check(not viewer.choices.visible, "branch actions hide after a branch is picked")
	check(viewer.reset_button.visible and viewer.reset_button.size.y >= 44, "chapter replay offers a 44px reread action")
	await capture("chapter-branch", Vector2i(1280, 720))
	check(abode.session.state.to_snapshot_dict() == before, "opening and choosing a branch changes no state")
	viewer.reset_button.pressed.emit()
	await frames()
	check(viewer.choices.visible and not viewer.reset_button.visible, "reread restores the branch actions")
	check(not String(viewer.body.text).contains("燈芯也剪短些"), "reread clears the previous branch copy")
	viewer.choose(1)
	await frames()
	check(String(viewer.body.text).contains("從山道上抬頭就看得見了"), "second branch reveals its own reply")
	check(not String(viewer.body.text).contains("燈芯也剪短些"), "the second branch never shows the first branch copy")
	check(abode.session.state.to_snapshot_dict() == before, "both branches leave state untouched")
	nav.back()
	await frames()
	check(not viewer.visible and panel.bond.visible, "closing the chapter replay returns to the bond page")
	check(abode.session.state.to_snapshot_dict() == before, "closing the replay also leaves state untouched")
	_prepare(abode.session.state, "qingheng", ["qingheng_1", "qingheng_2", "qingheng_3", "qingheng_4"])
	abode._refresh_hud()
	await frames()
	var row2: Dictionary = panel.chapter_rows[2]
	check((row2["replay"] as InscriptionAction).visible, "the final chapter exposes chapter replay too")
	check(not (row2["memory"] as InscriptionAction).visible, "only the last row carries the CG memory")
	var row3: Dictionary = panel.chapter_rows[3]
	check(String(row3.get("id", "")) == "qingheng_4", "the fourth row maps to the capstone chapter")
	check((row3["replay"] as InscriptionAction).visible, "the capstone chapter exposes chapter replay too")
	check((row3["memory"] as InscriptionAction).visible, "the final chapter still exposes its CG memory")
	(row2["replay"] as InscriptionAction).pressed.emit()
	await frames()
	check(String(viewer.title_label.text) == "青蘅 · 前世燈火", "third chapter replay opens the third chapter copy")
	check(not viewer.image.visible, "third chapter replay is dialogue only")
	nav.back()
	await frames()
	(row3["memory"] as InscriptionAction).pressed.emit()
	await frames()
	check(viewer.image.visible and viewer.image.texture != null, "the CG memory still shows its artwork")
	check(not viewer.choices.visible, "the CG memory exposes no chapter branches")
	nav.back()
	await frames()
	_prepare(abode.session.state, "nuomeizi", ["nuomeizi_2"])
	abode._refresh_hud()
	await frames()
	panel.select_maid("nuomeizi")
	await frames()
	var nuo_row: Dictionary = panel.chapter_rows[1]
	check((nuo_row["replay"] as InscriptionAction).visible, "another maid exposes replay for her claimed chapter")
	(nuo_row["replay"] as InscriptionAction).pressed.emit()
	await frames()
	check(String(viewer.title_label.text) == "糯美子 · 功法相印", "replay follows the selected maid")
	check(String(viewer.body.text).contains("兩卷功法並排攤開"), "replay uses that maid's own copy")
	nav.back()
	await frames()
	panel.select_maid("danxia")
	await frames()
	for row_index in 4:
		check(not ((panel.chapter_rows[row_index] as Dictionary)["replay"] as InscriptionAction).visible, "unread chapters stay unplayable for danxia")
	abode.queue_free()
	await process_frame
	print("MAID-BOND-CHAPTER checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
