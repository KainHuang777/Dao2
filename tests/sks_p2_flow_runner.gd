extends SceneTree
const DIR := "res://docs/verification/artifacts/sks-p2-flow/"
const SOURCE_DIR := "res://docs/verification/artifacts/content-p2-supply-3/"
const ALL_P2 := ["nascent_soul_incubation", "nascent_soul_mastery", "heavenly_craft", "deep_vein_resonance", "void_expansion", "spirit_transformation", "ancient_herb_attunement", "spirit_sea_breath", "void_mastery", "void_refinement", "void_essence_attunement", "frontier_storekeeping"]
const P2_BY_ERA := {
	4: ["nascent_soul_incubation", "nascent_soul_mastery", "heavenly_craft", "deep_vein_resonance"],
	5: ["void_expansion", "spirit_transformation", "ancient_herb_attunement", "spirit_sea_breath"],
	6: ["void_mastery", "void_refinement", "void_essence_attunement", "frontier_storekeeping"],
}
const EXPECT := {
	"nascent_soul_incubation": ["1.150", "1.322"],
	"nascent_soul_mastery": ["0.950", "0.902"],
	"heavenly_craft": ["0.95", "0.90"],
	"deep_vein_resonance": ["1.100", "1.210"],
	"void_expansion": ["1.100", "1.210"],
	"spirit_transformation": ["0.930", "0.865"],
	"ancient_herb_attunement": ["1.100", "1.210"],
	"spirit_sea_breath": ["1.150", "1.322"],
	"void_mastery": ["1.100", "1.210"],
	"void_refinement": ["0.900", "0.810"],
	"void_essence_attunement": ["1.100", "1.210"],
	"frontier_storekeeping": ["+100", "+200"],
}
const META := {"save_id": "sksp2-flow", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}
var content: GameContent
var s: GameSession
var serial := 0
var checks := 0
var failures: Array[String] = []
var era_reports := {}
var sources := {}
var reject_report := {}

class ToggleAdapter extends StorageAdapter:
	var backend := FileStorageAdapter.new("user://sks-p2-flow-fault")
	var fail_writes := false
	func read(key: String) -> Dictionary: return backend.read(key)
	func write(key: String, value: String) -> Dictionary:
		return {"ok":false,"error":"R8_WRITE_DENIED"} if fail_writes else backend.write(key,value)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func exists(key: String) -> bool: return backend.exists(key)

func _init() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FLOW FAILURE ", label)

func send(kind: String, payload: Dictionary = {}) -> Dictionary:
	serial += 1
	return s.submit({"type":kind, "payload":payload, "command_id":"sksp2-flow-" + str(serial), "expected_revision":s.state.revision})

func value(id: String) -> float:
	return IslandEconomy.value(s.state, "home", id)

func view_item(id: String) -> Dictionary:
	for item in SkillSystem.view(content, s.state).items:
		var entry: Dictionary = item
		if String(entry.id) == id:
			return entry
	return {}

func item_reason(id: String) -> String:
	return String(view_item(id).get("reason", ""))

func advance(seconds: int) -> Dictionary:
	return s.advance_time(float(seconds))

func ensure_home(id: String, target: float) -> bool:
	for attempt in 40:
		if value(id) + 0.000001 >= target:
			return true
		var rate := float(s.get_view().resources[id].rate)
		if rate <= 0.0:
			return false
		var step := maxi(1, int(ceil((target - value(id)) / rate)) + 1)
		var result := advance(step)
		if result.get("stopped") != null:
			check(false, "time stopped while waiting for " + id + ": " + str(result.stopped))
			return false
	check(false, "resource wait timeout " + id)
	return false

func ensure_points(cost: float) -> Dictionary:
	var waited := 0.0
	for attempt in 30:
		var have := value("skill_point")
		if have + 0.000001 >= cost:
			return {"ok":true, "waited":waited}
		var rate := float(s.get_view().resources.skill_point.rate)
		if rate <= 0.0:
			return {"ok":false, "waited":waited, "error":"NO_RATE"}
		var step := maxi(1, int(ceil((cost - have) / rate)) + 1)
		var result := advance(step)
		if result.get("stopped") != null:
			return {"ok":false, "waited":waited, "error":String(result.stopped)}
		waited += float(step)
	return {"ok":false, "waited":waited, "error":"TIMEOUT"}

