extends Control
## Shared, cached hand-painted item textures. See the artwork manifest for source/QC.
const NumberFormatter = preload("res://src/utils/number_formatter.gd")
const TEXTURES := {
	"skill_point": preload("res://assets/ui/resources-painted/imm4-r2/skill_point.png"),
	"dao_heart": preload("res://assets/ui/resources-painted/imm4-r2/dao_heart.png"),
	"dao_proof": preload("res://assets/ui/resources-painted/imm4-r2/dao_proof.png"),
	"contribution": preload("res://assets/ui/resources-painted/imm4-r2/contribution.png"),
	"refined_iron": preload("res://assets/ui/resources-painted/imm4-r2/refined_iron.png"),
	"mithril": preload("res://assets/ui/resources-painted/imm4-r2/mithril.png"),
	"cold_iron": preload("res://assets/ui/resources-painted/imm4-r2/cold_iron.png"),
	"spirit_grass_1000y": preload("res://assets/ui/resources-painted/imm4-r2/spirit_grass_1000y.png"),
	"trans_pill": preload("res://assets/ui/resources-painted/imm4-r2/trans_pill.png"),
	"void_essence": preload("res://assets/ui/resources-painted/imm4-r2/void_essence.png"),
	"star_metal": preload("res://assets/ui/resources-painted/imm4-r2/star_metal.png"),
	"void_crystal": preload("res://assets/ui/resources-painted/imm4-r2/void_crystal.png"),
	"spirit_crystal": preload("res://assets/ui/resources-painted/imm4-r2/spirit_crystal.png"),
	"azure_nectar": preload("res://assets/ui/resources-painted/imm4-r2/azure_nectar.png"),
	"jade_fox": preload("res://assets/ui/resources-painted/imm4-r2/jade_fox.png"),
	"iron_turtle": preload("res://assets/ui/resources-painted/imm4-r2/iron_turtle.png"),
	"fire_phoenix": preload("res://assets/ui/resources-painted/imm4-r2/fire_phoenix.png"),
	"cloud_serpent": preload("res://assets/ui/resources-painted/imm4-r2/cloud_serpent.png"),
	"frost_stag": preload("res://assets/ui/resources-painted/imm4-r2/frost_stag.png"),
	"herb_crane": preload("res://assets/ui/resources-painted/imm4-r2/herb_crane.png"),
	"nascent_breath_pill": preload("res://assets/ui/pills-painted/nascent_breath_pill.png"),
	"void_meditation_pill": preload("res://assets/ui/pills-painted/void_meditation_pill.png"),
	"ancient_herb_dew_pill": preload("res://assets/ui/pills-painted/ancient_herb_dew_pill.png"),
	"void_gathering_pill": preload("res://assets/ui/pills-painted/void_gathering_pill.png"),
	"spirit_vessel_pill": preload("res://assets/ui/pills-painted/spirit_vessel_pill.png"),
	"stone_vault_pill": preload("res://assets/ui/pills-painted/stone_vault_pill.png"),
	"calm_tribulation_pill": preload("res://assets/ui/pills-painted/calm_tribulation_pill.png"),
	"silver_ward_pill": preload("res://assets/ui/pills-painted/silver_ward_pill.png"),
	"wood_nurture_pill": preload("res://assets/ui/pills-painted/wood_nurture_pill.png"),
	"herb_nurture_pill": preload("res://assets/ui/pills-painted/herb_nurture_pill.png"),
	"wealth_gathering_pill": preload("res://assets/ui/pills-painted/wealth_gathering_pill.png"),
	"qi_absorption_pill": preload("res://assets/ui/pills-painted/qi_absorption_pill.png"),

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
	"dao_heart": "道心",
	"dao_proof": "道證",
	"contribution": "貢獻",
	"jade_fox": "靈狐獸魂",
	"iron_turtle": "玄龜獸魂",
	"fire_phoenix": "火鳳獸魂",
	"cloud_serpent": "雲蛟獸魂",
	"frost_stag": "霜角鹿獸魂",
	"herb_crane": "銜芝鶴獸魂",
	"mithril": "秘銀",
	"cold_iron": "寒鐵",
	"trans_pill": "化神丹",

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

var _art: UiIllustration
var resource_id := "":
	set(value):
		resource_id = value
		if is_instance_valid(_art): _art.texture = resource_texture()

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func get_resource_name(id: String) -> String:
	return NAMES.get(id, id)

static func get_resource_texture(id: String) -> Texture2D:
	return TEXTURES.get(id)

static func format_amount(raw: Variant) -> String:
	return NumberFormatter.format_amount(raw)

func resource_texture() -> Texture2D:
	return TEXTURES.get(resource_id)

func _draw() -> void:
	if not is_instance_valid(_art):
		_art = UiIllustration.new()
		add_child(_art)
		_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.texture = resource_texture()
