extends SceneTree

func _init() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	if not decoded.ok:
		quit(1)
		return
	var state: GameState = decoded.state
	state.reincarnation_count = 1
	state.dao_heart = AmountCompat.from_number(50)
	state.talents = {}
	# Explicit diagnostic eligibility, beyond every Lv1 lifespan bonus.
	state.total_elapsed_seconds = 100000.0
	state.current_realm = "realm_human"
	var meta: Dictionary = decoded.envelope
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	meta.saved_at_utc_ms = now
	meta.settled_until_utc_ms = now
	var encoded := SaveCodec.encode(state, meta.content_version, meta)
	if not encoded.ok:
		quit(1)
		return
	FileAccess.open("res://docs/verification/artifacts/early-v1-b/web-fixture.json", FileAccess.WRITE).store_string(encoded.json)
	state.dao_heart = AmountCompat.zero()
	var zero := SaveCodec.encode(state, meta.content_version, meta)
	if not zero.ok:
		quit(1)
		return
	FileAccess.open("res://docs/verification/artifacts/early-v1-b/web-zero-fixture.json", FileAccess.WRITE).store_string(zero.json)
	print("EARLY-V1-B funded exhausted diagnostic fixture; not natural progression")
	quit(0)
