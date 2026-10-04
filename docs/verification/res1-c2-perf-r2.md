# RES1-C2-PERF-R2｜離線恢復與量測複核

2026-10-04最新[桌面FPS重複量測](res1-c2-perf-r2-fps.md)：同iframe1280×650／DPR1.25三組遊戲pooled59.019FPS、p95均16.8ms／max200ms，三組無遊戲對照59.997FPS。v3整段條件／raw重算工具13契約PASS，嚴格60未過；只交付量測子階段，下一R2定位秒級更新／保存成本，不跳D。本輪未改Godot／重跑51 Runner，下面為前輪證據。

最新為末節「2026-10-04 續輪交付：節流長離線缺口」：節流長離線9.801／9.777秒有界通過，最終145精確檢查；嚴格60FPS與裝置／人工仍未完成。前面的10ms／121項／13.55秒是同日較早階段，保留原日期與證據。

2026-10-04。接續 PERF，不進 RES1-D。C/C2 維持 **IN_PROGRESS**；本輪未改 schema 3、rules `core-flow-9-island-progression`、收益上限、島群或素材。開始時保留既有大量 dirty／untracked C1/C2/C3/PERF 工作，沒有 commit、push 或部署。

## 實作與正確性

`TimeAdvancer.prepare_advance` 的快取只存在於一次無命令推進。宗門技巧與靈獸被動在此期間不變；BUFF 只在逐秒 tick 到期刪除時重算乘區，天時在 60 秒時辰邊界重算（360 秒天候邊界包含其中）。完整天時進度、BUFF 時間、靈獸冷卻仍逐秒更新。下一次命令／結算重新建立快取，不能跨命令沿用。

新增一秒 Amount delta／基礎容量快取，BUFF 或天時乘區變化立即重算；保持原有乘算次序與 multiply(1) 正規化。當秒庫存與在途／加工預留仍逐秒讀取。僅在非負產率且當前值等於有效容量時省略無效加法；負值、非加工資源超倉的原有截限仍走原演算法。生產、到貨、完工、開工、出發、事件／RNG 與壽盡順序保持。

`FrameBudget` 從 6 ms 改為 10 ms，讓 60 Hz 一幀仍有約 6.7 ms 留給進度 UI／render；單 tick 可能超時，因此實際結算幀間隔另測。牆鐘只決定讓出幀，不作經濟 elapsed。`living_abode` 增加兩個 console 生命週期標記供隔離工具觀測。

保留 `_produce_uncached` 的原 Amount 生產運算作比較路徑。perf Runner 擴充完整長離線至壽盡、Earth→Metal 容量縮減、宗門技巧／成熟玄龜／T4 被動、非整秒短期壽元 BUFF 到期；快取版、未準備逐秒版与分幀共享準備三者比對完整 snapshot、RNG、貨運、預留與事件順序。原 async Runner 另比對 48h 報告、拒寫／重試／游標原子提交與重載不重領。

## 量測方法

IAB Chromium 154、Windows、DPR 1.25，分開 origin 與既有玩家資料。每次載入由 launcher 按鈕匯入命令賺得 fixture，已有進度拒覆寫。基線與初版 R2 使用相同 fixture、1280×650 iframe CSS viewport、Brotli、無節流，測量期間沒有 Runner／export 並行；瀏覽器 profile／WASM code cache 未清除。

同輪基線 ready **18,033.9 ms**，R2 初測 **7,488.3 ms**，約降低 58.5%。[基線原始資料](artifacts/res1-c2-perf-r2-before-metrics.jsonl)、[初測資料](artifacts/res1-c2-perf-r2-after-metrics.jsonl)、[初測摘要畫面](artifacts/res1-c2-perf-r2-offline-r1.jpg)。這是本機無節流長離線案例，不能用來宣稱 20 Mbps／100 ms 長離線也通過。

`res1c2_metrics.js` measurementVersion 2 保留原始 rAF gaps，新增結算階段 duration／p95／max／visibility。FPS 分母改為已計數間隔的總時長；舊算法從按鈕點擊起算，但沒有計入點擊至第一 callback 的間隔，造成少算。保留 `rawWindowFps` 供核對，不把統計方法修正稱為遊戲 FPS 改善；未改 60 FPS 門檻。rAF 仍是瀏覽器排程代理，不能證明 GPU profiler 或實體手機效能。

## 有界結果（初版量測，最終保護修正另複核）

