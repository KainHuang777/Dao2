# RES1-B：加工時間、地方庫存、物流與保存遷移

2026-10-03 · 本文件保留較早 **IN_PROGRESS核心／CLI交付** 紀錄。本日後續 RES1-B-WEB-R1 已完成桌面Web保存故障矩陣，RES1-B原型核心／相交Web範圍 **DONE**，見 [最新驗收](res1-b-web-r1.md)。正式manifest保持未啟用；裝置／自然背景凍結／長離線CPU仍待C補驗。以下「下一故障矩陣」為歷史。

相依 RES1-A 首批契約已滿足。本輪沿用其 15 資源／8 配方，沒有改配方來源比例，也沒有啟用正式 manifest。RES1-C 的島嶼場景、操作介面、正式價格與空白檔可達流程尚未交付。築基丹消耗在 economy 啟用時先檢查 canonical mirror／嚴格 count，保留遷移時超出舊 clamp 的合法存量，只扣一次並同步鏡像。

工作開始已有未提交 RES1-A 變更；開發期間另出現 DebugActions／面板／測試變更，未覆寫或歸入本輪成果。

## 已交付契約

- `IslandEconomy` 是純規則模組；`GameState.economy` 保存版本、整數 tick、島開拓、加工工作、航線設定、在途貨物。祖島庫存引用既有 `resources`，祖島的地方 inventory 必須為空，沒有複製第二份中央庫存。遠島庫存採 Amount 字串；金錢、靈力／靈氣仍在全域，靈界 float 庫存維持原狀且不投入新配方。
- `migrate_processing` 是 opt-in 命令，先有唯讀遷移預覽；拒絕不支援的 Amount 或築基丹鏡像衝突。舊建築、宗門、界域與角色狀態保留，新島未開拓。既有 GameSession revision／收據負責重送去重，保存後仍有效。
- `craft` 在 economy 啟用時變為定時工作；未啟用時保留 A 的隔離即時契約。每批開始原子扣原料、保留產物空間；不足不扣，滿倉不扣。指定批數／重複、各原料保留量、缺料等待／補料恢復可用。停止在本批完成後生效；`switch_processing` 保存下一配方設定，在本批完成後才扣下一批原料。動畫不發貨、不發產物。
- `open_island` 與 `configure_route` 使用祖島實際可用材料；遠島餘貨不能隔空付費。B 原型開拓費為 20 木＋10 石，運力 1→2 費為 20 木；遠島每資源容量 100，祖島加工容量依 A catalog。這些是隔離驗收用 v2 數值，尚未平衡／提供正式操作頁。
- 青木／玄礦／丹霞是規則 ID `wood`／`ore`／`herb`，不是九界 ID。各有獨立生產者；祖島舊建築不遷移。B 遠島基礎產率木／低石／玄銅／低草每秒 2，百年草每秒 1。設施 gate 按各島固定原型職能，正式設施升級與解鎖流程留 C/D。
- 六條有界固定航線：木→礦的木、礦→木的石、靈材／銅精→祖島，以及丹霞低草／百年草→祖島。每條航線有來源保留量、目標存量、開關和兩級載量（10／20）；每趟 10 整數秒包含載貨腿與抽象往返。中途改設定／停用只影響下一趟，當趟仍完成；不改來源／目的地，不退貨、不隨機損失。
- 出航扣來源、增加在途並保留目的空間；到貨才可消費。保留量從進行中工作及在途貨物推導，隨同工作／貨物保存，沒有可漂移的第三份計數。加工與航線不能同時占用最後一格。舊祖島存量高於新原型上限時保留既有存量、停止新產出，不裁掉玩家材料。
- economy 啟用時 `TimeAdvancer` 逐整數秒處理既有產出／BUFF／天時／壽元，再按固定順序處理地方生產、到貨、完工、新加工、出航；同階段依穩定 ID 排序。600 秒一次與不規則分段、保存重載後續推進一致。此為固定有界首段規則，不是通用物流引擎；24h 上限的長期 CPU／裝置負载仍需在 C 的實際內容量下量測。
- 離線共用既有 `OfflineSettlement`／`OfflineCoordinator`：只有最前 24h 的有效時間推進加工／貨運；其餘為年歲／到期時間，加工及貨物剩餘時間冻结、不補發。壽盡後同樣冻结，不自動輪迴。
- 輪迴預覽列出當世島開拓、地方庫存、工作及其已消耗原料、貨物／容量保留清除；既有資源繼承是依新世容量計算的單次起手額，不是舊資產比例回收。不把貨物、已扣加工原料再加回計算；manifest 外新材料也清零。圖鑑 UI 留後續。

## 保存版本與故障行為

- 新快照 schema **3**、rules `core-flow-6-island-economy`、economy `res1-b-1`；Amount 版本仍為 1，首段只支援 layer 0、非負、≤1e12，不宣稱全量大數相容。RES1-A 配方 catalog 仍為 `res1-a-1`，配方版本 1。測試 content profile 加 `+res1-b-1`，正式 manifest 仍舊。
- schema 2 可讀、缺 economy 保持未啟用；禁止 schema 2 偷帶啟用的 economy。`SaveCodec.migration_preview` 返回來源／目標 schema、原始 JSON 與讀取狀態，不改檔。`SaveManager` 載入 schema 2 後第一次新保存前，將原始 bytes 存於 `save_schema2_original` 並讀回比對；備份失敗不提交新槽。兩世代快照繼續提供故障復原。
- 載入檢查島／資源／配方／固定航線、版本、數量、整數剩餘時間、等待／切配方狀態及容量保留。非法／未知版本明確拒絕；不丟棄工作或貨物來湊出有效狀態。先驗證原始整數時間，之後才正規化 JSON 數字，避免近整數錯值被四捨五入接受。
- 離線先複製 state，再把資源／工作／貨物／游標一起提交。payload 寫入、讀回、index 更新失敗保留原 state／游標，可重試而不重扣／重發；重啟時若有完整未索引的新快照，以其完整 state＋游標恢復，不再重領。損壞最新槽回到有效前代。
- **schema 3 codec 支援已接入保存基礎；這不表示新多島經濟已在正式遊戲啟用。** 未完成相交的瀏覽器可靠保存矩陣前，不解除 content opt-in 門檻，不將新工作／貨運用於玩家正式進度。沒有修改玩家現有存檔，也未存取玩家 origin。

