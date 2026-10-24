2026-10-24 後續整批收結：**CONTENT-P2-SUPPLY DONE**，人工節奏／UI已接受，L3 116／116最終通過；見[整批驗收](content-p2-supply-closure.md)。下方保留本階段原日期、失敗與證據邊界，不改寫原結果。

2026-10-24 SUPPLY-2經濟／保存核心已交付；正式入口仍待SUPPLY-3。見[本次範圍與驗收](content-p2-supply-2.md)。以下SUPPLY-1及當時下一步保留為歷史。

# CONTENT-P2-SUPPLY — SUPPLY-1 資料契約

日期：2026-10-24。整體 **IN_PROGRESS**；第一子階段 `SUPPLY-1` 完成，**不是供給／保存整段 DONE，也不是 Era4 正式開放**。

依使用者「接續 CONTENT-P2-SUPPLY，沿已核定 R46 原案實作」。R46 四表與舊修行時間不重問、不改價；TRIB 前置沿同日已完成的獨立驗收。由於現有經濟／保存假設四島、配方 ID 即庫存 ID，先完成可獨立驗收的內容與驗證器，再接新版本經濟及保存；不得在遷移尚未完成時掛入正式 IslandProgression.attach。

## 本段修改

- `tools/compile_r46_content.py`：從已核定 proposal-1 編譯 `content/supply/era4_6.json`，保留來源 SHA256、核定原文。`--check` 可重查，不會寫玩家／build。新配方沿既有採石場3／靈植場3設施邊界，不增技能閘。
- `src/content/supply_content.gd`：只建獨立 GameContent 候選；包含七資源／三新配方／九設施／三境及島、航線、時長、調度資料。完整候選22加工資源／11配方。原 content／skills 不修改、重複擴充明確拒絕；雜湊包含加工與物流參數。未接正式 release attach。
- `src/content/processing_catalog.gd`：新增有界 `res1-e-46-1` 內容驗證，Era 上限6；原 profile 仍上限3。新增 `product_id()`，`stone_mid_bulk` 指向既有 `stone_mid`，不建立第二份庫存。可達性按「配方」逐項驗證、按「產物」展開，避免既有中石可達掩蓋另一配方的未來材料／循環。未知版本、未知產物／錯誤型別及未來依賴拒絕。
- `src/content/content_loader.gd`：允許嚴格 max_level=1 的無權重固定產率建築；多階及1.5等非單階值仍要求權重。Production 現有單階計算即提供原案加法600靈力／170錢／20下石，未修改產率公式或百工白名單。
- `tests/content_p2_supply_data_runner.gd` 及 `tools/run_all_runners.ps1`：登錄專項，核對逐境九次成本／九升十、前境容量自救、原定義保持、素材無免費祖島產出、產率／容量與重複／無效資料拒絕。

## 實際命令與結果（L1，單尺寸政策）

本機 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` 回報 `4.7.2.stable.official.ed1daf0bf`。

```powershell
python tools/compile_r46_content.py
python tools/compile_r46_content.py --check
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_data_runner.gd,m1a_core_runner.gd,res1a_processing_runner.gd' -List
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_data_runner.gd,m1a_core_runner.gd,res1a_processing_runner.gd'
```

最終三支 exit0：新資料242 checks／failures=[]；RES1-A原八配方145 checks；M1-A核心 PASS。見 [專項報告](artifacts/content-p2-supply/data-contract.json)、[選取清單](artifacts/content-p2-supply/selected-list.log)、[命令摘要](artifacts/content-p2-supply/final-runners.log) 與 `artifacts/content-p2-supply/final-logs/` 原stdout／stderr。不是全量回歸。

交接更新後靜態檢查：`python tools/compile_r46_content.py --check` exit0；本輪受影響追蹤檔 `git diff --check` exit0（保留Git行尾轉換warning）；14份本輪檔案嚴格UTF-8、此報告4個相對連結及242項結果斷言通過。文件更新不重跑遊戲回歸。

初輪新專項241項有一項失敗：JSON數字解析成float，整份Dictionary與含int的預期值比較失敗；改為逐欄比較，不改原案數值。初次命令exit1，另兩支當時已PASS。保留 [初輪報告](artifacts/content-p2-supply/data-contract-initial.json)；修正後單支先PASS，最後加一項非整數單階防護補驗三支全PASS。初輪暫存路徑在下一次沙箱命令已不存在，複製原日誌失敗，不能聲稱初輪完整stdout已歸檔；最終於同一命令即複製成功。最後stdout／stderr仍含沙箱 `Failed to open log file for writing: user://logs/godot.log`，三支無 `SCRIPT ERROR:`；不宣稱零診斷。探索讀取中曾誤用Windows rg萬用字元路徑／猜測不存在的檔名，均已改由實際檔案定位，未據此判定功能結果。

本輪未做 Godot import／Web匯出／瀏覽器／L2／L3，未改玩家保存、schema、rules版本或build。工作區起始已含大量未提交成果；後續亦觀測到其他P1報告檔異動，未寫入／還原這些外部差異，不宣稱整個工作區hash保持。新runner只寫本批資料報告，所選既有兩支未寫fixture。未commit／push。

## 下一階段（同一 CONTENT-P2-SUPPLY）

`SUPPLY-2`：用本候選資料接 `IslandEconomy`／`IslandProgression`，先完成版本化舊四島驗證與新七島建立、d-2／c-1原文歸檔讀回／候選提交與只保存重試，再掛正式內容。保留原 jobs／pending／recipe_version／trips／reserved；未啟用舊檔維持明確啟用，不追補新島離線產出。新採集只套當島調度、每資源300容量、地方無工坊；新航線三級／10秒／既有升級費，既有七線參數保持。

**產物解耦尚未接執行器**：`ProcessingSystem`（即時）、`IslandEconomy`（原子扣料、完工、預留、容量、驗證／view）、製造UI與帳本目前仍有 recipe_id=product 的假設；必須統一呼叫 `ProcessingCatalog.product_id()` 後，才可讓正式玩家見到大批中石。新候選單獨載入不等於批次已能執行。

接續補調度開島前置、玄龜容量的既有效果、可付款祖島容量／在途預留、中文名稱與管理入口（無新島美術，不以舊島世界冒充），三境合法命令／實料丹獸／600秒分段／輪迴；保存拒寫恢復重載。UI完成後L2一次當次包1280×720桌面Web抽驗。其他P2技能／丹藥／天賦／美術仍另批；此子階段不觸發L3。

依AGENTS Context Guard，本子階段驗收後停止並交接至New Chat；沿原案直接接實作，不重開設計核定。
