extends VBoxContainer
## Shared icon-based cost display: heading, square item cells and a shortage note.
const Tile = preload("res://src/presentation/recipe_material_tile.gd")
const Icon = preload("res://src/presentation/resource_icon.gd")
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
const MUTED := Color("355f58")
const SHORT := Color("a23e32")

var heading: Label
var cards: HFlowContainer
var note: Label
var tiles: Dictionary = {}
var _text_color := MUTED
var _heading_text := ""
var _note_text := ""
var compact := false

func _init() -> void:
	add_theme_constant_override("separation", 2)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", MUTED)
	heading.visible = false
	add_child(heading)
	cards = HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	add_child(cards)
	note = Label.new()
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.visible = false
	add_child(note)

func show_costs(costs: Dictionary, names: Dictionary, available: Dictionary, sources: Dictionary, title_text: String, note_text: String = "", text_color: Color = MUTED) -> void:
	_text_color = text_color
	_heading_text = title_text
	heading.text = title_text
	heading.add_theme_color_override("font_color", text_color)
	for resource in costs:
		if not tiles.has(resource):
			tiles[resource] = Tile.new()
			tiles[resource].set_compact(compact)
			cards.add_child(tiles[resource])
		var tile = tiles[resource]
		var source := String(sources.get(resource, "祖島"))
		tile.refresh(resource, String(names.get(resource, resource)), float(costs[resource]), float(available.get(resource, 0.0)), source)
		tile.set_reserved(0.0)
	for resource in tiles:
		tiles[resource].visible = costs.has(resource)
	_note_text = note_text
	note.text = note_text
	_apply_text_visibility()
	note.add_theme_color_override("font_color", SHORT if note_text.contains("缺") else text_color)

func set_compact(enabled: bool) -> void:
	if compact == enabled:
		return
	compact = enabled
	add_theme_constant_override("separation", 0 if enabled else 2)
	cards.add_theme_constant_override("h_separation", 4 if enabled else 6)
	cards.add_theme_constant_override("v_separation", 2 if enabled else 6)
	for resource in tiles:
		tiles[resource].set_compact(enabled)
	_apply_text_visibility()

func is_compact() -> bool:
	return compact

func _apply_text_visibility() -> void:
	heading.visible = not compact and not _heading_text.is_empty()
	note.visible = not compact and not _note_text.is_empty()

func clear_costs() -> void:
	for resource in tiles:
		tiles[resource].visible = false
	_heading_text = ""
	_note_text = ""
	heading.visible = false
	note.visible = false

func visible_tiles() -> int:
	var count := 0
	for resource in tiles:
		if tiles[resource].visible:
			count += 1
	return count

static func shortage_text(costs: Dictionary, available: Dictionary, names: Dictionary, prefix: String = "祖島材料不足") -> String:
	var parts: Array[String] = []
	for resource in costs:
		var gap := float(costs[resource]) - float(available.get(resource, 0.0))
		if gap > 0.0:
			parts.append("%s 需 %s・缺 %s" % [String(names.get(resource, resource)), NumberFormatter.format_amount(costs[resource]), NumberFormatter.format_amount(gap)])
	if parts.is_empty():
		return ""
	return prefix + "：" + "・".join(parts)

static func covers(costs: Dictionary, available: Dictionary) -> bool:
	for resource in costs:
		if float(available.get(resource, 0.0)) < float(costs[resource]):
			return false
	return true
