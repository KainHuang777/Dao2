extends "res://tools/imm0_r2_samples.gd"
## Shared resource-pane study plus representative duplicate-route captures.
var stock_study: RefCounted

func _init() -> void:
	OUT = "res://.test-output/imm0-r3"
	selected_samples = ["manufacturing-normal","manufacturing-shortage","manufacturing-inventory-drawer","transport-inventory","outposts-inventory"]
	# The inherited _init would reset R2 configuration.
	run.call_deferred()

func prepare(sample: String,vp: Vector2i) -> void:
	await super.prepare("manufacturing-shortage" if sample == "manufacturing-shortage" else "manufacturing-normal",vp)
	if sample == "transport-inventory": abode.feature_navigation.open("transport")
	if sample == "outposts-inventory": abode.feature_navigation.open("outposts")
	abode._layout_for_size(Vector2(vp))
	if sample == "manufacturing-inventory-drawer":
		abode.feature_navigation.shell.toggle_overlay("resources")
	await frames()

func apply_candidate(sample: String,vp: Vector2i) -> void:
	island_hits.clear()
	squares.clear()
	if sample.begins_with("manufacturing"): super.apply_candidate(sample,vp)
	stock_study = preload("res://tools/imm0_inventory_study.gd").new()
	stock_study.install(abode)

func capture(sample: String,variant: String,vp: Vector2i) -> void:
	await super.capture(sample,variant,vp)
	if variant != "candidate": return
	for cell in stock_study.cells:
		if absf(cell.size.x-cell.size.y)>1 or cell.size.x<44:
			failed=true; push_error("IMM0-R3 inventory item geometry")
