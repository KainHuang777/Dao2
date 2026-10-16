# 內容擴充 Batch A 實作驗收（丹藥與渡劫）

日期：2026-10-11。設計來源：[content-expansion-batch-a.md](content-expansion-batch-a.md)。流程：fusion（orchestrator 持有共用檔，四 worker 各寫獨占檔，引擎驗證串行，獨立審查）。**未 commit。**

## 使用者裁定（binding）

1. 渡劫失敗 = 失敗降一階（era_id = from_era − 1，level = 新境界 max_level，training_seconds = 0）。
2. §4 丹藥數值照設計文件實作；延壽丹門檻由 EAR1 移至 EAR4，效果 +10 年（非 5 年）。
3. 範圍：Batch A 全部；Batch B、C 未開始。

## 交付檔案

| 檔案 | 狀態 | 內容 |
| --- | --- | --- |
| src/simulation/alchemy_system.gd | 改寫 | PILLS 8 種（§4）；min_era 門檻；計數上限 99；`stack_count`／`reset_stacks`；高階聚靈丹遞減；限時 BUFF 倍數；渡劫丹疊層 |
| src/simulation/tribulation_rules.gd | 新增 | `TribulationRules`：基礎率、丹藥 bonus、成功率 clamp、確定性 roll |
| src/simulation/buff_system.gd | 改 | `MAX_TIMED_DURATION=3600`；`spirit_tide`(×1.5, 300s)、`quick_output`(×1.2, 600s) 定義；同 id 取 max、限時 clamp |
| src/domain/game_state.gd | 改 | `tribulation_seed:int=0`、`tribulation_roll_index:int=0`；duplicate_state／to_snapshot_dict |
| src/persistence/save_codec.gd | 改 | 可選讀取兩欄，缺欄預設 0，型別錯誤 `STATE_FIELD_TYPE:<field>`；roll_index < 0 拒絕；未升 schema |
| src/simulation/command_processor.gd | 改 | `_apply_breakthrough` 渡劫分支（from_era ≥ 3）；`_sync_processing_unlocks` 共用；`_apply_consume_pill` 訓練上限含 high_cultivation_pill |
| tests/batch_a_pills_runner.gd | 新增 | 61 checks：公式、種子掃描、煉丹／服丹門檻、BUFF 上限、渡劫成敗 |
| tests/early_pacing2_pill_runner.gd | 改 | 延壽期望 5.0 → 10.0 |
| tests/m3b_alchemy_runner.gd | 改 | 煉延壽丹前 era_id=4，期望 10 年，之後還原 |
| tools/run_all_runners.ps1 | 改 | 登記 `tests/batch_a_pills_runner.gd` |

## 關鍵公式（與設計文件一致）

- 基礎率 base(EAR) = max(0.30, 0.80 − 0.10×(EAR−3))，EAR ≥ 3；EAR 1–2 無渡劫。
- 丹藥 bonus(n) = B×(1−0.85^n)/0.15，n 上限 99；B：golden_tribulation_pill 0.03，tribulation_pill 0.05。
- p = clamp(base + bonus, 0.05, 0.95)；decline_reduction = 0（天賦 Batch C）。
- roll = float(("%d:%d" % [seed, idx]).hash() & 0x7FFFFFFF) / 2^31；成功 iff roll < p；每次嘗試 idx += 1。
- 高階聚靈丹：gain = 300 × 0.85^k × (1−0.85^c)/0.15，k 為同境已服、c 為本次數量，每境界上限 99。
- 限時 BUFF：duration = 單丹秒數 × count，同 id 取 max，上限 3600。

## v2 預設（orchestrator 決定，已記錄於 rule-differences V2-020）

- 渡劫丹 stacks 存於 `pill_effects["stacks"]`，成功與失敗皆於一次嘗試後全數重置（以換境界為界）。
- `tribulation_seed` 新遊戲預設 0；種子政策尚未定案，列為待決。
- 渡劫失敗後 `processing` 資源解鎖依新境界重新同步。

