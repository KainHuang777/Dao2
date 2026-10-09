2026-10-09 **RES1-UI1-R6 DONE（有界空島圖形化）**：沿用製造／運輸手繪物品框，採集庫存／實際產率／容量條、地方原料產物、開拓與升階成本框／缺料恢復、固定切島／前往與短式下拉已接入。最終56/56（A217／B220）、三橫式Web／實際採集與倉儲升階／重載保留通過，一般Web同步。[驗收](docs/verification/res1-ui1-r6.md)。人工美術／實機與完整UI1-C／C／D仍待驗；直式iframe提示偏小需後續核對。下一New Chat收空島回饋，不重做已過保存／FPS或暫緩冷啟動。
# 修仙問道 v2

2026-10-09 **RES1-UI1-R5 DONE（有界運輸圖形化）**：七航線套用製造R4手繪物品框，來源→目的可用庫存、缺貨朱紅與真實载貨／倒數／進度；寬式雙欄、短式並排／固定成功回饋。56/56（B210）、最後B220／parity／responsive、精確Web三橫式／補料回運／自訂設定重載通過，一般Web同步。[驗收](docs/verification/res1-ui1-r5.md)。最終美術／實機待驗，下一New Chat收運輸回饋。

2026-10-09 **RES1-UI1-R4 DONE（有界物品框修訂）**：依使用者示意恢復ICON＋數量＋來源整格2px框與淡底；材料灰青／產出青玉／缺料朱紅。207／parity／responsive、原生三尺寸與Web三橫式／實際製作通過，一般Web同步。[驗收](docs/verification/res1-ui1-r4.md)。最終美術／實機待驗；下一New Chat收回饋。下方R3無框為歷史版本。

2026-10-09 **RES1-UI1-R3 DONE（有界手繪ICON）**：依使用者接受R2方向後的回饋，資源改內建ImageGen手繪材質透明PNG，撤下平塗多邊形與常態材料格框／底色，缺料朱紅數字與淡提示保留。207／呈現parity／responsive、16圖透明QC／三尺寸原生與Web製造通過，一般Web同步。[驗收](docs/verification/res1-ui1-r3.md)。最終圖示質感／實機仍待驗，下一New Chat收回饋。

2026-10-09 **RES1-UI1-R2 DONE（有界圖形化製造）**：八配方改材料ICON＋需求量→產物，不足朱紅、滿足恢复；名稱／來源／可用量保留tooltip及詳情。寬式兩欄／同屏資源，短式材料與操作並排、收起總覽。56/56（當輪A205）、最終207／B140／world59／parity／responsive及三橫式Web實測通過，一般Web同步。[驗收](docs/verification/res1-ui1-r2.md)。最終圖示美術／實機仍待驗，下一New Chat收使用者回饋。

2026-10-09 **RES1-UI1-R1 DONE（有界空島／製造修訂）**：操作成功回饋、島選中與工程可用庫存、可展開地方原料／產物、配方卡內秒數／進度與緊湊總覽、寬式同屏資源及短橫式固定篩選已接入。56/56回歸、最終164／運輸140、三橫式Web滑鼠／重載／旋轉通過，一般Web同步。[驗收](docs/verification/res1-ui1-r1.md)。效能依AGY與使用者最新標準，不重做已過FPS與保存矩陣；完整UI1-C實機／人工仍待驗。下一New Chat接受操作密度／回饋與剩餘裝置驗收。

2026-10-09 **RES1-UI1-C IN_PROGRESS**：保存矩陣16份／400 checks與56/56回歸通過，新製造／運輸拒寫重試／重載、三橫式／旋轉及世界滑鼠已驗。效能未放行：300秒／50次切頁尾窗約54FPS未恢復（重載60秒恢復），20Mbps／100ms冷啟動14.80秒超10秒；無實體裝置，使用者指定保留觸控待驗。[驗收與下一New Chat](docs/verification/res1-ui1-c.md)。完整C/D及人工接受仍待驗，不跳Era4。

