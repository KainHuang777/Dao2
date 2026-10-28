extends SceneTree
## IMM-0 isolated presentation study. Synthetic cloned data, no normal saves.
var OUT := "res://.test-output/imm0"
var selected_samples: Array[String] = ["home-normal", "manufacturing-normal", "manufacturing-shortage", "fortune-pending", "fortune-ready", "fortune-save-error"]
var abode: Node
var records: Array = []
var failed := false

func _init() -> void: run.call_deferred()
func frames() -> void:
	for i in 10: await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	load("res://src/abode/living_abode.gd").save_dir_override = OUT + "/storage"
	abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	while abode.session == null or abode.feature_navigation == null: await process_frame
	await frames()
	abode.set_process(false)
	abode.camera.set_process(false)
	abode.offline_summary.hide()
	abode.v2_rules_notice.hide()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for vp in [Vector2i(1280,720), Vector2i(844,390)]:
		root.size = vp; root.content_scale_size = vp
		for sample in selected_samples:
			await prepare(sample, vp)
			await capture(sample, "current", vp)
			if sample == "fortune-pending" and vp.y < 500:
				await capture_option_tail("current",vp)
			if OS.get_environment("IMM0_BASELINE_ONLY") != "1":
				apply_candidate(sample, vp)
				await capture(sample, "candidate", vp)
				if sample == "fortune-pending" and vp.y < 500:
					await capture_option_tail("candidate",vp)
	var f := FileAccess.open(OUT + "/captures.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"IMM-0 native static samples; synthetic cloned fixture; no mouse/save-fault/performance acceptance", "captures":records}, "\t"))
	abode.queue_free(); await frames()
	load("res://src/abode/living_abode.gd").save_dir_override = ""
	quit(1 if failed else 0)

func prepare(sample: String, vp: Vector2i) -> void:
	# Recreate the scene for every pair: candidate tree edits never contaminate current.
	if records.size() > 0:
		abode.queue_free(); await frames()
		abode = load("res://scenes/living_abode.tscn").instantiate(); root.add_child(abode)
		while abode.session == null or abode.feature_navigation == null: await process_frame
		await frames()
		abode.set_process(false); abode.camera.set_process(false)
		abode.offline_summary.hide(); abode.v2_rules_notice.hide()
	var decoded := SaveCodec.decode(FileAccess.get_file_as_string("res://docs/verification/artifacts/res1-d2-earned-era3.json"))
	if not decoded.ok: failed = true; quit(1); return
	abode.session.state = decoded.state.duplicate_state()
	for id in abode.session.state.resources: abode.session.state.resources[id].value = AmountCompat.from_number(200)
	for id in abode.session.state.economy.islands: abode.session.state.economy.islands[id].opened = true
	for island in abode.session.state.economy.islands:
		for id in abode.session.state.economy.islands[island].inventory: abode.session.state.economy.islands[island].inventory[id] = "40"
	abode.session.state.economy.jobs = {}; abode.session.state.economy.trips = {}
	FortuneSystem.ensure_initialized(abode.session.state)
	if sample == "manufacturing-shortage":
		abode.session.state.resources.wood.value = AmountCompat.zero()
		abode.session.state.economy.islands.wood.inventory.wood = "0"
		abode.session.state.economy.islands.ore.inventory.black_copper = "0"
	if sample == "manufacturing-normal":
		abode.session.state.economy.jobs.ore = {"recipe_id":"bronze_essence","recipe_version":1,"remaining":7,"repeat":true,"batches":0,"reserves":{},"status":"running"}
	if sample.begins_with("fortune"):
		if sample == "fortune-pending":
			var def: Dictionary = FortuneSystem.get_encounters().filter(func(d): return d.id == "herb_garden")[0] if FortuneSystem.get_encounters().any(func(d): return d.id == "herb_garden") else FortuneSystem.get_encounters()[0]
			var pending := def.duplicate(true)
			pending.instance_id = "imm0-static"
			abode.session.state.fortune.pending_encounter = pending
		else:
			abode.session.state.fortune.pending_encounter = {}
			abode.session.state.fortune.cooldown_remaining = 0
	abode.session.state.revision += 1
	abode._refresh_hud()
	var nav = abode.feature_navigation
	if sample.begins_with("home"): nav.home()
	elif sample.begins_with("manufacturing"): nav.open("manufacturing")
	else: nav.open("fortune")
	abode._layout_for_size(Vector2(vp))
	if sample == "fortune-save-error":
		abode.fortune_modal.set_save_result({"ok":false,"error":"IMM0_WRITE_DENIED"})
		nav.shell.set_save_result({"ok":false,"error":"IMM0_WRITE_DENIED"})
	await frames()
	abode.camera.focus_home()
	abode.camera.position = abode.camera.home_position
	abode.camera.zoom = Vector2.ONE * abode.camera.home_zoom
	abode.island_world.refresh()
	await frames()
	var view_file := FileAccess.open(OUT + "/" + sample + "-view.json", FileAccess.WRITE)
	view_file.store_string(JSON.stringify(abode.session.get_view(), "\t"))

func capture(sample: String, variant: String, vp: Vector2i) -> void:
	await frames()
	var before: Dictionary = abode.session.state.to_snapshot_dict().duplicate(true)
	await RenderingServer.frame_post_draw
	var file := "%s/%s-%s-%dx%d.png" % [OUT,sample,variant,vp.x,vp.y]
	var result := root.get_texture().get_image().save_png(file)
	var unchanged: bool = before == abode.session.state.to_snapshot_dict()
	if result != OK or not unchanged: failed = true
	records.append({"sample":sample,"variant":variant,"size":[vp.x,vp.y],"file":file,"snapshot_sha256":JSON.stringify(before).sha256_text(),"render_did_not_mutate_state":unchanged,"save_png":result})
	print("IMM0_CAPTURE ", file, " unchanged=",unchanged)

func capture_option_tail(variant: String, vp: Vector2i) -> void:
	var m: FortuneModal = abode.fortune_modal
	for row in m._option_rows:
		m._body_scroll.ensure_control_visible(row.button)
		await frames()
		if row.button.size.x < 44 or row.button.size.y < 44 or not m._body_scroll.get_global_rect().encloses(row.button.get_global_rect()):
			failed = true; push_error("IMM0 option not reachable: " + variant)
	await capture("fortune-pending-tail",variant,vp)
	m._body_scroll.scroll_vertical = 0
	await frames()

func paper_line(bottom: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98,0.96,0.89,0.16)
	s.border_color = Color(0.36,0.33,0.25,0.22)
	s.border_width_bottom = 1 if bottom else 0
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 10; s.content_margin_bottom = 10
	return s

func apply_candidate(sample: String, vp: Vector2i) -> void:
	# Only this transient scene is changed. Existing navigation/type/CloseSeal stay intact.
	var short := vp.y < 500
	if sample.begins_with("home"):
		var s := UiMaterial.surface("paper").duplicate()
		s.content_margin_left = 16; s.content_margin_right = 16
		s.content_margin_top = 14; s.content_margin_bottom = 14
		abode.header.add_theme_stylebox_override("panel",s)
		abode._hud_controller._goal_scroll.add_theme_stylebox_override("panel", UiMaterial.surface("paper"))
		abode.island_world.world_panel.add_theme_stylebox_override("panel",UiMaterial.surface("paper"))
		# One horizontal destination row; removes duplicate vertical island status block.
		abode.island_world.title.text = "人界 · 祖島"
		if not short:
			abode.island_world.world_controls.custom_minimum_size.x = 680
			abode.island_world.rail.add_theme_constant_override("margin_bottom",100)
			abode.header_box.add_theme_constant_override("separation",8)
		for chip in abode._hud_controller._chips.values():
			if chip is PanelContainer:
				chip.add_theme_stylebox_override("panel",UiMaterial.surface("paper"))
				for label in chip.find_children("*","Label",true,false): label.add_theme_color_override("font_color",UiMaterial.INK)
		return
	if sample.begins_with("manufacturing"):
		candidate_manufacturing(short)
		return
	var m: FortuneModal = abode.fortune_modal
	m._title_row.hide() # Same feature tab already names the page and provides CloseSeal.
	if short and sample == "fortune-pending":
		m._options_container.reparent(m._encounter_panel)
		m._options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m._options_container.size_flags_stretch_ratio = 1.5
		m._story.custom_minimum_size.x = 280
		m._encounter_panel.add_theme_constant_override("separation",20)
		m._book_button.text = "抉擇簿"
		m._art.custom_minimum_size = Vector2(48,48)
	if sample == "fortune-save-error":
		m._feedback_row.hide() # Existing shared fixed alert already supplies save-only retry.
	if short and sample != "fortune-pending":
		m._art.custom_minimum_size = Vector2(48,48)
		m._encounter_desc.visible = false
		m._encounter_title.text = "靜候天機"
		m._encounter_title.tooltip_text = m._encounter_desc.text
	if not short:
		m._content.add_theme_constant_override("separation",12)
		m._encounter_panel.add_theme_constant_override("separation",36)
		m._art.custom_minimum_size = Vector2(300,260)
		m._encounter_title.add_theme_font_size_override("font_size",26)
		m._encounter_desc.add_theme_font_size_override("font_size",18)
		if sample == "fortune-pending":
			m._options_container.reparent(m._encounter_panel)
			m._options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m._options_container.size_flags_stretch_ratio = 1.5
			m._story.custom_minimum_size.x = 350
			m._art.reparent(m._story)
			m._story.move_child(m._art,1)
			m._art.custom_minimum_size = Vector2(220,176)
			m._art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m._story.add_theme_constant_override("separation",10)
			m._encounter_desc.add_theme_font_size_override("font_size",16)
			m._encounter_title.add_theme_font_size_override("font_size",24)
			m._book_button.text = "抉擇簿"
	for row in m._option_rows:
		var s := paper_line()
		s.content_margin_top = 5; s.content_margin_bottom = 5
		row.card.add_theme_stylebox_override("panel", s)
		row.button.custom_minimum_size.y = 44
		row.button.add_theme_font_size_override("font_size",18)
	m._options_container.add_theme_constant_override("separation",6 if short else 12)
	if sample != "fortune-pending" and not short:
		m._art.custom_minimum_size = Vector2(360,310)
		m._story.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		m._story.add_theme_constant_override("separation",20)
	m._fit_margin.call_deferred()

func candidate_manufacturing(short: bool) -> void:
	var m = abode.feature_navigation.manufacturing_panel
	# Keep real filter, category, modes, settings and material tiles; only compose them anew.
	m.heading_label.hide()
	m.production_summary.visible = not short
	m.grid.columns = 1
	m.grid.add_theme_constant_override("v_separation",12 if not short else 8)
	for id in m.cards:
		var card: Dictionary = m.cards[id]
		var row: RecipeRow = card.row
		var info: Dictionary = m._view.manufacturing.recipes[id]
		if info.reason == "INSUFFICIENT_RESOURCE":
			var parts: Array[String] = []
			for resource in info.inputs:
				var input: Dictionary = info.inputs[resource]
				if float(input.available) < float(input.required):
					parts.append("%s %.0f／%.0f" % [m._resource_name(resource),float(input.available),float(input.required)])
			row.status.text = "缺料 · " + "、".join(parts)
			row.status.add_theme_color_override("font_color",Color("a23e32"))
			row.status.visible = true
			row.status_box.visible = true
		row.add_theme_stylebox_override("panel",paper_line())
		row.recipe_badge.draw.disconnect(row._draw_badge)
		var art := UiIllustration.new()
		art.texture = preload("res://src/presentation/resource_icon.gd").get_resource_texture(row.product_id)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.recipe_badge.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.offset_left = 6; art.offset_right = -6; art.offset_top = 6; art.offset_bottom = -6
		row.badge_island_icon.hide() # Full island name remains on the same row.
		row.recipe_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if short:
			row.recipe_badge.custom_minimum_size = Vector2(56,56)
			continue
		# A single horizontal workflow: object / requirements / mode and action.
		row.recipe_badge.custom_minimum_size = Vector2(80,80)
		row.recipe_badge.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		row.title.add_theme_font_size_override("font_size",20)
		row.title.custom_minimum_size.y = 36
		var workflow := HBoxContainer.new()
		workflow.add_theme_constant_override("separation",20)
		row.column.add_child(workflow)
		row.column.move_child(workflow,0)
		row.recipe_badge.reparent(workflow)
		var details := VBoxContainer.new()
		details.custom_minimum_size.x = 180
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		workflow.add_child(details)
		row.title.reparent(details)
		row.time_box.reparent(details)
		row.status_box.reparent(details)
		row.materials.reparent(workflow)
		var control_column := VBoxContainer.new()
		control_column.custom_minimum_size.x = 160
		control_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		control_column.add_theme_constant_override("separation",6)
		workflow.add_child(control_column)
		row.modes.reparent(control_column)
		var action_row := HBoxContainer.new()
		control_column.add_child(action_row)
		row.action.reparent(action_row)
		row.settings.reparent(action_row)
		row.header.hide()
		row.controls.hide()
		UiIcon.decorate_button(row.action,UiIcon.Kind.PLAY,GraphicAction.JADE,24)
