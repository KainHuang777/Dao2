extends SceneTree
const OUT="E:/WORK/Dao2/docs/verification/artifacts/trib-b/"
var failures := []
var checks := 0
func _init() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func snap(name: String) -> void:
	# Background SubViewport and foreground must both render the same explicit time.
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+name+".png")==OK,"capture "+name)
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var page=load("res://preview.tscn").instantiate()
	root.add_child(page)
	for i in 8: await process_frame
	var art=page.effect
	art.paused=true
	for dimensions in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size=dimensions
		for i in 6: await process_frame
		for button in page.controls.values():
			check(button.size.y>=44,"44px "+button.text)
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_global_rect()),"inside "+button.text)
		check(art.size.x>=200 and art.size.y>=120,"stage area")
		for failed in [false,true]:
			art.failed=failed
			for time in [0.0,3.5,6.5,9.4,14.0,20.0]:
				art.seek(time)
				var actor: Sprite2D=art.foreground[art.pose]
				var anchor: Vector2=(Vector2(64,64)+art.CORES[art.pose]*896.0)/1024.0
				var actual: Vector2=actor.position+(anchor-Vector2(.5,.5))*actor.texture.get_size()*actor.scale
				check(actual.distance_to(art.core)<.01,"pose core aligned")
				check(Rect2(Vector2.ZERO,art.size).encloses(Rect2(actor.position-actor.texture.get_size()*actor.scale*.5,actor.texture.get_size()*actor.scale)),"full actor canvas")
				if art.strike>.1: check(art.bolts[0].points[-1]==art.core,"bolt contact")
				await snap("pose-%s-%dx%d-%04.1f" % ["failure" if failed else "success",dimensions.x,dimensions.y,time])
	root.size=Vector2i(1280,720)
	for i in 6: await process_frame
	art.failed=false
	art.seek(4)
	var before: float=art.clock
	art._process(.2)
	check(art.clock==before,"pause")
	art.paused=false
	art.hide()
	art._process(.2)
	check(art.clock==before,"hidden")
	art.show()
	art.paused=true
	for mode in ["背景","人物","護體","雷擊","修羅"]:
		art.solo=mode
		art.failed=true
		art.seek(13.4 if mode=="修羅" else 9.4)
		await snap("solo-"+str(["背景","人物","護體","雷擊","修羅"].find(mode)))
	art.solo="合成"
	art.reduced=true
	art.seek(9.4)
	check(not art.bolts[0].visible,"reduced bolt off")
	check(art.backdrop.material.get_shader_parameter("bend")==0.0,"reduced distortion off")
	await snap("reduced")
	art.reduced=false
	for toggle in [false,true]:
		art.glow=toggle
		art.fisheye=toggle
		art.seek(4)
		await snap("effects-"+str(toggle))
	page.muted=false
	art.paused=false
	art.seek(9)
	page.sync_audio()
	check(page.audio.playing,"sound start")
	page._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not page.audio.playing and art.paused,"focus stops sound and time")
	page.focused=true
	art.paused=true
	art.seek(20)
	page.sync_audio()
	check(not page.audio.playing,"skip stops sound")
	page.muted=true
	# 20s per outcome, actual fixed-time Godot renders, no FPS claim.
	root.size=Vector2i(960,540)
	for i in 6: await process_frame
	for failed in [false,true]:
		art.failed=failed
		var prefix: String="failure" if failed else "success"
		page.streams[1 if failed else 0].save_to_wav(OUT+prefix+".wav")
		for i in 240:
			art.seek(float(i)/12)
			await snap(prefix+"-%03d"%i)
	var result={"checks":checks,"failures":failures,"frames":480,"capture_fps":12,"duration_each":20,"engine":Engine.get_version_info().string,"note":"fixed-time native render; not runtime FPS evidence"}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("TRIBB_CHECKS ",JSON.stringify(result))
	page.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
