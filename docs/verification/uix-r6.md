2026-10-17 **最新驗收範圍調整：R6桌面／Web有界DONE；實體觸控／高DPR實機延期**。使用者指定觸控與實機測試待專案完成度夠高才開始，後續任務暫不安排，也不作當前DoD阻擋。比例已接受，既有CLI／原生／桌面Web及長文驗收完成，此有界階段結案；實機不是已通過，而是延期。下方「僅剩實機所以IN_PROGRESS／下一New Chat只補實機」為政策調整前歷史，不再作目前安排。不開R7。本次僅文件更新，沒有新遊戲測試或規則改動。

# UIX-R6-ACHIEVEMENTS：功業冊

## 2026-10-17 R6比例接受／剩餘驗收（最新）

使用者明確回覆「維持目前比例」：桌面128px／短橫式最多112px、僅標題與獎勵及必要狀態的成就版面比例接受。**R6完整仍IN_PROGRESS**，實體觸控／DPR2或3仍待驗；本次不開始R7，未commit/push。

新增獨立 `R6Acceptance` Web preset、`run/main_scene.r6_acceptance` feature override 與 `src/verification/uix_r6_acceptance.gd/.tscn`。僅驗收版載入明示顯示fixture：準備真實茅屋成就資格，替換該卡長標題與三組大數獎勵文字；沿正式AchievementPanel、FeatureNavigation與Session領取／保存。正常Web排除src/verification，原Web包沒有重匯出，SHA256仍 `3BF1C3DE53FBB1B617BB0EA419438B913B3A02A554772D3B7B6D634C21A6B69F`。這是長文版面／實際命中驗收，**不是自然新檔或全量Amount／大數獎勵契約**；實際獎勵仍為靈木100。

IAB隔離origin `http://127.0.0.1:48769/index.html`：

- CSS 1280×720／844×390／800×360，桌面雙欄／短式單欄，長標題及21位數字獎勵完整換行，操作沒有被擠出；[桌面](artifacts/uix-r6/acceptance/web-1280-long.jpg)、[844](artifacts/uix-r6/acceptance/web-844-long.jpg)、[800](artifacts/uix-r6/acceptance/web-800-long.jpg)。844畫布依既有縮放使用約779×360 Godot邏輯尺寸，不混稱CSS像素。
- 800×360真實滑鼠點領取後顯示成功／已領取，fixture的只讀DOM report記錄 `claim_clicks=1`、`claimed=true`；固定成功訊息下圖像完整，長獎勵仍可讀。[領取後](artifacts/uix-r6/acceptance/web-800-claimed.jpg)、[幾何紀錄](artifacts/uix-r6/acceptance/web-claimed-layout.json)。沒有用函式直接觸發領取。
- 列表內捲後分類／關閉仍固定；滑鼠關閉回洞府，頂部實際靈木100。[內捲](artifacts/uix-r6/acceptance/web-800-scrolled.jpg)、[返回](artifacts/uix-r6/acceptance/web-return.jpg)。800的document尺寸800×360，無外部捲軸，DPR約1.000000015。viewport工具只支援寬高，不能以此宣稱高DPR或實體觸控通過。
- 最終重載後捕獲warn/error為空，見[瀏覽器日誌](artifacts/uix-r6/acceptance/browser-logs.json)。首跑fixture僅等一幀，Web尚在等待儲存鎖，產生null function並未完成驗收；改為等session／導覽建立後再準備fixture，最終重跑成功。首次也缺BGM companion；準備壓縮／音樂companions後重跑沒有該警告。初版export.log保留，不作成功Web證據。

儲存缺口更正：`src/persistence/web_storage_adapter.gd` 的 `backend_name()` 是 `web_localstorage`，實際read/write用localStorage並有lifetime Web Lock；`living_abode.gd`正式初始化選用此adapter。因此「IndexedDB直接觀察」**不是目前成就權威存檔的必要驗收**；引擎檔案系統的IndexedDB與本遊戲權威保存是不同路徑。下方歷史待驗保留日期，不再以此阻擋R6。F1隔離正常保存／拒寫／恢復／重載證據保持其原hash與範圍；本輪不重做整個保存矩陣。

命令（PowerShell；各引擎命令使用隔離 `APPDATA=build/uix-r6-acceptance-appdata`）：

