extends SceneTree
## Synthetic UI states; earned flow is separately recorded.
const OUT := "res://docs/verification/artifacts/content-p2-sect-ui/"
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	SaveManager.configure(content,FileStorageAdapter.new(OUT+"ui-unused-storage"))
	var session := GameSession.create_new_game(content,20261025)
	var state := session.state
	state.era_id = 6
	state.highest_era = 6
	state.buildings.core_storehouse_4 = 1
	state.buildings.core_storehouse_5 = 1
	check(session.submit({"command_id":"ui-activate","type":"activate_islands","payload":{},"expected_revision":state.revision}).ok,"synthetic activate")
	for island in state.economy.islands: state.economy.islands[island].opened = true
	SectSystem.ensure_sect_state(state)
	state.sect.unlocked = true
	state.sect.contribution = "10000"
	state.resources.wood.value = AmountCompat.from_number(10000)
	state.resources.stone_low.value = AmountCompat.from_number(10000)
	var panel := SectPanel.new()
	root.add_child(panel)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX")=="full" else [Vector2i(1280,720)]):
		root.size = vp; root.content_scale_size = vp
		# Match the normal short workspace after the HUD, feature tabs and dock.
		panel.set_layout_bounds(Rect2(0,0,vp.x-48,vp.y-230) if vp.y < 500 else Rect2(0,0,vp.x-160,vp.y-150))
		panel.update_view(state)
		for tab in [SectPanel.TabMode.TECHNIQUES,SectPanel.TabMode.MARKET]:
			panel._switch_tab(tab); await frames()
			var grid: GridContainer = panel._grids[0]
			check(grid.get_child_count()==8,"eight cards "+str(tab))
			for i in [6,7]:
				var card: Control = grid.get_child(i)
				panel._scroll.ensure_control_visible(card); await frames()
				var row = card.get_child(0)
				var art: Control = row.get_child(0)
				var button: Button = row.get_child(row.get_child_count()-1)
				check((art is TextureRect and art.texture != null) if tab==SectPanel.TabMode.TECHNIQUES else (art is Label and art.text in ["精鐵","千草"]),"P2 art or named fallback "+str([tab,i]))
				check(art is UiIllustration if tab==SectPanel.TabMode.TECHNIQUES else art is Label,"shared B art or named resource")
				check(button.size.x>=44 and button.size.y>=44,"44px action")
				check(card.size.x <= panel._scroll.size.x+1,"card width")
				check(panel._scroll.get_global_rect().encloses(button.get_global_rect()),"action reachable")
				check(card.size.y <= panel._scroll.size.y,"card fits "+str([vp,tab,i,card.size,panel._scroll.size]))
				check(not button.disabled,"eligible enabled")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OUT+"native-"+str(vp.x)+"-"+str(tab)+"-"+str(i)+".png")
		panel._switch_tab(SectPanel.TabMode.TECHNIQUES)
		check("鐵30／石100" in panel._p2_technique_preview("sacred_beast_feed_conservation") and "鐵29／石98" in panel._p2_technique_preview("sacred_beast_feed_conservation"),"actual turtle fees")
		check("草10 → 9" in panel._p2_technique_preview("sacred_beast_feed_conservation"),"phoenix actual 10 to9")
		check("1,000" in panel._p2_technique_preview("p2_pill_qi_conservation") or "1000" in panel._p2_technique_preview("p2_pill_qi_conservation"),"actual Amount fee")
		for id in SectSystem.P2_TECHNIQUES:
			for condition in ["era","supply","life","poor","max"]:
				var branch := state.duplicate_state()
				if condition=="era": branch.era_id=3
				if condition=="supply": branch.economy={}
				if condition=="life": branch.total_elapsed_seconds=1e10
				if condition=="poor": branch.sect.contribution="0"
				if condition=="max": branch.sect.techniques[id]=5
				panel.update_view(branch); panel._switch_tab(SectPanel.TabMode.TECHNIQUES); await frames()
				var idx := 6 if id==SectSystem.P2_TECHNIQUES[0] else 7
				var row = panel._grids[0].get_child(idx).get_child(0)
				var action: Button = row.get_child(row.get_child_count()-1)
				check(action.disabled,"official technique gate "+id+condition)
		for id in SectSystem.P2_MARKET:
			for condition in ["era","island","full","sold","life"]:
				var branch := state.duplicate_state()
				var def: Dictionary = SectSystem.MARKET_ITEMS[id]
				if condition=="era": branch.era_id=3
				if condition=="island": branch.economy.islands[def.requires_open_island].opened=false
				if condition=="full": branch.resources[def.grant_resource].value=AmountCompat.from_number(100000000)
				if condition=="sold": branch.sect.market_purchases[id]=10
				if condition=="life": branch.total_elapsed_seconds=1e10
				panel.update_view(branch); panel._switch_tab(SectPanel.TabMode.MARKET); await frames()
				var row = panel._grids[0].get_child(6 if id==SectSystem.P2_MARKET[0] else 7).get_child(0)
				var action: Button = row.get_child(row.get_child_count()-1)
				check(action.disabled,"market gate "+id+condition)
				check(action.text=={"era":"境界未達","island":"來源島未開","full":"庫存已滿","sold":"售罄","life":"壽元已盡"}[condition],"specific market reason "+condition)
	panel.queue_free(); await frames()
	var file := FileAccess.open(OUT+"native-ui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"level":"L1","checks":checks,"failures":failures,"synthetic":true},"\t"))
	print("SECT2 UI ",checks," failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
