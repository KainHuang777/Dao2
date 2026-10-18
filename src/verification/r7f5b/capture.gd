extends SceneTree
var failures: Array[String] = []
const OUT = "E:/WORK/Dao2/docs/verification/artifacts/uix-r7-f5b-f2/"
func _init() -> void: run.call_deferred()
func check(condition: bool,message: String) -> void:
	if not condition: failures.append(message)
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"save "+name)
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var page=load("res://preview.tscn").instantiate()
	root.add_child(page)
	for i in 10: await process_frame
	var art=page.effect
	art.paused=true
	check(art.ready_for_capture,"glyph caches ready")
	for word in art.WORDS:
		for character in word: check(art.font.has_char(character.unicode_at(0)),"font coverage "+character)
	for word in art.SANSKRIT:
		for character in word: check(art.sanskrit_font.has_char(character.unicode_at(0)),"Sanskrit coverage "+character)
	for vp in art.caches: check(vp.render_target_update_mode==SubViewport.UPDATE_DISABLED,"cache stopped")
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size=dimensions
		for i in 6: await process_frame
		for button in page.controls.values():
			check(button.size.y>=44,"44px button")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"button in viewport "+button.text)
		art.clock=1.5
		art.apply_pose()
		await snap("composite-%dx%d" % [dimensions.x,dimensions.y])
	root.size=Vector2i(1280,720)
	for i in 6: await process_frame
	for mode in ["裸盤","花光","雲霧","豎字"]:
		art.solo=mode
		art.apply_pose()
		await snap("solo-"+str(["裸盤","花光","雲霧","豎字"].find(mode)))
	art.solo="裸盤"
	for quarter in 8:
		art.clock=float(quarter)
		art.apply_pose()
		await snap("bare-angle-%03d" % (quarter*45))
	art.solo="合成"
	art.clock=1.5
	art.apply_pose()
	var before: float=art.rotor.rotation
	art.clock=3.5
	art.apply_pose()
	check(is_equal_approx(art.rotor.rotation-before,PI/2),"disc rotates 90deg in two seconds")
	check(art.layers.lotus.rotation==0.0,"lotus upright")
	check(art.layers.disc_rim_fixed.rotation==0.0,"rim stationary")
	check(art.rotor.scale==Vector2.ONE*0.86,"disc full carving fits aperture")
	check(art.layers.disc_rim_fixed.offset==Vector2(-5.5,11.5),"housing aperture centered")
	check(art.layers.mist_front_left.position.x>512 and art.layers.mist_front_right.position.x<512,"mist opposite")
	var stopped: float=art.clock
	art._process(0.05)
	check(art.clock==stopped,"pause stops explicit clock")
	art.paused=false
	art.hide()
	art._process(0.05)
	check(art.clock==stopped,"hidden stops clock")
	art.show()
	art.reduced=true
	art.apply_pose()
	art._process(0.05)
	check(art.clock==stopped and art.rotor.rotation==0.0,"reduced static")
	await snap("reduced")
	art.reduced=false
	art.clock=1.5
	art.glow_enabled=false
	art.apply_pose()
	await snap("glow-off")
	art.glow_enabled=true
	art.apply_pose()
	await snap("glow-on")
	# Fixed-time captures of the actual Godot composite, 8 seconds / 24fps.
	art.paused=true
	root.size=Vector2i(800,600)
	for i in 6: await process_frame
	for i in 192:
		art.clock=float(i)/24.0
		art.apply_pose()
		await snap("frame-%03d" % i)
	art.solo="裸盤"
	for i in 192:
		art.clock=float(i)/24.0
		art.apply_pose()
		await snap("bare-frame-%03d" % i)
	var result={"task":"UIX-R7-F5-B-F2","failures":failures,"frames":384,"capture_fps":24,"duration_each":8,"engine":Engine.get_version_info().string,"draw_order":{"housing":art.layers.disc_rim_fixed.get_index(),"rotor":art.rotor.get_index()},"note":"rotor above housing; composite and bare full-turn fixed-time Godot renders; not runtime FPS evidence"}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("F5B_CHECKS ",JSON.stringify(result))
	page.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
