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
	var hit_width: float = 110.0 if level == 0 else body_size.x * 0.9
	var hit_height: float = 90.0 if level == 0 else body_size.y * 0.75
	return Rect2(Vector2(-hit_width * 0.5, -hit_height + 12.0), Vector2(hit_width, hit_height)).has_point(to_local(world_point))

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
	caption.text = "%s · %s" % [title, status_text]
	UiMaterial.keep_world_text_readable(caption, 18)
	var pulse: float = 0.0 if reduced_motion else sin(clock_time * 1.6) * 0.018
	if (building_id == "garden" or building_id == "herb_farm") and running and level > 0:
		sprite.scale = base_scale * Vector2(1.0 + pulse * 0.3, 1.0 + pulse)
	sprite.visible = true
	if level == 0:
		var blueprint_alpha: float = 0.45 if reduced_motion else 0.40 + sin(clock_time * 2.8) * 0.15
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
		var aura_alpha: float = 0.55 if reduced_motion else 0.50 + sin(clock_time * 2.6) * 0.20
		draw_set_transform(Vector2(0, -10), 0, Vector2(1, 0.42))
		draw_arc(Vector2.ZERO, base_radius + 6, 0, TAU, 64, Color(0.40, 0.88, 0.95, aura_alpha), 2.5, true)
		draw_arc(Vector2.ZERO, base_radius * 0.72, 0, TAU, 48, Color(0.95, 0.85, 0.50, aura_alpha * 0.6), 1.5, true)
		draw_arc(Vector2.ZERO, base_radius + 14, 0, TAU, 64, Color(0.35, 0.82, 0.90, aura_alpha * 0.25), 6.0, true)
		draw_set_transform(Vector2.ZERO)
	elif selected or upgrade_flash > 0.0:
		draw_set_transform(Vector2(0, -12), 0, Vector2(1, 0.4))
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 9 + upgrade_flash * 30, 0, TAU, 80, Color(tint, 0.75), 3.0, true)
		draw_arc(Vector2.ZERO, body_size.x * 0.5 + 16, 0, TAU, 80, Color(tint, 0.2), 8.0, true)
		draw_set_transform(Vector2.ZERO)
	if building_id == "altar" and level > 0:
		var alpha: float = 0.4 if reduced_motion else 0.35 + sin(clock_time * 1.5) * 0.15
		draw_set_transform(Vector2(0, -body_size.y * 0.44), clock_time * 0.08 if not reduced_motion else 0, Vector2(1, 0.42))
		draw_arc(Vector2.ZERO, body_size.x * 0.28, 0, TAU, 80, Color("d9e9ba", alpha), 2.0 + level, true)
		draw_set_transform(Vector2.ZERO)
