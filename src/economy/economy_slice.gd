class_name EconomySlice
extends RefCounted
## Explicit Era1–3 content factory. Context is ephemeral and owned by one profile.
const FRONTIER_TAG := "+econ-r1-d2-1"
const FRONTIER_GATES := {"mithril_matrix":"R11", "trans_pill":"R12", "stone_high":"R13", "void_array":"R14"}
const FRONTIER_BUILDINGS := {"research_instruments":"R11", "matrix_storehouse":"R13", "void_condenser":"R14", "void_harvester":"R14", "ancient_focus":"R12", "core_storehouse_5":"R13", "cultivation_focus_5":"R12", "cultivation_focus_6":"R14"}
const LATE_TAG := "+econ-r1-d1-1"
const DEEP_GATES := {"refined_iron":"R09", "cold_iron":"R10", "mithril":"R11"}
const TAG := "+econ-r1-c-1"
const RECIPE_GATES := {"spirit_timber":"R01", "bronze_essence":"R02", "formation_core":"R05", "talisman":"R05", "liquid":"R06", "golden_core_pill":"R06", "stone_mid":"R07"}
const DISCRETE := ["spirit_timber", "bronze_essence", "formation_core", "foundation_pill", "golden_core_pill", "talisman", "mithril_matrix", "void_array"]

static func create() -> Dictionary:
	var loaded := ContentLoader.load_directory("res://content")
	if not loaded.ok: return loaded
	var c: GameContent = loaded.content
	var attached := IslandProgression.attach_supply(c)
	if not attached.ok: return attached
	for id in ["research_seat", "craft_workshop"]:
		c.building_ids.append(id)
		c.buildings[id] = {"id":id, "era":2, "max_level":1 if id == "research_seat" else 2, "cost_factor":1.15, "prereq":null, "base_cost":{"money":30, "wood":20, "stone_low":10}, "effect_weight":null, "effects":{}}
	# Moving liquid to Era3 must also remove its legacy Era2 cultivation dependency.
	c.eras = c.eras.duplicate(true)
	c.eras[2].level_up_requirements.graded_resources[1].resources = {"spirit_timber":5, "bronze_essence":5}
	c.content_version += TAG
	c.processing_catalog["econ_r1"] = {"completed":{}}
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/research/econ_r1.json"))
	return {"ok":true, "content":c, "catalog":catalog}

static func create_late() -> Dictionary:
	var loaded := create()
	if not loaded.ok: return loaded
	loaded.content.content_version += LATE_TAG
	var extension: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/research/econ_r1_d1.json"))
	loaded.catalog.nodes.append_array(extension.nodes)
	loaded.content.processing_catalog.econ_r1["stage"] = 4
	return loaded

static var _components: Dictionary = {}
static var _frontier_content: GameContent

static func component_data() -> Dictionary:
	if _components.is_empty(): _components = JSON.parse_string(FileAccess.get_file_as_string("res://content/research/econ_r1_d2_components.json"))
	return _components

static func frontier_content() -> GameContent:
	if _frontier_content == null: _frontier_content = create_frontier().content
	return _frontier_content

static func frontier(c: GameContent) -> bool:
	return c.content_version.ends_with(FRONTIER_TAG)

static func frontier_state(state: GameState) -> bool:
	return state.resources.has("mithril_matrix") and state.resources.has("void_array")

static func extend_catalog(catalog: Dictionary) -> Dictionary:
	var result := catalog.duplicate(true)
	var data := component_data()
	result.resources.merge(data.resources)
	result.recipes.merge(data.recipes)
	return result

