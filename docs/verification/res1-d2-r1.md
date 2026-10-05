# RES1-D2-R1：丹霞分層世界與双向入口

2026-10-05後續 [Web保存子階段](res1-d2-web-r1.md)已通過：最終53/53／world38／管理89、九案例16份報告400 checks；自動正常空白流程為模擬秒，完整自然時間滑鼠流程仍待驗。保存恢復提示已修正，正常新包另存build/res1d2-web-live；本文件與原res1d2r1包保持世界子階段歷史。完整D2-R1仍IN_PROGRESS。

2026-10-05（Asia/Taipei）。**世界／美術與桌面 Web 子階段交付；D2-R1、D2及完整D仍 IN_PROGRESS。** R2仍由AGY負責。前輪規則、容量及保存契約見[D2](res1-d2.md)／[ADR-011](../decisions/ADR-011-era3-capacity-and-skill-gates.md)，本輪不改方案或保存版本。

## 交付範圍

丹霞採赤色砂岩、低草地與泉池的獨立島體；藥草栽培床、晾草架與丹液提煉工坊作一個獨立複合地標。內建image_gen生成兩張runtime PNG與一張規劃參考，每張1536×1024、真實RGBA透明；三份手寫提示詞、來源／授權邊界、hash、圖層與地基／命中資料在[manifest](../../assets/abode/res1d2/manifest.json)。沒有裁參考圖當runtime、沒有借用其他島的地標、沒有聲稱人類審美已放行。

Godot `IslandWorld` 新增herb位置(0,-1550)。築基可查看丹霞／「金丹解鎖」條件；金丹已啟用D2但未開拓顯空地，開拓後才顯藥坊。點島面／管理此島進canonical outposts/herb；管理頁「前往此島世界」回同一島，返回祖島沿既有路徑。丹霞三條草／百年草／丹液航線，只從真實economy.trips畫在途貨物；動畫不發收益。

四島控制列依左HUD、紙面內距與導航實際範圍計算寬度／底部安全距離，採HFlowContainer換行。Banner短橫式仍單行；全部控制可見，不靠瀏覽器捲軸。遠島縮小鏡頭隱藏原祖島／山域遠景題字，返回祖島恢復，避免「天外仍有天地」覆蓋丹霞。資源清單refresh補回HUD已傳入的第四個延後刷新參數，保留導航合併共享資源後再刷卡片的原有接線。

## 命令與結果

使用既有Godot `4.7.2.stable.official.ed1daf0bf` 與同版單執行緒Web模板。未更新環境，未手改.godot或匯出HTML。

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2_asset_audit.py
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1d2_world_runner.gd
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1c2_world_runner.gd
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/m2d_responsive_ui_runner.gd
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1c_progression_runner.gd
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web .\build\res1d2r1\index.html
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2r1_pack_audit.py
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2r1_preview_server.py --port 4257
git diff --check
```

- 資產audit：3張RGBA／3提示詞／hash及placement PASS；import exit0。
- 固定入口新增Danxia世界runner，首輪及題字修正後最終全量均**53/53 PASS、exit0**，包含D2 **215 checks**及C1 **87 checks**，[all-runners](artifacts/res1-d2-r1-all-runners.log)／[all-final](artifacts/res1-d2-r1-all-final.log)。後者world37；管理頁最後雙向入口補接另由下列125 checks驗證，沒有把較早全量冒稱又在這一行改動後重跑一次。
- 最後Danxia世界**38 checks PASS／exit0**，[world-release](artifacts/res1-d2-r1-world-release.log)：開拓前後／Era1隱藏與Era2條件／canonical及reverse路由／50切島完整規則快照不變、907節點不增加／1280×720、844×390、640×360的屋頂、44px控制、導航避讓／resize／遠景題字復原。
- 原三島世界**26 checks PASS／exit0**，[c3-world](artifacts/res1-d2-r1-c3-world.log)；響應式runner exit0，[responsive-final](artifacts/res1-d2-r1-responsive-final.log)；管理頁最後補接後C1 **87 checks PASS／exit0**，[management-release](artifacts/res1-d2-r1-management-release.log)。
- 獨立Web匯出exit0；初版／題字修正後／雙向入口最終包各留export日誌。音樂companions從原build/web/audio複製到獨立目錄。PCK原始目錄檢查兩runtime層存在，所有dressed_reference均排除；原build/web與前輪build/res1d2 hash不變，見[pack JSON](artifacts/res1-d2-r1-pack.json)。PCK目錄／byte數不是新FPS、下載或啟動驗收。

保留失敗：第一次沙箱user://保存拒絕，啟動SAVE_FAILED後Nil，停止本輪程序exit1；按AGENTS授權重跑隔離user://。首授權跑暴露既有BuildingCatalog refresh参数不相容，已最小修正；測試曾錯用GameState.clone，改duplicate_state。初版四島控制超寬／碰導航，內距與HFlowContainer修正後35 checks通過。新增題字測試用_process(0)仍讀真實經過時間，改用diagnostic clone，原可達fixture不被改寫，最終38通過。早期日志保留；既有Font／CanvasItem RID、ObjectDB／resource shutdown診斷仍在，不聲稱零錯誤退出日志。沒有自動審查拒絕或待使用者放行的命令。

## 真實瀏覽器與證據邊界

IAB、独立 `http://127.0.0.1:4257/launcher`、正常Web namespace dao2_saves。只在此新origin用UI種一次CLI命令取得的Era3Lv2檔；已有進度工具拒覆寫。原4256／其他origin玩家資料未讀改。**這是命令取得fixture的世界驗收，不是從瀏覽器空白完整玩到金丹。**

