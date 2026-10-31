class_name SectSpecialization
extends RefCounted
## CORE-2 feature version, independent of the later whole-save reform migration.
const VERSION := 1
const METHODS := {
	"taixu_inner_cycle": ["taixu_sect", "A", "太虛內景經"],
	"taixu_qi_spring": ["taixu_sect", "B", "靈泉歸元訣"],
	"tianjian_ore_vein": ["tianjian_sect", "A", "金脈識真訣"],
	"tianjian_forge_rhythm": ["tianjian_sect", "B", "百煉合鋒法"],
	"piaomiao_herb_garden": ["piaomiao_sect", "A", "百草辨靈經"],
	"piaomiao_pill_measure": ["piaomiao_sect", "B", "丹衡惜材法"],
	"wanfo_life_lamp": ["wanfo_sect", "A", "蓮燈養命經"],
	"wanfo_enduring_body": ["wanfo_sect", "B", "金身長養法"],
	"zixiao_spirit_vessel": ["zixiao_sect", "A", "紫府納靈陣"],
	"zixiao_material_vault": ["zixiao_sect", "B", "玄門藏材陣"],
}
const A_CONTRIBUTION := [80, 120, 180, 270, 405]
const B_CONTRIBUTION := [120, 180, 270, 405, 608]
const A_STONE := [5, 8, 12, 17, 26]
const B_STONE := [10, 15, 23, 34, 51]
const FORGE := ["bronze_essence", "stone_mid", "stone_mid_bulk", "stone_high", "talisman", "formation_core"]
const MATERIALS := ["wood", "stone_low", "black_copper", "spirit_timber", "bronze_essence", "liquid", "formation_core"]
const GATHER := {"ore": ["stone_low", "black_copper"], "deep": ["refined_iron", "mithril", "cold_iron"], "herb": ["spirit_grass_low", "spirit_grass_100y"], "ancient": ["spirit_grass_1000y"]}

static func level(state: GameState, id: String) -> int:
	if state == null or not METHODS.has(id) or state.sect.get("techniques_version", 0) != VERSION: return 0
	var definition: Array = METHODS[id]
	if SectIdentity.view(state.sect).sect_id != definition[0]: return 0
	var is_a: bool = definition[1] == "A"
	if state.era_id < (2 if is_a else 3): return 0
	return clampi(int(state.sect.get("techniques", {}).get(id, 0)), 0, 5 if state.era_id >= (4 if is_a else 5) else 3)

static func signature(state: GameState) -> Array:
	return [state.era_id, SectIdentity.view(state.sect).sect_id, state.sect.get("techniques_version", 0), state.sect.get("techniques", {}).duplicate(true), state.sect.get("lineage", {}).get("learned", {}).duplicate(true)]

static func view(state: GameState) -> Dictionary:
	var result := {}
	for id in METHODS:
		result[id] = {"name": METHODS[id][2], "sect_id": METHODS[id][0], "group": METHODS[id][1], "max_level": 5,
			"learned_level": int(state.sect.get("techniques", {}).get(id, 0)), "active_level": level(state,id), "requirements": requirements(state,id)}
	return result

static func requirements(state: GameState, id: String) -> Dictionary:
	if state == null or not METHODS.has(id): return {"ok": false, "error": "UNKNOWN_TECHNIQUE"}
	if SectIdentity.view(state.sect).sect_id != METHODS[id][0]: return {"ok": false, "error": "TECHNIQUE_SECT_REQUIRED"}
	if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	var current := int(state.sect.get("techniques", {}).get(id, 0))
	if current >= 5: return {"ok": false, "error": "TECHNIQUE_MAX_LEVEL"}
	var is_a: bool = METHODS[id][1] == "A"
	var era := (2 if current < 3 else 4) if is_a else (3 if current < 3 else 5)
	if state.era_id < era: return {"ok": false, "error": "TECHNIQUE_ERA_LOCKED"}
	if not is_a:
		var prerequisite: String = ""
		for candidate in METHODS:
			if METHODS[candidate][0] == METHODS[id][0] and METHODS[candidate][1] == "A": prerequisite = candidate
		if int(state.sect.get("techniques", {}).get(prerequisite, 0)) < (3 if current < 3 else 5):
			return {"ok": false, "error": "TECHNIQUE_PREREQUISITE"}
	var contribution: int = (A_CONTRIBUTION if is_a else B_CONTRIBUTION)[current]
	var stone: int = (A_STONE if is_a else B_STONE)[current]
	var held := AmountCompat.try_parse(String(state.sect.get("contribution", "0")))
	if not held.ok or held.value.compare_to(AmountCompat.from_number(contribution)) < 0: return {"ok": false, "error": "INSUFFICIENT_CONTRIBUTION"}
	var available: AmountCompat = state.resources.get("stone_low", {}).get("value", AmountCompat.zero())
	if available.compare_to(AmountCompat.from_number(stone)) < 0: return {"ok": false, "error": "INSUFFICIENT_STONE"}
	return {"ok": true, "next_level": current + 1, "contribution": contribution, "stone_low": stone}

static func learn(state: GameState, id: String) -> Dictionary:
	var req := requirements(state, id)
	if not req.ok: return req
	state.sect.contribution = AmountCompat.try_parse(state.sect.contribution).value.subtract(AmountCompat.from_number(req.contribution)).serialize()
	var entry: Dictionary = state.resources.stone_low
	entry.value = ResourceLedger.change(state, "home", "stone_low", entry.value, (entry.value as AmountCompat).subtract(AmountCompat.from_number(req.stone_low)), "sect")
	state.sect.techniques[id] = req.next_level
	state.sect.techniques_version = VERSION
	return {"ok": true, "technique_id": id, "new_level": req.next_level, "events": [{"kind": "technique_learned", "technique_id": id, "level": req.next_level}]}

static func capacity_bonus(state: GameState, id: String) -> float:
	if id == "lingli": return 0.04 * level(state, "zixiao_spirit_vessel") + SectLineage.bonus(state, "zixiao") + GuardianBeasts.bonus(state, "capacity")
	return 0.04 * level(state, "zixiao_material_vault") if id in MATERIALS else 0.0

static func gather_bonus(state: GameState, island: String, id: String) -> float:
	if id not in GATHER.get(island, []): return 0.0
	var sect_bonus := (0.04 * level(state, "tianjian_ore_vein") + SectLineage.bonus(state, "tianjian")) if island in ["ore", "deep"] else (0.04 * level(state, "piaomiao_herb_garden") + SectLineage.bonus(state, "piaomiao"))
	return sect_bonus + GuardianBeasts.gather_bonus(state, island, id)

static func duration(state: GameState, recipe: String, base: int) -> int:
	return maxi(1, int(ceil(base / (1.0 + 0.03 * level(state, "tianjian_forge_rhythm"))))) if recipe in FORGE else base

static func pill_discount_level(state: GameState, pill: String, material: String) -> int:
	var eligible := material == "spirit_grass_low" and pill in ["cultivation_pill", "wood_nurture_pill", "wealth_gathering_pill", "qi_absorption_pill", "lifespan_pill"]
	eligible = eligible or (pill == "tribulation_pill" and material == "spirit_grass_100y")
	return level(state, "piaomiao_pill_measure") if eligible else 0
