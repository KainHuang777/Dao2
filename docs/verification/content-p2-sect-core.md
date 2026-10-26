# CONTENT-P2-SECT／SECT-1 核心與保存驗收

2026-10-25。**SECT-1 DONE；整批 CONTENT-P2-SECT IN_PROGRESS。** 使用者本次指定「SECT-1」，據此執行方案 W 的 W1／W2／W3／W-save，未虛構另有「採 W」回覆。兩圖尚未生成／尚未接受，卡片與合法代表流程屬 SECT-2。

方案：[逐項規則](../38-content-p2-sect-design.md)、[機讀表](../design-data/content-p2-sect-proposal.json)。本段採 **L1＋有界 L2，單一 1280×720／matrix=single**，不是全量回歸、Web 或自然取得證據。

## 交付

- 正式 registry 8功法／30委託模板／8商品。舊6功法／20模板／6商品的定義、品階權重、時間、貢獻與舊呈現順序不變。
- 玄煉節息訣五階：僅指定八丹直接靈力費以 Amount 乘整數百分比、除100後乘批量；展示、負擔判斷、付款、paid_cost／receipt與帳本沿既有單一 `refinement_cost`。其他12丹、其他丹材、加工配方不變。
- 龜鳳育靈法五階：只玄龜／火鳳餵費；與獸魂百分比合算、最後一次整數除法及至少1。火鳳當世Era6才套新因子；靈狐／雲蛟不吃此法，XP／冷卻／成熟與取得規則不改。
- 十模板先品階、再合資格池；精確凍結ID／文字／Era／時間／完整獎勵。領取驗instance及合法payload、保留原獎勵，不重驗現在Era／開島／持獸；資源只入祖島ResourceLedger一次，沿舊領獎不clamp政策。
- 兩商品各終身10次：來源島／當世Era／供給／入宗及有效祖島容量通過才一次扣貢獻、加次數與整包入庫。用 `IslandEconomy.home_cap` 和 `reserved`，包含在途預留；缺content、未知資源、非法容量具名拒絕。
- schema5不變、sect_version2、rules `core-flow-22-content-p2-sect`、正式供給content tag `+content-p2-sect`。GameState既有常數預設／duplicate／snapshot及SaveCodec讀寫已沿VERSION接入。economy／pill／talent／skill子版本不變。
- v0／v1不得夾帶P2 ID；v2註冊模板逐欄驗證；舊無template_id形狀保持舊reward白名單，P1仍只精確P1 profile。不用擴大全域白名單放高階資源。
- load／import原文雜湊歸檔→逐字讀回→同候選雙槽提交；加入宗門candidate與`SECT_SAVE_REQUIRED`，命令／時間／離線游標保持。歸檔寫入／讀取／損壞、槽寫入／損壞、索引失敗都只重試同候選。損壞歸檔先另存並讀回，再修復原文；第二次share／legacy import不能覆蓋待提交original引用。供給／宗門／丹藥／天賦同時遷移逐份保留相同原文。

## 核對時修正的文件假設

傳說P1靈狐委託也要求當前靈狐，與新玄龜／火鳳各自互斥。因此傳說池最大是舊3＋持獸1＝4，新模板每槽2%／4＝**0.5%**；無獸只舊3。原設計「最多5／0.4%／舊4」為算表錯誤，已修正說明與算表工具，不改任何資格或抽選規則。

現有GameSession沒有宗門全命令共用的壽盡禁令；方案原文對此的假設不符來源。本段對新兩功法／新兩商品明確採用P2丹藥相同壽元上限算法拒絕壽盡學習／購買；不改舊委託凍結領獎政策。供給容量是可解析數字字串，正常接受；不把不可解析值視為無限倉。

## 命令與結果

本機既有引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。同版 `--headless --path . --editor --import --quit` exit0；保留沙箱無法開user://、既有巢狀project提示，未更新引擎／模板。

每批先 `tools/run_all_runners.ps1 -Only '<下列精選檔名>' -List`。執行同selector、預設45秒、matrix=single。`tools/run_sect1_checks.ps1` 是本段薄包裝：同樣先List，再呼叫既有runner入口，設定專案內隔離儲存，並在沙箱暫存消失前封存stdout／stderr。**13支唯一runner最終分段通過**，保留原始失敗，不宣稱單次全綠。

