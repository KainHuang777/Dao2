extends SceneTree
## Re-envelope the command-earned fixture for human review, with no offline aging.
func _init() -> void:
	var unopened := "--unopened" in OS.get_cmdline_user_args()
	var source := "res://docs/verification/artifacts/res1-c-earned-era2.json" if unopened else "res://docs/verification/artifacts/res1-c2-offline-fixture.json"
	var destination := "res://docs/verification/artifacts/res1-c3-unopened-fixture.json" if unopened else "res://docs/verification/artifacts/res1-c2-review-fixture.json"
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(source))
	if not decoded.ok:
		push_error("C2 review source invalid")
		quit(1)
		return
	var now := str(int(Time.get_unix_time_from_system() * 1000.0))
	var meta := {"save_id": "c2_review", "saved_at_utc_ms": now, "settled_until_utc_ms": now, "sim_tick": str(int(decoded.state.total_elapsed_seconds))}
	var encoded := SaveCodec.encode(decoded.state, decoded.envelope.content_version, meta)
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if not encoded.ok or file == null:
		push_error("C2 review fixture write failed")
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	var verified := SaveCodec.decode(FileAccess.get_file_as_string(destination))
	if not verified.ok or verified.state.to_snapshot_dict() != decoded.state.to_snapshot_dict():
		push_error("C2 review state changed")
		quit(1)
		return
	print("PASS: C2 review fixture keeps command-earned state; only envelope UTC/save_id refreshed")
	quit(0)
