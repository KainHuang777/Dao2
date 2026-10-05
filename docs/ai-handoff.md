# 2026-10-05 R2最新接手提示

2026-10-05追加 **D2-R1 Web 保存子階段 PASS；完整D2-R1／D2／D與C／C2／R2仍IN_PROGRESS**。先讀[Web驗收](verification/res1-d2-web-r1.md)與updata頂部。最終53/53／exit0、world38／管理89；九案例16報告400 checks，空白流程是自動正常命令／模擬秒（含215共用診斷），不是完整滑鼠通關。D2真實保存矩陣176項通過；正常開局滑鼠及丹霞拒寫／重試追加，保存恢復提示修復。4258新檔、4259金丹試玩存檔保留，頁面停launcher／override reset；4259按開啟隔離遊戲，勿再Seed。新正常包build/res1d2-web-live，測試包build/res1d2-web，原web／res1d2／res1d2r1不變。下一New Chat續自然時間完整滑鼠流程、人工／裝置／C-R2；R2交AGY，不重做已過保存矩陣或跳Era4。下方日期化歷史保留。

2026-10-05最新 **D2-R1世界／美術子階段交付，完整D2-R1／D2／D IN_PROGRESS**：丹霞兩張獨立PNG與雙向世界／管理入口、貨運視覺、控制列換行及遠景題字避讓已接。53/53／exit0；最後world38＋管理87、原三島26／響應式回歸、獨立Web與1280×720.4／844×390滑鼠重載證據見[驗收](verification/res1-d2-r1.md)。下一New Chat續正常Web空白完整首段與D2瀏覽器保存故障矩陣；人工／裝置／C-R2仍待驗，R2交AGY。先讀updata頂部，4257/launcher沿用進度，勿再種檔；build/res1d2r1獨立，原web／res1d2包不變。

2026-10-05最新 **RES1-D2 IN_PROGRESS（容量／技能方案與正常規則／管理接線已交付）**：使用者核定Era＋設施門檻及新增築基靈池；正常空白T1→金丹Lv10、丹霞丹液回運／T3／扣料與保存故障215 checks、52/52 Runner／exit0，最後呈現87 checks回歸／獨立Web匯出及1280×720.4／844×390滑鼠與重載通過。[D2驗收](verification/res1-d2.md)／[ADR-011](decisions/ADR-011-era3-capacity-and-skill-gates.md)。丹霞專用世界美術、完整Web新檔首段、人工玩法／裝置與C/R2門檻仍待驗，**D2／完整D IN_PROGRESS**；R2仍交AGY。下一New Chat續D2-R1，本輪不開下一大型階段；以下按日期保留歷史。


2026-10-05最新：**D1 DONE（稽核＋隔離216 checks）**，讀[res1-d1](verification/res1-d1.md)及updata頂部；8來源hash一致，空白開局到Era3 Lv10。正常靈力容量1100不達突破2000；容量250／無一般技能／丹液陣芯晉階成本是明示fixture提案，正式檔未改。獨立命令`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\res1d1_audit.ps1`及Godot `--headless --path . --script res://tests/res1d1_contract_runner.gd`；完整D／正式保存／世界仍待整合。R2仍AGY負責，C／C2／R2 IN_PROGRESS；下一D2先定容量與技能方案、共享核心單方修改，New Chat接續。下方TODO分工為此前歷史。

**同日最新使用者分工覆蓋下方接手順序：R2交AGY，Codex下一RES1-D1隔離子階段（TODO），可並行。**先讀[AGY交接](handoffs/2026-10-05-r2-agy.md)、[AGY Prompt](handoffs/2026-10-05-agy-r2-prompt.md)、[D1範圍與Codex Prompt](handoffs/2026-10-05-codex-res1-d1.md)。R2／C／C2仍IN_PROGRESS、完整D TODO，不以並行消除效能／保存／裝置放行門檻。本輪只建文件，未開始D1或對外傳送prompt。共享檔與build先協調；AGY量FPS時Codex暂停高負載測試／匯出。

