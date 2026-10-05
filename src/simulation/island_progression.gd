class_name IslandProgression
extends RefCounted
## Bounded Era2/3 release progression. Legacy C remains readable until explicit extension.
const LEGACY_VERSION := "res1-c-1"
const VERSION := "res1-d-2"
const NAMES := {"home": "祖島", "wood": "青木島", "ore": "玄礦島", "herb": "丹霞島"}
const FACILITIES := {"extractor": "採集設施", "workshop": "加工坊", "storage": "倉儲"}
const RECIPES := {"wood": "spirit_timber", "ore": "bronze_essence", "herb": "liquid"}
const HOME_RECIPES := ["formation_core", "foundation_pill", "stone_mid", "golden_core_pill", "talisman"]

static func owns(state: GameState, island: String, recipe: String) -> bool:
	if state.economy.get("version") == LEGACY_VERSION:
		return island in ["wood", "ore"] and RECIPES.get(island) == recipe
	return (island == "home" and recipe in HOME_RECIPES) or RECIPES.get(island) == recipe

static func attach(content: GameContent) -> Dictionary:
	var loaded := ProcessingCatalog.load_file()
	if not loaded.ok:
		return loaded
	content.processing_catalog = loaded.catalog
	if content.era(3) == null:
		var resources: Array = content.resources.values().duplicate(true)
		for id in loaded.catalog.resources:
			if not content.resources.has(id):
				resources.append({"id": id, "type": "crafted", "max": float(loaded.catalog.resources[id].cap), "rate": 0, "unlocked": false})
		var buildings: Array = content.buildings.values().duplicate(true)
		var new_buildings: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/buildings/era2.json"))
		var new_eras: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/eras/era3.json"))
		if not new_buildings is Array or not new_eras is Array:
			return {"ok": false, "error": "D2_CONTENT_FORMAT"}
		buildings.append_array(new_buildings)
		var eras: Array = content.eras.values().duplicate(true)
		eras.append_array(new_eras)
		var expanded := ContentLoader.build_content(resources, buildings, eras)
		if not expanded.ok:
			return expanded
		content.buildings = expanded.content.buildings
		content.building_ids = expanded.content.building_ids
		content.eras = expanded.content.eras
		content.era_ids = expanded.content.era_ids
		content.content_version = expanded.content.content_version
	# Content identity includes the progression contract, not just legacy tables.
	if not content.content_version.ends_with("+" + VERSION):
		content.content_version += "+" + VERSION
	return {"ok": true}

static func active(state: GameState) -> bool:
	return state.economy.get("version", "") in [VERSION, LEGACY_VERSION]

static func preview(state: GameState, content: GameContent) -> Dictionary:
	if state.era_id < 2:
		return _fail("ERA_REQUIREMENT")
	if state.economy.get("version") == VERSION:
		return _fail("ALREADY_MIGRATED")
	if state.economy.get("version") == LEGACY_VERSION:
		var legacy_error := IslandEconomy.validate(state)
		if not legacy_error.is_empty():
			return _fail(legacy_error)
		return {"ok": true, "version": VERSION, "home_policy": "保留三島庫存、設施、工作與在途貨物，另開放金丹丹霞產線。", "cost_policy": "不贈料、不退料；丹霞開拓仍需祖島靈木20＋下品靈石10。", "reset_policy": "輪迴清除本世產業。"}
	if state.economy.is_empty():
		var checked := IslandEconomy.migration_preview(state, content.processing_catalog)
		if not checked.ok:
			return checked
	else:
		var error := IslandEconomy.validate(state)
		if not error.is_empty():
			return _fail(error)
		# B is an isolated prototype, not a release progression to silently promote.
		return _fail("PROTOTYPE_SAVE_REQUIRES_REVIEW")
	return {"ok": true, "version": VERSION, "home_policy": "祖島庫存與既有建築保留，不搬遷、不複製；青木／玄礦尚未開拓。", "cost_policy": "開拓各需靈木20＋下品靈石10；工程費只扣祖島可用庫存。", "reset_policy": "輪迴清除當世島嶼、設施、加工與貨物，不退原料。"}

static func command(content: GameContent, state: GameState, kind: String, p: Dictionary) -> Dictionary:
	if content.processing_catalog.is_empty():
		return _fail("PROCESSING_NOT_ENABLED")
	if kind == "activate_islands":
		var checked := preview(state, content)
		if not checked.ok:
			return checked
		if state.economy.get("version") == LEGACY_VERSION:
			state.economy.version = VERSION
			return _ok("islands_extended")
		var migrated := IslandEconomy.command(content, state, "migrate_processing", {})
		if not migrated.ok:
			return migrated
		state.economy.version = VERSION
		for id in state.economy.islands:
			state.economy.islands[id].facilities = {"extractor": 1, "workshop": 1, "storage": 1}
		return _ok("islands_activated")
	if not active(state):
		return _fail("ECONOMY_NOT_MIGRATED")
	var island: Variant = p.get("island_id", "")
	var facility: Variant = p.get("facility_id", "")
	if not island is String or not island in RECIPES:
		return _fail("UNKNOWN_ISLAND")
	if not facility is String or not facility in FACILITIES:
		return _fail("UNKNOWN_FACILITY")
	if state.era_id < 2 or not state.economy.islands[island].opened:
		return _fail("ISLAND_NOT_OPEN")
	var level: int = state.economy.islands[island].facilities[facility]
	if level >= 3:
		return _fail("LEVEL_CAP")
	var costs := upgrade_cost(facility, level)
	for id in costs:
		if IslandEconomy.value(state, "home", id) < float(costs[id]):
			return _fail("INSUFFICIENT_RESOURCE")
	for id in costs:
		IslandEconomy._put(state, "home", id, IslandEconomy.value(state, "home", id) - float(costs[id]))
	state.economy.islands[island].facilities[facility] = level + 1
	return _ok("island_facility_upgraded")

static func upgrade_cost(facility: String, level: int) -> Dictionary:
	match facility:
		"extractor": return {"wood": 20 * level, "bronze_essence": 2 * level}
		"workshop": return {"spirit_timber": 2 * level, "bronze_essence": 2 * level}
		_: return {"spirit_timber": 2 * level, "stone_low": 20 * level}

static func capacity(state: GameState, island: String) -> float:
	if not active(state):
		return 100.0
	return 100.0 * int(state.economy.islands[island].get("facilities", {}).get("storage", 1))

static func duration(state: GameState, island: String, recipe: String) -> int:
	var base: int = IslandEconomy.DURATIONS[recipe]
	if not active(state):
		return base
	return maxi(1, int(ceil(float(base) / int(state.economy.islands[island].facilities.workshop))))

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "events": [], "changed_ids": []}

static func _ok(kind: String) -> Dictionary:
	return {"ok": true, "events": [{"kind": kind}], "changed_ids": ["economy", "resources"]}
