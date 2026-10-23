# LEDGER-1／REPORT-1B：資源帳目驗收

日期：2026-10-22（Asia/Taipei）。**DONE（CLI／原生／桌面Web有界）。** 使用者本輪指定此任務；範圍以 [docs27](../27-life-report-and-decision-ux-integration-plan.md) §8／§9 與 [ADR-015](../decisions/ADR-015-resource-life-accounts.md) 為準。

## 交付與檔案

- `src/domain/resource_ledger.gd`：原寫入觀測、固定來源／用途聚合、在途、完整小數、結構／大小驗證與整列略去。LifeLedger 選填 accounts／型別復原／清空前封存／新世真實期初；schema5、九世與總352KiB保持。
- `src/simulation/` 的 command_processor、time_advancer、offline_closed_form、offline_economy_jump、island_economy、island_progression、processing_system／inventory、alchemy、fortune、realm_decision、realm、sect、skill、beast、achievement、abode_scenery：已驗資格之原提交點，原運算與RNG保持。主動採集、成本、獎勵、加工、運送、生產與快取／跳算均有觀測。
- `src/application/game_session.gd`：指定世帳目深複製 API，新遊戲期初。`src/presentation/resource_accounts_view.gd`、reincarnation_panel、abode_modal_manager、living_abode：正式頁帳目入口、單資源條／表、固定操作與剛封存故障閱讀。
- 新增 resource_accounts_runner／resource_accounts_ui_runner、resource_account_assertions；沿原經濟測試補帳目 Amount 比對，保留經濟／RNG 精確快照與拒絕／保存故障的完整狀態比對。註冊固定清單92項。
- 專用合成 fixture／acceptance 場景、自訂匯出與正常候選，來源規則不依賴 fixture。沿原字型生成工具補新字，原字型／OFL不變；沒有新圖形資產。

帳目只涵蓋正式資源庫存、在途及兩種靈界資源；獨立丹藥數量、道心、道證、宗門貢獻、獸魂／BUFF／修煉仍由原系統與收據表達。沒有把不同單位加成總財富，沒有新增年度曲線或歷世比較。

## 命令與結果

所有 Godot 使用既有 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，實測 `4.7.2.stable.official.ed1daf0bf`。APPDATA 使用專案 build/ledger-1-*-user 隔離；未操作玩家 origin／進度，沒有升級／重裝。

| 命令 | 證據 |
| --- | --- |
| Godot `--version`／`--headless --path . --import` | 版本及最終 import 日誌／退出碼見 artifacts。保留既有圖片副檔名與退出診斷，不宣稱乾淨 import。 |
| Godot `--headless --path . --script res://tests/resource_accounts_runner.gd` | 最終穩定 fixture **1,419 checks，failures=[]**：權威機緣分項、同交易20／30、調整／滿倉、運送／分數運量／字串實庫存、逐列等式、線上與快速離線、舊schema5部分覆蓋、精確重載、未知版本備份／兩代拒寫、48列／12KiB及多分類壓力、完整小數與量級條界線。 |
| Godot `--path . --script res://tests/resource_accounts_ui_runner.gd` | 最終原生 **30 checks，failures=[]**；三橫式選單44px／內捲／固定收益與確認、取消不封存、保存保護、接近整數的小數可讀；9張PNG。原生截圖不冒充Web截圖。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 最終完整 **92／92 Runner exit0，SCRIPT ERROR 0**；all-delivery.log。首兩項亦為1,419專項／30 UI；全量之後沒有再改正式程式。 |
| `python tools/subset_game_fonts.py`／`--check` | 初檢缺5字，生成後check通過；原檔及授權保持。 |
| Godot `--export-release Web build/web-ledger-1/index.html` | 正常候選；最終退出碼、壓縮與hash見manifest。 |
| Godot `--export-release ResourceAccountsAcceptance build/ledger-1-acceptance/index.html` | 合成獨立候選；正式Godot頁面／保存管線。 |
| `node tools/prepare_web_compression.mjs <兩候選目錄>` | 核心壓縮往返與四BGM companions；最終退出碼見 export-exits.json。 |
| `python tools/resource_accounts_audit.py`／`git diff --check` | audit exit0：86份來源／UID嚴格UTF-8、9本地連結、9原生PNG與兩包SHA／BGM一致；diff-check exit0，保留LF／CRLF提示。 |
| `python tools/ui_shell_server.py --build build/ledger-1-acceptance --port 4403` | 專案既有本機127.0.0.1隔離服務，未變動網路／防火牆設定。驗收後於自有session以Ctrl+C停止，exit1為主動終止；瀏覽器測試分頁已關閉、viewport override已reset。 |

原始日誌放在 [artifacts/ledger-1/logs](artifacts/ledger-1/logs)。最終all-delivery.log完整結尾為ALL 92 RUNNERS PASSED；原始95個RUNNING字樣含三支runner自行重印標頭，非95支固定runner。最終整輪之後若僅增補測試，專項數以各自最後日誌為準，不把後增測試數倒填較早日誌。

