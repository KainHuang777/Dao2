# 舊存檔相容性矩陣（M1-E LegacyImporter）

更新：2026-09-16

本文件定義 v2 `LegacyImporter`（`src/persistence/legacy_importer.gd`）對舊版 `cultivation-game` 存檔的支援範圍，作為 M1-E 的凍結介面附錄與驗收對照。此矩陣只描述「匯入器可接受並轉換的欄位」，**不是**對舊存檔 byte-for-byte 相容或跨版本無損續玩的宣稱；任何超出下表欄位的舊資料都不會進入 v2 狀態。判定以唯讀來源 `E:\Python\test1`（cultivation-game v0.46.6）的實作為準，不以展示數值或文件臆測為準。

## 舊版來源事實

- 序列化器：`src/utils/saveSystem.ts`；格式版本固定為 `"1.0"`，遊戲版本 0.46.6。
- 分享碼＝**標準 Base64**（非 URL-safe）包 UTF-8 JSON；localStorage 存**純 JSON**。兩者內容同構。
- compact 頂層鍵：`v`(version)、`o`(onboardingVersion)、`t`(timestamp)、`p`(player)、`r`(resources)、`b`(buildings)、`s`(sect)、`beastData`。
- 長形式頂層鍵：`version`、`onboardingVersion`、`timestamp`、`player`、`resources`、`buildings`、`sect`、`beast`。
- compact 判定：`v`／`p`／`r` 任一存在即 compact（`saveSystem.ts:158`）。
- 所有 Decimal 金額為**字串**（break_eternity `toString`），layer≥2 形如 `"ee5"`；亦容忍 `{sign,mag,layer}` 物件。

## 支援／部分／拒絕矩陣

| 欄位／鍵 | 舊版來源 | v2 處理 | 狀態 | 備註 |
| --- | --- | --- | --- | --- |
| compact／long 頂層鍵 | `saveSystem.ts:111-120`、`202-211` | 兩種頂層鍵形式均接受；compact 判定同舊 loader（`v`／`p`／`r` 存在） | supported | 不另行猜測其他頂層鍵 |
| `v`／`version` | `saveSystem.ts:60` | 路由到 importer 判定格式版本，**不複製**為 v2 版本欄位 | supported | `format_version` 只讀取記錄；非 `"1.0"` 亦按已知欄位處理 |
| `o`／`onboardingVersion` | `saveSystem.ts:61`、`366-371` | 映射為 `onboarding_version = int(o ?? onboardingVersion ?? 0)` | partial | 缺欄時以 0 代替（不當新手、不回溯）；與舊 loader 的 `?? 0` 語意一致 |
| `t`／`timestamp` | `saveSystem.ts:62` | 僅記錄為來源時間 `source_timestamp_ms` | supported | **不作任何補算來源**；首次匯入 `backfill_policy="none"`，多年時間戳不觸發離線收益 |
| `p.eraId`、`p.level` | `PlayerManager.ts:42-43` | 映射為 `era_id = max(1, int(eraId ?? 1))`、`level = max(1, int(level ?? 1))` | supported | 下限 1，非法／缺欄不寫入負值 |
| `r`／`resources` 的 `v,u,e` 與長鍵 `value,unlocked,everObtained` | `ResourceManager.ts:779-790` | 以 `content.resource_ids` 建全 0／`unlocked=false`／`ever_obtained=false`，再對已知 id 套 `value`／`unlocked`／`ever_obtained` | supported | `u`／`e` 容忍 1/0 或 true/false；`max`／`rate` 不存、由規則重算，不從舊檔讀取 |
| 高層金額 `ee…`／`{sign,mag,layer}` | `break_eternity.js`（Amount 字串） | 在 AmountCompat 解析能力內（layer 0–3）解析；超出則記入 `amount_issues`，不靜默歸零 | partial | layer≥2 另記入 `high_layer_amounts`；layer>3 完整算術不在本輪承諾（見 ADR-008） |
| `b`／`buildings`（`{b:{id:level},m,ab,at,db}`） | `BuildingManager.ts:1150-1164` | 映射已知 id 的 `int(level)`（≥0）；同時接受 `id={id,level}` 嵌套形式 | supported | `m`／`ab`／`at`／`db` 為自動化旗標，**忽略不映射** |
| `s`／`sect` | `SectManager.ts:121-162` | **不匯入**，僅列入報告（`has_sect`／`ignored_fields`） | rejected | **文件更正**：`docs/02-technical-architecture.md` §7.2 該列寫「b／buildings、s／skills」有誤；`s` 是 sect 不是 skills。skills 位於 `p.learnedSkills`，以本矩陣為準 |
| `p.learnedSkills`／skills、`talents`、`daoHeart`、`daoProof`、pills、buffs | `PlayerManager.ts:46-57` | 不映射，僅列入報告（`ignored_fields`） | rejected | 跨世／效果欄位需逐欄驗證；本輪未建立對應 v2 語意 |
| `p.achievements`、`hints` | `PlayerManager.ts:58-59` | 不映射，僅列入報告 | rejected | 記錄為未支援欄位，不猜測語意 |
| `beastData`／`beast` | `saveSystem.ts:67-70`、`BeastManager.ts:144-146` | **不匯入**；缺欄時 `has_beast=false` 且 build 仍成功、記 warning | rejected | 舊版分享碼不攜帶活的獸進度（舊版 `beastData` 寫而不讀，見 BeastManager 的 `saveState`／`exportData` 與本文件證據表）；本輪不搬移獸資料 |
| 未知資源／建築 id | `ResourceManager.ts:781-787`、`BuildingManager.ts:1152-1155` | 列入 `unknown_resource_ids`／`unknown_building_ids` 報告，**永不加入狀態** | rejected | 與 M1-E 介面「未知 id 不寫入 state」一致 |
| settings／language／`sect.activeEvent` | — | 無對應欄位；分享碼不含這些資料 | rejected | 舊 loader 亦不從單一分享碼還原此類散鍵 |

