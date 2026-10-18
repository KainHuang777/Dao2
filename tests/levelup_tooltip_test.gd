extends SceneTree

const ResourceIconScript = preload("res://src/presentation/resource_icon.gd")
const CultivationLevelUpButtonScript = preload("res://src/presentation/cultivation_level_up_button.gd")

func _init() -> void:
	print("Starting levelup tooltip & resource Chinese verification...")
	
	# 1. 驗證資源繁體中文名稱
	assert(ResourceIconScript.get_resource_name("spirit_timber") == "靈材", "spirit_timber 應為 靈材")
	assert(ResourceIconScript.get_resource_name("bronze_essence") == "銅精", "bronze_essence 應為 銅精")
	assert(ResourceIconScript.get_resource_name("liquid") == "丹液", "liquid 應為 丹液")
	assert(ResourceIconScript.get_resource_name("stone_mid") == "中品靈石", "stone_mid 應為 中品靈石")
	assert(ResourceIconScript.get_resource_name("lingli") == "靈氣", "lingli 應為 靈氣")
	print("PASS: Resource Chinese names verified.")

	# 2. 驗證數值格式化，避免長浮點數
	var fmt_float := ResourceIconScript.format_amount(136.425019707314)
	assert(fmt_float == "136", "136.425... 應格式化為 136，當前: " + fmt_float)
	var fmt_int := ResourceIconScript.format_amount(20.0)
	assert(fmt_int == "20", "20.0 應格式化為 20，當前: " + fmt_int)
	print("PASS: Amount formatting verified.")

	# 3. 驗證 CultivationLevelUpButton 與 Custom Tooltip
	var btn := CultivationLevelUpButtonScript.new()
	var costs := {
		"lingli": 200,
		"spirit_timber": 20,
		"bronze_essence": 10
	}
	var missing := {
		"lingli": {"available": 136.425019707314, "required": 200},
		"spirit_timber": {"available": 0, "required": 20},
		"bronze_essence": {"available": 0, "required": 10}
	}
	btn.update_tooltip_data(costs, missing, false, false)
	
	var tooltip_obj = btn._make_custom_tooltip("")
	assert(tooltip_obj != null, "Custom tooltip 應成功生成")
	assert(tooltip_obj is PanelContainer, "Custom tooltip 應為 PanelContainer")
	
	var vbox: VBoxContainer = tooltip_obj.get_child(0)
	assert(vbox != null, "應包含 VBoxContainer")
	
	# 檢查圖標與行數
	var row_count := 0
	var found_icons := 0
	for child in vbox.get_children():
		if child is HBoxContainer:
			row_count += 1
			for sub in child.get_children():
				if sub is TextureRect and sub.texture != null:
					found_icons += 1
	
	assert(row_count == 3, "應有 3 條需求資源行，當前: %d" % row_count)
	assert(found_icons == 3, "3 條需求資源行都應持有現有 hand-painted TextureRect，當前: %d" % found_icons)
	print("PASS: Custom tooltip UI with hand-painted icons verified (row_count=%d, found_icons=%d)." % [row_count, found_icons])

	tooltip_obj.free()
	btn.free()
	print("ALL LEVELUP TOOLTIP CHECKS PASSED.")
	quit(0)
