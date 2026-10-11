extends SceneTree

func _init() -> void:
	var source := "res://docs/verification/artifacts/early-flow1d-foundation.json"
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(source))
	if not decoded.ok:
		push_error(decoded.error)
		quit(1)
		return
	var envelope: Dictionary = decoded.envelope
	var utc := str(int(Time.get_unix_time_from_system() * 1000.0))
	var meta := {
		"save_id": envelope.save_id,
		"saved_at_utc_ms": utc,
		"settled_until_utc_ms": utc,
		"sim_tick": envelope.sim_tick,
		"rng_streams": envelope.rng_streams,
		"last_offline_report": envelope.last_offline_report,
	}
	var encoded := SaveCodec.encode(decoded.state, envelope.content_version, meta)
	if not encoded.ok:
		push_error(encoded.error)
		quit(1)
		return
	var verified := SaveCodec.decode(encoded.json)
	if not verified.ok or verified.state.to_snapshot_dict() != decoded.state.to_snapshot_dict():
		push_error("Re-enveloping must preserve the entire command-earned game state")
		quit(1)
		return
	var output := "res://docs/verification/artifacts/early-flow1d-natural-foundation.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write isolated natural-flow fixture")
		quit(1)
		return
	file.store_string(encoded.json)
	file.close()
	print("NATURAL_FIXTURE: unchanged game state; refreshed UTC=", utc, "; ", output)
	quit(0)
