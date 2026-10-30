extends SceneTree
var checks := 0
var failures := []
var DIR := RunnerResult.output_path("res://docs/verification/artifacts/content-p1-skills/")
func _init() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 12: await process_frame
func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(DIR+name+".png")
func run() -> void:
	# Establish the target viewport before scene setup; each matrix case below
	# explicitly opens the formal route before checking visible-page geometry.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var scene = load("res://src/verification/content_p1_skills_acceptance.tscn").instantiate()
	root.add_child(scene)
	await frames()
	var abode = scene.abode
	await frames()
	var panel = abode.feature_navigation.action_panel
	var page = panel.skill_view
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		abode.feature_navigation.open("skills")
		await frames()
		check(page.is_visible_in_tree() and panel.visible,"formal skill route visible "+str(vp))
		print("SKILL_UI_GEOMETRY ",vp," scroll=",page.scroll.get_global_rect()," card=",page.cards.alchemical_breath_control.card.get_global_rect())
		check(page.cards.size() == 24,"24 cards "+str(vp))
		for id in SkillSystem.P1_LIMITS:
			var row: Dictionary = page.cards[id]
			check(row.art.texture != null,"art "+id)
			check(row.action.size.x >= 44 and row.action.size.y >= 44,"44px "+id)
			check(row.card.size.x <= page.scroll.size.x+1,"width "+id)
			check(row.effect.size.y >= row.effect.get_minimum_size().y,"effect not clipped "+id)
			check(row.action.global_position.x - row.cost.global_position.x < 200,"cost and action grouped "+id)
			check(row.card.size.x <= 760,"bounded reading width "+id)
			page.scroll.ensure_control_visible(row.card)
			await frames()
			check(page.scroll.get_global_rect().encloses(row.action.get_global_rect()),"action reachable "+id)
			await shot("native-"+str(vp.x)+"-"+id)
		check(page.scroll.size.y >= page.cards.alchemical_breath_control.card.size.y,"full card height "+str(vp))
		abode.feature_navigation.home()
		check(not panel.visible,"return "+str(vp))
		abode.feature_navigation.open("skills")
		await frames()
	print("CONTENT-P1-SKILL UI ",checks," checks failures=",JSON.stringify(failures))
	var f := FileAccess.open(DIR+"native-ui.json",FileAccess.WRITE)
	if f == null:
		push_error("write failed: " + DIR + "native-ui.json")
		RunnerResult.finish(self, 1)
	else:
		f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	scene.queue_free()
	await frames()
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
