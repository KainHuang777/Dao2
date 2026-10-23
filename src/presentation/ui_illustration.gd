class_name UiIllustration
extends TextureRect
## Presentation-only B treatment. The original Texture2D and layout rectangle stay intact.
## Dense icons below 40 display pixels deliberately retain their authored soft edges.
const EDGE_SHADER = preload("res://src/presentation/ui_illustration.gdshader")
const SAFETY_PIXELS := 7.0
# These accepted medallions already have a continuous authored gold frame.
const FRAMED_PREFIXES := ["res://assets/ui/achievements-painted/"]
var _signature: Array = []

static func permits_treatment(image: Texture2D) -> bool:
	for prefix in FRAMED_PREFIXES:
		if image.resource_path.begins_with(prefix): return false
	return true

func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var ink := ShaderMaterial.new()
	ink.shader = EDGE_SHADER
	material = ink

func _ready() -> void:
	resized.connect(_sync_effect)
	_sync_effect()

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_sync_effect()

func _sync_effect() -> void:
	if texture == null or size.x <= 0 or size.y <= 0:
		return
	# Includes viewport stretch; image-space texels are never used as display pixels.
	var screen := get_screen_transform()
	var scale_px := Vector2(screen.x.length(), screen.y.length()).max(Vector2(0.001, 0.001))
	var fitted := texture.get_size() * minf(size.x / texture.get_width(), size.y / texture.get_height())
	var signature := [texture, fitted, scale_px]
	if signature == _signature:
		return
	_signature = signature
	var ink := material as ShaderMaterial
	ink.set_shader_parameter("art_texture", texture)
	ink.set_shader_parameter("image_size", fitted)
	ink.set_shader_parameter("pixel_scale", scale_px)
	ink.set_shader_parameter("enabled", permits_treatment(texture) and minf(fitted.x * scale_px.x, fitted.y * scale_px.y) >= 40.0)

