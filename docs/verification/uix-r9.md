# UIX-R9-SECT：山門事務

2026-10-17。使用者核定接續R9，覆蓋R8交接的「不開R9」限制；R8仍美術待接受。本頁記錄實作及本輪驗收，R9人工美術尚未接受，不標完整DONE。

## 交付

- 內建ImageGen生成13張獨立透明圖：五宗門徽記、四現有功法、採集／護送／探索／護陣四種委託題材；15個現有委託模板均有映射。坊市復用靈草／靈石／築基丹圖，無專圖的靈晶使用字印。
- [資產manifest](../../assets/ui/sects-painted/manifest.json)、[逐字提示詞與生成紀錄](artifacts/uix-r9/generation-records.json)、`artifacts/uix-r9/originals/`與逐圖prompt保存來源。runtime336×336、透明輪廓完整配適、16px安全留白；桌面112px／短橫式80px。源alpha保留；天劍圖最大alpha254屬近不透明，不為滿足255斷言重畫原圖。原圖為本專案AI生成，無外部參考圖，不宣稱取得第三方商用授權。
- `sect_panel.gd`：共用正式／細軸卷軸、MarginContainer／VBox、紙面深墨卡片、GameTab／CloseSeal；固定分頁及貢獻，內捲內容。1120px工作區，面板寬1040px起雙欄，其餘單欄。短式收重複總覽，貢獻併分頁，首次入宗第一個操作無須先捲動。
- 未入宗顯示五山門；入宗後保留歷練、秘術、坊市。宗門簡介改為題材意象，避免原文暗示核心不存在的選宗專屬產率／壽元加成；實際效果仍見原四功法。
- 倒數、冷卻與資源變化就地刷新，保持滑鼠目標；結構／任務／功法階級改變才重建。卡片動作固定44px並垂直置中，避免被圖卡高度撐大。保留當前派遣單槽契約，不因未使用的常數擴成多槽；普通／優秀等文字是任務稀有度，不是宗門等級。
- 真實費用、缺料／貢獻不足、滿階／售罄；完整任務獎勵補顯玄銅。貢獻用Amount格式，完整原值留TIP。派遣完成顯示「完成待領」，領取仍由Session結算。
- `abode_modal_manager.gd`：六項宗門操作沿既有Session命令，回饋與保存錯誤留頁內；重試只呼叫保存，不重送操作。`living_abode.gd`普通保存及Web背景保存成功清除宗門失敗狀態。未改成本、解鎖、收益、RNG、輪迴或schema。
- `feature_navigation.gd`新增宗門1120px工作區政策。獨立R9Acceptance場景／preset與server為明示隔離Era2／資源fixture，已有旗標不重種；不冒充正常前期進程。`r9long=1`只改呈現副本。
- 本批順序已依使用者追加：R9→R10→R11→**RES1-E-SKILLS-PLAN**；尾階段交付技能盤點、分境界表與可執行清單，詳見[美術計畫](../20-feature-interface-art-plan.md)。目前未擴增技能。

## 命令與證據

命令在專案根執行；CLI／原生APPDATA分別隔離於`build/uix-r9-tests`、`build/uix-r9-native`，不覆寫玩家進度。最終結果於本頁下方追加。

- Godot：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：4.7.2.stable.official.ed1daf0bf。
- `python tools/uix_r9_assets.py`：13圖透明度／尺寸QC、原圖／提示詞／manifest／縮圖總覽交付。
- Godot `--headless --path . --import`、`--script res://tests/uix_r9_sect_ui_runner.gd`；專項涵蓋實際入宗、扣費、拒寫／重試不重扣、隔離讀回、派遣／完成／領取／重領拒絕、缺料／滿階／售罄、三尺寸卡片／44px／內捲／安全距離及返回。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`；另有`tests/m3b_sect_runner.gd`核心基線。
- Godot非headless `--path . --script res://tools/uix_r9_preview.gd`：三橫式×未開／可入宗／委託／派遣中／待領／功法／坊市／保存錯誤，共24圖；均為明示fixture渲染。
- `python tools/subset_game_fonts.py`與`--check`；補齊既有OFL字型子集／來源清單，未改來源TTF。
- Godot `--headless --path . --export-release R9Acceptance build/r9-acceptance/index.html`及`Web build/web/index.html`；每版接`node tools/prepare_web_compression.mjs <build-dir>`，壓縮及音樂companions。
- `python tools/uix_r9_server.py --port 48779`：僅綁127.0.0.1，隔離origin與玩家服務分離。沙箱服務首次IAB逾時，以Ctrl+C停止自有session後，主機層同命令重啟。

## 失敗與邊界

