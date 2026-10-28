extends RefCounted
## Shared IMM-0 study only: replace context text with icon inventory, preserving View values.
const Icon = preload("res://src/presentation/resource_icon.gd")
const Numbers = preload("res://src/utils/number_formatter.gd")
var cells: Array[Button] = []
var scroll: ScrollContainer
var detail: Label
var meter: ProgressBar
var detail_icon: Control
var first := true

func install(abode: Node) -> void:
	var shell = abode.feature_navigation.shell
	var paper: PanelContainer = shell.context_paper
	for child in paper.get_children(): child.hide()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	paper.add_child(column)
	var heading := Label.new()
	heading.text = "庫存"
	heading.add_theme_font_override("font",UiTypography.emphasis_font())
	heading.add_theme_font_size_override("font_size",20)
	heading.add_theme_color_override("font_color",UiMaterial.INK)
	column.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var groups := VBoxContainer.new()
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("separation",12)
	scroll.add_child(groups)
	var readout := HBoxContainer.new()
	readout.add_theme_constant_override("separation",8)
	column.add_child(readout)
	detail_icon = Icon.new()
	detail_icon.custom_minimum_size = Vector2(36,36)
	readout.add_child(detail_icon)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("font_size",16)
	detail.add_theme_color_override("font_color",UiMaterial.INK)
	readout.add_child(detail)
	meter = ProgressBar.new()
	meter.custom_minimum_size.y = 5
	meter.show_percentage = false
	meter.add_theme_stylebox_override("background",UiMaterial.rounded(Color("d6d2c0"),2))
	meter.add_theme_stylebox_override("fill",UiMaterial.rounded(GraphicAction.JADE,2))
	column.add_child(meter)
	var view: Dictionary = abode.session.get_view()
	var nav = abode.feature_navigation
	var route: String = nav.page
	var islands: Array = ["home","wood","ore","herb"]
	if route == "outposts": islands = [nav.island_panel.island]
	elif route == "transport":
		if nav.transport_panel.selected_route.is_empty(): islands = [nav.transport_panel.island]
		else:
			var ends: Array = nav.transport_panel._routes()[nav.transport_panel.selected_route]
			islands = [ends[0],ends[1]]
	elif route == "manufacturing":
		if not nav.manufacturing_panel.selected_recipe.is_empty(): islands = [nav.manufacturing_panel.island]
		elif not nav.manufacturing_panel.island_filter.is_empty(): islands = [nav.manufacturing_panel.island_filter]
	var context_islands := islands.duplicate()
	if not "home" in islands: islands.append("home") # Preserve separate home payment inventory.
	for island in islands:
		var stock: Dictionary = view.get("economy",{}).get("inventory",{}).get(island,{})
		if stock.is_empty(): continue
		var label := Label.new()
		label.text = IslandProgression.NAMES.get(island,island) + (" · 工程材料" if island == "home" and not "home" in context_islands else "")
		label.add_theme_font_size_override("font_size",16)
		label.add_theme_color_override("font_color",GraphicAction.JADE)
		groups.add_child(label)
		var grid := GridContainer.new()
		grid.columns = maxi(1,floori((paper.size.x-34.0)/98.0))
		grid.add_theme_constant_override("h_separation",10)
		grid.add_theme_constant_override("v_separation",10)
		groups.add_child(grid)
		var ordered: Array = ["lingli","money","wood","spirit_grass_low","stone_low","black_copper"]
		for id in stock:
			if not id in ordered: ordered.append(id)
		for id in ordered:
			if not stock.has(id): continue
			if island == "home" and not "home" in context_islands and not id in ["wood","stone_low","spirit_timber","bronze_essence","lingli"]: continue
			var slot: Dictionary = stock[id]
			var rates: Dictionary = view.get("manufacturing",{}).get("islands",{}).get(island,{}).get("rates",{})
			if float(slot.get("available",0)) == 0 and float(slot.get("reserved",0)) == 0 and not rates.has(id) and not (island == "home" and view.resources.get(id,{}).get("visible",false)): continue
			var cap: Variant = view.resources.get(id,{}).get("cap","—") if island == "home" else view.get("manufacturing",{}).get("islands",{}).get(island,{}).get("capacity","—")
			add_item(grid,island,id,slot,cap)
		if grid.get_child_count() == 0:
			label.text += " · 尚無庫存"
	# Real positive cargo only; zero routes do not become text noise.
	var transit_grid: GridContainer
	for route_id in view.get("economy",{}).get("trips",{}):
		var trip: Dictionary = view.economy.trips[route_id]
		var ends: Array = nav.transport_panel._routes().get(route_id,[])
		if ends.size()<3 or float(trip.get("cargo",0))<=0 or not (ends[0] in context_islands or ends[1] in context_islands): continue
		if transit_grid == null:
			var heading_transit := Label.new()
			heading_transit.text = "在途"
			heading_transit.add_theme_color_override("font_color",GraphicAction.COOL)
			groups.add_child(heading_transit)
			transit_grid = GridContainer.new()
			transit_grid.columns = maxi(1,floori((paper.size.x-34.0)/98.0))
			transit_grid.add_theme_constant_override("h_separation",10)
			transit_grid.add_theme_constant_override("v_separation",10)
			groups.add_child(transit_grid)
		add_item(transit_grid,str(ends[0]),str(ends[2]),{"available":float(trip.cargo),"reserved":0},"—")
		cells[-1].tooltip_text = "%s → %s\n%s：在途 %s · %s秒" % [IslandProgression.NAMES.get(ends[0],ends[0]),IslandProgression.NAMES.get(ends[1],ends[1]),Icon.get_resource_name(ends[2]),Numbers.format_amount(trip.cargo),str(trip.get("remaining",0))]

