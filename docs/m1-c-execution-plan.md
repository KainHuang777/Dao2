# M1-C 執行計畫（fusion 簡報）

用途：供 fusion 編排嚴格遵循。此檔凍結 M1-C 介面與規則；實作細節一律以本檔為準，不從記憶推測。對應 ROADMAP「M1-C — 新快照與平台持久化」。

## DoD（ROADMAP 原文）

- 相依：M1-A、M0-C。交付 SaveCodec、兩世代槽位、校驗與平台儲存介面、手動匯出／匯入最小 UI。
- 格式依 docs/02：schema／rules／content／Amount 版本、revision、UTC 游標、state、RNG；範例 JSON 不是有效存檔。
- Web 擇一權威儲存，確認瀏覽器實際完成訊號，不以 FileAccess 關檔推定 IndexedDB 已提交；薄 JS 平台橋接允許。
- 驗收：往返一致、寫入中斷／損壞／quota／拒絕儲存可恢復或明示失敗；不覆蓋兩份有效快照；兩分頁單一寫入者；匯入失敗保留當前進度；瀏覽器重載保持同一份 GameState。

## 環境事實（scout 已查證，勿重查）

- `project.godot` **無** `application/config/version`；`config/features` = `PackedStringArray("4.7", "GL Compatibility")`。遊戲版本以本專案常數 `GAME_VERSION := "0.1.0"` 定義於 SaveCodec。
- 既有存檔探針模式：`src/presentation/web_probe.gd`（`FileAccess.open` + `JSON.stringify` + `FileAccess.file_exists`）；`tools/test_runner.gd` 有 `close()` 與讀回驗證的 headless 範例。全專案**無** `Marshalls`／base64／ConfigFile／`JavaScriptBridge`／`HashingContext`（除 `content_loader.gd:402-405` 的 content_version SHA-256）。
- `GameState`（`src/domain/game_state.gd`）欄位：`revision:int`、`era_id:int`、`level:int`、`onboarding_version:int`、`training_seconds:float`、`total_elapsed_seconds:float`、`resources:Dictionary`（每筆 `{value:AmountCompat, unlocked:bool, ever_obtained:bool}`）、`buildings:Dictionary`（id→int）。有 `to_snapshot_dict()`，**無** inverse。
- `AmountCompat.try_parse(str) -> {ok, error?, value}`；`value.serialize() -> String`。
- `GameContent.content_version: String`（64 位小寫 SHA-256 hex）。
- `SeededRandomCompat`（`src/domain/seeded_random_compat.gd`）：`var state: int`、`static from_state(saved:int)`。目前在 `src/` 無任何使用（尚無 gameplay RNG）。**M1-C 不新增 RNG 邏輯**；`rng_streams` 僅作為格式欄位（現為空 `{}`）。
- 「權威儲存」在 docs/02 §7.1 為二選一；本任務以 Godot `user://` FileAccess 為**已驗證**路徑，IndexedDB 橋接僅提供薄骨架並**標為未驗證**（不得宣稱已落盤）。
- 縮排：`src/` 用 TAB；`tests/m1b_time_runner.gd` 用 4 空格。新檔案比照同類別既有檔。

## 凍結格式（canonical JSON；`JSON.stringify(payload, "", true)` 排序鍵）

```json
{
  "schema_version": 2,
  "game_version": "0.1.0",
  "content_version": "<64-hex>",
  "rules_version": "legacy-parity-1",
  "amount_format_version": 1,
  "generator_version": 1,
  "save_id": "local-1",
  "revision": 0,
  "saved_at_utc_ms": "0",
  "settled_until_utc_ms": "0",
  "sim_tick": "0",
  "state": {},
  "rng_streams": {},
  "last_offline_report": null,
  "checksum": "<64-hex sha256>"
}
```

- 時間與 sim_tick 一律**十進位字串**；`revision` 為整數。
- `checksum` = SHA-256 hex of `JSON.stringify(envelope_without_checksum)`（用 `HashingContext`，比照 `content_loader.gd:402-405`）。
- `state` = `GameState.to_snapshot_dict()`。

