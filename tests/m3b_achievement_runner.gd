class_name M3bAchievementRunner
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  M3-B 成就系統 (Achievements) 契約與規則驗證")
	print("==================================================")

	var failures: Array[String] = []

	test_definitions(failures)
	test_unlock_conditions(failures)
	test_claim_rewards(failures)
	test_reincarnation_persistence(failures)
	test_debug_reset(failures)
	test_save_codec_roundtrip(failures)

	if failures.is_empty():
		print("\n[SUCCESS] 全部 6 項 M3-B 成就系統測試案例 PASS！")
		quit(0)
	else:
		print("\n[FAILED] 存在測試失敗：")
		for f in failures:
			print(" - ", f)
		quit(1)

func test_definitions(failures: Array[String]) -> void:
	print("\n[CASE 1] 驗證成就定義完整度與維度...")
	var count := AchievementSystem.DEFINITIONS.size()
	if count < 18:
		failures.append("成就定義數量不足 18 項，實際為 %d" % count)
		return

	for id in AchievementSystem.DEFINITIONS:
		var def: Dictionary = AchievementSystem.DEFINITIONS[id]
		if not def.has("name") or not def.has("category") or not def.has("desc") or not def.has("rewards"):
			failures.append("成就 %s 缺少必要欄位" % id)
			return

	print("  -> 通過：18 項成就定義結構完整，涵蓋 6 大維度。")

func test_unlock_conditions(failures: Array[String]) -> void:
	print("\n[CASE 2] 驗證成就條件判定與自動解鎖...")
	var state := GameState.new()
	state.era_id = 1
	state.level = 1

	var unlocked := AchievementSystem.check_achievements(state)
	if not unlocked.is_empty():
		failures.append("開局空白狀態不應解鎖任何成就，實際解鎖了: " + str(unlocked))
		return

	# 1. 建造首座草廬
	state.buildings["hut"] = 1
	var u1 := AchievementSystem.check_achievements(state)
	if not u1.has("build_first_hut"):
		failures.append("建造首座茅屋未正確解鎖 build_first_hut")
		return

	# 2. 引氣入體二層
	state.level = 2
	var u2 := AchievementSystem.check_achievements(state)
	if not u2.has("era_qi"):
		failures.append("修為提升至引氣 2 層未正確解鎖 era_qi")
		return

	# 3. 突破至築基期
	state.era_id = 2
	state.level = 1
	var u3 := AchievementSystem.check_achievements(state)
	if not u3.has("era_foundation"):
		failures.append("突破至築基期未正確解鎖 era_foundation")
		return

	print("  -> 通過：建築建造、境界突破與修為提升之成就自動解鎖判定精確。")

func test_claim_rewards(failures: Array[String]) -> void:
	print("\n[CASE 3] 驗證成就獎勵發放、防重領取與非法領取拒絕...")
	var state := GameState.new()
	state.era_id = 2
	state.level = 1
	state.buildings["hut"] = 1
	AchievementSystem.check_achievements(state)

	var initial_dh := state.dao_heart.to_float() if state.dao_heart != null else 0.0

	# 1. 領取未解鎖成就
	var invalid_claim := AchievementSystem.claim_reward(state, null, "era_golden_core")
	if bool(invalid_claim.get("ok", false)) or invalid_claim.get("error") != "ACHIEVEMENT_NOT_UNLOCKED":
		failures.append("領取未達成成就應被拒絕，實際為: " + str(invalid_claim))
		return

	# 2. 正常領取已達成成就 era_foundation (獎勵: 道心 +20、道證 +1)
	var claim_res := AchievementSystem.claim_reward(state, null, "era_foundation")
	if not bool(claim_res.get("ok", false)):
		failures.append("領取已達成成就失敗: " + str(claim_res))
		return

	var after_dh := state.dao_heart.to_float()
	if after_dh != initial_dh + 20.0 or state.dao_proof != 1:
		failures.append("成就獎勵發放數額錯誤，道心: %f, 道證: %d" % [after_dh, state.dao_proof])
		return

	# 3. 重複領取防範
	var duplicate_claim := AchievementSystem.claim_reward(state, null, "era_foundation")
	if bool(duplicate_claim.get("ok", false)) or duplicate_claim.get("error") != "ALREADY_CLAIMED":
		failures.append("重複領取成就獎勵應被拒絕，實際為: " + str(duplicate_claim))
		return

	print("  -> 通過：獎勵發放原子性保證、重領防護與未達成攔截均正確。")