- 固定引擎 `--version`：`4.7.2.stable.official.ed1daf0bf`，exit0。
- `--headless --path . --editor --import`：exit0，但import.log有既存歷史Web證據`.png`匯入錯誤，不能稱零錯誤；未改那些原始證據或正式資產。新增fixture無parse error。
- `--headless --path . --script res://tests/uix_r6_achievement_ui_runner.gd`：**221 checks、failed=false、exit0**，既有Font／CanvasItem／ObjectDB退出診斷仍在。
- `--headless --path . res://src/verification/uix_r6_acceptance.tscn --quit-after 180`：exit0，沒有SCRIPT ERROR，見native-fixture.log。
- `--headless --path . --export-release R6Acceptance build/r6-acceptance/index.html`、bundled Node `tools/prepare_web_compression.mjs build/r6-acceptance`：最終均exit0。驗收PCK SHA256 `249F753D3A147EEA3F0AA8034DD8E31470DBA9C4386BCB89162F5FC1C677B1FD`。log在[acceptance](artifacts/uix-r6/acceptance)。
- bundled Python `tools/web_static_server.py --port 48769 --directory build/r6-acceptance`：僅127.0.0.1，Web實際載入成功；收尾停止自己的服務／關閉分頁並重設viewport。未操作4306／4175或玩家origin。精確清除本輪匯入新生166份未追蹤證據`.import`，原始圖／JSON／所有`.uid`保留。

下一步僅補實體橫式手機的按鈕／分類橫捲／列表內捲／返回／旋轉與DPR2或3可讀性。無實體裝置控制面，本輪保持待驗，完整R6不標DONE。比例已接受，無須再詢問同一比例；依Context Guard在此交接，不開R7。

收尾：10份受影響文字嚴格UTF-8通過，`git diff --check` exit0（僅既有LF→CRLF提示）；服務Ctrl+C退出1為主動停止，非Web驗收失敗。英文checkpoint已置於updata.txt最頂部，狀態／Roadmap／handoff均同步。

## 2026-10-17 使用者美術回饋修訂（UIX-R6-F2，最新）

使用者指出圖像精緻，但遊戲ICON尺寸太小，要求精簡文字，只留下標題及獎勵並放大圖像。本輪沿此回饋修改`achievement_panel.gd`：移除Desc Label，卡片僅標題／獎勵及必要領取狀態／操作；徽章72→128px，短橫式最多112px（正常高度相對原72px增加約56%），桌面增加約78%。短橫式收起總覽行、分類列52→44px及間距縮小；當固定保存回饋占用高度時，依實際列表高度縮放圖像，保留完整輪廓。雙欄／單欄及原規則／命令／徽章資產不變。共用規範已同步19。

`tests/uix_r6_achievement_ui_runner.gd`最終 **221 checks、failed=false、exit0**，追加每卡只有兩個文字Label、大圖尺寸、短式總覽收斂與拒寫回饋下圖像完整可見。`tools/uix_r6_preview.gd`改將本版12張PNG輸出至獨立`artifacts/uix-r6/art-feedback`，舊版原生及Web證據保留，不混稱新排版；最終原生preview exit0，桌面、800正常／拒寫狀態均已目視核對。首版219 checks通過後追加拒寫圖像完整配適，以上221為最後版本。退出診斷保持。

新排版人工接受仍待使用者判定，使用者稱圖像精緻不等於已核定新尺寸／密度。下方F1為此修訂前的Web完整互動／故障驗收，最新排版Web複核結果於本節接續記錄。

最終接續結果：

- 收尾：12份受影響文字嚴格UTF-8及本頁本地連結檢查通過，`git diff --check` exit0（只有LF→CRLF提示）；清理本輪最後匯出再生121份未追蹤證據`.import`，未刪除原始證據或`.uid`。

