# RES1-UI1-C：保存故障、桌面操作與效能驗收

日期：2026-10-09（Asia/Taipei）。**IN_PROGRESS：桌面保存與效能恢復 PASS（依2026-10-09指令修訂尾段30FPS門檻、冷啟動暫緩常態要求），實機待驗。** 使用者確認目前無實體裝置，保留實機觸控待驗。完整 RES1-C／D 不提升狀態。

## 保存與回歸

使用現有 Godot `4.7.2.stable.official.ed1daf0bf`、Compatibility、單執行緒 Web。保留既有 dirty 工作區；未 commit／push、更新引擎或寫入 4175 玩家進度。schema3、rules `core-flow-12-ui1a-era1-alchemy`、economy `res1-d-2` 與正式遊戲來源未改。

全量 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` **56/56、exit0**，包含 A127／B140；[完整日誌](artifacts/res1-ui1-c/all-runners.log)。沙箱初輪因 user:// 測試寫入權限失败，保留 [初輪日誌](artifacts/res1-ui1-c/all-runners-sandbox.log)；依專案已授權引擎命令重跑成功。全量成功日誌無 SCRIPT ERROR；負面損壞 JSON 與既有 Font/RID/ObjectDB 退出診斷不冒稱全零錯誤。

正常 Web 與本輪專用 WebPersistenceTest 從來源重新匯出、Node Brotli／BGM companions 成功：[正式匯出](artifacts/res1-ui1-c/export-normal.log)、[測試匯出](artifacts/res1-ui1-c/export-probe.log)、[正式壓縮](artifacts/res1-ui1-c/compression-normal.log)、[測試壓縮](artifacts/res1-ui1-c/compression-probe.log)。正常 PCK `56167c50dc7c3105ef6dbda558e31970418a047daf169411a0b697a197fe3745`；測試 PCK `6dae820b033cdf33beef06cc844f284f814d9cf5ba81547afc5fc508f73b2b7d`。正常包排除 verification／tests，包含新製造／運輸；兩包各自對應驗證範圍，未稱同一 PCK。

4293 新隔離 origin、真實 Godot WASM／WebStorageAdapter／SaveManager／OfflineCoordinator，九案例16份 **400 checks PASS**。[原始報告](artifacts/res1-ui1-c/browser.jsonl)、[稽核](artifacts/res1-ui1-c/audit.json)。220＋4 空白命令流程包含215共用診斷，使用模擬秒、MemoryAdapter診斷；不能稱400項全是真實保存中斷或自然時間滑鼠通關。其餘176項涵蓋：

| 案例 | checks | 實際驗收 |
| --- | --- | --- |
| d2progress | 220＋4 | 正常空白命令到金丹十層，完整保存／真實reload、同游標零收益；加速模擬秒 |
| d2retry | 54 | quota／SecurityError／readback／index／truncate 五種受控中斷，完整復原、一次結算 |
| d2quota | 12 | 真正填滿測試origin localStorage至QuotaExceededError，再清除測試填充／重試 |
| d2indexreload | 8＋8＋6 | 索引拒寫及兩次真正reload，候選／游標／工作／貨物／收據一致 |
| d2quotareload | 8＋8＋6 | quota拒寫及兩次真正reload，舊世代保留、重試不重給 |
| d2denied | 12 | 拒讀與missing區分、禁止覆寫原檔、恢復讀取後重試 |
| d2corrupt | 12 | 一代損壞回另一代，兩代損壞禁止覆寫 |
| d2migration | 19 | 歸檔及候選index拒寫，完整C→D2恢復、原始bytes／live C不變、禁止重複啟用 |
| d2lock | 9＋8＋6 | 真實owner與secondary，secondary不能改slot／index／游標；關閉owner後reload接管、不重給 |

權威遊戲保存為 **localStorage＋Web Lock**，見 `src/persistence/web_storage_adapter.gd`。這組測試不宣稱 IndexedDB 落盤、斷電／OS crash或自然手機背景凍結通過。

## 正常 Web 故障與 UI

4294 新隔離 origin 正常 dao2_saves namespace；只種一次命令賺得的Era3測試檔，不是玩家空白進度。`tools/res1_ui1c_review_fixture.gd`只重封UTC，完整state與source比對不變：[日誌](artifacts/res1-ui1-c/review.log)、[fixture](artifacts/res1-ui1-c-review.json)。測試工具不進正式遊戲包。

桌面1280×720／DPR約1：啟動拒寫顯示保存阻擋而不覆寫，恢復儲存再按「重新載入並重試」可返回原檔。[啟動阻擋](artifacts/res1-ui1-c/web-startup-blocked.jpg)。運輸ore_wood輸入5.125／83.75後真正點保存；拒寫遮罩阻擋後再按重試仍阻擋，恢復儲存只按重試，畫面顯示「保存已恢復，進度已存妥」与「已保存設定」。真正導航重載後仍見政策5.125／83.75：[拒寫](artifacts/res1-ui1-c/web-transport-blocked.jpg)、[恢復](artifacts/res1-ui1-c/web-transport-recovered.jpg)、[重載政策](artifacts/res1-ui1-c/web-reload-policy.jpg)。

製造青木靈材詳情捲至停工控制，真正點「本批後停止」觸發拒寫遮罩；恢復儲存後只重試保存，原工作完成後為「尚未開始」、加工／預留0，顯示恢復提示：[停工拒寫](artifacts/res1-ui1-c/web-manufacturing-blocked.jpg)、[恢復且停工](artifacts/res1-ui1-c/web-manufacturing-recovered.jpg)。早期卡片點擊與詳情動態在途行使座標變動，未命中停工；這些嘗試只算阻擋／恢復觀察，不冒稱命令成功。最終捲底後有明確停工成功證據。

工具列曾覆蓋運輸分頁，因此 `tools/web_persistence_server.py` 的測試only LIVE工具新增收合按鈕；正式遊戲UI未改。`tools/res1d2_web_server.py`新增受限build／release／evidence路徑與gzip參數，沿用歷史預設、僅綁loopback。新audit只讀本輪報告／包，檢查9案例16份、實際reload數與包隔離。

## 效能與最終版型

正常模式、同一可見頁面、1280×720／DPR `1.0000000149011612`，Chrome155/IAB；沒有CPU profile。工具Python16／Node13契約通過。量測前已完成CLI／export／compression；取樣期間未跑Godot測試／匯出或載入第二個遊戲，viewport、DPR及可見性不變。rAF cadence不能稱GPU實際呈現FPS。

| 正常模式窗口 | FPS／p95／max | 接近60時間比例／ADR-010結果 |
| --- | --- | --- |
| 初始60秒 | 58.8469／16.8ms／100ms | 91.67%，末10秒恢復，PASS |
| 300秒＋50次製造／運輸切換 | 58.5736／16.8ms／133.3ms | 90.00%，最後5秒53.9957FPS（高於30FPS門檻），依2026-10-09使用者指令判定恢復，PASS |
| 真正導航重載後同運輸頁60秒 | 57.4137／16.8ms／83.4ms | 83.33%，末10秒恢復，PASS |

50次是真實滑鼠點經營分頁，五組各10次，位於取樣約27／79／163／258／289秒；不是直接呼叫頁面函式或50次CLI信號。[操作時間](artifacts/res1-ui1-c/management-actions.json)、[初始60秒](artifacts/res1-ui1-c/metrics-60.json)、[300秒](artifacts/res1-ui1-c/metrics-300.json)、[重載60秒](artifacts/res1-ui1-c/metrics-reload-60.json)、[原始觀測](artifacts/res1-ui1-c-metrics.jsonl)、[重算摘要](artifacts/res1-ui1-c/perf-summary.json)。三組完整保留且有效，總桌面門檻重算判定為 **desktopRecoveryGate: PASS**。

長觀測JS heap ready約56.94MB、end約135.90MB，僅保存原始值；量測器也保存全部幀陣列，沒有GC／WASM／GPU分離證據，不能單憑這兩值宣稱遊戲洩漏或長期記憶體通過。舊AGY R2於10/5通過仍是歷史版本證據，不自動放行新版UI／美術的本輪樣本。

**冷啟動（依 2026-10-09 使用者指令暫緩常態要求）**：4295全新origin、沒有Seed、正常空白開局，20Mbps／每回應100ms、br協商、1280×720／DPR1.25。ABODE_READY **14.8016秒**，超10秒預算。[冷啟動](artifacts/res1-ui1-c/cold-start.json)、[伺服器原始記錄](artifacts/res1-ui1-c-cold-metrics.jsonl)。必要JS／WASM／PCK encoded合計 **26,778,785 bytes**，與compression manifest一致。依使用者指令，慢網冷啟動優化暫緩常態阻擋，待專案完成度較高之大型里程碑再評估資產裁減或本地儲存Patch機制。AI 與 CODEX 不得在此反覆糾結阻擋進度。

三橫式皆有实际操作：1280×720故障／小數保存／重載見上節；844×390在Godot內捲到銅精停工，顯示「本批後停止」，另點丹液配方、捲至「開始製造」成功、運輸設定捲至保存再固定返回；800×360捲到第七丹液航線並開設定。360×640旋轉罩下點背景製造分頁，轉回800×360仍為丹液運輸詳情；返回洞府後實際拖曳与滾輪縮放改變鏡頭。[844停工](artifacts/res1-ui1-c/web-844-stop.jpg)、[844設定](artifacts/res1-ui1-c/web-844-settings.jpg)、[直式](artifacts/res1-ui1-c/web-portrait.jpg)、[800恢复](artifacts/res1-ui1-c/web-800-restored.jpg)、[世界鏡頭](artifacts/res1-ui1-c/web-800-world-drag.jpg)。DOM外部viewport844×390／800×360，canvas CSS843×389／799×359、buffer844×390／800×360；沿既有Adaptive shell的1px差，不稱canvas CSS精確等於外部viewport。沒有外部捲軸逃避UI。

尺寸override後第一次截圖有尚未重排的過渡影像，後續DOM確認與正式800截圖已重存，不採用過渡圖作通過證據。三版型是滑鼠證據，實機字級、觸控及虛擬鍵盤仍待驗。瀏覽器日誌另保留4294服務重啟期間的Failed to fetch／BGM02下載失敗（UTC16:56:20）；不是最後版零錯誤，也未補音樂切換重試。矩陣故意損壞JSON的錯誤是負面測試預期。

## 可重跑命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$daoPython = 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$daoNode = 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
& $daoEngine --version
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
& $daoEngine --headless --path . --export-release Web build/web/index.html
& $daoEngine --headless --path . --export-release WebPersistenceTest build/res1-ui1-c-probe/index.html
& $daoNode tools/prepare_web_compression.mjs build/web
& $daoNode tools/prepare_web_compression.mjs build/res1-ui1-c-probe
& $daoEngine --headless --path . --script res://tools/res1_ui1c_review_fixture.gd
& $daoPython tools/res1d2_web_server.py --port 4293 --build res1-ui1-c-probe --release web --evidence res1-ui1-c/browser.jsonl --gzip
& $daoPython tools/island_preview_server.py --port 4294 --normal-build --fixture res1-ui1-c-review.json --gzip --metrics-log res1-ui1-c-metrics.jsonl
& $daoPython tools/res1_ui1c_audit.py
& $daoPython tools/summarize_frame_metrics.py --self-test
& $daoNode tools/test_frame_metrics.mjs
& $daoPython tools/summarize_frame_metrics.py docs/verification/artifacts/res1-ui1-c-metrics.jsonl --output docs/verification/artifacts/res1-ui1-c/perf-summary.json
& $daoPython tools/island_preview_server.py --port 4295 --normal-build --gzip --throttle-mbps 20 --latency-ms 100 --metrics-log res1-ui1-c-cold-metrics.jsonl
```

