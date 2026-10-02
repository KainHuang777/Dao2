# M3-B-CONTENT2 驗證報告（完整 Era 2 經濟切片）

日期：2026-10-02
執行方式：fusion 協作（orchestrator + worker-a/b/c + scout 資料研究 + auditor 稽核）
狀態：DONE（headless CLI 驗證通過；瀏覽器／觸控／FPS／IndexedDB 證據本工作階段未取得）

## 交付範圍

1. 生產內容（`content/`，經 `content/manifest.json` manifest_version 1 載入）新增完整 Era 2（築基期）切片：
   - `content/eras/era2.json`：Dao1 legacy 平價 — max_level 10、resource_multiplier 1.5、lifespan 120、level_up {base_time 120, time_multiplier 1.18, lingli 500 / money 100 / stone_low 50}、upgrade_requirements {level 10, capacity {lingli:2000, stone_low:1000}}（capacity 鍵**去 `_max` 後綴**，修正舊 production era2.json 的潛在破格 bug：`CommandProcessor._apply_breakthrough` 以原始鍵查 `Production.compute_caps` 結果，帶 `_max` 的鍵永遠查到 0 導致永遠 INSUFFICIENT_CAPACITY）。
   - `content/resources/era2.json`：9 項資源（skill_point 技能點 200、spirit_rice 靈米 200、refined_iron 精鐵 300、beast_hide_low 初級妖獸皮毛 100、beast_bone_low 初級獸骨 100、beast_crystal_low 初級獸晶 80、bronze_essence 銅精 100、monster_core_low 初級妖丹 150、liquid 丹液 1000），全部帶 Dao1 A1 語系的 unlock 陣列（beast_crystal_low 為 [era:3] 前置標籤 — Dao1 monster_core_low 食譜本身即為 era-3 前置原料，屬已知異常）。
   - `content/buildings/era2.json`：11 棟建築（iron_mine、hunter_camp、rice_field、library、scripture_hall、stone_mine_mid、storage_lingli_mid、storage_stone_mid、storage_money_mid、storage_wood_mid、storage_herb_mid），數值逐一對照 Dao1 `buildings.csv`／`storage.csv`。
   - `content/recipes/era2.json`：3 個食譜（craft_bronze_essence 玄銅10+下品靈石5；craft_liquid 低階靈草5+靈氣50；craft_monster_core_low 初級獸晶2+低階靈草2）。
   - `content/skills/era2.json`：6 個技能（basic_meditation 5級/90、foundation_building 5級/3600、qi_storage_1 120、body_strengthening_1 1000、building_mastery_1 200、qi_condensation 5級/1800，成本皆為 skill_point）。
2. 源碼接線：
   - `src/domain/content_reconciliation.gd`：新增 `unlock_eligible_resources(state, content)` — 僅掃帶非空 `unlock` 定義的資源（era-1 資源含 foundation_pill 權威路徑不變），用 `ProgressionEvaluator.resource_status` 判 available/owned 才解鎖。
   - `src/simulation/command_processor.gd`：新增 `_append_progression_unlocks`，掛在 `_apply_upgrade` 成功尾端與 `_apply_breakthrough`（era_id 遞增後），發出 `resource_unlocked` 事件與 changed_ids。
3. 測試：
   - 新增 `tests/m3b_content2_runner.gd`（10 組檢查，隔離 fixture，不覆寫 content1 fixtures）。
   - 更新 `tests/m1a_core_runner.gd`（期望擴至 16 資源/21 建築）、`tests/m1c_persistence_runner.gd`（比較器改為順序無關遞迴 deep-equal，克服 SaveCodec round-trip int→float 與鍵序差異）、`tests/core_positive_flow_runner.gd`（era-1 流程濾掉 era-2 建築；倍率改讀內容定義 1.5）。
4. 文件：`docs/rule-differences.md` 新增 LP-011… 條目；`docs/development-status.md` 狀態更新。

## 命令與結果

| 命令 | 輸出 | 結果 |
|---|---|---|
| `tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` | `tmp\m3b2_import.log` | exit 0 |
| `... --headless --path . --script res://tests/m3b_content2_runner.gd` | `tmp\m3b2_fast.log` | RESULT PASS, exit 0 |
| `... --headless --path . --script res://tests/m3b_content1_runner.gd` | `tmp\m3b1_fast.log` | RESULT PASS, exit 0 |
| `tools\run_all_runners.ps1` | `tmp\m3b2_suite4.log` | ALL 35 RUNNERS PASSED, suite exit 0，`SCRIPT ERROR` grep 計數 0 |

修錯紀錄（中途 suite 失敗 → 修正）：`tmp\m3b2_suite3.log` 顯示兩個回歸 — (a) m1c 比較器在 SaveCodec round-trip 後鍵序與 int/float 型別不一致；(b) core_positive_flow era-1 流程碰觸 era-2 建築且硬編 2.0 倍率（實為 1.5）。兩者均已修正並復跑通過。

## 內容切片 E2E 鏈（headless 驗證的經濟可達性）

- era-1 破格門檻 = lingli_max ≥ 500：storage_lingli 升 5 級（等級上限 10）即可達 → breakthrough 可過。
- era-2 破格門檻 = lingli_max ≥ 2000 且 stone_low_max ≥ 1000：突破後建 storage_lingli_mid 1 級（+50000）、storage_stone_mid 1 級（+2500）即達 → era-3 門檻在 era-2 經濟內可達。

## 未驗證項（明示）

- 真實瀏覽器互動、觸控、縮放、FPS、IndexedDB 落盤：本工作階段僅 headless CLI 證據，不作宣稱。後續 M 任務或人工步驟補驗。
- era-2 技能的實際購買／效果生效（lingli_multiplier 等）未有指令管道，屬後續任務（prereqTech 同因暫緩）。
- Dao1 monster_core_low 前置原料 beast_crystal_low 為 era-3，源定義即為前向標籤異常；Dao2 照抄並以 ever_obtained unlock 表達，未「修好」。

## 平價決策（詳 docs/rule-differences.md）

- era2 數值依 Dao1 `eras.csv` 原樣（lingli 500/money 100/stone_low 50、base_time 120、time_mult 1.18）= legacy_parity；production era2.json 舊值（lingli 200、time_mult 1.2、無 money/stone_low）被視為未接線的草稿，不做 v2 保留。
- building `prereqTech` 不搬入 = v2_change（Dao1 legacy 路徑本來就繞過；Dao2 無技能購買指令）。
- resource_multiplier 1.5 在 Dao2 為生效機制（Dao1 僅模擬器使用）= v2_change。
- 等級上限維持 LP-009：min(maxLevel, 10) = legacy_parity。
