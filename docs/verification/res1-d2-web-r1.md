# RES1-D2-R1：Web 保存矩陣與正常操作追加驗收

2026-10-05（Asia/Taipei）。**桌面 Web 保存矩陣子階段通過；完整 D2-R1／D2／D、C／C2／R2 仍 IN_PROGRESS。** R2 交 AGY。既有丹霞世界／分層美術證據保留於 [D2-R1](res1-d2-r1.md)。

## 結果與證據邊界

IAB 實際執行 Godot WebAssembly、正式 GameSession／SaveManager／WebStorageAdapter／OfflineCoordinator，16 份報告共 **400 checks PASS**。其中空白自動命令流程 220＋重載 4，其餘 D2 真實瀏覽器保存矩陣 **176 checks**。原生與 Web 使用同一份 [D2 契約](../../src/verification/res1d2_contract.gd)，沒有把 CLI 已賺得的存檔冒稱瀏覽器空白流程。

**空白流程是自動命令、正常內容與加速模擬秒，不是正常畫面完整滑鼠試玩。** 215 個共用契約也含 MemoryAdapter 診斷分支；400 不能解讀為 400 項全是真實保存故障。空白主線不賦值境界、修煉、庫存或建築，不用 Debug，透過採集／建設／正常晉階與加工命令，到金丹十層需 11561 模擬秒；在瀏覽器以真實 localStorage 保存終態，實際重載比對完整狀態且同游標零重複收益。人工玩法、自然時間完整操作及裝置門檻保持待驗。

[原始報告](artifacts/res1-d2-web-browser.jsonl)、[稽核摘要／包 hash](artifacts/res1-d2-web-summary.json)、[首段畫面](artifacts/res1-d2-web-progress.jpg)。全部報告由頁面 MutationObserver POST 到只綁 loopback 的工具服務；頁面重整與雙分頁用瀏覽器工具實際執行，沒有直接呼叫頁面私有函式代替重整／輸入。

| 案例 | checks／結果 | 實際範圍 |
| --- | --- | --- |
| d2progress | 220＋4 PASS | 空白正常命令到金丹十層；真實保存／重載完整狀態；同游標零收益 |
| d2retry | 54 PASS | quota、SecurityError、readback、index、truncate 五種受控中斷；完整旧／新世代復原、一次結算、再重試零收益 |
| d2quota | 12 PASS | 真正填滿此測試 origin 的 localStorage 至 QuotaExceededError，拒絕提交、清除測試填充、重試狀態一致；非單純 mock quota |
| d2indexreload | 8＋8＋6 PASS | 索引拒寫後兩次真實 reload；完整候選、游標與工作／貨物／命令收據一致 |
| d2quotareload | 8＋8＋6 PASS | 受控 quota 拒寫後兩次真實 reload；保留原世代、重試一次結算、再次重載零收益 |
| d2denied | 12 PASS | 受控拒讀不同於 missing；拒絕覆寫原檔，恢复讀取後重試 |
| d2corrupt | 12 PASS | 一代損壞回另一代；兩代損壞阻止新檔覆寫 |
| d2migration | 19 PASS | C 診斷 clone 的 D2 歸檔拒寫／第二次 index（候選提交）拒寫；live C 不变、原始 archive bytes 保留、重試完整產業一致與禁止重复启用 |
| d2lock | 9＋8＋6 PASS | 真實兩分頁，secondary 不改 slot／index／游標；關閉 owner 後 secondary 實際 reload 接管，同游標不重給 |

除空白主線外，保存矩陣使用原生空白命令流程產生的 [active fixture](artifacts/res1-d2-active-fixture.json)：金丹、丹霞正在加工多批丹液、liquid_home 成品在途；不是只有閒置原料的 C2 舊檔。遷移與破壞分支是明示診斷 clone，排除可達性證據。斷電／OS crash／自然背景凍結不在這組受控中斷證據內。

## 正常 Web 滑鼠追加驗收與修復

獨立 **4258／dao2_saves** 沒有按 Seed：正常新檔 → 實際採集 → 茅屋一階 → 二階 → reload → 保留二階 → 844×390 修為晉階至練氣二層。這是開局操作範圍，不是完整築基／金丹滑鼠通關。[茅屋二階](artifacts/res1-d2-web-fresh-hut2.jpg)、[重開後短橫式／練氣二層](artifacts/res1-d2-web-fresh-compact.jpg)。

獨立 **4259／dao2_saves** 只種一次原生命令取得的金丹二層檔，矩陣使用不同 dao2_matrix_d2* namespace。正常丹霞世界 → 管理 → 拒寫 → 點丹液一批 → Godot 暫停／保存阻擋。拒寫時再點重試仍阻擋；恢復儲存 → 點 Godot 重試 → 原工作继续、祖島丹液 1 可見，沒有再次按製作。原包保留失敗提示的 [修前畫面](artifacts/res1-d2-web-live-recovered-before-fix.jpg) 是发现問題的證據，不冒稱最終包。

**修復：** 背景／故障結算成功後，丹霞管理頁原本仍顯示「操作未保存」，會誤導玩家再做一次。現在只有保存失敗訊息被更新為「保存已恢復，進度已存妥」；不足原料等規則拒絕保留。沒有改命令、扣料、保存 schema 或時間演算法。修正版同進度重載再做拒寫／恢復，恢復訊息正確且console記錄WEB_BACKGROUND_SETTLED。[最終恢復畫面](artifacts/res1-d2-web-live-recovered-final.jpg)拍攝時加工已閒置、預留為0，因此只作訊息恢復證據；加工延續的前次操作與保存矩陣證據分開保留。

