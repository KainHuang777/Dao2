extends SceneTree
## Resource import verification only; never creates a game or loads player data.
func _initialize() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/tribulation/trib-a/manifest.json"))
	var failures: Array = []
	for entry in manifest.assets:
		var texture = load("res://assets/tribulation/trib-a/" + entry.file)
		if not texture is Texture2D or texture.get_width() != entry.canvas[0] or texture.get_height() != entry.canvas[1]:
			failures.append(entry.id)
	print("TRIB-A imported textures: ", manifest.assets.size(), "; failures=", failures)
	quit(0 if failures.is_empty() else 1)
