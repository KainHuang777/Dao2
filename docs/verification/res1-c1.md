# RES1-C1：三島產業契約與隔離 Godot 操作

2026-10-03 · **C1 階段已交付；RES1-C 整體 IN_PROGRESS**。本階段是三島操作頁／正式數值候選的可驗收基線，不是三島世界場景或正式玩家放行。沒有新增／冒用世界地標圖片；沒有啟用正式 manifest。依 AGENTS Context Guard，完成本階段後交接 C2，不能直接跳 RES1-D。

## 規則與保存

- 新 `IslandProgression` 使用 `res1-c-1`，沿用 B 的地方庫存、原料扣除、容量保留與固定航線。B `res1-b-1` 仍可讀；B 不讀 C 的設施倍率／容量。隔離 prototype B 檔拒絕自動轉 C，要求另外審核。C 只准青木→靈材、玄礦→銅精，祖島不能繞過物流直接製作這兩項；丹霞與 Era3 配方不在 C 開放。
- Era2 才能啟用。每島開拓付祖島靈木20＋下品靈石10，包含一階採集、加工及倉儲；第一條航線免費，因此起手不要求尚未產出的 T2。祖島舊建築不搬遷／複製，庫存仍為 resources 單一權威。
- 設施有1–3階：採集各原料每秒2×階數；加工每批 ceil(10/階數) 秒；本地每項容量100×倉儲階數。採集升級費為木20×當前階數＋銅精2×階數；加工為靈材2×階數＋銅精2×階數；倉儲為靈材2×階數＋石20×階數。這些是 **v2 C 工作數值**，不是 DAO1 parity 或玩法平衡已放行。
- C 航線運力1→2消耗祖島靈材2＋銅精2，載量10→20，週期10秒；進行中的貨物／加工保持原來數量與剩餘時間，升級作用於下一趟／下一批。工程費只扣祖島可用庫存；物流試驗證明運力提高後實際到貨增加。
- 輪迴保留 C 版本，但清除當世開拓、設施等級、工作與在途貨物，不退原料；回 Era1 原有新手鏈可重建，Era2再開拓。保存拒絕非法設施階數、未開拓／祖島的不合法升級、未来島開拓及錯島配方。
- `SaveManager.activate_islands` 先保存當前未啟用來源快照，再將確切 bytes 寫入並讀回 `save_before_islands`。確認檔可解碼、未啟用 economy、save_id相同；損壞／衝突不覆寫。候選 Session 複製後送命令，兩槽候選提交成功才替換 live state。archive／候選index失敗保留live source，重試不重扣；完整未索引候選仍遵守既有恢復規則。schema2 原始 bytes 備份機制照舊。
- schema仍3；rules為 `core-flow-9-island-progression`，預覽 content加 `+res1-c-1`。正式7資源／10建築／Era1–2 manifest沒增加或附掛配方。只有 `IslandProgressionTest` feature和native runner override會附掛 catalog，玩家 namespace `dao2_saves`未讀寫。

## Godot 操作與 Web 證據

`FeatureNavigation` 的「經營→三島」同頁提供島嶼切換、遷移預覽、開拓、可用／在途或加工預留、配方投入／狀態、單批／持續／本批後停止、三種設施升級與四條航線的保留量／目標庫存／啟停／運力。既有靈界洞天仍可從頁內進入。所有操作送 Session 命令並保存，不由 UI 改庫存；重建內容只在切島或首次catalog，逐tick更新不重建按鈕，避免破壞按下／放開。

IAB 真實滑鼠、隔離 `http://127.0.0.1:4197`／`dao2_islands_preview`：

- 載入由CLI空白檔命令走出的築基fixture；正式preview使用同一生活洞府場景，未注入Debug庫存。
- 1280×720讀取遷移預覽、啟用、開拓青木與玄礦；頁籤／固定關閉／返回經營可操作。
- 844×390重載後两島開拓仍保留，切玄礦、內容捲動、點「製作一批」顯示加工中10秒。初版固定島列／訊息佔用過多高度，改為內容區島列、固定島名／關閉，長成本文字分行；修正後操作已驗。
- 1280×720啟動銅精→祖島，實際顯示載貨1／10秒；稍後祖島銅精可用1、遠島銅精0。證據：[航線](artifacts/res1-c-web-route-desktop.jpg)、[到貨](artifacts/res1-c-web-arrival-desktop.jpg)、[短橫式](artifacts/res1-c-web-short.jpg)。此為控制／單條實際加工貨運證據，不冒稱Web已走完兩鏈T2升級／完整離線矩陣。
- 本輪觀察的 warn/error log為空；沒有高DPR、實體觸控、自然背景凍結或長離線Web效能通過宣稱。臨時viewport override已reset，測試頁回launcher以釋放遊戲鎖。

