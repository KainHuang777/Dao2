extends SceneTree
const Numbers = preload("res://src/utils/number_formatter.gd")
const Cell = preload("res://src/presentation/inventory_item_cell.gd")
const Tile = preload("res://src/presentation/recipe_material_tile.gd")
const Shell = preload("res://src/presentation/ui_shell_controller.gd")
var failures: Array[String] = []
var checks := 0
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames() -> void:
	for i in 5: await process_frame
func text_width(label: Label) -> float:
	return label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
func _run() -> void:
	var sizes := ([Vector2i(1280,720), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)])
	var values: Array = [0, 9.99999999, 9999.999, 10000, 99999999.999, 100000000, 999999999999.9, 1e12, 9.9999e15, 1e100, 1e-8, -0.000001, -9999, -1e100, null, "未知資料不可當零", NAN, INF, AmountCompat.from_components(1, 2, 99.123456)]
	check(Numbers.format_amount(1e-8) == "<0.001", "nonzero tiny amount never becomes zero")
	check(Numbers.exact_amount(1e-8).to_float() == 1e-8, "exact tiny TIP retains nonzero value")
	check(Numbers.format_amount(9.9999e15) == "9.99e15", "scientific mantissa truncates without false carry")
	check(Numbers.format_amount(99999999.999) == "9999.9萬", "unit boundary never rounds to one 億")
	check(Numbers.format_amount(9.99999999) == "9.9", "fraction boundary never rounds to ten")
	var host := Control.new()
	root.add_child(host)
	for vp in sizes:
		root.size = vp
		for small in [false, true]:
			var tile = Tile.new()
			host.add_child(tile)
			tile.set_compact(small)
			for raw in values:
				var cell = Cell.new()
				host.add_child(cell)
				var data := {"key":"test", "id":"wood", "name":"完整物品名稱", "source":"測試島・當地", "available":raw, "capacity":1e100, "demand":10000, "provided":{"available":true,"capacity":true,"demand":true}}
				cell.apply(data)
				await frames()
				check(text_width(cell._amount) + 10 <= cell.size.x - 10 + 0.1, "inventory glyph + outline inside square " + str(raw))
				check(is_equal_approx(cell.size.x, cell.size.y) and cell._amount.visible, "inventory stays square with explicit unknown")
				check(cell.tooltip_text.contains(Numbers.exact_amount(raw)) and cell.tooltip_text.contains("需求：10000") and cell.tooltip_text.contains("測試島・當地"), "exact value/capacity/demand/source survive short label")
				if raw == null or raw is String or (raw is float and not is_finite(raw)):
					check(cell._amount.text == "？", "unknown is not zero")
				cell.free()
			for value in [9999.99, 10000.0, 99999999.9, 1e12, 9.9999e15, -1e100, 0.0000001, -0.0000001]:
				tile.refresh("wood", "完整木材名稱", value, value - 0.000001, "測試島")
				await frames()
				check(is_equal_approx(tile.size.x, tile.size.y), "material square unchanged")
				check(tile.quantity.get_theme_font_size("font_size") >= 16, "compact quantity at least 16px")
				check(text_width(tile.quantity) + 2 * tile.quantity.get_theme_constant("outline_size") <= tile.cell.size.x - 4 + 0.1, "material glyph + outline fits " + str(value))
				check(tile.tooltip_text.contains(Numbers.exact_amount(value)), "material exact TIP")
			tile.refresh("wood", "木材", 10000, 9999.9999, "當地")
			check(tile.shortage and tile.tooltip_text.contains("缺料"), "abbreviation never hides real shortfall")
			tile.refresh("wood", "木材", 10000, 10000, "當地")
			check(not tile.shortage, "exact sufficiency still uses raw quantity")
			tile.free()
	for route in ["skills", "sect", "beasts", "reincarnation", "alchemy", "transport", "manufacturing", "fortune", "decisions"]:
		check(Shell.resource_entry_title(route).length() <= 4, "bounded resource entry title " + route)
	host.free()
	for failure in failures: push_error(failure)
	print("EARLY16_UI_C: %d checks, %d failures" % [checks, failures.size()])
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
