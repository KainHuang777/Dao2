# REF-A：洞府呈現層拆分與文件瘦身

日期：2026-09-28。狀態：**DONE（使用者指定純重構、25 Runner 與 Web Release 載入範圍）**。

本輪不代表已修復原版玩法整合、窄版可讀性、手機手勢或儲存端到端缺口。

## 基線與交付

- 基線提交 `d77bca3`，master，開始時工作樹乾淨。
- Godot `4.7.2.stable.official.ed1daf0bf`，現有同版模板、Compatibility、單執行緒 Web。
- 原 `living_abode.gd` 2,285 行，改為 1,097 行；HUD 控制器 900 行，彈窗管理器 470 行。
- 原 94 個方法簽名、93 個公共／靜態欄位、15 個常數以及訊號宣告均一致（原根腳本無自訂 signal）。根場景保留薄委託 API。
- 核心、內容、存檔編解碼、場景 tscn、project/export 設定及既有 25 Runner 均未修改。
- 控制器使用同一根場景欄位，不快取第二份 Session；Panel 實例順序、父節點、Callable 接收者保持相同。
- 原一般彈窗可同時顯示，因此未採 AGY 的新互斥行為。突破原有相機鎖定、HUD 遮罩、保存先於演出均保留。
- 狀態檔歷史全段落歸檔到 `docs/archive/development-status-m0-m2.md` 與 `development-status-m3-m4.md`，保留原段落序號；現在只保留簡短任務板、證據與限制。
- 原狀態檔包含非法 UTF-8、截斷段落、重複舊任務板；歸檔以 `\xNN` 表示非法位元組，原始位元組仍可從基線 Git blob 還原。
- [呈現層索引](../abode-presentation-map.md) 讓 HUD／彈窗工作只需讀對應控制器與功能檔。

## 命令與結果

均在 `E:\WORK\Dao2` 使用已獲授權的 PowerShell 執行路徑，測試存檔均使用 Runner 隔離位置。

| 命令 | 結果 |
| --- | --- |
| `Godot_v4.7.2-stable_win64_console.exe --version` | exit 0；4.7.2 官方版 |
| `powershell -File .\tools\run_all_runners.ps1`（修改前） | exit 0，25/25 PASS |
| `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` | exit 0，無 SCRIPT ERROR／Parse Error |
| `powershell -File .\tools\run_all_runners.ps1`（修改後） | exit 0，25/25 PASS；原有清單未變 |
| `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/abode_presentation_parity_runner.gd` | exit 0／PASS |
| 相同新 Runner 加 `-- --reference-script=res://build/ref-a/baseline_abode.gd` | 基線原腳本也 exit 0／PASS |
| `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web .\build\web\index.html` | exit 0；成功生成 Web Release |
| 公共 API／機械抽取比對 | 原簽名／欄位／常數一致；方法體除根引用限定與必要 local 型別外一致 |
| `git diff --check` | exit 0 |

追加 Runner 驗證：六個面板公開實例身分、堆疊／開關、四種邏輯尺寸、訊號唯一接線與原 Callable、替換 Session 後讀取新狀態、天賦命令只提交一次／同成本與保存順序、拒絕煉丹命令不改狀態、釋放場景後面板也釋放。

原有退出時 Font／CanvasItem／ObjectDB 洩漏診斷在重構前已存在；損壞 Base64／JSON 測試也預期記錄錯誤。本輪新增測試原版／重構版都出現相同 6 個 ObjectDB／1 個 CanvasItem／1 個 Font 診斷，未將「exit 0」描述成所有 log 完全乾淨。

本機重跑紀錄位於 `build/ref-a/`（Git 忽略）：`baseline-runners.log`、`runners.log`、`import.log`、`export.log`、`parity-baseline.log`、`parity.log`、`static-parity.txt`。基線暫存腳本不進正式匯出。

## Web 真實瀏覽器檢查

Codex CUA 啟動失敗：`helper_unknown_error: setup refresh had errors`。改用內建 Playwright 套件與已安裝 Microsoft Edge，headless Chromium 引擎、全新隔離 browser context、DPR 1，實際執行 WebGL 2.0。

既有 4175 listener 回覆 `ERR_EMPTY_RESPONSE`，未停止使用者服務；另以 Python HTTP server 在 4176 提供同一份 `build/web`，測試結束停止此臨時服務。隔離 context 未使用使用者的 IndexedDB／存檔。

| CSS viewport | 實際觀察 | 證據（本機） |
| --- | --- | --- |
| 1280×720 | 場景已繪製且可操作；關閉離線摘要、更多選單開煉丹、關閉煉丹 | `build/ref-a/web-wide-home.png`、`web-wide-more.png`、`web-wide-alchemy.png` |
| 844×390 | 場景可渲染；更多選單可點開存檔，後续 resize 保留同一面板 | `build/ref-a/web-compact-save.png` |
| 360×640 | 存檔面板保持可见；點擊關閉生效，但文字與按鈕明顯過小 | `build/ref-a/web-portrait-save.png`、`web-portrait-closed.png` |
| 360×480 | 場景與 HUD 繼續渲染；文字／操作區過小，不能視為手機驗收通過 | `build/ref-a/web-short-portrait.png` |

console／pageerror／HTTP error 收集為空；[瀏覽器紀錄](ref-a-browser.json) 含實際 `ABODE_LAYOUT`。Web 載入／代表性點擊通過，不以 ABODE_READY 單一訊息代替截圖與操作證據。

## 發現與後續優先序

1. **正式命令整合（優先修復）**：基線 `GameSession.KNOWN_COMMAND_TYPES` 只列舊命令；`join_sect`、`switch_realm` 等返回 `UNKNOWN_COMMAND`。新增場景測試初版直接發出宗門與跨界訊號，在原版重現失敗；規則／面板測試直接調系統而未經 Session，原 25 項不足以排除這個缺口。另案納入所有新命令、成功／拒絕／冪等／存檔回歸，勿只改文件為 DONE。
2. **窄版 CSS 尺度（待修）**：844×390 CSS 實際傳入 Godot 1558×720，360×640 為 1280×2275，360×480 為 1280×1706；與 Runner 直接輸入 CSS 尺寸不同。造成窄版小字、操作區低於 44 CSS px。原 `project.godot` stretch 與版型演算法均未改，此次保留行為並記錄；下輪獨立修復後再驗 docs/07。
3. 原版 `get_view`／面板可能透過 `ensure_*` 懶初始化宗門／靈界資料；新回歸先暖機這些欄位再比較純開關／排版前後快照。本輪不重新定義其狀態語意。
4. 實體手機、GPU／幀率／50 次切換記憶體、IndexedDB 重載／quota／多分頁尚未在本輪驗證。
5. 修復 1、2 並補真實使用路徑後再推 M4-B；REF-A 純重構未混入這些玩法／畫布行為變更。

## DOC-A 文件整理（2026-09-28）

REF-A 完成後再依程式證據複核 README、Roadmap 與相關狀態頁。新增 DOC-A 標記，讓之後接手不會把環境探針中的 2026-09-13「下一步 M1」或正流程紀錄中的歷史 M2-D 狀態當成現況。M3-B／M4-A 的驗收頁保留各自模組與 Runner 證據，將正式 Session 缺口提到最前；Roadmap 任務依賴先經 M4-A-R1、M2-D-R1 再到 M4-B。舊 `development-status.md` 段落保留於 `docs/archive/`，僅改相對連結供歸檔位置閱讀。

README 46 行、目前狀態 62 行；DOC-A 不執行遊戲測試，前述 REF-A Runner／匯出結果不重複作為文件驗收。
