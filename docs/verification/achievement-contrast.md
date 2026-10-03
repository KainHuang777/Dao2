# UI8-COLOR-R1 成就文字對比修正

2026-10-03 · DONE（使用者回報的配色錯誤／桌面 Web 驗證）。

根因：AchievementPanel 的摘要、說明與已領取標題使用 `UiMaterial.INK`，但背景是深青玉卡片，文字幾乎融入背景。

修改 `src/presentation/achievement_panel.gd`：摘要／說明／已領取標題改為共用 `LIGHT_TEXT`，未達成標題改 `#c3cdc6`；頁標題與獎勵改 `#e5cf99`，成功訊息改 `#9cdeb5`。保留既有按鈕材質與成就規則。

驗證：Godot 4.7.2 `--headless --path . --script res://tests/m3b_achievement_runner.gd` 六項案例 PASS、exit 0，見 `artifacts/achievement-contrast-runner.log`（沙箱下 root certificate 診斷保留）。`--headless --path . --export-release Web .\build\web\index.html` exit 0，見 `artifacts/achievement-contrast-export.log`。

真實 IAB 滑鼠、隔離 origin 4186：1280×720 開修行→成就，摘要／說明／可領／未達成均可讀；實際領取一項測試成就後「已領取」標題及成功訊息仍可讀。844×390 縮放並在 Godot 內容區捲動確認說明、獎勵及未達成文字。截圖：`artifacts/achievement-contrast-desktop.jpg`、`artifacts/achievement-contrast-short.jpg`。console warn/error 空；測試頁與本輪 HTTP 服務已關閉。未操作 4175 玩家存檔。

只有配色修改，使用既有成就回歸，未新增鏡像測試或重跑全量。觸控／高 DPR 與整體 UI 放行仍待獨立驗證。下一大型任務仍為 M1-C/D Web 持久化與離線驗收，請以 New Chat 接手。
