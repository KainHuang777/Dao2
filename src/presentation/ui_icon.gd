class_name UiIcon
extends Control
## Small scalable UI illustrations drawn by Godot instead of font glyphs.

enum Kind { HOURGLASS, SCROLL, TEMPLE, GIFT, REFRESH, LOTUS, SPARKLE, ARROW, GEAR, RETURN_ARROW, WOOD, ORE, HERB, ISLAND_HOME, MANAGEMENT }

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
		Kind.SCROLL, Kind.MANAGEMENT:
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
		Kind.RETURN_ARROW:
			# U-turn arrow: top horizontal bar returning left with arrow head, curved downward to bottom right
			draw_arc(Vector2(center.x + 2 * scale_factor, center.y + 1 * scale_factor), 6.5 * scale_factor, -PI * 0.5, PI * 0.5, 16, c, stroke, true)
			_draw_line(Vector2(14, 4.5), Vector2(7, 4.5), c, stroke, scale_factor)
			draw_colored_polygon(_points([[4, 4.5], [8.5, 1.5], [8.5, 7.5]], scale_factor), c)
			_draw_line(Vector2(14, 17.5), Vector2(10, 17.5), c, stroke, scale_factor)
		Kind.WOOD:
			# Lingmu sprout/branch: central trunk with dual leaf shoots
			_draw_line(Vector2(12, 21), Vector2(12, 6), c, stroke * 1.1, scale_factor)
			_draw_line(Vector2(12, 15), Vector2(6, 10), c, stroke, scale_factor)
			_draw_line(Vector2(12, 11), Vector2(18, 7), c, stroke, scale_factor)
			draw_colored_polygon(_points([[6, 10], [5, 6], [10, 8]], scale_factor), c)
			draw_colored_polygon(_points([[18, 7], [19, 3], [14, 5]], scale_factor), c)
			draw_colored_polygon(_points([[12, 6], [10, 3], [14, 3]], scale_factor), c)
		Kind.ORE:
			# Xuanku diamond crystal / ore shard
			var poly := _points([[12, 3], [19, 10], [15, 20], [9, 20], [5, 10]], scale_factor)
			draw_colored_polygon(poly, Color(c.r, c.g, c.b, 0.35))
			for i in range(poly.size()):
				draw_line(poly[i], poly[(i + 1) % poly.size()], c, stroke, true)
			_draw_line(Vector2(12, 3), Vector2(12, 20), c, stroke * 0.8, scale_factor)
			_draw_line(Vector2(5, 10), Vector2(19, 10), c, stroke * 0.8, scale_factor)
		Kind.HERB:
			# Danxia spirit herb: elegant dual arched blades / leaves
			draw_arc(Vector2(center.x - 3 * scale_factor, center.y + 2 * scale_factor), 7 * scale_factor, -PI * 0.7, -0.1, 14, c, stroke, true)
			draw_arc(Vector2(center.x + 3 * scale_factor, center.y + 2 * scale_factor), 7 * scale_factor, -PI * 0.9, -0.3, 14, c, stroke, true)
			_draw_line(Vector2(12, 21), Vector2(12, 13), c, stroke * 1.2, scale_factor)
			draw_colored_polygon(_points([[12, 13], [10, 5], [14, 5]], scale_factor), c)
			draw_colored_polygon(_points([[5, 8], [3, 12], [8, 12]], scale_factor), c)
			draw_colored_polygon(_points([[19, 8], [21, 12], [16, 12]], scale_factor), c)
		Kind.ISLAND_HOME:
			# Ancestral Home island crest / pagoda silhouette
			draw_colored_polygon(_points([[4, 10], [12, 4], [20, 10]], scale_factor), c)
			_draw_line(Vector2(5, 11), Vector2(19, 11), c, stroke, scale_factor)
			_draw_line(Vector2(6, 18), Vector2(18, 18), c, stroke * 1.3, scale_factor)
			_draw_line(Vector2(8, 11), Vector2(8, 18), c, stroke, scale_factor)
			_draw_line(Vector2(16, 11), Vector2(16, 18), c, stroke, scale_factor)
			_draw_line(Vector2(12, 11), Vector2(12, 18), c, stroke, scale_factor)