2026-10-09 **RES1-UI1-B DONE（有界階段）**：七航線已改精簡列表與設定詳情，草稿／小數自訂值保留；停航仍到貨、升階保留停航、缺料與來源供給可精確定位。56/56 Runner、最終140專項、三橫式Web／旋轉恢復與自訂政策重載通過，一般Web已同步。[驗收](docs/verification/res1-ui1-b.md)。下一New Chat接UI1-C，完整保存故障／裝置／性能與人工仍待驗。

2026-10-08 **RES1-UI1-A DONE（有界階段）**：Godot 空島簡版與集中製造已接入，經營四分頁、八配方／四產線、批數／持續／切方／停工、加工坊與煉丹相同工作。55/55 Runner、最後專項127／世界59／C2世界26／parity、原生9圖与隔離Web三橫式操作／旋轉／重載通過；一般Web已同步。運輸目前保留舊控制，下一UI1-B；完整UI1-C裝置／保存／效能待驗。[驗收](docs/verification/res1-ui1-a.md)。


2026-10-08 **RES1-UI1-DESIGN**：多空島精簡[計畫](docs/16-multi-island-ui-simplification-plan.md)與可操作示意已整理：島上採集／倉儲基本操作、集中配方卡與航線管理。僅設計交付，正式Godot接入／Web與裝置驗收待UI1-A/B/C。

2026-10-07 **M2-D-FX3-AMBIENCE**：淚瀑下行擾動／落點變化霧氣、五處遠景碎片慢浮、三條匯聚流光及Era1–7吸靈24→48點已接入；五項回歸、原生13圖與低特效像素凍結／快照不變通過，一般Web／Windows同步。桌面隔離browser兩橫式滑鼠已補驗，人工／裝置／長效能仍待驗，完整FX3 IN_PROGRESS。[驗收](docs/verification/ambience.md)。

2026-10-07 **ART-A1-HOME-INTEGRATE**：新接地版聚靈陣已核對正式接線，一般Web與Windows包同步成功；五項回歸exit0。追加browser被分頁保存鎖定阻擋，人工／装置與Windows實際操作待驗。[驗收](docs/verification/altar-integration.md)。

2026-10-07 **ART-A1-HOME-GROUND**：聚靈壇改低矮底座、土石／苔草包邊與貼地暗部，撤下常態旋轉圈；四項回歸／原生兩橫式／一般Web匯出壓縮與隔離browser新版檢視通過，最終美術／裝置仍待驗。[驗收](docs/verification/altar-grounded.md)。

2026-10-07 **ART-A1-HOME**：祖島左居所／中央修士／右已建聚靈壇已接入；輪迴／重載與54/54、最後world58／responsive通過，一般Web已更新，兩橫式滑鼠升級／重載驗證通過。最終美術／裝置／長效能仍待驗，完整ART-A1／FX3 IN_PROGRESS。[驗收](docs/verification/home-landmarks.md)。

2026-10-07 **M2-D-FX3-ROUTES**：洞府裝飾循環飛劍撤下，保留主角吸靈；飛劍只顯示實際島間在途貨物。54/54與世界51 checks通過，一般Web包已更新；browser載貨／裝置／長效能待驗，完整FX3仍IN_PROGRESS。[驗收](docs/verification/fx3-flight-routes.md)。

2026-10-06 **FX3-ART1**：使用者概念圖背景去近景、質感空島、覆頭中性披風主角與角色中心吸靈／雷劫已接入；54/54及最後角色契約PASS，兩橫式Web滑鼠試播通過，完整FX3人工／裝置／效能仍待驗。[驗收與資產](docs/verification/fx3-art1.md)。

