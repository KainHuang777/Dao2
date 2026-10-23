class_name LifeReportFixture
extends RefCounted
## Synthetic acceptance data only. Not earned player progress.
static func apply(state: GameState, mode: String) -> void:
	state.era_id = 3
	state.level = 1
	state.highest_era = 8
	state.reincarnation_count = 1
	StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
	state.total_elapsed_seconds = 0
	state.buildings.hut = 1
	state.buildings.rebirth_lotus = 1 if mode != "living" else 0
	state.life_ledger = {}
	LifeLedger.initialize(state, mode != "partial")
	var ids := ["hut", "wood", "ore", "2:3"]
	var kinds := ["building_built", "island_opened", "island_opened", "era_breakthrough"]
	if mode == "partial":
		state.total_elapsed_seconds = 600
		state.life_ledger = {}
		LifeLedger.initialize(state)
	for n in ids.size(): LifeLedger.note(state, kinds[n], ids[n], "report-fixture:" + str(n), state.total_elapsed_seconds)
	state.total_elapsed_seconds = Lifespan.max_lifespan_seconds([{"era_id":1,"lifespan":80},{"era_id":2,"lifespan":120},{"era_id":3,"lifespan":540}], 3) if mode == "exhausted" else 1200
	LifeLedger.observe(state)
	if mode == "exhausted": LifeLedger.exhausted(state)
	state.tutorial_flags.seen_nine_realms_hook = true
	state.tutorial_flags.report_fixture_1a = true
	state.revision += 1
