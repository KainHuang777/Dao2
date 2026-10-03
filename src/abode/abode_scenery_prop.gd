extends Node2D
## Read-only prop; harvest feedback cannot grant resources.
var find_id := ""
var kind := ""
var reduced_motion := false
var sprite: Sprite2D
var age := 0.0
var tint := Color.WHITE
var width := 96.0

func setup(entry: Dictionary, texture: Texture2D) -> void:
	find_id = entry.id
	kind = entry.kind
	name = "洞府小景_" + find_id.replace(":", "_")
	tint = Color("b6e7a5") if kind == "wood" else (Color("d6eee1") if kind == "herb" else Color("a6dce2"))
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * width / texture.get_width()
	sprite.position = Vector2(0, -width * 0.4)
	add_child(sprite)

func contains_point(point: Vector2) -> bool:
	if not visible:
		return false
	var transform := get_viewport().get_canvas_transform() * global_transform
	var minimum := 44.0 / maxf(0.01, minf(transform.x.length(), transform.y.length()))
	var hit_size := Vector2(maxf(width * 0.9, minimum), maxf(width * 0.9, minimum))
	return Rect2(Vector2(-hit_size.x * 0.5, -width * 0.4 - hit_size.y * 0.5), hit_size).has_point(to_local(point))

func _process(delta: float) -> void:
	for child in get_children():
		if child is Label:
			UiMaterial.keep_world_text_readable(child, 18)
	if reduced_motion:
		return
	age += delta
	queue_redraw()

func _draw() -> void:
	# Subtle ground ring, not a text sign or a build plot. Does not float the sprite.
	var alpha := 0.35 if reduced_motion else 0.30 + sin(age * 1.8) * 0.1
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, 0.35))
	draw_arc(Vector2.ZERO, 35, 0, TAU, 32, Color(tint, alpha), 1.8, true)
	draw_set_transform(Vector2.ZERO)

func harvest_feedback(text: String, font: Font) -> void:
	find_id = "" # Immediately cease being selectable while feedback fades.
	var label := Label.new()
	label.text = text
	label.position = Vector2(-100, -108)
	label.size = Vector2(200, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiMaterial.apply_world_caption(label, font, 20)
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	if not reduced_motion:
		tween.tween_property(label, "position:y", -132.0, 0.65)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
