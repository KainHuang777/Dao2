extends SceneTree
## Reseal envelope time only, preserving the command-earned state.
func _init() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/pill2-era5.json"))
	if not decoded.ok:
		quit(1)
		return
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var encoded := SaveCodec.encode(decoded.state, decoded.envelope.content_version, {"save_id":"pill2_closure", "saved_at_utc_ms":now, "settled_until_utc_ms":now, "sim_tick":str(int(decoded.state.total_elapsed_seconds))})
	if not encoded.ok:
		quit(1)
		return
	var file := FileAccess.open("res://docs/verification/artifacts/content-p2-pills-closure/review-earned.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	var verified := SaveCodec.decode(encoded.json)
	var equal: bool = verified.ok and verified.state.to_snapshot_dict() == decoded.state.to_snapshot_dict()
	print("REVIEW_REBASE state_equal=", equal)
	quit(0 if equal else 1)
