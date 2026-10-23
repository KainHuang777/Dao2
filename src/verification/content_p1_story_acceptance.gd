extends Node
## Explicit funded, paused test state; separate namespace, never player progress.
class FaultAdapter extends StorageAdapter:
	var backend: StorageAdapter
	func _init(adapter: StorageAdapter) -> void: backend = adapter
	func read(key: String) -> Dictionary: return backend.read(key)
	func exists(key: String) -> bool: return backend.exists(key)
	func erase(key: String) -> Dictionary: return backend.erase(key)
	func write(key: String, value: String) -> Dictionary:
		if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!parent.shellFail",true)):
			return {"ok":false,"error":"STORY_TEST_WRITE_DENIED"}
		return backend.write(key,value)
var abode: Node
var elapsed := 0.0
var observation_seq := 0
var _clock_active := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()
func start() -> void:
	if not OS.has_feature("web"): SaveSlots.new(FileStorageAdapter.new("user://content-p1-story-acceptance")).reset()
	load("res://src/abode/living_abode.gd").save_dir_override = "" if OS.has_feature("web") else "user://content-p1-story-acceptance"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
	for i in 4: await get_tree().process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	if not abode.session.state.tutorial_flags.get("content_p1_story_fixture",false):
		var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://src/verification/content_p1_story_fixture.json"))
		if not decoded.ok: push_error("story fixture decode failed: " + str(decoded.error)); return
		abode.session.state = decoded.state
		abode.session.state.tutorial_flags.content_p1_story_fixture = true
		abode.session.state.tutorial_flags.seen_nine_realms_hook = true
		var selected := String(JavaScriptBridge.eval("parent.document.getElementById('template').value",true)) if OS.has_feature("web") else "album"
		if selected == "full-album":
			for id in ["wood", "stone_low", "spirit_grass_low", "lingli", "money"]: abode.session.state.resources[id].value = StoryProgress.cap(abode.session.state,abode.content,id)
		if selected.begins_with("enc_p1_"):
			for def in FortuneSystem.get_encounters():
				if def.id != selected: continue
				var state: GameState = abode.session.state
				for id in ["wood", "stone_low", "spirit_grass_low", "lingli", "money"]: state.resources[id].value = AmountCompat.from_number(80)
				state.economy = IslandEconomy.initial()
				state.economy.islands.wood.opened = true
				var pending := StorySaveContract.freeze(def,state)
				pending.instance_id = ("story-ui-"+selected).sha256_text()
				state.economy = {}
				state.fortune.pending_encounter = pending
		abode._save_game()
	SaveManager.configure(abode.content,FaultAdapter.new(SaveManager.adapter()))
	abode._refresh_hud()
	abode.feature_navigation.open("achievements" if not OS.has_feature("web") or not String(JavaScriptBridge.eval("parent.document.getElementById('template').value",true)).begins_with("enc_p1_") else "fortune")
func buttons(node: Node, result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var r: Rect2 = node.get_global_rect()
		result.append({"name":str(node.name),"path":str(node.get_path()),"text":node.text,"disabled":node.disabled,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	for child in node.get_children(): buttons(child,result)
func _process(delta: float) -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null: return
	var realtime := OS.has_feature("web") and bool(JavaScriptBridge.eval("parent.document.getElementById('clock').checked",true))
	if realtime and not _clock_active: abode._last_process_ticks_msec = Time.get_ticks_msec()
	_clock_active = realtime
	abode.set_process(realtime)
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	var state: GameState = abode.session.state
	# Paused fixtures still refresh after the pressed-button rebuild guard releases.
	abode._refresh_hud()
	var resources := {}
	for id in ["wood","stone_low","spirit_grass_low","lingli","money"]: resources[id] = state.resources[id].value.serialize()
	var actions := []
	buttons(abode.achievement_panel if abode.achievement_panel.visible else abode.fortune_modal, actions)
	var overlay_buttons := []
	if abode._storage_block_layer != null: buttons(abode._storage_block_layer,overlay_buttons)
	var viewport_size := get_viewport().get_visible_rect().size
	var scroll_rect: Rect2 = abode.achievement_panel._scroll.get_global_rect() if abode.achievement_panel.visible else abode.fortune_modal._body_scroll.get_global_rect()
	observation_seq += 1
	var data := {"book":abode.session.get_decision_book(),"contribution":str(state.sect.get("contribution","0")),"overlay_buttons":overlay_buttons,"observation_seq":observation_seq,"viewport":[viewport_size.x,viewport_size.y],"scroll_rect":[scroll_rect.position.x,scroll_rect.position.y,scroll_rect.size.x,scroll_rect.size.y],"fixture":"synthetic isolated story", "era_id":state.era_id,"age_seconds":state.total_elapsed_seconds,"achievements":state.achievements,"resources":resources,"pills":state.pills,"fortune":state.fortune,"story_version":state.story_version,"revision":state.revision,"save_failed":abode.feature_navigation.shell.save_failed,"buttons":actions}
	if OS.has_feature("web"): JavaScriptBridge.eval("parent.document.getElementById('state').textContent = "+JSON.stringify(JSON.stringify(data)),true)
