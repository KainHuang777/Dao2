2026-10-26整批更新：兩圖／卡片／節奏已接受，最終18px正常候選與供給原始日誌補驗完成，整批DONE；見[收尾驗收](content-p2-sect-closure.md)。下方為歷史。

# CONTENT-P2-SECT／SECT-2：兩卡、兩圖與合法代表流程

2026-10-25 後續補驗：**SECT-2 技術交付 DONE（L1／有界L2，桌面1280×720）；整批 CONTENT-P2-SECT IN_PROGRESS，兩圖／卡片及整合節奏待使用者接受。** 本次使用者再次指定「SECT-2」，接續上次待驗，沒有將這句視為美術或節奏接受。下方 EACCES／未DONE 內容保留為較早歷史。

## 本次完成的桌面 Web 補驗

- 隔離網址本次可達；先核對前次紀錄19份來源／包hash全部一致，沿用同日七支runner及原生證據，沒有因換輪或文件更新重跑。原localhost EACCES／四次IAB逾時保留，不宣稱已找出或修改系統成因。
- 首次元嬰學法後出現「狀態已1階、卡片仍0階」：暫停驗收場景漏了按鈕釋放後正常refresh。只在 `src/verification/sect2_acceptance.gd` 的250ms觀察迴圈補 `panel.update_view(state)`；正式遊戲既有refresh、規則／SectPanel／數值／兩張圖保持。`--headless --check-only --script res://src/verification/sect2_acceptance.gd` exit0；重匯當次 `Sect2Acceptance` exit0，見 `harness-refresh-check.log`／`export-web-retry.log`。不把check-only算遊戲runner。
- CUA真實滑鼠操作、捲動、HTML情境／拒寫／重載控制，**Godot viewport 實測始終1280×720**；外層1680×800僅容納48px驗收工具列及右側唯讀摘要，非新增遊戲測試尺寸。完成元嬰與煉虛兩條既有已賺得分支，沒有直接呼叫遊戲函式或注入新貢獻／材料／境界。

| Web 分支 | 真實操作與結果 |
| --- | --- |
| 元嬰 | 貢獻 **644→524** 學玄煉1階；**524→374** 學龜鳳1階時拒寫；再次點重試仍拒寫，貢獻／階數不變；恢復正常再保存，仍374。精鐵匣 **374→284**、終身次數1，拒寫再次重試／恢復／重載皆不重扣；重載保留兩法1階＋精鐵匣1次＋284，再以共用CloseSeal返回洞府。千草匣顯示當世化神、元嬰「境界未達」 |
| 煉虛 | 貢獻 **615→465→345** 依次學龜鳳／玄煉1階，實際木450→250（這次正常保存未介入恢復結算）。火鳳預覽學前10→9、學後9→9，後階取整平台可讀。既有精鐵3002超倉，精鐵匣顯示「庫存已滿」；千草匣 **345→225**、次數1，拒寫／再次重試／恢復／重載不重扣。重載保留兩法1階＋千草匣1次＋225，再返回洞府並重開宗門兩卡 |

元嬰首次玄煉操作發生於暫停場景refresh修正前；已在修正後PCK重載驗階數及原扣款，煉虛同ID亦於修正後包實際首次學習。不能把首次操作時未刷新的卡片畫面當作最終成品。

新[瀏覽器稽核](artifacts/content-p2-sect-ui/browser-acceptance.json)：**18項／failures=[]、38份觀測、15張PNG**，保留每階段revision／貢獻／功法／購買次數／保存狀態／返回可見性及PCK hash。原始橋接觀測 `browser-states.jsonl`；瀏覽器最終warn/error查詢空，見 `browser-final-diagnostics.json`，不外推零錯誤或長時穩定性。範例：[兩卡完成畫面](artifacts/content-p2-sect-ui/web-final-cards.png)、[功法拒寫](artifacts/content-p2-sect-ui/web-era4-technique-refused.png)、[元嬰重載](artifacts/content-p2-sect-ui/web-era4-reloaded.png)、[火鳳平台](artifacts/content-p2-sect-ui/web-era6-phoenix-plateau.png)、[煉虛重載](artifacts/content-p2-sect-ui/web-era6-reloaded.png)。

