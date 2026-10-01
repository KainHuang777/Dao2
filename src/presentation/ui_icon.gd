class_name UiIcon
extends Control
## Small scalable UI illustrations drawn by Godot instead of font glyphs.

enum Kind { HOURGLASS, SCROLL, TEMPLE, GIFT, REFRESH, LOTUS, SPARKLE, ARROW, GEAR }

@export var kind: Kind = Kind.SPARKLE:
	set(value):
		kind = value
		queue_redraw()
@export var tint := Color("e8cf83"):
	set(value):
		tint = value
		queue_redraw()
@export var icon_size := 20.0:
	set(value):
		icon_size = value
		custom_minimum_size = Vector2(value, value)
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)

func _draw() -> void:
	var center := size * 0.5
	var scale_factor := minf(size.x, size.y) / 24.0
	var stroke := maxf(1.5, 1.8 * scale_factor)
	var c := tint
	match kind:
		Kind.HOURGLASS:
			_draw_line(Vector2(7, 3), Vector2(17, 3), c, stroke, scale_factor)
			_draw_line(Vector2(7, 21), Vector2(17, 21), c, stroke, scale_factor)
			_draw_line(Vector2(8, 4), Vector2(16, 10), c, stroke, scale_factor)
			_draw_line(Vector2(16, 10), Vector2(8, 18), c, stroke, scale_factor)
			_draw_line(Vector2(8, 18), Vector2(16, 21), c, stroke, scale_factor)
			_draw_line(Vector2(16, 4), Vector2(8, 10), c, stroke, scale_factor)
			_draw_line(Vector2(8, 10), Vector2(16, 18), c, stroke, scale_factor)
		Kind.SCROLL:
			draw_rect(Rect2(center.x - 7 * scale_factor, center.y - 9 * scale_factor, 14 * scale_factor, 18 * scale_factor), c, false, stroke)
			for y in [-4.0, 0.0, 4.0]:
				_draw_line(Vector2(7, 12 + y), Vector2(17, 12 + y), c, stroke, scale_factor)
		Kind.TEMPLE:
			draw_colored_polygon(_points([[3, 9], [12, 3], [21, 9]], scale_factor), c)
			_draw_line(Vector2(4, 10), Vector2(20, 10), c, stroke, scale_factor)
			_draw_line(Vector2(5, 20), Vector2(19, 20), c, stroke, scale_factor)
			for x in [7.0, 12.0, 17.0]:
				_draw_line(Vector2(x, 11), Vector2(x, 19), c, stroke, scale_factor)
		Kind.GIFT:
			draw_rect(Rect2(center.x - 8 * scale_factor, center.y - 3 * scale_factor, 16 * scale_factor, 11 * scale_factor), c, false, stroke)
			_draw_line(Vector2(4, 9), Vector2(20, 9), c, stroke, scale_factor)
			_draw_line(Vector2(12, 6), Vector2(12, 20), c, stroke, scale_factor)
			_draw_line(Vector2(12, 6), Vector2(8, 3), c, stroke, scale_factor)
			_draw_line(Vector2(12, 6), Vector2(16, 3), c, stroke, scale_factor)
		Kind.REFRESH:
			draw_arc(center, 8 * scale_factor, -2.5, 1.2, 20, c, stroke, true)
			draw_colored_polygon(_points([[17, 3], [22, 5], [18, 9]], scale_factor), c)
			draw_arc(center, 8 * scale_factor, 0.6, 4.3, 20, c, stroke, true)
			draw_colored_polygon(_points([[7, 21], [2, 19], [6, 15]], scale_factor), c)
		Kind.LOTUS:
			_draw_line(Vector2(12, 19), Vector2(12, 8), c, stroke, scale_factor)
			_draw_line(Vector2(12, 18), Vector2(5, 12), c, stroke, scale_factor)
			_draw_line(Vector2(12, 18), Vector2(19, 12), c, stroke, scale_factor)
			_draw_line(Vector2(12, 8), Vector2(8, 4), c, stroke, scale_factor)
			_draw_line(Vector2(12, 8), Vector2(16, 4), c, stroke, scale_factor)
			_draw_line(Vector2(4, 20), Vector2(20, 20), c, stroke, scale_factor)
		Kind.SPARKLE:
			_draw_line(Vector2(12, 2), Vector2(12, 22), c, stroke, scale_factor)
			_draw_line(Vector2(2, 12), Vector2(22, 12), c, stroke, scale_factor)
			_draw_line(Vector2(5, 5), Vector2(19, 19), c, stroke, scale_factor)
			_draw_line(Vector2(19, 5), Vector2(5, 19), c, stroke, scale_factor)
		Kind.ARROW:
			_draw_line(Vector2(3, 12), Vector2(20, 12), c, stroke, scale_factor)
			_draw_line(Vector2(14, 6), Vector2(20, 12), c, stroke, scale_factor)
			_draw_line(Vector2(20, 12), Vector2(14, 18), c, stroke, scale_factor)
		Kind.GEAR:
			draw_arc(center, 5.5 * scale_factor, 0.0, TAU, 24, c, stroke, true)
			draw_arc(center, 2.5 * scale_factor, 0.0, TAU, 16, c, stroke, true)
			for i in range(8):
				var angle: float = float(i) * TAU / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				var p1 := center + dir * (5.5 * scale_factor)
				var p2 := center + dir * (8.5 * scale_factor)
				draw_line(p1, p2, c, stroke * 1.6, true)

func _draw_line(a: Vector2, b: Vector2, color: Color, width: float, scale_factor: float) -> void:
	draw_line((a - Vector2(12, 12)) * scale_factor + size * 0.5, (b - Vector2(12, 12)) * scale_factor + size * 0.5, color, width, true)

func _points(coords: Array, scale_factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in coords:
		result.append((Vector2(point[0], point[1]) - Vector2(12, 12)) * scale_factor + size * 0.5)
	return result
