# M3-B 技能購買指令（接 era-2 技能內容）

任務：在既有 v2 指令管道上新增 `learn_skill`，讓玩家以 `skill_point` 購買升級 `content/skills/era2.json` 的 6 個 Era 2 技能（basic_meditation 90sp max5、foundation_building 3600sp max5、qi_storage_1 120sp max1、body_strengthening_1 1000sp max1、building_mastery_1 200sp max1、qi_condensation 1800sp max5）。

## 狀態

**DONE（headless CLI 契約層）** — 2026-10-02。

## 修改檔案

| 檔案 | 內容 |
| --- | --- |
| `src/simulation/skill_system.gd`（新增） | `SkillSystem` 全 static RefCounted（比照 TalentSystem）：`get_definition`／`get_cost`（定義表價格不隨等級變動）／`can_learn`（原因 UNKNOWN_SKILL、SKILL_MAX_LEVEL、SKILL_COST_MISSING、MISSING_RESOURCE_ENTRY、RESOURCE_LOCKED、INSUFFICIENT_RESOURCE；容差 0.000001）／`learn`（扣費＋`state.skills[id] += 1`＋事件 `skill_learned` {skill_id, new_level, cost_resource, cost, remaining}；changed_ids 含 cost_resource 與 `skills`；扣至 $-\epsilon$ 時 snap 到零）／`get_view`（每技能 id／name_key／level／max_level／cost／cost_resource／can_learn／reason） |
| `src/simulation/command_processor.gd` | apply 新增 `learn_skill` 分支與 `_apply_learn_skill`：空白 `skill_id` → `EMPTY_SKILL_ID`；失敗經 `_failure(error, detail)` 包裝；成功回傳系統結果原樣 |
| `src/application/game_session.gd` | KNOWN_COMMAND_TYPES 加 `learn_skill`；`_is_valid_shape` 校驗 skill_id 為非空字串；便捷方法 `learn_skill(skill_id)`（command_id `learn_skill_<id>_<revision>_<ticks>`）；`get_view()` 新增 `"skills"` 陣列（6 技能） |
| `tests/m3b_skill_runner.gd`（新增） | T1–T10 契約測試（見下） |
| `tools/run_all_runners.ps1` | runners 陣列加入 m3b_skill_runner；並補上遺漏的 `tests/m3b_content2_runner.gd`（前一任務遺留缺口，經fusion 稽核發現），共 37 條 |

`content/skills/era2.json` 未改動（defs 無 era/prereq/effects 欄位；Schema 只認已知欄位）。

## 設計決策

- **成本為定義表價（flat）**：era2 skill def 只有 `cost`／`cost_resource`，無 legacy 的 per-level scaling（Dao1 skillCost 有 `pow`/floor 級距）；比對舊版行為差異不成立於本切片，故 `get_cost` 不含 `level` 項。Legacy 平價決策記於 `docs/rule-differences.md`（SKILL-FLAT-COST）。
- **無 era/prereq 把關**：era2 skill defs 沒有那些欄位，解鎖實際上是靠 skill_point 資源解鎖條件（era 2＋library L1），與「先行 ContentReconciliation 解鎖資源」串接。
- **RULES 不讀 Node／時鐘**：SkillSystem 全 static，僅觸 `state.skills`／`state.resources`；無動畫／特效依賴。
- **未接 skill effects**：era2 defs 沒有 effects 資料，故 `Cultivation.skill_time_multiplier` 的 legacy time_reduction 接線不在本切片（等 effects 才做，非本任務）。

## 驗證證據（全數 first-hand）

引擎：`tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`。

1. `godot --import` → **exit 0**，log 無 SCRIPT ERROR。
2. 新 runner 單跑 → **exit 0，RESULT: PASS，71 PASS 行，0 FAIL，log 無 SCRIPT ERROR**。 T1–T10 涵蓋：未明技能／成功購買（100−90=10）／連買至 max 後拒絕（SKILL_MAX_LEVEL）／餘額不足拒絕（等級、餘額不動）／成本以 `AmountCompat.compare_to` 驗證不隨等級變動（0 級與 1 級皆 90；200 兩買剩 20）／view 形狀（size 6、basic_meditation level 2）／空 `skill_id` 拒（EMPTY_SKILL_ID）／save→load roundtrip（bm 3／qs 1／qc 0）／reconcile 對舊存檔 zero-fill 6 技能到 0／GameSession 便捷方法 e2e（ok、revision＋1、level 1、get_view().skills 陣列 6）。
3. 全套 `pwsh -NoProfile -File tools\run_all_runners.ps1` → **exit 0，"ALL 37 RUNNERS PASSED WITH EXIT CODE 0!"**（補修 content2_runner 缺項後 36→37），log 檔 `$env:TEMP\opencode\m3b_final_suite.log`。
4. 獨立稽核（fusion-auditor，唯讀）：**VERDICT PASS**。D1–D10 全 OK；誤判風險項目均附 file:line 駁回。稽核發現 content2_runner 缺項 → 補上並重跑全套確認。

## 未驗證／邊界

- Headless 契約測試不等於瀏覽器／互動證據：滑鼠命中、觸控、縮放、IndexedDB 實盤落盤、UI 整合（living_abode HUD／模態接 learn_skill）本次未做，超範圍。
- era2 技能尚無 effects；購買後只改 `state.skills`（save 辭典驗證 SAVE_CODEC STATE_FIELD_TYPE:skills），生產力／時程效果待後續內容。
- `MISSING_RESOURCE_ENTRY`／`RESOURCE_LOCKED`／`SKILL_COST_MISSING` 為 can_learn 防禦分支，無專用 runtime 測試（單元路徑由 code review 覆蓋）。
- 真機／瀏覽器／IndexedDB 項目維持先前任務的記錄，未新增證據。
