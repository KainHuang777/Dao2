extends RefCounted
## One container owns management tabs, contextual stock and the active page.
var abode: Node
var panel: PanelContainer
var column: VBoxContainer
var body: HBoxContainer
var stock: Control
var pages: Control
var stock_content: Control
var stock_title: Label
var active := false
var _parents := {}
var _styles := {}
var _flat := StyleBoxEmpty.new()

func _init(scene: Node) -> void:
	abode = scene
	panel = PanelContainer.new()
	panel.name = "ManagementWorkbench"
	panel.add_theme_stylebox_override("panel", UiMaterial.compact_scroll_shell())
	abode.hud.add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	stock = VBoxContainer.new()
	stock.custom_minimum_size.x = 236
	body.add_child(stock)
	stock_title = Label.new()
	stock_title.add_theme_font_size_override("font_size", 16)
	stock_title.add_theme_color_override("font_color", UiMaterial.INK)
	stock.add_child(stock_title)
	stock_content = Control.new()
	stock_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stock.add_child(stock_content)
	pages = Control.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(pages)
	panel.hide()
	pages.resized.connect(_fit_page)
	stock_content.resized.connect(_fit_stock)

func _move(control: Control, host: Node) -> void:
	if control.get_parent() == host: return
	if not _parents.has(control):
		_parents[control] = control.get_parent()
		if control is PanelContainer: _styles[control] = control.get_theme_stylebox("panel")
	control.reparent(host, false)

func apply(enabled: bool, bounds: Rect2, wide: bool, show_stock: bool) -> void:
	if not enabled and not active: return
	active = enabled
	panel.visible = enabled
	if not enabled:
		for control in _parents:
			if control.get_parent() != _parents[control]: control.reparent(_parents[control], false)
			if _styles.has(control): control.add_theme_stylebox_override("panel", _styles[control])
		abode.building_catalog.set_embedded(false)
		for child in [abode.feature_navigation.island_panel, abode.feature_navigation.manufacturing_panel, abode.feature_navigation.transport_panel]: child.set_embedded(false)
		return
	panel.position = bounds.position
	panel.size = bounds.size
	var nav = abode.feature_navigation
	_move(nav.bar, column)
	column.move_child(nav.bar, 0)
	nav.bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.bar.custom_minimum_size.y = 44
	nav.bar.add_theme_stylebox_override("panel", _flat)
	stock.visible = wide and show_stock and not nav.island_flow.visible
	stock_title.text = "祖島可用庫存" if nav.page == "buildings" else "當地與付款庫存"
	for resource_panel in [abode.resource_ribbon, nav.shell.context_paper]:
		_move(resource_panel, stock_content)
		resource_panel.add_theme_stylebox_override("panel", _flat)
	for child in [abode.building_catalog, nav.island_panel, nav.manufacturing_panel, nav.transport_panel]:
		_move(child, pages)
		child.set_embedded(true)
	_move(nav.island_flow, pages)
	# Commands can open/close details within one frame. Supply the container's
	# allocation immediately so feedback does not read yesterday's short layout.
	# Normal container sorting refines the same allocation on the next frame.
	var inner: Vector2 = bounds.size - panel.get_theme_stylebox("panel").get_minimum_size()
	var stock_width: float = stock.get_combined_minimum_size().x + body.get_theme_constant("separation") if stock.visible else 0.0
	pages.size = Vector2(maxf(80, inner.x - stock_width), maxf(80, inner.y - nav.bar.get_combined_minimum_size().y - column.get_theme_constant("separation")))
	_fit_page()
	_fit_stock()

func _fit_page() -> void:
	if not active: return
	var nav = abode.feature_navigation
	# Legacy realm outposts retain their existing modal owner and global bounds.
	if nav.page == "outposts" and nav._legacy_outposts:
		nav.layout_page(Rect2(pages.global_position, pages.size))
	else:
		nav.layout_page(Rect2(Vector2.ZERO, pages.size))

func _fit_stock() -> void:
	if not active: return
	for child in stock_content.get_children():
		child.position = Vector2.ZERO
		child.size = stock_content.size
