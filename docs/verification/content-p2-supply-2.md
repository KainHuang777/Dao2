2026-10-24 後續整批收結：**CONTENT-P2-SUPPLY DONE**，人工節奏／UI已接受，L3 116／116最終通過；見[整批驗收](content-p2-supply-closure.md)。下方保留本階段原日期、失敗與證據邊界，不改寫原結果。

# CONTENT-P2-SUPPLY — SUPPLY-2 經濟與保存核心

日期：2026-10-24。`SUPPLY-2` **經濟／保存核心交付**；整體 `CONTENT-P2-SUPPLY` **IN_PROGRESS**。本階段是有界核心接線，**正式玩家入口仍用 D2，沒有宣告 Era4–6 已可玩或整段 DONE**。下階段需完成管理介面、正式入口切換及整合流程，不能把本頁 fixture 測試當作合法長流程或 Web 證據。

## 交付

- `IslandEconomy` 按 economy 子版本選四島／七島、七線／十二線及八／十一配方；原 B／C／D2 常數與參數保留。新島開拓原子扣祖島可用庫存、每資源地方容量300、只採集無工坊；調度只倍增對應島產率。新航線每趟10秒、每級10載量、最高3級；直接1→3收兩階既有費用，舊線仍最高2級。
- `IslandProgression.attach_supply()` 提供明確的供給候選接入；`attach()`、`living_abode` 的正式入口沒有切換。候選含已核定R46資料、三境／九設施；不是另一套HTML核心。`prepare_supply()` 先驗證舊版，再複製保留 jobs／pending／recipe_version／remaining／reserves／routes／trips／tick；補未開空新島與零新資源，不發離線收益、不消耗渡劫RNG。未啟用舊檔保持未啟用，超出有界Amount拒絕進入新契約。
- `SaveManager` 的槽位載入及分享碼匯入，在使用供給候選內容時建立遷移候選。首次保存先以 `save_before_supply_<原文SHA256>` 寫入並逐字讀回原JSON，再走既有雙槽提交。歸檔寫入／讀回、槽位寫入或index拒寫均可保存同一候選重試；有效舊槽保留，完整但未索引的新槽仍沿既有恢復政策。候選等待提交時 `GameSession.submit/advance_time` 及 `OfflineCoordinator` 拒絕追加操作，直到驗證保存成功；不重扣／重啟工作／重發貨物。保留schema5；新economy保存的rules為 `core-flow-18-content-p2-supply`，舊economy仍記原rules。
- `ProcessingSystem` 即時加工、`IslandEconomy` 扣料／完工／容量預留／驗證／唯讀manufacturing view統一用 `ProcessingCatalog.product_id()`；`stone_mid_bulk` 只增加 `stone_mid`，不生成配方同名庫存或帳本列。View新增 `product_id` 供下一階段UI使用，尚未修改Control。
- 七島帳本與在途帳使用版本化航線；祖島加工／運輸容量使用候選建築與既有宗門／天時／靈獸乘區，玄龜精鐵容量只乘一次，地方容量保持300。祖島自然生產保留在途／加工預留，不再被舊固定catalog上限壓住新倉庫。輪迴保留七島結構，清空當世新島／設施／地方庫存／加工／在途，不把地方或在途再複製給祖島。
- 新版小數地方產率在離線入口採權威逐秒路徑，舊整數跳算仍保留。本輪證明600秒一致性，**沒有證明新經濟48小時效能**；舊48小時對照另有本輪回歸。

修改來源：`src/content/supply_content.gd`、`src/simulation/{island_economy,island_progression,processing_system,command_processor,time_advancer,offline_closed_form,offline_economy_jump,reincarnation_rules,story_progress}.gd`、`src/domain/resource_ledger.gd`、`src/persistence/{save_manager,save_codec}.gd`、`src/application/{game_session,offline_coordinator}.gd`。新增 `tests/content_p2_supply_economy_runner.gd` 並登錄tools入口；M1-C／D runner新增 `DAO_TEST_STORAGE_ROOT` 測試目錄選項，M1-C額外將Session與破壞性槽位fixture分離，避免讀取預設玩家保存。

## 驗收與命令

Godot版本命令回報 `4.7.2.stable.official.ed1daf0bf`。每組均先 `-Only '<相同檔名>' -List` 確認範圍。沒有執行 `-Full`，預設單尺寸政策；本段不含UI修改，因此沒有Web抽驗、匯出或L3。

