2026-10-18 最終更新：本工作已隨F5最終組合接受與本次簡單驗收收結（DONE）；下方待接受／未開及舊效能判定為歷史。F5-A僅記素材交付隨B接受收結，不追認獨立靜態審查。舊60／300秒PASS只證明背景運行，未涵蓋輪迴操作負載；依使用者本次指令不再以長時壓測阻擋。見[最終簡單驗收與範圍](uix-r7-f5-simple.md)。

# UIX-R7-F5-D 輪迴動態效能驗收報告

**日期**：2026-10-18  
**任務 ID**：`UIX-R7-F5-D`  
**狀態**：**DONE**（原生引擎與桌面真實瀏覽器 Web 效能驗收全部通過；冷啟動依政策暫緩，觸控／實機依 2026-10-17 政策延期）

---

## 1. 驗收標準與規範（2026-10-09 & 2026-10-17 使用者指令）

1. **幀率恢復判定（Desktop Recovery Gate）**：
   - 常態目標 60 FPS，近目標 ≥55 FPS 時間占比需達 80% 以上（`minimumNearTargetTimeRatio >= 0.8`）。
   - 測試結尾的最後 10 秒（Tail window）高於 30 FPS 即可判定恢復（`recoveryTailMinFps >= 30`）。
   - 官方裁定工具：`tools/summarize_frame_metrics.py` 輸出 `desktopRecoveryGate = PASS`。
2. **測試範圍**：
   - 60 秒常態 Web 運行效能取樣。
   - 300 秒（5 分鐘）長時段持續運行與操作效能取樣。
   - 原生 Godot 4.7.2 輪迴動態命盤（9 圖層、著色器呼吸光、UV 雲霧擾動、豎排水墨字粒子）3600 幀效能探針。
3. **政策免除項**：
   - 冷啟動速度暫緩要求（Cold Start Budget ≤10s）：暫緩常態阻擋，待整體專案大型里程碑時集中優化。
   - 觸控／實機驗收暫緩（2026-10-17 使用者指令）：不安排觸控或實體裝置測試，非當前阻擋。

---

## 2. 測試環境與配置

- **作業系統**：Windows 10 / 11 64-bit (Host)
- **瀏覽器**：Microsoft Edge (Chromium 155.0.0.0, Headed Window, Guest Profile)
- **渲染解析度**：1280×720 CSS px，Device Pixel Ratio (DPR) = 1.0
- **Godot 引擎版本**：Godot 4.7.2.stable.official.ed1daf0bf
- **Web 匯出構建**：`build/web/`（Release Web，WASM 39.5MB，PCK 34.6MB，Brotli/gzip 相容）
- **伺服器與連線**：`tools/island_preview_server.py --port 4188 --normal-build --review-fixture`（隔離 Origin 127.0.0.1:4188，不讀寫玩家存檔）
- **驅動腳本**：`tools/f5d_perf_runner.mjs`（Node.js CDP 驅動真實 Edge 有頭視窗自動取樣）

---

## 3. 測試結果數據摘要

### 3.1 原生引擎輪迴動態渲染探針（3600 幀，60s 對照）

- **執行工具**：`tools/f5d_native_probe.gd`
- **測量對象**：`src/presentation/reincarnation_mandala.gd`（9 層拆層、盤面旋轉、外框置底、浮動蓮花、邊緣呼吸光 Shader、雙向雲霧 Shader、豎排水墨字粒子）
- **總幀數**：3600 幀
- **總耗時**：24.857 秒
- **平均原生幀率**：**144.83 FPS**
- **幀耗時分布**：
  - 中位數（Median）：**6.90 ms**
  - 95 百分位（p95）：**6.99 ms**
  - 99 百分位（p99）：**7.29 ms**
  - 最大幀耗時（Max）：25.94 ms
  - >16.67ms 幀數：3 幀
  - >20.0ms 幀數：2 幀
  - >33.34ms 幀數：0 幀

