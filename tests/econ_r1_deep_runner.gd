extends "res://tests/econ_r1_slice_runner.gd"
## D-1: fresh earned Era4 path; fixtures below are strictly separate from that path.

func rejected(kind: String, payload: Dictionary, error: String) -> void:
	if kind == "breakthrough_era" and s.state.era_id == 3: return # C's old endpoint; D exercises the real transition later.
	super.rejected(kind, payload, error)

func build(id: String) -> bool:
	var required: String = {"mineral_focus":"R09", "core_storehouse_4":"R10", "cultivation_focus_4":"R08"}.get(id, "")
	if not required.is_empty() and not research(required): return false
	return super.build(id)

func ensure(id: String, target: float, depth: int = 0) -> bool:
	if value(id) + 0.000001 < target:
		var required: String = EconomySlice.DEEP_GATES.get(id, "")
		if not required.is_empty() and not research(required): return false
		if id == "stone_mid" and s.state.era_id >= 4 and not research("R08"): return false
	return super.ensure(id, target, depth)

func smoke() -> void:
	check(ResearchSystem.validate_catalog(catalog, content).is_empty() and catalog.nodes.size() == 11, "D1 catalog DAG")
	var c := EconomySlice.create()
	check(c.ok and c.catalog.nodes.size() == 7 and not EconomySlice.late(c.content), "C factory preserved")
	var old := EconomyProfile.open(c.content, SliceMemory.new(), c.catalog, true)
	var old_bytes: String = old.profile._source
	check(p.inspect_save(old_bytes).get("error") == "PROFILE_VERSION:rules_version", "C cannot silently upgrade")
	check(old.profile.inspect_save(p._source).get("error") == "PROFILE_VERSION:rules_version", "D cannot silently downgrade")
	# Actual storage rejection, including authenticated incompatible main + compatible backup.
	var incompatible := SliceMemory.new()
	incompatible.data = memory.data.duplicate(true)
	incompatible.data["econ_r1_" + SaveSlots.SLOT_MAIN] = old_bytes
	var before_data := incompatible.data.duplicate(true)
	check(not EconomyProfile.open(content, incompatible, catalog).ok and incompatible.data == before_data, "incompatible storage stays byte-identical")
	for id in ["stone_mid_bulk"]:
		rejected("craft", {"recipe_id":id,"island_id":"home"}, "RESEARCH_REQUIRED:R08")
	# Explicit unit fixture, not used by life() or the earned report.
	var fixture := GameSession.create_new_game(content, 1)
	fixture.state.era_id = 4
	fixture.state.onboarding_version = 0
	fixture.state.buildings.research_seat = 1
	fixture.state.buildings.craft_workshop = 1
	for id in fixture.state.resources:
		fixture.state.resources[id].unlocked = true
		fixture.state.resources[id].value = AmountCompat.from_number(0 if id == "foundation_pill" else 100)
	check(IslandProgression.command(content, fixture.state, "activate_islands", {"hub":true}).ok, "fixture activate")
	check(IslandEconomy.command(content, fixture.state, "open_island", {"island_id":"deep"}).ok, "fixture deep opening before research")
	var r := ResearchSystem.initial()
	for node in catalog.nodes:
		if node.id in ["R09", "R10", "R11", "R08"]: continue
		r.completed[node.id] = true; r.mastered[node.id] = true
	fixture.content = EconomySlice.bind(content, r)
	var cat := fixture.content.processing_catalog
	fixture.state.resources.stone_mid.ever_obtained = false
	check(ResearchSystem.quote(catalog, r, fixture.state, "R08").get("error") == "RESEARCH_SAMPLE_REQUIRED", "bulk needs actual sample")
	fixture.state.resources.stone_mid.ever_obtained = true
	check(ResearchSystem.quote(catalog, r, fixture.state, "R08").ok, "sample qualifies")
	for i in 4:
		for resource in EconomySlice.DEEP_GATES:
			var expected: bool = r.completed.has(EconomySlice.DEEP_GATES[resource])
			check((IslandEconomy.rate(fixture.state, "deep", resource, cat) > 0) == expected, "rate stage "+str(i)+":"+resource)
			var before := IslandEconomy.value(fixture.state, "deep", resource)
			IslandEconomy.tick(fixture.state, cat, {"deep:"+resource:99.0})
			check((IslandEconomy.value(fixture.state, "deep", resource) > before) == expected, "authoritative production / override stage "+str(i)+":"+resource)
		if i < 3:
			var id: String = ["R09", "R10", "R11"][i]
			var paid_before := fixture.state.to_snapshot_dict()
			if i == 0:
				var denied := ResearchSystem.start(catalog, r, fixture.state, "R10", content)
				check(not denied.ok and ResearchSystem.same(paid_before, fixture.state.to_snapshot_dict()), "out-of-order research atomic")
			check(ResearchSystem.start(catalog, r, fixture.state, id, content).ok, "paid research "+id)
			r.job.remaining = 1 # boundary-only fixture
			check(ResearchSystem.tick(r).size() == 1, "complete stage "+id)
	check(IslandEconomy.rate(fixture.state, "deep", "mithril") > 0, "legacy rate unchanged")
	check(EconomySlice.guard(fixture.content, fixture.state, "open_island", {"island_id":"ancient"}) == "ECON_SLICE_NOT_AVAILABLE", "D1 future boundary")
	# Persist a valid R09 job; refusal freezes the exact candidate, then completion
	# and a further tick exercise the idle-production cache invalidation in one call.
	r = ResearchSystem.initial()
	for id in ["R01", "R02", "R03", "R05"]: r.completed[id] = true; r.mastered[id] = true
	var q := ResearchSystem.quote(catalog, r, fixture.state, "R09")
	check(q.ok, "boundary job quote")
	check(ResearchSystem.start(catalog, r, fixture.state, "R09", content).ok, "boundary job paid")
	r.job.remaining = 3
	fixture.state.economy.islands.deep.inventory.clear()
	fixture.state.economy.trips.clear()
	for route in fixture.state.economy.routes.values(): route.enabled = false
	fixture.content = EconomySlice.bind(content, r)
	var mem := SliceMemory.new()
	var probe := EconomyProfile.open(content, mem, catalog, true).profile as EconomyProfile
	var staged := probe._stage(fixture, r, {"ok":true})
	check(staged.ok, "isolated boundary save:"+str(staged))
	var branches: Array = []
	for i in 2:
		var branch_memory := SliceMemory.new()
		branch_memory.data = mem.data.duplicate(true)
		var branch := EconomyProfile.open(content, branch_memory, catalog)
		check(branch.ok, "boundary branch load")
		branches.append(branch.profile)
	var prior := probe.view()
	mem.reject_candidate = true
	var refused := probe.advance_time(4)
	check(not refused.ok and ResearchSystem.same(probe.view().state, prior.state), "completion refused write preserves state")
	var frozen := probe._pending
	mem.reject_candidate = false
	check(probe.retry_save().ok and probe._source == frozen, "completion retries identical bytes")
	check(probe._research.completed.has("R09") and is_equal_approx(IslandEconomy.value(probe._game.state, "deep", "refined_iron"), 0.1), "new production begins next authoritative tick:"+str(probe._research)+":"+str(probe._game.state.economy.islands.deep))
	check(IslandEconomy.value(probe._game.state, "deep", "cold_iron") == 0 and IslandEconomy.value(probe._game.state, "deep", "mithril") == 0, "future mining remains locked")
	check(branches[0].advance_time(3).ok and branches[0].advance_time(1).ok, "split completion ticks")
	check(branches[1].settle_to(1000000).ok and branches[1].settle_to(1004000).ok, "UTC completion ticks")
	for branch in branches:
		check(ResearchSystem.same(branch.view().state, probe.view().state) and ResearchSystem.same(branch.view().research, probe.view().research), "D1 online/split/UTC all-field parity")
	var reload := EconomyProfile.open(content, mem, catalog)
	check(reload.ok and ResearchSystem.same(reload.profile.view(), probe.view()), "D1 reload all fields")
	print("ECON-D1 smoke failures=", failures)