實際費用以正式命令及可見貢獻／階數／次數核對；恢復與重載會走正式離線結算，不能把其間資源增長誤當重複交付。本次未測瀏覽器實餵，實餵玄龜鐵29／石98與火鳳草9沿前次44項合法CLI證據；未宣稱全新模板在Web自然取得。

觀測曾在升階後立即截圖時呈現短暫容器重排，後續穩定畫面恢復正確界線；沒有把瞬間當作持續溢出，也未量測FPS或長時WebGL。Storage.setItem拒寫是在獨立測試命名空間，非IndexedDB／整體瀏覽器持久化故障全矩陣。兩圖與其prompt／原圖／runtime hash保持，不自動接受美術。

本次只改驗收harness／本機測試PCK與紀錄。由前次delivery核對，19份中僅上述harness和PCK有差異，W規則／正式UI／資產／fixture保持；既有歷史runner JSON未重寫，無需重做20241份封存或再跑runner。未L3／全尺寸／壓縮候選包、未改玩家進度、未commit/push。

依Context Guard，本技術子階段停止，**下一New Chat先收兩圖／卡片及整合節奏接受或具體修訂；接受後才做同批唯一L3收尾，不開其他P2／P3。** 下方為第一次技術交付與當時缺口，現在Web缺口由本節解除。

---

2026-10-25。**兩圖／卡片與 CLI 合法流程已交付；SECT-2 IN_PROGRESS，桌面 Web 待驗；整批 IN_PROGRESS。** 使用者指定「SECT-2：兩卡、兩圖與合法代表流程」。沿 W 原數值，不重問規則。沒有 L3、全尺寸矩陣、候選包或玩家進度修改，未 commit／push。

## 已交付

- 玄煉節息訣／龜鳳育靈法各一張內建 ImageGen 原創透明 RGBA 插圖，原圖與 runtime 逐 byte 相同，alpha 0–254 保留；未改圖、未重採樣。提示詞、來源、SHA256、用途、切層及授權說明見 [art manifest](artifacts/content-p2-sect-ui/art-manifest.json)。**兩圖尚待使用者美術接受。**
- 共用 SectPanel／UiIllustration B、GameTab、CloseSeal、黑體及 44px 操作保持。兩法卡顯示當前→下階的正式實費；八丹只直接靈力，其他材料不折，八 ID 對應名稱在提示。玄龜／火鳳讀正式整數餵費，明示火鳳當世煉虛與第2–5階草費不再降。效果只在結構／倍率變更時重建，避免每幀複製完整狀態。
- 抽出唯讀 `SectSystem.technique_requirements`，正式學法與 P2 按鈕共用前置／不足／滿階判定。沒有改學法成本、效果或付款算法。
- 坊市正確顯示元嬰／化神、寒銀／古藥已開、整包數量與終身餘次；來源島未開、供給未開、壽元已盡、滿倉及容量資料異常分別呈現，不都標成滿倉。委託高階資源沿共用名稱。
- **實際資產修正**：方案 W 所稱「既有精鐵／千草圖」在工作區與 ResourceIcon registry 均不存在。兩商品依共用「無專圖用具名文字」規則顯示精鐵／千草字印，沒有假借其他礦物圖或額外生成兩張。機讀計畫同步修正；十委託沿現有題材／品階圖。

## 分級驗收與邊界

本段 **L1＋有界 L2，單一 1280×720／matrix=single**。七支唯一 runner 最終分段通過；保留原失敗，不宣稱單次全綠或全量回歸。

