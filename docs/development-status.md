# 開發狀態與交接紀錄

更新：2026-09-16。此檔描述實際進度；順序與 DoD 見根目錄 ROADMAP。下列歷史通過結果來自本對話先前的工具／使用者驗證，本次 Roadmap 整理沒有重新執行 Godot 或瀏覽器。

## 目前可用成果

- Godot 4.7.2.stable.official.ed1daf0bf／同版模板、Compatibility、單執行緒 Web 已安裝並成功匯出。
- 主場景為 `scenes/living_abode.tscn`；獨立圖片位於 assets/abode；美術提示詞位於 docs/abode-art。
- 2026-09-13 先前 CLI：`abode_state_runner.gd` 通過；`living_abode_runner.gd` 通過，輸出 `PASS: living abode selects buildings, upgrades, pauses production, and changes scale.`；主場景啟動輸出 ABODE_READY；Web export 成功。主洞府的最新工作基線為 1280×720 橫版桌面優先；手機版需另做直式適配，不能等比例縮小本 HUD。
- 同日先前瀏覽器：點茅屋有 ABODE_SELECT: hut 與詳情；點升級有 ABODE_UPGRADE: hut level=2 與畫面更新；點神識展開有 ABODE_REGION 與多浮島遠景。橫版重排後重新檢查 1280×720 16:9 畫布：繁中標題、資源、建築底牌與右側詳情均清楚可見，點茅屋後右側升級卡正常出現。
- 使用者先前確認舊周天探針繁中正常，點擊計數重載後保留；洞府展示無存檔。兩者不能混用。
- 上一輪服務使用 localhost:4175，當前是否仍在運行必須重新檢查。不可把暫時服務當作已部署產品。

## 任務板

| 任務 | 狀態 | 剩餘工作 |
| --- | --- | --- |
| M0-A | IN_PROGRESS（桌面 Web 完成） | 可重跑整合入口、獨立計數探針 export、瀏覽器重載／HUD／滑鼠拖曳與滾輪已通過；實體觸控／雙指與裝置矩陣待 M2-D 前補證 |
| M0-B | DONE | 2026-09-14 已固定唯讀來源的雜湊／資料 profile，建立代表性黃金 fixture 與隔離 reference runner；詳見 `docs/verification/m0-b.md`。完整 Amount 契約留給 M0-C。 |
| M0-C | DONE | 2026-09-14 交付 `src/domain/amount_compat.gd`、`seeded_random_compat.gd` 與黃金 fixture／契約 runner（Git `9e35c43`）；支援邊界與 ADR-008 見 `docs/verification/m0-c.md`。2026-09-15 本輪重跑 import 與 `m0c_compat_v3_runner.gd` 通過。 |
| M1-A | DONE | 2026-09-16 交付 domain／simulation／application 最小核心、era1 內容與驗證器、`tests/m1a_core_runner.gd`（exit 0）；詳見 `docs/verification/m1-a.md`。場景接線留 M2-A。 |
| M1-B | DONE | 2026-09-16 以 fusion 編排交付可注入 Clock、整數 tick、TimeAdvancer、修行／壽元與 `tests/m1b_time_runner.gd`（exit 0）；詳見 `docs/verification/m1-b.md`。突破／升境、維持費、丹藥天時未實作，不宣稱通過。 |
| M1-C | DONE（CLI／桌面路徑；瀏覽器儲存未驗證） | 2026-09-16 交付 SaveCodec、兩世代槽位、checksum、File／Web storage adapter、SaveManager、匯出／匯入 UI 與 `tests/m1c_persistence_runner.gd`（exit 0）；詳見 `docs/verification/m1-c.md`。IndexedDB 落盤、兩分頁互斥、瀏覽器重載未驗證。 |
| M1-D | DONE（CLI／桌面路徑；瀏覽器、跨程序未驗證） | 2026-09-16 以 fusion 編排交付離線結算（24h 上限、游標提交、不雙領）、協調器、摘要 UI 與 `tests/m1d_offline_runner.gd`（exit 0）；詳見 `docs/verification/m1-d.md`。 |
| M1-E | DONE（CLI／桌面路徑；瀏覽器 UI 與真實 corpus 未驗證） | 2026-09-16 交付 `LegacyImporter`、9 個隔離樣本、支援矩陣 `docs/legacy-compatibility.md` 與 `tests/m1e_import_runner.gd`（exit 0）；預覽差異、新槽提交、原文保留、`backfill_policy="none"`。詳見 `docs/verification/m1-e.md`。 |
| M2-A | DONE（CLI／桌面路徑；實機觸控與裝置驗收待 M2-D） | 2026-09-19 交付主場景接入 GameSession/SaveManager、10建築配置、Onboarding連鎖解鎖、聚氣引靈（gather）、雙Runner（living_abode_runner & m2a_abode_runner 通過）；詳見 `docs/verification/m2-a.md`。 |
| M2-B | DONE（CLI／桌面路徑；全量 11 個 Runner 通過） | 2026-09-19 交付首次升境規則、Era 2（築基期）定義、小階修煉積累、大境界突破容量門檻（不扣庫存）、突破演出場景控制器（可跳過／可重播不重發）、洞府天象反饋與 `m2b_breakthrough_runner.gd`（exit 0）；詳見 `docs/verification/m2-b.md`。 |
| M2-C/D | TODO | Godot九界一瞥（M2-C）及完整畫質／裝置驗收（M2-D）待做 |
| M3-A/B | TODO | 多世循環與舊系統矩陣 |
| M4-A/B | TODO | 第二界可玩差異、正式尺度與法則資料 |
| M5-A/B | TODO | 按需生成、封存與逐界內容 |

