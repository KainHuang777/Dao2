extends SceneTree
## Trailing actions use actual container geometry, never text padding/coordinates.
var failures: Array[String] = []
var checks := 0
var abode
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message)
func frames() -> void:
 for n in 12: await process_frame
func reveal(scroll: ScrollContainer, target: Control) -> void:
 scroll.scroll_vertical = 100000
 await frames()
 var view := scroll.get_global_rect()
 var rect := target.get_global_rect()
 if rect.position.y < view.position.y:
  scroll.scroll_vertical -= int(ceil(view.position.y - rect.position.y)) + 1
  await frames()
 elif rect.end.y > view.end.y:
  scroll.scroll_vertical += int(ceil(rect.end.y - view.end.y)) + 1
  await frames()
func trailing(action: Control, context: String) -> void:
 var row: Control = action.get_parent()
 check(absf(action.get_rect().end.x - row.size.x) <= 1.1, context + " right content edge")
 check(absf(action.get_rect().get_center().y - row.size.y * 0.5) <= 1.1, context + " vertical center")
 check(action.size.y >= 44 and action.size.x >= 44, context + " 44px hit")
 check(row.get_global_rect().encloses(action.get_global_rect()), context + " inside row")
func card_edge(action: Control, card: PanelContainer, context: String) -> void:
 var style := card.get_theme_stylebox("panel")
 check(absf(action.get_global_rect().end.x - (card.get_global_rect().end.x - style.get_content_margin(SIDE_RIGHT))) <= 1.1, context + " card safe right margin")
func _run() -> void:
 var script = load("res://src/abode/living_abode.gd")
 script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/early16-ui-a")
 SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
 abode = script.new()
 root.add_child(abode)
 await process_frame
 abode.set_process(false)
 abode.offline_summary.hide()
 abode.v2_rules_notice.hide()
 var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
 check(decoded.ok, "isolated earned fixture")
 abode.session.state = IslandProgression.prepare_supply(abode.content, decoded.state).state
 for id in ["wood", "ore", "herb"]: abode.session.state.economy.islands[id].opened = true
 abode._refresh_hud()
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 var nav = abode.feature_navigation
 for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
  root.size = vp
  root.content_scale_size = vp
  abode._layout_for_size(Vector2(vp))
  nav.open("buildings")
  await frames()
  var catalog = abode.building_catalog
  for id in catalog.upgrade_buttons:
   var button: Button = catalog.upgrade_buttons[id]
   if not button.is_visible_in_tree(): continue
   trailing(button, "building " + id)
   card_edge(button, catalog.cards[id], "building " + id)
  nav.open("outposts")
  nav.island_panel.select_island("wood")
  await frames()
  for id in nav.island_panel.facility_buttons:
   var button: Button = nav.island_panel.facility_buttons[id]
   trailing(button, "facility " + id)
   card_edge(button, nav.island_panel.facility_cards[id].card, "facility " + id)
  nav.open("transport")
  nav.transport_panel.back_to_list()
  await frames()
  var transport = nav.transport_panel
  for width in [transport.size.x, 410.0]:
   transport.set_layout_bounds(Rect2(transport.position, Vector2(width, transport.size.y)))
   await frames()
   for id in transport.route_widgets:
    var w: Dictionary = transport.route_widgets[id]
    if not w.root.is_visible_in_tree(): continue
    var host: Control = w.actions.get_parent()
    check(w.root.size.x <= transport.size.x + 1, "route bounded " + id)
    check(absf(w.actions.get_rect().end.x - host.size.x) <= 1.1, "route right edge " + id)
    if not host.vertical:
     check(absf(w.actions.get_rect().get_center().y - host.size.y * 0.5) <= 1.1, "route centered " + id)
    check(w.toggle.size.y >= 44 and w.settings.size.y >= 44, "route hit " + id)
   transport.show_success("測試成功回饋")
   abode._refresh_hud()
   await frames()
  abode._layout_for_size(Vector2(vp))
  nav.open("decisions")
  await frames()
  var page = nav.action_panel.decision_view
  var view: Dictionary = abode.session.get_view()
  var snapshot: Dictionary = abode.session.state.to_snapshot_dict()
  for funded in [false, true]:
   for item in view.realm_decisions:
    item.name = "長標題與缺料狀態驗證".repeat(4)
    item.is_ready = funded
    item.costs_met = funded
    item.usage_count = 999 if funded else 0
   page.refresh(view)
   await frames()
   for id in page.cards:
    var w: Dictionary = page.cards[id]
    trailing(w.action, "decision " + id)
    card_edge(w.action, w.card, "decision " + id)
    check(w.card.size.x <= page.scroll.size.x + 1, "long card bounded " + id)
   check(snapshot == abode.session.state.to_snapshot_dict(), "presentation refresh keeps state")
  await reveal(page.scroll, page.cards.values().back().action)
  check(page.scroll.get_global_rect().encloses(page.cards.values().back().action.get_global_rect()), "last action reachable")
  nav.open("skills")
  await frames()
  for w in nav.action_panel.skill_view.cards.values(): trailing(w.action, "skill sample")
  nav.open("beasts")
  await frames()
  for w in nav.action_panel.beast_view.cards.values():
   trailing(w.feed if w.feed.visible else w.acquire, "beast sample")
   for talent in w.talents.values(): trailing(talent.button, "beast talent sample")
  nav.open_manufacturing("wood", "spirit_timber")
  await frames()
  for w in nav.manufacturing_panel.cards.values():
   var row = w.row
   if not row.is_visible_in_tree(): continue
   trailing(row.settings, "recipe settings")
   check(absf(row.action.get_rect().get_center().y - row.controls.size.y * 0.5) <= 1.1, "recipe action centered")
  nav.home()
 abode.queue_free()
 await process_frame
 for message in failures: printerr("FAIL: " + message)
 print("EARLY-16-UI-A checks=%d failures=%d" % [checks, failures.size()])
 RunnerResult.finish(self, 0 if failures.is_empty() else 1)
