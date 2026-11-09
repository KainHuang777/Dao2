extends SceneTree
const Flow = preload("res://src/presentation/island_flow_model.gd")
const LevelUpSupply = preload("res://src/presentation/level_up_supply_panel.gd")
const Onboarding = preload("res://src/simulation/onboarding.gd")
var checks := 0
var failures: Array[String] = []
func _init() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func frames() -> void:
	for n in 8: await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(RunnerResult.output_path("res://era2-flow/"+name+".png"))
func _run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=root.size
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = RunnerResult.output_path("res://era2-flow-save")
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	var nav = abode.feature_navigation
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-c-earned-era2.json"))
	check(decoded.ok,"earned Era2 fixture")
	abode.session.state = decoded.state.duplicate_state()
	abode.session.state.training_seconds = float(abode.session.get_view().next_level_required_seconds)
	var now := str(int(Time.get_unix_time_from_system()*1000))
	var fixture := SaveCodec.encode(abode.session.state,abode.content.content_version,{"save_id":"era2-browser","saved_at_utc_ms":now,"settled_until_utc_ms":now,"sim_tick":str(int(abode.session.state.total_elapsed_seconds))})
	check(SaveCodec.decode(fixture.json).ok,"browser fixture valid before serving")
	var file := FileAccess.open(RunnerResult.output_path("res://era2-browser-start.json"),FileAccess.WRITE)
	file.store_string(fixture.json)
	file.close()
	abode._refresh_hud()
	abode.level_up_button.pressed.emit()
	await frames()
	check(nav.level_up_supply.recipe_buttons.bronze_essence.text=="開拓玄礦島","unactivated hub explains the prerequisite at the link")
	nav.level_up_supply.recipe_buttons.bronze_essence.pressed.emit()
	await frames()
	var panel = nav.island_flow
	check(panel.visible and not nav.island_panel.visible,"focused default")
	check(panel.island=="ore" and panel.recipe=="bronze_essence","ore first teaching selection")
	check(nav.supply_return.text=="返回晉階","before first opening advancement remains reachable")
	check(panel.island_rows.herb.action.disabled and panel.island_rows.herb.state.text.contains("金丹"),"future island stays gated")
	var before := JSON.stringify(abode.session.state.to_snapshot_dict())
	panel.refresh(abode.session.get_view(),abode.content.processing_catalog)
	check(before==JSON.stringify(abode.session.state.to_snapshot_dict()),"refresh read only")
	var poor: Dictionary = abode.session.get_view().duplicate(true)
	poor.resources.wood.value=AmountCompat.zero()
	panel.refresh(poor,abode.content.processing_catalog)
	check(panel.island_rows.ore.action.disabled and panel.island_rows.ore.remedy.visible,"unaffordable opening offers contextual remedy")
	check(Flow.opening(poor,"ore").get("id")=="forest_farm","opening remedy identifies exact production building")
	panel.refresh(abode.session.get_view(),abode.content.processing_catalog)
	await capture("hub-unopened-1280x720")
	panel.island_rows.ore.action.pressed.emit()
	await frames()
	check(Flow.opened(abode.session.get_view(),"ore"),"canonical opening committed")
	check(Flow.hub(abode.session.get_view()),"fresh live activation selects hub economy")
	check(Flow.discovered(abode.session.get_view(),"transport"),"single producing island reveals raw transport")
	check(not panel.steps.transport.disabled,"raw transport usable before second island")
	check(abode.session.get_view().transport.copper_home.settings.enabled,"new ore island opens its raw route automatically")
	check(nav.supply_return.text=="繼續原配方","first opening unlocks the original recipe return")
	# Isolated shortage fixture: spendable home copper is deliberately depleted.
	abode.session.state.resources.black_copper.value = AmountCompat.zero()
	var pause: Dictionary = abode.session.get_view().transport.copper_home.settings.duplicate(true)
	pause.merge({"route_id":"copper_home","enabled":false},true)
	nav._on_island_action("configure_route",pause)
	abode._refresh_hud()
	nav.supply_return.pressed.emit()
	await frames()
	check(panel.work_surface.get_parent()==panel.island_rows.home.group,"all manufacturing appears at ancestor hub")
	var stock = nav.shell.context_inventory
	check(stock._items.has("home:black_copper") and stock._items.has("home:stone_low") and stock._items.has("home:bronze_essence"),"recipe context uses ancestor inputs and output")
	check(not stock._items.has("ore:bronze_essence"),"no false local product inventory")
	check(panel.status.text.contains("祖島可用／每批需求") and panel.status.text.contains("玄銅 0／10"),"recipe explains spendable copper and batch cost")
	check(panel._actions[0].get("page")=="transport_settings" and panel._actions[0].get("id")=="copper_home","v2 manual stop links to exact saved policy")
	var manual_view: Dictionary = abode.session.get_view().duplicate(true)
	manual_view.economy.hub_version = IslandEconomy.HUB_VERSION
	panel.refresh(manual_view, abode.content.processing_catalog)
	check(panel._actions[0].get("payload",{}).get("route_id")=="copper_home","v1 keeps the existing quick incoming route")
	panel.refresh(abode.session.get_view(), abode.content.processing_catalog)
	var settings: Dictionary = abode.session.get_view().transport.copper_home.settings.duplicate(true)
	panel.buttons[0].pressed.emit()
	await frames()
	check(nav.transport_panel.visible and nav.transport_panel.selected_route=="copper_home","open exact policy in full management")
	nav.transport_panel.detail_toggle.pressed.emit()
	await frames()
	var updated: Dictionary = abode.session.get_view().transport.copper_home.settings
	check(updated.enabled and updated.target==settings.target and updated.reserve==settings.reserve and updated.level==settings.level,"explicit toggle preserves saved policies")
	nav.supply_return.pressed.emit()
	await frames()
	check(panel.visible and panel.page=="manufacturing" and panel.recipe=="bronze_essence","return restores focused manufacturing and original recipe")
	nav._flow_navigate("transport","copper_home")
	await frames()
	check(panel.route=="copper_home" and panel.resume_recipe=="bronze_essence","raw supply detail preserves interrupted recipe")
	check(stock._items.has("ore:black_copper") and stock._items.has("home:black_copper"),"route context uses exact endpoints")
	abode.session.advance_time(5)
	abode._refresh_hud()
	nav._flow_navigate("manufacturing","bronze_essence")
	await frames()
	check(panel.status.text.contains("在途"),"craft shortage explains pending arrival")
	check(panel._actions.is_empty(),"in transit waits on recipe without sending player to transport")
	abode.session.advance_time(25)
	abode._refresh_hud()
	await frames()
	check(panel._actions[0].get("kind")=="craft","actual raw arrival enables crafting")
	panel.buttons[0].pressed.emit()
	await frames()
	check(abode.session.state.economy.jobs.has("ore"),"existing lane retained for parallel work")
	abode.session.advance_time(15)
	abode._refresh_hud()
	await frames()
	check(float(abode.session.get_view().economy.inventory.home.bronze_essence.available)>0,"finished product directly arrives in ancestor inventory")
	check(float(stock._items["home:bronze_essence"].available)>0,"shared inventory refreshes actual output")
	check(panel.title.text.contains("祖島製造") and not panel.status.text.contains("運回產物"),"central manufacturing has no redundant product shipment")
	panel.mode.select(1)
	panel.mode.item_selected.emit(1)
	panel.buttons[0].pressed.emit()
	await frames()
	check(bool(abode.session.state.economy.jobs.get("ore",{}).get("repeat",false)),"continuous mode uses canonical existing work command")
	await capture("hub-manufacture-1280x720")
	var before_help := JSON.stringify(abode.session.state.to_snapshot_dict())
	check(abode.level_up_button.visible and not abode.level_up_button.disabled,"shortage HUD action can open advancement supply")
	abode.level_up_button.pressed.emit()
	await frames()
	check(nav.level_up_supply.visible and nav.level_up_supply.recipe_buttons.spirit_timber.visible and nav.level_up_supply.recipe_buttons.bronze_essence.visible,"advancement shows both shortages together")
	check(nav.level_up_supply.costs.note.text.contains("靈材") and nav.level_up_supply.costs.note.text.contains("銅精"),"advancement lists both deficits")
	nav.level_up_supply.recipe_buttons.spirit_timber.pressed.emit()
	await frames()
	check(panel.page=="manufacturing" and panel.recipe=="spirit_timber" and panel._actions[0].get("id")=="wood","locked timber opens the exact recipe and points to its producer")
	check(before_help==JSON.stringify(abode.session.state.to_snapshot_dict()),"advancement help and recipe navigation are read only")
	panel.buttons[0].pressed.emit()
	await frames()
	panel.island_rows.wood.action.pressed.emit()
	await frames()
	check(Flow.opened(abode.session.get_view(),"wood"),"second producer opened")
	check(nav.supply_return.text=="繼續原配方","opened producer preserves the originating recipe link")
	nav.supply_return.pressed.emit()
	await frames()
	check(panel.page=="manufacturing" and panel.recipe=="spirit_timber","return from producer selects timber")
	check(abode.session.get_view().transport.wood_home.settings.enabled,"wood route is already enabled")
	nav.supply_return.pressed.emit()
	await frames()
	check(nav.level_up_supply.visible and nav.level_up_supply.heading.text.contains("1 層 → 2 層"),"returns to original advancement target")
	nav.shell.overlay_close.pressed.emit()
	abode.session.advance_time(20)
	abode._refresh_hud()
	nav._flow_navigate("manufacturing","spirit_timber")
	await frames()
	check(panel._actions[0].get("kind")=="craft","ancestor stock enables second production lane")
	panel.mode.select(0)
	panel.mode.item_selected.emit(0)
	panel.buttons[0].pressed.emit()
	abode.session.advance_time(15)
	abode._refresh_hud()
	await frames()
	check(float(abode.session.get_view().economy.inventory.home.spirit_timber.available)>0,"timber finishes at hub without outbound product route")
	check(abode.session.get_view().transport.copper_home.settings.enabled,"other raw delivery policy survives second chain")
	var saved := SaveCodec.encode(abode.session.state,abode.content.content_version,{"save_id":"flow","saved_at_utc_ms":"0","settled_until_utc_ms":"0","sim_tick":"0"})
	var reloaded := SaveCodec.decode(saved.json)
	check(saved.ok and reloaded.ok and IslandEconomy.hub(reloaded.state),"hub progress reloads")
	abode.session.state=reloaded.state
	nav.open("transport")
	await frames()
	panel.full_requested.emit()
	await frames()
	check(nav.transport_panel.visible and not panel.visible,"advanced settings remain reachable")
	check(nav.transport_panel.route_widgets.has("copper_home") and nav.transport_panel.route_widgets.has("raw_stone_home"),"advanced routes include new raw supply")
	nav.flow_return.pressed.emit()
	await frames()
	check(panel.visible,"return to focused mode")

	# ERA2-PACING-A1: liquid button, ancestor routing, and herb farm prerequisite
	var mock_view: Dictionary = abode.session.get_view().duplicate(true)
	mock_view.era_id = 2
	mock_view.level = 5
	mock_view.level_up_missing_resources = {"liquid": 5.0}
	check(LevelUpSupply.offers_help(mock_view), "LevelUpSupply offers help for missing liquid in Era 2")
	nav.level_up_supply.refresh(mock_view, abode.RESOURCE_NAMES)
	check(nav.level_up_supply.recipe_buttons.has("liquid"), "LevelUpSupply has liquid button")
	check(nav.level_up_supply.recipe_buttons.liquid.visible, "liquid button visible when missing liquid")
	check(nav.level_up_supply.recipe_buttons.liquid.text == "煉製丹液", "liquid button shows 煉製丹液 in Era 2")

	abode.session.state.buildings.herb_farm = 1
	nav.level_up_supply.recipe_buttons.liquid.pressed.emit()
	await frames()
	check(nav.page == "buildings", "missing herb_farm 3 redirects to buildings page")

	abode.session.state.buildings.herb_farm = 3
	nav.level_up_supply.recipe_buttons.liquid.pressed.emit()
	await frames()
	check(nav.page == "manufacturing", "herb_farm 3 navigates to manufacturing")

	var mock_era := {"max_level": 10, "upgrade_requirements": {"capacity": {"lingli": 2000}}}
	abode.session.state.era_id = 2

	# E1 guidance (Levels 1-3)
	abode.session.state.level = 2
	var g_e1 := Onboarding.golden_guidance(abode.session.state, mock_era, abode.session.get_view().resources, false, false, 60.0)
	check(g_e1.step == "F7" and g_e1.substep == "E1", "E1 step is F7 with substep E1")
	check(g_e1.title.contains("穩固產線"), "E1 title guides steady supply line")
	check(g_e1.text.contains("飛舟渡口") and g_e1.text.contains("聚靈陣盤"), "E1 text recommends pacing buildings")

	# E2 guidance (Level 4, liquid gate)
	abode.session.state.level = 4
	abode.session.state.buildings.herb_farm = 1
	var g_e2_pre := Onboarding.golden_guidance(abode.session.state, mock_era, abode.session.get_view().resources, false, false, 60.0)
	check(g_e2_pre.substep == "E2" and g_e2_pre.route == "herb_farm", "E2 routes to herb_farm when under tier 3")
	abode.session.state.buildings.herb_farm = 3
	var g_e2 := Onboarding.golden_guidance(abode.session.state, mock_era, abode.session.get_view().resources, false, false, 60.0)
	check(g_e2.substep == "E2" and g_e2.route == "manufacturing" and g_e2.recipe_id == "liquid", "E2 routes to home liquid manufacturing")
	check(g_e2.text.contains("五層晉階需丹液"), "onboarding golden guidance provides level 4 liquid tip")

	# E3 guidance (Levels 5-9)
	abode.session.state.level = 6
	var g_e3 := Onboarding.golden_guidance(abode.session.state, mock_era, abode.session.get_view().resources, false, false, 60.0)
	check(g_e3.substep == "E3" and g_e3.title.contains("擴充洞府"), "E3 guides abode expansion")

	# E4 guidance (Level 10)
	abode.session.state.level = 10
	var g_e4 := Onboarding.golden_guidance(abode.session.state, mock_era, abode.session.get_view().resources, false, true, 0.0)
	check(g_e4.substep == "E4" and g_e4.title.contains("突破至金丹"), "E4 guides golden core breakthrough when ready")

	# ERA2-PACING-B2: new buildings, prerequisites, and effect bonuses
	check(abode.content.buildings.has("alchemy_chamber"), "alchemy_chamber in building catalog")
	check(abode.content.buildings.has("spirit_array_plate"), "spirit_array_plate in building catalog")
	check(abode.content.buildings.has("dock_post"), "dock_post in building catalog")

	# The catalog tolerates missing portrait files, so verify the displayed textures.
	nav.open_buildings()
	await frames()
	var catalog = abode.building_catalog
	for id in ["alchemy_chamber", "spirit_array_plate", "dock_post"]:
		var card: Button = catalog.rows.get(id)
		var portrait: UiIllustration = card.get_child(0) as UiIllustration if card else null
		check(
			card != null and card.is_visible_in_tree() and portrait != null
			and portrait.is_visible_in_tree() and portrait.texture != null
			and portrait.texture.resource_path == "res://assets/ui/buildings-painted/%s.png" % id
			and portrait.texture.get_size() == Vector2(192, 192),
			"%s displays its 192px portrait in the Era 2 catalog" % id
		)

	var cmd_state: GameState = abode.session.state.duplicate_state()
	cmd_state.buildings.foundation_reservoir = 0
	var fail_cmd: Dictionary = CommandProcessor.apply(abode.content, cmd_state, {"type": "upgrade_building", "payload": {"building_id": "alchemy_chamber"}})
	check(not fail_cmd.ok and fail_cmd.error == "PREREQ_UNSATISFIED", "alchemy_chamber blocked without foundation_reservoir")

	var dur_base: int = IslandProgression.duration(cmd_state, "home", "liquid")
	cmd_state.buildings.alchemy_chamber = 1
	var dur_reduced: int = IslandProgression.duration(cmd_state, "home", "liquid")
	check(dur_reduced < dur_base, "alchemy_chamber reduces liquid crafting duration")

	var train_state: GameState = abode.session.state.duplicate_state()
	train_state.buildings.spirit_array_plate = 1
	train_state.training_seconds = 0.0
	TimeAdvancer.advance(train_state, abode.content, 10)
	check(train_state.training_seconds > 10.0, "spirit_array_plate boosts cultivation speed above 1.0x")

	check(IslandEconomy.transit_duration(abode.session.state) == 10, "default transit is 10s")
	var dock_state: GameState = abode.session.state.duplicate_state()
	dock_state.buildings.dock_post = 1
	check(IslandEconomy.transit_duration(dock_state) == 8, "dock_post reduces transit to 8s")

	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	for vp in ([Vector2i(1280,720),Vector2i(844,390),Vector2i(800,360)] if OS.get_environment("DAO_VIEWPORT_MATRIX")=="full" else [Vector2i(1280,720)]):
		root.size=vp
		root.content_scale_size=vp
		for route in ["outposts","manufacturing","transport"]:
			nav.open(route)
			abode._layout_for_size(Vector2(vp))
			await frames()
			check(nav.shell.workbench.pages.get_global_rect().encloses(panel.get_global_rect()),"panel within allocated workspace "+route+str(vp))
			check(panel.column.get_combined_minimum_size().y<=panel.size.y,"single internal list scroll "+route+str(vp))
			if panel.work_surface.visible:
				for button in panel.buttons:
					if button.is_visible_in_tree(): check(panel.work_surface.get_global_rect().encloses(button.get_global_rect()),"actions stay grouped "+route+str(vp))
			for id in panel.island_rows:
				check(panel.island_rows[id].row.size.x<=panel.island_scroll.size.x,"no list horizontal overflow "+id+str(vp))
			await capture("hub-%s-%dx%d"%[route,vp.x,vp.y])
	panel.show_result("操作未保存：test")
	check(panel.retry.visible,"save failure offers save-only retry")
	panel.storage_recovered()
	check(not panel.retry.visible,"save recovery clears retry")
	abode.queue_free()
	await process_frame
	print("ERA2-FLOW checks=%d failures=%s"%[checks,JSON.stringify(failures)])
	RunnerResult.finish(self,0 if failures.is_empty() else 1)