| 案例 | 結果 | 證據邊界 |
| --- | --- | --- |
| 20 Mbps／100 ms 新 origin 新檔、1280×720 | ready 8,453.8 ms | 新檔 ≤10 秒通過，未清 WASM code cache |
| 同網路48h雙鏈、1280×650 iframe | ready 13,550.2 ms；純結算 5,161.1 ms | **長離線網路總啟動未過10秒** |
| 上項結算302個 rAF 間隔 | p95／max 16.9 ms、visible | 有界進度 UI 排程，非 GPU profiler |
| 真實 reload → 按開啟隔離遊戲 | ready 8,572.3 ms，摘要只有新25秒、未套上限 | 不再重結算48h；不是以直接函式呼叫代替 reload |
| 1280×720 雙鏈15秒，v2統計 | 59.7301 FPS／p95 16.8 ms／max 33.4 ms；舊分母59.7234 | **嚴格60仍未過**，p95通過 |
| 600秒 native探針 | 238,468→144,776 µs（約39.3%）；hash `b0ccfe4b…36e63` 相同 | 同輪配對；與前輪539866比較不同量測環境 |
| native 48h同步結算 | 2,724,192 µs；停在12000秒壽盡、收益上限86400 | 純規則CPU，非Web ready／讓出成本 |

[節流新檔](artifacts/res1-c2-perf-r2-cold-metrics.jsonl)／[節流離線與重載](artifacts/res1-c2-perf-r2-throttled-offline-metrics.jsonl)／[桌面](artifacts/res1-c2-perf-r2-active-metrics.jsonl)／[CPU](artifacts/res1-c2-perf-r2-cpu-final.log)保留完整原始資料與 gaps。

最後複核發現 `BeastSystem.compute_multipliers` 會初始化空的 beasts，因此改為通過零 tick／壽盡保護後才首次準備靈獸乘區；補兩個 no-op 完整 snapshot 檢查，不改既有初始化時機。最終回歸、匯出與瀏覽器複核將記在下節。

人工美術／節奏、指定手機、DPR 2/3 最大 zoom、自然背景凍結、其他瀏覽器、長期 GPU 記憶體仍待驗。

## 最終來源與瀏覽器複核

最終正常 PCK SHA256 `dac46aa8a5e2f2240e6faaf065e002f794d70c30bb7d710950caec7e91018789`，引擎 WASM hash保持 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。必要 JS／WASM／PCK Brotli **14,445,165 bytes**，所有四首原MP3仍另5,347,590 bytes。[最終包清單](artifacts/res1-c2-perf-r2-budget-final.json)／[companion清單](artifacts/res1-c2-perf-r2-compression-guard-final.json)／[HTTP13案](artifacts/res1-c2-perf-r2-http-guard-final.json)。沒有手改匯出JS／WASM／PCK來修來源。

