class_name CloakedCultivator
extends Node2D
## Visual-only actor. Spirit motes converge on the chest, never award resources.
const BODY = preload("res://assets/abode/fx3art1/hero/sheet-transparent.png")
const FEET := Vector2(0, -85)
const CORE := Vector2(0, -170)
var body: Sprite2D
var reduced_motion := false
var energy := 0.0
var clock := 0.0
var redraw_elapsed := 0.0
var cultivation_era := 1

func absorption_profile() -> Dictionary:
	# The visual growth caps at 48 motes; no extra nodes or gameplay RNG.
	var step := mini(cultivation_era - 1, 6)
	return {"motes": 24 + step * 4, "radius": 180.0 + step * 9.0,
		"speed": 0.22 + step * 0.015, "size": 2.3 + step * 0.17,
		"tail": 14.0 + step * 2.0}

func _ready() -> void:
	name = "覆頭披風修行者"
	z_index = 2
	body = Sprite2D.new()
	body.texture = BODY
	body.centered = false
	body.scale = Vector2.ONE * 175.0 / BODY.get_height()
	# fit_scale=0.84 puts the processor's feet anchor at 92% of the cell.
	body.position = FEET - Vector2(87.5, 175.0 * 0.92)
	add_child(body)

func present(low_motion: bool, strength: float, current_era: int = -1) -> void:
	var next_era := cultivation_era if current_era < 1 else clampi(current_era, 1, 12)
	if reduced_motion == low_motion and is_equal_approx(energy, strength) and cultivation_era == next_era:
		return
	reduced_motion = low_motion
	energy = strength
	cultivation_era = next_era
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or reduced_motion:
		return
	clock += delta
	redraw_elapsed += delta
	if redraw_elapsed < 0.08:
		return
	redraw_elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	# Soft contact shadow and breathing halo keep the cloaked outline readable.
	draw_set_transform(FEET, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 48.0, Color(0.035, 0.045, 0.05, 0.32))
	draw_arc(Vector2.ZERO, 65.0, 0.0, TAU, 48, Color(0.93, 0.8, 0.49, 0.32), 1.4, true)
	draw_set_transform(Vector2.ZERO)
	if reduced_motion:
		return
	var profile := absorption_profile()
	# Three breathing ribbons make the inward movement readable against textured rock.
	for stream in range(3):
		var path := PackedVector2Array()
		for segment in range(17):
			var progress := float(segment) / 16.0
			var radius := (1.0 - progress) * float(profile.radius)
			var angle := stream * TAU / 3.0 + clock * 0.16 + progress * 1.6
			path.append(CORE + Vector2(cos(angle) * radius, sin(angle) * radius * 0.44 + (1.0 - progress) * 46.0))
		var pulse := 0.48 + 0.12 * sin(clock * 1.2 + stream * 2.1)
		draw_polyline(path, Color(0.22, 0.75, 1.0, pulse * 0.3), 8.0, true)
		draw_polyline(path, Color(0.55, 0.94, 1.0, pulse), 2.2, true)
	var count: int = profile.motes
	for i in range(count):
		var t := fposmod(clock * float(profile.speed) + float(i) / count, 1.0)
		var angle := float(i) * 2.39996 + t * 1.6
		var radius := (1.0 - t) * float(profile.radius)
		var point := CORE + Vector2(cos(angle) * radius, sin(angle) * radius * 0.44 + (1.0 - t) * 46.0)
		var alpha := sin(t * PI) * (0.82 + energy * 0.15)
		var tint := Color(0.54, 0.86, 1.0) if i % 3 != 0 else Color(1.0, 0.86, 0.52)
		var tail := (CORE - point).normalized() * float(profile.tail)
		draw_line(point - tail, point, Color(tint, alpha * 0.16), 5.0, true)
		draw_line(point - tail * 0.72, point, Color(tint, alpha * 0.7), 1.8, true)
		var size := float(profile.size) + energy * 0.7
		draw_circle(point, size * 2.4, Color(tint, alpha * 0.12))
		draw_circle(point, size, Color(0.9, 0.98, 1.0, alpha))