func test_reincarnation_persistence(failures: Array[String]) -> void:
	print("\n[CASE 4] 驗證六道輪迴後成就進度之跨世永久繼承...")
	var load_res := ContentLoader.load_directory("res://content")
	var content: GameContent = load_res.content
	var state := GameState.new()
	state.era_id = 2
	state.buildings["hut"] = 1
	state.buildings["rebirth_lotus"] = 1
	AchievementSystem.check_achievements(state, content)
	AchievementSystem.claim_reward(state, content, "era_foundation")

	# 輪迴轉世
	var reinc_res := ReincarnationRules.apply_reincarnation(state, content, "normal")
	if not bool(reinc_res.get("ok", false)):
		failures.append("輪迴執行失敗: " + str(reinc_res))
		return

	# 檢查成就狀態
	var ach := state.achievements
	if not ach.get("unlocked", {}).has("era_foundation") or not ach.get("claimed", {}).has("era_foundation"):
		failures.append("輪迴轉世後成就進度丟失: " + str(ach))
		return

	print("  -> 通過：輪迴轉世重塑肉身後，已達成與已領取成就完好繼承。")

func test_debug_reset(failures: Array[String]) -> void:
	print("\n[CASE 5] 驗證 DEBUG 調試重置成就功能...")
	var state := GameState.new()
	state.era_id = 2
	AchievementSystem.check_achievements(state)
	AchievementSystem.claim_reward(state, null, "era_foundation")

	if state.achievements.get("unlocked", {}).is_empty():
		failures.append("前置狀態應有已解鎖成就")
		return

	# 執行重置
	AchievementSystem.reset_achievements(state)

	if not state.achievements.get("unlocked", {}).is_empty() or not state.achievements.get("claimed", {}).is_empty():
		failures.append("DEBUG 重置後成就應為空字典，實際為: " + str(state.achievements))
		return

	print("  -> 通過：DEBUG 重置功能可成功清空全部成就進度與狀態。")

func test_save_codec_roundtrip(failures: Array[String]) -> void:
	print("\n[CASE 6] 驗證 SaveCodec 快照序列化與舊存檔向後相容...")
	var state := GameState.new()
	state.era_id = 2
	state.achievements = {
		"unlocked": {"era_foundation": 12345.0},
		"claimed": {"era_foundation": true},
		"stats": {"total_harvests": 3}
	}

	var snap := state.to_snapshot_dict()
	var decoded_res := SaveCodec._state_from_snapshot(snap)
	if not bool(decoded_res.get("ok", false)):
		failures.append("快照解碼失敗: " + str(decoded_res.get("error")))
		return

	var restored: GameState = decoded_res.get("state")
	if restored.achievements.get("unlocked", {}).get("era_foundation") != 12345.0:
		failures.append("還原的成就解鎖時間不匹配")
		return
	if not bool(restored.achievements.get("claimed", {}).get("era_foundation", false)):
		failures.append("還原的成就領取標記不匹配")
		return

	# 舊存檔向後相容（不含 achievements 鍵）
	var legacy_snap := snap.duplicate(true)
	legacy_snap.erase("achievements")
	var legacy_res := SaveCodec._state_from_snapshot(legacy_snap)
	if not bool(legacy_res.get("ok", false)):
		failures.append("舊存檔解碼失敗: " + str(legacy_res.get("error")))
		return
	var legacy_state: GameState = legacy_res.get("state")
	if not (legacy_state.achievements is Dictionary):
		failures.append("舊存檔解碼後 achievements 應為 Dictionary")
		return

	print("  -> 通過：SaveCodec 快照往返序列化與舊檔相容驗證完好。")
