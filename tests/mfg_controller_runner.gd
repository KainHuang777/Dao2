extends SceneTree
## MFG-1: ProductionController payload / ratio / single-meaning action checks.

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _init() -> void:
	var PC = load("res://src/presentation/production_controller.gd")
	# Mode -> payload matches the legacy craft/switch payload.
	var single: Dictionary = PC.work_payload("home", "liquid", PC.Mode.SINGLE, 7, {})
	check(single.count == 1 and single.repeat == false, "single ignores count")
	var counted: Dictionary = PC.work_payload("home", "liquid", PC.Mode.COUNT, 7, {})
	check(counted.count == 7 and counted.repeat == false, "count mode")
	var repeating: Dictionary = PC.work_payload("home", "liquid", PC.Mode.REPEAT, 7, {})
	check(repeating.count == 1 and repeating.repeat == true, "repeat mode")
	check(PC.work_payload("home", "x", PC.Mode.COUNT, 0, {}).count == 1, "count clamps low")
	check(PC.start_command({}) == "craft" and PC.start_command({"recipe_id": "a"}) == "switch_processing", "start command")
	# Ratio -> absolute reserve (floor, strings, send-time stock).
	var inputs := {"wood": {"available": 10.0}, "ore": {"available": 7.0}}
	var reserves: Dictionary = PC.reserves_from_ratio(inputs, {"wood": 50, "ore": 50})
	check(reserves.wood == "5.0" and reserves.ore == "3.0", "ratio floor: %s" % [reserves])
	check(PC.reserves_from_ratio(inputs, {}).wood == "0.0", "default ratio 0")
	check(PC.reserves_from_ratio(inputs, {"wood": 250}).wood == "10.0", "ratio clamps to 100")
	check(PC.ratio_blocks_start({"wood": 100}) and not PC.ratio_blocks_start({"wood": 75}), "100% blocks")
	# Single-meaning actions equal the old _card_action payloads.
	var info := {"island": "home", "reason": ""}
	var start: Dictionary = PC.start_action({}, info, "liquid")
	check(start.command == "craft" and start.payload.count == 1 and start.payload.repeat == false and start.payload.island_id == "home", "start payload")
	check(PC.start_action({"recipe_id": "a"}, info, "liquid").command == "", "start blocked while busy")
	check(PC.start_action({}, {"island": "home", "reason": "OUTPUT_FULL"}, "liquid").command == "", "start blocked by reason")
	var running := {"recipe_id": "liquid", "remaining": 5, "batches": 2, "repeat": false}
	check(PC.stop_action(running, "home").command == "stop_processing", "stop running")
	var last_batch := {"recipe_id": "liquid", "remaining": 5, "batches": 0, "repeat": false}
	check(PC.finishing(last_batch) and PC.stop_action(last_batch, "home").command == "", "finishing has no stop")
	check(PC.stop_action({}, "home").command == "", "stop idle")
	# Mode preference lives in memory only; repeat pref flows into start.
	var ctl = PC.new()
	check(ctl.pref("liquid").mode == PC.Mode.SINGLE, "default pref single")
	check(ctl.cycle_mode("liquid") == PC.Mode.REPEAT and ctl.cycle_mode("liquid") == PC.Mode.SINGLE, "cycle mode")
	ctl.set_pref("liquid", PC.Mode.REPEAT)
	check(PC.start_action({}, info, "liquid", ctl.pref("liquid")).payload.repeat == true, "pref repeat -> payload")
	ctl.set_pref("liquid", PC.Mode.COUNT, 5)
	check(PC.start_action({}, info, "liquid", ctl.pref("liquid")).payload.count == 5, "pref count -> payload")
	# MFG-0 icons exist and draw into textures.
	var UiIconScript = load("res://src/presentation/ui_icon.gd")
	for kind in [UiIconScript.Kind.PLAY, UiIconScript.Kind.STOP, UiIconScript.Kind.INFINITY, UiIconScript.Kind.BATCH]:
		var tex = UiIconScript.create_texture(kind, 24)
		var img: Image = tex.get_image()
		var painted := false
		for y in 24:
			for x in 24:
				if img.get_pixel(x, y).a > 0.0:
					painted = true
		check(painted, "icon texture painted kind %d" % kind)
	if failures.is_empty():
		print("PASS: MFG-1 controller and MFG-0 icons.")
		quit(0)
	else:
		for f in failures:
			push_error(f)
		quit(1)
