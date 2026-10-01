class_name IslandBreakthroughFx
extends Node2D
## Pure presentation in world coordinates. No GameState, commands or RNG access.

const DURATION := 5.6
const GOLD := Color(1.0, 0.79, 0.35)

class FormationLayer extends Node2D:
	var director: IslandBreakthroughFx
	var front: bool = false
	func _draw() -> void:
		director.draw_layer(self, front)

var back_layer: FormationLayer
var front_layer: FormationLayer
var active: bool = false
var attained: bool = false
var reduced_motion: bool = false
var phase_time: float = 0.0
var energy: float = 0.0
var era_id: int = 2

## Bounded presentation tiers; independent of gameplay tribulation rules.
func set_era(value: int) -> void:
	era_id = clampi(value, 1, 12)
	_refresh()

func visual_profile() -> Dictionary:
	var tier := 0 if era_id <= 3 else (1 if era_id <= 6 else (2 if era_id <= 9 else 3))
	return {"tier": tier, "bolts": 3 + tier, "sparks": 48 + tier * 12, "rings": 4 + tier, "glow": 1.0 + tier * 0.18}
var _idle_time: float = 0.0
var _redraw_elapsed: float = 0.0

func _ready() -> void:
	back_layer = FormationLayer.new()
	back_layer.name = "島後法陣"
	back_layer.director = self
	back_layer.z_index = -1
	add_child(back_layer)
	front_layer = FormationLayer.new()
	front_layer.name = "島前法陣與靈光"
	front_layer.director = self
	front_layer.front = true
	front_layer.z_index = 4
	add_child(front_layer)
	_refresh()

func set_attained(value: bool) -> void:
	if attained == value:
		return
	attained = value
	_refresh()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	_refresh()

func sample_sequence(seconds: float, low_motion: bool) -> void:
	active = true
	reduced_motion = low_motion
	phase_time = clampf(seconds, 0.0, DURATION)
	var charge := smoothstep(0.0, 1.6, phase_time)
	var release := 1.0 - smoothstep(3.8, DURATION, phase_time)
	energy = 0.35 if reduced_motion else charge * release
	_refresh()

func stop() -> void:
	active = false
	energy = 0.0
	_refresh()

func _process(delta: float) -> void:
	if active or not attained or reduced_motion:
		return
	_idle_time += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= 0.08:
		_redraw_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	visible = active or attained
	if back_layer != null:
		back_layer.queue_redraw()
		front_layer.queue_redraw()

func draw_layer(canvas: Node2D, front: bool) -> void:
	var strength := energy if active else (0.13 if attained else 0.0)
	if strength <= 0.0:
		return
	var rotation := 0.0 if reduced_motion else (phase_time * 0.18 if active else _idle_time * 0.025)
	var radius := 645.0 + (energy * 36.0 if active else 0.0)
	_draw_formation(canvas, Vector2(0, 115), radius, 0.26, rotation, strength, front)
	if not active or reduced_motion:
		return
	if not front:
		_draw_formation(canvas, Vector2(0, -590), 420.0, 0.25, -rotation, strength, false, true)
		_draw_beam(canvas, strength)
		_draw_cloud_wave(canvas)
	else:
		_draw_lightning(canvas, strength)
		_draw_sparks_and_rocks(canvas, strength)
		var core := Vector2(0, -105)
		for i in range(4, 0, -1):
			canvas.draw_circle(core, float(i) * 17.0, Color(1.0, 0.83, 0.46, strength * 0.05))
		canvas.draw_circle(core, 6.0, Color(1.0, 0.96, 0.76, strength * 0.8))

func _point(center: Vector2, radius: float, flatten: float, angle: float) -> Vector2:
	return center + Vector2(cos(angle) * radius, sin(angle) * radius * flatten)

