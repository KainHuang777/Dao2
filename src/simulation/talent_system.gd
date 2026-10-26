class_name TalentSystem
extends RefCounted

const VERSION := 3
const P2_IDS := ["elixir_conservation_memory", "frontier_prospector_memory", "sacred_beast_nurture_memory"]
const P1_IDS := ["alchemical_past_wisdom", "artisan_past_wisdom", "beast_bond_past_wisdom"]
const FRONTIER_RESOURCES := {"deep":["refined_iron", "mithril", "cold_iron"], "ancient":["spirit_grass_1000y"], "void":["void_essence"]}
const ARTISAN_BUILDINGS := ["wooden_house", "forest_farm", "stone_mine", "herb_farm"]

const TALENTS := {
	"resource_inheritance": {
		"id": "resource_inheritance",
		"name": "資源傳承",
		"max_level": 10,
		"base_cost": 5,
		"cost_factor": 2.0,
		"description": "每級使轉世開局已解鎖的基礎資源獲得新庫容 10%；下次轉世生效",
	},
	"lifespan_extension": {
		"id": "lifespan_extension",
		"name": "長生久視",
		"max_level": 10,
		"base_cost": 10,
		"cost_factor": 2.0,
		"description": "每級使修行壽元上限比例提升 10%",
	},
	"innate_dao_body": {
		"id": "innate_dao_body",
		"name": "先天道體",
		"max_level": 10,
		"base_cost": 15,
		"cost_factor": 2.0,
		"description": "每級使修行進度積累速度提升 10%",
	},
	"alchemical_past_wisdom": {
		"id": "alchemical_past_wisdom", "name": "丹心宿慧", "max_level": 5, "base_cost": 5, "cost_factor": 2.0,
		"description": "每階使聚靈丹／上品聚靈丹修煉收益 +10%；衰減後計算，受當層上限限制。購入即生效、跨世保留，不追補已服丹",
	},
	"artisan_past_wisdom": {
		"id": "artisan_past_wisdom", "name": "百工宿慧", "max_level": 5, "base_cost": 5, "cost_factor": 2.0,
		"description": "每階使祖島木屋／林場／採石場／靈植場的產率貢獻 +8%；不含庫容、茅屋、產點與遠島。購入即生效、跨世保留，需重建設施",
	},
	"beast_bond_past_wisdom": {
		"id": "beast_bond_past_wisdom", "name": "靈契宿慧", "max_level": 5, "base_cost": 5, "cost_factor": 2.0,
		"description": "每階使靈狐餵養經驗 +20%；與獸魂成長加數相加，草料／冷卻／成熟上限不變。購入即生效、跨世保留，不追補已餵經驗",
	},
	"elixir_conservation_memory": {"id":"elixir_conservation_memory", "name":"丹材宿慧", "max_level":5, "base_cost":10, "cost_factor":2.0, "description":"每階省延壽丹低階草／渡劫丹百年草4%；只折直接草費，不改其他材料與丹效；需已輪迴且最高元嬰，購入即生效、跨世保留"},
	"frontier_prospector_memory": {"id":"frontier_prospector_memory", "name":"拓脈宿慧", "max_level":5, "base_cost":10, "cost_factor":2.0, "description":"每階使寒銀／古藥／太虛島指定採集產率+10%；未開島收益0，不改庫容與航運；需已輪迴且最高元嬰，購入即生效、跨世保留"},
	"sacred_beast_nurture_memory": {"id":"sacred_beast_nurture_memory", "name":"玄靈宿慧", "max_level":5, "base_cost":10, "cost_factor":2.0, "description":"每階使玄龜／火鳳每餵經驗+10；火鳳仍須Era6，不改餵費與冷卻；需已輪迴且最高元嬰，購入即生效、跨世保留"},
}

static func get_definition(talent_id: String) -> Variant:
	return TALENTS.get(talent_id, null)

static func view(state: GameState) -> Dictionary:
	var options := {}
	for id in TALENTS:
		var eligibility := can_learn(state, id)
		options[id] = {"can_learn":bool(eligibility.get("can_learn", false)), "reason":String(eligibility.get("reason", ""))}
	return options

static func get_cost(talent_id: String, current_level: int) -> AmountCompat:
	var def: Variant = get_definition(talent_id)
	if def == null:
		return AmountCompat.zero()
	var base_cost: float = float(def["base_cost"])
	var factor: float = float(def["cost_factor"])
	var cost_val: float = floor(base_cost * pow(factor, float(current_level)))
	return AmountCompat.from_number(cost_val)

