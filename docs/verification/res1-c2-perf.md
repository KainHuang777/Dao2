# RES1-C2-PERF｜下載、呈現與離線成本收尾

2026-10-04後續：[PERF-R2](res1-c2-perf-r2.md)同輪本機48h恢復18.03→7.75秒、最終51/51／121精確檢查／Web retry49通過；節流長離線13.55秒及嚴格60FPS仍未過，C/C2 IN_PROGRESS，不跳D。下方本輪數據是R2前的歷史，未覆寫。

2026-10-04；桌面改善與有界回歸交付，RES1-C/C2 維持 **IN_PROGRESS**。本輪不新增 Era 3、島群或規則版本，不代表人工美術／裝置放行。開始時工作區已有大量未提交與未追蹤的 C1/C2/C3、BUFF 等內容；保留原工作，沒有 commit、push 或部署。

## 結果與證據邊界

| 項目 | 本輪實測 | 判定 |
| --- | --- | --- |
| 正常 Web 必要 JS/WASM/PCK | Brotli **14,442,159 bytes（14.44 MB）**；gzip 16,683,717；raw 46,314,205 | 30 MB 壓縮下載預算通過；raw 不符合下載預算，必須使用 HTTP 壓縮 |
| 加上四首原始 MP3 | 19,789,749 bytes（19.79 MB）；音樂合计 5,347,590 | 完整音樂未刪除／轉碼；按播放需求另行下載 |
| 新 origin 新檔冷啟動 | **8,485.7 ms**；20 Mbps、每個回應延遲 100 ms、no-store、1280×720、DPR 1.25 | 此新檔案例 ≤10秒通過；不是全新瀏覽器 profile，未清除瀏覽器 WASM code cache |
| 1280×720 正常版雙鏈場景 15秒 | 最終版 **59.45 FPS／p95 16.8 ms／max 49.9 ms**；較早同輪 **59.85／16.8／33.4** | p95≤20 ms 通過；平均仍低於嚴格60 FPS，不改門檻或將其標成通過 |
| 600秒同狀態 CPU 探針 | advance 539,866→271,115 µs，約減少49.8%；600 ticks與終態hash完全相同 | 純規則有界成本改善；不是 Web FPS 或完整48h成本 |
| 48h命令賺得雙鏈存檔／正常 Web | 本機無節流 **18,194.3 ms** ready；真實分批畫面，86400秒收益上限、壽盡、重載只新間隔 | 長離線正確性通過；長離線恢復仍超10秒，不用新檔8.49秒遮蓋此缺口 |
| 核心／UI／保存回歸 | 固定 **51/51 Runner exit0**；新增107精確tick/font；世界26；Web async retry49 | 只擴張適用的有界證據；手機、GPU長期記憶體等另驗 |

