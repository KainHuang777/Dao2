extends SceneTree
var checks := 0
var failures: Array[String] = []
const IDS := ["qingheng", "nuomeizi", "danxia"]
const KINDS := ["recruit_maid", "assign_maid_duty", "clear_maid_duty", "set_maid_duty_paused", "execute_maid_duty", "claim_maid_chapter", "maid_reunion"]
const REQUIRE_KINDS := ["duty_units", "sect_unlocked", "any_skill", "beast_active", "reincarnation_talent"]
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: " + label)
func frames() -> void:
	for n in 8: await process_frame
func _strings(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for value in raw: out.append(String(value))
	return out
func _pairwise_distinct(values: Array) -> bool:
	var seen: Array = []
	for value in values:
		if seen.has(value): return false
		seen.append(value)
	return true
func _shared(left: Array, right: Array) -> bool:
	for value in left:
		if right.has(value): return true
	return false
func _prepare(state, maid_id: String, bond: int) -> Dictionary:
	var entry: Dictionary = MaidSystem._ensure_entry(state, maid_id)
	entry.recruited = true
	entry.bond = bond
	entry.duty = {}
	entry.duty_actions = 0
	return entry
func _run() -> void:
	var panel_script: GDScript = load("res://src/presentation/maid_character_panel.gd")
	for id in IDS:
		var chapters: Array = MaidRules.chapters(id)
		check(chapters.size() == 4, "maid rules hold four chapters for " + id)
		var capstone := (chapters[3] as Dictionary)
		check(String(capstone.get("id", "")) == id + "_4", "the capstone chapter id appends after the third for " + id)
		check(int(capstone.get("bond", 0)) == 90, "the capstone chapter grants ninety bond for " + id)
		check(REQUIRE_KINDS.has(String(capstone.get("requires", ""))), "the capstone chapter uses a frozen requirement kind for " + id)
		check(String(capstone.get("requires", "")) != "duty_units" or int(capstone.get("amount", 0)) >= 1, "duty gated chapters keep an action amount for " + id)
	var titles: Array = []
	var closings_copy: Dictionary = {}
	var branch_copy: Dictionary = {}
	var scripts: Dictionary = panel_script.BOND_SCRIPT
	for id in IDS:
		var entry := (scripts.get(id, {}) as Dictionary)
		var per_closings: Array = []
		var per_branch: Array = []
		for chapter_def in MaidRules.chapters(id):
			var chapter_id := String(chapter_def.get("id", ""))
			var chapter_title := String(chapter_def.get("title", ""))
			titles.append(chapter_title)
			var script_def := (entry.get(chapter_id, {}) as Dictionary)
			check(not script_def.is_empty(), "bond script exists for " + chapter_id)
			check(String(script_def.get("title", "")) == chapter_title, "bond script title matches the rule title for " + chapter_id)
			var lines := _strings(script_def.get("lines", []))
			check(lines.size() == 2 and not lines[0].is_empty(), "bond script opens with two narrated lines for " + chapter_id)
			check(lines.size() == 2 and lines[1].contains("「"), "bond script second line is her speech for " + chapter_id)
			var choices := _strings(script_def.get("choices", []))
			check(choices.size() == 2 and choices[0] != choices[1], "bond script offers two distinct picks for " + chapter_id)
			var branches: Variant = script_def.get("branches", [])
			check(branches is Array and (branches as Array).size() == 2, "bond script keeps a reply for each pick for " + chapter_id)
			if branches is Array:
				for branch in (branches as Array):
					var texts := _strings(branch)
					check(texts.size() == 1 and not texts[0].is_empty(), "each branch owns one reply for " + chapter_id)
					for text in texts: per_branch.append(text)
			var closing := String(script_def.get("closing", ""))
			check(not closing.is_empty(), "bond script converges on a closing line for " + chapter_id)
			per_closings.append(closing)
		closings_copy[id] = per_closings
		branch_copy[id] = per_branch
	check(_pairwise_distinct(titles), "the twelve chapter titles never collide")
	for id in IDS:
		check(_pairwise_distinct(closings_copy[id] + branch_copy[id]), "closings and branch replies stay unique within " + id)
	var stories := (panel_script.STORIES as Dictionary)
	var seals: Array = []
	var quotes: Array = []
	var closings: Array = []
	var notes: Array = []
	var tags: Array = []
	for id in IDS:
		var story := (stories[id] as Dictionary)
		seals.append(String(story.get("seal", "")))
		quotes.append(String(story.get("quote", "")))
		closings.append(String(story.get("closing", "")))
		notes.append(String(story.get("role_note", "")))
		tags.append(str(story.get("tags", [])))
		check(_pairwise_distinct(_strings(story.get("replies", []))) and _pairwise_distinct(_strings(story.get("choices", []))), "meeting copy stays unique within " + id)
	for id in IDS:
		for other in IDS:
			if other == id: continue
			check(not _shared(_strings(stories[id]["replies"]), _strings(stories[other]["replies"])), "meeting replies stay distinct between " + id + " and " + other)
			check(not _shared(_strings(stories[id]["choices"]), _strings(stories[other]["choices"])), "meeting choices stay distinct between " + id + " and " + other)
	check(_pairwise_distinct(seals) and _pairwise_distinct(quotes) and _pairwise_distinct(closings) and _pairwise_distinct(notes) and _pairwise_distinct(tags), "person copy never collides across the three maids")
	var greetings := (panel_script.GREETINGS as Dictionary)
	var duty_greetings := (panel_script.DUTY_GREETINGS as Dictionary)
	var reunion := (panel_script.REUNION_LINES as Dictionary)
	for id in IDS:
		check(_strings(greetings.get(id, [])).size() == 4, "greetings hold four tier lines for " + id)
		check(_pairwise_distinct(_strings(greetings.get(id, []))), "greeting tiers read differently for " + id)
		check(_strings(duty_greetings.get(id, [])).size() == 4, "duty greetings hold four tier lines for " + id)
		check(_pairwise_distinct(_strings(duty_greetings.get(id, []))), "duty greeting tiers read differently for " + id)
		check(not _shared(_strings(greetings.get(id, [])), _strings(duty_greetings.get(id, []))), "idle and duty greetings never repeat for " + id)
		check(not String(reunion.get(id, "")).is_empty(), "reunion line exists for " + id)
	check(_pairwise_distinct(_strings(reunion.values())), "reunion lines stay distinct per maid")
	for kind in KINDS:
		for id in IDS:
			var line: String = panel_script.voice_line(kind, id)
			check(not line.is_empty(), "voice line exists for " + kind + " x " + id)
			check(line.length() <= 22, "voice line stays short for " + kind + " x " + id)
			check(panel_script.voice_line(kind, id) == line, "voice lines are deterministic for " + kind + " x " + id)
	check(panel_script.voice_line("unknown_kind", "qingheng") == "", "unknown kinds answer empty")
	check(panel_script.voice_line("recruit_maid", "bogus") == "", "unknown maids answer empty")
	check(panel_script.voice_line("", "") == "", "empty inputs answer empty")
	var constants := panel_script.get_script_constant_map()
	check(constants.has("VOICE_LINES") and constants.has("GREETINGS") and constants.has("DUTY_GREETINGS") and constants.has("REUNION_LINES"), "voice tables are script constants")
	var voice_table: Dictionary = constants["VOICE_LINES"]
	check(panel_script.voice_line("recruit_maid", "qingheng") == String(voice_table["recruit_maid"]["qingheng"]), "voice_line is static and stateless")
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = RunnerResult.output_path("res://maid-voice-save")
	SaveSlots.new(FileStorageAdapter.new(abode_script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	var panel = abode.feature_navigation.character_panel
	abode.feature_navigation.open("characters")
	panel.show_mode("person")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	check(not panel.greeting_label.visible, "greeting stays hidden for an unrecruited maid")
	for id in IDS:
		var entry := _prepare(abode.session.state, id, 40)
		abode._refresh_hud()
		await frames()
		panel.select_maid(id)
		await frames()
		check(String(panel.greeting_label.text) == String(panel.GREETINGS[id][1]), "greeting shows the 相知 line for " + id)
		check(panel.greeting_label.visible, "greeting shows once the maid is in the abode for " + id)
		entry.bond = 200
		abode._refresh_hud()
		await frames()
		check(String(panel.greeting_label.text) == String(panel.GREETINGS[id][3]), "greeting shows the 同道 line for " + id)
	var qing_entry := _prepare(abode.session.state, "qingheng", 40)
	qing_entry.duty = {"kind": "steward_stock", "paused": false, "cooldown": 0, "status": "RUNNING"}
	abode._refresh_hud()
	await frames()
	panel.select_maid("qingheng")
	await frames()
	check(String(panel.greeting_label.text) == String(panel.DUTY_GREETINGS["qingheng"][1]), "an active duty swaps in the duty greeting")
	qing_entry.reunion_pending = true
	abode._refresh_hud()
	await frames()
	check(panel.reunion_box.visible, "reunion row shows after rebirth for qingheng")
	check(String(panel.reunion_label.text) == String(panel.REUNION_LINES["qingheng"]), "reunion label names the reunion copy")
	panel.select_maid("nuomeizi")
	await frames()
	check(String(panel.reunion_label.text) == String(panel.REUNION_LINES["nuomeizi"]), "reunion label follows the selected maid")
	panel.select_maid("danxia")
	await frames()
	check(String(panel.reunion_label.text) == String(panel.REUNION_LINES["danxia"]), "reunion label keeps following the selection")
	panel.select_maid("qingheng")
	await frames()
	check(String(panel.reunion_label.text) == String(panel.REUNION_LINES["qingheng"]), "reunion label returns with the first maid")
	qing_entry.reunion_pending = false
	qing_entry.duty = {}
	abode._refresh_hud()
	await frames()
	panel.select_maid("nuomeizi")
	await frames()
	panel.select_maid("qingheng")
	await frames()
	check(String(panel.greeting_label.text) == String(panel.GREETINGS["qingheng"][1]), "clearing the duty returns the idle greeting")
	check(not panel.reunion_box.visible, "cleared reunion hides the reunion row")
	abode.queue_free()
	await process_frame
	print("MAID-VOICE checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
