extends Control
## Shared, cached hand-painted item textures. See the artwork manifest for source/QC.
const TEXTURES := {
	"wood": preload("res://assets/ui/resources-painted/wood.png"),
	"spirit_timber": preload("res://assets/ui/resources-painted/spirit_timber.png"),
	"black_copper": preload("res://assets/ui/resources-painted/black_copper.png"),
	"bronze_essence": preload("res://assets/ui/resources-painted/bronze_essence.png"),
	"stone_low": preload("res://assets/ui/resources-painted/stone_low.png"),
	"stone_mid": preload("res://assets/ui/resources-painted/stone_mid.png"),
	"stone_high": preload("res://assets/ui/resources-painted/stone_high.png"),
	"formation_core": preload("res://assets/ui/resources-painted/formation_core.png"),
	"spirit_grass_low": preload("res://assets/ui/resources-painted/spirit_grass_low.png"),
	"spirit_grass_100y": preload("res://assets/ui/resources-painted/spirit_grass_100y.png"),
	"liquid": preload("res://assets/ui/resources-painted/liquid.png"),
	"talisman": preload("res://assets/ui/resources-painted/talisman.png"),
	"foundation_pill": preload("res://assets/ui/resources-painted/foundation_pill.png"),
	"golden_core_pill": preload("res://assets/ui/resources-painted/golden_core_pill.png"),
	"money": preload("res://assets/ui/resources-painted/money.png"),
	"lingli": preload("res://assets/ui/resources-painted/lingli.png")
}
var resource_id := ""

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func resource_texture() -> Texture2D:
	return TEXTURES.get(resource_id)

func _draw() -> void:
	var texture := resource_texture()
	if texture == null:
		return
	var extent := minf(size.x, size.y)
	draw_texture_rect(texture, Rect2((size - Vector2.ONE * extent) * 0.5, Vector2.ONE * extent), false)
