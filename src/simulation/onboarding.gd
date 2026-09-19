class_name Onboarding
extends RefCounted

const SCHEMA_VERSION := 1
const HUT_LINGLI_CAPACITY_PER_LEVEL := 150
const MILESTONES := [
	{"building": "hut", "level": 2},
	{"building": "wooden_house", "level": 2},
	{"building": "forest_farm", "level": 3},
	{"building": "stone_mine", "level": 3},
	{"building": "herb_farm", "level": 3},
]

static func is_active(onboarding_version: int, era_id: int) -> bool:
	return era_id == 1 and onboarding_version >= SCHEMA_VERSION

static func unlock_state(era_id: int, onboarding_version: int, buildings: Dictionary) -> Dictionary:
	if not is_active(onboarding_version, era_id):
		return {"active": false, "resources": [], "buildings": [], "next_objective": null}
	var hut := _level(buildings, "hut")
	var wooden_house := _level(buildings, "wooden_house")
	var forest_farm := _level(buildings, "forest_farm")
	var stone_mine := _level(buildings, "stone_mine")
	var herb_farm := _level(buildings, "herb_farm")
	var resources: Array = ["lingli"]
	var visible: Array = ["hut"]
	if hut >= 1:
		resources.append("money")
		resources.append("wood")
	if hut >= 2:
		visible.append("wooden_house")
		visible.append("storage_lingli")
		visible.append("storage_money")
	if wooden_house >= 2:
		visible.append("forest_farm")
	if forest_farm >= 3:
		visible.append("stone_mine")
	if stone_mine >= 1:
		resources.append("stone_low")
		visible.append("storage_stone")
	if stone_mine >= 3:
		visible.append("herb_farm")
	if herb_farm >= 1:
		resources.append("spirit_grass_low")
		visible.append("storage_wood")
		visible.append("storage_herb")
	if herb_farm >= 3:
		resources.append("foundation_pill")
	var next_objective: Variant = null
	for milestone in MILESTONES:
		if _level(buildings, milestone.building) < milestone.level:
			next_objective = {"kind": "building", "id": milestone.building}
			break
	return {"active": true, "resources": resources, "buildings": visible, "next_objective": next_objective}

static func hut_lingli_capacity(era_id: int, onboarding_version: int, buildings: Dictionary) -> int:
	if not is_active(onboarding_version, era_id):
		return 0
	return _level(buildings, "hut") * HUT_LINGLI_CAPACITY_PER_LEVEL

static func _level(buildings: Dictionary, building_id: String) -> int:
	return int(buildings.get(building_id, 0))
