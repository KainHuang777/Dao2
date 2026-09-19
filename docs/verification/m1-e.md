# M1-E 驗收紀錄｜舊檔遷移（支援範圍獨立公布）

日期：2026-09-16。狀態：**DONE**（CLI／桌面路徑；瀏覽器 UI 與真實 corpus 未驗證）。執行方式：fusion 編排（deepseek-v4.1-flash 主導，輕量 worker 並行，fusion-auditor 獨立稽核）。

## 目標與邊界

交付 LegacyImporter、去識別化隔離樣本與 `docs/legacy-compatibility.md` 支援矩陣。匯入為**使用者主動貼上／選檔**：先在記憶體解碼、驗證並產生差異報告，成功才另存**新槽位**，並保留匯入原文。**不自動讀取舊站 origin 的 localStorage**；單一分享碼不含全部靈獸資料；首次匯入**不按舊時間戳補算**（`backfill_policy="none"`）。

## 產物

- `src/persistence/legacy_importer.gd`：`LegacyImporter`——`decode_input`（raw JSON 或標準 Base64）、`is_base64`、`deserialize_amount`（字串／數字／`{sign,mag,layer}`）、`build_report`（17 鍵差異報告，含未知 ID、金額問題、高階層、缺失欄位、警告）、`map_state`（依 content 全量預建，未知 ID 不寫入）、`import_text`。
- `src/persistence/save_manager.gd`：`LEGACY_RAW_KEY`、`import_legacy_text()`（原文另存、`revision=max(prev+1,1)`、提交新槽、**不覆寫 `_current_state`**）、`legacy_raw()`。
- `src/presentation/save_controls.gd`：最小舊檔匯入 UI（顯示來源格式、未知資源／建築、數值問題、高階數）。
- `tests/fixtures/legacy/import_samples/`：9 個隔離樣本（compact 開局、Base64 中期、長鍵中期、輪迴、大數、靈獸缺欄、未知 ID、截斷損壞、損壞 JSON）。
- `tests/m1e_import_runner.gd`：契約測試（16 群）。
- `docs/legacy-compatibility.md`：來源事實、支援／部分／拒絕 14 列矩陣、匯入政策、已知限制、證據 file:line。

## 驗收環境與命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1e_import_runner.gd
& $daoEngine --headless --path . --script res://tests/m1d_offline_runner.gd
& $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd
& $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd
```

2026-09-16 實測：`--import` 退出碼 0；`m1e_import_runner.gd` 退出碼 0，輸出 `PASS: M1-E legacy import decode, mapping, reports, and slot commit.`；m1d／m1c／m1b 回歸皆退出碼 0、各 PASS=1、**無 `SCRIPT ERROR`**。輸出檔：`C:\Users\asus\AppData\Local\Temp\opencode\m1e_run3_m1e.txt` 等。輸出含兩條**預期負向路徑**的 engine ERROR（損壞 Base64、損壞 JSON），非 SCRIPT ERROR。

## DoD 對照

| 驗收 | 證據 |
| --- | --- |
| 舊 JSON／UTF-8 Base64 | `DECODE JSON`／`DECODE BASE64`；`compact_midgame.b64.txt` 標準 Base64 重建 era2/level4/HUD 值 |
| 短鍵／已核對長鍵 | `FORMAT DETECTION`（`compact = v||p||r`）、`LONG KEY MAPPING`；`s`=sect（更正 docs §7.2「s／skills」） |
| 開局 | `compact_opening.json`→`MAPPING CORE` |
| 中期 | `compact_midgame`／`long_midgame.json` |
| 輪迴 | `long_reincarnation.json`（rebirthCount 23、era clamp） |
| 大數 | `BIGNUM`：`"1e1000"`、`"ee5"`（compare 到 `1e100000`）、`{sign,mag,layer}`、`"ee20"`→`high_layer_amounts` `wood:layer=2` |
| 靈獸缺欄 | `MISSING BEAST`→`BEAST_DATA_MISSING` 警告，不中斷 |
| 未知 ID | `UNKNOWN IDS`：`ghost_crystal`／`void_essence`／`dark_pagoda`／`spirit_spring` 列報告、不寫入狀態 |
| 損壞檔 | `CORRUPT`：截斷 Base64／損壞 JSON 回具名錯誤，不靜默 |
| 匯入前預覽差異 | `build_report` 17 鍵；`REPORT DETERMINISM` 重算相等 |
| 成功另存新槽 | `IMPORT NEW SLOT`：`import_legacy_text` 提交，`load_state()` 可見 |
| 保留原文 | `IMPORT PRESERVES RAW`：`legacy_raw() == raw_json`（JSON 與 Base64 兩路徑） |
| 不按舊時間戳補算 | `BACKFILL POLICY`：`backfill_policy="none"`，`last_settled_utc_ms()==0` |
| domain/persistence 不讀系統鐘 | `NO SYSTEM CLOCK` 掃描 |

## 已知偏離與缺口（auditor 標記，非阻礙）

1. `report` 的 `left_at_utc_ms` 等時間欄位在此路徑僅為來源時間 `source_timestamp_ms`（不消費）；信封 meta 之 `saved_at_utc_ms`／`settled_until_utc_ms` 固定 `"0"`。
2. `runner` 匯入新槽僅斷言 `revision>=1`，未預置高 revision 槽驗 `revision==prev+1`（實作正確，缺直接測試）。
3. 無「匯入失敗後 progress／槽未被動」的直接斷言（`_current_state` 於匯入路徑從未被賦值，屬結構保證）。
4. `_strip_whitespace` 去除全文所有 `\s+`（含引號內字串），依凍結簡報規定；名稱含空白時可能與舊站不同。
5. `SUPPORTED_VERSION="1.0"` 宣告但未強制；非 "1.0" 仍按已知欄位處理（矩陣自記為有意政策）。

## 未實作／不宣稱

1. 瀏覽器 UI 互動（`save_controls.gd` 舊檔匯入按鈕）未驗證；headless 測試非畫面證據。
2. 真實舊存檔 corpus：樣本為依規格手工去識別化，非真實使用者存檔；`~20000` 字元截斷為舊站限制。
3. AmountCompat layer>3 算術、`break_eternity` 全 API（ADR-008）與 byte-for-byte 文字相容未承諾。
4. 靈獸進度：舊分享碼寫入但從未被讀取，跨裝置僅憑分享碼會遺失獸資料。
5. 門派（sect）、技能、天賦、丹藥、道心／道證、成就等欄位僅列入報告，不映射（矩陣標 `rejected`／`partial`）。
