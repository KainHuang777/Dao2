# 離線閉式分段路徑 v1（RES1-C2 跟進）

2026-10-12。使用者核定（「使用fusion skill實作閉式分段路徑」）後，以 fusion 流程（worker-a 閉式分段引擎 → worker-b 失敗改由 orchestrator 自寫，worker-c parity runner → orchestrator 整合除錯 → auditor 稽核並修復 5 個 gap）交付。**位元精確重構，非規則變更**：`docs/rule-differences.md` 無需新條目。

## 修改檔案

- `src/simulation/offline_closed_form.gd`（新增）：分段閉式推進。門檻先讀後寫（fractional_elapsed／non_layer0／fractional_buff／fractional_decision／fractional_beast／fractional_sect／fractional_scenery／fractional_fortune／no_encounters／realm_outposts）；60s 時辰／天時邊界分段；丹藥到期、壽元上限、經濟家園改動點皆為分段邊界；產率以分段重算並快取（buff/chrono 不變即重用），Amount 相加與每秒整數捷徑／非整數逐 tick 浮點微循環皆與 `_produce_prepared` 位元一致；training_seconds 逐 float 累加；fortune trigger／門派／妖獸／決策／Chrono／ viajar scenery 以 batch 等價調用。post-mutation unsupported 回傳含 `executed`。
- `src/simulation/offline_economy_jump.gd`（新增）：島嶼經濟事件跳躍。事件 tick 走 lean inline tick（tick++ → 填充乾跑後套用 → 到貨 → 完成 → 開工 → 以 ROUTES keys 出貨，與 `IslandEconomy.tick` 同序）；事件間以整數捷徑跳躍填充與倒數；失敗重試 job 的成功 tick 依 `_check_start` 門檻整數精確推導（不可推導回 -1 交由外部事件）；ints 不變量不滿足時整段退回真實 tick 迴圈（本能精確，不回 unsupported）；legacy res1-b-1（無 facilities）已 active-gate 不觸發腳本錯誤。
- `src/simulation/offline_settlement.gd`：`settle()` 改接 `OfflineClosedForm.advance`（先 `prepare_advance`），unsupported 時以 `full_ticks - executed` 餘數退回 `TimeAdvancer.advance`（消除雙重推進洞）；`advance_time_only` 與 `OfflineCoordinator.compute_async` 維持原樣，作為 parity 對照基準。
- `tests/offline_closed_form_parity_runner.gd`（新增）：850／600000／172800000（48h 全窗）三時長＋tick_remainder 0.4 的閉式 vs 逐 tick 快照／報告相等、雙跑確定性、非整數 buff 回退一致性，共 10 檢查。
- `tools/run_all_runners.ps1`：註冊新 runner（res1c2_offline 之後）。

## 命令與結果（詳 docs/verification/logs/）

| 命令 | 結果 |
| --- | --- |
| `--headless --path . --import` | exit 0（[log](logs/offline_closed_form_import.txt)） |
| `--script res://tests/offline_closed_form_parity_runner.gd` | exit 0，PASS 10 checks，無 SCRIPT ERROR：`CLOSED_FORM_MS=1395.684 REFERENCE_MS=4732.573`（[log](logs/cf_offline_closed_form_parity_runner.txt)） |
| `--script res://tools/offline_cpu_86400_probe.gd` | exit 0：`OFFLINE_CPU_86400: 1329.249 ticks=86400 stopped=<null>`（前基線 4868.974，約 **3.7×**）；`RELOAD: 1.487`（[log](logs/offline_closed_form_probe_run.txt)） |
| res1c2_offline／res1b_economy／web_persistence_fault／m1d_offline／res1c2_perf 五 runner 重跑 | 全部 exit 0，六份 log 無 SCRIPT ERROR（cf_*.txt） |
| `tools/run_all_runners.ps1` 全量 | 67 runner：基準前 43 依序全過；`early_flow1b_runner` exit 1 為**既有失敗**（foundation handoff UI 檢查，與本任務無關，先前 session 已兩次記錄）；其後 23 個逐一重跑全過（0 失敗） |

過程中發現並修正：`_lean_tick` 曾漏 economy.tick 自增與出貨迭代用 trips.keys()（parity 抓到並修復）；legacy res1-b-1 無 facilities 觸發 SCRIPT ERROR（res1b 暴露，已 active-gate）；失敗重試 job 曾迫使逐 tick（速度反劣），改為依 `_check_start` 整數推導成功 tick 後 86400 全窗由 ~4.9s 降為 ~1.3s。

## 語意邊界

- 經濟為空（未啟用 RES1-B）的存檔一律走既有 aggregate/per-tick 路徑（門檻直接 unsupported 回退），不在本任務風險面內。
- 86400 全窗真實瀏覽器 WASM 成本與 `/metrics.html?sampleSeconds=300` FPS：**2026-10-13 已實測通過**（[closed-form-web2-2026-10-13.jsonl](artifacts/closed-form-web2-2026-10-13.jsonl)、[summary](artifacts/closed-form-web2-2026-10-13-summary.txt)）。方法：隔離 origin（127.0.0.1:4183，`island_preview_server.py --normal-build --offline-fixture`，build/web 為閉式定稿後匯出）＋ CDP 驅動真實 Edge 155 guest 視窗（非 headless、非實體裝置；先清空隔離 origin 存檔再種入 48h fixture，等 `ABODE_READY` 後才取樣，修復前一批樣本 `game_not_ready_at_start` 無效問題）。結果：`valid:true` 300s／18000 幀，`desktopRecoveryGate=PASS`（59.9968 FPS，nearTargetTimeRatio 1.0，所有 5 秒窗 ≥55，尾窗通過，max frame gap 17.6ms，0 幀 >20ms，DPR 1.25，無 rAF 對照組）。48h fixture 結算（`OFFLINE_SETTLEMENT_BEGIN…END`）：Web 端 **1536.8ms**，期間 rAF 維持 ~16.7ms 節奏（intervals=80，max 16.9ms）無主執行緒卡頓；與 native 1329.249ms 一致（快於原估 WASM 3–5×）。touch／高 DPR 實體裝置、慢網與跨瀏覽器為獨立待驗項。同日更早的 [closed-form-web-2026-10-13.jsonl](artifacts/closed-form-web-2026-10-13.jsonl) 三批樣本因 `game_not_ready_at_start` 全部無效，不作放行依據。
- `docs/verification/offline-cpu-86400-probe.md` 的「閉式路徑未實作，等核定」陳述已由本任務取代。
