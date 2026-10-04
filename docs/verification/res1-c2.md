# RES1-C2：三島世界候選、分批離線與桌面 Web

**2026-10-04 最新收尾**：[C2-R1](res1-c2-closure.md) 已補桌面async追加保存矩陣146 checks、全量50/50、世界15 checks與50次原生記憶體取樣。實測冷啟動／下载／幀時間超預算；使用者選擇美術／節奏待驗。整體仍IN_PROGRESS，下一C2-PERF及裝置／人工驗收；下方為前輪歷史，不能再將新async追加矩陣列為尚未執行。

2026-10-03–10-04 · **程式／桌面候選驗收已交付；RES1-C 與 C2 完整放行仍 IN_PROGRESS**。正式 manifest 仍未附掛，玩家 `dao2_saves` 未操作。C1 的 87 checks 與原交付保留，不重做 A/B，不跳 D。

## 本輪交付

- 同一 Godot 世界新增青木／玄礦各自的 SVG 島體與獨立林場工坊／礦坑熔爐候選。未開拓只有島體，開拓後才顯示代表產業；祖島舊建築不複製。美術為原創向量候選，來源、用途、切層、錨點、提示與 SHA-256 見 `assets/abode/res1c/manifest.json`。**未取得使用者美術放行，僅隔離預覽**。
- 世界点島與「管理此島」均導向 FeatureNavigation 的 `outposts`／同一 IslandManagementPanel；管理頁可前往選定島。短 Banner 2.2 秒後轉常駐島名／開拓狀態，返回祖島、44 高控制與窄版 HUD 避讓已接入。四條航線的世界線／船只讀真實在途記錄，不靠動畫扣料或發獎。
- Web 重開與背景恢復使用 OfflineCoordinator 的候選複本分批推進。Platform `FrameBudget` 每批目標 6ms，逐秒沿用 TimeAdvancer；每批讓出 `process_frame`，完成後一次提交。預算只控制排程，不提供經濟時間；既有 simulation 不讀系統時間。來源、加工、貨物、收據與完整游標保存／失敗重試契約不变。傳統未啟用 economy 的整段語意保留。
- 原生 Godot 結算進度遮罩，計算時停止遊戲操作；保存成功才恢復。離線摘要正文改內部捲動、關閉固定並避開底部導航。
- 長離線 fixture 揭露既有 SaveCodec 自己生成的 JSON checksum 不一致：雜湊原數值與實際 JSON 浮點表示可能不同。Encode 現先取得序列化後可讀回表示再算 checksum，Verify 保持原算法。schema 3／rules `core-flow-9-island-progression` 不變；不是新經濟公式或舊存檔全量相容承諾。既有有效快照仍可讀；先前無效 snapshot 仍拒絕，不自動重簽或覆寫。4199 的拒絕測試槽保留。

## 命令與結果

| 命令／證據 | 結果 |
| --- | --- |
| 既有 Godot `--version` | `4.7.2.stable.official.ed1daf0bf`，exit 0；未更新／安裝 |
| `--headless --path . --import` | 最終 exit 0；初次沙箱 user:// 開啟失敗診斷保留，後續使用正常授權 |
| `--script res://tests/res1c2_offline_runner.gd` | **27 checks PASS、exit 0**；600s／48h／倒退／零碎秒與原同步狀態、摘要相等；分批多次讓出、保存失敗來源不變、重試原子提交、重載不重領、實際 fixture checksum 往返 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1` | **50/50 PASS、exit 0**；最終 checksum 修正後全量日誌 `res1-c2-all-runners-checksum-final.log`。此前兩輪架構守門失敗詳下 |
| `--script res://tests/res1c2_world_runner.gd` | **14 checks PASS、exit 0**；50次切島不改規則、未開拓不顯地標、canonical route／返回、兩版型控制／摘要／地標上緣。為補充 Runner，不在固定50清單 |
| M1-D／responsive／world／fixture diagnostic | 相關回歸 exit 0，见 `res1-c2-related-final.log`；診斷 decoded ok、hash 一致 |
| `--export-release IslandProgressionTest .\build\island-preview\index.html` | 最終 exit 0，见 `res1-c2-preview-export-final.log` |
| `--export-release Web .\build\web\index.html` | exit 0，正式內容保持未啟用；见 `res1-c2-release-export-final.log` |
| `python tools/island_preview_server.py --port …` | 僅127.0.0.1，4198雙鏈／4200長離線／4201拒寫；可加 `--offline-fixture`，測試故障頁不進正式匯出 |
| `git diff --check` | 通過；CRLF 提示保留 |