- 四項呈現回歸`feature_navigation`／`m2d_responsive_ui`／`uix_r2_hud`／`uix_r1_components`皆exit0（`*-art-feedback.log`）；專項在最後分類resize可見性微修後再次221 checks／exit0（`ui-art-feedback-runner-final.log`）。最終Web匯出與壓縮exit0（`export-art-feedback-final.log`、`compression-art-feedback-final.log`），PCK SHA256 **`3BF1C3DE53FBB1B617BB0EA419438B913B3A02A554772D3B7B6D634C21A6B69F`**。中間大圖版`471C312E…`僅差分類resize後ensure_control_visible接線。
- IAB沿用`localhost:48768`隔離進度，無種檔／重置：正常頁重載仍有靈木100與已領1；1280×720雙欄、800×360單欄完整大圖，標題／獎勵與操作並列。實際滑鼠分類、末端分類自動橫捲、列表內捲至最後、844×390固定關閉恢復洞府均通過。最新hash再reload後，800↔844末項選中與1280返回營造分類已複核。[最終桌面](artifacts/uix-r6/art-feedback/web-final-1280-building.png)、[800營造](artifacts/uix-r6/art-feedback/web-800-building.png)、[800內捲](artifacts/uix-r6/art-feedback/web-800-scrolled.png)、[最終800末項](artifacts/uix-r6/art-feedback/web-final-800-selected.png)、[最終844末項](artifacts/uix-r6/art-feedback/web-final-844-selected.png)。
- 最終正常頁捕獲warn／error空（`art-feedback/web-final-logs.json`），CSS viewport844×390、DPR約1，document尺寸相同無外部捲軸。最終大圖版未再做新空白領取／Web故障全鏈，F1實際保存矩陣與221專項證據保持各自範圍；沒有宣稱高DPR／實體觸控通過。12張大圖原生含拒寫畫面已檢視，保存回饋下完整圖像配適通過。
- 本輪自己的48767／48768服務皆以Ctrl+C停止（exit1為主動停止），遊戲測試頁關閉、viewport override重設。最初逾時data-URL錯誤頁無法由工具重新取得（URL policy拒絕），未嘗試繞過，保持臨時未標記分頁。玩家origin保持。
- 來源改動為成就頁、living_abode保存恢復接線、成就Runner與preview；文件同步README／ROADMAP／handoff／status／19／20／updata。100份首次匯出新生證據PNG `.import`清理後，最後匯出再生之同類metadata與本輪art-feedback圖的metadata再精確清理，原始PNG／JSON與`.uid`保留。未commit/push。

## 2026-10-17 接續回饋／Web驗收更新（優先於下方較早紀錄）

**IN_PROGRESS：桌面Web有界功能驗收通過；人工美術／實體觸控／高DPR及長文大數Web仍待驗。** 本輪只接R6，不開始R7，未commit/push，未操作玩家4306／4175或清除進度。

實測發現並修復：Web領取後拒寫，使用全畫面保存遮罩的「重試保存」成功，成就頁仍殘留保存失敗訊息與重試鈕。`AchievementPanel.storage_recovered()`僅在有待保存錯誤時更新提示；`living_abode.gd`在一般保存成功與`_settle_web_background()`成功後通知成就頁，不重送領取、不覆蓋普通成功文案。修改這兩份來源與`tests/uix_r6_achievement_ui_runner.gd`；本輪沒有重生徽章、改規則／schema／獎勵。

### 真實瀏覽器證據

