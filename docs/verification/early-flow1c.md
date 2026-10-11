# EARLY-FLOW1-C：雙島供給驗收

日期：2026-10-10。**DONE（F1–F4 CLI／桌面 Web／三橫式有界範圍）**；EARLY-FLOW1 整體及原 UI1-C／C／D 保持 IN_PROGRESS。人類節奏接受、實機觸控／高 DPR 仍待驗。

## 範圍與結果

使用者指定「EARLY-FLOW1-C：雙島供給」。接續已交付 B，不重做練氣教學：啟用保存→兩島開拓→玄礦下品石實際到青木累計5→青木靈材與玄礦銅精真正完工→兩種產物各累計1真正到祖島。目標一次突出當前段；一階設施／航線即可，不要求升運力或技能／宗門，不贈料，不改成本／工時／解鎖資格。

`onboarding.gd` 提供 F1–F4 文字及目的路由。F1列尚未開拓島、祖島費用；F2說明設定／出發不算到貨、保留／目標／來源／滿倉原因並直達 `ore_wood`；F3列仍未完工的地方配方；F4列仍未到貨的產物並直達首條缺少回運航線。加工頁與運輸頁沿用既有 Godot 容器、地方材料、狀態／倒數、內部捲動與固定返回。短橫式沿既有經營分頁操作，不新增常駐長清單。

## 有界保存契約（v2 metadata）

schema 3／既有 rules 版本保持，新增選填 `state.economy.early_supply`，內部 `version=1`，固定六欄：version、ore_delivered（0–5）、timber_done／bronze_done（bool）、timber_home／bronze_home（0–1）。到貨數量有界累計，支援分次小數貨物；飽和後不繼續增大。首次正常啟用建立；只有規則 `_put` 實際到貨／完工成功後記錄，與貨物／工作共用快照。設定、出發、工作啟動、看頁面、演出與重試均不記完成／不發獎。

材料用掉後不倒退；拒寫保留已生效的 live state，重試只保存；非法版本／欄位／數量在 encode／decode 共用 IslandEconomy.validate 拒絕，SaveSlots 可退回另一有效世代。缺欄位的既有產業檔不補造歷史、不強迫再製造或回運；雙島開拓後只給可選說明。舊三島升版仍保留原歷史缺欄位行為；高境界不退回本段。輪迴清除已完成紀錄，已有本契約者初始化新世空紀錄，未有者保持缺欄位；不新增跨世「已介紹」偏好。這是展示歷史 metadata 的 v2 擴充，沒有宣稱 Amount 或舊版全量相容。

## 修改檔案

- `src/simulation/onboarding.gd`：目標／有界紀錄與驗證。
- `src/simulation/island_progression.gd`：首次啟用建立紀錄。
- `src/simulation/island_economy.gd`：真實完工／到貨紀錄、保存驗證。
- `src/simulation/reincarnation_rules.gd`：新世初始化。
- `src/presentation/abode_hud_controller.gd`：目標直達運輸／製造、築基標題、同路由不同完成文字刷新。
- `tests/early_flow1c_runner.gd`／Godot `.uid`、`tools/run_all_runners.ps1`：供給專項與固定回歸入口。
- `assets/fonts/runtime/`兩衍生字型及 manifest：新文字覆蓋；原字型／授權不變。
- 本驗收、docs17、README／ROADMAP／handoff／development-status／updata：結果與下一段。

## 命令與證據

| 工具／命令 | 結果 |
| --- | --- |
| PowerShell Get-Content／rg／git status／diff | 核對交接、Roadmap、架構、docs07／08、開工 dirty；保留上一段修改。幾次 Windows glob 搜索失敗後改讀實際檔案 |
| Godot `--version` | exit0，4.7.2.stable.official.ed1daf0bf |
| `powershell -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | **58/58 exit0**，當輪C96；[全量](artifacts/early-flow1c/regression.log) |
| Godot `--headless --path . --script res://tests/early_flow1c_runner.gd`（隔離 user://） | 最後追加 **104 checks exit0**，[專項](artifacts/early-flow1c/core-final.log)；新檔正常命令、F1部分開島重載、來源／保留／目標／滿倉、部分小數到貨、工作未完／真正完工、材料花掉、保存拒寫／重試／非法欄位／兩世代復原、分段重載、較高境界與輪迴、三尺寸UI路由 |
| bundled Python `tools/subset_game_fonts.py`，其後 `--check` | exit0，1826 codepoints覆蓋／hash檢查；[生成](artifacts/early-flow1c/fonts.log) |
| Godot `--headless --path . --export-release Web E:/WORK/Dao2/build/web/index.html` | exit0，[匯出](artifacts/early-flow1c/export.log) |
| bundled Node `tools/prepare_web_compression.mjs build/web` | exit0，Brotli／gzip與四首BGM companions；[壓縮](artifacts/early-flow1c/compression.log) |
| bundled Python `tools/island_preview_server.py --port 48174 --normal-build --gzip --fixture early-flow1c-unopened.json` | 正常版新隔離origin可連線；fixture由本輪正常命令築基產生，UTC重新封裝，不是完整Web新檔練氣通關 |
| CUA真實滑鼠／DOM尺寸／重載 | 1280×720啟用、兩島開拓、送料、兩配方各單批、靈材回運；844×390篩選／內捲／銅精啟航；800×360目的銅精1與返回；360×640提示／恢復；真實重載保留完成目標。最後warn/error查詢空 |

