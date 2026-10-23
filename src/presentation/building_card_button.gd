extends Button
## Local portrait ornaments show material readiness and level milestones only.
static var _textures: Dictionary = {}
var _ratio := 0.0
var _level := 0
var _cap := 1
var _meter := false
var _portrait: UiIllustration

func _init() -> void:
	_portrait = UiIllustration.new()
	add_child(_portrait)
	# Keep Button.icon for its established layout/minimum-size contract.
	# Its artwork is rendered once by the shared child, with no shader on text/rings.
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_color_override("icon_" + state + "_color", Color.TRANSPARENT)

func refresh_portrait(id: String, era: int, level: int, cap: int, ratio: float, meter: bool) -> void:
	var path := "res://assets/ui/buildings-painted/%s.png" % id
	if id == "hut":
		path = "res://assets/ui/buildings-painted/courtyard.png" if era >= 2 else "res://assets/abode/hut.png"
	elif id == "storage_lingli":
		path = "res://assets/abode/altar-grounded/altar-grounded-v2.png"
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	var next_icon: Texture2D = _textures[path]
	if icon != next_icon:
		icon = next_icon
	_portrait.texture = next_icon
	if [_ratio, _level, _cap, _meter] == [ratio, level, cap, meter]:
		return
	_ratio = ratio
	_level = level
	_cap = maxi(cap, 1)
	_meter = meter
	queue_redraw()

func _draw() -> void:
	if icon == null:
		return
	var extent := float(get_theme_constant("icon_max_width"))
	var face := get_theme_stylebox("normal")
	var center := Vector2(face.content_margin_left + extent * 0.5, size.y * 0.5)
	_portrait.position = center - Vector2.ONE * extent * 0.5
	_portrait.size = Vector2.ONE * extent
	if _meter:
		draw_arc(center, extent * 0.5 + 2, -PI * 0.5, PI * 1.5, 40, Color("b0a58b"), 2, true)
		if _ratio > 0:
			draw_arc(center, extent * 0.5 + 2, -PI * 0.5, -PI * 0.5 + TAU * _ratio, 40, Color("528576"), 2, true)
	# Five milestones divide the actual level cap; the exact level stays in text.
	for i in 5:
		var reached := _level >= ceili(float(_cap) * (i + 1) / 5.0)
		draw_circle(center + Vector2((i - 2) * 7, extent * 0.5 + 5), 2, Color("577e67") if reached else Color("c4b999"))
