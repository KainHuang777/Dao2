class_name RuntimeInspector
extends RefCounted
## Pure diagnostic inspector for runtime GameState and GameSession.
## Evaluates production rate breakdowns and performs comprehensive integrity checks.
## Read-only analysis; does not mutate state or trigger side effects.

const EXPECTED_BEAST_STAGES := ["egg", "juvenile", "mature"]

## 產銷與加成乘區詳細拆解
static func inspect_production(session: GameSession) -> Dictionary:
	if session == null or session.state == null or session.content == null:
		return {"ok": false, "error": "SESSION_OR_STATE_NULL"}
	var state := session.state
	var content := session.content
	
	var multipliers := TalentSystem.compute_multipliers(state)
	var buff_multipliers := BuffSystem.compute_multipliers(state)
	var chrono_multipliers := ChronoSystem.compute_multipliers(state)
	var beast_multipliers := BeastSystem.compute_multipliers(state)
	var sect_multipliers := SectSystem.compute_multipliers(state)

	var era_def = content.era(state.era_id)
	var era_multiplier := 1.0 if era_def == null else float(era_def.resource_multiplier)
	var pill_prod_multiplier := 1.0 + float(state.pill_effects.get("production_multiplier", 0.0)) + float(buff_multipliers.global_production_multiplier)

	var global_prod_total := era_multiplier * float(multipliers.global_production_multiplier) * (pill_prod_multiplier + float(chrono_multipliers.global_production_multiplier) + float(beast_multipliers.global_production_multiplier))
	var rates := Production.compute_rates(content, state.buildings, global_prod_total)
	var caps := Production.compute_caps(content, state.buildings, state.era_id, state.onboarding_version)
	
	var spec_multipliers: Dictionary = buff_multipliers.get("specific_resource_multipliers", {})
	var chrono_spec: Dictionary = chrono_multipliers.get("specific_resource_multipliers", {})

	var resource_breakdown := {}
	for resource_id in state.resources:
		var entry: Dictionary = state.resources[resource_id]
		var is_unlocked: bool = bool(entry.get("unlocked", false))
		var current_val: AmountCompat = entry.get("value", AmountCompat.zero())
		var cap_limit: AmountCompat = caps.get(resource_id, AmountCompat.zero())
		
		var raw_rate: AmountCompat = rates.get(resource_id, AmountCompat.zero())
		var final_rate := raw_rate
		var specific_mults := {}

		if spec_multipliers.has(resource_id):
			var extra: float = 1.0 + float(spec_multipliers[resource_id])
			specific_mults["buff_specific"] = extra
			final_rate = final_rate.multiply(AmountCompat.from_number(extra))

		if chrono_spec.has(resource_id):
			var c_extra: float = 1.0 + float(chrono_spec[resource_id])
			specific_mults["chrono_specific"] = c_extra
			final_rate = final_rate.multiply(AmountCompat.from_number(c_extra))

		if (resource_id == "herb" or resource_id == "spirit_grass_low") and (float(sect_multipliers.production_herb_wood) > 0.0 or float(beast_multipliers.production_herb) > 0.0):
			var herb_mult := 1.0 + float(sect_multipliers.production_herb_wood) + float(beast_multipliers.production_herb)
			specific_mults["sect_beast_herb"] = herb_mult
			final_rate = final_rate.multiply(AmountCompat.from_number(herb_mult))

		if (resource_id == "stone_low" or resource_id == "refined_iron") and float(beast_multipliers.production_stone_iron) > 0.0:
			var stone_mult := 1.0 + float(beast_multipliers.production_stone_iron)
			specific_mults["beast_stone_iron"] = stone_mult
			final_rate = final_rate.multiply(AmountCompat.from_number(stone_mult))

		if resource_id == "money" and float(beast_multipliers.money_rate) > 0.0:
			var money_mult := 1.0 + float(beast_multipliers.money_rate)
			specific_mults["beast_money"] = money_mult
			final_rate = final_rate.multiply(AmountCompat.from_number(money_mult))

		resource_breakdown[resource_id] = {
			"unlocked": is_unlocked,
			"current_amount": current_val.to_display_string(),
			"cap_amount": cap_limit.to_display_string(),
			"is_full": current_val.compare_to(cap_limit) >= 0 if cap_limit.sign != 0 else false,
			"net_rate_per_sec": final_rate.to_display_string(),
			"net_rate_float": final_rate.to_float(),
			"specific_multipliers": specific_mults
		}

	return {
		"ok": true,
		"global_multipliers": {
			"era_multiplier": era_multiplier,
			"talent_global": float(multipliers.global_production_multiplier),
			"pill_prod": float(state.pill_effects.get("production_multiplier", 0.0)),
			"buff_global": float(buff_multipliers.global_production_multiplier),
			"chrono_global": float(chrono_multipliers.global_production_multiplier),
			"beast_global": float(beast_multipliers.global_production_multiplier),
			"total_combined_global": global_prod_total
		},
		"resources": resource_breakdown
	}

