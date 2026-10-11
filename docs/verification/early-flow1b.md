# EARLY-FLOW1-B：練氣至首次築基

日期：2026-10-10。**EARLY-FLOW1-B DONE（本段CLI／桌面Web／三橫式範圍）**；EARLY-FLOW1整體IN_PROGRESS。

## 核定範圍與實作

依使用者「核定順序後接EARLY-FLOW1-B」，本段採 Q1 五段建築鏈 → Q2 可選聚靈丹說明 → Q3 練氣十層／實際容量達標／首次築基。Q2與Q3同時可選，不用「曾服丹」阻擋主線，也不新增永久略過偏好。後續F1–G4維持分段範圍，這輪不展開C。

- `src/simulation/onboarding.gd`：以目前當世狀態、Era定義及已算好的View容量產生唯讀`early_guidance`；不複製經濟公式、不發指令。高境界或缺Era定義返回空資料。既有`next_objective`建築契約保留。
- `src/application/game_session.gd`：View附帶新目標，沒有新增保存欄位、schema或rules版本。
- `src/presentation/abode_hud_controller.gd`：建築鏈後延續目標、閱讀區固定44px「前往目標／可選：煉丹」；容量不足直達聚靈壇詳情，修行目標返回洞府現有晉階／突破控制；重開閱讀區讀最新狀態。首次築基未啟用產業時，標頭短目標直接開空島頁，避免世界控制列收起閱讀區使交接入口無效。容量與庫存、丹藥可選、先晉階避免浪費均有文字；穩定提示key避免每秒覆写命令反饋。
- `src/simulation/alchemy_system.gd`：築基丹描述澄清「當世產率＋10%，不是築基必需品」，沒有改成本或效果。
- `tests/early_flow1b_runner.gd`／`.uid`、`tools/run_all_runners.ps1`：新增正式附掛內容的空白正常命令、無丹藥築基、可選煉製／服用、View重載、拒寫／重試／重送、壽盡輪迴、UI路由／三尺寸幾何／旋轉／收起重開。
- `tests/m2d_responsive_ui_runner.gd`：舊「建築完成後移除所有目標」斷言改為延續修行目標。
- `assets/fonts/runtime/`兩衍生字型與manifest：依新文字重新生成，原字型與授權保留。

## 命令與结果

| 命令／工具 | 結果 |
| --- | --- |
| PowerShell `Get-Content`／`rg`／`git status`與diff | 核對入口文件、架構、docs07／08、真實來源及開工前變更；幾次探索使用不存在路徑／Windows glob失敗後改讀實際檔案，未改來源專案 |
| Godot 4.7.2 `--version` | exit0，`4.7.2.stable.official.ed1daf0bf` |
| `--headless --path . --import` | exit0，但既有UI1-R6證據PNG import有錯誤，保留日誌；不能稱import零診斷 |
| `--headless --path . --script res://tests/early_flow1b_runner.gd`（絕對log路徑） | 最終110 checks、exit0；無贈料／直接設定層級，原速率逐秒模擬等待1010秒；不是wall-clock證據 |
| `tools/run_all_runners.ps1` | 最終57/57、exit0；[全量日誌](artifacts/early-flow1b/regression.log) |
| bundled Python `tools/subset_game_fonts.py`，其後`--check` | 生成及覆蓋／hash檢查exit0；[生成紀錄](artifacts/early-flow1b/fonts.log) |
| Godot `--headless --path . --export-release Web E:/WORK/Dao2/build/web/index.html` | 重試exit0，[匯出](artifacts/early-flow1b/export.log) |
| bundled Node `tools/prepare_web_compression.mjs build/web` | exit0，壓縮／四首音樂companions完成；[紀錄](artifacts/early-flow1b/compression.log) |
| bundled Python `tools/island_preview_server.py --port 48173 --normal-build --gzip` | 新origin正常版服務，真實瀏覽器可連線；未載入fixture |