正向Runner保留既有Font／CanvasItem／ObjectDB退出診斷；負面紀錄 `SAVE_SLOT_REJECTED: ECONOMY_EARLY_SUPPLY` 為預期故障驗證，exit0不等於日誌零錯誤。最早沙箱B回歸因user://拒写而UI未啟動，雖exit0有SCRIPT ERROR，不作通過證據；正常授權全量B110/C96通過。早期C測試型別宣告、錯場景路徑及錯估升階成本失敗，修復後正常命令再賺第二對產物支付2＋2；輪迴本來保留產業啟用，改新世空紀錄。追加分段比較的失敗診斷證明差異只有 `5.0`／`5`，最後改Codec既有數字正規化後104通過，不修改規則；[診斷](artifacts/early-flow1c/chunk-diagnostic.log)。新增文字最初font check缺四字後重新生成通過。沒有auto-review拒絕。

## 真實 Web 與限制

48173試圖接B進度時另一分頁持有保存鎖，列出的可操作分頁無owner；保留锁保護，關閉本輪受阻分頁，改新48174。只在新origin載入一次正常命令取得的未啟用築基fixture；所有雙島步驟由滑鼠／自然時間完成，沒有Debug、贈料或加速。這不代替從練氣新檔的整段自然通關（B已有獨立證據）。

兩島一階、10秒工作／10秒航程實際運作，主線沒有強迫升級。雙島來源／目的ICON可見真實庫存，送料滿倉後顯示目的倉滿；首批回運後來源無餘貨、目的銅精1。成功收據暫時會推移桌面卡片，實際核對畫面後重新命中；這是既有介面行为，未把誤點當成功。最後兩產物回祖島後顯示「雙島供給已接通」，重載只按Play、沒有再seed，仍保留該目標。

- [真正完工後F4](artifacts/early-flow1c/web-f4.jpg)
- [844銅精啟航](artifacts/early-flow1c/web-bronze-844.jpg)
- [800銅精到貨](artifacts/early-flow1c/web-arrived-800.jpg)
- [雙島完成](artifacts/early-flow1c/web-complete-1280.jpg)
- [真實重載完成目標](artifacts/early-flow1c/web-reload-complete.jpg)

DOM實測iframe844×390與800×360，桌面使用1280×720測試控制；均為桌面瀏覽器，非實體手機。自然耗時以HUD取樣：開始開拓約182/200祀、完成回運約178/200祀，約4分鐘（含查看、誤點後核對與換版型），不是精確秒表／一般玩家節奏承諾；等待只來自地方採集、10秒加工與10秒在途。重載後約177/200祀，壽元有餘裕。

實機觸控／高DPR、人類接受、完整UI1-C／C／D與既有直式提示偏小保持待驗。沒有重做已通過FPS／400保存矩陣；冷啟動依使用者最新政策暫緩。新增欄位真實Web正常重載已驗，故障／損壞復原在本輪隔離Adapter專項；未冒稱本輪另驗真實Web quota／IndexedDB／跨瀏覽器。

收尾只恢復開工前乾淨的四份被Runner刷新之歷史fixture（res1-c2-offline、res1-d2-active、res1-d2-earned-era3、skills-b1），以HEAD原始bytes還原；移除本輪生成的八份UI1-R6舊證據PNG.import，原圖保留。保留本輪UID與新供給fixture。原dirty成果未還原，未commit／push／同步Windows。48174服務停止後可依上表命令重開，只按Play沿用既有完成進度，不重覆seed。

最終13檔嚴格UTF-8、20個本輪文件連結與 `git diff --check` 通過；行尾CRLF提示不是diff錯誤。CUA驗收分頁已關閉、viewport override已reset。48174以Ctrl+C停止，exit1為主動終止；server有favicon404，遊戲資產請求正常，未操作開工前其他服務。

依Context Guard把英文checkpoint置於updata頂部。**下一New Chat：EARLY-FLOW1-D，F5–G4可延後技能／宗門、金丹首升級與靈狐首次餵食**；不在本輪展開。
