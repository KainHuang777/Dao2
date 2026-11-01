# MAID-CLOSE 仙侍整批收尾驗收紀錄

<a id="l3-2026-11-02"></a>
## 2026-11-02 完整 L3：全專案 runner 矩陣＋全尺寸矩陣＋Web 匯出＋桌面三橫式

- 級別：**L3（完整）**——`run_all_runners.ps1 -Full` 全 170 支 runner、`DAO_VIEWPORT_MATRIX=full` 全尺寸矩陣、重新 Web 匯出、桌面 Chrome 三橫式瀏覽器流程；觸控／實機依 2026-10-17 指令延期。
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`；瀏覽器：Chrome `156.0.8078.79`（headful、獨立 profile、CDP 9252、靜態伺服器 48352）；Node `v20.20.0`（`--experimental-websocket`）；Python `3.14.2`；基準 commit `b6130f35`。
- 對應階段：[MAID-CLOSE](../development-status.md#maid-close)；前置：[R2 Web 驗收](maid-art-r2-web.md)、[2026-11-01 L3 限定輪](#l3-2026-11-01)。

### 交付

- 修正全尺寸矩陣暴露的實際版面缺陷：800×360 下人物面板的最小高度 189px 大於可用高度 156px（面板頂端 y=124、底部工具列上緣 280），`PanelContainer` 因而長出底部導覽。`src/presentation/maid_character_panel.gd` 的 `set_layout_bounds()` 在緊湊版面把名冊選擇列（青蘅／糯美子／丹霞）從第二列移入標題列，形成單列「人物／初遇重溫／職掌／羈絆＋三位仙侍」；寬式版面仍還原名冊獨立一列。修正後 800×360 最小尺寸為 620×141、面板實際 768×156，完全落在紙面內。
- 以含修正的來源重新匯出 Web 測試包 `build/web-maid-close`（非交付候選包），並重建字型子集以覆蓋仙侍新增文案碼位（1997→2048 碼位）。
- 未改規則、schema、存檔格式、美術或經濟數值；唯一遊戲程式變更為上述緊湊版面重排。`tests/maid_ui_runner.gd` 的暫用診斷輸出已移除，最終檔案與修正前語意一致。

### 命令與結果

1. 前置：`Godot … --headless --path . --import` → exit 0；`python tools/subset_game_fonts.py --check` 首次因仙侍文案缺字失敗，重建後 exit 0（`Dao2Sans-VF.ttf` sha256 `a6b632f9…f56b03`、`Dao2Serif-VF.ttf` sha256 `9d05915d…f462d`，皆覆蓋 2048 碼位）；`git diff --check` → exit 0（僅既有 LF→CRLF 警告）。`updata.txt` 檔尾多餘空行已先清除。
2. **L2（MAID 領域，1280×720）**：`tools\run_all_runners.ps1 -Only 'maid' -TimeoutSeconds 240` → 10/10 PASS：MAID-UI 53、MAID-CORE 266、MAID-OFFLINE 62、MAID-UI2 62、MAID-DUTY-PRESET 34、MAID-FIRST-MEETING 27、MAID-ART-R2 78、MAID-BOND-CG 68、MAID-BOND-CHAPTER 138、MAID-STAND 33，共 821 checks，failures=`[]`，無 SCRIPT ERROR。
3. **L3 首輪**：`tools\run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 120`（170 支、全尺寸矩陣）→ 9 支未過：`maid_ui` 為真實失敗（800×360 `page clears main navigation`，該輪 153 checks），其餘 8 支為 120 秒上限逾時（`content_p2_story_flow`、`content_p2_beasts_flow`、`content_p2_pills_flow`、`content_p2_talents_flow`、`content_p2_supply_progression`、`content_p1_accept`、`early_flow1d`、`sks_p2_flow`），逾時時皆持續推進、無 `SCRIPT ERROR`。
4. **修正後重跑**：`-Only 'maid_ui'` → 2/2 PASS（1280×720）；`-Only 'maid' -Matrix full -Parallel 3 -TimeoutSeconds 300` → 10/10 PASS（全尺寸矩陣，maid_ui 15.5s，其餘 2.8–12.7s）；修正後 800×360 的 MAID-UI 153 checks 全數通過。
5. **長流程逾時重跑**（提高上限、不變更程式）：`-Only '<8 支>' -Parallel 2 -TimeoutSeconds 600` → 7 支 PASS（story_flow 260.3s、beasts_flow 458.3s、pills_flow 493.5s、talents_flow 427.5s、content_p1_accept 158.8s、sks_p2_flow 192.0s；`early_flow1d` 見下）；`content_p2_supply_progression` 單獨以 `-TimeoutSeconds 1800` 重跑 → PASS 1135.9s。8 支中僅 `early_flow1d` 會讀 `DAO_VIEWPORT_MATRIX`（第 241／262／276 行），另以 `-Matrix full -TimeoutSeconds 900` 重跑 → PASS 134.1s；其餘 7 支不具尺寸分支，單尺寸重跑即等同全尺寸結果。首輪逾時屬 120 秒預算過緊，不是規則或 UI 回歸。
6. **Web 匯出**：`--headless --path . --export-release "Web" "build/web-maid-close/index.html"` → exit 0（`index.pck` 159,007,356 B、`index.wasm` 39,514,754 B、`index.js` 279,815 B）；`node tools/prepare_web_compression.mjs build/web-maid-close` → exit 0（br：js 64,438、wasm 7,996,785、pck 158,316,021，合計 166,377,244 B）。
7. **瀏覽器**：`tools/maid_art_r2_web_fixture.gd` → `PASS: maid-art-r2 fixture actions=4 units=20`。首次以自訂 `SAVE_NAMESPACE` 執行時存檔未還原（應用固定使用 `dao2_saves`，見 `src/abode/living_abode.gd:354`），改回預設命名空間後 `node --experimental-websocket tools/maid_art_r2_web_check.mjs` → `MAID-ART-R2-WEB PASS errors=[]`：
   - `1280×720`：canvas 0,0,1279,719、無頁面溢出、`actions=4`、流程後 schema=6。
   - `844×390`：canvas 0,0,843,389、無頁面溢出、`actions=4`、`maid-switch-differs`、`viewer-open-close-differs`、職掌／羈絆可捲動、schema=6。
   - `800×360`：canvas 0,0,799,359、無頁面溢出、`actions=4`、同上四項斷言、schema=6；截圖確認單列標題列與紙面內收束。
   - `console-no-script-error`：92 行主控台輸出，無 SCRIPT ERROR／Uncaught／TypeError。
8. **收尾**：`python tools/delivery_check.py --web build/web-maid-close` → RESULT PASS／exit 0（`[web] 7/7 files match compression.json`、`[git] 34 changed entries; head=b6130f35`、`[evidence] 2`）；`python tools/subset_game_fonts.py --check` → exit 0；`git diff --check` → exit 0。

### 證據

`docs/verification/artifacts/maid-close-web-l3/`

- 38 張截圖：1280×720 共 11 張完整流程；844×390 與 800×360 各 13 張（含 `09b`／`10b` 捲動後）。`800x360-03-characters.png` 顯示合併後單列名冊與紙面內完整小傳；`1280x720-03-characters.png` 與修正前版面一致。
- `maid-art-r2-web-report.json`（25,986 B）：尺寸、逐項檢查、點擊座標與截圖清單。
- 瀏覽器與靜態伺服器程序已於驗收後停止。

### 邊界與未驗證

- 首輪 `-Full` 的 9 支未過已逐一修正或提高上限重跑通過，但未再整批重跑第二次 `-Full`；全量結論為「170 支皆已於本輪全尺寸矩陣或等效重跑中通過」，不寫成「單次 -Full 零失敗」。
- 觸控、實機、DPR 2／3、實機旋轉、FPS 與 IndexedDB 落盤未驗（依 2026-10-17 指令延期，非當前阻擋）。
- `build/web-maid-close` 為本機測試包，非交付候選包；`index.pck` 159.0 MB 屬已延後的冷啟動／資產預算議題。
- 緊湊尺寸的瀏覽器座標仍為截圖量測值，面板版面或文案長度再變需重校。

<a id="l3-2026-11-01"></a>
## 2026-11-01（歷史：L3 限定）

- 級別：**L3 限定**——MAID 領域 runner（`-Only 'maid'`，5 支）＋當前包桌面三橫式瀏覽器點擊流程；未跑全專案 runner 矩陣、未驗觸控。
- 引擎 `4.7.2.stable.official.ed1daf0bf`；Chrome `156.0.8078.79`（CDP 9251、靜態伺服器 48351）；Node `v20.20.0`；Python `3.14.2`。前置：[R2 Web 驗收](maid-art-r2-web.md)。

### 交付

- 補完前一輪未做的短橫式人物面板點擊流程：`tools/maid_art_r2_web_check.mjs` 新增 `COMPACT` 座標表（844×390、800×360）與 canvas 空間點擊／滾輪輔助。緊湊版面由 `maid_character_panel.gd` 自行重排（`_compact = bounds.size.y < 400 or bounds.size.x < 960`，隱藏標題／職稱／印章、列轉直向），不能沿用 1280×720 邏輯座標等比換算，故座標以實際截圖逐一量測。
- 每個緊湊尺寸改為完整流程：關閉離線摘要 → 遊歷→人物 → 糯美子／丹霞／青蘅 → 開啟完整立繪 → 關閉檢視器 → 初遇重溫 → 職掌（滾輪） → 羈絆（滾輪） → 關閉面板，並以截圖雜湊斷言「切換角色有變化」「立繪開關有變化」「職掌頁可捲動」「羈絆頁可捲動」。
- 未改動任何遊戲程式、規則、schema 或美術；本輪只擴充測試工具與文件。`build/web-maid-art-r2` 沿用已修正字型子集的既有匯出（見 [R2 Web 驗收](maid-art-r2-web.md)），未重新匯出。

### 命令與結果

1. `Godot … --headless --path . --script res://tools/maid_art_r2_web_fixture.gd` → `PROBE stopped=<null> maid={actions: 4, units: 20, …}`、`PASS: maid-art-r2 fixture actions=4 units=20`，exit 0。
2. `python -u tools/web_static_server.py --port 48351 --directory build/web-maid-art-r2` ＋ Chrome CDP 9251。
3. `node --experimental-websocket tools/maid_art_r2_web_check.mjs`（`OUT_DIR=docs/verification/artifacts/maid-close-web`）→ `MAID-ART-R2-WEB PASS errors=[]`：
   - `1280x720`：canvas 0,0,1279,719、無頁面溢出、`save-restored actions=4`、`save-intact-after-flow schema=6`；11 張流程截圖。
   - `844x390`：canvas 843×389、無頁面溢出、存檔還原與流程後完整；`maid-switch-differs`、`viewer-open-close-differs`、`work-page-scrolls`、`bond-page-scrolls` 皆 PASS。
   - `800x360`：canvas 799×359、無頁面溢出、存檔還原與流程後完整；同上四項斷言 PASS。
   - `console-no-script-error`：無 SCRIPT ERROR／Uncaught／TypeError。
