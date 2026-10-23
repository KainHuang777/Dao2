extends SceneTree
const OUT := "res://docs/verification/artifacts/ui-art-edge/"
var checks := 0
var failures: Array[String] = []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for i in 8: await process_frame
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://src/verification/ui_art_edge_acceptance.tscn").instantiate()
	root.add_child(scene)
	await frames()
	for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = vp
		root.content_scale_size = vp
		for edge in [192, 112, 64, 28]:
			scene.set_edge(edge)
			await frames()
			for index in [1, 3, 5]:
				var image: TextureRect = scene.pictures[index]
				check(image is UiIllustration, "shared component")
				check(image.size.is_equal_approx(Vector2.ONE * edge), "unshrunk picture " + str(edge))
				check(image.material.get_shader_parameter("enabled") == (edge >= 40), "dense icon exemption")
				check(image.mouse_filter == Control.MOUSE_FILTER_IGNORE, "no input interception")
			check(scene.scroll.get_h_scroll_bar().max_value <= scene.scroll.size.x, "no horizontal overflow")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"native-"+str(vp.x)+"-"+str(edge)+".png")
	# Transform scaling must change sampling/padding, not make a 2.3px outline.
	var sample := UiIllustration.new()
	sample.texture = scene.pictures[1].texture
	root.add_child(sample)
	sample.size = Vector2(64, 64)
	sample.scale = Vector2(1.5, 1.5)
	await frames()
	check(sample.material.get_shader_parameter("pixel_scale").is_equal_approx(Vector2(1.5, 1.5)), "screen scale included")
	var replacement := load("res://assets/ui/reincarnation-painted/reincarnation_wheel.png")
	sample.texture = replacement
	await frames()
	check(sample._signature[0] == replacement, "runtime texture replacement")
	check(sample.material != scene.pictures[3].material, "independent sampling uniforms")
	check(sample.material.get_shader_parameter("art_texture") == replacement, "replacement reaches renderer")
	sample.texture = load("res://assets/ui/achievements-painted/build_first_hut.png")
	await frames()
	check(not sample.material.get_shader_parameter("enabled"), "authored gold frame is not outlined twice")
	if DisplayServer.get_name() != "headless":
		# Render an isolated alpha fixture: catches blank textures, rectangular halos,
		# double modulation, and effects accidentally scaled in source texels.
		var viewport := SubViewport.new()
		viewport.size = Vector2i(128, 128)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var pixels := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		pixels.fill_rect(Rect2i(8, 8, 16, 16), Color.RED)
		var fixture := UiIllustration.new()
		fixture.texture = ImageTexture.create_from_image(pixels)
		fixture.position = Vector2(32, 32)
		fixture.size = Vector2(64, 64)
		viewport.add_child(fixture)
		await frames()
		await RenderingServer.frame_post_draw
		var rendered := viewport.get_texture().get_image()
		check(rendered.get_pixel(64, 64).is_equal_approx(Color.RED), "opaque center preserves original color")
		check(rendered.get_pixel(47, 64).a > 0.1, "outline extends outside solid alpha")
		check(rendered.get_pixel(40, 64).a < 0.01, "no rectangular halo")
		check(rendered.get_pixel(64, 82).a > 0.01, "downward soft shadow rendered")
		fixture.modulate.a = 0.5
		await frames()
		await RenderingServer.frame_post_draw
		rendered = viewport.get_texture().get_image()
		check(absf(rendered.get_pixel(64, 64).a - 0.5) < 0.02, "modulation applied once")
		viewport.queue_free()
	print("UI-ART-EDGE ",checks," checks failures=",JSON.stringify(failures))
	var result := FileAccess.open(OUT + ("native.json" if DisplayServer.get_name() != "headless" else "runner.json"), FileAccess.WRITE)
	result.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	sample.queue_free()
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