static func can_learn(state: GameState, talent_id: String) -> Dictionary:
	var invalid := validate_state(state)
	if not invalid.is_empty():
		return {"can_learn": false, "reason": invalid}
	var def: Variant = get_definition(talent_id)
	if def == null:
		return {"can_learn": false, "reason": "UNKNOWN_TALENT"}
	var cur_level: int = int(state.talents.get(talent_id, 0))
	if (talent_id in P1_IDS and state.talent_version < 2) or (talent_id in P2_IDS and state.talent_version < VERSION):
		return {"can_learn": false, "reason": "TALENT_VERSION"}
	if talent_id in P2_IDS:
		if state.reincarnation_count < 1: return {"can_learn":false, "reason":"TALENT_REINCARNATION_REQUIRED"}
		if state.highest_era < 4: return {"can_learn":false, "reason":"TALENT_HIGHEST_ERA_REQUIRED"}
	var max_level: int = int(def["max_level"])
	if cur_level >= max_level:
		return {"can_learn": false, "reason": "TALENT_MAX_LEVEL"}
	var cost: AmountCompat = get_cost(talent_id, cur_level)
	if state.dao_heart.compare_to(cost) < 0:
		return {
			"can_learn": false,
			"reason": "INSUFFICIENT_DAO_HEART",
			"required": cost.serialize(),
			"current": state.dao_heart.serialize(),
		}
	return {"can_learn": true, "cost": cost, "next_level": cur_level + 1}


static func learn(state: GameState, talent_id: String) -> Dictionary:
	var check := can_learn(state, talent_id)
	if not bool(check.get("can_learn", false)):
		return {
			"ok": false,
			"error": String(check.get("reason", "CANNOT_LEARN")),
			"events": [],
			"changed_ids": [],
			"detail": check,
		}
	var cost: AmountCompat = check["cost"]
	state.dao_heart = state.dao_heart.subtract(cost)
	var next_level: int = int(check["next_level"])
	state.talents[talent_id] = next_level
	var event := {
		"kind": "talent_learned",
		"talent_id": talent_id,
		"new_level": next_level,
		"cost": cost.serialize(),
		"remaining_dao_heart": state.dao_heart.serialize(),
	}
	return {
		"ok": true,
		"events": [event],
		"changed_ids": ["dao_heart", "talents"],
	}

static func compute_multipliers(state: GameState) -> Dictionary:
	var dh_val := state.dao_heart.to_float() if state.dao_heart != null else 0.0
	var dao_heart_bonus := 0.15 * (log(dh_val + 1.0) / log(10.0))
	var dp_val := float(state.dao_proof)
	var dao_proof_bonus := 0.05 * sqrt(dp_val)
	var lifespan_bonus := float(state.talents.get("lifespan_extension", 0)) * 0.1
	var innate_bonus := float(state.talents.get("innate_dao_body", 0)) * 0.1
	var inheritance_bonus := float(state.talents.get("resource_inheritance", 0)) * 0.1
	return {
		"dao_heart_bonus": dao_heart_bonus,
		"dao_proof_bonus": dao_proof_bonus,
		"lifespan_bonus": lifespan_bonus,
		"cultivation_speed_bonus": innate_bonus,
		"resource_inheritance_bonus": inheritance_bonus,
		"global_production_multiplier": 1.0 + dao_heart_bonus,
	}

static func validate(version: int, talents: Dictionary) -> String:
	if version not in [1, 2, VERSION]: return "TALENT_VERSION"
	if talents.size() > TALENTS.size(): return "TALENT_LIMIT"
	for id in talents:
		if not id is String or not TALENTS.has(id): return "TALENT_ID"
		if (version == 1 and id in P1_IDS) or (version < 3 and id in P2_IDS): return "TALENT_VERSION"
		var value: Variant = talents[id]
		if not (value is int or value is float): return "TALENT_LEVEL"
		if not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 0 or float(value) > float(TALENTS[id].max_level): return "TALENT_LEVEL"
	return ""

static func reconcile(state: GameState) -> bool:
	if not validate_state(state).is_empty(): return false
	if state.talent_version == VERSION: return false
	state.talent_version = VERSION
	return true

static func p1_bonus(talents: Dictionary, id: String) -> float:
	var per_rank := 0.1 if id == "alchemical_past_wisdom" else (0.08 if id == "artisan_past_wisdom" else 0.2)
	return float(clampi(int(talents.get(id, 0)), 0, 5)) * per_rank

static func pill_multiplier(state: GameState, pill_id: String) -> float:
	return 1.0 + p1_bonus(state.talents, "alchemical_past_wisdom") if pill_id in ["cultivation_pill", "high_cultivation_pill"] else 1.0

static func validate_state(state: GameState) -> String:
	var invalid := validate(state.talent_version, state.talents)
	if not invalid.is_empty(): return invalid
	for id in P2_IDS:
		if int(state.talents.get(id, 0)) > 0:
			if state.reincarnation_count < 1: return "TALENT_REINCARNATION_REQUIRED"
			if state.highest_era < 4: return "TALENT_HIGHEST_ERA_REQUIRED"
	return ""

static func herb_cost_multiplier(state: GameState, pill: String, resource: String) -> float:
	if state == null or state.talent_version < VERSION: return 1.0
	if (pill == "lifespan_pill" and resource == "spirit_grass_low") or (pill == "tribulation_pill" and resource == "spirit_grass_100y"):
		return 1.0 - 0.04 * int(state.talents.get("elixir_conservation_memory", 0))
	return 1.0

static func local_rate_multiplier(state: GameState, island: String, resource: String) -> float:
	if state.talent_version < VERSION: return 1.0
	if FRONTIER_RESOURCES.has(island) and resource in FRONTIER_RESOURCES[island]:
		return 1.0 + 0.1 * int(state.talents.get("frontier_prospector_memory", 0))
	return 1.0