首次分批 Runner 為 Variant 推斷錯誤，修正型別後通過。第一輪全量由 M1-B 拒絕 simulation 的 `Time` token，第二輪由 M1-D 拒絕 coordinator 的直接 `Time`；改由 platform FrameBudget 提供排程預算，沒有削弱測試。新增地標上緣斷言亦曾型別推斷失敗，修正後14 checks通過。初版控制列被 FlowContainer 最小寬度壓成直列、短版取景上緣與摘要溢出，已修正並重驗。

Checksum 首失敗原生與 Web 都重現：原 hash `ba80e0d4…e2b5`、讀回 `964ca21a…b83d`。修正後原生診斷兩者 `d606b173…5030` 一致；fixture 生成時刻不同會改 checksum，不應硬編碼為預期。既有 RID／CanvasItem／ObjectDB／resource 退出診斷及故障注入錯誤保留，不稱日誌零錯誤。

## 真實瀏覽器操作

IAB、滑鼠、獨立 localStorage namespace `dao2_islands_preview`；直接遊戲 CSS viewport 1280×720／844×390。fixture 由空白命令流程賺得 Era2，再以相同命令開拓／產線；沒有 Debug 資源注入。測試 launcher 是工具頁，其 iframe／故障條不是產品 UI。

1. 4198 桌面：世界青木島點擊 → 同一三島管理頁 → 預覽遷移／啟用 → 開拓兩島；玄礦持續銅精、玄礦→青木靈石、青木持續靈材、兩項加工物運回祖島。祖島顯示靈材／銅精可用及在途。
2. 實際 T2 升級：青木→玄礦運力10→20，青木加工坊1→2／每批10→5秒；成功訊息已保存。见 [T2升級](artifacts/res1-c2-web-t2-upgrade.jpg)。CLI/C1 規則試驗提供精確消耗／吞吐證據，不能只由畫面猜扣量。
3. 844×390：重載開拓／產線保留，摘要固定關閉、世界切島、常駐島名／返回祖島、礦坑熔爐與林場分開；根據實際有效 viewport 調整遠島取景。见 [短摘要](artifacts/res1-c2-web-summary-short.jpg)、[玄礦最終取景](artifacts/res1-c2-web-ore-short-final.jpg)。高DPR／實體觸控未驗。桌面再查加工坊二階／每批5秒、航線運力20仍保留，见 [升級重載](artifacts/res1-c2-web-t2-reload.jpg)。
4. 4200：48h雙鏈候選分批畫面更新，见 [進度](artifacts/res1-c2-web-offline-progress.jpg)。此案例收益計畫86400 ticks，但壽元提前停止，**不宣稱實際執行滿86400秒或Web FPS/p95達標**。
5. 4201：對隔離 namespace 注入寫入拒絕；完成計算後 `SAVE_FAILED / SecurityError` 顯示保留原檔。實際點恢復儲存及原生重新載入／重試後，摘要為實際離開177824秒、有效86400秒、上限是、壽元耗盡。见 [拒寫](artifacts/res1-c2-web-offline-save-failed.jpg)、[成功重試](artifacts/res1-c2-web-offline-retry-cap.jpg)。再次直接重載只結算11秒，上限否，壽元仍200年，见 [再重載](artifacts/res1-c2-web-offline-reload.jpg)。CLI 另驗資源／工作／貨物／游標同快照和不重扣。
6. 4199 首次不一致 checksum 拒載仍保留，[拒絕畫面](artifacts/res1-c2-web-offline-rejected.jpg)，沒有清除其測試存檔來假装通過。修正後改新4200/4201 origin驗證。

觀察正常成功流程的 warn/error 為空；故障和舊fixture拒載的代碼按實際記錄保留。既有 B 的真實quota／雙分頁／schema2矩陣不由本輪重新推定為所有裝置通過；本輪新 async 路徑做的是隔離拒寫／重試／重載。

## 修改與後續

新增 FrameBudget、IslandWorld、四個SVG及manifest、兩個C2 Runner（Godot uid保留）、fixture diagnostic；修改 OfflineCoordinator、living_abode、SaveCodec／Manager、FeatureNavigation、IslandManagementPanel、OfflineSummary／ModalManager、preview server及固定Runner入口。相關文件／英文checkpoint同步。現有C1與其他未提交變更保留，沒有commit／push／部署。

**尚未放行**：候選美術與節奏、指定實體手機／觸控／高DPR、自然OS背景凍結、跨瀏覽器、完整Web p95／冷啟動／長期記憶體；新增async的quota／索引中斷／多分頁全面重跑未由拒寫案例推定完成。正式ContentLoader保持未附掛，RES1-C/C2完整DoD保留IN_PROGRESS。下一仍為 **RES1-C2 驗收收尾**，不進RES1-D。依AGENTS Context Guard，本階段成果交接至 `updata.txt` 頂部，後續大型工作使用New Chat。
