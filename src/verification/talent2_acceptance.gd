extends Node
## Paused isolated desktop verification. Only named, provenance-recorded fixtures.
var abode: Node
var elapsed := 0.0
var case_id := "earned"
var scene_ready := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if OS.has_feature("web"):
		case_id = String(JavaScriptBridge.eval("parent.caseId",true))
		if case_id not in ["earned","elixir","frontier","beast","budget","max","migration"]: push_error("invalid case"); return
		var adapter := WebStorageAdapter.new("dao2_talent2_acceptance_"+case_id)
		var status := adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = adapter.session_status()
		if status != "ready": push_error("test writer unavailable"); return
		if not adapter.exists(SaveSlots.SLOT_MAIN):
			var suffix: String = {"budget":"synthetic-budget","max":"synthetic-max","migration":"old-earned"}.get(case_id,"earned")
			var raw := FileAccess.get_file_as_string("res://src/verification/talent2-"+suffix+".json")
			var decoded := SaveCodec.decode(raw)
			if not decoded.ok: push_error("test fixture decode failed"); return
			# Current timestamp prevents the harness pause from becoming a historical offline grant.
			var now := str(int(Time.get_unix_time_from_system()*1000))
			var encoded := SaveCodec.encode(decoded.state,String(JSON.parse_string(raw).content_version),{"save_id":"talent2-"+case_id,"saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
			if not encoded.ok or not adapter.write(SaveSlots.SLOT_MAIN,encoded.json).ok: push_error("test seed failed"); return
		# Fault is injected at localStorage, exercising the real Web adapter and startup UI.
		JavaScriptBridge.eval("""const originalSet = Storage.prototype.setItem; Storage.prototype.setItem = function(k,v) { if(parent.shellFail && (parent.caseId !== 'migration' || k.includes('save_before_talents_'))) throw new DOMException('isolated TALENT-2 injected failure','QuotaExceededError'); return originalSet.call(this,k,v); };""",true)
	else:
		load("res://src/abode/living_abode.gd").save_dir_override = "user://talent2-native"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode._refresh_hud()
	abode.feature_navigation.open("reincarnation")
	abode.reincarnation_panel._switch_tab("talents")
	scene_ready = true
func _process(delta: float) -> void:
	if abode == null: return
	if scene_ready: abode.set_process(false)
	elapsed += delta
	if elapsed < 0.3: return
	elapsed = 0
	var data := {"case":case_id,"ready":scene_ready,"evidence":"paused isolated earned rebirth; budget/max explicitly synthetic"}
	if scene_ready:
		var state: GameState = abode.session.state
		var page: ReincarnationPanel = abode.reincarnation_panel
		var rows := {}
		for id in page._talent_rows:
			var row: PanelContainer = page._talent_rows[id]
			var button: Button = row.find_child("LearnButton",true,false)
			var rect := button.get_global_rect()
			rows[id] = {"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"disabled":button.disabled,"button":button.text,"description":row.find_child("TalentDesc",true,false).text,"cost":row.find_child("CostLabel",true,false).text,"art":row.find_child("TalentArt",true,false).texture != null}
		data.merge({"hearts":state.dao_heart.serialize(),"talents":state.talents,"era":state.era_id,"highest":state.highest_era,"rebirths":state.reincarnation_count,"talent_version":state.talent_version,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]})
	else:
		var candidate: GameState = SaveManager.load_state()
		if candidate != null: data.merge({"migration_pending":SaveManager.migration_pending(candidate),"hearts":candidate.dao_heart.serialize(),"talents":candidate.talents,"revision":candidate.revision,"talent_version":candidate.talent_version})
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
