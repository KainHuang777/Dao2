extends SceneTree
func _initialize() -> void:
	for id in ["buddha", "waterfalls", "far_island", "mist_near", "mist_far", "hero_hover", "hero_hit", "hero_unbalanced", "hero_recover", "shield_intact", "shield_cracked", "shield_shattered_v2", "asura"]:
		var im = Image.load_from_file("res://docs/verification/artifacts/trib-a/originals/" + id + ".png")
		print(id, " size=", im.get_size(), " alpha=", im.detect_alpha(), " used=", im.get_used_rect(), " corner=", im.get_pixel(0, 0))
	quit()
