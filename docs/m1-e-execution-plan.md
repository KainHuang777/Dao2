# M1-E 執行計畫（fusion 簡報：舊檔匯入）

用途：供 fusion 編排嚴格遵循。此檔凍結 M1-E 的介面、映射規則、樣本清單與驗收命令。研究依據見 `docs/02-technical-architecture.md` §7.1／§7.2、`docs/decisions/ADR-008-amount-rng-probe-boundary.md`、以及 scout 對唯讀 `E:\Python\test1`（cultivation-game v0.46.6）的實證（摘要見本檔末）。

## DoD（ROADMAP M1-E）

交付 LegacyImporter、隔離樣本、`docs/legacy-compatibility.md` 的支援／部分／拒絕矩陣。驗收：舊 JSON／UTF-8 Base64、短鍵／已核對長鍵、開局／中期／輪迴／大數／靈獸缺欄／未知 ID／損壞檔。匯入前預覽差異、成功另存新槽、保留原文。不自動讀舊站 localStorage。首次匯入補算政策先記錄，不得按多年舊時間戳補獎。

## 舊格式事實（worker 必須照用）

- 分享碼＝**標準 Base64**（非 URL-safe）包 UTF-8 JSON；localStorage 存**純 JSON**。兩者內容同構。
- 格式版本 `"1.0"`；舊版遊戲 0.46.6。
- compact 頂層鍵：`v`(version)、`o`(onboardingVersion)、`t`(timestamp ms)、`p`(player 長名稱物件)、`r`(resources)、`b`(buildings)、`s`(**sect**)、`beastData`。長形式則為 `version/o/timestamp/player/resources/buildings/sect/beast`。
- compact 判定：`data.v || data.p || data.r` 存在即 compact。
- **`s` 是 sect，不是 skills**；skills 在 `p.learnedSkills`。docs §7.2 該列有誤，本任務以實作為準。
- `r[id]`＝`{v,u,e}`（value 為 Decimal 字串、unlocked、everObtained；`u`/`e` 為 1/0 或 true/false）；長形式為 `{value,unlocked,everObtained,...}`；`max`/`rate` 不存，重算。
- `b`＝`{b:{id:level}, m, ab, at, db}`；reader 亦接受 `id={id,level}`。
- 所有 Decimal 金額為**字串**（break_eternity `toString`），layer≥2 會是 `"ee5"` 之類；亦容忍 `{sign,mag,layer}` 物件。
- 資源／建築 ID 即 CSV id；未知 ID 不得寫入狀態，只列入報告。
- 分享碼不含 settings、language、sect.activeEvent、實際獸進度（`beastData` 舊版寫而不讀）。

## 凍結介面

### `src/persistence/legacy_importer.gd`（class_name LegacyImporter extends RefCounted）— worker-a

常數：`const SUPPORTED_VERSION := "1.0"`、`const BACKFILL_POLICY := "none"`。

- `static func decode_input(input_text: String) -> Dictionary`
  回 `{ok:bool, error:String, raw_json:String}`。規則：去除所有空白；空→`EMPTY`；以 `{` 開頭→`raw_json` 即該文字；否則若 `is_base64`→以 `Marshalls.base64_to_utf8` 解碼，非空→`raw_json`，空→`BASE64_DECODE`；否則→`NOT_JSON_OR_BASE64`。（先做 base64 字元集檢查，避免對非法字串呼叫解碼器噴 engine ERROR。）
- `static func is_base64(text: String) -> bool`（僅 `A-Za-z0-9+/=`、長度>0）。
- `static func deserialize_amount(raw: Variant) -> Dictionary`
  回 `{ok:bool, error:String, value:AmountCompat, layer:int, form:String}`。String→`AmountCompat.try_parse`（失敗 `INVALID_AMOUNT`）；int/float→`AmountCompat.from_number`（form `"number"`）；Dictionary 且有 `sign`/`mag`/`layer`→`AmountCompat.from_components(sign, layer, mag)`（form `"components"`）；其餘→`INVALID_AMOUNT`。`layer` 取 `value.layer`（AmountCompat 屬性；若無公開屬性則用 `to_components()`）。
