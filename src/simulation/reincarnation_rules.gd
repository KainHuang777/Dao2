class_name ReincarnationRules
extends RefCounted

const NORMAL_DAO_PROOF_DIVISOR := 50.0
const ADVANCED_DAO_PROOF_DIVISOR := 30.0

static func building_level_sum(buildings: Dictionary) -> int:
	var total := 0
	for building_id in buildings:
		total += int(buildings[building_id])
	return total

static func era_dao_heart_floor(era_id: int) -> int:
	if era_id <= 1:
		return 0
	elif era_id == 2:
		return 15
	elif era_id == 3:
		return 20
	else:
		return 25

static func compute_reward(building_sum: int, era_id: int, mode: String = "normal") -> Dictionary:
	var floor_val := era_dao_heart_floor(era_id)
	var from_buildings := int(floor(float(building_sum) / 10.0))
	var dao_heart_amount := maxi(from_buildings, floor_val)
	var divisor := ADVANCED_DAO_PROOF_DIVISOR if mode == "advanced" else NORMAL_DAO_PROOF_DIVISOR
	var dao_proof_amount := int(floor(float(building_sum) / divisor))
	return {
		"building_sum": building_sum,
		"dao_heart": AmountCompat.from_number(float(dao_heart_amount)),
		"dao_proof": dao_proof_amount,
		"era_floor": floor_val,
	}

static func inheritance_ratio(rebirth_count: int, inheritance_bonus: float = 0.0) -> float:
	if rebirth_count <= 0:
		return 0.0
	return clampf(inheritance_bonus, 0.0, 1.0)

static func compute_start_amount(cap_val: float, rebirth_count: int, inheritance_bonus: float = 0.0) -> float:
	return floor(cap_val * inheritance_ratio(rebirth_count, inheritance_bonus))

static func check_eligibility(state: GameState, content: GameContent) -> Dictionary:
	var talent_lifespan_bonus := 0.0
	if state.talents.has("lifespan_extension"):
		talent_lifespan_bonus = float(state.talents["lifespan_extension"]) * 0.1
	var pill_lifespan_bonus := float(state.pill_effects.get("lifespan_bonus_years", 0.0))
	var buff_multipliers := BuffSystem.compute_multipliers(state)
	pill_lifespan_bonus += float(buff_multipliers.lifespan_bonus_years)
	var max_seconds := Lifespan.max_lifespan_seconds(content.era_lifespan_entries(), state.era_id, talent_lifespan_bonus, pill_lifespan_bonus)
	var exhausted := Lifespan.is_exhausted(state.total_elapsed_seconds, max_seconds)
	if exhausted:
		return {"can_reincarnate": true, "reason": "lifespan_exhausted"}
	# 提前輪迴：需修築特定輪迴建築（往生蓮臺 rebirth_lotus 或 太虛輪迴境 void_mirror）
	if int(state.buildings.get("rebirth_lotus", 0)) > 0 or int(state.buildings.get("void_mirror", 0)) > 0:
		return {"can_reincarnate": true, "reason": "rebirth_lotus"}
	return {"can_reincarnate": false, "reason": "NOT_ELIGIBLE"}