目前無已確認的外部阻塞；未選定基準手機與實機測量仍待安排。不因這一項未知而停掉可做的 CLI／fixture 工作。

## 已知限制與檢查線索

1. 主場景已完整切換至 GameSession 與 SaveManager；展示數值與 float process 已由正式 Tick 與 AmountCompat 取代。
2. 目前場景測試直接呼叫函式；2026-09-13 已額外在桌面 Web 實測建築命中、HUD、拖曳、滾輪、歸家及遠景。雙指／實體觸控、拖出 HUD 後釋放和不同手機 DPI 仍待 M2-D 前補證。
3. 主場景已改為 1280×720 桌面橫版設計，完整 CLI／Web 匯出與瀏覽器畫面已於本輪重驗。手機直式適配、360 CSS px 可讀性與44px觸控區仍需在 M2-D 前量測，不能由桌面畫面推定通過。
4. region 是重用地形的視覺示範，没有新據點經濟；飛劍／靈流已有動畫程式，但視覺強度、位置對齊與手機效能待實測。
5. all_resources 匯出會帶入 src/效果圖 和 tests；正式發布前需明確排除開發／參考內容，保留來源原圖。
6. 2026-09-19 M1 全量 Commit 595cea6，M2-A 順利交付並提交 0f460e0，M2-B 通過全量 11 項 Runner 驗證。

## 下一個動作

M2-B 已完成（CLI／桌面路徑；全量 11 個 Runner 通過）。下一個主線依 ROADMAP 進入 M2-C（Godot 第一分鐘九界鉤子；相依 M2-B）。實現首次引氣事件、6–8 秒可跳過神識抽遠、九界預覽與返回洞府。

## 本輪交付

2026-09-19 M2-B：新增 `content/eras/era2.json`（築基期）並註冊至 `content/manifest.json`；擴充 `src/simulation/command_processor.gd` 與 `src/application/game_session.gd` 支援 `level_up_cultivation` 與 `breakthrough_era`（容量門檻嚴格防護、突破不扣庫存）；新增 `src/presentation/breakthrough_sequence.gd`（突破演出：天地異象、可跳過、可重播不重發獎勵）；主場景 `src/abode/living_abode.gd` 整合修煉晉階與突破按鈕、掛載突破演出、築基後浮現天幕祥雲與聚靈壇光環；新增 `tests/m2b_breakthrough_runner.gd`（exit 0，小階累積、突破契約、演出跳過與重播、存檔重載全通）；全量 11 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-b.md`。

2026-09-19 M2-A：重構 `src/abode/living_abode.gd` 徹底接入 `GameSession`、`SaveManager`、`OfflineCoordinator` 與 `Onboarding`；擴充 `src/abode/abode_building.gd` 支援未建造狀態；修復 `web_storage_adapter.gd` 關鍵字衝突並增補 `AmountCompat.to_float()`；更新 `tests/living_abode_runner.gd` 並新增 `tests/m2a_abode_runner.gd`（exit 0，6 階段驗證全通）；全量 10 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-a.md`。

