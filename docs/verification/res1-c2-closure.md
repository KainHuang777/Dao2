# RES1-C2-R1：驗收收尾與未放行項

2026-10-04。**桌面 async 保存追加矩陣完成；RES1-C／C2 仍 IN_PROGRESS**。使用者本輪選擇「美術／節奏先保留待驗，提供預覽」。本輪沒有啟用正式 manifest，也沒有修改玩家 `dao2_saves`、經濟公式或存檔版本。原 C1／C2 交付與首失敗紀錄保留於 [C2](res1-c2.md)。

## 可重跑的桌面保存證據

`WebPersistenceTest` 的既有 probe 增加 C2 案例，從命令賺得的 Era2 雙鏈 fixture 解碼，附掛 `IslandProgression`，使用正式 `WebStorageAdapter`／`SaveManager`／`OfflineCoordinator.settle_async`。所有故障只針對 `dao2_matrix_c2*`；不靠 DOM 修改正式遊戲資源。固定 600 秒案例與原同步協調器的完整快照比較，包括資源、jobs、cargo、收據及游標。

IAB Chromium 154／Windows，獨立 `127.0.0.1:4202`，原始結果追加於 [browser JSONL](artifacts/web-persistence-browser.jsonl)，本輪擷取見 [structured results](artifacts/res1-c2-closure-browser-results.json)：

| 案例 | 結果與實際核對 |
| --- | --- |
| `c2retry` | **49 checks PASS**：注入 quota／SecurityError／讀回失敗／索引失敗／截斷；失敗保留 live source／cursor，重建 SaveManager 後選完整舊或新世代，重試只結算一次；最終 probe 另重跑49 checks PASS |
| `c2quota` | **11 checks PASS**：真的填滿此 origin 的 localStorage，實際 `QuotaExceededError`；source／cursor 不變，清除本案例自己的可丟棄填充後重試，完整狀態一致且再次結算0 ticks |
| `c2indexreload` | **7 → 8 → 6 checks PASS**：首次索引寫失敗，真正 reload 選取完整未索引新快照與601000游標，重試及第二次真正 reload 都不重領 |
| `c2quotareload` | **7 → 8 → 6 checks PASS**：首次槽寫失敗，真正 reload 保留舊快照與1000游標，成功補算一次，第二次真正 reload 不重領 |
| `c2lock` | **8 → 8 → 6 checks PASS**：兩個實際分頁；owner 提交，次分頁即使計算完成仍 `writer_not_owned`，source／slots／index／cursor 不變；關閉 owner，再 reload 次分頁接手，0 重複收益 |
| `c2denied` | **11 checks PASS**：讀取 SecurityError 區分於 missing，async 啟動 `NO_STATE`，不能覆寫原檔；恢復讀取後 async 成功 |
| `c2corrupt` | **11 checks PASS**：最新槽損壞恢復前世代並 async 提交，雙槽損壞停止啟動且拒絕覆寫 |

首輪合計 **146 checks PASS**，最終 retry 49 為額外回歸，不重複計入146。這是新 async 在桌面 Web 的保存追加範圍；自然 OS 凍結、BFCache、跨瀏覽器或實體裝置仍不由此推定。舊 B 的 schema2 原文備份／遷移證據保留。48h 上限與真實遊戲滑鼠 retry 採原 C2 證據；本輪 fault probe 並非再一次完整玩法滑鼠測試。

## 效能結果：未達預算

工具頁 `/metrics.html` 只觀察 rAF、Navigation／Resource Timing 與 JS heap；不更改遊戲 state。伺服器在來源工具層注入觀察器，沒有修改 `build/` HTML。資料見 [metrics JSONL](artifacts/res1-c2-closure-metrics.jsonl)；所有取樣 `document.visibilityState=visible`。

| 條件／量測 | 實測與判定 |
| --- | --- |
| 首次獨立 origin，20Mbps 合計輸出限速、每請求100ms回應延迟、no-store、未壓縮；1280×650 iframe、DPR1.25；48h雙鏈 fixture | `ABODE_READY` **67,837.4ms**；WASM傳輸約29,796.8ms、PCK約27,784.7ms（並行，共用20Mbps預算）。包含引擎啟動＋長離線恢復，當時全量 Runner 並行，不當作純離線CPU或獨立冷啟動基準；**仍未達10秒**，光傳輸已超過預算 |
| 未限速新遊戲頁，1280×720、DPR約1，同一48h來源再次恢復 | `ABODE_READY` **35,374.5ms**，WASM／PCK各約0.17秒傳輸；不能把 planned86400 ticks 當成實際計滿，壽元限制仍有效 |
| 1280×720、DPR約1，摘要已關閉、完整祖島、全量Runner及其他測試分頁已停止；15.042秒取樣731幀 | **48.60 FPS／p95 33.4ms／max 50.1ms**；rAF間隔是瀏覽器實際呈現節奏的代理，不是GPU profiler。**未達桌面60 FPS／p95≤20ms** |
| 其他探索取樣 | 限速 origin 49.83 FPS／p95 33.4ms；1280×720從結算過渡到ready的混合取樣52.59 FPS／p95 33.4ms；不把混合取樣標成全程離線或正常世界基準 |
| 匯出JS＋WASM＋PCK | 原始 **74,384,813 bytes（74.38MB）**；gzip level6估算 **44,717,954 bytes（44.72MB）**，PCK單獨34.41MB。未達必要壓縮下載30MB目標；gzip僅唯讀估算，伺服器本輪未啟用壓縮。檔案hash／分項見 [budget](artifacts/res1-c2-closure-export-budget.json) |
| 原生 headless 50次切島 | **15 checks PASS**，nodes固定854；static bytes每10次為 `[133964630,134239026,134239026,134239050,134239098,134239098]`，首10次預熱後只有72 bytes差異，尾兩點相等。是短程原生穩定證據，**不是Web／GPU長期記憶體放行**；JS heap波動也不當作WASM全量記憶體 |

