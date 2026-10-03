# M2-D-NAV1／UI5 使用者截圖回饋

2026-10-03。局部修正已交付；整體 NAV1／UI5 保留 IN_PROGRESS，使用者視覺、高 DPR、實體手機待驗。

針對底部字級不一、兩個「待辦」意思不明、無營造清單時訊息偏右：舊輪迴按鈕留下 22 字級，其他入口 18；兩個待辦分別来自 reincarnation_preview.eligible 與 fortune.has_pending，並非文案誤植；訊息原公式以左 HUD 右方的剩餘空間置中。

交付：四入口統一 18；改為「修行・輪迴」／「遊歷・機緣」並補 tooltip，輪迴明示為可選操作；小於 640 邏輯寬度使用入口名加圓點維持版面。洞府訊息以 viewport 中心為基準，短橫向碰到 HUD 時向右讓位。經營依既有單頁互斥收起訊息，返回洞府恢復。移除 HUD 密度函式的舊主入口尺寸／隱藏設定，FeatureNavigation 統一管理；重設文字後重套 toolbar 邊界。

真實瀏覽器額外找到短橫向資源面板攔截修行入口：z_index 只控制繪製順序，Control 命中仍按節點順序。將 toolbar 移至 HUD 子節點末端，之後才建立旋轉遮罩；844×390 實際點擊已能進入煉丹頁及返回洞府。此次没有修改規則、玩家存檔、資產或既有 HTTP 日誌。

修改：src/presentation/abode_hud_controller.gd、feature_navigation.gd；tests/feature_navigation_runner.gd、m2d_responsive_ui_runner.gd；docs/07-responsive-ui-web-spec.md、development-status.md、此紀錄及 updata.txt。新增通知真假四種组合、四入口字級、訊息 viewport 置中／經營返回恢復及短橫向安全區回歸。

環境與命令（專案根目錄，現有 tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe）：

- `--version`：4.7.2.stable.official.ed1daf0bf，exit 0。
- `--headless --path . --import`：exit 0，artifacts/nav1-feedback-import.log。
- `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd --quit-after 600` 與 feature_navigation_runner：已驗局部修正，最終版本亦納入全量入口。
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1`：最終 38/38 PASS、exit 0，artifacts/nav1-feedback-all-runners-authorized.log。
- `--headless --path . --script res://tests/abode_presentation_parity_runner.gd --quit-after 600`：最終 PASS、exit 0，artifacts/nav1-feedback-parity-authorized.log。
- `--headless --path . --export-release Web build/web/index.html`：最終 exit 0，artifacts/nav1-feedback-export.log。
- `python -m http.server 4183 --bind 127.0.0.1 --directory build/web`：IAB 使用既有 NAV1 測試 origin，與玩家 4175／4178 分離。1280×720 及 844×390 CSS、DPR 約 1；桌面訊息水平中心、兩項具體提醒、經營切換／返回；短橫向 HUD 避讓、修行實際滑鼠開煉丹、遊歷開九界及返回均觀察到。console error/warn 查詢空。截圖 artifacts/nav1-feedback-desktop.jpg、nav1-feedback-short.jpg、nav1-feedback-cultivation-short.jpg；截圖為 JPEG。

失敗紀錄：首輪全量與相容測試因沙箱無法寫入 user:// fixture 而 exit 1，依 AGENTS.md 授權重跑後通過。移除舊隱藏設定時曾讓 360×480／640 toolbar 最小寬度殘留 424，響應式測試 exit 1；窄版文案、統一入口尺寸及重新套 toolbar bounds 修正後通過。既有 Font RID／CanvasItem／ObjectDB 等退出警告保留，不宣稱日誌零錯誤。

驗收限制：本輪瀏覽器沿用隔離 NAV1 origin 的既有壽盡／待決狀態，不覆寫或重置資料；未操作輪迴或機緣選項。一般無提醒與兩項真假组合由隔離 Runner 驗證。未驗實體手機、高 DPR、效能或 IndexedDB 落盤；不是整體 UI DoD 完成。下一步先收本輪使用者視覺回饋，不接著展開大型功能。

## 2026-10-03：建造清單訊息欄重開修復

使用者回報開建造清單會關閉訊息且無法重開。根因為 FeatureNavigation.layout 在 HUD 完成訊息位置／可見性判斷後，對所有功能頁無條件設定 hint_panel.visible=false。改為 buildings 保留 HUD 判斷，其他頁面仍使用原本替換空間的配置。沒有修改規則、存檔或收益。

修改：src/presentation/feature_navigation.gd、tests/feature_navigation_runner.gd、此紀錄、docs/development-status.md、updata.txt。

Godot 4.7.2，命令與結果：
- `--headless --path . --script res://tests/feature_navigation_runner.gd --quit-after 600`：exit 0；新增桌面開啟保留訊息／不重疊建造欄、收起選擇保留、重開、短橫向顯式重開及回洞府置中回歸。artifacts/nav1-building-messages-test.log。
- `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd --quit-after 600`：PASS、exit 0；artifacts/nav1-building-messages-responsive.log。
- `--headless --path . --export-release Web build/web/index.html`：exit 0；artifacts/nav1-building-messages-export.log。
- 真實 IAB 1280×720，隔離測試 origin 4183：經營開啟建造清單仍可見訊息，點收起消失，點清單「下一步」重新開啟；兩欄無重疊。console error/warn 空，已恢復 viewport override。artifacts/nav1-building-messages-reopened.jpg。

兩項相關 Runner 重跑，未將前輪 39/39 全量結果冒充本輪全量。既有 Font RID／CanvasItem／ObjectDB 退出診斷保留。短橫向預設暫收訊息的省空間規則保留，顯式開啟不再被導覽強制關閉；實體觸控／高 DPR 待驗。NAV1/UI5 整體 IN_PROGRESS，下一步收視覺回饋；大型階段以 New Chat 接續。
2026-10-03 使用者回覆「測試 OK」：本輪建造清單訊息保留／收起／重開修復子項驗收通過（DONE）。NAV1/UI5 整體實機／高 DPR DoD 不由此推定；沒有新增執行測試。下一步 M4-A-R1 正式整合驗收，在 New Chat 接續。