func run() -> void:
	policy = "econ-d1-solo"
	var loaded := EconomySlice.create_late()
	check(loaded.ok, "late factory")
	content = loaded.content; catalog = loaded.catalog
	var opened := EconomyProfile.open(content, memory, catalog, true, 1)
	check(opened.ok, "fresh D1 profile")
	if not opened.ok: print(opened); RunnerResult.finish(self, 1); return
	p = opened.profile; s = p._game
	smoke()
	if OS.get_environment("DAO_ECON_D_EARNED") == "1" and failures.is_empty():
		var ok := life()
		if ok: ok = research("R08") and ladder(3)
		if ok: ok = opening("deep") and research("R09") and build("mineral_focus") and research("R10") and research("R11") and build("core_storehouse_4") and build("cultivation_focus_4")
		while ok and s.state.level < 10:
			ok = bill(plain(Cultivation.level_up_cost(content.eras[4], s.state.level, 0)))
			var required := Cultivation.next_level_required_seconds(content.eras[4], s.state.level, 0, 1)
			while ok and s.state.training_seconds + 0.000001 < required: ok = tick(30, "training:era4")
			if ok: ok = send("level_up_cultivation")
		check(ok and s.state.era_id == 4 and s.state.level == 10, "earned D1 endpoint:"+blocked)
		if ok: super.rejected("breakthrough_era", {}, "ECON_SLICE_NOT_AVAILABLE")
		var report := {"task":"ECON-R1-D1", "seconds":s.state.total_elapsed_seconds, "era":s.state.era_id, "level":s.state.level, "research":p._research, "trace":trace, "waits_seconds":waits, "witnesses":witnesses, "failures":failures, "snapshot_sha256":JSON.stringify(p.view(), "", true).sha256_text()}
		var file := FileAccess.open(RunnerResult.output_path("res://econ-r1-d1/earned-path.json"), FileAccess.WRITE)
		check(file != null, "report write")
		if file != null: file.store_string(JSON.stringify(report, "\t", true)); file.close()
		var checkpoint := FileAccess.open(RunnerResult.output_path("res://econ-r1-d1/checkpoint.json"), FileAccess.WRITE)
		if checkpoint != null: checkpoint.store_string(JSON.stringify({"storage":memory.data, "trace":trace, "waits_seconds":waits, "witnesses":witnesses, "first_quotes":first_quotes, "commands":commands, "serial":serial, "failures":failures}, "", true)); checkpoint.close()
		print("ECON-D1 earned seconds=",s.state.total_elapsed_seconds," endpoint=",s.state.era_id,":",s.state.level," failures=",failures)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