桌面父viewport1280×790、iframe實測**1280×720.400024 CSS px**、DPR約1；短橫式iframe**844×390 CSS px**。實際滑鼠：關摘要→丹霞按鈕→獨立赤岩島／藥坊→點島面進丹霞管理→持續丹液加工「操作完成，已保存」、低草100→95／產品預留1→真實重載離線摘要73秒、丹霞開拓與工作延續。持續加工可消耗共用靈力至不足並等待供給；本輪觀察不構成人類節奏放行。短横式管理使用Godot內部捲動，固定關閉保留；實際「本批完成後停止」顯示「操作完成，已保存」，下一重載51秒後「尚未加工」。最終包管理此島→丹霞「前往此島世界」實際返回丹霞，在島上直接resize，四島控制換行、題字遮擋消失。

[桌面世界](artifacts/res1-d2-r1-desktop.png)、[管理加工](artifacts/res1-d2-r1-management.png)、[短橫式題字修正](artifacts/res1-d2-r1-compact-final.png)、[停止保存](artifacts/res1-d2-r1-compact-stop.png)、[尺寸](artifacts/res1-d2-r1-viewport.json)。首兩張屬題字／雙向入口最後補接前的正常Web實際操作；不能混為同一PCK時間點。最終PCK `e8a549e394fb26e1cf973de9b85786cf94604a2bd2e794727f76ab760d5f1f84`（10669068 bytes）的[release桌面](artifacts/res1-d2-r1-release-desktop.png)、[release管理／停止後](artifacts/res1-d2-r1-release-management.png)、[release短橫式](artifacts/res1-d2-r1-release-compact.png)為最後畫面證據。[Console](artifacts/res1-d2-r1-console.json)是最終重載文件所捕獲warn/error空列，僅覆蓋該觀測範圍，不覆蓋前文件或CLI退出診斷。

最終短橫式「返回祖島」已以滑鼠驗到祖島與「祖業保留」，[返回畫面](artifacts/res1-d2-r1-release-home.png)。4257服務保留，頁面最後停launcher釋放遊戲writer／GPU負載，viewport override reset。已有隔離進度按「開啟隔離遊戲」，不要再次種檔。Web服務只綁127.0.0.1；可用上列server命令重啟。實際截圖Compose自兩獨立runtime層，作為分層QA，不以dressed reference充當世界。

交接文件UTF-8與309個本地Markdown連結檢查PASS／exit0，[doc-check](artifacts/res1-d2-r1-doc-check.log)；git diff --check exit0（CRLF提醒），[diff-final](artifacts/res1-d2-r1-diff-final.log)。

## 修改、待驗與接續

新增assets/abode/res1d2（兩runtime PNG、reference、三提示詞、manifest／引擎import）、asset／pack audit、独立server、Danxia世界runner與引擎.uid、驗收／ownership及artifacts。修改island_world、island_management_panel世界返回、living_abode遠景題字、building_catalog接口、export_presets排除參考圖、fixed runner；同步入口文件、docs07／08／15、status與英文updata。保存schema3／res1-d-2／core-flow-10-danxia不變；沒有TimeAdvancer／R2工具調整、commit／push或玩家檔操作。全量runner會重生既有測試artifacts，保留既有dirty。

剩餘：正常Web空白玩家完整T1→築基→金丹→丹霞／T3／修行首段；D2實際瀏覽器quota／保存中斷／重試／双分頁等矩陣；人工美術／擴產、運力、加工與修行取捨／平衡；實體手機觸控／高DPR／自然背景凍結／跨瀏覽器／長期GPU-WASM及相關C/R2放行。沒有新的FPS／IndexedDB或這些裝置證據。下一仍**D2-R1剩餘Web驗收**，不跳Era4或大型島群，R2仍交AGY。

按[AGENTS Context Guard](../../AGENTS.md)「單一 Session 完成當前階段任務（測試與驗收通過）」停止本世界子階段；英文checkpoint置updata頂部，下一大型Web矩陣與玩法工作使用New Chat。這項停止是明示專案交接要求，並非D2完整DoD已完成。
