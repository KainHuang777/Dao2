# MAID-CLOSE 仙侍整批收尾驗收紀錄

- 日期：2026-11-01
- 級別：**L3 限定**——MAID 領域 runner（`-Only 'maid'`，5 支）＋當前包桌面三橫式瀏覽器點擊流程；**未跑全專案 runner 矩陣、未驗觸控**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 瀏覽器：Chrome `156.0.8078.79`（headful、獨立 profile、CDP 9251、靜態伺服器 48351）
- Node：`v20.20.0`（`--experimental-websocket`）；Python `3.14.2`
- 對應階段：[MAID-CLOSE](../development-status.md#maid-close)；前置：[R2 Web 驗收](maid-art-r2-web.md)

## 交付

- 補完前一輪未做的短橫式人物面板點擊流程：`tools/maid_art_r2_web_check.mjs` 新增 `COMPACT` 座標表（844×390、800×360）與 canvas 空間點擊／滾輪輔助。緊湊版面由 `maid_character_panel.gd` 自行重排（`_compact = bounds.size.y < 400 or bounds.size.x < 960`，隱藏標題／職稱／印章、列轉直向），不能沿用 1280×720 邏輯座標等比換算，故座標以實際截圖逐一量測。
- 每個緊湊尺寸改為完整流程：關閉離線摘要 → 遊歷→人物 → 糯美子／丹霞／青蘅 → 開啟完整立繪 → 關閉檢視器 → 初遇重溫 → 職掌（滾輪） → 羈絆（滾輪） → 關閉面板，並以截圖雜湊斷言「切換角色有變化」「立繪開關有變化」「職掌頁可捲動」「羈絆頁可捲動」。
- 未改動任何遊戲程式、規則、schema 或美術；本輪只擴充測試工具與文件。`build/web-maid-art-r2` 沿用已修正字型子集的既有匯出（見 [R2 Web 驗收](maid-art-r2-web.md)），未重新匯出。

## 命令與結果

1. `Godot … --headless --path . --script res://tools/maid_art_r2_web_fixture.gd` → `PROBE stopped=<null> maid={actions: 4, units: 20, …}`、`PASS: maid-art-r2 fixture actions=4 units=20`，exit 0。
2. `python -u tools/web_static_server.py --port 48351 --directory build/web-maid-art-r2` ＋ Chrome CDP 9251。
3. `node --experimental-websocket tools/maid_art_r2_web_check.mjs`（`OUT_DIR=docs/verification/artifacts/maid-close-web`）→ `MAID-ART-R2-WEB PASS errors=[]`：
   - `1280x720`：canvas 0,0,1279,719、無頁面溢出、`save-restored actions=4`、`save-intact-after-flow schema=6`；11 張流程截圖。
   - `844x390`：canvas 843×389、無頁面溢出、存檔還原與流程後完整；`maid-switch-differs`、`viewer-open-close-differs`、`work-page-scrolls`、`bond-page-scrolls` 皆 PASS。
   - `800x360`：canvas 799×359、無頁面溢出、存檔還原與流程後完整；同上四項斷言 PASS。
   - `console-no-script-error`：無 SCRIPT ERROR／Uncaught／TypeError。
4. `tools\run_all_runners.ps1 -Only 'maid' -TimeoutSeconds 180` → 5/5 PASS（`maid_ui` 37、`maid_core` 179、`maid_offline` 62、`maid_ui2` 56、`maid_art_r2` 78 checks，共 412 checks，failures=`[]`，無 SCRIPT ERROR）。
5. `python tools/delivery_check.py --web build/web-maid-art-r2` → RESULT PASS（Web 7/7 檔雜湊相符；`[evidence]` 變更条目 11 筆）。
6. `python tools/subset_game_fonts.py --check` → exit 0（覆蓋 1997 碼位）。
7. `git diff --check` → exit 0（僅既有 LF→CRLF 警告）。

## 證據

`docs/verification/artifacts/maid-close-web/`

- `1280x720-01…11`：關閉離線摘要、世界、人物頁、糯美子、丹霞、完整立繪開關、初遇、職掌、羈絆、關閉面板。
- `844x390-01…11`（含 `09b`／`10b` 捲動後）：同一流程於 844×390 實際點擊；`09b-work-scrolled` 露出「立即執行／清除」，`10b-bond-scrolled` 露出三章清單與狀態。
- `800x360-01…11`（含 `09b`／`10b`）：同一流程於 800×360；立繪檢視器標題「青蘅 · 完整立繪」，關閉後回人物頁。
- `maid-art-r2-web-report.json`：尺寸、逐項檢查、點擊座標與截圖清單。

## 邊界與未驗證

- 緊湊尺寸座標是依實際截圖量測的 canvas CSS 像素，若面板版面或文字長度改變需重新校準；腳本未以影像辨識自動定位。
- 短高度下人物頁小傳、職掌控制項與羈絆章節清單落在捲動區下緣，需滾輪捲動；本輪已驗可捲動且可達操作項，未改版面。
- 未跑全專案 L3 runner 矩陣與全尺寸矩陣；不宣稱「全量回歸通過」，本次範圍僅 MAID 領域與三橫式瀏覽器。
- 未驗觸控、實機、DPR 2／3、實機旋轉、FPS 或 IndexedDB 落盤（依 2026-10-17 指令延期）。
- `build/web-maid-art-r2` 為本機測試包，非交付候選包；`build/web` 未更新。`index.pck` 152.9 MB 屬已延後的冷啟動／資產預算議題。
