# M1-D 執行計畫（fusion 簡報）

用途：供 fusion 編排嚴格遵循的凍結介面與規則。對應 ROADMAP「M1-D — 離線收益」與 docs/02 §6.1–6.3。M1-D 政策為 **v2 暫定（V2-002）**，非原作 parity。

## DoD（ROADMAP.md:109-113）

- 相依 M1-B/C。交付背景恢復、重開共用協調器及離線摘要。
- 預設：收益計最前 24 小時且受壽盡限制；年歲／到期推進完整間隔；壽盡不自動輪迴。必須寫入 `rules_version` 與規則差異。
- 驗收：48 小時案例結算後立即重載不補領剩餘 24 小時；倒退時鐘不給收益也不倒退游標；保存失敗可重試而不雙領；關閉摘要不觸發加獎；資源與游標同一有效快照提交。

## 凍結時間與政策常數

- `SECONDS_PER_TICK = 60`（既有）。1 tick = 60 秒。
- 離線收益上限 `CAP_MS := 86400000`（24 小時，毫秒）。
- 游標 `settled_until_utc_ms`：信封欄位（既有），十進位字串毫秒 UTC。
- 子 tick 餘數截斷（floor）；`away_ms` 一律非負。

## 凍結介面

### `src/simulation/time_advancer.gd`（既有檔；worker-a 追加一個函式）

追加（不得改動既有函式行為）：

```
static func advance_time_only(state: GameState, content: GameContent, ticks: int) -> Dictionary
```

- 回傳形狀同既有 `advance`：`{ticks_advanced:int, events:Array, changed_ids:Array, stopped:String|null}`。
- 每 tick **只**：`state.total_elapsed_seconds += 60`，然後判壽盡（`Lifespan.is_exhausted`）；壽盡則 append `{kind:"lifespan_exhausted",...}`、`stopped="lifespan_exhausted"`、break。
- 不產出、不修練、不解鎖、不記 changed_ids（回空陣列）。
- `ticks <= 0` 回 `{ticks_advanced:0, events:[], changed_ids:[], stopped:null}` 且不動 state。

### `src/simulation/offline_settlement.gd`（新；worker-a）

```
class_name OfflineSettlement extends RefCounted
const CAP_MS := 86400000

static func plan(now_utc_ms: int, last_settled_utc_ms: int) -> Dictionary
# → {away_ms:int, effective_ms:int, forfeited_ms:int, cap_applied:bool, rollback:bool, bootstrap:bool}

static func settle(state: GameState, content: GameContent, now_utc_ms: int, last_settled_utc_ms: int) -> Dictionary
# → {report:Dictionary, stopped:String}
```

`plan` 規則：
- `last_settled_utc_ms <= 0` → `{away_ms:0, effective_ms:0, forfeited_ms:0, cap_applied:false, rollback:false, bootstrap:true}`。
- `now < last` → 全部 0、`rollback:true`、`bootstrap:false`。
- 否則 `away = now - last`、`effective = min(away, CAP_MS)`、`forfeited = away - effective`、`cap_applied = away > CAP_MS`。

