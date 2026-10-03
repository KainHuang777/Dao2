class_name GameContent
extends RefCounted

var resource_ids: Array = []
var building_ids: Array = []
var era_ids: Array = []
var resources: Dictionary = {}
var buildings: Dictionary = {}
var eras: Dictionary = {}
var content_version: String = ""
var processing_catalog: Dictionary = {} # RES1-A opt-in; not in release save/content version yet.

func resource(resource_id: String) -> Variant:
	return resources.get(resource_id)

func building(building_id: String) -> Variant:
	return buildings.get(building_id)

func era(era_id: int) -> Variant:
	return eras.get(era_id)

func era_lifespan_entries() -> Array:
	var entries: Array = []
	for era_id in era_ids:
		var definition: Dictionary = eras[era_id]
		entries.append({"era_id": int(definition.id), "lifespan": float(definition.lifespan)})
	return entries
