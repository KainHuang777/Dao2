extends SceneTree
var failures: Array[String] = []
var checks := 0
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for _i in 15: await process_frame
func run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://early-v1c-native"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await frames()
	abode.set_process(false)
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/early-v1-c/web-fixture.json"))
	check(decoded.ok, "fixture decode")
	abode.session.state = decoded.state
	abode.offline_summary.hide()
	abode._refresh_hud()
	abode.feature_navigation.open("skills")
	var panel = abode.feature_navigation.action_panel
	var page = panel.skill_view
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)]:
		root.size = vp
		root.content_scale_size = vp
		abode._layout_for_size(Vector2(vp))
		await frames()
		page.scroll.scroll_vertical = 0
		await frames()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/verification/artifacts/early-v1-c/native-first-%dx%d.png" % [vp.x,vp.y])
		page.scroll.scroll_vertical = 10000
		panel.show_result("操作完成，進度已更新。")
		await frames()
		page.scroll.scroll_vertical = 10000
		await frames()
		var row: Dictionary = page.cards.golden_core_formation
		check(row.art.texture != null, "golden art loaded")
		check(page.scroll.get_global_rect().encloses(row.art.get_global_rect()), "complete art reachable")
		check(page.scroll.get_global_rect().encloses(row.action.get_global_rect()), "golden action reachable")
		check(row.action.size.y >= 44 and not row.action.disabled, "funded 44px action")
		check(page.scroll.get_global_rect().encloses(row.card.get_global_rect()), "complete card after success")
		check(row.effect.text.contains("1.000") and row.effect.text.contains("0.900"), "before and after effects")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/verification/artifacts/early-v1-c/native-golden-%dx%d.png" % [vp.x,vp.y])
	FileAccess.open("res://docs/verification/artifacts/early-v1-c/native-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	abode.queue_free()
	await process_frame
	print("EARLY-V1-C native checks=%d failures=%s" % [checks,str(failures)])
	quit(0 if failures.is_empty() else 1)
