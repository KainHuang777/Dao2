class_name NativeVfx
extends RefCounted
## Original bounded 2D effects. Visual randomness never touches gameplay RNG.
const RING := preload("res://assets/vfx/spirit_ring.gdshader")
const SWORD := preload("res://assets/vfx/sword_emission.gdshader")
const LIGHTNING := preload("res://assets/vfx/tribulation_lightning.gdshader")
const SPARK := preload("res://assets/vfx/spark.tres")
const TITLE_GLOW := preload("res://src/presentation/title_glow.gd")

static func additive() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material

static func spark_texture() -> GradientTexture2D:
	return SPARK

static func particles(amount: int, tint: Color, lifetime: float = 0.8) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.emitting = false
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.fixed_fps = 30
	emitter.texture = spark_texture()
	emitter.material = additive()
	emitter.color = tint
	emitter.gravity = Vector2.ZERO
	emitter.direction = Vector2.UP
	emitter.spread = 45.0
	emitter.initial_velocity_min = 12.0
	emitter.initial_velocity_max = 35.0
	emitter.scale_amount_min = 0.12
	emitter.scale_amount_max = 0.28
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	emitter.color_ramp = fade
	return emitter

static func ring(parent: Node, center: Vector2, size: Vector2, tint: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	var blank := GradientTexture2D.new()
	blank.width = 4
	blank.height = 4
	sprite.texture = blank
	sprite.position = center
	sprite.scale = size / 4.0
	var material := ShaderMaterial.new()
	material.shader = RING
	material.set_shader_parameter("tint", tint)
	sprite.material = material
	parent.add_child(sprite)
	return sprite

static func neon_title(label: Label, tint: Color) -> void:
	TITLE_GLOW.new().setup(label, tint)
	# Native font outline/shadow keeps shaped Chinese text and responsive layout.
	label.add_theme_color_override("font_color", Color("fff8dc"))
	label.add_theme_color_override("font_outline_color", Color(tint, 0.6))
	if not label.has_theme_constant_override("outline_size"):
		label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_shadow_color", Color(tint, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	# Reuse existing glyph outline sizes instead of creating a second large atlas.
	if not label.has_theme_constant_override("shadow_outline_size"):
		label.add_theme_constant_override("shadow_outline_size", 8)

static func set_title_glow_enabled(label: Label, enabled: bool) -> void:
	var glow := label.get_node_or_null("題字柔光")
	if glow != null:
		glow.glow_enabled = enabled