- 首次資產QC對天劍alpha硬性要求255失敗；檢查原圖確認範圍0–254，改驗透明背景與最大alpha≥250，保留原圖。
- 中間無素材測試不作通過證據；初輪短式操作被卡高撐大、第一山門被介紹占滿、舊深底搭配深墨字及新增回饋沿用淺色等均由幾何或原生檢查發現後修正。
- 首次Web匯出因目標資料夾不存在失敗，建立專案build子目錄後重跑；字型check初次缺字、後續來源清單變動均重建後再驗。
- 既有Font／CanvasItem／ObjectDB退出診斷與負面測試的預期錯誤保留，不稱零error日誌。未commit／push。
- 觸控與實機依當次使用者指令延期、非目前阻擋，不宣稱通過。未重做已接受FPS／暫緩冷啟動矩陣。

## 最終結果

- 固定入口70/70、exit0（包含當時R9 158 checks）；最後標題／字色／短式修正再跑R9 **164 checks failed=false、exit0**，宗門UI、導覽與正確入口`m2d_responsive_ui_runner.gd`均exit0。曾誤用不存在的`responsive_layout_runner.gd`，命令失敗有保留，已用正確入口補跑，不把誤發命令列成功。
- 原生最終`uix-r9-native-delivery-final.log` exit0，24PNG檢查紙底深墨、第一山門可見、功法／坊市、派遣待領與保存重試；先前中間圖已由最終版重產。
- 最終兩版export-release、各自Node壓縮／音樂companions及font --check均exit0。Web PCK SHA256 `421F65FC7BF580650ECA2501E6F25CF9CA909702F066C617D29906B765B2EF82`；R9Acceptance `B1E629BD08F971A0A6E42B63C3DBF347AC0F04479DFCC58474B3F4446F242577`。
- IAB 48779真實滑鼠入太虛；48780獨立`?r9funded=1`初始fixture明示入宗、1000貢獻／5秒委託／資源，既有旗標不重種。滑鼠派遣→等待完成，神農0→1扣50（950）、草囊0→1扣30（920）、領80（1000）。寫入拒絕下神農1→2費75生效、全畫面保存阻擋；拒寫時重試仍失敗，恢復後重試解除，頁內提示已恢復；再次重載保持第二重與925貢獻，草囊1/20，未再次扣75或升第三重。
- Web三CSS viewport1280×720／844×390／800×360，短式內捲至引靈大陣、分頁固定、返回洞府／重開及設定鈕避讓；直接viewport與iframe均有檢查。IAB DOM畫布實測為1279×719／843×389／799×359的1px取整差，未當作精確原生尺寸；精確三尺寸由原生渲染另驗。中間尺寸圖已依實際viewport重新命名，以下有效證據依檔案內容判定。
- 長文副本在三CSS尺寸可讀／可內捲到操作，貢獻採科學記號，完整30位原值留TIP；桌面直式遮罩與回橫式已驗，非實機旋轉。第二分頁一度被既有多分頁保護阻擋，先關閉第一分頁後重載才進入長文驗收；不將阻擋畫面稱長文通過。正常頁warn/error查詢空；故障頁SecurityError為預期注入。
- 主要瀏覽器證據：[實領](artifacts/uix-r9/web-claimed-1280.png)、[拒寫](artifacts/uix-r9/web-write-denied.png)、[恢復](artifacts/uix-r9/web-storage-recovered.png)、[重載第二重](artifacts/uix-r9/web-reload-technique2.png)、[844末項](artifacts/uix-r9/web-iframe844-last.png)、[800重開](artifacts/uix-r9/web-iframe800-reopened.png)、[長文844](artifacts/uix-r9/web-long-844.png)、[長文800](artifacts/uix-r9/web-long-800.png)。全部CLI日誌複製至本頁artifacts目錄，摘要見[delivery-summary.json](artifacts/uix-r9/delivery-summary.json)。

下一New Chat先收R9美術回饋／必要有界修正，再依使用者續行指示接R10；不在本輪展開R10。R8美術待接受保持；技能盤點與分境界實作清單確定排在R11後，實際擴充另依該清單逐批交付。

清理：自有48779／48780服務均Ctrl+C主動停止（exit1為刻意終止），正常驗收頁關閉、viewport reset。首次逾時的data-URL錯誤頁被Browser Use URL policy拒絕取回／關閉，保留為不可操作錯誤頁；未繞過該限制。工作區既有dirty成果保留。

文件收尾：PowerShell／Python嚴格UTF-8八份文件、驗收頁12個本地連結、13張runtime／來源／prompt的manifest引用與336px RGBA尺寸皆PASS；git diff --check exit0（僅既有LF／CRLF提示）。
