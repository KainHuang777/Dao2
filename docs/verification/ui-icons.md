# UI-ICON-R1｜避免以字型字元代替圖示

日期：2026-09-28

## 問題與範圍

宗門歷練清單的沙漏、卷軸及其他面板的 emoji 直接寫在 Label／Button 文字中。專案中文字型是 Noto Serif TC，emoji／部分符號沒有穩定的平台字形，因此在 Godot／Web 顯示成方框。這不是來源碼亂碼，而是把圖示交給不含該字形的字型繪製。

## 修正

- `src/presentation/ui_icon.gd`：新增可縮放的 Godot `Control` 圖示，以原生繪圖 API 畫沙漏、卷軸、道觀、禮物、刷新、蓮花、星芒及箭頭。
- `src/presentation/sect_panel.gd`：進行中歷練標題與委託清單標題改用 Godot 自繪圖示；按鈕禮物／刷新符號改為 SVG 資產；移除歷練、委託與頓悟文字中的 emoji。
- `assets/ui/icons/`：新增禮物、刷新、蓮花三個小型 SVG UI 圖示。
- `src/presentation/abode_hud_controller.gd`、`src/presentation/reincarnation_panel.gd`、`src/presentation/realm_teleport_modal.gd`：移除壽元、輪迴及跨界介面的 emoji／箭頭文字字形依賴；輪迴入口使用蓮花 SVG。
- `tests/m3b_sect_ui_runner.gd`：檢查標題使用 Godot 圖示節點，且歷練面板文字沒有 emoji。

## 驗收

- Godot 4.7.2 `--headless --editor --path . --import --quit`：通過，SVG 匯入成功。
- `--headless --path . --script res://tests/m3b_sect_ui_runner.gd`：通過。
- `powershell -File .\tools\run_all_runners.ps1`：25/25 PASS，exit 0。負面輸入案例有預期錯誤診斷；另有既存 Font RID 退出診斷。
- Web Release 匯出：通過；瀏覽器視覺檢查待補。

## 邊界

這次清除了正式 GDScript 介面中找到的 emoji 字元，沒有重新設計所有介面的圖示系統。純文字星號等一般字元保留。SVG 經 Godot 正常匯入，請勿手動修改 `.godot/` 快取或匯出物。