## 核心／容量證據

每列 `期末=期初+實際收入−已付支出+調整`；overflow獨立、不再扣一次。機緣與即時Craft分列實際成本／產出；靈界同tick產晶／耗晶分開。轉出與轉入配在途，合併排除移轉；分數運量依真實cargo，島庫存依原字串提交值，差異列調整。

新世／新遊戲完整，舊帳缺欄位讀取不改檔；首次真實寫入以當時年歲標部分，無資料不假0。沒有逐秒事件陣列，固定48列與16分類、每世12KiB含於原額度。多分類／70資源壓力會略去整列並明示部分；轉世清空前封存，保存失敗與重試／取消不重記。

穩定 `parity-source.json` 是本輪 RES1-C2 既有runner生成之隔離資料副本，與玩家無關，凍結供新專項使用，避免全量重建舊fixture使檢查數與基準漂移。早期使用共享fixture時專項數1550／1552，後改自有固定來源後1419；兩者數量不同不代表失敗被刪除。最後bench：1800模擬秒逐秒約2.29s、快速離線約0.945s，帳目3457 bytes；這是CLI時間與有界序列化證據，沒有新FPS／GPU聲稱。

## 真實桌面 Web

IAB、滑鼠、隔離 origin4403，三個遊戲iframe CSS尺寸1280×720、844×390、800×360。外層工具JSON／尺寸／拒寫按鈕僅驗收工具，正式頁仍為Godot。合成第二世20祀，原生Session先完成同資源機緣交換：期初100、收入30、支出20、餘量110。

1. 真實滑鼠開帳目、選全域靈木、閱讀分類與條／表；800短式內捲，收益／確認固定。轉世確認後取消，archive仍0，帳目保持。
2. 啟用拒寫後正式確認：輪迴計數1→2、道心0→20，archive僅一份，帳目木100／30／20／110，保存保護可讀。
3. 拒寫再試仍計數2、道心20、單份封存；三橫式resize閱讀同帳與固定重試，不再提交轉世。
4. 恢復寫入、按原固定重試後恢復並沿原演出；重載仍2／20／一份，完整book完全相同。新世完整覆蓋／期初不是舊世收入。
5. 最終候選重載沿同origin保持相同封存；800選單行距與最末靈界項滑鼠內捲可達。console warn/error查詢空。最後匯出後再次重載：2／20／一份，完整封存book仍相同。

[瀏覽器觀測JSON](artifacts/ledger-1/browser-observations.json)與對話內CUA截圖為Web證據；磁碟九張PNG是原生證據，無假造Web截圖。原生例圖：[帳目](artifacts/ledger-1/accounts-1280x720.png)、[800短式](artifacts/ledger-1/accounts-800x360.png)、[保護頁](artifacts/ledger-1/protection-800x360.png)。

## 初輪失敗、修正及界線

- 初次未設APPDATA導致user://不可寫、舊UI測試未啟動並拋Nil.hide；終止該自有測試，改專案隔離APPDATA，不把它算通過。早期parse錯誤（錯誤變數ID／Variant型別推導／尚未import新類別）均保留日誌並修正。
- 首個採集fixture木未解鎖，原規則正確拒絕，測試改正前置；中途錯用不存在的合成航線ID亦改為正式wood_ore。未為測試放寬規則。
- 逐次累計曾誤用顯示字串，接近整數捨入使帳目流失小數；改帳目自身完整精度，未改原資源／AmountCompat公式。另避免把Amount比較精度內的浮點殘屑記為溢出。
- res1b／C1／D2／async／skills舊測試直接比整份快照，新增聚合浮點／衍生容量計數使其失敗。保留原經濟、RNG、游標與狀態精確比對，帳目另外按Amount契約比對。首次skills修正仍未過，定位為0與7e-14的假溢出，修正核心記錄後重驗；未單純跳過帳目。
- 原生／headless有既有Font RID／CanvasItem／ObjectDB／resource退出警告，負面保存／損壞案例有預期JSON錯誤；最終SCRIPT ERROR另計，不宣稱所有ERROR字樣為0。
- 瀏覽器初次重載比較false是觀測工具把重複參照輸出為`[Circular]`；改為只讀唯一book物件，完全相等。不是遊戲封存變更，保留觀測說明。

目前觸控／實機依核定政策延期，非當輪阻擋。完整大數精確、自然一生、年度曲線／歷世比較與事件回聲不由本次證據推定。沒有commit／push或覆寫凍結build/web。固定全量重建的十份原先乾淨受追蹤fixture已按HEAD原始bytes還原，清單見restored-generated-fixtures.json；本任務固定parity-source與前輪來源變更保持。

## 狀態與交接

最終固定全量92／92、候選讀回與驗收已完成；來源／UID／UTF-8／本地連結與匯出hash由 resource_accounts_audit.py 收錄manifest。本階段停止；下一大型任務為 `REPORT-2`（使用者另指定），不在本輪展開。英文checkpoint與development-status於收結同步。
