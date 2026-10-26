extends SceneTree
var checks := 0
var failures := []
var content: GameContent
const KINDS := ["building_built", "island_opened", "island_opened", "era_breakthrough", "tribulation_failed", "cultivation_leveled_up", "cargo_arrived", "beast_acquired", "beast_matured", "joined_sect", "expedition_completed", "building_built", "cultivation_leveled_up"]
const SUBJECTS := ["hut", "wood", "ore", "2:3", "3:2", "2:2", "wood_home", "fox", "fox", "sect", "sect", "herb_farm", "1:2"]

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func fixture(mask: int) -> GameState:
	var state := GameSession.create_new_game(content, 34).state
	for n in KINDS.size():
		if mask & (1 << n):
			LifeLedger.note(state, KINDS[n], SUBJECTS[n], "fixture:" + str(n), 0, "a".repeat(64) if n in [7, 8] else "")
	return state

func expected(mask: int) -> String:
	var has := []
	for n in 13: has.append(bool(mask & (1 << n)))
	if has[0] and has[1] and has[2] and has[3]: return "cloud"
	if has[4] and (has[5] or has[12]): return "after"
	if has[3]: return "core"
	if has[1] and has[2] and has[6]: return "routes"
	if has[7] and has[8]: return "companion"
	if has[9] and has[10]: return "sect"
	if has[0] and has[11]: return "garden"
	if has[0]: return "hut"
	if has[5] or has[12]: return "quiet"
	return "fallback"

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	for mask in 8192:
		var state := fixture(mask)
		var life: Dictionary = state.life_ledger.current
		var report := LifeReport.generate(life)
		check(report.title_id == expected(mask), "priority:" + str(mask))
		var seqs := []
		for event in life.events: seqs.append(int(event.seq))
		var valid: bool = report.traces.size() <= 3 and LifeLedger.bytes(report) <= LifeLedger.TEXT_BYTES
		for sentence in report.sentences:
			for ref in sentence.refs: valid = valid and ref in seqs
		check(valid, "refs/bytes:" + str(mask))
	# Temporal/matching-instance negatives cannot be demonstrated by presence masks alone.
	var reordered := fixture(15)
	var first_fact: Dictionary = reordered.life_ledger.current.events.pop_front()
	reordered.life_ledger.current.events.append(first_fact)
	for n in reordered.life_ledger.current.events.size(): reordered.life_ledger.current.events[n].seq = n + 1
	check(LifeReport.generate(reordered.life_ledger.current).title_id == "core", "cloud temporal words require hut before islands and core")
	var state := fixture((1 << 4) | (1 << 5))
	state.life_ledger.current.events.reverse()
	state.life_ledger.current.events[0].seq = 1
	state.life_ledger.current.events[1].seq = 2
	check(LifeReport.generate(state.life_ledger.current).title_id == "quiet", "level before failure")
	state = fixture((1 << 7) | (1 << 8))
	state.life_ledger.current.events[1].instance = "b".repeat(64)
	check(LifeReport.generate(state.life_ledger.current).title_id == "fallback", "different beast")
	state = fixture((1 << 0) | (1 << 11))
	state.life_ledger.current.events.reverse()
	state.life_ledger.current.events[0].seq = 1
	state.life_ledger.current.events[1].seq = 2
	check(LifeReport.generate(state.life_ledger.current).sentences[0].text == "此世築屋，亦建成靈草圃。", "garden reverse neutral wording")
	state = fixture(8191)
	var before := JSON.stringify(state.to_snapshot_dict(), "", true)
	var first := LifeReport.generate(state.life_ledger.current, "rebirth_lotus")
	check(first == LifeReport.generate(state.life_ledger.current, "rebirth_lotus"), "stable preview")
	check(before == JSON.stringify(state.to_snapshot_dict(), "", true), "preview no mutation/RNG")
	check(not first.closing.contains("壽") and first.closing.contains("暫擱"), "early not death")
	check(LifeReport.generate(state.life_ledger.current).closing == "行跡仍在續寫。", "living")
	LifeLedger.seal(state, "rebirth_lotus", "seal")
	var sealed: Dictionary = state.life_ledger.archive[0]
	var frozen: String = sealed.frozen_text
	check(LifeReport.read(sealed) == first, "freeze actual selected prose")
	state.reincarnation_count += 1
	StoryProgress.next_life(state) # Keep synthetic life fixture consistent with story v1.
	LifeLedger.begin_next(state)
	check(LifeLedger.validate(state.life_ledger, 2).is_empty(), "contract valid after text")
	var meta := {"save_id":"report-test", "saved_at_utc_ms":"100000", "settled_until_utc_ms":"100000", "sim_tick":"0"}
	var encoded := SaveCodec.encode(state, content.content_version, meta)
	check(encoded.ok, "text encode")
	var decoded := SaveCodec.decode(encoded.json)
	check(decoded.ok and decoded.state.life_ledger.archive[0].frozen_text == frozen, "reload frozen exact")
	sealed.text_version = "future-copy-version"
	check(LifeReport.read(sealed) == first, "content updates do not regenerate")
	sealed.frozen_text = ""
	check(LifeReport.read(sealed).title_id == "unrecorded", "old archive never backfilled")
	var session := GameSession.create_new_game(content, 19)
	session.state.highest_era = 12
	check(session.get_life_report().report.title_id == "fallback", "global peak cannot supply core fact")
	var copy := session.get_life_report()
	copy.life.events.append({})
	check(session.state.life_ledger.current.events.is_empty(), "explicit report deep copy")
	print(JSON.stringify({"suite":"REPORT-1A", "checks":checks, "failures":failures}))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
