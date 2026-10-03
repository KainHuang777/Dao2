extends SceneTree
## Separate process durability evidence; explicit project-local test directory.
const DIR := "res://docs/verification/artifacts/res1-b-cross-process"
const META := {"save_id": "res1b_disk", "saved_at_utc_ms": "1000", "settled_until_utc_ms": "1000", "sim_tick": "0"}

func _init() -> void:
	var mode := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "verify"
	var content: GameContent = ContentLoader.load_directory("res://content").content
	content.processing_catalog = ProcessingCatalog.load_file().catalog
	content.content_version += "+res1-b-1"
	var adapter := FileStorageAdapter.new(DIR)
	SaveManager.configure(content, adapter)
	if mode == "seed":
		var slots := SaveSlots.new(adapter)
		slots.reset()
		var s := GameSession.create_new_game(content)
		s.state.era_id = 3
		s.state.buildings = {"hut": 2, "stone_mine": 3}
		for id in content.processing_catalog.resources:
			s.state.resources[id] = {"value": AmountCompat.zero(), "unlocked": true, "ever_obtained": false}
		if not _command(s, "migrate_processing", {}, "migrate").ok:
			_fail("migrate")
			return
		IslandEconomy._put(s.state, "home", "wood", 100)
		IslandEconomy._put(s.state, "home", "stone_low", 100)
		if not _command(s, "open_island", {"island_id": "wood"}, "open").ok:
			_fail("open")
			return
		IslandEconomy._put(s.state, "wood", "wood", 40)
		IslandEconomy._put(s.state, "wood", "stone_low", 20)
		_command(s, "craft", {"island_id": "wood", "recipe_id": "spirit_timber", "repeat": true}, "job")
		_command(s, "configure_route", {"route_id": "timber_home"}, "route")
		TimeAdvancer.advance(s.state, content, 17)
		if not SaveManager.save(s.state, META).ok:
			_fail("seed save")
			return
		var expected := s.state.duplicate_state()
		TimeAdvancer.advance(expected, content, 600)
		expected.revision += 1
		if not adapter.write("expected", SaveCodec.compute_checksum(expected.to_snapshot_dict())).ok:
			_fail("expected write")
			return
	elif mode == "resume":
		var state: GameState = SaveManager.current_state()
		if state.economy.is_empty() or int(state.economy.tick) != 17:
			_fail("reload seed with in-transit cargo")
			return
		var s := GameSession.new()
		s.content = content
		s.state = state
		if not _command(s, "craft", {"recipe_id": "spirit_timber"}, "job").get("duplicate", false):
			_fail("persisted command receipt")
			return
		var settled := OfflineCoordinator.settle(601000)
		if not settled.ok or SaveCodec.compute_checksum(settled.state.to_snapshot_dict()) != adapter.read("expected").data:
			_fail("cross-process settlement differs")
			return
	else:
		var state: GameState = SaveManager.current_state()
		if SaveManager.last_settled_utc_ms() != 601000 or SaveCodec.compute_checksum(state.to_snapshot_dict()) != adapter.read("expected").data:
			_fail("cursor/state durability")
			return
		if OfflineCoordinator.settle(601000).report.effective_ticks != 0:
			_fail("double offline reward")
			return
	print("PASS: RES1-B cross-process " + mode)
	quit(0)

func _command(s: GameSession, kind: String, p: Dictionary, id: String) -> Dictionary:
	return s.submit({"command_id": id, "type": kind, "payload": p, "expected_revision": s.state.revision})

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
