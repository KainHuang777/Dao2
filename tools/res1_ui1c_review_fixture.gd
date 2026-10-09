extends SceneTree
## Re-envelope the command-earned Era3 state without changing gameplay fields.
func _init() -> void:
	var source := FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json")
	var decoded := SaveCodec.decode(source)
	if not decoded.ok:
		push_error("UI1-C command-earned source invalid")
		quit(1)
		return
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var encoded := SaveCodec.encode(decoded.state, decoded.envelope.content_version, {
		"save_id": "local", "saved_at_utc_ms": now, "settled_until_utc_ms": now,
		"sim_tick": str(int(decoded.state.total_elapsed_seconds))})
	if not encoded.ok:
		quit(1)
		return
	var after := SaveCodec.decode(encoded.json)
	if not after.ok or after.state.to_snapshot_dict() != decoded.state.to_snapshot_dict():
		push_error("UI1-C review changed command-earned state")
		quit(1)
		return
	var output := FileAccess.open("res://docs/verification/artifacts/res1-ui1-c-review.json", FileAccess.WRITE)
	if output == null:
		quit(1)
		return
	output.store_string(encoded.json)
	output.close()
	print("PASS: UI1-C review cursor refreshed; complete earned state unchanged")
	quit(0)
