extends SceneTree
## Offline asset registration and QA only; never loads GameSession or user saves.
const OUT = "res://docs/verification/artifacts/uix-r7-f5a/"
const DEST = "res://assets/ui/reincarnation-layered-f5a/"
const IDS = ["mist_back", "disc_face", "disc_rim_fixed", "tassels", "lotus", "lotus_emission", "light_ribbon", "mist_front_left", "mist_front_right"]
var layers: Dictionary = {}
var entries: Array = []
var failures: Array = []

func blank() -> Image:
	return Image.create(1024, 1024, false, Image.FORMAT_RGBA8)

func raw(id: String) -> Image:
	var im = Image.load_from_file(OUT + "originals/" + id + ".png")
	im.convert(Image.FORMAT_RGBA8)
	return im

func fitted(im: Image, rect: Rect2i, crop: bool = true) -> Image:
	var source = im.get_region(im.get_used_rect()) if crop else im.duplicate()
	source.resize(rect.size.x, rect.size.y, Image.INTERPOLATE_LANCZOS)
	var result = blank()
	result.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), rect.position)
	return result

func blend(base: Image, overlay: Image) -> void:
	base.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)

func project(im: Image) -> Image:
	var source = im.duplicate()
	source.resize(962, 922, Image.INTERPOLATE_LANCZOS)
	var result = blank()
	result.blend_rect(source, Rect2i(0, 11, 962, 911), Vector2i(31, 0))
	return result

func composite(angle: int, bare: bool = false) -> Image:
	var result = blank()
	if not bare: blend(result, layers.mist_back)
	var disc = layers.disc_face.duplicate()
	for quarter in range(angle / 90): disc.rotate_90(CLOCKWISE)
	blend(result, project(disc))
	blend(result, project(layers.disc_rim_fixed))
	if not bare:
		for id in ["tassels", "lotus", "light_ribbon", "mist_front_left", "mist_front_right"]:
			blend(result, layers[id])
	return result

func save(im: Image, path: String) -> void:
	var err = im.save_png(path)
	if err != OK: failures.append("save failed " + path)

