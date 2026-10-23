class_name LifeEchoFixture
extends RefCounted
## Synthetic preparation; choices, join/claim, acquisition/feed use real commands.
static func apply(session: GameSession) -> void:
	var state := session.state
	state.era_id = 3
	state.level = 1
	state.buildings.rebirth_lotus = 1
	state.total_elapsed_seconds = 0
	state.life_ledger = {}
	state.fortune = {}
	state.sect = {}
	state.beasts = {}
	LifeLedger.initialize(state, true)
	ResourceLedger.initialize(state, true)
	for id in state.resources: state.resources[id].value = AmountCompat.from_number(1000000)
	FortuneSystem.ensure_initialized(state)
	state.fortune.pending_encounter = FortuneSystem.get_encounters()[0].duplicate(true)
	var chosen := session.resolve_fortune(1)
	var joined := session.join_sect("太虛天闕")
	var acquired := session.acquire_beast("jade_fox")
	assert(chosen.ok and joined.ok and acquired.ok)
	# Fast-forward fixture setup is explicit; this is not a natural-life pacing test.
	state.total_elapsed_seconds = 60
	LifeLedger.note(state, "cultivation_leveled_up", "3:2", "echo-fixture-level", 60)
	state.sect.active_expedition = {"name":"合成短程委託", "duration":7, "elapsed":7, "rewards":{"contribution":5}}
	var claimed := session.claim_sect_expedition()
	state.beasts.active.stage = "growing"
	state.beasts.active.exp = 990
	var fed := session.feed_beast()
	assert(claimed.ok and fed.ok)
	LifeLedger.observe(state)
	state.tutorial_flags.life_echo_fixture_v2 = true
	state.tutorial_flags.seen_nine_realms_hook = true
	state.revision += 1
