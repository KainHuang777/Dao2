extends SceneTree
const DIR := "res://docs/verification/artifacts/content-p1-pills/"
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 12: await process_frame
func run() -> void:
	var scene = load("res://src/verification/content_p1_pills_acceptance.tscn").instantiate()
	root.add_child(scene)
	await frames()
	var abode = scene.abode
	await frames()
	var page = abode.alchemy_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		page.show_feedback("煉製成功・養木丹 +1", true, "wood_nurture_pill")
		page.update_view(abode.session.get_view())
		await frames()
		check(page._pill_rows.size() == AlchemySystem.PILLS.size(),"all current cards "+str(vp))
		for id in AlchemySystem.P1_IDS:
			var row: Control = page._pill_rows[id]
			var w: Dictionary = page._widgets[id]
			check(w.output.icon.resource_texture() != null,"art "+id)
			for button in [w.refine,w.consume]:
				check(button.size.x >= 44 and button.size.y >= 44,"44px "+id)
			check(row.size.x <= page._scroll.size.x+1,"width "+id)
			check("祖島" in (w.title.text if page._short else w.status.text),"scope status "+id)
			page._scroll.ensure_control_visible(row)
			await frames()
			check(page._scroll.get_global_rect().encloses(w.refine.get_global_rect()),"reachable "+id)
			check(page._scroll.get_global_rect().encloses(w.consume.get_global_rect()),"consume reachable "+id)
			check(page._scroll.size.y >= row.size.y,"full card "+id+str(vp))
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(DIR+"native-"+str(vp.x)+"-"+id+".png")
		abode.feature_navigation.home()
		check(not page.visible,"return "+str(vp))
		abode.feature_navigation.open("alchemy")
		await frames()
	print("CONTENT-P1-PILL UI ",checks," checks failures=",JSON.stringify(failures))
	var f := FileAccess.open(DIR+"native-ui.json",FileAccess.WRITE)
	if f == null:
		push_error("write failed: " + DIR + "native-ui.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	scene.queue_free()
	await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
