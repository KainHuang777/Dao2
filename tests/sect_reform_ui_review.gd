extends Node
## Isolated desktop Web harness. Paused synthetic scenario, actual native controls/storage.
var abode: Node
var ready_review := false
var elapsed := 0.0
var reported_pending := false
func _ready() -> void: start.call_deferred()
func start() -> void:
 var content: GameContent = ContentLoader.load_directory("res://content").content
 IslandProgression.attach_supply(content)
 var adapter: StorageAdapter
 if OS.has_feature("web"):
  adapter = WebStorageAdapter.new("dao2_sect_reform_ui_review_v1")
  var status: String = adapter.begin_session()
  while status == "pending":
   await get_tree().process_frame
   status = adapter.session_status()
  if status != "ready": push_error("isolated writer unavailable"); return
 else:
  var folder := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform-ui/review-storage")
  adapter = FileStorageAdapter.new(folder)
  load("res://src/abode/living_abode.gd").save_dir_override = folder
 if not adapter.exists(SaveSlots.SLOT_MAIN):
  var state: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
  var life_case := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('life')", true)) if OS.has_feature("web") else ""
  if life_case == "gate":
   state = GameSession.create_new_game(content, 31).state
   state.era_id = 2
   state.highest_era = 2
  elif life_case in ["1","tournament"]:
   var sect_case := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('sect')", true)) if OS.has_feature("web") else ""
   if SectIdentity.NAMES.has(sect_case):
    SectIdentity.write(state.sect,sect_case)
    SectLineage.observe(state)
    state.sect.available_tasks = []
    SectSystem.refresh_tasks(state)
   state = SectLife.prepare(state)
   state.sect.entry = SectEntry.initial()
   state.sect.entry.skip = true
   SectLife.advance(state, 300 if life_case == "tournament" else 1, true)
  if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('entry')", true)) == "1":
   state.sect.entry = SectEntry.initial()
  var now := str(int(Time.get_unix_time_from_system()*1000))
  var result := SaveCodec.encode(state, content.content_version, {"save_id":"sect-ui-review", "saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":"0"})
  if not result.ok or not adapter.write(SaveSlots.SLOT_MAIN, result.get("json", "")).ok: push_error("isolated seed failed " + str(result)); return
 if OS.has_feature("web"):
  JavaScriptBridge.eval("const originalSet = Storage.prototype.setItem; Storage.prototype.setItem = function(k,v) { if(parent.shellFail && k.startsWith('dao2_sect_reform_ui_review_v1:')) throw new DOMException('UI review write denial','QuotaExceededError'); return originalSet.call(this,k,v); };", true)
 abode = load("res://scenes/living_abode.tscn").instantiate()
 add_child(abode)
 while abode.session == null or abode.feature_navigation == null: await get_tree().process_frame
 for i in 10: await get_tree().process_frame
 abode.set_process(false)
 abode.offline_summary.hide()
 abode.v2_rules_notice.hide()
 abode.feature_navigation.open("sect")
 if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('life')", true)) == "1":
  abode.sect_panel._switch_tab(SectPanel.TabMode.FELLOWS)
 if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('life')", true)) == "tournament":
  abode.sect_panel._switch_tab(SectPanel.TabMode.TOURNAMENT)
 ready_review = true
 print("SECT_REFORM_UI_REVIEW_READY")
func _process(delta: float) -> void:
 if not ready_review: return
 abode.set_process(false)
 elapsed += delta
 if elapsed < 0.25: return
 elapsed = 0
 if SaveManager.core_save_pending(abode.session.state):
  if not reported_pending:
   reported_pending = true
   abode._save_game() # Match normal living_abode preflight while the review clock is paused.
 else: reported_pending = false
 abode._refresh_hud()
 var state: GameState = abode.session.state
 var data := {"revision":state.revision,"tokens":state.sect.guardian.guardian_tokens,"permits":state.sect.guardian.permits,"active":state.beasts.active,"techniques":state.sect.techniques,"lineage":state.sect.lineage.learned,"souls":state.beast_souls,"pending":SaveManager.core_save_pending(state),"route":abode.feature_navigation.page,"buttons":[]}
 data["sect_life"] = SectLife.view(state)
 data["contribution"] = state.sect.contribution
 gather(abode.hud, data.buttons)
 if OS.has_feature("web"): JavaScriptBridge.eval("parent.receiveState("+JSON.stringify(data)+")", true)
func gather(node: Node, result: Array) -> void:
 if node is Button and node.is_visible_in_tree():
  var rect: Rect2 = node.get_global_rect()
  result.append({"text":node.text,"disabled":node.disabled,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
 for child in node.get_children(): gather(child, result)