MB 使用十進位。budget來源 [最終包清單](artifacts/res1-c2-perf-budget-final.json)；[HTTP 13案](artifacts/res1-c2-perf-http-final.json)逐位元核對 br/gzip/禁止壓縮與四首 MP3。必要量包括JS/WASM/PCK；HTML/小圖示及HTTP標頭另有少量開銷。最終正常 PCK SHA256 `b4560ac8beac0ca6ccb86ed28208600787fe2a9e142af0aac5d1b83114074305`，引擎 WASM `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。

瀏覽器使用 Codex IAB、Chromium154、Windows、DPR1.25。工具 rAF callback gaps 是幀排程代理指標，沒有 GPU profiler／實體觸控證據。原始 [新檔冷啟動](artifacts/res1-c2-perf-cold-final-metrics.jsonl)、[最終桌面](artifacts/res1-c2-perf-active-final-metrics.jsonl)、[桌面快照](artifacts/res1-c2-perf-desktop-metrics.json)、[離線與重載](artifacts/res1-c2-perf-offline-metrics.jsonl)保留。

本輪改動前正常PNG新檔基線：1280×720／DPR1.25、無節流、ready3,294.4ms，59.85FPS／p95 16.8ms／max33.3ms。此新檔本來已接近60Hz，不能以較早 SVG／不同離線fixture 的48.60FPS作配對改善證明。前輪67.84秒亦含並行Runner負載。兩筆本輪基線原始資料保留在既有 `res1-c2-closure-metrics.jsonl` 的4209案例；沒有刪歷史。最終59.45FPS樣本開始時關閉另一個剛完成probe的分頁，環境擾動如實保留；所有平均均未達嚴格60。

## 實作

- `living_abode.gd` 以 GameState 物件身分＋revision 快取每幀唯讀 View；命令、debug、重試、載入的明確refresh重新建View。HUD控制器接同份View，刪每幀重複建築外觀refresh。沒有把動畫或幀率當作經濟狀態。
- `TimeAdvancer`／`OfflineCoordinator` 每次無命令的結算只準備一次天賦、基礎倉容、壽元條目；產率乘區變更時重算。BUFF、天時、靈獸、庫存、在途與保留容量仍逐秒推進，事件次序／RNG與收益契約不改。prepared 不持久化，也不可跨命令重用。schema3／rules `core-flow-9-island-progression` 保持。
- `island_world.gd` 在Era2需要時載入兩遠島的圖層；原始PNG／切層／提示詞／來源保留。兩島import尺寸上限1024（實際1024×682）；木地標維持lossless，其餘依品質驗證選定lossy，祖島terrain與sky維持原尺寸。
- `subset_game_fonts.py` 由src/content/scenes的文字＋Latin1產生 Dao2 Sans／Dao2 Serif runtime字型；每種1809原字型支援字元，原始兩TTF不變。hmtx、垂直metrics、wght axis及400/600/800角色保持。family、unique、PostScript及variable named instance名稱均更名，保留原copyright與OFL。`--check` 為新增文字的覆蓋守門；任意外來／自訂字串及原字型本來沒有的emoji不保證可顯示。見[manifest](../../assets/fonts/runtime/manifest.json)與[授權](../../assets/fonts/README.md)。依據 [fontTools subset文件](https://fonttools.readthedocs.io/en/stable/subset/)／[OFL修改指引](https://openfontlicense.org/how-to-modify-ofl-fonts/)。
- Web BGM保留四首原MP3逐位元內容，`library.json`維持原Era門檻；需要播放才用HTTPRequest下載，30秒timeout、4MB限制、相同track pending去重、失敗可關閉／開啟重試，回應不可重新播放已取消曲目。原生仍使用既有資源路徑，音樂沒有任何收益副作用。
- 三份export preset排除原始大字型、未引用舊sky、MP3；runtime字型與音樂metadata保留。`prepare_web_compression.mjs`是開發工具，用Node內建zlib產生驗證過的.br與MP3 companion；不修改Godot匯出的index.js/wasm/pck。Node不參與遊戲規則或Web runtime。
- `web_static_server.py`是stdlib loopback HTTP服務，MIME、Content-Encoding、Content-Length、Vary、q=0及gzip/raw fallback已驗；啟動時核對Brotli來源／companion hash，來源重匯出後過期companion不再使用。`start_web_server.ps1`涵蓋assets/content變更、準備音樂／壓縮；未執行此固定4175入口，以免中斷使用者既有服務，只通過PowerShell語法解析與等價隔離HTTP測試。

## 素材與品質

`tools/res1c2_texture_audit.gd`按照Godot的CUBIC size_limit resize及fix_alpha_edges比較import結果；不是把1024輸出與1536原圖宣稱逐像素相同。opaque encoding PSNR門檻35dB，六檔最終通過，alpha相對宣告resize均零差異：

| 檔案 | import方式 | PSNR |
| --- | --- | --- |
| terrain | 原尺寸、lossy0.85 | 35.488 |
| sky_tearfall_island_v6 | 原尺寸、lossy0.85 | 36.668 |
| wood_body | 1024、lossy0.92 | 35.861 |
| wood_landmark | 1024、lossless | 120（零encoding差異哨兵值） |
| ore_body | 1024、lossy0.92 | 36.941 |
| ore_landmark | 1024、lossy0.98 | 35.472 |

[最終數據](artifacts/res1-c2-perf-textures-final-r2.log)。此指標不驗證縮圖後的美術品質、最大鏡頭縮放或DPR2/3可接受性；原1536×1024圖與license/provenance／切層未修改，高DPR人工觀察仍是正式放行條件。

## 真實瀏覽器操作

各origin彼此隔離，只載入命令賺得fixture；正常namespace `dao2_saves`仍是該origin專屬，沒有讀写4175／4207或其他玩家進度。

1. 4219：新origin、正常新檔，20Mbps／100ms、no-store，必要下載14.44MB、ABODE_READY8.486秒；BGM於ready之後約0.88秒完成。[畫面](artifacts/res1-c2-perf-cold-final.png)。
2. 4220：HTTP503故意拒絕第一首音樂，遊戲仍操作。实际齒輪選單「背景音樂：開→關→開」，沒有重整，`BGM_WEB_READY`確認62.432秒原MP3可解碼。[console](artifacts/res1-c2-perf-bgm-toggle-console.json)／[操作畫面](artifacts/res1-c2-perf-bgm-toggle.png)。這不是音效人工聽覺驗收。
3. 4220全頁1280×720：關閉摘要／引導，15秒幀取樣；青木島→管理此島顯示加工中與實際預留材料。[畫面](artifacts/res1-c2-perf-wood-management.png)。
4. 4221：瀏覽器viewport控制呼叫沒有實際生效（read-only innerWidth仍1280），未用來報844。新增測試launcher按鈕，真實iframe CSS viewport 844×390；Godot依stretch規格使用779×360 logical viewport。從玄礦世界縮小、地標／返回／管理按鈕可見，點管理、在Godot內捲動讀「加工中」、關閉、返回祖島，再填滿視窗。[短橫式世界](artifacts/res1-c2-perf-ore-short.png)／[內部捲動](artifacts/res1-c2-perf-ore-short-scroll.png)／[返回](artifacts/res1-c2-perf-home-short.png)。沒有改正式HTML／CSS去裁切畫布。
5. 4221：寬版實際50次木／礦交替點擊，每10次保存畫面，最後玄礦世界且console warn/error空。[50次畫面](artifacts/res1-c2-perf-web-switch-50.png)。原生同樣50次的nodes861固定，預熱後static memory113,875,512→113,875,584（+72bytes）；兩者均非長期GPU記憶體證明。
6. 4218：48hfixture載入有真實558/86400分批進度，18.19秒本機ready，摘要離開173698秒（測試準備時間另加）、收益上限86400秒、壽元200年耗盡；保存後真實reload只新間隔（截圖8秒），沒有重結算48h。[進度](artifacts/res1-c2-perf-offline-progress.png)／[摘要](artifacts/res1-c2-perf-offline-summary.png)／[重載](artifacts/res1-c2-perf-offline-reload.png)。
7. 4215：最終WebPersistenceTest五種async中斷retry案例 **49 checks PASS**，原始report追加既有JSONL。[本輪畫面](artifacts/res1-c2-perf-browser-retry49.png)／[文字](artifacts/res1-c2-perf-browser-retry49.txt)。未重做前輪全部146案，也未把單案通過擴張為新完整跨瀏覽器證據。

## 命令與結果

引擎先驗證 `4.7.2.stable.official.ed1daf0bf`，未更新／重裝；原版模板。工具都從專案根執行，輸出存本輪 `docs/verification/artifacts/res1-c2-perf-*`。

```powershell
$engine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --version
& $engine --headless --path . --editor --import
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
& $engine --headless --path . --script res://tests/res1c2_perf_runner.gd
& $engine --headless --path . --script res://tests/res1c2_world_runner.gd
& $engine --headless --path . --script res://tests/abode_presentation_parity_runner.gd
& $engine --headless --path . --script res://tools/res1c2_perf_profile.gd
& $engine --headless --path . --script res://tools/res1c2_texture_audit.gd
& $engine --headless --path . --script res://tools/res1c2_review_fixture.gd
& $engine --headless --path . --export-release Web build/web/index.html
& $engine --headless --path . --export-release WebPersistenceTest build/web-persistence/index.html
& $engine --headless --path . --export-release IslandProgressionTest build/island-preview/index.html
node tools/prepare_web_compression.mjs build/web
node tools/prepare_web_compression.mjs build/web-persistence
node tools/prepare_web_compression.mjs build/island-preview
python tools/res1c2_export_budget.py --build web
python tools/test_web_delivery.py --port 4221
python tools/island_preview_server.py --port 4221 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-responsive-metrics.jsonl
```

依順序：import／三preset最終export exit0；兩次完整51/51 exit0 [最終日誌](artifacts/res1-c2-perf-all-runners-final.log)；107精確tick/font [最終metadata更名後回歸](artifacts/res1-c2-perf-font-final-test.log)；world26與presentation pass exit0；CPU、texture、review-state保真工具exit0；Node built-in Brotli roundtrip、HTTP13案exit0。Python py_compile、Node --check、PowerShell parser零errors。FontTools4.61.1由官方PyPI安裝至忽略的build/tool-deps，使用bundled Python3.12；`subset_game_fonts.py --check`最終exit0。[來源hash／覆蓋結果](artifacts/res1-c2-perf-fonts-final-check.json)。

首次sandbox本機服務無法連線、PyPI DNS／user:// log寫入受限，改用已授權一般工具之escalation／隔離測試；原始失敗保留。107 Runner首次型別推斷失敗已修；lossy0.85縮圖與木地標0.98仍不足35dB，修為較高品質／木地標lossless，保留各r1/r2/r3。音樂仍包在PCK時，gzip新檔11.856秒、Brotli10.992秒，未達10秒；分包後新origin最終8.486秒。沒有忽略這些失敗而只聲稱命令發出成功。

world Runner退出仍有FontAdvanced RID、CanvasItem、8 ObjectDB與1 resource診斷；腳本PASS／exit0與退出清理問題分別記錄，不能稱zero errors。[原生日誌](artifacts/res1-c2-perf-world.log)；最終字型內部更名後再跑26項，仍PASS／exit0及相同退出診斷，見[最終日誌](artifacts/res1-c2-perf-world-font-final.log)。純工具sandbox log警告不是玩家存檔故障；完整保存回歸使用既有隔離資料。git diff --check最後通過（既有LF/CRLF notices）；沒有手改.godot或匯出index檔修來源。

## 交付與下一步

保留本輪4221服務：[正常版隔離試玩](http://127.0.0.1:4221/launcher?metrics=1)。已有隔離進度拒覆寫，若需新鮮review狀態先由工具重封UTC並用全新未使用port；不可覆寫玩家資料。已驗工具與報告可重跑；本輪4208–4220自建服務停止，4175／4207原服務未中斷。

未通過／待驗：嚴格平均60 FPS、48h恢复≤10秒、DPR2/3與最大zoom美術、指定手機觸控／30FPS p95≤40ms、自然背景凍結、其他瀏覽器、長期Web/WASM/GPU記憶體與人工節奏。Desktop p95與新檔下載／啟動過關不使整體C2 DONE。下一 **RES1-C2-PERF-R2／裝置與人工放行**：先補長離線與嚴格FPS證據，再人工／指定裝置；不跳RES1-D。依AGENTS Context Guard，本階段有界交付後用New Chat續接，英文checkpoint置updata頂部。
