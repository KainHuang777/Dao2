# RES1-B-WEB-R1：Web 保存與離線故障矩陣

2026-10-03 · **DONE：核心／桌面 Web 保存故障範圍**。RES1-B 相交保存門檻於此範圍補齊；正式多島內容／玩法與裝置、長離線效能仍留 RES1-C/D。隔離 origin `http://127.0.0.1:4196`，Godot 4.7.2、Compatibility、單執行緒 Web。權威儲存沿用 **localStorage**，沒有 IndexedDB 或 user:// Web 落盤宣稱。正式 processing catalog 仍 opt-in。

## 修正與契約

- WebStorageAdapter 使用每 namespace 的 lifetime exclusive Web Lock。未取得、已釋放或瀏覽器不支援時拒絕寫入；不使用可能在背景過期的 timer lease。次分頁停止啟動，關閉原分頁後必須重載，重新讀取保存狀態再結算。pagehide 釋放鎖，BFCache 回復的舊畫面須重載。
- 讀取 SecurityError 與 missing 分開。任一槽讀取被拒絕，或已有快照但兩槽均無效時，SaveManager 不建立空白新檔、拒絕保存。正式 Godot 顯示保留進度與重試訊息。
- read_best 選完整、驗證過且 revision 最新的快照；同 revision 比較離線游標，再以有效 index 決定。復原後 rotation 以實際選中槽為準，避免索引中斷後下一筆保存覆蓋唯一最新有效槽。
- 保存游標不可因系統時鐘倒退而回退。schema2 原文備份已存在時也重新核對 bytes；衝突拒絕提交。schema 3、rules core-flow-8-talent-only-inheritance 維持；本輪修正持久化與既定離線政策接線，沒有改材料公式或啟用多島。
- Web 大於 2 秒的幀恢復間隔由 OfflineCoordinator.settle_state 使用原狀態副本結算並保存。保留完整間隔、收益依既定 24h／壽元限制，不再把完整間隔裁成 86400 秒。Web focus notification 不另補算。失敗保留原 state／游標並暫停玩法；玩家恢復儲存後按重試保存，包含未保存命令收據且不重送命令。一般 Web 保存失敗亦以同一方式保留記憶體並重試。
- 錯誤提示使用 Godot Container、共同字體與短橫式 viewport 適配；重試 Control 至少 44 邏輯像素。HTML 按鈕、Storage prototype 故障注入與結果 DOM 僅為驗證工具。