4. `tools\run_all_runners.ps1 -Only 'maid' -TimeoutSeconds 180` → 5/5 PASS（`maid_ui` 37、`maid_core` 179、`maid_offline` 62、`maid_ui2` 56、`maid_art_r2` 78 checks，共 412 checks，failures=`[]`，無 SCRIPT ERROR）。
5. `python tools/delivery_check.py --web build/web-maid-art-r2` → RESULT PASS（Web 7/7 檔雜湊相符；`[evidence]` 變更條目 11 筆）。
6. `python tools/subset_game_fonts.py --check` → exit 0（覆蓋 1997 碼位）。
7. `git diff --check` → exit 0（僅既有 LF→CRLF 警告）。

### 證據

`docs/verification/artifacts/maid-close-web/`

- `1280x720-01…11`：關閉離線摘要、世界、人物頁、糯美子、丹霞、完整立繪開關、初遇、職掌、羈絆、關閉面板。
- `844x390-01…11`（含 `09b`／`10b` 捲動後）：同一流程於 844×390 實際點擊；`09b-work-scrolled` 露出「立即執行／清除」，`10b-bond-scrolled` 露出三章清單與狀態。
- `800x360-01…11`（含 `09b`／`10b`）：同一流程於 800×360；立繪檢視器標題「青蘅 · 完整立繪」，關閉後回人物頁。
- `maid-art-r2-web-report.json`：尺寸、逐項檢查、點擊座標與截圖清單。

### 邊界與未驗證（歷史）

- 緊湊尺寸座標是依實際截圖量測的 canvas CSS 像素，若面板版面或文字長度改變需重新校準；腳本未以影像辨識自動定位。
- 短高度下人物頁小傳、職掌控制項與羈絆章節清單落在捲動區下緣，需滾輪捲動；本輪已驗可捲動且可達操作項，未改版面。
- 未跑全專案 L3 runner 矩陣與全尺寸矩陣；不宣稱「全量回歸通過」，該輪範圍僅 MAID 領域與三橫式瀏覽器。
- 未驗觸控、實機、DPR 2／3、實機旋轉、FPS 或 IndexedDB 落盤（依 2026-10-17 指令延期）。
- `build/web-maid-art-r2` 為本機測試包，非交付候選包；`build/web` 未更新。`index.pck` 152.9 MB 屬已延後的冷啟動／資產預算議題。
