# MAID-ART-ND-R2 Web／瀏覽器驗收紀錄

- 日期：2026-11-01
- 級別：Web 匯出＋桌面 Chrome 點擊流程（L3 僅限「Web 匯出與瀏覽器流程」）；**未跑全量 runner、未跑全尺寸 runner 矩陣、未驗觸控**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 瀏覽器：Chrome `156.0.8078.79`（headful、獨立 profile、CDP 9250、靜態伺服器 48350）
- Node：`v20.20.0`（`--experimental-websocket`）；Python `3.14.2`；fonttools `4.61.1`（`build/tool-deps`）
- 對應階段：[MAID-ART-ND-R2 整合](../development-status.md#maid-art-nd-r2-integration)

## 交付

### 字型子集修正（本次驗收發現並修正）

- 瀏覽器截圖顯示糯美子／丹霞小傳出現豆腐方塊；`python tools/subset_game_fonts.py --check` 失敗，列出 17 個缺字碼位（`[20123, 20180, 22696, 24398, 24590, 25569, 26202, 26228, 26564, 28855, 29105, 31449, 32631, 34261, 35504, 36084, 38506]`，含些、仔、墨、彎、怎、握、晚、晴、炷、熱、站、罷、藕、誰、賴、陪、柄）。
- 依工具既定流程以 `python tools/subset_game_fonts.py`（不帶 `--check`）重建 `assets/fonts/runtime/Dao2Sans-VF.ttf`、`Dao2Serif-VF.ttf` 與 `manifest.json`，覆蓋碼位由 1980 增至 1997；輸出 `Dao2Sans-VF.ttf` 1,029,552 B `d9af4673…573130`、`Dao2Serif-VF.ttf` 1,444,056 B `c592dade…0123cb`。重建後 `--check` exit 0。
- 原始 OFL 字型未改動；子集工具仍檢查變體軸、advance、垂直度量與 name ID 身分。

### 測試工具

- `tools/maid_art_r2_web_fixture.gd`（新增）：產生青蘅已招募、職掌執行中、離線 10 分鐘可結算的存檔，寫出 `docs/verification/artifacts/maid-art-r2-l3-fixture.json`；自檢 `PASS: maid-art-r2 fixture actions=4 units=20`（`stopped=<null>`）。既有 MAID-UI-2 fixture 產生已逾 2.5 小時，載入時按牆鐘重算會耗盡境界一壽元（停止原因：壽元耗盡）而無仙侍職掌列，故改用新的短時間 fixture。
- `tools/maid_art_r2_web_check.mjs`（新增）：注入 fixture、等待新的 `ABODE_READY:` 主控台行（避免舊行造成誤判）、以 canvas 實際矩形換算 1280×720 邏輯座標點擊、逐尺寸檢查 canvas 貼合／頁面溢出／存檔還原，並斷言流程後存檔仍完整。

## 命令與結果

1. `--headless --path . --import` → exit 0（角色圖 `.import` 已存在，重新匯入成功）。
2. `--headless --path . --export-release Web build/web-maid-art-r2/index.html` → exit 0。
3. `node tools/prepare_web_compression.mjs build/web-maid-art-r2` → exit 0；`index.pck` 152,965,544 B、sha256 `8ba70e3ce8ac645c18ebb98d6200a67b66eb9164f151307265819d1baf37d380`、br 152,271,184 B／`25bf582a…76fe2dc`；`index.wasm` br 7,996,785 B；`index.js` br 64,438 B；`br_bytes` 合計 160,332,407。
4. 引擎執行 `tools/maid_art_r2_web_fixture.gd` → `PASS: maid-art-r2 fixture actions=4 units=20`，exit 0。
5. `python tools/subset_game_fonts.py --check` → 修正前 exit 1（列出上述 17 碼位）；重建後 exit 0（1997 碼位）。
6. `python tools/web_static_server.py --port 48350 --directory build/web-maid-art-r2` ＋ Chrome CDP，`node --experimental-websocket tools/maid_art_r2_web_check.mjs` → `MAID-ART-R2-WEB PASS errors=[]`：
   - `1280x720-canvas-fits` canvas=0,0,1279,719；`-no-page-overflow` doc/inner 皆 1280×720；`-save-restored actions=4`；`-save-intact-after-flow schema=6`。
   - `844x390-canvas-fits` 843×389；`-no-page-overflow`；`-save-restored actions=4`。
   - `800x360-canvas-fits` 799×359；`-no-page-overflow`；`-save-restored actions=4`。
   - `console-no-script-error` 無 SCRIPT ERROR／Uncaught／TypeError。
7. 修正字型並重新匯出後，重跑同一腳本仍 `PASS errors=[]`，截圖中豆腐方塊消失。
8. `python tools/delivery_check.py --web build/web-maid-art-r2` → RESULT PASS（Web 7/7 檔雜湊相符）。
9. `git diff --check` → exit 0（僅既有 LF→CRLF 警告）。

## 證據

`docs/verification/artifacts/maid-art-r2-l3-web/`

- `1280x720-01-offline-summary.png`：離線摘要「仙侍職掌：離線完成 4 次」。
- `1280x720-02-world.png`、`…-11-world-after-close.png`：關閉摘要後的世界與 HUD；面板關閉後回到世界。
- `1280x720-03-characters.png`：遊歷→人物頁，青蘅立繪、小傳、引語、標籤、收束句完整。
- `1280x720-04-nuomeizi-person.png`、`…-05-danxia-person.png`：切換角色後標題、印章、立繪、小傳同步；字型修正後無缺字。
- `1280x720-06-art-viewer.png`：完整立繪檢視器標題「青蘅 · 完整立繪」，點擊立繪開啟。
- `1280x720-07-art-viewer-closed.png`：Escape 關閉檢視器回到人物頁。
- `1280x720-08-meeting.png`：初遇重溫頁 CG、說話者、台詞與選項。
- `1280x720-09-work.png`：職掌頁「青蘅（定量備料）· 已達目標 · 累計 14 次」、丹藥選單「築基丹」、目標 20、四操作。
- `1280x720-10-bond.png`：羈絆頁「青蘅・初識 30 點」、下一階段 40 點、三章狀態。
- `844x390-01-offline-summary.png`、`800x360-01-offline-summary.png`：短橫式 canvas 貼合、無頁面溢出。
- `maid-art-r2-web-report.json`：尺寸、檢查、點擊與截圖清單。
- `docs/verification/artifacts/maid-art-r2-l3-fixture.json`：本次注入的存檔 fixture。

補充（非腳本自動判定）：以滑鼠移至小傳欄後滾輪可捲動，糯美子收束句第二行「自雲海試劍之後，院裡便多了一陣清亮的劍鳴。」可完整顯示；預設視窗下該行落在捲動區下緣被裁切屬預期捲動行為，非版面錯誤。

## 邊界與未驗證

- 未跑全量 runner 與全尺寸 runner 矩陣；不宣稱全量回歸通過。runner 覆蓋仍以 `docs/verification/maid-art-nd-r2.md` 記錄的 L1 結果為準。
- 844×390／800×360 只驗 canvas 貼合、無頁面溢出與存檔還原；短橫式離線摘要關閉鈕的座標未按緊湊版面校準，因此該兩尺寸**未**執行人物面板點擊流程（未宣稱通過）。
- 未驗觸控、實機、DPR 2／3、實機旋轉、FPS 或 IndexedDB 落盤（依 2026-10-17 指令延期）。
- `build/web-maid-art-r2` 是本機測試包，不是交付候選包；`build/web` 未更新。
- `index.pck` 因 R2 角色圖增至 152.9 MB，屬已延後的冷啟動／資產預算議題，本輪不處理。
