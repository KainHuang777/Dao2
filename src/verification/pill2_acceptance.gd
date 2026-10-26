extends Node
## Paused desktop harness. Named earned snapshots, real commands and Web storage.
var abode: Node
var elapsed := 0.0
var case_id := "era5"
var scene_ready := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if OS.has_feature("web"):
		case_id = String(JavaScriptBridge.eval("parent.caseId",true))
		if case_id not in ["era4","era5","era6"]: push_error("invalid case"); return
		var adapter := WebStorageAdapter.new("dao2_pill2_acceptance_"+case_id)
		var status := adapter.begin_session()
		while status == "pending":
			await get_tree().process_frame
			status = adapter.session_status()
		if status != "ready": push_error("test writer unavailable"); return
		if not adapter.exists(SaveSlots.SLOT_MAIN):
			var raw := FileAccess.get_file_as_string("res://src/verification/pill2-"+case_id+".json")
			var decoded := SaveCodec.decode(raw)
			if not decoded.ok: push_error("fixture decode failed"); return
			var now := str(int(Time.get_unix_time_from_system()*1000))
			var encoded := SaveCodec.encode(decoded.state,String(JSON.parse_string(raw).content_version),{"save_id":"pill2-"+case_id,"saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
			if not encoded.ok or not adapter.write(SaveSlots.SLOT_MAIN,encoded.json).ok: push_error("seed failed"); return
		JavaScriptBridge.eval("const set = Storage.prototype.setItem; Storage.prototype.setItem = function(k,v) { if(parent.shellFail) throw new DOMException('PILL2 isolated failure','QuotaExceededError'); return set.call(this,k,v); };",true)
	else:
		load("res://src/abode/living_abode.gd").save_dir_override = "user://pill2-native-review"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 6: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	abode._refresh_hud()
	abode.feature_navigation.open("alchemy")
	scene_ready = true
func _process(delta: float) -> void:
	if not scene_ready: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	var rows := {}
	var panel: AlchemyPanel = abode.alchemy_panel
	for id in AlchemySystem.P2_IDS:
		if not panel._widgets.has(id): continue
		var w: Dictionary = panel._widgets[id]
		var r: Rect2 = w.refine.get_global_rect()
		var c: Rect2 = w.consume.get_global_rect()
		rows[id] = {"refine":[r.position.x,r.position.y,r.size.x,r.size.y],"consume":[c.position.x,c.position.y,c.size.x,c.size.y],"refine_disabled":w.refine.disabled,"consume_disabled":w.consume.disabled,"status":w.status.text,"art":w.output.icon.resource_texture() != null}
	var resources := {}
	for id in state.resources: resources[id] = state.resources[id].value.serialize()
	var data := {"case":case_id,"evidence":"earned continuous CLI snapshot, paused Web mouse branch","era":state.era_id,"level":state.level,"pills":state.pills,"effects":state.pill_effects,"buffs":state.buffs,"resources":resources,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"rows":rows,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"scroll":panel._scroll.scroll_vertical}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")",true)
