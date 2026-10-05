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
var sword_sprites: Array[Sprite2D] = []
var sword_trails: Array[CPUParticles2D] = []
var aura: Sprite2D
var spirit_particles: CPUParticles2D

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
	for route in range(3):
		for index in range(3):
			var sprite := Sprite2D.new()
			sprite.texture = SWORD
			sprite.scale = Vector2.ONE * 76.0 / SWORD.get_width()
			var material := ShaderMaterial.new()
			material.shader = NativeVfx.SWORD
			material.set_shader_parameter("emission", Color("a2fce0") if route == 1 else Color("ffe3a1"))
			sprite.material = material
			add_child(sprite)
			sword_sprites.append(sprite)
			var trail := NativeVfx.particles(16, Color("a2fce0") if route == 1 else Color("ffe3a1"), 0.65)
			trail.local_coords = false
			trail.z_index = -1
			add_child(trail)
			sword_trails.append(trail)
	aura = NativeVfx.ring(self, altar + Vector2(0, 10), Vector2(420, 180), Color("78efc9"))
	aura.z_index = -2
	spirit_particles = NativeVfx.particles(64, Color("8affd6"), 1.8)
	spirit_particles.position = altar
	spirit_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spirit_particles.emission_rect_extents = Vector2(150, 48)
	spirit_particles.gravity = Vector2(0, -12)
	add_child(spirit_particles)
	_update_native_fx()

func _process(delta: float) -> void:
	elapsed += delta
	_update_native_fx()
	queue_redraw()

func _update_native_fx() -> void:
	if aura == null:
		return
	var visual_time := 0.0 if reduced_motion else elapsed
	aura.material.set_shader_parameter("clock", visual_time)
	aura.material.set_shader_parameter("strength", 0.22 if reduced_motion else 0.52)
	spirit_particles.emitting = not reduced_motion and intensity > 0.0
	spirit_particles.visible = not reduced_motion
	for route in range(paths.size()):
		var curve: Curve2D = paths[route]
		var length := curve.get_baked_length()
		var active := route != 1 or garden_running
		var count := 2 if reduced_motion else 3
		for index in range(3):
			var slot := route * 3 + index
			var phase := fposmod(float(index) / count + (visual_time * (0.105 + intensity * 0.013) if active else 0.1), 1.0)
			var distance := phase * length
			var point := curve.sample_baked(distance)
			var tangent := curve.sample_baked(minf(distance + 4, length)) - curve.sample_baked(maxf(0, distance - 4))
			var sprite := sword_sprites[slot]
			sprite.visible = index < count
			sprite.position = point
			sprite.rotation = tangent.angle()
			sprite.modulate = Color.WHITE if active else Color(0.5, 0.65, 0.68)
			sprite.material.set_shader_parameter("clock", visual_time)
			sprite.material.set_shader_parameter("strength", 0.2 if reduced_motion or not active else 1.0)
			var trail := sword_trails[slot]
			trail.position = point
			trail.emitting = active and not reduced_motion
			trail.visible = active and not reduced_motion

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
			var phase: float = fposmod(float(i) / count + ((0.0 if reduced_motion else elapsed) * (0.105 + intensity * 0.013) if active else 0.1), 1.0)
			var distance: float = phase * length
			var point: Vector2 = curve.sample_baked(distance)
			sword_positions.append(point)
			if not reduced_motion and active:
				for segment in 9:
					var a: float = maxf(0, distance - segment * 6)
					var b: float = maxf(0, distance - (segment + 1) * 6)
					draw_line(curve.sample_baked(a), curve.sample_baked(b), Color(color, 0.7 * (1.0 - float(segment) / 9)), 3.5, true)
	# Reduced mode keeps a few static motes; normal ambience uses engine particles.
	var particles: int = 10 if reduced_motion else 0
	for i in particles:
		var phase: float = fposmod(float(i) * 0.618, 1.0)
		var radius: float = (1.0 - phase) * 175.0
		var angle: float = i * 2.4 + phase * 3.5
		var point: Vector2 = altar + Vector2(cos(angle) * radius, sin(angle) * radius * 0.45 - phase * 35)
		var alpha: float = sin(phase * PI) * 0.8
		draw_circle(point, 1.8 + (i % 3) * 0.5, Color(0.77, 1.0, 0.84, alpha))
