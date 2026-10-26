# CONTENT-P2-TALENT 設計階段驗收

日期2026-10-24；級別 **L1靜態**。設計交付，U已核定（使用者：「採 U」）；正式實作TODO、整批IN_PROGRESS。

交付：[三項逐階規則與保存設計](../36-content-p2-talent-design.md)、[機讀方案U](../design-data/content-p2-talents-proposal.json)、[可重跑稽核工具](../../tools/content_p2_talent_design_audit.py)、[算表及結果](artifacts/content-p2-talent-design/analysis.json)、[原始檔案SHA256基準](artifacts/content-p2-talent-design/protected-baseline.json)。來源commit `11be5451849e33ff9456bf1b150a9417e9fbe5dc`，開始git status乾淨。

## 命令及證據範圍

- PowerShell Get-Content／rg／git status／git rev-parse：現行六天賦、丹費、獸成長、三島率與SaveManager實際遷移接線已查。早期glob `docs/25*`、pill_system／spirit_beast_system／alchemy及persistent_game_session等猜測路徑不存在，後用rg --files找到alchemy_system／beast_system／save_manager；讀取失敗不算檢查成功，未改來源。
- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`；未更新環境。
- `python tools/content_p2_talent_design_audit.py --capture-baseline`：exit0，首次建立且拒絕覆寫。保護src／content／assets／tests／build/web／build/web-sks-p2，包含現有正式包，僅讀取。
- `python tools/content_p2_talent_design_audit.py`：最終數目與failures見analysis.json及本文件追加結果。檢查提案未核定／未附掛、三候選／固定白名單／25保底預算的可負擔組合、0–5階折扣與批量線性、獸魂有無時最少餵次、採集連續與按秒等待、正式檔案集合與逐檔hash、UTF8與連結。
- `git diff --check`及Python AST語法檢查：另於下方記最終結果。提案不是正式Godot定義，沒有新增遊戲Runner，未跑引擎import／Runner／Web／L3；不把純文件任務升級為遊戲回歸。

U1草費按Decimal核對，實作仍須Amount runner證明；U2只是來源率算例，不含航運／滿倉；U3首餵已就緒／不缺料，非自然養成。H20／25／50／100／310枚舉三新天賦全組合，舊六項以原公式／費用具體比較，沒有窮舉九項全策略或宣稱最優平衡。圖像只有三份prompt，尚未生成或接受。

修改範圍：新增docs36、design-data提案、此驗收／artifacts、audit工具；更新README／ROADMAP／docs25／ai-handoff／development-status與updata頂部。無正式規則、UI、schema、玩家資料、既有build／.godot修改，未commit/push。

下一New Chat直接依已核定U1／U2／U3／U-save／U-art接同一任務TALENT-1，不重問U。只將本設計交付標完成，九項正式天賦仍未實作，不開其他P2／P3。

## 最終結果

- 靜態稽核最終exit0：**1,606 checks／failures=[]**，1,326份保護檔案集合及逐檔SHA256保持。十一份直接規則來源另列[source-hashes](artifacts/content-p2-talent-design/source-hashes.json)。
- 首輪exit1的兩項為輸出analysis.json尚未建立時的自連結，保存於[analysis-initial](artifacts/content-p2-talent-design/analysis-initial.json)；首輪已產生輸出後原命令重跑exit0，無遊戲來源修正。
- 十份交付文件嚴格UTF8、audit Python AST、git diff --check及十一來源hash靜態檢查共13項全通過，見[static-checks](artifacts/content-p2-talent-design/static-checks.json)。
- 此為設計算例驗收，未驗新規則Godot行為、UI滑鼠、自然取得、保存故障或美術；正式九項仍未交付，不稱全量回歸通過。

## 2026-10-24 使用者核定追加

使用者明確回覆「採 U」：U1／U2／U3／U-save／U-art皆採原案，提案approval改APPROVED並保存原話、日期與五項決議。未更動效果、費用、門檻或保存方案。U-art是製圖計畫核定，三圖仍未生成／未美術接受。正式實作仍TODO。

本次只改核定metadata與文件、稽核接受斷言；依AGENTS Context Guard完成本階段即停止，下一New Chat直接實作TALENT-1。保留[設計交付算表](artifacts/content-p2-talent-design/analysis-design-delivery.json)及[設計交付靜態結果](artifacts/content-p2-talent-design/static-checks-design-delivery.json)，初輪失敗不覆寫。最新analysis.json為核定後重跑結果，下方記實際exit及數目。

核定後命令結果：`python tools/content_p2_talent_design_audit.py` exit0，**1,611 checks／failures=[]**，1,326份保護檔案SHA256保持；UTF8／Python AST／diff-check／核定仍未附掛靜態13項全通過。未重跑遊戲驗收。
