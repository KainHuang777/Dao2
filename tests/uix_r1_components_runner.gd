extends SceneTree
## UIX-R1 Component and FeatureUnlocks Unit/Contract Test Runner

const FeatureUnlocks = preload("res://src/presentation/feature_unlocks.gd")
const DockButton = preload("res://src/presentation/components/dock_button.gd")
const ResourceChip = preload("res://src/presentation/components/resource_chip.gd")
const SegmentChips = preload("res://src/presentation/components/segment_chips.gd")
const GameTab = preload("res://src/presentation/components/game_tab.gd")
const CloseSeal = preload("res://src/presentation/components/close_seal.gd")
const DaoSeal = preload("res://src/presentation/components/dao_seal.gd")

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func run() -> void:
	test_feature_unlocks()
	test_real_view_routes()
	await test_dock_button()
	await test_resource_chip()
	await test_segment_chips()
	await test_game_tab()
	await test_close_seal()
	await test_dao_seal()
	
	print("UIX-R1: %d checks passed with %d failures." % [checks, failures.size()])
	for f in failures:
		push_error(f)
	quit(0 if failures.is_empty() else 1)

func test_real_view_routes() -> void:
	var content = ContentLoader.load_directory("res://content").content
	SkillSystem.attach(content)
	var session := GameSession.create_new_game(content)
	var view := session.get_view()
	check(FeatureUnlocks.check("skills", view).state == FeatureUnlocks.State.PREVIEW, "Real View previews locked skills")
	session.state.era_id = 2
	session.state.buildings.library = 1
	view = session.get_view()
	check(FeatureUnlocks.check("skills", view).state == FeatureUnlocks.State.AVAILABLE, "Real View library level dictionary unlocks skills")
	for group in preload("res://src/presentation/feature_navigation.gd").GROUPS.values():
		for entry in group.pages:
			check(FeatureUnlocks.check(entry[0], view).reason != "未知功能", "Canonical route %s recognized" % entry[0])

