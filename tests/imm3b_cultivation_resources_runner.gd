extends SceneTree
## IMM-3B: icon resource language on cultivation, beasts, sect and fortune surfaces.
const ShellResources = preload("res://src/presentation/ui_shell_resources.gd")
const FortuneModal = preload("res://src/presentation/fortune_modal.gd")
const DecisionView = preload("res://src/presentation/realm_decision_view.gd")
var checks := 0
var failures: Array[String] = []
var abode: Node

class MemoryAdapter extends StorageAdapter:
	var data := {}
	func read(key: String) -> Dictionary:
		return {"ok": data.has(key), "data": data.get(key, ""), "error": "missing"}
	func write(key: String, payload: String) -> Dictionary:
		data[key] = payload
		return {"ok": true}
	func exists(key: String) -> bool:
		return data.has(key)
	func erase(key: String) -> Dictionary:
		data.erase(key)
		return {"ok": true}

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func frames() -> void:
	for n in 4:
		await process_frame

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/imm3b/imm3b_cultivation_resources_runner")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	abode = script.new()
	root.add_child(abode)
	await process_frame
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	check(decoded.ok, "earned fixture decodes")
	var state = IslandProgression.prepare_supply(abode.content, decoded.state).state
	state.economy.jobs = {}
	state.economy.routes = {}
	state.economy.trips = {}
	for id in abode.content.processing_catalog.resources:
		ProcessingInventory.write(state, id, AmountCompat.from_number(1000 if id in IslandEconomy.GLOBAL else 100))
		state.resources[id].unlocked = true
	abode.session.state = state
	SaveManager.configure(abode.content, MemoryAdapter.new())
	abode._refresh_hud()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var nav = abode.feature_navigation
	var sizes: Array = [Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]
	for vp in sizes:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		abode._layout_for_size(vp)
		await frames()
		await _check_skills(nav, vp)
		await _check_beasts(nav, vp)
		await _check_decisions(nav, vp)
		await _check_sect(nav, vp)
	_check_decision_lifespan()
	await _check_reincarnation()
	await _check_fortune()
	_check_shell_routes(nav)
	if failures.is_empty():
		print("PASS: IMM-3B ", checks, " checks; cultivation/beast/sect/fortune resource seals")
		RunnerResult.finish(self, 0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		RunnerResult.finish(self, 1)

func _check_skills(nav, vp: Vector2) -> void:
	nav.open("skills")
	abode._layout_for_size(vp)
	await process_frame
	var view: Dictionary = abode.session.get_view()
	var rows: Array = view.get("skills", {}).get("items", [])
	check(not rows.is_empty(), "skill rows exist " + str(vp))
	var view_cards: Dictionary = nav.action_panel.skill_view.cards
	check(view_cards.size() == rows.size(), "one skill card per row " + str(vp))
	var pointed := 0
	var sources_ok := true
	for item in rows:
		if not view_cards.has(item.id):
			continue
		var strip = view_cards[item.id].cost
		check(strip.visible_tiles() == 1, "skill cost is one icon cell " + str(vp))
		var tile = strip.tiles.get("skill_point")
		if tile != null and tile.visible:
			pointed += 1
			sources_ok = sources_ok and tile.caption.text.contains("當世")
			sources_ok = sources_ok and not tile.quantity.text.is_empty()
	check(pointed == rows.size(), "skill cell uses the skill-point seal " + str(vp))
	check(sources_ok, "skill cell names the 當世 source " + str(vp))

func _check_beasts(nav, vp: Vector2) -> void:
	nav.open("beasts")
	abode._layout_for_size(vp)
	await process_frame
	var view: Dictionary = abode.session.get_view()
	var cards: Dictionary = nav.action_panel.beast_view.cards
	check(not cards.is_empty(), "beast cards exist " + str(vp))
	var food_ok := false
	var soul_ok := true
	for id in cards:
		var card: Dictionary = cards[id]
		if card.cost.visible_tiles() > 0:
			food_ok = true
			for resource in card.cost.tiles:
				var tile = card.cost.tiles[resource]
				soul_ok = soul_ok and tile.caption.text.contains("祖島")
		soul_ok = soul_ok and card.soul.text.contains("同種獸魂") and card.soul.text.contains("不用於餵養")
	check(food_ok, "beast feed costs render as icon cells " + str(vp))
	check(soul_ok, "feed source 祖島 and souls stay a separate seal " + str(vp))

func _check_decisions(nav, vp: Vector2) -> void:
	nav.open("decisions")
	abode._layout_for_size(vp)
	await process_frame
	var view: Dictionary = abode.session.get_view()
	var items: Array = view.get("realm_decisions", [])
	check(not items.is_empty(), "law decisions exist " + str(vp))
	var cards: Dictionary = nav.action_panel.decision_view.cards
	var strips_ok := true
	var lifespan_seen := false
	var lifespan_ok := true
	for item in items:
		var card = cards.get(item.id, {})
		if card.is_empty():
			continue
		var expected := 0
		for id in item.get("costs", {}):
			if str(id) == "lifespan_seconds":
				lifespan_seen = true
				lifespan_ok = lifespan_ok and card.lifespan.visible and card.lifespan.text.contains("秒")
			elif float(item.costs[id]) > 0:
				expected += 1
		if expected == 0:
			strips_ok = strips_ok and not card.costs.visible
		else:
			strips_ok = strips_ok and card.costs.visible and card.costs.visible_tiles() == expected
			strips_ok = strips_ok and card.costs.heading.text == "法令所需"
	check(strips_ok, "law costs use one shared icon strip " + str(vp))
	if lifespan_seen:
		check(lifespan_ok, "lifespan stays a labelled second cost, not a resource tile " + str(vp))

func _check_sect(nav, vp: Vector2) -> void:
	# Legacy P1 cost strips remain the non-reform presentation; reform-active
	# saves render specialization cards instead. Pin this section to the legacy
	# path so the shared contribution seal stays covered.
	var saved_sect_version := int(abode.session.state.sect_version)
	abode.session.state.sect_version = 2
	abode.session.state.sect.unlocked = true
	abode.session.state.sect.contribution = "5000"
	SectIdentity.write(abode.session.state.sect, "taixu_sect")
	if not abode.session.state.sect.has("techniques"): abode.session.state.sect["techniques"] = {}
	nav.open("sect")
	abode._layout_for_size(vp)
	await process_frame
	var panel = abode.sect_panel
	panel.update_view(abode.session.state)
	panel._tab_techniques_btn.pressed.emit()
	await process_frame
	var strips: Array = []
	_find_strips(panel._tab_content_container, strips)
	check(not strips.is_empty(), "technique cards carry contribution strips " + str(vp))
	var contrib_ok := not strips.is_empty()
	for strip in strips:
		var tile = strip.tiles.get("contribution")
		contrib_ok = contrib_ok and tile != null and tile.visible and tile.caption.text.contains("宗門")
	check(contrib_ok, "technique cost uses the sect contribution seal " + str(vp))
	panel._tab_market_btn.pressed.emit()
	await process_frame
	strips.clear()
	_find_strips(panel._tab_content_container, strips)
	check(not strips.is_empty(), "market cards carry contribution strips " + str(vp))
	contrib_ok = not strips.is_empty()
	for strip in strips:
		var tile = strip.tiles.get("contribution")
		contrib_ok = contrib_ok and tile != null and tile.visible and tile.caption.text.contains("宗門")
	check(contrib_ok, "market price uses the sect contribution seal " + str(vp))
	panel._tab_expeditions_btn.pressed.emit()
	abode.session.state.sect_version = saved_sect_version

func _check_decision_lifespan() -> void:
	var view := DecisionView.new()
	root.add_child(view)
	view.refresh({
		"realm": {"current_realm": "realm_human"},
		"resources": {"lingli": {"value": "0"}},
		"realm_decisions": [{
			"id": "imm3b", "name": "????", "description": "??", "effects": {},
			"costs": {"lingli": 5, "lifespan_seconds": 30}, "min_era": 1, "era_met": true,
			"cooldown_remaining": 0, "cooldown_seconds": 10, "usage_count": 0,
			"costs_met": false, "is_ready": false
		}]
	})
	var card: Dictionary = view.cards.get("imm3b", {})
	check(not card.is_empty(), "law card renders a lifespan decision")
	if not card.is_empty():
		check(card.costs.visible and card.costs.visible_tiles() == 1, "law lifespan cost is not a resource tile")
		check(card.costs.tiles.lingli.quantity.text == "5", "law resource requirement stays exact")
		check(card.lifespan.visible and card.lifespan.text.contains("30") and card.lifespan.text.contains("秒"), "lifespan is a labelled seconds cost: " + card.lifespan.text)
	view.queue_free()

func _check_reincarnation() -> void:
	var panel = abode.reincarnation_panel
	panel._active_tab = "talents"
	var view: Dictionary = abode.session.get_view()
	panel.refresh(view)
	await process_frame
	check(panel._currency_label.text.contains("道心") and panel._currency_label.text.contains("道證"), "dao heart and proof keep separate labels")
	var strips: Array = []
	_find_strips(panel._talents_list, strips)
	check(not strips.is_empty(), "talent rows carry dao-heart strips")
	var ok := not strips.is_empty()
	for strip in strips:
		if not strip.visible:
			continue
		ok = ok and strip.visible_tiles() == 1
		var tile = strip.tiles.get("dao_heart")
		ok = ok and tile != null and tile.visible and tile.caption.text.contains("傳承")
	check(ok, "talent cost uses the dao-heart seal with 傳承 source")

func _check_fortune() -> void:
	var modal = FortuneModal.new()
	root.add_child(modal)
	var view := {
		"resources": {"lingli": {"value": "2"}},
		"fortune": {
			"has_pending": true,
			"pending_encounter": {
				"id": "imm3b",
				"title": "測試機緣",
				"desc": "描述",
				"options": [
					{"text": "支付靈氣", "costs": {"lingli": 5}, "rewards": {"resources": {"lingli": 10}}},
					{"text": "不支付", "costs": {}, "rewards": {}}
				]
			}
		}
	}
	modal.refresh(view)
	check(modal._option_rows.size() == 2, "fortune keeps both options")
	if modal._option_rows.size() == 2:
		var paid: Dictionary = modal._option_rows[0]
		check(paid.strip.visible and paid.strip.visible_tiles() == 1, "fortune paid option uses one icon cell")
		check(paid.strip.tiles.lingli.quantity.text == "5", "fortune cell shows the exact cost")
		check(paid.strip.note.visible and paid.strip.note.text.contains("缺"), "fortune names the shortfall")
		check(paid.button.text == "支付靈氣", "fortune option button remains wired")
		check(not modal._option_rows[1].strip.visible, "free option shows no fake cost cell")
	modal.queue_free()

func _check_shell_routes(nav) -> void:
	var snapshot = nav.shell.state.snapshot()
	var view: Dictionary = abode.session.get_view()
	for route in ["skills", "beasts", "decisions"]:
		nav.open(route)
		await process_frame
		snapshot = nav.shell.state.snapshot()
		var info: Dictionary = ShellResources.inventory(snapshot, view, nav)
		check(bool(info.get("supported", false)), "focused drawer data exists for " + route)
		check(not info.get("groups", []).is_empty(), "focused drawer groups render for " + route)
		if route == "beasts":
			var food_items := 0
			for group in info.get("groups", []):
				if String(group.get("id", "")) == "beasts:food":
					food_items = group.get("items", []).size()
			check(food_items > 0, "beast drawer lists feed stock from care costs")
	nav.open("reincarnation")
	abode.reincarnation_panel._active_tab = "talents"
	await process_frame
	snapshot = nav.shell.state.snapshot()
	var rc: Dictionary = ShellResources.inventory(snapshot, view, nav)
	check(bool(rc.get("supported", false)) and not rc.get("groups", []).is_empty(), "talent drawer exposes dao-heart groups")

func _find_strips(node: Node, out: Array) -> void:
	if node.has_method("show_costs") and node.has_method("visible_tiles") and not node.is_queued_for_deletion():
		out.append(node)
	for child in node.get_children():
		_find_strips(child, out)
