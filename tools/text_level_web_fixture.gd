extends SceneTree
## Isolated acceptance fixture only; never a normal starting save.
func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	var session := GameSession.create_new_game(content)
	session.state.era_id = 2
	session.state.highest_era = 2
	session.state.level = 8
	session.state.training_seconds = 100000.0
	session.state.tutorial_flags = {"nine_realms_hook_seen": true}
	session.state.buildings.hut = 1
	session.state.buildings.storage_lingli = 50
	for id in content.resource_ids:
		session.state.resources[id].value = AmountCompat.from_number(10000)
		session.state.resources[id].unlocked = true
		session.state.resources[id].ever_obtained = true
	var now_ms := str(int(Time.get_unix_time_from_system() * 1000))
	var encoded := SaveCodec.encode(session.state, content.content_version, {"save_id": "text_level_fixture", "saved_at_utc_ms": now_ms, "settled_until_utc_ms": now_ms, "sim_tick": "0"})
	if not encoded.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/text-level-web-fixture.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	print("PASS: isolated level-up fixture generated")
	quit(0)
