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

const NAMES := {
	"lingli": "靈氣",
	"money": "金錢",
	"wood": "靈木",
	"stone_low": "下品靈石",
	"stone_mid": "中品靈石",
	"stone_high": "上品靈石",
	"black_copper": "玄銅",
	"spirit_grass_low": "靈草",
	"spirit_grass_100y": "百年靈草",
	"spirit_grass_1000y": "千年靈草",
	"spirit_timber": "靈材",
	"bronze_essence": "銅精",
	"liquid": "丹液",
	"formation_core": "陣芯",
	"foundation_pill": "築基丹",
	"golden_core_pill": "金丹",
	"talisman": "符咒",
	"star_metal": "星金",
	"void_crystal": "虛空結晶",
	"skill_point": "技能點",
	"spirit_crystal": "極品靈晶",
	"azure_nectar": "天青靈液",
	"refined_iron": "精鐵",
	"void_essence": "虛空精華"
}

var resource_id := ""

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func get_resource_name(id: String) -> String:
	return NAMES.get(id, id)

static func get_resource_texture(id: String) -> Texture2D:
	return TEXTURES.get(id)

static func format_amount(raw: Variant) -> String:
	if raw == null:
		return "0"
	var val: float = 0.0
	if raw is AmountCompat:
		if raw.layer == 0:
			val = raw.mag * float(raw.sign)
		else:
			return raw.to_display_string()
	elif typeof(raw) == TYPE_STRING:
		var parsed: Dictionary = AmountCompat.try_parse(raw)
		if bool(parsed.get("ok", false)):
			var a: AmountCompat = parsed["value"]
			if a.layer == 0:
				val = a.mag * float(a.sign)
			else:
				return a.to_display_string()
		else:
			val = float(raw)
	elif typeof(raw) in [TYPE_FLOAT, TYPE_INT]:
		val = float(raw)

	if is_equal_approx(val, floor(val)):
		return str(int(val))
	if val >= 10.0:
		return str(int(floor(val)))
	return "%.1f" % val

func resource_texture() -> Texture2D:
	return TEXTURES.get(resource_id)

func _draw() -> void:
	var texture := resource_texture()
	if texture == null:
		return
	var extent := minf(size.x, size.y)
	draw_texture_rect(texture, Rect2((size - Vector2.ONE * extent) * 0.5, Vector2.ONE * extent), false)