先讀[持續劣化定位](verification/res1-c2-sustained-degradation.md)與updata頂部。本輪正常頂層1280×720／DPR約1三組300秒（含50次有間隔管理開關）與重載60秒59.744／59.564／59.744／59.847均恢復PASS；CPU237／GPU150同期資料、6／16／13契約PASS。沒有Godot來源／匯出／51 Runner變更。共用GPU process高CPU時仍近60、heap大小與FPS非單一對應；不是根因修復。前輪DPR1.25與木屋3階、此輪DPR1／木屋2階不同，原失敗未消除。R2／C／C2 IN_PROGRESS、D TODO。4248服務沿用，分頁停launcher／override reset，已有進度按開啟遊戲，勿種檔。下一同進度DPR1.25重現／DPR對照，再按失速證據分層追蹤；New Chat開始下一大型階段。

# 給下一位 AI 的開發交接

2026-10-04最新 **R2正常恢復／長觀測驗收 NOT_PASSED**：正常60秒59.880、首組300秒59.823通過；有間隔50次管理操作的300秒54.740（末45秒低谷）、同頁延長300秒48.088、重載60秒35.105均未恢復。無遊戲對照59.997只作診斷，不替代遊戲通過；木屋2→3／扣料重載、三島滑鼠與完整模式正常。Python16／Node13契約通過，無新Godot來源／匯出／51 Runner。**R2／C／C2 IN_PROGRESS、D TODO**；下一定位持續劣化，裝置／人工另待驗。[本輪驗收](verification/res1-c2-recovery-browser.md)。較早政策修訂與通過結果保留歷史，New Chat續同R2。
4248服務保留（session6020），正常隔離origin；分頁停launcher釋放writer鎖，已有進度按開啟隔離遊戲，勿重種。先讀updata頂部／本輪驗收，失敗raw保留，下一針對持續低FPS取證，不為單一59.x或可恢復尖峰優化。


2026-10-04最新使用者要求：[ADR-010放置FPS恢復標準](decisions/ADR-010-idle-frame-recovery-budget.md)，優先於下方全部歷史「嚴格60未過」。常態目標60、偶發30後回升可接受；55／5秒窗／80%及末10秒恢復是工程定義，低谷10秒警示不直接阻擋。工具desktopRecoveryGate取代strictDesktopGate，正常`/metrics.html?sampleSeconds=60`／300做恢復／長期觀測，profile仍排除。16 summary＋13 observer契約通過，舊三組15秒短窗口符合但INSUFFICIENT_EVIDENCE，沒有新瀏覽器／全量Godot／匯出。R2仍IN_PROGRESS，下一按恢復與持續劣化驗收，不再為平均59.x或可恢復33ms無限優化；手機等獨立待驗、不自動進D。launcher的sampleSeconds轉交要重啟服務，直接metrics頁動態讀新JS。[本輪驗收](verification/res1-c2-idle-fps-policy.md)，New Chat續同R2。

2026-10-04最新R2：[長幀入口追蹤](verification/res1-c2-main-loop-tracing.md)與updata頂部。preflight＋LoAF診斷交付；83.3ms rAF對應MainLoop_runner84.1ms，同窗process0.4／preflight0.1／HUD保存0，沒有WASM內call stack，不指定GC或GPU根因。51/51／world26、正常與profile export／compression、JS／Python契約通過；正常頂層1280×720三組pooled57.887FPS／p95 16.9ms，嚴格60未過，非配對改善。4247服務（session96276）保留：bundled Python `tools/island_preview_server.py --port 4247 --profile-build --gzip --review-fixture --metrics-log res1-c2-task-profile-metrics.jsonl`，正常 `/launcher?metrics=1`／頂層診斷 `/profile.html?profileSeconds=60`；兩build PCK相同，normal無CPU橋接。已有隔離資料按開啟遊戲，拒覆寫；override已reset，分頁停launcher。下一仍R2引擎迴圈內／其他節點／繪圖與33ms掉幀追蹤、嚴格FPS／裝置與人工，**R2/C/C2 IN_PROGRESS、D TODO**，New Chat；以下是歷史。

2026-10-04最新R2子階段：讀[View／encode與長幀](verification/res1-c2-view-encode-longframes.md)與updata頂部。固定快照encode17.368→14.9985ms；定時View少重建、明確刷新保留。51/51／resource754／world26／Web retry49通過；非profile59.619FPS／p95 16.8ms／max183.3，嚴格60未過。另60秒profile捕捉166.8ms rAF與180ms LongTask，同窗已量process0.3ms，沒有call stack、不能歸因GC／GPU。4244正常隔離試玩保留，已有進度按開啟隔離遊戲；profile選項`/launcher?profile=1&profileSeconds=60`只作診斷，保持raw報告收起。**R2/C/C2 IN_PROGRESS、D TODO**；New Chat續同R2未覆蓋task／引擎／節點耗時與裝置／人工缺口，以下同日紀錄保留歷史。

