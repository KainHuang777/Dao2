class_name GameContent
extends RefCounted

var resource_ids: Array = []
var building_ids: Array = []
var era_ids: Array = []
var recipe_ids: Array = []
var consumable_ids: Array = []
var skill_ids: Array = []
var resources: Dictionary = {}
var buildings: Dictionary = {}
var eras: Dictionary = {}
var recipes: Dictionary = {}
var consumables: Dictionary = {}
var skills: Dictionary = {}
var content_version: String = ""

func resource(resource_id: String) -> Variant:
	return resources.get(resource_id)

func building(building_id: String) -> Variant:
	return buildings.get(building_id)

func era(era_id: int) -> Variant:
	return eras.get(era_id)

func recipe(recipe_id: String) -> Variant:
	return recipes.get(recipe_id)

func consumable(resource_id: String) -> Variant:
	return consumables.get(resource_id)

func skill(skill_id: String) -> Variant:
	return skills.get(skill_id)

func era_lifespan_entries() -> Array:
	var entries: Array = []
	for era_id in era_ids:
		var definition: Dictionary = eras[era_id]
		entries.append({"era_id": int(definition.id), "lifespan": float(definition.lifespan)})
	return entries
