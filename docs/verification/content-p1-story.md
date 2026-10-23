2026-10-23 **R已核定；實作TODO，整體IN_PROGRESS。** 使用者明確回覆「採R」，一次接受R1／R2／R-save／R-art全部設計、數值、文稿、保存政策與美術製作計畫；不是未生成圖像的美術接受。無需重問方案。

本核定輪更新proposal的APPROVED_FOR_IMPLEMENTATION及原話／四組範圍、docs33核定表、audit批准斷言、五份狀態文件與英文checkpoint。`python tools/content_p1_story_design_audit.py`實際exit0，451 checks／failures=[]，1,195受保護檔案changed=[]。核定前成功結果另存[analysis-before-approval.json](artifacts/content-p1-story-design/analysis-before-approval.json)，現行[analysis.json](artifacts/content-p1-story-design/analysis.json)對應已核定提案hash。未重跑Godot／Runner／原生／瀏覽器／生成圖／匯出，未改正式規則／玩家進度，未commit/push。

下一New Chat依R接同一CONTENT-P1-STORY正式實作，按docs33 §7驗收；不開P1-ACCEPT、不重做S／T／P／SECT。本階段停止。以下待核定紀錄屬先前設計交付歷史，由本段覆蓋現行核定狀態。

# CONTENT-P1-STORY：設計交付與核定紀錄

日期：2026-10-23。狀態：**設計交付完成，R1／R2／R-save／R-art 待使用者核定；實作 TODO，整體 IN_PROGRESS。**

使用者要求：「CONTENT-P1-STORY，先做逐項設計與核定表」。本輪沒有收到採R或逐項核定，不得將提案當成已批准規則。主交付：[逐項設計與核定表](../33-content-p1-story-design.md)、[機讀原稿與完整選文](../design-data/content-p1-story-proposal.json)。

## 交付範圍與依據

已讀README／ROADMAP／ai-handoff／development-status、docs02／07／08／19／25、既有成就／機緣／丹藥／宗門／靈獸／輪迴來源、保存與DECISION-1契約。工作區現為Git repository且有大量既有dirty／untracked成果；本輪保留既有內容，沒有reset、commit或push。前置S／T／P／SECT的接受狀態沿最近日期，不因舊歷史「不開STORY」文字阻擋本輪明確指派。

本輪新增12項成就、12則機緣（36選項）**提案**，依六類各2分配；新增的正式定義數仍為0。包含逐項ID、條件／Era／人界限制、完整文稿、固定代價／效果、滿倉／Amount拒絕、終身與當世觀測、舊檔／拒寫重試及14張新圖製作計畫。實作後目標30／38，不宣稱當下可領30項／可抽38題。R1資源補給合計200木／180石／90草／340靈力／65貢獻，新增道心／道證0。

## 命令與實際結果

| 命令／工具 | exit code／結果 | 證據界線 |
| --- | --- | --- |
| PowerShell `Get-Content`、`rg`、`git status --short` | 讀取現有工作與來源；未覆寫既有修改 | 初期批次輸出過大被截斷，後改範圍讀取，不將截斷輸出作完整證據 |
| 探索 `content/processing`、`content/pills/pills.json`、`src/simulation/island_transport.gd` | 探索批次exit1：這些猜測路徑不存在 | 後以rg定位正確來源 `content/recipes/era1_3.json`、`src/simulation/alchemy_system.gd`、`src/simulation/island_economy.gd`；非規則測試失敗 |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` | exit0，`4.7.2.stable.official.ed1daf0bf` | [版本輸出](artifacts/content-p1-story-design/engine-version.txt)；沒有更新引擎或模板 |
| `python tools/content_p1_story_design_audit.py --capture-baseline` | 初輪exit1，451 checks，1 failure | [初輪analysis](artifacts/content-p1-story-design/initial-analysis.json)：錯誤是算表預期Era2新題7，E06實際需Era3，因此應6；原始碼／提案事件資格無誤 |
| `python tools/content_p1_story_design_audit.py` | 最終exit0，**451 checks，failures=[]** | [analysis](artifacts/content-p1-story-design/analysis.json)：修正預期與設計文件Era2清單後通過；是靜態／合成池比例，不是Godot測試 |
| Python交付檢查（文件本地連結、UTF-8、五份最新狀態前綴、JSON核定狀態／數量） | exit0，errors=[]；PENDING_USER_REVIEW，12／12／36 | 設計與驗收文件引用目標均存在；不是遊戲或UI測試 |

稽核檢查原18／26定義、24個新ID無重複／衝突、六類各2、分支數量／選文／有限條件與資源白名單、非改名複製的12組分支、R1獎勵總額、待核定狀態與五組池比例。固定情境第二世Era3全條件：舊W1900＋新720，新增合計27.4809%，指定新題2.2901%。未以這個算表聲稱自然生成、UI命中或持久化成功。

[protected-baseline.json](artifacts/content-p1-story-design/protected-baseline.json) 包含**1,195份**src／content／tests／assets／project.godot／export_presets.cfg／build/web檔案SHA256；最終對照changed=[]。既有凍結build/web與正式來源／資產／測試保持。這個baseline是本輪設計開始時的實際狀態，不追溯保證其他輪的檔案歷史。

## 修改檔案

- `docs/33-content-p1-story-design.md`、`docs/design-data/content-p1-story-proposal.json`：完整提案與核定碼。
- `tools/content_p1_story_design_audit.py`、本驗收文件與`artifacts/content-p1-story-design/`：可重跑靜態盤點／算表／hash／初輪失敗保留。
- `README.md`、`ROADMAP.md`、`docs/25-system-content-expansion-plan.md`、`docs/ai-handoff.md`、`docs/development-status.md`：最頂部追加當輪最新範圍與狀態，歷史文字保留。
- `updata.txt`：最頂部英文checkpoint，列核定狀態、交付與下一步。

## 未執行與下一步

沒有執行Godot import／規則Runner／原生渲染、瀏覽器、ImageGen、字型重建、Web匯出或自然流程；本輪僅設計，沒有新素材可聲稱美術已接受。沒有修改正式規則、schema、玩家存檔或build產物。核定後仍須按設計§7逐項實作驗收，不能把451項盤點稱為新內容已通過。觸控／實機依既定政策延期，非當前阻擋。

依Context Guard，本設計階段交接後停止。下一New Chat收R1／R2／R-save／R-art核定或逐項修訂，再接**同一CONTENT-P1-STORY**實作；不自動開CONTENT-P1-ACCEPT、不重做已接受S／T／P／SECT。可回覆「採R」，或以A01–12／E01–12指定修改。四組核定尚未取得是實作前置，並非本設計交付未完成。
