extends SceneTree
## Offline packing and static composition only. No GameSession, save or runtime stage.
const ROOT = "res://assets/tribulation/trib-a/"
const OUT = "res://docs/verification/artifacts/trib-a/"
const IDS = ["clean", "buddha", "waterfalls", "far_island", "mist_near", "mist_far", "star_arc", "hero_hover", "hero_hit", "hero_unbalanced", "hero_recover", "shield_intact", "shield_cracked", "shield_shattered_v2", "asura"]
const CORES = {"hero_hover": Vector2(.57, .39), "hero_hit": Vector2(.58, .40), "hero_unbalanced": Vector2(.70, .42), "hero_recover": Vector2(.53, .39)}
var layers: Dictionary = {}
var entries: Array = []
var failures: Array = []
var checks := 0
var samples: Array = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func save(im: Image, path: String) -> void:
	check(im.save_png(path) == OK, "save " + path)

func write_json(path: String, data: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "open " + path)
	if file: file.store_string(JSON.stringify(data, "\t") + "\n")

func image(size: Vector2i, color: Color = Color.TRANSPARENT) -> Image:
	var im = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	im.fill(color)
	return im

func stamp(base: Image, id: String, at: Vector2, height: float, alpha: float = 1.0, anchor: Vector2 = Vector2(.5, .5)) -> Rect2i:
	var im: Image = layers[id].duplicate()
	var scale_factor = height * base.get_height() / im.get_height()
	var size = Vector2i(Vector2(im.get_size()) * scale_factor)
	im.resize(maxi(1, size.x), maxi(1, size.y), Image.INTERPOLATE_LANCZOS)
	if alpha < 1.0:
		for y in im.get_height():
			for x in im.get_width():
				var c = im.get_pixel(x, y)
				c.a *= alpha
				im.set_pixel(x, y, c)
	var p = Vector2i(at * Vector2(base.get_size()) - anchor * Vector2(im.get_size()))
	base.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), p)
	return Rect2i(p, im.get_size())

func sky(size: Vector2i, id: String = "clean", offset: Vector2 = Vector2.ZERO, zoom: float = 1.16) -> Image:
	var source: Image = layers[id].duplicate()
	var scale_factor = maxf(float(size.x) / source.get_width(), float(size.y) / source.get_height()) * zoom
	source.resize(ceili(source.get_width() * scale_factor), ceili(source.get_height() * scale_factor), Image.INTERPOLATE_LANCZOS)
	var result = image(size, Color.MAGENTA)
	var p = (size - source.get_size()) / 2 + Vector2i(offset * Vector2(size))
	check(p.x <= 0 and p.y <= 0 and p.x + source.get_width() >= size.x and p.y + source.get_height() >= size.y, "overscan coverage")
	result.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), p)
	return result

func line(im: Image, a: Vector2, b: Vector2, color: Color, width: int) -> void:
	var start = a * Vector2(im.get_size())
	var finish = b * Vector2(im.get_size())
	var steps = ceili(start.distance_to(finish))
	for n in range(steps + 1):
		var p = Vector2i(start.lerp(finish, float(n) / maxi(1, steps)))
		im.fill_rect(Rect2i(p - Vector2i(width, width) / 2, Vector2i(width, width)), color)

func hero(im: Image, id: String, core: Vector2, height: float) -> Rect2i:
	var uv: Vector2 = CORES[id]
	var anchor = (Vector2(64, 64) + uv * 896.0) / 1024.0
	var rect = stamp(im, id, core, height, 1.0, anchor)
	check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= im.get_width() and rect.end.y <= im.get_height(), "full hero canvas within " + id)
	return rect

func home(im: Image, phase: int) -> void:
	stamp(im, "far_island", Vector2(.18, .29 + phase * .10), .30, .75)
	stamp(im, "far_island", Vector2(.90, .59 + phase * .10), .20, .55)
	var buddha_pos = Vector2(.80, .33 + phase * .22)
	stamp(im, "buddha", buddha_pos, .63, .70)
	# Two independent regions are aligned to measured Buddha eye outlets.
	var buddha_top = buddha_pos - Vector2(.315 * im.get_height() / im.get_width(), .315)
	for eye in [{"id": "waterfall_left", "uv": Vector2(.365, .45)}, {"id": "waterfall_right", "uv": Vector2(.61, .41)}]:
		var eye_uv: Vector2 = (Vector2(64, 64) + eye.uv * 896.0) / 1024.0
		var target = buddha_top + Vector2(eye_uv.x * .63 * im.get_height() / im.get_width(), eye_uv.y * .63)
		stamp(im, eye.id, target, .32, .70, Vector2(.51, .103) if eye.id == "waterfall_left" else Vector2(.363, .10))
	stamp(im, "mist_far", Vector2(.50, .67 + phase * .16), .40, .40)
	stamp(im, "terrain", Vector2(.49, .95 + phase * .32), .59)
	stamp(im, "ground_shadow", Vector2(.50, .83 + phase * .32), .08, .70)

