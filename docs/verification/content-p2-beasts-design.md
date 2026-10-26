# CONTENT-P2-BEAST：設計階段驗收

2026-10-26。**設計 DONE；方案 X 待核定，核心／UI／美術實作 TODO，整批 IN_PROGRESS。**

交付[逐項設計](../39-content-p2-beast-design.md)與[候選JSON](../design-data/content-p2-beasts-proposal.json)：2獸、8項獸魂天賦、既有玄龜／火鳳來源、單世一獸及11世魂價、成長／餵費／地方增產與容量、保存版本與候選閘、兩圖prompt及分級驗收。未改正式規則／玩家進度／PNG／Web包，未commit／push。

L1僅靜態：PowerShell／rg讀取本地指引與來源；本機Godot `--version` 回傳 `4.7.2.stable.official.ed1daf0bf`，exit0；Python為3.14.2。靜態稽核exit0，**631 checks／failures=[]，1363份保護檔案hash保持**。沒有啟動Godot Runner、import、遊戲渲染、瀏覽器、Web匯出、全尺寸或L3。

執行命令：

```powershell
python tools/content_p2_beast_design_audit.py --capture-baseline
python tools/content_p2_beast_design_audit.py
git diff --check -- docs/39-content-p2-beast-design.md docs/verification/content-p2-beasts-design.md tools/content_p2_beast_design_audit.py README.md ROADMAP.md docs/ai-handoff.md docs/development-status.md docs/25-system-content-expansion-plan.md updata.txt
```

第一次命令成功建立保護基準；稽核實際結果見[audit.json](artifacts/content-p2-beasts-design/audit.json)，枚舉見[calculations.json](artifacts/content-p2-beasts-design/calculations.json)，來源SHA256見[protected-baseline.json](artifacts/content-p2-beasts-design/protected-baseline.json)。稽核驗證正式4／16保持、候選2／8唯一ID、來源／門檻、20或16餵及5700／4500秒冷卻下限、階段T1與既有SKS／拓脈／丹藥乘區、地方固定容量加法、W火鳳取整平台、版本未占用與文件本地連結。這是獨立有理數計算，不是遊戲行為測試。

初讀時三次寬範圍輸出被截斷，已改定向讀取；PowerShell下`docs/25*`／`content/islands/*`等rg路徑不存在或glob無效，以及誤猜beast_panel／talent proposal單數路徑讀取失敗，均以實際檔名重新定位。兩次文件patch因上下文不匹配拒絕，改精確單檔patch完成。初次diff-check發現本次checkpoint空白行有空格，移除後重查通過；Git既有LF→CRLF提示保留，未為此重寫全檔。Python AST、JSON與六份交接頁首檢查通過。這些探索／編輯失敗沒有作為測試通過證據。

待核定X1／X2／X3／X-save／X-art；兩圖未生成未接受，兩新增獸尚無自然取得、真實滑鼠或保存故障證據。既有2026-10-25宗門玄龜／火鳳實餵證據只作日期化背景，不冒稱本批完成。下一New Chat接同批核定／BEAST-1，不因純設計或換對話跑遊戲回歸。