## 匯入政策

- **不自動讀取**舊站 `localStorage`。匯入只接受使用者貼上的文字或檔案內容；舊站與新站網域不同，v2 不假設已讀到瀏覽器中的完整玩家進度。
- **首次匯入不補算**：`backfill_policy = "none"`；`training_seconds`、`total_elapsed_seconds`、`revision` 均不以舊 `timestamp` 推算，多年舊時間戳不得觸發任何收益補發。
- 成功匯入後，狀態另存**新槽位**；匯入原文以 `LEGACY_RAW_KEY = "legacy_import_raw"` 保留，供稽核與恢復。
- 未知／損壞輸入以**具名錯誤**拒絕（`EMPTY`、`BASE64_DECODE`、`NOT_JSON_OR_BASE64`、`JSON_PARSE`、`NOT_OBJECT`、`INVALID_AMOUNT`）；拒絕時**不觸碰現有進度**，`_current_state` 不被覆寫。
- 匯入成功的槽位 meta 設 `settled_until_utc_ms="0"`、`saved_at_utc_ms="0"`，避免任何時間推斷。

## 已知限制與未驗證項

- 無真實玩家存檔 corpus；所有樣本為去識別化／依規格手構（`tests/fixtures/legacy/import_samples/`）。
- 分享碼約 **20,000 字元截斷**是舊版已知限制（`saveSystem.ts:175-179` 對接近 20,000 字元長度給出截斷警告）；v2 無法憑截斷碼還原遺失內容。
- **layer>3 的完整 `break_eternity` 算術**不在本輪承諾（ADR-008）；超出 AmountCompat 邊界只記錄 `amount_issues`。
- 瀏覽器路徑（檔案選擇、貼碼、IndexedDB 落盤）與匯入 UI 互動**未驗證**；本輪僅 CLI headless runner 驗證。
- 不宣稱 byte-for-byte 舊存檔相容或跨版本無損續玩。

## 證據

舊版來源（唯讀 `E:\Python\test1`）引用：

| 檔案 | 行號 | 內容 |
| --- | --- | --- |
| `src/utils/saveSystem.ts` | `:60` | 格式版本 `version: "1.0"` |
| `src/utils/saveSystem.ts` | `:105-139` | `generateSaveCode`：compact 鍵 `v,o,t,p,r,b,s,beastData` → 標準 Base64 |
| `src/utils/saveSystem.ts` | `:144-182` | `parseSaveCode`：去空白、atob 解碼、compact 判定與長鍵對照、截斷警告 |
| `src/utils/saveSystem.ts` | `:202-218` | `saveToStorage`：localStorage 存純 JSON（主檔＋備份），同 compact 物件 |
| `src/utils/saveSystem.ts` | `:350-408` | `migrateSave`：`v||version`、`o||onboardingVersion` 容錯、`v/value` 對照、`max`/`rate` 重算註記 |
| `src/utils/ResourceManager.ts` | `:779-790` | `exportData`：每資源 `{v,u,e}`，`u`/`e` 為 1/0 |
| `src/utils/BuildingManager.ts` | `:1150-1164` | `exportData`：`{b:{id:level}, m, ab, at, db}` |
| `src/utils/PlayerManager.ts` | `:41-60` | `PlayerState`：`eraId`、`level`、`learnedSkills`、`daoHeart`、`daoProof`、`talents`、pills、buffs、`hints`、`achievements` |
| `src/utils/SectManager.ts` | `:121-162` | `exportData`：sect 緊湊格式（`sl,dp,cc,nr,nt,pc,mr,et,t,at,ur,mc,stc`） |
| `src/utils/BeastManager.ts` | `:144-146` | `exportData`：直接回傳 `this.state`（寫而不讀，分享碼不攜帶活的獸進度） |

frozen 介面依據：`docs/m1-e-execution-plan.md`（M1-E）、`docs/02-technical-architecture.md` §7.1／§7.2（§7.2 的「s／skills」列以本文件更正）、`docs/decisions/ADR-008-amount-rng-probe-boundary.md`。