extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var unlocks = load("res://src/presentation/feature_unlocks.gd")
	for route in ["skills", "beasts", "realms", "decisions"]:
		print("AUDIT actual route %s at era1: %s" % [route, str(unlocks.check(route, {"era_id": 1}))])
	var dock = load("res://src/presentation/components/dock_button.gd").new()
	root.add_child(dock)
	await process_frame
	var before: Color = dock.get_theme_stylebox("normal").bg_color
	dock.button_pressed = true
	await process_frame
	print("AUDIT DockButton automatic toggle style: before=%s after=%s" % [str(before), str(dock.get_theme_stylebox("normal").bg_color)])
	var tab = load("res://src/presentation/components/game_tab.gd").new()
	root.add_child(tab)
	await process_frame
	var tab_before = tab.get_theme_stylebox("normal")
	tab.button_pressed = true
	await process_frame
	print("AUDIT GameTab automatic toggle changes style: %s" % str(tab_before != tab.get_theme_stylebox("normal")))
	var abode_script = load("res://src/abode/living_abode.gd")
	abode_script.save_dir_override = "user://uix_behavior_audit"
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame
	abode._layout_for_size(Vector2(844, 390))
	await process_frame
	print("AUDIT main_action_box property exists: %s" % str("main_action_box" in abode))
	print("AUDIT action container position=%s header=%s" % [str(abode.level_up_button.get_parent().position), str(abode.header.get_global_rect())])
	print("AUDIT CloseSeal minimum=%s" % str(load("res://src/presentation/components/close_seal.gd").new().custom_minimum_size))
	quit(0)