func buy(id: String, role: String) -> Dictionary:
	var before := view_item(id)
	var cost := float(before.get("cost", "0"))
	var cap := float(s.get_view().resources.skill_point.cap)
	check(cost <= cap + 0.000001, "skill point cap holds %s (%s <= %s)" % [id, cost, cap])
	var wait := ensure_points(cost)
	check(bool(wait.get("ok", false)), "points for %s: %s" % [id, str(wait.get("error", ""))])
	var balance_before := value("skill_point")
	var level_before := int(s.state.skills.get(id, 0))
	var result := send("learn_skill", {"skill_id":id})
	check(result.ok, "learn command %s %s" % [id, str(result.get("error", ""))])
	check(int(s.state.skills.get(id, 0)) == level_before + 1, "level increased " + id)
	check(absf((balance_before - value("skill_point")) - cost) < 0.000001, "exact deduction " + id)
	var after := view_item(id)
	return {"id":id, "role":role, "ok":bool(result.ok), "cost":cost, "waited_seconds":float(wait.get("waited", 0.0)), "balance_before":balance_before, "balance_after":value("skill_point"), "reason_before":String(before.get("reason", "")), "can_learn_before":bool(before.get("can_learn", false)), "scope_before":before, "level_after":int(s.state.skills.get(id, 0)), "current_effect":String(after.get("current_effect", "")), "next_effect":String(after.get("next_effect", "")), "age":s.state.total_elapsed_seconds}

func build_to(id: String, level: int, era: int) -> bool:
	var guard := 0
	while int(s.state.buildings.get(id, 0)) < level and guard < 40:
		guard += 1
		var info: Dictionary = s.get_view().buildings[id]
		for resource in info.costs:
			if not ensure_home(resource, float(info.costs[resource])):
				check(false, "build resource " + String(resource) + " era" + str(era))
				return false
		var result := send("upgrade_building", {"building_id":id})
		check(result.ok, "upgrade %s to %d era%d %s" % [id, int(s.state.buildings.get(id, 0)) + 1, era, str(result.get("error", ""))])
		if not result.ok:
			return false
	check(int(s.state.buildings.get(id, 0)) == level, "%s reaches level %d era%d" % [id, level, era])
	return true

func load_fixture(era: int) -> bool:
	var path := SOURCE_DIR + "earned-era" + str(era) + ".json"
	var raw := FileAccess.get_file_as_string(path)
	sources["era" + str(era)] = {"path":path, "sha256":raw.sha256_text()}
	var decoded := SaveCodec.decode(raw)
	check(decoded.ok, "decode earned era%d" % era)
	if not decoded.ok:
		return false
	check(decoded.state.era_id == era, "earned era id " + str(era))
	check(decoded.state.skills.is_empty(), "earned mainline zero skills era" + str(era))
	var source_skill_version: int = decoded.state.skill_version
	check(source_skill_version in [3, 4], "earned supported skill_version 3/4 era" + str(era))
	check(String(decoded.state.economy.get("version", "")) == IslandProgression.SUPPLY_VERSION, "earned supply economy era" + str(era))
	s = GameSession.new()
	s.content = content
	s.state = decoded.state
	s.clock = GameClock.create(s.state.total_elapsed_seconds)
	check(SkillSystem.reconcile(content, s.state) == (source_skill_version == 3), "legacy migration or current-version no-op era" + str(era))
	check(s.state.skill_version == 4, "skill_version 4 era" + str(era))
	return true

func expect_scope(id: String, open: bool, note: String) -> void:
	var item := view_item(id)
	check(item.has("scope_open") and bool(item.get("scope_open", false)) == open, "scope open %s era%d" % [id, s.state.era_id])
	check(String(item.get("scope_note", "x")) == note, "scope note %s era%d = %s" % [id, s.state.era_id, String(item.get("scope_note", ""))])
	check(not String(item.get("scope", "")).is_empty(), "scope text " + id)

