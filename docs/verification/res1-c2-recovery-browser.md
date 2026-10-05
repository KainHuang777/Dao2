# RES1-C2-PERF-R2｜正常恢復與長觀測驗收

2026-10-04（Asia/Taipei）。本輪依 ADR-010 執行真實瀏覽器驗收；**桌面恢復 NOT_PASSED，R2／C／C2 IN_PROGRESS，D TODO**。完成本輪證據收集，不代表完成 R2 DoD。沒有修改遊戲來源或放寬門檻。

## 環境與樣本

Godot `4.7.2.stable.official.ed1daf0bf`；正常單執行緒 Compatibility Web。IAB Chromium 154，頂層 CSS 1280×720、DPR 1.25，所有樣本 valid、visible、環境不變，無 CPU profile。原音樂／預設特效、資源數量模式，離線摘要關閉、量測原始報告收起；完整模式於最後功能確認才開。没有清除瀏覽器快取，不宣稱冷啟動或獨立聽音驗證。取樣期間沒有執行 Runner、匯出、壓縮或 profile；未量測 OS／GPU 的同期負載，不能完全排除外部因素。

新隔離 origin `http://127.0.0.1:4248`；review 工具只重封命令賺得的三島狀態 UTC／save_id，decode 後完整快照相等。以 launcher 種入空 origin，之後沿用既有進度；沒有覆寫玩家 origin。初次頂層載入結算新的 6 秒，300 秒頁載入結算新的 2 秒；最後重載只結算新的 8 秒。不同樣本自然時間／庫存不同，不作效能優化前後的精確配對。

正常 PCK SHA256 `134334491bd68be37fec0cdc292916c5f93020fae986e7ae3a6ecfec5e216eba`，WASM `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`；沿用前輪匯出，本輪沒有重匯出或手改 build。

| 順序／觀測 | 秒 | 平均 FPS | p95 ms | max ms | 接近目標時間 | 尾端恢復 | 結果 |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 首次正常 | 60.005 | 59.8803 | 16.8 | 33.4 | 100% | 是 | PASS |
| 首組長觀測／快速管理點擊、三島操作 | 300.003 | 59.8234 | 16.8 | 166.7 | 100% | 是 | PASS |
| 追加有間隔管理操作 | 300.015 | 54.7405 | 33.3 | 283.3 | 81.6624% | 否 | NOT_PASSED |
| 同頁延長，沒有重載／改設定 | 300.033 | 48.0882 | 49.9 | 250.0 | 53.3276% | 否 | NOT_PASSED |
| 木屋升級後重載 | 60.018 | 35.1050 | 50.1 | 116.9 | 0% | 否 | NOT_PASSED |
| 最後無遊戲 rAF 對照 | 60.014 | 59.9970 | 16.8 | 17.2 | 100% | 是 | 僅診斷 |

第三組最後約 45 秒的 5 秒窗口依序約 40.97、22.93、20.13、24.73、26.50、31.20、31.70、32.46、32.83 FPS，尾端尚未恢復。第四組同頁延長仍未通過，重載後第五組仍低；此輪不能以首兩組通過或無遊戲對照取代失敗。延長觀測另起樣本，中間未取樣間隔保留；不宣稱已獲得無間斷 15 分鐘 raw。工具全部有效遊戲樣本 2/5 恢復通過，總 gate `NOT_PASSED`。

對照顯示稍後同尺寸瀏覽器 rAF 可接近 60，因此下一步應排查遊戲執行負載及持續劣化；這是推論，不是 CPU／GPU、GC、引擎函式或特定節點的根因證據。重載沒恢復，也不能單憑管理次數就宣稱節點洩漏。

## 互動與保存

- 初組有超過 50 次快速管理點擊，但部分即時 screenshot 尚在轉換；不以這批作逐次成功證據。第二組另做 25 組管理開／關，共 50 次，每次留 300 ms 轉換間隔；另有 4 次開啟／返回確認，共 54 次有間隔管理操作。分批 screenshot 驗證管理開啟與洞府恢復，沒有逐次 Godot 收據或獨立事件計數。
- 經營→空島、青木島、玄礦島、返回祖島均以真實滑鼠及後續畫面確認。首次島捷徑點擊未立即顯示；待空島頁建立後再次點擊正常，沒有重現持續命中故障。不是實體觸控證據。
- 木屋 2→3 階成功，靈氣 550→466、金錢 920→864；重載後木屋 3 階及扣料保留，離線摘要僅新增 8 秒。完整模式顯示容量與產率，管理仍可開關。沒有重新跑完整 IndexedDB／quota／雙分頁故障矩陣，這些維持前輪日期化證據。
- 遊戲文件的 warn/error console 多次讀取為空；最後保存的 console JSON 僅包含最終對照文件，不能把它當全程 console 保存。畫面證據：[重載後木屋3階](artifacts/res1-c2-recovery-reloaded.jpg)。

## 命令、檔案與結果

PowerShell 從專案執行：

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/res1c2_review_fixture.gd
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/island_preview_server.py --port 4248 --normal-build --gzip --review-fixture --metrics-log res1-c2-recovery-metrics.jsonl
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/summarize_frame_metrics.py docs/verification/artifacts/res1-c2-recovery-metrics.jsonl --output docs/verification/artifacts/res1-c2-recovery-summary.json
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/summarize_frame_metrics.py --self-test
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/test_frame_metrics.mjs
git diff --check
```

版本符合；review 顯示快照相等 PASS／shell exit0，但保留 `user://logs/godot.log` 寫入拒絕診斷。第一個沙箱伺服器造成瀏覽器 ERR_CONNECTION_TIMED_OUT，停止 exit1；經授權的同命令服務成功供真實瀏覽器存取，session6020 保留。summary exit0 表示解析成功，不代表 gate PASS；最終 gate NOT_PASSED。Python 16、Node 13 契約 PASS／exit0；diff check exit0，有既有 LF→CRLF 提示。沒有新 Godot 51 Runner，前輪結果不冒稱本輪重跑。

本輪修改：review fixture 重封、此驗收、README／ROADMAP／ai-handoff／development-status／updata 交接，新增 `artifacts/res1-c2-recovery-*` raw／summary／命令輸出／contracts／fixture log／console／JPEG。既有 dirty 變更保留，沒有 commit／push／部署。

完整數據：[raw](artifacts/res1-c2-recovery-metrics.jsonl)、[summary](artifacts/res1-c2-recovery-summary.json)、[summary命令](artifacts/res1-c2-recovery-summary-command.log)、[contracts](artifacts/res1-c2-recovery-contracts.log)、[fixture](artifacts/res1-c2-recovery-fixture.log)、[console範圍](artifacts/res1-c2-recovery-console.json)。原始 sampleSequence 會在導覽重置，須搭配 URL／sampledAtUtc 辨認，不依序號去重。

下一仍 **RES1-C2-PERF-R2**：定位正常版持續劣化（保留當前存檔，先確認重現，再針對 process／其他節點／繪圖及系統負載取證），修復後重做正常恢復／長觀測。手機／觸控、DPR2/3、自然背景凍結、跨瀏覽器、長期 WASM／GPU 與人工美術／節奏仍待驗。分頁停在 launcher 釋放遊戲鎖，已有隔離進度按「開啟隔離遊戲」，勿重種。依 AGENTS Context Guard，本輪長觀測與輸出累積後在此交接，使用 New Chat 開始下一個較大型定位階段；不進 D。
