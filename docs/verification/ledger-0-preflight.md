# LEDGER-0：最小事實層

2026-10-22 · **IN_PROGRESS（前置盤點完成；保存容量待核定，正式實作未開始）**

使用者本輪指定 `LEDGER-0`。依 [整合規劃](../27-life-report-and-decision-ux-integration-plan.md) 的範圍，交付當世里程碑／覆蓋、版本與封存契約；驗收新舊檔、線上離線一致、拒寫復原、重試／輪迴去重，以及收益與 RNG 不變。指定本任務不等於接受 ATM-LIFE-DESIGN 的布局、十題選文或容量提案。

## 尚待核定的唯一前置選項

docs27 任務列明訂「保存世數先核定」；[docs30 保存容量提案](../30-atm-life-design.md) 仍標待核定。本輪已送出最近 5／10／20 世選項，尚無使用者答覆，沒有將最近 10 世當作已接受。

建議最近 10 世；封存每世最多 64 事件／32 KiB、當世 64 KiB，敘事子樹總上限 384 KiB。每事件最多 384 UTF-8 bytes，凍結文字最多 4096 bytes，均計入每世上限。此額度不包含其他存檔資料、envelope、儲存字串表示與復原副本。5／20 世對應 224／704 KiB。

## 實際來源與接線發現

以下是靜態原碼盤點，沒有宣稱功能已實作或測試通過。來源 SHA256 見 [本輪清單](artifacts/ledger-0/source-hashes.json)。

| 路徑 | 現況與實作約束 |
| --- | --- |
| `src/domain/game_state.gd` | 尚無敘事資料；新增欄位須一併接 duplicate_state 與 to_snapshot_dict，否則離線候選／存檔會遺失。 |
| `src/application/game_session.gd` | submit 在 CommandProcessor 成功後增加 revision、保存 command_receipts；duplicate 回傳空 events。記錄須依成功提交與穩定來源身分，拒絕、預覽、重播不得寫事實。 |
| `src/simulation/reincarnation_rules.gd` | eligibility 成功後，先發道果與增加世數，再清空當世。必須在清空前擷取最終事實；不得封存先前讀過但已過期的預覽。 |
| `src/simulation/time_advancer.gd` | 有 legacy 聚合、經濟逐秒、advance_time_only 路徑。只在外層看最終狀態，不能還原區間內事件時刻。 |
| `src/simulation/offline_settlement.gd` | 同步離線先用 OfflineClosedForm，unsupported 時回退 TimeAdvancer；不能只在 Session 記錄。 |
| `src/simulation/offline_closed_form.gd` | 快速路徑直接推進狀態；要在已計算事件邊界接記錄，保持原運算順序與 RNG 呼叫數。 |
| `src/application/offline_coordinator.gd` | 非同步／同步均用 duplicate_state 候選，保存成功才回傳候選。記錄應跟隨候選，不在失敗時改來源。 |
| `src/simulation/island_economy.gd` | cargo_arrived 帶 route_id；open_island 成功 events 未帶完整具名島資料，需從通過驗證的命令／提交點補事實。不可從終值捏造到貨歷史。 |
| `src/simulation/sect_system.gd` | joined_sect、expedition_started、expedition_claimed 是不同事件；完成與領獎時刻須分開，不能用派遣當作完成。 |
| `src/simulation/beast_system.gd` | beast_acquired／beast_stage_up 可作來源，但尚無供敘事使用的穩定取得實例身分；同種靈獸不得直接當作同一實例。 |
| `src/persistence/save_codec.gd` | 目前 schema4；decoder 接受 2／3／4，先驗 checksum。尚無敘事驗證／遷移。 |
| `src/persistence/save_slots.gd` | 主／備輪替、readback、index；read_best 依合法 revision／settled cursor 選擇。未知版本與損壞敘事須納入 validator，不可繞過 checksum。 |
| `src/persistence/save_manager.gd` | 已有 schema2／skills 原文備份；沒有敘事版本專項遷移。保存失敗不代表命令沒執行，重試只能保存原候選。 |

## 待實作契約（不構成容量接受）

