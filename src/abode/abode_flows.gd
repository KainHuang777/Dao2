extends Node2D
## Pure presentation: flight completion never awards resources.
const SWORD: Texture2D = preload("res://assets/abode/sword.png")
var elapsed: float = 0.0
var garden_running: bool = true
var reduced_motion: bool = false
var intensity: float = 1.0
var paths: Array[Curve2D] = []
var sword_positions: Array[Vector2] = []
var altar: Vector2 = Vector2(-8, -145)

func _ready() -> void:
	var coords: Array = [
		[Vector2(-245, -255), Vector2(-115, -300), altar],
		[Vector2(300, -145), Vector2(180, -260), altar],
		[altar, Vector2(-110, -60), Vector2(-245, -255)]
	]
	for points in coords:
		var curve := Curve2D.new()
		curve.bake_interval = 8.0
		curve.add_point(points[0], Vector2.ZERO, (points[1] - points[0]) * 0.65)
		curve.add_point(points[2], (points[1] - points[2]) * 0.65)
		paths.append(curve)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	sword_positions.clear()
	for route in paths.size():
		var curve: Curve2D = paths[route]
		var length: float = curve.get_baked_length()
		var active: bool = route != 1 or garden_running
		var color: Color = Color("a2fce0") if route == 1 else Color("ffe3a1")
		var baked: PackedVector2Array = curve.get_baked_points()
		draw_polyline(baked, Color(color, 0.15 if active else 0.05), 6.0, true)
		draw_polyline(baked, Color(color, 0.6 if active else 0.16), 1.2, true)
		var count: int = 2 if reduced_motion else 3
		for i in count:
			var phase: float = fposmod(float(i) / count + (elapsed * (0.105 + intensity * 0.013) if active else 0.1), 1.0)
			var distance: float = phase * length
			var point: Vector2 = curve.sample_baked(distance)
			sword_positions.append(point)
			var tangent: Vector2 = curve.sample_baked(minf(distance + 4, length)) - curve.sample_baked(maxf(0, distance - 4))
			if not reduced_motion and active:
				for segment in 9:
					var a: float = maxf(0, distance - segment * 6)
					var b: float = maxf(0, distance - (segment + 1) * 6)
					draw_line(curve.sample_baked(a), curve.sample_baked(b), Color(color, 0.7 * (1.0 - float(segment) / 9)), 3.5, true)
			draw_set_transform(point, tangent.angle())
			draw_texture_rect(SWORD, Rect2(-38, -38, 76, 76), false, Color.WHITE if active else Color(0.5, 0.65, 0.68))
			draw_set_transform(Vector2.ZERO)
	var particles: int = 8 if reduced_motion else 24
	for i in particles:
		var phase: float = fposmod(float(i) * 0.618 + elapsed * 0.16, 1.0)
		var radius: float = (1.0 - phase) * 175.0
		var angle: float = i * 2.4 + phase * 3.5
		var point: Vector2 = altar + Vector2(cos(angle) * radius, sin(angle) * radius * 0.45 - phase * 35)
		var alpha: float = sin(phase * PI) * 0.8
		draw_circle(point, 1.8 + (i % 3) * 0.5, Color(0.77, 1.0, 0.84, alpha))
