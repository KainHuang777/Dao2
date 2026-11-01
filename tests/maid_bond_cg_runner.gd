extends SceneTree
var checks := 0
var failures: Array[String] = []
const IDS := ["qingheng", "nuomeizi", "danxia"]
const EXPECTED := {
	"qingheng": {"path": "res://assets/characters/qingheng/bond-lamplight-r1.png", "title": "前世燈火", "name": "青蘅", "line": "不肯熄的燈"},
	"nuomeizi": {"path": "res://assets/characters/nuomeizi/bond-sword-rain-r1.png", "title": "劍鳴舊世", "name": "糯美子", "line": "同一場雨"},
	"danxia": {"path": "res://assets/characters/danxia/bond-night-vigil-r1.png", "title": "丹心照夜", "name": "丹霞", "line": "一爐未成的丹"},
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
		root.get_texture().get_image().save_png(RunnerResult.output_path("res://maid-bond-cg/%s-%dx%d.png" % [label, vp.x, vp.y]))
func _tex_path(image: TextureRect) -> String:
	if image == null or image.texture == null: return ""
	return String(image.texture.resource_path)
func _prepare(state, maid_id: String) -> void:
	var entry: Dictionary = MaidSystem._ensure_entry(state, maid_id)
	entry.recruited = true
	entry.bond = 50
	entry.chapters = {maid_id + "_1": true, maid_id + "_2": true}
func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://maid-bond-cg-save")
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
	abode.session.state.reincarnation_count = 1
	abode.session.state.talents["alchemical_past_wisdom"] = 1
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var nav = abode.feature_navigation
	var panel = nav.character_panel
	nav.open("characters")
	panel.show_mode("bond")
	abode._layout_for_size(Vector2(1280, 720))
	await frames()
	check(nav.portrait_viewer.image.texture == null, "no bond CG is preloaded before replay")
	var cg_paths: Array[String] = []
	for id in IDS:
		var def: Dictionary = panel.BOND_CG.get(id, {})
		var path := String(def.get("path", ""))
		cg_paths.append(path)
		check(ResourceLoader.exists(path), "accepted bond CG resolves for " + id)
		check(def.get("texture", null) == null, "bond CG table stores a path, not a texture, for " + id)
		var lines: Variant = def.get("lines", [])
		check(not String(def.get("title", "")).is_empty() and lines is Array and not (lines as Array).is_empty(), "bond CG memory copy present for " + id)
	check(cg_paths[0] != cg_paths[1] and cg_paths[0] != cg_paths[2] and cg_paths[1] != cg_paths[2], "each maid owns a distinct bond CG")
	for id in IDS:
		var expected: Dictionary = EXPECTED[id]
		_prepare(abode.session.state, id)
		abode._refresh_hud()
		await frames()
		panel.select_maid(id)
		await frames()
		var row_data: Dictionary = panel.chapter_rows[2]
		var claim: InscriptionAction = row_data["claim"]
		var memory: InscriptionAction = row_data["memory"]
		check(String(row_data.get("id", "")) == id + "_3", "third row maps to the final chapter for " + id)
		check(not memory.visible, "memory replay stays locked before the final chapter claim for " + id)
		check(not (panel.chapter_rows[0] as Dictionary)["memory"].visible and not (panel.chapter_rows[1] as Dictionary)["memory"].visible, "earlier chapters expose no bond CG replay for " + id)
		var claimed: Dictionary = MaidSystem.claim_chapter(abode.session.state, id, id + "_3")
		check(bool(claimed.get("ok", false)), "the existing final chapter flag is claimed for " + id)
		abode._refresh_hud()
		await frames()
		check(not claim.visible, "final chapter claim is consumed for " + id)
		check(memory.visible and not memory.disabled, "memory replay unlocks with the final chapter flag for " + id)
		check(memory.size.y >= 44, "memory replay keeps a 44px target for " + id)
		var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
		memory.pressed.emit()
		await frames()
		check(nav.portrait_viewer.visible and nav.shell.state.snapshot().overlay == "tool", "bond CG uses the shared blocking viewer overlay for " + id)
		check(_tex_path(nav.portrait_viewer.image) == String(expected["path"]), "viewer shows the accepted CG for " + id)
		check(String(nav.portrait_viewer.title_label.text) == "%s · %s" % [expected["name"], expected["title"]], "viewer title names the maid and chapter for " + id)
		check(String(nav.portrait_viewer.body.text).contains(String(expected["line"])), "viewer renders the chapter memory copy for " + id)
		check(nav.portrait_viewer.body_scroll.visible, "memory copy owns its own scroll area for " + id)
		check(nav.portrait_viewer.get_global_rect().encloses(nav.portrait_viewer.body_scroll.get_global_rect()), "memory copy stays inside the shared viewer for " + id)
		check(nav.portrait_viewer.image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "bond CG contains the whole accepted artwork for " + id)
		check(nav.portrait_viewer.image.texture != null and nav.portrait_viewer.image.texture.get_size() == Vector2(1672, 941), "bond CG keeps the accepted source resolution for " + id)
		await capture("memory-" + id, Vector2i(1280, 720))
		check(abode.session.state.to_snapshot_dict() == before, "replaying the bond CG grants nothing and changes no flag for " + id)
		nav.back()
		await frames()
		check(not nav.portrait_viewer.visible and panel.bond.visible, "closing the memory returns to the bond page for " + id)
		check(memory.visible and not claim.visible, "the final chapter stays claimed without re-claim for " + id)
		check(abode.session.state.to_snapshot_dict() == before, "closing the memory also leaves state untouched for " + id)
		await capture("bond-" + id, Vector2i(1280, 720))
	abode.queue_free()
	await process_frame
	print("MAID-BOND-CG checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