func add_item(grid: GridContainer, island: String, id: String, slot: Dictionary, cap: Variant) -> void:
	var hit := Button.new()
	hit.custom_minimum_size = Vector2(88,88)
	hit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hit.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var s := UiMaterial.rounded(Color("e7e4d4"),8)
	s.border_color = Color("89917d")
	s.set_border_width_all(2)
	for state in ["normal","hover","pressed","focus"]:
		var style: StyleBoxFlat = s.duplicate()
		if state != "normal": style.border_color = GraphicAction.JADE; style.bg_color = Color("dbe5d8")
		hit.add_theme_stylebox_override(state,style)
	var source: String = IslandProgression.NAMES.get(island,island)
	hit.tooltip_text = "%s · %s\n可用 %s／容量 %s\n容量預留 %s" % [Icon.get_resource_name(id),source,Numbers.format_amount(slot.available),Numbers.format_amount(cap),Numbers.format_amount(slot.reserved)]
	hit.pressed.connect(func(): select(id,slot,cap))
	grid.add_child(hit)
	cells.append(hit)
	var art := Icon.new()
	art.resource_id = id
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 7; art.offset_right = -7; art.offset_top = 5; art.offset_bottom = -5
	var count := Label.new()
	count.text = Numbers.format_amount(slot.available)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_font_override("font",UiTypography.emphasis_font())
	count.add_theme_font_size_override("font_size",20)
	count.add_theme_color_override("font_color",Color.WHITE)
	count.add_theme_color_override("font_outline_color",Color("24372f"))
	count.add_theme_constant_override("outline_size",5)
	hit.add_child(count)
	count.offset_right = -5; count.offset_bottom = -3
	if float(slot.reserved) > 0:
		var lock := UiIcon.new()
		lock.kind = UiIcon.Kind.HOURGLASS
		lock.icon_size = 18
		lock.tint = GraphicAction.COOL
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit.add_child(lock)
	if first:
		select(id,slot,cap)
		first=false

func select(id: String, slot: Dictionary, cap: Variant) -> void:
	detail_icon.resource_id = id
	detail_icon.queue_redraw()
	detail.text = "%s\n%s／%s" % [Icon.get_resource_name(id),Numbers.format_amount(slot.available),Numbers.format_amount(cap)]
	detail.tooltip_text = "可用／總容量；容量預留 %s" % Numbers.format_amount(slot.reserved)
	meter.visible = str(cap).is_valid_float() and float(cap)>0
	if meter.visible:
		meter.max_value = float(cap)
		meter.value = minf(float(cap),float(slot.available)+float(slot.reserved))
		meter.tooltip_text = "庫容使用：可用＋容量預留"
