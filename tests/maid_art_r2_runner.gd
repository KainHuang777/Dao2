extends SceneTree
var checks := 0
var failures: Array[String] = []
const IDS := ["qingheng", "nuomeizi", "danxia"]
const EXPECTED := {
	"qingheng": {"portrait": "res://assets/characters/qingheng/portrait.png", "meeting": "res://assets/characters/qingheng/first-meeting.png"},
	"nuomeizi": {"portrait": "res://assets/characters/nuomeizi/portrait-r2.png", "meeting": "res://assets/characters/nuomeizi/first-meeting-r2.png"},
	"danxia": {"portrait": "res://assets/characters/danxia/portrait-r2.png", "meeting": "res://assets/characters/danxia/first-meeting-r2.png"},
}
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
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-art-r2/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _tex_path(image: TextureRect) -> String:
	if image == null or image.texture == null: return ""
	return String(image.texture.resource_path)
func _copy_text(panel) -> String:
	var out := ""
	for node in panel.copy_box.find_children("*", "Label", true, false):
		out += String((node as Label).text)
	return out
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-art-r2-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var view: Dictionary = abode.session.get_view()
	SectSystem.ensure_sect_state(abode.session.state)
	var maid_view: Dictionary = view.get("maid", {})
	var maids: Dictionary = maid_view.get("maids", {})
	for id in IDS:
		var info: Dictionary = maids.get(id, {})
		check(bool(info.get("art_ready", false)), "session view reports art_ready for %s" % id)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	nav.open("characters")
	panel.show_mode("person")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	check(String(panel.selected_maid) == "qingheng", "fresh game opens on qingheng")
	check(_tex_path(panel.portrait_image) == String(EXPECTED["qingheng"]["portrait"]), "qingheng portrait shown on open")
	for id in IDS:
		var art_def: Dictionary = EXPECTED[id]
		var art_entry: Dictionary = panel.ART.get(id, {})
		check(String(art_entry.get("portrait", "")) == String(art_def["portrait"]), "ART table portrait for %s" % id)
		check(String(art_entry.get("meeting", "")) == String(art_def["meeting"]), "ART table meeting for %s" % id)
		check(ResourceLoader.exists(String(art_def["portrait"])) and ResourceLoader.exists(String(art_def["meeting"])), "accepted art files resolve for %s" % id)
		var story: Dictionary = panel.STORIES.get(id, {})
		var fields_ok := true
		for key in ["role_note", "quote", "bio", "closing", "seal", "scene", "opening"]:
			if String(story.get(key, "")).is_empty(): fields_ok = false
		check(fields_ok, "story text fields complete for %s" % id)
		var tags: Variant = story.get("tags")
		check(tags is Array and not (tags as Array).is_empty(), "story tags present for %s" % id)
		var replies: Variant = story.get("replies")
		var replies_ok := false
		if replies is Array:
			var arr: Array = replies
			replies_ok = arr.size() == 2 and not String(arr[0]).is_empty() and not String(arr[1]).is_empty() and String(arr[0]) != String(arr[1])
		check(replies_ok, "two usable per-character replies for %s" % id)
	var before: Dictionary = abode.session.state.to_snapshot_dict()
	var openings: Dictionary = {}
	var bios: Dictionary = {}
	for id in IDS:
		panel.select_maid(id)
		await frames()
		check(String(panel.selected_maid) == id, "select_maid switches to %s" % id)
		check(bool(panel._has_art()), "has_art true for %s" % id)
		var cur_art: Dictionary = panel._art()
		check(String(cur_art.get("portrait", "")) == String(EXPECTED[id]["portrait"]), "_art returns portrait entry for %s" % id)
		check(_tex_path(panel.portrait_image) == String(EXPECTED[id]["portrait"]), "portrait texture switches to %s" % id)
		var info: Dictionary = maids.get(id, {})
		var expected_name := String(info.get("name", ""))
		check(not expected_name.is_empty() and String(panel.name_label.text).replace("\n", "") == expected_name, "vertical name label shows %s" % id)
		var story_ref: Dictionary = panel.STORIES.get(id, {})
		var seal_text := String(story_ref.get("seal", ""))
		check(not seal_text.is_empty() and String(panel.seal.text) == seal_text, "seal matches story seal for %s" % id)
		openings[id] = String(panel._story().get("opening", ""))
		bios[id] = String(panel._story().get("bio", ""))
		check(not String(bios[id]).is_empty() and _copy_text(panel).contains(String(bios[id])), "bio text rendered into copy scroll for %s" % id)
		await capture("person-" + String(id), Vector2i(1280, 720))
	check(String(openings["qingheng"]) != String(openings["nuomeizi"]) and String(openings["qingheng"]) != String(openings["danxia"]) and String(openings["nuomeizi"]) != String(openings["danxia"]), "openings are pairwise per-character")
	check(String(openings["nuomeizi"]) != String(openings["qingheng"]), "nuomeizi opening differs from qingheng")
	check(String(openings["danxia"]) != String(openings["qingheng"]), "danxia opening differs from qingheng")
	check(String(bios["qingheng"]) != String(bios["nuomeizi"]) and String(bios["qingheng"]) != String(bios["danxia"]) and String(bios["nuomeizi"]) != String(bios["danxia"]), "bios are pairwise per-character")
	for key in ["role_note", "quote", "bio", "closing", "seal", "scene", "opening"]:
		var a := String(panel.STORIES["qingheng"].get(key, ""))
		var b := String(panel.STORIES["nuomeizi"].get(key, ""))
		var c := String(panel.STORIES["danxia"].get(key, ""))
		check(a != b and a != c and b != c, "story field %s is per-character" % key)
	for key in ["tags", "choices", "replies"]:
		var x := JSON.stringify(panel.STORIES["qingheng"][key])
		var y := JSON.stringify(panel.STORIES["nuomeizi"][key])
		var z := JSON.stringify(panel.STORIES["danxia"][key])
		check(x != y and x != z and y != z, "story list %s is per-character" % key)
	for id in IDS:
		panel.show_mode("person")
		panel.select_maid(id)
		panel.show_mode("meeting")
		await frames()
		check(_tex_path(panel.meeting_image) == String(EXPECTED[id]["meeting"]), "meeting CG switches to %s" % id)
		var scene_story: Dictionary = panel._story()
		check(String(panel.line.text) == String(scene_story.get("opening", "")), "meeting line opens with %s story" % id)
		var scene_text := String(scene_story.get("scene", ""))
		check(not scene_text.is_empty() and String(panel.speaker.text).contains(scene_text), "speaker cites scene for %s" % id)
		await capture("meeting-" + String(id), Vector2i(1280, 720))
	panel.show_mode("person")
	panel.select_maid("nuomeizi")
	panel.show_mode("meeting")
	panel.restart_meeting()
	await frames()
	var nm_open := String(panel._story().get("opening", ""))
	check(not nm_open.is_empty() and String(panel.line.text) == nm_open, "nuomeizi meeting reset to opening")
	check(panel.choices.get_child_count() == 2, "nuomeizi presents two response buttons")
	var nm_reply := ""
	var nm_replies: Variant = panel._story().get("replies")
	if nm_replies is Array: nm_reply = String((nm_replies as Array)[0])
	if panel.choices.get_child_count() > 0:
		panel.choices.get_child(0).pressed.emit()
		await frames()
	check(not nm_reply.is_empty() and String(panel.line.text) == nm_reply, "choice shows per-character reply for nuomeizi")
	panel.restart_meeting()
	await frames()
	check(String(panel.line.text) == nm_open, "restart_meeting restores nuomeizi opening")
	check(int(panel.portrait_image.stretch_mode) == int(TextureRect.STRETCH_KEEP_ASPECT_CENTERED), "portrait keeps whole artwork")
	check(int(panel.meeting_image.stretch_mode) == int(TextureRect.STRETCH_KEEP_ASPECT_CENTERED), "meeting CG keeps whole artwork")
	check(abode.session.state.to_snapshot_dict() == before, "art switching leaves state unchanged")
	var fresh_view: Dictionary = abode.session.get_view()
	var fresh_maids: Dictionary = (fresh_view.get("maid", {}) as Dictionary).get("maids", {})
	var nm_info: Dictionary = fresh_maids.get("nuomeizi", {})
	var dx_info: Dictionary = fresh_maids.get("danxia", {})
	check(not bool(nm_info.get("recruited", true)) and not bool(dx_info.get("recruited", true)) and _tex_path(panel.portrait_image) == String(EXPECTED["nuomeizi"]["portrait"]), "unrecruited nuomeizi and danxia still show accepted art")
	panel.select_maid("danxia")
	panel.show_mode("person")
	await frames()
	panel.portrait_button.pressed.emit()
	await frames()
	check(nav.portrait_viewer.visible and String(nav.portrait_viewer.title_label.text).contains("丹霞"), "full viewer title names the current maid")
	check(_tex_path(nav.portrait_viewer.image) == String(EXPECTED["danxia"]["portrait"]), "full viewer shows the current maid artwork")
	nav.back()
	check(not nav.portrait_viewer.visible, "viewer closes back to the character page")
	abode.queue_free()
	await process_frame
	print("MAID-ART-R2 checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