static func apply_reincarnation(state: GameState, content: GameContent, mode: String = "normal") -> Dictionary:
	var check := check_eligibility(state, content)
	if not bool(check.get("can_reincarnate", false)):
		return {
			"ok": false,
			"error": "REINCARNATION_NOT_ELIGIBLE",
			"events": [],
			"changed_ids": [],
			"detail": check,
		}

	var b_sum := building_level_sum(state.buildings)
	var reward := compute_reward(b_sum, state.era_id, mode)
	var previous_era := state.era_id
	var previous_level := state.level
	var economy_preview := IslandEconomy.reincarnation_preview(state)
	var had_economy := not state.economy.is_empty()
	var had_progression := IslandProgression.active(state)
	var progression_version: String = state.economy.get("version", "")

	# Update meta progress
	state.reincarnation_count += 1
	state.highest_era = maxi(state.highest_era, previous_era)
	state.dao_heart = state.dao_heart.add(reward["dao_heart"])
	state.dao_proof += int(reward["dao_proof"])

	# Reset current life progress
	state.abode_scenery = {}
	state.economy = IslandEconomy.initial() if had_economy else {}
	if had_progression:
		state.economy.version = progression_version
		for island in state.economy.islands:
			state.economy.islands[island].facilities = {"extractor": 1, "workshop": 1, "storage": 1}
	# Extra processing IDs are not in the release manifest: clear them as well.
	for resource_id in state.resources:
		if not resource_id in content.resource_ids:
			state.resources[resource_id].value = AmountCompat.zero()
			state.resources[resource_id].unlocked = false
	state.era_id = 1
	state.level = 1
	state.training_seconds = 0.0
	state.total_elapsed_seconds = 0.0
	state.tick_remainder_seconds = 0.0
	state.buildings.clear()
	state.pills.clear()
	state.pill_effects.clear()
	var surviving_buffs: Dictionary = {}
	for buff_id in state.buffs:
		var b: Dictionary = state.buffs[buff_id]
		if bool(b.get("transmigratable", false)):
			surviving_buffs[buff_id] = b
	state.buffs = surviving_buffs
	SectSystem.on_reincarnate(state)
	var beast_reincarnate_res := BeastSystem.on_reincarnate(state)
	if state.fortune is Dictionary:
		state.fortune["pending_encounter"] = {}
		state.fortune["cooldown_remaining"] = FortuneSystem.compute_cooldown_for_era(1)

	# Re-initialize onboarding unlock state
	state.onboarding_version = 1
	var onboarding_state := Onboarding.unlock_state(state.era_id, state.onboarding_version, state.buildings)
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)

	# Calculate resource inheritance bonus from talents
	var inheritance_bonus := 0.0
	if state.talents.has("resource_inheritance"):
		inheritance_bonus = float(state.talents["resource_inheritance"]) * 0.1

	var granted_resources: Dictionary = {}
	for resource_id in content.resource_ids:
		var def: Dictionary = content.resources[resource_id]
		var is_unlocked: bool = not onboarding_state.active or (resource_id in onboarding_state.resources)
		var entry: Dictionary = state.resources.get(resource_id, {})
		if entry.is_empty():
			entry = {
				"value": AmountCompat.zero(),
				"unlocked": is_unlocked,
				"ever_obtained": is_unlocked,
			}
			state.resources[resource_id] = entry
		else:
			entry.unlocked = is_unlocked

		if is_unlocked and String(def.get("type", "")) == "basic":
			var cap_amount: AmountCompat = caps.get(resource_id, AmountCompat.from_number(100.0))
			var cap_float: float = cap_amount.to_float()
			var start_amount := compute_start_amount(cap_float, state.reincarnation_count, inheritance_bonus)
			entry.value = AmountCompat.from_number(start_amount)
			entry.ever_obtained = start_amount > 0.0 or is_unlocked
			if start_amount > 0.0:
				granted_resources[resource_id] = start_amount
		else:
			entry.value = AmountCompat.zero()

	var event_payload := {
		"kind": "reincarnated",
		"economy_preview": economy_preview,
		"mode": mode,
		"reincarnation_count": state.reincarnation_count,
		"highest_era": state.highest_era,
		"gained_dao_heart": (reward["dao_heart"] as AmountCompat).serialize(),
		"gained_dao_proof": reward["dao_proof"],
		"total_dao_heart": state.dao_heart.serialize(),
		"total_dao_proof": state.dao_proof,
		"gained_beast_souls": beast_reincarnate_res.get("gained_souls", {}),
		"granted_resources": granted_resources,
		"previous_era": previous_era,
		"previous_level": previous_level,
	}

	return {
		"ok": true,
		"events": [event_payload],
		"changed_ids": ["reincarnation_count", "dao_heart", "dao_proof", "era_id", "cultivation_level", "resources", "buildings", "beasts", "beast_souls"],
		"reward": reward,
	}
