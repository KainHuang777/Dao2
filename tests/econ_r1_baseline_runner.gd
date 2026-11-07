extends SceneTree
## Read-only current-edition analysis. All gameplay uses isolated fresh Sessions.
var content: GameContent
var s: GameSession
var serial := 0
var failures: Array = []
var trace: Array = []
var waits := {}
var blocked := ""
var stack: Array = []
var policy := ""
var commands := 0
const HORIZON := 172800.0
# Routine regression covers the repaired bootstrap through the Era3 entrance.
# Opt in to the expensive downstream observation; it is not a daily L1 check.
var stage_limit := 6 if OS.get_environment("DAO_ECON_A_FULL_BASELINE") == "1" else 2
var selected_policy := OS.get_environment("DAO_ECON_A_POLICY")

class MemoryAdapter extends StorageAdapter:
	var data := {}
	var reject_candidate := false
	func read(key: String) -> Dictionary:
		return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
	func write(key: String, payload: String) -> Dictionary:
		if reject_candidate and payload.contains('"hub_version"'): return {"ok":false,"error":"injected activation write failure"}
		data[key] = payload
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}
	func exists(key: String) -> bool: return data.has(key)

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(policy+":"+label)

func activation_checks() -> void:
	# Use the earned Era2 state, before any processing activation or stock grant.
	var probe := GameSession.new()
	probe.content = content
	probe.state = s.state.duplicate_state()
	probe.clock = GameClock.create(probe.state.total_elapsed_seconds)
	var before := probe.state.to_snapshot_dict()
	check(not probe.state.resources.spirit_timber.unlocked,"fresh timber initially locked")
	var mem := MemoryAdapter.new()
	SaveManager.configure(content,mem)
	var meta := {"save_id":"econ-a-activation","saved_at_utc_ms":"0","settled_until_utc_ms":"0","sim_tick":str(int(probe.state.total_elapsed_seconds))}
	mem.reject_candidate = true
	check(not SaveManager.activate_islands(probe,meta).ok,"candidate save rejection")
	check(before == probe.state.to_snapshot_dict(),"failed activation preserves live state")
	var archive: String = mem.data.get(SaveManager.ISLAND_ARCHIVE_KEY,"")
	check(not archive.is_empty(),"source archive retained")
	mem.reject_candidate = false
	check(SaveManager.activate_islands(probe,meta).ok,"activation retry")
	check(mem.data.get(SaveManager.ISLAND_ARCHIVE_KEY) == archive,"retry preserves source archive")
	for id in content.processing_catalog.resources:
		check(probe.state.resources[id].unlocked == (int(content.processing_catalog.resources[id].era) <= 2),"activation Era gate "+id)
		check(probe.state.resources[id].value.serialize() == s.state.resources[id].value.serialize(),"activation stock preserved "+id)
		check(probe.state.resources[id].ever_obtained == s.state.resources[id].ever_obtained,"activation history preserved "+id)
	SaveManager.configure(content,mem)
	var loaded: Variant = SaveManager.load_state()
	# JSON restores integral numbers as floats and StringName keys as strings.
	# Compare all fields using the codec's canonical representation.
	check(loaded != null and JSON.stringify(SaveCodec._normalize_numbers(loaded.to_snapshot_dict()),"",true) == JSON.stringify(SaveCodec._normalize_numbers(probe.state.to_snapshot_dict()),"",true),"committed activation reload")
	var committed := probe.state.to_snapshot_dict()
	check(not SaveManager.activate_islands(probe,meta).ok and committed == probe.state.to_snapshot_dict(),"activation cannot repeat")
	# Historical missing-slot form still receives an empty, Era-gated slot.
	var old := s.state.duplicate_state()
	old.resources.erase("spirit_timber")
	check(IslandEconomy.command(content,old,"migrate_processing",{}).ok,"missing-slot migration")
	check(old.resources.spirit_timber.unlocked and old.resources.spirit_timber.value.to_float() == 0 and not old.resources.spirit_timber.ever_obtained,"missing-slot initialization")

func _init() -> void: run.call_deferred()

func plain(values: Dictionary) -> Dictionary:
	var out := {}
	for id in values: out[id] = values[id].to_float() if values[id] is AmountCompat else values[id]
	return out

