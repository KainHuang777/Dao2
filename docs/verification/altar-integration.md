# ART-A1-HOME-INTEGRATE — 聚靈陣遊戲包同步

2026-10-07。使用者要求將新完成的聚靈陣接入遊戲。核對發現正式來源已使用接地版 `assets/abode/altar-grounded/altar-grounded-v2.png`，但 Windows 包仍停在 10/5；本輪完成一般 Web／Windows 匯出同步。此子任務 DONE 僅指來源接線核對、CLI 回歸與遊戲包同步；完整 ART-A1／FX3 的人工美術、實機／高 DPR／長效能仍待驗。

## 最終行為

沿用 `storage_lingli`（遊戲名稱「聚靈壇」）：已建成時在修士右側顯示新圖，未建與輪迴後不顯示、不留下命中區；点選開啟原營造詳情，升級仍由既有命令處理。來源、提示詞及分層記錄沿用 [接地版驗收](altar-grounded.md) 與 [三核心驗收](home-landmarks.md)。本輪沒有新增圖片或修改玩法來源，既有未提交成果保持。

## 命令與結果

- Godot `--version`：`4.7.2.stable.official.ed1daf0bf`。
- 同引擎 `--headless --path . --script res://tests/<runner>_runner.gd`：living_abode、abode_scenery_ui、m3a_reincarnation_ui、res1d2_world（58 checks）、m2d_responsive_ui 五項全部 exit 0。隔離測試資料，不改正常玩家進度；未重跑全量 54。
- 初次 living runner 因 sandbox 無法寫 user:// 而 exit 1，後續依專案授權升權重跑五項成功。失敗日誌保留；既有 Font／CanvasItem／ObjectDB 退出診斷仍存在。
- `--headless --path . --export-release Web build/web/index.html`：exit 0。
- `--headless --path . --export-release WindowsDesktop build/windows/dao2.exe`：exit 0。
- `node tools/prepare_web_compression.mjs build/web`：exit 0，四首 BGM companions 完整。
- PowerShell 唯讀檢查兩個 PCK 的資產路徑與 SHA256，皆包含新版聚靈陣路徑。Web PCK：`ba77ab14a2bd7383dac01689854a819cfb82f4f3826bbf77440f8c558c9497e9`；Windows PCK：`6955564c7b1beac841c7939ca130bf8489c20041faec98dd5c9e3729d5cacb58`。
- 本輪 IAB 4269 與新測試 origin 4271 均遇到遊戲「另一個分頁正在遊玩」保存鎖定提示，未進入世界，不能列為本輪滑鼠／視覺 PASS。4271 僅種入指定隔離 fixture，最後退回 launcher，未接觸 4175 玩家資料。既有 10/7 兩橫式 browser 證據保留為歷史，Windows executable 的實際操作本輪待驗。
- `git diff --check`：既有 `src/presentation/ui_icon.gd:139` trailing whitespace 與 EOF 空行使全工作區檢查未通過；本輪文件另作限定檢查，不修改其他人的 icon 成果。第一次 rg 以 Windows glob 路徑查日誌失敗，改用 `rg -g '*retry.log'` 成功，未影響 runner 結果。

日誌與包檢查位於 `build/verification/altar-integration/`。無 Git commit／push。本階段完成後 checkpoint；下一任務為解除其他遊戲分頁鎖定後人工檢視聚靈陣，以及 Windows 實際操作／裝置驗收，請用 New Chat 接續。
