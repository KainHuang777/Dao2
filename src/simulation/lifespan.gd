class_name Lifespan
extends RefCounted

static func max_lifespan_seconds(eras: Array, era_id: int, talent_bonus: float = 0.0, pill_bonus: float = 0.0) -> float:
	var target := maxi(1, int(floor(float(era_id))))
	var total_years := 0.0
	for i in range(1, target + 1):
		var lifespan_years := 0.0
		var found := false
		for entry in eras:
			var data: Dictionary = entry
			if int(data.get("era_id", 0)) != i:
				continue
			var lifespan: Variant = data.get("lifespan", 0.0)
			if typeof(lifespan) == TYPE_FLOAT or typeof(lifespan) == TYPE_INT:
				lifespan_years = float(lifespan)
				found = true
			break
		if found and lifespan_years > 0.0:
			total_years += lifespan_years
		elif i == 1:
			total_years += 80.0
		else:
			total_years += float(i) * 100.0
	var max_years: float = floor(total_years * (1.0 + talent_bonus) + pill_bonus)
	return max_years * 60.0

static func is_exhausted(total_elapsed_seconds: float, max_lifespan_seconds: float) -> bool:
	return is_finite(max_lifespan_seconds) and total_elapsed_seconds >= max_lifespan_seconds
static func for_state(eras: Array, state: GameState) -> float:
	var talents := TalentSystem.compute_multipliers(state)
	var buffs := BuffSystem.compute_multipliers(state)
	var ratio := float(talents.lifespan_bonus) + 0.02 * SectSpecialization.level(state, "wanfo_enduring_body") + SectLineage.bonus(state, "wanfo") + GuardianBeasts.bonus(state, "lifespan")
	var flat := float(state.pill_effects.get("lifespan_bonus_years", 0)) + float(buffs.lifespan_bonus_years) + 2.0 * SectSpecialization.level(state, "wanfo_life_lamp")
	return max_lifespan_seconds(eras, state.era_id, ratio, flat)