func send(kind: String, payload: Dictionary = {}) -> bool:
	serial += 1
	var before := {}
	if kind != "gather":
		before = {"caps":caps(),"buildings":s.state.buildings.duplicate(true)}
	var result := s.submit({"type":kind,"payload":payload,"command_id":"econ-a-"+str(serial),"expected_revision":s.state.revision})
	commands += 1
	if not result.ok:
		blocked = kind+":"+str(payload)+":"+str(result.get("error"))
		return false
	if kind != "gather": trace.append({"seconds":s.state.total_elapsed_seconds,"kind":kind,"payload":payload.duplicate(true),"era":s.state.era_id,"level":s.state.level,"before":before})
	return true

func tick(seconds: float, reason: String) -> bool:
	if s.state.total_elapsed_seconds + seconds > HORIZON:
		blocked = "observation_horizon:"+reason
		return false
	var result := s.advance_time(seconds)
	waits[reason] = float(waits.get(reason,0)) + seconds
	if not result.get("ok",false) or result.get("stopped") != null:
		blocked = "time:"+str(result.get("stopped",result.get("error")))
		return false
	return true

func value(id: String) -> float: return s.state.resources[id].value.to_float()
func caps() -> Dictionary: return plain(Production.compute_caps(content,s.state.buildings,s.state.era_id,s.state.onboarding_version,s.state.skills))

func bill(costs: Dictionary) -> bool:
	# Later ingredients can consume earlier ingredients; settle the entire bill.
	for attempt in 8:
		for id in costs:
			if not ensure(id,float(costs[id])): return false
		var ready := true
		for id in costs:
			if value(id)+0.000001 < float(costs[id]): ready = false
		if ready: return true
	blocked = "bill_contention:"+str(costs)
	return false

func capacity(id: String, target: float) -> bool:
	for attempt in 40:
		if float(caps().get(id,0)) + 0.000001 >= target: return true
		var candidates: Array = []
		for b in content.building_ids:
			var d: Dictionary = content.buildings[b]
			if int(d.era) > s.state.era_id or int(s.state.buildings.get(b,0)) >= CommandProcessor.level_cap(d,content,s.state) or b in stack: continue
			if d.effects.has(id+"_max") or (d.effects.has("all_max") and id in Production.BASIC_RESOURCE_KEYS): candidates.append(b)
		var built := false
		for b in candidates:
			if build(b): built = true; break
		if not built:
			blocked = "capacity:"+id+":"+str(target)+":cap="+str(caps().get(id,0))
			return false
	return false

func build(id: String) -> bool:
	if id in stack or stack.size() > 20: return false
	var d: Dictionary = content.buildings[id]
	if int(d.era) > s.state.era_id: return false
	stack.append(id)
	if d.prereq != null:
		while int(s.state.buildings.get(d.prereq.building,0)) < int(d.prereq.level):
			if not build(d.prereq.building): stack.pop_back(); return false
	var cost := plain(BuildingCosts.compute_cost(BuildingCosts.resolve_base_cost(id,d.base_cost,Onboarding.is_active(s.state.onboarding_version,s.state.era_id)),int(s.state.buildings.get(id,0)),float(d.cost_factor)))
	var ok := bill(cost) and send("upgrade_building",{"building_id":id})
	stack.pop_back()
	return ok