本輪實測父 viewport **1280×720、DPR 1.25**，桌面 iframe **1280×650**。曾要求 override 1280×790，但未生效，不稱 1280×720 畫布通過。短橫式實測 **844×390**，Godot 內部捲動能到加工控制、固定關閉與四主導航保留。[尺寸](artifacts/res1-d2-web-viewport.json)、[最終短橫式](artifacts/res1-d2-web-live-compact-final.jpg)。前輪 1280×720.4 證據保留原日期；這不是手機觸控、DPR2／3 或 FPS 驗收。

## 命令與結果

使用既有 Godot **4.7.2.stable.official.ed1daf0bf**、Compatibility、同版單執行緒 Web 模板，未更新環境。

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1d2_integration_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/res1-d2-web-native.log
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
New-Item -ItemType Directory -Force build/res1d2-web,build/res1d2-web-live
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release WebPersistenceTest .\build\res1d2-web\index.html
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web .\build\res1d2-web-live\index.html
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/prepare_web_compression.mjs build/res1d2-web-live
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2_web_server.py --port 4259
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2_web_audit.py
git diff --check
```

版本／獨立原生 **215 checks／exit0**；全量初輪及提示修正後最終各 **53/53／exit0**，最終含 **管理89、D2 215、丹霞world38**。[native](artifacts/res1-d2-web-native.log)、[all-final](artifacts/res1-d2-web-all-final.log)。Web probe 最終匯出、正常修正版匯出及音樂／Brotli companions 各 exit0，[probe export](artifacts/res1-d2-web-export-final.log)、[normal export](artifacts/res1-d2-web-live-export.log)、[compression](artifacts/res1-d2-web-live-compression.log)。壓縮檔只是準備產物，本HTTP服務沒有以此新驗下載／ready 預算。

audit **exit0**：九案例／16份／400checks皆PASS、正常新包排除全部 verification／tests 與 reference 圖，測試包含共用契約；原 web／res1d2／res1d2r1 hash 全部不變。最終 normal PCK `0cf078752939ee22e803323935a8ae6d50d1582b33847c43cacf58d84a971890`，probe PCK `f0290bcaf3d20f974eb445c95fb1d53631a198f80ea7a3c0563f6d035813c95e`。[audit](artifacts/res1-d2-web-audit.log)。Probe 包早於最後提示修正，正常包是提示修正版；兩包只各自對應上述範圍，沒有冒稱同一PCK。

保留失敗／限制：4258 首 sandbox 服務瀏覽器連線逾時，停止該程序 exit1，授權 loopback 同命令可用；錯誤分頁導航／關閉曾遭 URL policy 阻擋，換新分頁後取得可用證據。首 import exit0 但報 user:// 拒寫與歷史 JPEG-bytes／.png 擴展名證據圖匯入失敗，相關 docs 圖不進正常包；未改其舊圖或手改 .godot。初 probe export 因目錄未建立 exit1，建立後 exit0。一次 Python讀fixture 未指定 UTF-8、cp950 解碼失败，UTF-8重讀通過。原生負面損壞 JSON 與既有 Font／RID／ObjectDB shutdown 診斷保留，不稱整輪零error。工具服務本輪重啟的 exit1 是主動 Ctrl+C，不作驗收失败。沒有自動審查拒絕。

## 修改與接續

新增 `src/verification/res1d2_contract.gd`＋引擎 UID、兩個 Web 工具、active fixture／驗收／artifacts。原 D2 integration runner 成為共用契約的原生入口；web_persistence_probe 加 D2 路由、空白流程與 C→D2 真實保存診斷，既有 C2 case 保留。提示修復僅 island_management_panel、living_abode 兩行接線、C1 UI兩項驗證。同步 README／ROADMAP／ai-handoff／development-status／D2-R1 入口與英文 updata。沒有 TimeAdvancer／R2工具、規則版本、schema或圖形資產變更；原玩家origin與既有dirty保留，無commit／push／部署。七份UTF-8交接檔、25個本地連結、UID及JPEG簽章檢查PASS，最後diff check exit0／CRLF提醒：[文件檢查](artifacts/res1-d2-web-doc-check.log)、[diff check](artifacts/res1-d2-web-diff-check.log)。

4258 正常新檔及 4259 金丹試玩檔保留，頁面停 launcher 釋放遊戲 writer／GPU，override 已 reset。4259 [正常試玩](http://127.0.0.1:4259/launcher) 按「開啟隔離遊戲」，**勿再 Seed**；[矩陣入口](http://127.0.0.1:4259/?case=d2progress) 既有 progress 會走重載分支，重跑空白流程須使用新的測試origin，不能刪改玩家存檔。服務重啟用上列命令；4258 用 `tools/res1d2r1_preview_server.py --port 4258`，它仍服務原D2-R1包。

**下一仍 D2-R1：** 正常畫面自然時間完整空白T1→築基／靈池→金丹→丹霞／T3／修行、人類擴產／運力／加工／修行取捨及美術；實體手機／DPR2–3／跨瀏覽器／自然凍結／長期GPU-WASM与C/R2放行。已通過的D2保存矩陣不再列為未開始。依 [AGENTS](../../AGENTS.md)「單一 Session 完成當前階段任務（測試與驗收通過）」完成此有界Web保存子階段，checkpoint追加updata頂部，使用New Chat接續；不跳Era4或大型島群。
