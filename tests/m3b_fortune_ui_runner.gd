extends SceneTree

const FortuneModalScript = preload("res://src/presentation/fortune_modal.gd")
const LivingAbodeScene = preload("res://scenes/living_abode.tscn")

func _init() -> void:
	_run()

func _run() -> void:
	print("\n--- Running M3-B Fortune UI Runner ---")
	test_modal_structure()
	test_modal_refresh_and_options()
	test_modal_signals()
	test_modal_responsive_layouts()
	await test_living_abode_integration()
	print("PASS: M3-B fortune UI structure, options, signals, layouts, and living_abode integration.\n")
	quit(0)

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		push_error("ASSERTION FAILED: " + msg)
		print("FAIL: " + msg)
		quit(1)

func test_modal_structure() -> void:
	print("Testing FortuneModal node creation and structure...")
	var modal: Control = FortuneModalScript.new()
	root.add_child(modal)

	var title_lbl: Label = modal.get("_title_label")
	_assert(title_lbl != null, "_title_label must exist")
	_assert(title_lbl.text.contains("機緣奇遇"), "Title should mention 機緣奇遇")

	var enc_title: Label = modal.get("_encounter_title")
	_assert(enc_title != null, "_encounter_title must exist")

	var options_box: VBoxContainer = modal.get("_options_container")
	_assert(options_box != null, "_options_container must exist")

	var trig_btn: Button = modal.get("_trigger_btn")
	_assert(trig_btn != null, "_trigger_btn must exist")

	modal.queue_free()

func test_modal_refresh_and_options() -> void:
	print("Testing FortuneModal refresh with empty and pending encounter views...")
	var modal: Control = FortuneModalScript.new()
	root.add_child(modal)

	# 1. Empty view
	var empty_view := {
		"fortune": {
			"cooldown_remaining": 600.0,
			"has_pending": false,
			"pending_encounter": {},
			"encounter_history_count": 2,
			"total_fortunes_claimed": 1,
			"max_per_hour": 2
		},
		"resources": {}
	}
	modal.refresh(empty_view)
	var trig_btn: Button = modal.get("_trigger_btn")
	_assert(trig_btn.visible, "Trigger button must be visible when no pending encounter")
	_assert(trig_btn.disabled, "Trigger button must be disabled when on cooldown")

	# 2. View with pending encounter
	var pending_view := {
		"fortune": {
			"cooldown_remaining": 1200.0,
			"has_pending": true,
			"pending_encounter": {
				"id": "enc_ancient_cave",
				"title": "古仙殘府遺址",
				"desc": "後山雲霧散去，露出一處前朝古仙遺留的殘破洞府。",
				"options": [
					{"text": "破解外圍禁制", "desc": "謹慎收取洞府外圍資糧", "costs": {}},
					{"text": "強行破陣", "desc": "消耗 100 靈石破陣", "costs": {"money": 100}}
				]
			},
			"encounter_history_count": 3,
			"total_fortunes_claimed": 1,
			"max_per_hour": 2
		},
		"resources": {
			"money": {"value": 50.0}
		}
	}
	modal.refresh(pending_view)
	_assert(not trig_btn.visible, "Trigger button must be hidden when pending encounter exists")
	var options_box: VBoxContainer = modal.get("_options_container")
	_assert(options_box.get_child_count() == 2, "Must create 2 option buttons")

	var btn0: Button = options_box.get_child(0) as Button
	var btn1: Button = options_box.get_child(1) as Button
	_assert(not btn0.disabled, "Option 0 has no cost and should be enabled")
	_assert(btn1.disabled, "Option 1 costs 100 money but player only has 50 -> must be disabled")

	modal.queue_free()

func test_modal_signals() -> void:
	print("Testing FortuneModal signals for trigger, resolve, and close...")
	var modal: Control = FortuneModalScript.new()
	root.add_child(modal)

	var trigger_fired := [false]
	var resolve_arg := [-1]
	var close_fired := [false]

	modal.trigger_requested.connect(func(): trigger_fired[0] = true)
	modal.resolve_requested.connect(func(idx: int): resolve_arg[0] = idx)
	modal.close_requested.connect(func(): close_fired[0] = true)

	# Test trigger signal
	var trig_btn: Button = modal.get("_trigger_btn")
	trig_btn.pressed.emit()
	_assert(trigger_fired[0], "trigger_requested signal must fire")

	# Test resolve signal via option button
	var pending_view := {
		"fortune": {
			"has_pending": true,
			"pending_encounter": {
				"title": "測試奇遇",
				"options": [{"text": "選項一", "costs": {}}]
			}
		},
		"resources": {}
	}
	modal.refresh(pending_view)
	var options_box: VBoxContainer = modal.get("_options_container")
	var opt_btn: Button = options_box.get_child(0) as Button
	opt_btn.pressed.emit()
	_assert(resolve_arg[0] == 0, "resolve_requested signal must fire with option index 0")

	# Test close signal
	var close_btn: Button = modal.get("_close_button")
	close_btn.pressed.emit()
	_assert(close_fired[0], "close_requested signal must fire")

	modal.queue_free()

func test_modal_responsive_layouts() -> void:
	print("Testing FortuneModal responsive layout bounds...")
	var modal: Control = FortuneModalScript.new()
	root.add_child(modal)

	# 1. Desktop wide bounds
	var wide_rect := Rect2(370, 100, 540, 520)
	modal.set_layout_bounds(wide_rect)
	_assert(modal.position == wide_rect.position, "Position must match wide bounds")
	_assert(modal.size == wide_rect.size, "Size must match wide bounds")

	# 2. Compact mobile landscape bounds
	var compact_rect := Rect2(12, 12, 755, 336)
	modal.set_layout_bounds(compact_rect)
	_assert(modal.position == compact_rect.position, "Position must match compact bounds")
	_assert(modal.size == compact_rect.size, "Size must match compact bounds")

	modal.queue_free()

func test_living_abode_integration() -> void:
	print("Testing LivingAbode scene integration with FortuneModal...")
	var abode = LivingAbodeScene.instantiate()
	root.add_child(abode)
	await process_frame

	_assert(abode.fortune_modal != null, "LivingAbode must have instantiated fortune_modal")
	_assert(not abode.fortune_modal.visible, "fortune_modal should be initially hidden")

	# Open fortune modal via _toggle_fortune_modal
	abode._toggle_fortune_modal()
	_assert(abode.fortune_modal.visible, "fortune_modal must be visible after toggle")

	# Close fortune modal
	abode._on_fortune_closed()
	_assert(not abode.fortune_modal.visible, "fortune_modal must be hidden after closed")

	abode.queue_free()
