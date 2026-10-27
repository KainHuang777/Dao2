class_name StoryProgressP2
extends RefCounted
## Y: bounded successful-action facts, separate from P1 facts and retained ledgers.
const MASKS := {"refined_mask":255, "consumed_mask":255, "arrival_mask":31, "task_mask":1023, "market_mask":3, "mature_mask":15}
const ARRIVALS := ["deep_iron_home", "deep_mithril_home", "deep_cold_home", "ancient_grass_home", "void_essence_home"]
const TASKS := ["deep_stock_register", "ancient_dew_register", "silver_convoy_accounts", "ancient_herb_sorting", "cold_iron_assay", "ancient_pill_herb_catalog", "void_supply_chart", "tribulation_material_check", "turtle_nursery_reserve", "phoenix_nursery_reserve"]
const MARKET := ["refined_iron_reserve", "ancient_herb_reserve"]
const BEASTS := ["frost_stag", "herb_crane", "iron_turtle", "fire_phoenix"]
const TALENTS := ["elixir_conservation_memory", "frontier_prospector_memory", "sacred_beast_nurture_memory"]
const REQUIRES := ["deep_open", "ancient_open", "void_open", "deep_arrived", "ancient_arrived", "void_arrived", "joined_sect", "p2_task_claimed", "p2_refined", "p2_consumed", "second_life", "any_p2_talent", "active_stag", "active_crane", "active_phoenix"]

static func blank() -> Dictionary:
	var result := {}
	for key in MASKS: result[key] = 0
	return result

static func initial(state: GameState) -> Dictionary:
	return {"started_life_id":state.reincarnation_count + 1, "started_age_seconds":state.total_elapsed_seconds, "lifetime":blank(), "current":blank()}

static func facts(state: GameState, lifetime: bool = false) -> Dictionary:
	return state.achievements.get("story", {}).get("p2", {}).get("lifetime" if lifetime else "current", blank())

static func mark_id(state: GameState, key: String, order: Array, id: String) -> void:
	var index := order.find(id)
	if state.story_version != 2 or index < 0: return
	var p2: Dictionary = StoryProgress.ensure(state).p2
	for field in ["lifetime", "current"]: p2[field][key] = int(p2[field][key]) | (1 << index)
	StoryProgress.unlock_available(state)

static func pill(state: GameState, id: String, consumed: bool) -> void:
	mark_id(state, "consumed_mask" if consumed else "refined_mask", AlchemySystem.P2_IDS, id)

static func observe_mature(state: GameState) -> void:
	var active: Dictionary = state.beasts.get("active", {})
	if active.get("stage") == "mature": mark_id(state, "mature_mask", BEASTS, str(active.get("id", "")))

static func qualifications(state: GameState) -> Dictionary:
	var f := facts(state)
	var islands: Dictionary = state.economy.get("islands", {})
	var active: String = state.beasts.get("active", {}).get("id", "")
	var talent := false
	for id in TALENTS: talent = talent or int(state.talents.get(id, 0)) >= 1
	return {"deep_open":bool(islands.get("deep", {}).get("opened", false)), "ancient_open":bool(islands.get("ancient", {}).get("opened", false)), "void_open":bool(islands.get("void", {}).get("opened", false)), "deep_arrived":int(f.arrival_mask) & 7 != 0, "ancient_arrived":int(f.arrival_mask) & 8 != 0, "void_arrived":int(f.arrival_mask) & 16 != 0, "joined_sect":not str(state.sect.get("current_sect", "")).is_empty(), "p2_task_claimed":int(f.task_mask) != 0, "p2_refined":int(f.refined_mask) != 0, "p2_consumed":int(f.consumed_mask) != 0, "second_life":state.reincarnation_count >= 1, "any_p2_talent":talent, "active_stag":active == "frost_stag", "active_crane":active == "herb_crane", "active_phoenix":active == "fire_phoenix"}

static func achievement_met(state: GameState, id: String) -> bool:
	if state.story_version != 2: return false
	var f := facts(state, true)
	match id:
		"p2_deep_student": return int(state.skills.get("deep_vein_resonance", 0)) >= 1
		"p2_herb_student": return int(state.skills.get("ancient_herb_attunement", 0)) >= 1 and int(state.skills.get("spirit_sea_breath", 0)) >= 1
		"p2_void_storekeeper": return int(state.skills.get("void_essence_attunement", 0)) >= 1 and int(state.skills.get("frontier_storekeeping", 0)) >= 1
		"p2_deep_arrivals": return int(f.arrival_mask) & 7 == 7
		"p2_ancient_arrival": return int(f.arrival_mask) & 8 != 0
		"p2_void_arrival": return int(f.arrival_mask) & 16 != 0
		"p2_training_alchemist": return int(f.refined_mask) & 3 == 3
		"p2_local_elixirs": return int(f.consumed_mask) & 12 == 12
		"p2_vessels_and_wards": return int(f.consumed_mask) & 240 == 240
		"p2_frontier_commissions": return int(f.task_mask) & 405 != 0 and int(f.task_mask) & 554 != 0 and int(f.task_mask) & 64 != 0
		"p2_two_sect_methods": return int(state.sect.get("techniques", {}).get("p2_pill_qi_conservation", 0)) >= 1 and int(state.sect.get("techniques", {}).get("sacred_beast_feed_conservation", 0)) >= 1
		"p2_two_reserves": return int(f.market_mask) == 3
		"p2_mature_stag": return int(f.mature_mask) & 1 != 0 or _active_mature(state, "frost_stag")
		"p2_mature_crane": return int(f.mature_mask) & 2 != 0 or _active_mature(state, "herb_crane")
		"p2_turtle_and_phoenix": return int(f.mature_mask) & 12 == 12
		"p2_second_nascent": return state.reincarnation_count >= 1 and state.era_id >= 4
		"p2_second_void": return state.reincarnation_count >= 1 and state.era_id >= 6
		"p2_three_memories":
			for talent in TALENTS:
				if int(state.talents.get(talent, 0)) < 1: return false
			return true
	return false

static func _active_mature(state: GameState, id: String) -> bool:
	return state.beasts.get("active", {}).get("id", "") == id and state.beasts.get("active", {}).get("stage", "") == "mature"

static func validate(state: GameState, story: Dictionary) -> String:
	var p2: Variant = story.get("p2")
	if not p2 is Dictionary or not LifeLedger._keys(p2, ["started_life_id", "started_age_seconds", "lifetime", "current"]): return "STORY_P2_KEYS"
	if not SectSaveContract.integer(p2.get("started_life_id"), state.reincarnation_count + 1) or int(p2.started_life_id) < 1 or int(p2.started_life_id) < int(story.started_life_id): return "STORY_P2_START_LIFE"
	if not SectSaveContract.number(p2.get("started_age_seconds")) or (int(p2.started_life_id) == state.reincarnation_count + 1 and float(p2.started_age_seconds) > state.total_elapsed_seconds): return "STORY_P2_START_AGE"
	for field in ["lifetime", "current"]:
		if not p2.get(field) is Dictionary or not LifeLedger._keys(p2[field], MASKS.keys()): return "STORY_P2_FACT_KEYS"
		for key in MASKS:
			if not SectSaveContract.integer(p2[field].get(key), MASKS[key]): return "STORY_P2_MASK"
	for key in MASKS:
		if int(p2.current[key]) | int(p2.lifetime[key]) != int(p2.lifetime[key]): return "STORY_P2_SUBSET"
	return ""
