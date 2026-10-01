# M2-D-UI3：空島文字風格

2026-10-01，IN_PROGRESS：實作與原生驗證完成，使用者視覺驗收、真實 Web／手機驗證待補。

使用者要求將空島上的文字一併延伸已接受的青玉古金樣板。既有茅屋與靈木名稱改用共用九宮格銘牌、暖絹色字與柔和陰影；靈木字級由 20 調整為 22，其餘維持原尺寸。洞府題字及採集浮字沿用強調字型、暖金色與較薄的場景描邊。文字層級置於飛劍光尾上方，銘牌不接收滑鼠事件。

修改檔案：`src/presentation/ui_material.gd`、`src/abode/abode_building.gd`、`src/abode/abode_tree.gd`、`src/abode/living_abode.gd`、`tools/ui_material_preview.gd`。沿用原創 `assets/ui/material/jade_plaque.svg`；沒有新增圖形素材。建築命中區、文字內容與階數／可建／停產判斷、採集命令與收益、存檔格式保持原行為。

驗證命令與結果（引擎均為 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`）：

- `--version`：`4.7.2.stable.official.ed1daf0bf`。
- `--path . --script tools/ui_material_preview.gd -- --world-captions`：exit 0，Compatibility 原生 GPU 渲染四張圖，已檢查近景銘牌與橫向縮放；使用隔離 `user://ui_material_preview` 存檔與呈現層茅屋一階 fixture，不覆寫玩家進度。
- `tools/run_all_runners.ps1`：30/30 Runner PASS，exit 0；包括洞府建造、選取、採集、縮放與響應式 UI 回歸。此為函式／場景契約，不能代替真實滑鼠或觸控證據。
- `--headless --path . --script tests/abode_presentation_parity_runner.gd`：PASS，exit 0。
- `--headless --path . --export-release Web build/web/index.html`：exit 0；既有 4178 本機服務回應 HTTP 200。

原生圖像位於 `docs/verification/artifacts/ui-world/`：`island-1280x720.png`、`harvest-1280x720.png`、`island-844x390.png`、`captions-close-1280x720.png`。短橫向原生邏輯 viewport 為 779×360；預設鏡頭下左側 HUD 仍可能遮住茅屋，這是既有構圖現象，此次沒有宣稱解決該佈局問題。

未通過／待補：Web DPR、實際滑鼠／觸控與實體手機觀察，及本輪使用者視覺驗收。Godot 結束仍報既有 Font RID／CanvasItem／ObjectDB 資源清理訊息；測試退出碼成功不代表無警告。HTTP 200 與匯出成功也不代表已完成瀏覽器互動測試。

下一步：在 `http://127.0.0.1:4178/index.html?ui=world-20261001` 重載後驗收茅屋與靈木銘牌、縮放和採集浮字，再承接 UI2 的 Web／手機驗證與使用者回饋；不自動展開其他大型任務。