static func create_frontier() -> Dictionary:
	var loaded := create_late()
	if not loaded.ok: return loaded
	var c: GameContent = loaded.content
	c.content_version += FRONTIER_TAG
	var extension: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/research/econ_r1_d2.json"))
	loaded.catalog.nodes.append_array(extension.nodes)
	c.processing_catalog = extend_catalog(c.processing_catalog)
	c.processing_catalog.econ_r1.stage = 6
	var data := component_data()
	for id in data.resources:
		c.resource_ids.append(id)
		c.resources[id] = {"id":id, "type":"crafted", "max":float(data.resources[id].cap), "rate":0, "unlocked":false}
	for definition in data.buildings:
		c.building_ids.append(definition.id)
		c.buildings[definition.id] = definition
	return loaded

static func late(c: GameContent) -> bool:
	return c.content_version.ends_with(LATE_TAG) or frontier(c)

static func active(c: GameContent) -> bool:
	return c.content_version.ends_with(TAG) or late(c)

static func bind(c: GameContent, research: Dictionary) -> GameContent:
	if not active(c): return c
	var copy := GameContent.new()
	for key in ["resource_ids", "building_ids", "era_ids", "resources", "buildings", "eras", "skill_defs", "content_version"]: copy.set(key, c.get(key))
	copy.processing_catalog = c.processing_catalog.duplicate(true)
	copy.processing_catalog.econ_r1 = research.duplicate(false)
	copy.processing_catalog.econ_r1["stage"] = 6 if frontier(c) else 4 if late(c) else 3 # ephemeral; not profile research state.
	return copy

static func recipe_gate(state: GameState, catalog: Dictionary, id: String) -> String:
	if not catalog.has("econ_r1"): return ""
	if int(catalog.econ_r1.get("stage", 3)) >= 6 and FRONTIER_GATES.has(id):
		if not catalog.econ_r1.completed.has(FRONTIER_GATES[id]): return "RESEARCH_REQUIRED:" + FRONTIER_GATES[id]
		return "" if int(state.buildings.get("craft_workshop", 0)) >= 1 and IslandEconomy.hub(state) else "FACILITY_REQUIREMENT"
	if id == "stone_mid_bulk" and int(catalog.econ_r1.get("stage", 3)) >= 4:
		if not catalog.econ_r1.completed.has("R08"): return "RESEARCH_REQUIRED:R08"
		return "" if int(state.buildings.get("craft_workshop", 0)) >= 1 and IslandEconomy.hub(state) else "FACILITY_REQUIREMENT"
	if id != "foundation_pill" and not RECIPE_GATES.has(id): return "ECON_SLICE_NOT_AVAILABLE"
	if id == "foundation_pill": return ""
	if not catalog.econ_r1.completed.has(RECIPE_GATES[id]): return "RESEARCH_REQUIRED:" + RECIPE_GATES[id]
	if not IslandEconomy.hub(state): return "HUB_REQUIRED"
	if int(state.buildings.get("craft_workshop", 0)) < 1: return "FACILITY_REQUIREMENT"
	return ""

static func guard(c: GameContent, state: GameState, kind: String, p: Dictionary) -> String:
	if not active(c): return ""
	var completed: Dictionary = c.processing_catalog.econ_r1.completed
	if kind == "breakthrough_era" and state.era_id >= (6 if frontier(c) else 4 if late(c) else 3): return "ECON_SLICE_NOT_AVAILABLE"
	if kind == "open_island" and not frontier(c) and p.get("island_id") in (["ancient", "void"] if late(c) else ["deep", "ancient", "void"]): return "ECON_SLICE_NOT_AVAILABLE"
	if kind in ["craft", "switch_processing", "refine_pill"]:
		return recipe_gate(state, c.processing_catalog, String(p.get("recipe_id", p.get("pill_id", ""))))
	var required := ""
	if kind == "level_up_cultivation" and state.era_id == 2 and state.level >= 5: required = "R03"
	if kind == "upgrade_building":
		var id := String(p.get("building_id", ""))
		if c.buildings.has(id) and int(c.buildings[id].era) > (6 if frontier(c) else 4 if late(c) else 3): return "ECON_SLICE_NOT_AVAILABLE"
		if id == "craft_workshop": required = "R01" if int(state.buildings.get(id, 0)) == 0 else "R03"
		if id == "core_storehouse_3": required = "R04"
		if late(c): required = {"mineral_focus":"R09", "core_storehouse_4":"R10", "cultivation_focus_4":"R08"}.get(id, required)
	if kind == "upgrade_building" and frontier(c): required = FRONTIER_BUILDINGS.get(String(p.get("building_id", "")), required)
	if kind == "upgrade_island_facility":
		required = {"workshop":"R03", "extractor":"R03", "storage":"R04"}.get(p.get("facility_id"), "")
	if not required.is_empty() and not completed.has(required): return "RESEARCH_REQUIRED:" + required
	return ""

