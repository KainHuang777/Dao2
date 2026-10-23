2026-10-21 **F-C粗明體修訂已交付**：依使用者「執行」，樣張卷末題名改Noto Serif TC真實字重800、題簽900；小傳／卷末句文楷、數字與操作黑體保持。比較頁預設開啟卷末F-C。三橫式含長文保存異常共6張專項圖通過（字重800／900、字型載入、44px與布局無溢出），見[新版樣張](../verification/artifacts/ui-shell-design/heavy-serif/fc800-1280x720.png)。本次只調設計樣張與共用規範，正式Godot字型接線留待共用殼實作；整體布局仍待確認，UI-SHELL-DESIGN仍IN_PROGRESS。未改GDScript／build／玩家資料，未commit/push。

2026-10-21 **UI-SHELL-DESIGN 字體F-C已選定；布局仍待確認**：使用者明確回覆「F-C」。核定卷末題名用明體、小傳與卷末句用文楷；數字、帳目、收據、按鈕及分頁仍用思源黑體。此為限定敘事角色的共用規範例外，後續經UiTypography集中接入，不授權各頁自行載字或全面換字。正式字型接線尚未實作；整體布局、題名條件與保存世數未因本次字體選擇接受，任務仍IN_PROGRESS。[方案與比較](../29-ui-shell-design-proposal.md)。本輪僅記錄決策，未重跑引擎／瀏覽器／匯出，未改正式程式／build／玩家資料，未commit/push。

# UI-SHELL-DESIGN · 設計樣張驗證

2026-10-21 · **IN_PROGRESS：樣張交付，待使用者接受／字體選擇。** docs28前置規劃已滿足；正式UI-SHELL-0～2及ATM-LIFE實作未開始。

交付：[候選方案與圖片索引](../29-ui-shell-design-proposal.md)、`docs/visual-prototype/ui-shell-design/{index,screen}.html`、`tools/ui_shell_design_server.py`、`tools/ui_shell_design_capture.mjs`、本目錄 `artifacts/ui-shell-design/`。

環境：Windows桌面、現有Godot `4.7.2.stable.official.ed1daf0bf`（僅版本確認）、Node20.20.0／Python3.14、隔離Edge CDP9251。實際browser版本與每圖CSS尺寸／DPR、載圖、字體使用與矩形檢查見 [browser-checks.json](artifacts/ui-shell-design/browser-checks.json)。

## 命令與結果

最終收結：Edge155.0.4283.62，29圖／9項樣張互動全部通過，`failures=[]`；`python tools/ui_shell_design_artifacts.py` exit0（31來源hash、3張總覽）；`python tools/ui_shell_design_checkpoint.py` exit0（11份UTF-8、33本地連結、errors=[]）；targeted `git diff --check` exit0。隔離瀏覽器profile已在`.gitignore`精確排除，沒有刪除其他probe或玩家資料。

- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` exit0，同版正確。
- `python tools/ui_shell_design_server.py --port 4392` 啟動本機唯讀樣張服務；僅綁127.0.0.1。4391初次沙箱服務無法供外部Edge讀取，已Ctrl+C停止，該程序exit1為主動終止。
- 隔離Edge：`msedge.exe --remote-debugging-port=9251 --user-data-dir=E:/WORK/Dao2/probes/ui-shell-design-browser --no-first-run http://127.0.0.1:4392/index.html`。透過Start-Process、WindowStyle Hidden啟動；不使用玩家瀏覽器設定檔。
- `node --experimental-websocket tools/ui_shell_design_capture.mjs` 最終結果於JSON與本輪狀態checkpoint記錄。29張PNG：6頁×3尺寸、F-C×3、F-C長文異常×3、抽屜／訊息異常／提前／在世／F-B長文各1。
- 9項真實桌面滑鼠／resize樣張序列：洞府關庫存及關訊息→建築資源→開關抽屜→技能設定→顯示異常→訊息→返回技能→resize→回洞府偏好保留→樣張重試；另直式遮罩及恢復。JSON逐項記錄。
- Python靜態檢查、圖片總覽、既有資產hash／來源清單、文件連結／UTF-8及targeted git diff-check結果在本輪checkpoint。

腳本不是正式遊戲E2E，樣張「保存失敗／重試」是記憶體旗標，不代表localStorage或IndexedDB測試；樣張按鈕不執行玩法命令。自動檢查圖字及固定邊界，也逐張縮圖總覽並原大檢查短式卷末／長文異常／洞府及資源層。未以CSS矩形通過冒充Godot滑鼠命中。

## 初次失敗與修訂

1. 初次Node連CDP得EACCES，正常升權後ECONNREFUSED；隔離Edge以正常授權流程重啟成功。沙箱4391服務超時，初批24張是瀏覽器錯誤頁，該輪後續click失敗exit1。隨後加真正`designState`載入閘門，改4392可讀服務，所有同名圖片重新拍攝；錯誤頁不列交付證據。
2. 首次有效布局檢查發現800洞府scrollHeight368>360，及長文異常的卷末首屏只剩題名。修正短式庫存入口、世界圖層百分比／grid最小尺寸、卷末空白回饋行及標題／判詞排列；追加壽盡HUD一致性。
3. 中間一次`node -e`診斷遭PowerShell引號SyntaxError，改存成`diagnose.mjs`後exit0。診斷定位洞府世界圖造成main scrollHeight362，未透過裁切隱藏溢出。

## 證據界線與下一步

樣張不等於所有共用元件已精確復刻：CSS紙色／青玉／細底線及透明CloseSeal只表達同一視覺方向；正式接線仍復用GameTab／SegmentChips／CloseSeal及UiMaterial。無新美術生成、無字型新增、無GDScript／schema／玩家進度／build變更，未跑Godot Runner／import／原生渲染／Web遊戲匯出／FPS；本任務未改正式來源，不以回歸套件取代設計審閱。

目前未通過項：使用者尚未接受共用布局與F-B／F-C，故任務未DONE。完整選文／保存／規則證據仍屬後續範圍。停止本階段，請New Chat收回饋；接受後才啟動UI-SHELL-0。

## F-C粗明體專項修訂

使用者先選F-C，再參考截圖要求較粗飽滿，並明確授權「執行」。`screen.html`僅F-C題名800／題簽900，未描邊或合成加粗；`index.html`預設卷末F-C。`node --experimental-websocket docs/verification/artifacts/ui-shell-design/capture-heavy.mjs` exit0，6張PNG／failures=[]；原大目視寬式及800長文異常通過。量測與截圖見[checks.json](artifacts/ui-shell-design/heavy-serif/checks.json)。舊29圖保留為較早版本，新字重以heavy-serif為準。未重跑Godot／遊戲保存／全量Runner，未改正式程式。