## 指令與結果（實際執行）

| 步驟 | 指令 | 結果 |
| --- | --- | --- |
| 匯入 | `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` | exit 0（docs/verification/logs/batchA_import.txt） |
| 新 runner | `--script res://tests/batch_a_pills_runner.gd` | exit 0，`61 checks, 0 failures`，無 SCRIPT ERROR |
| 全 66 runner 逐一 | 逐個 `--script res://tests/<x>.gd`，見 logs/runner_summary.txt | 65 個 exit 0，0 個 SCRIPT ERROR；`early_flow1b_runner.gd` exit 1 |
| 重跑 10 相關 runner（改 buff 上限 log 與 changed_ids 後） | batch_a、early_pacing2_pill、m3b_alchemy、m3b_alchemy_ui、m2b_breakthrough、island_breakthrough、res1c_progression、buff_system、m1c_persistence、m1a_core | 全部 exit 0，0 SCRIPT ERROR |

注意：`tools/run_all_runners.ps1` 在第一個失敗 runner 即停止，因此完整掃描改為逐一執行（同一組 runner 清單）。`early_flow1b_runner.gd` 的失敗項為 `foundation handoff survives hidden message rail`（abode UI 的 objective 文字）。

**該失敗為既有問題**：已將 HEAD 還原到暫存目錄（`git checkout -- .`，不動工作區）後跑同一 runner，同樣 exit 1 且同樣失敗於同一 check。與本批次無關，未修改。

日誌為 UTF-8（`docs/verification/logs/`）。舊的 `run_all_runners.txt` 為 UTF-16（PowerShell 重導向預設），僅供 grep 參考。

## 獨立審查（fusion-auditor，唯讀）

- VERIFIED：§3 公式逐項核對（base、bonus、clamp、roll、嚴格 <）；計數 [1,99] 原子拒絕；BUFF 同 id max 與 3600 上限；§4 八種丹藥數值與門檻；roll_index 每次嘗試 +1；失敗降階與解鎖同步；存檔欄位讀寫；stack_count 對 JSON 浮點做 int 轉換。
- 審查發現並已修正：
  1. `applied_effects["duration_seconds"]` 回報未截斷值 → 改為 `minf(buff_duration, MAX_TIMED_DURATION)`。
  2. 渡劫 `changed_ids` 未含 `pill_effects` → 已加入（成功與失敗路徑）。
- 審查提出、未修正（記錄為待決／缺口）：
  - 失敗時全數清空 stacks（含 high_cultivation 遞減歷史）。依 v2 預設保留，記錄於 V2-020，待使用者核定是否改為僅清渡劫丹 stack。
  - tribulation_seed 未在新遊戲或輪迴時重新取種（政策待定）。
  - 缺少存檔往返斷言（seed／roll_index 經 SaveCodec 編解碼）；缺少 stack 重置的直接斷言；缺少 count=99 合法邊界測試；缺少 high_cultivation 經指令路徑的訓練上限測試。

## 未通過／未驗證

- `early_flow1b_runner.gd`：既有失敗（見上），與本批次無關，未修。
- 缺口：
  - content/manifest.json 僅列 era1、era2 的 `era_files`；`content/eras/era3.json` 存在但未掛載，era4 無檔案。因此渡劫路徑只在測試中以記憶體內 fixture 注入 era3／era4（測試清除 era3 capacity 需求）。正式遊戲中 EAR3 以上不可達，屬內容掛載決策，未擅自改 manifest。
  - 丹藥數據仍硬編於 alchemy_system.gd（§5 建議遷出 content/alchemy/pills.json，未做）。
  - UI：煉丹面板（abode alchemy_panel）為原三種丹藥的固定元件，新丹藥可由指令煉製與服用，但面板未顯示。需另案。
  - 種子政策、渡劫失敗 stack 清除範圍、高階丹 DL 配方外部化，皆待使用者核定。
  - 人工遊玩、Web 互動、存檔落盤於瀏覽器未驗證（本批次僅為 headless 契約證據）。