func _draw_formation(canvas: Node2D, center: Vector2, radius: float, flatten: float, rotation: float, alpha: float, front: bool, whole: bool = false) -> void:
	var first := 0.0 if front else PI
	var span := TAU if whole else PI
	var rings: int = int(visual_profile().rings) if active and not reduced_motion else 3
	var enhanced := active and not reduced_motion
	for ring in range(rings):
		var factor := lerpf(0.72 if enhanced else 0.86, 1.0, float(ring) / float(rings - 1))
		var line := PackedVector2Array()
		for i in range(65):
			line.append(_point(center, radius * factor, flatten, first + span * float(i) / 64.0))
		var glow: float = float(visual_profile().glow) if active and not reduced_motion else 0.6
		if enhanced:
			canvas.draw_polyline(line, Color(GOLD, alpha * 0.08 * glow), 24.0, true)
		canvas.draw_polyline(line, Color(GOLD, alpha * 0.24 * glow), 10.0, true)
		canvas.draw_polyline(line, Color(GOLD, alpha), 3.5 if enhanced else 1.7, true)
		if enhanced:
			canvas.draw_polyline(line, Color(1.0, 0.96, 0.72, alpha * 0.85), 1.4, true)
	for i in range(40):
		var angle := fposmod(float(i) * TAU / 40.0 + rotation, TAU)
		if not whole and ((front and angle > PI) or (not front and angle < PI)):
			continue
		var inner := _point(center, radius * 0.94, flatten, angle)
		var outer := _point(center, radius, flatten, angle)
		canvas.draw_line(inner, outer, Color(GOLD, alpha * 0.9), 2.4, true)
		if i % 5 == 0:
			var pos := _point(center, radius * 0.90, flatten, angle)
			var diamond := PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(12, 0), pos + Vector2(0, 8), pos + Vector2(-12, 0), pos + Vector2(0, -8)])
			canvas.draw_polyline(diamond, Color(GOLD, alpha), 1.5, true)
			canvas.draw_circle(pos, 2.5, Color(GOLD, alpha))
		if active and not reduced_motion and i % 2 == 0:
			# Original radial seal strokes, not borrowed glyph/texture artwork.
			var seal := PackedVector2Array()
			for offset in [-0.018, 0.0, 0.018]:
				seal.append(_point(center, radius * (0.79 if offset == 0.0 else 0.84), flatten, angle + offset))
			canvas.draw_polyline(seal, Color(1.0, 0.90, 0.55, alpha * 0.95), 2.2, true)

func _draw_beam(canvas: Node2D, alpha: float) -> void:
	var beam_alpha := alpha * smoothstep(1.1, 1.9, phase_time)
	var bottom := Vector2(0, -105)
	var top := Vector2(0, -700)
	for i in range(5, 0, -1):
		var width := float(i * i) * 4.5 * float(visual_profile().glow)
		canvas.draw_colored_polygon(PackedVector2Array([bottom + Vector2(-width * 0.65, 0), top + Vector2(-width, 0), top + Vector2(width, 0), bottom + Vector2(width * 0.65, 0)]), Color(GOLD, beam_alpha * 0.065))
	canvas.draw_line(bottom, top, Color(GOLD, beam_alpha * 0.5), 22.0, true)
	canvas.draw_line(bottom, top, Color(1.0, 0.96, 0.75, beam_alpha), 7.0, true)
	# Smooth spiritual arcs, not a gameplay tribulation or rapid strobe.
	for side in [-1.0, 1.0]:
		var arc := PackedVector2Array()
		for i in range(29):
			var t := float(i) / 28.0
			var x: float = side * (sin(t * PI) * 280.0 + sin(t * 18.0 + phase_time) * 20.0)
			arc.append(Vector2(x, lerpf(-640.0, -110.0, t)))
		canvas.draw_polyline(arc, Color(GOLD, beam_alpha * 0.28), 16.0, true)
		canvas.draw_polyline(arc, Color(1.0, 0.9, 0.63, beam_alpha * 0.85), 3.0, true)