```powershell
# L1：5支精選，單尺寸
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_data_runner.gd,content_p2_supply_economy_runner.gd,res1a_processing_runner.gd,res1b_economy_runner.gd,res1c_progression_runner.gd'
# L2：共用保存、Session、離線及帳本依賴，因此擴到8支，仍非全量
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_economy_runner.gd,m1a_core_runner.gd,m1c_persistence_runner.gd,m1d_offline_runner.gd,res1c2_offline_runner.gd,offline_closed_form_parity_runner.gd,resource_accounts_runner.gd,res1d2_integration_runner.gd'
# 只補長測試，已核對五萬秒壽盡／48h對照範圍
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'res1d2_integration_runner.gd,offline_closed_form_parity_runner.gd' -TimeoutSeconds 180
# 保存測試在專案隔離目錄；新專項補驗亦納入
$env:DAO_TEST_STORAGE_ROOT = 'res://docs/verification/artifacts/content-p2-supply/disk-tests'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_economy_runner.gd,m1c_persistence_runner.gd,m1d_offline_runner.gd'
# M1-C的Session／槽位fixture分離修正後只補該支
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'm1c_persistence_runner.gd'
# 最後歸檔／分享碼／Amount防護補驗只跑新專項
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_economy_runner.gd'
python tools/compile_r46_content.py --check
python tools/supply2_delivery_audit.py
```

最終 **12支唯一相關runner均有PASS證據**，不稱全量。新專項最終 **283 checks／failures=[]**：兩舊版遷移、原子加工與滿倉拒絕、新島付費與三級物流、調度與地方封頂、玄龜容量、600秒逐秒／分段／離線入口一致、輪迴、四類保存故障×兩版本與恢復、只保存重試及分享碼原文歸檔。

證據均位於 `artifacts/content-p2-supply/`：

- [新核心最終報告](artifacts/content-p2-supply/economy-contract.json)、[最後命令](artifacts/content-p2-supply/economy-final.log)、`economy-final-logs/`。
- [L1五支](artifacts/content-p2-supply/supply2-l1.log) 與 `supply2-l1-logs/`。
- [原L2命令與失敗](artifacts/content-p2-supply/supply2-l2.log) 與 `supply2-l2-logs/`；帳本／M1-A／C2於此PASS。
- [兩長測試補驗](artifacts/content-p2-supply/long-final.log) 與 `long-final-logs/`：D2整合74.3秒／48h對照92.9秒，exit0。舊48h對照13 checks；這不是新版48h效能結果。
- [保存隔離目錄補驗](artifacts/content-p2-supply/save-final.log)（新核心、M1-D PASS，M1-C當時仍失敗）、[M1-C最終補驗](artifacts/content-p2-supply/m1c-final.log) 與對應 `*-logs/`。
- [交付稽核](artifacts/content-p2-supply/supply2-delivery-audit.json) 記錄最終12支證據選取、SCRIPT ERROR檢查及來源hash。

初輪失敗不覆寫：新runner誤用不存在的 `snapshot()`／`is_zero()`，印出219項PASS但含SCRIPT ERROR，故**無效**；保留 [無效初輪報告](artifacts/content-p2-supply/economy-contract-initial-invalid.json)，該次完整暫存stdout未及歸檔，不能宣稱已保存。修正為正式snapshot與Amount sign後重跑。另一次登錄命令Python引號錯誤，selector明確拒絕，未啟動引擎。L2原命令exit1：D2與48h對照45秒逾時；M1-C／D原 `user://` 磁碟寫入失敗。改專案隔離目錄後M1-C的Session曾共用已故障注入槽位，再分離Session adapter後才PASS；中間失敗仍保留。交付稽核首輪將只輸出`failures=[]`的帳本runner誤判為缺PASS文字；改為同時查命令的逐支PASS與stdout／stderr，修正後12支通過，原稽核失敗另存`supply2-delivery-audit-initial.json`。所有最終選取stderr無SCRIPT ERROR，但含沙箱Godot log寫入失敗及故意損壞JSON／Base64診斷，不宣稱零錯誤日誌。

兩次含D2／C2的批次對既有三份JSON fixture先讀取原bytes，`finally`逐字還原：`res1-d2-earned-era3.json`、`res1-d2-active-fixture.json`、`res1-c2-offline-fixture.json`。新測試使用記憶體adapter及本批隔離磁碟目錄，未覆寫玩家進度；未改build、未commit／push。起始工作區已有大量其他未提交成果，本頁不宣稱整個工作區乾淨。

## 下一階段

`SUPPLY-3`：讀UI／Web／建築規範，接中文名稱、管理清單／開拓成本／調度開島門檻提示、新航線與製造UI的product_id；無新島世界美術，不借舊島場景冒充。先處理首次載入供給候選需要保存、成功後才開始離線結算的共用殼流程，再切換正式 `attach_supply` 入口。補已賺得Era3→Era4–6合法命令、實料丹獸／無技能主線／輪迴與瓶頸紀錄，功能完成做當次包1280×720桌面Web抽驗。其他P2批次未授權自動開工；本段不反向觸發L3。

依AGENTS Context Guard，本核心階段驗收後交接New Chat，不在同一Session展開下一大型UI／流程階段。
