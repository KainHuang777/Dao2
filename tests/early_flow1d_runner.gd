extends SceneTree
var checks := 0
var failures: Array[String] = []
var helper = preload("res://src/verification/res1d2_contract.gd").new()
var content: GameContent
var foundation_ready: GameState

class FaultAdapter extends StorageAdapter:
	var data := {}
	var refuse := false
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, value: String) -> Dictionary:
		if refuse:
			return {"ok": false, "error": "QuotaExceededError"}
		data[key] = value
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func step(s: GameSession) -> String:
	return String(s.get_view().early_guidance.get("step", ""))

func meta() -> Dictionary:
	return {"save_id": "early-flow1d", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"}

func persist(s: GameSession) -> GameSession:
	var encoded := SaveCodec.encode(s.state, content.content_version, meta())
	check(encoded.ok, "valid checkpoint")
	if not encoded.ok:
		return s
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok, "checkpoint decode")
	if not decoded.ok:
		return s
	var copy := GameSession.new()
	copy.content = content
	copy.state = decoded.state
	copy.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(copy.get_view().early_guidance == s.get_view().early_guidance, "reload goal preserved")
	return copy

func fixture(s: GameSession, id: String) -> void:
	var m := meta()
	var utc := str(int(Time.get_unix_time_from_system() * 1000))
	m.saved_at_utc_ms = utc
	m.settled_until_utc_ms = utc
	var encoded := SaveCodec.encode(s.state, content.content_version, m)
	check(encoded.ok, "earned browser fixture " + id)
	var file := FileAccess.open("res://docs/verification/artifacts/early-flow1d-" + id + ".json", FileAccess.WRITE)
	check(file != null, "fixture file " + id)
	if file != null:
		file.store_string(encoded.json)

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach(content).ok, "normal attached content")
	helper.content = content
	var source := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/early-flow1c-unopened.json"))
	check(source.ok, "C normal command-earned Foundation input")
	if not source.ok:
		quit(1)
		return
	var s := GameSession.new()
	s.content = content
	s.state = source.state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(helper.send(s, "activate_islands").ok, "activate")
	for id in ["wood", "ore"]:
		check(helper.send(s, "open_island", {"island_id": id}).ok, "open " + id)
	for id in ["ore_wood", "timber_home", "bronze_home"]:
		check(helper.send(s, "configure_route", {"route_id": id, "enabled": true, "target": "100", "reserve": "0", "level": 1}).ok, "route " + id)
	s.advance_time(31)
	for pair in [["wood", "spirit_timber"], ["ore", "bronze_essence"]]:
		check(helper.send(s, "craft", {"island_id": pair[0], "recipe_id": pair[1], "count": 2}).ok, "earned two batches " + pair[0])
	s.advance_time(42)
	print("F1D-STAGE: f1-f4 done level=", s.state.level, " step=", step(s))
	check(step(s) == "F7", "actual supply hands off to F7")
	check(s.get_view().early_guidance.optional_skills and s.get_view().early_guidance.optional_sect, "both branches optional")
	check(s.get_view().early_guidance.skills_route == "storage_wood", "library wood capacity bottleneck")
	check(s.get_view().early_guidance.route == "storage_lingli", "altar prerequisite before reservoir")
	fixture(s, "foundation")
	s = persist(s)
	# Separate branch proves skill and sect operations without gating the main path.
	var branch := persist(s)
	check(helper.build(branch, "storage_wood"), "optional wood capacity")
	check(helper.build(branch, "storage_money") and helper.build(branch, "storage_money"), "optional money capacity")
	check(branch.get_view().early_guidance.skills_route == "library", "capacity sufficient directs library")
	check(helper.build(branch, "library"), "optional library earned")
	check(branch.get_view().early_guidance.skills_route == "skills", "built library directs skill")
	branch.advance_time(90)
	check(helper.send(branch, "learn_skill", {"skill_id": "basic_meditation"}).ok, "optional meditation learned")
	check(not branch.get_view().early_guidance.optional_skills and step(branch) == "F7", "skill completion doesn't replace main goal")
	check(helper.send(branch, "join_sect").ok, "optional sect joined")
	var tasks: Array = branch.state.sect.get("available_tasks", [])
	check(not tasks.is_empty(), "sect offers task")
	if not tasks.is_empty():
		check(helper.send(branch, "start_sect_expedition", {"task_id": tasks[0].id}).ok, "optional task dispatched")
		check(step(branch) == "F7", "dispatch never waits for rewards")
	# Main path never learns a skill or joins a sect.
	check(helper.build(s, "storage_lingli"), "altar tier two earned")
	for _i in range(2):
		check(helper.build(s, "foundation_reservoir"), "reservoir earned")
	check(helper.wait_craft(s, "spirit_timber", "wood"), "repeat spirit_timber producer")
	check(helper.wait_craft(s, "bronze_essence", "ore"), "repeat bronze_essence producer")
	for _i in range(25):
		check(helper.wait_recipe(s, "liquid"), "era2 banked liquid batch " + str(_i))
	print("F1D-STAGE: era2 supply banked level=", s.state.level)
	check(s.state.skills.is_empty() and not bool(s.state.sect.get("unlocked", false)), "main bypasses both optional branches")
	var last_level := s.state.level
	var stall := 0
	for _attempt in range(5000):
		if s.state.level == 10:
			break
		if s.state.level != last_level:
			stall = 0
			last_level = s.state.level
		else:
			stall += 1
			if stall == 1200:
				print("F1D-STAGE: ladder stalled at level=", s.state.level, " timber=", IslandEconomy.value(s.state, "home", "spirit_timber"), " bronze=", IslandEconomy.value(s.state, "home", "bronze_essence"), " liquid=", IslandEconomy.value(s.state, "home", "liquid"))
		if s.get_view().can_level_up:
			check(helper.send(s, "level_up_cultivation").ok, "paid Foundation level")
		else:
			s.advance_time(1)
	print("F1D-STAGE: era ladder result=", s.state.level, " sim=", s.state.total_elapsed_seconds)
	check(s.state.level == 10 and s.get_view().can_breakthrough, "F7 ready normal capacity")
	if s.state.level != 10:
		for failure in failures:
			push_error(failure)
		print("EARLY-FLOW1-D: aborted at F7 ladder; level=", s.state.level)
		quit(1)
		return
	check(s.state.skills.is_empty() and not bool(s.state.sect.get("unlocked", false)), "main bypasses both optional branches")
	s = persist(s)
	foundation_ready = s.state.duplicate_state()
	check(helper.send(s, "breakthrough_era").ok and step(s) == "G1", "real Golden Core without optional branches")
	print("F1D-STAGE: breakthrough era=", s.state.era_id)
	if s.state.era_id != 3:
		for failure in failures:
			push_error(failure)
		print("EARLY-FLOW1-D: aborted at key breakthrough; era=", s.state.era_id)
		quit(1)
		return
	fixture(s, "golden")
	check(helper.send(s, "open_island", {"island_id": "herb"}).ok, "earned Danxia opening")
	s.advance_time(5)
	check(helper.send(s, "craft", {"island_id": "herb", "recipe_id": "liquid", "count": 1}).ok, "liquid start")
	check(step(s) == "G1", "start isn't home delivery")
	s.advance_time(10)
	check(s.get_view().early_guidance.get("route_id", "") == "liquid_home", "completed liquid directs exact route")
	check(helper.send(s, "configure_route", {"route_id": "liquid_home", "enabled": true, "target": "1", "reserve": "0", "level": 1}).ok, "liquid return")
	s.advance_time(1)
	check(step(s) == "G1", "departure isn't arrival")
	s = persist(s)
	s.advance_time(10)
	check(step(s) == "G2" and s.get_view().early_guidance.get("recipe_id", "") == "stone_mid", "actual liquid arrived then mid stone")
	check(helper.wait_recipe(s, "stone_mid", 50), "earned fifty mid stones serial job")
	check(s.get_view().early_guidance.get("recipe_id", "") == "formation_core", "second home recipe follows first")
	check(helper.wait_recipe(s, "formation_core"), "earned core from returned materials")
	check(step(s) == "G3", "all intermediates available")
	check(helper.build(s, "storage_money") and helper.build(s, "storage_money"), "first level money capacity")
	for _attempt in range(1000):
		if s.get_view().can_level_up:
			break
		s.advance_time(1)
	check(s.get_view().can_level_up, "Golden first level ready")
	fixture(s, "ready")
	print("F1D-STAGE: g3 ready level=", s.state.level)
	var before := s.state.duplicate_state()
	check(helper.send(s, "level_up_cultivation").ok and s.state.level == 2 and step(s) == "G4", "G3 actual paid level")
	for id in content.eras[3].level_up_requirements.resources:
		check(IslandEconomy.value(s.state, "home", id) == IslandEconomy.value(before, "home", id) - float(content.eras[3].level_up_requirements.resources[id]), "exact paid " + id)
	s = persist(s)
	check(helper.send(s, "acquire_beast", {"beast_id": "jade_fox"}).ok, "free fox contract")
	check(step(s) == "G4", "acquisition isn't feeding")
	var grass := IslandEconomy.value(s.state, "home", "spirit_grass_low")
	check(helper.send(s, "feed_beast").ok, "first actual fox feed")
	check(IslandEconomy.value(s.state, "home", "spirit_grass_low") == grass - 50, "exact grass feed payment")
	check(step(s) == "complete" and String(s.state.beasts.get("active", {}).get("stage", "")) == "egg" and s.state.beasts.get("active", {}).get("exp", -1) == 50, "first feed remains egg")
	check(not helper.send(s, "feed_beast").ok and s.state.beasts.active.get("exp", -1) == 50, "cooldown rejected without second feed")
	print("F1D-STAGE: g4 done")
	s = persist(s)
	var old := persist(s)
	old.state.economy.erase("early_supply")
	check(step(old) == "complete", "old higher progress never returns to first supply")
	var reborn := s.state.duplicate_state()
	TimeAdvancer.advance(reborn, content, 50000)
	check(ReincarnationRules.apply_reincarnation(reborn, content, "normal").ok, "earned exhaustion reincarnation")
	check(reborn.era_id == 1 and BeastSystem.get_active_beast(reborn).is_empty(), "new life resets beast and era")
	check(Onboarding.early_guidance(reborn, content.era(1), {}, false, false, 0).is_empty(), "new life uses building chain no stale D goal")
	var adapter := FaultAdapter.new()
	SaveManager.configure(content, adapter)
	check(SaveManager.save(before, meta()).ok, "previous valid generation")
	adapter.refuse = true
	var snapshot := helper.snapshot(s.state)
	check(not SaveManager.save(s.state, meta()).ok, "failed completion save reported")
	adapter.refuse = false
	check(SaveManager.save(s.state, meta()).ok and snapshot == helper.snapshot(s.state), "retry saves only no repeated payment or feed")
	SaveManager.configure(content, adapter)
	var restored := SaveManager.current_state()
	check(restored != null, "completion restored")
	if restored != null:
		check(restored.beasts.get("active", {}).get("exp", -1) == 50, "completion restored beast exp")
	var index: Dictionary = JSON.parse_string(adapter.data[SaveSlots.INDEX_KEY])
	adapter.data[index.active_slot] = "broken"
	SaveManager.configure(content, adapter)
	check(SaveManager.current_state() != null, "corrupt generation recovery")
	SaveManager.reset_for_tests()
	print("F1D-STAGE: fault matrix done; entering ui")
	await ui(s)
	print("EARLY-FLOW1-D: ", checks, " checks; normal commands, simulated waits, sim seconds=", s.state.total_elapsed_seconds)
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func ui(s: GameSession) -> void:
	var original := s.state
	var facade = preload("res://src/abode/living_abode.gd")
	facade.save_dir_override = "user://early-flow1d-ui"
	SaveSlots.new(FileStorageAdapter.new(facade.save_dir_override)).reset()
	var scene = preload("res://scenes/living_abode.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.offline_summary.visible = false # Goal layout fixture; startup summary has separate runners.
	scene.session = s
	scene.state = scene.AbodeStateCompat.new(s)
	scene.set_process(false)
	for size in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = size
		scene._layout_for_size(Vector2(size))
		scene._refresh_hud()
		scene._hud_controller._open_current_goal()
		check(scene.feature_navigation.page.is_empty(), "complete navigation " + str(size))
	scene.feature_navigation.open("beasts")
	check(scene.feature_navigation.page == "beasts", "canonical beast route")
	for id in ["foundation", "golden", "ready"]:
		var saved := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/early-flow1d-" + id + ".json"))
		if not saved.ok:
			check(false, "fixture decode " + id)
			continue
		s.state = saved.state
		scene._refresh_hud()
		scene._hud_controller._open_current_goal()
		check(scene.feature_navigation.page == ("outposts" if id == "golden" else ("buildings" if id == "foundation" else "")), "exact goal route " + id)
		if id == "foundation":
			scene._hud_controller._open_optional_skills()
			check(scene.feature_navigation.page == "buildings" and scene.selected_id == "storage_wood", "optional skill routes capacity")
			scene.feature_navigation.home()
			for size in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
				root.size = size
				scene._layout_for_size(Vector2(size))
				scene._refresh_hud()
				scene._hud_controller.show_messages()
				scene._layout_for_size(Vector2(size))
				scene._refresh_hud()
				check(scene.hint_panel.visible and not scene.island_world.rail.visible, "explicit explanation replaces rail " + str(size))
				check(scene._hud_controller._skills_action.visible and scene._hud_controller._sect_action.visible, "both optional actions " + str(size))
				scene._hud_controller._toggle_guidance()
				scene._refresh_hud() # normal frame refresh; this test disables _process
				check(scene.island_world.rail.visible, "closing explanation restores rail " + str(size))
	s.state = foundation_ready.duplicate_state()
	scene.feature_navigation.home()
	for size in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
		root.size = size
		scene._layout_for_size(Vector2(size))
		scene._refresh_hud()
		await process_frame
		scene._layout_for_size(Vector2(size))
		check(s.get_view().can_breakthrough, "earned Foundation10 eligible " + str(size))
		check(scene.breakthrough_button.visible and scene.breakthrough_button.get_parent().visible and not scene.breakthrough_button.disabled, "actual Golden Core primary action reachable " + str(size))
		check(scene.breakthrough_button.text.contains("金丹期"), "primary action names actual next era " + str(size))
		check(Rect2(Vector2.ZERO, Vector2(size)).encloses(scene.breakthrough_button.get_global_rect()) and scene.breakthrough_button.size.y >= 44, "Golden Core primary action fits hit area " + str(size))
	# Real button signal must submit the normal command, not just display eligibility.
	scene.breakthrough_button.pressed.emit()
	check(s.state.era_id == 3 and s.state.level == 1, "primary button actually performs earned Golden Core breakthrough")
	check(step(s) == "G1", "button breakthrough hands off to Danxia guidance")
	scene.queue_free()
	await process_frame
	s.state = original
	facade.save_dir_override = ""
