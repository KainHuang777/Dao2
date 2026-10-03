extends Node2D
## Interactive Spirit Tree prop on the abode island.
## Can be clicked to chop/gather wood directly from the world scene.

var tree_id: String = "spirit_tree"
var title: String = "靈木"
var sprite: Sprite2D
var caption: Label
var body_size: Vector2
var base_scale: Vector2
var _harvest_tween: Tween

func setup(display_name: String, art: Texture2D, width: float, font: Font) -> void:
	title = display_name
	name = display_name
	body_size = Vector2(width, width)

	sprite = Sprite2D.new()
	sprite.texture = art
	sprite.scale = Vector2.ONE * width / float(art.get_width())
	base_scale = sprite.scale
	sprite.position = Vector2(0, -width * 0.45)
	add_child(sprite)

	caption = Label.new()
	caption.position = Vector2(-70, 10)
	caption.size = Vector2(140, 36)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiMaterial.apply_world_caption(caption, font, 22)
	caption.text = title
	add_child(caption)

func contains_point(world_point: Vector2) -> bool:
	if not visible:
		return false
	var local: Vector2 = to_local(world_point)
	var hit_w: float = body_size.x * 0.85
	var hit_h: float = body_size.y * 0.95
	var hit_rect := Rect2(Vector2(-hit_w * 0.5, -hit_h + 10.0), Vector2(hit_w, hit_h))
	return hit_rect.has_point(local)

func _process(_delta: float) -> void:
	for child in get_children():
		if child is Label:
			UiMaterial.keep_world_text_readable(child, 18)

func chop_feedback(amount: int = 1) -> void:
	if _harvest_tween != null and _harvest_tween.is_valid():
		_harvest_tween.kill()

	_harvest_tween = create_tween().set_parallel(true)
	# Elastic shake on the tree trunk/branches
	_harvest_tween.tween_property(sprite, "rotation_degrees", -5.0, 0.06).from(0.0)
	_harvest_tween.chain().tween_property(sprite, "rotation_degrees", 4.0, 0.07)
	_harvest_tween.chain().tween_property(sprite, "rotation_degrees", -2.0, 0.06)
	_harvest_tween.chain().tween_property(sprite, "rotation_degrees", 0.0, 0.08)

	_harvest_tween.tween_property(sprite, "scale", base_scale * 0.94, 0.06).from(base_scale)
	_harvest_tween.chain().tween_property(sprite, "scale", base_scale * 1.05, 0.08)
	_harvest_tween.chain().tween_property(sprite, "scale", base_scale, 0.10)

	# Floating "+1 木材" label
	_spawn_floating_text("+%d 木材" % amount)

func deny_feedback() -> void:
	if _harvest_tween != null and _harvest_tween.is_valid():
		_harvest_tween.kill()
	_harvest_tween = create_tween()
	_harvest_tween.tween_property(sprite, "position:x", 6.0, 0.05).from(0.0)
	_harvest_tween.chain().tween_property(sprite, "position:x", -6.0, 0.05)
	_harvest_tween.chain().tween_property(sprite, "position:x", 4.0, 0.05)
	_harvest_tween.chain().tween_property(sprite, "position:x", 0.0, 0.06)

func _spawn_floating_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiMaterial.apply_world_caption(float_label, UiTypography.emphasis_font(), 22)
	float_label.position = Vector2(-60, -body_size.y * 0.85)
	float_label.size = Vector2(120, 32)
	add_child(float_label)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(float_label, "position:y", float_label.position.y - 45.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(float_label, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(float_label.queue_free)