static func effect(id: String, family: String, scope: String, value: float) -> Dictionary:
	return {"effect_id":id, "family":family, "scope":scope, "unit":"reduction", "stack_mode":"sum_then_dr", "limit":EconomyEffects.LIMITS[family], "source":id, "value":value}

static func building_quote(c: GameContent, state: GameState, id: String) -> Dictionary:
	var d: Dictionary = c.buildings[id]
	var level := int(state.buildings.get(id, 0))
	var base := BuildingCosts.resolve_base_cost(id, d.base_cost, Onboarding.is_active(state.onboarding_version, state.era_id))
	if id == "craft_workshop" and level == 1: base = {"spirit_timber":5, "bronze_essence":5}
	var costs := BuildingCosts.compute_cost(base, level, float(d.cost_factor))
	var sources: Array = []
	if (id.begins_with("storage_") or id == "core_storehouse_3") and c.processing_catalog.econ_r1.completed.has("R04"):
		sources.append(effect("R04", "building_cost", id, 0.1))
	var reduction := EconomyEffects.resolve("building_cost", id, sources)
	for resource in costs:
		var q := EconomyEffects.cost(costs[resource], 1, resource in DISCRETE, reduction)
		if not q.ok: return q
		costs[resource] = q.amount
	return {"ok":true, "costs":costs, "effect":reduction}

static func inputs(state: GameState, catalog: Dictionary, island: String, recipe: String) -> Dictionary:
	var result := {}
	var sources: Array = []
	# Legacy late-game skill is represented once, rather than discounted before DR.
	if island == "home" and recipe in SksP2Rules.DISCOUNT_RECIPE_IDS:
		sources.append(effect("heavenly_craft", "processing_cost", recipe, 1.0 - SksP2Rules.lingli_discount_multiplier(state.skills)))
	for id in catalog.recipes[recipe].inputs:
		var reduction := EconomyEffects.resolve("processing_cost", recipe, sources if id == "lingli" else [])
		var q := EconomyEffects.cost(AmountCompat.from_number(float(catalog.recipes[recipe].inputs[id])), 1, id in DISCRETE, reduction)
		result[id] = String.num(q.amount.to_float(), 6)
	return result

static func duration(state: GameState, catalog: Dictionary, lane: String, recipe: String) -> int:
	if not catalog.has("econ_r1"): return IslandProgression.duration(state, lane, recipe)
	var base: int = IslandEconomy.durations(state)[recipe]
	var level := int(state.economy.islands[lane].facilities.workshop)
	var sources: Array = [effect("island_workshop", "work_time", recipe, 1.0 - 1.0 / level)]
	if int(state.buildings.get("craft_workshop", 0)) >= 2: sources.append(effect("craft_workshop", "work_time", recipe, 0.2))
	if frontier_state(state) and int(state.buildings.get("void_condenser", 0)) > 0 and recipe in ["stone_mid", "stone_mid_bulk", "stone_high"]: sources.append(effect("void_condenser", "work_time", recipe, 0.3))
	var sect_seconds := SectSpecialization.duration(state, recipe, base)
	sources.append(effect("sect", "work_time", recipe, maxf(0.0, 1.0 - float(sect_seconds) / base)))
	return EconomyEffects.duration(base, EconomyEffects.resolve("work_time", recipe, sources)).seconds
