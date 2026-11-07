extends "res://tests/econ_r1_frontier_runner.gd"
## Explicit funded sensitivity experiment; no claim of earned sect progression.
func network_total(state: GameState, resource: String) -> float:
	var total := IslandEconomy.value(state,"home",resource)
	for island in state.economy.islands:
		if island != "home": total += IslandEconomy.value(state,island,resource)
	for route in state.economy.trips:
		if IslandEconomy.route_defs(state)[route][2] == resource: total += float(state.economy.trips[route].cargo)
	return total

func quote_prerequisites(research: Dictionary, id: String) -> void:
	for prerequisite in ResearchSystem.node_for(catalog,id).prerequisites:
		quote_prerequisites(research,prerequisite)
		research.completed[prerequisite] = true
		research.mastered[prerequisite] = true

func run() -> void:
	policy = "econ-d2-funded-sensitivity"
	var loaded := EconomySlice.create_frontier()
	content = loaded.content; catalog = loaded.catalog
	p = EconomyProfile.open(content,memory,catalog,true,1).profile; s = p._game
	var era_lifespans := {}
	for era in range(1,7): era_lifespans[str(era)] = Lifespan.max_lifespan_seconds(content.era_lifespan_entries(),era)
	check(era_lifespans["4"]==65400 and era_lifespans["6"]==158400,"runtime cumulative lifespan, correcting D1 handoff estimate")
	var rows: Array = []
	for sect in ["solo", "taixu_sect", "tianjian_sect", "piaomiao_sect", "wanfo_sect", "zixiao_sect"]:
		var probe := fixture_profile()
		var state := probe._game.state
		if sect != "solo":
			check(SectSystem.join_sect(state,sect).ok,"scenario join "+sect)
			state.sect.contribution = "5000" # declared synthetic equal investment budget
			state.resources.stone_low.value = AmountCompat.from_number(1000)
			for group in ["A", "B"]:
				for id in SectSpecialization.METHODS:
					if SectSpecialization.METHODS[id][0] != sect or SectSpecialization.METHODS[id][1] != group: continue
					for rank in 3: check(SectSpecialization.learn(state,id).ok,"paid rank "+id+str(rank))
		check(probe._stage(probe._game,probe._research,{"ok":true}).ok,"save scenario "+sect)
		state = probe._game.state
		var before_training := state.training_seconds
		var before_iron := network_total(state,"refined_iron")
		var before_herb := network_total(state,"spirit_grass_1000y")
		var timing := EconomySlice.duration(state,probe._game.content.processing_catalog,"home","stone_mid_bulk")
		var core_seconds := EconomySlice.duration(state,probe._game.content.processing_catalog,"home","formation_core")
		var life := Lifespan.for_state(content.era_lifespan_entries(),state)
		var capacity := IslandEconomy.home_cap(state,"lingli",content.processing_catalog)
		check(probe.advance_time(60).ok,"60 real rule seconds "+sect)
		state = probe._game.state
		rows.append({"sect":sect,"basis":"funded Era6 / A3+B3; 60 authoritative seconds; not earned playthrough", "budget_contribution":0 if sect=="solo" else 5000,"spent_contribution":0 if sect=="solo" else 5000-float(state.sect.contribution),"bulk_seconds":timing,"core_seconds":core_seconds,"training_delta":state.training_seconds-before_training,"iron_delta":network_total(state,"refined_iron")-before_iron,"herb_delta":network_total(state,"spirit_grass_1000y")-before_herb,"lifespan_seconds":life,"lingli_cap":capacity})
		var reloaded := EconomyProfile.open(content,probe._storage._base,catalog)
		check(reloaded.ok and ResearchSystem.same(probe.view(),reloaded.profile.view()),"scenario full reload "+sect)
	check(rows[1].training_delta > rows[0].training_delta,"taixu training specializes")
	check(rows[2].iron_delta > rows[0].iron_delta and rows[2].core_seconds < rows[0].core_seconds,"tianjian metal specializes")
	check(rows[3].herb_delta > rows[0].herb_delta,"piaomiao herbs specialize")
	check(rows[4].lifespan_seconds > rows[0].lifespan_seconds,"wanfo lifespan specializes")
	check(rows[5].lingli_cap > rows[0].lingli_cap,"zixiao capacity specializes")
	var probe := fixture_profile()
	var quotes := {}
	for node in catalog.nodes:
		var empty := ResearchSystem.initial()
		# Valid ancestor-only completed DAG, rather than impossible descendants.
		quote_prerequisites(empty,node.id)
		check(ResearchSystem.validate(empty,catalog).is_empty(),"valid first quote state "+node.id)
		var q := ResearchSystem.quote(catalog,empty,probe._game.state,node.id)
		check(q.ok,"before quote "+node.id+":"+str(q))
		quotes[node.id] = q
	probe._game.state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(),probe._game.state)-1 # boundary fixture
	check(probe._stage(probe._game,probe._research,{"ok":true}).ok,"save death-boundary fixture")
	check(probe.advance_time(2).get("stopped") == "lifespan_exhausted","executed natural boundary tick")
	check(probe.submit({"type":"reincarnate","payload":{"mode":"normal"},"command_id":"scenario-rebirth","expected_revision":probe._game.state.revision}).ok,"official scenario reincarnation")
	check(probe._research.completed.is_empty() and probe._research.job.is_empty() and probe._research.inherited_depth >= 6,"frontier research reset and inherited")
	for id in ["mithril_matrix","void_array"]: check(probe._game.state.resources[id].value.to_float()==0,"no component inheritance "+id)
	for id in EconomySlice.component_data().buildings: check(probe._game.state.buildings.get(id.id,0)==0,"no equipment inheritance "+id.id)
	var inherited := probe._research.duplicate(true)
	var timings: Array = []
	var quote_state := fixture_profile()._game.state
	quote_state.resources.stone_mid.ever_obtained = true
	for node in catalog.nodes:
		inherited.completed.clear()
		quote_prerequisites(inherited,node.id)
		check(ResearchSystem.validate(inherited,catalog).is_empty(),"valid inherited quote state "+node.id)
		var q := ResearchSystem.quote(catalog,inherited,quote_state,node.id)
		check(q.ok and int(q.get("duration",0)) < int(quotes[node.id].get("duration",0)) and ResearchSystem.same(q.paid,quotes[node.id].paid),"inherit time only "+node.id)
		timings.append({"id":node.id,"first_seconds":quotes[node.id].get("duration"),"next_seconds":q.get("duration"),"paid":q.get("paid")})
	write_report("sensitivity",{"task":"ECON-R1-D2","scope":"funded sensitivity and death-boundary fixture; not earned five-sect/multi-life playthrough","era_lifespans_seconds":era_lifespans,"sects":rows,"research_rebuild":timings,"failures":failures})
	print("ECON-D2 sensitivity=",rows," failures=",failures)
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
