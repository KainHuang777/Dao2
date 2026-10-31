class_name StoryProgress
extends RefCounted
## R1/R2 fixed facts; independent of rendering, RNG and ledger retention.
const VERSION := 2
const LIFETIME := ["timber_completed", "timber_arrived", "bronze_arrived", "positive_home_arrival", "new_supply_claimed", "fox_matured"]
const CURRENT := ["timber_completed", "positive_home_arrival", "new_supply_claimed"]
const MASKS := ["refined_mask", "consumed_mask"]
const REQUIRES := ["wood_open", "timber_completed", "positive_home_arrival", "joined_sect", "new_supply_claimed", "refined_any_p1", "two_p1_consumed", "active_fox", "mature_active_fox", "second_life", "any_new_talent"]
const TALENTS := ["alchemical_past_wisdom", "artisan_past_wisdom", "beast_bond_past_wisdom"]

static func blank(keys: Array) -> Dictionary:
	var facts := {"refined_mask": 0, "consumed_mask": 0}
	for key in keys: facts[key] = false
	return facts

static func ensure(state: GameState) -> Dictionary:
	if not state.achievements.has("story"):
		state.achievements.story = {"version": state.story_version, "started_life_id": state.reincarnation_count + 1, "started_age_seconds": state.total_elapsed_seconds, "current_life_id": state.reincarnation_count + 1, "lifetime": blank(LIFETIME), "current": blank(CURRENT)}
	var story: Dictionary = state.achievements.story
	if state.story_version >= 2 and not story.has("p2"):
		story.version = 2
		story.p2 = StoryProgressP2.initial(state)
	return story

static func migrate(state: GameState) -> void:
	state.story_version = VERSION
	FortuneSystem.ensure_initialized(state)
	ensure(state)
	if mature_fox(state): mark(state, "fox_matured")
	StoryProgressP2.observe_mature(state)
	unlock_available(state)

static func next_life(state: GameState) -> void:
	# Legacy version-zero states must remain writable until explicit migration.
	if state.story_version < 1: return
	var story := ensure(state)
	story.current = blank(CURRENT)
	story.current_life_id = state.reincarnation_count + 1
	if state.story_version >= 2: story.p2.current = StoryProgressP2.blank()

static func mark(state: GameState, key: String) -> void:
	if state.story_version < 1: return
	var story := ensure(state)
	if key in LIFETIME: story.lifetime[key] = true
	if key in CURRENT: story.current[key] = true
	unlock_available(state)

static func pill(state: GameState, id: String, consumed: bool) -> void:
	var index := AlchemySystem.P1_IDS.find(id)
	StoryProgressP2.pill(state, id, consumed)
	if index < 0 or state.story_version < 1: return
	var story := ensure(state)
	var key := "consumed_mask" if consumed else "refined_mask"
	for facts in [story.lifetime, story.current]: facts[key] = int(facts[key]) | (1 << index)

static func completed(state: GameState, island: String, recipe: String) -> void:
	if island == "wood" and recipe == "spirit_timber": mark(state, "timber_completed")

static func arrived(state: GameState, route: String, delta: float) -> void:
	if delta <= 0 or not IslandEconomy.route_defs(state).has(route) or IslandEconomy.route_defs(state)[route][1] != "home": return
	StoryProgressP2.mark_id(state, "arrival_mask", StoryProgressP2.ARRIVALS, route)
	mark(state, "positive_home_arrival")
	if route == "timber_home": mark(state, "timber_arrived")
	if route == "bronze_home": mark(state, "bronze_arrived")

static func mature_fox(state: GameState) -> bool:
	return state.beasts.get("active", {}).get("id", "") == "jade_fox" and state.beasts.get("active", {}).get("stage", "") == "mature"

static func facts(state: GameState, lifetime: bool = false) -> Dictionary:
	return state.achievements.get("story", {}).get("lifetime" if lifetime else "current", blank(LIFETIME if lifetime else CURRENT))

static func qualifications(state: GameState) -> Dictionary:
	var current := facts(state)
	var mask := int(current.consumed_mask)
	var count := 0
	for bit in range(4):
		if mask & (1 << bit): count += 1
	var talent := false
	for id in TALENTS: talent = talent or int(state.talents.get(id, 0)) >= 1
	return {"wood_open": bool(state.economy.get("islands", {}).get("wood", {}).get("opened", false)), "timber_completed": current.timber_completed, "positive_home_arrival": current.positive_home_arrival, "joined_sect": bool(state.sect.get("unlocked", false)), "new_supply_claimed": current.new_supply_claimed, "refined_any_p1": int(current.refined_mask) > 0, "two_p1_consumed": count >= 2, "active_fox": state.beasts.get("active", {}).get("id", "") == "jade_fox", "mature_active_fox": mature_fox(state), "second_life": state.reincarnation_count >= 1, "any_new_talent": talent}