func ensure(id: String, target: float, depth: int = 0) -> bool:
	if depth > 15: blocked = "ingredient_cycle:"+id; return false
	if not capacity(id,target): return false
	for attempt in 10000:
		if value(id)+0.000001 >= target: return true
		var recipe := "stone_mid_bulk" if id == "stone_mid" and s.state.era_id >= 4 else id
		if content.processing_catalog.recipes.has(recipe):
			var d: Dictionary = content.processing_catalog.recipes[recipe]
			if int(d.era) > s.state.era_id: blocked = "recipe_era:"+recipe; return false
			var lane := "wood" if recipe == "spirit_timber" else ("ore" if recipe == "bronze_essence" else "home")
			if recipe == "liquid" and s.state.era_id >= 3: lane = "herb"
			if lane == "home":
				for facility in d.facility:
					while int(s.state.buildings.get(facility,0)) < int(d.facility[facility]):
						if not build(facility): return false
			var count := mini(100,maxi(1,int(ceil((target-value(id))/float(d.output)))))
			var current_caps := caps()
			for input in d.inputs: count = mini(count,maxi(1,int(floor(float(current_caps[input])/float(d.inputs[input])))))
			for input in d.inputs:
				if not ensure(input,float(d.inputs[input])*count,depth+1): return false
			if not send("craft",{"recipe_id":recipe,"island_id":lane,"count":count}): return false
			while s.state.economy.get("jobs",{}).has(lane):
				if not tick(10,"craft:"+recipe): return false
		else:
			# One legal gather per simulated second in Era1; no stock injection.
			if s.state.era_id == 1 and content.resources[id].type == "basic" and s.state.resources[id].unlocked:
				if not send("gather",{"resource_id":id}) or not tick(1,"gather:"+id): return false
			else:
				if not tick(60,"supply:"+id): return false
	blocked = "supply_timeout:"+id
	return false

func opening(id: String) -> bool:
	var d: Dictionary = IslandEconomy.island_defs(s.state)[id]
	if not bill(d.get("cost",{"wood":20,"stone_low":10})) or not send("open_island",{"island_id":id}): return false
	for route in IslandEconomy.route_defs(s.state):
		var r: Array = IslandEconomy.route_defs(s.state)[route]
		if r[0] == id and r[1] == "home":
			if not send("configure_route",{"route_id":route,"enabled":true,"target":"3000","reserve":"0"}): return false
	return true

func ladder(era: int) -> bool:
	while s.state.level < 10:
		if not bill(plain(Cultivation.level_up_cost(content.eras[era],s.state.level,0))): return false
		var required := Cultivation.next_level_required_seconds(content.eras[era],s.state.level,0,1)
		while s.state.training_seconds+0.000001 < required:
			if not tick(30,"training:era"+str(era)): return false
		if not send("level_up_cultivation"): return false
	if era == 6: return true
	for id in content.eras[era].get("upgrade_requirements",{}).get("capacity",{}):
		if not capacity(id,float(content.eras[era].upgrade_requirements.capacity[id])): return false
	for attempt in 20:
		if not send("breakthrough_era"): return false
		if s.state.era_id == era+1: return true
		if s.state.era_id != era: blocked = "tribulation_regression"; return false
		if not ladder(era): return false
	return false

func baseline(name: String) -> Dictionary:
	policy = name; s = GameSession.create_new_game(content,1)
	trace = []; waits = {}; blocked = ""; stack = []; commands = 0
	var milestones: Array = []
	var ok := true
	# Same opening gates; compare optional investments at the first branch.
	for entry in Onboarding.MILESTONES:
		while int(s.state.buildings.get(entry.building,0)) < int(entry.level):
			if not build(entry.building): ok = false; break
		if not ok: break
	if ok and name == "production_first":
		for id in ["wooden_house","forest_farm","stone_mine","herb_farm"]:
			if not build(id): ok = false; break
	if ok and name == "capacity_first":
		for id in ["storage_lingli","storage_money","storage_wood","storage_stone","storage_herb"]:
			if not build(id): ok = false; break
	for era in range(1,stage_limit+1):
		if not ok: break
		if era == 2:
			activation_checks()
			ok = send("activate_islands",{"hub":true}) and opening("ore") and opening("wood")
		if era == 3: ok = opening("herb") and build("core_storehouse_3")
		if era == 4: ok = opening("deep") and build("mineral_focus") and build("core_storehouse_4") and build("cultivation_focus_4")
		if era == 5: ok = opening("ancient") and build("ancient_focus") and build("core_storehouse_5") and build("cultivation_focus_5")
		if era == 6: ok = opening("void") and build("void_focus") and build("cultivation_focus_6")
		if ok: ok = ladder(era)
		milestones.append({"stage":era,"completed":ok,"seconds":s.state.total_elapsed_seconds,"caps":caps(),"buildings":s.state.buildings.duplicate(true)})
		print("ECON-A ",name," stage=",era," ok=",ok," seconds=",s.state.total_elapsed_seconds," blocked=",blocked if not ok else "")
	var encoded := SaveCodec.encode(s.state,content.content_version,{"save_id":"econ-a-isolated","saved_at_utc_ms":"0","settled_until_utc_ms":"0","sim_tick":str(int(s.state.total_elapsed_seconds))})
	if not encoded.ok or not SaveCodec.decode(encoded.get("json","")).ok: failures.append(name+":snapshot")
	if not s.state.skills.is_empty() or not s.state.sect.is_empty(): failures.append(name+":solo_contract")
	var locked: Array = []
	for id in s.state.resources:
		if not s.state.resources[id].unlocked: locked.append(id)
	# This regression must pass through real first batches and the first paid level.
	check(s.state.era_id > 2 or s.state.level > 1,"earned first Era2 level:"+blocked)
	for recipe in ["spirit_timber","bronze_essence"]:
		check(trace.any(func(row): return row.kind == "craft" and row.payload.get("recipe_id") == recipe),"earned first batch "+recipe)
	return {"policy":name,"completed_era6":ok and s.state.era_id==6 and s.state.level==10,"stop_reason":blocked if not ok else ("era6_level10" if stage_limit == 6 else "checkpoint:era3_entrance"),"seconds":s.state.total_elapsed_seconds,"era":s.state.era_id,"level":s.state.level,"commands":commands,"waits_seconds":waits.duplicate(true),"milestones":milestones,"trace":trace.duplicate(true),"locked_resources":locked,"snapshot_sha256":encoded.get("json","").sha256_text()}

