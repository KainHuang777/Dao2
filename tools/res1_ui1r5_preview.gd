extends SceneTree
## Isolated captures and review fixture for UI1-B; player directories stay untouched.
const OUT := "res://docs/verification/artifacts/res1-ui1-r5"
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://res1_ui1r5_preview"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.offline_summary.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	if not decoded.ok:
		quit(1)
		return
	abode.session.state = decoded.state.duplicate_state()
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var fixture := SaveCodec.encode(abode.session.state, abode.content.content_version, {"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": str(int(abode.session.state.total_elapsed_seconds))})
	if not fixture.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/res1-ui1-r5-review.json", FileAccess.WRITE)
	file.store_string(fixture.json)
	file.close()
	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root.size = vp
		root.content_scale_size = vp
		await create_timer(0.2).timeout
		var nav = abode.feature_navigation
		nav.transport_panel.drafts.clear()
		nav.open("transport")
		abode._layout_for_size(root.get_visible_rect().size)
		await capture("routes-%dx%d" % [vp.x, vp.y])
		nav.transport_panel.show_success("航線設定已保存；停航時在途貨物仍會到貨。")
		await capture("receipt-%dx%d" % [vp.x, vp.y])
		nav.transport_panel.show_result("")
		nav.open_transport("ore_wood")
		await capture("settings-%dx%d" % [vp.x, vp.y])
		nav.transport_panel.reserve.text = "5.125"
		nav.transport_panel.reserve.text_changed.emit("5.125")
		nav.back()
		await capture("draft-%dx%d" % [vp.x, vp.y])
		print("UI1R5_RECT ", nav.transport_panel.get_global_rect(), " viewport=", root.get_visible_rect(), " min=", nav.transport_panel.get_combined_minimum_size())
		_inspect(nav.transport_panel, nav.transport_panel.get_global_rect())
	abode.queue_free()
	await process_frame
	script.save_dir_override = ""
	quit(0)
func capture(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
	if result != OK:
		quit(1)
	print("UI1R5_CAPTURE ", label)

func _inspect(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree() and (node.get_combined_minimum_size().x > bounds.size.x or node.get_global_rect().end.x > bounds.end.x + 1):
		print("UI1R5_OVERSIZE ", node.get_path(), " rect=", node.get_global_rect(), " min=", node.get_combined_minimum_size())
	for child in node.get_children():
		_inspect(child, bounds)