| 範圍 | 實際結果 |
| --- | --- |
| L1 新 UI `content_p2_sect_ui_runner.gd` | **64 checks，failures=[]**。兩卡實圖、兩商品具名字印、44px／寬度／可達性、餵費預覽、五類功法與五類商品 gate／具體拒絕原因；純 UI fixture，不當自然取得證據 |
| L2 合法流程 `content_p2_sect_flow_runner.gd` | **44 checks，failures=[]**。兩條獨立已賺得 Era4／Era6 快照分支；正式入宗、自然抽委託、派遣／推進模擬時間／領獎、兩法首學、兩商品各買、實餵／冷卻、隔離保存與重載 |
| L1 核心共用前置相依 | `content_p2_sect_runner.gd` **4189**、`content_p2_sect_save_runner.gd` **957**、`content_p1_sect_runner.gd` **8578**，全 failures=[] |
| L2 共用宗門 UI 相依 | `content_p1_sect_ui_runner.gd` **23**、`uix_r9_sect_ui_runner.gd` **84** 最終通過。含既有宗門派遣／保存故障與只保存重試的 CLI 接線；不作真實 Web 鼠標證據 |
| 原生渲染 | 新 UI runner 非 headless **64 checks／exit0**，四張 1280 PNG；[兩卡](artifacts/content-p2-sect-ui/native-1280-1-6.png)。原生 harness 最終 headless 起動 **exit0**、`SECT2_REVIEW_READY era=4`，只驗可載入 |
| 引擎／字型 | 本機 `4.7.2.stable.official.ed1daf0bf`；import exit0。`subset_game_fonts.py --check` 初次缺 U+63C0，依既有工具重建兩 runtime 字型，最後 check exit0；字重／度量檢查沿原工具 |
| 當次本機 Web 測試包 | `--export-release Sect2Acceptance build/sect2-acceptance/index.html` 最終 exit0；四 BGM companion 已複製。僅本機抽驗包，沒有壓縮／候選交付／L3 |
| 桌面 Web | **未驗**。IAB 四次連線 `ERR_CONNECTION_TIMED_OUT`，本機 socket／Node health 明確 `connect EACCES 127.0.0.1:4476`。沒有成功載入、沒有瀏覽器遊戲截圖或真實鼠標／拒寫恢復／重載／返回通過聲稱。見 [blocked](artifacts/content-p2-sect-ui/browser-blocked.json) |

七支的理由：本段抽出共用宗門前置並修改既有宗門頁，需保護 P1 核心／保存與兩支既有 UI 接線；只精選此領域，未擴全量。每批經 `tools/run_sect2_checks.ps1` 先呼叫 `run_all_runners.ps1 -Only '<完整檔名>' -List`，再執行同 selector。預設45秒；只有已確認大量模擬派遣／保存的流程延長240秒，最後36秒完成。

完整命令與 stdout／stderr 在 [runs](artifacts/content-p2-sect-ui/runs/)；核心首批 `20261025-095227-802`、保存／P1 `095311-189`、合法流 `095614-662`、UIX 最終 `100048-942`、兩 UI 最終 `100519-015`。原生／匯入／匯出見同目錄 `native-render.log`、`import-final.log`、`harness-final.log`、`export-current.log`。

## 合法取得與抽樣

[flow.json](artifacts/content-p2-sect-ui/flow.json) 保存兩來源 SHA256、每件自然委託完整凍結內容、時間、正式餵費與檢查結果。來源為 `content-p2-supply-3/earned-era4.json` 及 `earned-era6.json`；透過 SaveManager 原文歸檔與候選提交遷移，不手塞貢獻、委託、材料或境界。

最終 Era4 分支6件委託／模擬1740秒；Era6分支7件／1800秒，均達足額貢獻後兩法各學1階及本境補給。玄龜鐵29＋石98，火鳳千草9，正式扣款／冷卻與重載已核對。Era4／Era6 是獨立代表分支，**不是同一角色從 Era4 連續升到 Era6，也不是瀏覽器自然牆鐘長跑**。

本次自然新模板僅抽到 `deep_stock_register`，另外兩法／兩商品共4個新操作 ID 可達；不能稱10個模板全部自然取得。十模板逐ID可控 fixture／凍結／領取契約沿 SECT-1（同日）4189／957核心證據，與自然抽樣分開。

## 原失敗與處理

