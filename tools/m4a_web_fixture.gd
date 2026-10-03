extends SceneTree
## Test-only snapshot. Never imported into the normal player origin.
func _init() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	var s := GameSession.create_new_game(content)
	s.state.era_id = 2
	s.state.highest_era = 2
	s.state.tutorial_flags = {"nine_realms_hook_seen": true}
	s.state.buildings.hut = 1
	for id in content.resource_ids:
		s.state.resources[id].value = AmountCompat.from_number(1000)
		s.state.resources[id].unlocked = true
		s.state.resources[id].ever_obtained = true
	s.join_sect("驗收用太虛天闕")
	s.state.sect.contribution = "1000"
	# Explicitly marked short expedition: real start/tick/claim commands still apply.
	s.state.sect.available_tasks = [{"id": "r1_web_task", "name": "驗收用短程歷練", "desc": "隔離測試資料，不代表正式節奏。", "rarity": "common", "rarity_name": "普通", "rarity_color": "#cccccc", "duration": 30, "elapsed": 0, "rewards": {"contribution": 80, "money": 100, "spirit_grass_low": 15, "special_buff": "epiphany"}}]
	s.apply_buff("turtle_breath")
	s.apply_buff("spirit_surge", 600)
	var now_ms := str(int(Time.get_unix_time_from_system() * 1000))
	var encoded := SaveCodec.encode(s.state, content.content_version, {"save_id": "m4a_r1_fixture", "saved_at_utc_ms": now_ms, "settled_until_utc_ms": now_ms, "sim_tick": "0"})
	if not encoded.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/m4a-r1-web-fixture.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	print("PASS: isolated M4-A-R1 Web fixture generated.")
	quit(0)