首次專項漏保存API參數導致parse失敗；第二輪錯用正式content不存在的`rebirth_lotus`，Runner中斷後改走正常壽盡輪迴，最終通過。首次全量被沙箱`user://`寫入拒絕阻擋，使用專案已授權隔離測試的工具升權重跑；其後全量發現Era4測試沒有Era定義、`early_guidance`不可接Nil，補防護後57/57。首次Web export字型import時引擎崩潰（exit -1073741819），正常授權重試成功。首次本機服務受沙箱網路阻擋；正常授權啟動成功。4291發現已有隔離歷史進度，保留後換48173新origin。末輪壓縮曾在export程序返回session後過早開始，已在確認export exit0後重新壓縮並重啟服務，該中間包不作驗收。

正向Runner仍有Font／CanvasItem／ObjectDB退出診斷，全量包含預期corrupt JSON等負面資料錯誤。程序exit0與日誌零錯誤不同。[108项UI追加歷史](artifacts/early-flow1b/core-ui.log)；最終110項在全量日誌第2003行附近。正常匯出及最後壓縮順序均確認exit0後才重啟服務。

## Web證據與剩餘界線

本輪使用CUA真實滑鼠，48173正常Web新檔，沒有seed／Debug／贈料／加速模擬。1280×720建築鏈、聚靈壇、目標路由、聚靈丹煉製／服用、練氣十層→首次築基及保存成功已驗；844×390煉丹內部捲動／服用／返回主線、800×360目標操作與360×640旋轉提示／恢復已驗。[800×360](artifacts/early-flow1b/web-800.jpg)、[十層庫存未滿也可突破](artifacts/early-flow1b/web-ready-1280.jpg)、[首次築基](artifacts/early-flow1b/web-foundation-1280.jpg)。九層時原分頁從工具session消失，重開同origin、44秒正常離線後保留九層及丹藥結果；沒有重設或再seed。築基後最終包真實重載保留Era2 Lv1；[桌面短目標實際開空島頁](artifacts/early-flow1b/web-handoff-final.jpg)、[844×390交接頁](artifacts/early-flow1b/web-handoff-844.jpg)、[800×360內部捲動可找到啟用](artifacts/early-flow1b/web-handoff-800.jpg)通過。短橫式維持精簡HUD，後續空島入口也可沿經營→空島進入；本輪沒有按啟用或開拓，F1–F4仍留C。最後browser warn/error查詢空，只涵蓋工具所保留的該分頁日誌，不代替前期Runner退出診斷。

自然等待紀錄：Q1建築链結束時壽元約77/80祀（約3分鐘），首顆聚靈丹服用／練氣三層時約76/80祀（約4分鐘），首次築基前約67/80祀（約13分鐘）。以上由HUD整數取樣估算，不是精確分段計時；本路徑共正常服用10顆聚靈丹，餘下等待來源是修煉條與正常靈力產線，材料不足使用規則允許的採集。首次築基前仍約67祀餘裕，進築基後上限200祀。server初始index請求約01:28:08、Era2音樂請求約01:40:58與此範圍一致，但包含載入與44秒離線，不當精確wall-clock通關報告。匯出字串已能在原生TextEdit顯示，瀏覽器clipboard讀回空字串，故未保存假空白存檔或宣稱取得精確JSON計時。

自然時間路徑可以使用正常聚靈丹；無丹藥正常規則路径由專項的1010秒逐秒模擬另證。這不代表一般玩家只等17分鐘或人類已接受節奏，實際操作停留、建造與丹藥都會改變總耗時。實機觸控／高DPR、直式提示偏小及原UI1-C／C／D待驗仍保留；本輪沒有重新量FPS或冷啟動。

收尾：只恢復開工前乾淨、被Runner刷新之三份fixture（res1-d2-earned-era3／res1-c2-offline-fixture／skills-b1-fixture），以唯讀HEAD原始bytes還原；移除本輪產生的八份UI1-R6證據import sidecar，原PNG不動。字型import sidecar若僅換行改寫，恢復原始bytes；保留新Runner UID及全部開工前文件變更。`git diff --check`通過，UTF-8／本地連結檢查另留document-check紀錄。服務48173保留作隔離試玩，其餘本輪服務以Ctrl+C停止，exit1屬主動終止。

已依Context Guard完成英文checkpoint與development-status。下一New Chat續EARLY-FLOW1-C（F1–F4真實雙島供給），不重做B、不跳金丹支線或Era4。