- 初版流程少傳保存 metadata，parse error；之後 user:// 沙箱寫入失敗，改本專案隔離資料。另一次45秒逾時不是成功。最終正常流程36秒完成。
- 初版重載直接比較 Dictionary 的 int／JSON float 造成兩項假失敗，改 JSON 正規化語義比較；原 [flow-first-reload-assertion-failed](artifacts/content-p2-sect-ui/flow-first-reload-assertion-failed.json) 保留。
- 初版 UI 誤以為存在精鐵／千草 PNG；已改具名字印；餵費 `%s` 顯示浮點樣式改整數展示。透明圖 alpha 上界254為生成原值，沒有為滿255重寫圖檔。
- 舊 P1 UI 只等固定幀數即讀未完成場景、卡數仍6、舊報告不可寫；改等待實際入口、8卡及隔離報告。UIX舊 user:// 拒寫與初始化後規則／離線報告覆層造成返回被阻擋，改專案隔離儲存，按報告關閉流程後驗返回，不移除保存保護。
- 原生 harness 初版把日期1970的 fixture直接開成離線長跑，該程序已主動中止（exit1，不算成功）；原生 fixture改只更新保存時間 metadata，最終重新載入 ready／exit0。Web分支原已用當前時間。
- 引擎既有 user:// log／shader cache、非對稱anchors、Font RID／CanvasItem／ObjectDB退出診斷保留；不宣稱零錯誤日誌或修復長時 WebGL 問題。

20241份既有驗收／fixture JSON 先封存；其中2份變動先另存再逐 byte 還原，見 [restore](artifacts/content-p2-sect-ui/restore.json)。新增本段證據／源碼及圖資不還原；核對後只清除本輪專用baseline暫存目錄，未動玩家保存。服務連線失敗保留，測試程序主動停止與自然完成分列。

## 修改檔案

- 正式：`src/presentation/sect_panel.gd`、`src/simulation/sect_system.gd`、`src/abode/living_abode.gd`（僅新增隔離 feature 的保存 namespace）；兩張 `assets/ui/sects-painted/*.png`／manifest／Godot import與UID，`assets/fonts/runtime/`。
- 驗收：新 `tests/content_p2_sect_ui_runner.gd`、`content_p2_sect_flow_runner.gd`；調整P1／UIX-R9 runner及P1驗收場景的等待／測試隔離；新 `src/verification/sect2_acceptance.gd`／tscn／兩已賺得JSON、project feature與專用 export preset。
- 工具／文件：`tools/run_sect2_checks.ps1`、`sect2_ui_evidence.py`、`sect2_acceptance_server.py`、runner清單、本報告及狀態／機讀計畫／英文checkpoint。

## 下一步與人工桌面 Web 步驟

1. 在允許 localhost 的桌面環境執行 `python tools/sect2_acceptance_server.py`，開 `http://127.0.0.1:4476/review.html`。預期 iframe／canvas 1280×720，選 era4／era6；命名空間 `dao2_sect2_acceptance_<case>`，不使用玩家資料。若來源有新變更，先重匯 `Sect2Acceptance`，四BGM沿現有library複製。
2. 用真實滑鼠開秘術傳承、捲至兩卡，各學一階，核對實際貢獻120／150與材料10石／200木。開坊市買精鐵匣90→5鐵／千草匣120→2草；未滿足資格須具名禁用。
3. 在頁外切「寫入：拒絕」，點一次尚未買過的操作；核對僅一次扣款與進度已生效、保存失敗。再次點重試仍拒寫，貢獻／次數不變；恢復正常後只保存，重載後不重扣，關閉返回洞府。兩類操作分開記錄。
4. 保存當次狀態、截圖、包hash與瀏覽器日誌。上述尚未做，不能把 CLI 故障注入代替這段。

依 Context Guard 先記本段交接，**下一 New Chat 繼續同一 SECT-2 的待驗 Web，不開其他P2／P3**。兩圖／卡片／整合節奏人工接受後，才安排整批唯一L3；目前不標SECT-2或整批DONE。

最後靜態檢查：17份來源／工具嚴格UTF-8、本文7個本地連結、兩圖原圖／runtime及兩個Web fixture逐byte一致，`git diff --check` exit0；[delivery](artifacts/content-p2-sect-ui/delivery.json)記錄來源與本機包SHA256。文件更新沒有觸發新一輪遊戲回歸。
