2026-10-25 核定追加：**使用者「採 V」，V1／V2／V3／V4／V-save／V-art全部原案核定**。八丹數值與規則不變；實作TODO、整批IN_PROGRESS。八圖仍NOT_GENERATED／實際美術接受PENDING。

本核定輪僅metadata／靜態稽核：原待核定proposal與219項成功設計audit已另存於 `artifacts/content-p2-pill-design/approval/`。更新audit斷言為六組APPROVED、使用者原文「採 V」、美術仍待接受及排除approval／approval_record／status後的完整提案相等。最新命令 `python tools/content_p2_pill_design_audit.py`：exit0，222 checks、failures=[]，1313份來源／資產／測試／設定hash保持，結果在 `artifacts/content-p2-pill-design/audit.json`；下方219項及首輪失敗為保留的設計歷史。核定輪相關六份交接文件 `git diff --check` exit0。本輪未重跑Godot／Runner／Web／匯出／L3，未改遊戲來源／PNG／玩家進度，未commit/push。

下一New Chat直接接CONTENT-P2-PILL／PILL-1核心與保存，不重問V、不開其他P2／P3。下方待核定與下一步文字保留為日期化歷史。

# CONTENT-P2-PILL 設計驗收

2026-10-25，**L1_STATIC_ONLY**。設計已交付；方案V全部待核定，實作TODO、整批IN_PROGRESS。見[逐項設計](../37-content-p2-pill-design.md)與[機讀方案](../design-data/content-p2-pills-proposal.json)。

本輪只讀取本專案來源／既有驗收、查本機Godot版本、建立設計及可重跑靜態算表，未修改遊戲來源／PNG／玩家進度／既有fixture，未commit/push。起點已存在大量已追蹤異動及未追蹤的P2天賦／RunnerResult成果；不將既有dirty項歸為本輪，未reset或覆寫它們。

## 命令與結果

- `git status --short`：exit0，確認已有Git與大量既有異動。
- PowerShell `Get-Content`／`rg`：核對README、ROADMAP、ai-handoff、development-status、updata、docs02／00／07／08／19／25／31／34／36與實際Alchemy／Tribulation／CommandProcessor／Production／IslandEconomy／TimeAdvancer／SaveCodec／SaveManager等來源。
- `& '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。
- `python tools/content_p2_pill_design_audit.py --capture`：exit0，記錄1313份src／content／assets／tests及project／export設定SHA256；不含build與既有驗收產物，不宣稱凍結Web包。
- `python tools/content_p2_pill_design_audit.py`：最終exit0，**219 checks、failures=[]**，含八ID／材料Era與單顆容量／分類／版本／未附掛／圖像待生成／概率界線／來源保持及本兩文件連結檢查。結果見[設計時audit](artifacts/content-p2-pill-design/approval/design-audit-before-approval.json)。

首輪exit1、218項中1項失敗：驗收頁連到尚未生成的audit.json，檢查在寫出報告之前執行，造成首次自連結不存在。原結果完整另存[audit-initial](artifacts/content-p2-pill-design/audit-initial.json)；首次報告生成後重跑exit0。這是靜態工具輸出時序問題，沒有遊戲規則修復，不將原失敗改記成功。

第一批閱讀有不存在的推測路徑（breakthrough.gd／capacity.gd／reincarnation_system.gd），及Windows rg路徑萬用字錯誤；已用`rg --files src/simulation`定位真正tribulation_rules／reincarnation_rules／production與直接檔案名再讀。初次大段輸出遭截斷，後續按相關段與程式定位補讀；不把原命令最後exit0冒稱所有子讀取成功。未發生遊戲測試失敗，因本輪未執行遊戲測試。

## 設計證據與限制

靜態算表檢查12正式＋8候選=20、各類2個、ID不碰撞、材料已在對應Era供應、單顆費不超已知新資源祖島基礎庫容。概率測40組Era4／5×舊丹數×兩旗標，含未必是合法服用順序的純函式邊界；不能視為40條自然路徑。Python浮點只算有界設計值，不能取代正式Amount付款驗證。

來源核對發現現有舊渡劫丹僅Era4生效、Era5沒有舊丹對應；保留不改，以新準備丹補可達場景。兩新容量效果須一致接入所有權威讀取端；現行pill遷移未在migration_pending中，不宣稱既有天賦保存閘自動涵蓋新丹。這些列入PILL-1待實作。

新圖8張全未生成，僅逐ID完整prompt；八卡／自然取得／同版Web／保存故障／玩家節奏接受均未完成。不跑Godot runner／import／Web匯出／全尺寸／L3，也不將歷史天賦121支通過當本批規則證據。

## 修改與下一步

新增逐項設計、機讀提案、靜態audit工具及專屬baseline／audit產物；更新README／ROADMAP／docs25／ai-handoff／development-status頂部與英文updata交接。`git diff --check -- README.md ROADMAP.md docs/25-system-content-expansion-plan.md docs/ai-handoff.md docs/development-status.md updata.txt`：exit0。六份交接文件保持原CRLF格式；新增文件採UTF-8。最終新增audit-initial連結後為219項，原218項首輪失敗另存，不覆寫歷史結果。

下一New Chat：先收方案V核定／具體修訂，核定後接CONTENT-P2-PILL／PILL-1規則與保存。有界L1／L2，整批最終只一次L3；不開其他P2／P3。
