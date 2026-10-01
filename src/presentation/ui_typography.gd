class_name UiTypography
extends RefCounted
## Shared Godot font roles for readable Traditional Chinese UI.

const BASE_FONT: FontFile = preload("res://assets/fonts/SourceHanSansTW-VF.ttf")
const CHAPTER_FONT: FontFile = preload("res://assets/fonts/NotoSerifTC-VF.ttf")
const WEIGHT_AXIS: int = 0x77676874 # OpenType wght tag; verified by TextServer.

static var _body: FontVariation
static var _emphasis: FontVariation
static var _chapter: FontVariation

static func chapter_font() -> Font:
	if _chapter == null:
		_chapter = FontVariation.new()
		_chapter.base_font = CHAPTER_FONT
		_chapter.variation_opentype = {WEIGHT_AXIS: 800}
	return _chapter

static func body_font() -> Font:
	if _body == null:
		_body = _weighted_font(400)
	return _body

static func emphasis_font() -> Font:
	if _emphasis == null:
		_emphasis = _weighted_font(600)
	return _emphasis

static func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font = body_font()
	result.default_font_size = 18
	result.set_font("normal_font", "RichTextLabel", body_font())
	result.set_font("bold_font", "RichTextLabel", emphasis_font())
	UiMaterial.populate_theme(result)
	return result

static func dialog_surface() -> StyleBoxTexture:
	return UiMaterial.surface("panel").duplicate()

static func _weighted_font(weight: int) -> FontVariation:
	var result := FontVariation.new()
	result.base_font = BASE_FONT
	result.variation_opentype = {WEIGHT_AXIS: weight}
	return result
