# RES1-C2-PERF-R2｜效能定位與修復驗收報告

日期：2026-10-05（Asia/Taipei）。**任務負責：AGY**。
依據 `AGENTS.md`、`ADR-010-idle-frame-recovery-budget.md` 與使用者指令，本輪針對持續 FPS 劣化問題進行深層迴圈排查、程式碼層級優化實作與完整測試驗證。

---

## 1. 根因剖析與定位成果 (Root Cause Analysis)

經過對 `MainLoop_runner` 呼叫鏈與 Godot 4.7.2 渲染迴圈的逐行審查，鎖定三個主要造成主迴圈長幀阻塞、排版管線壓力過重與 CanvasItem 批次繪圖負載的核心問題：

1. **`building_catalog.gd` 定時重排（Layout Reflow）風暴**：
   - **機制**：原先 `refresh()` 每 0.25 秒執行時，會無條件調用 `_update_row_overlays(id)`。該函式直接對 `ProgressBar` 的 `meter.position` 與 `meter.size` 賦值。在 Godot 4 中，對容器子 Control 覆寫尺寸與座標會強制觸發容器標記髒排版（`notification(NOTIFICATION_SORT_CHILDREN)`）並向父節點傳遞，每 0.25 秒對全部 10+ 個建築列反覆觸發 Minimum Size 重新計算。
   - **修復**：引入 `target_pos` / `target_size` 檢測，**僅在座標或尺寸發生實質改變時才賦值**。同時在建築行與資源卡片刷新中加入狀態 Signature 比對，避免在數據未變更時頻繁重新覆寫 StyleBox 與 Label。
2. **`abode_building.gd` 隱藏建築節點每幀空轉**：
   - **機制**：即使建築物未解鎖或處於不可見狀態（`visible == false`），`_process(delta)` 仍每幀更新 `clock_time`、重組字串 `caption.text`、調用 `UiMaterial.keep_world_text_readable()` 並調用 `queue_redraw()`。
   - **修復**：在 `_process` 首行加入 `if not visible: return` 提早返回，徹底阻斷不可見世界物件的無效計算。
3. **`abode_flows.gd` 祭壇粒子與飛劍 CanvasItem Immediate Draw 命令爆炸**：
   - **機制**：相容性（Compatibility Web / WebGL）渲染模式對每幀大量 Immediate 2D Primitive 繪製呼叫批次處理成本極高。
   - **修復**：常態粒子繪製與減速模式對齊（減至 0~24 顆合適數量，避免每幀百次 `draw_circle` 調用），移除冗餘高頻外圈線條。

---

## 2. 測試與驗證數據 (Verification Evidence)

### 2.1 測試套件全數通過
- **全量測試**：`tools/run_all_runners.ps1` 執行 **54/54 Runner PASS**（Exit Code 0）。
- **工具契約**：
  - `summarize_frame_metrics.py --self-test`：16 項 PASS。
  - `test_frame_metrics.mjs`：13 項 PASS。
  - `test_system_load_summary.py`：6 項 PASS。
- **Web 匯出與壓縮**：
  - `Godot Web Release export`：exit 0，生成 10,670,316 位元組 PCK。
  - `prepare_web_compression.mjs`：Brotli / Gzip 壓縮校驗通過。

### 2.2 ADR-010 幀率與恢復門檻驗證
依據 `ADR-010-idle-frame-recovery-budget.md` 標準（目標 60 FPS，容許偶發約 30 FPS 波動，但在 5 秒視窗內近目標 ≥55 FPS 時間佔比 ≥80%，末 10 秒恢復正常）：

| 觀測組別 | 觀測時長 | 實際 FPS | p95 間隔 (ms) | 最大間隔 (ms) | 接近目標時間比 | 末10秒恢復 | 判定結果 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 正常首組觀測 | 300s | 59.7436 | 16.9 | 183.4 | 100.0% | 是 | **PASS** |
| 同頁50次管理操作 | 300s | 59.5636 | 16.9 | 249.9 | 100.0% | 是 | **PASS** |
| 同頁延長連續觀測 | 300s | 59.7436 | 16.9 | 216.7 | 98.33% | 是 | **PASS** |
| 頁面重載後冷啟動 | 60s | 59.8468 | 16.9 | 33.5 | 100.0% | 是 | **PASS** |

- **`desktopRecoveryGate` 總體判定**：**`PASS`**。
- **結論**：四組測試全部符合 ADR-010 門檻，在承受定時刷新與連續管理切換操作下，完全消除每 0.25 秒強制的容器排版 reflow 與不可見物件的每幀負擔，長幀顯著平抑，主迴圈恢復穩定常態 60 FPS 水準。

---

## 3. 變更檔案清單
1. [src/presentation/building_catalog.gd](file:///e:/WORK/Dao2/src/presentation/building_catalog.gd)：新增 `_row_rendered` / `_resource_rendered` 狀態比對；優化 `_update_row_overlays()` 僅在 `position` 或 `size` 變更時賦值。
2. [src/abode/abode_building.gd](file:///e:/WORK/Dao2/src/abode/abode_building.gd)：`_process` 加入不可見提早返回。
3. [src/abode/abode_flows.gd](file:///e:/WORK/Dao2/src/abode/abode_flows.gd)：優化 Immediate Draw 呼叫頻率與粒子繪製量。
4. [docs/verification/artifacts/res1-c2-agy-r2-summary.json](file:///e:/WORK/Dao2/docs/verification/artifacts/res1-c2-agy-r2-summary.json)：ADR-010 幀統計摘要。
5. [docs/verification/artifacts/res1-c2-agy-r2-load-summary.json](file:///e:/WORK/Dao2/docs/verification/artifacts/res1-c2-agy-r2-load-summary.json)：系統負載關聯報告。
