# M1-D 驗收紀錄｜離線收益（上限 24 小時，V2-002）

日期：2026-09-16。狀態：**DONE**（CLI／桌面路徑；瀏覽器儲存與跨程序行為未驗證）。執行方式：fusion 編排（deepseek-v4.1-flash 主導、輕量 worker 並行、auditor 獨立稽核）。

## 目標與邊界

交付背景恢復、重開共用協調器與離線摘要。政策為 v2 暫定：離線資源與修練收益只計最前 24 小時且受壽盡限制；年歲與到期效果按完整真實間隔推進；壽盡不自動輪迴。不覆蓋 M1-C 的平台儲存實作，也不宣稱瀏覽器落盤。

## 產物

- `src/simulation/offline_settlement.gd`：`CAP_MS=86400000`、`plan(now,last)`、`settle(state,content,now,last)`；收益窗走完整 per-tick，超出上限只走 `advance_time_only`；產生摘要 report。
- `src/simulation/time_advancer.gd`：新增 `advance_time_only`（只推年歲與壽盡，不產出、不修練）。
- `src/application/offline_coordinator.gd`：`settle(now_utc_ms)`——讀最後有效快照、深拷貝、結算、原子提交、回摘要；失敗不雙領。
- `src/presentation/offline_summary.gd`：最小摘要 UI；關閉只隱藏、不結算、不存檔。
- `src/domain/game_state.gd`：`duplicate_state()` 深拷貝（Amount 不共用物件）。
- `src/persistence/save_manager.gd`：`_envelope`、`last_settled_utc_ms()`、`envelope()`。
- `src/persistence/save_codec.gd`：`RULES_VERSION` 升為 `"offline-24h-1"`。
- `tests/m1d_offline_runner.gd`：契約測試。

## 驗收環境與命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1d_offline_runner.gd
& $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd
& $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd
```

2026-09-16 實測：`--import` 退出碼 0；`m1d` 退出碼 0，輸出 `PASS: M1-D offline settlement, cap 24h, cursor commit, no double grant.`；`m1c`、`m1b` 回歸退出碼 0。三者皆無 `SCRIPT ERROR`、無失敗行。（`m1c` 輸出含一行預期負向路徑的 `Marshalls.base64_to_utf8` engine ERROR，來自刻意的非法分享字串測試，非 SCRIPT ERROR。）

## DoD 對照

| 驗收 | 證據 |
| --- | --- |
| 收益計最前 24 小時、受壽盡限制 | `CAP 24H`：away 48h → `effective_ticks=1440`、`time_only_ticks=1440`；`LIFESPAN LIMIT`：Era1 於 4800 秒停止、`stopped="lifespan_exhausted"` |
| 年歲／到期推進完整間隔 | `AGE FULL INTERVAL`：era 8 下 48h → `total_elapsed_seconds=172800`（收益窗僅 1440 tick） |
| 48h 結算後立即重載不補領 | `RELOAD NO REGRANT`：commit 後重新 configure＋`load_state()` 再 settle → `away_ms==0`、`effective_ms==0`、年歲與游標不變 |
| 倒退時鐘不給收益、不倒退游標 | `ROLLBACK`：`rollback=true`、`committed=false`、游標不變 |
| 保存失敗可重試而不雙領 | `SAVE FAILURE RETRY`：注入 write 失敗 → `SAVE_FAILED`／`committed=false`、快取未動；恢復後重試 snapshot 等於單次結算 |
| 關閉摘要不觸發加獎 | `SUMMARY NO REWARD`：`offline_summary.gd` 無 `SaveManager`／`OfflineCoordinator`／`OfflineSettlement`／`.commit(`／`.save(`／`import_share_string`，關閉只改 `visible` |
| 資源與游標同一有效快照提交 | coordinator 先 `duplicate_state` 結算後才 `SaveManager.save(working, meta)`；游標 `settled_until_utc_ms=now`（含放棄區間） |
| 游標提交至 now | `CURSOR COMMIT`：結算後 `last_settled_utc_ms()==now` |
| 首局 bootstrap 不給收益 | `PLAN ARITHMETIC`／`CURSOR COMMIT`：`last<=0` → 全 0、游標提交至 now |
| 確定性 | `DETERMINISM`：相同初始 state 與 now 結算兩次 → report 與 snapshot 相等 |
| 無系統時鐘 | `NO SYSTEM CLOCK`：掃 `src/simulation` 與 `offline_coordinator.gd` 無 `Time.`／`OS.get_` |
| 深拷貝隔離 | `DUPLICATE STATE ISOLATION`：copy 與原物件不同一、資源 Amount 不共用、改 copy 不影響原快照 |

## 已知偏離與限制

1. 摘要 report 的 `left_at_utc_ms`／`settled_at_utc_ms` 為 **int**（凍結簡報原寫 String）；內部一致，摘要以 int 讀取、落盤 meta 以 `str()` 存入信封的十進位字串欄位。記為 v2 偏離。
2. `effective_ticks` 定義為收益窗換算的 ticks（`full_ticks`）；若壽盡使 `advance` 提前停止，此值不反映實際執行 tick 數（與凍結簡報一致）。摘要顯示的 `effective_ms` 不受影響。
3. 未實作／不宣稱：IndexedDB 實際落盤、兩分頁單一寫入者、跨程序關閉再開、丹藥／天時到期（`stopped` 目前僅 `lifespan_exhausted`）、自動輪迴、`advance_to` 邊界驅動與批次讓出、匯出／匯入 UI 互動。headless 契約測試非瀏覽器行為證據。
4. `rng_streams` 仍為空格式欄位（尚無 gameplay RNG）。RULES_VERSION 升版使舊 `legacy-parity-1` 存檔的版本語意改變；未提供遷移。
