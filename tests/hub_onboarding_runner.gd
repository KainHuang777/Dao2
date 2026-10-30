extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _init() -> void:
	var s := GameState.new()
	s.era_id = 2
	s.economy = IslandEconomy.initial()
	s.economy.version = IslandProgression.VERSION
	s.economy.hub_version = 1
	s.economy.early_supply = Onboarding.initial_supply()
	for id in ["black_copper", "stone_low", "wood", "bronze_essence", "spirit_timber"]:
		s.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
	check(Onboarding.supply_guidance(s).step == "H1", "first island is ore")
	s.economy.islands.ore.opened = true
	check(Onboarding.supply_guidance(s).route_id == "copper_home", "missing copper directs raw delivery")
	s.resources.black_copper.value = AmountCompat.from_number(10)
	check(Onboarding.supply_guidance(s).route_id == "raw_stone_home", "missing stone has independent route")
	s.resources.stone_low.value = AmountCompat.from_number(5)
	check(Onboarding.supply_guidance(s).step == "H3", "existing home raw stock can craft without invented arrival")
	var before := JSON.stringify(s.economy)
	Onboarding.supply_guidance(s)
	check(JSON.stringify(s.economy) == before, "guidance is read only")
	Onboarding.supply_completed(s, "ore", "bronze_essence")
	check(Onboarding.supply_guidance(s).step == "H4", "actual completion unlocks second introduction")
	s.economy.islands.wood.opened = true
	check(Onboarding.supply_guidance(s).route_id == "wood_home", "missing wood goes to ancestor")
	s.resources.wood.value = AmountCompat.from_number(10)
	check(Onboarding.supply_guidance(s).recipe_id == "spirit_timber", "original timber target retained")
	Onboarding.supply_completed(s, "wood", "spirit_timber")
	check(Onboarding.supply_guidance(s).step == "complete", "spent finished products do not reset tutorial")
	var copied := s.duplicate_state()
	check(Onboarding.supply_guidance(copied) == Onboarding.supply_guidance(s), "snapshot restores same goal")
	s.economy.erase("early_supply")
	check(Onboarding.supply_guidance(s).step == "legacy", "older save is never forced to replay history")
	print(JSON.stringify({"checks": checks, "failures": failures}))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