func run() -> void:
	var loaded := ContentLoader.load_directory("res://content")
	if not loaded.ok: RunnerResult.finish(self,1); return
	content = loaded.content
	if not IslandProgression.attach_supply(content).ok: RunnerResult.finish(self,1); return
	s = GameSession.create_new_game(content,1)
	var cost_tables := {}
	for id in content.building_ids:
		var d: Dictionary = content.buildings[id]
		var rows: Array = []
		for level in CommandProcessor.level_cap(d,content,s.state):
			rows.append({"from_level":level,"costs":plain(BuildingCosts.compute_cost(BuildingCosts.resolve_base_cost(id,d.base_cost,int(d.era)==1),level,float(d.cost_factor)))})
		cost_tables[id] = rows
	var cultivation := {}
	for era in content.era_ids:
		var levels: Array = []
		for level in range(1,10): levels.append({"level":level,"costs":plain(Cultivation.level_up_cost(content.eras[era],level,0)),"training_seconds":Cultivation.next_level_required_seconds(content.eras[era],level,0,1)})
		cultivation[str(era)] = levels
	# Definition-only expanded state is separate from earned Sessions above.
	var definitions := GameState.new()
	definitions.economy = {"version":IslandProgression.SUPPLY_VERSION,"hub_version":1}
	var report := {"task":"ECON-R1-A","engine":Engine.get_version_info().string,"content_version":content.content_version,"resources":content.resources,"buildings":content.buildings,"eras":content.eras,"skills":content.skill_defs,"catalog":content.processing_catalog,"islands":IslandEconomy.island_defs(definitions),"routes":IslandEconomy.route_defs(definitions),"durations":IslandEconomy.durations(definitions),"building_costs":cost_tables,"cultivation":cultivation,"onboarding_milestones":Onboarding.MILESTONES,"legacy_hut_first_cost":plain(BuildingCosts.compute_cost(BuildingCosts.resolve_base_cost("hut",content.buildings.hut.base_cost,false),0,1.5)),"strategies":[]}
	for name in ["production_first","capacity_first","progression_first"]:
		if not selected_policy.is_empty() and name != selected_policy: continue
		report.strategies.append(baseline(name))
		await process_frame
	check(not report.strategies.is_empty(),"valid policy selector")
	report.failures = failures
	report.stage_limit = stage_limit
	var path := RunnerResult.output_path("res://econ-r1-a/runtime-baseline.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures.append("output_write")
	else: file.store_string(JSON.stringify(report,"\t",true)); file.close()
	print("ECON-A report=",path," failures=",failures)
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