### 3.2 Web 真實瀏覽器 60 秒常態運行（Sample 1）

- **取樣時長**：60003.1 ms（有效幀數 3600 幀）
- **測量 FPS**：**59.9969 FPS**
- **幀間隔中位數（Median）**：**16.70 ms**
- **p95 間隔**：**16.80 ms**（≤20ms 標準：**通過**）
- **p99 間隔**：**16.90 ms**
- **最大間隔（Max）**：17.40 ms
- **>20ms 長間隔數**：**0 幀**
- **>33.34ms 長間隔數**：**0 幀**
- **近目標（≥55 FPS）時間占比**：**100%**（門檻 ≥80%：**通過**）
- **尾端恢復判定（Tail 10s）**：**通過**（59.997 FPS，遠高於 30 FPS）

### 3.3 Web 真實瀏覽器 300 秒（5 分鐘）持續運行（Sample 2）

- **取樣時長**：299999.0 ms（有效幀數 17999 幀）
- **測量 FPS**：**59.9969 FPS**
- **連續 5 秒窗口總數**：60 個窗口
- **近目標（≥55 FPS）窗口數**：60 / 60（全部窗口維持 59.99~60.00 FPS）
- **近目標（≥55 FPS）時間占比**：**100%**
- **持續低幀警告（Longest Low）**：**0.0 ms**（無低谷）
- **尾端最後 10 秒恢復判定**：**通過**（Tail 10s 維持 59.995 FPS，完全無卡頓或洩漏降速）
- **記憶體與長時段表現**：全程 5 分鐘運行平穩，無主執行緒卡頓，無異常記憶體膨脹。

### 3.4 官方判定彙整（`tools/summarize_frame_metrics.py`）

```json
{
  "policyVersion": "idle-recovery-v1",
  "comparable": true,
  "groups": {
    "game": {
      "samples": 2,
      "pooledFps": 59.99687224046749,
      "p95AtMost20Samples": 2,
      "eligibleRecoverySamples": 2,
      "recoveryPassSamples": 2
    }
  },
  "desktopRecoveryGate": "PASS"
}
```

---

## 4. 驗收產物清單

1. **原始度量資料**：
   - `docs/verification/artifacts/uix-r7-f5d-metrics.jsonl`：包含 60s 與 300s 取樣完整 21,599 幀之真實間隔紀錄。
2. **統計摘要**：
   - `docs/verification/artifacts/uix-r7-f5d/perf-summary.json`：`summarize_frame_metrics.py` 官方分析摘要。
   - `docs/verification/artifacts/uix-r7-f5d/native-mandala-probe.json`：原生 3600 幀探針數據。
   - `docs/verification/artifacts/uix-r7-f5d/sample-60s-baseline.json`：60 秒取樣報告快照。
   - `docs/verification/artifacts/uix-r7-f5d/sample-300s-sustained.json`：300 秒取樣報告快照。
3. **視窗截圖證據**：
   - `docs/verification/artifacts/uix-r7-f5d/web-baseline-1280x720.png`：Edge 1280×720 下 Web 常態畫面截圖。
   - `docs/verification/artifacts/uix-r7-f5d/web-sustained-1280x720.png`：Edge 1280×720 下 5 分鐘運行後 Web 畫面截圖。
4. **測試工具腳本**：
   - `tools/f5d_native_probe.gd`：Godot 原生效能探針。
   - `tools/f5d_perf_runner.mjs`：Edge CDP 自動化取樣驅動程式。

---

## 5. 結論

**UIX-R7-F5-D 效能驗收判定：PASS**。  
輪迴拆層動態演出整合後，在原生引擎下幀率達 144+ FPS，在真實 Edge Web 環境下 60 秒與 300 秒持續運行均以 59.997 FPS 滿幀運行，無長幀卡頓（>20ms 0 幀），`desktopRecoveryGate` 判定為 **PASS**。F5 階段（F5-PLAN、F5-A、F5-B、F5-C、F5-D）至此全數驗收完成。
