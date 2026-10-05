extends SceneTree
## Fixed, read-only fixture: no clocks, user://, commands or gameplay advancement.
func _init() -> void:
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-review-fixture.json"))
	if not decoded.ok:
		quit(1)
		return
	var content: GameContent = ContentLoader.load_directory("res://content").content
	IslandProgression.attach(content)
	var session := GameSession.new()
	session.content = content
	session.state = decoded.state
	# Existing first-view initialization populates subsystem defaults. Warm it
	# before fixing the snapshot; measured iterations must not change that state.
	session.get_view()
	var meta: Dictionary = decoded.envelope.duplicate(true)
	var source_hash := JSON.stringify(session.state.to_snapshot_dict(), "", true).sha256_text()
	var samples: Array = []
	var reference_samples: Array = []
	RuntimeProfile.enabled = true
	for index in 110:
		# Alternate execution order to bound warmup/order bias; same immutable state.
		var reference := ""
		var reference_us := 0
		if index % 2 == 0:
			var reference_start := Time.get_ticks_usec()
			reference = _reference_encode(session.state, content.content_version, meta)
			reference_us = Time.get_ticks_usec() - reference_start
		RuntimeProfile.begin_frame()
		var started := RuntimeProfile.begin()
		var encoded := SaveCodec.encode(session.state, content.content_version, meta)
		RuntimeProfile.end("save_encode", started)
		started = RuntimeProfile.begin()
		session.get_view()
		RuntimeProfile.end("view_build", started)
		var spans: Dictionary = RuntimeProfile._spans.duplicate()
		RuntimeProfile.end_frame()
		if index % 2 != 0:
			var reference_start := Time.get_ticks_usec()
			reference = _reference_encode(session.state, content.content_version, meta)
			reference_us = Time.get_ticks_usec() - reference_start
		if not encoded.ok or not SaveCodec.decode(encoded.json).ok or JSON.parse_string(reference) != JSON.parse_string(encoded.json):
			push_error("ENCODE_PARITY")
			quit(1)
			return
		if index >= 10:
			samples.append(spans)
			reference_samples.append(reference_us)
	RuntimeProfile.enabled = false
	var unchanged := source_hash == JSON.stringify(session.state.to_snapshot_dict(), "", true).sha256_text()
	var numeric_checks := 0
	for number in [0.0, -0.0, 0.00000000000001, 0.000001, 0.1, 0.9999999, 1.0000001, 1.9999999, 86400.00000001, 9000000000000000.0, -1.0000001, 164.712345678901, 1.234567890123456e-20, 1.234567890123456e20]:
		var sample_state: GameState = session.state.duplicate_state()
		sample_state.training_seconds = abs(number)
		var sample_meta := meta.duplicate(true)
		sample_meta.last_offline_report = {"number": number, "nested": [number, {"text": '繁體\\"}\nchecksum', "value": number}]}
		var candidate := SaveCodec.encode(sample_state, content.content_version, sample_meta)
		var expected := _reference_encode(sample_state, content.content_version, sample_meta)
		if not candidate.ok or JSON.parse_string(candidate.json) != JSON.parse_string(expected) or not SaveCodec.decode(candidate.json).ok:
			push_error("NUMERIC_PARITY:" + str(number))
			quit(1)
			return
		numeric_checks += 1
	print(JSON.stringify({"fixture_sha256": FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c2-review-fixture.json").sha256_text(), "state_hash": source_hash, "unchanged": unchanged, "samples_us": samples, "reference_encode_us": reference_samples, "numeric_checks": numeric_checks, "envelope_parity_checks": 110}))
	quit(0 if unchanged else 1)

func _reference_encode(state: GameState, content_version: String, meta: Dictionary) -> String:
	# Prior production algorithm, retained only in this read-only diagnostic.
	if not IslandEconomy.validate(state).is_empty():
		return ""
	var envelope := {"schema_version": SaveCodec.SCHEMA_VERSION, "game_version": SaveCodec.GAME_VERSION,
		"content_version": content_version, "rules_version": SaveCodec.RULES_VERSION,
		"amount_format_version": SaveCodec.AMOUNT_FORMAT_VERSION, "generator_version": SaveCodec.GENERATOR_VERSION,
		"save_id": meta.save_id, "revision": state.revision, "saved_at_utc_ms": meta.saved_at_utc_ms,
		"settled_until_utc_ms": meta.settled_until_utc_ms, "sim_tick": meta.sim_tick,
		"state": state.to_snapshot_dict(), "rng_streams": meta.get("rng_streams", {}),
		"last_offline_report": meta.get("last_offline_report", null)}
	envelope = JSON.parse_string(JSON.stringify(envelope, "", true))
	envelope.checksum = SaveCodec.compute_checksum(envelope)
	return JSON.stringify(envelope, "", true)
