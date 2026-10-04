extends SceneTree
## Reproducible CPU timings; never reads user:// or changes the earned fixture.
func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-offline-fixture.json"))
	if not decoded.ok:
		quit(1)
		return
	var state: GameState = decoded.state
	var session := GameSession.new()
	session.content = content
	session.state = state
	session.clock = GameClock.create(state.total_elapsed_seconds)
	var start := Time.get_ticks_usec()
	for i in 600:
		session.get_view()
	var view_us := Time.get_ticks_usec() - start
	var working := state.duplicate_state()
	start = Time.get_ticks_usec()
	var result := TimeAdvancer.advance(working, content, 600)
	var advance_us := Time.get_ticks_usec() - start
	var offline := state.duplicate_state()
	start = Time.get_ticks_usec()
	var settlement := OfflineSettlement.settle(offline, content, 172900000, 100000)
	var offline_us := Time.get_ticks_usec() - start
	# Independent 12k one-second subsystem samples locate hot paths. These are
	# diagnostic timings, not additive estimates of a real settlement.
	var subsystem_us := {}
	var island_hashes := {}
	var idle_ticks := 0
	for id in ["island", "island_prepared", "chrono", "scenery", "fortune", "beast", "realm", "sect", "decisions"]:
		var sample := state.duplicate_state()
		var economy_prepared := {}
		start = Time.get_ticks_usec()
		for tick in 12000:
			sample.total_elapsed_seconds += 1.0
			match id:
				"island": IslandEconomy.tick(sample, content.processing_catalog)
				"island_prepared": IslandEconomy.tick_prepared(sample, content.processing_catalog, economy_prepared)
				"chrono": ChronoSystem.tick(sample, 1.0)
				"scenery": AbodeScenery.advance(sample, 1.0)
				"fortune": FortuneSystem.advance_time(sample, 1.0)
				"beast": BeastSystem.tick(sample, 1.0)
				"realm": RealmSystem.tick(sample, 1.0)
				"sect": SectSystem.tick(sample, 1.0)
				"decisions": RealmDecisionSystem.advance_time(sample, 1.0)
		subsystem_us[id] = Time.get_ticks_usec() - start
		if id.begins_with("island"):
			island_hashes[id] = JSON.stringify(SaveCodec._normalize_numbers(sample.to_snapshot_dict()), "", true).sha256_text()
			idle_ticks = int(economy_prepared.get("idle_ticks", idle_ticks))
	print(JSON.stringify({"view_600_us": view_us, "advance_600_us": advance_us, "ticks": result.ticks_advanced, "snapshot_hash": JSON.stringify(SaveCodec._normalize_numbers(working.to_snapshot_dict()), "", true).sha256_text(),
		"subsystem_12000_us": subsystem_us, "island_sample_hashes": island_hashes, "island_idle_ticks": idle_ticks, "offline_48h_us": offline_us, "offline_report": settlement.report, "offline_snapshot_hash": JSON.stringify(SaveCodec._normalize_numbers(offline.to_snapshot_dict()), "", true).sha256_text()}))
	quit(0 if island_hashes.island == island_hashes.island_prepared else 1)
