extends Node
## Isolated desktop mouse verification, using earned CLI snapshots and real commands.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(value: StorageAdapter) -> void: backend = value
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail", true)):
			return {"ok":false,"error":"P2_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
var refill_seen := 0
var refill_result := {}
var era := 6
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if OS.has_feature("web"): era = int(JavaScriptBridge.eval("parent.caseEra",true))
	if era not in [3,4,5,6]: push_error("invalid earned era"); return
	if not OS.has_feature("web"):
		load("res://src/abode/living_abode.gd").save_dir_override = "user://sks-p2-mouse-era" + str(era)
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("sks_p2_mouse",false):
		var suffix := "library" if era == 3 else "first-tier"
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/sks_p2_earned-era" + str(era) + "-" + suffix + ".json"))
		if not decoded.ok: push_error("earned snapshot decode failed"); return
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.sks_p2_mouse = true
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("skills")
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	abode.set_process(false)
	elapsed += delta
	if elapsed < 0.5: return
	elapsed = 0
	if OS.has_feature("web"):
		var requested := int(JavaScriptBridge.eval("parent.refillRequest",true))
		if requested != refill_seen:
			refill_seen = requested
			var resource: Dictionary = abode.session.get_view().resources.skill_point
			var seconds := maxi(0,int(ceil((float(resource.cap)-IslandEconomy.value(abode.session.state,"home","skill_point"))/maxf(0.01,float(resource.rate)))))
			refill_result = abode.session.advance_time(seconds)
			abode._save_game()
			abode._refresh_hud()
	var s: GameState = abode.session.state
	var items: Array = []
	var page = abode.feature_navigation.action_panel.skill_view
	for item in abode.session.get_view().skills.items:
		var r: Rect2 = page.cards[item.id].action.get_global_rect()
		items.append({"id":item.id,"level":item.level,"cost":item.cost,"reason":item.reason,"scope":item.scope,"scope_note":item.scope_note,"current":item.current_effect,"next":item.next_effect,"art":page.cards[item.id].art.texture != null,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	var data := {"evidence":"earned CLI fixture; paused browser; refill advances legal simulation time","era":s.era_id,"skills":s.skills,"points":IslandEconomy.value(s,"home","skill_point"),"revision":s.revision,"skill_version":s.skill_version,"economy_version":s.economy.get("version"),"save_failed":abode.feature_navigation.shell.save_failed,"age":s.total_elapsed_seconds,"refill":refill_seen,"refill_result":refill_result,"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"items":items}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState(" + JSON.stringify(data) + ")",true)
