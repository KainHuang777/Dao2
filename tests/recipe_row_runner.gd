extends SceneTree
## MFG-2: RecipeRow component structure, state visuals, and responsive layouts.

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _init() -> void:
	var RecipeRowClass = load("res://src/presentation/recipe_row.gd")
	check(RecipeRowClass != null, "RecipeRow class loads")

	var row = RecipeRowClass.new()
	var flags := {"selected": false, "acted": false}
	row.setup("spirit_timber", func(): flags.selected = true, func(): flags.acted = true)
	check(row.recipe_id == "spirit_timber", "setup recipe_id")

	# Test compatibility dictionary
	var card_dict: Dictionary = row.as_card_dict()
	check(card_dict.root == row, "dict root")
	check(card_dict.column == row.column, "dict column")
	check(card_dict.header == row.header, "dict header")
	check(card_dict.title == row.title, "dict title")
	check(card_dict.materials == row.materials, "dict materials")
	check(card_dict.time == row.time, "dict time")
	check(card_dict.progress == row.progress, "dict progress")
	check(card_dict.status == row.status, "dict status")
	check(card_dict.action == row.action, "dict action")
	check(card_dict.recipe_badge == row.recipe_badge, "dict recipe_badge")

	# Test island setting
	row.set_island("wood")
	check(row.badge_island_icon.kind == UiIcon.Kind.WOOD, "island wood icon kind")
	check(row.recipe_badge.tooltip_text.contains("青木島"), "badge tooltip contains island name")

	# Test state visual setting
	row.set_state_visual(RecipeRowClass.COLOR_RUNNING, true)
	check(row._state_border_color == RecipeRowClass.COLOR_RUNNING and row._state_glow, "running state border and glow")

	# Test signals/callbacks
	row.recipe_badge.pressed.emit()
	check(flags.selected, "badge press triggers select callback")
	row.action.pressed.emit()
	check(flags.acted, "action press triggers act callback")

	# Test responsive layout toggle
	# Standard mode
	row.apply_layout(false)
	check(not row.compact_row.visible, "compact row invisible in standard")
	check(row.materials.get_parent() == row.column, "materials in column in standard")
	check(row.recipe_badge.custom_minimum_size == Vector2(56, 56), "badge size in standard")

	# Compact mode
	row.apply_layout(true)
	check(row.compact_row.visible, "compact row visible in compact")
	check(row.materials.get_parent() == row.compact_row, "materials in compact_row in compact")
	check(row.recipe_badge.custom_minimum_size == Vector2(44, 44), "badge size in compact")

	# Restore to standard mode
	row.apply_layout(false)
	check(row.materials.get_parent() == row.column, "materials restored to column")

	# Test inside a mock scene tree at target sizes
	var root_node = Control.new()
	root.add_child(root_node)
	root_node.add_child(row)

	for vp in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(800, 360)]:
		root_node.size = Vector2(vp)
		row.apply_layout(vp.y < 400)
		check(row.action.custom_minimum_size.y >= 44, "action minimum 44px hit size for " + str(vp))

	root_node.queue_free()

	if failures.is_empty():
		print("PASS: MFG-2 RecipeRow component and layout checks.")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)
