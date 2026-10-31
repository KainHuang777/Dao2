class_name GuardianBeasts
extends RefCounted
## Five-species growth/effects shared by isolated contracts and the complete
## beast2 release. Acquisition authority belongs to the validated permit ledger.
const VERSION := 2
const SPECIES := {
	"taixu_baize": ["太虛白澤", "baize", "cultivation", 0.04],
	"tianjian_suanni": ["天劍狻猊", "suanni", "ore", 0.08],
	"piaomiao_jade_hare": ["縹緲芝靈兔", "hare", "herb", 0.08],
	"wanfo_lotus_elephant": ["萬佛蓮心象", "elephant", "lifespan", 0.04],
	"zixiao_star_tapir": ["紫霄星紋貘", "tapir", "capacity", 0.08],
}
const TALENTS := {
	"baize_t1_resonance": ["taixu_baize", 1], "baize_t2_growth": ["taixu_baize", 2],
	"baize_t3_feed": ["taixu_baize", 3], "baize_t4_memory": ["taixu_baize", 4],
	"suanni_t1_resonance": ["tianjian_suanni", 1], "suanni_t2_growth": ["tianjian_suanni", 2],
	"suanni_t3_feed": ["tianjian_suanni", 3], "suanni_t4_memory": ["tianjian_suanni", 4],
	"hare_t1_resonance": ["piaomiao_jade_hare", 1], "hare_t2_growth": ["piaomiao_jade_hare", 2],
	"hare_t3_feed": ["piaomiao_jade_hare", 3], "hare_t4_memory": ["piaomiao_jade_hare", 4],
	"elephant_t1_resonance": ["wanfo_lotus_elephant", 1], "elephant_t2_growth": ["wanfo_lotus_elephant", 2],
	"elephant_t3_feed": ["wanfo_lotus_elephant", 3], "elephant_t4_memory": ["wanfo_lotus_elephant", 4],
	"tapir_t1_resonance": ["zixiao_star_tapir", 1], "tapir_t2_growth": ["zixiao_star_tapir", 2],
	"tapir_t3_feed": ["zixiao_star_tapir", 3], "tapir_t4_memory": ["zixiao_star_tapir", 4],
}
const COSTS := [1, 2, 3, 5]
const SUFFIXES := ["_t1_resonance", "_t2_growth", "_t3_feed", "_t4_memory"]

static func owns(state: GameState, id: String, tier: int) -> bool:
	if state == null or state.beast_version != VERSION or not SPECIES.has(id) or tier < 1 or tier > 4: return false
	return state.beast_talents.get(String(SPECIES[id][1]) + SUFFIXES[tier - 1], 0) == 1

## Permit ownership must come from the eventual validated permanent permit
## ledger. It is an input to this isolated rule, never a player command field.
static func acquire_requirements(state: GameState, id: String, permit_owned: bool) -> Dictionary:
	if not SPECIES.has(id): return {"ok": false, "error": "UNKNOWN_BEAST"}
	if state.beast_version != VERSION: return {"ok": false, "error": "GUARDIAN_SAVE_REQUIRED"}
	if not state.beasts.get("active", {}).is_empty(): return {"ok": false, "error": "ALREADY_HAS_ACTIVE_BEAST"}
	if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	if state.era_id < 3: return {"ok": false, "error": "INSUFFICIENT_ERA", "required_era": 3}
	if not state.economy.get("islands", {}).get("herb", {}).get("opened", false): return {"ok": false, "error": "ISLAND_NOT_OPEN", "island": "herb"}
	if not permit_owned: return {"ok": false, "error": "GUARDIAN_PERMIT_REQUIRED"}
	return {"ok": true}

static func feed_costs(state: GameState, id: String) -> Dictionary:
	if not SPECIES.has(id): return {}
	return {"spirit_grass_low": 30 if owns(state, id, 3) else 50}

static func feed_xp(state: GameState, id: String) -> int:
	if not SPECIES.has(id): return 0
	return (65 if owns(state, id, 2) else 50) + (10 if owns(state, id, 4) else 0)

