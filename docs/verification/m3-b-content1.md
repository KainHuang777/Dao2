# M3-B-CONTENT1：有型內容契約、統一庫存與版本化內容 reconciliation

日期：2026-10-02。狀態：**DONE（CLI 契約層；CONTENT2 內容資料另做；UI／瀏覽器／實機待驗項保留）**。

## 目標與非目標

- 已交付：有型的 resource（含 advanced 類別、name_key／category／display_group／display_order／unlock 條件）、building（requirements、name_key 等）、recipe／consumable／skill 定義契約與載入驗證；foundation_pill 統一為 resource Amount 庫存單一權威；版本化 content reconciliation（舊存檔 zero-fill、不提前解鎖、保留未知項）；ProgressionEvaluator（hidden/teased/available/owned）。
- 非目標：未搬 Dao1 CSV、未新增 Era 2 正式 content 檔（CONTENT2）、未做瀏覽器／實機驗收、未動既有 M0-B fixture。

## 修改檔案

- 新增：`src/content/progression.gd`、`src/content/content_schema.gd`、`src/domain/content_reconciliation.gd`、`tests/m3b_content1_runner.gd`、`tests/fixtures/content1/`（9 檔）。
- 修改：`src/content/content_loader.gd`（資源 optional 欄位與未知欄位拒載、recipe/consumable/skill 檔載入與驗證、requirement 目標交叉檢查、hash 納入全部定義）、`src/content/game_content.gd`、`src/domain/game_state.gd`（skills、learned_recipes）、`src/persistence/save_codec.gd`（optional decode）、`src/persistence/save_manager.gd`（load 與 share import 一致 reconcile＋重試）、`src/simulation/alchemy_system.gd`（foundation_pill 單一權威、容量 clamp 200、CAPACITY_FULL）、`src/simulation/sect_system.gd` 與 `fortune_system.gd`（foundation_pill 發放改寫 resource 權威）、`tests/m3b_alchemy_runner.gd`（統一契約期望）、`tools/run_all_runners.ps1`（新增 runner）。

## 命令與結果

- `--headless --import`：exit 0。
- `tests/m3b_content1_runner.gd`：PASS exit 0（載入、hash 敏感性、schema 拒載、reconciliation 冪等／不重發、zero-fill 不解鎖、狀態矩陣、容量 clamp 200、存檔 roundtrip、SaveManager 經 adapter 的 reconciliation）。
- `tools/run_all_runners.ps1`：**ALL 35 RUNNERS PASSED，exit 0**（兩輪，含重大修正後重跑）。

## 獨立審核（fusion-auditor）與處置

- 已修復：share import 未 reconcile；sect/fortune 發放繞過庫存權威；loader float 未拒 NaN/inf；recipe unlock_skill 在無 skills 時可逃漏檢查；requirement 目標（building/resource）未交叉驗證；SaveManager 路徑無測試。
- 保留為已知限制（Minor）：reconciliation 對非 content 的 foundation_pill 也建立 resource 項；migrated pill entry `unlocked=false/ever_obtained=true` 保守方向；`fill_to_capacity` 用 to_float（限定 200 容量內）；recipe/consumable/skill 未知頂層欄位未拒；量值仍以 float 內容定義、全量 Amount 字串契約留待全量大數承諾。
- 已知未驗：真實瀏覽器、IndexedDB、實機；`is_retryable("RECONCILE_SAVE_FAILED")` 目前為防禦性 API，實際 reconcile 失敗路徑僅 null 參數。

## 資料安全

未覆寫玩家存檔、未修改 Dao1；舊 fixture 全部保留；新 fixture 僅在 `tests/fixtures/content1/`。