func _draw_lightning(canvas: Node2D, alpha: float) -> void:
	var charge := alpha * smoothstep(1.2, 2.0, phase_time)
	if charge <= 0.0:
		return
	var profile := visual_profile()
	# Continuous slowly evolving paths, no frame RNG, abrupt redraw or screen flashes.
	for bolt in range(int(profile.bolts)):
		var lane := float(bolt) - float(int(profile.bolts) - 1) * 0.5
		var path := PackedVector2Array()
		for step in range(23):
			var t := float(step) / 22.0
			if step > 0 and step < 22:
				t += sin(float(step) * 5.1 + float(bolt)) * 0.012
			var envelope := sin(t * PI)
			var zigzag := sin(float(step) * 12.989 + float(bolt) * 78.233) * 45.0 + sin(float(step) * 4.17 + float(bolt)) * 23.0 + sin(phase_time * 0.7 + float(step)) * 12.0
			var x := lane * lerpf(170.0, 105.0, t) + envelope * zigzag
			path.append(Vector2(x, lerpf(-690.0 + absf(lane) * 45.0, 100.0, t)))
		_draw_bolt(canvas, path, charge, float(profile.glow))
		for branch in [7, 13, 17]:
			var origin := path[branch]
			var side := -1.0 if (bolt + branch) % 2 == 0 else 1.0
			var twig := PackedVector2Array([origin, origin + Vector2(side * 42.0, 18), origin + Vector2(side * 23.0, 38), origin + Vector2(side * 83.0, 78)])
			_draw_bolt(canvas, twig, charge * 0.65, 0.55)

func _draw_bolt(canvas: Node2D, path: PackedVector2Array, alpha: float, width: float) -> void:
	canvas.draw_polyline(path, Color(GOLD, alpha * 0.07), 30.0 * width, true)
	canvas.draw_polyline(path, Color(GOLD, alpha * 0.22), 14.0 * width, true)
	canvas.draw_polyline(path, Color(1.0, 0.78, 0.32, alpha * 0.9), 5.0 * width, true)
	canvas.draw_polyline(path, Color(1.0, 0.98, 0.86, alpha), 2.0 * width, true)

func _draw_cloud_wave(canvas: Node2D) -> void:
	var progress := clampf((phase_time - 3.0) / 2.4, 0.0, 1.0)
	if progress <= 0.0:
		return
	var wave := PackedVector2Array()
	for i in range(97):
		wave.append(_point(Vector2(0, 130), lerpf(420.0, 1150.0, progress), 0.35, float(i) * TAU / 96.0))
	canvas.draw_polyline(wave, Color(0.92, 0.95, 1.0, sin(progress * PI) * 0.08), 65.0, true)
	canvas.draw_polyline(wave, Color(1.0, 0.87, 0.59, sin(progress * PI) * 0.25), 3.0, true)

func _draw_sparks_and_rocks(canvas: Node2D, alpha: float) -> void:
	for i in range(int(visual_profile().sparks)):
		var angle := float(i) * 2.39996 + phase_time * 0.08
		var radius := 320.0 + float(i % 7) * 49.0
		var rise := fposmod(float(i) * 19.0 + phase_time * 62.0, 370.0)
		var pos := Vector2(cos(angle) * radius, 160.0 + sin(angle) * radius * 0.25 - rise)
		var fade := alpha * sin(rise / 370.0 * PI)
		canvas.draw_line(pos, pos + Vector2(0, 11), Color(GOLD, fade * 0.4), 1.2, true)
		canvas.draw_circle(pos, 1.5 + float(i % 3), Color(1.0, 0.86, 0.46, fade))
	for i in range(10):
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector2(side * (555.0 + float(i % 3) * 44.0), 145.0 + float(i % 5) * 52.0 - sin(phase_time * 0.8 + float(i)) * 32.0)
		var rock := PackedVector2Array([pos + Vector2(-9, -8), pos + Vector2(6, -12), pos + Vector2(12, 0), pos + Vector2(0, 18), pos + Vector2(-8, 5)])
		canvas.draw_colored_polygon(rock, Color(0.18, 0.25, 0.24, alpha * 0.9))
		canvas.draw_line(rock[0], rock[1], Color(GOLD, alpha * 0.8), 1.5, true)