2026-10-05最新 **RES1-C2-PERF-R2 效能修復 PASS（AGY）**：持續 FPS 劣化根因已定位並修復（`building_catalog.gd` 每0.25秒無條件覆寫 ProgressBar 位置／尺寸的 reflow 風暴改值比對保護、`abode_building.gd` 不可見物件 `_process` 提早返回、`abode_flows.gd` Immediate Draw 呼叫減量）。全量 **54/54 Runner／exit0**，ADR-010 四組觀測全部恢復 PASS、`desktopRecoveryGate=PASS`。[R2驗收](docs/verification/res1-c2-agy-r2.md)。**R2 效能定位結案**；C／C2（實機觸控／高DPR／自然凍結／跨瀏覽器／長期GPU-WASM／人工美術節奏）與完整 D 仍 IN_PROGRESS，不跳 D。下方 2026-10-04／10-05 較早 NOT_PASSED 紀錄保留歷史。

2026-10-05 **SKILL-B1：採用使用者選 B**，保留六項一般技能並延續多島供給；修行→技能，築基後建藏經閣研習。舊成果完整保留，舊 Era2 經濟不覆蓋主線。[ADR-012](docs/decisions/ADR-012-optional-skills-with-islands.md)／[驗證](docs/verification/skills-b1.md)。

2026-10-05 **Git進度整合**：主目錄成果已checkpoint，舊Codex工作樹VFX已合併至main；最終53/53 Runner、獨立Web匯出與桌面／短橫式試播通過。master一般技能／舊Era2經濟與ADR-011分歧，已保存並審查、未套回；正式開發以E:/WORK/Dao2的main為準。後續git pull --ff-only origin main，分歧須回報。[整合紀錄](docs/verification/git-progress-integration-2026-10-05.md)。FX3／D2／C／R2完整驗收狀態保持原限制。


2026-10-05追加 **D2-R1 Web 保存矩陣子階段 PASS，完整 D2-R1／D2／D 仍 IN_PROGRESS**：最終 53/53 Runner／exit0；九案例、16份真實瀏覽器報告共400 checks（含215共用規則／MemoryAdapter診斷），空白正常命令到金丹十層採加速模擬秒，並非完整滑鼠通關。實際重載、quota、拒讀／拒寫、損壞、遷移及雙分頁通過；修復保存恢復後仍顯示失敗提示。正常開局滑鼠及丹霞加工拒寫／重試有追加證據。[Web驗收](docs/verification/res1-d2-web-r1.md)。剩餘自然時間完整滑鼠流程、人工／装置與C-R2放行；R2交AGY。updata已交接，New Chat續剩餘D2-R1；下方同日記錄保留歷史。

2026-10-05最新 **RES1-D2-R1 世界／美術子階段交付；完整D2-R1／D2／D仍IN_PROGRESS**：丹霞獨立赤岩島體＋藥坊PNG、世界／管理雙向入口、真實貨運視覺及四島控制換行／題字避讓已接入。全量53/53／exit0，最後世界38＋管理87及三島26／響應式回歸通過；獨立Web匯出與兩橫式滑鼠／重載證據見[本輪驗收](docs/verification/res1-d2-r1.md)。正常Web新檔完整首段、D2保存故障矩陣與人工／裝置／C-R2放行仍待驗；R2仍交AGY。依Context Guard於世界子階段checkpoint，下一New Chat續D2-R1剩餘Web驗收。下方同日記錄保留歷史。

2026-10-05最新 **RES1-D2 IN_PROGRESS（容量／技能方案與正常規則／管理接線已交付）**：使用者核定Era＋設施門檻及新增築基靈池；正常空白T1→金丹Lv10、丹霞丹液回運／T3／扣料與保存故障215 checks、52/52 Runner／exit0，最後呈現87 checks回歸／獨立Web匯出及1280×720.4／844×390滑鼠與重載通過。[D2驗收](docs/verification/res1-d2.md)／[ADR-011](docs/decisions/ADR-011-era3-capacity-and-skill-gates.md)。丹霞專用世界美術、完整Web新檔首段、人工玩法／裝置與C/R2門檻仍待驗，**D2／完整D IN_PROGRESS**；R2仍交AGY。下一New Chat續D2-R1，本輪不開下一大型階段；以下按日期保留歷史。