## 檔案、命令與結果

新增 `src/simulation/island_progression.gd`、`src/presentation/island_management_panel.gd`、`tests/res1c_progression_runner.gd`（保留Godot uid）、`tools/island_preview_server.py`；修改 IslandEconomy、CommandProcessor、GameSession、ReincarnationRules、SaveCodec／Manager、living_abode、FeatureNavigation、export_presets及全量入口。專題／交接／差異文件同步。

| 命令 | 結果 |
| --- | --- |
| 既有引擎 `--version` | 4.7.2.stable.official.ed1daf0bf，exit0，未升級／安裝 |
| `--headless --path . --import` | 首輪三個UI變數型別推斷失敗，修正後r2 exit0、無新parse錯誤；保留initial/r2日誌 |
| `--script res://tests/res1c_progression_runner.gd` | 最終87 checks PASS、exit0；空白→Era2→啟用→兩島→雙鏈T2→設施／運力／倉儲／採集、重送／故障／保存／600秒與分段／離線／壽盡輪迴；實際management rail容器幾何與44高命令按鈕。見 core-layout-final及all-runners-final日誌 |
| `--script res://tests/res1b_economy_runner.gd` | 251 checks PASS、exit0；預期broken JSON診斷保留 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | 第一次49/49 PASS、exit0；最後UI與版本驗證修正後**再次49/49 PASS、exit0**，見 all-runners-final。數量以現有清單為準，較早47為歷史紀錄 |
| `--script res://tests/feature_navigation_runner.gd` | 沙箱隔離user寫入造成場景啟動失敗／Nil，定向終止本次runner；正常授權重跑exit0。保留navigation-final與navigation-elevated-final及既有RID/ObjectDB退出診斷 |
| `--export-release IslandProgressionTest .\build\island-preview\index.html` | 兩輪exit0；測試preset用獨立feature／namespace |
| `--export-release Web .\build\web\index.html` | exit0；正式存檔仍未啟用C |
| `python tools/island_preview_server.py` | sandbox通訊端受限，停止本次server後正常授權啟動成功，只綁127.0.0.1:4197；只服務生成Web檔與一份隔離fixture |
| `git diff --check` | EOF多空行已修，最終通過；CRLF提示保留 |

首次core失败是開始木加工早於完整補料到達、用Session-call revision比較分段結果；改為等待30秒及直接比較TimeAdvancer狀態，沒有修改配方／預期來掩蓋經濟差異。追加測試曾引用錯誤API與把fixture寫入放錯函式，修正後重驗；輪迴改使用實際壽盡推演結果，未注入提前輪迴建築。日誌全部保留。87 checks包含預期corrupt archive JSON診斷，不能稱日誌零錯誤。

## 未通過項與 C2

1. **世界場景**：三島專用島體／代表地標、同canonical route世界點擊、切島Banner、返回祖島與HUD避讓未交付。現有頁面不是完成的三島世界，不得用共用茅屋／漂浮名称牌補成品。
2. **長離線效能**：48h計畫report為86400 effective_ticks，實際受壽元提前停止；native完整C內容同步推演約8.3–12.2秒（最後core-layout-final 9134ms），不符合Web流暢需求。需分批讓出主執行緒、保持state／cursor原子提交／可重試及600秒等價；未宣稱24h都實際執行或Web量測。
3. **放行**：完整Web雙鏈／T2升級、遷移與重載失敗／離線矩陣、使用者視覺／節奏、實機／高DPR待補。正式ContentLoader保持未附掛，C2通過所需DoD後才決定正式啟用。沒有commit／push／部署。

重跑：先執行全量入口或C runner產生 earned-era2 fixture，`--export-release IslandProgressionTest`，`python tools/island_preview_server.py`，開 `/launcher`。沒有隔離存檔才可按載入fixture；已有測試進度按「開啟隔離遊戲」，launcher拒絕覆寫。新遊戲用單獨origin測，不清玩家保存。測試檔可用一般SaveCodec分享碼匯出；`save_before_islands`是未啟用來源快照，不擅自覆蓋現行進度。
