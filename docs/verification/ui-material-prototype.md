# M2-D-UI1 Godot 原生介面材質樣板

2026-09-30 — IN_PROGRESS：實作與 CLI 回歸完成，使用者視覺驗收、Web／手機驗證待補。

## 交付範圍

- 修行面板：原創青玉漸層、古金雙層包邊、角飾；同面板操作按鈕採玉牌。
- 一張營造列：僅 `hut` 茅屋套淡絹紙、深色文字；需求條保持狀態語意，以玉綠／赭色顯示。
- 底部導航：空島、營造、神識展開、更多功能採玉牌；沿用既有 disabled 表示當前分頁，提供高亮選中材質。
- 新增 `UiMaterial` 共用快取材質，使用 StyleBoxTexture 九宮格；文字、容器與輸入節點獨立。沒有加入 shader 動畫、粒子或演出時間依賴。

修改：`src/presentation/abode_hud_controller.gd`、`src/presentation/building_catalog.gd`；新增 `src/presentation/ui_material.gd`（含 Godot 生成 UID）、`assets/ui/material/` 三張原創 SVG／匯入設定與來源說明、`tools/ui_material_preview.gd`、本頁與驗收 artifacts。同步 Roadmap、development-status、updata。未修改遊戲規則或存檔格式，未寫入 GodTower。

## 命令與結果

使用現有 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`：

- `--headless --editor --path . --import --quit`：exit 0，SVG 匯入與腳本類別註冊成功。
- `--path . --script res://tools/ui_material_preview.gd`：exit 0，Compatibility、NVIDIA GTX 1660 Ti 真實渲染；取得四張截圖。腳本僅使用 `user://ui_material_preview`，暫停場景時間，於预覽隱藏開機摘要；不改正式場景摘要行為。結束清空該隔離測試槽。
- `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd`：PASS，exit 0。
- `powershell -File tools/run_all_runners.ps1`：28/28 PASS，exit 0；完整輸出 `artifacts/ui-material/runners.log`。
- `--headless --path . --script res://tests/abode_presentation_parity_runner.gd`：PASS，exit 0；`artifacts/ui-material/parity.log`。
- `--headless --path . --export-release Web build/web/index.html`：exit 0；`artifacts/ui-material/export.log`。
- `git diff --check -- src/presentation/abode_hud_controller.gd src/presentation/building_catalog.gd`：exit 0。本輪前已存在的全工作區 EOF 空白於 AGENTS.md、ai-handoff.md、game_state.gd 未代為修改；全工作區 diff check 不能稱全通過。
- Python `-m http.server 4178 --bind 127.0.0.1 --directory E:\WORK\Dao2\build\web`：隱藏背景啟動，PID 278200；HTTP 200。本機試玩 http://127.0.0.1:4178/index.html；獨立 origin 不沿用 4175 的進度。open_in_codex 回覆 queued，不宣稱已完成瀏覽器載入。

Runner／預覽結束仍輸出既有 Font RID、CanvasItem／ObjectDB 清理診斷，不代表沒有退出資源警告；未出現新腳本編譯錯誤。

## 視覺證據與限制

已實際讀取並檢查 Godot 渲染圖片：

- [桌面空島](artifacts/ui-material/home-1280x720.png)
- [桌面營造](artifacts/ui-material/catalog-1280x720.png)
- [橫向空島](artifacts/ui-material/home-844x390.png)
- [橫向營造](artifacts/ui-material/catalog-844x390.png)

桌面視窗 1280×720／邏輯 viewport 1280×720；橫向視窗 844×390／邏輯 viewport 779×360（由既有自適應縮放決定），截圖檔為 844×390。實際觀察：修行文字位於實底內；導航與茅屋樣板未裁切；選中態可辨識；新材質的飾角隨九宮格保留比例。這些是 native Godot 截圖，並非 Web 截圖，也不是即時滑鼠命中證據。

CUA 建立 iab 頁面因 `helper_unknown_error: setup refresh had errors` 失敗，未取得真實瀏覽器互動／DPR 證據。使用者視覺喜好、實體手機觸控、GPU 效能、p95、下載量與高 DPI 平滑度尚待驗證。無法據此宣稱消除所有鋸齒、FPS 改善或全装置 DoD 通過。

下一步：在試玩頁切換空島／營造、查看與建造茅屋、點神識／更多、切低特效；於 1280×720 與手機橫向檢查材質、字體和命中。根據使用者視覺回饋修訂這三處，未放行前不擴展至全介面或下個大型任務。

2026-10-01 追加：使用者已明確驗收本樣板視覺 OK，並授權延伸至其他核心介面。使用者視覺方向已放行；原 Web／DPR／實體手機待驗邊界保留。後續實作見 [M2-D-UI2](ui-core-materials.md)。
