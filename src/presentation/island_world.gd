extends Node2D
## Layered island presentation: artwork reads economy, never produces resources.
const LOCATIONS := {"wood": Vector2(1450, -100), "ore": Vector2(-1450, -100), "herb": Vector2(0, -1550), "deep": Vector2(2300, -1750), "ancient": Vector2(-2300, -1750), "void": Vector2(0, -3300)}
const ROLES := {"home": "修行與祖業", "wood": "林業・靈材加工", "ore": "採礦・銅精加工", "herb": "靈草採集・丹液提煉", "deep": "精鐵・秘銀・寒鐵採集", "ancient": "千年靈草採集", "void": "虛空精華採集"}
const CARGO_SWORD: Texture2D = preload("res://assets/abode/sword.png")
var cargo_swords := {}
var abode: Node
var current := "home"
var roots := {}
var bodies := {}
var landmarks := {}
var landmark_masks := {}
var rail: MarginContainer
var _rail_align: VBoxContainer
var _rail_center: CenterContainer
var _rail_launcher: PanelContainer
var title: Label
var world_controls: HBoxContainer
var world_panel: PanelContainer
var buttons := {}
var selector
var selector_button: Button
var return_button: Button
var _wide_list_open := true
var _framing_signature: Array = []
var destination_ids: Array[String] = []
var manage_button: Button
var banner_until := 0
var framed_size := Vector2.ZERO

func build(scene: Node) -> void:
	abode = scene
	# A bounded visual per real route; no decorative or empty-return flights.
	for id in _all_routes():
		var sword := Sprite2D.new()
		sword.texture = CARGO_SWORD
		sword.scale = Vector2.ONE * 76.0 / CARGO_SWORD.get_width()
		sword.z_index = 3
		var material := ShaderMaterial.new()
		material.shader = NativeVfx.SWORD
		material.set_shader_parameter("emission", _cargo_tint(id))
		sword.material = material
		sword.visible = false
		add_child(sword)
		cargo_swords[id] = sword
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
	# Compact launcher and expanded selector share existing world/menu ownership.
	rail = MarginContainer.new()
	rail.hide()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abode.hud.add_child(rail)
	rail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var align := VBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_align = align
	rail.add_child(align)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	align.add_child(spacer)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_center = center
	align.add_child(center)
	var launcher := PanelContainer.new()
	launcher.add_theme_stylebox_override("panel",UiMaterial.hud_paper())
	_rail_launcher = launcher
	center.add_child(launcher)
	world_controls = HBoxContainer.new()
	launcher.add_child(world_controls)
	selector_button = GraphicAction.new()
	selector_button.custom_minimum_size = Vector2(140,44)
	UiIcon.decorate_button(selector_button,UiIcon.Kind.ISLAND_HOME,GraphicAction.JADE,24)
	selector_button.pressed.connect(show_selector)
	world_controls.add_child(selector_button)
	return_button = GraphicAction.new()
	return_button.text = "歸家"
	return_button.custom_minimum_size = Vector2(76,44)
	UiIcon.decorate_button(return_button,UiIcon.Kind.RETURN_ARROW,GraphicAction.JADE,24)
	return_button.pressed.connect(func(): enter("home"))
	world_controls.add_child(return_button)
	manage_button = GraphicAction.new()
	manage_button.text = "管理此島"
	manage_button.custom_minimum_size = Vector2(100,44)
	UiIcon.decorate_button(manage_button,UiIcon.Kind.MANAGEMENT,GraphicAction.JADE,24)
	manage_button.pressed.connect(manage_current)
	world_controls.add_child(manage_button)
	selector = preload("res://src/presentation/island_selector.gd").new()
	selector.name = "IslandSelector"
	abode.hud.add_child(selector)
	selector.hide()
	selector.selected.connect(_select_destination)
	selector.close_requested.connect(close_selector)
	world_panel = selector
	title = selector.title
	buttons = selector.buttons
	abode.hud.resized.connect(_on_hud_resized)
	refresh()

func _on_hud_resized() -> void:
	if abode == null or abode.session == null or abode.feature_navigation == null or abode.feature_navigation.shell == null:
		return
	_apply_world_layout.call_deferred(abode.hud.size)

