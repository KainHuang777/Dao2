# 仙侍系統：前期三角色設計與核心介面

- 日期：2026-11-01
- 狀態：**MAID-CORE-1 IMPLEMENTED（L1）**；核心規則與介面已落地。**MAID-CORE-2 離線職掌邊界已於 2026-11-01 核定並 IMPLEMENTED（L1，§11）**；糯美子／丹霞 R2 各三張（三向設定／立繪／初遇）已獲使用者美術接受並完成接入，見 [MAID-ART-ND-R2 接入](development-status.md#maid-art-nd-r2-integration)。**洞府侍立可收合展示已於 2026-11-01 實作（L1，§13）**，見 [MAID-STAND](development-status.md#maid-stand)。**多仙侍並行職掌已於 2026-11-01 實作（L1，§18）**，見 [MAID-PARALLEL-1](development-status.md#maid-parallel)。
- 上位文件：[docs/48](48-maid-companion-system-proposal.md)
- 驗收：[maid-core-1](verification/maid-core-1.md)
- 已完成前導：MAID-ART（青蘅 R3 美術）、MAID-UI-1（人物頁與初遇重播）
- 本輪範圍：設計定案、核心規則、保存契約、職掌與羈絆 View、人物頁工作／羈絆分頁
- 不在本輪：新立繪、新 CG、語音、觸控實機、離線職掌自動化

## 1. 定案方向

採用 docs/48 的方案 B「仙侍系統」，但只做前期三位角色，先把「相遇 → 共同委託 → 職掌 → 羈絆章節」做成可玩閉環。

| 角色 | 定位 | 職掌 | 招募條件 |
| --- | --- | --- | --- |
| 青蘅 | 洞府侍女 | 定量備料（單一配方、目標庫存、保留量） | Era 1 且洞府已建成 |
| 糯美子 | 劍侍 | 定量監造（單一建築，達條件才升級） | 青蘅羈絆達相知、Era 2 |
| 丹霞 | 丹師 | 定量煉丹（單一丹藥、目標庫存、保留量） | 青蘅羈絆達相知、Era 2、丹道已解鎖 |

三位都不消耗宗門貢獻、不佔靈獸槽、不新增貨幣。角色本身永久保留；今世的工作與任務不跨世沿用。

## 2. 不變量

1. UI 只送命令、只讀 View，不直接改 `GameState`。
2. 動畫、重播、切換分頁、查看立繪不得發放收益或改狀態。
3. 所有時間由 `GameSession.advance_time(elapsed)` 注入；核心不讀系統時鐘。
4. 職掌每次只做一個有界動作，最多 5 個批次，不得一次清空資源。
5. 職掌不得跨越保留量；保留量不足時停下並回報原因。
6. 職掌不得自動突破、輪迴、消耗道心、消耗道證、領取一次性選擇、改路線。
7. 每位仙侍最多一個職掌；不同仙侍可並行持有職掌，由確定性的公平輪轉推進，不再要求全府只有一位值班。
8. 不新增被動產量倍率、不新增天賦 ID、不新增宗門 token／市集品、不與靈獸共用好感或餵養。
9. 職掌在 v1 只於線上 `advance_time` 推進；離線與跨世預設暫停，屬明確 v1 邊界。
10. 羈絆點只來自一次性章節、首次職掌、輪迴重逢；沒有每日簽到、沒有離線掛機好感。

## 3. 羈絆與章節

| 等級 | 點數 |
| --- | --- |
| 初識 | 0 |
| 相知 | 40 |
| 信任 | 100 |
| 同道 | 200 |

每位角色三章，章節獎勵只有羈絆點與記憶／美術旗標，不發資源。

| 角色 | 第一章 | 第二章 | 第三章 |
| --- | --- | --- | --- |
| 青蘅 | 一盞燈：完成 10 次職掌動作 | 宗門來信：宗門已解鎖 | 前世燈火：輪迴 ≥1 且已學天賦 |
| 糯美子 | 第一道劍痕：完成 3 次監造 | 功法相印：任一功法 ≥1 | 劍鳴舊世：輪迴 ≥1 且已學天賦 |
| 丹霞 | 爐火初溫：完成 5 次煉丹 | 靈獸銜丹：有結契靈獸 | 丹心照夜：輪迴 ≥1 且已學天賦 |

- 章節必須依序領取；前一章未領，後一章不可領。
- 章節領取旗標永久保留，不因輪迴清除。
- 首次職掌成功另給 10 點羈絆，每位角色只給一次。

## 4. 職掌

### 4.1 共同欄位

```text
duty = {
  kind: String,
  paused: bool,
  cooldown: int,
  status: String,
  ...kind-specific fields
}
```

- `cooldown` 單位為秒，只在未暫停時由 `advance_time` 扣減。
- `status` 是最近一次結果代碼：`RUNNING`、`TARGET_REACHED`、`INSUFFICIENT_RESOURCE`、`OUTPUT_FULL`、`LEVEL_CAP`、`ALCHEMY_LOCKED`、`PILL_LOCKED`、`PAUSED`、`BLOCKED`。
- 節奏：青蘅 10 秒、糯美子 30 秒、丹霞 10 秒。
- 每次成功動作最多 5 個批次；不足 5 批則以實際可負擔批次為準。
- 指派新職掌會取代舊職掌；清除職掌會移除工作設定，但保留 `duty_actions` 累計。

### 4.2 青蘅：定量備料

```text
{kind:"steward_stock", recipe_id:String, target:int, reserve:{resource_id:String}}
```

- 只認單一配方；以配方 `product_id` 的現有庫存為準。
- 目標庫存以「產出單位」計，不是批數。
- 每批產出 = `recipe.output`；批次數 = `min(5, ceil((target - stock) / output))`。
- 材料不足時以可用量反推可負擔批次；仍為 0 則回報 `INSUFFICIENT_RESOURCE`。
- 保留量是材料保留，不讓職掌把指定材料壓到保留線以下。
- 經濟未展開（`state.economy.is_empty()`）時走即時 `ProcessingSystem.craft`；已展開時走 `IslandEconomy.command` 的 `home` 產線。
- 產線忙線時不搶線，回報 `BLOCKED`。

### 4.3 糯美子：定量監造

```text
{kind:"oversee_build", building_id:String}
```

- 只升级玩家指定的單一建築。
- 前置：建築可見、已解鎖、等級低於上限、資源足額。
- 每次只升一級，透過既有 `upgrade_building` 命令執行。
- 已達上限回報 `LEVEL_CAP`；資源不足回報 `INSUFFICIENT_RESOURCE`。
- 不掃描其他建築、不按定義順序貪婪升級、不消耗技能點。

### 4.4 丹霞：定量煉丹

```text
{kind:"restock_pills", pill_id:String, target:int, reserve:{resource_id:String}}
```

- 只煉玩家指定的單一丹藥。
- 目標庫存以丹藥數量計；每次最多 5 顆。
- 以 `AlchemySystem.can_refine` 與 `refinement_cost` 為準，並套用材料保留量。
- 丹道未解鎖回報 `ALCHEMY_LOCKED`；丹藥未解鎖回報 `PILL_LOCKED`；材料不足回報 `INSUFFICIENT_RESOURCE`。
- 築基丹在經濟展開且 Era ≥2 時，沿用既有命令轉導到加工產線，不另寫規則。

## 5. 跨世

- `state.maid` 永久保留：已招募、羈絆、章節、選擇、已領獎勵、職掌累計、展示偏好。
- 展示偏好（洞府侍立展開／收合與手動選角）存於 `state.maid.display`；`maid_id == ""` 表示跟隨當值。
- 輪迴時：
  - 已招募角色的職掌一律 `paused=true`，`cooldown=0`。
  - `reunion_pending=true`，角色可說一句重逢短句。
  - 不重播首次相遇獎勵，不重付招募條件。
  - 已領章節不重置。
- 新世玩家確認後可恢復職掌；恢復前不自動工作。
- 輪迴不得被仙侍流程阻擋；`on_reincarnate` 不得失敗。

## 6. 命令

全部走 `GameSession.submit`，成功回傳 `{ok, events, changed_ids}`。

| 命令 | payload | 說明 |
| --- | --- | --- |
| `recruit_maid` | `{maid_id}` | 招募；不消耗資源 |
| `assign_maid_duty` | `{maid_id, duty}` | 指派或取代職掌 |
| `clear_maid_duty` | `{maid_id}` | 清除職掌 |
| `set_maid_duty_paused` | `{maid_id, paused}` | 暫停／恢復 |
| `execute_maid_duty` | `{maid_id}` | 立即執行一次，忽略冷卻 |
| `claim_maid_chapter` | `{maid_id, chapter_id}` | 領取章節 |
| `maid_reunion` | `{maid_id}` | 清除重逢旗標 |
| `set_maid_display` | `{expanded, maid_id}` | 保存洞府侍立展開與手動選角；`maid_id` 可為空 |

八個命令都要加入 `KNOWN_COMMAND_TYPES`、`CommandProcessor._apply`、`GameSession._is_valid_shape`、`SectReformSave.COMMANDS`。

## 7. View

`GameSession.get_view()["maid"] = MaidSystem.get_view(state, content)`。

```text
{
  version: 2,
  bond_levels: [{id,name,at}],
  active_duty: String,
  display: {expanded: bool, maid_id: String},
  maids: {
    id: {
      id, name, role, recruited, bond, bond_name,
      next_bond_name, next_bond_at,
      recruit: {can, reason},
      chapters: [{id,title,bond,claimed,can_claim,reason}],
      duty: {} or {kind,paused,cooldown,status,status_text,...},
      duty_actions: int,
      reunion_pending: bool,
      art_ready: bool,
      options: {recipes:[{id,name}], buildings:[{id,name}], pills:[{id,name}]}
    }
  }
}
```

View 是純讀取；開啟分頁、切換角色不得初始化或修復狀態。

## 8. 保存

- 最上層新增可選 `state.maid`，維持 `SCHEMA_VERSION = 6`；巢狀區塊自 MAID-DISPLAY-PREF 起為 `version = 2`，含 `version`／`maids`／`display`。
- 缺欄視為舊存檔，空字典合法。
- `MaidSaveContract` 接受 v2 與舊版 v1（僅 `version`／`maids`）；`normalize` 一律升級為 v2 並補預設 `display = {expanded: true, maid_id: ""}`，舊存檔不得取得任何新關係、庫存或職掌。
- `MaidSaveContract.validate` 在 `SaveCodec.encode` 與 `_state_from_snapshot` 呼叫；不合法直接拒絕，不修復。v2 必須恰好三鍵，`display` 鍵集、型別與非空角色 id 皆須合法，否則回 `MAID_DISPLAY`。
- 大小上限 16384 bytes。
- `state.maid` 加入 `duplicate_state` 與 `to_snapshot_dict`。
- 輪迴不清除 `state.maid`，只由 `MaidSystem.on_reincarnate` 調整職掌暫停與重逢旗標；`display` 原樣保留。

## 9. UI

- 保留既有 `characters` route 與 header 四個分頁，`職掌`／`羈絆` 改為可用。
- 人物、初遇重溫、職掌、羈絆四個分頁皆顯示三位角色選擇列（青蘅／糯美子／丹霞，各用已驗收立繪），緊湊版面（`bounds.size.y < 400` 或 `bounds.size.x < 960`）的初遇重溫頁為保留對話高度暫不顯示選擇列，返回其他分頁即可切換；切換只改呈現，不寫入狀態。未招募角色同樣可切換閱覽人物小傳與初遇，並以「尚未招募 · 可先閱覽人物與初遇」提示及招募條件列說明；職掌／羈絆頁僅停用需招募後才能用的操作。
- 職掌分頁顯示：目前狀態、指派目標、目標數量、指派／暫停／立即執行／清除。
- 羈絆分頁顯示：等級、點數、下一階段、三章清單、領取、重逢短句。
- 所有按鈕至少 44px 命中；沿用 `GameTab`、`InscriptionAction`、`UiTypography`。
- 操作成功後發 `action_requested(kind, payload)`，由 `FeatureNavigation` 組標準 envelope、存檔、刷新。
- 招募成功後人物頁自動切到該仙侍的初遇分頁（已驗收 CG＋開場白＋兩選項，游標置於第一個選項），重播仍由「初遇重溫」手動進入；未新增存檔欄位，因 `recruit_maid` 為一次性命令，自然只觸發一次。招募失敗或存檔失敗不切換。

## 10. 未來擴充

- 更多角色（狐族、宗門聖女）與專屬大圖。
- 多仙侍並行職掌：已於 2026-11-01 實作（L1，§18），產線衝突改以 `BLOCKED` 狀態與冷卻重試處理。
- 離線職掌：§11 的有限次補算邊界已於 2026-11-01 核定並實作（L1）。
- 職掌預設組合、保留量 UI、材料不足提示細化。
- 羈絆章節對話分歧與已讀回放（已於 §16 實作；仍不得改規則）。
- 與宗門委託、靈獸照料、天賦輪迴的更多交叉條件（只讀既有事實）。

## 11. 離線職掌邊界（MAID-CORE-2，2026-11-01 核定並 L1 實作）

- 日期：2026-11-01
- 狀態：**已核定；L1 已實作。** `OfflineSettlement.settle` 與 `OfflineCoordinator.compute_async` 於時間結算後各呼叫一次 `MaidSystem.advance`；線上 `game_session.gd:142` 仍為獨立呼叫點。實作與驗收見 [maid-core-2](verification/maid-core-2.md)。
- 依據：§2-9 的 v1 邊界與 §10「不得無限補算」；本節取代 §2-9 的「離線暫停」半句，跨世暫停不變。
- 一句話邊界：**離線只讓已指派、未暫停的職掌以結算後庫存執行至多 5 次有界動作；不自動指派／恢復／領章／招募，不新增收益來源，壽元停止時整段跳過。**

### 11.1 決策摘要

| 項目 | 決策（PROPOSED） |
| --- | --- |
| 是否允許離線職掌 | 允許，僅限已存在且 `paused == false` 的職掌 |
| 單次結算上限 | `MAX_ACTIONS_PER_CALL := 5`，線上與離線共用 |
| 時間視窗 | 不另設；剩餘 ticks 只扣冷卻，達動作上限後整段捨棄、不跨呼叫攜帶 |
| 壽元停止 | `stopped != null` 時整段跳過（0 次） |
| 24 小時上限 | 超出 `CAP_MS` 只推時間，不補職掌 |
| 跨世 | `paused = true` 維持暫停；不自動重逢、不自動恢復 |
| 章節／重逢 | 不可離線領取或解除，仍須玩家命令 |
| 羈絆 | 只沿用既有一次性首次職掌 +10；無離線好感、無每日簽到 |
| 資源／倍率／貨幣 | 沿用既有 `craft`／`upgrade_building`／`refine_pill`；不新增 |
| 存檔 | schema 6、`state.maid`、`MaidSaveContract` 都不變 |
| 離線回報 | `report.maid` 附加鍵；缺鍵的舊存檔與舊 UI 可讀 |
| 與線上等價性 | **不宣稱逐 tick 等價**；離線是「時間結算後一次執行」的 v2 決策 |

### 11.2 不變量

1. 離線不得呼叫 `recruit`／`assign_duty`／`clear_duty`／`set_duty_paused`／`reunion`／`claim_chapter`。
2. 離線不得呼叫 `ensure_state`；`state.maid` 缺失時零寫入、零回報。
3. 單次 `advance` 最多 `MAX_ACTIONS_PER_CALL` 次動作，不得因 away 時長或 24h 上限放大。
4. 每位仙侍最多一個生效中職掌；多位仙侍可並行，推進沿用 §2-7 與 §18 的公平輪轉，不因並行放大單次結算預算。
5. 壽元停止、rollback、bootstrap、`full_ticks == 0` 時不做職掌。
6. 動作仍走既有命令管線；失敗只更新 `status` 與冷卻，不補償、不自動重指派。
7. 無 RNG、無系統時鐘、無幀率相依；結果只由 state＋cursor＋content 決定。
8. 動畫、分頁、立繪、回報文字都不得發放收益（沿用 §2-2）。

### 11.3 預算與演算法

- 常數：`maid_rules.gd` 新增 `MAX_ACTIONS_PER_CALL := 5`；`maid_system.gd` 保留 `MAX_ACTIONS_PER_ADVANCE := 1000` 為絕對上限。
- `MaidSystem.advance` 增加必填 `max_actions` 參數，實際上限 `clampi(max_actions, 0, MAX_ACTIONS_PER_ADVANCE)`；所有呼叫點都必須顯式傳預算，不給預設值，避免靜默無界。
- 為何 5 足夠安全：單次呼叫最多 5 次動作，由所有生效職掌共用；每次動作最多 5 批次，最壞 3 位×5 次×5 批次＝75 批次；章節需 3／5／10 次累積，不會一次跳關；目標庫存與建築等級上限本身就會讓職掌停下。
- 同步路徑（`offline_settlement.gd`）：時間推進（含 unsupported fallback 與 `time_only_ticks`）完成後，若 `full_ticks > 0` 且 `stopped == null`，對同一 working state 呼叫一次 `MaidSystem.advance(content, state, full_ticks, MaidRules.MAX_ACTIONS_PER_CALL)`。
- 非同步路徑（`offline_coordinator.gd::compute_async`）：`_advance_yielding`／`advance_time_only` 完成且 `stopped == null`、`full_ticks > 0` 時，在同一位置以同一參數呼叫一次。5 次動作成本極低，不進 `FrameBudget`、不需要 yield。
- 線上（`game_session.gd:142`）：維持「時間推進成功後才跑職掌」，改傳 `MaidRules.MAX_ACTIONS_PER_CALL`。
- `stopped != null` 跳過；`full_ticks == 0`（bootstrap／rollback）跳過；`time_only_ticks` 永不餵職掌。
- 順序語意：離線職掌在時間結算**之後**、以最終庫存執行；不與時間交錯。

### 11.4 決定性與同構

- 同一 state＋同一 `last_settled_utc_ms`＋同一 content ⇒ 同步、非同步與任何機器上的 `state.maid`、`report.maid` 完全相同。
- 依賴 `ids.sort()`、單一共享 `remaining`、固定動作上限；不讀 `Time`／`OS`／RNG／frame delta。
- `report.maid` 只能由 `MaidSystem.advance` 回傳的 events 推導，不得事後重跑模擬或讀回舊 report。

### 11.5 互動矩陣

| 情境 | 結果 |
| --- | --- |
| 壽元停止 | 0 次、無 `report.maid`、不發羈絆 |
| 24h 上限 | 有效窗內最多 5 次；超限只推年歲 |
| 跨世暫停／`reunion_pending` | 0 次；旗標不變 |
| 冷卻大於剩餘時間 | 只扣冷卻，0 次 |
| `TARGET_REACHED`／`LEVEL_CAP` | 0 次成功，更新 `status`，冷卻重設 |
| `INSUFFICIENT_RESOURCE`／`OUTPUT_FULL`／`BLOCKED`／`ALCHEMY_LOCKED`／`PILL_LOCKED` | 不發收益，記錄 `status`，冷卻重設 |
| 首次職掌 | 既有一次性 +10 羈絆照常，產生 `maid_first_duty` 事件 |
| 經濟已展開且職掌啟動計時產線 | 只計成功派工 1 次，後續 `BLOCKED`；成品回到線上後才完成，離線不記成品 |

### 11.6 報告與 UI

- `report.maid = {actions, units, kinds, first_duty}`：`actions` 為 `maid_duty_executed` 筆數、`units` 為其 `units` 總和、`kinds` 為依 `duty_kind` 計數、`first_duty` 為 `maid_first_duty` 筆數。
- `actions == 0` 時整個 `maid` 鍵省略；兩個 report 建構點共用同一 helper。
- `OfflineSummary.show_report` 只在有 `maid` 鍵時，於「目前年歲」與「停止原因」之間加一行：「仙侍職掌：離線完成 %d 次」。0 次時輸出與現行逐字相同；不新增控制項，保留 autowrap 與 ScrollContainer。
- `last_offline_report` 只作除錯留痕，規則與 UI 不讀回；未來若加形狀驗證，需把 `maid` 納入白名單。

### 11.7 凍結介面（已實作）

```gdscript
# src/simulation/maid_rules.gd
const MAX_ACTIONS_PER_CALL := 5

# src/simulation/maid_system.gd
const MAX_ACTIONS_PER_ADVANCE := 1000
static func advance(content: GameContent, state: GameState, ticks: int, max_actions: int) -> Dictionary
static func offline_report(events: Array) -> Dictionary
```

- `advance` 內部上限 `clampi(max_actions, 0, MAX_ACTIONS_PER_ADVANCE)`；`max_actions <= 0` 直接回空、不扣冷卻。
- `offline_report` 為純函式，不讀 state，0 筆職掌事件時回傳 `{}`。

### 11.8 驗收計畫（L1，2026-11-01 已執行）

| 案例 | 斷言 |
| --- | --- |
| 12h 執行中職掌、材料充足 | 恰好 `MaidRules.MAX_ACTIONS_PER_CALL` 筆 `maid_duty_executed` |
| 暫停職掌 | 0 筆、`duty_actions` 不變、report 無 `maid` 鍵 |
| 無 `state.maid` | 仍缺失（未初始化）、report 無 `maid` 鍵、snapshot 不變 |
| 壽元停止 | `stopped != null`、0 筆 |
| 轉世暫停 | 0 筆、旗標不變 |
| 24h 上限 | `cap_applied == true`、`actions == 上限` |
| 經濟已展開的備料 | 1 次成功＋`BLOCKED`、庫存無成品 |
| 同步與非同步 | `report` 與 `state.maid` 逐鍵相同 |
| 存檔往返 | `MaidSaveContract.validate == ""`、次數與首次旗標保留 |
| 線上小 tick | 既有 10／30 ticks 期望不變 |
| 確定性 | 兩次相同輸入的 state 與 report 全等 |
| UI 文字 | 有／無 `maid` 鍵兩態；0 次逐字沿用現行 |

- 新增 `tests/maid_offline_runner.gd`；既有 `maid_core_runner.gd`、`m1d_offline_runner.gd`、`offline_closed_form_parity_runner.gd` 加案。
- L1 以完整檔名精選 4 支，單一 1280×720、預設 45 秒、輸出至 `.test-output/`，任何 `SCRIPT ERROR` 即失敗；不跑 L3，直到仙侍大型任務結案或用戶要求。

### 11.9 實作分工（2026-11-01 已依分工完成）

- Worker A：`maid_rules.gd`、`maid_system.gd`。
- Orchestrator 專屬：`offline_settlement.gd`、`offline_coordinator.gd`，以及 `game_session.gd` 的呼叫參數。
- Worker B：`offline_summary.gd` 一行文字。
- Worker C：上述測試。
- 紅線：`save_codec.gd`、`save_manager.gd`、`maid_save_contract.gd` 零變更。

### 11.10 風險與待決

- 桌面聚焦回復：`living_abode.gd:859-877` 以 `advance_time(clampf(elapsed, 0.05, 86400))` 直接進線上職掌；共用 5 次上限後已封頂。建議後續把超過 60 秒的間距改走 `OfflineCoordinator`，但非本輪阻擋。
- 離線不與時間交錯，經濟產線派工在回線後才完成，屬刻意 v2 決策，不得宣稱與線上等價。
- `MAX_ACTIONS_PER_CALL` 是平衡常數，實機體感後可調；測試一律讀常數，不硬編 5。
- 未來若允許並行職掌，需重新計算共享 `remaining` 與預算公平性。（2026-11-01 已於 §18 以「下一個就緒者優先、少服務者優先」重算，預算仍為每次呼叫共用上限。）

## 12. 職掌／羈絆呈現驗收（MAID-UI-2，2026-11-01 L2）

- 範圍：MAID-CORE-1 已啟用但未經視覺驗證的職掌／羈絆分頁，以及 MAID-CORE-2 的離線摘要仙侍行；只做呈現修正、headless 覆蓋與桌面 Chrome 1280×720 抽驗。
- 版面：回饋列必須位於所屬分頁的捲動區內，不得成為頁面固定高度；短橫式仍以單區內捲消化，不撐破底部工具列。
- 輸入：目標數值只在 View 值變動且 `SpinBox` 未取得焦點時同步，避免 HUD 週期刷新覆寫輸入。
- 焦點：分頁捲動區啟用 `follow_focus`，鍵盤焦點不得停在可視區外。
- 文字：狀態列不重複「已暫停」；錯誤與狀態一律經 `status_text()` 轉中文，不得露出 `UNKNOWN_RECIPE`、`BUILDING_UNKNOWN` 等原始碼；選單顯示配方／丹藥／建築的顯示名稱，不顯示內部 id。
- 選單：`duty_picker` 沿用共用 44px 列高覆寫，並以所選項目文字作 tooltip。
- 驗收：`tests/maid_ui2_runner.gd` 覆蓋分頁幾何、44px、命令往返、暫停拒絕、章節、招募、重逢與短橫式堆疊；Web 抽驗以 `tools/maid_ui2_web_fixture.gd` 產生可結算存檔，`tools/maid_ui2_web_check.mjs` 斷言離線報告與畫面。
- 邊界：不新增規則、資源或 schema；不改 `save_codec.gd`、`save_manager.gd`、`maid_save_contract.gd`；未跑 L3、觸控或 FPS 驗收。

## 13. 洞府侍立（MAID-STAND，2026-11-01 L1 實作）

- 範圍：使用者要求「洞府內的仙侍展示（可收合）」；兌現 docs/48 §6「洞府侍立」候選列。MAID-STAND 本身不改規則、資源、schema 或存檔；展示偏好的持久化由後續 §15 補上。
- 呈現：新增 `src/presentation/maid_stand_display.gd`，由 HUD 建構並常駐 `abode.maid_stand`。寬式且有安全空間時，在訊息面板右側顯示已驗收立繪的上半身（`AtlasTexture` 裁切，`STRETCH_KEEP_ASPECT_COVERED`）、角色名、職位與職掌狀態；「前／後」切換展示角色、「人物頁 · 初遇」開啟既有 `characters` route；`CloseSeal` 收合成右下「仙侍」小籤，再點展開。
- 安全區：只在洞府首頁、無 overlay、寬式版面、選島器關閉，且展開區不與訊息面板或底部工具列重疊時顯示。空間不足（短橫式、窄橫式或選島器展開）時整個元件讓位，不遮住突破、保存恢復、訊息或核心世界目標；不改動 `world_safe_rect` 或鏡頭契約。
- 純呈現：`refresh(view)` 只讀 `view.maid`；預設展示 `active_duty`，玩家手動切換後以手動選擇為準。切換展示、收合、開啟人物頁都不派工、不發羈絆、不寫 `GameState`；未招募角色沿用人物頁既有的可閱覽政策。
- 保存：展示偏好（展開／收合與手動選角）自 MAID-DISPLAY-PREF 起跨存檔／輪迴保存，見 §15；本節其餘呈現與安全區規則不變。
- 驗收：新增 `tests/maid_stand_runner.gd`，覆蓋展開／收合、44px 命中、立繪裁切來源、當值與手動選擇優先序、人物頁往返、狀態零變更與短橫式讓位；L1 單一 1280×720 PASS（26 checks，另跑受影響的 `maid_ui_runner`、`ui_shell_integration_runner`、`living_abode_runner` 共 4/4 PASS），並以原生 1280×720 截圖目視確認半身與版面。

## 14. 羈絆終章 CG 回憶重播（MAID-BOND-CG-INTEGRATION，2026-11-01 L1 實作）

- 範圍：把三張已接受的第三章羈絆終章 CG 接入人物頁羈絆分頁的「回憶」重播；不改規則、獎勵、庫存、schema 或存檔。素材為青蘅 `bond-lamplight-r1.png`（前世燈火）、糯美子 `bond-sword-rain-r1.png`（劍鳴舊世）、丹霞 `bond-night-vigil-r1.png`（丹心照夜），皆 1672×941 單層 RGB。
- 解鎖：`maid_character_panel.gd` 的 `_sync_bond` 只在「已招募＋該角色第三章 `chapters[<id>_3]` 已領取＋列為最後一章」時顯示該列「回憶」按鈕；未領取、非終章或章節不存在時隱藏。沿用 `claim_chapter` 既有永久旗標，不新增旗標或 schema。
- 載入：`BOND_CG` 表只存路徑、標題與兩行敘事；按下時才以 `load(path)` 取得 `Texture2D`，不把三張 CG 放進 `preload` 或常駐欄位。路徑不存在時不開啟。
- 呈現：沿用共用 shell tool overlay（遮罩、`CloseSeal`、Escape／返回）與 `maid_portrait_viewer`；圖像 `EXPAND_IGNORE_SIZE`＋`STRETCH_KEEP_ASPECT_CENTERED` 完整 contain，不 cover 裁切頭飾、劍尖、右側劍鞘／流蘇，也不拉伸。`present_memory()` 在圖下加入可內捲的敘事 `Label`；一般立繪 `present()` 隱藏該區。
- 純重播：開啟回憶只發 `memory_requested(texture, title, lines)` 呈現訊號，不送命令、不寫 `GameState`、不重新領取、不發羈絆或資源；領取後按鈕只重播。`to_snapshot_dict()` 在開啟／關閉前後不變。
- 驗收：新增 `tests/maid_bond_cg_runner.gd`；L1 單一 1280×720 與 `maid_ui_runner`、`maid_ui2_runner`、`maid_art_r2_runner` 共 4/4 PASS（MAID-BOND-CG 68、MAID-UI 53、MAID-UI2 62、MAID-ART-R2 78 checks，failures=`[]`）。未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機。

## 15. 展示偏好跨存檔／輪迴（MAID-DISPLAY-PREF，2026-11-01 L1 實作）

- 範圍：兌現 docs/48 §8「展示偏好跨世保留」。`state.maid` 巢狀區塊升為 `version = 2`，新增 `display: {expanded: bool, maid_id: String}`；`maid_id == ""` 表示自動跟隨當值職掌，非空時必須是三位仙侍之一。最上層 `SCHEMA_VERSION` 維持 6，存檔外層格式不變。
- 相容／遷移：`MaidSaveContract` 同時接受 v2 與舊版 v1（僅 `version`／`maids`）；載入時 `normalize` 一律升級為 v2 並補預設 `{expanded: true, maid_id: ""}`，舊存檔不得因此獲得任何關係、庫存或職掌。v2 必須恰好三鍵且 `display` 通過型別、鍵集與角色 id 驗證；不合法回 `MAID_DISPLAY` 並由 `SaveCodec` 拒絕，不就地修復。
- 命令：新增 `set_maid_display`，payload `{expanded: bool, maid_id: String}`（`maid_id` 可空）；只寫 `state.maid.version` 與 `display`，不動 `maids`、羈絆、章節、庫存或職掌，成功回 `changed_ids: ["maid"]`，相同值為 no-op（`changed_ids: []`），未知角色回 `UNKNOWN_MAID`。已加入 `KNOWN_COMMAND_TYPES`、`_is_valid_shape`、`CommandProcessor`、`SectReformSave.COMMANDS`。
- 讀取：`MaidSystem.get_view()["maid"]` 新增 `display`；`MaidSystem.display()` 對缺欄或損壞值回預設，不寫狀態。
- 輪迴：`MaidSystem.on_reincarnate` 與 `ReincarnationRules.apply_reincarnation` 不碰 `display`；展開狀態與手動選角跨世保留。
- UI：`maid_stand_display.refresh()` 讀取 `view.maid.display` 還原展開與手動選角；`cycle()`／`set_expanded()` 在本地更新後送 `set_maid_display`（手動選角時帶角色 id，自動跟隨時為空字串），成功即存檔並刷新 HUD，失敗由刷新回退顯示。合成 view 無 `display` 時保留原「手動優先、否則跟隨當值」行為。
- 驗收：`tests/maid_core_runner.gd` 新增契約遷移、命令、存檔往返與輪迴保留案例；`tests/maid_stand_runner.gd` 改為比較扣除 `revision`／`command_receipts`／`life_ledger`／`achievements`／`maid` 的狀態切片，並斷言仙侍名冊未變、磁碟存檔 `display == {expanded: false, maid_id: "qingheng"}`（收合）與展開後 `expanded: true`、view 可還原展示。L1 單一 1280×720：MAID-CORE 210、MAID-STAND 33、MAID-UI 53、MAID-UI2 62 checks，4/4 PASS，failures=`[]`。未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機。

## 16. 羈絆章節對話分歧與已讀回放（MAID-BOND-CHAPTER，2026-11-01 L1 實作）

- 範圍：兌現 §10「羈絆章節對話分歧與已讀回放（仍不得改規則）」。只加呈現層的章節對話與分支重播，不改章節條件、羈絆點數、獎勵、庫存、schema 或存檔格式；對話分支選擇為單次閱讀狀態，不落盤。
- 內容：`maid_character_panel.gd` 新增 `BOND_SCRIPT`，以既有九個章節 id 為鍵（每位仙侍三章），每章含兩行開場、兩個分歧選項、每個選項一段專屬回應，以及共同收束句；文字全部沿用該角色既有語氣，章節標題與 `MaidRules.CHAPTERS` 完全一致。
- 已讀判定／解鎖：沿用 `claim_chapter` 的既有永久章節旗標——已招募且該章已領取（即已讀）才顯示章節列「重溫」；未領取、未招募或章節不存在時隱藏。不新增旗標、不重複領取、不發羈絆；第三章「重溫」與既有「回憶」CG 並存，兩個入口互不取代。
- 呈現：按下「重溫」發 `chapter_requested(title, script)`，由 `maid_portrait_viewer.present_chapter()` 在共用 shell tool overlay（遮罩、`CloseSeal`、Escape／返回）開啟。對話檢視器隱藏立繪，顯示章名、開場白、兩個 44px 分支按鈕；選定後只顯示該分支回應加共同收束句，分支按鈕收起，出現 44px「重新閱讀」可回到開場重新選；一般立繪與 CG 回憶重播會隱藏分支區，`present_chapter` 亦清空圖像，兩者互不殘留。
- 純重播：開場、選擇分支、重新閱讀與關閉都只改檢視器本地呈現，不送命令、不寫 `GameState`、不發羈絆或資源、不重領章節；`to_snapshot_dict()` 在每個步驟前後完全相同。
- 驗收：新增 `tests/maid_bond_chapter_runner.gd`；L1 單一 1280×720 與 `maid_bond_cg_runner`、`maid_ui_runner`、`maid_ui2_runner` 共 4/4 PASS（MAID-BOND-CHAPTER 138、MAID-BOND-CG 68、MAID-UI 53、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）。案例涵蓋九份腳本的標題對齊、兩行開場、兩個相異選項、每個分支各自的專屬回應、共同收束句、同角色章節不重複文案，重溫在未領取章節隱藏，44px 命中，共用遮罩與純對話檢視器，兩個分支互不顯示對方內容，重新閱讀可復原選項，第三章重溫與 CG 回憶並存，換仙侍後標題與文案跟著換，以及全程快照零變更。未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機。

## 17. 職掌預設組合、保留量 UI、材料不足提示細化（MAID-DUTY-PRESET，2026-11-01 L1 實作）

- 範圍：兌現 §10「職掌預設組合、保留量 UI、材料不足提示細化」。只加規則常數、View 唯讀欄位與既有職掌分頁的呈現／輸入輔助；不改職掌判定、產出上限、羈絆、章節、獎勵、庫存、schema 或存檔格式。
- 預設組合：`MaidRules.DUTY_PRESETS` 為 `steward_stock`、`restock_pills` 提供三個確定性組合（常備 5／保留 20%、充裕 10／保留 10%、趕工 20／保留 0%），`oversee_build` 為空；`MaidRules.duty_presets(kind)` 回傳對應陣列，未知種類回空陣列。預設只描述 UI 起點，不自動指派、不寫狀態。
- 保留量 UI：職掌分頁的目標列下方新增預設按鈕列（44px）與「保留量」逐材料 `SpinBox`（≥44px 高、≥150px 寬），選項切換或材料清單變更時才重建；欄位以現有 `duty.reserve` 為初值（僅當所選配方／丹藥與已指派職掌一致）。套用預設只在本機把目標設為組合目標、各材料保留設為 `floor(目前庫存 × reserve_ratio)`，不送命令。
- 命令負載：按下指派時，`assign_maid_duty` 的 `duty.reserve` 由保留量步進器收集（>0 才寫入，鍵為資源／丹藥 id），`steward_stock` 與 `restock_pills` 皆適用；`oversee_build` 仍無保留量。命令型別、`_is_valid_shape` 與契約鍵集不變。
- 唯讀提示：`MaidSystem.get_view()` 的選項補上輸入明細——配方 `inputs:[{id,name,per_batch,stock}]`、丹藥 `cost:[{id,name,per_unit,stock}]`；既有職掌另有 `shortage` 與 `shortage_text`。材料不足時以實際批次／預估批次找出最吃緊的輸入，文字如「低階靈草不足 60（需 60，現有 0，保留 40）」，無保留時省略保留子句；數量經 `AmountCompat` 格式化。`shortage` 只存在 View，不寫入 `state.maid`，`MaidSaveContract` 的嚴格鍵集與 `SCHEMA_VERSION` 均未更動。
- UI 提示行為：分頁在「尚無可用目標」以外，優先顯示已指派職掌的 `shortage_text`；尚未指派或調整目標／保留量時，以同批次規則在本機預覽不足（不改狀態）。材料足夠即隱藏提示。
- 驗收：新增 `tests/maid_duty_preset_runner.gd`，並擴充 `tests/maid_core_runner.gd` 的規則與 View 案例（配方輸入、丹藥成本、三種職掌 shortage、保留量文字、存檔 JSON 不含 `shortage`）。L1 單一 1280×720：`tools\run_all_runners.ps1 -Only 'maid_core,maid_duty_preset,maid_ui2'` → 3/3 PASS（MAID-CORE 251、MAID-DUTY-PRESET 34、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）。未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機。

## 18. 多仙侍並行職掌（MAID-PARALLEL-1，2026-11-01 L1 實作）

- 範圍：兌現 §10「多仙侍並行職掌」。以使用者核定的「全面並行＋公平輪轉」解掉舊 `DUTY_BUSY` 鎖；不動羈絆、章節、獎勵、庫存、schema 或存檔格式，也不新增 persisted 欄位。
- 指派：`assign_duty` 移除「其他仙侍已有職掌」的拒絕；每位仙侍仍最多一個職掌，重新指派只取代自己的舊職掌。`set_duty_paused` 的恢復同樣不再要求全府無人值班。
- 推進：`MaidSystem.advance` 改為就緒者輪轉——先收集所有未暫停且非空的職掌，依 `ids.sort()` 排序；每次把共享 `remaining` 推進到「所有職掌中最早到齊」的秒數，再從冷卻已歸零者中挑「累計 `duty_actions` 最少、其次 id 較小」者執行一次，成功後重置自己的 `_cadence(duty)`。共享的 `MAX_ACTIONS_PER_CALL` 上限不變，因此並行不會放大單次結算收益；冷卻剛好在本次 `remaining` 用完時歸零者，仍會執行該次動作，維持與單一職掌相同的邊界語意。
- 產線衝突：備料與煉丹若同時佔用同一條 home 產線，後到者沿用既有 `craft`／`refine_pill` 回傳 `JOB_BUSY`，職掌記為 `BLOCKED` 並於下一個冷卻週期重試；不排隊、不搶佔、不改經濟 schema。監造走既有即時 `upgrade_building`，仍受可見、解鎖、資源、前置與等級上限檢查，可與產線職掌並行。
- View：`get_view()["maid"]` 新增唯讀 `active_duties: Array[String]`，列出生效中（未暫停、非空）的仙侍 id，順序同 `MaidRules.MAIDS`；`active_duty` 保留為其第一個值，供既有侍立展示與舊 UI 相容。
- UI：職掌分頁的「生效中」列改列全部值班仙侍，所選角色加註「（就是眼前這位）」；錯誤文案 `DUTY_BUSY` 改為「產線暫時忙碌，稍後會自動重試。」，指派成功改為「職掌已指派，將按時自動推進。」。指派按鈕不再因他人值班而停用。
- 相容：`MaidSaveContract` 鍵集、`state.maid` v2 結構與 `SCHEMA_VERSION` 全部不變；舊存檔不會因本輪獲得職掌、羈絆或資源。
- 驗收：改寫 `tests/maid_core_runner.gd` 的單一值班案例為 `_test_parallel_duties`（三位同時指派、`active_duties` 三筆且 `active_duty == active_duties[0]`、暫停一位後剩兩筆、恢復成功、共享 60 秒×5 次預算下三位 `duty_actions` 皆 >0、契約有效）。L1 單一 1280×720：`tools\run_all_runners.ps1 -Only 'maid_core,maid_duty_preset,maid_offline,maid_ui2,maid_stand'` → 5/5 PASS（MAID-CORE 266、MAID-DUTY-PRESET 34、MAID-OFFLINE PASS、MAID-UI2 62、MAID-STAND 33 checks，failures=`[]`，無 SCRIPT ERROR）；另以 `-Only 'maid_ui'` 補跑 `maid_ui_runner` 與 `maid_ui2_runner` 2/2 PASS。未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機；實機觸控與 Web 體感依 AGENTS.md 暫緩。
