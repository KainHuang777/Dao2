extends Node2D
## Layered island presentation: artwork reads economy, never produces resources.
const LOCATIONS := {"wood": Vector2(1450, -100), "ore": Vector2(-1450, -100), "herb": Vector2(0, -1550)}
const ROLES := {"home": "修行與祖業", "wood": "林業・靈材加工", "ore": "採礦・銅精加工", "herb": "靈草採集・丹液提煉"}
var abode: Node
var current := "home"
var roots := {}
var bodies := {}
var landmarks := {}
var rail: MarginContainer
var title: Label
var world_controls: HFlowContainer
var world_panel: PanelContainer
var buttons := {}
var banner_until := 0
var framed_size := Vector2.ZERO

func build(scene: Node) -> void:
	abode = scene
	for id in LOCATIONS:
		var root := Node2D.new()
		root.position = LOCATIONS[id]
		add_child(root)
		roots[id] = root
		var body := Sprite2D.new()
		root.add_child(body)
		bodies[id] = body
		var landmark := Sprite2D.new()
		landmark.position = Vector2(0, -170)
		root.add_child(landmark)
		landmarks[id] = landmark
	# Container rail occupies the safe world region; no UI positions in world art.
	rail = MarginContainer.new()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abode.hud.add_child(rail)
	rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var align := VBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(align)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	align.add_child(spacer)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	align.add_child(center)
	var panel := PanelContainer.new()
	world_panel = panel
	panel.add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", UiMaterial.INK)
	column.add_child(title)
	var row := HFlowContainer.new()
	world_controls = row
	column.add_child(row)
	for id in IslandProgression.NAMES:
		var button := Button.new()
		button.text = "返回祖島" if id == "home" else IslandProgression.NAMES[id]
		button.custom_minimum_size = Vector2(90, 44)
		UiMaterial.apply_button(button)
		button.pressed.connect(func(): enter(id))
		row.add_child(button)
		buttons[id] = button
	var manage := Button.new()
	manage.text = "管理此島"
	manage.custom_minimum_size.y = 44
	UiMaterial.apply_button(manage)
	manage.pressed.connect(func(): manage_current())
	row.add_child(manage)
	refresh()

func refresh() -> void:
	var available: bool = abode.session.state.era_id >= 2
	if available and current != "home" and framed_size != abode.hud.size:
		_focus_remote()
	rail.visible = available and abode.feature_navigation.group == "home" and not abode.offline_summary.visible and not abode.save_controls.visible and not abode.debug_panel.visible
	for id in roots:
		if available:
			_ensure_art(id)
		roots[id].visible = available
		var opened: bool = abode.session.state.economy.get("islands", {}).get(id, {}).get("opened", false)
		landmarks[id].visible = opened
		roots[id].modulate = Color.WHITE if opened else Color(0.68, 0.73, 0.72)
	if not available and current != "home":
		current = "home"
		abode.camera.focus_home()
	if available:
		var status := "祖業保留" if current == "home" else ("產業已開拓" if landmarks[current].visible else "待開拓・可查看條件")
		if current == "herb" and not landmarks.herb.visible:
			status = "金丹解鎖・可查看條件" if abode.session.state.era_id < 3 else ("待開拓・可查看條件" if abode.session.state.economy.get("version") == IslandProgression.VERSION else "需接續丹霞產業・保留原檔")
		var detail: String = ROLES[current] if Time.get_ticks_msec() < banner_until else status
		title.text = ("%s・%s" if abode.hud.size.y < 500 else "人界・%s\n%s") % [IslandProgression.NAMES[current], detail]
		# Wrap the four-island controls inside the safe width; never grow the HUD.
		var safe_left := int(abode.header.size.x + 24)
		var panel_padding := world_panel.get_theme_stylebox("panel").get_minimum_size().x
		world_controls.custom_minimum_size.x = maxf(90.0, minf(510.0, abode.hud.size.x - safe_left - 16.0 - panel_padding))
		rail.add_theme_constant_override("margin_left", safe_left)
		rail.add_theme_constant_override("margin_right", 16)
		rail.add_theme_constant_override("margin_bottom", int(abode.hud.size.y - abode.toolbar.position.y + 12.0))
		if rail.visible:
			abode.hint_panel.visible = false
	queue_redraw()

func _ensure_art(id: String) -> void:
	# Unavailable Era1 islands allocate no textures; cache once when Era2 is reached.
	if bodies[id].texture == null:
		var folder := "res1d2" if id == "herb" else "res1c3"
		bodies[id].texture = load("res://assets/abode/%s/%s_body.png" % [folder, id])
		bodies[id].scale = Vector2.ONE * (780.0 / bodies[id].texture.get_width())
	if landmarks[id].texture == null:
		var folder := "res1d2" if id == "herb" else "res1c3"
		landmarks[id].texture = load("res://assets/abode/%s/%s_landmark.png" % [folder, id])
		landmarks[id].scale = Vector2.ONE * (440.0 / landmarks[id].texture.get_width())

func _draw() -> void:
	if abode == null or abode.session.state.era_id < 2:
		return
	var economy: Dictionary = abode.session.state.economy
	for id in IslandEconomy.ROUTES:
		var trip: Dictionary = economy.get("trips", {}).get(id, {})
		if trip.is_empty():
			continue
		var route: Array = IslandEconomy.ROUTES[id]
		var start: Vector2 = LOCATIONS.get(route[0], Vector2.ZERO) + Vector2(-280, 40)
		var finish: Vector2 = LOCATIONS.get(route[1], Vector2.ZERO) + Vector2(-280, 40)
		var fraction := clampf(1.0 - float(trip.remaining) / 10.0, 0.0, 1.0)
		var ship := start.lerp(finish, fraction)
		var tint := Color("c4a16b") if id.ends_with("home") else Color("84aaa1")
		draw_line(start, finish, Color(tint, 0.3), 3.0)
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-16, -5), ship + Vector2(16, -5), ship + Vector2(8, 8), ship + Vector2(-10, 8)]), tint)
		draw_line(ship + Vector2(0, -5), ship + Vector2(0, -26), tint, 3.0)

func enter(id: String) -> void:
	if not IslandProgression.NAMES.has(id) or abode.session.state.era_id < 2:
		return
	current = id
	banner_until = Time.get_ticks_msec() + 2200
	abode.feature_navigation.home()
	if id == "home":
		abode._return_home()
	else:
		_focus_remote()
	refresh()

func _focus_remote() -> void:
	framed_size = abode.hud.size
	abode.camera.zoom_anchor_active = false
	var compact := framed_size.y < 500
	abode.camera.target_zoom = 0.30 if compact else 0.65
	var displacement: float = abode.header.size.x * 0.5 / abode.camera.target_zoom
	abode.camera.target_position = LOCATIONS[current] + Vector2(-displacement, 260 if compact else -75)

func manage_current() -> void:
	abode.feature_navigation.open("outposts")
	abode.feature_navigation.island_panel.select_island(current)

func pick(point: Vector2) -> bool:
	if abode.session.state.era_id < 2:
		return false
	for id in LOCATIONS:
		# Same visible island surface at every zoom; no invisible remote entrance.
		if roots[id].visible and Rect2(LOCATIONS[id] - Vector2(390, 210), Vector2(780, 370)).has_point(point):
			current = id
			banner_until = Time.get_ticks_msec() + 2200
			manage_current()
			return true
	return false
