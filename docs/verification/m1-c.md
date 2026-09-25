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

## 待執行：瀏覽器 IndexedDB 實測程序

本節是日後實測的操作單，不是已取得的證據。每次實測均須記錄日期、Web build／commit、瀏覽器版本、作業系統、完整 origin、是否無痕模式，以及畫面或 DevTools 證據。不可用 `file://` 開啟，也不可在一次案例中混用 `127.0.0.1`、`localhost`、區網 IP 或不同瀏覽器：它們各自是不同 origin／儲存空間。

### A. 建立可重現的測試 origin

1. 匯出 Web release；在正常瀏覽器設定檔（非無痕）用 HTTP 服務開啟。桌面可用專案既有的 `start_web_server.bat`，網址為 `http://127.0.0.1:4175/index.html`。
2. 手機實測不可使用手機自身的 `127.0.0.1`；以 `python -m http.server 4175 --bind 0.0.0.0 --directory .\\build\\web` 提供區網服務，手機與電腦連同一私有網路後，以 `http://<電腦IPv4>:4175/index.html` 開啟。若 Windows 防火牆詢問，只允許私人網路。
3. 需要乾淨新檔時，僅清除這個**測試 origin** 的網站資料；不可清除正式使用者 origin 的資料。記錄清除動作與測試起點。

### B. 正常寫入、實際提交與重載

1. 由新檔建造茅屋並升級一次，再採集幾次金錢；等待至少 16 秒，確保自動存檔有機會觸發。記錄境界、茅屋等級、已建建築、各關鍵資源和時間。
2. 在桌面 Chrome／Edge 開啟 DevTools 的 `Application → Storage → IndexedDB → dao2_saves → kv`，確認有索引與至少一份有效快照；擷取畫面。Android 實機可透過 USB 偵錯，在桌面 Chrome 的 `chrome://inspect/#devices` 遠端檢視同一分頁後檢查。
3. 確認寫入已收到 IndexedDB transaction 的完成成功訊號；只有資料列暫時存在，或只看到 `pending`／錯誤，均不算通過。重新整理後立即再次確認遊戲狀態；再關閉全部該 origin 的分頁、重新開啟同一完整網址並確認狀態一致。為避免離線結算干擾，比對建築、境界與解鎖狀態；資源只可依已知離線規則增加，不可倒退或回到新檔。
4. 把每項結果填入下表。只有 A～C 均成功，才能把「IndexedDB 實際落盤」和「瀏覽器重載保持同一份 GameState」從未驗證改為通過。

| 日期 | Build／commit | 瀏覽器／裝置 | 完整 origin | 寫入完成訊號 | `dao2_saves/kv` 證據 | 重整／關閉重開結果 | 結論／證據連結 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 待驗證 | — | — | — | — | — | — | — |

### C. 失敗與多分頁案例（獨立列為未通過，不能由 B 推定）

1. 測試儲存被拒絕或 quota 不足時，遊戲必須明示失敗、保留兩份有效快照，且在恢復可寫後能安全重試；記錄瀏覽器的實際模擬／限制方式。
2. 以兩個分頁同時開啟同一 origin，分別做不同寫入並重開驗證。現況尚無單一寫入者互斥機制，因此此案例預期仍為**未驗證／不可宣稱通過**；實測只用來取得後續修正所需證據，不可覆寫使用者進度。