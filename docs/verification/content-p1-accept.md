# CONTENT-P1-ACCEPT：同版整合與第二世比較

日期：2026-10-23 開始／2026-10-24 交付（Asia/Taipei）。狀態：**DONE；2026-10-24 使用者明確回覆「接受P1整合節奏」，人工接受完成，P1整段收結**。S／T／P／SECT／STORY 的既有圖像接受有效；沒有新增圖像或重問美術方向。

## 範圍與版本

- 相依：五批 P1 已完成；STORY 的兩項歷史保留稽核失敗，已由使用者接受已揭露例外結案，仍保持原失敗與原 baseline。本輪不改寫或重新豁免它們。
- 使用 Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility、單執行緒 Web，schema5／`core-flow-17-content-p1-story`。本輪沒有更動正式經濟、獎勵、RNG、保存格式或圖像。
- 正式候選：`build/web-content-p1-accept`；隔離審閱候選：`build/content-p1-acceptance`。兩者沿同一正式規則來源；審閱版只覆寫主場景，加入暫停、唯讀觀測、拒寫與合法取得快照。不能把審閱版當正式新手起點。PCK 不同，不宣稱兩包位元組相同；完整 SHA 見各包 `compression.json` 與本輪交付稽核。
- [本輪起點 565 檔 hash](artifacts/content-p1-accept/start-hashes.json) 是新任務的保留基準，沒有取代 STORY 原 baseline。既有 dirty 工作保存在 [start-status](artifacts/content-p1-accept/start-status.txt)。10 份原 fixture 有原位元組備份，L3 後復原；新增的 `content_p1_accept_*.json` 是本輪產物。

## 可達路徑與時間的解讀

[integration.json](artifacts/content-p1-accept/integration.json) 是**本輪當前來源**由 `create_new_game` 開始、正式命令與加速模擬的證據。未直接填入資源、建築、Era、技能點、道心、年齡、靈狐經驗、機緣題目或冷卻。新遊戲的固定初始 seed 只為重現；沒有搜尋 seed 或重抽以取得指定題目。宗門沿既有全域測試 RNG；機緣使用正式獨立保存 RNG。

| 節點 | 當世模擬秒數 | 實際驗證 |
| --- | ---: | --- |
| 首世到金丹1層 | 5,728 | 採集、T1建築、築基、雙島加工／航線、靈液、藏經閣／經書殿、築基靈池與正式突破 |
| 五個 P1 技能各一階 | 5,728 | 既有自然產點存量支付，逐一正式研習 |
| 四個 P1 丹藥 | 5,728 | 正式原料逐一煉製／服用，當時四種效果並存 |
| 宗門兩新功法／一商品 | 6,629 | 真正入宗、派遣、模擬等候、領貢獻，再付費學習／購買；未直接填貢獻 |
| 自然抽到一則新機緣 | 10,829 | 沿真實冷卻與正式待決池抽取，以正式選項完成；不是指定事件注入 |
| 首世壽盡 | 44,400 | 正式時間推進至當世上限；沒有插入往生蓮臺或改年齡 |
| 首次普通輪迴 | 第二世0 | 真正結算20道心；清除技能／丹藥／人界建築 |
| 第二世重建到金丹 | 第二世3,908 | 不買天賦也能重建；保留20道心，再建立七個完全隔離比較分支 |

首世 prefix 沿既有合法測試路徑，包含故意測技能點封頂的600秒等待、補滿技能點等操作；**5,728秒不是最佳策略、資源單段5–10分鐘判定、玩家必需等待或瀏覽器連續自然長跑**。首次壽盡需740模擬分鐘（12小時20分）；本輪為 CLI 加速模擬，不偽稱連續真人遊玩。第二世較快亦包含保留道心等既有跨世結果，不歸因為尚未購入的新天賦。

## 同齡第二世的實測比較

選擇時均為第二世金丹1層、3,908秒、同一重建快照。購入立即生效；本次先共用一條不購買天賦的重建路徑，再各自分支購入，**不代表七條從新生起點採不同策略的最佳通關時間比較**。每分支都正式煉製／服用聚靈丹、取得靈狐、實際按規則付草餵至成熟、保存／拒寫／只保存重試／讀回。

