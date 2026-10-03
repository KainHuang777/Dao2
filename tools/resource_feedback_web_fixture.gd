extends SceneTree
## Isolated EAR1 rebirth snapshot reproducing the reported resources.
func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	var s := GameSession.create_new_game(content)
	s.state.reincarnation_count = 3
	s.state.highest_era = 2
	s.state.dao_heart = AmountCompat.from_number(104)
	s.state.dao_proof = 5
	s.state.beast_souls = {"jade_fox": 2}
	s.state.buildings.stone_mine = 3
	s.state.buildings.hut = 1
	s.state.tutorial_flags = {"nine_realms_hook_seen": true}
	for id in ["wood", "stone_low", "copper"]:
		if s.state.resources.has(id):
			s.state.resources[id].unlocked = true
			s.state.resources[id].ever_obtained = true
	s.state.resources.stone_low.value = AmountCompat.from_number(3.22)
	var data := RealmSystem.ensure_spirit_data(s.state)
	data.outposts = {"celestial_hub": 10, "pure_pool": 10, "void_beacon": 0}
	data.spirit_crystal = 89.3
	data.azure_nectar = 50.0
	var now_ms := str(int(Time.get_unix_time_from_system() * 1000))
	var encoded := SaveCodec.encode(s.state, content.content_version, {"save_id": "resource_feedback_fixture", "saved_at_utc_ms": now_ms, "settled_until_utc_ms": now_ms, "sim_tick": "0"})
	if not encoded.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/resource-feedback-web-fixture.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	print("PASS: isolated resource feedback Web fixture generated.")
	quit(0)