## 遊戲狀態一致性與完整性自檢
static func inspect_health(session: GameSession) -> Dictionary:
	if session == null or session.state == null or session.content == null:
		return {
			"healthy": false,
			"issues": ["SESSION_OR_STATE_NULL: 無法存取 Session 或 State"],
			"warnings": [],
			"stats": {}
		}
	var state := session.state
	var content := session.content
	var issues: Array[String] = []
	var warnings: Array[String] = []

	# 1. 境界與等級驗證
	if not content.era_ids.has(state.era_id):
		issues.append("INVALID_ERA_ID: 境界 ID %d 不存在於 Content 定義中" % state.era_id)
	if state.level < 1 or state.level > 10:
		issues.append("INVALID_LEVEL: 等級 %d 超出有效範圍 [1, 10]" % state.level)
	if state.highest_era < state.era_id:
		warnings.append("ANOMALY_HIGHEST_ERA: 最高境界 highest_era (%d) 低於當前境界 (%d)" % [state.highest_era, state.era_id])

	# 2. 壽元與修煉時間驗證
	if state.total_elapsed_seconds < 0.0 or is_nan(state.total_elapsed_seconds):
		issues.append("INVALID_ELAPSED_TIME: 總時長為負數或 NaN: %f" % state.total_elapsed_seconds)
	if state.training_seconds < 0.0 or is_nan(state.training_seconds):
		issues.append("INVALID_TRAINING_TIME: 修煉時長為負數或 NaN: %f" % state.training_seconds)

	# 3. 資源健全度驗證
	for res_id in state.resources:
		var entry: Dictionary = state.resources[res_id]
		if not (entry.get("value") is AmountCompat):
			issues.append("RESOURCE_TYPE_ERROR: 資源 %s 的值不是 AmountCompat" % res_id)
			continue
		var val: AmountCompat = entry.get("value")
		if val.sign < 0:
			issues.append("NEGATIVE_RESOURCE: 資源 %s 數值為負: %s" % [res_id, val.to_display_string()])
		if not content.resource_ids.has(res_id):
			warnings.append("ORPHAN_RESOURCE: 資源 %s 存在於存檔但不在當前 Content 中" % res_id)

	# 4. 建築有效性驗證
	for bld_id in state.buildings:
		var lvl: int = int(state.buildings[bld_id])
		if lvl < 0:
			issues.append("NEGATIVE_BUILDING_LEVEL: 建築 %s 等級為負: %d" % [bld_id, lvl])
		if not content.building_ids.has(bld_id):
			warnings.append("ORPHAN_BUILDING: 建築 %s 存在於存檔但不在當前 Content 中" % bld_id)

	# 5. 靈獸狀態自檢
	if not state.beasts.is_empty():
		var active_beast_id: String = String(state.beasts.get("active_beast_id", ""))
		if not active_beast_id.is_empty():
			if not BeastSystem.BEAST_CONFIGS.has(active_beast_id):
				issues.append("INVALID_BEAST_ID: 出戰靈獸 ID '%s' 非法" % active_beast_id)
			var roster: Dictionary = state.beasts.get("roster", {})
			if not roster.has(active_beast_id):
				issues.append("BEAST_NOT_IN_ROSTER: 出戰靈獸 %s 未記錄於靈獸名冊中" % active_beast_id)
			else:
				var beast_data: Dictionary = roster[active_beast_id]
				var stage: String = String(beast_data.get("stage", ""))
				if not EXPECTED_BEAST_STAGES.has(stage):
					issues.append("INVALID_BEAST_STAGE: 靈獸 %s 階段 '%s' 無效" % [active_beast_id, stage])

	# 6. 宗門狀態自檢
	if not state.sect.is_empty():
		var joined: bool = bool(state.sect.get("joined", false))
		if joined:
			var sect_name: String = String(state.sect.get("name", ""))
			if not SectSystem.SECT_NAMES.has(sect_name):
				warnings.append("UNKNOWN_SECT_NAME: 宗門名稱 '%s' 不在標準列表內" % sect_name)
			var ongoing_list: Array = state.sect.get("ongoing_expeditions", [])
			if ongoing_list.size() > SectSystem.EXPEDITION_SLOTS:
				issues.append("EXCEEDED_EXPEDITION_SLOTS: 進行中派遣數 (%d) 超過槽位上限" % ongoing_list.size())

	# 7. 奇遇與待決事件
	if not state.fortune.is_empty():
		var pending = state.fortune.get("pending_encounter")
		if pending != null and not (pending is Dictionary):
			issues.append("CORRUPTED_FORTUNE_PENDING: 待決奇遇資料格式損壞")

	# 8. 指令收據計數
	var receipts_count := state.command_receipts.size()
	if receipts_count > GameState.COMMAND_RECEIPT_LIMIT:
		warnings.append("RECEIPT_LIMIT_EXCEEDED: 指令收據數 (%d) 超過標準上限 (%d)" % [receipts_count, GameState.COMMAND_RECEIPT_LIMIT])

	return {
		"healthy": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": {
			"revision": state.revision,
			"era_id": state.era_id,
			"level": state.level,
			"total_elapsed_seconds": state.total_elapsed_seconds,
			"buildings_count": state.buildings.size(),
			"unlocked_resources_count": state.resources.values().filter(func(r): return bool(r.get("unlocked", false))).size(),
			"command_receipts_count": receipts_count
		}
	}