- IAB，CSS viewport 1280×720／844×390／800×360與360×640，DOM觀察DPR約1.000000015；三種橫式均無瀏覽器捲軸。由CUA實際滑鼠點擊與滾動，不用函式注入或fixture種檔。直式轉橫為尺寸模擬，不是實體裝置。
- 首次沙箱服務`python tools/web_static_server.py --port 48767 --directory build/web`有監聽但主機HTTP逾時，IAB仍`ERR_CONNECTION_TIMED_OUT`；主機層同命令重啟後成功。僅綁定127.0.0.1。這解除了前輪Web入口阻擋，未更動防火牆或瀏覽器設定。
- `127.0.0.1:48767/index.html`空白隔離origin：20次正常靈氣採集→點擊建造茅屋→修行→成就。仙家草廬領取後靈木0→100，已領1／待領0，分頁計數及Dock紅點清除；實際reload後庫存100與已領狀態保留。全部／六分類實際切換，列表內捲到後段、分類橫向捲動／末項自動帶入與固定關閉均通過。800與844關閉恢復洞府，重開成就頁可用。未達成按鈕點擊維持原狀。證據：[領取前](artifacts/uix-r6/web-1280-before-claim.png)、[領取後](artifacts/uix-r6/web-1280-claimed.png)、[庫存100](artifacts/uix-r6/web-wood100.png)、[重載](artifacts/uix-r6/web-reloaded-claimed.png)、[桌面內捲](artifacts/uix-r6/web-1280-scrolled.png)、[844營造](artifacts/uix-r6/web-844-building.png)、[844輪迴分類](artifacts/uix-r6/web-844-reincarnation.png)、[800內捲](artifacts/uix-r6/web-800-scrolled.png)。
- 360×640顯示旋轉遮罩；在遮罩下分類區點擊後，轉回844×390仍為成就／洞府營造。保留分類，未宣稱跨旋轉保留原列表捲動位置；直式提示偏小的既有裝置可讀性仍待驗。[遮罩](artifacts/uix-r6/web-360-portrait.png)、[轉橫恢復](artifacts/uix-r6/web-rotation-restored.png)。
- 使用既有`tools/island_preview_server.py --port 48768 --normal-build --gzip`的`/fault.html`測試工具，另一隔離origin正常採集／建屋後，按DOM「拒絕寫入」再實際領獎。Storage.prototype.setItem僅對本origin dao2_saves命名空間注入SecurityError，不是實際quota測試；全畫面遮罩阻擋後續操作，持續拒寫下重試不退出。修復前成功恢復仍有殘留提示，保存為[修復前證據](artifacts/uix-r6/web-stale-error-before-fix.png)。
- 最終匯出版於`localhost:48768/fault.html`新空白origin再走相同正常建屋／領獎流程。拒寫→重試失敗→DOM「恢復儲存」→全畫面「重試保存」成功，成就頁立即顯示「領取結果已保存」，沒有額外按成就頁重試。再導航同origin `/index.html`重載，庫存仍100、已領1／待領0且無紅點，沒有重發獎勵。[最終拒寫](artifacts/uix-r6/web-final-write-denied.png)、[最終恢復](artifacts/uix-r6/web-final-recovered.png)、[重載庫存100](artifacts/uix-r6/web-final-reload-wood100.png)、[重載已領](artifacts/uix-r6/web-final-reloaded-claimed.png)、[最終800](artifacts/uix-r6/web-final-800-building.png)。
- 正常頁`dev.logs(warn,error)`捕獲結果皆空，保存在`web-browser-logs.json`與`web-final-browser-logs.json`。故障頁明確有預期`WEB_BACKGROUND_SAVE_FAILED: SecurityError`與成功`WEB_BACKGROUND_SETTLED`，不宣稱故障注入零錯誤。儲存證據為實際正常Web重載與localStorage故障工具；本輪沒有IndexedDB直接觀察證據。
- 先前完整分類／旋轉矩陣使用原PCK `6BB418D5B634B60A7C3D8E180612DED57EA93CB34A023247382DDC406750958D`。修正只增保存恢復通知，不改版面；最終拒寫／恢復／重載及小橫式複核使用PCK `A1B3EBCE3EB296F2E45221788F221A6F5A08AD5C3657EF2A958D62F369172F32`。不混稱全部證據為同一hash。

### 本輪命令與結果

- 引擎`--version`為`4.7.2.stable.official.ed1daf0bf`，exit0。
- 隔離`APPDATA=build/uix-r6-tests`，引擎`--headless --path . --script res://tests/uix_r6_achievement_ui_runner.gd`最終 **195 checks、failed=false、exit0**。新增失敗背景重試保持提示、成功恢復清除提示、重試不重發、一般保存清除待保存錯誤及普通文案保留。初稿誤用`dao_points`欄位中止，修正為實際`dao_heart`後通過；初稿log保留，不當成功證據。
- `m3b_achievement`、`feature_navigation`、`m2d_responsive_ui`、`uix_r2_hud`、`uix_r1_components`五Runner最終皆exit0，log為`artifacts/uix-r6/*-feedback.log`。未重跑全量或既有FPS／冷啟動；已有Font／CanvasItem／ObjectDB退出診斷保持。
- 固定引擎`--headless --path . --export-release Web build/web/index.html`、bundled Node `tools/prepare_web_compression.mjs build/web`皆exit0，log為`export-feedback.log`與`compression-feedback.log`。bundled Python `tools/subset_game_fonts.py --check`（PYTHONPATH指向既有fonttools4.61.1）exit0，沒有再生成字型。

下一步：收使用者成就美術回饋／接受，補實體橫式觸控與DPR2／3；長文／大數瀏覽器案例及IndexedDB直接觀察仍待驗，現有CLI長文檢查不升格。完成本有界階段後依Context Guard交接New Chat，不開R7。

