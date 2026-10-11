extends SceneTree
var failures := 0
var checks := 0

func _init() -> void:
	_run()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var script = load("res://src/abode/living_abode.gd")
	script.save_dir_override = "user://gather-highlight-isolated"
	SaveSlots.new(FileStorageAdapter.new(script.save_dir_override)).reset()
	var abode = load("res://scenes/living_abode.tscn").instantiate()
	root.add_child(abode)
	await process_frame

	# 設置為茅屋 2 階、木屋未建、金錢不足的狀態
	abode.session.state.era_id = 1
	abode.session.state.buildings["hut"] = 2
	abode.session.state.buildings["wooden_house"] = 0
	abode.session.state.resources["lingli"].value = AmountCompat.from_number(90.0)
	abode.session.state.resources["money"].value = AmountCompat.zero()
	abode.session.state.resources["money"].unlocked = true
	abode.session.state.revision += 1
	abode._refresh_hud()
	await process_frame

	var obj_btn: Button = abode.objective_button
	check(obj_btn.text.contains("點擊【金錢】採集按鈕"), "objective button guides money gather: %s" % obj_btn.text)
	check(abode.hint.text.contains("點擊金錢旁的「採集」"), "hint text guides money gather: %s" % abode.hint.text)
	check(abode.building_catalog._highlighted_resources.has("money"), "building catalog highlights money button")
	check(abode.building_catalog._gather_tweens.has("money"), "money gather tween is running")

	# 點擊「前往目標」按鈕測試：應自動展開資源欄（若關閉）
	abode._hud_controller._set_resource_display_mode(0)
	check(abode.resource_display_mode == 0, "resource mode closed")
	abode._hud_controller._open_current_goal()
	check(abode.resource_display_mode == 1, "open goal auto expands resource ribbon to mode 1")

	# 模擬累積金錢至足額（20 建造木屋）
	abode.session.state.resources["money"].value = AmountCompat.from_number(20.0)
	abode.session.state.revision += 1
	abode._refresh_hud()
	await process_frame

	check(abode.building_catalog._highlighted_resources.is_empty(), "highlight cleared after enough money gathered")
	check(not abode.building_catalog._gather_tweens.has("money"), "money gather tween stopped")
	check(obj_btn.text == "下一步：建造【木屋】", "objective button updates to build wooden house: %s" % obj_btn.text)
	check(abode.hint.text.contains("選擇【木屋】並建造"), "hint text updates to build wooden house: %s" % abode.hint.text)

	# 建造木屋後（木屋 1 階），給予充足金錢（100），目標應變為「將木屋升至 2 階」
	abode.session.state.buildings["wooden_house"] = 1
	abode.session.state.resources["money"].value = AmountCompat.from_number(100.0)
	abode.session.state.revision += 1
	abode._refresh_hud()
	await process_frame
	check(obj_btn.text == "下一步：將木屋升至 2 階", "objective button updates to upgrade wooden house to level 2: %s" % obj_btn.text)

	print("GATHER GUIDANCE HIGHLIGHT: %d checks, %d failures" % [checks, failures])
	abode.queue_free()
	quit(0 if failures == 0 else 1)
