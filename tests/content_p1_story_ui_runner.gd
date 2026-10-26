extends SceneTree
const DIR := "res://docs/verification/artifacts/content-p1-story/"
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func frames() -> void:
	for i in 10: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name+".png")
func run() -> void:
	var scene = load("res://src/verification/content_p1_story_acceptance.tscn").instantiate()
	root.add_child(scene)
	await frames(); await frames()
	var abode = scene.abode
	if abode == null or abode.achievement_panel == null:
		check(false,"formal UI initialized"); RunnerResult.finish(self, 1); return
	var s: GameSession = abode.session
	var panel: AchievementPanel = abode.achievement_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp; root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp)); abode.feature_navigation.open("achievements"); await frames()
		check(panel._achievement_items.size()==30,"30 cards "+str(vp))
		for id in AchievementSystem.P1_DEFINITIONS:
			var card: Control = panel._achievement_items[id]
			panel._scroll.ensure_control_visible(card); await frames()
			var action: Button = card.get_node("HBox/Action")
			var art: TextureRect = card.get_node("HBox/Badge")
			check(art.texture != null,id+" art "+str(vp))
			check(card.size.x <= panel._scroll.size.x+1,id+" width")
			check(action.size.x>=44 and action.size.y>=44,id+" 44px")
			check(panel._scroll.get_global_rect().encloses(action.get_global_rect()),id+" action reachable")
			check(not card.tooltip_text.is_empty(),id+" readable condition")
			await shot("native-"+str(vp.x)+"-"+id)
		for def in FortuneSystem.get_encounters():
			if def.get("content_batch") != "content-p1-story": continue
			# Synthetic eligibility and balances; all choices use the real formal panel.
			s.state.economy = IslandEconomy.initial(); s.state.economy.islands.wood.opened = true
			var pending := StorySaveContract.freeze(def,s.state)
			pending.instance_id = ("native-story-"+def.id).sha256_text()
			s.state.economy = {}; s.state.fortune.pending_encounter = pending
			for id in ["wood","stone_low","spirit_grass_low","lingli","money"]: s.state.resources[id].value = AmountCompat.from_number(80)
			abode._refresh_hud(); abode.feature_navigation.open("fortune"); await frames()
			var fortune: FortuneModal = abode.fortune_modal
			check(fortune._art.texture != null,def.id+" art")
			check(fortune._option_rows.size()==3,def.id+" three options")
			for row in fortune._option_rows:
				fortune._body_scroll.ensure_control_visible(row.button); await frames()
				check(row.button.size.x>=44 and row.button.size.y>=44,def.id+" 44px")
				check(fortune._body_scroll.get_global_rect().encloses(row.button.get_global_rect()),def.id+" option reachable "+str(vp))
			await shot("native-"+str(vp.x)+"-"+def.id)
		abode.feature_navigation.home(); await frames()
		check(not abode.fortune_modal.visible and not panel.visible,"return")
	var write_file_native_ui := FileAccess.open(DIR+"native-ui.json",FileAccess.WRITE)
	if write_file_native_ui == null:
		push_error("write failed: " + str(DIR+"native-ui.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_native_ui.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-STORY UI ",checks," checks failures=",JSON.stringify(failures))
	scene.queue_free(); await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