`settle` 規則：
- `full_ticks = TimeAdvancer.ticks_for_elapsed(effective_ms/1000.0)`；`total_ticks = TimeAdvancer.ticks_for_elapsed(away_ms/1000.0)`；`time_only_ticks = max(0, total_ticks - full_ticks)`。
- 先 `TimeAdvancer.advance(state, content, full_ticks)`（完整：產出＋修練＋壽盡）。
- 若 `stopped == null` 且 `time_only_ticks > 0`，再 `TimeAdvancer.advance_time_only(state, content, time_only_ticks)`（年歲續推，不產出）。
- `report` 欄位（全部必填）：`left_at_utc_ms`（String，= last）、`settled_at_utc_ms`（String，= now）、`away_ms`(int)、`effective_ms`(int)、`forfeited_ms`(int)、`effective_ticks`(int)、`time_only_ticks`(int)、`cap_applied`(bool)、`rollback`(bool)、`bootstrap`(bool)、`age_seconds`(float，結算後 `state.total_elapsed_seconds`)、`stopped`(String 或 null)、`report_id`(String，`"offline:" + settled_at`）。
- **不得**使用 `Time.`／`OS.`。

### `src/application/offline_coordinator.gd`（新；worker-b）

```
class_name OfflineCoordinator extends RefCounted

static func settle(now_utc_ms: int) -> Dictionary
# → {ok:bool, report:Dictionary, error:String, committed:bool, state:GameState}
```

流程（僅呼叫靜態 `SaveManager`／`OfflineSettlement`）：
1. `var state: Variant = SaveManager.load_state()`；null → `{ok:false, error:"NO_STATE", report:{}, committed:false, state:null}`。
2. `var content = SaveManager.content()`；null → `error:"NO_CONTENT"`。
3. `var last: int = SaveManager.last_settled_utc_ms()`。
4. `var working: GameState = state.duplicate_state()`（**必須複製**，不得改動 `SaveManager` 快取物件）。
5. `var settled: Dictionary = OfflineSettlement.settle(working, content, now_utc_ms, last)`；`report = settled.report`。
6. `plan_result` 的 `rollback` 為真 → `{ok:true, report, committed:false, state:state, error:""}`（游標不倒退、不提交）。
7. 否則：`working.revision += 1`；`sim_tick = int(floor(working.total_elapsed_seconds / 60.0))`；`meta = {"save_id":"local","saved_at_utc_ms":str(now_utc_ms),"settled_until_utc_ms":str(now_utc_ms),"sim_tick":str(sim_tick),"last_offline_report":report}`；`var save_result = SaveManager.save(working, meta)`。
8. `save_result.ok` 為假 → `{ok:false, error:"SAVE_FAILED", report, committed:false, state:state}`（回傳**原始** state，重試不雙領）。
9. 成功 → `{ok:true, report, committed:true, state:working, error:""}`。

（`report.rollback` 可直接取自 `report` 欄位，不需另存 plan。）

### `src/presentation/offline_summary.gd`（新；worker-c）

```
class_name OfflineSummary extends Control
func show_report(report: Dictionary) -> void
```

- `_ready` 建 UI：Panel/VBox，標籤顯示五項——實際離開時間（`left_at_utc_ms`）、有效收益時間（`effective_ms`）、年歲變化（`age_seconds`）、到期／停止原因（`stopped`）、是否套用上限（`cap_applied`）；另有「關閉」Button。
- `show_report` 填入文字並 `visible = true`。
- 關閉只 `visible = false`；**不得**呼叫任何結算／存檔。
- 無 `Time.`／`OS.`。

### `src/domain/game_state.gd`（orchestrator）

新增 `func duplicate_state() -> GameState`：深拷貝 scalar 欄位與 `resources`（每筆 `value` 以 `AmountCompat` 的 `to_components`／`from_components` 或序列化往返複製，不得共用同一 Amount 物件）、`buildings`。

### `src/persistence/save_manager.gd`（orchestrator）

新增：`static var _envelope: Dictionary`（`_load_from_slots` 成功解碼時填入；`reset_for_tests` 清空）、`static func last_settled_utc_ms() -> int`（讀 `_envelope.get("settled_until_utc_ms","0")`，解析失敗回 0）、`static func envelope() -> Dictionary`。既有 `save(state, meta)` 成功時亦更新 `_envelope`（用 encode 的信封或直接存 meta）。

### `src/persistence/save_codec.gd`（orchestrator）

`RULES_VERSION` 由 `"legacy-parity-1"` 升為 `"offline-24h-1"`（v2 政策需版本化）。需重跑 m1c runner 確認不受影響。

## 測試（worker-d：`tests/m1d_offline_runner.gd`，4 空格縮排，SceneTree）

容器：`FileStorageAdapter.new("user://m1d_test_slots")`；`SaveManager.configure(content, adapter)`；begin/end `reset_for_tests()` + adapter 清理。輔助沿用 m1c runner（`_expect`/`_expect_equal`/`_expect_close`、`_scan_dir_for_clock`）。

群組：
1. **PLAN ARITHMETIC**：48h → away=172800000、effective=86400000、forfeited=86400000、cap_applied true；倒退（now<last）→ away 0、rollback true；bootstrap（last=0）→ away 0、bootstrap true。
2. **CAP 24H**：從 last 推進 48h → `effective_ticks == 1440`、`time_only_ticks == 1440`。
3. **REOPEN NO DOUBLE GRANT**：settle(now) 後立即再 settle(now) → 第二次 `away_ms==0`、資源與 `total_elapsed_seconds` 不變。
4. **ROLLBACK**：settle 於 `now < last` → `committed==false`，游標仍為 last（`SaveManager.last_settled_utc_ms()` 不變），資源不變。
5. **AGE FULL INTERVAL**：48h 案例後 `total_elapsed_seconds` 增加 48h（2880 ticks × 60），即使超出收益上限。
6. **LIFESPAN LIMIT**：間隔遠大於壽元（Era1 80 年=4800 秒）→ `stopped=="lifespan_exhausted"`、`total_elapsed_seconds` 停於 4800、游標仍提交至 now。
7. **SAVE FAILURE RETRY**：用內建 `class FailingAdapter extends StorageAdapter`（write 回 `{ok:false,error:"fail"}`）→ `ok==false`、`error=="SAVE_FAILED"`、`committed==false`；換回正常 adapter 重試 → 單次收益、無雙領。
8. **CURSOR COMMIT**：成功結算後 `SaveManager.last_settled_utc_ms() == now`。
9. **NO SYSTEM CLOCK**：掃 `res://src/simulation` 與 `res://src/application/offline_coordinator.gd`，禁 `Time.`／`OS.get_`。
10. **DETERMINISM**：相同初始 state 與 now 結算兩次（各自獨立 adapter/state）→ report 與 `to_snapshot_dict()` 相等。
11. **SUMMARY NO REWARD**：`OfflineSummary` 實例 `show_report(report)` 後呼叫關閉處理 → 不呼叫 SaveManager（以 spy 不可行者改為：斷言 `_on_close_pressed` 只改 `visible`，且 class 內無 `SaveManager` 字串）。

## 檔案所有權（單一寫者）

| 擁有者 | 檔案 |
| --- | --- |
| worker-a | `src/simulation/offline_settlement.gd`、`src/simulation/time_advancer.gd`（僅追加 `advance_time_only`） |
| worker-b | `src/application/offline_coordinator.gd` |
| worker-c | `src/presentation/offline_summary.gd` |
| worker-d | `tests/m1d_offline_runner.gd` |
| orchestrator | `src/domain/game_state.gd`、`src/persistence/save_manager.gd`、`src/persistence/save_codec.gd`、`docs/**` |

## 驗收命令（orchestrator 執行一次，序列化）

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1d_offline_runner.gd
& $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd
& $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd
```

需 EXIT=0、有 PASS 行、grep 無 `SCRIPT ERROR`。

## 未實作／不宣稱

- IndexedDB／瀏覽器落盤、兩分頁互斥、真實關閉再開的跨程序行為（未驗證）。丹藥／天時到期未接入（`stopped` 僅 `lifespan_exhausted`）。
- `settle` 不自動輪迴；壽盡後凍結，輪迴屬後續里程碑。
- `advance_to` 邊界驅動與批次讓出（docs/02 §6.2）非本任務；M1-D 用既有整數 tick 迴圈。