| 級別／範圍 | 最終結果 |
| --- | --- |
| L1 `content_p2_sect_runner.gd` | **4189 checks、failures=[]**；兩法逐階實付／拒絕／正式輪迴、八丹×6階×1／5／99、12丹與加工排除、兩獸全部獸魂餵費／成長XP開關×天賦0–5×功法0–5、10模板資格及凍結領取、商品滿倉／在途預留／精確滿倉／限購／非法容量 |
| L1 `content_p2_sect_save_runner.gd` | **957 checks、failures=[]**；v0／1 load與import六類故障、同候選重試、未來版／bool／NaN／負值／額外獎勵／未知ID、缺版本、舊形狀高階資源偽造、四子系統同時遷移、14新ID命令去重／保存拒寫／重載 |
| L2 丹藥／天賦／P1宗門 | `content_p2_pills_runner.gd`、`content_p2_pills_save_runner.gd`、`content_p2_talents_runner.gd`、`content_p1_sect_runner.gd`、`m3b_sect_runner.gd` 全exit0 |
| L2 保存／供給／Session／靈獸 | `content_p2_supply_economy_runner.gd`、`m1c_persistence_runner.gd`、`m1e_import_runner.gd`、`m4a_session_integration_runner.gd`、`m3b_spirit_beast_runner.gd` 全exit0 |
| L2 離線 | `m1d_offline_runner.gd` exit0／4.0秒；單支沿歷史長測試設定TimeoutSeconds240，未因時間充足擴大矩陣 |

需要超過5支的理由：改動共用保存版本與遷移閘，並觸及煉丹唯一付款及靈獸餵費；需保護既有P1宗門、供給、天賦、丹藥、匯入、Session去重與離線依賴，故以L2精選／分段執行，不擴全量。沒有UI變更／本輪Web驗收或匯出。

永久保留的最後補驗原始log：[五支保存相依](artifacts/content-p2-sect/runs/20261025-093709-691/command.log)、[離線](artifacts/content-p2-sect/runs/20261025-093802-066/command.log)、[最終核心](artifacts/content-p2-sect/runs/20261025-093836-617/command.log)，各目錄內含完整stdout／stderr；其餘早期工具輸出在本次對話，原始失敗摘要見[失敗沿革](artifacts/content-p2-sect/failure-history.md)。早期沙箱暫存log不保證跨tool存活，未宣稱已完整複製。

## 失敗、修正與資料保護

首輪新核心誤拒字串容量、沒有明確新功法壽盡檢查；修正後補驗通過。保存runner初稿尚缺方法、receipt fixture誤給舊丹鏡像、JSON int／float字典嚴格比較造成假失敗，均修正並保留沿革。相依測試更新新版rules優先序、宗門版本上限及舊人工任務instance ID；未放寬reward驗證。M1-C／E沙箱user://拒寫，改專案內`DAO_TEST_STORAGE_ROOT`隔離資料；未碰玩家存檔。

負面fixture預期JSON解析錯誤、NaN序列化警告及引擎user:// log開啟診斷保留，不稱日誌零錯誤。沒有逾時或SCRIPT ERROR當作成功。

本段相依回歸前封存20229份既有JSON；其中3份變動先另存本輪產物再逐字還原，結果見[restore](artifacts/content-p2-sect/restore.json)。規則／資產／新專項結果不回滾。`python tools/audit_sect1_delivery.py` exit0／619項靜態檢查，核對方案逐欄、舊定義與順序不變，以及前設計checkpoint的557份既有美術／正常Web PCK hash保持，結果見[delivery](artifacts/content-p2-sect/delivery.json)。21份嚴格UTF-8與本頁8個本地連結檢查通過；相關來源`git diff --check` exit0。最終同版Godot import exit0並產生兩支新runner的UID，見`artifacts/content-p2-sect/import-final.log`；未為文件更新重跑遊戲回歸。

## 修改檔案與交接

核心：`src/simulation/sect_system.gd`、`alchemy_system.gd`、`beast_system.gd`、`island_progression.gd`；保存：`src/persistence/sect_save_contract.gd`、`save_codec.gd`、`save_manager.gd`。

測試：新增`tests/content_p2_sect_runner.gd`、`content_p2_sect_save_runner.gd`及引擎UID；更新`content_p1_sect_runner.gd`、`content_p2_pills_save_runner.gd`、`content_p2_supply_economy_runner.gd`、`m1e_import_runner.gd`、`m4a_session_integration_runner.gd`。工具：runner清單、`run_sect1_checks.ps1`、`sect2_evidence.py`、`audit_sect1_delivery.py`及設計算表傳說分母修正。另更新設計機讀表、方案、Roadmap、README、擴充計畫、handoff、development-status與updata。

未做：兩功法插圖／卡片／字型、已賺得Era4與Era6代表合法流程、桌面Web滑鼠與拒寫恢復、L3／全尺寸／候選包；皆屬SECT-2或整批收尾，整批不標DONE。觸控／實機依政策延期、非當前阻擋。

依Context Guard，本階段停止。**下一New Chat直接接SECT-2**：兩功法卡／兩張內建ImageGen透明圖、Era4自然委託→首學／補給及Era6火鳳合法代表流程，再做同功能當次包1280×720桌面Web；不重問本段數值、不開其他P2／P3。圖與整合節奏接受後才做整批唯一L3。未commit／push、未改玩家進度。