2026-10-04最新HUD子階段：讀[驗收](verification/res1-c2-hud-optimization.md)及updata頂部。feature_navigation.layout(vp,view)沿用當輪View，無參數resize走既有身分/revision保護；catalog.refresh新增預設false的defer_resource_refresh，HUD等shared合併後一次更新，資源/材質以副本與Era/模式/名稱/紙底失效。最終51/51、資源顯示752、world26通過；正常Web已重新匯出並準備音樂／壓縮，PCK35539625…，br14,451,078 bytes。profile三組HUD5.58–5.82ms；非profile三組pooled59.508FPS／p95 16.8ms，max183.4ms，嚴格60未過。遊戲sample1280×721／DPR約1（iframe DOM1280×720），時間狀態不同，不能泛稱精確配對。4243正常隔離試玩保留，已有資料按開啟遊戲，勿種檔覆寫；4242已停。下一同R2剩餘View／保存編碼與長幀，保留故障契約與門檻，R2/C/C2 IN_PROGRESS、D TODO，用New Chat。以下同日定位紀錄為歷史。

2026-10-04最新R2耗時定位：讀[profile證據](verification/res1-c2-perf-r2-profile.md)及updata頂部。三組HUD12.7–12.8ms（navigation5.0–5.1／catalog3.7–3.9），保存18.1–22.7ms，encode13.8–18.5、commit4.1–4.2；tick1.2–1.3。新增RuntimeProfile預設關閉，僅`/launcher?profile=1`啟用；`--profile-build`服務獨立build/web-profile。基礎版51/51、最後world26，未做效能改善／完整Web故障重跑／200ms重現，profile不可判FPS通過。下一同R2改善FeatureNavigation重複get_view及BuildingCatalog重複資源／樣式更新，配對非profile驗收；R2/C/C2 IN_PROGRESS，D TODO。正常build/web未重匯出。請New Chat接後續。

2026-10-04最新R2 FPS子階段：先讀[桌面複測](verification/res1-c2-perf-r2-fps.md)及updata頂部。v3量測／重算工具13契約PASS；同iframe1280×650／DPR1.25三遊戲pooled59.019FPS、p95均16.8／max200ms，三無遊戲對照59.997。嚴格60未過；下一同R2實測每秒Session／View、0.25秒HUD、15秒同步保存各段成本後改善，未定位不能改保存／收益，不跳D。新4238正常版隔離試玩保留，4236本輪未驗；本輪未改Godot來源／export／跑51 Runner，下面為前輪證據。以New Chat接profile階段。

