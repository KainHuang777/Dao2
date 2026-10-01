# M2-D-UI4：絹紙＋青玉 HUD 樣板

2026-10-01，IN_PROGRESS；使用者指定先試做同一組「修行面板＋資源區」，視覺放行及真實 Web／手機驗證待補。

修行與資源容器改用低亮度暖灰絹紙；境界用強調字型與深墨色，修煉／壽元為次級墨色，天時沿用五行色相但加深。修為晉階、突破、下一步引導與採集仍為青玉操作物件。資源頁籤只有選中項目帶玉色；未選中項目使用墨字與淡色 hover 回饋。資源列取消逐列玉石金框，改為淡底、細分隔線；滿倉為深赭文字與淡赭底，保留「滿／滿倉」及禁用「已滿」按鈕。

樣板只作用於 HUD。共用 Theme、其他功能面板、營造清單與世界銘牌保留既有樣式。資源 Grid 原已從營造簿搬到 HUD，新增 `hud_paper_resources` 開關僅在正式 HUD 啟用，獨立 catalog 元件保持原樣。版型／捲動上限與 44px 頁籤高度、命令訊號、容量判斷與存檔不變。

## 修改檔案

- `assets/ui/material/silk_panel.svg`：直接撰寫的原創九宮格 SVG，淡纖維線、柔和邊緣；來源、用途及授權邊界記錄於同目錄 `README.md`。無外部素材或圖片生成提示詞。
- `src/presentation/ui_material.gd`：局部 HUD 紙底、快取資源列與紙頁籤樣式。
- `src/presentation/abode_hud_controller.gd`：修行／資源材質、文字對比與選中頁籤。
- `src/presentation/building_catalog.gd`：HUD 資源卡局部樣式及滿倉墨色。
- `tools/ui_material_preview.gd`：追加 `--paper-hud`，隔離保存，資源三態與滿倉呈現 fixture。
- `tests/m2d_responsive_ui_runner.gd`：舊斷言寫死淺金 `f5bd71`，首次回歸因此失敗；改驗滿倉前後顏色有別、有「滿」文字及採集停用。原有互動、捲動、版型斷言保留。

## 驗證

引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` 回覆 `4.7.2.stable.official.ed1daf0bf`。

- `--headless --path . --import`：exit 0（`artifacts/ui-world/ui4-import.log`）。
- `--path . --script tools/ui_material_preview.gd -- --paper-hud`：exit 0，Compatibility GPU 原生渲染四張圖；已檢查桌面完整模式與短橫向數量模式。額外資源與滿倉只是 UI fixture，不改正式 Session，不覆寫使用者存檔。
- `tools/run_all_runners.ps1`：首次因舊滿倉色碼斷言失敗；保留 `artifacts/ui-paper/runners-first-failure.log`。修正後 30/30 Runner PASS，exit 0（`artifacts/ui-paper/runners.log`）。
- `--headless --path . --script tests/abode_presentation_parity_runner.gd`：PASS，exit 0（`artifacts/ui-paper/parity.log`）。
- `--headless --path . --export-release Web build/web/index.html`：exit 0（`artifacts/ui-paper/export.log`）；既有 4178 服務 HTTP 200。

圖像在 `artifacts/ui-paper/`：`hud-quantity-1280x720.png`、`hud-full-1280x720.png`、`hud-closed-1280x720.png`、`hud-quantity-844x390.png`。短橫向原生邏輯視口 779×360；資源仍在固定高度內捲動，不擴高遮住導航。

保留既有 Font RID／CanvasItem／ObjectDB 結束清理警告。本輪沒有真實瀏覽器輸入、DPR 或實體手機證據；HTTP 成功及 native 圖像不代表這些驗收已完成。

下一步：使用者於 `http://127.0.0.1:4178/index.html?ui=paper-20261001` 比較紙底／墨字／玉石操作層次。視覺接受後才決定延伸其他介面或竹簡條列；此輪不自動擴大範圍。

## 2026-10-01 追加：M2-D-UI4-R1 舊紙邊緣

依使用者追加要求，僅修 `assets/ui/material/silk_panel.svg`：不規則紙張輪廓、局部破角、邊緣赭黃漸層、磨損與短纖維痕跡；移除規整內框。磨損限制在原有九宮格邊緣區，中心保留清楚墨字底。256×256 來源尺寸、20px 九宮格邊界、內容內縮、元件尺寸、捲動與點選規則不變。原創 SVG 直接撰寫，來源紀錄同步於資產 README。

命令與結果：`--headless --path . --import` exit 0（`artifacts/ui-paper/aged-import.log`）；`--path . --script tools/ui_material_preview.gd -- --paper-hud` exit 0，四張原生圖重產生並複製保留在 `artifacts/ui-paper-aged/`；桌面及短橫向實際渲染已檢查。`--headless --path . --script tests/m2d_responsive_ui_runner.gd` PASS、exit 0（`artifacts/ui-paper-aged/responsive.log`）。`--headless --path . --export-release Web build/web/index.html` exit 0（`artifacts/ui-paper-aged/export.log`），本機服務 HTTP 200。未重跑全量規則測試；上節 30 Runner 是前一輪的歷史證據。既有退出資源清理警告仍保留。

此修訂 IN_PROGRESS，待使用者視覺與真實 Web／手機驗收；預覽網址 `http://127.0.0.1:4178/index.html?ui=aged-paper-20261001`。下一步先確認磨損強度，不擴大其他介面。`artifacts/ui-paper/` 的四張 HUD 圖現在反映此次追加版本，舊版邊緣形狀以歷史 SVG 修改紀錄與對話圖為準。
