class_name SupplyContent
extends RefCounted
## Approved R46 data preparation. Does not activate an economy or modify a save.
## Normal release attach stays unchanged until versioned migration is integrated.
const VERSION := "res1-e-46-1"
const PATH := "res://content/supply/era4_6.json"
static var _runtime: GameContent = null

static func runtime_content() -> GameContent:
	# Immutable canonical definitions used by snapshot validation without a Node.
	if _runtime == null:
		var base := ContentLoader.load_directory("res://content")
		if not base.ok or not IslandProgression.attach(base.content).ok: return null
		var prepared := prepare(base.content)
		if prepared.ok: _runtime = prepared.content
	return _runtime

static func load_file() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary or raw.get("version") != VERSION:
		return {"ok": false, "error": "SUPPLY_CONTENT_VERSION"}
	for key in ["resources", "recipes", "islands", "routes", "durations", "dispatch"]:
		if not raw.get(key) is Dictionary:
			return {"ok": false, "error": "SUPPLY_CONTENT_FIELD:" + key}
	for key in ["eras", "buildings"]:
		if not raw.get(key) is Array:
			return {"ok": false, "error": "SUPPLY_CONTENT_FIELD:" + key}
	var base := ProcessingCatalog.load_file()
	if not base.ok:
		return base
	var catalog: Dictionary = base.catalog.duplicate(true)
	catalog.version = VERSION
	for key in ["resources", "recipes"]:
		for id in raw[key]:
			if catalog[key].has(id):
				return {"ok": false, "error": "SUPPLY_DUPLICATE:" + String(id)}
			catalog[key][id] = raw[key][id].duplicate(true)
	var checked := ProcessingCatalog.validate(catalog)
	if not checked.ok:
		return checked
	return {"ok": true, "data": raw, "catalog": checked.catalog}

static func prepare(base: GameContent) -> Dictionary:
	# Construct an isolated candidate. The caller explicitly decides when to attach.
	# Rebuilding through ContentLoader validates references, costs and prereq cycles.
	var loaded := load_file()
	if not loaded.ok:
		return loaded
	var resources: Array = base.resources.values().duplicate(true)
	for id in loaded.catalog.resources:
		if not base.resources.has(id):
			resources.append({"id": id, "type": "crafted", "max": float(loaded.catalog.resources[id].cap), "rate": 0, "unlocked": false})
	var buildings: Array = base.buildings.values().duplicate(true)
	for definition in loaded.data.buildings:
		if base.buildings.has(definition.id):
			return {"ok": false, "error": "SUPPLY_DUPLICATE_BUILDING:" + String(definition.id)}
		buildings.append(definition.duplicate(true))
	var eras: Array = base.eras.values().duplicate(true)
	for definition in loaded.data.eras:
		if base.eras.has(int(definition.id)):
			return {"ok": false, "error": "SUPPLY_DUPLICATE_ERA:" + str(definition.id)}
		eras.append(definition.duplicate(true))
	var built := ContentLoader.build_content(resources, buildings, eras)
	if not built.ok:
		return built
	var candidate: GameContent = built.content
	candidate.skill_defs = base.skill_defs.duplicate(true)
	candidate.processing_catalog = loaded.catalog
	# Include logistic and recipe parameters in identity, even though they are not
	# normal building/resource fields hashed by ContentLoader.
	candidate.content_version = (base.content_version + candidate.content_version + FileAccess.get_file_as_string(PATH)).sha256_text() + "+" + VERSION
	return {"ok": true, "content": candidate, "data": loaded.data}