| 一階選擇 | 費用／剩道心 | 木／石產率（每秒） | 靈力產率（每秒） | 一顆聚靈丹進度 | 靈狐成熟：餵數／草／首尾間隔 |
| --- | --- | ---: | ---: | ---: | --- |
| 全保留 | 0／20 | 1.436741 | 3.736032 | 60秒 | 20／1,000／5,700秒 |
| 丹心宿慧 | 5／15 | 1.415501 | 3.680803 | 66秒 | 20／1,000／5,700秒 |
| 百工宿慧 | 5／15 | 1.528742 | 3.680803 | 60秒 | 20／1,000／5,700秒 |
| 靈契宿慧 | 5／15 | 1.415501 | 3.680803 | 60秒 | 17／850／4,800秒 |
| 資源傳承（舊） | 5／15 | 1.415501 | 3.680803 | 60秒 | 20／1,000／5,700秒 |
| 長生久視（舊） | 10／10 | 1.386236 | 3.604703 | 60秒 | 20／1,000／5,700秒 |
| 先天道體（舊） | 15／5 | 1.338894 | 3.481597 | 60秒 | 20／1,000／5,700秒 |

完整金錢／草產率、壽元與修行天賦乘區在 JSON。長生一階壽元44,400→48,840秒；先天道體修行速度加數+0.1。資源傳承需**下次輪迴**才發起手資源，本次買後尚未第三世，表中不虛構其起手收益。

百工在此配置的木／石／草約高6.4%、金錢約高6.4%，靈力約低1.5%；丹心／靈契也犧牲約1.5%此配置祖島產率，換指定領域收益。靈契少3餵、150草、900秒；丹心一顆多6秒且仍受修煉上限限制。本表顯示真實取捨，不能推定任何選擇全面優勝。餵養時經過的產出會進庫，`feed_grass` 是各次正式扣料總和，並非用前後庫存淨差推定。

## 驗收命令與結果

| 級別／命令 | 結果與證據 |
| --- | --- |
| 引擎 `--version` | exit0，4.7.2；未更新環境 |
| L1 `run_all_runners.ps1 -Only 'content_p1_accept_runner.gd' -List` | 精選1支，未啟動引擎 |
| L1 同範圍 `-TimeoutSeconds 180` | 最終exit0，368 checks／failures=[]，135.3秒；[log](artifacts/content-p1-accept/l1-integration.log) |
| L3 `run_all_runners.ps1 -Full -List` | [112支選取清單](artifacts/content-p1-accept/l3-selection.txt) |
| L3 `run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 240` | 正常本機權限執行；111支通過、技能UI初輪／串行均失敗，原命令exit1；[完整log](artifacts/content-p1-accept/l3-runners-host.log)。其餘111支不重跑 |
| L3補驗：`DAO_VIEWPORT_MATRIX=full`，引擎 `--headless --script res://tests/content_p1_skills_ui_runner.gd` | 修正runner每尺寸正式開啟route後exit0，三尺寸87 checks／failures=[]；[最終log](artifacts/content-p1-accept/skills-ui-final-console.log)。合併覆蓋112／112唯一runner，不宣稱原全量命令exit0 |
| `--editor --import --quit` | exit0；[log](artifacts/content-p1-accept/import-console.log) |
| `--export-release ContentP1Acceptance build/content-p1-acceptance/index.html` | exit0，觀測器修正後[最終log](artifacts/content-p1-accept/export-review-observer-console.log) |
| `--export-release Web build/web-content-p1-accept/index.html` | exit0，[log](artifacts/content-p1-accept/export-normal-console.log) |
| `node tools/prepare_web_compression.mjs <candidate>` | 兩包 exit0，原檔／br SHA、Brotli解壓往返、4首BGM原位元組；[審閱](artifacts/content-p1-accept/compress-review.log)／[正常](artifacts/content-p1-accept/compress-normal.log) |
| `python tools/content_p1_accept_audit.py` | exit0，23 checks／failures=[]；[靜態交付稽核](artifacts/content-p1-accept/delivery-audit.json)，包含原檔保留、fixture復原、實測對比與候選／Web證據 |