static func eligible(state: GameState, definition: Dictionary) -> bool:
	if state.story_version < 1 or state.current_realm != "realm_human" or state.era_id < int(definition.min_era): return false
	var q := StoryProgressP2.qualifications(state) if definition.get("content_batch") == "content-p2-story" else qualifications(state)
	if definition.get("content_batch") == "content-p2-story" and (state.story_version < 2 or not IslandEconomy.expanded(state)): return false
	for key in definition.requires:
		if not bool(q.get(key, false)): return false
	return true

static func achievement_met(state: GameState, id: String) -> bool:
	if state.story_version < 1: return false
	if id.begins_with("p2_"): return StoryProgressP2.achievement_met(state, id)
	var f := facts(state, true)
	match id:
		"p1_greenwood_student": return int(state.skills.get("greenwood_nourishment", 0)) >= 1
		"p1_golden_specialist": return int(state.skills.get("warehouse_preparation", 0)) >= 1 and int(state.skills.get("alchemical_breath_control", 0)) >= 1
		"p1_timber_workshop": return f.timber_completed
		"p1_homebound_cargo": return f.timber_arrived and f.bronze_arrived
		"p1_two_specialist_pills": return int(f.refined_mask) & 3 == 3
		"p1_four_pills_used": return int(f.consumed_mask) == 15
		"p1_supply_commission": return f.new_supply_claimed
		"p1_two_sect_specialties": return int(state.sect.get("techniques", {}).get("alchemy_herb_conservation", 0)) >= 1 and int(state.sect.get("techniques", {}).get("fox_feed_conservation", 0)) >= 1
		"p1_mature_jade_fox": return mature_fox(state) or f.fox_matured
		"p1_fox_soul_choice": return int(state.beast_talents.get("fox_t1_boost", 0)) >= 1
		"p1_second_foundation": return state.reincarnation_count >= 1 and state.era_id >= 2
		"p1_three_past_wisdoms":
			for talent in TALENTS:
				if int(state.talents.get(talent, 0)) < 1: return false
			return true
	return false

static func cap(state: GameState, content: GameContent, id: String) -> AmountCompat:
	var value: AmountCompat = Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version, state.skills).get(id, AmountCompat.zero())
	var copy := state.duplicate_state()
	var beast := BeastSystem.compute_multipliers(copy)
	var bonus := SectSpecialization.capacity_bonus(state, id) + float(SectSystem.compute_multipliers(copy).storage_bonus) + float(ChronoSystem.compute_multipliers(copy).storage_bonus) + float(beast.all_capacity_mult)
	if id in ["stone_low", "refined_iron"]: bonus += float(beast.cap_stone_iron)
	if bonus > 0: value = value.multiply(AmountCompat.from_number(1 + bonus))
	if not state.economy.is_empty() and content.processing_catalog.get("resources", {}).has(id):
		value = AmountCompat.from_number(IslandEconomy.home_cap(state, id, content.processing_catalog)) if IslandEconomy.expanded(state) else AmountCompat.from_number(minf(value.to_float(), float(content.processing_catalog.resources[id].cap)))
		value = value.subtract(AmountCompat.from_number(IslandEconomy.reserved(state, "home", id, content.processing_catalog)))
	return value if not state.economy.is_empty() and content.processing_catalog.get("resources", {}).has(id) and IslandEconomy.expanded(state) else Production.add_pill_capacity(state, id, value)

static func transaction_error(state: GameState, content: GameContent, costs: Dictionary, rewards: Dictionary, limits: Dictionary = {}) -> String:
	var ids := costs.duplicate()
	ids.merge(rewards.get("resources", {}))
	for id in ids:
		var before: AmountCompat = state.resources.get(id, {}).get("value", AmountCompat.zero())
		var paid := AmountCompat.from_number(float(costs.get(id, 0)))
		var gain := AmountCompat.from_number(float(rewards.get("resources", {}).get(id, 0)))
		if compare_exact(before, paid) < 0: return "INSUFFICIENT_RESOURCE:" + id
		var after_paid := before.subtract(paid)
		var after := after_paid.add(gain)
		if (paid.sign > 0 and compare_exact(before.subtract(after_paid), paid) != 0) or (gain.sign > 0 and compare_exact(after.subtract(after_paid), gain) != 0): return "STORY_AMOUNT_UNREPRESENTABLE"
		if gain.sign > 0:
			var limit: AmountCompat = limits[id] if limits.has(id) else cap(state, content, id)
			if compare_exact(after, limit) > 0: return "STORY_DESTINATION_FULL:" + id
	for id in rewards.get("pills", {}):
		if id in AlchemySystem.P1_IDS and int(state.pills.get(id, 0)) + int(rewards.pills[id]) > AlchemySystem.P1_INVENTORY_CAP: return "PILL_INVENTORY_LIMIT"
	return ""

