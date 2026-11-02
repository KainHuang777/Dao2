extends SceneTree
var checks := 0
var failures: Array[String] = []
var helper = preload("res://src/verification/res1d2_contract.gd").new()
var content: GameContent

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func step(s: GameSession) -> String:
	return String(s.get_view().early_guidance.get("step", ""))

func meta() -> Dictionary:
	return {"save_id": "early-flow1d-hub", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply content")
	var source := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/early-flow1d-golden.json"))
	check(source.ok, "golden fixture")
	if not source.ok:
		_finish()
		return
	var prepared := IslandProgression.prepare_supply(content, source.state)
	check(prepared.ok, "migrate to supply")
	if not prepared.ok:
		_finish()
		return
	var s := GameSession.new()
	s.content = content
	s.clock = GameClock.create(prepared.state.total_elapsed_seconds)
	s.state = prepared.state
	helper.content = content
	helper.serial = 100000
	var non_hub_state: GameState = prepared.state.duplicate_state()
	check(s.state.economy.get("version") == IslandProgression.SUPPLY_VERSION and not IslandEconomy.hub(s.state), "migrated state is SUPPLY without hub")
	check(step(s) == "G1", "golden fixture sits at G1")
	check(helper.send(s, "activate_hub").ok and IslandEconomy.hub(s.state), "hub activated")
	var goal: Dictionary = s.get_view().early_guidance
	check(step(s) == "G1" and String(goal.get("route", "")) == "outposts" and String(goal.get("island_id", "")) == "herb", "hub opens Danxia before liquid")
	check(helper.send(s, "open_island", {"island_id": "herb"}).ok, "open Danxia")
	goal = s.get_view().early_guidance
	check(step(s) == "G1" and String(goal.get("route", "")) == "manufacturing" and String(goal.get("island_id", "")) == "herb" and String(goal.get("recipe_id", "")) == "liquid", "hub directs Danxia liquid")
	check(helper.send(s, "craft", {"island_id": "herb", "recipe_id": "liquid", "count": 1}).ok, "hub liquid start")
	s.advance_time(10)
	check(IslandEconomy.value(s.state, "home", "liquid") >= 1, "hub output landed on home")
	check(step(s) == "G2", "hub stores at home advances G2")
	check(not s.state.economy.routes.has("liquid_home"), "no liquid return route configured")
	check(helper.wait_recipe(s, "stone_mid", 50), "hub banked fifty mid stones")
	check(helper.wait_recipe(s, "formation_core", 1), "hub banked core")
	check(step(s) == "G3", "hub G3 intermediates ready")
	check(helper.build(s, "storage_money") and helper.build(s, "storage_money"), "hub first level money capacity")
	for _attempt in range(1000):
		if s.get_view().can_level_up:
			break
		s.advance_time(1)
	check(s.get_view().can_level_up, "hub Golden first level ready")
	var before := s.state.duplicate_state()
	check(helper.send(s, "level_up_cultivation").ok and s.state.level == 2 and step(s) == "G4", "hub G3 actual paid level")
	for id in content.eras[3].level_up_requirements.resources:
		check(IslandEconomy.value(s.state, "home", id) == IslandEconomy.value(before, "home", id) - float(content.eras[3].level_up_requirements.resources[id]), "hub exact paid " + id)
	check(helper.send(s, "acquire_beast", {"beast_id": "jade_fox"}).ok, "free fox contract")
	check(step(s) == "G4", "acquisition isn't feeding")
	var grass := IslandEconomy.value(s.state, "home", "spirit_grass_low")
	check(helper.send(s, "feed_beast").ok, "first actual fox feed")
	check(IslandEconomy.value(s.state, "home", "spirit_grass_low") == grass - 50, "exact grass feed payment")
	check(step(s) == "complete" and String(s.state.beasts.get("active", {}).get("stage", "")) == "egg" and s.state.beasts.get("active", {}).get("exp", -1) == 50, "first feed remains egg")
	check(not helper.send(s, "feed_beast").ok and s.state.beasts.active.get("exp", -1) == 50, "cooldown rejected without second feed")
	var encoded := SaveCodec.encode(s.state, content.content_version, meta())
	check(encoded.ok, "hub completion encode")
	if not encoded.ok:
		_finish()
		return
	var decoded := SaveCodec.decode(String(encoded.get("json", "")))
	check(decoded.ok, "hub completion decode")
	if not decoded.ok:
		_finish()
		return
	var reloaded := GameSession.new()
	reloaded.content = content
	reloaded.clock = GameClock.create(s.state.total_elapsed_seconds)
	reloaded.state = decoded.state
	check(reloaded.get_view().early_guidance == s.get_view().early_guidance, "hub reload guidance preserved")
	check(reloaded.state.era_id == 3 and reloaded.state.level == 2, "hub reload era level")
	check(reloaded.state.beasts.get("active", {}).get("exp", -1) == 50, "hub reload beast exp")
	var gate := GameSession.new()
	gate.content = content
	gate.clock = GameClock.create(non_hub_state.total_elapsed_seconds)
	gate.state = non_hub_state.duplicate_state()
	gate.state.era_id = 2
	gate.state.level = 10
	gate.state.training_seconds = 0.0
	check(step(gate) == "F7", "SUPPLY non-hub era2 stays at F7")
	check(not String(gate.get_view().early_guidance.get("title", "")).contains("開拓玄礦島"), "SUPPLY non-hub not frozen outposts goal")
	check(String(gate.get_view().early_guidance.get("text", "")).contains("靈材20") and String(gate.get_view().early_guidance.get("text", "")).contains("丹液5"), "F7 states graded era2 costs")
	check(gate.get_view().can_breakthrough, "SUPPLY non-hub era2 can break through")
	check(helper.send(gate, "activate_hub").ok and IslandEconomy.hub(gate.state), "gate state hub activated")
	check(gate.get_view().can_breakthrough, "hub activation keeps breakthrough open")
	check(helper.send(gate, "breakthrough_era").ok, "SUPPLY hub era2 breaks through")
	check(gate.state.era_id == 3 and gate.state.level == 1, "hub gate breakthrough reaches golden core")
	var n := GameSession.new()
	n.content = content
	n.clock = GameClock.create(non_hub_state.total_elapsed_seconds)
	n.state = non_hub_state.duplicate_state()
	n.state.era_id = 2
	n.state.level = 10
	n.state.training_seconds = 0.0
	check(not IslandEconomy.hub(n.state), "non-hub state stays non-hub")
	check(helper.send(n, "breakthrough_era").ok, "non-hub SUPPLY passes gate")
	check(n.state.era_id == 3, "non-hub reaches golden core")
	var non_hub_goal: Dictionary = n.get_view().early_guidance
	check(step(n) == "G1" and String(non_hub_goal.get("route", "")) == "outposts" and String(non_hub_goal.get("island_id", "")) == "herb", "non-hub directed to Danxia")
	check(not String(non_hub_goal.get("title", "")).contains("啟用金丹產業"), "non-hub not dead-end hub goal")
	print("EARLY-FLOW1D-HUB: ", checks, " checks; hub era=", s.state.era_id, " level=", s.state.level, "; non-hub era=", n.state.era_id)
	_finish()

func _finish() -> void:
	for failure in failures:
		push_error(failure)
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
