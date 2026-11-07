extends "res://tests/econ_r1_baseline_runner.gd"
## Earned slice uses only profile commands and authoritative elapsed seconds.
var p: EconomyProfile
var catalog: Dictionary
class SliceMemory extends StorageAdapter:
	var data := {}
	var reject_candidate := false
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key, ""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if reject_candidate: return {"ok":false, "error":"injected_write"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary: data.erase(key); return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)
var memory := SliceMemory.new()
var first_quotes := {}
var witnesses: Array = []

func raw(kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return p.submit({"type":kind, "payload":payload, "command_id":"econ-c-"+str(serial), "expected_revision":s.state.revision})

func send(kind: String, payload: Dictionary = {}) -> bool:
	var before := {"caps":caps(), "buildings":s.state.buildings.duplicate(true)}
	var result := raw(kind, payload)
	commands += 1
	if not result.ok:
		blocked = kind+":"+str(payload)+":"+str(result.get("error"))
		return false
	s = p._game
	if kind != "gather": trace.append({"seconds":s.state.total_elapsed_seconds, "life":s.state.reincarnation_count, "kind":kind, "payload":payload.duplicate(true), "before":before})
	return true

func tick(seconds: float, reason: String) -> bool:
	var result := p.advance_time(seconds)
	s = p._game
	waits[reason] = float(waits.get(reason, 0)) + seconds
	if not result.ok or result.get("stopped") != null:
		blocked = "time:"+str(result.get("error", result.get("stopped")))
		return false
	return true

func research(id: String) -> bool:
	if p._research.completed.has(id): return true
	var node := ResearchSystem.node_for(catalog, id)
	if s.state.era_id < int(node.era): blocked = "research_era:"+id; return false
	for prerequisite in node.prerequisites:
		if not research(prerequisite): return false
	if int(s.state.buildings.get("research_seat", 0)) == 0 and not build("research_seat"): return false
	if not bill(node.cost): return false
	var q := p.quote_research(id)
	if not q.ok: blocked = "quote:"+id+":"+str(q); return false
	witnesses.append({"kind":"research", "life":s.state.reincarnation_count, "id":id, "costs":q.get("paid", {}), "caps":caps()})
	if s.state.reincarnation_count == 0: first_quotes[id] = q.duplicate(true)
	else:
		check(ResearchSystem.same(first_quotes[id].paid, q.paid), "second-life identical materials "+id)
		check(q.duration < first_quotes[id].duration, "second-life research time only "+id)
	if id == "R01" and s.state.reincarnation_count == 0:
		var before := s.state.to_snapshot_dict()
		var wood_before := value("wood")
		memory.reject_candidate = true
		var failed := raw("start_research", {"research_id":id})
		check(not failed.ok and ResearchSystem.same(before, s.state.to_snapshot_dict()), "research refused write preserves live")
		check(p.submit({"type":"cancel_research", "payload":{}, "command_id":"blocked", "expected_revision":s.state.revision}).get("error") == "PROFILE_SAVE_REQUIRED", "pending pauses commands")
		memory.reject_candidate = false
		check(p.retry_save().ok, "research retry same candidate")
		s = p._game
		check(value("wood") == wood_before - float(q.paid.wood), "research retry pays once")
	else:
		if not send("start_research", {"research_id":id}): return false
	if id == "R05" and s.state.reincarnation_count == 0: equivalence(int(q.duration))
	if not tick(q.duration, "research:"+id): return false
	print("ECON-C research=", id," life=",s.state.reincarnation_count," seconds=",s.state.total_elapsed_seconds)
	check(p._research.completed.has(id), "completed "+id)
	return p._research.completed.has(id)

func build(id: String) -> bool:
	if id in stack: blocked = "building_cycle:"+id; return false
	var required := ""
	if id == "craft_workshop": required = "R01" if int(s.state.buildings.get(id, 0)) == 0 else "R03"
	if id == "core_storehouse_3": required = "R04"
	if not required.is_empty() and not research(required): return false
	var d: Dictionary = content.buildings[id]
	if int(d.era) > s.state.era_id: return false
	stack.append(id)
	if d.prereq != null:
		while int(s.state.buildings.get(d.prereq.building,0)) < int(d.prereq.level):
			if not build(d.prereq.building): stack.pop_back(); return false
	var q := EconomySlice.building_quote(s.content, s.state, id)
	if not q.ok: blocked = str(q); stack.pop_back(); return false
	var ok := bill(plain(q.costs))
	if ok:
		witnesses.append({"life":s.state.reincarnation_count, "id":id, "level":s.state.buildings.get(id,0), "costs":plain(q.costs), "caps":caps()})
		ok = send("upgrade_building", {"building_id":id})
	stack.pop_back()
	return ok

func ensure(id: String, target: float, depth: int = 0) -> bool:
	if EconomySlice.RECIPE_GATES.has(id) and value(id) + 0.000001 < target:
		if not research(EconomySlice.RECIPE_GATES[id]): return false
		if int(s.state.buildings.get("craft_workshop", 0)) == 0 and not build("craft_workshop"): return false
	return super.ensure(id, target, depth)

func equivalence(seconds: int) -> void:
	var copies: Array = []
	for i in 3:
		var mem := SliceMemory.new()
		mem.data = memory.data.duplicate(true)
		var opened := EconomyProfile.open(content, mem, catalog)
		check(opened.ok, "equivalence earned branch load")
		copies.append(opened.profile)
	check(copies[0].advance_time(seconds).ok, "online research boundary")
	check(copies[1].advance_time(seconds / 2.0).ok and copies[1].advance_time(seconds / 2.0).ok, "split research boundary")
	check(copies[2].settle_to(1000000).ok and copies[2].settle_to(1000000 + seconds * 1000).ok, "UTC research boundary")
	for i in [1, 2]:
		check(ResearchSystem.same(copies[0].view().state, copies[i].view().state), "all-field online/split/UTC state")
		check(ResearchSystem.same(copies[0].view().research, copies[i].view().research), "online/split/UTC completed research")
	var before: Dictionary = copies[2].view()
	check(copies[2].settle_to(1000000 + seconds * 1000).ok and ResearchSystem.same(before, copies[2].view()), "same UTC no duplicate yield")

func rejected(kind: String, payload: Dictionary, error: String) -> void:
	var before := p.view()
	var result := raw(kind, payload)
	check(not result.ok and result.get("error") == error, "authority "+kind+":"+str(result))
	check(ResearchSystem.same(before, p.view()), "rejection atomic "+kind)

func smoke() -> void:
	# Routine L1 stays short. Earned multi-life analysis is an explicit long probe.
	check(ResearchSystem.validate_catalog(catalog, content).is_empty() and catalog.nodes.size() == 7, "official catalog")
	var legacy: GameContent = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(legacy).ok, "legacy factory")
	check(not EconomySlice.active(legacy) and not legacy.buildings.has("research_seat"), "legacy content isolated")
	check(legacy.eras[2].level_up_requirements.graded_resources[1].resources.has("liquid"), "legacy liquid unchanged")
	var costs := plain(Cultivation.level_up_cost(content.eras[2], 5, 0))
	check(not costs.has("liquid") and costs.spirit_timber == 25 and costs.bronze_essence == 15, "Era2 no future material dependency")
	for id in EconomySlice.RECIPE_GATES:
		rejected("craft", {"recipe_id":id, "island_id":"home"}, "RESEARCH_REQUIRED:"+EconomySlice.RECIPE_GATES[id])
		rejected("switch_processing", {"recipe_id":id, "island_id":"home"}, "RESEARCH_REQUIRED:"+EconomySlice.RECIPE_GATES[id])
	for id in ["research_seat", "craft_workshop"]:
		for resource in content.buildings[id].base_cost: check(resource in ["money", "wood", "stone_low"], "raw-only first equipment")
	check(p.quote_research("R01").get("error") == "RESEARCH_ERA", "fresh research needs Era2")
	# Explicit quote-only fixture; never installed in the earned profile or storage.
	var fixture := s.state.duplicate_state()
	fixture.era_id = 2
	fixture.buildings.research_seat = 1
	var research_state := ResearchSystem.initial()
	var first := ResearchSystem.quote(catalog, research_state, fixture, "R01")
	for node in catalog.nodes: research_state.mastered[node.id] = true
	research_state.inherited_depth = 5
	var second := ResearchSystem.quote(catalog, research_state, fixture, "R01")
	check(first.ok and second.ok and first.duration == 120 and second.duration == 84, "research inheritance time")
	check(ResearchSystem.same(first.paid, second.paid), "research inheritance never discounts material")
	fixture.level = 5
	var bound := EconomySlice.bind(content, research_state)
	check(EconomySlice.guard(bound, fixture, "level_up_cultivation", {}) == "RESEARCH_REQUIRED:R03", "Era2 engineering authority")
	for node in catalog.nodes: research_state.completed[node.id] = true
	check(EconomySlice.guard(bound, fixture, "level_up_cultivation", {}).is_empty(), "completed engineering opens level")
	fixture.buildings.craft_workshop = 1
	var workshop := EconomySlice.building_quote(bound, fixture, "craft_workshop")
	check(workshop.ok and workshop.costs.spirit_timber.to_float() == 6 and workshop.costs.bronze_essence.to_float() == 6, "necessary discrete engineering bill")
	check(IslandProgression.command(bound, fixture, "activate_islands", {"hub":true}).ok, "fixture manufacturing scope")
	var base_time := EconomySlice.duration(fixture, bound.processing_catalog, "wood", "spirit_timber")
	fixture.buildings.craft_workshop = 2
	check(base_time == 10 and EconomySlice.duration(fixture, bound.processing_catalog, "wood", "spirit_timber") == 8, "work time consumer")
	var inputs := EconomySlice.inputs(fixture, bound.processing_catalog, "wood", "spirit_timber")
	check(float(inputs.wood) == 10 and float(inputs.stone_low) == 5, "processing quote without invented discount")
	print("ECON-C routine smoke failures=", failures)

