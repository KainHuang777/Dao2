extends SceneTree
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var source := args[0] if args.size() > 0 else "res://docs/verification/artifacts/res1-d2-earned-era3.json"
	var target := args[1] if args.size() > 1 else "res://docs/verification/artifacts/content-p2-supply-3/review-old.json"
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string(source))
	if not decoded.ok: quit(1); return
	var now := str(int(Time.get_unix_time_from_system()*1000))
	var encoded := SaveCodec.encode(decoded.state,decoded.envelope.content_version,{"save_id":"supply3-review","saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":str(int(decoded.state.total_elapsed_seconds))})
	if not encoded.ok: quit(1);return
	FileAccess.open(target,FileAccess.WRITE).store_string(encoded.json)
	var reread := SaveCodec.decode(FileAccess.get_file_as_string(target))
	print("REVIEW_REBASE state_equal=",reread.ok and reread.state.to_snapshot_dict()==decoded.state.to_snapshot_dict())
	quit(0 if reread.ok else 1)