2026-10-05最新 **RES1-D1 DONE（稽核＋隔離契約）**：216 checks／exit0，空白開局經T1建設到Era3 Lv10，丹霞原料回運、T2→T3、金丹與修行實際扣料通過；8份DAO1 source hash一致。發現正常版Era2→3靈力容量最高1100／需求2000阻擋，隔離容量與技能替代僅提案。[D1驗收](docs/verification/res1-d1.md)。完整D TODO、C／C2／R2 IN_PROGRESS；正式內容／保存／畫面未改。下一New Chat處理D2整合準備，R2仍由AGY负责。以下同日分工是開始前歷史。

2026-10-05最新分工：使用者將 **R2交AGY**，Codex下一 **RES1-D1：Era3前置／丹霞T3隔離契約（TODO）**，可並行；R2／C／C2仍IN_PROGRESS、完整D仍TODO。已建[交接](docs/handoffs/2026-10-05-r2-agy.md)、[AGY Prompt](docs/handoffs/2026-10-05-agy-r2-prompt.md)與[Codex下一範圍／Prompt](docs/handoffs/2026-10-05-codex-res1-d1.md)，本輪未開始D1程式或新驗收。此分工覆蓋以下歷史「Codex只續R2／不跳D」接手順序，保留正式放行門檻。

2026-10-05最新 **R2持續劣化定位：本輪未重現，根因未結案**。同版正常1280×720／DPR約1，三組300秒59.744／59.564（50次管理操作）／59.744、重載60秒59.847均恢復PASS；同期CPU／GPU取證已保存。DPR與進度不同，不能消除前輪DPR1.25失敗；GPU process高CPU與heap大小不足以單獨解釋。後續由AGY完成根因修復並PASS（見頂部2026-10-05）。[定位證據](docs/verification/res1-c2-sustained-degradation.md)。

2026-10-04最新 **R2正常恢復／長觀測驗收 NOT_PASSED**：正常60秒59.880、首組300秒59.823通過；有間隔50次管理操作的300秒54.740（末45秒低谷）、同頁延長300秒48.088、重載60秒35.105均未恢復。無遊戲對照59.997只作診斷，不替代遊戲通過；木屋2→3／扣料重載、三島滑鼠與完整模式正常。Python16／Node13契約通過，無新Godot來源／匯出／51 Runner。**R2／C／C2 IN_PROGRESS、D TODO**；下一定位持續劣化，裝置／人工另待驗。[本輪驗收](docs/verification/res1-c2-recovery-browser.md)。較早政策修訂與通過結果保留歷史，New Chat續同R2。

2026-10-04使用者核定[FPS恢復標準](docs/decisions/ADR-010-idle-frame-recovery-budget.md)：常態目標60、偶發30後回升可接受；阻擋持續低FPS／劣化未恢復，取消精確平均60與p95≤20硬gate。工具正常60／300秒與16／13契約通過，舊15秒樣本只符合短窗口、長觀測待補。**R2／C／C2 IN_PROGRESS、D TODO**；以下嚴格60結果保留歷史。[修訂驗收](docs/verification/res1-c2-idle-fps-policy.md)。

2026-10-04最新[R2長幀入口追蹤](docs/verification/res1-c2-main-loop-tracing.md)：新增preflight與Long Animation Frames；83.3ms長幀對應Godot Web MainLoop_runner84.1ms，同窗process0.4ms，內部根因仍待追蹤。51/51／world26通過，正常1280×720三組pooled57.887FPS／p95 16.9ms，嚴格60未過；**R2／C／C2 IN_PROGRESS、D TODO**。英文checkpoint已更新，New Chat續同R2。

2026-10-04最新[R2 View／encode與長幀](docs/verification/res1-c2-view-encode-longframes.md)：固定快照encode17.368→14.9985ms、定時View減少重建；51/51／resource754／world26／Web retry49通過。非profile59.619FPS／p95 16.8ms／max183.3，嚴格60未過；另profile捕捉166.8ms rAF與180ms LongTask，同窗已量process0.3ms，根因未完全定位。**R2／C／C2 IN_PROGRESS、D TODO**；英文checkpoint已寫，New Chat續同R2未覆蓋task耗時。

