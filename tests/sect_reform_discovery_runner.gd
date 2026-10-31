extends SceneTree
## BEAST-2 candidate contracts, not a released save or natural-play claim.
var content: GameContent
var checks := 0
var failures: Array[String] = []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func same(a: GameState, b: GameState) -> bool:
	return JSON.stringify(a.to_snapshot_dict()) == JSON.stringify(b.to_snapshot_dict())
func fresh(era: int = 3, opened: Array = ["herb"]) -> GameState:
	var source := GameSession.create_new_game(content, 17).state
	source.era_id = era
	SectSystem.ensure_sect_state(source)
	source.sect.unlocked = true
	SectIdentity.write(source.sect, "taixu_sect")
	var state := SectReformSave.prepare(source, "isolated-BEAST-2", "discovery-test")
	state.beast_version = GuardianBeasts.VERSION
	state.sect.guardian = {"version": 1, "guardian_tokens": 0, "permits": {}}
	state.economy = {}
	state.era_id = maxi(2, era)
	check(IslandProgression.command(content, state, "activate_islands", {}).ok, "canonical supply fixture")
	state.era_id = era
	for id in opened: state.economy.islands[id].opened = true
	return state
func completed(state: GameState, event: bool = false) -> Dictionary:
	# Deterministically locate an epic using the real five-draw generator.
	var task := {}
	for i in range(200):
		task = SectSystem._generate_random_task(state.era_id, 1, state.sect, state)
		if task.rarity == "epic": break
	check(task.rarity == "epic", "epic found in bounded stream")
	# Explicit sampling boundary fixture; production only stamps once.
	GuardianDiscovery.stamp(state, task, 0.0 if event else 0.99, 0.0)
	task.elapsed = task.duration
	state.sect.active_expedition = task
	state.sect.available_tasks = []
	return task
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply content")
	check(GuardianDiscovery.TARGETS.size() == 10, "fixed ten target registry")
	for era in range(1, 9):
		for mask in range(8):
			var opened: Array = []
			for i in range(3):
				if mask & (1 << i): opened.append(GuardianDiscovery.SOURCES[i])
			var state := fresh(era, opened)
			check(GuardianDiscovery.state_error(state).is_empty(), "valid candidate")
			var ids := GuardianDiscovery.pool(era, GuardianDiscovery.conditions(state))
			var expected := (5 if era >= 3 and "herb" in opened else 0) + (2 if era >= 4 and "deep" in opened else 0) + (1 if era >= 5 and "ancient" in opened else 0) + (1 if era >= 6 and "ancient" in opened else 0)
			check(ids.size() == expected and "jade_fox" not in ids and "cloud_serpent" not in ids, "actual sources, no fox or future cloud supply")
			var before_rng := SeededRandom.from_state(state.sect.rng.state)
			for i in range(15): before_rng.next()
			check(SectSystem.refresh_tasks(state).ok, "three-slot candidate refresh")
			check(state.sect.rng.state == before_rng.state and state.sect.task_counter == 3, "exact fifteen next values")
			for task in state.sect.available_tasks:
				check(SectSaveContract.validate_task(task, state.sect_version).is_empty(), "frozen task contract")
				check(task.guardian_reward.token_base == (1 if expected > 0 else 0), "base token frozen across rarities")
				check(task.rewards.size() <= 8 and not task.rewards.has("guardian_tokens"), "resource dictionary remains unchanged")
	# Every integer species interval is inspected at both boundaries.
	for sect_id in GuardianDiscovery.SECTS:
		for era in [3, 4, 5, 6]:
			var state := fresh(era, ["herb", "deep", "ancient"])
			var ids := GuardianDiscovery.pool(era, GuardianDiscovery.conditions(state))
			var representative: String = GuardianDiscovery.TARGETS[GuardianDiscovery.SECTS.find(sect_id)]
			var total := ids.size() + 2
			var cursor := 0
			for id in ids:
				var weight := 3 if id == representative else 1
				check(GuardianDiscovery.choose(ids, sect_id, float(cursor) / total) == id, "weighted interval left")
				check(GuardianDiscovery.choose(ids, sect_id, float(cursor + weight - 0.001) / total) == id, "weighted interval right")
				cursor += weight
			check(cursor == total, "same sect only species weighting")
	var state := fresh(4, ["deep"])
	check(GuardianDiscovery.pool(4, GuardianDiscovery.conditions(state)) == ["frost_stag", "iron_turtle"], "deep without herb has exactly old targets")
	check(GuardianDiscovery.choose(["iron_turtle"], "taixu_sect", 0.99999) == "iron_turtle", "single eligible target")
	state = fresh()
	var task := completed(state)
	for rarity in GuardianDiscovery.RARITIES:
		task.rarity = rarity
		for value in [0.0, 0.099999, 0.1, 0.199999, 0.2, 0.99999]:
			GuardianDiscovery.stamp(state, task, value, 0.0)
			var rate := 0.1 if rarity == "epic" else 0.2 if rarity == "legendary" else 0.0
			check(task.guardian_reward.permit_id.is_empty() == (value >= rate), "event threshold " + rarity)
	# Real start -> simulated completion -> real claim: baseline 12 earns one permit.
	state = fresh()
	for i in range(12):
		state.sect.available_tasks = []
		check(SectSystem.refresh_tasks(state).ok, "empty-list refresh policy")
		task = state.sect.available_tasks[0]
		GuardianDiscovery.stamp(state, task, 0.99, 0.0)
		check(SectSystem.start_expedition(state, task.id).ok, "formal start")
		check(not SectSystem.claim_expedition_reward(state).ok, "early claim rejected")
		SectSystem.tick(state, task.duration)
		check(SectSystem.claim_expedition_reward(state).ok, "formal completed claim")
		check(state.sect.guardian.guardian_tokens == i + 1 and state.sect.lineage.life_claimed == i + 1, "one token and one lineage credit")
		var snapshot := state.duplicate_state()
		check(not SectSystem.claim_expedition_reward(state).ok and same(state, snapshot), "claim cannot repeat")
	check(GuardianDiscovery.redeem(state, "tianjian_suanni").ok, "any sect target costs twelve")
	check(state.sect.guardian.guardian_tokens == 0 and state.sect.guardian.permits == {"tianjian_suanni": true} and state.beasts.get("active", {}).is_empty() and state.beast_souls.is_empty(), "no automatic beast or souls")
	var snapshot := state.duplicate_state()
	check(not GuardianDiscovery.redeem(state, "tianjian_suanni").ok and same(state, snapshot), "owned permit no charge")
	# Frozen generation rights survive lowered era, missing supply and exhausted life.
	state = fresh()
	task = completed(state, true)
	var frozen: Dictionary = task.guardian_reward.duplicate(true)
	state.era_id = 1
	state.economy = {}
	state.total_elapsed_seconds = 1e9
	check(SectSystem.claim_expedition_reward(state).ok, "finished claim at exhausted life keeps frozen eligibility")
	check(state.sect.guardian.permits.has(frozen.permit_id) and state.sect.guardian.guardian_tokens == 1, "frozen permit granted")
	# Redeeming an already frozen discovery target makes the claim a duplicate.
	state = fresh()
	task = completed(state, true)
	var id: String = task.guardian_reward.permit_id
	state.sect.guardian.guardian_tokens = 12
	check(GuardianDiscovery.redeem(state, id).ok, "redeem before claim")
	state.sect.guardian.guardian_tokens = 119
	var result := SectSystem.claim_expedition_reward(state)
	check(result.ok and result.events[-1].tokens_gained == 1 and result.events[-1].tokens_overflow == 2 and state.sect.guardian.guardian_tokens == 120, "duplicate saturates and explicitly reports overflow")
	check(state.beast_souls.is_empty(), "duplicate never grants souls")
	# Candidate data is permanent across sect reset, and is not serializable yet.
	var permanent: Dictionary = state.sect.guardian.duplicate(true)
	SectSystem.on_reincarnate(state)
	check(state.sect.guardian == permanent, "tokens and permits survive sect reset")
	check(not SaveCodec.encode(state, "test", {}).ok, "beast2 cannot enter released codec")
	state.beast_version = 1
	check(not SaveCodec.encode(state, "test", {}).ok, "ledger cannot masquerade as beast1")
	# Legacy dispatch has no retroactive discovery or lineage credit.
	state = fresh()
	task = completed(state, true)
	task.erase("guardian_reward"); task.erase("guardian_template_id"); task.erase("lineage_credit")
	check(SectSystem.claim_expedition_reward(state).ok and state.sect.guardian.guardian_tokens == 0 and state.sect.lineage.life_claimed == 0, "legacy dispatch receives no new rewards")
	# Malformed metadata and bounds reject without touching any live rewards.
	for field in ["version", "pool_version", "generation_life_seq", "generation_era", "generation_sect_id", "token_base", "permit_id", "pool_ids", "conditions", "extra"]:
		state = fresh(); task = completed(state, true)
		task.guardian_reward[field] = null
		snapshot = state.duplicate_state()
		check(not SectSystem.claim_expedition_reward(state).ok and same(state, snapshot), "invalid frozen field " + field)
	for value in [-1, 121, 1.5, NAN, INF, true, "12"]:
		check(not GuardianDiscovery.ledger_error({"version": 1, "guardian_tokens": value, "permits": {}}).is_empty(), "token bounds")
	for permits in [{"jade_fox": true}, {"taixu_baize": 1}, {"taixu_baize": false}, {"bogus": true}]:
		check(not GuardianDiscovery.ledger_error({"version": 1, "guardian_tokens": 0, "permits": permits}).is_empty(), "permit whitelist and flags")
	for reason in ["tokens", "era", "source", "membership", "exhausted", "target", "version"]:
		state = fresh(); state.sect.guardian.guardian_tokens = 12
		if reason == "tokens": state.sect.guardian.guardian_tokens = 11
		elif reason == "era": state.era_id = 2
		elif reason == "source": state.economy = {}
		elif reason == "membership": state.sect.unlocked = false; state.sect.sect_id = ""; state.sect.lineage.life_sect_id = ""
		elif reason == "exhausted": state.total_elapsed_seconds = 1e9
		elif reason == "version": state.beast_version = 1
		snapshot = state.duplicate_state()
		check(not GuardianDiscovery.redeem(state, "bogus" if reason == "target" else "taixu_baize").ok and same(state, snapshot), "redemption atomic gate " + reason)
	# Public force payload cannot skip refresh. New generation/start fail at death.
	state = fresh(); check(SectSystem.refresh_tasks(state).ok, "refresh before cooldown")
	snapshot = state.duplicate_state()
	check(not CommandProcessor.apply(content, state, {"type": "refresh_sect_tasks", "payload": {"force": true}}).ok and same(state, snapshot), "public force cannot bypass cooldown")
	state.total_elapsed_seconds = 1e9
	snapshot = state.duplicate_state()
	check(not SectSystem.refresh_tasks(state, true).ok and same(state, snapshot), "exhausted generation rejected")
	check(not SectSystem.start_expedition(state, state.sect.available_tasks[0].id).ok and same(state, snapshot), "exhausted dispatch rejected")
	check("redeem_guardian_permit" in SectReformSave.COMMANDS and "redeem_guardian_permit" in GameSession.KNOWN_COMMAND_TYPES, "shared candidate save route")
	# Same seed and state, regardless of global RNG and read-only views, produce
	# byte-identical frozen tasks and fifteen-step cursor advancement.
	state = fresh(6, ["herb", "deep", "ancient"])
	var twin := state.duplicate_state()
	for i in range(25):
		state.sect.available_tasks = []; twin.sect.available_tasks = []
		check(SectSystem.refresh_tasks(state).ok, "deterministic first branch")
		for j in range(13): randf()
		check(SectSystem.refresh_tasks(twin).ok and same(state, twin), "global RNG cannot alter private five-draw stream")
		var viewer := GameSession.new(); viewer.content = content; viewer.state = state
		var cursor: int = state.sect.rng.state
		viewer.get_view(); viewer.get_view()
		check(state.sect.rng.state == cursor, "view never draws private RNG")
		# View may initialize unrelated legacy display fields; mirror them so
		# subsequent stream comparisons still compare identical source states.
		twin = state.duplicate_state()
	# Candidate command receipt dedup uses the real session processor. This
	# explicit test-only execution does not claim released/durable beast2 saves.
	state = fresh(); state.sect.guardian.guardian_tokens = 24
	var candidate := GameSession.new(); candidate.content = content; candidate.state = state
	candidate._executing_save_candidate = true
	var command := {"command_id": "redeem-once", "expected_revision": state.revision, "type": "redeem_guardian_permit", "payload": {"target_id": "taixu_baize"}}
	check(candidate.submit(command).ok and GuardianDiscovery.permit_owned(state, "taixu_baize"), "candidate command uses authoritative ledger")
	snapshot = state.duplicate_state()
	check(candidate.submit(command).get("duplicate", false) and same(state, snapshot) and state.sect.guardian.guardian_tokens == 12, "same receipt does not debit again")
	command.command_id = "invalid-payload"; command.expected_revision = state.revision
	command.payload = {"target_id": "tianjian_suanni", "permit_owned": true}
	check(not candidate.submit(command).ok and same(state, snapshot), "caller cannot inject authority or extra payload")
	# Malformed generation identity/sequence and removed metadata are rejected.
	for reason in ["seq", "sect", "template", "missing_reward", "missing_template"]:
		state = fresh(); task = completed(state, true)
		if reason == "seq": task.guardian_reward.generation_life_seq += 1
		elif reason == "sect": task.guardian_reward.generation_sect_id = "tianjian_sect"
		elif reason == "template": task.guardian_template_id = "unregistered"
		elif reason == "missing_reward": task.erase("guardian_reward")
		else: task.erase("guardian_template_id")
		snapshot = state.duplicate_state()
		check(not SectSystem.claim_expedition_reward(state).ok and same(state, snapshot), "frozen identity rejection " + reason)
	var report_path := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/discovery.json")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path.get_base_dir()))
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: check(false, "report write")
	else: report.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t")); report.close()
	print("BEAST-2 checks=", checks, " failures=", failures)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