## 凍結介面

### `src/persistence/storage_adapter.gd`（orchestrator 擁有）

```
class_name StorageAdapter extends RefCounted
func read(key: String) -> Dictionary        # {ok:bool, data:String, error:String}
func write(key: String, data: String) -> Dictionary   # {ok:bool, error:String}
func erase(key: String) -> Dictionary       # {ok:bool, error:String}
func exists(key: String) -> bool
func backend_name() -> String
func is_persistent() -> bool
```

### `src/persistence/save_codec.gd`（worker-a）

```
class_name SaveCodec extends RefCounted
const SCHEMA_VERSION := 2
const GAME_VERSION := "0.1.0"
const RULES_VERSION := "legacy-parity-1"
const AMOUNT_FORMAT_VERSION := 1
const GENERATOR_VERSION := 1

static func encode(state: GameState, content_version: String, meta: Dictionary) -> Dictionary
    # meta 必須含: save_id, saved_at_utc_ms, settled_until_utc_ms, sim_tick（皆 String）
    # meta 選用: rng_streams(Dictionary, 預設 {}), last_offline_report(Variant, 預設 null)
    # 回傳 {ok:bool, json:String, error:String}
static func decode(json_text: String) -> Dictionary
    # 回傳 {ok:bool, state:GameState, envelope:Dictionary, error:String}
    # 驗證：JSON 可解析、schema_version 已知、checksum 相符、必要欄位型別；state 以 AmountCompat.try_parse 還原
static func compute_checksum(envelope_without_checksum: Dictionary) -> String
static func verify_checksum(envelope: Dictionary) -> bool
static func revision_of(envelope: Dictionary) -> int   # 無效回 -1
```

### `src/persistence/save_slots.gd`（worker-b）

```
class_name SaveSlots extends RefCounted
const SLOT_MAIN := "save_main"
const SLOT_BACKUP := "save_backup"
const INDEX_KEY := "save_index"

func _init(adapter: StorageAdapter) -> void
func commit(json_text: String, revision: int) -> Dictionary
    # 寫入「目前非最新有效」的世代；寫後讀回比對成功才更新 index
    # 回傳 {ok:bool, error:String, active_slot:String, commit_sequence:int}
func read_best(validator: Callable) -> Dictionary
    # validator: func(json:String)->int（有效回 revision，無效回 -1）
    # 讀兩槽，取通過驗證且 revision 最大者；其中一槽壞損時回另一槽
    # 回傳 {ok:bool, json:String, slot:String, revision:int, error:String}
func active_slot() -> String
func commit_sequence() -> int
func reset() -> void   # 清兩槽與 index（測試用）
```

規則：`index` 存 `{"commit_sequence":int, "active_slot":String, "revision":int}`。**同一份內容不得同時蓋掉兩個有效槽**：`commit` 只寫非 active 槽；讀回失敗時保留 active 槽並回 `ok:false`。若兩槽皆無有效內容，`read_best` 回 `ok:false`。

### `src/persistence/file_storage_adapter.gd`（worker-c）

```
class_name FileStorageAdapter extends StorageAdapter
const DEFAULT_DIR := "user://saves"
func _init(dir_path: String = DEFAULT_DIR) -> void
func path_for(key: String) -> String   # <dir>/<key>.json
```
- `write`：確保目錄存在（`DirAccess.make_dir_recursive_absolute`）→ `FileAccess.open(..., WRITE)` → `store_string` → `close()` → **再讀回比對字串**；不符或任一失敗回 `{ok:false, error}`。`is_persistent()` 回 `true`。key 需去除路徑分隔以策安全。

### `src/persistence/web_storage_adapter.gd`（worker-c）

```
class_name WebStorageAdapter extends StorageAdapter
const DEFAULT_NAMESPACE := "dao2"
func _init(namespace: String = DEFAULT_NAMESPACE) -> void
```
- 僅在 `OS.has_feature("web")` 時嘗試透過 `JavaScriptBridge` 以 IndexedDB 讀寫；以 `JavaScriptBridge.eval` 呼叫薄 JS 包裝，**必須取得實際提交訊號**才回 `ok:true`，否則回 `{ok:false, error:"..."}`。非 web 一律 `{ok:false, error:"not_web"}`，`is_persistent()` 回 `false`。
- **不得**在無確認訊號時回報成功；不得以 `FileAccess` 代替 IndexedDB。