- `static func build_report(data: Dictionary, content: GameContent) -> Dictionary`
  純分類，不建 state。回傳鍵（全部存在，陣列需**排序**以求確定性）：
  `source_format`(="compact"|"long")、`format_version`(String，`v||version||""`)、`source_timestamp_ms`(int)、`has_version`/`has_player`/`has_resources`/`has_buildings`/`has_sect`/`has_beast`(bool)、`mapped_fields`(Array[String])、`ignored_fields`(Array[String])、`unknown_resource_ids`、`unknown_building_ids`、`missing_fields`(Array[String])、`amount_issues`(Array[String]，`"<id>:<error>"`)、`high_layer_amounts`(Array[String]，`"<id>:layer=<n>"`，n≥2)、`warnings`(Array[String])、`backfill_policy`(="none")。
- `static func map_state(data: Dictionary, content: GameContent, report: Dictionary) -> GameState`
  - `era_id = max(1, int(player.eraId ?? 1))`；`level = max(1, int(player.level ?? 1))`；`onboarding_version = int(data.o ?? data.onboardingVersion ?? 0)`。
  - resources：先以 `content.resource_ids` 建全 0／`unlocked=false`／`ever_obtained=false`；再對 legacy map 中**已知** id 套 `value`(經 `deserialize_amount`)、`unlocked`、`ever_obtained`。未知 id 不加入。
  - buildings：先以 `content.building_ids` 建 0；對已知 legacy 項套 `int(level)`（≥0）。
  - `training_seconds = 0.0`、`total_elapsed_seconds = 0.0`、`revision = 0`（**不補算**）。
- `static func import_text(input_text: String, content: GameContent) -> Dictionary`
  回 `{ok:bool, error:String, report:Dictionary, state:GameState, raw_json:String}`。流程：`decode_input`→`JSON.parse_string(raw_json)`（非 Dictionary→`JSON_PARSE`／`NOT_OBJECT`）→`build_report`→`map_state`。成功 `ok:true`。
- 禁止 `Time.`／`OS.`（除 `Marshalls` 外不得用系統時鐘）。

### `src/persistence/save_manager.gd`（orchestrator）新增

- `const LEGACY_RAW_KEY := "legacy_import_raw"`
- `static var _adapter: StorageAdapter`（`configure`／`slots()` 時設定）。
- `static func import_legacy_text(input_text: String) -> Dictionary`
  回 `{ok, error, report, state}`。`LegacyImporter.import_text` 失敗即回；成功則：把 `raw_json` 以 `_adapter.write(LEGACY_RAW_KEY, raw_json)` 留存（供恢復）；設 `state.revision = max(目前 read_best 的 revision + 1, 1)`（使匯入成為最新，但**不覆寫 `_current_state`**）；`SaveCodec.encode`+`slots().commit`；meta 的 `settled_until_utc_ms="0"`、`saved_at_utc_ms="0"`（不補算政策）。
- `static func legacy_raw() -> String`（讀 `LEGACY_RAW_KEY`，缺→`""`）。
- `reset_for_tests()` 一併清 `_adapter`。

### `src/presentation/save_controls.gd`（orchestrator）新增

最小「匯入舊存檔」按鈕＋預覽 Label：呼叫 `SaveManager.import_legacy_text`，顯示 `report.source_format`、未知 ID 數、`amount_issues` 數、`high_layer_amounts` 數，成功顯示「已匯入並另存新槽」。（UI 互動不列入本輪驗證。）

### `tests/m1e_import_runner.gd`（worker-b，4 空格縮排，extends SceneTree）— worker-b

樣本放 `tests/fixtures/legacy/import_samples/`，**全為去識別化／依規格手構**，不得複製真實玩家檔。清單：
- `compact_opening.json`（compact：`v`/`o`/`t`/`p`(eraId 1, level 1)/`r`(lingli 少量)/`b`）
- `compact_midgame.b64.txt`（上者擴充為中期＋`"1e1000"` 大數，**標準 Base64**）
- `long_midgame.json`（長形式：`version`/`timestamp`/`player`(含 learnedSkills、daoHeart/daoProof 字串)/`resources`(長鍵 value/unlocked/everObtained)/`buildings`(長嵌套 `{id:{id,level}}`)/`sect`）
- `long_reincarnation.json`（`rebirthCount`>0、`highestEraEver`>1）
- `long_bignum.json`（資源值 `"ee5"` 及 `{sign:1,mag:5,layer:2}` 各一）
- `long_beast_missing.json`（無 `beastData`，其餘齊全）
- `unknown_ids.json`（含未知資源與未知建築 id）
- `corrupt_truncated.txt`（截斷的 base64 → invalid JSON）
- `corrupt_json.json`（`{` 開頭但壞 JSON）