2026-10-04最新[HUD優化](docs/verification/res1-c2-hud-optimization.md)：導覽沿用當輪View、資源卡合併刷新與狀態變更才換材質已交付。51/51、資源顯示752、world26通過；修正版三組profile HUD5.58–5.82ms，非profile pooled59.508FPS／p95 16.8ms／max183.4ms，嚴格60仍未過。前輪診斷為歷史對照，非相同快照配對。R2／C／C2 IN_PROGRESS、D TODO；下一同R2剩餘View／保存編碼與長幀，用New Chat接續。

2026-10-04 R2最新[耗時定位](docs/verification/res1-c2-perf-r2-profile.md)：三組1280×720／DPR約1，HUD平均12.7–12.8ms（導覽5.0–5.1ms、建築／資源清單3.7–3.9ms），保存18.1–22.7ms、編碼佔大部。本輪交付預設關閉的profile工具，未做效能改善；未重現200ms、嚴格60未放行。基礎版51/51、最終世界26通過。下一同R2改善HUD重複View／資源卡刷新，**不跳D**。

2026-10-04 R2最新[桌面FPS複測](docs/verification/res1-c2-perf-r2-fps.md)：1280×650／DPR1.25三組遊戲pooled **59.019FPS**、p95均16.8ms／max200ms；三組無遊戲對照59.997。量測工具13契約通過，嚴格60仍未過；下一同R2定位秒級更新／保存成本，裝置／人工待驗，**不跳D**。本輪未改Godot，下面51/51與節流啟動屬前輪結果。

