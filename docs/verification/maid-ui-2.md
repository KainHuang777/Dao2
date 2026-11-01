# MAID-UI-2 驗收紀錄

- 日期：2026-11-01
- 級別：L2（職掌／羈絆呈現修正＋headless 覆蓋＋桌面 Chrome 1280×720 抽驗）；**未跑 L3、非交付候選包**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 瀏覽器：Chrome `156.0.8078.79`（headful、isolated profile、CDP 9243、靜態伺服器 48343）
- Node：`v20.20.0`（CDP 腳本以 `--experimental-websocket` 執行）
- 設計：[docs/49 §12](../49-maid-companion-system-design.md)

## 交付

### 呈現修正（`src/presentation/maid_character_panel.gd`）

- 回饋列由 `column` 直接子節點移入職掌／羈絆頁的捲動區（`work_box`／`bond_box` 各一），短橫式不再把頁面撐到底部工具列之下；`feedback`／`bond_feedback` 只在對應分頁且有文字時可見。
- 職掌目標 `SpinBox` 同步加上 `_last_duty_target` 與 `has_focus()` 閘門，HUD 每 0.25 秒刷新不再覆寫玩家正在輸入的數值。
- 職掌／羈絆 `ScrollContainer` 設 `follow_focus = true`，鍵盤焦點不再跑到可視區外。
- 移除狀態字串重複的「已暫停」；狀態列改用具強調字重（`UiTypography.emphasis_font()`）。
- `duty_picker` 補上與既有選單一致的 44px 列高覆寫與所選項目 tooltip。
- `duty_target` 可見性改由 `TARGET_DUTIES`（`steward_stock`／`restock_pills`）推導，不再硬編角色 id。
- 切換分頁或角色時清除殘留回饋；`work_owner.visible` 只由 `_sync()` 一處決定。

### 規則／導覽

- `src/simulation/maid_system.gd`：`status_text()` 補 `UNKNOWN_RECIPE`（配方未知）、`UNKNOWN_PILL`（丹藥未知）；`get_view()` 的配方選項改用顯示名稱，新增 `_plain_name()` 去除 catalog 名稱的 emoji 前綴（字型子集無 U+1F48A 等碼位），職掌選單不再出現 `foundation_pill` 之類原始 id。
- `src/presentation/feature_navigation.gd`：仙侍錯誤對照鍵由 `UNKNOWN_BUILDING` 改為核心實際回傳的 `BUILDING_UNKNOWN`（顯示文字不變）。

### 測試與工具

- `tests/maid_ui2_runner.gd`（新增，登錄 `tools/run_all_runners.ps1`）：職掌／羈絆分頁幾何與 44px、指派命令往返與存檔差異、暫停／恢復與拒絕字串、章節領取、招募門檻、重逢、模式切換殘留、短橫式堆疊、空 View 容錯；單尺寸執行 56 checks。
- `tools/maid_ui2_web_fixture.gd`（新增）：產生青蘅已招募、職掌執行中、離線 30 分鐘可結算的存檔，寫出 `docs/verification/artifacts/maid-ui2-duty-fixture.json`；產生前先以 `OfflineSettlement.settle` 自檢，輸出 `PASS: maid-ui2 fixture actions=4 units=20`。
- `tools/maid_ui2_web_check.mjs`（新增）：注入 fixture、等待 `ABODE_READY`、截圖離線摘要／世界／人物／職掌／羈絆，並斷言存檔內 `last_offline_report.maid.actions` 與青蘅已招募。

## 命令與結果

1. `--headless --path . --import` → exit 0。
2. `tools\run_all_runners.ps1 -Only 'maid'` → 4/4 PASS（`maid_ui`、`maid_core`、`maid_offline`、`maid_ui2`），matrix=single 1280×720；`MAID-UI2 checks=56 failures=[]`，exit 0。
3. `--headless --path . --export-release Web build/web-maid-ui2/index.html` → exit 0。
4. `node tools/prepare_web_compression.mjs build/web-maid-ui2` → exit 0；pck sha256 `43a865cd…a5b567`、br `96b36a9e…d37f8e`。
5. `python tools/maid_ui2_web_fixture.gd`（引擎 `--script`）→ `PASS: maid-ui2 fixture actions=4 units=20`，exit 0。
6. `python tools/web_static_server.py --port 48343 --directory build/web-maid-ui2` + Chrome CDP，`node --experimental-websocket tools/maid_ui2_web_check.mjs` → `MAID-UI2-WEB PASS errors=[]`（`actions=4`、青蘅已招募、console 無 SCRIPT ERROR）。
7. `python tools/delivery_check.py --web build/web-maid-ui2` → RESULT PASS（Web 7/7 檔雜湊相符）。
8. `python tools/subset_game_fonts.py --check` → exit 0（1980 碼位，未改原始字型）。
9. `git diff --check` → 無空白錯誤。

## 證據

- `docs/verification/artifacts/maid-ui2-20261101/01-offline-summary.png`：離線摘要顯示「仙侍職掌：離線完成 4 次」。
- `…/02-world.png`、`…/03-characters.png`：由遊歷進入人物頁，四分頁可切換。
- `…/04-work.png`：職掌頁狀態、生效中、目標、四操作；配方選單顯示「築基丹」。
- `…/05-bond.png`：羈絆頁「青蘅・初識 30 點」、下一階段 40 點、三章狀態。
- `…/maid-ui2-web-check.json`：步驟、斷言與 console 紀錄。
- `docs/verification/artifacts/maid-ui2-duty-fixture.json`：本次注入的存檔 fixture。

## 邊界與未驗證

- 未跑 L3、全量 runner、全尺寸矩陣；不宣稱全量回歸通過。
- 未驗證觸控、實機、DPR 2／3、窄螢幕實機旋轉、FPS 或 IndexedDB 落盤；桌面抽驗僅 1280×720 一種尺寸。
- 本次 Web 目錄是本機測試包，不是交付候選包；`build/web` 未更新。
- 糯美子／丹霞立繪與初遇 CG 仍待美術補完，重逢與羈絆只驗證呈現與命令接線。
- 桌面聚焦間距超過 60 秒改走 `OfflineCoordinator` 仍為非阻擋後續（docs/49 §11.10）。