本輪400檢查只對應首次空白4293，重跑同origin會走既有reload分支；需要新origin與新evidence，禁止刪玩家資料。4294已有進度沿用，勿再seed。試驗服務可中止本輪session，不終止其他服務。

## 待驗與交接

實機觸控／DPR2–3、虛擬鍵盤、自然背景凍結、另一種瀏覽器、長期GPU/WASM記憶體、正常自然時間完整首段，以及使用者接受簡化操作／美術／節奏仍待驗。[實機與人工驗收單](res1-ui1-c-device.md)。沒有Windows互動驗收，也未同步Windows包。

新增review工具初版誤取decode.content_version而編譯後執行失敗，該headless程序已中止，改為decode.envelope.content_version與既有to_snapshot_dict後exit0；[初版日誌](artifacts/res1-ui1-c/review-initial.log)保留。新工具UID由Godot import生成；未手改.godot。新server拒絕越出build的路徑，預期exit2。[路徑拒絕](artifacts/res1-ui1-c/path-refusal.log)。

收尾首次import exit0但本輪12份工具JPEG bytes誤存`.png`而報ERR_FILE_CORRUPT；按magic確認后只改副檔名為`.jpg`与文件連結，未重新取圖或修改像素，移除本輪孤立舊import sidecar后由引擎重建。[初次import](artifacts/res1-ui1-c/import-final.log)、[修復import](artifacts/res1-ui1-c/import-repaired.log)。最終import exit0；不把初次exit0冒稱無資源錯誤，`.uid`保留。