- 最終完整 **51/51 Runner exit0**，包含 **121精確tick/font checks**與原async27；[全量日誌](artifacts/res1-c2-perf-r2-all-runners-final.log)。較早本輪亦51/51；追加no-op保護修正後才重跑最終回歸。世界26項PASS／exit0，[日誌](artifacts/res1-c2-perf-r2-world.log)保留既有FontAdvanced／CanvasItem／8 ObjectDB／1 resource退出診斷。
- 4229最終正常版、本機無節流、1280×650：48h ready **7,746.7 ms**，結算5,241.8ms、308個rAF間隔、p95 **16.8 ms**／max **17.0 ms**、visible。本輪同條件基線18,033.9ms，約減少57.0%。[原始資料](artifacts/res1-c2-perf-r2-final-offline-metrics.jsonl)／[真實摘要](artifacts/res1-c2-perf-r2-final-offline-summary.jpg)。截图嘗試時結算已完成，沒有把摘要假稱為途中進度；分幀證據來自308個原始gaps及CLI callbacks。
- 4230最終正常版、1280×720／DPR1.25，15秒 **59.7972 FPS／p95 16.8 ms／max33.3 ms**；原分母59.7813。嚴格60FPS仍未過，不四捨五入成60；[原始gaps](artifacts/res1-c2-perf-r2-final-active-metrics.jsonl)／[桌面](artifacts/res1-c2-perf-r2-desktop-final.jpg)。關閉摘要、收起引導後取樣，沒有Runner／export／HTTP驗收並行。
- 桌面真實青木島→管理此島，讀到加工中、靈材與預留，[加工畫面](artifacts/res1-c2-perf-r2-wood-management.jpg)。另以實際 **844×390 CSS iframe** 重載，關閉摘要／引導、進玄礦、開管理、Godot內部捲動讀加工剩餘、固定關閉、點洞府恢復世界Banner後返回祖島，再填滿視窗。[DOM尺寸](artifacts/res1-c2-perf-r2-short-viewport.json)／[玄礦](artifacts/res1-c2-perf-r2-ore-short.jpg)／[加工与固定關閉](artifacts/res1-c2-perf-r2-ore-short-processing.jpg)／[祖島](artifacts/res1-c2-perf-r2-home-short.jpg)。沒有藉正式固定canvas／瀏覽器捲軸裁切。read-only browser scope無法讀iframe.contentWindow，僅採已觀測DOM的clientWidth／rect與畫面；不猜裝置或logical viewport。
- 4228最終WebPersistenceTest：五種async故障／失敗重試 **49 checks PASS**；[畫面](artifacts/res1-c2-perf-r2-retry49.jpg)，原report追加既有`web-persistence-browser.jsonl`。前輪完整146桌面故障矩陣未重做，不擴張為全新跨瀏覽器覆蓋。正常版離線與兩版型console warn/error空，[最後console](artifacts/res1-c2-perf-r2-final-console.json)。
- 最終native CPU工具163,387µs／600tick，600tick hash与本輪初始相同，48h2,837,562µs／終態hash `ddb697e8e22bd830af9bea1034cb24889c1a7afb2139543eb0372ad2d0a8025e`；[最終工具輸出](artifacts/res1-c2-perf-r2-cpu-guard-final.log)。此最後探針執行時隔離試玩頁仍開著，與初版144,776µs分別保留，不挑較快數字冒充最終結果。

本輪修改來源：`time_advancer.gd`、`platform/frame_budget.gd`、`living_abode.gd`的console階段標記、perf Runner、CPU profile與metrics工具，以及README／ROADMAP／docs02／07／ai-handoff／development-status／本驗收／updata。没有更動來源圖、字型、規則／保存版本或既有玩家檔。

## 命令與已知限制

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
& $daoEngine --headless --path . --script res://tests/res1c2_perf_runner.gd
& $daoEngine --headless --path . --script res://tests/res1c2_world_runner.gd
& $daoEngine --headless --path . --script res://tools/res1c2_perf_profile.gd
& $daoEngine --headless --path . --script res://tools/res1c2_review_fixture.gd
& $daoEngine --headless --path . --export-release Web build/web/index.html
& $daoEngine --headless --path . --export-release WebPersistenceTest build/web-persistence/index.html
& $daoEngine --headless --path . --export-release IslandProgressionTest build/island-preview/index.html
node tools/prepare_web_compression.mjs build/web
node tools/prepare_web_compression.mjs build/web-persistence
node tools/prepare_web_compression.mjs build/island-preview
python tools/res1c2_export_budget.py --build web
python tools/test_web_delivery.py --port 4230
python tools/island_preview_server.py --port 4230 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-final-active-metrics.jsonl
python tools/web_persistence_server.py --port 4228
node --check tools/res1c2_metrics.js
git diff --check
```

引擎確認4.7.2.stable.official.ed1daf0bf，未重裝／升版。全部上述最終命令exit0；固定入口51項兩輪、三preset各來源階段匯出與companion roundtrip保留本輪日誌。既有Bundled Python3.12執行`subset_game_fonts.py --check`最終exit0（fonttools4.61.1、來源與runtime hash／1809 glyph metrics不變），[結果](artifacts/res1-c2-perf-r2-font-check-final.json)。

初次PowerShell搜尋用了不適用的brace語法，已改正；誤認OfflineSettlement在application後定位至simulation。初次sandbox本機服務無法供瀏覽器連線、HTTP驗收WinError10013、user://log受限；改用已授權loopback／隔離回歸執行環境後通過。試用相對`--log-file build/...`導致Godot `user://E:`診斷，未靠它判斷保存成功，後續不用此參數。既有世界退出清理診斷未解決，不能宣稱所有日誌零錯誤。

