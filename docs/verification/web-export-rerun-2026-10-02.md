# Web 匯出與 CLI 驗證重跑（UI7／FX2／TEXT1 回饋前置）

任務 ID／日期／狀態：WEB-RERUN-1／2026-10-02／CLI 部分完成，瀏覽器互動與真機待驗。

## 目標與非目標

- 目標：在本機 clone（D:\Temp\temp\Dao2，ENV-CLONE-1 後）重跑固定驗證入口，重新產出 Web 匯出與 native 證據，為 UI7／FX2／TEXT1 的視覺回饋與瀏覽器驗收提供最新基底。
- 非目標：不改任何 src／測試／資產；不做高 DPR、實體觸控、GPU 效能、FPS 與 IndexedDB 落盤宣稱；不動玩家存檔 origin。

## 驗收環境

- 引擎：`tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`，exit 0。
- OS：Windows；GPU：GTX 1050（OpenGL API 3.3.0 Compatibility）；Python 3.9.13（HTTP 服務）。
- Git HEAD：`b9f6685`（乾淨 clone；工作區另有 18 行既有變更，本任務未新增 src 修改）。

## 命令／退出碼／結果

- `--headless --path . --import`：exit 0（3 個 PNG 重掃描）。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`（僅本程序 Bypass）：**34/34 PASS、exit 0**。既有 Font RID／CanvasItem／ObjectDB 退出警告與 M1-C／M1-E 負面 fixture 預期錯誤照舊，不記為新失敗。
- `--headless --script res://tests/abode_presentation_parity_runner.gd`：PASS、exit 0。
- `--headless --path . --export-release Web '--build/web/index.html'`：exit 0（102 檔）；`index.html` 0.01MB、`index.pck` 32.17MB、`index.wasm` 37.68MB。build/web 此前不存在（build 被 gitignore），本輪為本 clone 首次匯出。
- Native 預覽（真實 GPU 渲染，均 exit 0）：
  - `tools/ui_material_preview.gd -- --quiet-material --guidance-hud`：5 張新 PNG 到 `artifacts/ui-quiet/guidance/`（11:10）；`core/` 既有 16 張（09:05）未重跑。
  - `tools/breakthrough_fx_preview.gd`：8 張新 PNG 到 `artifacts/breakthrough-fx2/`（era2/8/12/reduced × 1280×720 與 844×390；物理 844 對應邏輯 779×360）。
  - `tools/text_transition_preview.gd`：4 張新 PNG 到 `artifacts/text-transition/`（reveal/hold × 兩尺寸）。
- HTTP 服務：port 4175 啟動前確認空閒；`python -m http.server 4175 --bind 127.0.0.1 --directory D:\Temp\temp\Dao2\build\web`，監聽確認後 `GET /index.html` = **200（5464 bytes）**。首啟失敗原因：`Start-Process` 相對路徑引數致服務未綁定，改前景 job＋絕對路徑重啟成功；已如實記錄。

## 固定 origin 政策

- 本輪驗收 origin 為 `http://127.0.0.1:4175`（接手文件建議值）；4178（歷史正式預覽）與 4182（UI7 隔離預覽）保持空閒，舊存檔不受影響。換 port 會連到不同 IndexedDB origin，存檔驗收須固定 4175。

## 未驗項與下一步

1. 真實瀏覽器互動（滑鼠命中、拖曳／縮放、UI7 選中態、FX2 重溫突破、TEXT1 試播與 Esc 跳過）尚未在本輪執行；無瀏覽器自動化時提供人工步驟並標待驗。
2. 高 DPR、實體手機觸控／GPU、FPS／p95、冷啟動、長期記憶體：未測。
3. 既有退出警告（RID／CanvasItem／ObjectDB）與負面 fixture 錯誤持續存在，不构成「日誌零錯誤」。
4. 下一步：使用者實際開 `http://127.0.0.1:4175/index.html` 收 UI7／FX2／TEXT1 視覺回饋；回饋後在新對話微調或進 M3-B 靈獸／成就。
