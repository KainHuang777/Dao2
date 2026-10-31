extends SceneTree
const META := {"save_id":"sect-identity-isolated", "saved_at_utc_ms":"1000", "settled_until_utc_ms":"1000", "sim_tick":"0"}
var checks := 0
var failures: Array[String] = []
var content: GameContent

class Memory extends StorageAdapter:
	var data := {}
	var fail := false
	func exists(key: String) -> bool: return data.has(key)
	func read(key: String) -> Dictionary: return {"ok":data.has(key), "data":data.get(key, ""), "error":"missing"}
	func write(key: String, value: String) -> Dictionary:
		if fail: return {"ok":false, "error":"injected_write"}
		data[key] = value
		return {"ok":true}
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok":true}

func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func fresh() -> GameSession:
	var session := GameSession.create_new_game(content, 20261030)
	session.state.era_id = 2
	return session
func command(session: GameSession, kind: String, payload: Dictionary, id: String = "test") -> Dictionary:
	return {"command_id":id, "type":kind, "payload":payload, "expected_revision":session.state.revision}
func legacy(session: GameSession, name: String) -> void:
	SectSystem.ensure_sect_state(session.state)
	session.state.sect.merge({"unlocked":true, "sect_id":"taixu_sect", "sect_name":name, "contribution":"123", "techniques":{"breathing_method":3}, "market_purchases":{"herb_bundle":4}}, true)
	session.state.sect.available_tasks = [{"id":"frozen", "name":"舊委託", "duration":60, "elapsed":0, "rewards":{"contribution":15, "money":50}}]

func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	for id in SectIdentity.NAMES:
		for value in [id, SectIdentity.NAMES[id]]:
			var session := fresh()
			check(session.join_sect(value).ok, "join ID or alias " + value)
			check(session.state.sect.sect_id == id and session.state.sect.sect_name == SectIdentity.NAMES[id], "paired identity")
			check(session.state.sect.available_tasks.size() == 3, "initial tasks")
			var before := session.state.to_snapshot_dict()
			check(not session.join_sect("taixu_sect").ok and before == session.state.to_snapshot_dict(), "no switching")
		var old := fresh()
		legacy(old, SectIdentity.NAMES[id])
		var before := old.state.to_snapshot_dict()
		check(SectIdentity.view(old.state.sect).sect_id == id, "legacy name wins over taixu default")
		check(before == old.state.to_snapshot_dict(), "identity read is pure")
		var encoded := SaveCodec.encode(old.state,content.content_version,META)
		check(encoded.ok, "encode untouched legacy")
		var decoded := SaveCodec.decode(encoded.get("json", ""))
		check(decoded.ok, "decode untouched legacy " + str(decoded.get("error")))
		if decoded.ok:
			check(JSON.parse_string(JSON.stringify(decoded.state.sect)) == JSON.parse_string(JSON.stringify(old.state.sect)), "legacy roundtrip does not silently rewrite identity")
		check(not old.resolve_legacy_sect_identity("taixu_sect").ok, "known identity cannot reselect")
		SectSystem.on_reincarnate(old.state)
		check(SectIdentity.view(old.state.sect).sect_id.is_empty(), "unjoined legacy no identity")
	for payload in [{"sect_id":"unknown"}, {"sect_name":"unknown"}, {"sect_id":7}, {"sect_id":"tianjian_sect", "sect_name":"太虛天闕"}, {"sect_id":"", "sect_name":"太虛天闕"}]:
		var session := fresh()
		var before := session.state.to_snapshot_dict()
		check(not session.submit(command(session,"join_sect",payload)).ok and before == session.state.to_snapshot_dict(), "invalid identity no mutation " + str(payload))
	var direct := fresh()
	check(direct.submit(command(direct,"join_sect",{"sect_id":"wanfo_sect"})).ok, "formal payload")
	SectSystem.on_reincarnate(direct.state)
	check(direct.state.sect.sect_id == "" and SectSaveContract.validate(direct.state.sect_version,direct.state.sect).is_empty(), "new life clears canonical ID")
	check(direct.join_sect("zixiao_sect").ok and direct.state.sect.sect_id == "zixiao_sect", "new life reselect")
	for name in ["unknown", "", "tianjian_sect"]:
		var old := fresh()
		legacy(old, name)
		var before := old.state.to_snapshot_dict()
		check(SectIdentity.view(old.state.sect).identity_pending, "unknown legacy pending")
		check(not SectSystem.refresh_tasks(old.state,true).ok and before == old.state.to_snapshot_dict(), "pending no new tasks even force")
		check(is_equal_approx(SectSystem.compute_multipliers(old.state).cultivation_speed_bonus,0.06), "pending retains shared effects")
		check(SectSystem.start_expedition(old.state,"frozen").ok, "old task may start")
		SectSystem.tick(old.state,60)
		check(SectSystem.claim_expedition_reward(old.state).ok, "old task may claim")
		var data_before := old.state.sect.duplicate(true)
		var cmd := command(old,"resolve_legacy_sect_identity",{"sect_id":"piaomiao_sect"},"resolve")
		var pending := old.state.to_snapshot_dict()
		var stale := cmd.duplicate(true)
		stale.expected_revision += 1
		check(old.submit(stale).get("error") == "STALE_REVISION" and pending == old.state.to_snapshot_dict(), "stale identity confirmation no mutation")
		for invalid in [7, "unknown", "太虛天闕"]:
			check(not old.submit(command(old,"resolve_legacy_sect_identity",{"sect_id":invalid})).ok and pending == old.state.to_snapshot_dict(), "resolution requires formal known ID")
		check(old.submit(cmd).ok, "one-time confirm")
		for field in data_before:
			if field not in ["sect_id","sect_name"]: check(old.state.sect[field] == data_before[field], "resolution preserves " + field)
		var resolved := old.state.to_snapshot_dict()
		check(old.submit(cmd).get("duplicate",false) and resolved == old.state.to_snapshot_dict(), "receipt no replay")
		check(not old.resolve_legacy_sect_identity("wanfo_sect").ok, "cannot resolve twice")
		var mem := Memory.new()
		SaveManager.configure(content,mem)
		mem.fail = true
		check(not SaveManager.save(old.state,META).ok and not SaveManager.save(old.state,META).ok and resolved == old.state.to_snapshot_dict(), "save failure preserves same result")
		mem.fail = false
		check(SaveManager.save(old.state,META).ok, "save retry")
		SaveManager.configure(content,mem)
		old.state = SaveManager.current_state()
		check(old.state != null, "reload")
		if old.state != null:
			check(old.state.sect.sect_id == "piaomiao_sect" and old.submit(cmd).get("duplicate",false), "persisted identity and receipt")
		SaveManager.reset_for_tests()
	var good := fresh()
	good.join_sect("tianjian_sect")
	for value in [0,2,true,"1",1.5]:
		var bad := good.state.sect.duplicate(true)
		bad.identity_version = value
		check(not SectSaveContract.validate(2,bad).is_empty(), "identity version rejects " + str(value))
	for field in ["sect_id","sect_name","unlocked"]:
		var bad := good.state.sect.duplicate(true)
		bad[field] = false if field == "unlocked" else "forged"
		check(not SectSaveContract.validate(2,bad).is_empty(), "identity field rejects " + field)
	print("SECT-REFORM-IDENTITY ",checks," checks failures=",JSON.stringify(failures))
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
