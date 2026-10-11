extends Node2D
## Independent map prop: world anchor, selection area and sprite are separate.
var building_id: String
var title: String
var level: int = 1
var selected: bool = false
var running: bool = true
var reduced_motion: bool = false
var sprite: Sprite2D
var caption: Label
var body_size: Vector2
var clock_time: float = 0.0
var upgrade_flash: float = 0.0
var base_scale: Vector2

func setup(id: String, display_name: String, art: Texture2D, width: float, font: Font) -> void:
	building_id = id
	title = display_name
	name = display_name
	body_size = Vector2(width, width)
	sprite = Sprite2D.new()
	sprite.texture = art
	sprite.scale = Vector2.ONE * width / float(art.get_width())
	base_scale = sprite.scale
	sprite.position = Vector2(0, -width * 0.42)
	add_child(sprite)
	caption = Label.new()
	caption.position = Vector2(-105, 16)
	caption.size = Vector2(210, 44)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiMaterial.apply_world_caption(caption, font, 26)
	add_child(caption)

func contains_point(world_point: Vector2) -> bool:
	if not visible:
		return false
	var local_point := to_local(world_point)
	if level == 0 and Rect2(Vector2.ZERO, caption.size).has_point(caption.get_transform().affine_inverse() * local_point):
		return true
	var hit_width: float = body_size.x * 0.9
	var hit_height: float = body_size.y * (0.95 if level == 0 else 0.75)
	return Rect2(Vector2(-hit_width * 0.5, -hit_height + 12.0), Vector2(hit_width, hit_height)).has_point(local_point)

func pulse_upgrade() -> void:
	upgrade_flash = 1.0

func _process(delta: float) -> void:
	if not visible:
		return
	clock_time += delta
	upgrade_flash = maxf(0, upgrade_flash - delta * 0.8)
	var status_text := ""
	if level == 0:
		status_text = "可建"
	else:
		status_text = "%d階%s" % [level, "" if running else "·停"]
	caption.text = "點擊建造茅屋" if level == 0 and building_id == "hut" else "%s · %s" % [title, status_text]
	var caption_width := 280.0 if level == 0 else 210.0
	if caption.size.x != caption_width:
		caption.size.x = caption_width
		caption.position.x = -caption_width * 0.5
	# The low altar remains legible without a permanent nameplate across the ground.
	if building_id == "storage_lingli":
		caption.visible = selected
	UiMaterial.keep_world_text_readable(caption, 18)
	var pulse: float = 0.0 if reduced_motion else sin(clock_time * 1.6) * 0.018
	if (building_id == "garden" or building_id == "herb_farm") and running and level > 0:
		sprite.scale = base_scale * Vector2(1.0 + pulse * 0.3, 1.0 + pulse)
	sprite.visible = true
	if level == 0:
		var blueprint_alpha: float = 0.78 if reduced_motion else 0.75 + sin(clock_time * 2.8) * 0.10
		sprite.modulate = Color(0.48, 0.90, 0.98, blueprint_alpha)
	else:
		var flash_color: Color = Color(1.0 + upgrade_flash * 0.45, 1.0 + upgrade_flash * 0.3, 1.0 + upgrade_flash * 0.1, 1.0)
		sprite.modulate = flash_color if running else Color(0.65, 0.72, 0.73, 1.0)
	queue_redraw()

func _draw() -> void:
	var tint: Color = Color("bbf8d7") if running else Color("95a6a6")
	if level == 0:
		var pulse_cycle: float = 0.0 if reduced_motion else sin(clock_time * 2.6) * 0.08
		var base_radius: float = body_size.x * 0.52 * (1.0 + pulse_cycle)
		var aura_alpha: float = 0.85 if reduced_motion else 0.80 + sin(clock_time * 2.6) * 0.15
		draw_set_transform(Vector2(0, -10), 0, Vector2(1, 0.42))
		draw_arc(Vector2.ZERO, base_radius + 6, 0, TAU, 64, Color(0.40, 0.88, 0.95, aura_alpha), 4.0, true)
		draw_arc(Vector2.ZERO, base_radius * 0.72, 0, TAU, 48, Color(0.95, 0.85, 0.50, aura_alpha * 0.6), 1.5, true)
		draw_arc(Vector2.ZERO, base_radius + 14, 0, TAU, 64, Color(0.35, 0.82, 0.90, aura_alpha * 0.25), 6.0, true)
		draw_set_transform(Vector2.ZERO)
		if building_id == "hut":
			var bob := 0.0 if reduced_motion else sin(clock_time * 2.6) * 5.0
			var arrow_tip := Vector2(0, -body_size.y * 0.96 + bob)
			draw_polyline(PackedVector2Array([arrow_tip + Vector2(-14, -12), arrow_tip, arrow_tip + Vector2(14, -12)]), Color("f6dc83"), 5.0, true)
	elif selected or upgrade_flash > 0.0:
		var contact := Vector2(0, -body_size.y * 0.35) if building_id == "storage_lingli" else Vector2(0, -12)
		draw_set_transform(contact, 0, Vector2(1, 0.4))
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 9 + upgrade_flash * 30, 0, TAU, 80, Color(tint, 0.75), 3.0, true)
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 16, 0, TAU, 80, Color(tint, 0.2), 8.0, true)
		draw_set_transform(Vector2.ZERO)