沒有為通過而改預算、降低取樣百分位或關閉必要功能。壓縮／字型及其他資產下載、正常世界render成本與長離線單tick／分批成本需下一個有界效能任務處理；固定引擎版本不更新。

## 命令與驗證

| 命令 | 結果 |
| --- | --- |
| 既有引擎 `--version` | `4.7.2.stable.official.ed1daf0bf`，exit0 |
| `--headless --path . --editor --quit` | import完成exit0；[log](artifacts/res1-c2-closure-import.log) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | **50/50 PASS、exit0**；[log](artifacts/res1-c2-closure-all-runners.log)。包含其他聊天新增的BUFF修復，未覆寫它 |
| `--headless --path . --script res://tests/res1c2_world_runner.gd` | 正常授權重跑 **15 checks PASS、exit0**；[log](artifacts/res1-c2-closure-world-authorized.log) |
| `--headless --path . --export-release WebPersistenceTest .\build\web-persistence\index.html` | 兩次exit0，最終 [log](artifacts/res1-c2-closure-probe-export-final.log)；probe／tools在正式Web及IslandProgressionTest排除 |
| `python -m py_compile tools/island_preview_server.py tools/web_persistence_server.py tools/res1c2_export_budget.py` | exit0 |
| `python tools/web_persistence_server.py --port 4202` | 本機伺服器實際啟動，GET及/evidence POST204已核對，案例如上 |
| `python tools/island_preview_server.py --port 4203 --offline-fixture --throttle-mbps 20 --latency-ms 100` | 本機冷啟動實測，量測前no-store；不是CDP網路模擬或真實行動網路 |
| `python tools/res1c2_export_budget.py` | exit0，唯讀壓縮估算／SHA256寫入budget JSON |
| `--headless --path . --script res://tools/res1c2_review_fixture.gd` | exit0；[log](artifacts/res1-c2-closure-review-fixture.log)，快照狀態逐欄一致，只換測試save_id／UTC封套 |
| `python tools/island_preview_server.py --port 4205 --review-fixture` | 本輪可試玩三島入口實際開啟；已有資料拒覆寫 |
| `git diff --check` | 通過；既有CRLF提示保留 |

初次world Runner在沙箱無法寫 `user://`，`SAVE_FAILED / Can't open file` 後Nil腳本錯誤，程序未自行退出；已中止該測試，正常授權隔離重跑exit0。第一次Python預設沙箱無法定位既有執行檔，正常授權語法檢查／伺服器成功。預期故障JSON解析錯誤、RID／CanvasItem／ObjectDB退出診斷保留，不稱日誌零錯誤。不因上述環境失敗更新引擎或重裝。

## 修改、預覽與交接

本輪修改 `src/verification/web_persistence_probe.gd`、`tests/res1c2_world_runner.gd`、`tools/web_persistence_server.py`、`tools/island_preview_server.py`；新增 `tools/res1c2_metrics.js`、`tools/res1c2_export_budget.py`、`tools/res1c2_review_fixture.gd`及uid、review fixture、驗收文件／日誌／畫面；同步README／ROADMAP／ai-handoff／development-status／專題入口／updata。沒有更動正式遊戲規則；原C1/C2與另行BUFF變更保留。沒有commit／push／部署。

本輪 [試玩入口](http://127.0.0.1:4205/launcher) 已用命令取得的兩座開拓岛／雙鏈／四條航線狀態初始化；只刷新測試封套，未加入Debug資源。桌面1280×720青木／短橫式844×390玄礦真實滑鼠切島、固定返回和管理入口補看，畫面见 [青木](artifacts/res1-c2-closure-review-wood.jpg)／[玄礦短橫式](artifacts/res1-c2-closure-review-ore-short.jpg)。fixture不是T2升級完成檔，請依本輪已有供給進行試玩；原T2升級／重載證據見前輪C2。裝置覆寫在交付前重設，遊戲分頁回launcher釋放寫鎖。可再點「開啟隔離遊戲」，已有進度不會被載入按鈕覆寫。

**未通過／未取得**：效能預算（以上實測超標）、使用者美術／節奏放行（明確保留待驗）、實體手機觸控／DPR2或3、自然OS凍結／跨瀏覽器、長期Web／GPU記憶體。整體C2不標DONE、正式manifest不啟用、不進D。下一 **RES1-C2-PERF：下載與正常世界幀成本、長離線成本的有界改善及重測**，再補使用者／裝置驗收。按AGENTS Context Guard本階段收尾並將英文checkpoint放updata頂部；大型後續使用New Chat。