func refresh() -> void:
	var available: bool = abode.session.state.era_id >= 2
	if current != "home" and not _world_visible(current):
		current = "home"
		abode._return_home()
	_refresh_cargo(available)
	if available and current != "home" and framed_size != abode.hud.size:
		_focus_remote()
	for id in roots:
		var visible_world := _world_visible(id)
		if visible_world:
			_ensure_art(id)
		roots[id].visible = visible_world
		var opened: bool = abode.session.state.economy.get("islands", {}).get(id, {}).get("opened", false)
		landmarks[id].visible = opened and visible_world
		roots[id].modulate = Color.WHITE if opened else Color(0.68, 0.73, 0.72)
	if not available and current != "home":
		current = "home"
		abode.camera.focus_home()
	_refresh_destinations()
	var had_world_ui: bool = rail.visible or selector.visible
	var vp: Vector2 = abode.hud.size
	var wide := _wide(vp)
	var shell = abode.feature_navigation.shell
	var overlay: String = shell.state.snapshot().overlay
	var own_tool: bool = shell._tool == selector and overlay == "tool"
	var home_view: bool = available and abode.feature_navigation.group == "home" and not abode.offline_summary.visible and not abode.v2_rules_notice.visible and not abode.save_controls.visible and not abode.debug_panel.visible and not abode._hud_controller.messages_are_explicit()
	rail.visible = home_view and overlay.is_empty() and (not wide or not _wide_list_open)
	selector.visible = own_tool or (home_view and overlay.is_empty() and wide and _wide_list_open)
	var status := _island_status(current)
	title.text = "%s · %s" % [IslandProgression.NAMES[current],status]
	selector_button.text = "選島 · " + IslandProgression.NAMES[current]
	var host: Node = selector.footer if wide and selector.visible and not own_tool else world_controls
	if manage_button.get_parent() != host: manage_button.reparent(host)
	return_button.visible = current != "home"
	_layout_for_size(vp)
	if rail.visible or selector.visible: abode.hint_panel.visible = false
	var frame_signature := [vp,wide and selector.visible and not own_tool,rail.visible,current]
	if frame_signature != _framing_signature:
		_framing_signature = frame_signature
		if available or had_world_ui:
			abode._home_frame_size = Vector2.ZERO
			abode._layout_for_size.call_deferred(vp)
			if current != "home": _focus_remote()
	queue_redraw()

func _wide(vp: Vector2) -> bool:
	return vp.x>=960 and vp.y>=500 and vp.x>=vp.y*1.45

func _layout_for_size(vp: Vector2) -> void:
	if abode == null or vp.x <= 0.0 or vp.y <= 0.0:
		return
	_apply_world_layout(vp)

func _apply_world_layout(vp: Vector2) -> void:
	var wide := _wide(vp)
	var shell = abode.feature_navigation.shell
	var own_tool: bool = shell._tool == selector and shell.state.snapshot().overlay == "tool"
	var toolbar_y: float = abode.toolbar.position.y
	if wide:
		selector.set_compact(false)
		selector.position = Vector2(vp.x-320,84)
		selector.size = Vector2(304,maxf(120,toolbar_y-96))
	else:
		var slot := Rect2(Vector2(16,68),Vector2(minf(600,vp.x-32),maxf(120,(toolbar_y-8)-68)))
		if own_tool and selector.visible:
			selector.set_layout_bounds(slot)
		else:
			selector.set_compact(true)
			var drawer_width: float = minf(304.0,slot.size.x)
			var host: Control = selector.get_parent() as Control
			var host_width: float = host.size.x if host != null else vp.x
			selector.position = Vector2(maxf(0.0,host_width-slot.position.x-drawer_width),slot.position.y)
			selector.size = Vector2(drawer_width,slot.size.y)
	var safe_left := int(abode.header.size.x+24) if wide else 16
	var safe_bottom := int(vp.y-toolbar_y+12)
	rail.add_theme_constant_override("margin_left",safe_left)
	rail.add_theme_constant_override("margin_right",16)
	rail.add_theme_constant_override("margin_bottom",safe_bottom)
	selector_button.custom_minimum_size = Vector2(140,44) if wide else Vector2(108,44)
	return_button.custom_minimum_size = Vector2(76,44) if wide else Vector2(64,44)
	manage_button.custom_minimum_size = Vector2(100,44) if wide else Vector2(86,44)
	world_controls.add_theme_constant_override("separation",6 if wide else 4)
	_rail_align.add_theme_constant_override("separation",0)
	rail.position = Vector2.ZERO
	rail.size = vp
	var inner := Rect2(Vector2(safe_left,0),Vector2(maxf(44.0,vp.x-float(safe_left)-16.0),maxf(44.0,vp.y-float(safe_bottom))))
	_rail_align.position = inner.position
	_rail_align.size = inner.size
	var paper: StyleBox = _rail_launcher.get_theme_stylebox("panel")
	var pad_left: float = paper.get_margin(SIDE_LEFT)
	var pad_right: float = paper.get_margin(SIDE_RIGHT)
	var pad_top: float = paper.get_margin(SIDE_TOP)
	var pad_bottom: float = paper.get_margin(SIDE_BOTTOM)
	var row_min: Vector2 = world_controls.get_combined_minimum_size()
	var launcher := Vector2(clampf(row_min.x+pad_left+pad_right,44.0,inner.size.x),maxf(44.0,row_min.y+pad_top+pad_bottom))
	_rail_center.position = Vector2(0,maxf(0.0,inner.size.y-launcher.y))
	_rail_center.size = Vector2(inner.size.x,launcher.y)
	_rail_launcher.position = Vector2(maxf(0.0,(inner.size.x-launcher.x)*0.5),0)
	_rail_launcher.size = launcher
	world_controls.position = Vector2(pad_left,pad_top)
	world_controls.size = Vector2(maxf(0.0,launcher.x-pad_left-pad_right),maxf(44.0,launcher.y-pad_top-pad_bottom))
	var cursor := 0.0
	var gap := 6.0 if wide else 4.0
	for control in world_controls.get_children():
		var row_button: Button = control as Button
		if row_button == null or not row_button.visible:
			continue
		var button_width: float = maxf(44.0,row_button.get_combined_minimum_size().x)
		row_button.position = Vector2(cursor,0)
		row_button.size = Vector2(button_width,world_controls.size.y)
		cursor += button_width+gap
	rail.queue_sort()
	_rail_align.queue_sort()
	_rail_center.queue_sort()
	_rail_launcher.queue_sort()
	world_controls.queue_sort()
	selector.queue_sort()