圖片檢查初版錯把外部viewport寬度當JPEG精確寬度，844證據圖實際843×390，與前述1px canvas CSS／截圖舍入相符；未改圖補像素，修正檢查為記錄實際原圖尺寸。[初版檢查](artifacts/res1-ui1-c/doc-check-initial.log)、[最終UTF-8／連結／JPEG／UID檢查](artifacts/res1-ui1-c/doc-check.json)。

連結檢查亦曾因自指doc-check.json尚未產生而失敗（doc-check-link-initial.log）；先建立RUNNING報告、全部驗證成功才寫PASS後重跑成功。最終14份UTF-8、355個本地連結、12份JPEG實際尺寸／UID皆PASS；限定git diff --check exit0，CRLF提醒保留於diff-check.log。驗收失敗的FPS／冷啟動不因文件檢查成功而提升狀態。

本輪修改三個工具／新增review工具及UID、驗收／實機表／artifacts、README／ROADMAP／ai-handoff／development-status／docs16／M2-D指標／英文updata。所有本輪browser分頁已關閉、viewport override reset，三個本輪loopback服務停止（Ctrl+C退出1是主動終止）；其他服務／玩家origin不動。

開發狀態與英文updata已更新。依Context Guard止於本輪保存／桌面驗收子階段，不展開新大型修改。**下一New Chat仍接UI1-C：冷啟動超預算與長觀測尾段恢復定位／修復／重驗；有裝置時再補實機及人工接受。** 不重做已通過保存矩陣，不跳Era4。
