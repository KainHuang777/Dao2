# M3-B 技能 Effects 接線驗收（2026-10-02）

## 任務範圍

讓 `learn_skill` 已購入的技能實際生效：產率（`*_rate`／`*_multiplier`）、容量（`*_max`／`all_max`）、建築等級上限（`building_level_cap`）、升級時間（Dao1 time_reduction 同型，經 `Cultivation.skill_time_multiplier`）。以 Dao1 `D:\Temp\temp\Dao\Dao`（唯讀）之 `skills.csv` 與 effect 套用規則為平價來源。

## 模組與公式

- `src/simulation/production.gd`：
  - `compute_rates(content, buildings, resource_multiplier=1.0, skills={})`：`_skill_rate_additions`（`*_rate` → amount×level）→ `_skill_rate_multipliers`（`*_multiplier` → amount^level，排除 `all_rate_multiplier`／`all_max_multiplier`）→ 全域 resource_multiplier。
  - `compute_caps(content, buildings, era_id, onboarding_version, skills={}, skill_max_multipliers={})`：基礎上限後加 `_skill_capacity_additions`（`all_max` → 全 BASIC_RESOURCE_KEYS 平加 amount×level；其他 `*_max` 平加；`*_max_multiplier` 非平加型）。
  - `_collect_skill_effects(content, skills)` 跳過 level≤0 與未知技能 id；效果資料讀 `def.effect = {type, amount}`。
- `src/content/content_schema.gd`：`validate_skills` 接受選填 `effect`（type 非空字串、amount 為數字且 ≥0，拒 NaN/inf）。
- `src/simulation/command_processor.gd`：`level_cap(definition, content=null, state=null)` 以 `building_level_cap` amount×level 提升上限；`_apply_level_up` 以 `Cultivation.skill_time_multiplier(_collect_skill_effects(...))` 納入升級所需時間。
- 呼叫端補上 `state.skills`：`time_advancer.gd:28-29`、`game_session.gd`（get_view rates/caps + `level_cap` + 行 178 的 `next_level_required_seconds`）、`living_abode.gd:722`、`reincarnation_rules.gd:104`。
- `content/skills/era2.json` 六技能補 Dao1 平價 effects：basic_meditation lingli_multiplier 1.1；qi_condensation lingli_rate 2.0；foundation_building money_multiplier 1.2；qi_storage_1 lingli_max 200；body_strengthening_1 money_max 2000；building_mastery_1 building_level_cap 10。

## 測試

- 新 `tests/m3b_skill_effect_runner.gd`（SceneTree runner，PASS/FAIL/RESULT）：效果欄位驗證、空技能回基準線、lingli_rate 平加 level 1–5、 multiplier 與 caps 的非空洞對照（臨時將 content 資源 rate 設 10.0，測畢還原）、qi_storage_1＋body_strengthening_1 上限 lingli 100→300／money 200→2200／wood 不變、building_level_cap 10→20（library max_level 臨時設 10，測畢還原）、time 無 time_reduction 技能時維持 1.0、session get_view 動態基準線 1.1 倍（容差比較）、schema 拒空 type／接受合法 effect roundtrip。
- `tools/run_all_runners.ps1` 追加Runner，合計 38。

## 證據

- `.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` → exit 0、無 SCRIPT ERROR（`tmp\m3b2_import3.log`；第一次失敗為 production.gd `var effect := def.get(...)` Variant 推斷錯誤，改 `var effect: Variant` 修復）。
- 單跑 `m3b_skill_effect_runner` → exit 0，RESULT: PASS（`tmp\m3b2_eff2.log`）。
- 全套 `tools\run_all_runners.ps1` → 日誌 `tmp\m3b2_suite8.log`，**SUITE_EXIT=0，ALL 38 RUNNERS PASSED WITH EXIT CODE 0**（主控台實錄 exit code），零 SCRIPT ERROR、零 RESULT: FAIL（suite 內僅既有負向路徑 JSON 測試訊息）。
- 獨立 fusion-auditor 審計 VERDICT: PASS（缺陷已修：game_session:178 漏接、空洞乘法測試、runner 註解；餘為接受範圍見下）。

## 限制與未驗項

- schema 無 effect-type 白名單：拼錯型別會載入但不生效（inert）；`amount 0` 合法。
- `compute_caps` 的 `skill_max_multipliers` 參數目前無呼叫端傳非空值（Dao1 `all_max_multiplier` 型別保留；era-2 內容無此型）。schema 會接受 `all_rate_multiplier`／`all_max_multiplier` 型效果但運行時被忽略。
- headless CLI 契約層驗收：瀏覽器／觸控／FPS／IndexedDB 與 實機不變，仍未驗。
- UI 未顯示技能效果數值（僅 get_view 攜帶技能欄位）。

## 規則差異

見 `docs/rule-differences.md` V2-016（更新版）。
