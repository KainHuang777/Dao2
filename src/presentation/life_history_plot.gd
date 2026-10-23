class_name LifeHistoryPlot
extends Control
## Draw-only overview. Exact amounts and event IDs live in the adjacent table.
var samples: Array = []
var events: Array = []
var resource := ""
var start := 0.0
var finish := 1.0
var maximum := AmountCompat.zero()

func _init() -> void:
	custom_minimum_size = Vector2(0, 144)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func show_interval(data: Dictionary, key: String, first: float, last: float) -> void:
	samples = data.samples
	events = data.events
	resource = key
	start = first
	finish = last
	maximum = AmountCompat.zero()
	for sample in samples:
		for value in sample.rows.get(resource, []):
			if value == null: continue
			var amount := ResourceLedger.amount(value)
			if amount.compare_to(maximum) > 0: maximum = amount
	queue_redraw()

func _x(at: float) -> float:
	return 8 + (size.x - 16) * clampf((at - start) / maxf(1, finish - start), 0, 1)

func _draw() -> void:
	var bottom := size.y - 20
	draw_line(Vector2(8, 8), Vector2(8, bottom), UiMaterial.INK, 1)
	draw_line(Vector2(8, bottom), Vector2(size.x - 8, bottom), UiMaterial.INK, 1)
	for sample in samples:
		var row: Array = sample.rows.get(resource, [])
		for index in row.size():
			if row[index] == null: continue
			var y := bottom - (bottom - 12) * ResourceAccountsView.ratio(ResourceLedger.amount(row[index]), maximum)
			var p := Vector2(_x(float(sample.at)), y)
			if index == 0: draw_circle(p, 4, Color("29604c"))
			else: draw_rect(Rect2(p - Vector2(4,4), Vector2(8,8)), Color("746854"), false, 2)
	for event in events:
		var x := _x(float(event.at))
		draw_line(Vector2(x, bottom + 4), Vector2(x, bottom + 14), Color("9b3e30"), 2)