static func feed(state: GameState) -> Dictionary:
	var active: Dictionary = state.beasts.get("active", {})
	var id := String(active.get("id", ""))
	if not SPECIES.has(id): return {"ok": false, "error": "UNKNOWN_BEAST"}
	if state.beast_version != VERSION: return {"ok": false, "error": "GUARDIAN_SAVE_REQUIRED"}
	if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	if active.get("stage") == "mature": return {"ok": false, "error": "BEAST_ALREADY_MATURE"}
	if float(state.beasts.get("cooldown_remaining", 0)) > 0.0001: return {"ok": false, "error": "FEED_ON_COOLDOWN"}
	var cost: int = feed_costs(state, id).spirit_grass_low
	var held: AmountCompat = state.resources.get("spirit_grass_low", {}).get("value", AmountCompat.zero())
	if held.compare_to(AmountCompat.from_number(cost)) < 0: return {"ok": false, "error": "INSUFFICIENT_FEED_RESOURCE", "resource_id": "spirit_grass_low", "required": cost}
	var xp := feed_xp(state, id)
	var old_stage := String(active.stage)
	var total := int(active.exp) + xp
	var stage := "egg" if total < 100 else "young" if total < 500 else "growing" if total < 1000 else "mature"
	state.resources.spirit_grass_low.value = ResourceLedger.change(state, "home", "spirit_grass_low", held, held.subtract(AmountCompat.from_number(cost)), "beast")
	active.exp = total
	active.stage = stage
	state.beasts.cooldown_remaining = BeastSystem.BASE_COOLDOWN
	var events: Array = [{"kind": "beast_fed", "beast_id": id, "exp_gained": xp, "total_exp": total, "stage": stage, "costs": feed_costs(state, id)}]
	if old_stage != stage: events.append({"kind": "beast_stage_up", "beast_id": id, "previous_stage": old_stage, "new_stage": stage})
	return {"ok": true, "beast": active, "exp_gained": xp, "stage": stage, "events": events}

static func unlock(state: GameState, talent_id: String) -> Dictionary:
	if not TALENTS.has(talent_id): return {"ok": false, "error": "UNKNOWN_BEAST_TALENT"}
	if state.beast_version != VERSION: return {"ok": false, "error": "GUARDIAN_SAVE_REQUIRED"}
	if not SectSystem.p2_life_error(state).is_empty(): return {"ok": false, "error": "LIFESPAN_EXHAUSTED"}
	var id: String = TALENTS[talent_id][0]
	var tier: int = TALENTS[talent_id][1]
	if owns(state, id, tier): return {"ok": false, "error": "TALENT_ALREADY_UNLOCKED"}
	if tier > 1 and not owns(state, id, tier - 1): return {"ok": false, "error": "PREV_TIER_REQUIRED"}
	var held := int(state.beast_souls.get(id, 0))
	var cost: int = COSTS[tier - 1]
	if held < cost: return {"ok": false, "error": "INSUFFICIENT_BEAST_SOULS"}
	state.beast_souls[id] = held - cost
	state.beast_talents[talent_id] = 1
	return {"ok": true, "talent_id": talent_id, "remaining_souls": held - cost, "events": [{"kind": "beast_talent_unlocked", "talent_id": talent_id, "beast_id": id, "tier": tier}]}

static func bonus(state: GameState, axis: String) -> float:
	if state == null or state.beast_version != VERSION: return 0.0
	var active: Dictionary = state.beasts.get("active", {})
	var id := String(active.get("id", ""))
	if not SPECIES.has(id) or SPECIES[id][2] != axis: return 0.0
	var stage := float(BeastSystem.STAGE_CONFIGS.get(active.get("stage", "egg"), {}).get("multiplier", 0.0))
	if stage <= 0: return 0.0
	return float(SPECIES[id][3]) * (stage + (0.05 if owns(state, id, 1) else 0.0))

static func gather_bonus(state: GameState, island: String, id: String) -> float:
	if id not in SectSpecialization.GATHER.get(island, []): return 0.0
	return bonus(state, "ore" if island in ["ore", "deep"] else "herb")