180／240秒 watchdog 的理由是已確認此整合測試包含首世44,400秒壽盡、第二世重建與七分支成熟養成，單獨135.3秒、L3並行169.4秒，並非解除逾時或把SCRIPT ERROR當成功。工具目前只有全呼叫共用 timeout 參數，本輪同呼叫採240秒；日常其他任務仍沿45秒。

初輪失敗永久保留：新 runner誤讀不存在的state.rules_version使結尾SCRIPT ERROR並被45秒watchdog判失敗；修正後發現尚未壽盡即輪迴、重複activate已遷移島嶼、及直接比較未套用讀檔正規化／補0級library/scripture_hall的快照。均為驗收工具問題，已修正；沒有為通過而改遊戲規則。保存斷言現在僅接受正式SkillSystem.reconcile所補的0級鍵與revision，其他完整狀態須相同。首次完整壽盡版本45秒逾時，按已確認工作量調整180秒。原始JSON／log與讀回差異均保留於同artifact目錄。

第一次L3在沙箱無法寫隔離user://，STORY UI啟動失敗；該輪停止，不能算通過。改正常本機權限重跑，同時保留[沙箱log](artifacts/content-p1-accept/l3-runners.log)。既有FontRID／CanvasItem／ObjectDB退出診斷、預期負面案例ERROR仍可能存在；以每支exit／SCRIPT ERROR／斷言與串行重試判定，不宣稱所有日誌零錯誤。

正常權限L3唯一失敗為舊技能UI runner首個1280×720案例：診斷scroll為281×0、卡片281×1418，因未在設定尺寸後正式進入該route而檢查未開頁面；844／800後續案例原本就會經home／open而通過。先嘗試只把初始viewport提前設定仍失敗，保留[該log](artifacts/content-p1-accept/skills-ui-pre-route-console.log)。最終每尺寸設定後呼叫正式`open("skills")`，再新增「正式route可見」斷言；不刪或放寬原命中／完整卡片高度斷言。1280捲動區1212×378、卡片600×132，三尺寸87項全過。只改runner，不改正式布局；[診斷](artifacts/content-p1-accept/skills-ui-diagnostic-console.log)與最終結果都保留。226份L3原stdout／stderr另複製至本輪`l3-runner-logs/`。本輪L3是111+1修復補驗的有界覆蓋，不是一次未中斷全綠。

L3實際改動5份既有fixture，按起點位元組復原後10／10一致，見[復原記錄](artifacts/content-p1-accept/fixture-restoration.json)。`git diff --check`針對修改的既有來源／設定／runner／工具exit0，僅保留Git的LF→CRLF提示；新增文件另做UTF-8與本地連結檢查。本輪原`build/web`全部起點hash保持，未沿用STORY的較早hash作此輪基準。

Runner也刷新既有驗收目錄的JSON。12份起點乾淨的既有報告先把本輪結果複製到`refreshed-runner-artifacts/`，再按HEAD原文復原，避免覆蓋歷史；不是回退來源程式。起點已dirty的STORY `native-ui.json`原為最後單尺寸摘要，L3刷新為474項後，依仍保留的`ui-label-final.log`重建其158項／空failures的雙鍵摘要；本輪474項另存`story-native-ui-l3.json`。**此摘要沒有起點位元組備份，不能聲稱byte-identical還原**；方法與範圍記於[artifact-restoration.json](artifacts/content-p1-accept/artifact-restoration.json)。正式來源／資產／凍結包與10份src fixture的hash／位元組保留證據不受此限制影響。

## 桌面瀏覽器的證據邊界