func test_feature_unlocks() -> void:
	# 1. Base routes always available
	for r in ["buildings", "alchemy", "achievements"]:
		var res := FeatureUnlocks.check(r, {"era_id": 1})
		check(res.state == FeatureUnlocks.State.AVAILABLE, "Base route %s available at era 1" % r)
	for r in ["outposts", "manufacturing", "transport"]:
		check(FeatureUnlocks.check(r, {"era_id": 1}).state == FeatureUnlocks.State.HIDDEN, "%s hidden before foundation" % r)
		check(FeatureUnlocks.check(r, {"era_id": 2}).state == FeatureUnlocks.State.AVAILABLE, "%s available at foundation" % r)
	check((UiTypography.chapter_font() as FontVariation).base_font == UiTypography.BASE_FONT, "headings use shared sans family")
	
	# 2. Skill route
	# Era 1 -> PREVIEW ("築基期開放")
	var s_era1 := FeatureUnlocks.check("skills", {"era_id": 1})
	check(s_era1.state == FeatureUnlocks.State.PREVIEW and s_era1.reason == "築基期開放", "Skill preview at era 1")
	# Era 2 without library -> PREVIEW ("需建造藏經閣")
	var s_era2_nolib := FeatureUnlocks.check("skills", {"era_id": 2, "buildings": {"library": 0}})
	check(s_era2_nolib.state == FeatureUnlocks.State.PREVIEW and s_era2_nolib.reason == "需建造藏經閣", "Skill preview at era 2 without library")
	# Era 2 with library -> AVAILABLE
	var s_era2_lib := FeatureUnlocks.check("skills", {"era_id": 2, "buildings": {"library": 1}})
	check(s_era2_lib.state == FeatureUnlocks.State.AVAILABLE, "Skill available at era 2 with library")
	
	# 3. Sect route
	# Era 1, reinc 0 -> PREVIEW ("築基期開放")
	var sect_era1 := FeatureUnlocks.check("sect", {"era_id": 1, "reincarnation_count": 0})
	check(sect_era1.state == FeatureUnlocks.State.PREVIEW and sect_era1.reason == "築基期開放", "Sect preview at era 1")
	# Era 2, reinc 0 -> AVAILABLE
	var sect_era2 := FeatureUnlocks.check("sect", {"era_id": 2, "reincarnation_count": 0})
	check(sect_era2.state == FeatureUnlocks.State.AVAILABLE, "Sect available at era 2")
	# Era 1, reinc 1 -> AVAILABLE
	var sect_reinc := FeatureUnlocks.check("sect", {"era_id": 1, "reincarnation_count": 1})
	check(sect_reinc.state == FeatureUnlocks.State.AVAILABLE, "Sect available at era 1 if reincarnated")
	
	# 4. Beast route
	# Era 1 -> HIDDEN
	var beast_era1 := FeatureUnlocks.check("beasts", {"era_id": 1})
	check(beast_era1.state == FeatureUnlocks.State.HIDDEN, "Beast hidden at era 1")
	# Era 2 -> PREVIEW ("結丹期開放")
	var beast_era2 := FeatureUnlocks.check("beasts", {"era_id": 2})
	check(beast_era2.state == FeatureUnlocks.State.PREVIEW and beast_era2.reason == "結丹期開放", "Beast preview at era 2")
	# Era 3 -> AVAILABLE
	var beast_era3 := FeatureUnlocks.check("beasts", {"era_id": 3})
	check(beast_era3.state == FeatureUnlocks.State.AVAILABLE, "Beast available at era 3")
	
	# 5. Realm decision & Fortune
	var rd_era1 := FeatureUnlocks.check("decisions", {"era_id": 1})
	check(rd_era1.state == FeatureUnlocks.State.PREVIEW and rd_era1.reason == "築基期開放", "Realm decision preview at era 1")
	var rd_era2 := FeatureUnlocks.check("decisions", {"era_id": 2})
	check(rd_era2.state == FeatureUnlocks.State.AVAILABLE, "Realm decision available at era 2")
	
	var fort_era1 := FeatureUnlocks.check("fortune", {"era_id": 1})
	check(fort_era1.state == FeatureUnlocks.State.PREVIEW and fort_era1.reason == "築基期開放", "Fortune preview at era 1")
	var fort_era2 := FeatureUnlocks.check("fortune", {"era_id": 2})
	check(fort_era2.state == FeatureUnlocks.State.AVAILABLE, "Fortune available at era 2")
	
	# 6. Reincarnation
	var reinc_hidden := FeatureUnlocks.check("reincarnation", {"era_id": 5, "reincarnation_count": 0})
	check(reinc_hidden.state == FeatureUnlocks.State.HIDDEN, "Reincarnation hidden before era 6")
	var reinc_era6 := FeatureUnlocks.check("reincarnation", {"era_id": 6, "reincarnation_count": 0})
	check(reinc_era6.state == FeatureUnlocks.State.AVAILABLE, "Reincarnation available at era 6")
	var reinc_count1 := FeatureUnlocks.check("reincarnation", {"era_id": 1, "reincarnation_count": 1})
	check(reinc_count1.state == FeatureUnlocks.State.AVAILABLE, "Reincarnation available when count >= 1")
	
	# 7. Nine realms
	var nine_era2 := FeatureUnlocks.check("realms", {"era_id": 2})
	check(nine_era2.state == FeatureUnlocks.State.HIDDEN, "Nine realms hidden at era 2")
	var nine_era3 := FeatureUnlocks.check("realms", {"era_id": 3})
	check(nine_era3.state == FeatureUnlocks.State.PREVIEW and nine_era3.reason == "元嬰期開放", "Nine realms preview at era 3")
	var nine_era4 := FeatureUnlocks.check("realms", {"era_id": 4})
	check(nine_era4.state == FeatureUnlocks.State.AVAILABLE, "Nine realms available at era 4")
	
	# 8. Fallback / Unknown route
	var unknown := FeatureUnlocks.check("custom_unknown", {"era_id": 1})
	check(unknown.state == FeatureUnlocks.State.HIDDEN, "Unknown route stays hidden")

func test_dock_button() -> void:
	var btn := DockButton.new()
	root.add_child(btn)
	await process_frame
	
	check(btn.custom_minimum_size == Vector2(56, 56), "DockButton minimum size 56x56")
	check(btn.toggle_mode == true, "DockButton toggle_mode enabled")
	check(btn.focus_mode == Control.FOCUS_NONE, "DockButton focus_mode NONE")
	
	# Red dot visibility
	check(btn._red_dot != null and not btn._red_dot.visible, "DockButton red dot initially hidden")
	btn.set_red_dot(true)
	check(btn._red_dot.visible, "DockButton red dot visible after set_red_dot(true)")
	check(btn._red_dot.mouse_filter == Control.MOUSE_FILTER_IGNORE and btn._red_dot.get_child(0).mouse_filter == Control.MOUSE_FILTER_IGNORE, "DockButton badge does not intercept clicks")
	btn.set_red_dot(false)
	check(not btn._red_dot.visible, "DockButton red dot hidden after set_red_dot(false)")
	
	# Style update on toggle
	btn.button_pressed = true
	btn._update_style()
	var pressed_style: StyleBoxTexture = btn.get_theme_stylebox("normal")
	check(pressed_style != null and pressed_style.modulate_color.r > 1.0, "DockButton selected jade is brighter")
	
	btn.button_pressed = false
	btn._update_style()
	var normal_style: StyleBoxTexture = btn.get_theme_stylebox("normal")
	check(normal_style != null and normal_style.texture == UiMaterial.UIX_JADE and normal_style.modulate_color == Color.WHITE, "DockButton normal jade style applied")
	
	btn.queue_free()
	await process_frame

