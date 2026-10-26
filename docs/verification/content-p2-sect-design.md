# CONTENT-P2-SECT 設計驗收

2026-10-25；級別 **L1靜態設計**。設計階段DONE，W待核定，實作TODO，整批IN_PROGRESS。使用者指定「P2 宗門」，不是採用尚未存在的數值方案。[逐項設計](../38-content-p2-sect-design.md)／[機讀JSON](../design-data/content-p2-sect-proposal.json)。

## 來源與修改

已讀README／Roadmap／ai-handoff／development-status、docs02／25／32／34–37相關內容及07／19共用呈現規範；核對SectSystem、SectSaveContract、AlchemySystem、BeastSystem、SaveManager、SaveCodec、供給JSON與現有宗門稽核工具。沒有讀寫舊遊戲／GodTower。初次合併讀取輸出過長，後續改精選段落；一次rg包含不存在的data目錄、一次探查不存在的p2_pill_rules.gd回exit1，均是探索路徑失敗，不算驗收成功，已改讀實際alchemy_system.gd。

新增設計文件、機讀提案、專用Python靜態算表／來源保護腳本與本驗收；更新README／ROADMAP／docs25／ai-handoff／development-status和updata英文checkpoint。未改正式GDScript／content／tests／PNG／字型／玩家資料／build；未commit／push。原工作區大量修改保留，不能以git HEAD代表本輪基線。

## 命令與證據

- `tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`；未更新引擎或模板。
- `python --version`：exit0，Python3.14.2。
- `python tools/content_p2_sect_design_audit.py --capture-baseline`：exit0；先保護當時來源／資產／測試／設定及現有正常Web PCK，既有基線檔拒覆寫。
- `python tools/content_p2_sect_design_audit.py`：exit0，1256項、failures=[]，1345份受保護檔hash保持；最終結果見[audit.json](artifacts/content-p2-sect-design/audit.json)。成本、八丹費用、兩獸全部組合、資格枚舉、機率與版本／來源核對見[calculations.json](artifacts/content-p2-sect-design/calculations.json)。這是Decimal／整數合成計算，不是GDScript實作或實際保存驗收。
- `git diff --check -- README.md ROADMAP.md docs/25-system-content-expansion-plan.md docs/ai-handoff.md docs/development-status.md updata.txt`：exit0；本輪新增文件另做嚴格UTF-8與本地連結檢查，沒有以原既有修改冒充本輪新增功能。

baseline：[session-start.json](artifacts/content-p2-sect-design/session-start.json)。最終checks／failures／受保護檔數以audit為準，失敗若發生另存attempt證據，不覆寫為成功敘事。

## 發現與限制

正式6／20／6保持，候選2／10／2未附掛。八丹靈力折扣不擴大舊折扣；火鳳Era6，火鳳宗門1階即達本案餵費最低，後階用途與成本已明列；傳說兩模板因active beast互斥，不能宣稱十個同時合格。新高階reward僅允許v2註冊P2模板，不擴舊無ID快照白名單。既有sect原文備份不等於候選保存閘，本案列為SECT-1必交。

未跑Godot遊戲Runner／原生渲染／桌面瀏覽器／FPS／匯出／全尺寸／L3，未生成兩張圖，未驗自然取得新內容／持久化，不稱全量回歸通過。既有P2丹藥收尾的長時WebGL RangeError仍未修，不用本設計掩蓋。觸控／實機延期，非當前阻擋。

下一步：核定或修訂W1／W2／W3／W-save／W-art；核定後New Chat接CONTENT-P2-SECT／SECT-1核心與保存，不開其他P2／P3。停止依AGENTS Context Guard，並依docs25逐項表核定後實作。