func composition(index: int, size: Vector2i) -> Image:
	var result = sky(size, "star_arc" if index in [2, 3] else "clean")
	if index in [0, 1, 4, 5]: home(result, 1 if index == 1 else 0)
	if index == 5:
		stamp(result, "asura", Vector2(.50, .41), .90, .55)
	var core = Vector2(.50, .61 if index in [0, 4, 5] else (.46 if index == 1 else .49))
	var pose = ["hero_recover", "hero_hover", "hero_hover", "hero_hit", "hero_recover", "hero_unbalanced"][index]
	var hero_height = .49 if index == 3 else .44
	if index in [2, 3, 4]:
		stamp(result, "shield_cracked" if index == 3 else "shield_intact", core + Vector2(0, .075), .59, .50 if index == 3 else .35)
	var hero_rect = hero(result, pose, core, hero_height)
	if index == 3:
		var points: Array[Vector2] = []
		for step in 16:
			points.append(Vector2(.49 + sin(step * 2.7) * .014, lerpf(.03, core.y, step / 15.0)))
		points[-1] = core
		for i in range(points.size() - 1):
			line(result, points[i], points[i + 1], Color(.15, .55, 1, 1), 5)
			line(result, points[i], points[i + 1], Color(.88, .97, 1, 1), 2)
		check(points[-1] == core, "main bolt terminates at pose core")
		line(result, points[5], Vector2(.57, .27), Color(.55, .80, 1, 1), 1)
		line(result, points[9], Vector2(.43, .37), Color(.55, .80, 1, 1), 1)
	if index == 5: stamp(result, "shield_shattered_v2", core + Vector2(0, .09), .55, .65)
	if index in [0, 1, 4, 5]: stamp(result, "mist_near", Vector2(.50, .97), .37, .45)
	samples.append({"index": index, "size": [size.x, size.y], "hero_canvas": [hero_rect.position.x, hero_rect.position.y, hero_rect.size.x, hero_rect.size.y], "core": [core.x, core.y], "pose": pose})
	return result

func add_asset(id: String, im: Image, source: String, kind: String, z: int, processing: String) -> void:
	layers[id] = im
	save(im, ROOT + id + ".png")
	var bounds = im.get_used_rect()
	if kind != "opaque_plate":
		check(bounds.position.x >= 32 and bounds.position.y >= 32 and bounds.end.x <= im.get_width() - 32 and bounds.end.y <= im.get_height() - 32, "32px source safe border " + id)
		check(im.detect_alpha() == Image.ALPHA_BLEND, "real alpha " + id)
	var pose_id = id.trim_suffix("_emission")
	var packed_core = (Vector2(64, 64) + CORES[pose_id] * 896.0) / 1024.0 if CORES.has(pose_id) else Vector2.ZERO
	var attachment = Vector2(.51, .103) if id == "waterfall_left" else Vector2(.363, .10)
	entries.append({"id": id, "file": id + ".png", "canvas": [im.get_width(), im.get_height()], "pivot_uv": [.5, .5], "core_source_uv": [CORES[pose_id].x, CORES[pose_id].y] if CORES.has(pose_id) else [], "core_packed_uv": [packed_core.x, packed_core.y] if CORES.has(pose_id) else [], "water_attachment_uv": [attachment.x, attachment.y] if kind == "water_region" else [], "padding": 64 if kind != "opaque_plate" else 0, "z_index": z, "kind": kind, "source": source.trim_prefix("res://"), "source_sha256": FileAccess.get_sha256(source), "sha256": FileAccess.get_sha256(ROOT + id + ".png"), "processing": processing, "prompt_id": "waterfalls" if kind == "water_region" else ("" if kind == "original_mask" else pose_id)})

