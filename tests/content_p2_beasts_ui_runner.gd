extends SceneTree
var OUT := RunnerResult.output_path("res://docs/verification/artifacts/content-p2-beasts-ui/")
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("UI FAILURE ",label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/content-p2-beasts-ui/ui-storage")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide(); abode.v2_rules_notice.hide()
	var s: GameSession = abode.session
	s.state = GameSession.create_new_game(s.content,20261026).state
	s.state.era_id = 5
	check(s.submit({"type":"activate_islands","payload":{},"command_id":"beast2-ui-activation","expected_revision":s.state.revision}).ok,"synthetic activation")
	s.state.beast_version = BeastSystem.VERSION
	s.state.economy.islands.deep.opened = true
	s.state.economy.islands.ancient.opened = true
	var panel: Control = abode.feature_navigation.action_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp; root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp)); abode._refresh_hud()
		abode.feature_navigation.open("beasts")
		await frames()
		var page: Control = panel.beast_view
		check(page.cards.size() == 6,"six persistent cards")
		for id in BeastSystem.P2_IDS:
			var config: Dictionary = BeastSystem.BEAST_CONFIGS[id]
			var card: Dictionary = page.cards[id]
			check(card.art is UiIllustration and card.art.texture != null,"shared RGBA art "+id)
			for gate in ["era","island","active","ready"]:
				s.state.era_id = int(config.unlock_era)-1 if gate == "era" else 5
				s.state.economy.islands[config.island].opened = gate != "island"
				s.state.beasts = {"active":{"id":"jade_fox","stage":"egg","exp":0} if gate == "active" else {},"cooldown_remaining":0.0}
				panel.refresh(s.get_view())
				check(card.acquire.disabled == (gate != "ready"),"formal acquisition gate "+id+gate)
			var persistent: Button = card.acquire
			panel.refresh(s.get_view()); check(persistent == page.buttons["acquire:"+id],"refresh retains mouse target")
			s.state.beast_souls[id] = 11
			for tid in card.talents:
				panel.refresh(s.get_view())
				check(not card.talents[tid].button.disabled,"ordered talent affordability "+tid)
				var before: int = s.state.beast_souls[id]
				check(BeastSystem.unlock_talent(s.state,tid).ok,"formal synthetic soul purchase "+tid)
				check(before-int(s.state.beast_souls[id]) == int(BeastSystem.BEAST_TALENTS[tid].cost),"exact soul price "+tid)
			check(s.state.beast_souls[id] == 0,"11 souls spent")
			s.state.beasts = {"active":{"id":id,"stage":"young","exp":100},"cooldown_remaining":0.0}
			panel.refresh(s.get_view()); await frames()
			check("21" not in card.detail.text and "11" in card.detail.text,"T1 true young final percent")
			check("65XP" in card.detail.text,"T2 next XP")
			check("30" in card.detail.text,"T4 real local flat capacity")
			var cost_ok := false
			if id == "frost_stag":
				cost_ok = card.cost.tiles.has("refined_iron") and card.cost.tiles.refined_iron.quantity.text == "6" and card.cost.tiles.spirit_grass_low.quantity.text == "12"
			else:
				cost_ok = card.cost.tiles.has("spirit_grass_100y") and card.cost.tiles.spirit_grass_100y.quantity.text == "3" and card.cost.tiles.spirit_grass_1000y.quantity.text == "1"
			check(cost_ok,"T3 actual final costs")
			# Cards exceed short-landscape height. Verify the actual control can
			# scroll into view rather than asking the viewport to enclose a card.
			page.scroll.ensure_control_visible(card.feed); await frames()
			check(card.feed.size.x >= 44 and card.feed.size.y >= 44,"44px feed")
			check(page.scroll.get_global_rect().encloses(card.feed.get_global_rect()),"feed reachable")
			check(card.card.size.x <= page.scroll.size.x+1,"no horizontal overflow")
			check(card.card.size.x <= 860,"bounded beast reading width")
			check(card.feed.global_position.x - card.cost.global_position.x <= 180,"feed beside actual cost")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"native-"+str(vp.x)+"-"+id+".png")
			for tid in card.talents:
				var learn: Button = card.talents[tid].button
				page.scroll.ensure_control_visible(learn); await frames()
				check(learn.size.x >= 44 and learn.size.y >= 44,"44px talent "+tid)
				check(page.scroll.get_global_rect().encloses(learn.get_global_rect()),"talent reachable "+tid)
			s.state.beast_talents.clear(); s.state.beasts = {"active":{},"cooldown_remaining":0.0}
		panel.show_save_failure("隔離測試：保存失敗")
		check(panel.retry_button.visible and panel.status.visible,"save failure visible")
		panel.storage_recovered(); check(not panel.retry_button.visible,"recovery hides retry")
		abode.feature_navigation.home(); check(not panel.visible,"return home")
	var f := FileAccess.open(OUT+"ui.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"boundary":"Synthetic UI fixtures; direct signals/functions do not prove browser mouse"},"\t"))
	print("BEAST2 UI ",checks," failures=",JSON.stringify(failures))
	abode.queue_free(); await frames()
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
