extends SceneTree
## Refresh only envelope clock metadata for a normal-release isolated review.
func _init() -> void:
	for era in ["era4", "era5"]:
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/beast2-review-"+era+".json"))
		if not decoded.ok:
			quit(1)
			return
		var now := str(int(Time.get_unix_time_from_system() * 1000.0))
		var encoded := SaveCodec.encode(decoded.state, decoded.envelope.content_version, {"save_id":"beast2_closure_"+era, "saved_at_utc_ms":now, "settled_until_utc_ms":now, "sim_tick":str(int(decoded.state.total_elapsed_seconds))})
		if not encoded.ok:
			quit(1)
			return
		var file := FileAccess.open("res://docs/verification/artifacts/content-p2-beasts-closure/review-"+era+".json", FileAccess.WRITE)
		if file == null:
			quit(1)
			return
		file.store_string(encoded.json)
		file.close()
		var verified := SaveCodec.decode(encoded.json)
		var equal: bool = verified.ok and verified.state.to_snapshot_dict() == decoded.state.to_snapshot_dict()
		print("REVIEW_REBASE ",era," state_equal=",equal)
		if not equal:
			quit(1)
			return
	quit(0)
