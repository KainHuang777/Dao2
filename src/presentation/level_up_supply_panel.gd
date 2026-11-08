extends PanelContainer
## Uses the shell tool overlay for modality, responsive bounds and CloseSeal.
const Costs = preload("res://src/presentation/cost_strip.gd")
const Icon = preload("res://src/presentation/resource_icon.gd")
const RECIPES := ["spirit_timber", "bronze_essence"]

signal recipe_requested(id: String)
signal level_up_requested()

var heading: Label
var costs: VBoxContainer
var recipe_buttons := {}
var level_up: Button

static func offers_help(view: Dictionary) -> bool:
	var missing: Dictionary = view.get("level_up_missing_resources", {})
	return int(view.get("era_id", 0)) == 2 and (missing.has("spirit_timber") or missing.has("bronze_essence"))

func _ready() -> void:
	theme = UiTypography.create_theme()
	add_theme_stylebox_override("panel", UiMaterial.hud_paper())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	heading = Label.new()
	heading.add_theme_font_override("font", UiTypography.emphasis_font())
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", UiMaterial.INK)
	column.add_child(heading)
	costs = Costs.new()
	column.add_child(costs)
	var actions := HFlowContainer.new()
	column.add_child(actions)
	for id in RECIPES:
		recipe_buttons[id] = _add_button(actions, "製造" + Icon.get_resource_name(id), func(): recipe_requested.emit(id))
	level_up = _add_button(actions, "修為晉階", func(): level_up_requested.emit())

func refresh(view: Dictionary, names: Dictionary) -> void:
	heading.text = "%s %d 層 → %d 層" % [String(view.era.name), int(view.level), int(view.level) + 1]
	var amounts: Dictionary = view.get("level_up_costs", {})
	var available := {}
	for id in amounts:
		available[id] = view.resources[id].value.to_float()
	var note := Costs.shortage_text(amounts, available, names, "尚缺")
	var research := String(view.get("cultivation_research", ""))
	if not research.is_empty():
		note += "\n尚需完成工藝研習 " + research
	costs.show_costs(amounts, names, available, {}, "祖島晉階材料", note)
	var missing: Dictionary = view.get("level_up_missing_resources", {})
	for id in recipe_buttons:
		recipe_buttons[id].visible = missing.has(id)
		var producer: String = IslandProgression.RECIPES.find_key(id)
		recipe_buttons[id].text = "開拓" + IslandProgression.NAMES[producer] if view.economy.is_empty() else "製造" + Icon.get_resource_name(id)
	level_up.visible = bool(view.get("can_level_up", false))

func set_layout_bounds(bounds: Rect2) -> void:
	size = Vector2(minf(520, bounds.size.x), minf(300, bounds.size.y))
	position = Vector2((get_viewport_rect().size.x - size.x) * 0.5, bounds.position.y)

func _add_button(parent: Control, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 44
	UiMaterial.apply_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