func check_scopes(era: int) -> void:
	for id in ALL_P2:
		check(not String(view_item(id).get("scope", "")).is_empty(), "scope text " + id)
	expect_scope("deep_vein_resonance", true, "")
	expect_scope("nascent_soul_incubation", true, "")
	expect_scope("spirit_sea_breath", true, "")
	match era:
		4:
			expect_scope("ancient_herb_attunement", false, "古藥島未開 · 收益 0")
			expect_scope("void_essence_attunement", false, "太虛島未開 · 收益 0")
			expect_scope("frontier_storekeeping", false, "古藥島／太虛島未開 · 收益 0")
		5:
			expect_scope("ancient_herb_attunement", true, "")
			expect_scope("void_essence_attunement", false, "太虛島未開 · 收益 0")
			expect_scope("frontier_storekeeping", false, "太虛島未開 · 收益 0")
		6:
			expect_scope("ancient_herb_attunement", true, "")
			expect_scope("void_essence_attunement", true, "")
			expect_scope("frontier_storekeeping", true, "")

func snapshot(name: String) -> void:
	var encoded := SaveCodec.encode(s.state, content.content_version, {"save_id":"sksp2-flow-" + name, "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":str(int(s.state.total_elapsed_seconds))})
	check(encoded.ok, "snapshot encode " + name)
	if encoded.ok:
		var write_file_snap := FileAccess.open(DIR + name + ".json", FileAccess.WRITE)
		if write_file_snap == null:
			push_error("write failed: " + str(DIR + name + ".json"))
			RunnerResult.finish(self, 1)
		else:
			write_file_snap.store_string(encoded.json)

func run_era3() -> void:
	if not load_fixture(3):
		return
	var before_opened: bool = bool(SkillSystem.view(content, s.state).opened)
	check(not before_opened, "era3 points locked before library")
	for id in ALL_P2:
		check(item_reason(id) == "SKILL_STUDY_LOCKED", "era3 study locked " + id)
	check(not bool(s.state.resources.skill_point.unlocked), "era3 point resource locked")
	if not build_to("library", 1, 3):
		return
	check(bool(s.state.resources.skill_point.unlocked), "official library build unlocks points")
	check(SkillSystem.view(content, s.state).opened, "era3 study opened")
	for id in ALL_P2:
		check(item_reason(id) == "SKILL_ERA_LOCKED", "era3 era locked " + id)
		check(not bool(view_item(id).get("can_learn", true)), "era3 cannot learn " + id)
	var refused := send("learn_skill", {"skill_id":"deep_vein_resonance"})
	check(not refused.ok and String(refused.get("error", "")) == "SKILL_ERA_LOCKED", "era3 official command refuses P2")
	check(s.state.skills.is_empty(), "era3 still zero skills")
	var rate := float(s.get_view().resources.skill_point.rate)
	check(rate > 0.0, "era3 library produces points")
	snapshot("earned-era3-library")
	era_reports["era3"] = {"opened":true, "rate":rate, "age":s.state.total_elapsed_seconds, "refused":String(refused.get("error", ""))}

func run_era(era: int) -> void:
	if not load_fixture(era):
		return
	check(not SkillSystem.view(content, s.state).opened, "library missing before build era" + str(era))
	if not build_to("storage_wood", 2, era):
		return
	if not build_to("library", 3, era):
		return
	if not build_to("scripture_hall", 1, era):
		return
	check(bool(s.state.resources.skill_point.unlocked), "points unlocked era" + str(era))
	check(SkillSystem.view(content, s.state).opened, "study opened era" + str(era))
	var rate := float(s.get_view().resources.skill_point.rate)
	var cap := float(s.get_view().resources.skill_point.cap)
	check(rate > 0.0 and cap > 0.0, "point economy era" + str(era))
	check_scopes(era)
	var records: Array = []
	var prereq := []
	for id in ["foundation_building", "golden_core_formation"]:
		var entry := buy(id, "prereq")
		prereq.append(entry)
		check(bool(entry.ok), "prereq learned " + id + " era" + str(era))
	for id in P2_BY_ERA[era]:
		check(item_reason(id) == "INSUFFICIENT_SKILL_POINT", "waiting on points " + id + " era" + str(era))
		var entry := buy(id, "first_tier")
		records.append(entry)
		var expected: Array = EXPECT[id]
		check(entry.current_effect.contains(expected[0]), "current tier %s: %s" % [id, entry.current_effect])
		check(entry.next_effect.contains(expected[1]), "next tier %s: %s" % [id, entry.next_effect])
		check(int(entry.level_after) == 1, "first tier level " + id)
		if era < 6:
			for future in P2_BY_ERA[era + 1]:
				check(item_reason(future) == "SKILL_ERA_LOCKED", "future era still locked " + future)
	snapshot("earned-era" + str(era) + "-first-tier")
	era_reports["era" + str(era)] = {"rate":rate, "cap":cap, "age":s.state.total_elapsed_seconds, "prereq":prereq, "first_tier":records}