2026-10-16開工／2026-10-17交付。IN_PROGRESS（資產／來源／CLI／原生／Web匯出已交付；Web真實互動、人工／裝置仍待驗），未滿完整DoD，不標DONE。

範圍：18項現行成就各自生成透明手繪徽章，六分類復用代表圖，沿暖紙／深墨／青玉、SegmentChips、共用字型與CloseSeal。固定總覽、分類、回饋與返回；成就內捲，工作區最大1120px、工作寬1000起雙欄，其餘單欄。所有條件／獎勵／達成狀態讀原View，不新增細進度百分比或規則。72px卡圖／24px分類圖，生成原圖不作Control最小尺寸。

領取仍由GameSession處理。修正既有UI領取成功後忽略保存結果：領取已生效但寫入失敗時呈現具體錯誤與重試保存按鈕；重試只呼叫原保存流程，不再送領取命令，Web既有儲存阻擋／重試遮罩保持。未改schema、成本、獎勵、RNG或玩家存檔。

資產：內建ImageGen逐項生成，無外部參考圖。原始RGBA與逐字提示詞保存在本頁artifacts/uix-r6/originals及prompts；runtime與manifest放assets/ui/achievements-painted。tools/uix_r6_assets.py只做透明邊界配適／縮圖／留白，保留生成alpha；不做色鍵或用程式替代繪圖。完整來源、用途、尺寸、切層與授權聲明見manifest。

修改範圍：achievement_panel.gd、feature_navigation.gd（僅成就工作區上限設定與共用上限讀取）、abode_modal_manager.gd（重試signal）、living_abode.gd（成就領取／保存結果）；新增uix_r6_achievement_ui_runner.gd、uix_r6_preview.gd、uix_r6_assets.py與資產。字型corpus查出缺字，使用既有subset_game_fonts.py重建OFL衍生runtime字型，原TTF保持。既有dirty建築／文件成果保留，未commit/push。

驗證紀錄（以下初稿失敗保留歷史；最終結果見後段）：

