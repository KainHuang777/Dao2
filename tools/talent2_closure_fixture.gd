extends SceneTree
## Refresh only envelope UTC for the already command-earned fixture.
func _init() -> void:
	var source := "res://src/verification/talent2-earned.json"
	var destination := "res://docs/verification/artifacts/content-p2-talents-closure/review-earned.json"
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(source))
	if not decoded.ok:
		push_error("Earned fixture failed decode")
		quit(1)
		return
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var encoded := SaveCodec.encode(decoded.state, decoded.envelope.content_version, {"save_id":"talent2_closure", "saved_at_utc_ms":now, "settled_until_utc_ms":now, "sim_tick":str(int(decoded.state.total_elapsed_seconds))})
	if not encoded.ok:
		quit(1)
		return
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	var verified := SaveCodec.decode(FileAccess.get_file_as_string(destination))
	var equal: bool = verified.ok and verified.state.to_snapshot_dict() == decoded.state.to_snapshot_dict()
	print("REVIEW_REBASE state_equal=", equal)
	quit(0 if equal else 1)
