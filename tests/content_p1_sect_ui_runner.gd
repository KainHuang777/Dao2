extends SceneTree
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p1-sect/")
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func frames() -> void:
	for i in 12: await process_frame
func run() -> void:
	var scene = load("res://src/verification/content_p1_sect_acceptance.tscn").instantiate()
	root.add_child(scene)
	while scene.abode == null or scene.abode.feature_navigation == null: await process_frame
	await frames()
	var abode = scene.abode
	await frames()
	var panel = abode.sect_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp; root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp)); await frames()
		for tab in [SectPanel.TabMode.TECHNIQUES,SectPanel.TabMode.MARKET]:
			panel._switch_tab(tab); await frames()
			var grid: GridContainer = panel._grids[0]
			check(grid.get_child_count()==8,"8 cards "+str([vp,tab]))
			for i in [4,5]:
				var card: Control = grid.get_child(i)
				panel._scroll.ensure_control_visible(card); await frames()
				var row: HBoxContainer = card.get_child(0)
				var art: TextureRect = row.get_child(0)
				var action: Button = row.get_child(row.get_child_count()-1)
				check(art.texture != null,"new art "+str([tab,i]))
				check(action.size.x>=44 and action.size.y>=44,"44px action")
				check(card.size.x <= panel._scroll.size.x+1,"card fits width "+str([vp,tab,i]))
				check(panel._scroll.get_global_rect().encloses(action.get_global_rect()),"action reachable "+str([vp,tab,i]))
				check(card.size.y <= panel._scroll.size.y,"full card "+str([vp,tab,i]))
				if card.size.y > panel._scroll.size.y: print("CARD ",card.size," SCROLL ",panel._scroll.size," PANEL ",panel.size)
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(DIR+"native-"+str(vp.x)+"-"+str(tab)+"-"+str(i)+".png")
		abode.feature_navigation.home(); check(not panel.visible,"return")
		abode.feature_navigation.open("sect"); await frames()
	var report_path := DIR+"native-ui.json" if OS.get_environment("DAO_TEST_STORAGE_ROOT").is_empty() else OS.get_environment("DAO_TEST_STORAGE_ROOT").path_join("p1-native-ui.json")
	var write_file_native_ui := FileAccess.open(report_path,FileAccess.WRITE)
	if write_file_native_ui == null:
		push_error("write failed: " + str(DIR+"native-ui.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_native_ui.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CONTENT-P1-SECT UI ",checks," checks failures=",JSON.stringify(failures))
	scene.queue_free(); await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
