extends SceneTree
func _init() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(640,560)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var bg := ColorRect.new()
	bg.color = Color("102b28")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var art = load("res://src/presentation/reincarnation_mandala.gd").new()
	art.texture = load("res://assets/ui/reincarnation-painted/reincarnation_wheel.png")
	art.ceremonial = true
	root.add_child(art)
	art.size = Vector2(460,460)
	art.position = Vector2(90,20)
	art.set_process(false)
	var label := Label.new()
	label.text = "六道流轉 · 一念歸真"
	label.add_theme_font_override("font",UiTypography.emphasis_font())
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",Color("f3d38a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	label.position = Vector2(0,500)
	label.size.x = 640
	for i in 48:
		art._process(0.125)
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://docs/verification/artifacts/uix-r7-f4/frame-%02d.png" % i)
		if error != OK:
			quit(1)
			return
	quit(0)
