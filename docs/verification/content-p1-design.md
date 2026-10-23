# CONTENT-P1-DESIGN 驗收紀錄

2026-10-23。**設計交付完成，待使用者核定；正式內容實作 TODO。** 交付 [docs31](../31-content-p1-design.md) 與 [12項結構化提案](../design-data/content-p1-proposal.json)。本輪沒有Godot正式內容接線、美術或UI實作。

## 工作區與交付檔案

開始時Git已存在大量未提交／未追蹤成果。先讀AGENTS、README、Roadmap、交接、status／updata、docs02／21／25與相關呈現規範，再按實際來源核對；保留所有既有變更，沒有commit／push。內容計數與比較均以工作區為準。

- 新增：docs31、design-data/content-p1-proposal.json、tools/content_p1_design_audit.py、本報告及artifacts/content-p1-design/紀錄（session-start.json、initial-analysis.json、analysis.json、command-results.json及工具語法檢查產物）。
- 同步入口：README、ROADMAP、docs21／25、docs/ai-handoff、docs/development-status、updata.txt。
- 保護範圍：[開始清單](artifacts/content-p1-design/session-start.json)記錄650份src／content／tests及project、export presets、固定Runner與凍結build/web/index.pck原始SHA256；[最終分析](artifacts/content-p1-design/analysis.json)逐份核對不變且無新增runtime檔案。

## 命令與結果

1. PowerShell `Get-Content`／`rg`／`git status --porcelain=v1`：讀取規格、定位現況與既有變更；成功。前幾次整批讀取輸出過長被截斷，改以小段來源／特定函式查讀，不把截斷當完整程式證據。
2. `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`；沒有更新引擎或模板。
3. `python tools/content_p1_design_audit.py`：最終**268項／failures=[]／exit0**，完整結果見analysis／command-results；25份權威來源hash、650份保護檔核對、12個候選ID／四BUFF、材料／容量、產點等待、設施替代、道心組合、靈狐門檻、折扣批次、滿倉收益與重服界線核對。
4. 新增Python工具 `py_compile`（輸出置本任務artifacts）、針對本輪tracked文件的 `git diff --check`：結果見command-results。

算表枚舉20道心內可負擔的舊三／新三天賦48組配法；12組靈狐階數／既有獸魂加數；四丹72個庫容／產率／初始存量場景；30個重服邊界場景，另列丹心的衰減／批數／修煉上限組合。所有為**合成靜態提案分析**；零runtime變更校驗不代表執行正式Godot測試。

初輪audit exit1：兩個連結在檢查時指向工具尚未首次寫出的analysis.json；原始失敗另存initial-analysis.json。產物首次落盤後重跑連結驗證，並補上舊丹實際定義綁定及丹心邊界算例，最終結果依command-results，不隱去初輪失敗。初版文稿的設施產率近似值及場景數亦已按算表修正。

## 證據界線與未通過項

- 沒有執行Godot import、規則Runner、原生渲染、瀏覽器滑鼠、Web匯出、自然取得或保存故障測試；這些屬核定後的實作批次，沒有從既有96Runner或舊D自然流程挪作本批通過證據。
- 設計明列祖島／地方分界、神農靈訣木產率文字與程式差異、schema5與skill保存白名單限制；未藉此修正式規則。
- 所有ID／數值／新效果通道尚待核定；§9三組決策尚未通過，不能開始相應正式內容批次。高境界供給、九界開放和全量舊檔相容不在本批範圍。
- 沒有玩家origin或存檔操作，沒有新增圖像／素材授權主張。觸控／實機照使用者政策延期，非當前阻擋。

## DoD

- [x] 5技能／3天賦／4丹藥逐項表、暫定ID、Era／realm、成本、上限、作用範圍、取得與有效用途。
- [x] 公式／先後順序／疊加／重服／溢出、線上離線、輪迴與保存遷移／故障重試設計。
- [x] 產點與材料庫容、現有替代、持有道心機會成本、單資源丹與兩限時全產丹／永久築基丹比較。
- [x] 需新增通道、未來自然代表路徑、各ID命令／桌面驗收與美術交付範圍，及三組可審閱決策。
- [x] 文件／來源可追溯、靜態算表與保護hash驗證、狀態與英文checkpoint更新。
- [ ] 使用者核定S／T／P；各自後續實作與驗收（非本輪設計交付完成條件）。

本階段停止。下一個New Chat先收S／T／P決策，核定S後再接CONTENT-P1-SKILL；不自動啟動三批實作。