- IAB新隔離 origin：`http://localhost:48426/launcher`（審閱）與 `http://localhost:48428/index.html`（正常候選）。`127.0.0.1`在本環境連線逾時，改localhost成功；未更動防火牆或系統代理。只綁loopback的服務須正常本機權限；沙箱首個服務已停止。
- 審閱版暫停時讀合法CLI快照；以真實滑鼠切頁、內捲、百工購入、拒寫保護→恢復→重試保存→重載。重載仍一階百工／15道心，不重扣。正常離線結算會推進年齡，實測3,908→3,925秒，未要求年齡凍結。
- 三個**iframe CSS尺寸**1280×720／844×390／800×360，Godot內部viewport分別1280×720／779×360／800×360；短式按比例換算命中。1280研習百草1、844丹火1、800丹火2；800再正式支付10草+10下品石煉納靈丹並服用，餘300秒／庫存0。這是同一第二世不同視窗連續操作，非每項新增內容108次全矩陣；逐新增ID的歷史美術／操作接受沿原批紀錄，不膨脹本次覆蓋。
- [Web逐步觀測](artifacts/content-p1-accept/web-observations.json)；[1280技能](artifacts/content-p1-accept/web-skills-1280.png)、[844技能](artifacts/content-p1-accept/web-skills-844.png)、[800技能](artifacts/content-p1-accept/web-skills-800.png)、[800納靈丹](artifacts/content-p1-accept/web-pill-800.png)、[拒寫](artifacts/content-p1-accept/web-save-refused-final.png)。首版觀測器會隨保存保護暫停，第一筆artisan-refused是過期值；修正為PROCESS_MODE_ALWAYS後重跑，以artisan-refused-final及artisan-reloaded為準，不刪錯誤觀測。
- 正常候選空白新檔在1280×720實點採集20靈氣→營造首座茅屋→重載，未載任何驗收快照；[建成圖](artifacts/content-p1-accept/web-normal-first-hut.png)。後續到金丹／壽盡／第二世為本輪CLI證據，沒有虛構瀏覽器連續自然長跑。
- 審閱包最初在BGM companions複製前載入，console保留首曲下載失敗警告；後續壓縮工具已提供並校驗4首原檔。正常候選啟動console查詢空；不把前者警告改寫為從未發生。不宣稱人工試聽通過。

## 2026-10-24 人工節奏接受與收結

使用者明確回覆「接受P1整合節奏」。接受下列已交付結果：三種新天賦專長取捨與持有道心機會成本、四丹300秒定位與材料成本、技能點等候及首次壽盡時間。既有五批圖像接受與STORY已揭露例外繼續有效。CONTENT-P1-ACCEPT與P1整段標為DONE（桌面／Web有界），沒有擴大為瀏覽器連續自然長跑或最佳策略證據。

[接受metadata](artifacts/content-p1-accept/closure-decision.json)記錄本次原話、範圍、日期與下一步。原delivery-audit.json的PENDING為技術交付時點紀錄，原檔保留，由本次closure-decision覆蓋目前人工接受狀態；原L3命令exit1、修復補驗與STORY歷史失敗保持。

本輪修改README、ROADMAP、docs25、ai-handoff、development-status、本驗收文件、closure-decision.json與updata.txt。驗收採L1文件／metadata靜態檢查：PowerShell讀取與Git狀態檢查、Python嚴格UTF-8／相對連結／接受狀態一致性及既有非文件工作hash保留檢查、git diff --check。未重跑Godot、runner、瀏覽器、匯出或L3；同日既有證據沿用。靜態結果見[closure-checks.json](artifacts/content-p1-accept/closure-checks.json)。未改遊戲規則、PNG或玩家存檔，未commit/push。

下一New Chat可由使用者指定RES1-E-46來源稽核與規則表設計；規則表核定後再接CONTENT-P2。兩者均未開始。下方「交付與人工接受」保留技術交付時的待接受歷史。

## 交付與人工接受（技術交付時點歷史）

本輪新增：整合runner、10份合法快照、隔離審閱scene／script／server、交付audit／報告／artifact。正式living_abode只增加專屬custom feature的隔離namespace，project與export設定新增審閱入口；registry增加一支runner。規則／玩家存檔／原build/web／PNG保持，未commit/push。

人工節奏接受範圍：本表的三種專長取捨、四丹300秒定位與材料成本、技能點等候和首次壽盡時間。既有美術已接受，不要求重審全部圖。**未收到這次結果的明確接受前，CONTENT-P1-ACCEPT與P1整段都不標DONE，不自動開RES1-E-46／CONTENT-P2。**

英文checkpoint置updata.txt頂部，同步README／ROADMAP／docs25／ai-handoff／development-status。依Context Guard，技術交付階段停止；下一New Chat只接人工接受或具體修訂，不重跑L3，除非相關來源／環境有變更。
