extends SceneTree
## Funded UI fixture only. No claim of natural progression.
func _init() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/skills-b1-fixture.json"))
	if not decoded.ok:
		push_error(str(decoded))
		quit(1)
		return
	var state: GameState = decoded.state
	state.era_id = 3
	state.level = 1
	state.skills = {"foundation_building": 1}
	state.buildings.library = 1
	state.buildings.scripture_hall = 1
	state.sect = {}
	SectSystem.join_sect(state)
	state.sect.techniques["storage_talisman"] = 3
	state.resources.skill_point.value = AmountCompat.from_number(8060)
	state.total_elapsed_seconds = 0.0
	state.training_seconds = 0.0
	SkillSystem.sync_unlock(state)
	var meta: Dictionary = decoded.envelope
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	meta.saved_at_utc_ms = now
	meta.settled_until_utc_ms = now
	var encoded := SaveCodec.encode(state, meta.content_version, meta)
	if not encoded.ok:
		push_error(str(encoded))
		quit(1)
		return
	FileAccess.open("res://docs/verification/artifacts/early-v1-c/web-fixture.json", FileAccess.WRITE).store_string(encoded.json)
	print("EARLY-V1-C funded Era3 fixture: 8060 points, foundation1, talisman3; not natural progression")
	quit(0)
