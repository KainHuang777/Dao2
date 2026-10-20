extends RefCounted
## Test-only next-era definition; excluded from the normal Web preset.
static func attach(content: GameContent) -> void:
	var next: Dictionary = content.eras[3].duplicate(true)
	next.id = 4
	next.name = "元嬰期"
	content.eras[4] = next
	content.era_ids.append(4)
	content.eras[3].upgrade_requirements.capacity = {}

static func seed_state(state: GameState, success: bool) -> void:
	state.era_id = 3
	state.level = 10
	state.training_seconds = 123.0
	state.tribulation_seed = 0
	state.pill_effects = {"stacks": {"golden_tribulation_pill": 1}}
	var probability := TribulationRules.success_probability(3, 1)
	for index in 10000:
		if TribulationRules.is_success(TribulationRules.roll(0, index), probability) == success:
			state.tribulation_roll_index = index
			return
	assert(false, "No deterministic tribulation fixture")