- 引擎 --version：4.7.2.stable.official.ed1daf0bf，exit0。
- m3b_achievement_runner：6項規則／獎勵／防重領／跨世／codec案例PASS、exit0。
- feature_navigation、m2d_responsive_ui、uix_r2_hud、uix_r1_components：修正新頁GDScript型別推斷錯誤後v2皆exit0，未將早期失敗當通過。最後來源變更後將重驗受影響項。
- 原生三尺寸初稿exit0；首次缺隔離APPDATA導致STORAGE_STARTUP_FAILED與nil，已中止並以build/uix-r6-appdata重跑成功。早期無圖稿不作最終美術證據。
- 新UI runner初稿的缺圖斷言失敗（生成仍進行中）；已修正測試型別與update_view對單獨成就View的識別。領取／拒寫／重試／重載／紅點／分類與尺寸斷言未出現其他失敗；最終完整素材後再跑。
- 字型 --check初次缺10個碼位，既有工具重生字型exit0；最終再check。
- 隔離服務：python tools/web_static_server.py --port 48766 --directory build/web 啟動成功；IAB createBrowserTab(http://127.0.0.1:48766/index.html) 回net::ERR_CONNECTION_TIMED_OUT，未進遊戲，沒有真實Web互動證據。當時為連線預檢，非本輪匯出版驗收。不得操作4306／4175或既有玩家origin。

待驗：本輪最終Web真實滑鼠領取／內捲／分類／返回／重載與直式轉橫；長文／大數瀏覽器命中、人工美術、實體觸控／高DPR。原生與CLI只能證明各自範圍。既有退出Font RID／CanvasItem／ObjectDB診斷保留，不宣稱零錯誤。

下一階段只收成就回饋及剩餘驗收；本輪不開始UIX-R7輪迴。

## 2026-10-17 最終驗證

- `python tools/uix_r6_assets.py`：18枚不同生成圖均有0–255透明alpha，保留原圖與18份逐字提示詞、生成來源及manifest SHA256，exit0。目標72px圖表已檢視，無介面字樣、透明留白與完整物件輪廓；最終美術接受由使用者判定。[圖表](artifacts/uix-r6/badge-target-72px.jpg)、[manifest](../../assets/ui/achievements-painted/manifest.json)、[完整提示詞／原輸出路徑](artifacts/uix-r6/generation-records.json)。Runtime每枚224×224，source依各生成輸出保留，不使用來源尺寸作最小Control尺寸。
- 隔離`APPDATA=build/uix-r6-tests`，固定引擎`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/<runner>_runner.gd`：`uix_r6_achievement_ui` **188 checks、failed=false、exit0**；`m3b_achievement`、`feature_navigation`、`m2d_responsive_ui`、`uix_r2_hud`、`uix_r1_components`五項亦exit0。未跑全量，因變更限成就與工作區上限讀取／成就命令結果接線。最後分類ensure_control_visible微修後，成就專項重跑188 checks／exit0。
- 成就專項覆蓋18圖／6分類代表圖、未達成／可領／已領、真實signal→Session領取、精確獎勵、重領拒絕、待領分頁／Dock紅點更新、寫入拒絕提示與重試、重試不重發、FileStorageAdapter落盤重載、六分類、三尺寸捲動邊界／固定CloseSeal／44px動作、長獎勵文字不改動作寬度。這些是CLI／隔離檔案證據，不代替瀏覽器滑鼠或IndexedDB。
- `--path . --script res://tools/uix_r6_preview.gd`：最終exit0，1280×720／844×390／800×360各「全部／營造／輪迴／保存拒寫呈現」共12張原生PNG。已視覺檢查三尺寸、雙欄／單欄、紙底深墨、三態卡片、固定分類／關閉及回饋。短橫式分類可橫向內捲，選中項會自動移入可見區。失敗狀態渲染為明示fixture；實際拒寫／重試由上述UI runner驗證。[最終桌面](artifacts/uix-r6/album-1280x720-category0.png)、[844營造](artifacts/uix-r6/album-844x390-category2.png)、[800輪迴](artifacts/uix-r6/album-800x360-category6.png)、[800保存錯誤](artifacts/uix-r6/save-failure-800x360.png)。無`.godot`或build手改。
- bundled Python `tools/subset_game_fonts.py --check`最終exit0；重建只修改runtime兩字型與manifest，來源OFL字型及授權檔保持。
- 固定引擎 `--headless --path . --export-release Web build/web/index.html`與bundled Node `tools/prepare_web_compression.mjs build/web`最終皆exit0；export-final.log含18個achievements-painted PNG項，四首音樂companions齊備。最終PCK SHA256：`6BB418D5B634B60A7C3D8E180612DED57EA93CB34A023247382DDC406750958D`。因分類可見區小修，匯出再生成一次，以上hash為最後版本。
- 隔離服務48766上，IAB對`127.0.0.1`預檢與最終`localhost`皆回`net::ERR_CONNECTION_TIMED_OUT`。無遊戲Web screenshot、點擊、重載或旋轉通過證據。服務本輪啟動後已停止，未碰4306或4175。
- 首次Godot import順帶生成81份既有D2證據PNG的未追蹤`.import`衍生metadata；最後移除本輪新生metadata，既有PNG／JSON／uid與其他dirty成果保持。
- `git diff --check`與受影響UTF-8／本地連結核對結果另於收尾記錄。退出仍有既有Font RID／CanvasItem／ObjectDB／resource使用診斷，所有上述runner最終exit0，不宣稱零退出診斷。

## 待驗與人工步驟

使用新的隔離origin載入本輪Web包，勿清除或種入玩家origin。正常建造首座茅屋後，修行→成就，點洞府營造→仙家草廬「領取獎勵」；核對木材+100、按鈕已領、待領數／Dock紅點同步，重整確認保持。另檢查未達成按鈕禁用、各分類橫捲／列表內捲、固定返回、1280×720／844×390／800×360、直式旋轉遮罩→轉橫恢復；長文／大數、拒寫／儲存恢復重試及IndexedDB仍須真正瀏覽器證據。人工美術、實體觸控與DPR2／3各自待驗。

下一New Chat接R6回饋與上述缺口，不重生已交付18圖，不重跑既有FPS／暫緩冷啟動，不開始R7輪迴。原R4／R5及完整C/D歷史待驗維持。

收尾檢查：12份受影響文字嚴格UTF-8、7個本頁連結與18份runtime SHA256／RGBA／尺寸核對均PASS；git diff --check exit0（僅既有LF→CRLF提示）。