本輪自建4222–4229測試服務已停止，**4230隔離試玩保留**；先前4175／4207／4221服務未中斷。[開啟試玩](http://127.0.0.1:4230/launcher?metrics=1)，已有隔離檔按「開啟隔離遊戲」，seed拒覆寫。要新鮮長期試玩狀態，重新執行review工具並換未使用origin，不能覆寫玩家存檔。

尚未通過：節流長離線总ready≤10秒、嚴格60FPS、DPR2/3最大zoom美術、指定實體手機觸控／30FPS p95≤40ms、自然背景凍結、跨瀏覽器、長期WASM／GPU記憶體與人工節奏。人工後續應在可存取的獨立裝置測試origin（本機服務目前只綁loopback）驗橫／直旋轉、單指拖曳／雙指縮放、切島／抽屜／低特效、最大zoom清晰度；背景切走再回來與重載核對相同快照／新間隔。桌面iframe不能代替手機。

**C/C2/PERF-R2仍IN_PROGRESS，D TODO。** 依AGENTS Context Guard，本階段有界交付後主動停下；英文checkpoint寫updata頂部，下一New Chat續PERF-R2節流長離線／嚴格FPS與人工／裝置，不展開D。

## 2026-10-04 續輪交付：節流長離線缺口

接續同一R2。**長離線桌面網路案例有界通過，R2／C／C2仍IN_PROGRESS；D TODO。** 沒有改規則／schema、24h收益上限、Amount契約、素材、保存權威或玩家檔；未commit／push／部署。保留既有dirty／untracked成果。

### 來源與安全邊界

- `IslandEconomy.tick_prepared`先執行原逐秒tick，只有無在途、無加工倒數、完整economy除tick外完全不變、祖島Amount未變，才辨識固定點。後續每秒仍增加economy tick；祖島庫存一變即執行原流程，所以靈界耗料／當秒生產可以喚醒阻擋航線／加工。不跨命令重用。監看持有的resource entry與Amount；這些tick只替換entry.value，命令後重建準備。
- `TimeAdvancer`只在乘區未重建、上一生產結果不變、economy已靜止、祖島庫存未變時重用無變化生產。BUFF到期／時辰切換使壽元、修行倍率與生產快取失效；修行秒數保留原逐秒浮點加法，沒有把n次相加換成乘n。單tick路徑去掉第二層結果封套，事件仍按原順序合併。
- `ChronoSystem.tick`移除一次重複同步（ensure_initialized已同步）；`AbodeScenery.advance`滿兩件時省略eligible掃描，保持原本暫停時鐘／RNG政策。`FrameBudget`由10改為 **14ms**，約留2.7ms供60Hz進度UI／render；仍可能有單tick超時，牆鐘只管讓出，不決定收益。
- 擴充perf Runner至 **145精確tick/font checks**：長離線、BUFF／天時／容量收縮、宗門／靈獸、壽盡、靜止後倍率變化、靈界耗料、B原型祖島加工、祖島庫存下降立即出貨、單tick事件順序與共享準備。原逐秒 `IslandEconomy.tick`保留為比較路徑。

修改來源：`src/simulation/island_economy.gd`、`time_advancer.gd`、`chrono_system.gd`、`abode_scenery.gd`、`src/platform/frame_budget.gd`、`tests/res1c2_perf_runner.gd`、`tools/res1c2_perf_profile.gd`、`tools/island_preview_server.py`（僅新增無遊戲rAF對照入口），以及README／ROADMAP／docs02／07／ai-handoff／development-status／本頁／updata與`cont-*`證據。

### 量測與最終結果

IAB Chromium154、Windows、Compatibility、單執行緒Web。網路為共用20Mbps下載預算、每response 100ms延遲；Brotli、no-store、新origin，1280×650 CSS iframe／DPR約1。Runner產生48h前UTC游標，實測另含工具用時，因此為48h+；有效收益仍86400秒、總年歲12000秒壽盡。命令賺得GameState相同，沒有加資源。未清瀏覽器profile／WASM code cache；測量時沒有Runner／export／HTTP驗收並行。兩個通過樣本只有約0.2秒餘裕，不能承諾所有機器都低於10秒。

| 來源階段／案例 | ready | 純結算 | 結果 |
| --- | --- | --- | --- |
| 本輪10ms舊匯出基線、4231 | 13,564.7ms | 5,120.2ms | 未過 |
| 初版固定點／10ms、4232（DPR1.25） | 10,675.5ms | 2,220.1ms | 未過；不同DPR不作完全同條件配對 |
| 14ms、監看查找改善前、4233 | 10,034.6ms | 1,587.3ms | 未過，未四捨五入為10秒 |
| **最終交付版、新origin4234** | **9,800.7ms** | **1,349.6ms** | **≤10秒通過**；73間隔／p95 16.8／max33.3ms、visible |
| **同交付版、新origin4235複測** | **9,777.0ms** | **1,324.1ms** | **≤10秒通過**；72間隔／p95 16.8／max16.9ms、visible |
| 4234真實reload，再按開啟隔離遊戲 | 8,668.5ms | 141.2ms | 摘要只新10秒／未套上限，不重領48h |

[摘要索引](artifacts/res1-c2-perf-r2-cont-summary.json)僅整理原始資料，不覆寫gaps。[基線](artifacts/res1-c2-perf-r2-cont-baseline-metrics.jsonl)、[初版](artifacts/res1-c2-perf-r2-cont-throttled-metrics.jsonl)、[14ms未過](artifacts/res1-c2-perf-r2-cont-throttled-final-metrics.jsonl)、[最終與重載](artifacts/res1-c2-perf-r2-cont-delivery-offline-metrics.jsonl)、[複測](artifacts/res1-c2-perf-r2-cont-delivery-repeat-metrics.jsonl)。[最終摘要](artifacts/res1-c2-perf-r2-cont-delivery-offline.jpg)與[真實重載](artifacts/res1-c2-perf-r2-cont-delivery-reload.jpg)是完成畫面；沒有把它們稱為途中進度，分幀證據來自原始gaps與CLI callbacks。

原生48h同步CPU **2,662,373→885,503µs（約66.7%減少）**；完整終態hash仍 `ddb697e8e22bd830af9bea1034cb24889c1a7afb2139543eb0372ad2d0a8025e`。600tick hash仍 `b0ccfe4b94668b25ead2776a71d9e19601f5ef37c9113416d92d2fac1aa36e63`；600tick時間143,887→153,945µs，沒有宣稱活躍短期CPU改善。獨立12k島經濟工具原路徑／準備路徑hash一致，9998tick用到靜止捷徑。這是native規則探針，不能代替Web ready。[基線CPU](artifacts/res1-c2-perf-r2-cont-cpu-before.log)、[交付CPU](artifacts/res1-c2-perf-r2-cont-cpu-delivery.log)。

正常雙鏈遊戲1280×720／DPR約1，15秒 **59.930137FPS／p95 16.8ms／max33.2ms**。p95通過，**嚴格60仍未過**。[原始gaps](artifacts/res1-c2-perf-r2-cont-active-metrics.jsonl)、[桌面](artifacts/res1-c2-perf-r2-cont-desktop.jpg)。另無遊戲頁rAF **59.997200FPS／p95 16.8ms／max17.3ms**，初始記錄DPR1.25；只是排程對照，不能把差異全歸因引擎或改60門檻。[對照](artifacts/res1-c2-perf-r2-cont-raf-control.json)。未測GPU實際frame time。

桌面滑鼠青木→管理此島，可讀加工中、庫存與預留。[青木管理](artifacts/res1-c2-perf-r2-cont-wood-management.jpg)。直接viewport override曾量到843×389／845×390；最後回到既有launcher，DOM確認 **844×390 CSS iframe**，實際點玄礦→管理、半頁內部捲動讀銅精與剩餘秒數、固定關閉、點洞府、返回祖島。[尺寸](artifacts/res1-c2-perf-r2-cont-short-viewport.json)、[加工與關閉](artifacts/res1-c2-perf-r2-cont-ore-short-processing.jpg)、[返回](artifacts/res1-c2-perf-r2-cont-home-short.jpg)。沒有修改正式canvas或用瀏覽器捲軸躲避版面；桌面與離線console warn/error均空，[桌面console](artifacts/res1-c2-perf-r2-cont-active-console.json)、[離線console](artifacts/res1-c2-perf-r2-cont-delivery-console.json)。

### 最終命令與保存回歸

固定Godot `4.7.2.stable.official.ed1daf0bf`，未升版／重裝；以下交付命令exit0：

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
& $daoEngine --headless --path . --script res://tests/res1c2_world_runner.gd
& $daoEngine --headless --path . --script res://tools/res1c2_perf_profile.gd
& $daoEngine --headless --path . --script res://tools/res1c2_review_fixture.gd
& $daoEngine --headless --path . --export-release Web build/web/index.html
& $daoEngine --headless --path . --export-release WebPersistenceTest build/web-persistence/index.html
& $daoEngine --headless --path . --export-release IslandProgressionTest build/island-preview/index.html
node tools/prepare_web_compression.mjs build/web
node tools/prepare_web_compression.mjs build/web-persistence
node tools/prepare_web_compression.mjs build/island-preview
# 本輪使用bundled Python3.12；PATH Python曾失敗，後續不用它。
$daoPython = 'C:/Users/asus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $daoPython tools/res1c2_export_budget.py --build web
& $daoPython tools/test_web_delivery.py --port 4236
& $daoPython -m py_compile tools/island_preview_server.py
node --check tools/res1c2_metrics.js
git diff --check
```

- 最終完整 **51/51 exit0**，含145精確tick/font與async27；[日誌](artifacts/res1-c2-perf-r2-cont-all-runners-release.log)。新無命令快取依完整snapshot／事件核對，不以調整標準值讓測試變綠。額外world **26 checks exit0**，[日誌](artifacts/res1-c2-perf-r2-cont-world-release.log)保留既有FontAdvanced／CanvasItem／8 ObjectDB／1 resource退出診斷，沒有宣稱零錯誤。
- 三preset最終匯出／companion roundtrip exit0，[正常匯出](artifacts/res1-c2-perf-r2-cont-export-release-web.log)／[正常companion](artifacts/res1-c2-perf-r2-cont-compression-release-web.json)。正常PCK SHA256 **`7264ee1fccf17062f7e0c17c93177f5d836e5d30a3fcaa4fd66f4ef61215c11d`**；WASM hash仍`fc74679e…fa57d0`。必要JS／WASM／PCK Brotli **14,447,267 bytes**，四首原MP3另5,347,590，含全部19,794,857。[包清單](artifacts/res1-c2-perf-r2-cont-budget-delivery.json)。[HTTP13案](artifacts/res1-c2-perf-r2-cont-http.json)驗br／gzip／q=0與四首音訊hash；沒有手改匯出物修來源。
- 4237最終WebPersistenceTest **C2五種async中斷／重試49 checks PASS**，[報告](artifacts/res1-c2-perf-r2-cont-c2retry49.txt)／[畫面](artifacts/res1-c2-perf-r2-cont-c2retry49.jpg)。先開一般retry亦 **69 PASS**，[報告](artifacts/res1-c2-perf-r2-cont-retry69.txt)；一般retry不能取代C2路徑，後續另跑正確`?case=c2retry`。前輪146完整故障矩陣沒有重做，不擴張覆蓋宣稱。

最初CPU工具縮排錯誤已修；初次sandbox user://log／世界隔離存檔拒寫，使world到nil後等待，已停止該程序（exit1），使用授權隔離環境重跑26 PASS。第一次PATH Python出現找不到C:\Python314真實路徑，改bundled runtime後syntax／HTTP／budget通過。較早CPU工具與被拒的world程序重疊一次，保留該log，交付CPU另在無Runner／browser工作負載時執行。測試服務以Ctrl-C正常停止，回報exit1代表人工中止服務，不當成測試通過。

本輪4231–4235與4237已停，**4236正常版隔離試玩保留**：[開啟](http://127.0.0.1:4236/launcher?metrics=1)。已有隔離檔請按開啟隔離遊戲，seed拒覆寫。啟動命令：

```powershell
& $daoPython tools/island_preview_server.py --port 4236 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-cont-active-metrics.jsonl
# 新origin長離線複測（先確認port未使用；不能覆寫既有進度）
& $daoPython tools/island_preview_server.py --port 4238 --normal-build --gzip --offline-fixture --throttle-mbps 20 --latency-ms 100 --metrics-log res1-c2-perf-r2-next-offline-metrics.jsonl
```

下一仍 **R2嚴格60FPS量測／決策、指定手機觸控及30FPS／p95≤40ms、DPR2/3最大zoom、自然背景凍結、跨瀏覽器、長期WASM／GPU記憶體、人工美術／節奏**。手機需要可連線的獨立測試origin，目前loopback只限本機；桌面iframe不代替手機。按前節人工步驟驗旋轉、拖曳／雙指、抽屜、切島、低特效、重載與背景恢復。依AGENTS Context Guard，本階段已完成有界交付，停止展開新大型任務；英文checkpoint寫updata頂部，請New Chat接續同一R2，不跳D。