func _initialize() -> void:
	for folder in [ROOT, OUT + "black", OUT + "gray", OUT + "white", OUT + "compositions", OUT + "extremes"]:
		DirAccess.make_dir_recursive_absolute(folder)
	for id in IDS:
		var path = OUT + "originals/" + id + ".png"
		var raw = Image.load_from_file(path)
		check(raw != null and not raw.is_empty(), "source " + id)
		raw.convert(Image.FORMAT_RGBA8)
		var plate = id in ["clean", "star_arc"]
		if plate: check(raw.detect_alpha() == Image.ALPHA_NONE, "opaque full plate " + id)
		var packed = raw.duplicate()
		if not plate:
			packed = image(Vector2i(1024, 1024))
			var fit = 896.0 / maxf(raw.get_width(), raw.get_height())
			raw.resize(roundi(raw.get_width() * fit), roundi(raw.get_height() * fit), Image.INTERPOLATE_LANCZOS)
			packed.blit_rect(raw, Rect2i(Vector2i.ZERO, raw.get_size()), (Vector2i(1024, 1024) - raw.get_size()) / 2)
		var z = {"clean": 0, "star_arc": 10, "far_island": 20, "buddha": 30, "waterfalls": 35, "mist_far": 40, "asura": 58, "shield_intact": 60, "shield_cracked": 60, "shield_shattered_v2": 90, "mist_near": 110}.get(id, 80)
		add_asset(id, packed, path, "opaque_plate" if plate else "transparent_sprite", z, "Unmodified generated RGBA; aspect-preserving fit into 896px box on 1024 transparent canvas. No chroma key, painted correction or alpha threshold.")
	# Reuse accepted terrain. No new landmarks or layout modifications.
	layers.terrain = Image.load_from_file("res://assets/abode/fx3art1/terrain.png")
	layers.terrain.convert(Image.FORMAT_RGBA8)
	# Water split into independent source rectangles; top anchor measured from visible stream.
	var water = Image.load_from_file(OUT + "originals/waterfalls.png")
	for i in 2:
		var region = Rect2i(280 if i == 0 else 690, 365 if i == 0 else 300, 330, 880 if i == 0 else 945)
		var piece = water.get_region(region)
		var packed = image(Vector2i(512, 1024))
		piece.resize(330, 896, Image.INTERPOLATE_LANCZOS)
		packed.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(91, 64))
		add_asset("waterfall_left" if i == 0 else "waterfall_right", packed, OUT + "originals/waterfalls.png", "water_region", 35, "Source region " + str(region) + "; water-only rectangular extraction; eye attachment " + ("(0.51,0.103)" if i == 0 else "(0.363,0.10)") + "; independent y length fitted to 896.")
	# Mask data derived from each pose; preserve full packed canvas and local core mapping.
	for id in CORES:
		var mask: Image = layers[id].duplicate()
		var core = Vector2(64, 64) + CORES[id] * 896.0
		for y in mask.get_height():
			for x in mask.get_width():
				var c = mask.get_pixel(x, y)
				var local = Vector2(x, y).distance_to(core) / 180.0
				var strength = c.a * (1.0 - smoothstep(.15, 1.0, local))
				mask.set_pixel(x, y, Color(1, 1, 1, strength))
		add_asset(id + "_emission", mask, ROOT + id + ".png", "emission_mask", 95, "White RGB, alpha=pose alpha * radial smoothstep falloff around measured core; same canvas/padding/anchor as pose. Data mask only, no baked glow.")
		check(mask.get_size() == layers[id].get_size(), "mask canvas matches " + id)
	# Ground shadow stays on island, independent from actor.
	var shadow = image(Vector2i(512, 256))
	for y in 256:
		for x in 512:
			var r = Vector2((x - 256.0) / 200.0, (y - 128.0) / 65.0).length()
			shadow.set_pixel(x, y, Color(.025, .035, .05, (1 - smoothstep(.3, 1, r)) * .42))
	add_asset("ground_shadow", shadow, "res://tools/trib_a_assets.gd", "original_mask", 55, "Original analytic soft ellipse, independent island-plane layer; no image reference.")
	var transparent_ids: Array = []
	for item in entries:
		if item.kind != "opaque_plate": transparent_ids.append(item.id)
	for bg in {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}:
		var contact = image(Vector2i(1600, ceili(transparent_ids.size() / 4.0) * 320), {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}[bg])
		for i in transparent_ids.size():
			var id: String = transparent_ids[i]
			var single = image(layers[id].get_size(), {"black": Color.BLACK, "gray": Color("777777"), "white": Color.WHITE}[bg])
			single.blend_rect(layers[id], Rect2i(Vector2i.ZERO, single.get_size()), Vector2i.ZERO)
			save(single, OUT + bg + "/" + id + ".png")
			single.resize(300, 300, Image.INTERPOLATE_LANCZOS)
			contact.blit_rect(single, Rect2i(0, 0, 300, 300), Vector2i((i % 4) * 400 + 50, (i / 4) * 320 + 10))
			single = null
		save(contact, OUT + "layers-" + bg + ".png")
	var sheet = image(Vector2i(1920, 1620))
	for size in [Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)]:
		for index in 6:
			var comp = composition(index, size)
			save(comp, OUT + "compositions/%02d-%dx%d.png" % [index + 1, size.x, size.y])
			if size.x == 1280:
				comp.resize(960, 540, Image.INTERPOLATE_LANCZOS)
				sheet.blit_rect(comp, Rect2i(0, 0, 960, 540), Vector2i((index % 2) * 960, (index / 2) * 540))
	save(sheet, OUT + "six-keyframes.png")
	# All four signed overscan extremes, no Buddha/terrain/person: prove absence of baked remnants.
	for i in 4:
		var offset = Vector2(-.07 if i % 2 == 0 else .07, -.07 if i < 2 else .07)
		var im = sky(Vector2i(1280, 720), "clean", offset)
		save(im, OUT + "extremes/clean-no-buddha-%d.png" % i)
		im = sky(Vector2i(1280, 720), "star_arc", offset, 1.32)
		save(im, OUT + "extremes/star-max-zoom-%d.png" % i)
	# Maximum independent layer displacement and scale; full clean plate stays behind.
	for i in 2:
		var im = sky(Vector2i(1280,720))
		stamp(im, "buddha", Vector2(.85, 1.20 if i == 1 else .40), .85 if i == 1 else .35)
		stamp(im, "terrain", Vector2(.5, 1.32 if i == 1 else .90), .70 if i == 1 else .35)
		hero(im, "hero_hover", Vector2(.5, .46), .62 if i == 1 else .32)
		save(im, OUT + "extremes/layers-%d.png" % i)
	write_json(ROOT + "manifest.json", {"task": "TRIB-A", "date": "2026-10-18", "status": "candidate_pending_visual_acceptance", "generator": "built-in image_gen; 16 originals, first shattered shield rejected", "engine": Engine.get_version_info().string, "assets": entries, "references": ["assets/abode/fx3art1/sky.png", "assets/abode/fx3art1/hero/sheet-transparent.png"], "rights": "Project AI-generated derivations; original user concept third-party commercial rights not independently established. No additional third-party library used; generation is not legal clearance.", "compositing": "Straight-alpha RGBA. Per-pose core anchors differ: align stage actor to core_source_uv transformed by 64px padding + 896px fit, not texture center. Shadow stays on terrain. Waterfall independent eye anchors. Shield behind actor; cracks/contact may be foreground. UI separate.", "z_order": ["clean", "star_arc", "far_island", "buddha", "waterfalls", "mist_far", "terrain", "ground_shadow", "asura_behind_actor", "shield_rear", "actor", "emission", "shield_front_cracks", "lightning_contact", "mist_near", "UI"], "limits": {"background_zoom": [1.16, 1.32], "background_offset_uv": [-.07,.07], "buddha_height_h": [.35,.85], "buddha_y": [.40,1.20], "terrain_y": [.90,1.32], "actor_canvas_height_h": [.32,.62]}, "reused_terrain": {"path": "assets/abode/fx3art1/terrain.png", "sha256": FileAccess.get_sha256("res://assets/abode/fx3art1/terrain.png")}, "prompts": "generation-prompts.json", "reproduce": "Godot 4.7.2 --headless --path . --script res://tools/trib_a_assets.gd", "scope": "Offline packing/static storyboard only, no dynamic staging, SFX, Web, FPS or final art acceptance."})
	write_json(OUT + "qa.json", {"task": "TRIB-A", "checks": checks, "failures": failures, "asset_count": entries.size(), "original_count": 16, "samples": samples, "transparent_order": transparent_ids, "evidence": "Godot Image CPU packing and static composition, not GPU frame capture or browser interaction. Visual QA recorded separately."})
	print("TRIB-A: ", entries.size(), " assets, ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