func test_resource_chip() -> void:
	var chip := ResourceChip.new()
	root.add_child(chip)
	await process_frame
	
	check(chip.icon_rect != null, "ResourceChip has icon_rect")
	check(chip.value_label != null, "ResourceChip has value_label")
	
	# Setup with normal amount
	chip.setup("wood", 150.0, false)
	check(chip.value_label.text == "150", "ResourceChip formats regular number directly")
	check(chip.value_label.get_theme_color("font_color") == Color("efe7d1"), "ResourceChip non-full font color efe7d1")
	
	# Setup with large amount (>= 10000)
	chip.setup("wood", 25600.0, true)
	check(chip.value_label.text == "2.6w", "ResourceChip formats >= 10000 with w suffix (2.6w)")
	check(chip.value_label.get_theme_color("font_color") == Color("f3d48c"), "ResourceChip is_full font color f3d48c")
	
	chip.setup("wood", 10000.0, false)
	check(chip.value_label.text == "1.0w", "ResourceChip formats 10000 as 1.0w")
	chip.setup("unknown_resource", 0, false)
	check(chip.icon_rect.texture == null, "Unknown resource clears stale icon")
	
	chip.queue_free()
	await process_frame

func test_segment_chips() -> void:
	var seg := SegmentChips.new()
	root.add_child(seg)
	await process_frame
	
	var labels: PackedStringArray = ["全部", "宗門", "島嶼"]
	seg.set_segments(labels, 0)
	check(seg.get_child_count() == 3, "SegmentChips creates matching number of buttons")
	
	var btn0: Button = seg.get_child(0)
	var btn1: Button = seg.get_child(1)
	var btn2: Button = seg.get_child(2)
	check(btn0.button_pressed and not btn1.button_pressed and not btn2.button_pressed, "SegmentChips initial selected index 0")
	
	# Test selection change signal
	var payload := {"index": -1}
	seg.segment_selected.connect(func(idx: int): payload.index = idx)
	seg._on_button_pressed(1)
	
	check(payload.index == 1, "SegmentChips emits segment_selected with clicked index")
	check(not btn0.button_pressed and btn1.button_pressed and not btn2.button_pressed, "SegmentChips mutually exclusive selection")
	
	seg.queue_free()
	await process_frame

func test_game_tab() -> void:
	var tab := GameTab.new()
	root.add_child(tab)
	await process_frame
	
	check(tab.toggle_mode == true, "GameTab toggle_mode enabled")
	check(tab.focus_mode == Control.FOCUS_NONE, "GameTab focus_mode NONE")
	
	tab.button_pressed = true
	tab._update_style()
	check(tab.button_pressed, "GameTab handles selection state")
	
	tab.queue_free()
	await process_frame

func test_close_seal() -> void:
	var seal := CloseSeal.new()
	root.add_child(seal)
	await process_frame
	
	check(seal.custom_minimum_size == Vector2(44, 44), "CloseSeal touch target 44x44")
	check(seal.text == "×" and UiTypography.body_font().has_char(0x00d7), "CloseSeal uses cross supported by runtime font")
	check(seal.focus_mode == Control.FOCUS_NONE, "CloseSeal focus_mode NONE")
	
	var normal_box: StyleBoxFlat = seal.get_theme_stylebox("normal")
	check(normal_box != null and normal_box.bg_color == Color.TRANSPARENT, "CloseSeal inherits paper without black background")
	
	seal.queue_free()
	await process_frame

func test_dao_seal() -> void:
	var dao := DaoSeal.new()
	root.add_child(dao)
	await process_frame
	
	check(dao.custom_minimum_size == Vector2(64, 64), "DaoSeal minimum size 64x64")
	check(dao.text == "道", "DaoSeal initial text is '道'")
	check(dao._label.text == "道", "DaoSeal internal label matches text")
	
	# Text change
	dao.text = "悟"
	check(dao._label.text == "悟", "DaoSeal label updates on text assignment")
	
	# Progress ratio clamping
	dao.progress_ratio = 0.75
	check(is_equal_approx(dao.progress_ratio, 0.75), "DaoSeal ratio set to 0.75")
	dao.progress_ratio = -0.5
	check(is_equal_approx(dao.progress_ratio, 0.0), "DaoSeal ratio clamps lower bound 0.0")
	dao.progress_ratio = 1.5
	check(is_equal_approx(dao.progress_ratio, 1.0), "DaoSeal ratio clamps upper bound 1.0")
	
	dao.queue_free()
	await process_frame
