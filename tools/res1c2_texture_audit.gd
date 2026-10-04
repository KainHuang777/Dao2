extends SceneTree
## Import-only encoding QA: source PNGs are immutable; alpha/dimensions retained.
func _init() -> void:
	var files := ["res://assets/abode/terrain.png", "res://assets/abode/sky_tearfall_island_v6.png"]
	for id in ["wood", "ore"]:
		for layer in ["body", "landmark"]:
			files.append("res://assets/abode/res1c3/%s_%s.png" % [id, layer])
	var report: Array = []
	var ok := true
	for path in files:
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		var original_size := source.get_size()
		var texture: Texture2D = load(path)
		var image := texture.get_image()
		# Match Godot's declared import resize, then measure only encoding loss.
		var remote: bool = String(path).contains("res1c3/")
		if remote:
			source.resize(1024, 682, Image.INTERPOLATE_CUBIC)
		# Importer fixes translucent edge RGB before WebP encoding; compare that baseline.
		source.fix_alpha_edges()
		var dimensions_ok := image.get_size() == source.get_size()
		var alpha_differences := 0
		var error_sum := 0.0
		var samples := 0
		for y in source.get_height():
			for x in source.get_width():
				var before := source.get_pixel(x, y)
				var after := image.get_pixel(x, y)
				if before.a != after.a:
					alpha_differences += 1
				# Border fix changes invisible RGB; audit opaque painted surfaces.
				if before.a >= 0.98:
					error_sum += pow(before.r-after.r, 2) + pow(before.g-after.g, 2) + pow(before.b-after.b, 2)
					samples += 3
		var psnr_db := -10.0 * log(maxf(1e-12, error_sum / maxi(1, samples))) / log(10.0)
		ok = ok and dimensions_ok and alpha_differences == 0 and psnr_db >= 35
		report.append({"path": path, "source_dimensions": [original_size.x, original_size.y], "dimensions": [image.get_width(), image.get_height()], "dimensions_ok": dimensions_ok, "alpha_differences_vs_declared_resize": alpha_differences, "opaque_encoding_psnr_db": psnr_db, "quality": (null if String(path).ends_with("wood_landmark.png") else (0.98 if String(path).contains("landmark") else 0.92)) if remote else 0.85})
	var output := FileAccess.open("res://docs/verification/artifacts/res1-c2-perf-textures.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"ok": ok, "files": report}, "\t"))
	output.close()
	print(JSON.stringify({"ok": ok, "files": report}))
	quit(0 if ok else 1)