### `src/persistence/save_manager.gd`（orchestrator 擁有）

同步 `src/presentation/save_controls.gd`（最小匯出／匯入 UI，orchestrator 擁有）。

## 檔案所有權分割（單一寫者）

| 擁有者 | 檔案 |
| --- | --- |
| worker-a | `src/persistence/save_codec.gd` |
| worker-b | `src/persistence/save_slots.gd` |
| worker-c | `src/persistence/file_storage_adapter.gd`、`src/persistence/web_storage_adapter.gd` |
| worker-d | `tests/m1c_persistence_runner.gd` |
| orchestrator | `src/persistence/storage_adapter.gd`、`src/persistence/save_manager.gd`、`src/presentation/save_controls.gd`、`src/domain/game_state.gd`、`docs/**` |

## 測試（worker-d，`tests/m1c_persistence_runner.gd`，SceneTree，4 空格縮排）

以 `FileStorageAdapter.new("user://m1c_test_slots")` 隔離，測試結束 `reset()` 清乾淨（不覆寫使用者進度）。群組：

1. CODEC ROUND TRIP：`encode`→`decode` 後 snapshot 與原 state 相等；Amount 字串保留。
2. ENVELOPE FIELDS：schema/game/rules/amount_format/generator 版本、`content_version`、`saved_at_utc_ms`/`settled_until_utc_ms`/`sim_tick` 皆十進位字串、`rng_streams` 存在。
3. CHECKSUM：正常 `verify_checksum` 為真；改動 payload 任一值後為偽，`decode` 回 `ok:false`。
4. SLOTS ROTATION：連續 `commit` 兩次 → 兩槽皆有內容、active 切換、`commit_sequence` 遞增；確認第二次 commit 未破壞另一有效槽。
5. CORRUPTION RECOVERY：破壞 active 槽字串 → `read_best` 回另一個有效槽且 revision 正確。
6. NO DOUBLE OVERWRITE：對非 active 槽寫入無效內容後 `read_best` 仍回有效內容（不兩槽皆毀）。
7. IMPORT FAILURE PRESERVES PROGRESS：以無效分享碼呼叫 `SaveManager.import_share_string` → `ok:false`，且 `SaveManager.load_state()` 結果與匯入前相同。
8. EXPORT/IMPORT ROUND TRIP：`export_share_string` → `import_share_string` → snapshot 相等。
9. REVISION SELECTION：兩槽 revision 不同且皆有效時，`read_best` 取較大者。
10. VALIDATOR REJECTION：`read_best` 傳入一律回 -1 的 validator → `ok:false`。
11. NO SYSTEM CLOCK：掃 `src/persistence` 無 `Time.`／`OS.` 系統時鐘（時間須由呼叫端注入）。

## 驗收命令（orchestrator 執行一次，序列化）

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
$out = & $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd 2>&1
$code = $LASTEXITCODE
$out | Out-File -Encoding utf8 'C:\Users\asus\AppData\Local\Temp\opencode\m1c_run.txt'
"EXIT=$code"
# 必須：EXIT=0、輸出含 PASS 行、且無 "SCRIPT ERROR"（SCRIPT ERROR 不計入 runner failures）
```

## 未實作／不宣稱（寫入 `docs/verification/m1-c.md`）

1. IndexedDB 落盤、兩分頁互斥、瀏覽器重載持續：**未驗證**，需人工步驟（提供步驟，不宣稱通過）。
2. quota／拒絕儲存的可恢復性：僅在 FileAccess 路徑以錯誤回報驗證，非瀏覽器 quota。
3. gameplay RNG 尚未存在，`rng_streams` 為空格式欄位。
4. 手動匯出／匯入 UI 為最小程式面（`save_controls.gd`），互動未在瀏覽器驗證。