func run_reject_retry() -> void:
	var id := "frontier_storekeeping"
	var cost := float(view_item(id).cost)
	var wait := ensure_points(cost)
	check(bool(wait.get("ok", false)), "points for rejected save")
	var adapter := ToggleAdapter.new()
	SaveSlots.new(adapter).reset()
	SaveManager.configure(content, adapter)
	var balance_before := value("skill_point")
	var level_before := int(s.state.skills.get(id, 0))
	adapter.fail_writes = true
	var learned := send("learn_skill", {"skill_id":id})
	check(learned.ok, "rejected-flow learn accepted")
	var frozen: Dictionary = s.state.to_snapshot_dict()
	var denied := SaveManager.save(s.state, META)
	check(not denied.ok, "denied save fails")
	var retry_denied := SaveManager.save(s.state, META)
	check(not retry_denied.ok and s.state.to_snapshot_dict() == frozen, "denied retry does not learn twice")
	adapter.fail_writes = false
	var saved := SaveManager.save(s.state, META)
	check(saved.ok and s.state.to_snapshot_dict() == frozen, "retry saves without mutation")
	var points_after := value("skill_point")
	check(absf((balance_before - points_after) - cost) < 0.000001, "rejected flow single deduction")
	SaveManager.configure(content, adapter)
	var loaded: Variant = SaveManager.load_state()
	check(loaded != null and String(SaveManager.load_error()).is_empty(), "reload after retry")
	var reloaded_level := -1
	if loaded != null:
		reloaded_level = int(loaded.skills.get(id, 0))
		check(int(loaded.skills.get(id, 0)) == level_before + 1, "reload keeps learned level")
		check(absf(loaded.resources.skill_point.value.to_float() - points_after) < 0.000001, "reload keeps deducted points %s vs %s" % [loaded.resources.skill_point.value.to_float(), points_after])
		check(int(loaded.buildings.get("library", 0)) == 3 and int(loaded.buildings.get("scripture_hall", 0)) == 1, "reload keeps study buildings %s" % [loaded.buildings])
		check(loaded.skill_version == 4, "reload keeps skill version")
		check(String(loaded.economy.get("version", "")) == IslandProgression.SUPPLY_VERSION, "reload keeps supply economy")
	reject_report = {"skill_id":id, "cost":cost, "waited_seconds":float(wait.get("waited", 0.0)), "denied_error":String(denied.get("error", "")), "retry_error":String(retry_denied.get("error", "")), "reloaded_level":reloaded_level}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "supply content attachment")
	var started := Time.get_ticks_msec()
	run_era3()
	for era in [4, 5, 6]:
		run_era(era)
		if era == 6:
			run_reject_retry()
		await process_frame
	var report := {
		"level":"L2",
		"checks":checks,
		"failures":failures,
		"elapsed_ms":Time.get_ticks_msec() - started,
		"sources":sources,
		"eras":era_reports,
		"reject_retry":reject_report,
		"runtime_seconds":float(Time.get_ticks_msec() - started) / 1000.0,
	}
	var write_file_report := FileAccess.open(DIR + "flow-report.json", FileAccess.WRITE)
	if write_file_report == null:
		push_error("write failed: " + str(DIR + "flow-report.json"))
		RunnerResult.finish(self, 1)
	else:
		write_file_report.store_string(JSON.stringify(report, "\t"))
	print("SKS-P2 FLOW ", JSON.stringify(report))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
