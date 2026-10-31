extends SceneTree
## IMM-3C: page-by-page resource language, shared controls and overlay consistency.
const ShellPolicy = preload("res://src/presentation/ui_shell_policy.gd")
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
	script.save_dir_override = RunnerResult.output_path("res://docs/verification/artifacts/imm3c/imm3c_page_consistency_runner")
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
	for id in ["wood", "ore", "herb"]:
		state.economy.islands[id].opened = true
		for resource in abode.content.processing_catalog.resources:
			if not resource in IslandEconomy.GLOBAL:
				state.economy.islands[id].inventory[resource] = "50"
	state.economy.islands.wood.facilities.workshop = 1
	state.sect.unlocked = true
	state.sect.contribution = "5000"
	state.sect["techniques"] = {}
	state.reincarnation_count = 1
	state.fortune.pending_encounter = {
		"id": "imm3c_page", "title": "頁面一致性抽驗", "desc": "抽驗機緣成本圖示。",
		"options": [
			{"text": "支付靈氣", "costs": {"lingli": 5}, "rewards": {"resources": {"lingqi": 10}}},
			{"text": "不支付", "costs": {}, "rewards": {}}
		]
	}
	abode.session.state = state
	SaveManager.configure(abode.content, MemoryAdapter.new())
	abode._refresh_hud()
	abode.feature_navigation.shell.home_preferences(1, false)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var nav = abode.feature_navigation
	var sizes: Array = [Vector2(1280, 720), Vector2(844, 390), Vector2(800, 360)] if OS.get_environment("DAO_VIEWPORT_MATRIX") == "full" else [Vector2(1280, 720)]
	for vp in sizes:
		root.size = Vector2i(vp)
		root.content_scale_size = Vector2i(vp)
		abode._layout_for_size(vp)
		await frames()
		await _check_pages(nav, vp)
		await _check_manufacturing(nav, vp)
		await _check_transport(nav, vp)
		await _check_buildings(nav, vp)
		await _check_outposts(nav, vp)
		await _check_alchemy(nav, vp)
		await _check_skills(nav, vp)
		await _check_beasts(nav, vp)
		await _check_decisions(nav, vp)
		await _check_achievements(nav, vp)
		await _check_reincarnation(nav, vp)
		await _check_sect(nav, vp)
		await _check_fortune(nav, vp)
		await _check_overlays(nav, vp)
		_check_policy_guards(vp)
	if failures.is_empty():
		print("PASS: IMM-3C ", checks, " checks; 14 pages plus shared overlays keep one resource language")
		RunnerResult.finish(self, 0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		RunnerResult.finish(self, 1)

func _check_pages(nav, vp: Vector2) -> void:
	var pages := [
		["home", "home"], ["buildings", "inventory"], ["outposts", "inventory"],
		["manufacturing", "inventory"], ["transport", "inventory"], ["skills", "focused"],
		["alchemy", "inventory"], ["beasts", "focused"], ["achievements", "none"],
		["reincarnation", "none"], ["realms", "none"], ["sect", "focused"],
		["fortune", "focused"], ["decisions", "focused"]
	]
	for entry in pages:
		await _check_page(nav, String(entry[0]), String(entry[1]), vp)

func _check_page(nav, route: String, kind: String, vp: Vector2) -> void:
	if route == "home":
		nav.home()
	else:
		nav.open(route)
	abode._layout_for_size(vp)
	await frames()
	var shell = nav.shell
	var snapshot: Dictionary = shell.state.snapshot()
	if route == "home":
		check(nav.group == "home" and snapshot.route == "home", "canonical home page " + str(vp))
		check(not nav.bar.visible, "home keeps the original header instead of workspace tabs " + str(vp))
	else:
		check(nav.page == route and snapshot.route == route, "canonical " + route + " " + str(vp))
		check(nav.bar.visible, "shared tabs visible " + route + " " + str(vp))
		check(nav.back_button.custom_minimum_size.y >= 44 and nav.back_button.size.y >= 44, "shared back target " + route + " " + str(vp))
		var tabs_ok: bool = not nav.tab_buttons.is_empty()
		for id in nav.tab_buttons:
			var button: Button = nav.tab_buttons[id]
			if button.visible:
				tabs_ok = tabs_ok and button.custom_minimum_size.y >= 44 and button.size.y >= 44
		check(tabs_ok, "shared tab targets " + route + " " + str(vp))
	check(String(shell.effective.get("resource_context", "")) == kind, "resource context " + route + " " + str(vp))
	var wide: bool = vp.x >= 960.0 and vp.y >= 500.0
	if kind == "home":
		check(shell.resource_button.visible, "home resource entry " + str(vp))
		if wide:
			check(abode.resource_ribbon.visible, "home resource rail " + str(vp))
		else:
			check(not abode.resource_ribbon.visible and not shell.context_paper.visible, "compact home folds stock into summary " + str(vp))
	elif kind == "inventory":
		check(shell.resource_button.visible, "inventory entry " + route + " " + str(vp))
		if not wide:
			check(not shell.context_paper.visible and not abode.resource_ribbon.visible, "compact inventory folds stock into summary " + route + " " + str(vp))
		elif route in ["buildings", "alchemy"]:
			check(abode.resource_ribbon.visible and not shell.context_paper.visible, "home-style ribbon " + route + " " + str(vp))
		else:
			check(shell.context_paper.visible and shell.context_inventory.visible, "inventory icons " + route + " " + str(vp))
			check(not shell.context_scroll.visible, "no legacy resource text " + route + " " + str(vp))
	elif kind == "focused":
		check(shell.resource_button.visible, "focused summary entry " + route + " " + str(vp))
		check(not shell.context_paper.visible, "focused summary stays unobtrusive " + route + " " + str(vp))
		await _open_drawer(nav, vp)
		if route == "sect":
			check(shell.context_scroll.visible and not shell.context_inventory.visible, "expedition drawer keeps one labelled fallback " + str(vp))
		else:
			check(shell.context_inventory.visible and not shell.context_scroll.visible, "focused drawer uses inventory icons " + route + " " + str(vp))
		await _close_drawer(nav, vp)
	else:
		check(not shell.resource_button.visible and not shell.context_paper.visible and not abode.resource_ribbon.visible, "no resource entry " + route + " " + str(vp))
	if route == "realms":
		check(abode.nine_realms_preview.visible, "realms keeps its own overview " + str(vp))

func _open_drawer(nav, vp: Vector2) -> void:
	nav.shell.toggle_overlay("resources")
	abode._layout_for_size(vp)
	await frames()

func _close_drawer(nav, vp: Vector2) -> void:
	nav.shell.close_overlay()
	abode._layout_for_size(vp)
	await frames()

func _check_manufacturing(nav, vp: Vector2) -> void:
	nav.open_manufacturing("wood", "spirit_timber")
	abode._layout_for_size(vp)
	await frames()
	var panel = nav.manufacturing_panel
	var view: Dictionary = abode.session.get_view()
	var info: Dictionary = view.manufacturing.recipes.spirit_timber
	check(panel.detail_costs.visible and panel.detail_costs.visible_tiles() == info.inputs.size(), "manufacturing one cell per input " + str(vp))
	check(_tiles_are_seals(panel.detail_costs.tiles), "manufacturing cells use the shared seal " + str(vp))
	check(not panel.detail_stock.text.contains("："), "manufacturing stock drops per-input text rows " + str(vp))
	check(panel.detail_stock.text.contains("產物可用") and panel.detail_stock.text.contains("加工待完成"), "manufacturing keeps product and reservation facts " + str(vp))
	var level := int(abode.session.state.economy.islands.wood.facilities.workshop)
	var workshop: Dictionary = IslandProgression.upgrade_cost("workshop", level)
	check(panel.workshop_costs.visible and panel.workshop_costs.visible_tiles() == workshop.size(), "workshop upgrade costs keep their icon strip " + str(vp))
	check(_tiles_are_seals(panel.workshop_costs.tiles), "workshop upgrade cells use the shared seal " + str(vp))
	check(panel.workshop_button.text.contains("加工坊") and not panel.workshop_button.text.contains("祖島支付"), "workshop button keeps the verb without the price list " + str(vp))

func _check_transport(nav, vp: Vector2) -> void:
	nav.open_transport("timber_home")
	abode._layout_for_size(vp)
	await frames()
	var panel = nav.transport_panel
	var info: Dictionary = panel._info("timber_home")
	check(panel.detail_stock.text.contains("來源餘貨") and panel.detail_stock.text.contains("目的容量預留") and panel.detail_stock.text.contains("已保存目標"), "transport keeps labelled endpoint facts " + str(vp))
	check(panel.detail_stock.text.contains("運力"), "transport capacity remains an explicit setting " + str(vp))
	check(panel.upgrade_costs.visible and panel.upgrade_costs.visible_tiles() == info.upgrade_cost.size(), "transport upgrade costs keep their icon strip " + str(vp))
	check(_tiles_are_seals(panel.upgrade_costs.tiles), "transport upgrade cells use the shared seal " + str(vp))
	check(panel.upgrade_button.text.contains("運力") and not panel.upgrade_button.text.contains("祖島支付"), "transport button keeps capacity wording without the price list " + str(vp))

func _check_buildings(nav, vp: Vector2) -> void:
	nav.open("buildings")
	abode._layout_for_size(vp)
	await frames()
	var view: Dictionary = abode.session.get_view()
	var target := ""
	for id in view.buildings:
		var data: Dictionary = view.buildings[id]
		if bool(data.get("visible", false)) and not data.get("costs", {}).is_empty() and int(data.level) < int(data.level_cap):
			target = id
			break
	check(not target.is_empty(), "an upgradeable building exists " + str(vp))
	if target.is_empty():
		return
	abode._select_building_from_catalog(target)
	abode._layout_for_size(vp)
	await frames()
	check(abode.detail_costs.visible and abode.detail_costs.visible_tiles() == view.buildings[target].costs.size(), "building detail costs use the shared strip " + str(vp))
	check(_tiles_are_seals(abode.detail_costs.tiles), "building detail cells use the shared seal " + str(vp))

func _check_outposts(nav, vp: Vector2) -> void:
	nav.open("outposts")
	abode._layout_for_size(vp)
	await frames()
	var panel = nav.island_panel
	panel.select_island("wood")
	abode._layout_for_size(vp)
	await frames()
	check(not panel.facility_cards.is_empty(), "facility cards exist " + str(vp))
	if panel.facility_cards.has("extractor"):
		check(_tiles_are_seals(panel.facility_cards.extractor.tiles), "facility costs use the shared seal " + str(vp))
	if not panel.payment_tiles.is_empty():
		check(_tiles_are_seals(panel.payment_tiles), "home payment cells use the shared seal " + str(vp))
	for id in panel.opening_tiles:
		check(panel.opening_tiles[id].show_source_caption == false, "island cells keep compact captions " + str(vp))

func _check_alchemy(nav, vp: Vector2) -> void:
	nav.open("alchemy")
	abode._layout_for_size(vp)
	await frames()
	var panel = abode.alchemy_panel
	check(not panel._pill_rows.is_empty(), "alchemy rows exist " + str(vp))
	if panel._pill_rows.is_empty():
		return
	var pill_id: String = panel._pill_rows.keys()[0]
	check(_tiles_are_seals(panel._widgets[pill_id].tiles), "alchemy materials use the shared seal " + str(vp))

func _check_skills(nav, vp: Vector2) -> void:
	nav.open("skills")
	abode._layout_for_size(vp)
	await frames()
	var strips: Array = []
	_find_strips(nav.action_panel.skill_view, strips)
	check(not strips.is_empty() and _strips_are_seals(strips), "skill cost stays one seal cell " + str(vp))

func _check_beasts(nav, vp: Vector2) -> void:
	nav.open("beasts")
	abode._layout_for_size(vp)
	await frames()
	var cards: Dictionary = nav.action_panel.beast_view.cards
	check(not cards.is_empty(), "beast cards exist " + str(vp))
	var food := 0
	var food_ok := true
	var soul_ok := true
	for id in cards:
		var card: Dictionary = cards[id]
		if card.cost.visible_tiles() > 0:
			food += 1
			food_ok = food_ok and _tiles_are_seals(card.cost.tiles)
		soul_ok = soul_ok and card.soul.text.contains("同種獸魂") and card.soul.text.contains("不用於餵養")
	check(food > 0 and food_ok, "beast feed costs use seal cells " + str(vp))
	check(soul_ok, "souls remain a separate labelled line " + str(vp))

func _check_decisions(nav, vp: Vector2) -> void:
	nav.open("decisions")
	abode._layout_for_size(vp)
	await frames()
	var cards: Dictionary = nav.action_panel.decision_view.cards
	var found := 0
	var seals_ok := true
	for id in cards:
		var card: Dictionary = cards[id]
		if card.costs.visible:
			found += 1
			seals_ok = seals_ok and _tiles_are_seals(card.costs.tiles)
	check(found > 0 and seals_ok, "law costs keep the shared seal " + str(vp))

func _check_achievements(nav, vp: Vector2) -> void:
	nav.open("achievements")
	abode._layout_for_size(vp)
	await frames()
	var strips: Array = []
	_find_strips(abode.achievement_panel, strips)
	check(strips.is_empty(), "achievements keep badges and reward text without a resource strip " + str(vp))

func _check_reincarnation(nav, vp: Vector2) -> void:
	nav.open("reincarnation")
	abode._layout_for_size(vp)
	await frames()
	var panel = abode.reincarnation_panel
	panel._switch_tab("talents")
	abode._layout_for_size(vp)
	await frames()
	var shell = nav.shell
	check(String(shell.effective.get("resource_context", "")) == "focused", "talent subpage requests focused resources " + str(vp))
	check(panel._currency_label.text.contains("道心") and panel._currency_label.text.contains("道證"), "dao heart and proof keep separate labels " + str(vp))
	var strips: Array = []
	_find_strips(panel._talents_list, strips)
	check(not strips.is_empty() and _strips_are_seals(strips), "talent costs use dao-heart seal cells " + str(vp))
	var heart_ok := not strips.is_empty()
	for strip in strips:
		if not strip.visible:
			continue
		var tile = strip.tiles.get("dao_heart")
		heart_ok = heart_ok and tile != null and tile.visible and tile.icon.visible and not tile.caption.visible and tile.tooltip_text.contains("傳承")
	check(heart_ok, "talent cells name the 傳承 source " + str(vp))
	await _open_drawer(nav, vp)
	check(shell.context_inventory.visible and not shell.context_scroll.visible, "talent drawer uses inventory icons " + str(vp))
	await _close_drawer(nav, vp)
	panel._switch_tab("reincarnate")
	abode._layout_for_size(vp)
	await frames()
	check(String(shell.effective.get("resource_context", "")) == "none", "reincarnate tab keeps narrative-only layout " + str(vp))

func _check_sect(nav, vp: Vector2) -> void:
	# Legacy P1 cost strips remain the non-reform presentation; pin this page so
	# the shared contribution seal stays covered.
	var saved_sect_version := int(abode.session.state.sect_version)
	abode.session.state.sect_version = 2
	abode.session.state.sect.unlocked = true
	# A freshly unlocked sect without an affiliation renders the identity
	# prompt instead of the technique/market cards; pin the legacy taixu id.
	SectIdentity.write(abode.session.state.sect, "taixu_sect")
	abode.session.state.sect.contribution = "5000"
	if not abode.session.state.sect.has("techniques"): abode.session.state.sect["techniques"] = {}
	nav.open("sect")
	abode._layout_for_size(vp)
	await frames()
	var panel = abode.sect_panel
	panel.update_view(abode.session.state)
	panel._tab_techniques_btn.pressed.emit()
	abode._layout_for_size(vp)
	await frames()
	check(String(nav.shell.effective.get("resource_context", "")) == "inventory", "technique subpage requests inventory resources " + str(vp))
	if vp.x >= 960.0 and vp.y >= 500.0:
		check(nav.shell.context_paper.visible and nav.shell.context_inventory.visible, "technique drawer uses inventory icons " + str(vp))
	else:
		check(nav.shell.resource_button.visible and not nav.shell.context_paper.visible, "compact technique summary " + str(vp))
		await _open_drawer(nav, vp)
		check(nav.shell.context_paper.visible and nav.shell.context_inventory.visible, "technique drawer uses inventory icons " + str(vp))
		await _close_drawer(nav, vp)
	var strips: Array = []
	_find_strips(panel._tab_content_container, strips)
	check(not strips.is_empty() and _strips_are_seals(strips), "technique costs keep contribution seal cells " + str(vp))
	var contrib_ok := not strips.is_empty()
	for strip in strips:
		var tile = strip.tiles.get("contribution")
		contrib_ok = contrib_ok and tile != null and tile.visible and tile.icon.visible and not tile.caption.visible and tile.tooltip_text.contains("宗門")
	check(contrib_ok, "technique cells name the 宗門 source " + str(vp))
	panel._tab_market_btn.pressed.emit()
	abode._layout_for_size(vp)
	await frames()
	check(String(nav.shell.effective.get("resource_context", "")) == "inventory", "market subpage requests inventory resources " + str(vp))
	strips.clear()
	_find_strips(panel._tab_content_container, strips)
	check(not strips.is_empty() and _strips_are_seals(strips), "market costs keep contribution seal cells " + str(vp))
	panel._tab_expeditions_btn.pressed.emit()
	abode._layout_for_size(vp)
	await frames()
	abode.session.state.sect_version = saved_sect_version

func _check_fortune(nav, vp: Vector2) -> void:
	nav.open("fortune")
	abode._layout_for_size(vp)
	await frames()
	var modal = abode.fortune_modal
	check(modal.visible and not modal._option_rows.is_empty(), "fortune options render " + str(vp))
	if modal._option_rows.is_empty():
		return
	var paid: Dictionary = modal._option_rows[0]
	check(paid.strip.visible and _tiles_are_seals(paid.strip.tiles), "paid fortune option uses one seal cell " + str(vp))
	check(not modal._option_rows[1].strip.visible, "free fortune option shows no fake cost " + str(vp))
	await _open_drawer(nav, vp)
	check(nav.shell.context_inventory.visible and not nav.shell.context_scroll.visible, "fortune drawer uses inventory icons " + str(vp))
	await _close_drawer(nav, vp)

func _check_overlays(nav, vp: Vector2) -> void:
	nav.open("manufacturing")
	abode._layout_for_size(vp)
	await frames()
	var shell = nav.shell
	shell.toggle_overlay("messages")
	abode._layout_for_size(vp)
	await frames()
	check(shell.shield.visible and abode.hint_panel.visible, "messages overlay uses the shared shield " + str(vp))
	check(shell.overlay_close.size.x >= 44 and shell.overlay_close.size.y >= 44, "messages overlay keeps the shared close target " + str(vp))
	nav.back()
	abode._layout_for_size(vp)
	await frames()
	check(nav.page == "manufacturing" and not shell.shield.visible, "messages overlay returns to the page " + str(vp))
	shell.toggle_overlay("resources")
	abode._layout_for_size(vp)
	await frames()
	check(shell.shield.visible and shell.context_paper.visible and shell.context_inventory.visible, "resources overlay keeps inventory icons " + str(vp))
	shell.close_overlay()
	abode._layout_for_size(vp)
	await frames()
	abode._toggle_save_controls()
	abode._layout_for_size(vp)
	await frames()
	check(shell.state.snapshot().overlay == "tool" and shell.shield.visible and abode.save_controls.visible, "save tool reuses the shared overlay " + str(vp))
	nav.back()
	abode._layout_for_size(vp)
	await frames()
	check(nav.page == "manufacturing" and not shell.shield.visible, "save tool returns to the page " + str(vp))
	shell.set_save_result({"ok": false, "error": "IMM3C_TEST"})
	check(shell.alert.visible, "save failure shows the fixed retry row " + str(vp))
	var retry := _find_button(shell.alert, "重試保存")
	check(retry != null and retry.custom_minimum_size.y >= 44 and retry.size.y >= 44, "save retry keeps a 44px target " + str(vp))
	shell.set_save_result({"ok": true})
	abode._layout_for_size(vp)
	await frames()
	check(not shell.alert.visible, "save retry clears the alert " + str(vp))
	var report_strips: Array = []
	_find_strips(abode.offline_summary, report_strips)
	check(report_strips.is_empty(), "offline report keeps narrative text, not resource tiles " + str(vp))

func _check_policy_guards(vp: Vector2) -> void:
	check(String(ShellPolicy.resolve({"route": "fortune"}, vp, {"has_costs": false}).resource_context) == "none", "fortune without costs exposes no resource entry")
	check(not bool(ShellPolicy.resolve({"route": "fortune"}, vp, {"has_costs": false}).resource_entry), "fortune without costs hides the entry")
	check(String(ShellPolicy.resolve({"route": "fortune"}, vp, {"has_costs": true}).resource_context) == "focused", "paid fortune requests focused costs")
	check(String(ShellPolicy.resolve({"route": "reincarnation", "subpage": "reincarnate"}, vp, {}).resource_context) == "none", "reincarnate tab stays outside resource inventory")
	check(String(ShellPolicy.resolve({"route": "reincarnation", "subpage": "talents"}, vp, {}).resource_context) == "focused", "talents tab requests focused costs")
	check(String(ShellPolicy.resolve({"route": "sect", "subpage": "expeditions"}, vp, {}).resource_context) == "focused", "expeditions keep a focused drawer")
	check(String(ShellPolicy.resolve({"route": "sect", "subpage": "techniques"}, vp, {}).resource_context) == "inventory", "techniques request inventory")
	check(String(ShellPolicy.resolve({"route": "sect", "subpage": "market"}, vp, {}).resource_context) == "inventory", "market requests inventory")

func _tiles_are_seals(tiles: Dictionary) -> bool:
	var count := 0
	var ok := true
	for id in tiles:
		var tile = tiles[id]
		if tile == null or not tile.visible:
			continue
		count += 1
		var cell_size := Vector2(36, 36) if bool(tile.compact) else Vector2(56, 56)
		ok = ok and tile.get_child(0).get_child(0).custom_minimum_size == cell_size
		ok = ok and not tile.quantity.text.is_empty()
		var label: Label = tile.quantity
		var glyph_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		ok = ok and label.get_theme_font_size("font_size") >= 16
		ok = ok and glyph_width + 2 * label.get_theme_constant("outline_size") <= cell_size.x - 4 + 0.1
		ok = ok and is_equal_approx(tile.size.x, tile.size.y) and not tile.caption.visible
	return ok and count > 0

func _strips_are_seals(strips: Array) -> bool:
	var ok := true
	for strip in strips:
		if not strip.visible:
			continue
		ok = ok and _tiles_are_seals(strip.tiles)
	return ok

func _find_strips(node: Node, out: Array) -> void:
	if node.has_method("show_costs") and node.has_method("visible_tiles") and not node.is_queued_for_deletion():
		out.append(node)
	for child in node.get_children():
		_find_strips(child, out)

func _find_button(node: Node, label: String) -> Button:
	if node is Button and String(node.text) == label:
		return node
	for child in node.get_children():
		var found := _find_button(child, label)
		if found != null:
			return found
	return null