func show_selector() -> void:
	if abode.feature_navigation.group != "home" or abode.session.state.era_id<2: return
	if not abode.feature_navigation.shell.state.snapshot().overlay.is_empty(): return
	if _wide(abode.hud.size):
		_wide_list_open = true
		refresh()
	else:
		abode.feature_navigation.shell.open_tool(selector)
		refresh()
	selector.reveal_current(current)

func close_selector() -> void:
	var shell = abode.feature_navigation.shell
	if shell._tool == selector:
		shell.close_overlay()
	else:
		_wide_list_open = false
	refresh()

func _select_destination(id: String) -> void:
	if abode.feature_navigation.shell._tool == selector: abode.feature_navigation.shell.close_overlay()
	enter(id)

func _island_status(id: String) -> String:
	if id == "home": return "修行與祖業"
	if id == "herb" and abode.session.state.era_id<3: return "金丹解鎖 · 可查看條件"
	var opened: bool = abode.session.state.economy.get("islands",{}).get(id,{}).get("opened",false)
	return "已開拓" if opened else "待開拓 · 可查看條件"

func world_safe_rect(vp: Vector2) -> Rect2:
	var left: float = maxf(abode.header.get_global_rect().end.x,abode.resource_ribbon.get_global_rect().end.x if abode.resource_ribbon.visible else 0)+12
	var right := vp.x-16
	if selector.visible and _wide(vp) and abode.feature_navigation.shell._tool != selector: right = minf(right,selector.position.x-12)
	var bottom: float = abode.toolbar.position.y-12-(60 if rail.visible else 0)
	return Rect2(Vector2(left,16),Vector2(maxf(160,right-left),maxf(140,bottom-16)))

func _ensure_art(id: String) -> void:
	# Unavailable Era1 islands allocate no textures; cache once when Era2 is reached.
	if bodies[id].texture == null:
		var folder := "world46" if id in ["deep", "ancient", "void"] else ("res1d2" if id == "herb" else "res1c3")
		bodies[id].texture = load("res://assets/abode/%s/%s_body.png" % [folder, id])
		bodies[id].scale = Vector2.ONE * (780.0 / bodies[id].texture.get_width())
	if landmarks[id].texture == null:
		var folder := "world46" if id in ["deep", "ancient", "void"] else ("res1d2" if id == "herb" else "res1c3")
		landmarks[id].texture = load("res://assets/abode/%s/%s_landmark.png" % [folder, id])
		landmarks[id].scale = Vector2.ONE * (440.0 / landmarks[id].texture.get_width())
		if id in ["deep", "ancient", "void"]:
			# Preserve A's accepted-for-integration preview proportions and shared ground line.
			landmarks[id].scale = Vector2.ONE * ((780.0 * 310.0 / 570.0) / landmarks[id].texture.get_width())
			landmarks[id].position.y = -8.0 - landmarks[id].texture.get_height() * landmarks[id].scale.y * 0.5
		var mask := BitMap.new()
		mask.create_from_image_alpha(landmarks[id].texture.get_image(), 0.15)
		landmark_masks[id] = mask

func _cargo_tint(id: String) -> Color:
	return Color("c4a16b") if id.ends_with("home") else Color("84aaa1")