## 已知限制與檢查線索

1. 主場景已完整切換至 GameSession 與 SaveManager；展示數值與 float process 已由正式 Tick 與 AmountCompat 取代。
2. 目前場景測試直接呼叫函式；2026-09-13 已額外在桌面 Web 實測建築命中、HUD、拖曳、滾輪、歸家及遠景。雙指／實體觸控、拖出 HUD 後釋放和不同手機 DPI 仍待 M2-D 前補證。
3. 主場景已改為 1280×720 桌面橫版設計，完整 CLI／Web 匯出與瀏覽器畫面已於本輪重驗。手機直式適配、360 CSS px 可讀性與44px觸控區仍需在 M2-D 前量測，不能由桌面畫面推定通過。
4. region 是重用地形的視覺示範，没有新據點經濟；飛劍／靈流已有動畫程式，但視覺強度、位置對齊與手機效能待實測。
5. all_resources 匯出會帶入 src/效果圖 和 tests；正式發布前需明確排除開發／參考內容，保留來源原圖。
6. 2026-09-19 M1 全量 Commit 595cea6，M2-A 順利交付並通過 10 項 Runner 驗證。

## 下一個動作

M2-A 已完成（CLI／桌面路徑；實機觸控待 M2-D）。下一個主線依 ROADMAP 進入 M2-B（首次升境與可重播演出；相依 M2-A）。由舊依賴資料補齊第一個升境必需功法、配方、材料，實現首度境界突破演出。

## 本輪交付

