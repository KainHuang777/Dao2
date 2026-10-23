class_name ResourceAccountsFixture
extends RefCounted
## Synthetic acceptance preparation, followed by a real core command.
static func apply(session: GameSession) -> void:
	var state := session.state
	LifeReportFixture.apply(state, "early")
	state.resources.wood.value = AmountCompat.from_number(100)
	ResourceLedger.initialize(state)
	FortuneSystem.ensure_initialized(state)
	state.fortune.pending_encounter = {"id":"accounts_fixture", "title":"帳目交換（合成驗收）", "options":[{"text":"付二十得三十", "costs":{"wood":20}, "rewards":{"resources":{"wood":30}}}]}
	var result := session.resolve_fortune(0)
	assert(result.ok)
	state.tutorial_flags.accounts_fixture = true
