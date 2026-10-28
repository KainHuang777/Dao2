extends "res://tools/imm0_samples.gd"
## User-directed revision: island thumbnail list, square item badges; fortune stays original.
var island_scroll: ScrollContainer
var island_hits: Array[Button] = []
var squares: Array[Control] = []

func _init() -> void:
	OUT = "res://.test-output/imm0-r2"
	selected_samples = ["home-normal", "manufacturing-normal", "manufacturing-shortage"]
	super._init()

func apply_candidate(sample: String, vp: Vector2i) -> void:
	island_hits.clear(); squares.clear()
	if sample.begins_with("home"):
		island_list(vp.y < 500)
	elif sample.begins_with("manufacturing"):
		super.candidate_manufacturing(vp.y < 500)
		var panel = abode.feature_navigation.manufacturing_panel
		for card in panel.cards.values():
			for tile in card.tiles.values(): square_tile(tile,vp.y < 500)
			square_tile(card.output_tile,vp.y < 500)
	# No fortune override: retain the original official layout.

func island_list(short: bool) -> void:
	abode.island_world.rail.hide()
	var margin := MarginContainer.new()
	margin.name = "IslandThumbnailListStudy"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abode.hud.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",16)
	margin.add_theme_constant_override("margin_right",16)
	margin.add_theme_constant_override("margin_top",82 if short else 92)
	margin.add_theme_constant_override("margin_bottom",int(abode.hud.size.y-abode.toolbar.position.y+12))
	var align := HBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(align)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.add_child(spacer)
	var paper := PanelContainer.new()
	paper.custom_minimum_size.x = 258 if short else 280
	if not short: paper.custom_minimum_size.y = 478
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL if short else Control.SIZE_SHRINK_CENTER
	paper.add_theme_stylebox_override("panel",UiMaterial.compact_scroll_shell() if short else UiMaterial.scroll_shell())
	align.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	paper.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Label.new()
	title.text = "選擇空島"
	title.add_theme_font_override("font",UiTypography.emphasis_font())
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",UiMaterial.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	if short:
		var close := CloseSeal.new()
		heading.add_child(close)
		close.pressed.connect(func(): margin.hide())
	island_scroll = ScrollContainer.new()
	island_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	island_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(island_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",6)
	island_scroll.add_child(list)
	var art_paths := {"home":"res://assets/abode/fx3art1/terrain.png","wood":"res://assets/abode/res1c3/wood_body.png","ore":"res://assets/abode/res1c3/ore_body.png","herb":"res://assets/abode/res1d2/herb_body.png"}
	for id in ["home","wood","ore","herb"]:
		var hit := Button.new()
		hit.name = "Select_"+id
		hit.custom_minimum_size = Vector2(220,80 if short else 92)
		UiMaterial.apply_scroll_button(hit,id == "home")
		hit.tooltip_text = IslandProgression.NAMES[id]+" · 前往此島"
		hit.pressed.connect(func(): abode.island_world.enter(id))
		list.add_child(hit)
		island_hits.append(hit)
		var inset := MarginContainer.new()
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit.add_child(inset)
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]: inset.add_theme_constant_override("margin_"+side,8)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation",12)
		inset.add_child(row)
		var art := UiIllustration.new()
		art.texture = load(art_paths[id])
		art.custom_minimum_size = Vector2(88,60 if short else 72)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art)
		var label := Label.new()
		label.text = IslandProgression.NAMES[id]+(" · 當前" if id == "home" else "")
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",GraphicAction.JADE if id == "home" else UiMaterial.INK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)

func square_tile(tile: Control, short: bool) -> void:
	var edge := 56 if short else 68
	# Reuse the actual item, tooltip and quantity. No extra text row or caption panel.
	tile.custom_minimum_size = Vector2(edge,edge)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var old := tile.get_child(0)
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(edge,edge)
	tile.add_child(canvas)
	tile.icon.reparent(canvas)
	tile.quantity.reparent(canvas)
	old.hide() # Existing View refreshes still update the hidden caption reference.
	tile.style.content_margin_left = 0; tile.style.content_margin_right = 0
	tile.style.content_margin_top = 0; tile.style.content_margin_bottom = 0
	tile.style.set_corner_radius_all(8)
	tile.style.set_border_width_all(2)
	tile.style.shadow_size = 2
	tile.icon.custom_minimum_size = Vector2.ZERO
	tile.icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tile.icon.offset_left = 5; tile.icon.offset_right = -5
	tile.icon.offset_top = 3; tile.icon.offset_bottom = -5
	tile.quantity.custom_minimum_size = Vector2.ZERO
	tile.quantity.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tile.quantity.offset_left = 2; tile.quantity.offset_right = -4
	tile.quantity.offset_top = 2; tile.quantity.offset_bottom = -1
	tile.quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tile.quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	tile.quantity.add_theme_font_override("font",UiTypography.emphasis_font())
	tile.quantity.add_theme_font_size_override("font_size",18)
	tile.quantity.add_theme_color_override("font_color",Color("a23e32") if tile.shortage else Color("ffffff"))
	tile.quantity.add_theme_color_override("font_outline_color",Color("f7efdf") if tile.shortage else Color("24372f"))
	tile.quantity.add_theme_constant_override("outline_size",5 if tile.shortage else 4)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	squares.append(tile)

func capture(sample: String, variant: String, vp: Vector2i) -> void:
	await super.capture(sample,variant,vp)
	if variant != "candidate": return
	for tile in squares:
		if absf(tile.size.x-tile.size.y)>1:
			failed=true; push_error("IMM0-R2 non-square material: "+str(tile.size))
	if sample.begins_with("home"):
		for hit in island_hits:
			island_scroll.ensure_control_visible(hit)
			await frames()
			if not island_scroll.get_global_rect().encloses(hit.get_global_rect()) or hit.size.y < 80:
				failed=true; push_error("IMM0-R2 island row not reachable")
		island_scroll.scroll_vertical = 0