func life() -> bool:
	for entry in Onboarding.MILESTONES:
		while int(s.state.buildings.get(entry.building,0)) < int(entry.level):
			if not build(entry.building): return false
	if not super.ladder(1): return false
	check(s.state.total_elapsed_seconds < Lifespan.for_state(content.era_lifespan_entries(), s.state), "Era2 lifespan margin")
	if s.state.economy.is_empty() and not send("activate_islands", {"hub":true}): return false
	if not IslandEconomy.hub(s.state) and not send("activate_hub"): return false
	if not opening("wood") or not opening("ore"): return false
	if s.state.reincarnation_count == 0:
		var fixture := s.state.duplicate_state()
		fixture.resources.wood.value = AmountCompat.from_number(141.198949540223)
		fixture.economy.trips.wood_home = {"version":1, "cargo":"8.8010504597774", "remaining":10}
		check(IslandEconomy.validate(fixture).is_empty(), "subprecision reservation roundtrip accepted")
		fixture.resources.wood.value = AmountCompat.from_number(141.199)
		check(IslandEconomy.validate(fixture) == "ECONOMY_RESERVATION_OVERFLOW", "real reservation overflow refused")
		fixture.economy.trips.clear()
		fixture.economy.islands.wood.inventory.wood = "1"
		fixture.resources.wood.value = AmountCompat.from_number(150.0 - 0.00000001)
		check(IslandEconomy.departure_info(fixture, content.processing_catalog, "wood_home", fixture.economy.routes.wood_home).cargo == 0.0, "no subprecision ghost cargo")
		fixture.resources.wood.value = AmountCompat.from_number(150.0 - 0.0000021)
		var micro: float = IslandEconomy.departure_info(fixture, content.processing_catalog, "wood_home", fixture.economy.routes.wood_home).cargo
		check(micro > 0 and String.num(micro, 6).to_float() == micro, "micro cargo lossless storage")
	for id in EconomySlice.RECIPE_GATES:
		rejected("craft", {"recipe_id":id, "island_id":"home"}, "RESEARCH_REQUIRED:"+EconomySlice.RECIPE_GATES[id])
		rejected("switch_processing", {"recipe_id":id, "island_id":"home"}, "RESEARCH_REQUIRED:"+EconomySlice.RECIPE_GATES[id])
	rejected("refine_pill", {"pill_id":"golden_core_pill"}, "RESEARCH_REQUIRED:R06")
	rejected("upgrade_building", {"building_id":"craft_workshop"}, "RESEARCH_REQUIRED:R01")
	rejected("upgrade_island_facility", {"island_id":"wood", "facility_id":"workshop"}, "RESEARCH_REQUIRED:R03")
	if not research("R01") or not build("craft_workshop") or not research("R02") or not research("R03") or not research("R04") or not research("R05"): return false
	# Engineering changes the next batch, never rewrites paid work.
	var upgrade_bill := plain(EconomySlice.building_quote(s.content, s.state, "craft_workshop").costs)
	upgrade_bill.merge({"wood":20, "stone_low":10})
	if not bill(upgrade_bill): return false
	if not send("craft", {"recipe_id":"spirit_timber", "island_id":"wood", "count":2}): return false
	var paid_remaining := int(s.state.economy.jobs.wood.remaining)
	if not build("craft_workshop"): return false
	check(int(s.state.economy.jobs.wood.remaining) == paid_remaining, "upgrade preserves paid duration")
	if not tick(paid_remaining, "paid_old_batch"): return false
	var quote := IslandEconomy.manufacturing_view(s.state, s.content.processing_catalog)
	check(int(s.state.economy.jobs.wood.remaining) == int(quote.recipes.spirit_timber.duration), "next batch uses shared work quote")
	while s.state.economy.jobs.has("wood"):
		if not tick(10, "remaining_batch"): return false
	for facility in ["extractor", "workshop", "storage"]:
		if not bill(IslandProgression.upgrade_cost(facility, 1)): return false
		if not send("upgrade_island_facility", {"island_id":"wood", "facility_id":facility}): return false
	if not super.ladder(2): return false
	check(p.quote_research("R06").get("error") == "RESEARCH_ISLAND", "R06 requires actual Danxia opening")
	if not opening("herb") or not build("core_storehouse_3"): return false
	rejected("craft", {"recipe_id":"liquid", "island_id":"herb"}, "RESEARCH_REQUIRED:R06")
	if not research("R06") or not research("R07"): return false
	for id in ["formation_core", "talisman", "golden_core_pill"]:
		if not ensure(id, 1): return false
	while s.state.level < 10:
		if not bill(plain(Cultivation.level_up_cost(content.eras[3], s.state.level, 0))): return false
		var required := Cultivation.next_level_required_seconds(content.eras[3], s.state.level, 0, 1)
		while s.state.training_seconds + 0.000001 < required:
			if not tick(30, "training:era3"): return false
		if not send("level_up_cultivation"): return false
	check(s.state.skills.is_empty() and s.state.sect.is_empty(), "earned solo without optional skills")
	check(p._research.completed.size() == 7, "all seven earned")
	rejected("breakthrough_era", {}, "ECON_SLICE_NOT_AVAILABLE")
	return true

