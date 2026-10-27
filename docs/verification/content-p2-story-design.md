# CONTENT-P2-STORY 設計驗收

日期：2026-10-27。**設計 DONE；方案Y待核定，實作 TODO／整批 IN_PROGRESS。驗收級別 L1 靜態。**

使用者指定「P2 成就／機緣」。前置P1、P2供給／技能／天賦／丹藥／宗門／靈獸均有日期化收結紀錄；本輪僅交 [方案Y](../40-content-p2-story-design.md) 及 [機讀提案](../design-data/content-p2-story-proposal.json)。18成就／18機緣／54分支、20個製圖prompt與有限事實／保存版本方案已齊，Y1／Y2／Y-save／Y-art尚未核定。

## 修改範圍

- 新增 `docs/40-content-p2-story-design.md`、`docs/design-data/content-p2-story-proposal.json`、本驗收頁。
- 新增 `tools/content_p2_story_design_audit.py`；提案作者／文件生成來源留於 `artifacts/content-p2-story-design/author_proposal.py`、`render_design.py`。
- 更新 README、ROADMAP、docs25、ai-handoff、development-status 及 updata 頂部checkpoint與任務入口，原歷史保留。
- 沒有修改正式規則／內容／資產／測試／玩家進度，沒有生成圖片、commit或push。既有dirty工作區保持；起點已有的tests／fixture等變更不是本輪實作。

## 命令與結果

| 命令 | 結果與證據 |
| --- | --- |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` | exit0，`4.7.2.stable.official.ed1daf0bf`；未更新引擎或模板 |
| `git status --short`、`rg --files content` 及來源閱讀 | 實際有Git與既有dirty變更。初次猜測`content/skills/era4.json`與`content/recipes/era4_6.json`不存在，改依檔案盤點讀正式`skills/era4_6.json`及`supply/era4_6.json`；不算規則測試失敗 |
| `python .../author_proposal.py` 初次 | exit1，作者腳本括號SyntaxError，尚未產出提案；修正後成功。後續`--replace`只重建本輪候選JSON，不寫正式內容 |
| `python .../author_proposal.py --replace`、`python .../render_design.py` | 最終各exit0，18／18／54與文件生成；20完整prompt未送ImageGen |
| `python tools/content_p2_story_design_audit.py --capture-baseline` | 初輪exit1；[原報告](artifacts/content-p2-story-design/audit-first-failed.json)保留。正式成就計數regex誤含巢狀resource鍵、E12缺deep_open及跨題換物正收益均已揭露 |
| `python tools/content_p2_story_design_audit.py` | 最終exit0，793 checks、failures=[]；[audit.json](artifacts/content-p2-story-design/audit.json)／[起點hash](artifacts/content-p2-story-design/protected-baseline.json) |
| 本輪12檔UTF-8嚴格讀取／兩新增Markdown本地連結檢查 | exit0，12檔／12連結、failures=[]；[文件檢查](artifacts/content-p2-story-design/document-check.json) |
| `git diff --check -- README.md ROADMAP.md docs/25-system-content-expansion-plan.md docs/ai-handoff.md docs/development-status.md updata.txt` | exit0；僅選取本輪入口／狀態文件，不把既有dirty整體當乾淨工作區 |

1405份正式來源／content／tests／assets／設定及凍結build/web檔案逐位元hash與本輪基準一致。這是「本輪未改」證據，不表示起點dirty內容已重新通過遊戲回歸。只新增文件與候選，不觸發Godot runner／import／Web匯出／L2／L3。

靜態檢查含數量／分類／ID、當境可達ID引用、來源島資格、固定正數與免費C、有限mask、100條單資源循環路徑（含起點重複列法）、單獸互斥加權池與prompt來源狀態。首次候選E17A三百草換700靈力可與E14A／E03B等形成靈力增殖，已改為300；E07B先在人工對照中改為3鐵換40低草，避免與E13A增殖。全部只是候選修訂，不是修正式遊戲bug。

本案成就一次性總獎勵：靈力4000、下石700、低階草420、木160、貢獻180；無新道心、道證或魂。第二世Era6持鹿／鶴／鳳時新題最多16，合計率23.85%，指定題1.49%、平均11.18模擬小時；固定中性條件的算表，不是自然命中統計或等待上限。龜鳳與鹿鶴互斥，不能把不同世的事件當同池。

## 未執行與下一步

未跑遊戲runner、自然合法路徑、原生／桌面Web互動、匯出、L3或效能測試；未生成／接受20圖。單資源閉環稽核不等於含多原料、正式配方的完整經濟證明；實作仍需Amount付款後容量、預留、旗標觀測、版本／候選保存及重試契約測試。

本輪設計DoD滿足，不等於整批DONE。下一New Chat核定／修訂Y，再接同批STORY-1核心／保存；STORY-2再製圖與卡片／合法代表流程，人工接受後唯一L3收尾。依Context Guard停止，不開其他P2／P3。
