# M1-C 驗收紀錄｜新快照與平台持久化

日期：2026-09-16。狀態：**DONE（CLI／桌面路徑；瀏覽器儲存未驗證）**。執行方式：fusion 編排（deepseek-v4.1-flash 主導，輕量 worker 並行，auditor 獨立稽核）。

## 目標與邊界

交付 SaveCodec、兩世代槽位、校驗、平台儲存介面與手動匯出／匯入最小 UI。瀏覽器權威儲存（IndexedDB）與兩分頁互斥為本任務設計範圍，但**未在本機瀏覽器實證**，列為未驗證。

## 產物

- `src/persistence/storage_adapter.gd`：儲存介面基底（read／write／erase／exists／backend_name／is_persistent）。
- `src/persistence/save_codec.gd`：信封編碼／解碼、checksum（SHA-256）、`revision_of`。
- `src/persistence/save_slots.gd`：兩世代槽位輪替（寫入→讀回比對→才更新 index）、`read_best` 選 revision 最大且通過驗證者。
- `src/persistence/file_storage_adapter.gd`：桌面 `user://` 儲存（寫後重讀比對）。
- `src/persistence/web_storage_adapter.gd`：薄 IndexedDB 橋接（`JavaScriptBridge`，僅 web；成功需交易完成訊號，否則 `pending`）。
- `src/persistence/save_manager.gd`：組裝 content／slots／adapter；載入、存檔、匯出／匯入分享字串。
- `src/presentation/save_controls.gd`：手動匯出／匯入最小 UI（程式化 Control）。
- `tests/m1c_persistence_runner.gd`：契約測試（11 群）。

## 信封格式（docs/02 §7.1）

`schema_version`=2、`game_version`、`content_version`、`rules_version`、`amount_format_version`=1、`generator_version`、`save_id`、`revision`、`saved_at_utc_ms`／`settled_until_utc_ms`／`sim_tick`（十進位字串）、`state`、`rng_streams`、`last_offline_report`、`checksum`。checksum = SHA-256 hex of canonical `JSON.stringify`（對數字正規化後）。僅偵測損壞，非防作弊。

## 驗收環境與命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd
```

2026-09-16 實測：`--import` 退出碼 0；runner 退出碼 0，輸出 `PASS: M1-C save codec, two-slot persistence, checksum, export/import.`，無 `SCRIPT ERROR`、無 FAIL。

輸出中含一行 engine ERROR：`Marshalls.base64_to_utf8` 對刻意非法的分享字串 `INVALID_SHARE_CODE_12345` 解碼失敗——屬「匯入失敗不覆蓋進度」的預期負面路徑（`save_manager.gd` 隨即回 `ok:false`），非 SCRIPT ERROR。

## DoD 對照

| 驗收 | 證據 |
| --- | --- |
| 交付 SaveCodec、兩世代槽位、校驗、平台介面、匯出／匯入 UI | 上列產物；`save_controls.gd` 建匯出／匯入按鈕與分享字串欄 |
| 格式欄位齊備、時間為十進位字串 | `ENVELOPE FIELDS`；`decode` 的 `FIELD_TYPE:*` 驗證 |
| 往返一致 | `CODEC ROUND TRIP`：decode 後 `to_snapshot_dict()`（含 revision）與原 state 相等，`revision_of==revision` |
| 寫入中斷／損壞可恢復 | `CORRUPTION RECOVERY`：直接覆寫 active 槽為垃圾 → `read_best` 回另一槽及其 revision |
| 不覆蓋兩份有效快照 | `NO DOUBLE OVERWRITE`：壞資料寫入另一槽後 `read_best` 仍回 revision 3、內容不含 `CORRUPTED` |
| 匯入失敗保留當前進度 | `IMPORT FAILURE PRESERVES PROGRESS`：非法字串 → `ok:false`，`to_snapshot_dict()` 前後相等 |
| 匯出／匯入往返 | `EXPORT/IMPORT ROUND TRIP`：匯入 state 與匯出前相等，且 `load_state()` 未被覆寫 |
| revision 選擇 | `REVISION SELECTION`：兩槽 revision 1／2 → `read_best` 選 2 |
| 槽位輪替與 index 一致性 | `SLOTS ROTATION`：兩槽內容分別等於兩次 commit、`read_best().revision==1` |
| 驗證器拒絕 | `VALIDATOR REJECTION`：validator 恆 -1 → `read_best` 回 `ok:false` |
| 一致性防護 | `decode` 檢查 `envelope.revision == state.revision`，不符回 `REVISION_MISMATCH` |
| 無系統時鐘 | `NO SYSTEM CLOCK`：掃 `src/persistence` 無 `Time.`／`OS.get_`（`OS.has_feature` 屬合法平台判斷） |

## 設計註記

1. **數字正規化**：Godot `JSON.parse_string` 將 JSON 數字一律解析為 float，故 `int` 0 序列化為 `"0"` 但往返後為 `"0.0"`，會使 checksum 不符。`compute_checksum` 先將「有限整數值、abs<9e15」的 float 正規化為 int（Array／Dictionary 遞迴），encode 寫出的 JSON 仍保留原 int；兩側經同一正規化，故一致。
2. `rng_streams` 為信封欄位，由 `encode` 的 `meta` 提供（非 `GameState`），目前恆為空（無 gameplay RNG）。
3. `WebStorageAdapter` 僅在 `OS.has_feature("web")` 為真時運作；未取得交易完成訊號時回 `pending`，絕不以 `FileAccess.close()` 推定 IndexedDB 已提交。

## 未實作／未驗證（不宣稱通過）

1. **IndexedDB 實際落盤**：`WebStorageAdapter` 為薄骨架，未在瀏覽器實證完成訊號、quota 或 `is_persistent()` 生效。
2. **兩分頁單一寫入者**：尚無互斥機制。
3. **瀏覽器重載保持同一份 GameState**：未驗證。
4. **quota／拒絕儲存可恢復性**：僅 FileAccess 路徑有寫後比對；web quota 未測。
5. **匯出／匯入 UI 互動**：`save_controls.gd` 未掛入場景、未以滑鼠驗證。
6. checksum 非防作弊；`rng_streams` 為空格式欄位。

瀏覽器驗證人工步驟：匯出 Web 後於固定 origin 開啟，觸發一次 `SaveManager.save(...)`，確認 IndexedDB 交易完成訊號與重載後 `load_state()` 一致，再測兩分頁同時寫入與 quota；在完成前，M1-C 於瀏覽器語意的完成度應視為未驗證。