func run() -> void:
	policy = "econ-c-solo"
	var loaded := EconomySlice.create()
	check(loaded.ok, "slice factory")
	content = loaded.content
	catalog = loaded.catalog
	var opened := EconomyProfile.open(content, memory, catalog, true, 1)
	check(opened.ok, "fresh isolated profile")
	if not opened.ok: print(opened); RunnerResult.finish(self, 1); return
	p = opened.profile; s = p._game
	if OS.get_environment("DAO_ECON_C_EARNED") != "1" and OS.get_environment("DAO_ECON_C_RESUME").is_empty():
		smoke()
		RunnerResult.finish(self, 0 if failures.is_empty() else 1)
		return
	var resume := OS.get_environment("DAO_ECON_C_RESUME")
	var ok := true
	if resume.is_empty():
		ok = life()
	else:
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(resume))
		memory.data = saved.storage
		var restored := EconomyProfile.open(content, memory, catalog)
		check(restored.ok, "resume authentic earned profile")
		if not restored.ok: RunnerResult.finish(self, 1); return
		p = restored.profile; s = p._game
		trace = saved.trace; waits = saved.waits_seconds; witnesses = saved.witnesses
		first_quotes = saved.first_quotes; commands = int(saved.commands); serial = int(saved.serial)
		failures.append_array(saved.failures)
		ok = s.state.era_id == 3 and s.state.level == 10 and s.state.reincarnation_count == 0 and p._research.completed.size() == 7
	check(ok, "first earned life:"+blocked)
	var first_seconds := s.state.total_elapsed_seconds
	if ok and resume.is_empty():
		var checkpoint := FileAccess.open(RunnerResult.output_path("res://econ-r1-c/first-life-checkpoint.json"), FileAccess.WRITE)
		check(checkpoint != null, "earned checkpoint write")
		if checkpoint != null:
			checkpoint.store_string(JSON.stringify({"storage":memory.data, "trace":trace, "waits_seconds":waits, "witnesses":witnesses, "first_quotes":first_quotes, "commands":commands, "serial":serial, "failures":failures}, "", true))
			checkpoint.close()
		print("ECON-C first-life Era3 Lv10 seconds=",first_seconds)
	if ok:
		# Reload authoritative paid state before real lifespan expiry and reincarnation.
		var reloaded := EconomyProfile.open(content, memory, catalog)
		check(reloaded.ok and ResearchSystem.same(reloaded.profile.view(), p.view()), "earned reload all fields")
		var remaining := Lifespan.for_state(content.era_lifespan_entries(), s.state) - s.state.total_elapsed_seconds
		var death := p.advance_time(remaining + 1)
		s = p._game
		check(death.ok and death.stopped != null, "natural elapsed lifespan boundary")
		check(send("reincarnate", {"mode":"normal"}), "earned official reincarnation")
		check(p._research.completed.is_empty() and p._research.job.is_empty(), "research cleared")
		check(int(s.state.buildings.get("craft_workshop",0)) == 0 and int(s.state.buildings.get("research_seat",0)) == 0, "equipment rebuilt each life")
		check(value("formation_core") == 0 and value("spirit_timber") == 0, "no inherited components")
		ok = life()
		check(ok, "second earned life:"+blocked)
	var report := {"task":"ECON-R1-C", "first_seconds":first_seconds, "second_seconds":s.state.total_elapsed_seconds, "era":s.state.era_id, "level":s.state.level, "life":s.state.reincarnation_count, "commands":commands, "waits_seconds":waits, "first_quotes":first_quotes, "research":p._research, "witnesses":witnesses, "trace":trace, "failures":failures, "snapshot_sha256":JSON.stringify(p.view(), "", true).sha256_text()}
	var path := RunnerResult.output_path("res://econ-r1-c/earned-path.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: check(false, "report write")
	else: file.store_string(JSON.stringify(report, "\t", true)); file.close()
	print("ECON-C report=", path, " failures=", failures, " first=",first_seconds, " second=",s.state.total_elapsed_seconds)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
