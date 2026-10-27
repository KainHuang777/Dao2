extends SceneTree
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p1-talents/")
var checks := 0
var failures := []
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 12: await process_frame
func run() -> void:
	var scene = load("res://src/verification/content_p1_talents_acceptance.tscn").instantiate()
	root.add_child(scene)
	await frames()
	var abode = scene.abode
	await frames()
	var page = abode.reincarnation_panel
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		page._switch_tab("talents")
		page.set_save_result({"ok":true})
		await frames()
		check(not page._feedback_row.visible if vp.y < 500 else page._feedback_row.visible,"saved feedback fits "+str(vp))
		check(page._talent_rows.size() == TalentSystem.TALENTS.size(),"all current cards "+str(vp))
		for id in TalentSystem.TALENTS:
			var row = page._talent_rows[id]
			var button: Button = row.find_child("LearnButton",true,false)
			var desc: Label = row.find_child("TalentDesc",true,false)
			check(row.find_child("TalentArt",true,false).texture != null,"art "+id)
			check(button.size.x >= 44 and button.size.y >= 44,"44px "+id)
			check(row.size.x <= page._body_scroll.size.x+1,"width "+id)
			check(desc.size.y >= desc.get_minimum_size().y,"description not clipped "+id)
			page._body_scroll.ensure_control_visible(row)
			await frames()
			check(page._body_scroll.get_global_rect().encloses(button.get_global_rect()),"reachable "+id)
			check(page._body_scroll.size.y >= row.size.y,"full card "+id+str(vp))
			if id in TalentSystem.P1_IDS and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(DIR+"native-"+str(vp.x)+"-"+id+".png")
		abode.feature_navigation.home()
		check(not page.visible,"return "+str(vp))
		abode.feature_navigation.open("reincarnation")
		await frames()
	print("CONTENT-P1-TALENT UI ",checks," checks failures=",JSON.stringify(failures))
	var f := FileAccess.open(DIR+"native-ui.json",FileAccess.WRITE)
	if f == null:
		push_error("write failed: " + DIR + "native-ui.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	scene.queue_free()
	await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