2026-09-19 M2-A：重構 `src/abode/living_abode.gd` 徹底接入 `GameSession`、`SaveManager`、`OfflineCoordinator` 與 `Onboarding`；擴充 `src/abode/abode_building.gd` 支援未建造狀態；修復 `web_storage_adapter.gd` 關鍵字衝突並增補 `AmountCompat.to_float()`；更新 `tests/living_abode_runner.gd` 並新增 `tests/m2a_abode_runner.gd`（exit 0，6 階段驗證全通）；全量 10 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-a.md`。

2026-09-13：新增 ROADMAP、AGENTS、AI handoff 與本狀態檔，更新 README 和舊規劃入口。只修改文件，未改遊戲程式或再次跑遊戲測試；已核對現有檔案與測試入口，並檢查新增文件 UTF-8、相對連結和 Roadmap 任務覆蓋。
2026-09-13 M0-A：新增 `tools/run_m0a.ps1`、隔離周天 probe、兩個 Godot source-scan ignore 及鏡頭觀察記錄。完整 CLI 匯入／runner／雙 Web export 成功；桌面瀏覽器實測周天保存 1→2→3、洞府選取／升級／藥圃停復／低特效／遠景／歸家／拖曳／滾輪。詳見 [M0-A 驗收紀錄](verification/m0-a.md)。實體 touch/pinch 與效能未測，故 M0-A 保持 IN_PROGRESS。

2026-09-13 可讀性調整：主場景設計尺寸改為 1280×720；HUD 改為左側狀態、中央洞府、右側詳情與底部操作，面板提高不透明度、字級與按鈕尺寸，建築名稱加深色底牌；低優先的常駐操作提示移出主畫面，保留操作說明按鈕。初始洞府鏡頭提高至 0.70，讓地形在桌面畫布成為主視覺。`tools/run_m0a.ps1` 最後一次完整匯入、三個 runner、啟動與兩個 Web export 均成功；localhost Web 實測茅屋選取及右側升級詳情通過。此調整未改展示數值、經濟或保存。手機直式適配仍未做。

2026-09-14 M0-B：新增 `docs/legacy-source-manifest.md`、`docs/rule-differences.md`、`tests/fixtures/legacy/m0-b-v1.json`、`tests/fixtures/legacy/m0b_reference.test.ts` 與驗收紀錄。`E:\Python\test1` 不是 Git work tree，故以 package 版本、精選規則／測試／CSV 的 SHA-256 和資料列數固定來源。隔離 Vitest runner 直接從唯讀舊規則模組驗證建築成本、容量容差、修煉時間、Amount 代表字串、壽元、輪迴、新手解鎖與 ASCII／繁中／數字 SeededRandom state 恢復；1 test 通過。完整 Amount 演算與 GDScript RNG 實作尚未開始，列入 M0-C。

2026-09-14 M0-C（前一輪交付，本輪補記錄）：Git `9e35c43` 新增 `src/domain/amount_compat.gd`、`src/domain/seeded_random_compat.gd`、`tests/fixtures/legacy/m0-c-v1..v3.json`、三個 m0c runner、`docs/verification/m0-c.md` 與 ADR-008；當時實測 import、M0-C runner 與 M0-B vitest 皆通過。該輪未同步更新本狀態檔的任務板（M0-C 仍標 TODO），屬記錄衝突，本輪以程式與測試證據修正為 DONE。

2026-09-15 進度確認：工作區已是 Git repository（master，工作樹乾淨，最新提交 `9e35c43`）。重跑 Godot 4.7.2 版本檢查、`--import`、`m0c_compat_v3_runner.gd`（PASS: M0-C AmountCompat canonical contract and SeededRandomCompat match the fixture.）、`abode_state_runner.gd` 與 `living_abode_runner.gd`（皆 PASS）。未重跑 Web export、瀏覽器互動與 vitest；本輪僅改本狀態檔，未動遊戲程式。下一個任務 M1-A。

2026-09-16 M1-A：新增 `content/`（manifest＋era1 資源 7／建築 10）、`src/content/game_content.gd`、`src/content/content_loader.gd`（驗證與 SHA-256 content_version）、`src/domain/game_state.gd`、`src/simulation/onboarding.gd`、`building_costs.gd`、`production.gd`、`command_processor.gd`、`src/application/game_session.gd`（冪等登記、revision、get_view）與 `tests/m1a_core_runner.gd`。實測 `--import` 成功、runner 退出碼 0（PASS 行如上，無 SCRIPT ERROR），涵蓋費用／onboarding parity（m0-b-v1.json）、空白初始、Gather／升級、冪等、過時 revision、確定性與內容驗證。同輪更新 `docs/verification/m1-a.md`、`docs/rule-differences.md`（LP-001／002 收斂，新增 LP-009～011、V2-004）與 `docs/ai-handoff.md` 命令區。未 commit；`src/abode/` 展示與 ADR-008 早期候選檔未動（後者待使用者確認刪除）。

2026-09-16 M1-B 前置（fusion）：新增 opencode fusion 設定 `.opencode/skills/fusion/SKILL.md`、六個 subagents（`fusion-worker-a` glm-5.3-flash、`-b` qwen3.8-flash、`-c` deepseek-v4-flash、`-d` nemotron-3.5-lightning-free、`fusion-scout`、`fusion-auditor`，後兩者 edit deny）與命令 `fusion-m1b`。完成 M1-B 舊規則研究並凍結於 `docs/m1-b-execution-plan.md`：tick=60 秒／年、修練時間公式與向量（47.5／33.75／36／1）、壽元公式與向量（4800／13500／68400；累積 80／200／740 祀）、升境不重置 `totalElapsedSeconds`、每 tick 步驟與容量 clamp。Era1 的 baseTime／levelUp 需求等未固定項留 scout。opencode 設定不熱重載：**需重啟後執行 `/fusion-m1b`**。本輪未寫 M1-B 遊戲程式、未跑引擎。

2026-09-16 M1-B（fusion 執行）：以 fusion 編排完成。新增 `src/simulation/game_clock.gd`、`time_advancer.gd`、`cultivation.gd`、`lifespan.gd`、`content/eras/era1.json`、`tests/m1b_time_runner.gd`；擴充 `GameContent`／`ContentLoader`（era 定義、引用驗證、content_version 含 eras）、`Production.compute_rates`（resource_multiplier）、`GameState`（training_seconds／total_elapsed_seconds）、`GameSession`（clock／advance_time／view）。Era1 數值對照唯讀 `eras.csv`（SHA-256 `E71F03AB…CA404`）。實測 `--import` 退出碼 0、`m1b_time_runner.gd` 退出碼 0（`PASS: M1-B clock, ticks, cultivation, lifespan, boundaries, determinism.`，無 SCRIPT ERROR／FAIL）。fusion-auditor 稽核後修正：runner 內容載入失敗不再靜默 fallback、`_expect_close` 加 NaN 檢查、補 level 10 邊界與 Era1 lv5–lv9 向量。未實作：突破／升境、維持費、丹藥天時、`lv9Item`。未 commit。

2026-09-16 M1-C（fusion 執行）：以 fusion 編排完成。新增 `src/persistence/storage_adapter.gd`、`save_codec.gd`、`save_slots.gd`、`save_manager.gd`、`file_storage_adapter.gd`、`web_storage_adapter.gd`、`src/presentation/save_controls.gd`、`tests/m1c_persistence_runner.gd`（11 群）。信封依 docs/02 §7.1；checksum 為 SHA-256，並修正 Godot JSON int→float 往返造成的雜湊不符（數字正規化）；decode 增 `REVISION_MISMATCH` 一致性檢查。實測 `--import` 退出碼 0、`m1c_persistence_runner.gd` 退出碼 0（`PASS: M1-C save codec, two-slot persistence, checksum, export/import.`，無 SCRIPT ERROR）。fusion-auditor 稽核後修正：runner 損壞復原改為真正覆寫 active 槽、移除恆真斷言、匯入／匯出改以 `to_snapshot_dict()` 比較。未驗證：IndexedDB 落盤、兩分頁互斥、瀏覽器重載、web quota、匯出匯入 UI 互動。未 commit。

2026-09-16 M1-D（fusion 執行）：以 fusion 編排完成。新增 `src/simulation/offline_settlement.gd`、`src/application/offline_coordinator.gd`、`src/presentation/offline_summary.gd`、`tests/m1d_offline_runner.gd`；`time_advancer.gd` 增 `advance_time_only`；`game_state.gd` 增 `duplicate_state()`；`save_manager.gd` 增 `_envelope`／`last_settled_utc_ms()`／`envelope()`；`save_codec.gd` `RULES_VERSION` 升 `offline-24h-1`。政策：收益窗 24h 上限、超出只推年歲與壽盡、游標提交至 now、保存失敗可重試不雙領。實測 `--import` 退出碼 0；`m1d_offline_runner.gd`、`m1c_persistence_runner.gd`、`m1b_time_runner.gd` 皆退出碼 0、無 SCRIPT ERROR（m1d PASS：`PASS: M1-D offline settlement, cap 24h, cursor commit, no double grant.`）。fusion-auditor 稽核後修正：NO_STATE／NO_CONTENT 回 `{}`、`advance_time_only` 改用 `SECONDS_PER_TICK`、DETERMINISM 改結算兩次比 report、補重載不補領與深拷貝隔離測試、強化摘要靜態檢查。未驗證：IndexedDB 落盤、兩分頁互斥、跨程序關閉再開、丹藥／天時到期、自動輪迴、`advance_to` 邊界驅動與批次讓出、匯出匯入 UI 互動。未 commit。

2026-09-16 M1-E（fusion 執行）：以 fusion 編排完成。新增 `src/persistence/legacy_importer.gd`、`tests/m1e_import_runner.gd`、`tests/fixtures/legacy/import_samples/`（9 個去識別化樣本：compact 開局、Base64 中期、長鍵中期／輪迴／大數／靈獸缺欄、未知 ID、截斷損壞、損壞 JSON）與 `docs/legacy-compatibility.md`（14 列支援／部分／拒絕矩陣，含 docs §7.2「s／skills」更正為 `s`=sect）。`save_manager.gd` 增 `LEGACY_RAW_KEY`／`import_legacy_text()`／`legacy_raw()`；`save_controls.gd` 增舊檔匯入 UI。政策：使用者主動貼上／選檔、`backfill_policy="none"` 不按舊時間戳補獎、成功另存新槽 `revision=max(prev+1,1)`、原文存 `legacy_import_raw`、未知 ID／金額問題列入報告且不寫入狀態。修掉 `build_report` 兩個缺陷（迭代包裝字典 `{ok,map,error}` 的鍵、將整個資源 entry 直接送 `deserialize_amount`）與長形式 `buildings` 拆包。實測 `--import` 退出碼 0；`m1e_import_runner.gd` 退出碼 0（PASS：`PASS: M1-E legacy import decode, mapping, reports, and slot commit.`），m1d／m1c／m1b 回歸皆退出碼 0、無 SCRIPT ERROR。fusion-auditor 稽核九項準則全 MET。未驗證：瀏覽器 UI 互動、真實 corpus、`~20000` 字元截斷、layer>3 算術、獸進度不被分享碼攜帶、門派／技能／天賦等僅列報告不映射。未 commit。