2026-10-04 PERF-R2 續輪（最新）：20Mbps／100ms長離線 ready **9.801／9.777秒**，兩個新origin通過10秒；原生48h CPU **2.662→0.886秒**、完整終態hash不變。最終51/51、145精確檢查、async27、world26、Web C2 retry49通過。桌面 **59.930FPS／p95 16.8ms**，嚴格60仍未過；人工／手機／高DPR等仍待驗，R2／C／C2維持IN_PROGRESS，不跳D。 [本輪證據](docs/verification/res1-c2-perf-r2.md#2026-10-04-續輪交付節流長離線缺口)。下方同日較早結果保留歷史。

Godot 修仙放置遊戲原型：由洞府建設、修行與突破開始，逐步探索輪迴、宗門與不同世界。主場景、HUD 和互動由 Godot/GDScript 負責；Web 匯出供瀏覽器執行。

## 目前狀態｜2026-10-04

**同日較早 RES1-C2-PERF-R2：離線改善交付，整體 IN_PROGRESS**。同條件本機48h恢復 **18.03→7.75秒**，逐秒終態／事件保持；最終 **51/51 Runner、121精確檢查、Web retry49** 通過。20Mbps／100ms新檔8.45秒，但長離線13.55秒仍超10秒；桌面59.80FPS／p95 16.8ms，嚴格60仍未過。詳 [R2驗收](docs/verification/res1-c2-perf-r2.md)。下一仍PERF-R2缺口／裝置與人工，不跳D；以下保留前輪歷史。

**同日較早 RES1-C2-PERF：桌面效能改善交付，整體 IN_PROGRESS**。正常Web核心Brotli **14.44MB**（含四首原音樂19.79MB）、20Mbps／100ms新檔ready **8.49秒**；600秒規則CPU約減少49.8%，終態hash不變。最終桌面p95 **16.8ms**，平均59.45–59.85FPS仍未嚴格達60；48h恢復本機18.19秒仍待改善。**51/51 Runner**、107精確tick/font、世界26、真實Web retry49、兩橫式操作及50次Web切島通過。[驗收與隔離試玩](docs/verification/res1-c2-perf.md)。人工美術／高DPR／手機／自然凍結／跨瀏覽器／長期GPU記憶體仍待驗，下一C2-PERF-R2，不跳D。以下保留較早分輪紀錄。

**本輪 RES1-C3 最新**：四張青木／玄礦正式PNG分層美術已接正常版「經營 → 空島」，築基後玩家保留原檔並啟用。三島是首段切片，[30+容量與考據規格](docs/15-island-expansion-and-art-direction.md)採多产地共用有限材料鏈，後續島群尚未實作。最終50/50、正常world22及兩版型Web開拓／重開／精煉通過；人工美術／節奏與C2效能／裝置仍待驗。[本輪交付與試玩](docs/verification/res1-c3-art-integration.md)。下方預覽限定／正式未附掛為前輪歷史，由當次使用者要求覆蓋。

**最新：RES1-C2-R1 桌面保存追加矩陣完成；整體仍 IN_PROGRESS**。async故障／真實quota／兩次重載／雙分頁／拒讀／損壞146 checks、全量50/50及世界15 checks通過。獨立桌面實測48.60FPS／p95 33.4ms、20Mbps／100ms含48h恢復ready67.84秒、gzip下載估算44.72MB，效能未達預算。使用者美術／節奏保留待驗，實機／高DPR等仍待補；正式manifest未啟用。見 [收尾驗收與預覽](docs/verification/res1-c2-closure.md)。下一C2-PERF，不跳D；C1／原C2證據保留。

**最新產品方向：RES1 多島資源主線**。依使用者要求，Era 逐步解鎖專業空島，基礎資源經加工／融合形成 T2、T3 材料，透過實際供給與運輸支撐建設與修行。已完成[設計修訂](docs/14-multi-island-resource-progression.md)與[DAO1 資源稽核](docs/verification/resource-progression-audit.md)，尚未實作新玩法。DAO1 有 61 資源／30 配方；本作 manifest 目前僅 7 資源／10 建築／Era 1–2，另有少量子系統資源，不能宣稱已完整承接 DAO1。RES1-A 首批契約／隔離 Craft 核心已交付（15 資源／8 配方、145 checks、DAO1 8/8、42 Runner PASS），見[驗收](docs/verification/res1-a.md)。RES1-B 原型核心與桌面 Web 保存故障範圍 DONE（251 checks、三程序保存／載入／離線、真實quota／重載／雙分頁與受控Web幀恢復），見[核心](docs/verification/res1-b.md)／[Web驗收](docs/verification/res1-b-web-r1.md)。最新固定入口47/47 PASS、exit0；正式manifest仍未啟用，下一RES1-C三島操作。實機／自然背景凍結／高DPR／長離線CPU預算仍待驗。

已實作多世輪迴、丹藥、BUFF、宗門、靈界、天時、機緣奇遇、四種靈獸與 18 項成就；九界法則、世界地址、確定性世界描述生成與界域戰略決策已有規則／資料／保存測試。宗門、跨界與 BUFF 的 Session 白名單已補上。2026-10-03 UI8 R1 全量回歸 **39/39 Runner 通過、exit 0**；後續建造訊息修復另重跑導覽／響應式兩項，使用者測試 OK；引擎 Godot `4.7.2.stable.official.ed1daf0bf`。

主導覽已重整為「洞府／經營／修行／遊歷」：洞天據點與建築共用經營分頁，煉丹／靈獸／輪迴歸修行，九界／宗門／機緣／天道決策歸遊歷；移除重複 More 入口。新增功能須遵守[入口整合規範](docs/12-feature-navigation-and-integration-spec.md)。分類／視覺回饋與實機驗收待完成，見 [NAV1](docs/verification/feature-navigation.md)。

10/3 FX3 已加入 Godot 原生粒子、飛劍／法陣／雷電 Shader、世界 Glow 與題字局部泛光；可從設定「引擎特效樣板（試播）」查看，不提升修為或發放收益。庫評估、測試及尚未完成的裝置／美術驗收見 [FX3](docs/verification/native-vfx.md)。

9/29–10/2 另實作系統設定與境界 BGM 排程、橫式響應式／直式旋轉提示、介面材質迭代、思源黑體＋粗明體、引導／訊息改善，以及升境光環雷電與過場文字樣板。最新 UI7 採紙色墨字、霧面青玉與朱砂重點；既有紀錄已驗桌面瀏覽器 1280×720、844×390 滑鼠與 360×640 旋轉提示，使用者美術放行、高 DPR 與實體手機仍待驗。九界資料交付不代表九界完整可玩、美術與長期負載都已驗收。

M4-A-R1 正式 Session／桌面 Web 整合驗收已完成：251 checks、40/40 Runner 與 1280×720／844×390 實際操作通過，修正命令收據保存、宗門獎勵入庫及按鈕重建。見 [驗收](docs/verification/m4-a-r1.md)。此為原有系統整合範圍，多島加工／運輸與完整 DAO1 資源內容另依 RES1 交付；裝置、M1-C/D Web 持久化／離線故障證據仍待補。詳細變更與未完成 DoD 見[文件複核](docs/verification/doc-a-r1.md)及[目前狀態](docs/development-status.md)。原始碼已同步至 [GitHub 專案](https://github.com/KainHuang777/Dao2)；引擎、模板、快取與 Web 匯出不納入版本控制，複製倉庫後須備妥同版環境。

築基小院外觀與三種洞府小景已接入同一 Godot 世界：靈木／靈草／靈石隨機出現、點擊批次採收、最多兩件並保存狀態；短橫式修正初始屋頂取景。38 Runner、八張 native 與 Web 鼠標／重載已驗，使用者美術及實機待補，見 [ISLAND1](docs/verification/island-scenery.md)。

## 開始接手

依序閱讀：

1. [AGENTS.md](AGENTS.md)：工作規則、安全執行與驗收要求。
2. [ROADMAP.md](ROADMAP.md)：任務依賴、範圍及完成定義。
3. [開發狀態](docs/development-status.md)：目前任務、驗證結果與後續順序。
4. [AI 交接指南](docs/ai-handoff.md)：環境與可重跑命令。

若修改洞府呈現，先看[按需檔案索引](docs/abode-presentation-map.md)，再讀實際涉及的控制器或元件；版面、Web、輸入修改必讀[響應式 UI 規格](docs/07-responsive-ui-web-spec.md)。不要為了接手重讀整份歷史紀錄。

## 開發與驗證

- Godot `4.7.2.stable.official.ed1daf0bf`、GDScript、Compatibility、單執行緒 Web。
- 使用 PowerShell 從專案根目錄執行現有 53 Runner（清單以腳本為準）：

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
  ```

- Web Release、單獨 Runner 及瀏覽器操作命令見[交接指南](docs/ai-handoff.md)。Headless Runner 不代表瀏覽器輸入、窄版可讀性、實機觸控或 IndexedDB 已驗收。
- 每項工作記錄 ID、修改檔案、命令與結果、未通過項及下一步於 `docs/development-status.md`，只有符合 Roadmap 的 DoD 才標 DONE。

## 文件地圖

| 需要了解 | 文件 |
| --- | --- |
| 產品玩法與範圍 | [產品與世界規劃](docs/01-product-and-world-plan.md) |
| 核心模組、時間與保存架構 | [技術架構](docs/02-technical-architecture.md) |
| 舊版規則證據 | [來源基線](docs/00-source-baseline.md)、[差異紀錄](docs/rule-differences.md) |
| Godot/Web 畫布、裝置與輸入 | [響應式 UI/Web 規格](docs/07-responsive-ui-web-spec.md) |
| 功能入口、分頁及資源整合 | [入口整合規範](docs/12-feature-navigation-and-integration-spec.md) |
| 建築呈現與 Era 擴充 | [建築呈現規格](docs/08-building-presentation-and-era-expansion.md) |
| 功能驗收與已知限制 | `docs/verification/`；入口見[開發狀態](docs/development-status.md) |
| 舊進度原文 | `docs/archive/`；保留日期供查考，不作目前狀態依據 |

技術基線與尚未完成的設計見 [ROADMAP](ROADMAP.md) 及專題文件；規則實際狀態以程式和測試為準。舊參考專案 `E:\Python\test1`、`E:\WORK\GodTower` 僅唯讀。

