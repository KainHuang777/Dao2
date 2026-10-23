class_name LifeHistoryFixture
extends RefCounted
## Entirely synthetic, deterministic records; never player progression.
static func apply(session: GameSession) -> void:
	var state := session.state
	LifeReportFixture.apply(state, "early")
	state.reincarnation_count = 0
	StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
	state.life_ledger = {}
	LifeLedger.initialize(state, true)
	state.total_elapsed_seconds = 0
	state.life_ledger.current.started_at = 0.0
	state.life_ledger.current.until = 0.0
	state.life_ledger.current.peak.at = 0.0
	state.life_ledger.current.events = []
	state.resources.wood.unlocked = true
	state.resources.wood.value = AmountCompat.from_number(100)
	LifeHistory.observe(state, session.content, true)
	for n in 5:
		state.total_elapsed_seconds = float(n + 1) * 240
		state.resources.wood.value = AmountCompat.from_number(100 + 10 * n)
		LifeHistory.observe(state, session.content, true)
		LifeLedger.note(state, "cultivation_leveled_up", "1:" + str(n + 2), "fixture" + str(n), state.total_elapsed_seconds)
	var result := ReincarnationRules.apply_reincarnation(state, session.content, "normal", "history-fixture-first")
	assert(result.ok)
	# Older archive lacks both the optional samples and an authoritative reward.
	state.life_ledger.archive[0].erase("history")
	state.life_ledger.archive[0].erase("settlement")
	state.total_elapsed_seconds = 0
	state.resources.wood.unlocked = true
	LifeHistory.observe(state, session.content, true)
	for n in 80:
		state.total_elapsed_seconds = float(n + 1) * 60000
		state.resources.wood.value = AmountCompat.from_number(100 + n * 3)
		LifeHistory.observe(state, session.content, true)
		if n in [4, 40, 79]: LifeLedger.note(state, "building_built", "hut", "fixture-long" + str(n), state.total_elapsed_seconds)
	result = ReincarnationRules.apply_reincarnation(state, session.content, "normal", "history-fixture-long")
	assert(result.ok)
	state.buildings.rebirth_lotus = 1
	state.total_elapsed_seconds = 1200
	LifeHistory.observe(state, session.content, true)
	state.tutorial_flags.history_fixture = true