## 檔案與命令證據

本輪修改：`src/simulation/island_economy.gd`、`processing_system.gd`、`command_processor.gd`、`time_advancer.gd`、`reincarnation_rules.gd`；`src/domain/game_state.gd`；`src/application/game_session.gd`；`src/persistence/save_codec.gd`、`save_manager.gd`；兩個 RES1-B Runner（含引擎產生的 `.uid`）、`tools/run_res1b_verification.ps1`、全量 Runner 清單與本輪文件。

環境：Windows／PowerShell，Godot `4.7.2.stable.official.ed1daf0bf`，既有同版模板，Compatibility／單執行緒 Web。沒有安裝／升級環境。

| 命令／驗證 | 結果與範圍 |
| --- | --- |
| 引擎 `--version` | 4.7.2.stable.official.ed1daf0bf，exit 0 |
| `--headless --path . --import` | exit 0；初次匯入有既有 world-text PNG 損壞錯誤，保留於 res1-b-import.log；重新匯入無 GDScript parse／compile error，詳 res1-b-import-final.log |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_res1b_verification.ps1` | 最終專項 **251 checks PASS、exit 0**；另三個獨立程序 seed／resume／verify 全部 exit 0。日誌 res1-b-economy-final.log、res1-b-cross-process-*.log |
| 跨程序 FileStorageAdapter | `docs/verification/artifacts/res1-b-cross-process/` 專案隔離目錄；保存有正在加工／在途貨物的快照，第二程序載入收據／結算，第三程序載入 state／cursor、同時間不重領；不是 browser localStorage／IndexedDB 證據 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | 重匯入後 **44/45 exit 0，最後 debug_actions_runner exit 1**，res1-b-all-runners-final.log。B 當時為 198 checks；後續補切配方／爭用／故障案例並重跑專項與相關回歸 |
| 十項相關回歸 | A／B、M1-A／B／C／D、M3-A 輪迴、丹藥、正流程、M4-A Session：各 exit 0，res1-b-regression-*.log；B 當時 243 checks，最終再補近整數非法時間、煉丹 count 及遷移大額丹藥單次扣除案例為 251 |
| `--headless --path . --export-release Web .\build\web\index.html` | exit 0，res1-b-web-export.log；不是瀏覽器儲存／互動驗收 |
| `git diff --check` | 通過；既有 CRLF 提醒保留 |

首次全量測試因工作期間新出現的 `DebugActions` 未註冊而卡在 living_abode_runner；檢查 PID／完整命令後只停止該測試程序 682112，重新匯入後重跑。未用全域 kill 或修改其他來源。後續 debug_actions_runner 的核心部分已執行，但新面板按鈕查找失敗，這批檔案不是 RES1-B 編輯；未把全量失敗隱藏成 PASS。

最初保存比較發現其他既有 JSON 子系統的 int／float 表示差異；驗收改比較正規化後的完整 snapshot（仍保留所有欄位與數值），並正規化 economy／receipt 的整數。第一版切配方測試受既有礦場持續產出影響，修為純加工時間案例；完整 TimeAdvancer 鏈仍另測。損壞 JSON／quota／寫入中斷皆為預期故障注入，日誌保留診斷。普通沙箱執行另有 user:// 引擎日誌與憑證讀取權限診斷，受影響既有隔離保存 Runner 以正常升權執行；沒有 automatic approval rejection。

可重現 PowerShell 入口初次將預期 stderr 當作 NativeCommandError 中止；已修為保留故障診斷並逐程序檢查原生 exit code，重新執行成功。

## 尚未滿足的放行條件與下一步

1. RES1-B 仍 **IN_PROGRESS**。CLI 契約及 native 跨程序保存已交付，Web 新經濟的重載／背景恢復、拒絕儲存／quota、兩分頁單一寫入者與失敗重試尚未測試／補齊。現行 Web adapter 是 localStorage，不宣稱 IndexedDB 落盤或瀏覽器矩陣已驗。下一步優先 **RES1-B／M1-C/D Web 故障矩陣**，不要直接解除正式 manifest 門檻。
2. 跨程序 Runner 可獨立重跑；`run_res1b_verification.ps1` 合併其 seed／resume／verify。全量入口只加入一般 economy Runner，避免單獨 verify 依賴前次檔案。
3. 全量 DebugActions 面板失敗需由其所屬工作修正後再跑，不等於 RES1-B 251 checks 失敗。正式保存預覽 UI、三島地標／Godot 操作及價格／物流瓶頸玩法驗收留 RES1-C；未宣稱三島已可玩。
4. 依 AGENTS Context Guard，當前 CLI 交付階段結束後將英文 checkpoint 置於 updata.txt 頂部；下一大型瀏覽器／UI 工作使用 New Chat。
