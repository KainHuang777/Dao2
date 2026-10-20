extends SceneTree
func _init() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	if not decoded.ok:
		push_error(str(decoded))
		quit(1)
		return
	decoded.state.reincarnation_count = 1
	decoded.state.buildings.rebirth_lotus = 1
	decoded.state.dao_heart = AmountCompat.from_number(50)
	var meta: Dictionary = decoded.envelope
	var now := str(int(Time.get_unix_time_from_system()*1000.0))
	meta.saved_at_utc_ms = now
	meta.settled_until_utc_ms = now
	var encoded := SaveCodec.encode(decoded.state,meta.content_version,meta)
	if not encoded.ok:
		push_error(str(encoded))
		quit(1)
		return
	FileAccess.open("res://docs/verification/artifacts/uix-r7-f5-simple-fixture.json",FileAccess.WRITE).store_string(encoded.json)
	print("F5 simple isolated eligible fixture encoded")
	quit(0)