測試群（至少）：DECODE JSON／DECODE BASE64／空與非法輸入／FORMAT DETECTION（compact vs long）／MAPPING CORE（era_id/level/onboarding/resources/buildings）／LONG KEY MAPPING（value/unlocked/everObtained、`{id:{id,level}}`）／UNKNOWN IDS（只入報告）／MISSING BEAST（`has_beast=false`、build 成功、warnings 記）／BIGNUM（`1e1000` ok；`ee5`→`high_layer_amounts` 含 layer≥2；`{sign,mag,layer}` ok）／INVALID AMOUNT（`amount_issues` 記、不靜默歸零）／CORRUPT（`ok:false`、無 crash）／REPORT DETERMINISM（同輸入兩次 report 相等）／IMPORT PRESERVES RAW（`SaveManager.legacy_raw()` 等於 `raw_json`）／IMPORT NEW SLOT（匯入後 `load_state()` 對應映射值；`_current_state` 未被直接覆寫）／NO SYSTEM CLOCK（掃 `res://src/persistence`，禁 `Time.`／`OS.get_`）／BACKFILL POLICY（`report.backfill_policy=="none"`）。
容器：`FileStorageAdapter.new("user://m1e_test_slots")`＋`SaveManager.configure(content, adapter)`＋`slots().reset()`；頭尾 `SaveManager.reset_for_tests()`。PASS 行自訂。

### `docs/legacy-compatibility.md`（worker-c）

支援／部分／拒絕矩陣：
- 支援：`v`/`o`/`t`/`p.eraId`/`p.level`/`r[*].v,u,e`（含 `1e1000`）/`b[*]`（兩種形式）/compact 與 long 兩種頂層。
- 部分：layer≥2（`ee…`，AmountCompat 解析能力內；否則記 issue）、`{sign,mag,layer}` 物件、缺欄位（缺 `o`→0）。
- 拒絕／不匯入：`s`(sect)、`beastData`（缺欄／分享碼本就不含）、skills/talents/daoHeart/daoProof/pills/achievements/hints（僅報告不映射）、未知 ID、`max`/`rate`（重算）、settings/language。
- 明列：不自動讀舊站 localStorage；首次匯入不補算（`backfill_policy="none"`）；保留原文 key `legacy_import_raw`。
- 附來源檔案與行號（saveSystem.ts 等）與已知 docs 更正（`s`=sect）。

## 檔案所有權（單一寫者）

| 擁有者 | 檔案 |
| --- | --- |
| worker-a | `src/persistence/legacy_importer.gd` |
| worker-b | `tests/fixtures/legacy/import_samples/**`、`tests/m1e_import_runner.gd` |
| worker-c | `docs/legacy-compatibility.md` |
| orchestrator | `src/persistence/save_manager.gd`、`src/presentation/save_controls.gd`、`docs/verification/m1-e.md`、`docs/development-status.md`、`docs/ai-handoff.md`、`docs/rule-differences.md`、本計畫 |

worker-d（nemotron free）本輪不派工（前次輸出退化為亂碼）。

## 驗收命令（orchestrator 序列化執行）

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
$out = & $daoEngine --headless --path . --script res://tests/m1e_import_runner.gd 2>&1
$out | Out-File -Encoding utf8 'C:\Users\asus\AppData\Local\Temp\opencode\m1e_run.txt'
# 需 EXIT=0、有 PASS 行、無 SCRIPT ERROR；再回歸 m1d／m1c／m1b runner
```

## 未實作／不宣稱

真實玩家 corpus、byte-for-byte 舊存檔、layer>3 完整算術、舊站 localStorage 直讀、獸進度搬移、匯入 UI 互動與瀏覽器路徑。ADR-008 早期候選檔（`amount.gd`、`amount_compat_v2.gd`、`seeded_random.gd`）仍未刪。