鎖設計依 [W3C Web Locks](https://www.w3.org/TR/web-locks/) 的 promise 持鎖／exclusive 語意。瀏覽器不支援 Web Locks 或非安全連線時採停止啟動，不降級為可能雙寫的 lease。更新前已開啟的舊版程式不會自動遵守新鎖，部署前須關閉舊分頁；本輪沒有部署。

## 瀏覽器證據

同一 production adapter、SaveManager、OfflineCoordinator、GameSession、IslandEconomy 在測試專用 Godot Web 匯出執行，15資源／8配方與工作／在途貨物／收據全部快照比較。

| 案例 | 結果 |
| --- | --- |
| 注入 quota／SecurityError／讀回失敗／index 中斷／payload 截斷 | retry 69 checks PASS；source／cursor 不變，重啟可回到完整舊或新快照，重試只領一次 |
| 拒絕讀取 | denied 11 checks PASS；不建立新檔、不覆寫原 bytes，權限恢復後可讀 |
| 單槽／雙槽損壞 | corrupt 10 checks PASS；前代復原／雙槽失效停止保存 |
| schema2 備份失敗／重試 | migration 7 checks PASS；原文不動，成功另存 schema3並核對原文 |
| 真實 reload → settle → 第二次 reload | 8／6／5 checks PASS；tick17加工／貨物及收據保留，600秒結果等價，第二次零收益 |
| 實際填滿瀏覽器 localStorage quota | actualquota 12 checks PASS；真實 QuotaExceededError、保留state／cursor，僅移除隔離填充鍵後重試成功、不雙領 |
| 48h／24h上限／倒退時鐘 | cap 14 checks PASS；完整 state 與政策參照一致、立即重載不領第二天、游標不退 |
| 兩個真實分頁競爭同一鎖 | first owns / second blocked / 關閉第一分頁後第二重載接手，各1 check PASS；第二分頁直接呼叫 adapter.write亦被拒絕 |
| 受控 Web 幀暫停／恢復／失敗重試 | `/background` 測試頁暫停 requestAnimationFrame 後恢復：36 ticks 保存成功；另一輪恢復時 SecurityError 被拒絕，Godot停止並保留source，滑鼠重試46 ticks成功。原始成功／失敗報告已寫入JSONL。 |
| 正式 Godot UI | 1280×720雙分頁阻擋；844×390讀取拒絕提示可讀、滑鼠恢復儲存後按重新載入進入原檔；在線保存拒絕後暫停，滑鼠重試成功、139 ticks結算並恢復玩法 |

`web-persistence-browser.jsonl` 是測試頁透過本機HTTP POST保存的原始結果，包括seed／reload各階段及失敗紀錄；瀏覽器畫面由工具實際擷取並檢查，未寫入本地圖片檔，不虛構截圖路徑。拒絕儲存採可控制的 SecurityError 注入，沒有變更使用者隱私／網站權限；quota另有真實耗盡測試。

48h 案例首次瀏覽器等待因同步CPU計算逾時；稍後明確取得14 checks PASS。目前沒有穩定幀時間或長離線CPU預算通過宣稱；RES1-C 正式內容量仍需量測／分批讓出主執行緒。沒有實體手機、高DPR、跨瀏覽器或OS/瀏覽器崩潰測試；payload中斷為可控制故障注入。

## 檔案與可重跑命令

- 修改：src/persistence/{web_storage_adapter,save_slots,save_manager}.gd；src/application/offline_coordinator.gd；src/abode/living_abode.gd；project.godot；export_presets.cfg；tools/run_all_runners.ps1。
- 新增：src/verification/web_persistence_probe.gd、scenes/web_persistence_probe.tscn、tests/web_persistence_fault_runner.gd、tools/web_persistence_server.py（Godot產生的uid保留）。正式Web preset排除probe及場景；只有WebPersistenceTest帶persistence_verification feature／專用主場景。
- 並行工作相依修復：src/debug/simulation_sandbox.gd 原先呼叫不存在的 AmountCompat.deserialize、Lifespan.SECONDS_PER_YEAR、GameClock.current_time，改為既有try_parse／60秒每年／clock.now；未重做Debug沙盒。DebugActions專項最終exit0。初輪Web編譯錯誤及受影響全量結果保留。

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
& $daoEngine --headless --path . --script res://tests/web_persistence_fault_runner.gd
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
& $daoEngine --headless --path . --export-release Web .\build\web\index.html
New-Item -ItemType Directory -Force build/web-persistence
& $daoEngine --headless --path . --export-release WebPersistenceTest .\build\web-persistence\index.html
python tools/web_persistence_server.py
```

瀏覽器入口 `/?case=retry`、reload（連續兩次按重新載入）、corrupt、denied、migration、cap、actualquota；lock開兩個分頁，關閉first後在second重載。重新測reload前使用新的隔離namespace／origin或明確保留舊證據並重建測試檔，不覆寫玩家origin4175。`/release/index.html?fault=read`測正式錯誤提示；恢復儲存清掉query，再按Godot重試。拒絕寫入後等15秒自動保存觸發暫停，再恢復並按Godot重試。`/background`按「暫停遊戲幀」超過2秒，再恢復，觀察WEB_BACKGROUND報告；這是測試工具攔截requestAnimationFrame的受控Web幀暫停，不是原生分頁／OS凍結證據。IAB單純切分頁／隱藏iframe未產生可證明的暫停，故不列為通過。實際裝置背景／OS凍結另待驗。

命令結果日誌：web-persistence-import.log；fault-core.log（首輪15 checks）／fault-core-final.log（最終19 checks，新增既有schema2原文衝突／重試）；probe-parse.log；debug-actions-r2.log；all-runners-initial.log（sandbox隔離user寫入失敗）；all-runners-elevated.log（45/45）；all-runners-final.log（並行沙盒引入後失敗）；all-runners-after-sandbox.log（最終工作區47/47、exit0）；release-export-final.log；export-r3.log（測試preset）。第一版export未建立目的目錄、及命令列場景override不被模板支援／probe兩項型別推斷失敗均已修正；保留首次紀錄。負向JSON／既有退出RID診斷不當作新成功結果。

最終 native 命令：47/47 Runner exit0；run_res1b_verification.ps1 251 checks及seed/resume/verify全部exit0；Web正式export最終exit0。錯誤提示與讀取拒絕／在線保存拒絕以真實滑鼠驗；正式來源不含故障控制HTML。下一任務 RES1-C 三島T2操作切片；仍不得直接把test catalog接入現有玩家正式保存。

最後補四項「既有schema2 archive衝突／原文保留／修復後重試」斷言，新Runner最終19 checks PASS、exit0（fault-core-final.log）。全量47/47是在這四項測試斷言追加前完成；其後未修改遊戲來源，未重複全量。