1. 以存檔內單調世序建立 life_id；事件有同世單調序號與穩定來源 ID。command_id／結算來源與事件序號職責分開；同 tick 依實際核心提交順序排列，不使用畫面、系統時間或特效 RNG。
2. 新檔從零時刻開始記錄支援範圍；舊檔從導入時刻開始 partial。覆蓋需分 complete／partial／missing／unsupported，並列明支援事件類別；缺資料不回填假 0，也不以跨世 highest_era 冒充當世峰值。
3. 只記已提交里程碑：首次建屋／設施、具名島開拓、真實到貨、境界進退、宗門加入／完成、同實例靈獸取得／成熟、壽盡。完整資源流水及權威實得機緣收據留 LEDGER-1／DECISION-1；尚未支援的類別明示 unsupported。
4. 當世峰值與記錄覆蓋用有界聚合保存；截斷事件不改寫峰值。容量滿時略去完整事件並增加 omitted_count，不能切斷 UTF-8、半句或以不存在的事件填槽。關鍵槽／最近槽策略須與核定容量一併實作及測試。
5. 轉世預覽只讀；真正轉世由最新當世狀態產生 end_state，包含實際終點、結束原因與 settlement_id。與原道果／轉世同候選保存，舊卷與新世 ID 同時生成。讀報告、取消、重播、保存重試皆不得再封存或發獎。
6. 新敘事結構有獨立 version；外層 schema 變更須完整支援既有 2／3／4。未知／無界／損壞資料先走驗證與兩代復原；不得默默丟棄後覆寫玩家進度。固定文稿與 content_version 預留契約，正式文稿生成仍屬 REPORT-1A。

## 驗收矩陣（尚未執行）

| 範圍 | 必須證明 |
| --- | --- |
| 新舊檔 | 新檔、schema2／3／4 導入、partial 起點、深複製、UTF-8 往返、未知版本／錯型／超限／checksum 拒絕。 |
| 時間一致 | 在線逐秒、批次、同步離線快速／回退、非同步離線、超額 time_only；同來源里程碑／時序／覆蓋一致。 |
| 核心不變 | 去除新敘事欄後，原快照、Amount、RNG 種子／索引及既有收益一致。不得為記錄新增隨機抽樣。 |
| 封存 | 預覽後再命令、提前轉世／壽盡、同 tick 多事件、跨世不混記、跨世峰值與當世峰值分開。 |
| 去重／恢復 | 同 command_id、拒絕／stale、重試、reload、兩代損壞回復；道果和封存皆恰好一次。 |
| 上限 | 超事件數、超 bytes、長壽、多世淘汰、emoji／中英混合、最壞鍵值、遷移未知資料；總 UTF-8 硬上限。 |
| Web 保存 | 使用隔離 origin，真實桌面滑鼠轉世、拒寫保護／保存重試、重載查驗；CLI 往返不代替瀏覽器落盤。 |

## 本輪命令與結果

- PowerShell Get-Content／rg：讀專案入口、規劃、狀態與以上原碼；Git status 確認大量既有未提交修改，均保留。一次 rg 包含不存在的 `src/simulation/island_transport.gd`，報路徑不存在；後續由實際 `island_economy.gd` 定位運輸邏輯，不把該搜尋視為完整成功。
- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。
- 來源 SHA256、文件 UTF-8／本地連結與本輪 diff 空白檢查：結果記於 artifacts/ledger-0/preflight-checks.json。
- 未跑 Godot import／Runner／原生／Web 匯出或瀏覽器；未改正式 GDScript、schema、規則、資產、build 或玩家資料。未 commit/push。

下一步仍是 **LEDGER-0**：收到容量選項後在本任務實作並完成上述驗收；不啟動 REPORT-1A、不將 ATM-LIFE-DESIGN 標 DONE。本次只是前置紀錄，LEDGER-0 未完成。

補充檢查紀錄：靜態檢查器初輪誤將Git換行提示、no-index差異退出碼當失敗；修訂時又遇Windows cp950解碼失敗與CRLF檢查問題。初輪JSON保留。最終以明確UTF-8解碼、CR-at-EOL政策檢查，沒有空白錯誤；未改永久Git設定。這些是文件檢查問題，不是遊戲測試結果。