func _draw_line(a: Vector2, b: Vector2, color: Color, width: float, scale_factor: float) -> void:
	draw_line((a - Vector2(12, 12)) * scale_factor + size * 0.5, (b - Vector2(12, 12)) * scale_factor + size * 0.5, color, width, true)

func _points(coords: Array, scale_factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in coords:
		result.append((Vector2(point[0], point[1]) - Vector2(12, 12)) * scale_factor + size * 0.5)
	return result

## Creates a crisp ImageTexture of the vector icon to use with Button.icon.
static func create_texture(icon_kind: Kind, icon_size_px: int = 18, color := Color("343c3d")) -> ImageTexture:
	var img := Image.create(icon_size_px, icon_size_px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := color
	var scale := float(icon_size_px) / 24.0
	var stroke_w := maxi(1, int(round(1.5 * scale)))
	
	# Helper for drawing lines onto Image
	var draw_l := func(p1: Vector2, p2: Vector2, col: Color):
		var x0 := int(round(p1.x))
		var y0 := int(round(p1.y))
		var x1 := int(round(p2.x))
		var y1 := int(round(p2.y))
		var dx := absi(x1 - x0)
		var dy := absi(y1 - y0)
		var sx := 1 if x0 < x1 else -1
		var sy := 1 if y0 < y1 else -1
		var err := dx - dy
		while true:
			for ox in range(-stroke_w / 2, stroke_w / 2 + 1):
				for oy in range(-stroke_w / 2, stroke_w / 2 + 1):
					var px := x0 + ox
					var py := y0 + oy
					if px >= 0 and px < icon_size_px and py >= 0 and py < icon_size_px:
						img.set_pixel(px, py, col)
			if x0 == x1 and y0 == y1:
				break
			var e2 := 2 * err
			if e2 > -dy:
				err -= dy
				x0 += sx
			if e2 < dx:
				err += dx
				y0 += sy

	# Coordinate transformer from 24x24 canvas to icon_size_px
	var pt := func(x: float, y: float) -> Vector2:
		return Vector2(x, y) * scale

	match icon_kind:
		Kind.RETURN_ARROW:
			# U-turn arrow: top line right-to-left, arrow head on left, curve down to bottom
			# Arc simulation on right
			var arc_center: Vector2 = pt.call(14.0, 11.0)
			var r := 6.5 * scale
			for i in range(16):
				var a1 := -PI * 0.5 + float(i) * PI / 16.0
				var a2 := -PI * 0.5 + float(i + 1) * PI / 16.0
				draw_l.call(arc_center + Vector2(cos(a1), sin(a1)) * r, arc_center + Vector2(cos(a2), sin(a2)) * r, c)
			draw_l.call(pt.call(14.0, 4.5), pt.call(6.0, 4.5), c)
			# Arrow head pointing left
			draw_l.call(pt.call(6.0, 4.5), pt.call(10.0, 1.5), c)
			draw_l.call(pt.call(6.0, 4.5), pt.call(10.0, 7.5), c)
			draw_l.call(pt.call(10.0, 1.5), pt.call(10.0, 7.5), c)
			draw_l.call(pt.call(14.0, 17.5), pt.call(9.0, 17.5), c)
		Kind.WOOD:
			# Lingmu shoot: vertical trunk with branches and leaves
			draw_l.call(pt.call(12.0, 21.0), pt.call(12.0, 5.0), c)
			draw_l.call(pt.call(12.0, 15.0), pt.call(6.0, 10.0), c)
			draw_l.call(pt.call(6.0, 10.0), pt.call(5.0, 5.0), c)
			draw_l.call(pt.call(5.0, 5.0), pt.call(10.0, 8.0), c)
			draw_l.call(pt.call(12.0, 11.0), pt.call(18.0, 7.0), c)
			draw_l.call(pt.call(18.0, 7.0), pt.call(19.0, 3.0), c)
			draw_l.call(pt.call(19.0, 3.0), pt.call(14.0, 5.0), c)
			# Top leaf
			draw_l.call(pt.call(12.0, 5.0), pt.call(9.0, 2.0), c)
			draw_l.call(pt.call(9.0, 2.0), pt.call(15.0, 2.0), c)
			draw_l.call(pt.call(15.0, 2.0), pt.call(12.0, 5.0), c)
		Kind.ORE:
			# Xuanku diamond crystal / facet lines
			var p_top: Vector2 = pt.call(12.0, 3.0)
			var p_r: Vector2 = pt.call(19.0, 10.0)
			var p_br: Vector2 = pt.call(15.0, 20.0)
			var p_bl: Vector2 = pt.call(9.0, 20.0)
			var p_l: Vector2 = pt.call(5.0, 10.0)
			draw_l.call(p_top, p_r, c)
			draw_l.call(p_r, p_br, c)
			draw_l.call(p_br, p_bl, c)
			draw_l.call(p_bl, p_l, c)
			draw_l.call(p_l, p_top, c)
			draw_l.call(p_top, pt.call(12.0, 20.0), c)
			draw_l.call(p_l, p_r, c)
		Kind.HERB:
			# Danxia spirit herb: dual gracefully curved blades & stem
			draw_l.call(pt.call(12.0, 21.0), pt.call(12.0, 11.0), c)
			# Left leaf
			draw_l.call(pt.call(12.0, 14.0), pt.call(5.0, 9.0), c)
			draw_l.call(pt.call(5.0, 9.0), pt.call(3.0, 13.0), c)
			draw_l.call(pt.call(3.0, 13.0), pt.call(9.0, 13.0), c)
			# Right leaf
			draw_l.call(pt.call(12.0, 14.0), pt.call(19.0, 9.0), c)
			draw_l.call(pt.call(19.0, 9.0), pt.call(21.0, 13.0), c)
			draw_l.call(pt.call(21.0, 13.0), pt.call(15.0, 13.0), c)
			# Top bud
			draw_l.call(pt.call(12.0, 11.0), pt.call(10.0, 4.0), c)
			draw_l.call(pt.call(10.0, 4.0), pt.call(14.0, 4.0), c)
			draw_l.call(pt.call(14.0, 4.0), pt.call(12.0, 11.0), c)
		Kind.SCROLL, Kind.MANAGEMENT:
			# Management scroll / registry
			draw_l.call(pt.call(5.0, 4.0), pt.call(19.0, 4.0), c)
			draw_l.call(pt.call(19.0, 4.0), pt.call(19.0, 20.0), c)
			draw_l.call(pt.call(19.0, 20.0), pt.call(5.0, 20.0), c)
			draw_l.call(pt.call(5.0, 20.0), pt.call(5.0, 4.0), c)
			draw_l.call(pt.call(8.0, 8.0), pt.call(16.0, 8.0), c)
			draw_l.call(pt.call(8.0, 12.0), pt.call(16.0, 12.0), c)
			draw_l.call(pt.call(8.0, 16.0), pt.call(14.0, 16.0), c)
		Kind.ISLAND_HOME:
			# Mountain / ancestral abode crest
			draw_l.call(pt.call(12.0, 3.0), pt.call(4.0, 19.0), c)
			draw_l.call(pt.call(4.0, 19.0), pt.call(20.0, 19.0), c)
			draw_l.call(pt.call(20.0, 19.0), pt.call(12.0, 3.0), c)
			draw_l.call(pt.call(12.0, 10.0), pt.call(8.0, 19.0), c)
			draw_l.call(pt.call(12.0, 10.0), pt.call(16.0, 19.0), c)
		_:
			# Default sparkle / diamond
			draw_l.call(pt.call(12.0, 3.0), pt.call(12.0, 21.0), c)
			draw_l.call(pt.call(3.0, 12.0), pt.call(21.0, 12.0), c)

	return ImageTexture.create_from_image(img)

## Decorates a Button with an icon texture, keeping text and styles pristine.
static func decorate_button(button: Button, icon_kind: Kind, icon_color := Color("343c3d"), icon_dp := 18) -> void:
	button.icon = create_texture(icon_kind, icon_dp, icon_color)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = false
	button.add_theme_constant_override("h_separation", 6)