2026-10-04 PERF-R2 續輪（最新）：20Mbps／100ms長離線 ready **9.801／9.777秒**，兩個新origin通過10秒；原生48h CPU **2.662→0.886秒**、完整終態hash不變。最終51/51、145精確檢查、async27、world26、Web C2 retry49通過。桌面 **59.930FPS／p95 16.8ms**，嚴格60仍未過；人工／手機／高DPR等仍待驗，R2／C／C2維持IN_PROGRESS，不跳D。 使用最新 `FrameBudget` 14ms；保留正常版隔離試玩 [4236](http://127.0.0.1:4236/launcher?metrics=1)，已有隔離進度拒覆寫。先讀 [R2續輪](verification/res1-c2-perf-r2.md#2026-10-04-續輪交付節流長離線缺口)與updata頂部；以下更新行為較早歷史。

更新：2026-10-04（PERF-R2續輪：節流長離線9.801／9.777秒有界通過；最終51/51＋145精確；嚴格60FPS／裝置與人工仍待驗）。較早結果保留歷史。

## 閱讀與恢復工作

1. 根目錄 `AGENTS.md`：開發約束。
2. `ROADMAP.md`：產品目的、任務 ID、相依與完成定義。
3. `docs/development-status.md`：實際進度與證據，找到當前未完成工作。
4. 按任務讀 docs/02 技術架構、docs/00 舊規則來源；美術任務讀 docs/04、06。
5. 涉及世界場景、HUD、輸入、畫面尺寸、Web shell 或 Web 匯出時，閱讀 `docs/07-responsive-ui-web-spec.md`；它規定 `1280×720` 構圖基準、Godot 響應式版型與瀏覽器證據，不可用固定畫布取代適配。
6. 涉及新建築、修行境界（Era）擴充、島面與可布置空間時，閱讀 `docs/08-building-presentation-and-era-expansion.md`；多數建築進營造清單，只有有圖形化地基與獨立美術的少數地標可進世界場景。
7. 涉及功能入口、群組分頁、資源或升級清單整合，必讀 `docs/12-feature-navigation-and-integration-spec.md`；新系統不得塞進 More 或新增重複入口。

如果工具不自動讀 AGENTS.md，請在首個提示明確要求閱讀。歷史文件 docs/03 保留初期推理與案例，開發順序以根目錄 Roadmap 為準。不要因舊文有「下一步建立環境」而重裝。

依修改類型查 [呈現層索引](abode-presentation-map.md)。歷史長記錄已歸檔，不作每次必讀；目前缺口與驗證以 [開發狀態](development-status.md) 為準。

## 最新接手狀態

- **2026-10-04 PERF-R2續輪最新**：長離線節流兩新origin9.801／9.777秒，最終51/51＋145精確、world26、Web C2 retry49。FrameBudget14ms；桌面59.930FPS／p95 16.8ms、嚴格60仍未過。固定點快取不跨命令，祖島Amount／乘區變化立即失效；全部計數仍逐秒。4236正常版隔離試玩保留。先讀R2末節與updata頂部；下一同R2嚴格FPS／人工與装置，D TODO。下列10ms／121項紀錄為同日較早階段。

- **2026-10-04 PERF-R2 最新**：讀 [R2驗收](verification/res1-c2-perf-r2.md)／updata頂部。最終51/51、121精確tick/font（含零tick／已壽盡不得初始化靈獸）、Web retry49通過。本機48h ready18.03→7.75秒，結算rAF p95 16.8／max17ms；20Mbps／100ms新檔8.45秒、長離線13.55秒仍超10秒；桌面59.80FPS／p95 16.8ms，嚴格60仍未過。準備只限無命令結算；BUFF到期、時辰切換與當秒庫存／預留仍保持原順序，FrameBudget10ms只決定讓出。三preset最終匯出並準備companions，正常PCK hash `dac46aa8a5e2f2240e6faaf065e002f794d70c30bb7d710950caec7e91018789`、核心br14,445,165 bytes。保留正常版隔離試玩4230服務：`python tools/island_preview_server.py --port 4230 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-final-active-metrics.jsonl`；已有進度拒覆寫。下一仍PERF-R2節流長離線／嚴格FPS、指定裝置與人工，不跳D，不重做已過A/B／保存矩陣。用New Chat接大型後續工作。

- **2026-10-04 RES1-C2-PERF最新**：讀[效能驗收](verification/res1-c2-perf.md)與updata。核心br14.44MB／含四原MP3共19.79MB，新檔20Mbps／100ms8.49秒，p95 16.8ms；平均59.45–59.85未嚴格60、48h恢復本機18.19秒仍待改善。51/51、107精確tick/font、world26、真實Web retry49／音樂503後選單重試／兩橫式／50次Web切島通過。三preset匯出後**必須準備音樂companions**：`node tools/prepare_web_compression.mjs build/web`（其餘preset換目錄），再`python tools/web_static_server.py --port 4175 --directory build/web`；一般`start_web_server.ps1`會自動準備，無Node仍copy原MP3與gzip。只Godot export不會建立audio/bgm companions。Runtime字型用bundled Python＋build/tool-deps/fonttools4.61.1執行`tools/subset_game_fonts.py --check`，新增文字缺字時再生成，不改原TTF。預覽4221服務保留：`python tools/island_preview_server.py --port 4221 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-responsive-metrics.jsonl`；已有資料拒覆寫，844×390測試按鈕是可驗證iframe，不是實體手機。原4175／4207未中斷。下一PERF-R2／裝置與人工放行，New Chat，不跳D；舊紀錄保留歷史，勿重做A/B或已通過矩陣。

- **2026-10-04 RES1-C3 本輪最新**：正常版已附掛processing／空島入口，築基後玩家保留原檔啟用；前輪「正式未附掛／只有preview」由當次要求覆蓋。四張PNG＋兩參考＋提示詞／manifest，最終50/50、正常world22與兩版型Web開拓／重開／精煉通過；world退出清理警告有記錄。读[C3](verification/res1-c3-art-integration.md)、[30+容量與考據](15-island-expansion-and-art-direction.md)與updata。實際仍首批三島，後續未實作。正常4175已更新；`python tools/island_preview_server.py --port 4207 --normal-build --review-fixture`保留試玩，獨立origin正常namespace，已有檔拒覆寫。C/C3人工美術／節奏與C2效能／裝置待驗；下一C2-PERF＋人工，New Chat接大型工作，不重做已通過矩陣／A/B，不跳D。下方C2-R1等按歷史保留。

- **2026-10-04 最新RES1-C2-R1**：讀 [收尾驗收](verification/res1-c2-closure.md)／updata。桌面async追加矩陣146 checks、最後retry49回歸、全量50/50及world15 checks PASS；原生50switch memory穩定僅有界證據。20Mbps／100ms未壓縮含48h恢復ready67.84s、獨立桌面48.60FPS／p95 33.4ms、gzip估算44.72MB，未達預算；使用者美術／節奏明確待驗。正式manifest仍未附掛，下一 **C2-PERF**，不重做已通過保存矩陣／A/B、不跳D。`WebPersistenceTest` export → `python tools/web_persistence_server.py --port 4202` → `?case=c2retry/c2quota/c2indexreload/c2quotareload/c2lock/c2denied/c2corrupt`；reload兩案要真的重整兩次，lock要兩個分頁且關閉owner後reload。review工具只重封UTC不改command-earned state：`--script res://tools/res1c2_review_fixture.gd`，server `--port 4205 --review-fixture`，已有資料拒覆寫；不要用48hfixture當可長期試玩檔。metrics來源工具 `--throttle-mbps 20 --latency-ms 100`／`/launcher?metrics=1`，禁止手改build。大型下一步用New Chat。

- **2026-10-04 RES1-C2 IN_PROGRESS，程式／桌面候選已交付**：先讀 [C2驗收](verification/res1-c2.md)／development-status／updata頂部。27 checks、checksum修正後固定50/50及世界14 checks、Web雙鏈／T2升級與重載、48h分批拒寫／恢復／重試／再重載已驗。新增SVG候選未美術放行，正式catalog仍未附掛。FrameBudget在platform，coordinator不直接讀Time；舊有效checksum驗證保持，Encode修正實際JSON表示往返。`run_all_runners.ps1`含新offline runner並產生48hfixture；另跑world runner。preview server支援`--port 4198`、`--port 4201 --offline-fixture`；`/launcher?fault=write`使用既有namespace受限故障條，`/fault.html`是工具頁，不改build。已有隔離進度拒覆寫。下一C2美術／裝置與新async完整故障追加矩陣／效能收尾，不跳D；用New Chat。

- **2026-10-03 RES1-C IN_PROGRESS，C1階段已交付，下一 C2**：先讀 [C1驗收](verification/res1-c1.md)／development-status及updata頂部。三島設施／T2消耗、遷移備份／重試與Godot操作頁已有87 checks、最終49/49 Runner、IAB1280×720／844×390滑鼠證據。正式manifest沒有附掛；只有IslandProgressionTest feature使用`dao2_islands_preview`，native override僅測試用。以C Runner生成earned-era2 fixture→export IslandProgressionTest→`python tools/island_preview_server.py`→4197/launcher；已有隔離進度按開啟遊戲，拒絕覆寫。下一C2補專用三島世界／Banner／世界命中與長離線分批讓出主執行緒、完整Web雙鏈／T2升級／重載離線矩陣，通過才做正式內容啟用。不要重做A/B或誤認C已DONE／跳D。依Context Guard用New Chat接續。

- **2026-10-03 RES1-B-WEB-R1 DONE，下一 RES1-C**：251 checks／native三程序與桌面Web保存故障矩陣已交付、最終固定入口47/47 PASS、exit0。讀 [驗收](verification/res1-b-web-r1.md)／development-status及updata頂部。localStorage＋lifetime Web Lock，拒絕讀寫／quota／損壞／索引中斷／重載與重試、受控Web幀恢復已驗；正式manifest保持opt-in。自然分頁／OS背景凍結、裝置與長離線CPU另待驗。本節後續A／B待做順序是本日較早歷史，不重做已交付核心。下個大型任務用New Chat。

- **2026-10-03 RES1-A 已完成首批契約／隔離核心，下一 RES1-B**：讀 [驗收](verification/res1-a.md) 與 updata 頂部。15 資源／8 配方、145 checks、新舊差異與唯讀 DAO1 8/8 參照、全量 42 Runner PASS。正式 ContentLoader 不附掛 processing_catalog，Craft 為 opt-in；正式 manifest／schema／rules 未變，新經濟不可先接玩家保存。B 將 A 的即時命令契約接批次時間、地方庫存、固定航線、容量保留、版本遷移與離線／輪迴／故障重試，補相交 M1-C/D 後開啟；百年草取得、Era3 技能／材料消耗與 UI 在 C/D。以下 A TODO 為較早歷史方向。

- **2026-10-03 RES1 最新指示優先於本節後續歷史次序**：使用者重申 Era 解鎖資源島、多階加工／融合與實際供給運輸。RES1-DESIGN 文件與靜態來源稽核 DONE，runtime 尚未改；先讀 [docs/14](14-multi-island-resource-progression.md)、[ADR-009](decisions/ADR-009-multi-island-resource-economy.md)、[稽核](verification/resource-progression-audit.md)。DAO1 61 資源／30 配方，DAO2 manifest 7／10 建築／Era 1–2，完整承接缺口從 Era 2–3 起。**下一 RES1-A（資源／配方／需求契約與 Craft 核心），再 B 加工／庫存／物流／保存、C 三島、D Era 3／三級材料**；M1-C/D 相交持久化／離線驗收仍是正式放行條件。已建立英文 checkpoint，使用 New Chat 開始實作，不把設計表當已上線玩法。

- 2026-10-03 M4-A-R1 DONE：251 checks／40 Runner、兩版型 IAB 真實滑鼠及重整恢復通過；rules_version=core-flow-5-session-receipts，schema 2 選填最近 256 筆成功命令收據。最後舊任務 alias 修正另重跑四項相關 Runner，全部 exit 0。Web adapter 實際是 localStorage；下一步 M1-C/D 權威儲存與離線故障矩陣，實機／高 DPR 獨立待驗。看 verification/m4-a-r1.md 及 updata.txt 頂部；使用 New Chat，不重做白名單。本節以下為本日較早接手紀錄，已由此項取代後續順序。

- 2026-10-03 最新：成就已交付，固定入口 39 Runner，UI8 R1 全量 39/39 PASS；建造訊息修復另有兩項 Runner／Web 證據且使用者測試 OK。下一步 M4-A-R1 補正式 Session 成功／拒絕／冪等／保存與 Web 矩陣，不能重做已存在白名單。再補 M1-C/D 瀏覽器持久化與離線證據；實機／高 DPR 仍待驗。下列按日期的 38 Runner 為歷史結果。

- NAV1 四主入口與九分頁已實作；靈獸核心及正式操作頁已接，下一步收分類／視覺回饋與實機驗收，見 verification/feature-navigation.md。

- Session 已放行宗門／跨界／BUFF，不能照 9/28 提示重做白名單；全部新命令端到端／Web 證據仍按 R1 補齊。
- M4-B、M5-A／B 已有核心／資料實作；完整可玩／美術／試玩／長期負載尚未全驗。最新 UI7 已實作，優先收 UI／字型／演出回饋與裝置驗收。
- 倉庫 origin 為 https://github.com/KainHuang777/Dao2.git，main 追蹤 origin/main；引擎／模板、.godot、build 被忽略。乾淨 clone 不含本機引擎，需同版 4.7.2 執行檔及模板，不自動更新環境。
- 執行政策 Bypass 僅作用於該測試子程序。若沙箱阻擋隔離 user:// fixture，記錄失敗並使用正常授權重跑；不要改玩家存檔。

## 實際路徑與現有檔案

| 路徑 | 已有用途 |
| --- | --- |
| `project.godot`、`export_presets.cfg` | 已鎖定環境；主場景 living_abode；Web 單執行緒 |
| `scenes/living_abode.tscn` | Node2D 啟動場景，運行時建構地形、建築、鏡頭和 HUD |
| `src/abode/living_abode.gd` | 世界與正式 Session／保存協調、公共相容入口 |
| `src/presentation/abode_hud_controller.gd` | HUD 組裝／版型／數值與引導更新 |
| `src/presentation/abode_modal_manager.gd` | 次級彈窗掛載／位置／事件分發 |
| `src/abode/abode_state.gd` | 純展示經濟，尚用 float、無持久化、無正式離線 |
| `src/abode/abode_camera.gd` | 平移、滑鼠／觸控縮放、HUD 排除、遠近景；待完整手勢驗收 |
| `src/abode/abode_building.gd` | 獨立 sprite、命中區、標籤、選取及升級特效 |
| `src/abode/abode_flows.gd` | 飛劍與靈氣的程式動畫；不發放資源 |
| `assets/abode/` | terrain、sky、hut、garden、altar、sword 分層圖片 |
| `assets/fonts/`、`src/presentation/ui_typography.gd` | 思源黑體 TW VF 400／600 資訊字與粗明體 800 題字；保留字型授權 |
| `docs/abode-art/` | 生成提示詞、原始與處理紀錄，非正式遊戲模組 |
| `scenes/web_probe.tscn`、`src/presentation/web_probe.gd` | 舊計數探針；`user://web_probe_state.json`；與洞府不同存檔契約 |
| `tools/test_runner.gd` | 基本 JSON／user 儲存與字型探針 |
| `tests/abode_state_runner.gd` | 展示產率、升級、藥圃停止測試 |
| `tests/living_abode_runner.gd` | 直接呼叫場景選取／升級／停產／鏡頭函式，非真實輸入 E2E |
| `docs/visual-prototype/` | 早期 HTML 視覺提案，不能作為正式遊戲核心 |
| `src/效果圖/` | 現有參考圖，勿任意刪除；export_presets.cfg 已排除 release 打包 |
| `build/`、`.godot/` | 匯出與快取，可重建；修改來源後重新生成 |

舊來源 `E:\Python\test1`、塔防參考 `E:\WORK\GodTower` 僅供讀取。其他機器沒有這些路徑時，可先做不依賴來源的驗收；公式 fixture 任務應報缺來源，不從記憶或圖片猜公式。

## 可重跑命令（目前已存在的入口）

以下在 Windows PowerShell 執行。每一步確認退出碼；2026-10-03 ISLAND1 重跑固定入口 38/38 PASS，清單以 tools/run_all_runners.ps1 為準。追加呈現層回歸不在固定入口；歷史結果見各驗收頁，本輪未重跑。非 Windows 接手者需提供同版本當地 Godot 執行檔與模板，保留來源專案設定。

```powershell
Set-Location 'E:\WORK\Dao2'
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
if ($LASTEXITCODE -ne 0) { throw 'Godot version check failed' }
& $daoEngine --headless --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
if ($LASTEXITCODE -ne 0) { throw 'A runner failed' }
& $daoEngine --headless --path . --script res://tests/abode_presentation_parity_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Presentation facade regression failed' }
New-Item -ItemType Directory -Path '.\build\web' -Force | Out-Null
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
```

另外開一個終端啟動本機 HTTP（若已有相同服務，先確認不用重開）：

```powershell
Set-Location 'E:\WORK\Dao2'
python -m http.server 4175 --bind 127.0.0.1 --directory '.\build\web'
```

開啟 `http://127.0.0.1:4175/index.html`；不要直接雙擊本機 HTML。此服務只提供 build/web，不公開整個專案。停止該終端中的服務用 Ctrl+C，不終止不相關程序。若換 port，origin 與瀏覽器存檔也不同；存檔回歸必須保持固定 origin。

現有 Godot 採 `_sc_` 自我包含模式，模板在引擎旁 `editor_data/export_templates/4.7.2.stable/`；引擎與模板被 .gitignore 排除。若工具沙箱阻止引擎寫入，使用該工具的正常授權流程，不繞過限制。

周天探針不再是主場景；M0-A 需提供獨立 export/config 的可重跑方式，不直接改 release main_scene 又忘記還原。`tools/` 被 release 排除，CLI runner 可從源專案執行；不要把 runner 的存在當作 release 可載入保證。

## 瀏覽器驗收的正確做法

- 先等實際場景可互動；loader 截圖與 console 的 ABODE_READY 都不足以證明畫面品質。
- 從當次截圖／viewport 確認座標，記錄 CSS 尺寸和 DPR；不要複用上一回的固定座標。Godot 畫布內部文字通常不在 DOM，不能把 AX 的 canvas fallback 文字視為畫面錯誤。
- 真實點建築／按鈕並核對文字與狀態；拖曳檢查位置、縮放檢查比例及命中；UI 上拖放後再點世界，確認不黏住拖曳。
- 測試暫停藥圃前後一段固定時間的靈草增量，恢復後繼續；鏡頭切換與低特效不能改產率。展示版允許重載重置，正式存檔接入後更新此預期。
- 周天持久化記錄初值、點後值、重載值；不能以檔案存在、函式返回或 headless JSON 往返代替瀏覽器持久化。
- 缺瀏覽器自動化能力就提供人工步驟並標待驗證，不擅自宣稱全通過。手機模擬 viewport 不等於實體手機 GPU、觸控或效能驗證。

## 任務與驗收紀錄模板

每項工作在既有 `docs/verification/<task-id>.md` 建立或追加紀錄：

```text
任務 ID／日期／狀態：
目標與非目標：
已滿足相依：
來源 hash 或規則版本：
修改檔案：
驗收環境（引擎、OS、瀏覽器、裝置、CSS尺寸/DPR）：
命令／退出碼／結果（實測或未執行）：
瀏覽器操作、預期、觀察、截圖路徑：
資料安全／存檔相容影響：
未通過項、阻塞原因、下一步：
```

調整已決定的架構或規則時，在 `docs/decisions/ADR-xxx.md` 記錄理由、替代方案、影響及驗證，並更新 Roadmap。ADR-001–007 已存在 docs/03，不重用編號。

## 上下文管理與主動剎車協定（Context Guard & Checkpoint）

1. **防禦 Context Drift**：長 Session 會累積過多終端輸出與代碼檢視，導致模型注意力分散、代碼品質下降與幻覺。
2. **主動剎車標準**：
   - 當前任務（Task/Bugfix）已完成且測試通過，準備進行下一個不相關的大任務時。
   - 單一對話對話輪數過多、或終端大量錯誤日誌累積時。
3. **固化與交接 SOP**：
   - **寫入 `updata.txt`**：按照專案規定，在最頂部追加最新英文更新日誌（含變更檔案、關鍵邏輯、測試驗證結果）。
   - **更新狀態**：將當前進度與下一步標記在 `docs/development-status.md`。
   - **提示重啟**：在回覆末端提示使用者點擊「New Chat」開啟新對話。
4. **冷啟動接手**：新開啟的對話**不依賴任何舊歷史記憶**，只需閱讀 `AGENTS.md`、`updata.txt`（頂部最新日誌）與 `docs/development-status.md`，即可 100% 精準恢復上下文並立刻推進下一任務。

## 可直接貼给下一個 AI 的提示

> 請接續 E:\WORK\Dao2。先閱讀 AGENTS.md、README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md 與 updata.txt 頂部 checkpoint；按呈現層索引定位來源，UI 必讀 docs/07。使用現有 Godot 4.7.2／GDScript／Compatibility／單執行緒 Web。34 Runner 於 2026-10-02 重跑通過，Session 白名單已補，M4-B 與 M5-A／B 核心資料已交付；不重做舊接線，也不把數值測試當作九界完整遊玩驗收。先接續最新 UI7、混搭字型、FX2／TEXT1 的回饋及裝置驗收，再選靈獸／成就或補 M5 完整 DoD；缺少證據的項目照狀態頁保留待驗。

## RES1-B 冷啟動入口（2026-10-03）

先讀 [B 驗收](verification/res1-b.md) 及 updata 頂部：核心 251 checks／native 三程序交付，整體 IN_PROGRESS；下一 RES1-B／M1-C/D Web 故障矩陣，尚未進 RES1-C。重跑 `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_res1b_verification.ps1`。測試資料只在 docs/verification/artifacts/res1-b-cross-process；全量最近一輪 44/45、exit 1（其他新增 DebugActions 面板失敗），不要忽略。schema3 decoder支援舊schema2，但正式processing catalog仍未啟用；瀏覽器matrix不能由native結果推定。
