extends Control
## Original lightweight corner ornament; the world remains fully interactive.
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var edge := 5.0
	var color := Color("9c865b")
	for point in [Vector2(edge, edge), Vector2(size.x - edge, edge), Vector2(edge, size.y - edge), size - Vector2.ONE * edge]:
		var direction := Vector2(1 if point.x < size.x * 0.5 else -1, 1 if point.y < size.y * 0.5 else -1)
		draw_line(point, point + Vector2(32 * direction.x, 0), color, 2, true)
		draw_line(point, point + Vector2(0, 24 * direction.y), color, 2, true)
		draw_arc(point + direction * 12, 5, 0, TAU * 0.8, 12, Color("756b50"), 1, true)
