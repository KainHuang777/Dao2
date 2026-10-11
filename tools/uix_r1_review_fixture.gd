extends SceneTree
## Earned pre-breakthrough checkpoint for isolated UI acceptance; no state injection.
func _init() -> void:
	call_deferred("run")

func run() -> void:
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var helper = preload("res://src/verification/res1d2_contract.gd").new()
	var session := GameSession.create_new_game(content)
	for milestone in Onboarding.MILESTONES:
		while int(session.state.buildings.get(milestone.building, 0)) < int(milestone.level):
			if not helper.build(session, milestone.building):
				quit(1)
				return
	if not helper.build(session, "storage_lingli"):
		quit(1)
		return
	var waited := 0
	while session.state.level < 10 and waited < 4800:
		if session.get_view().can_level_up:
			if not helper.send(session, "level_up_cultivation").ok:
				quit(1)
				return
		else:
			session.advance_time(1)
			waited += 1
	if not session.get_view().can_breakthrough:
		push_error("Earned fixture not ready")
		quit(1)
		return
	var encoded := SaveCodec.encode(session.state, content.content_version, {"save_id": "uix-r1-earned", "saved_at_utc_ms": "0", "settled_until_utc_ms": "0", "sim_tick": "0"})
	var file := FileAccess.open("res://docs/verification/artifacts/uix-r1-prebreak.json", FileAccess.WRITE)
	if file == null or not encoded.ok:
		quit(1)
		return
	file.store_string(encoded.json)
	print("UIX-R1 earned prebreakthrough fixture; normal commands, simulated wait=%ds" % waited)
	quit(0)
