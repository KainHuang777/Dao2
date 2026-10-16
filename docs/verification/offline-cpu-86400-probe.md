# 長離線 86400 tick 壓力 CPU 探針（有界隔離工具）

2026-10-12。RES1-C2-PERF 程式可驗證部分：本輪 fusion（scout 調查 → worker-a 新增探針 → orchestrator 序列執行 → auditor 唯讀稽核），未改任何正式遊戲來源、內容、schema 或玩家存檔。FPS 標準已依使用者 2026-10-09 下修版（尾 10 秒 >30 FPS 判恢復；`desktopRecoveryGate` 已落地），不重測嚴格 60。

## 背景

- 歷史 `RES1C_OFFLINE_CPU_MS: ~886–1500ms / 86400` 量的是**壽元截斷後的實際執行**（fixture Era1–3，壽元 12000s 即 stop；`time_only_ticks` 被 stop 短路，`offline_settlement.gd:51`）。沒有任何既有 harness 真正跑滿 86400 收益窗。
- 閉式（解析積分）方向在 `docs/02-technical-architecture.md:169` 已預設；本探針提供實測資料供使用者核定。

## 工具

`tools/offline_cpu_86400_probe.gd`（新增，唯一檔案，59 行）：SceneTree headless 探針，載入 `res1-c2-offline-fixture.json`，測試用途在記憶體副本上 `pill_effects["lifespan_bonus_years"]=100000.0` 強制壽元餘裕（`time_advancer.gd:76/lifespan.gd:25-26` 路徑），48h away → 24h cap → 86400 tick 完整收益窗，量 `settle` 與 `advance(86400)` 兩段 CPU，再量小間隔重載結算。不寫 user://，不觸玩家資料。

## 命令與結果

| 命令 | 結果 |
| --- | --- |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` | exit 0（[log](logs/offline_86400_probe_import.txt)） |
| `--headless --path . --script res://tools/offline_cpu_86400_probe.gd` | exit 0，無 SCRIPT ERROR（[log](logs/offline_86400_probe_run.txt)） |

實測（本機，隔離 fixture）：

- `PROBE_LIFESPAN_FORCED=1`；max_seconds 6,012,000，headroom 6,010,800 ticks ≫ 86400。
- **完整 86400-tick 收益窗 `settle`：4868.974 ms**（`stopped=<null>`，真正跑滿）。
- 裸 `TimeAdvancer.advance(state, content, 86400)` 粗量：5113.713 ms。
- 小間隔（11s）重載結算：3.297 ms。
- 對照：截斷版（壽盡 12000s 停）歷史約 700–1500 ms。完整窗約為其 3.5–6 倍。

## 稽核

fusion-auditor 四項全 MET（隔離性／契約列／log 實測／不碰存檔）；已知 minor：ticks 不做 quit(1) 硬斷言（觀測性探針設計）、STOPPED 分支本輪未走到。

## 結論與含义

- 完整 24h 收益窗逐 tick 結算 CPU ≈ **4.9–5.1 秒**（本機 native headless；Web WASM 會更慢），超出既有 10s ready 預算的舒適餘裕約一半，且 Web 端要吃 FrameBudget 14ms 讓出的總壁鐘更久。
- 現實玩家準則下多數回合仍在壽元邊界前停下（Era1–3 內容最多 ~44400 ticks），截斷版成本 <1.5s；但 Era3 深期 ＋ 延壽丹情境可直接逼近完整窗成本。
- 能否改走閉式路徑屬規則路徑變更，待使用者核定。低風險切點：非經濟子系統（chron 1440 邊界可 720s 週期重用 ×120）與固定乘區分段積分；難點為島嶼經濟事件流（10s 航程 / 5–30s 產線回饋）與浮點逐秒加成恆等（既有 exact-parity 測試鎖定，改乘法需記為 v2 差異）。

## 未驗證

- 瀏覽器（真實 Web WASM）完整 86400 秒結算成本與 FPS：需真實瀏覽器工具，本 session 未做，列人工步驟：啟動 `tools/island_preview_server.py` → `/metrics.html?sampleSeconds=300`（判定依 `desktopRecoveryGate`，尾 10 秒 >30 FPS）；48h fixture 上真實重載結算。
- 閉式路徑未實作，等核定。
