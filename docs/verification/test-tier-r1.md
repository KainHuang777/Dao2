# TEST-TIER-R1：分級驗收機制複核與防誤跑

日期：2026-10-23。範圍：使用者指定之測試／驗收流程優化，無遊戲 UI 或規則變更。狀態：DONE（L1 工具契約與兩支實際 runner；未做 L3）。

## 發現與修正

- 原本 L1／L2／L3 規範、Only 篩選與主要尺寸迴圈開關已存在；固定清單 111 支，本輪沒有改清單。
- 無參數原本仍會跑全部：改為明確拒絕，全部必須 `-Full`；篩選匹配全部亦拒絕。`-Full` 不可混搭 Only／StartAt，避免部分結果被誤稱完整驗收。
- 新增 `-List` 預覽，逐個驗證 selector、修剪逗號前後空白。L1 選取前先預覽，避免寬泛關鍵字擴大範圍。
- 串行與並行失敗後的串行重跑原本沒有 watchdog：統一使用有逾時的排程。並行失敗只重跑失敗者，串行仍失敗即回報失敗。
- 直接啟動引擎，避免 cmd 包裝；遇 CIM 不可用時仍終止直接擁有的程序。例外清理只停止這一輪啟動的程序。
- 子程序獨立設定 DAO_VIEWPORT_MATRIX，不污染後續命令；每輪獨立日誌目錄，初跑／重試 stdout 與 stderr 分開保留。exit0 但有 `SCRIPT ERROR:` 亦不能通過，成功摘要明寫 SELECTED 與 matrix。
- `apply_viewport_matrix_gate.py` 的「idempotent」註解原本與實作不符：重跑會再次包裝已加 gate 的陣列。改為略過已處理陣列；只在隔離微型專案測試，沒有重新轉寫正式 tests。
- ai-handoff 的 L3 序列補上 `-Full -Parallel 3`；額外直接執行的 presentation parity 明設 full 並還原呼叫端環境。

## 減少重驗的工作規則

AGENTS 與 ai-handoff 已同步：依變更決定驗收，不依對話次數；純文件／metadata／美術接受只做相關靜態檢查。同來源與環境可引用已有證據，標日期與範圍；受影響項才重跑。大型任務子階段仍採 L1／L2，最終收尾才 L3。日常不主動製作候選交付包來反向觸發 L3；UI 功能完成合併一次桌面 Web 抽驗，必要的本機測試包更新可局部匯出，舊包不可冒充新證據。

尺寸檢查也發現 `m2d_responsive_ui_runner`、`uix_r2_hud_runner` 有專門測窄版／旋轉恢復的情境；本輪保留這類狀態切換測試，不假稱所有 runner 全程只出現 1280×720。已加 gate 的重複版型矩陣預設為單尺寸；針對旋轉／resize 行為的必要情境仍會切換尺寸。往後若單支成本偏高，再按情境拆 runner，無需在本輪重寫整批 UI 測試。

## 命令與結果

驗收級別 **L1**；工具契約與實際啟動冒煙，未跑全遊戲回歸。

| 命令 | 結果 |
| --- | --- |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` | exit0，4.7.2.stable.official.ed1daf0bf |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_runner_orchestration.ps1` | 最終 exit0，15 契約檢查；使用隔離 fake engine，不讀玩家資料 |
| `python tools/test_viewport_matrix_gate.py` | 最終 exit0，1 unittest；含首次轉換與二次不改位元組等5斷言 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'm1a_core,recipe_row'` | exit0，SELECTED 2、matrix=single；recipe_row 約1.9秒、m1a_core 約2.1秒 |
| `git diff --check -- AGENTS.md tools/run_all_runners.ps1 tools/apply_viewport_matrix_gate.py tools/test_runner_orchestration.ps1 tools/test_viewport_matrix_gate.py docs/ai-handoff.md docs/verification/test-tier-r1.md ROADMAP.md docs/development-status.md updata.txt` | exit0 |

契約日誌：[orchestration](artifacts/test-tier-r1/orchestration.log)、[viewport-gate](artifacts/test-tier-r1/viewport-gate.log)。工具日誌留在各輪 `[LOGS]` 暫存目錄；本輪沒把遊戲測試產物當正式玩家進度。

初輪失敗保留：測試 harness 因 PowerShell NativeCommandError 中斷（已改為捕捉子命令非零結果）；timeout 測試揭露 CIM 不可用（已修直接程序停止）；Python 系統暫存子目錄遭拒（改於專案 build 下的隔離 TemporaryDirectory，離開時自動清除）。最後重新驗證均通過。探索搜尋兩次使用了不存在的 glob／設定目錄，已改用 tests 目錄 glob；不影響測試結果。

未執行：全量 runner、全尺寸矩陣、Web 匯出／壓縮、瀏覽器、效能長跑。這些不屬本次工具修改的必要驗收；不稱全量回歸通過。既有工作區 STORY 變更保持，未 commit／push。

修改檔案：AGENTS.md、tools/run_all_runners.ps1、tools/apply_viewport_matrix_gate.py、tools/test_runner_orchestration.ps1、tools/test_viewport_matrix_gate.py、docs/ai-handoff.md、本驗收頁與日誌、ROADMAP.md、docs/development-status.md、updata.txt。

下一步：使用者指定下一任務；新對話沿用以上分級政策，不因換對話補跑 L3。後續可依實測慢項再拆小 runner，無需預建自動依賴推斷系統。
