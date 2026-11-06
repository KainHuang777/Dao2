extends SceneTree
const Memory = preload("res://tests/sect_reform_save_runner.gd").Memory
const META := {"save_id":"sect-entry-test", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ", message)
func _init() -> void: run.call_deferred()
func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach_supply(content)
	var s := GameSession.create_new_game(content, 51)
	check(FeatureUnlocks.check("sect", s.get_view()).state == FeatureUnlocks.State.HIDDEN, "first life hidden")
	check(not s.join_sect().ok and not s.ack_sect_entry("later").ok, "core rejects first-life entry")
	check(SectEntry.guidance(s.state).is_empty() and not SectEntry.invitation(s.state), "no hidden invitation or guide")
	s.state.era_id = 2
	s.state.economy = IslandEconomy.initial()
	s.state.economy.early_supply = Onboarding.initial_supply()
	check(not SectEntry.invitation(s.state), "supply before invitation")
	s.state.resources.bronze_essence = {"value": AmountCompat.from_number(10), "unlocked": true, "ever_obtained": true}
	s.state.resources.spirit_timber = {"value": AmountCompat.from_number(10), "unlocked": true, "ever_obtained": true}
	check(not SectEntry.invitation(s.state), "stock alone does not invent completed supply")
	for id in ["wood", "ore"]: s.state.economy.islands[id].opened = true
	s.state.economy.early_supply.bronze_done = true
	s.state.economy.early_supply.timber_done = true
	s.state.economy.early_supply.ore_delivered = 5
	s.state.economy.early_supply.bronze_home = 1
	s.state.economy.early_supply.timber_home = 1
	check(SectEntry.invitation(s.state), "accepted supply history invites")
	var raw_before := JSON.stringify(s.state.sect)
	SectEntry.guidance(s.state)
	check(JSON.stringify(s.state.sect) == raw_before, "view read does not persist")
	var command := {"command_id":"later-once", "type":"ack_sect_entry", "expected_revision":s.state.revision, "payload":{"action":"later"}}
	check(s.submit(command).ok and s.submit(command).get("duplicate", false), "dismiss idempotent")
	check(not SectEntry.invitation(s.state), "dismiss does not repeat")
	var encoded := SaveCodec.encode(s.state, content.content_version, META)
	check(encoded.ok, "entry encode")
	var decoded := SaveCodec.decode(encoded.get("json", ""))
	check(decoded.ok and not SectEntry.invitation(decoded.state), "dismiss reload")
	check(s.join_sect("太虛天闕").ok, "manual entry after dismissal")
	check(SectEntry.guidance(s.state).step == "intro", "new member introduction")
	check(not s.ack_sect_entry("finish").ok, "read cannot fabricate claim")
	check(s.ack_sect_entry("intro").ok, "greeting acknowledged")
	var original_tasks: Array = s.state.sect.available_tasks
	s.state.sect.available_tasks = []
	check(SectEntry.guidance(s.state).get("task_id", "") == "", "empty task list keeps normal refresh")
	s.state.sect.available_tasks = original_tasks
	var guide := SectEntry.guidance(s.state)
	check(not String(guide.get("task_id", "")).is_empty(), "recommend eligible shortest")
	var expected_duration := 2147483647
	for task in s.state.sect.available_tasks: expected_duration = mini(expected_duration, int(task.duration))
	var recommended := String(guide.task_id)
	check(s.start_sect_expedition(recommended).ok and s.state.sect.entry.first_dispatch, "actual dispatch marks receipt")
	check(int(s.state.sect.active_expedition.duration) == expected_duration, "shortest current task")
	check(not s.claim_sect_expedition().ok and not s.state.sect.entry.first_claim, "early claim does not mark")
	s.state.sect.active_expedition.elapsed = s.state.sect.active_expedition.duration
	check(s.claim_sect_expedition().ok and s.state.sect.entry.first_claim, "successful claim only")
	check(SectEntry.guidance(s.state).step == "report", "first report and use")
	check("50" in String(SectEntry.guidance(s.state).text), "unaffordable target exposes cost")
	var contrib := String(s.state.sect.contribution)
	check(s.ack_sect_entry("finish").ok and SectEntry.guidance(s.state).is_empty(), "finish optional guide")
	check(String(s.state.sect.contribution) == contrib, "tutorial grants no resources")
	s.state.sect.erase("entry")
	check(SectEntry.guidance(s.state).step == "review" and not SectEntry.receipt(s.state).first_claim, "legacy history unknown")
	check(s.ack_sect_entry("review").ok and String(s.state.sect.contribution) == contrib, "legacy no-reward review")
	s.state.reincarnation_count = 1
	s.state.era_id = 1
	SectSystem.on_reincarnate(s.state)
	check(not s.state.sect.has("entry") and SectEntry.invitation(s.state), "rebirth resets and invites early")
	check(s.join_sect().ok and s.ack_sect_entry("skip").ok and SectEntry.guidance(s.state).is_empty(), "returning player skip")
	check(s.state.sect.active_expedition == null and not s.state.sect.entry.first_claim, "skip does not dispatch or claim")
	var invalid := s.state.sect.duplicate(true)
	invalid.entry.first_dispatch = false
	invalid.entry.first_claim = true
	check(not SectSaveContract.validate(s.state.sect_version, invalid).is_empty(), "reject impossible receipt")
	invalid = s.state.sect.duplicate(true)
	invalid.entry.extra = true
	check(not SectSaveContract.validate(s.state.sect_version, invalid).is_empty(), "bounded receipt keys")
	# Existing release transaction owns failure/retry; no separate tutorial writes.
	var mem := Memory.new()
	s.state = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
	s.state.sect.entry = SectEntry.initial()
	SaveManager.configure(content, mem)
	var save_meta := META.duplicate()
	save_meta.save_id = s.state.sect.core_save.save_id
	var saved := SaveCodec.encode(s.state, content.content_version, save_meta)
	mem.write(SaveSlots.SLOT_MAIN, saved.json)
	s.state.sect.entry.skip = false
	# Re-encode the actual source before starting the candidate transaction.
	saved = SaveCodec.encode(s.state, content.content_version, save_meta)
	mem.write(SaveSlots.SLOT_MAIN, saved.json)
	mem.fail = SaveSlots.SLOT_BACKUP
	var result := s.ack_sect_entry("skip")
	check(not result.ok and not s.state.sect.entry.skip, "denied write leaves authority unchanged")
	check(SaveManager.core_save_pending(s.state), "denial stages exact candidate")
	mem.fail = ""
	result = SaveManager.save(s.state, save_meta)
	check(result.ok and s.state.sect.entry.skip, "retry commits frozen receipt")
	var restored := SaveCodec.decode(mem.data[SaveSlots.SLOT_BACKUP])
	check(restored.ok and restored.state.sect.entry.skip, "durable receipt after retry")
	var corrupt := JSON.parse_string(mem.data[SaveSlots.SLOT_BACKUP]) as Dictionary
	corrupt.state.sect.entry.skip = "invalid"
	corrupt.erase("checksum")
	corrupt.checksum = SaveCodec.compute_checksum(corrupt)
	mem.data[SaveSlots.SLOT_BACKUP] = JSON.stringify(corrupt)
	SaveManager.configure(content, mem)
	var fallback: GameState = SaveManager.current_state()
	check(fallback != null and not fallback.sect.entry.skip, "invalid entry restores previous valid generation")
	SaveManager.reset_for_tests()
	var panel := SectPanel.new()
	root.add_child(panel)
	panel.set_layout_bounds(Rect2(0, 0, 1000, 460))
	s.state.sect.erase("entry")
	panel.update_view(s.state)
	await process_frame
	check(panel._tab_content_container.get_child_count() > 0, "legacy guide renders alongside existing tabs")
	panel.queue_free()
	print("SECT-LIFE-ENTRY ", checks, " checks failures=", JSON.stringify(failures))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)