## 輸出結構化純文字報告
static func generate_report(session: GameSession) -> String:
	var health := inspect_health(session)
	var prod := inspect_production(session)
	
	var lines: Array[String] = []
	lines.append("================ [遊戲運行時診斷報告] ================")
	lines.append("狀態健康評估: %s" % ("【健全 PASS】" if bool(health.healthy) else "【異常 FAIL】"))
	
	var stats: Dictionary = health.get("stats", {})
	lines.append("修為境界: Era %s (LV%s) | 修煉時長: %.1fs | 存檔修訂: rev %s" % [
		stats.get("era_id", "?"),
		stats.get("level", "?"),
		stats.get("total_elapsed_seconds", 0.0),
		stats.get("revision", 0)
	])
	
	var issues: Array = health.get("issues", [])
	if not issues.is_empty():
		lines.append("\n[發現異常 (Issues)]:")
		for iss in issues:
			lines.append("  - " + String(iss))
	else:
		lines.append("無重大邏輯或資料衝突異常。")
		
	var warnings: Array = health.get("warnings", [])
	if not warnings.is_empty():
		lines.append("\n[警告提示 (Warnings)]:")
		for w in warnings:
			lines.append("  * " + String(w))
			
	if bool(prod.get("ok", false)):
		lines.append("\n---------------- [資源產銷與乘區拆解] ----------------")
		var g_mults: Dictionary = prod.get("global_multipliers", {})
		lines.append("全域產率倍率: x%.2f (Era: x%.1f | 天賦: x%.2f | 靈丹BUFF: x%.2f | 天時: +%.2f | 靈獸: +%.2f)" % [
			g_mults.get("total_combined_global", 1.0),
			g_mults.get("era_multiplier", 1.0),
			g_mults.get("talent_global", 1.0),
			g_mults.get("pill_prod", 0.0) + g_mults.get("buff_global", 0.0),
			g_mults.get("chrono_global", 0.0),
			g_mults.get("beast_global", 0.0)
		])
		
		var res_dict: Dictionary = prod.get("resources", {})
		for rid in res_dict:
			var r_info: Dictionary = res_dict[rid]
			if not bool(r_info.get("unlocked", false)):
				continue
			var status_str := "滿倉" if bool(r_info.get("is_full", false)) else "正常"
			lines.append("• %s: 存量 %s / %s (%s) | 秒產: +%s/s" % [
				rid,
				r_info.get("current_amount", "0"),
				r_info.get("cap_amount", "0"),
				status_str,
				r_info.get("net_rate_per_sec", "0")
			])
	lines.append("======================================================")
	return "\n".join(lines)