## 2026-10-12 追加：種子政策與 era3 掛載嘗試

- 已定案（使用者）：渡劫失敗後全數重置 stack（現行 v2 即如此，`command_processor._apply_breakthrough` 每次嘗試後呼叫 `AlchemySystem.reset_stacks`）；`tribulation_seed` 新遊戲與輪迴時隨機取種。
- 實作：`GameSession.create_new_game(content, tribulation_seed := -1)`，未指定時 `GameSession.draw_tribulation_seed()`（RandomNumberGenerator，只在協調層）；`GameSession.reincarnate` 的 payload 帶 `tribulation_seed`，`command_processor._apply_reincarnate` 於成功後寫入 seed 並將 `tribulation_roll_index` 歸 0。
- 測試隔離：依賴兩次新局快照相等的 runner 改傳固定 seed `1`（m1a_core、m1b_time、m1d_offline、res1a_processing）。
- **era3 掛載失敗，已還原 manifest**：加入 `eras/era3.json` 後 `ContentLoader` 報 `level_up_requirements.resources` / `lv9_item` 參照 `stone_mid`、`liquid`、`formation_core`、`talisman` 不存在。正式 `content/resources/era1.json` 僅有 lingli、money、wood、stone_low、black_copper、spirit_grass_low、foundation_pill 七項；其餘只存在於隔離的 ProcessingCatalog（res1-a/b/c/d profile）。`DEFERRED_RESOURCE_IDS` 只放寬 graded_resources 驗證，未放寬 level_up 與 lv9 驗證。
- 結論：掛載 era3 需先決定正式資源目錄是否納入 RES1 的中品靈石／丹液／陣芯／符咒／靈材等（屬經濟變更，與 RES1-B～D 隔離 profile 的關係待定），不能只改 manifest。

### 指令與結果（2026-10-12）

| 命令 | 結果 |
| --- | --- |
| `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` | exit 0（logs/batchB_import.txt） |
| `--script res://tests/batch_a_pills_runner.gd`（掛 era3 時） | exit 1，4 項 era3 參照失敗；還原後 exit 0，61 checks |
| 全 67 runner（tools/run_all_runners.ps1 清單，逐一執行） | 第一輪：res1a、m1b、m1d 因新局隨機 seed 失敗（已修）；early_flow1b 既有失敗 |
| 修正後重跑 res1a、m1b、m1d、early_flow1b | res1a／m1b／m1d exit 0、無 SCRIPT ERROR；early_flow1b exit 1（既有，abode objective 文字） |
| 其餘 runner 第一輪 | exit 0、無 SCRIPT ERROR（早前 65/66 與本輪一致，僅 early_flow1b 不過） |

未驗證：人工與瀏覽器互動、Web 匯出、煉丹面板顯示新丹。

### Batch B 狀態

- 使用者已定 Batch B 範圍為「高階非草與丹材」。但 Batch B 的具體資源清單與正式目錄的歸屬未定：(a) 將中品靈石、丹液、陣芯、符咒、靈材、金丹渡劫丹等納入正式 `content/resources`（改變正式經濟與存檔），或 (b) 維持隔離 profile、只做 era3 之外的服用丹材。兩者與 RES1-B～D 的關係需使用者裁定後才能分派 fusion workers。
- 目前 `tribulation_pill` 的成本使用 `spirit_timber` 2，對應設計文件的「靈材 2」，名稱一致，非缺口；但 `golden_tribulation_pill` 與高階靈草在正式目錄不存在，正式遊戲中渡劫丹仍無法取得。

## 下一步

1. 裁定 Batch B 的正式目錄歸屬（見上）。
2. 之後才決定 era3 掛載時機與 era4 內容時程。