func background(im: Image, color: Color) -> Image:
	var result = Image.create(im.get_width(), im.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(color)
	blend(result, im)
	return result

func _initialize() -> void:
	layers.disc_face = fitted(raw("disc_face"), Rect2i(232, 232, 560, 560))
	layers.disc_rim_fixed = fitted(raw("disc_rim_fixed"), Rect2i(102, 102, 820, 820))
	# Source canvas is preserved for lotus and mask: do not auto-crop them independently.
	layers.lotus = fitted(raw("lotus"), Rect2i(252, 270, 520, 347), false)
	var mask_source = raw("lotus_emission_v2")
	# Interpret the generated grayscale mask: only near-white contour values emit.
	# Gray petal fill is a zero-emission value, not a second opaque flower.
	for y in mask_source.get_height():
		for x in mask_source.get_width():
			var c = mask_source.get_pixel(x, y)
			var strength = smoothstep(0.88, 0.98, minf(c.r, minf(c.g, c.b))) * c.a
			mask_source.set_pixel(x, y, Color(1, 1, 1, strength))
	layers.lotus_emission = fitted(mask_source, Rect2i(252, 270, 520, 347), false)
	layers.mist_back = fitted(raw("mist_back"), Rect2i(62, 600, 900, 175))
	layers.mist_front_left = fitted(raw("mist_front_left"), Rect2i(80, 712, 520, 180))
	layers.mist_front_right = fitted(raw("mist_front_right"), Rect2i(430, 748, 514, 175))
	layers.light_ribbon = fitted(raw("light_ribbon"), Rect2i(412, 500, 220, 390), false)
	var tassel_source = raw("tassels")
	var half = tassel_source.get_width() / 2
	layers.tassels = fitted(tassel_source.get_region(Rect2i(0, 0, half, tassel_source.get_height())), Rect2i(108, 436, 110, 288), false)
	blend(layers.tassels, fitted(tassel_source.get_region(Rect2i(half, 0, half, tassel_source.get_height())), Rect2i(806, 436, 110, 288), false))
	var records = JSON.parse_string(FileAccess.get_file_as_string(OUT + "generation-records.json"))
	var contact = Image.create(1536, 1536, false, Image.FORMAT_RGBA8)
	contact.fill(Color("33383a"))
	for index in IDS.size():
		var id: String = IDS[index]
		var im: Image = layers[id]
		save(im, DEST + id + ".png")
		var bounds = im.get_used_rect()
		if bounds.position.x < 24 or bounds.position.y < 24 or bounds.end.x > 1000 or bounds.end.y > 1000:
			failures.append(id + " insufficient safe margin")
		var source_id = "lotus_emission_v2" if id == "lotus_emission" else id
		var record: Dictionary = {}
		for item in records:
			if item.id == source_id: record = item
		entries.append({"id": id, "file": id + ".png", "canvas": [1024, 1024], "pivot": [512, 512], "z_index": index,
			"source": OUT.trim_prefix("res://") + "originals/" + source_id + ".png", "source_sha256": FileAccess.get_sha256(OUT + "originals/" + source_id + ".png"),
			"sha256": FileAccess.get_sha256(DEST + id + ".png"), "prompt": record.get("prompt", ""),
			"bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
			"mask_of": "lotus" if id == "lotus_emission" else "", "transform_space": "disc_plane" if id in ["disc_face", "disc_rim_fixed"] else "composition"})
		var small = im.duplicate()
		small.resize(512, 512, Image.INTERPOLATE_LANCZOS)
		contact.blend_rect(small, Rect2i(0, 0, 512, 512), Vector2i((index % 3) * 512, (index / 3) * 512))
		for bg in {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}:
			save(background(im, {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}[bg]), OUT + id + "-" + bg + ".png")
	save(contact, OUT + "layers-contact.png")
	var angle_sheet = Image.create(2048, 2048, false, Image.FORMAT_RGBA8)
	angle_sheet.fill(Color("ede6d7"))
	var bare_sheet = angle_sheet.duplicate()
	for index in 4:
		var angle = index * 90
		var comp = composite(angle)
		var bare = composite(angle, true)
		save(comp, OUT + "composite-%03d.png" % angle)
		save(bare, OUT + "bare-%03d.png" % angle)
		angle_sheet.blend_rect(comp, Rect2i(0, 0, 1024, 1024), Vector2i((index % 2) * 1024, (index / 2) * 1024))
		bare_sheet.blend_rect(bare, Rect2i(0, 0, 1024, 1024), Vector2i((index % 2) * 1024, (index / 2) * 1024))
		# No transparent holes anywhere in the visible rotating aperture at all four angles.
		var holes = 0
		for y in range(250, 651):
			for x in range(312, 713):
				if Vector2(x - 512, (y - 450) / 0.96).length() < 235 and bare.get_pixel(x, y).a < 0.95: holes += 1
		if holes > 0: failures.append("angle %d aperture holes: %d" % [angle, holes])
	save(angle_sheet, OUT + "four-angles.png")
	save(bare_sheet, OUT + "four-angles-bare.png")
	var base = composite(0)
	for bg in {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}:
		save(background(base, {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}[bg]), OUT + "composite-" + bg + ".png")
	# Compare final display at 460px using three texture resolutions.
	var comparison = Image.create(1380, 460, false, Image.FORMAT_RGBA8)
	comparison.fill(Color("ede6d7"))
	for index in 3:
		var resolution = [512, 768, 1024][index]
		var sample = base.duplicate()
		sample.resize(resolution, resolution, Image.INTERPOLATE_LANCZOS)
		sample.resize(460, 460, Image.INTERPOLATE_LANCZOS)
		comparison.blend_rect(sample, Rect2i(0, 0, 460, 460), Vector2i(index * 460, 0))
	save(comparison, OUT + "resolution-comparison.png")
	var manifest = {"task": "UIX-R7-F5-A", "date": "2026-10-18", "status": "candidate_pending_visual_acceptance", "generator": "built-in ImageGen",
		"source_reference": "docs/verification/artifacts/uix-r7/originals/reincarnation_wheel.png", "license": "AI-generated for this project from project-owned AI reference; no third-party commercial license asserted",
		"canvas": [1024, 1024], "origin": [0, 0], "disc_pivot": [512, 512], "projected_disc_center": [512, 450],
		"projection": {"scale": [962.0 / 1024.0, 922.0 / 1024.0], "translation": [31, -11], "order": "rotate disc around pivot THEN project; rim projects without rotation"},
		"baseline_scale": 1, "runtime_resolution": "1024 selected candidate: preserves thin mask contours; 512/768/1024 offline comparison at 460px saved. F5-B may revise after real rendering/performance evidence.",
		"emission_encoding": "white RGB / alpha strength from generated grayscale smoothstep(0.88,0.98), multiplied by source alpha; same full source canvas as lotus",
		"compositing": "straight alpha; emission excluded from baseline static composite; source atlas has no gameplay text",
		"reproduction": "Godot 4.7.2 --headless --path . --script res://tools/uix_r7f5a_assets.gd", "assets": entries}
	FileAccess.open(DEST + "manifest.json", FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t") + "\n")
	FileAccess.open(OUT + "qa.json", FileAccess.WRITE).store_string(JSON.stringify({"failures": failures, "layer_count": layers.size(), "angles": [0,90,180,270], "engine": Engine.get_version_info().string, "checks": "PNG save; 24px safety margins; four-angle central aperture coverage"}, "\t") + "\n")
	print("F5-A packaging: ", layers.size(), " layers; failures=", failures)
	quit(0 if failures.is_empty() else 1)
