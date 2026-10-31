extends SceneTree
var failures := []
var checks := 0
class DeniedStorage extends StorageAdapter:
 var data := {}
 var deny := false
 func read(key: String) -> Dictionary:
  return {"ok":data.has(key),"data":data.get(key,""),"error":"missing"}
 func write(key: String, value: String) -> Dictionary:
  if deny: return {"ok":false,"error":"QuotaExceededError"}
  data[key] = value
  return {"ok":true}
 func exists(key: String) -> bool: return data.has(key)
func _init() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
 checks += 1
 if not ok: failures.append(note); print("FAIL ", note)
func frames() -> void:
 for i in 8: await process_frame
func run() -> void:
 var content: GameContent = ContentLoader.load_directory("res://content").content
 IslandProgression.attach_supply(content)
 var state: GameState = preload("res://tests/sect_reform_ui_fixture.gd").create(content)
 var encoded := SaveCodec.encode(state, content.content_version, {"save_id":"sect-ui-review","saved_at_utc_ms":"1000","settled_until_utc_ms":"1000","sim_tick":"0"})
 check(encoded.ok, "fixture full codec " + str(encoded.get("error")))
 check(SectReformRelease.validate(state).is_empty(), "complete synthetic fixture validates " + SectReformRelease.validate(state))
 var session := GameSession.new()
 session.content = content
 session.state = state
 var panel := SectPanel.new()
 root.add_child(panel)
 var beasts = preload("res://src/presentation/beast_care_view.gd").new()
 root.add_child(beasts)
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
  root.size = vp
  panel.set_layout_bounds(Rect2(20,20,vp.x-40,vp.y-80))
  panel.update_view(state)
  panel._switch_tab(SectPanel.TabMode.TECHNIQUES)
  await frames()
  check(panel._grids.size() == 2, "specialization and common sections")
  check(panel._grids[0].get_child_count() == 10, "ten specialization options")
  session.get_view() # Prime pre-existing legacy derived state before read-only UI comparison.
  var before := JSON.stringify(state.to_snapshot_dict())
  var acquired := []
  beasts.action_requested.connect(func(kind: String, id: String): acquired.append([kind,id]))
  beasts.position = Vector2(20,20)
  beasts.size = Vector2(vp.x-40,vp.y-80)
  panel.hide()
  beasts.refresh(session.get_view())
  await frames()
  check(beasts.cards.size() == 11, "eleven permanent controls")
  for id in GuardianBeasts.SPECIES:
   var card: Dictionary = beasts.cards[id]
   check(card.talents.size() == 4, "four distinct talents " + id)
   check(card.art.texture is AtlasTexture, "growth atlas " + id)
   check(not card.redeem.disabled, "24 tokens permits redeem " + id)
   check(card.acquire.disabled, "discovery separate from acquisition " + id)
   card.redeem.pressed.emit()
   check(acquired.back() == ["redeem",id], "target-specific signal " + id)
   beasts.scroll.ensure_control_visible(card.redeem)
   await frames()
   check(beasts.scroll.get_global_rect().encloses(card.redeem.get_global_rect()), "redeem reachable by internal scroll " + id)
   var persistent: Button = card.redeem
   beasts.refresh(session.get_view())
   check(persistent == beasts.cards[id].redeem, "stable mouse target " + id)
  check(JSON.stringify(state.to_snapshot_dict()) == before, "rendering and signals never mutate state or RNG")
  var req := GuardianDiscovery.redeem_requirements(state, "taixu_baize")
  var copy := state.duplicate_state()
  check(req == GuardianDiscovery.redeem(copy,"taixu_baize") or (req.ok and copy.sect.guardian.permits.has("taixu_baize")), "view and command eligibility")
  state.sect.guardian.guardian_tokens = 0
  beasts.refresh(session.get_view())
  check(beasts.cards.taixu_baize.redeem.disabled, "token shortage updates without rebuild")
  state.sect.guardian.guardian_tokens = 24
  for stage in ["egg","young","growing","mature"]:
   state.beasts.active = {"id":"taixu_baize","stage":stage,"exp":{"egg":0,"young":100,"growing":500,"mature":1000}[stage]}
   state.sect.guardian.permits.taixu_baize = true
   beasts.refresh(session.get_view())
   var index: int = ["egg","young","growing","mature"].find(stage)
   check(beasts.cards.taixu_baize.art.get_meta("stage") == index, "growth uses actual stage " + stage)
  state.beasts.active = {}
  state.sect.guardian.permits.erase("taixu_baize")
 # Reproduce a real candidate command failure, then recover through SaveManager.
 var memory := DeniedStorage.new()
 check(memory.write(SaveSlots.SLOT_MAIN, encoded.json).ok, "seed UI recovery storage")
 SaveManager.configure(content, memory)
 session.state = SaveManager.current_state()
 panel.update_view(session.state)
 memory.deny = true
 var denied := session.submit({"command_id":"ui-denial","expected_revision":session.state.revision,"type":"learn_sect_technique","payload":{"technique_id":"taixu_inner_cycle"}})
 check(not denied.ok and SaveManager.core_save_pending(session.state), "legal technique stages pending candidate on write denial")
 panel.set_command_result(denied)
 check(panel._pending_save and panel._feedback.text.begins_with("操作待保存"), "pending command feedback distinguishes save failure")
 memory.deny = false
 var recovered := SaveManager.save(session.state, {})
 check(recovered.ok, "same candidate retry succeeds")
 panel.storage_recovered()
 check(not panel._pending_save and panel._feedback.text == "保存已恢復，操作結果已保存。" and panel._feedback.tooltip_text == panel._feedback.text, "recovery clears stale quota text and tooltip")
 var achievements := AchievementPanel.new()
 root.add_child(achievements)
 achievements.set_layout_bounds(Rect2(20,20,1000,600))
 achievements.update_view(session.get_view())
 for id in SectLineage.ACHIEVEMENTS:
  check(achievements._achievement_items.has(id), "lineage achievement card " + id)
  var card: Control = achievements._achievement_items[id]
  check(card.get_node("HBox/Badge").texture != null, "lineage badge source " + id)
  check(not card.get_node("HBox/Info/Reason").text.is_empty(), "explicit condition and progress " + id)
 achievements.queue_free()
 var report := {"checks":checks,"failures":failures,"level":"L1","fixture":"synthetic; not natural player progress or browser input"}
 var out := RunnerResult.output_path("res://docs/verification/artifacts/sect-reform-ui/result.json")
 DirAccess.make_dir_recursive_absolute(out.get_base_dir())
 FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("SECT REFORM UI ",checks," failures=",failures)
 panel.queue_free(); beasts.queue_free()
 await process_frame
 RunnerResult.finish(self, 0 if failures.is_empty() else 1)