func _cargo_leg(id: String) -> Dictionary:
	var trip: Dictionary = abode.session.state.economy.get("trips", {}).get(id, {})
	if trip.is_empty() or float(trip.get("cargo", 0)) <= 0:
		return {}
	var routes := IslandEconomy.route_defs(abode.session.state)
	if not routes.has(id):
		return {}
	var route: Array = routes[id]
	if not _world_visible(route[0]) or not _world_visible(route[1]):
		return {}
	var start: Vector2 = LOCATIONS.get(route[0], Vector2.ZERO) + Vector2(-280, 40)
	var finish: Vector2 = LOCATIONS.get(route[1], Vector2.ZERO) + Vector2(-280, 40)
	# The core contract is a ten-second loaded leg. Never advance rule time here.
	var fraction := clampf(1.0 - float(trip.remaining) / 10.0, 0.0, 1.0)
	return {"start": start, "finish": finish, "position": start.lerp(finish, fraction)}

func _refresh_cargo(available: bool) -> void:
	for id in cargo_swords:
		var sword: Sprite2D = cargo_swords[id]
		var leg := _cargo_leg(id) if available else {}
		sword.visible = not leg.is_empty()
		if leg.is_empty():
			continue
		sword.position = leg.position
		sword.rotation = (leg.finish - leg.start).angle()
		sword.material.set_shader_parameter("clock", 0.0 if abode.reduced else float(Time.get_ticks_msec()) / 1000.0)
		sword.material.set_shader_parameter("strength", 0.2 if abode.reduced else 0.8)

func _draw() -> void:
	if abode == null or abode.session.state.era_id < 2:
		return
	for id in _all_routes():
		var leg := _cargo_leg(id)
		if leg.is_empty():
			continue
		var tint := _cargo_tint(id)
		draw_line(leg.start, leg.finish, Color(tint, 0.16), 1.2, true)
		if not abode.reduced:
			var direction: Vector2 = (leg.finish - leg.start).normalized()
			for segment in range(6):
				draw_line(leg.position - direction * segment * 6.0, leg.position - direction * (segment + 1) * 6.0, Color(tint, 0.6 * (1.0 - float(segment) / 6.0)), 2.5, true)

func enter(id: String) -> void:
	if not _world_visible(id):
		return
	if abode.feature_navigation.shell._tool == selector: abode.feature_navigation.shell.close_overlay()
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
	var safe := world_safe_rect(framed_size)
	abode.camera.target_zoom = clampf(minf(safe.size.x/840.0,safe.size.y/720.0),0.20,0.65)
	abode.camera.target_position = LOCATIONS[current]+Vector2(0,-80)-(safe.get_center()-framed_size*0.5)/abode.camera.target_zoom

func manage_current() -> void:
	if abode.feature_navigation.shell._tool == selector: abode.feature_navigation.shell.close_overlay()
	abode.feature_navigation.open("outposts")
	abode.feature_navigation.island_panel.select_island(current)

func pick(point: Vector2) -> bool:
	if abode.session.state.era_id < 2:
		return false
	for id in LOCATIONS:
		if not roots[id].visible:
			continue
		var art: Sprite2D = landmarks[id]
		var local := art.to_local(point) - art.get_rect().position
		if art.visible and landmark_masks.has(id) and Rect2(Vector2.ZERO, Vector2(landmark_masks[id].get_size())).has_point(local) and landmark_masks[id].get_bitv(Vector2i(local)):
			current = id
			if IslandProgression.RECIPES.has(id):
				abode.feature_navigation.open_manufacturing(id, IslandProgression.RECIPES[id])
			else:
				manage_current()
			return true
		# Same visible island surface at every zoom; no invisible remote entrance.
		if roots[id].visible and Rect2(LOCATIONS[id] - Vector2(390, 210), Vector2(780, 370)).has_point(point):
			current = id
			banner_until = Time.get_ticks_msec() + 2200
			manage_current()
			return true
	return false

func _all_routes() -> Dictionary:
	var routes := IslandEconomy.ROUTES.duplicate()
	routes.merge(IslandEconomy.HUB_ROUTES)
	routes.merge(IslandEconomy.supply_data().routes)
	return routes

func _world_visible(id: String) -> bool:
	if abode.session.state.era_id < 2:
		return false
	if id in ["home", "wood", "ore", "herb"]:
		return true
	return IslandEconomy.expanded(abode.session.state) and IslandEconomy.supply_data().islands.has(id) and abode.session.state.era_id >= int(IslandEconomy.supply_data().islands[id].era)

func _refresh_destinations() -> void:
	var visible_ids: Array[String] = []
	var entries: Array = []
	for id in IslandProgression.NAMES:
		if not _world_visible(id): continue
		visible_ids.append(id)
		if id != "home": _ensure_art(id)
		entries.append({"id":id,"name":IslandProgression.NAMES[id],"status":_island_status(id),"texture":abode.TERRAIN if id == "home" else bodies[id].texture})
	destination_ids = visible_ids
	selector.refresh(entries,current,"%s · %s" % [IslandProgression.NAMES[current],_island_status(current)])