static func compare_exact(a: AmountCompat, b: AmountCompat) -> int:
	# The generic approximate comparator permits cap+1 at large layer-zero stocks.
	# Fixed-price story transactions must reconcile the actual representable values.
	if a.sign != b.sign: return -1 if a.sign < b.sign else 1
	if a.sign == 0: return 0
	if a.layer != b.layer: return (-1 if a.layer < b.layer else 1) * a.sign
	return 0 if a.mag == b.mag else (-1 if a.mag < b.mag else 1) * a.sign

static func claim_error(state: GameState, content: GameContent, id: String, limits: Dictionary = {}) -> String:
	if id.begins_with("p2_"):
		var life_error := SectSystem.p2_life_error(state)
		if not life_error.is_empty(): return life_error
	var rewards: Dictionary = AchievementSystem.DEFINITIONS[id].rewards
	var error := transaction_error(state,content,{}, {"resources":rewards.get("resource",{})},limits)
	if not error.is_empty(): return error
	if rewards.has("sect_contribution"):
		var before := DecisionReceipt._amount(state.sect.get("contribution", "0"))
		var gain := AmountCompat.from_number(float(rewards.sect_contribution))
		if compare_exact(before.add(gain).subtract(before), gain) != 0: return "STORY_AMOUNT_UNREPRESENTABLE"
	return ""

static func claim(state: GameState, content: GameContent, id: String) -> Dictionary:
	var def: Dictionary = AchievementSystem.DEFINITIONS[id]
	var rewards: Dictionary = def.rewards
	var error := claim_error(state,content,id)
	if not error.is_empty(): return {"ok": false, "error": error}
	var contribution := {}
	if rewards.has("sect_contribution"):
		var before := DecisionReceipt._amount(state.sect.get("contribution", "0"))
		var gain := AmountCompat.from_number(float(rewards.sect_contribution))
		var after := before.add(gain)
		contribution = {"before": before.serialize(), "gained": gain.serialize(), "after": after.serialize()}
		state.sect.contribution = after.serialize()
	for resource in rewards.get("resource", {}):
		var gain := AmountCompat.from_number(float(rewards.resource[resource]))
		var before: AmountCompat = state.resources.get(resource, {}).get("value", AmountCompat.zero())
		state.resources[resource] = {"value": ResourceLedger.change(state, "home", resource, before, before.add(gain), "achievement", gain), "unlocked": true, "ever_obtained": true}
	state.achievements.claimed[id] = true
	return {"ok": true, "achievement_id": id, "rewards": rewards, "contribution": contribution, "message": "成功領取成就獎勵：" + def.rewards_desc}

static func reason(error: String) -> String:
	if error == "STORY_NO_TRAINING_GAIN": return "當級修煉已滿，請先晉階"
	if error == "LIFESPAN_EXHAUSTED": return "壽元已盡，請先輪迴"
	if error.begins_with("INSUFFICIENT_RESOURCE"): return "祖島材料不足"
	if error.begins_with("STORY_DESTINATION_FULL"): return "祖島容量不足，需整筆入庫"
	if error == "PILL_INVENTORY_LIMIT": return "丹庫已滿"
	if error == "STORY_AMOUNT_UNREPRESENTABLE": return "數值精度不足，無法整筆結算"
	return error

static func unlock_available(state: GameState) -> void:
	var ach := AchievementSystem.ensure_achievements_state(state)
	for id in AchievementSystem.DEFINITIONS:
		if not str(id).begins_with("p1_") and not str(id).begins_with("p2_"): continue
		if not ach.unlocked.has(id) and achievement_met(state,id):
			# Qualification is permanent; zero means no separate exact attainment timestamp is recorded.
			# Offline batch clocks must not fabricate per-event wall-clock times.
			ach.unlocked[id] = 0.0
