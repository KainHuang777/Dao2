extends SceneTree
var failures: Array[String] = []
var checks := 0
var clicks := 0
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message)
func frames() -> void:
 for i in 8: await process_frame
func click(button: Button) -> void:
 var point := button.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position = point
 Input.parse_input_event(motion)
 await process_frame
 for down in [true, false]:
  var event := InputEventMouseButton.new()
  event.position = point
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  Input.parse_input_event(event)
  await process_frame
func seals(node: Node) -> Array:
 var result: Array = []
 if node is CloseSeal: result.append(node)
 for child in node.get_children(): result.append_array(seals(child))
 return result
func scrolls(node: Node) -> Array:
 var result: Array = []
 if node is ScrollContainer: result.append(node)
 for child in node.get_children(): result.append_array(scrolls(child))
 return result
func _run() -> void:
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 for vp in ([Vector2i(1280,720), Vector2i(844,390), Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2i(1280,720)]):
  root.size = vp
  var seal := CloseSeal.new()
  root.add_child(seal)
  seal.pressed.connect(func(): clicks += 1)
  await frames()
  check(seal.text.is_empty() and seal.icon == null, "vector cross independent of glyph/asset")
  check(seal.accessibility_name == "關閉" and seal.tooltip_text == "關閉", "close name and TIP")
  check(seal.get_theme_stylebox("normal").bg_color == Color.TRANSPARENT, "transparent idle")
  check(seal.get_theme_stylebox("hover").bg_color != seal.get_theme_stylebox("pressed").bg_color, "distinct hover/pressed")
  await click(seal)
  check(clicks == 1, "one mouse click one callback")
  seal.disabled = true
  await click(seal)
  check(clicks == 1, "disabled does not close")
  seal.disabled = false
  seal.grab_focus()
  for down in [true, false]:
   var key := InputEventKey.new()
   key.keycode = KEY_ENTER
   key.pressed = down
   Input.parse_input_event(key)
   await process_frame
  check(clicks == 2 and seal.has_focus(), "keyboard focus and Enter close once")
  seal.free()
  clicks = 0
  for script in ["building_catalog", "island_management_panel", "offline_summary", "v2_rules_notice", "save_controls", "debug_panel", "realm_teleport_modal"]:
   var page = load("res://src/presentation/" + script + ".gd").new()
   root.add_child(page)
   var bounds := Rect2(Vector2.ZERO, Vector2(mini(vp.x, 580), mini(vp.y, 340)))
   if page.has_method("set_layout_bounds"): page.set_layout_bounds(bounds)
   else: page.size = bounds.size
   page.show()
   if script == "offline_summary": page.show_report({})
   await frames()
   var buttons := seals(page)
   check(buttons.size() == 1, script + " one common close")
   var button: Button = buttons[0]
   var before := button.get_global_rect()
   check(before.size.x >= 44 and before.size.y >= 44, script + " hit 44")
   check(page.get_global_rect().encloses(before), script + " close inside page")
   for scroll in scrolls(page):
    var filler := Label.new()
    filler.text = "長內容捲動驗證\n".repeat(80)
    if scroll.get_child(0) is Label:
     scroll.get_child(0).text += filler.text
     filler.free()
    else:
     scroll.get_child(0).add_child(filler)
    await frames()
    check(not scroll.is_ancestor_of(button), script + " close outside scroller")
    scroll.scroll_vertical = 100000
    await frames()
    check(scroll.scroll_vertical > 0, script + " content actually scrolled")
   await frames()
   check(before == button.get_global_rect(), script + " fixed while scrolling")
   if page.has_signal("close_requested"): page.close_requested.connect(func(): clicks += 1)
   if page.has_signal("closed"): page.closed.connect(func(): clicks += 1)
   await click(button)
   if page.has_signal("close_requested") or page.has_signal("closed"):
    check(clicks == 1, script + " original route once")
   else: check(not page.visible, script + " dismissed")
   clicks = 0
   page.free()
 for failure in failures: push_error(failure)
 print("EARLY16_UI_B: %d checks, %d failures" % [checks, failures.size()])
 RunnerResult.finish(self, 0 if failures.is_empty() else 1)
