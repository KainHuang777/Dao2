extends SceneTree
var failed := false

func _init() -> void:
	_run.call_deferred()

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var catalog = load("res://src/presentation/building_catalog.gd").new()
	catalog.theme = UiTypography.create_theme()
	root.add_child(catalog)
	catalog.configure_resources({"wood": "靈木", "money": "金錢"}, ["wood", "money"])
	catalog.configure([{"id": "production", "title": "生產", "entries": [{"id": "wooden_house", "title": "木屋", "role": "產出金錢"}]}])
	var resources := {"wood": {"value": "25", "visible": true}, "money": {"value": "100", "visible": true}}
	var entry := {"visible": true, "level": 1, "level_cap": 10, "costs": {"wood": "100", "money": "50"}, "affordable": false}
	catalog.refresh({"wooden_house": entry}, resources)
	catalog.set_layout_bounds(Rect2(0, 0, 680, 540))
	await process_frame
	_expect(catalog.rows.wooden_house.icon != null, "Authored production portrait must load")
	_expect(catalog.group_grids.production.columns == 2, "Wide catalog shows two framed building cards per row")
	var wood: Dictionary = catalog.cost_cells.wooden_house.wood
	var money: Dictionary = catalog.cost_cells.wooden_house.money
	_expect(wood.box.get_global_rect().position.x >= catalog.rows.wooden_house.get_global_rect().end.x, "Costs must occupy the information column beside the enlarged portrait")
	_expect(catalog.cards.wooden_house.get_global_rect().encloses(catalog.upgrade_buttons.wooden_house.get_global_rect()), "Compact action stays inside the building frame")
	_expect(wood.label.text == "25/100" and money.label.text == "100/50", "Each material shows owned/required amounts")
	_expect(wood.label.get_theme_color("font_color") != money.label.get_theme_color("font_color"), "Only the deficient material receives warning color")
	var original_cell: Control = wood.box
	resources.wood.value = "22.5860542520968"
	catalog.refresh({"wooden_house": entry}, resources)
	_expect(catalog.cost_cells.wooden_house.wood.box.tooltip_text == "靈木｜庫存 22.59／需求 100", "Cost cell tooltip rounds float amounts to 2 decimal places")
	resources.wood.value = "100"
	catalog.refresh({"wooden_house": entry}, resources)
	_expect(catalog.cost_cells.wooden_house.wood.box == original_cell, "Command refresh reuses material controls")
	_expect(catalog.upgrade_buttons.wooden_house.disabled, "Ready materials never override domain prerequisites")
	catalog.set_layout_bounds(Rect2(0, 0, 352, 260))
	await process_frame
	_expect(catalog.group_grids.production.columns == 1, "Short narrow catalog uses one column")
	_expect(catalog.rows.wooden_house.custom_minimum_size.y >= 44, "Portrait action remains touchable")
	# Exercise the actual deferred container layout across the old wrap threshold.
	# Numeric refreshes must not move another material or resize the card.
	catalog.set_resource_display_mode(0)
	for width in [680, 768, 724, 352]:
		catalog.set_layout_bounds(Rect2(0, 0, width, 540))
		resources.wood.value = "0"
		resources.money.value = "0"
		catalog.refresh({"wooden_house": entry}, resources)
		for frame in 6:
			await process_frame
		var first_position: Vector2 = wood.box.global_position
		var second_position: Vector2 = money.box.global_position
		var card_size: Vector2 = catalog.cards.wooden_house.size
		_expect(second_position.y >= wood.box.get_global_rect().end.y, "Each material always occupies its own row")
		for stock in ["11.96", "999.99", "0", "10000.25", "1"]:
			resources.wood.value = stock
			resources.money.value = stock
			catalog.refresh({"wooden_house": entry}, resources)
			for frame in 6:
				await process_frame
			_expect(wood.box.global_position.is_equal_approx(first_position) and money.box.global_position.is_equal_approx(second_position), "Stock changes preserve material positions at width %d" % width)
			_expect(catalog.cards.wooden_house.size.is_equal_approx(card_size), "Stock changes preserve card dimensions at width %d" % width)
			_expect(catalog.cards.wooden_house.get_global_rect().encloses(money.box.get_global_rect()), "Material row remains inside its card")
	entry.level = 10
	catalog.refresh({"wooden_house": entry}, resources)
	_expect(not catalog.cost_rows.wooden_house.visible and not catalog.rows.wooden_house._meter, "Level cap hides irrelevant requirement indicators")
	entry.visible = false
	catalog.refresh({"wooden_house": entry}, resources)
	_expect(not catalog.group_rows.production.visible, "Hidden buildings do not leave empty graphic groups")
	catalog.queue_free()
	await process_frame
	print("UIX-R4 building cards: PASS" if not failed else "UIX-R4 building cards: FAIL")
	quit(1 if failed else 0)
