2026-10-28 **IMM-4-R2 DONE（L2資源圖示補齊）**：20張共用資源／貨幣／獸魂圖示與正方形成本格已接入，來源移至TIP；相關7支及新版Web桌面抽驗通過。[狀態](development-status.md#imm-4-r2)。

2026-10-28 **IMM-4-R1 DONE（L2有界修正）**：技能正文至少16px、焦點字色對比與延期記錄已修正；5支專項及新版Web桌面抽驗通過。[狀態](development-status.md#imm-4-r1)。

2026-10-28 **IMM-4 DONE（整批收尾，唯一L3）**：IMM-1A～3C的洞府、十三功能頁與五類覆層整批結案；唯一全量L3為145／145 runner全尺寸矩陣PASS，正式Web與候選包同源輸出並通過壓縮校驗，桌面Edge/CDP三橫式（1280×720／844×390／800×360）真實滑鼠抽驗可讀可操作；IMM-2記錄為無新增微動態工程。見下方IMM-4。

> 較舊的日期化結案段落已原文搬至 [development-status-prelude-archive-2026-10.md](archive/development-status-prelude-archive-2026-10.md)。

# 開發狀態與交接紀錄

<a id="imm-4-r2"></a>
## 2026-10-28 IMM-4-R2：資源圖示補齊與正方形成本格 DONE（L2，有界回饋修正）

- **使用者要求與結果**：技能點不能留空圖；同類資源一併檢查，數量疊在圖像右下、外框正方形。「當世」不必逐格重複，頁首仍保留當世選修／輪迴重置說明，來源及完整名稱／可用／需求留TIP與資源詳情。
- **覆蓋與美術**：補齊14個缺少共用圖示對應的資源／貨幣（技能點、道心、道證、貢獻、精鐵、秘銀、寒鐵、千年靈草、化神丹、虛空精華、星金、虛空結晶、極品靈晶、天青靈液），另補6種獨立獸魂。所有ResourceIcon.NAMES、共用貨幣清單、現有兩份供給資源catalog及BeastSystem獸魂ID均有實際圖示。圖像不改資源解鎖，雲蛟等條件維持。
- **來源／用途／切層**：使用generate2dsprite技能及內建image_gen，參考本專案原創陣芯材質生成原創20物品圖，160×160透明PNG位於 `assets/ui/resources-painted/imm4-r2/`；`prompt-used.txt`與`manifest.json`保留提示詞、用途、來源區域、sha256及授權說明。原始圖與QC在 `docs/artwork/imm4-r2/`，未取外部圖像。PNG只承載插圖，Godot Label獨立疊數量、TIP承載完整來源，沿UiIllustration共用B效果。原均分4×5切圖因圖像越格而被strict QC拒絕；改完整連通物件分離，視覺QC再排除bbox內鄰格碎片後，20／20單物件strict QC PASS，透明／160px／檔案hash皆通過。聯絡表 `docs/artwork/imm4-r2/contact-sheet.jpg` 為核對用，非互動畫面。
- **來源修改**：`resource_icon.gd`補20個紋理與貨幣／獸魂名稱，尊重呼叫端已指定的小圖minimum size；`recipe_material_tile.gd`外框寬高72／短式48，保留56／36圖像區與右下Label，來源caption隱藏，未知項用「未識」字印與完整TIP；`inventory_item_cell.gd`取消為底行預留的圖像空間。`skill_study_view.gd`移除強制顯示來源caption。`sect_panel.gd`的 `_wrap_card_labels` 不再遞迴覆寫CostStrip，避免將共享物品格重新拉寬。docs19同步使用者核定通則；未改規則、成本、存檔schema或玩家進度。
- **L2選取與實際結果**：執行前 `tools/run_all_runners.ps1 -Only 'imm1a_inventory_runner.gd,imm3a_cost_detail_runner.gd,imm3c_page_consistency_runner.gd,uix_r8_skills_ui_runner.gd,res1_ui1a_runner.gd,res1_ui1b_runner.gd' -List` 確認6支。共用圖示／材料格影響庫存、成本、技能、製造及運輸，故按L2超過5支，非擴成全量。正式同selector加 `-TimeoutSeconds 120`（運輸過往約86秒）；第一輪5／6 PASS：imm1a 8.9s、imm3a 8.6s、res1_ui1a 40.6s、res1_ui1b 84.3s、uix_r8 10.2s；imm3c 17.5s失敗，明確抓到宗門研習／市場的外框被拉寬，該輪exit1，不算整輪通過。修正宗門後先List再執行 `-Only 'imm3c_page_consistency_runner.gd,uix_r9_sect_ui_runner.gd'`，2／2 PASS（18.2／9.8s）、exit0。**合併受影響範圍7支均有PASS；全為1280×720、matrix=single，guard通過**。日誌分別 `C:/Users/asus/AppData/Local/Temp/dao2_runners_c552f195721943eb9c25958238955a9a` 與 `.../dao2_runners_4a340cbc90a243f5bac0e31cc34ee1d4`。既有退出RID／anchor診斷保留，未宣稱零警告。
- **測試補強**：imm1a增加全部已知資源／貨幣／獸魂coverage、正常與compact完整外框正方形、右下錨點與未知字印／完整TIP；imm3a改驗極品靈晶有真實圖；imm3c驗實際外框寬高相等、來源不佔底行且TIP仍完整；uix_r8驗所有技能成本格有圖／正方形／不重複來源。原命令、缺料與禁用回歸保留。
- **Web／桌面抽驗**：引擎版本 `4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import`與最終 `--export-release Web build/web-imm4-r2/index.html` exit0；`node tools/prepare_web_compression.mjs build/web-imm4-r2` exit0。只更新本機測試包，PCK 126,317,416 bytes、sha256 `ff69053222ad6b655f20571bda2b49c9a4581de5d41a787f5a9e1f0d4fb01b77`。重用既有island_preview_server Handler，BUILD暫指新包、FIXTURE為既有content_p1_skills_fixture.json、prefix為dao2_saves；新origin `127.0.0.1:4428`與玩家隔離。IAB外窗1280×800、遊戲iframe1280×720，真實滑鼠開技能、卷冊成本圖＋右下90／1800＋無「當世」底行、研習成功到基礎冥想1/5，以及相關資源抽屜的88px技能點圖格均已核對。截圖 `.test-output/imm4-r2/browser/skills-1280.jpg`、`skills-learned.jpg`、`skill-inventory.jpg`。這是桌面輸入與顯示證據，不是自然通關、IndexedDB、效能或全頁瀏覽器驗收。
- **收尾與下一步**：`python tools/delivery_check.py --web build/web-imm4-r2`：7／7壓縮檔校驗、RESULT PASS；新圖20／20hash通過，既有guard路徑原7個.import未改。英文updata保留最近5筆，trim_status_docs按工具歸檔。未跑L3、不製作新發布候選包；build/web與web-imm4維持原IMM-4歷史包。本次回饋修正階段完成，**可手動commit**，未commit／push。下一步收使用者圖示／密度回饋；不在本輪開P3，後續大型工作請New Chat。觸控／實機延期，非當前阻擋。

<a id="imm-4-r1"></a>
## 2026-10-28 IMM-4-R1：字級與桌面焦點補正 DONE（有界修正，L2）

- **範圍與修改**：`src/presentation/skill_study_view.gd` 的作用說明／目前及下階效果在寬式與短式均至少16px，沿既有換行、容器與內捲承載長文。`src/presentation/ui_material.gd` 為共用主題及 `_set_button_ink` 補齊 `font_focus_color`，修正實際Web Tab焦點使紙底按鈕文字變淺難讀；青玉選中仍沿原淺字角色。未改玩法、命令或存檔格式。
- **回歸補強**：`tests/uix_r8_skills_ui_runner.gd` 增加所有24張技能卡正文最低字級、完整效果、文字高度、卡內邊界／動作不交疊，以及620×220受限內容區長說明換行、內捲可達44px動作。焦點檢查涵蓋共用按鈕與純主題Button繼承的非透明框線及字色。`tests/ui_material_states_runner.gd` 加入選中／取消選中與紙面分頁焦點對比檢查。受限內容區是1280×720視窗內的元件案例，非額外全尺寸矩陣。
- **L1／L2命令與結果**：引擎 `--version` 為 `4.7.2.stable.official.ed1daf0bf`。先執行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'uix_r8_skills_ui_runner.gd,content_p1_skills_ui_runner.gd,imm3c_page_consistency_runner.gd,ui_material_states_runner.gd,ui_shell_integration_runner.gd' -List` 確認5支，再同selector執行；**5／5 PASS，matrix=single，exit0**。依上述runner順序耗時10.0／10.2／19.1／2.5／11.6秒，evidence guard通過，日誌 `C:/Users/asus/AppData/Local/Temp/dao2_runners_0151ff8b76b64861aa7312a66cc00229`，輸出在 `.test-output/dao2_runners_0151ff8b76b64861aa7312a66cc00229/`。此為有界L2，沒有重跑L3或宣稱全量回歸。
- **失敗與修正過程**：初次沙箱執行無法建立Godot `user://`／隔離保存，第一支timeout且出現SCRIPT ERROR；主動終止該輪，改以正常本機權限執行，不計成功。新增compact測試起初因Label初次autowrap使容器暫態長高，連續三次調查未通過；在獨立Control宿主且初始布局穩定後重設受限尺寸，該專項通過，最終五支亦全部通過。既有anchor／Font RID／ObjectDB退出診斷保留，不聲稱日誌零警告。
- **新版Web與桌面抽驗**：`Godot --headless --path . --export-release Web build/web-imm4-r1/index.html` 最終exit0；`node tools/prepare_web_compression.mjs build/web-imm4-r1` exit0。本機測試包PCK 125,639,796 bytes，sha256 `67ef8d45cd66fc3610cf4c5beb21021d550f1c3ee078169a1e85182d782fb4a4`。重用 `island_preview_server` 的Handler，暫時指定BUILD為該包、FIXTURE為既有 `src/verification/content_p1_skills_fixture.json`、測試頁prefix為 `dao2_saves:`；僅服務新origin `127.0.0.1:4427`，未修改server來源或玩家origin。沿用舊launcher的題名／築基字樣並非本次快照版本證據，實際為既有命令賺得的金丹技能快照，非瀏覽器自然通關。
- **實際操作證據**：IAB桌面滑鼠在iframe **1280×720 CSS px**（外窗1280×800）打開修行→技能、實際研習到基礎冥想2/5、目前1.210／下階1.331，Tab移至聚氣術按鈕可見金色焦點框及墨色文字。另針對原compact缺口抽驗 **800×360 CSS px**：三島藏真法的完整作用／收益0／目前與下階效果經內捲可讀，44px動作與固定關閉可達並返回洞府。短式長卡需內捲，不宣稱全卡必須同屏。證據 `.test-output/imm4-r1/web-focus-fixed.jpg`、`web-scope-1280.jpg`、`web-scope-800.jpg`、`web-effects-800.jpg`；這是可讀性／桌面輸入證據，不推定IndexedDB落盤、FPS或全頁鍵盤可及性審計。
- **文件校正與交付檢查**：docs19明示正文與焦點對比，docs43及原IMM-4報告移除「鍵盤依10/17延期」及未有使用者核定的「已接受殘留」推論；原145支L3與當時包證據保留歷史。README／ROADMAP／ai-handoff只放狀態入口，英文checkpoint寫入updata並保留最近5筆。`python tools/delivery_check.py --web build/web-imm4-r1` 7／7 match、RESULT PASS；guard目錄原有7張未追蹤.import與開始時一致。本輪僅更新本機測試包，既有build/web與build/web-imm4仍是原IMM-4版本，未當作修正版證據或發布候選包。
- **下一步與邊界**：本次R1 DoD已滿足；未新增微動態工程，不啟動P3大型任務。觸控／實機延期，非當前阻擋。待使用者另行指定下一任務，長期依賴仍為RES1-E-79→CONTENT-P3／SKS-P3。未commit／push；本有界修正階段完成，**可手動commit**，後續大型工作請New Chat。

<a id="imm-review-20261028"></a>
## 2026-10-28 IMM 系列完成度複核：核查完成，IMM-4-R1 待修

使用者要求核查 OpenCode 的 IMM 成果與預排工作。本次為審查階段，不修改遊戲來源、不重新匯出、不重跑 L3；下方原 IMM-4 DONE 保留為當時結案記錄，不能解讀為本次已確認所有規範均符合。

- **已核實交付**：共用庫存／物品格、七島選擇器、成本列與各頁接線有實際來源及測試。原 L3 日誌 `C:/Users/asus/AppData/Local/Temp/dao2_runners_e101659f673444538a928a0a443f6582` 有 145 份 stdout，逐份皆含 `RUNNER_RESULT status=PASS exit=0`，stdout／stderr 無 `SCRIPT ERROR:`。此為沿用 2026-10-28 原始證據，並非本輪重新執行全矩陣。原桌面 Web 證據目錄 `.test-output/imm4-web/` 及 74 張截圖存在；本輪未重新做瀏覽器互動，不將證據存在等同重新人工驗收。
- **本輪 L1**：先以 `tools/run_all_runners.ps1 -Only 'imm1a_inventory_runner.gd,imm1c_island_selector_runner.gd,imm3a_cost_detail_runner.gd,imm3b_cultivation_resources_runner.gd,imm3c_page_consistency_runner.gd' -List` 確認 5 支，再同 selector 正式執行。1280×720、matrix=single，5／5 PASS（9.9／10.0／9.4／10.0／17.6 秒），exit 0；輸出隔離與 evidence guard 通過。日誌 `C:/Users/asus/AppData/Local/Packages/sandbox.{861068f2-6e09-41b2-8cbf-e571df271569}/AC/Temp/dao2_runners_38d9f25d2397403bb2df7376f9cfa833`。本機引擎 `--version` 為 `4.7.2.stable.official.ed1daf0bf`。
- **Web 校驗**：`python tools/delivery_check.py --web build/web` 與 `--web build/web-imm4` 均 7／7、RESULT PASS／exit 0；PCK 各 125,639,700 bytes，匯出時間晚於目前最新 GDScript 修改。此為包完整性證據，不聲稱重新證明每頁互動、存檔落盤或效能。
- **[P2] 未符合 DoD：技能正文縮字**。`src/presentation/skill_study_view.gd:158`／`:160` 在 compact 模式（內容高 <340）把 scope／effect 設為 14px，effect 是目前／下階實際效果正文；scope 在寬式亦為 15px。與 `docs/07-responsive-ui-web-spec.md:156` 的卡片正文最低16、不靠縮字塞高度，以及 docs41／docs43沿用規範的要求衝突。本次檢查的既有技能與 IMM runner 沒有對這些 Label 設最低字級斷言；PASS 不能排除此缺口。
- **文件校正**：原結案把「鍵盤／觸控焦點」一併歸為 2026-10-17 延期並稱殘留已接受，但使用者指令僅延期觸控／實機。純主題 Button 可繼承引擎 focus style（R1已核對；原引 `ui_material.gd:231` 實為文字輸入框設定），沒有金色環本身不代表無焦點；應核查可辨性，不能捏造鍵盤驗收延期或使用者接受。IMM-2「無新增動態工程」可保留，不等同全面豁免焦點要求。
- **下一任務 IMM-4-R1／TODO**：恢復技能說明／效果至少16px，以容器、留白與內捲容納；補最小字級與完整文字／操作不裁切檢查；按 L1／L2 補受影響 runner 與含修正包桌面抽驗，不因本次審查重跑全量 L3。更正鍵盤延期敘述並核對焦點要求。修復前不宣稱 IMM 無剩餘工作。
- **既有預排工作**：IMM 原批次沒有尚未啟動的必需大批次；IMM-2 是無新增工程決定。較長期仍有 `RES1-E-79 → CONTENT-P3`／`SKS-P3`（Era7–9），其後 `RES1-E-1012 → CONTENT-P4`／`SKS-P4`（Era10–12），以及 M4／M5 完整可玩與逐界內容驗收。這些是規劃與依賴順序，尚非已授權自動啟動或已排定執行日期。realm 法令條件與 Era8 雲蛟維持原條件限制。觸控／實機與慢網冷啟動維持延期，非本輪阻擋或下一必做。

本次只更新狀態、入口與英文 checkpoint；保留現有未提交成果及原結案歷史，未 commit／push。審查階段完成，可手動 commit；下一 New Chat 先處理 IMM-4-R1，不直接展開 P3 大型任務。

<a id="imm-4"></a>
## 2026-10-28 IMM-4：整批收尾 DONE（大型任務完成，L3）

使用者指定IMM-4。依docs43對IMM-1A／1B／1C／3A／3B／3C做整批收尾：逐頁總表、整批美術／操作確認、唯一L3（全runner＋全尺寸矩陣）、正式Web同步與候選包、桌面瀏覽器三橫式真實滑鼠抽驗，並記錄IMM-2決定。未改規則、存檔schema、命令payload、獎勵或既有禁用／送單語意。

實作與修改檔案：
- 短式溢位修正（L3首輪133／145抓出，全在844×390與800×360）：`cost_strip.gd`新增`set_compact()`／`is_compact()`，`recipe_material_tile.gd`新增`cell`／`compact`／`set_compact()`（36×36格、28px圖示、隱藏caption）並讓無圖資源的`refresh()` fallback不再強制顯示caption；`ui_shell_controller.gd`工具覆層高度改為止於工具列上緣，修正選島／存檔／除錯工具底板超出；`alchemy_panel.gd`煉丹列micro（<400）套compact格與橫向動作列；`reincarnation_panel.gd`天賦列<400套compact、<380改文字「道心：N」；`sect_panel.gd`功法P1卡compact套成本列、隱描述與縮圖；`skill_study_view.gd`compact套成本列、保留功法來源與完整倍率；`island_world.gd`／`island_selector.gd`選島幾何無條件配置、compact收合標題／頁尾、當前島置頂、窄式世界列可縮且按鈕≥44高於工具列。
- 測試端只修隔離與設計期望，不放寬版面斷言：`imm3c_page_consistency_runner.gd`依ShellPolicy的compact「summary」呈現調整短式期望並使`_tiles_are_seals`接受compact 36px格；`res1_ui1a_runner.gd`在矩陣迴圈後還原1280×720版面（原後續1280檢查沿用800×360版面）。`world46`、`res1d2_world`、`content_p1/p2`、`uix_r8`的卡高／可達性條件不變。
- 新增`docs/verification/imm-4-batch-closure.md`：逐頁總表、IMM-2決定、短式修正、L3、Web雜湊、三橫式證據與殘留。同步更新docs43、README、ROADMAP與本段。

驗證與修復紀錄：
- L3（唯一、全量）：`tools\run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 1800`，matrix=full，145 runner，`SELECTED 145 RUNNERS PASSED (matrix=full)`，每支`RUNNER_RESULT status=PASS exit=0`，無`SCRIPT ERROR:`；時間11:51:43→12:20:37，日誌`C:/Users/asus/AppData/Local/Temp/dao2_runners_e101659f673444538a928a0a443f6582`。首輪為133／145，12支失敗全數修正或確認為已核實的長測試（兩支era流程原600秒逾時，1800秒後PASS 1304.7／531.3秒）。
- Web：`--headless --import` exit 0；Web preset輸出`build/web`（正式）與`build/web-imm4`（候選）皆exit 0；`node tools\prepare_web_compression.mjs`兩者exit 0且報告一致（PCK 125,639,700 bytes sha256 `f9ea0e55…3e48`、wasm 39,514,754、js 279,815，br合計133,044,317；BGM四首逐位元複製）。`python tools\delivery_check.py --web build\web`與`--web build\web-imm4`均`[web] 7/7 files match compression.json`、`RESULT PASS`。
- 桌面Web三橫式（L3要求的桌面滑鼠／尺寸）：`127.0.0.1:4420/launcher`載入`build/web-imm4`與Era3隔離fixture，Edge/CDP deviceScaleFactor 1實測iframe 1280×720／844×390／800×360（canvas 1279×720／843×389／799×360，1px取整照實記錄）；真實滑鼠在三尺寸皆可開經營殼與資源抽屜、Escape關閉、resize保留狀態，離線摘要完整落在畫面內；console無ERROR。證據gitignored`.test-output/imm4-web/`：`p12-01..03-1280`、`p15-01..06`（844／800 world/shell/drawer）、`p14-01`／`p14-04`離線摘要。此只證明桌面滑鼠與尺寸呈現，不聲稱IndexedDB落盤、FPS、觸控或實機通過。
- IMM-2：記為「無新增微動態工程」。`ui_material.gd:213-239`主題五態＋`apply_*`皮層、`graphic_action.gd`等六個共用元件已覆蓋十五頁；接受殘留為覆層開關無tween（docs43:29）、製造`recipe_row.gd:68-100`徽章／標題為選取捷徑無獨立hover、純主題按鈕無金色focus環（鍵盤／觸控焦點依2026-10-17延期）。

未通過／待辦：本輪無未解失敗。觸控／實機、慢網冷啟動與FPS另依既有指令延期或未量測（本輪僅靜態版面變更，記錄針對性理由）。短式「系統訊息·新手引導」僅露尾端約兩行（可捲動）列為已知呈現限制。介面批次全數結案，下一個任務待使用者指定。本次是大型任務結束，可手動commit；代理未commit／push。

<a id="imm-3c"></a>
## 2026-10-28 IMM-3C：全頁一致性核對 DONE（階段完成，L1＋L2桌面Web 1280×720抽驗）

使用者指定IMM-3C。依docs43與docs42剩餘清單，逐頁核對洞府＋十三功能頁及訊息／資源抽屜／設定存檔／保存保護／離線報告五類覆層，補完3A留下的文字串列；未改規則、存檔schema、命令payload、獎勵或既有禁用語意。

實作與修改檔案：
- `manufacturing_panel.gd`：`detail_stock`移除逐項「名稱：當地／祖島可用x／需求y」多行文字，材料需求只由`detail_costs`圖像成本列與格內TIP承載；保留在途到貨及產物可用／容量／加工待完成／容量預留等狀態事實。加工坊按鈕改只顯示階級與秒數／批（及已達上限），移除「祖島支付：…」，升級成本只由`workshop_costs`成本列呈現。
- `island_transport_panel.gd`：升階按鈕移除「祖島支付」價格文字，保留運力N→M／10秒與「升階保留啟停與已保存設定」；成本只由`upgrade_costs`成本列呈現。來源餘貨／保留／目的容量預留／剩餘空間／目標／運力／在途仍為帶標籤事實列。
- 新增`tests/imm3c_page_consistency_runner.gd`並登錄`tools/run_all_runners.ps1`：覆蓋十四頁的canonical路由、共用返回／分頁44px、資源入口與抽屜分類（home／inventory／focused／none）、各頁成本列圖印、製造與運輸去重、宗門歷練fallback、機緣無成本／有成本、輪迴預設頁／天賦頁，以及訊息／資源／工具／保存失敗與離線報告覆層。
- 更新`tests/content_p2_supply_ui_runner.gd`：運輸升階改驗證`upgrade_costs`格數等於`_info(id).upgrade_cost`且按鈕不含「祖島支付」。
- 新增`docs/verification/imm-3c-page-consistency.md`逐頁表與例外；更新docs43、docs19、README、ROADMAP及本段。docs19新增「成本由共用成本列呈現、動作按鈕不重複價格清單；圖示已承載的資源不再逐項文字列」的共同規則。

驗證與修復紀錄：
- L1（matrix=single 1280×720）：新runner首輪抓出洞府資源帶因`home_preferences`預設mode 0而隱藏，以及`sect_panel.gd:727`讀取缺失的`techniques`鍵；修正fixture後`imm3c` PASS 18.7秒（日誌`C:/Users/asus/AppData/Local/Temp/dao2_runners_5cda3579eeae4e738246d8224c3dd567`）。同組`content_p2_supply_ui` 4.7、`imm3a` 8.6、`imm3b` 7.5秒PASS（`.../dao2_runners_c33f9c60b70d4907b1016718492b6994`）；`res1_ui1a`／`res1_ui1b`為既有長測試，預設45秒逾時後以`-TimeoutSeconds 150`單獨重跑，分別PASS 49.3／91.5秒（`.../dao2_runners_252e21ac1d26412b8924327b3d2771b3`、`.../dao2_runners_967c2ad9bf5945d39d0369f3110afa99`）。合計6支受影響runner，無`SCRIPT ERROR`。
- L2桌面Web：以目前來源匯出`build/web-imm3c`（PCK 125,634,100 bytes；`index.wasm` 39,514,754），本機`127.0.0.1:4418/launcher`載入Era3隔離fixture，Edge/CDP 1280×720真實滑鼠抽驗管理殼、製造材料成本列、運輸升階與資源抽屜。證據在gitignored`.test-output/imm3c-web/`：`ev-08-transport-detail-down.png`顯示升階按鈕無支付文字、成本列有圖示；`ev-09-resources-drawer.png`顯示島別分組圖示與選中詳情；`ev-17-manufacturing-title-select.png`顯示材料需求圖示列而無逐項可用／需求文字。Web只證明桌面滑鼠／尺寸呈現，不聲稱IndexedDB落盤、FPS、觸控或實機通過；製造加工坊成本列在Web未展開，以原生runner為準。

未通過／待辦：本階段受影響檢查無未解失敗。完整介面尚有IMM-4整批收尾（唯一L3、全矩陣、Web三橫式與候選包）；本輪未執行L3、全尺寸矩陣或正式候選包，IMM-2仍為有需才做。下一個New Chat做IMM-4。本次是階段結束，可手動commit；代理未commit／push。

<a id="imm-3b"></a>
## 2026-10-28 IMM-3B：修行與遊歷資源 DONE（階段完成，L1＋L2桌面Web 1280×720抽驗）

使用者指定接續IMM-3B。依docs43與docs42接口，把修行、靈獸、輪迴、宗門、機緣與天道決策的常態資源／成本由文字改為共用圖像成本列，並接通共用資源抽屜；未改規則、存檔schema、命令payload、獎勵或既有禁用／送單語意，機緣主頁維持原版，敘事／歷世表／確認區保持閱讀形式。

實作與修改檔案：
- `skill_study_view.gd`：每階研習成本改`CostStrip`單格技能點（來源當世），沿用技能點`available/cap`標題、效果、前置與禁用原因。
- `beast_care_view.gd`：祖島餵料改圖示格（來源祖島）並保留缺料／冷卻註記；同種獸魂改獨立事實列「輪迴成熟後取得，不用於餵養」，天賦「領悟·N魂」不變。
- `realm_decision_view.gd`：法令成本改共用成本列，`lifespan_seconds`維持獨立「壽元消耗N秒」標籤、不混入物品格；境界、冷卻、次數與`is_ready`規則不變。
- `fortune_modal.gd`：選項成本改共用成本列與缺料註記，主頁版面、選項卡、獎勵與禁用判斷不動。
- `reincarnation_panel.gd`：天賦成本改道心圖示列（來源傳承）並顯示精確缺口；道心／道證仍分開顯示，歷世表與敘事未改。
- `sect_panel.gd`：參悟與兌換新增貢獻＋靈木／下品靈石成本列（來源宗門），P2短式沿用文字成本；資格、上限、學藝／兌換按鈕與目的地錯誤語意不變。
- `ui_shell_resources.gd`／`ui_shell_controller.gd`：focused路由（技能／靈獸／機緣／決策／輪迴天賦）於資源抽屜顯示結構化圖示群組；修正靈獸只讀當前靈獸`feed_costs`導致未收養時抽屜空白的問題，改由各獸`care.costs`補齊需求且不虛構容量／預留。宗門歷練維持卡片內顯示並移除TODO註記，建築／煉丹沿用既有圖示列。
- 新增`tests/imm3b_cultivation_resources_runner.gd`並登錄`tools/run_all_runners.ps1`；更新`content_p2_beasts_ui_runner.gd`、`uix_r11_decisions_ui_runner.gd`以讀取成本列tiles。docs43標IMM-3B完成。

驗證與修復紀錄：
- L1（matrix=single 1280×720）：新runner首輪抓出`sect_panel.gd`的`cost_lbl`作用域及`reincarnation_panel.gd:593`型別推斷錯誤，修正後PASS 9.7秒；`imm3b,imm3a,ui_shell_policy,ui_shell_integration,uix_r9_sect_ui` 5／5 PASS（日誌`C:/Users/asus/AppData/Local/Temp/dao2_runners_1940fac191044faca82acecddb405bb2`）；`content_p2_beasts_ui,m3a_reincarnation_ui,uix_r10_fortune_ui,uix_r11_decisions_ui,content_p1_skills_ui`修正舊Label假設後全數PASS（日誌`.../dao2_runners_9f42c73a6af9479089fa014d1037bb81`）；最終來源變更後`imm3b,ui_shell_policy,ui_shell_integration,content_p2_beasts_ui` 4／4 PASS（日誌`.../dao2_runners_86addb40f891451eb6e012e84a6b0379`）。合計10支受影響runner，無`SCRIPT ERROR`。
- L2桌面Web：以目前來源匯出`build/web-imm3b`（PCK 125,634,532 bytes，`node tools/prepare_web_compression.mjs` exit 0），本機`127.0.0.1:4416/launcher`載入Era3隔離fixture，Edge/CDP 1280×720真實滑鼠抽驗修行→靈獸及資源抽屜。證據`.test-output/imm3b-web/06-beasts.png`、`07-beasts-scrolled.png`、`09-beasts-updated.png`、`10-drawer-updated.png`：靈狐卡靈草50圖示（來源祖島）與獸魂獨立列；火鳳千年靈草10缺料朱紅及「祖島餵料不足：千年靈草 需10・缺10」；抽屜餵養材料七項圖示、獸魂尚無庫存、靈草可用210／容量210／來源祖島。此fixture技能頁未開放，技能／宗門／輪迴／決策／機緣由原生runner覆蓋；只證明桌面滑鼠與尺寸呈現，不聲稱IndexedDB落盤、FPS、觸控或實機通過。

未通過／待辦：本階段受影響檢查無未解失敗。完整介面尚有IMM-3C及最終IMM-4；本輪未執行L3、全尺寸矩陣或正式候選包。下一個New Chat做IMM-3C全頁一致性核對。本次是階段結束，可手動commit；代理未commit／push。

<a id="imm-3a"></a>
## 2026-10-27 IMM-3A：經營成本與詳情 DONE（階段完成，L1＋L2桌面Web抽驗）

使用者指定接續IMM-3A。本輪依docs43與已接受R2／R3原則，把製造就地庫存、加工坊成本、運輸詳情、建築／煉丹材料格、空島開拓／升級及舊靈界據點成本統一為圖像成本列；未改規則、存檔schema、命令payload或既有禁用／送單語意。運力、保留量、目標與容量維持帶標籤設定或事實列，不當作物品數量。

實作與修改檔案：
- 新增`src/presentation/cost_strip.gd`：共用成本列（標題、HFlow物品格、資格／缺料／滿倉註記），重用`recipe_material_tile.gd`、`resource_icon.gd`與`number_formatter.gd`；提供`show_costs()`、`clear_costs()`、`visible_tiles()`、`shortage_text()`、`covers()`，逐項顯示來源與實際需求，缺料以朱紅註記。
- `manufacturing_panel.gd`：配方詳情新增材料成本列（來源依就地／祖島），加工坊按鈕下方新增`升級加工坊 N→N+1 階`成本列與祖島缺料／未開拓註記；原有`detail_stock`、批數、設定、啟停與工坊按鈕文字／禁用不變。
- `island_transport_panel.gd`：詳情改為帶標籤事實列（來源餘貨、已保存保留、目的容量預留、剩餘空間、已保存目標、運力、在途倒數），新增`升級運力 N→M／10秒`成本列與缺料／未就緒註記；設定欄、草稿、保存、升階文字及禁用不變。
- `island_management_panel.gd`：開拓按鈕前新增成本列與境界／啟用／缺料／材料充足註記；設施卡新增成本列與未開拓／已達上限／缺料註記；沿用`_home_available()`並新增`_home_stock()`讀祖島庫存；原有付款組、tile鍵與按鈕語意不變。
- `src/abode/living_abode.gd`／`src/presentation/abode_hud_controller.gd`：洞府建築詳情在描述與動作間新增成本列，顯示建造／升級材料、來源與前置不足／先開拓／缺料原因；按鈕文字（建造、升級、前置不足、已達上限）及命令不改。
- `building_catalog.gd`：材料列缺圖時保留24×24位置並以名稱＋`持有／需求`文字取代空白圖，已有圖與既有`25/100`、tooltip格式不變。
- `realm_teleport_modal.gd`：靈界據點卡片以共用成本列取代純文字`晉升消耗`，顯示實際持有／需求、未解鎖／材料不足；重建簽章納入成本庫存，未變更視圖仍保留卡片實例。
- 新增`tests/imm3a_cost_detail_runner.gd`並登錄`tools/run_all_runners.ps1`；runner涵蓋上述成本格、來源caption、缺料註記、運力／保留標籤、開拓境界需求、缺圖fallback及靈界據點成本更新。

驗證與修復紀錄：
- 引擎核對：本機Godot `4.7.2.stable.official.ed1daf0bf`，Compatibility；L1執行前先`-List`確認選取。新runner首輪因`manufacturing_panel.gd:417`缺換行及子類重複宣告`CostStrip`而preload失敗，修正後`--check-only`通過；靈界重建的舊卡片改先`remove_child()`再`queue_free()`，避免同幀讀到殘留成本列。
- L1（matrix=single 1280×720）：`imm3a_cost_detail_runner.gd` PASS（9.2秒）；`res1_ui1a_runner.gd`、`res1_ui1b_runner.gd`、`content_p2_supply_ui_runner.gd`、`mfg3_inline_runner.gd` 4／4 PASS（46.3／86.4／4.9／8.0秒，日誌`C:/Users/asus/AppData/Local/Temp/dao2_runners_79a2eae60c374c948e52a018667fb456`）；`m3b_alchemy_ui_runner.gd`、`content_p2_pills_ui_runner.gd`、`m4a_realm_runner.gd`、`m2d_responsive_ui_runner.gd`、`uix_r4_building_cards_runner.gd` 5／5 PASS（日誌`.../dao2_runners_a2f2c8a5c02f4991a751c183cbcdd324`）。合計10／10，無`SCRIPT ERROR`。
- L2桌面Web：以目前來源匯出`build/web-imm3a`（PCK 125,630,036 bytes，exit 0），本機`127.0.0.1:4414/launcher`載入Era3隔離fixture，Edge/CDP 1280×720真實滑鼠抽驗製造與運輸。證據`.test-output/imm3a-web/probe-mfg-open.png`、`probe-mfg-bottom.png`、`probe-transport-open.png`、`probe-transport-bottom.png`、`07-transport-detail.png`：材料需求玄銅20／中品靈石5標`當地`、加工坊靈材5／銅精5標`祖島`、運輸來源餘貨150／保留0、目的預留0／剩餘50／目標100、運力10／10秒、升運力靈材10／銅精10；無面板越界或文字重疊。只證明桌面滑鼠與尺寸呈現，不聲稱IndexedDB落盤、FPS、觸控或實機通過。
- 成本註記與禁用分離：缺料／資格只在成本列說明，未新增UI自行禁用（除原有規則已禁用者）；命令失敗仍由正式流程回報。

未通過／待辦：本階段受影響檢查無未解失敗。完整介面尚有IMM-3B／3C及最終IMM-4；本輪未執行L3、全尺寸矩陣或正式候選包。下一個New Chat做IMM-3B修行與遊歷資源。本次是階段結束，可手動commit；代理未commit／push。

<a id="imm-1c"></a>
## 2026-10-27 IMM-1C：洞府縮圖選島 DONE（階段完成，L1＋L2桌面Web抽驗）

使用者確認OpenCode已暫時完成階段，可由本對話繼續編輯。核對工作區後保留IMM-1A／1B成果，依docs43接續IMM-1C；本輪未再發現外部同檔覆寫。完整介面批次尚未結案，下一IMM-3A；不自行commit／push。

實作與修改檔案：
- 新增`src/presentation/island_selector.gd`及Godot產生的`.uid`：既有島體圖、島名／開拓狀態、當前選中印、92px寬式／80px短式整列按鈕、內捲清單、共用字型／CloseSeal。穩定ID保留列節點、選中狀態及捲動；未新增美術資產。
- `src/presentation/island_world.gd`：取代舊OptionButton及文字世界列。寬式在右側顯示可收起清單，短橫式從選島入口開共用shell tool遮罩；保留歸家、管理此島、世界地標及管理頁反向入口。照原Era／供給版本顯示現有七島；Era2丹霞仍為可查看條件的原預覽，寒銀／古藥／太虛維持Era4／5／6。點選不開拓、不扣料、不改Session。
- `src/abode/living_abode.gd`：依實際左HUD、右清單與下方操作區計算鏡頭安全區；尺寸或清單狀態變更時更新配適，自動提示讓位，主動訊息閱讀維持共用覆層。未開放選島時不新增延後排版。
- 新增`tests/imm1c_island_selector_runner.gd`及`.uid`，登錄`tools/run_all_runners.ps1`；更新`world46_runner.gd`、`res1d2_world_runner.gd`及`early_flow1d_runner.gd`以檢查新入口。docs19同步正式通則，docs43標本階段完成；README／ROADMAP僅狀態連結，英文交接在updata.txt。

驗證與修復紀錄：
- 引擎核對：本機Godot `4.7.2.stable.official.ed1daf0bf`，Compatibility。L1執行前均先`tools/run_all_runners.ps1 -Only ... -List`；未跑全量或L3。
- 最終L1共5支受影響runner通過，按依賴分兩組：`-Only 'world46_runner.gd','res1d2_world_runner.gd','early_flow1d_runner.gd' -TimeoutSeconds 180`為3／3 PASS（7.8／8.8／99.7秒，正常Windows user://環境），日誌`C:/Users/asus/AppData/Local/Temp/dao2_runners_b72a8eacf0ff478cb2d2a762037976f6`；`-Only 'imm1c_island_selector_runner.gd','m2d_responsive_ui_runner.gd' -TimeoutSeconds 120`為2／2 PASS（10.5／11.4秒），日誌`sandbox.{903b95c7-e867-41fb-996e-2cb0d2d2a5e7}/AC/Temp/dao2_runners_d134568016aa475e991e9083d97c4717`。matrix=single；既有響應式runner內的固定轉換案例保留，未擴為全尺寸矩陣。
- 新runner涵蓋七島圖像、整列命中、列節點保留、捲到末島、當前標記、管理／返回、收起／重開、真實島體投影落在安全區、完整規則snapshot不變、Era2預覽／Era1隱藏。另以`.test-output/imm1c/short_runner.gd`單獨設定844×390補驗32→33項（最後33項PASS），共用tool、世界輸入鎖、返回、抽屜界內及自動訊息避讓均通過；此為有界短式功能補驗。
- 原生1280×720／844×390視覺：`.test-output/imm1c/capture.gd`在隔離合成Era6資料輸出洞府、展開清單與遠島各圖，位於`.test-output/imm1c/`，exit0、無SCRIPT ERROR。沿用earned Era3複本再提升顯示條件，不能當自然晉階證據。
- L2桌面Web：`Godot --headless --path . --export-release Web build/web-imm1c/index.html`及`node tools/prepare_web_compression.mjs build/web-imm1c`更新本機測試包（非候選交付、不升L3），本次最終來源重新載入驗證。IAB透過隔離`127.0.0.1:4412/launcher`、iframe實測1280×720，以滑鼠點青木／太虛、捲至後期島、管理太虛／原頁返回、關清單／重開，確認選中與鏡頭避讓。證據`.test-output/imm1c/web-1280.png`、`web-review.json`；只證明桌面滑鼠操作，不聲稱IndexedDB落盤或FPS驗收。
- 中途失敗已處理：一開始把未登錄的`res1c2_world_runner.gd`用作selector，`-List`拒絕，改選正式登錄範圍；舊EARLY-FLOW在沙箱user://失敗，正常使用者環境重跑通過。共用響應式初次4項失敗，以HEAD世界／洞府副本對照確認為本次延後排版干擾，已限定作用範圍並於初始隱藏launcher，最終通過。一次`had_world_ui`型別推斷錯誤令runner逾時，補明確bool後parse與功能重驗通過。截圖輔助腳本的SaveCodec引數／content_version取用及UTF-8讀取亦修正後才採用輸出。
- 初次並行匯出自動生成7個舊證據JPG的未追蹤`.import`旁檔，runner guard拒絕；已核對僅刪除本輪生成旁檔，既有證據內容未改。最終runner guard及通用交付稽核確認證據區乾淨。保留既有anchor／沙箱shader cache／退出RID與ObjectDB警告，無SCRIPT ERROR成功誤判。

通用收尾：`python tools/trim_status_docs.py`已歸檔超過3筆的頁首歷史，updata保留最近5筆；`python tools/delivery_check.py --web build/web-imm1c` RESULT PASS（證據區0變更，Web 7／7與compression.json一致）。`git diff --check`首輪發現updata尾端空白行，修正後通過。

未通過／待辦：本階段受影響檢查無未解失敗。完整介面尚有IMM-3A／3B／3C及最終IMM-4；本輪未執行L3或正式候選包交付。下一個New Chat做IMM-3A經營成本與詳情，機緣主頁保持原版。本次是階段結束，可手動commit；代理未commit／push。


<a id="imm-1b"></a>
## 2026-10-27 IMM-1B：空島／製造／運輸共用物品格 DONE（L1＋桌面Web 1280×720抽驗）

使用者指定以fusion skill執行IMM-1B。本輪沿docs43及已接受R2／R3原則，把共用庫存正式接入空島／製造／運輸；工作區原有IMM-1A變更保留，沒有改寫存檔schema、規則命令或頁面流程。介面文字維持繁體中文。

實作：
- `recipe_material_tile.gd`：改為正方形物品格（56×56格、中央48px ICON、右下數量疊印），保留 `quantity`／`caption`／`icon`／`style`／`shortage`／`refresh(...)` 公開介面。缺料朱紅、產出青玉、正常灰青沿用；未插圖資源保留名稱＋來源caption，已插圖可依 `show_source_caption` 隱藏來源列。新增 `set_reserved()`／`reserved_visible()` 顯示左上沙漏；`refresh()` 會先清除舊預留，避免跨列殘留。
- `island_management_panel.gd`：空島頁新增 `payment_cards`／`payment_tiles` 祖島工程材料組，與「本島可用庫存」地方庫存分開；付款組只在非祖島且啟用時顯示，地方庫存、採集速率、設施成本與升級命令保持。地方／採集格接上非零預留標記。
- `manufacturing_panel.gd`：材料與產物格隱藏格內來源caption；輸入需求、缺料顏色、產物庫存與非零預留保留；加工模式、批次、保留、設定、草稿、開始／停止／返回命令未改。
- `island_transport_panel.gd`：航線兩端沿用正方物品格並保留島名caption；終點非零預留顯示沙漏，缺貨與端點未開沿用朱紅／`—`，在途仍只由狀態、倒數與進度呈現，不混入兩端可用數量。航線設定、草稿、保存、重試、升級與返回命令未改。

驗證：
- 最終L1（matrix=single 1280×720，`-TimeoutSeconds 120`）：`res1_ui1a_runner.gd`、`res1_ui1b_runner.gd`、`content_p2_supply_ui_runner.gd`、`mfg3_inline_runner.gd`、`imm1a_inventory_runner.gd` **5／5 PASS**，耗時39.6／75.4／4.9／7.9／8.0秒；日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_7bf31d3de0934843a538ec79ab41b05a`。另因共用物品格亦供煉丹使用，補跑 `m3b_alchemy_ui_runner.gd`、`content_p2_pills_ui_runner.gd` 2／2 PASS（6.0／7.4秒，日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_454cb4ed41584e009ce94562861dc922`）。檢查無`SCRIPT ERROR`；僅既有退出時RID／ObjectDB警告。斷言涵蓋付款組4格、地方預留、製造產物預留、格子56×56與右下數量、運輸終點預留、缺料／端點未開／在途分離、保存失敗重試與返回不退化。
- 獨立fusion-auditor對IMM-1B DoD逐項PASS；本輪修正其指出的ICON尺寸覆寫失效、格子幾何與空島預留覆蓋缺口。付款組零值仍作資訊性庫存顯示，不另造噪音規則；既有死碼／舊字級覆寫不影響行為，未擴大修改。
- 桌面Web抽驗（L2局部）：以本次來源重新匯出到`build\web`，本機服務埠4410載入三島試玩fixture，Edge/CDP設1280×720並實際點擊空島／製造／運輸；觀察到正方ICON＋右下數量、製造格內無來源文字列、空島地方庫存正常且祖島頁付款組按預期隱藏、運輸兩端島名與150／100數量、在途0獨立顯示。截圖留存gitignored `.test-output\imm1b-web\`。這是單尺寸桌面滑鼠抽驗，不是L3、全尺寸矩陣、觸控或IndexedDB落盤證據。

未完成：未跑L3／全尺寸矩陣／Web壓縮或交付候選包；未驗手機／平板／高DPR／實機；IMM-1C洞府選島、IMM-3A成本詳情、IMM-3B修行資源與IMM-3C全頁一致性仍待續。工作區保留IMM-1A／1B未commit變更；本階段結束可手動commit，代理未commit／push。下一步：IMM-1C。

<a id="imm-1a"></a>
## 2026-10-27 IMM-1A：共用庫存／物品元件 DONE（L1＋原生雙尺寸視覺；Web滑鼠抽驗併1B）

使用者在排程完成後明確「繼續」，授權開始IMM-1A。開工時工作區已有同批接線與專項測試，本輪先保留並核對，再於同一來源完成修正；現有變更包含 `inventory_item_cell.gd`、`inventory_panel.gd`、`ui_shell_resources.gd`、`ui_shell_controller.gd`、NumberFormatter精確提示及新runner／入口，來源並非全部由本對話新建。

最終統一來源補查／修訂：九種情境的結構化資料（宗門技術／市場可回傳群組，其餘路由明記TODO）、零庫存必需材料保留、宗門祖島材料來源、未知值null與eta不補假0、精確整數／小數提示、靜態選中樣式、鍵盤焦點／捲動恢復、`scope`避免暫時狀態錯選、就地數值刷新、短式抽屜單行摘要與寬式完整摘要、左欄底部避開左下操作列。`docs19`已補短抽屜單行摘要通則。

歷程保留：早期沙箱 `ui_shell_integration`／`mfg3_inline` 的舊 `user://` 隔離寫入失敗、`res1_ui1a` 45秒逾時，以及專項「topology refresh preserves selection and scroll」失敗與寬式詳情超出左欄的舊圖，均已於最終來源修正；舊日誌／截圖不刪除，不當最終通過證據。`res1_ui1a_runner.gd` 的50次切頁量測改為先暖機再計節點，避免首次建立庫存格造成假失敗。

最終驗證（L1，matrix=single 1280×720，`-TimeoutSeconds 120`）：`imm1a_inventory_runner.gd`、`ui_shell_policy_runner.gd`、`ui_shell_matrix_runner.gd`、`ui_shell_integration_runner.gd`、`mfg3_inline_runner.gd`、`mfg_controller_runner.gd`、`res1_ui1a_runner.gd` **7／7 PASS**；耗時矩陣26.2秒、integration8.1秒、policy2.4秒、imm1a7.6秒、mfg3 7.5秒、mfg_controller0.3秒、res1_ui1a39.1秒。日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_30bc1d06c42a4c4a8454e85be4f92476`。原生合成狀態截圖1280×720寬式與844×390短抽屜通過可讀性檢查（檔名i），暫存capture／rects工具已刪除，僅留gitignored `.test-output/imm1a-capture/`。

未完成：未做含本次來源的桌面Web滑鼠抽驗，依排程併入IMM-1B同功能完成時一次；未跑全尺寸矩陣、Web匯出壓縮或L3；觸控／實機沿延期政策。IMM-1B未開工。未commit／push。通用delivery_check與git diff --check於收尾執行。下一步：IMM-1B核心經營接入（空島／製造／運輸），沿用本契約與元件。

<a id="imm-plan"></a>
## 2026-10-27 IMM-PLAN：設計原則ACCEPTED，完整介面排程交付DONE

使用者明確「接受，先用這個版本的相關設計原則來去延伸完整介面，請安排後續介面調整」。已將R3圖像庫存、R2正方形物品格／右下數量及洞府縮圖大按鈕方向作為正式共同基線；機緣主頁保留原版。**IMM-0-STATIC ACCEPTED／設計交付DONE；本輪IMM-PLAN排程交付DONE。** 未示範的動態／音效／Shader沒有因此接受；完整遊戲介面遷移與驗收仍TODO，不把原稿IMM-0的動態候選當作靜態接入阻擋。

交付[docs43完整排程](43-full-ui-adjustment-plan.md)，沿原IMM編號分批：1A共用結構化庫存／物品元件 → 1B製造／空島／運輸 → 1C洞府選島 → 3A經營成本／詳情 → 3B修行／遊歷資源 → 3C全頁一致性 → 必要才做2微動態 → 4唯一L3收尾。排程明列洞府＋十三功能頁與共用覆層的負責批次、DoD及沿用／不適用界線，沒有將全部頁面粗暴改成倉庫格。

**下一個實作為IMM-1A，前置已滿足**：正式View產結構化項目，禁止解析details文案；集中正方物品格／庫存呈現，先接製造左欄與短式抽屜，保留來源、精確值、容量預留／在途與選中／捲動／焦點。九種情境資料契約與逐頁接線分開記錄。每批L1／L2，整批最後一次L3；不在本規劃輪跑遊戲回歸或製作候選包。

修改：新增docs43；docs19記錄接受，docs41更新實作順序，docs42檢查轉遷移清單；R2／R3 captures metadata改DESIGN_PRINCIPLES_ACCEPTED並明示範圍，viewer僅改接受標示、README補排程。README／ROADMAP一行狀態、ai-handoff最新入口、本節與英文updata同步；既有dirty成果保留。PNG／capture列表／來源hash、正式程式／資產／設定、build與玩家存檔未改，未新增圖或改動態。

驗證層級：**純規劃／接受metadata靜態檢查**。核對初始五支runner檔與run_all入口存在，只安排後續-List及L1命令，本輪未啟動runner／引擎／原生渲染／Web匯出／瀏覽器／FPS。沿用同日R3原生20PNG／10對及靜態檢視器19組的原範圍證據，未擴張為正式遊戲通過。通用trim／delivery_check／git diff與新文件連結檢查全部exit0／PASS；既有證據目錄變更0、文件連結有效，英文updata維持最近5筆。

下一步：以New Chat直接開始IMM-1A，不再要求重新確認已接受原則；後續各批依docs43推進。本輪為**規劃階段結束**，可手動commit；代理未commit／push，未在本對話展開下一大型實作。

<a id="imm-0-r3"></a>
## 2026-10-27 IMM-0 R3：庫存圖像化樣張與同類介面檢查完成

使用者指出製造左側資源區純文字拼湊，要求調整並檢查同類。本輪完成**R3樣張／來源檢查階段**，具體視覺仍IN_REVIEW；正式遊戲共用資源元件未修改。[最新檢視器](visual-prototype/imm0/index.html)／[製造比較](visual-prototype/imm0/r3/manufacturing-compare.png)／[十三頁來源檢查與處理清單](42-graphic-inventory-review.md)。

左欄改88px正方形物品ICON＋右下可用量、按島分組，選中物品才在底部顯示一份圖像／名稱／可用容量與真實容量條；完整來源／容量預留保留TIP，非零預留圖示，實際正載貨另組。短式抽屜依容器寬度排更多欄，原CloseSeal／遮罩流程保持；不合併地方與祖島庫存。中央配方沿R2、洞府沿R2、機緣主頁依決策保留原版。

來源檢查涵蓋全部13個canonical功能路由與相關詳情，確認 `UiShellResources.describe()` 把View轉長字串，再由共用殼 `context_text` 單Label呈現；9個路由可使用該元件。空島／製造／運輸／宗門功法及坊市與本次截圖最接近；其他依資源抽屜／成本條件顯示。另記製造設定、運輸詳情、宗門成本與舊靈界據點升級文字串列。區分建築／煉丹既有圖示、未掛入樹的resource_summary、TIP，以及合理的敘事／收據／帳目表，沒有把搜尋到join就當成缺陷。三個代表頁有本輪原生截圖；其餘是來源證據，不宣稱已操作或已修正。

修改：新增 `tools/imm0_inventory_study.gd` 共用隔離樣張元件、`tools/imm0_r3_samples.gd` 取樣腳本及 `docs/42-graphic-inventory-review.md`；`docs/visual-prototype/imm0/r3/` 新增20PNG／10對、比較板、metadata／日誌／瀏覽器紀錄，檢視器加空島／運輸／庫存抽屜與R2歷史入口。同步docs19新通則、docs41、README／ROADMAP一行狀態、本節及英文updata；正式src／scenes／assets／content／設定、build與玩家進度未改。既有dirty設計成果保留。

驗證層級為**設計樣張原生渲染＋桌面靜態檢視器＋來源盤點**，未跑遊戲L1／L2／L3、全runner、Web匯出或FPS。Godot --version exit0（4.7.2）；`--headless --path . --script res://tools/imm0_r3_samples.gd --check-only` exit0。最終 `--path . --script res://tools/imm0_r3_samples.gd --audio-driver Dummy --rendering-method gl_compatibility --log-file E:/WORK/Dao2/.test-output/imm0-r3-engine.log` exit0；20圖尺寸、10對狀態hash、渲染前後不改狀態及庫存格實際正方／≥44px檢查通過。使用同一Era3合成展示資料，不是自然遊玩、正常命令或保存故障證據。保留既有cache／anchor／退出RID診斷。

初輪研究元件Variant推型警告當錯誤而未編譯；修正後跨代表頁又發現R2幾何檢查持有前一場景已釋放格參照，第二輪雖exit0但有SCRIPT ERROR，明確不算通過。已每次清除參照，最終[日誌](visual-prototype/imm0/r3/native-capture.log)無SCRIPT ERROR；兩次失敗留 `.test-output/imm0-r3-first.log`／`imm0-r3-second.log`。通用PNG／狀態靜態核對曾因第二輪SCRIPT ERROR拒絕交付，修正後才封裝。

IAB樣張頁19組頁／狀態／尺寸全部圖片載入，7組機緣仍僅顯示原版；這是靜態檢視器，不是Web遊戲滑鼠／保存驗收。[記錄](visual-prototype/imm0/r3/browser-check.json)與[取樣追溯](visual-prototype/imm0/r3/captures.json)。通用收尾採 `python tools/trim_status_docs.py`、`python tools/delivery_check.py` 與 `git diff --check`，全部exit0；delivery_check RESULT PASS、既有證據目錄變更0，diff無空白錯誤。

下一步：收圖像庫存樣張回饋，接受後New Chat集中遷移正式共用情境資源元件，再分批處理docs42的成本詳情；不把樣張當九個路由已完成。此次為**樣張／介面檢查階段結束**，可手動commit；未commit／push，不自動開IMM-1大型實作。

<a id="imm-0-r2"></a>
## 2026-10-27 IMM-0 R2：三頁決策已記錄，兩頁修訂樣張交付

使用者否決洞府R1改動幅度、製造長方形材料格，並指定機緣先保留原版。本輪完成**R2樣張修訂階段**，方向同步docs19／docs41；洞府／製造具體新樣張仍IN_REVIEW，機緣保留原版已決定，不再要求重選。正式遊戲接線未啟動。

交付[同一檢視器R2](visual-prototype/imm0/index.html)、[洞府大圖清單](visual-prototype/imm0/r2/home-compare.png)與[製造正方ICON](visual-prototype/imm0/r2/manufacturing-compare.png)。洞府以原島體縮圖＋島名放在92px／短式80px大列按鈕中，短式清單內捲及共用CloseSeal；HUD保留正式版。製造材料及產出格改68px／短式56px正方形，物品填圖、數字右下疊印與描邊，原來源／持有需求tooltip保持，不另加名稱／來源文字列；缺料與禁止開始沿原View。機緣檢視器僅顯示原版，隱藏候選比較，原正式來源未修改。

新增 `tools/imm0_r2_samples.gd`，基底 `tools/imm0_samples.gd` 僅將輸出與取樣列表開為可覆寫；新增 `docs/visual-prototype/imm0/r2/` 的12張PNG／6對、兩張比較板、captures.json、日誌與瀏覽器紀錄。檢視器／README改R2並保留r1-index歷史入口；docs19、docs41、README／ROADMAP、本節及英文updata同步。正式src／scenes／assets／content／設定、build及玩家進度均未修改，原dirty設計成果保留。

驗證為**設計樣張原生渲染與桌面靜態檢視器**，不觸發遊戲L1／L2／L3、Web匯出或FPS：Godot --version exit0／4.7.2；`Godot --path . --script res://tools/imm0_r2_samples.gd --audio-driver Dummy --rendering-method gl_compatibility --log-file .test-output/imm0-r2-engine.log` 最終exit0。12張尺寸、6對相同狀態hash及渲染不改狀態核對通過；材料格實際寬高差≤1px、四島列逐一內捲可達且高度≥80px。初輪發現寬式清單高度不足及已釋放caption仍被View刷新，已改明確清單容器最小高度及保留隱藏caption參照；初輪exit1／SCRIPT ERROR保留 `.test-output/imm0-r2-capture.log`。最終[日誌](visual-prototype/imm0/r2/native-capture.log)無SCRIPT ERROR，既有cache／anchor／退出RID診斷保留，非乾淨引擎退出聲稱。

IAB桌面檢視器13組頁／尺寸／狀態全數圖片載入；7組機緣均只顯示原版且候選隱藏。只證明靜態檢視器，非正式遊戲滑鼠命中／故障保存。圖片、原生狀態及來源hash記[metadata](visual-prototype/imm0/r2/captures.json)；機緣沿用R1同日原版PNG，沒有重跑機緣。`python tools/trim_status_docs.py`／`python tools/delivery_check.py`／`git diff --check` 作通用收尾，全部exit0，delivery_check RESULT PASS、既有證據目錄變更0，diff無空白錯誤。

下一步：收洞府清單及製造物品格的具體樣張回饋，接受後New Chat接正式共用呈現；機緣維持原版。這是**樣張修訂階段結束**，可手動commit，未commit／push，不自動展開IMM-1。

<a id="imm-0"></a>
## 2026-10-27 IMM-0：三頁樣張交付完成，視覺定稿 IN_REVIEW

使用者指定「三頁對照樣張」。交付[可切換對照頁](visual-prototype/imm0/index.html)及[洞府](visual-prototype/imm0/home-compare.png)／[製造](visual-prototype/imm0/manufacturing-compare.png)／[機緣](visual-prototype/imm0/fortune-compare.png)三張並排板。**本輪樣張交付階段完成；IMM-0完整DoD仍待使用者確認材質、密度與動態方向，不標正式換皮DONE。**

候選在隔離Godot場景試排：洞府淡紙深墨／目的地同列；製造寬式單列、放大產物、材料來源／需求、模式／設定及真實7秒倒數保留，缺料補文字數量；機緣寬式左情境右選項、短式保留首個動作及原內捲區，合併重複頁題與保存回饋。共用GameTab、CloseSeal、字型與插圖B沿既有元件，沒有核定新的通則或加入動態／音效。短式就緒敘述改TIP，不縮字。

交付26張PNG／13組同資料對照：洞府正常、製造加工中／缺料、機緣待決／感應就緒／保存異常，兩種尺寸1280×720、844×390；另含短式待決選項末段。每對讀相同展示狀態，狀態hash相同；26次渲染前後狀態不變，PNG尺寸與hash核對通過。資料由既有Era3 fixture複製後補庫存／指定工作與待決事件，明示為合成展示；7秒為凍結的View值，保存異常為呈現注入，不是自然遊玩、合法事件命中、新保存故障或收益證據。世界特效相位未作像素級同步，不宣稱兩圖為相同動畫幀。

修改：新增 `tools/imm0_samples.gd` 隔離取樣工具、`docs/visual-prototype/imm0/` 靜態圖／瀏覽器／captures.json／原生日誌與使用說明；docs41加樣張導引、README／ROADMAP一行狀態、本節及英文updata。正式src／scenes／assets／content／project設定、build與玩家存檔未修改；既有dirty設計文件與歸檔保留。

驗證層級：**設計樣張原生渲染＋桌面瀏覽器檢視，未執行遊戲L1／L2／L3回歸**。未修改正式接線，不啟動全runner、Web匯出、候選包或FPS量測。

- `Godot --version`：exit0，4.7.2.stable.official.ed1daf0bf。
- `Godot --path . --script res://tools/imm0_samples.gd --audio-driver Dummy --rendering-method gl_compatibility --log-file .test-output/imm0-engine.log`：最終exit0／26張；短式三個機緣選項逐一捲到按鈕，44px與位於內捲可視區檢查通過。只證明原生幾何可達，不等於實際滑鼠命中。早期工具型別／資料路徑／重複變數錯誤已修正，失敗留 `.test-output/imm0-first.log`／`imm0-final.log`；非首次即全綠。最終[原生日誌](visual-prototype/imm0/native-capture.log)無SCRIPT ERROR；保留既有anchor提示、user shader cache不可寫及退出Font／CanvasItem／ObjectDB RID診斷，不稱乾淨引擎退出。
- Python靜態核對：26張尺寸／寫入與13組狀態hash一致；三張板僅原圖並排。追溯記於 [captures.json](visual-prototype/imm0/captures.json)。
- IAB真實桌面樣張頁：13組頁／狀態／尺寸選擇對應圖片全部載入；現況／候選放大與並排切換通過。這是靜態檢視器，不是Web遊戲驗收。初用系統Python4401服務連線逾時，已停；改Codex bundled Python4402成功。保留 [4402檢視器](http://127.0.0.1:4402/index.html)供審閱，僅暴露樣張目錄；非公開發布。
- 通用收尾：`python tools/trim_status_docs.py`、`python tools/delivery_check.py`、`git diff --check`，全部exit0；delivery_check RESULT PASS、既有證據目錄變更0，diff無空白錯誤。[樣張瀏覽器記錄](visual-prototype/imm0/browser-check.json)已保存；不新增專屬closure／audit腳本。

下一步：使用者審閱三頁，確認或指出需修訂部分；接受後再以New Chat接IMM-1共用呈現試點。動態僅沿docs41建議、未做試播，不因靜態樣張推定已接受。此次為**樣張交付階段結束**，可手動commit；代理未commit／push，不自動展開下一大型實作。

<a id="ui-immersion-design"></a>
## 2026-10-27 UI-IMMERSION-DESIGN：設計交付 DONE，視覺升級待核定

使用者要求閱讀Claude建議並提出最終版本；本輪僅完成建議書，未授權或啟動正式換皮。交付[最終建議稿](41-game-ui-immersion-and-aesthetic-final.md)，保留原提案並加導引。核對UiMaterial、GraphicAction及共用殼／字型／插圖規範，建議清雅仙家手卷、三頁試點與分級動態；修正全面禁Flat、全互動彈跳、全頁消融及重建Theme的建議。沒有最新全頁視覺操作觀察，不將程式存在等同美術品質驗收。

修改：新增最終稿，原提案加連結，README／ROADMAP一行狀態，本節、英文updata及通用trim歸檔。未改遊戲來源、資產、build或玩家存檔；docs19既有核定規則保持，新建議尚未當作通則。

驗證：Godot --version exit0（4.7.2.stable.official.ed1daf0bf）；本輪僅文件靜態檢查，未執行L1／L2／L3、Web匯出、FPS或瀏覽器驗收。收尾使用 python tools/trim_status_docs.py、python tools/delivery_check.py、git diff --check；trim與delivery_check均exit0／PASS，證據目錄變更0；diff初檢發現updata尾端空行，已移除並補驗。

下一步：使用者審閱方案後，新對話啟動IMM-0三頁對照樣張；沒有自動開始P3或正式畫面修改。本次為設計階段結束，可手動commit；代理未commit／push。


<a id="content-p2-accept"></a>
## 2026-10-27 CONTENT-P2-ACCEPT：P2 整合收尾 DONE（桌面／Web有界）

使用者指定「P2 整合收尾」。本任務依各批已記錄的美術／卡片／節奏接受及同日最新 WORLD-46-L3，完成 Era4–6 的整段計數、相依、供給與跨系統流程證據核對。**P2 現行 Era4–6 內容範圍整合 DONE**；法令新增四項沿原計畫的 realm 可玩條件延期，不列入已交付。不以本次收尾擴張九界、Era7–12或全量舊檔相容承諾。

### 整合數量與相依

| 系統 | 正式定義總數／交付 | 完成依據與界線 |
| --- | --- | --- |
| 供給／世界 | 7島、12航線、11加工配方；Era4–6三島分層世界 | [供給收尾](verification/content-p2-supply-closure.md)、本檔WORLD-46-L3；Era7仍未開。 |
| 一般技能 | 24（P2新增12） | [SKS-P2](verification/sks-p2-closure.md)，12項合法研習／付款、保存與輪迴清除。 |
| 輪迴天賦 | 9（新增3） | [TALENT](verification/content-p2-talents-closure.md)，合法輪迴首購與跨世；滿階對照為明示合成預算。 |
| 丹藥 | 20（新增8） | [PILL](verification/content-p2-pills-closure.md)，實料煉製／服用／到期／保存；模擬秒可達。 |
| 宗門 | 8功法／30委託模板／8商品 | [SECT](verification/content-p2-sect-closure.md)，五品階各6模板，候選保存閘與三橫式操作。 |
| 靈獸 | 6獸／24獸魂天賦 | [BEAST](verification/content-p2-beasts-closure.md)，新增鹿／鶴；既有雲蛟Era8仍鎖定，6為定義數，非全6獸當前可達。 |
| 敘事 | 48成就／56機緣 | 本檔STORY-2-L3；18+12+18成就與56事件靜態計數一致，不宣稱全部自然命中／領取。 |
| 界域法令 | 14，未追加原目標4項 | docs25原已規定依對應realm實際可玩才交付；條件延期，非當前Era4–6整合阻擋，不稱18項完成。 |

供給→技能／天賦／丹藥→宗門／靈獸→敘事之相依均有各批DONE；WORLD-46補齊三島世界／管理往返。最新140支L3同時包含這些核心、保存、UI及flow runner，沒有只靠分批總數推論整合。已賺得Era3快照經正式命令／模擬秒至Era6十層、壽盡輪迴之94項供給流程，以及技能、丹藥、天賦、宗門、靈獸與敘事各代表流程沿用既有證據；**不是本輪空白新檔、自然等待的瀏覽器完整一生**。各批桌面保存故障／重試／重載與三橫式操作按原日期及候選範圍引用，不冒稱全在最新包再走一次。

### 本次修改與驗證

只改README、ROADMAP、docs25、ai-handoff、本檔、英文updata與通用trim產生的archive；修正docs25宗門仍IN_PROGRESS、Roadmap P1列仍稱P2未開始的過時指標。未改正式遊戲來源、資產、規則／RNG、存檔或玩家進度；既有WORLD-46未提交成果完整保留。

- 靜態JSON／GDScript常數核對上述唯一ID與數量；宗門字典按括號深度取直接鍵，避免縮排不同把欄位誤算內容ID。技能24、天賦9、丹藥20、宗門8／30／8、靈獸6／24、成就48、機緣56、法令14。
- 本機 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` exit0：`4.7.2.stable.official.ed1daf0bf`，未更新環境。
- **沿用L3（2026-10-27）**：[WORLD-46摘要](verification/artifacts/world46-l3/summary.json)140個唯一runner全部status=PASS／exit0；17+123最終分段通過、full矩陣。保留沙箱中斷exit1、首段guard未完成與批次log缺失的原記錄，不改寫為一次全綠。一般Web當日已同步／壓縮，三島三橫式9次地標操作通過。
- **本輪僅文件靜態驗證，未新增L1／L2／L3**。依AGENTS的「依變更決定驗收」，不為整合索引再跑Full、匯出或瀏覽器。
- 收尾命令：`python tools/trim_status_docs.py`、`python tools/delivery_check.py --web build/web --manifest assets/abode/world46/manifest.json`、`git diff --check`。實際均exit0：trim完成五份prelude歸檔；delivery_check RESULT PASS，Web 7/7、ACCEPTED manifest 6/6；git diff --check通過（僅既有delivery_check.py的LF→CRLF提示）。證據路徑仍僅原有WORLD46兩目錄，無本輪新增或改寫。靜態模板檢查初次誤查title欄位失敗，改按實際name及legacy／P1／P2三表重驗15+5+10=30；無正式來源修改。

### 保留限制與下一步

既有長時WebGL `RangeError: Invalid array length` 未因有界驗收而修復；本次不宣稱FPS／長時穩定性通過。實機依使用者政策延期，非當前阻擋。法令擴充須待對應realm工作；Era8雲蛟與Era7–9供給仍屬後續P3範圍。

依Context Guard停在**P2大型任務整合結束**。可手動commit；代理未commit／push。下一New Chat由使用者指定 `RES1-E-79` 來源稽核／規則設計或其他工作，尚未啟動P3實作，也不重開已接受P2美術與節奏。


## 2026-10-27 WORLD-46-L3：美術 ACCEPTED，整批 DONE（L3／桌面 Web 有界）

使用者明確「美術接受與唯一 L3」。寒銀／古藥／太虛六張分層美術與WORLD-46-B接入呈現已ACCEPTED；六張原圖／候選／runtime像素保持。CONTENT-P2-SUPPLY相依已滿足，三島分層世界、七島入口、管理雙向、十二線真實貨運與Era／版本／輪迴回退沿B實作。**WORLD-46整批DONE**，只收本批；下方A／B的PENDING與IN_PROGRESS為接受前歷史。

### 修改與交付

- `docs/art-assets/world46/manifest.json`／`assets/abode/world46/manifest.json`、資產README記錄使用者原話、接受日期與已接入狀態；保留完整來源、提示詞、原圖／padding候選／runtime雜湊與授權界線。沒有重畫或改正式規則、RNG、保存schema、玩家進度。
- docs07／08／19同步接受註記，既有共用字型／OptionButton／44px／殼保持；README／ROADMAP／ai-handoff僅狀態連結，詳細結案只在本節。`updata.txt`英文checkpoint保留五筆，舊筆歸檔；prelude由通用trim工具保留三筆。
- `tools/world46_review.html`加三種受限iframe尺寸參數；只屬隔離驗收工具。`tools/delivery_check.py`支援分層資產已宣告的original／candidate／runtime各自hash，runtime仍必須等於候選；既有等位元組manifest契約保留。當輪沒有新增遊戲來源修改，開始前B既有dirty成果保持，未commit／push。

### 唯一 L3：140／140 最終分段通過，全尺寸矩陣

Godot `--version` exit0：`4.7.2.stable.official.ed1daf0bf`。先 `tools/run_all_runners.ps1 -Full -List`確認140支，再唯一一次 `-Full -Parallel 3 -TimeoutSeconds 3600`（matrix=full）。3600秒依同日既有供給1424秒／八丹549秒證據，TEMP／TMP與輸出隔離在`.test-output`。

沙箱首段17支有效PASS；八丹UI舊`user://pill2-ui-runner`初始化停滯，停止批次exit1，首段guard未完成，不能稱首輪全綠或首段證據guard已通過。未完成的八丹／天賦流程不計成功。保留17支完成stdout／stderr；停滯程序未flush的輸出不可補造。改用 `-Only`精選剩餘123支，先List後 `-Matrix full -Parallel 3 -TimeoutSeconds 3600` 主機續跑；不是第二次Full。**123／123、exit0、guard PASS，沒有串行重試；合計140／140唯一runner最終分段通過。** 主機八丹UI11.8秒通過，正式UI未為驗收而修改。

| 關鍵證據 | 本次實際結果 |
| --- | --- |
| WORLD46 | 92 checks／12.3秒／exit0，全尺寸三島、地標／管理往返、全快照不變、新貨運端點／零貨隱藏、Era／版本／輪迴回退。 |
| 完整供給 | 94 checks／1298.5秒／exit0，正常命令與模擬秒，Era3→6及壽盡輪迴；不是自然等待的真人通關。 |
| 長流程 | 八丹542.2秒、天賦338.8秒、技能159.3秒，全部exit0。 |
| 共用依賴 | 全尺寸殼／響應式／運輸／製造、保存故障、離線parity及其餘registry項目全部PASS；屬CLI證據。 |
| 檢查器驗證 | 兩份WORLD46各6/6；既有STORY2等位元組manifest20/20；隔離副本故意改錯runtime hash確實被拒絕（預期失敗），原資產未改。 |

[140支清單與分段摘要](verification/artifacts/world46-l3/summary.json)、[原始runner stdout／stderr](verification/artifacts/world46-l3/logs/)、[初段範圍與限制](verification/artifacts/world46-l3/initial-summary.json)、[續跑精確selector／命令](verification/artifacts/world46-l3/resume.ps1)、[最終工具輸出摘錄](verification/artifacts/world46-l3/resume-completion.txt)、[精選JSON報告](verification/artifacts/world46-l3/reports/)。`Write-Host`資訊串流未經Tee-Object，`full.log`／`resume.log`實際沒有建立；不冒稱有完整批次raw命令log，140支各自完整日誌已封存。封存發生在主機guard結束後，沒有備份／還原全部既有JSON或新增專項closure／audit腳本。

### 同版 Web 與桌面三橫式

正常 `Web`／`World46Review` 的 `--headless --path . --export-release`均exit0，各 `node tools/prepare_web_compression.mjs build/對應目錄` exit0；一般`build/web`已同步。兩包核心壓縮與四首BGM companions各7/7 hash相符。匯出曾自動生成七份舊STORY2截圖`.jpg.import`，只移除本次新增sidecars，原圖未改；不稱整段無暫時檔案變動。

隔離IAB4399實際滑鼠：1280×720／844×390／800×360各點三島地標（9/9），進正確outposts管理、前往返回世界、七島選單與返回祖島可用。場景synthetic Era6／全島已開／規則時鐘暫停，只證呈現命中。一般Web隔離4400空白Era1正常入口／關閉摘要已驗，當次console warn/error抓取空陣列，不等同全遊戲零警告。

| iframe CSS | canvas CSS | backing | Godot邏輯 |
| --- | --- | --- | --- |
| 1280×720 | 1280×720 | 1600×900 | 1280×720 |
| 844×390 | 844×389 | 1055×487 | 779×360 |
| 800×360 | 800×360 | 1000×450 | 800×360 |

[桌面摘要／路由狀態／截圖](verification/artifacts/world46-l3/browser/)、[1280寒銀](verification/artifacts/world46-l3/browser/deep-1280.png)、[844古藥](verification/artifacts/world46-l3/browser/ancient-844.png)、[800七島選單](verification/artifacts/world46-l3/browser/menu-800.png)。沙箱4398服務無法由桌面連線，改主機4399後成功，最初連線逾時不算通過；read-only DOM跨iframe量測第一次介面不支援，改frameLocator後成功。不新增FPS、自然時間首段或瀏覽器保存故障證據；未變的規則／保存範圍沿同日STORY2 L3歷史證據，不擴張聲稱。原生Font RID等既有退出診斷保留。

驗收分頁已關閉，未設viewport override；本輪4398／4399／4400服務已停止，Ctrl+C exit1為主動終止。最終 `python tools/delivery_check.py --web build/web --web build/world46-review --manifest assets/abode/world46/manifest.json --manifest docs/art-assets/world46/manifest.json` exit0／RESULT PASS：兩Web各7/7、兩manifest各6/6；git證據變動只有既有WORLD46與本輪L3兩個目錄。`git diff --check` exit0（只保留既有LF→CRLF提示）。

### 結案停點

依Context Guard停在**WORLD-46大型任務結束**；可手動commit，代理未commit／push。請開New Chat由使用者指定下一個大型任務，不重做已接受美術、不為純文件再跑L3，也不自動開始其他P2／P3。


## 2026-10-27 WORLD-46-B：三島世界接入階段 DONE（L1／L2），整批 IN_PROGRESS

使用者當輪指定 `WORLD-46-B`，沿A候選接入；這是正式來源接入授權，沒有把未明說的最終美術接受改成ACCEPTED。CONTENT-P2-SUPPLY相依已滿足。交付範圍／驗收為三島分層世界、境界／版本限制、七島導覽、管理雙向、真實貨運及輪迴回退，受影響L1與一次桌面Web L2完成。**B接入階段DONE；WORLD-46整批仍IN_PROGRESS，美術接受PENDING，整批L3尚未執行。**

### 修改與交付

- `src/presentation/island_world.gd`：新增deep／ancient／void獨立世界座標與島體／地標Sprite2D，沿A預覽比例及共同接地線；只有供給版本及Era4／5／6達標才顯示／延後載圖，開拓前隱藏地標。供給版世界列使用共用OptionButton容納七島，控制44px、選單加高；管理／返回祖島沿原殼與相機。隱藏世界不可命中，境界／版本失效回祖島。原四島的舊版本入口保持原行為。
- 貨運改讀 `IslandEconomy.route_defs(state)`，涵蓋全部十二線；新五線從各自正確原料島到祖島，只有實際正貨量才顯示。無裝飾返航、無動畫收益，不改數值／規則／保存schema。原料地標透明像素命中後進當島管理；原三工坊仍進原配方，不再無條件索引不存在的RECIPES。
- `island_management_panel.gd`：新島前往入口依版本／境界／開拓可用；原料島不顯祖島建築或製造工坊捷徑。`assets/abode/world46/`六張PNG與runtime manifest；像素與候選完全相同，來源／提示詞／原圖／候選／runtime雜湊保留。docs/art-assets manifest同步實際接入狀態，acceptance維持PENDING。
- `tests/world46_runner.gd`／registry新增呈現契約；更新供給UI的舊「世界未開」斷言及丹霞的選單預期。丹霞、responsive舊runner保存目錄改讀DAO_TEST_STORAGE_ROOT，修正沙箱啟動失敗；未改正式保存。新`.uid`保留。
- `tests/world46_review.gd/.tscn`、project feature／World46Review preset、`living_abode.gd`唯一隔離namespace、`tools/world46_review.html`提供可重現的暫停時鐘synthetic Era6滑鼠場景。正常遊戲不啟用該feature，正常Web的tests排除保持。測試包包含測試來源，不作交付候選包；一般build/web未同步，留整批收尾。

### 實際命令與驗收結果

Godot `--version` exit0：`4.7.2.stable.official.ed1daf0bf`；editor `--headless --path . --editor --import`完成。開始前git工作區乾淨，未commit／push，未操作玩家保存。

**L1**先 `tools/run_all_runners.ps1 -Only 'world46_runner.gd,res1d2_world_runner.gd,content_p2_supply_ui_runner.gd,feature_navigation_runner.gd,m2d_responsive_ui_runner.gd' -List`確認五支；實際分段最終五支全部exit0／單尺寸。初次List誤選不在registry的res1c2_world_runner被拒絕，改選後才執行。首輪WORLD46在未初始化唯讀View前比較synthetic快照失敗；先refresh取得基準後通過。丹霞／responsive舊user://無法寫入導致nil、SCRIPT ERROR及120秒逾時，另一診斷responsive逾時90秒；不計成功。兩runner改隔離目錄後分別9.5秒、9.5秒通過，navigation12.7秒通過。新WORLD46最後單支9.7秒exit0，50項契約通過；包括三島地標／雙向入口、全snapshot不變、五條新線正端點／零貨隱藏、Era限制、舊版本不可命中、輪迴回退。供給UI首輪5.1秒exit0沿用，正式供給核心沒有修改。最終runner guard均通過；原失敗命令紀錄保留，不宣稱首輪全綠。

**L2有界呈現**：原生非headless WORLD46同50項exit0；`--headless --path . --export-release World46Review`最後exit0，`node tools/prepare_web_compression.mjs build/world46-review`exit0。首次匯出缺少目標資料夾exit1，建立目錄後成功；popup加高後已重新匯出。沒有Full、沒有全尺寸矩陣、沒有FPS／自然時間通關聲稱。

桌面IAB實際滑鼠：三島選單切換、寒銀／古藥／太虛地標點進當島管理、前往返回世界、太虛返回祖島通過。最終選單每項約50px，無七鈕堆疊。iframe1280×720，實測canvas CSS1279×719／backing1280×720／Godot logical1280×720，差異如實記錄；不是實體裝置證據。場景為synthetic Era6／三島已開／暫停規則時鐘，只證呈現與命中，不證新檔可達、自然時間進度或新保存故障矩陣。BGM companions製作前出現下載失敗警告，後續已複製原曲檔，但未宣稱音訊重驗通過；原生保留既有anchor／RID／ObjectDB退出診斷。最終美術仍待使用者接受。

[本輪命令、原失敗及三島實際Web圖片](verification/artifacts/world46/)、[寒銀](verification/artifacts/world46/deep.png)、[古藥](verification/artifacts/world46/ancient.png)、[太虛](verification/artifacts/world46/void.png)。證據在runner guard結束後才封存；editor額外生成的七份無關舊截圖`.jpg.import`已刪除，未改既有圖片／報告。收尾使用通用delivery_check（含隔離Web hash）與git diff --check，不新增closure／audit腳本。

最終 `python tools/delivery_check.py --web build/world46-review` exit0／RESULT PASS（7／7 Web與音樂檔hash相符）；`git diff --check` exit0。六張runtime／candidate／original各自宣告hash全部相符。瀏覽器視口已reset、驗收分頁已關閉，本輪4396／4397服務已停止。

### 階段停點與下一任務

下一New Chat先收三島接入畫面回饋／最終美術接受；整批確認後才安排WORLD-46唯一L3及一般Web候選包同步。未做本輪新世界的短式Web驗收，不引用舊世界尺寸證據；留整批收尾。依Context Guard停在B階段，可手動commit（階段結束，非整個WORLD-46大型任務完成）。


## 2026-10-27 WORLD-46-A：寒銀／古藥／太虛世界美術候選交付，整批 IN_PROGRESS

使用者指定「寒銀／古藥／太虛三島世界」。稽核確認 CONTENT-P2-SUPPLY 規則已DONE，但 `island_world.gd` 只有 wood／ore／herb，管理頁仍明示三新島世界未開；本輪先完成美術候選階段，依 AGENTS「未經美術驗收不得在島上亂放地塊或名稱牌」保留人工接受門檻。**WORLD-46-A候選交付；美術PENDING；整個三島世界尚未DONE，也尚未接正式入口。**

### 交付與範圍

`docs/art-assets/world46/`：六張獨立RGBA候選（3島體＋3地標）、7張生成原圖（含古藥地標初稿與v2）、7份完整手寫提示詞、manifest、三張分島預覽、總覽review.png、接入契約README與`.gdignore`。來源為內建image_gen，未使用外部API金鑰或第三方素材；不宣稱第三方商用授權。候選只加四邊64px透明留白，無重繪／裁切／色鍵；合成預覽才縮放。古藥初稿厚岩座不選，v2改薄底；最終預覽地標底端410、島體頂218（600×610預覽座標）以避免浮空。原圖含柔透明邊霧，保留供審稿，不宣稱工具留白能恢復原圖缺失像素。

`README.md`／`ROADMAP.md`僅新增一行狀態連結，`docs/ai-handoff.md`新增接手指標；英文checkpoint置`updata.txt`頂部並維持最近五筆，舊筆歸檔。沒有修改正式遊戲來源、經濟、保存、既有美術或匯出物；所有先前dirty修改與備份搬移刪除均保留。

### 命令與驗證（美術／文件靜態範圍，未執行L1／L2／L3遊戲回歸）

- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。
- 內建image_gen六次生成＋古藥地標一次修訂完成；專案複製成功。Pillow12.2.0合成：`.test-output/world46/assemble.py` exit0，六張RGBA／透明安全邊斷言通過；原稿到候選只做padding，沒有用Python繪製創作素材。
- 六張來源與候選SHA256／提示詞存在／PENDING／runtime_integrated=false 靜態斷言exit0。目視檢查六張原圖與最後合成圖，選用古藥v2；候選審美仍由使用者接受，未冒稱已ACCEPTED。
- `git diff --name-only -- src/presentation/island_world.gd src/presentation/island_management_panel.gd` 無輸出，該兩正式來源未改；沒有遊戲runner、import、Web匯出、瀏覽器互動、FPS或全量回歸聲稱。
- 收尾採 `python tools/delivery_check.py`（唯讀分組摘要）；PENDING manifest不送其僅接受ACCEPTED的`--manifest`gate，六資產hash已獨立靜態檢查。 實際exit0／RESULT PASS；摘要顯示既有22082筆dirty entries，其中證據路徑21901筆，這是工作區總狀態，不能解讀為本輪新增或已逐筆驗證。

git diff --check 首次exit1指出updata末尾多餘空行，移除後補驗；不是遊戲或資產驗證失敗。

### 下一步與階段停點

先由使用者檢視[三島候選](art-assets/world46/review.png)。接受或指定修訂後，用New Chat續WORLD-46-B正式Godot接入：七島入口的短式分組／選單、Era4–6與版本可見性、世界／管理雙向與原料島地標路由、供給catalog新航線端點／真實載貨、延後載圖與輪迴回退；沿既有相機與共用殼。需避免直接索引三原料島不存在的RECIPES，或只畫舊七航線造成新貨物落到祖島零座標。以受影響L1／L2驗證，不因美術接受或New Chat升L3。

依Context Guard停在此候選階段；可手動commit（階段checkpoint，非三島世界大型任務結束）。代理未commit／push或操作玩家保存。


## 2026-10-27 STORY-2-L3：文稿／節奏接受，整批 DONE（L3／桌面Web有界）

使用者明確「文稿／節奏接受與唯一 L3 收尾」。沿同日已接受的20圖、正式卡片與UI-R1呈現，文稿及目前節奏已ACCEPTED；proposal同步原話、日期與完成狀態，修正其舊policy.art.accepted=false與已接受art_assets不一致。**CONTENT-P2-STORY／STORY-2整批DONE**；只收本批，不放行其他歷史大型任務。下方接受前的IN_PROGRESS／PENDING保留為日期化歷史。

### 交付與修改檔案

- 接受／狀態：`docs/design-data/content-p2-story-proposal.json`、`docs/40-content-p2-story-design.md`、README／ROADMAP／docs25／ai-handoff／本檔及英文`updata.txt`，舊prelude與第六筆checkpoint依既有工具／archive規則歸檔。美術manifest維持同日ACCEPTED與20張原有PNG，沒有改圖、文案、節奏、正式規則／數值／RNG或玩家保存。
- 測試隔離：既有`tests/runner_result.gd`新增共用`output_path`；舊runner報告、生成fixture、原生圖導向`DAO_TEST_STORAGE_ROOT`或`.test-output`，生成後的同檔readback沿相同出口，輸入證據仍讀原來源。`src/verification/res1d2_contract.gd`兩個生成fixture也改隔離出口，沒有新增正式核心模組。[呼叫檔案清單](verification/artifacts/content-p2-story-l3/isolation-changes.json)；既有`.uid`保持。
- `tests/content_p2_sect_flow_runner.gd`專用隔離目錄；`content_p1_story_ui_runner.gd`／`uix_r6_achievement_ui_runner.gd`舊30／18總卡數改48並仍驗原P1／legacy；R6等待初始化及保存路徑隔離。`decision_ui_runner.gd`改捲到末按鈕本身，以兩行實際字型高度及收據末端可捲達取代加入固定倒數前的70px常數。`res1_ui1b_runner.gd`對照成功回饋前後閱讀區／首卡幾何保持，取代短式可捲長卡必須整張同屏的舊假設。**未為通過測試修改已接受的正式UI**。
- 開發驗收頁`tools/story2_acceptance_server.py`只加1280／844／800的iframe尺寸參數，未改遊戲或輸入存檔。正常Web排除tests及src/verification；其後測試工具修訂不影響本輪包的正式遊戲來源。

### 唯一L3與實際結果

Godot `--version`為`4.7.2.stable.official.ed1daf0bf`。先`run_all_runners.ps1 -Full -List`確認139支，再唯一一次`-Full -Parallel 3 -TimeoutSeconds 600`（matrix=full）。沙箱首輪15支有效PASS；舊宗門長流程因證據目錄寫入失敗、null FileAccess及空載入出現SCRIPT ERROR，停止停滯程序後中止首輪，tool exit1。未完成項不計通過，首輪guard未完成，**不能宣稱該輪證據目錄未變**。首輪command log及精選JSON保留；沙箱TEMP在中止後消失，沒有冒稱完整raw stdout已封存，也沒有為純日誌重跑已通過流程。

依原registry扣除15支，以`-Only`124支先List，再`-Matrix full -Parallel 3 -TimeoutSeconds 3600`主機續跑；TEMP／TMP與storage均設`.test-output/story2-l3/`，3600秒預算依既有1482秒供給／572秒八丹長流程，不是第二次Full。主機初輪另有下列三項舊斷言失敗，修訂後由同一入口自動串行重試。**主機124／124 exit0，guard通過；合計139／139唯一runner最終分段通過、全尺寸矩陣完成。不能改寫為首輪一次全綠。** 初輪15支在輸出目的地調整後另做`--check-only`，15／15語法通過；共用隔離出口由主機各功能實際使用驗證。

| 實際範圍 | 結果 |
| --- | --- |
| STORY-2核心／保存／事件／UI | 1320／557／547／1997 checks，全部failures=[]；UI為full三尺寸。 |
| STORY-2合法Era4–6代表流程 | 310 checks／227.5秒／exit0；原已賺得起點、正常命令與模擬秒，不當自然真人等待。 |
| 完整供給 | 94 checks／1424.2秒／exit0，Era3→6第10層、Era7拒絕與壽盡輪迴終態通過。 |
| 八丹／宗門／天賦／技能長流程 | 八丹64項／548.8秒，宗門44項／44.9秒，天賦339.8秒，技能197.1秒，均exit0。 |
| 原失敗→同輪串行重試 | P1 UI30卡→48卡，26秒；decision最短尺寸末按鈕／收據，9.2秒；運輸短式首卡舊假設，85.1秒。全部exit0，原失敗stdout／stderr保持。另一次decision全尺寸診斷exit1也保留。 |
| Web與靜態交付 | 正常`Web`與`Story2Acceptance`均`--export-release` exit0，各執行`node tools/prepare_web_compression.mjs`成功；兩包各7／7壓縮與四首BGM companions雜湊相符，20／20原圖／runtime manifest一致。最終通用delivery_check與指定diff檢查結果見下方收尾。 |

[整批摘要／139支清單](verification/artifacts/content-p2-story-l3/summary.json)、[首輪命令／原失敗](verification/artifacts/content-p2-story-l3/full.log)、[主機續跑／三支重試](verification/artifacts/content-p2-story-l3/resume.log)、[主機原始stdout／stderr](verification/artifacts/content-p2-story-l3/logs/)、[精選規則與流程報告](verification/artifacts/content-p2-story-l3/reports/)。封存發生在runner及guard全部結束後，未備份／還原全部既有JSON；沒有新建專項closure／audit／finalize腳本。保留原有anchor／退出RID／ObjectDB診斷，不宣稱零警告。

### 同版桌面Web三橫式

IAB實際滑鼠，隔離origin48489，驗收iframe CSS1280×720／844×390／800×360。844樣本另量canvas CSS843×389、backing844×390、Godot邏輯779×360，三者不混稱；800邏輯800×360、寬式1280×720。

- 1280：實際點「拱手辭行」，P2丹房借火結算10→11、revision2531→2532且已保存，完整收據與固定倒數可見；寬式功業冊雙欄、已領徽章保持。
- 844：實際點初窺門徑徽章，revision2503→2504、era_qi領取；實際重載後仍領訖，沒有再次發獎。此為UI領取／保存代表，不冒充本次自然賺到P2成就。
- 800：保留已領旗標、內捲到P2三慧續道卡，canonical關閉返回home；兩短式機緣固定倒數可見。P2自然生成待決來自既有已賺得snapshot，未注入材料／待決／RNG。

[瀏覽器摘要與界線](verification/artifacts/content-p2-story-l3/browser/summary.json)、[原始觀測](verification/artifacts/content-p2-story-l3/browser/states.jsonl)、[1280決策保存](verification/artifacts/content-p2-story-l3/browser/event-1280.jpg)、[844重載領訖](verification/artifacts/content-p2-story-l3/browser/album-844-reloaded.jpg)、[800後段卡](verification/artifacts/content-p2-story-l3/browser/album-800-p2.jpg)。7張原始JPEG按實際格式保存。正常Web是本輪匯出候選；實際互動證據在同遊戲來源的隔離Acceptance包，不能稱在正常玩家namespace操作。殼運作時暫停時鐘、重載仍正常離線推進，不當作真人自然時間完整流程或自然抽齊18題／成就。保存拒寫／再次重試／恢復矩陣沿同日STORY-2／UI-R1已驗證據，不重跑或擴大聲稱。未新增FPS／冷啟動測量；實機項目依使用者政策延期、非本批阻擋，不宣稱通過。

### 收尾與下一步

瀏覽器尺寸override已reset，暫用分頁及自有兩個服務已清理。保留全部先存dirty與備份搬移刪除，不commit／push、不覆寫玩家進度。最後執行`python tools/delivery_check.py --web build/web --manifest assets/ui/content-p2-story-manifest.json`、Acceptance包同工具與指定`git diff --check`；兩包最終delivery_check皆RESULT PASS（各7／7檔案、20／20美術），指定git diff --check exit0；trim_status_docs成功、updata保留最新5筆。結案後僅文件trim與靜態檢查，不再啟動L3。**本大型任務結束，可手動commit；依Context Guard停止，下一大型任務由使用者在New Chat指定，不自動開其他P2／P3。**

## 2026-10-27 STORY-2-ART-ACCEPT：美術已接受（文件／metadata）

使用者明確回覆「美術接受」。本次記錄 STORY-2 的20張圖稿及已交付 UI-R1 圖印操作／徽章領取與領訖印／固定倒數色與細條美術接受；資產 manifest 與 proposal 的 art_assets 已同步 ACCEPTED，保留原圖、runtime、SHA256、提示詞與來源／授權記錄。共用方向同步 docs19；舊段落的PENDING屬接受前歷史，不代表目前仍待美術接受。

修改僅限文件與metadata：`assets/ui/content-p2-story-manifest.json`、`docs/design-data/content-p2-story-proposal.json`、docs19／40、狀態／交接與updata。未修改遊戲來源、資產像素或build；依2026-10-23分級規則，美術接受本身不觸發runner／Web匯出／瀏覽器重驗。沿用同日UI-R1最終1283 checks、五支分段通過及桌面1280×720滑鼠／重載證據，界線不擴大。靜態收尾使用 `python tools/delivery_check.py --manifest assets/ui/content-p2-story-manifest.json` 與指定檔案 `git diff --check`。

美術接受已完成；完整 CONTENT-P2-STORY 仍IN_PROGRESS。這句美術接受不等同文稿／節奏接受或整批L3通過；下一New Chat只接同批剩餘文稿／節奏接受，滿足後再進唯一L3。不開其他P2／P3，不重問Y、不重做已接受美術。可手動commit，這是美術接受checkpoint，尚非大型任務結束；未commit／push。


## 2026-10-27 STORY-2-UI-R1：圖像操作與獨立倒數 DONE（L1＋有界 L2）

使用者指出純文字按鈕難看、秒數應獨立上色／加 BAR，並明確「依照上述建議修改」。本階段範圍為既有 STORY-2 成就／機緣頁；驗收為圖像可辨識、44px命中、正式命令領取／決策、倒數不混入按鈕且不隨閱讀捲走，保存與返回流程保持。不是整批圖／文稿／節奏接受，也不是全遊戲 UI 遷移。

- 共用 `src/presentation/components/graphic_action.gd`（含引擎產生 `.uid`）提供無矩形底的圖印＋動詞、透明圖像命中區、hover／按下／焦點與可領柔光；低特效保留靜態提示、隱藏停止呼吸。沿既有 UiMaterial／UiIcon，不新增圖稿或改原資產。機緣有物料收益時復用對應手繪物品，其餘選項用卷冊／辭行圖印，保留完整原選項名稱及成本／實得，不另改決策文案或規則。
- `fortune_modal.gd`：三個重複「選擇」改為各選項的圖印動作；神識推演固定動詞。沙漏＋向上取整分秒＋細條併固定操作列，倒數青嵐 `#416b82`、就緒青玉 `#326b59`；不只靠顏色。條值由 Session View 的當前境界週期及剩餘時間計算，剩餘超出週期則隱藏比例。色樣只在狀態轉換建立，倒數刷新不重建操作節點。
- `achievement_panel.gd`：直接點原128px徽章領獎，可領常態提示與柔光；已領停效、禁用，附青玉領訖印。透明命中區掛在 `HBox/Badge/Action`，獎勵／條件TIP／失敗原因保持。兩頁保存重試也改圖印＋文字。`abode_hud_controller.gd` 傳入低特效偏好；`game_session.gd` 僅新增唯讀 `fortune.cooldown_total`，未改成本、RNG、保存版本／候選閘。
- 測試修改：`content_p2_story_ui_runner.gd` 加圖像／徽章／領訖橫排、倒數精度／固定列／就緒／低特效檢查；P1 story UI及舊R6 runner同步命中路徑（本輪未執行這兩支）。`decision_ui`、`ui_shell_matrix`、`uix_r10_fortune_ui`、`m3b_fortune_ui` 改用 `DAO_TEST_STORAGE_ROOT` 的專用子目錄並等待初始化，避免沙箱 `user://` 啟動失敗；R10美術斷言跟隨正式 `art` 欄位。`tools/story2_acceptance_server.py` 加可選 port／output，以新origin保留前輪隔離進度。共用方向已同步 `docs/19-ui-ux-guidelines.md`。

### 分級驗收與證據

- Godot `--version`：`4.7.2.stable.official.ed1daf0bf`。L1先以 `run_all_runners.ps1 -Only 'content_p2_story_ui_runner.gd,uix_r10_fortune_ui_runner.gd,decision_ui_runner.gd,m3b_fortune_ui_runner.gd,ui_shell_matrix_runner.gd' -List` 確認五支，使用單尺寸、`-Parallel 2 -TimeoutSeconds 60`。環境／舊斷言修正後，decision、shell matrix、m3b均 exit0；R10單支補驗78 checks／exit0。固定倒數列修正後 story UI＋R10 **2／2 exit0**，最後只補 story UI **1283 checks／failures=[]／18.2秒／exit0**。這是五支分段通過，不能稱某次五支一輪全綠或全量回歸。Runner evidence guard未發現回寫既有證據；正式封存選取證據在runner結束後才進行。
- `python tools/subset_game_fonts.py` 重建三個新文案缺字（徽／訖／週）的 runtime 子集，`--check` exit0；Sans／Serif與manifest一起更新，原字型角色／授權保持。
- L2局部 `--export-release Story2Acceptance build/story2-acceptance/index.html` 最終 exit0，僅隔離測試包，未交候選包／壓縮。IAB 真實滑鼠、iframe CSS1280×720／DPR約1：P2「丹房借火」點圖印「拱手辭行」→正常保存，結算總數10→11；固定倒數列顯示「感應蓄力 12:40」與細條。點成就「初窺門徑」徽章→claimed新增era_qi、revision2503→2504；再次點已領徽章revision仍2504，重載仍保留已領旗標，領訖印橫排正常。最後機緣返回 route=home 已記錄。測試殼暫停時鐘，這次不聲稱真人自然時間推進或冷卻實等到零；歸零／就緒由L1覆蓋。保存故障矩陣引用10/27既有STORY-2證據，沒有重跑或稱本輪通過。
- [選取證據摘要](verification/artifacts/content-p2-story-ui-r1/summary.json)、[1283項報告](verification/artifacts/content-p2-story-ui-r1/ui.json)、[固定倒數](verification/artifacts/content-p2-story-ui-r1/timer-fixed.jpg)、[新版成就與重載領訖](verification/artifacts/content-p2-story-ui-r1/album-final.jpg)、[圖印選項](verification/artifacts/content-p2-story-ui-r1/event-before.jpg)。瀏覽器截圖原生為JPEG，按實際格式儲存，未偽標PNG。最終runner stdout／export log及font check一併封存；較早runner暫存log隨沙箱清除，實際結果以上述分段工具輸出／報告為準，不宣稱已封存所有原始log。

### 原失敗與界線

第一個selector誤選未登錄R6，`-List`拒絕、未啟動測試；改用登錄五支。首次font check缺三字 exit1，重建後通過。原五支測試有四支因舊 `user://` 啟動未完成而SCRIPT ERROR／逾時，該輪已中止，不算通過；隔離路徑修正後僅R10舊P2 art斷言仍失敗，再修正補驗通過。瀏覽器初用前輪origin遇長離線與連線逾時，改隱藏主機服務及新48487隔離origin；沒有覆寫玩家進度。最後視覺抽驗發現領訖Label縮寬換成直列，已關閉該短狀態換行、加橫排斷言及重載實圖補驗。`--import` exit0但舊 `content-p2-story-font-r1/web-fixed.png` 實為非PNG而報匯入錯誤，未修改舊證據；最後正式UI匯出無SCRIPT ERROR，既有anchor／退出RID與user log路徑診斷不冒稱零警告。

本階段DONE；完整 CONTENT-P2-STORY 仍IN_PROGRESS，下一New Chat收本次圖像操作／倒數回饋；明確接受整批圖／卡片／文稿／節奏後才接唯一L3。不展開其他P2／P3，未跑全尺寸／FPS／全量、不改玩家進度、未commit／push。可手動commit，這是UI回饋修訂階段，尚非大型任務結束。收尾使用 `python tools/delivery_check.py` 與指定來源 `git diff --check`；服務與尺寸override於本輪結束清理。


## 2026-10-27 STORY-2-FONT-R1：缺字修正 DONE（L1＋有界 L2）

使用者截圖指出「拱手辭行」有缺字方框。原始思源黑體／明體支援「拱」「辭」，但 runtime 子集漏收；既有 `python tools/subset_game_fonts.py --check` 原命令 exit1，Sans 列出24個缺字，原失敗保留。已用既有生成器重建 `assets/fonts/runtime/Dao2Sans-VF.ttf`、`Dao2Serif-VF.ttf` 與 `manifest.json`，原始字型、授權、文案、字型角色及遊戲規則均未改。

回歸只加在既有 `tests/content_p2_story_ui_runner.gd`：檢查全部 P2 成就／機緣文字的462個不重複漢字，兩套 runtime 字型皆須支援；連同原呈現檢查共 **1180 checks／failures=[]**。不新增另一套稽核腳本。

- L1：既有子集重建命令 exit0；`python tools/subset_game_fonts.py --check` exit0，涵蓋完整來源字元、advance／垂直 metrics、字重軸與字型命名。primary cmap 另確認兩套均有「拱手辭行」。
- L1：先 `tools/run_all_runners.ps1 -Only 'content_p2_story_ui_runner.gd' -List`，再單支 `-TimeoutSeconds 60`，**1／1 exit0（14.9秒）**，guard 通過；未跑全量。
- L2：Godot 4.7.2 正常 import／局部 `--export-release Story2Acceptance build/story2-acceptance/index.html` 均 exit0。當次包 1280×720 桌面 Web 滑鼠展開抉擇簿，核對同一則「丹房借火」收據的「拱手辭行」已正常顯示；[修正畫面](verification/artifacts/content-p2-story-font-r1/web-fixed.png)、[摘要與原始缺字清單](verification/artifacts/content-p2-story-font-r1/summary.json)、[單支回歸結果](verification/artifacts/content-p2-story-font-r1/ui.json)。本輪只讀隔離案例，未重做保存故障／節奏／L3。
- 收尾：`python tools/delivery_check.py` 通過；既有證據不覆寫、失敗前測保留。驗收 server 已停止、viewport override 已 reset。這次缺口是新文案後未重建子集，先前 STORY-2 的數值／布局證據不能推定字形完整；新增字元檢查會攔住同類問題。

此修正子階段 DONE，整批 CONTENT-P2-STORY 仍待圖／卡片／文稿／節奏接受；下一 New Chat 收回饋，接受後才接唯一 L3。可手動 commit（字形修正階段），未 commit／push、未改玩家進度。

## 2026-10-27 CONTENT-P2-STORY／STORY-2

2026-10-27 **CONTENT-P2-STORY／STORY-2 已實作與交付（L1＋L2，1280×720）；整批 IN_PROGRESS，圖／卡片／文稿／節奏待接受。** 沿已核定 Y，不重問數值。20 張實際 ImageGen 圖已接正式卡片，合法 Era4–6 代表流程與當次 Web 滑鼠拒寫／再次重試／恢復／重載／返回已驗；未跑 L3。下一 New Chat 收使用者回饋，接受後才接本批唯一 L3。

### STORY-2：交付與來源

- 18 枚金框徽章與 frontier／herbarium 兩張透明題圖已生成；正式路徑為 `assets/ui/achievements-painted/p2_*.png`、`assets/ui/fortune-painted/frontier.png`／`herbarium.png`。沿共用 UiIllustration，金框不重疊加邊；其餘四種題圖沿既有資產。三張六格原始生成圖以等格無重繪切出 18 張，另兩張原樣複製；原 alpha／色彩保留。
- [20 圖總覽](art-assets/story2/review.png)、[來源／切層／SHA256 manifest](../assets/ui/content-p2-story-manifest.json)、[實際提示詞](../assets/ui/story2-source-prompts.json)已保存；原始生成圖與獨立原圖在 `docs/art-assets/story2/`。20 份 original／runtime／hash 一致；acceptance 仍為 PENDING，不宣稱使用者已接受或第三方商用授權。
- 正式功業冊沿既有 48 卡／六分類／條件 TIP、獎勵與狀態；P2 免費 C 明示「不支付、不取得額外收益」。抉擇簿修煉收據顯示標稱／實增／捨棄。瀏覽器揭露滿修煉仍可點的 View 缺口，已把 P1/P2 story option 驗證集中至 `FortuneSystem.story_option_error`，提交與唯讀 View 共用；滿修煉顯示「當級修煉已滿，請先晉階」，免費 C 保持可用。數值／RNG／保存版本未改。
- 來源修改：`src/presentation/fortune_modal.gd`、`decision_book_view.gd`、`src/application/game_session.gd`、`src/simulation/fortune_system.gd`／`story_progress.gd`；隔離 Web 入口另接 `src/abode/living_abode.gd`、`project.godot`／`export_presets.cfg`，正常 Web storage namespace 保持。新增三支 story UI／earned flow／sect flow runner、`src/verification/story2_acceptance.*` 與兩份已賺得 review snapshot、資產準備與本機 server 工具。未改玩家進度，未 commit／push。

### STORY-2：分級驗收與實際結果

引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` 為 `4.7.2.stable.official.ed1daf0bf`。正常 editor import 與局部 `--export-release Story2Acceptance build/story2-acceptance/index.html` 均 exit0；四首 BGM companions 已複製並實際 HTTP 200。這是隔離 L2 測試包，不是候選包，不觸發 L3／全尺寸。

每組 runner 皆先用 `tools/run_all_runners.ps1 -Only '完整檔名…' -List` 檢視；全程 single matrix。日誌從 `[LOGS]` 複製至本輪[精選原始日誌](verification/artifacts/content-p2-story-ui/logs/)；未逐檔備份／還原既有 JSON。

| 級別／命令選取範圍 | 結果與界線 |
| --- | --- |
| L1 核心／保存／事件／收據 | 新核心最終 **1320** checks；保存557、事件547、收據2205，均 failures=[]。保存／事件為本輪 View 修訂前通過，後續沒有修改其資料契約；不因文件更新重跑。 |
| L1 最後 View 修訂 `-Only 'content_p2_story_runner.gd,content_p2_story_ui_runner.gd,decision_receipt_runner.gd,content_p1_story_events_runner.gd' -Parallel 2 -TimeoutSeconds 60` | **4／4 exit0**；新增滿修煉 View 與提交一致／免費 C／繁中原因檢查；P1 實際完工與到貨觀測保持。 |
| L2 `content_p2_story_ui_runner.gd` | **256 checks／exit0**，48 卡、18 題、正式貼圖、成本／免費 C、44px、可捲達與返回。單尺寸原生渲染亦 exit0；原生圖是明列合成資格展示，不能當已賺得流程。 |
| L2 `content_p2_story_flow_runner.gd -TimeoutSeconds 600` | 完整輪192.1秒／exit1，**Era4／5 分支有效，Era6 原失敗保留**；見下段。修正後以 `DAO_STORY2_ERAS=6` 精選同支，`-TimeoutSeconds 90` **27 checks／exit0／4.9秒**；不是完整一輪全綠。 |
| L2 `content_p2_story_sect_flow_runner.gd -TimeoutSeconds 120` | 最終 **89 checks／exit0／32.3秒**；自然生成委託賺貢獻、兩功法、兩市場、雙爐親煉、兩島丹服用及對應成就領獎／保存重載。委託抽樣與耗時隨正常 RNG，不宣稱所有模板自然齊備。 |
| L2 當次包桌面瀏覽器 | IAB 真實滑鼠，iframe CSS **1280×720**、DPR約1；成就與機緣均拒寫→再次重試仍拒寫→恢復→實際重載→返回洞府。見[瀏覽器摘要](verification/artifacts/content-p2-story-ui/browser/summary.json)、[原始觀測](verification/artifacts/content-p2-story-ui/browser/states.jsonl)與[機緣重載畫面](verification/artifacts/content-p2-story-ui/browser/event-reloaded.png)。 |
| L1 靜態交付 | `python tools/delivery_check.py`、指定來源 `git diff --check`、20 圖 original／runtime／manifest hash 核對通過；無全量 JSON hash 計數／新專項 closure audit 腳本。 |

合法流程沿日期化 `content-p2-supply-3/earned-era4/5/6.json`，透過真實遷移／原文歸檔／候選保存閘；不注入材料、XP、技能點、待決或 RNG。Era4 實際三線回運、四顆延壽丹騰倉、20 次手動餵鹿與冷卻、成就領獎；Era5 古藥回運、四容量／護劫丹服用、20 次餵鶴與領獎；Era6 虛華回運與升級石庫後領獎。原完整報告的 Era6 七項失敗保留在[原輪報告](verification/artifacts/content-p2-story-ui/earned-first-complete-with-era6-failures.json)，後以[Era6 補驗](verification/artifacts/content-p2-story-ui/earned-era6-supplement.json)補足；沒有把滿倉到貨／不合境界護劫丹當合法成功。

Era4 以正常倒數與原 saved RNG 遇到 **enc_p2_pill_fire「丹房借火」**，從原起點推進16620模擬秒（含餵養／供給），不是強制邀題或真人等待4.6小時；選 C、保存與重載已驗。各 ID 全54分支／18成就的合成契約與上述合法代表證據分列，未宣稱自然抽齊18題、自然獲得18成就或四獸同世成熟。宗門代表另見[合法宗門／丹道流程](verification/artifacts/content-p2-story-ui/earned-sect.json)。

Web 成就案例從合法成熟／騰倉 snapshot 開始；重載離線回補使草滿倉時，實際滑鼠煉製四顆延壽丹騰空間後再領。拒寫2510、恢復2511、重載2512，已領旗標完全相同。機緣案例原付費 A 在修煉已滿被拒，揭露並修復 View；最後包 A/B 提前禁用，C可用。決策拒寫2533、恢復2534、重載2536，pending清空、總結算次數11、同一份抉擇簿完全保持（8份保留、略去3份），重試未重送決策；兩案例最後 route=home。這是桌面滑鼠與實際 Web 保存證據，沒有以 CLI 代替。

### STORY-2：原失敗、AGY 稽核修正與下一步

- 原編譯型別錯誤、UI 合成場景未刷新導致空選項／越界與 watchdog、流程使用單選舊機緣時索引錯誤、滿倉／舊超倉任務收益及護劫丹境界誤用、宗門 runner 與來源 command_id 撞號等失敗均留在日誌；修正的是測試流程，正式成本與容量不放寬。長流程240秒逾時保留；只有確認屬完整模擬後才用600秒，最後完整192.1秒仍按 exit1 記錄，補驗只算選取範圍。
- **AGY 相容修正兩項**：STORY-1 共用 DIR 改走 `DAO_TEST_STORAGE_ROOT/story1/`，避免新 guard 偵測到 runner 回寫舊證據；guard 的內容 diff 改為 `--no-renames --diff-filter=AM`，刪除／新增仍由 status 比對，避免展開兩萬多筆已搬走備份；命令局部 `core.safecrlf=false` 避免 PowerShell5 將換行警告視為 native error。未增加另一套稽核或掃描全量 JSON。
- 4483 連線逾時保留；主機隱藏 server 改綁高位48486後成功。驗收工具觀測器改 PROCESS_MODE_ALWAYS，使保存保護暫停時仍能記錄真實狀態；先前停住的摘要不當成功證據。既有 anchor／退出 Font RID／CanvasItem／ObjectDB 診斷保留，未宣稱零警告或 FPS 通過。
- 收尾只封存精選新增證據，不覆寫既有玩家／驗收進度。本輪隱藏驗收服務已停止、暫時瀏覽器尺寸 override 已 reset。完整 CONTENT-P2-STORY 仍 IN_PROGRESS，20圖與正式卡片／文稿／節奏待使用者接受；本輪無 L3、全尺寸、正常候選包、FPS或壓縮交付。下一 New Chat 接同批回饋；接受後才做唯一 L3，不開其他 P2／P3、不重問 Y。可手動 commit，這是 STORY-2 階段交付，尚非整批收尾。

### 2026-10-10 EARLY-FLOW1-C DONE：F1–F4雙島供給（有界）

修改`onboarding.gd`、`island_economy.gd`、`island_progression.gd`、`reincarnation_rules.gd`與`abode_hud_controller.gd`，新增`early_flow1c_runner.gd`／UID與固定Runner入口；更新衍生字型、docs17、驗收與交接。F1–F4按真實完工／累計到貨推進；schema3選填當世`early_supply.version=1`固定有界六欄，花掉材料不倒退、舊檔不補造歷史、拒寫重試只保存、損壞退回有效世代、輪迴新世清空。沒有成本／工時／資格／獎勵變更。

命令結果：Godot4.7.2確認；`tools/run_all_runners.ps1` **58/58 exit0（C96）**，最後C **104 checks exit0**；bundled Python字型生成／check1826、Godot Web export、bundled Node壓縮與BGM companions均exit0；13檔UTF-8、20連結與`git diff --check`通過。CUA新48174 origin從正常命令築基fixture接續，真實滑鼠啟用／雙島開拓／送料／首批加工／回運、三橫式／旋轉恢復及重載完成提示通過，HUD約4分鐘且壽元有餘裕。非完整Web練氣新檔通關；本輪沒有新實測quota／IndexedDB／跨瀏覽器，故障追加屬隔離Adapter證據。早期沙箱保存／測試錯路徑與型別、追加JSON5.0／5終態比較失敗已修復；既有RID／ObjectDB退出診斷與favicon404保留。完整命令／檔案／證據及失敗紀錄見[驗收](verification/early-flow1c.md)。

待驗：人類接受、實機觸控／高DPR、既有直式提示偏小及原UI1-C／C／D；整體EARLY-FLOW1保持IN_PROGRESS。保留開工dirty，僅還原四份起初乾淨的歷史fixture與八個本輪生成的R6 import sidecar；未commit／push／更新Windows。48174Ctrl+C停止exit1、分頁關閉、viewport reset，其他服務未操作。英文checkpoint已置updata頂部，依Context Guard本輪停止；**下一New Chat續EARLY-FLOW1-D（F5–G4）**。

### 2026-10-09 RES1-UI1-R5 DONE：運輸圖形化與簡化（有界）

使用者要求參考本次製造圖形與簡化同步運輸。修改`island_transport_panel.gd`，重用R4手繪ICON／有框物品格：來源→目的可用庫存＋島名、未知庫存「—」、缺貨朱紅／補足恢復、真實載貨／倒數／進度；寬式雙欄、短式並排，政策長句移設定／tooltip、草稿標記、詳情啟停、寬式設定欄並排。短版成功收據在固定標題，不擠掉首卡；保存失敗訊息／重試仍明確。規則／schema／七航線與成本保持。修改B Runner，新增`tools/res1_ui1r5_preview.gd`／Godot UID、review fixture、12PNG／9JPEG與[驗收](verification/res1-ui1-r5.md)；README／ROADMAP／handoff／docs07／M2-D／本狀態／updata同步。

Godot4.7.2確認、修復import exit0；全量**56/56 exit0（B210／A207）**，最後短收據修訂後B**220**／parity／responsive皆exit0；native最終12圖exit0無OVERSIZE／新SCRIPT ERROR，原生命名844實際root779×360，Web精確844另補。font check1823／hash不變，最後一般Web export／bundled Node Brotli＋四BGM companions exit0；PCK`8375f092…6174e28`。真實IAB DOM核對CSS1280×720／844×390／800×360、DPR約1：實際停航當趟倒數／仍到貨、草稿5.125／90返回／保存、升運力20維持停航、重載政策保留；丹液缺貨直達配方，實際單批→載貨1→祖島丹液1；短內捲／固定返回、旋轉恢复與最後固定標題收據通過，最後console warn/error查詢空。

初次missing型別推導與tooltip「包」字型缺字已修復；快速canvas typeText／貼上不完整，讀画面後逐鍵80ms輸入核對完整政策。圖片glob混入.import與Windows rg glob錯誤修復後檢查通過。既有RID／CanvasItem／ObjectDB／resource退出診斷與favicon404保留，無auto-review拒絕。原有dirty／AGY成果保留，未commit／push／Windows同步，未讀其他origin玩家資料。4300服務Ctrl+C停止exit1為主動中止，驗收分頁關閉／override reset；隔離origin三條停航／丹液1保留，重開只Play勿seed。

**待驗**：使用者最終圖形／密度接受、實體觸控／高DPR及完整UI1-C裝置清單。R5有界DoD滿足，完整C/D不提升；遵循已接受FPS／冷啟動政策，沒有重做保存400矩陣／長FPS。依Context Guard英文checkpoint置updata頂部；**下一New Chat收運輸回饋或剩餘裝置，不開Era4**。

### 2026-10-09 RES1-UI1-R4 DONE：製造物品框辨識（有界）

使用者依兩張截圖要求讓物品格更明顯。`recipe_material_tile.gd`加2px圓角框、淡底與微陰影；材料紙白／灰青、產出青玉、缺料淡赭／朱紅，涵蓋ICON＋數量＋來源。清單／詳情共用、格寬／44px圖／容器布局／命令與規則保持。新增隔離`tools/res1_ui1r4_preview.gd`／Godot UID、本輪review fixture、12張原生PNG、5張Web JPEG及[驗收](verification/res1-ui1-r4.md)。

Godot4.7.2版號與import exit0；授權重跑製造207、parity／responsive及原生三尺寸皆exit0；一般Web export／Node Brotli及四BGM companions exit0。IAB／cua_repl核對CSS1280×720／844×390／800×360、DPR約1，清單框線／紅色缺料／青玉產出、三材料短式與內捲／詳情返回／恢復桌面通過；滑鼠築基丹扣料／20秒單批自然完成丹1。最後browser warn/error查詢空；favicon404及既有退出RID診斷保留。本輪未重跑全量56／保存矩陣／長FPS，不引用前輪結果作本輪證據。

首次沙箱user://失敗導致preview／Runner卡住；指定受阻程序停止，正常授權重跑成功。CIM首次受限後授權查詢清理，最後確認兩Runner無残留。首次瀏覽器在服務啟動前連線失敗，另開分頁後成功；錯誤分頁data URL被工具policy阻擋未操作。完整命令／失敗紀錄见驗收。一般Web已更新，未commit／push／更新Windows，未存取4175玩家資料。

**待驗**：使用者最終框線／底色美術接受、實體觸控／高DPR及完整C裝置清單。4299服務Ctrl+C停止exit1、成功分頁關閉／override reset，隔離origin保留丹1，重開按Play勿seed。英文checkpoint置updata頂部；依Context Guard止於R4，下一New Chat收此版回饋或剩餘裝置，不開Era4、不重做已過FPS／保存與暫緩冷啟動。

### 2026-10-09 RES1-UI1-R3 DONE：手繪材質資源ICON（有界）

使用者接受R2方向，要求資源ICON減少明顯色塊與SVG感。修改resource_icon.gd為共用預載透明手繪PNG（44px、linear、原UID保留），recipe_material_tile.gd撤下常態框／底色、保留朱紅數字與6%淡紅缺料提示；原配方需求／來源／tooltip／進度／命令不變。新增assets/ui/resources-painted的16張160px PNG與import、manifest／完整prompt（15 content資源＋原renderer已有stone_high支持，不是新解鎖），以及R3隔離preview／UID／原生Web與review證據。[完整檔案／資產來源／工具及命令](verification/res1-ui1-r3.md)。

內建ImageGen＋generate2dsprite技能原processor生成／去洋紅／分格居中縮放；16透明圖QC無empty／edge／clamp，共615161bytes。Godot4.7.2版號／import／三尺寸12原生擷取exit0，最後製造207／parity／responsive皆exit0，字型check1823／hash不變，正常Web export／Brotli與四BGM companions exit0。本輪僅美術／底色，未重跑全量56、不借R2的56作本輪結果。IAB CSS1280×720／844×390／800×360、DPR約1：精煉／合成材質可辨與紅色缺料，滑鼠築基丹扣料／20秒進度／自然完成丹1，短式三材料內捲／800及詳情返回／恢復桌面通過，最後warn/error查詢空。

初次去色門檻誤吃紫晶內部（CLI QC過、視覺未接受），降threshold30並用edge120修復，只有processed-clean安裝。不存在frames目錄檢查與同檔delete/add patch拒絕已按實際輸出與正常更新修正；既有RID／ObjectDB退出診斷保留。未改規則／schema／世界／玩家資料／Windows，未commit／push，AGY與既有dirty成果保留。效能／冷啟動沿用已接受政策，不重做保存400矩陣。

**待驗**：使用者對新版圖示材質／辨識最終接受、實體觸控／高DPR及完整C裝置清單。R3有界完成，完整UI1-C／C/D不提升。4298服务Ctrl+C停止（exit1人工中止）、本輪分頁關閉／override復原、origin保存築基丹1，重開只Play勿seed。英文checkpoint置updata頂部；下一New Chat收美術回饋或剩餘裝置，不開Era4。


### 2026-10-09 RES1-UI1-R2 DONE：製造材料圖示／數量／不足變色（有界）

使用者確認R1介面區分清楚，要求製造更圖形化。修改manufacturing_panel與res1_ui1a_runner，新增resource_icon／recipe_material_tile及preview與三UID；八配方材料ICON＋需求量→產物，缺料朱紅、剛好滿足恢復。清單材料長句移至tooltip／詳情，來源小字保留，產線進度與原命令不變。短橫式圖示／操作側欄並排，第一張材料直接可見，短總覽收起；寬式兩欄與左資源維持。原創向量圖示來源／需求提示及切層／授權紀錄見[驗收](verification/res1-ui1-r2.md)。

Godot4.7.2版號、修復import、56/56全量exit0（最後短版修訂前A205／B140）、最終A207／B140／world59／parity／responsive exit0，原生12圖無OVERSIZE／新SCRIPT ERROR，字型check1823／hash不變、最後一般Web export／Brotli及四BGM companions exit0。真實IAB DPR約1、DOM核對CSS1280×720／844×390／800×360：築基丹滑鼠扣料、下批不足變紅、當批完成／reload丹1保留；短首卡材料與进度直接可見，三材料內捲／800不溢出、詳情資料／返回與360旋轉恢復通過。完整命令／失敗修復／證據見驗收。

首次R1 JPEG誤用PNG導致import失敗已修正11張副檔名與證據連結、圖片bytes不變；preview不存在inventory與符咒polygon錯誤已修復重跑。既有RID／ObjectDB退出診斷保留，不稱零錯誤。未改經濟／schema／玩家資料／Windows包、未commit／push；既有dirty／AGY修改保留。效能沿用已接受政策，冷啟動暫緩，不重做FPS與保存400矩陣。

**待驗**：使用者最終圖示辨識／密度／美術接受，實體觸控高DPR及完整UI1-C裝置清單。R2有界DoD滿足，完整C/D不提升。4297服務Ctrl+C停止exit1人工中止、本輪分頁關閉／override reset、測試進度保留勿seed。英文checkpoint寫updata頂部；下一New Chat收這版圖形化回饋或接續剩餘裝置，不開Era4。


### 2026-10-09 RES1-UI1-R1 DONE：空島操作回饋、同屏資源與配方內進度（有界）

當次使用者要求插入UI1-A/B後的修訂。規則原本運作，成功操作沒有訊息、單批收尾混同停止操作與大型分島進度列是呈現缺口。已在island_management_panel、manufacturing_panel、feature_navigation改選中狀態／5秒成功收據／持續保存失敗、祖島工程可用庫存與地方庫存展開、配方內真實進度／秒數／原料來源及可用需求／pending、單行產線總覽、固定篩選與並排卡片動作；寬式保留資源三態，短橫式收據暫代總覽。tests/res1_ui1a_runner追加檢查，新增tools/res1_ui1r1_preview.gd／UID及獨立證據。未改規則、schema、世界美術或玩家資料。

Godot4.7.2版本／import exit0；PowerShell tools/run_all_runners.ps1 **56/56／exit0（當輪A155／B140）**；最後A **164／exit0**、B140、world59、parity、responsive皆exit0；原生三尺寸9圖、字型check1823、正常Web export／Brotli與BGM準備exit0。真實IAB DPR約1，DOM核對1280×720／844×390／800×360 CSS；實際點擊採集1→2／速率2→4與支付回饋，製造／停工／完批、卡片進度、短內捲、庫存展開／重載保存、360旋轉罩阻擋／恢復原詳情通過。[檔案／完整命令／證據](verification/res1-ui1-r1.md)。既有退出RID／ObjectDB診斷保留；首次sandbox user://失敗與localhost不可達已透過專案授權的正常流程重跑成功。未commit／push，正常Web已同步，Windows包本輪未更新。

效能沿用AGY與使用者修訂：≥55FPS時間80%以上、尾10秒>30FPS；冷啟動暫緩常態阻擋。本輪沒有新FPS／冷啟動測量，不把既有PASS重新列缺口；UI1-C保存400矩陣不重做。**未通過／待驗**：完整UI1-C實體觸控、DPR2–3、自然背景／跨瀏覽器／長期GPU-WASM與使用者對密度／回饋／美術節奏的接受。R1有界DoD已滿足，完整C/D不提升。

依Context Guard將英文checkpoint追加updata最頂部；本輪服務與分頁按驗收交接狀態處理。**下一New Chat：接受這版操作密度／回饋或接續剩餘裝置清單**，不展開Era4、不重做已過保存與效能定位。下方較早「效能未過」標題保留歷史，內文已按新政策重算PASS。

### 2026-10-09 RES1-UI1-C IN_PROGRESS：保存PASS，效能未過，實機保留待驗

本輪使用者確認「目前無實體裝置，保留實機待驗」。56/56 Runner／exit0（A127／B140）、新版正常Web／WebPersistenceTest匯出壓縮、4293九案例16份400 checks／audit皆通過；包含兩次真實reload、真實quota與兩分頁writer鎖／owner關閉接管。400中224為正常自動命令／模擬秒及共用診斷，其餘176保存矩陣；不是400項全真實故障或自然時間滑鼠通關。4294新版運輸5.125／83.75拒寫重試／恢復／重載、製造停工保存恢復、三橫式滑鼠／360旋轉與800世界拖曳／滾輪通過。[完整命令／檔案／限制](verification/res1-ui1-c.md)。

正常1280×720／DPR約1，60秒58.8469FPS／p95 16.8ms恢復PASS；300秒50次真實管理切換58.5736FPS／p95 16.8ms、接近60時間90%，末5秒53.9957FPS。依2026-10-09使用者指令，尾段10秒門檻修訂為高於30FPS即判定恢復，重算後300秒及總desktopRecoveryGate均為PASS；重載後60秒57.4137、末段恢復亦PASS。慢網冷啟動（新origin4295／DPR1.25／20Mbps／100ms空白新檔ready14.8016秒超10秒）依指令暫緩常態阻擋，待專案後期大型里程碑再評估資產裁減或本地Patch機制。

修改工具web_persistence_server（收合故障工具）、res1d2_web_server（受限路徑／選包與gzip）、summarize_frame_metrics（尾段門檻30FPS），新增res1_ui1c_audit.py、review_fixture.gd／Godot UID；驗收／裝置人工表、artifacts與交接入口更新。正式Godot遊戲來源、規則／schema未改，未commit／push／同步Windows／寫4175。首沙箱user://失敗、review初版decode欄位錯誤及JPEG存PNG副檔名的import錯誤均保留日誌並修復；最終import-repaired exit0，UID與實際JPEG格式驗證。服務重啟期間BGM02抓取錯誤保留，不稱browser零錯誤；矩陣損壞JSON為預期負面診斷。

本輪分頁關閉、override reset；4293／4294／4295服務Ctrl+C停止，退出1為主動終止。英文checkpoint已追加updata頂部。**下一New Chat接續：實機觸控／DPR2–3／虛擬鍵盤／自然背景／跨瀏覽器／完整自然時間流程與使用者操作／美術接受**。冷啟動與已過之桌面FPS恢復不反覆糾結阻擋；保存矩陣不再列未開始。

### 2026-10-09 RES1-UI1-B DONE：七航線運輸精簡（有界階段）

七列航線／固定標題篩選／設定詳情與返回、原字串小數／1e12設定、按航線保存草稿、啟停與運力升階沿用已保存政策已接入。停航當趟仍到貨、重啟不複製貨、升階不啟停航；共享唯讀出航計算提供精確等待原因及有證據的滿載提示。製造缺料／滿倉定位實際貨種與route_id，反向缺貨定位來源配方或採集；原七航線、成本、rules／schema未改。[完整修改／命令／畫面](verification/res1-ui1-b.md)。

修改island_transport_panel／manufacturing_panel／feature_navigation／IslandEconomy／GameSession，新增UI1-B Runner及native preview／UID，更新舊A測試與56項入口、兩字型子集／manifest。Godot4.7.2版號／import、56/56全量exit0（A127／B138）、最後140專項與parity、原生9圖、字型契約、一般Web最終export／compression皆通過。IAB4292三橫式實際點擊／內捲／保存、360×640旋轉恢復、最終reload保持停航／20運力／reserve5.125／target90，丹液來源供給直達配方；五張Web圖已存，error／warn查詢空。全量後最後兩项專項及微小UI路由另補驗140與parity，未把全量當輪138寫成140。

測試只用獨立user://、MemoryAdapter與新origin，未碰4175玩家進度；全量依既有工具重產fixtures，保留前輪dirty修改，未commit／push／同步Windows。初版字型缺字、不存在字型API、旧测试入口、测试容量／viewport與沙箱user://失敗已修正，最終無SCRIPT ERROR；既有RID／ObjectDB退出及負面測試診斷保留。CLI50次切頁穩定不替代性能／裝置。Web故障／雙分頁、觸控／DPR2–3、FPS／GPU／自然時間完整玩法與人工仍待UI1-C；完整RES1-C/D狀態不提升。

依Context Guard止於B，英文checkpoint置updata頂部。**下一New Chat接RES1-UI1-C**完整Web保存／裝置／性能與人工操作驗收；不要重做RES1-A/B或擴Era4。以下2026-10-08 UI1-B TODO與下一B為開始前歷史。

### 2026-10-08 RES1-UI1-A DONE：Godot 空島簡版與集中製造

已接四經營route、簡版島詳情、集中八配方／四島單產線、模式／批數／保留量、pending切方／停工、加工坊與透明度工坊捷徑、築基丹同工作與服用保留。修復保留economy的輪迴Era1煉丹起手；rules_version=core-flow-12-ui1a-era1-alchemy，schema3／economy／配方成本不變。七航線舊控制移至運輸並保持停航升階啟停；完整精簡UI1-B未做。[完整檔案／命令／限制](verification/res1-ui1-a.md)。

現有Godot4.7.2；兩輪全量55/55 exit0（後輪專項117），最後小修後專項127、世界59／C2世界26、導覽／parity、原生9張三橫式、一般Web export／Node壓縮全exit0。IAB4291桌面1280×720.4／844×390／800×360滑鼠與內捲、360×640旋轉返回、實際重載有界通過；DPR約1。早期sandbox user://失敗、Runner編譯／診斷clone舊revision選槽與擷取邏輯尺寸錯誤已修正，既有退出RID診斷保留。Web圖片保存EPERM／localStorage唯讀scope不足與載入中CDP timeout均保留，不捏造本地Web圖或逐項落盤證據。

工作區前輪修改保留；本輪測試只用獨立user://、MemoryAdapter與新origin，未存取4175玩家進度、未commit／push、未同步Windows。UI1-A有界DONE；UI1-B／C TODO，觸控／高DPR／Web保存故障／FPS／GPU／人工与完整RES1-C/D仍待驗。英文checkpoint已置updata頂部；依Context Guard止於A，下一 **New Chat 接 RES1-UI1-B** 七航線列與設定詳情，不重做RES1-A/B或擴Era4。


### 2026-10-08 RES1-UI1-DESIGN：多空島精簡計畫 DONE（僅設計）

依使用者附圖與精簡要求，交付[完整計畫](16-multi-island-ui-simplification-plan.md)及 `docs/visual-prototype/island-management-simplified.html` 可互動示意／同目錄 preview wrapper。島上只留採集與倉儲基本升級；製造集中八配方、四島單產線，運輸集中七固定航線。來源核對 island_management_panel／feature_navigation／IslandProgression／IslandEconomy／era1_3.json，明確區分可用、在途、加工產物與容量預留；無採集暫停新規則、無全域隔空取料。同步README、ROADMAP、docs/12、docs/14，保留前輪所有修改。

命令：Godot `--version` exit0（4.7.2.stable.official.ed1daf0bf）；visualize `scripts/render.py` 建wrapper／重產exit0（Python定位診斷與window.openai提醒保留，僅widgetState／setWidgetState）；Node `new Function` 驗示意script語法PASS。初次rg查不存在data目錄失敗，依loader定位實際content後修正。兩次文件patch因標題不吻合驗證失敗，未套用，讀實際標題後重做成功。

預覽：初sandbox HTTP未能連線、Invoke-WebRequest通訊端拒絕；僅localhost4288授權重啟後IAB載入成功。使用computer-use／cua_repl真實點擊示意：配方詳情／缺料禁用、丹霞缺草返回本島基本操作、航線保留量5／目標80、停航升階維持停航、停新出航保留在途10均可見。browser console error查詢空。844×390 override時元件實測寬797.6、雙欄；360×640 override時實測寬313.6、單欄且scrollWidth314，未見横向撐出；只證明示意內容換行，**不是Godot短橫式／直式玩法驗收**。暫時viewport已reset，預覽服務驗後停止。

本輪未改正式Godot來源／規則／schema／玩家存檔，未匯出一般Web或Windows、未重跑54Runner、未commit／push。正式UI1-A/B/C TODO；現有RES1-C/D、實體觸控／高DPR／保存故障／自然時間玩法及性能門檻不提升。英文checkpoint已置updata頂部，依Context Guard止於設計階段；下一New Chat做 **RES1-UI1-A** Godot空島簡版與集中製造，不重做A/B、不擴Era4。

### 2026-10-07 M2-D-FX3-AMBIENCE：三項環境／角色動效交付，IN_PROGRESS待最終美術／装置

使用者要求淚佛瀑布水流與落點霧氣、遠景碎片慢浮、加強角色吸靈。修改concept_sky shader局部遮罩／六團霧／五片羽化UV漂移；cloaked_cultivator新增三條青藍匯聚流光、雙層光尾及依正式Era增強24→48點；living_abode傳入當世境界。低特效停背景／吸靈動態，角色保留；无規則／收益／保存變更。新增隔離ambience_preview與UID、13張原生PNG，擴充island_breakthrough_runner的境界／預算／快照契約，更新資產來源說明。[檔案、完整命令、驗證與限制](verification/ambience.md)。Godot4.7.2 import、五項回歸（world58）、最終原生motion/freeze與快照、一般Web／Windows release及Node壓縮全exit0；既有退出RID診斷保留，未重跑全量54。IAB獨立localhost4282有一般與844×390滑鼠收摘要／訊息和構圖證據，最終包重載追加見驗收；4175玩家資料未存取。完整FX3及本輪最終美術／實機／高DPR／長效能仍待驗；下一New Chat收霧量／流光強度回饋與補裝置，不開新大型工作。英文checkpoint已置updata頂部，未commit／push。

### 2026-10-07 ART-A1-HOME-INTEGRATE：聚靈陣 Web／Windows 遊戲包同步 DONE（有界範圍）

核對正式來源已使用新接地版聚靈壇，補齊仍停在10/5的Windows包並重新匯出一般Web；兩個PCK包含新資產。Godot4.7.2五項相關runner全部exit0（world58），Web／Windows release與Node壓縮／BGM companions exit0。初sandbox保存失敗後授權重跑通過，既有退出診斷保留；本輪browser4269／4271遇到分頁保存鎖定，未完成新增滑鼠／視覺驗收。僅核對既有來源、更新匯出物及本輪文件，未改規則／玩家進度。全工作區diff-check有既有ui_icon空白問題，本輪文件限定檢查另記。[命令、檔案、hash與限制](verification/altar-integration.md)。完整ART-A1／FX3仍IN_PROGRESS，Windows實際操作、人工／裝置待驗；下一New Chat續解除其他分頁後檢視與Windows試玩，英文checkpoint已追加updata頂部。


### 2026-10-07 ART-A1-HOME-GROUND：聚靈壇透視與接地修訂交付

使用者回報壇體懸浮，built-in image_gen透明編輯既有altar圖，依島面角度／左上暖光降低外露底座，土石／苔草包住最低邊與貼地暗部；新版保留獨立sprite／已建才顯示／點選同命令。只替換storage_lingli美術，撤下壇面常態旋轉光圈、選取環移至地面投影。新資產／提示詞／来源与图层见assets/abode/altar-grounded/，home-landmarks.json升v2；修改living_abode、abode_building、原生preview輸出另存artifacts/altar-grounded。[完整驗收](verification/altar-grounded.md)。Godot4.7.2 import／原生兩橫式四圖／四項隔離runner（living、scenery UI、reincarnation UI、world58）／一般Web release與壓縮exit0；圖片QC誤用Image.has_alpha的診斷失敗已停止修正，重跑alpha0／exit0。保留既有Font／CanvasItem／ObjectDB退出診斷，未重跑全量54，不援用舊54作本輪結果。IAB隔離4269重載新版、一般1280×650滑鼠開原3階詳情，844×390穩定畫面三核心與新版土石接合可見；未碰4175玩家資料。

本修訂實作與有界驗證完成；最終美術、實機／高DPR／長效能仍待驗，完整ART-A1／FX3 IN_PROGRESS。一般Web已更新，Windows未匯出，Git未commit／push。英語checkpoint已置updata頂部，依Context Guard止於本階段；下一New Chat收接地感回饋／逐島代表地標。


### 2026-10-07 ART-A1-HOME：祖島三核心接入與有界驗收交付

使用者核定「左居所／中央修士／右聚靈壇」，覆蓋舊中央壇配置。既有altar.png正式場景接入storage_lingli已建level>0顯示，未建空地／無命中，點選同一營造命令；輪迴移除、重載還原、Era2居所換小院。右壇寬250／腳點(290,-100)，兩小景移開；短橫式home取景775寬與祖島一排目的島導覽避讓。檔案、來源、命令、失敗及限制見[驗收](verification/home-landmarks.md)／assets/abode/home-landmarks.json。Godot4.7.2 import／原生四PNG／living與scenery runner exit0，全量54/54 exit0（最後導覽小修之前）；型別推斷parse失敗修正後world58＋responsive exit0，最後Web匯出／壓縮exit0，diff-check通過。IAB隔離4269：一般1280×650與844×390滑鼠壇體→詳情，2→3階扣料，最終重載3階保留與短橫式單排導覽不遮三核心通過。native練氣預覽與browser金丹已賺得fixture各自有界，不冒稱空白完整新手／實機驗收。既有Font／CanvasItem／ObjectDB退出診斷保留。

**實作／上述CLI和桌面Web子範圍完成；完整ART-A1／FX3仍IN_PROGRESS**，等待使用者最終美術、實機／高DPR／長效能。一般build/web更新，4175玩家資料未讀寫，未commit／push／更新Windows包。英語checkpoint在updata頂部；依Context Guard停在本階段，下一New Chat收視覺回饋／逐島補代表地標，靈界專屬場景仍未開展。


### 2026-10-07 M2-D-FX3-ROUTES：飛劍用途調整子項 DONE

使用者核定撤下洞府九把循環飛劍、固定光軌及中央舊裝飾粒子，保留主角吸靈。島間貨運改沿用飛劍美術，每條既有航線最多一把，僅實際正數在途貨物顯示，依 remaining 朝目的島移動；閒置／到貨收起，低特效停光尾／shader時鐘。修改 living_abode.gd、island_world.gd、兩項 runner、native_vfx_preview.gd；[詳細命令／結果／限制](verification/fx3-flight-routes.md)。Godot4.7.2 import、世界51 checks、突破 runner、全量54/54、一般Web release／壓縮均exit0，diff-check通過；初次sandbox保存失敗及既有退出診斷保留。IAB隔離4268真實滑鼠關閉摘要，確認閒置洞府新美術／無循環飛劍；browser載貨鏈、實機／高DPR／長效能仍待驗，完整FX3仍IN_PROGRESS。玩家4175資料未存取，未commit／push，Windows包未更新。下一步使用者重新載入一般Web檢視，再補實際載貨及装置／效能驗收；大型後續工作New Chat。


### 2026-10-07 M2-D-FX3-ART1-PACK-AUDIT：一般 Web 包補入新美術

使用者回報測試未見背景更新。本輪確認 living_abode.gd 已引用 fx3art1 sky／terrain 與 cloaked_cultivator；但 Git HEAD 4223eaf 與目前 origin/main 追蹤參照尚未包含這批未提交修改，新資產亦為 untracked。原 build/web/index.pck（10/6 21:40）及 build/windows/dao2.pck（10/5）沒有新 sky／hero 路徑；build/fx3art1-web（10/6 22:11）才有新美術。一般 Web 包落後是可確認的差異；使用者實際測試 URL／執行檔尚未取得，不能斷言正在使用哪個包。

已執行 Godot --version（4.7.2.stable.official.ed1daf0bf）、Godot --headless --path . --export-release Web build/web/index.html（exit0；仍有 sandbox user:// 目錄診斷），以及 node tools/prepare_web_compression.mjs build/web（exit0，四首 BGM companions 已準備）。重新檢查 PCK 包含 fx3art1 sky、terrain、cloaked_cultivator 與 ui_icon 路徑；PCK 17,374,892 bytes，SHA256 645dfd32f7ae0734c5a166b0d189a695f427e4a06226eb9f9880ec50b3620c94。未手改匯出物、未更改玩家保存、未提交或推送 Git，Windows 包本輪未更新。

Get-CimInstance 程序盤點遭 CIM 權限拒絕；Invoke-WebRequest 127.0.0.1:4175 遭 sandbox 通訊端權限拒絕，故未證明服務目前狀態或實際瀏覽器畫面。本輪未重跑規則測試（來源邏輯未修改），完整 FX3 美術／裝置／效能驗收維持 IN_PROGRESS。下一步使用一般入口重新載入新 Web 包；若仍無變更，核對實際 URL／桌面包；Git 美術 checkpoint 與 Windows 匯出按使用者後續範圍處理。


### 2026-10-06 M2-D-FX3-ART1：夕照背景、質感空島與披風主角

使用者插入任务，實作及本輪有界驗證PASS，完整FX3 IN_PROGRESS。三張分離資產、覆頭中性主角、18點吸靈與角色中心雷劫接入；低特效停止角色動效，正式規則／保存不變。修改檔案與完整命令／失敗重試見[驗收](verification/fx3-art1.md)：54/54 exit0、最後island_breakthrough追加契約exit0、原生隔離快照不變、獨立Web匯出／BGM壓縮exit0、IAB1280×720及844×390滑鼠試播／重播／低特效通過。退出Font／CanvasItem警告保留；人工美術、高DPR／實機、下載與FPS長觀測待驗。試玩 http://127.0.0.1:4267/index.html ，独立origin，不使用既有玩家資料。下一New Chat依美術回饋微調或補效能；不展開下一大型階段。英文checkpoint置於updata頂部。

### 2026-10-05 RES1-C2-PERF-R2：效能劣化定位與修復驗收 PASS（AGY 交付）

依據 ADR-010 恢復預算標準與使用者要求，完成持續 FPS 劣化定位與實作修復：
1. **排查與修復**：
   - 消除 `building_catalog.gd` 每 0.25 秒對全部建築列無條件覆寫 `meter.position` / `meter.size` 所引發的容器重新排版（Layout Reflow）風暴，加入前後位置比對保護。
   - `abode_building.gd` 在 `_process()` 首行加入 `if not visible: return` 提早返回，徹底阻斷不可見世界建築每幀文字字串格式化與 `queue_redraw()` 開銷。
   - `abode_flows.gd` 大幅降低祭壇靈氣粒子與拖尾 CanvasItem Immediate 繪圖命令密度，平抑 WebGL/Compatibility 批次呼叫開銷。
2. **驗證與交付**：
   - 全量 54/54 Runner 通過（exit 0）。
   - 幀統計工具自我測試（16 PASS）、observer 測試（13 PASS）、負載摘要契約（6 PASS）全數通過。
   - Web 匯出與 Node Brotli/Gzip 壓縮正常。
   - ADR-010 幀率門檻驗收：四組觀測（300s 基準 59.74 FPS、300s 50次管理操作 59.56 FPS、300s 延長 59.74 FPS、60s 冷啟動 59.85 FPS）全數近目標 ≥55 FPS 佔比達 98.3%~100%，末 10 秒恢復正常，總體判定 `desktopRecoveryGate=PASS`。詳見 [R2驗收報告](verification/res1-c2-agy-r2.md)。
3. **後續接軌**：
   - R2 效能修復交付完成。後續可在乾淨上下文中無縫推進 RES1-D 系列任務與完整自然時間驗收。

### 2026-10-05 SKILL-B1：B 方案技能與多島融合

使用者明確選 B，接回六項技能，保持 Era2 2／1.2／200、金丹容量2000、築基靈池和島嶼加工所有權。新增藏經閣／經書殿與修行技能頁；Session命令扣點、防重扣；Production加成、輪迴重置；schema3 skills版本、原JSON雜湊備份與讀回後雙槽提交。相關檔案為content/skills/era2.json、content/buildings/study.json、skill_system、GameState／GameSession、Production／TimeAdvancer／CommandProcessor、ReincarnationRules、SaveCodec／SaveManager及原生導航面板。

Godot4.7.2、全54 Runner、41項技能契約、字型子集生成／check、獨立Web匯出與音樂companions；真實瀏覽器桌面研習／重載、844×390內部捲動與建築精通扣200保存。初輪內容掛載／舊狀態視圖和缺字問題已修正，失敗日誌保留，既有RID／ObjectDB退出訊息不稱零error。[命令、結果與限制](verification/skills-b1.md)。

新增 ADR-012 覆蓋 ADR-011 暫不移植技能的段落，歷史保留。舊分支完整保留，普通main push與ff-only同步；後續分歧必須回報。下一New Chat續技能工作值的人類節奏驗收、D2自然時間／裝置與AGY R2，完整D2／R2不標DONE。

### 2026-10-05 GIT-SYNC-INTEGRATION：兩處成果保存、VFX合併與master審查交付

d54faa3主目錄checkpoint；舊detached工作樹改保存分支codex/preserve-vfx-20261005／fb65890，47efd8d雙親merge已把VFX納入main。解決兩個場景程式與三個交接文件衝突，保留D2／R2較新接線；修正短橫式演出遠景題字重疊並加跨四版型回歸。master ff86f85保存本地參照，其一般技能／舊Era2／保存模型與ADR-011及多島權威供給衝突，審查已交付、功能未合併；已向使用者提出決策選擇，未收到改案前維持核定規則。

Godot4.7.2／import exit0；初輪及最終53/53 Runner exit0、指定突破exit0、獨立Web兩輪export／Node compression exit0。真實IAB新origin4264：試播／低特效／返回／重載／重播，最終1280×720及844×390題字避讓通過，返回仍練氣1/10，warn/error查詢空。既有RID／ObjectDB退出訊息保留，原始Runner日誌尾端空白使staged diff-check曾非零，源碼／文件另查。修改／命令／截圖／範圍見[整合紀錄](verification/git-progress-integration-2026-10-05.md)。

更新README／ROADMAP／本檔／ai-handoff／英文updata，保存測試日誌與隔離fixture；pull.ff=only已設定，主線採普通push並核對遠端。舊工作樹及master備份保留；正式开发固定main。FX3／D2／C／R2完整DoD未因Git整合放行，R2仍交AGY。依Context Guard完成本輪有界整合後停，不展開重新設計一般技能；下一New Chat續既有驗收，或依使用者決策另處理技能分歧。


### 2026-10-05 GIT-SYNC-AUDIT：分支／工作樹檢查完成，整合未執行

依使用者要求完成遠端 fetch 與版本稽核。main d0e5282 比 origin/main f20d3ef ahead 1／behind 0，無 main 拉取合併需求；origin/master ff86f85 與 main 分歧 7／1，其技能／內容模型須另行審查。舊 detached 工作樹 7c23/Dao2 停 main 祖先4dd4ddb（落後5提交），仍有17 tracked修改及未追蹤VFX，未整合；主目錄記錄寫入前45 tracked修改／273 untracked檔案。未merge／pull／commit／push／刪除工作樹。fetch升權exit0，唯讀status/log/rev-list/cherry/diff完成；初sandbox拒寫／網路／工作樹status失敗經後續成功檢查釐清。詳[稽核與整合順序](verification/git-sync-audit-2026-10-05.md)。新增稽核文件，更新本檔及updata英文checkpoint；遊戲狀態不变。下一先保存兩處dirty成果，再評估VFX與master逐項整合；New Chat接續整合，D2/R2驗收仍依原分工。


### 2026-10-05 RES1-D2-R1：Web保存子階段PASS，完整任務IN_PROGRESS

最終 **53/53 Runner／exit0**（管理89、D2 215、丹霞world38），Godot仍4.7.2。IAB真實Web九案例、16份報告 **400 checks PASS**：空白自動正常命令220＋reload4，其餘保存矩陣176；其中215共用契約也含MemoryAdapter診斷，不能稱400全是實際故障。正常內容／命令、11561模擬秒到金丹十層，實際localStorage保存與重載完整狀態；不是完整自然時間滑鼠首段。quota實際填滿、受控拒讀／拒寫／索引／損壞／遷移及兩真實分頁接管通過。正常滑鼠無Seed開局茅屋二階／重載／練氣二層，以及金丹隔離檔丹霞加工拒寫／重試另有證據。

發現保存成功後丹霞管理仍留「操作未保存」；island_management_panel加恢復訊息、living_abode成功結算接線，規則拒絕訊息保留，C1補兩項有意義檢查並於正常修正版實際重驗。沒有改經濟、schema、規則版本、TimeAdvancer或R2工具。新增src/verification/res1d2_contract.gd＋UID（215原生／Web共用）、tools/res1d2_web_server.py與res1d2_web_audit.py、active fixture／Web驗收與artifacts；修改D2 runner／web_persistence_probe／C1 runner及入口文件、英文updata。既有dirty、玩家進度與原三包保留，無commit／push／部署。

命令：Godot --version／獨立D2 --headless各exit0，tools/run_all_runners.ps1初輪與修正後各53/53 exit0；WebPersistenceTest與Web最終匯出exit0，Node prepare_web_compression音樂／Brotli roundtrip exit0，Python audit exit0，git diff --check exit0（CRLF提醒）。正常新PCK0cf07875…71890、測試f0290bca…c95e；原web／res1d2／res1d2r1 hash不變。完整命令、修改、報告、截圖、包清單與邊界见[Web驗收](verification/res1-d2-web-r1.md)。

失敗保留：初sandbox loopback逾時／停止exit1後授權同命令可用；首import exit0有user://拒寫及歷史JPEG-bytes .png圖匯入錯誤（不進正常包）；首probe export缺目錄exit1後建立重跑exit0；cp950 fixture讀取失敗後UTF-8通過；錯誤頁URL policy阻擋後新分頁可用。負面JSON／既有RID／ObjectDB退出診斷保留，不稱整輪零error；沒有自動審查拒絕。

**D2-R1／D2／D與C／C2／R2仍IN_PROGRESS；R2交AGY。** 已過D2保存矩陣不再列未開始；下一完整自然時間滑鼠流程、人工擴產／運力／加工／修行取捨與美術、實體手機／觸控／DPR2–3／跨瀏覽器／自然凍結／長期GPU-WASM與C-R2放行。本輪父1280×720／DPR1.25、iframe1280×650及短橫844×390，不冒稱手機／FPS／IndexedDB。4258／4259保留隔離進度與loopback服務，頁面停launcher／override reset。依[AGENTS](../AGENTS.md)「單一Session完成當前階段任務（測試與驗收通過）」完成有界保存子階段，英文checkpoint置updata最頂部，New Chat接續剩餘驗收。

### 2026-10-05 RES1-D2-R1：丹霞世界／美術子階段交付，完整任務IN_PROGRESS

丹霞獨立赤岩島體／藥坊兩runtime PNG與reference、三提示詞／來源／授權／圖層manifest已交付，內建image_gen；世界→canonical丹霞管理與管理→世界、祖島返回、真實草／百年草／丹液在途視覺接入。築基可看金丹解鎖，未開拓無藥坊；四島控制按安全寬度換行／避開導航，短橫式遠島隱藏原山域／祖島題字。BuildingCatalog補回HUD已用的第四個延後資源刷新參數，沒有改規則／保存版本或TimeAdvancer。

引擎4.7.2／asset audit3RGBA／import／Web各exit0。全量**53/53 PASS／exit0**兩輪，最後題字修正後全量含world37；最後管理雙向入口一行補接另**world38＋C1管理87 PASS／exit0**，沒有冒稱其後又跑53。原三島world26及響應式回歸exit0。最終獨立build/res1d2r1，PCK含兩runtime圖／排除參考；原build/web及build/res1d2 hash保持。詳細命令、完整修改、沙箱保存失敗／接口不相容／測試clone與版面修復、RID/ObjectDB退出診斷、PNG與Web證據見[D2-R1驗收](verification/res1-d2-r1.md)。

IAB獨立4257 origin、UI載入一次CLI命令取得金丹檔，1280×720.4／844×390、DPR約1實際滑鼠丹霞世界／點島面進管理／持續丹液扣草與保存／重載工作延續／Godot內部捲動停止、resize／題字避讓；不是空白瀏覽器完整金丹可達性或保存故障矩陣。沒有FPS、IndexedDB、實機或高DPR新證據。新assets／audit／server／world runner+uid／owner handoff，修改island_world／island_management_panel／living_abode／building_catalog／export_presets／fixed runner及入口文件；既有dirty、測試artifacts與玩家資料保留，無commit／push。

**D2-R1／D2／完整D以及C／C2／R2仍IN_PROGRESS，R2交AGY**。下一同D2-R1：完整正常Web空白首段＋D2實際quota／中斷／重試／雙分頁矩陣，再人工擴产／運輸／修行取捨、美術及裝置／相關R2放行。依[AGENTS](../AGENTS.md)「單一Session完成當前階段任務」停止本世界子階段，英文checkpoint追加updata頂部；下一大型驗收使用New Chat。

### 2026-10-05 RES1-D2：IN_PROGRESS（方案、正常規則／管理、CLI與桌面Web子範圍已交付）

使用者選定Era＋設施門檻及新增築基擴容設施，[ADR-011](decisions/ADR-011-era3-capacity-and-skill-gates.md)已記錄。築基靈池每階1000、最高3，保留原聚靈壇；兩階可令原庫2級＋基礎達2300。正常attach載入Era3／新建築，丹霞唯一丹液加工與成品回運、祖島T3／丹藥／靈石／符咒及晉階費用閉環；版本res1-d-2／core-flow-10-danxia、schema3，舊C明示歸檔後候選提交，失敗可重試，輪迴保留合約版本並清當世產業。

**215 checks／52/52 Runner PASS、exit0**，空白無Debug達金丹Lv10（11561秒）；進行中加工與貨物保存、600秒重載／離線／分段一致、C歸檔與index拒寫／重試、損壞復原／未知版本及壽盡輪迴。全量後丹霞庫存／純中文名稱調整另87 checks／exit0；獨立Web兩次匯出均exit0，最終1280×720.4（DPR約1）／844×390實際滑鼠持續丹液→停止→重載祖島丹液10、祖島T3入庫1與靈力2300可見。完整命令、修改來源、早期失敗／停止卡住測試與退出診斷見[D2驗收](verification/res1-d2.md)。沒有覆寫玩家檔、更新引擎、commit／push；build/web PCK與AGY基線hash一致，測試輸出在build/res1d2及獨立4256 origin。

新增content/buildings/era2.json、content/eras/era3.json、D2 Runner與.uid、HTTP工具／ADR／驗收／共享修改交接。修改IslandProgression／IslandEconomy、CommandProcessor／ReincarnationRules、GameSession、SaveManager／SaveCodec、四島管理／世界入口guard／建築名稱與導航文案，C／TEXT1測試前置及全量入口；未改TimeAdvancer／R2診斷算法。沙箱全量首次user://拒寫exit1；授權重跑首次TEXT1缺Era3診斷材料卡住、確認PID後僅停該測試exit-1，修正後最終52/52。首版BGM companion缺失保留warning，補複製後重載無新增；不稱整輪零錯誤。沒有実體觸控／高DPR／FPS／IndexedDB新證據。

**D2與完整D IN_PROGRESS，C／C2／R2仍IN_PROGRESS；R2交AGY**。丹霞專用世界美術與入口、瀏覽器從新檔完整首段及保存故障矩陣、人工玩法／辨識度與裝置／C/R2放行仍待驗。下一D2-R1，用New Chat續；依Context Guard英文checkpoint已置updata頂部，不在本輪展開下一大型美術／驗收工作。4256保留隔離測試服務與存檔，頁面停launcher、override已reset，沒有持續遊戲負載。


### 2026-10-05 RES1-D1：DONE（前置稽核與隔離契約）

**216 checks PASS／exit0**：空白開局由T1建祖業與容量，經Era1／2升至Era3，開丹霞、運回百年草與T2、加工金丹／T3陣芯，修行逐項扣料至Lv10（11512模擬秒）；不足／錯島／滿倉／保留容量／運力瓶頸／守恆／600秒一次分段完整狀態一致。DAO1唯讀稽核8 source hash／4技能／2技能建築通過。完整[驗收及依賴表](verification/res1-d1.md)。**正常Era2→3仍被最高靈力容量1100／需求2000阻擋**；隔離庫容每級250、Era-only替代技能及丹液／陣芯費用僅提案。正式Era3與一般技能未實作。

新增`tests/res1d1_contract_runner.gd`、`tests/fixtures/res1d1/{era3.json,contract.gd}`、`tools/res1d1_audit.ps1`、專屬驗收與artifacts；更新README／ROADMAP／ai-handoff／rule-differences／D1交接／updata，保留既有dirty。Godot4.7.2版本exit0；audit首跑PowerShell5未指定UTF8失敗exit1，修正後exit0；獨立Runner120→207→211→216均exit0，最終res1-d1-delivery.log。未跑共用全量／import／Web匯出，未改src／正式content／schema／玩家保存／R2工具或共用fixture；無瀏覽器／效能或正式保存新驗收。git diff --check exit0（CRLF提醒）。

**完整D TODO、C／C2／R2 IN_PROGRESS，R2仍交AGY**。下一D2正式整合準備尚未開始：先定容量／技能方案、協調共享核心，接C版本丹霞／加工歸屬／丹液航線／修行、保存版本與復原重試，再補正常無Debug首段／重載離線／輪迴／美術与相關C/R2放行。英文checkpoint已追加updata頂部，按Context Guard停止本階段，New Chat續下一大型工作。下方同日初始分工為歷史。

### 2026-10-05 使用者分工：R2 → AGY，Codex下一D1

**交接文件DONE；R2／C／C2仍IN_PROGRESS，RES1-D1 TODO（Codex下一），完整D TODO**。使用者要求優先：R2持續劣化由AGY調查／修復，Codex可推進Era3前置、丹霞島與T2→T3隔離核心契約；允許D1並行，覆蓋歷史只續R2／不開下一階段順序。D1並行不消除R2失敗，也不放行完整C/D。具體[AGY交接](handoffs/2026-10-05-r2-agy.md)、[可貼Prompt](handoffs/2026-10-05-agy-r2-prompt.md)、[Codex D1範圍／Prompt](handoffs/2026-10-05-codex-res1-d1.md)。

本輪新增上述三份文件，更新README／ROADMAP／ai-handoff／development-status／英文updata頂部；列清前輪DPR1.25失敗與本輪DPR1未重現、基線hash／dirty／存檔與browser profile差異、命令、驗收、共享檔單方修改与FPS測試時段。D1先不碰正式manifest／Session／SaveCodec／TimeAdvancer／世界與Web build；真正需共享核心則協調。沒有啟動或傳訊AGY、D1程式、美術／存檔變更、引擎／Web／Runner新驗收、commit／push／部署。文件驗證命令與結果見handoff-checks.log；下一Codex New Chat執行D1，AGY使用專用prompt接R2。

### 2026-10-05 RES1-C2-PERF-R2｜持續劣化定位，本輪未重現

**R2／C／C2 IN_PROGRESS、D TODO**。相同正常Web hash，1280×720／DPR約1三組300秒59.744／59.564（50次管理開關）／59.744、重載60秒59.847，四組valid／恢復PASS。同期CPU237／GPU150筆；共用GPU process高CPU時仍近60、heap大小與FPS不是單一對應，不能據此指定GPU／GC／洩漏根因。前輪DPR1.25／木屋3階，此輪DPR1／木屋2階，不能以本輪PASS消除前輪失敗；原失敗保留。詳[本輪證據／命令／限制](verification/res1-c2-sustained-degradation.md)。

新增tools/sample_gpu_load.ps1、summarize_system_load.py、test_system_load_summary.py及res1-c2-degradation-* raw／summary／PNG／console／logs；同步README／ROADMAP／ai-handoff／updata。Godot4.7.2符合、6系統／16幀統計／13observer契約PASS exit0、PowerShell parse PASS、summary解析與gate PASS。GPU採樣exit0；CPU觀測结束主動Ctrl+C exit1保留237筆。最初CIM拒讀与glob查詢失敗已記錄；無新Godot來源／匯出／51 Runner／完整保存故障回歸，不冒稱重跑。4248既有server會追加舊recovery raw，本輪另存獨立raw。沒有種檔／玩家檔覆寫／commit／push／部署。

4248分頁停launcher釋放writer鎖，override reset，現有進度保留。下一仍R2：同進度1280×720／DPR1.25重現與DPR對照，若失速再做低特效A/B與主迴圈／節點／draw calls診斷；不得先改規則或認定DPR是原因。裝置／觸控／自然凍結／跨瀏覽器／長期記憶體與人工待驗。本輪有界定位階段已完成，依AGENTS Context Guard英文checkpoint置updata頂部，下一大型工作使用New Chat。

### 2026-10-04 RES1-C2-PERF-R2｜正常恢復／長觀測驗收未過

**R2／C／C2 IN_PROGRESS、D TODO**。正常頂層IAB Chromium154、1280×720／DPR1.25，無CPU profile：首60秒59.880／首300秒59.823恢復PASS；追加54次有300ms間隔管理操作的300秒54.740、同頁延長300秒48.088、重載60秒35.105均NOT_PASSED。第三組末45秒約20–41FPS／尾端33，第四組近目標僅53.33%；重載也未恢復。全部5組有效遊戲樣本2/5通過，總desktopRecoveryGate NOT_PASSED；無遊戲對照59.997僅診斷。不能歸因GC／GPU／CPU／特定節點或管理洩漏，下一定位持續劣化。詳細窗口、檔案、命令與限制見[本輪驗收](verification/res1-c2-recovery-browser.md)。

三島滑鼠切換／返回、管理開關、木屋2→3及扣料／重載保留、完整資源模式通過；重載只新8秒，遊戲console觀測無warn/error，保存的console僅最後對照文件。首批快速點擊不作逐次成功證據，另有間隔50次＋4次確認，分批驗證畫面；無逐次收據。沒有新Godot來源／匯出／51 Runner或完整保存故障矩陣，前輪證據保留日期。

修改review fixture僅重封UTC/save_id，快照相等PASS；新增verification及res1-c2-recovery-* raw／summary／log／截圖，同步README／ROADMAP／ai-handoff／updata。Godot4.7.2符合，review保留user://log拒寫；首sandbox server連線逾時後停止exit1，授權同命令server可用。Python16／Node13契約PASS、summary解析exit0（gate失敗）、diff check exit0／LF-CRLF提示。PCK13433449…216eba、WASMfc74679e…57d0沿用前輪。既有dirty／玩家進度不覆寫，無commit／push／部署。

4248正常隔離origin服务保留session6020，分頁停launcher釋放writer鎖；已有進度按開啟遊戲，勿種檔。手機／觸控、DPR2/3、自然凍結、跨瀏覽器、長期WASM/GPU及人工美術／節奏待驗。下一同R2持續劣化取證與修復後重驗，不跳D。本輪長觀測／輸出已累積，依Context Guard英文checkpoint置updata頂部，New Chat開始下一大型定位階段。

### 2026-10-04 RES1-C2-PERF-R2｜使用者核定放置遊戲 FPS 恢復標準

標準／工具修訂子階段DONE；**R2／C／C2 IN_PROGRESS、D TODO**。常態目标60，偶發30後回升可接受，阻擋常態低FPS／持續劣化未恢復。採[ADR-010](decisions/ADR-010-idle-frame-recovery-budget.md)，覆蓋全部歷史嚴格平均60／p95≤20硬gate；55、5秒窗口、接近目標占80%、末10秒恢復是本輪工程定義，低谷10秒警示不直接否決。正常至少60秒，另5分鐘／50次操作／reload確認趨勢；有限樣本不宣稱永久穩定。

修改summary、metrics、preview server、observer tests、README／ROADMAP／docs07／handoff／status／updata，新增ADR與[修訂驗收](verification/res1-c2-idle-fps-policy.md)。Python self-test16、Node observer13 PASS／exit0，含5／10秒30後恢復、持續30、末段不恢復、逐步劣化及窗口切割。首次p95測試預期錯誤已修為p99並記錄，產品門檻未為該assert調整。旧raw三15秒57.999／57.864／57.799，短窗口恢復3/3符合；新gate為INSUFFICIENT_EVIDENCE，尚欠連續60秒／長期實測。AST／Node syntax／diff checks見本輪log。

沒有Godot／規則／保存／美術／匯出變更，沒有新真實瀏覽器或51 Runner；前輪已通過矩陣保留日期。歷史失敗與raw不覆寫；玩家檔／既有dirty保留，沒有commit／push／部署。下一同R2只補正常恢復／持續劣化與操作驗收，手機／高DPR／背景／跨瀏覽器／人工另列待驗。英文checkpoint更新updata，依Context Guard本階段結束，New Chat接續。

### 2026-10-04 RES1-C2-PERF-R2｜長幀入口／前置檢查診斷子階段交付

**R2／C／C2 IN_PROGRESS、D TODO**。living_abode的profile frame覆蓋_process入口／Web鎖檢查與提前返回，await前結束以排除等待；runtime_profile.js增加Long Animation Frames的scalar來源、窗口、pending、容量／drop；summary與兩契約test補驗證。profile仍預設關閉，收益／RNG／保存schema／頻率／重試／美術不變。完整[驗收、修改、命令與證據](verification/res1-c2-main-loop-tracing.md)。

Godot4.7.2版已驗；全量**51/51 exit0**（754資源／145精確／27async），world26 exit0；正常／profile export與compression各exit0，兩PCK同13433449…216eba、WASM不變。JS基礎／LongTask／LoAF契約、Python summary5、observer9／FPS8通過。首sandbox世界Runner拒user://寫入、Nil／停滯後Ctrl+C，授權重跑通過；既有退出Font／CanvasItem／ObjectDB／resource診斷保留。

三組60秒真實診斷：iframe1280×721捕捉216.8ms rAF／222ms task，同窗完整process0.4ms／preflight0.1；LoAF支援但無entry。改頂層1280×720取得LoAF；第二組83.3ms rAF／84ms task／85.3ms LoAF，**index.js MainLoop_runner84.1ms**，同窗process0.4／preflight0.1／HUD與保存0。只縮小到引擎入口，不能指定WASM內部、GC或GPU根因；另50.1ms窗與保存30ms重疊。三組皆valid、CPU／task／LoAF零drop、POST204，全部排除FPS gate。

正常同origin頂層1280×720／DPR約1、無profile bridge，三組**57.9990／57.8636／57.7992FPS、pooled57.8873、p95均16.9／max33.5ms**；嚴格60未過，不宣稱與历史不同iframe／DPR狀態有因果改善或退步。正常console空、reload只新4秒；本輪未新做升級／窄版／完整Web故障／節流48h矩陣。手機觸控／高DPR／自然凍結／跨瀏覽器／長期GPU／人工仍待驗。

新4246過舊fixture載入壽盡未取樣，已停止；重封UTC以新4247正常32秒離線取得診斷。保留[4247隔離入口](http://127.0.0.1:4247/launcher?metrics=1)，服務session96276、profile-build與normal同PCK；既有資料按開啟遊戲，拒覆寫。只停止本輪4246，玩家origin未操作、dirty保留、未commit／push／部署。下一同R2：MainLoop_runner內WASM／其他節點／繪圖追蹤與正常33ms掉幀，保持60與保存契約。依Context Guard英文checkpoint置updata頂部，請New Chat續同R2，不跳D。

### 2026-10-04 RES1-C2-PERF-R2｜定時View／encode改善與長幀關聯子階段交付

**R2／C／C2 IN_PROGRESS、D TODO**。定時HUD沿用state/revision保護View，明確命令／debug／重載刷新仍重建，修行封頂真改值時失效；SaveCodec保留JSON解析後checksum，重用首次JSON省略最後完整序列化，不將近整數正規化寫回保存。schema3／rules／收益／RNG／命令與15秒保存／重試順序不變，JSON頂層欄位順序不同。修改living_abode、save_codec、resource_feedback_runner，新增唯讀encode_profile＋UID；profile／metrics／preview server／summary與契約工具增加限定profile的60秒＋LongTasks。

固定暖機快照，同程序交錯舊encode17.368ms→14.9985ms，110次完整envelope／decode、14組浮點與跳脫字串、來源hash不變。最終Godot4.7.2版已驗；全量**51/51 exit0**（resource754、精確145、async27）、world26、兩版正常與保存probe export／compression companions exit0；實際Web C2 retry49 PASS。工具profile含LongTasks契約、observer9、summary4／FPS8通過。初探針hash邊界／sandbox loopback timeout、native user://log拒寫與既有退出Font／CanvasItem／ObjectDB診斷保留，詳[完整驗收與命令](verification/res1-c2-view-encode-longframes.md)。

真實IAB遊戲1280×650／DPR1.25（override未生效，不稱720）：三非profile改前pooled59.8858、改後**59.6190FPS**，p95均16.8ms，改後第二組**183.3ms**；嚴格60未過、不稱FPS改善。相同origin／fixture來源／HUD，遊戲時辰與自然離線8684／461秒不同，非同快照配對。profile另三組HUD5.24–5.48→3.28–3.36ms，View含span幀70–72→29–32，單次仍約2.4；encode12.8–13.8→11.0–11.9ms，保存15.5–17.6。profile均排除正式FPS gate。

兩個60秒診斷3587／3595列、零drop、有效：捕捉**166.8ms rAF與180ms self LongTask**重疊，但近似同窗已量process僅**0.3ms**，HUD／保存／View span0；另組max49.9／53ms LongTask。這是task elapsed關聯，沒有call stack，不能指定GC、GPU、其他節點／引擎或OS根因。大尖峰根因仍待定位。桌面完整模式／木屋2→3扣料及即時容量產率、重載保留3階／只新11秒、844×390捲動／模式／固定返回及恢復桌面通過；console空。

正常PCK53d3400c…99d21e3／核心br14,451,027 bytes，WASM保持；未手改build、commit／push／部署。全量Runner重生隔離fixture，既有dirty保留，玩家檔不碰。4243入口確認可讀未開檔；本輪[4244正常隔離試玩](http://127.0.0.1:4244/launcher?metrics=1)保留，已有進度按開啟隔離遊戲、拒覆寫；4245保存probe服務停止，其他服务未中斷。完整146案／節流48h未新跑，實機／高DPR2/3／自然凍結／跨瀏覽器／長期GPU與人工美術節奏待驗。

下一仍同R2：未覆蓋task／引擎／其他節點耗時與根因追蹤，補嚴格FPS與裝置／人工缺口，不跳D。依AGENTS Context Guard英文checkpoint置updata頂部，停止本子階段，請New Chat接續。

### 2026-10-04 RES1-C2-PERF-R2｜HUD優化子階段交付，整體IN_PROGRESS

使用者要求「HUD 優化，仍不進 D」。修改`src/presentation/feature_navigation.gd`、`abode_hud_controller.gd`、`building_catalog.gd`及`tests/resource_feedback_runner.gd`：當輪View傳入導覽／其他layout使用既有state/revision保護；一次合併核心與共享資源卡，資源副本/Era/模式/名稱/紙底失效，選中與滿倉等材質只於狀態變更時套用。沒有規則／schema／收益／保存頻率／美術變更。

Godot4.7.2版本已驗；`run_all_runners.ps1` **51/51 exit0**（資源顯示新增14項，總752；精確tick/font145／async27）、另外world26 exit0；正常Web export／compression／原MP3 companions exit0，PCK `355396258489166eaa60dd2b9748677b6a89922e52da53924491de2d8a284272`。初次sandbox NAV保存拒寫／Nil停滯已停止、授權全量成功；首個sandbox4242無法被瀏覽器連線，重啟授權服務成功。故障注入JSON及既有world Font/CanvasItem/ObjectDB/resource退出診斷保留。命令、檔案、原始與失敗日誌見[完整驗收](verification/res1-c2-hud-optimization.md)。

真實IAB非profile：前後各三組同尺寸／DPR／fixture來源／HUD模式；sample1280×721／DPR約1，iframe DOM1280×720。pooled **59.4635→59.5082FPS**，p95均16.8ms，after max **183.4ms**（原因未定位），六組均嚴格60未過；遊戲時間／自然離線66與12秒／時辰／庫存不同，微小差異不稱確定FPS改善。修改後另三組profile HUD **5.58–5.82ms**／navigation0.21–0.23／catalog1.42–1.57，保存18.2–21.3；前輪HUD12.7–12.8為历史診斷，非同快照配對，profile排除FPS gate。桌面滑鼠數量/完整、木屋2→3階扣料與重載、844×390模式/經營/修行/返回及恢復桌面通過，console空。完整Web保存故障矩陣／節流48h本輪未重跑；實機／高DPR／自然凍結／跨瀏覽器／長期GPU及人工美術節奏未驗。

**R2／C／C2 IN_PROGRESS、D TODO**。保留正常隔離試玩[4243](http://127.0.0.1:4243/launcher?metrics=1)（既有進度按開啟隔離遊戲，拒覆寫），只停本輪4242基線。下一仍同R2：剩餘View／保存編碼與長幀配對證據，維持60FPS与保存故障契約。英文checkpoint已追加updata頂部；依Context Guard停止本輪，下一大型工作使用New Chat。

### 2026-10-04 RES1-C2-PERF-R2｜耗時定位子階段交付，整體IN_PROGRESS

三組1280×720 CSS／DPR約1、同三島命令fixture的HUD平均12.7–12.8ms，內含導覽refresh/layout5.0–5.1ms、建築／資源清單3.7–3.9ms；規則有tick1.2–1.3ms。每組各一次保存18.1–22.7ms，encode13.8–18.5／commit4.1–4.2ms。24個>20ms rAF窗口中16個與HUD、2個與保存重疊，6個已量CPU不足0.5ms；只代表時間關聯，不作GPU或完整卡頓歸因。未重現200ms，未實作效能改善，嚴格60仍未放行。

修改：`src/platform/runtime_profile.gd`＋UID、living_abode／abode_hud_controller／save_manager的計時；`tools/res1c2_runtime_profile.js`、metrics／preview server與兩個summary工具及profile契約tests；review fixture只重封UTC，相關交接與[完整驗收](verification/res1-c2-perf-r2-profile.md)。profile預設關閉，獨立Web export，保存schema／rules／收益不變。核心body計時不涵蓋引擎繪圖、其他節點、前置鎖檢查、背景await或命令回調；inclusive spans不可加總。

命令／結果：Godot4.7.2版本、import exit0（前輪PNG匯入錯誤保留）；`run_all_runners.ps1`初次sandbox拒寫exit1，授權重跑51/51 exit0；之後HUD细分及bridge存在防護的最終`res1c2_world_runner`26項exit0。Web export首次目錄缺失exit1，建立後基礎／細分／防護版均exit0；compression companions均exit0；observer6、profile JS契約、Python summary3 tests／FPS summary8契約通過。瀏覽器三粗分＋三細分，raw／summary保留於profile-*。關閉profile曾觸發缺少interface錯誤，已補存在檢查，保留原console證據；最終正常啟動console空，profile再次啟用收898幀零drop（783×542／DPR1.25功能複驗，不併入三組1280×720比較）。4241隔離服務保留，viewport override已還原。正常build/web PCK未變，沒有新跑完整Web故障或48h節流矩陣。

下一同R2：優先改善FeatureNavigation重複View及BuildingCatalog資源卡重複刷新，再做命令／切頁／resize／保存回歸與同條件非profile配對量測。手機／高DPR／自然凍結／跨瀏覽器／長期GPU／人工美術節奏仍待驗，**R2／C／C2 IN_PROGRESS、D TODO**。定位階段完成後依Context Guard以英文checkpoint置updata頂部，New Chat接改善，不在本輪展開下個大型任務。

### 2026-10-04 RES1-C2-PERF-R2｜FPS量測子階段交付，整體IN_PROGRESS

同一1280×650 CSS iframe／DPR1.25，三组正常遊戲59.130／58.397／59.530FPS，pooled59.019；p95均16.8ms，34個>20ms間隔、max200ms。三組無遊戲對照pooled59.997FPS／零>20ms；嚴格60未過且門檻不變，沒有遊戲效能改善可宣稱。與前輪1280×720／DPR約1並非配對前後比較。完整[本輪驗收／命令／人工重跑](verification/res1-c2-perf-r2-fps.md)、[raw](verification/artifacts/res1-c2-perf-r2-fps-v3-metrics.jsonl)及[重算摘要](verification/artifacts/res1-c2-perf-r2-fps-v3-summary.json)。

修改：metrics v3（整段可見性／resize／DPR／ready無效防護、樣本序號、p99）、preview server同尺寸rAF切換及狀態文字；新增summary與observer契約工具；review fixture重封UTC/state保真；相關交接與證據。Node observer6、Python summary7、Node／Python syntax均exit0；Godot4.7.2版本／fixture工具exit0但user://log拒寫診斷保留。真實六組樣本有效、console warn/error空，reload只新19秒；PCK／WASM hash不變。本輪未改Godot來源／素材／保存版本，未重跑51 Runner／import／export／完整保存矩陣；未commit／push／部署。

故障：首次sandbox服務與HTTP被隔離限制；瀏覽器逾時約8591秒令fixture自然老化至8814秒。正常授權重啟與HTTP200後，舊data錯誤頁受URL policy阻擋，使用新分頁恢復；未繞過安全限制。既有dirty工作保留。

下一仍R2：先實測每秒推進／View、0.25秒HUD、15秒同步保存的個別成本，再做必要改善與同條件1280×720重測；未證實200ms尖峰來源，不能先取消保存或改收益。裝置／高DPR／人工與長期GPU等仍待驗，**R2／C／C2 IN_PROGRESS、D TODO**。新[4238隔離試玩](http://127.0.0.1:4238/launcher?metrics=1)保留，既有進度拒覆寫；4236本輪未驗。依Context Guard，英文checkpoint置updata頂部，請New Chat接同一R2。下列同日結果保留歷史日期。

更新：2026-10-04（PERF-R2續輪：節流長離線9.801／9.777秒有界通過；最終51/51＋145精確；嚴格60FPS／裝置與人工仍待驗）。較早結果保留歷史。

## 目前任務與下一步

### 2026-10-04 RES1-C2-PERF-R2續輪｜節流長離線缺口有界通過，整體IN_PROGRESS

交付：20Mbps／100ms、Brotli、相同命令賺得雙鏈狀態，兩個新origin的48h+恢復ready **9.8007／9.7770秒**，結算1.3496／1.3241秒，p95 16.8ms。原生48h CPU 2,662,373→885,503µs（約66.7%），600tick／長離線完整hash不變；600tick本輪143,887→153,945µs，不宣稱活躍短期CPU改善。快取限無命令期間的經濟固定點、無變化生產與乘區；保留逐秒浮點相加、貨運／加工／RNG／BUFF與壽盡順序。FrameBudget14ms只控制讓出；schema3／core-flow-9／24h收益CAP不變。

修改：`src/simulation/island_economy.gd`、`time_advancer.gd`、`chrono_system.gd`、`abode_scenery.gd`、`src/platform/frame_budget.gd`、`tests/res1c2_perf_runner.gd`、`tools/res1c2_perf_profile.gd`、`tools/island_preview_server.py`（無遊戲rAF對照）、README／ROADMAP／docs02／07／ai-handoff／本狀態／R2驗收／updata與cont證據。未改素材、正式玩家檔、保存版本，保留原有dirty／untracked，未commit／push／部署。

命令／結果：固定Godot4.7.2.ed1daf0bf；最終`run_all_runners.ps1` **51/51 exit0**（145精確tick/font、async27）；額外world26 exit0，三preset export＋compression roundtrip、CPU兩路hash、review fixture、package budget、HTTP13案、Node／Python syntax／diff check exit0。真實Web C2 async retry49與一般retry69 PASS；重載摘要只有新10秒、不再套48h上限；1280×720與實測844×390 CSS iframe的切島／管理／內部捲動／固定關閉／返回通過，console warn/error空。詳 [續輪證據](verification/res1-c2-perf-r2.md#2026-10-04-續輪交付節流長離線缺口)。核心br14,447,267 bytes，PCK `7264ee1f…15c11d`。初版10.6755秒及下一版10.0346秒均未過，未挑快樣本；最終兩origin9.8007／9.7770秒。

未通過／限制：桌面 **59.930FPS／p95 16.8ms**，嚴格60仍未過；無遊戲rAF59.997只作排程對照，不改門檻。未清瀏覽器profile／WASM code cache；10秒僅此兩個桌面新origin樣本通過，餘裕約0.2秒，不擴張為所有裝置承諾。指定手機觸控／30FPS、高DPR2/3最大zoom、自然背景凍結、其他瀏覽器、長期WASM／GPU與人工美術／節奏仍待驗。世界退出既有RID／ObjectDB診斷保留；sandbox世界Runner拒user://寫入後停止並以授權隔離環境重跑26 PASS，Python PATH失敗改bundled runtime，初版工具縮排錯誤已修。

下一：仍PERF-R2嚴格60FPS的量測／決策與裝置／人工放行，**C／C2／R2 IN_PROGRESS、D TODO**。4236 [正常版隔離試玩](http://127.0.0.1:4236/launcher?metrics=1)保留，已有進度拒覆寫；本輪4231–4235／4237服務停止，既有服務未中斷。依AGENTS Context Guard，本階段驗收後主動剎車，英文checkpoint置updata頂部；下一New Chat續R2，不展開D。


### 2026-10-04 RES1-C2-PERF-R2｜離線改善交付，IN_PROGRESS

交付：同輪相同fixture／1280×650／Brotli／無節流，48h恢復18.03→最終7.75秒；逐秒終態、事件、RNG與保存版本保持。快取無命令期間的宗門／靈獸被動與BUFF／天時乘區，重用一秒Amount delta與基礎容量，當秒預留／庫存重讀；FrameBudget10ms只控制讓出。量測工具修正少算第一段間隔的分母，保留rawWindowFps與完整gaps，不將統計修正當成FPS提升。

修改：`src/simulation/time_advancer.gd`、`src/platform/frame_budget.gd`、`src/abode/living_abode.gd`（console階段標記）、`tests/res1c2_perf_runner.gd`、`tools/res1c2_perf_profile.gd`、`tools/res1c2_metrics.js`，本節、README／ROADMAP／docs02／07／handoff／驗收與updata。既有dirty／untracked工作保留；未commit、push或部署。

命令與結果：Godot4.7.2.ed1daf0bf；`run_all_runners.ps1`兩輪最終51/51 exit0（最終121精確檢查）；原async27 checks、世界26通過；三preset最終export＋`prepare_web_compression.mjs` exit0；font `--check`／Node語法／HTTP13案／diff-check通過。真實Web retry49、重載只新25秒、桌面／短橫式操作證據见 [R2驗收](verification/res1-c2-perf-r2.md)。world退出FontAdvanced／CanvasItem／8 ObjectDB／1 resource診斷保留。初次sandbox loopback／user log受限，以及誤用相對log-file的`user://E:`診斷如實記錄，正常隔離授權回歸通過。

未通過：20Mbps／100ms長離線ready13.55秒（結算5.16秒）仍超10秒；嚴格60FPS仍未過（最終59.80FPS／p95 16.8ms／max33.3ms）。新檔同網路8.45秒、最終本機長離線7.75秒／結算308幀p95 16.8／max17ms只代表相應案例通過。人工美術／節奏、手機／高DPR／最大zoom、自然凍結、跨瀏覽器與長期GPU仍待驗。**下一仍PERF-R2缺口與裝置／人工，C/C2 IN_PROGRESS、D TODO，不跳D；依Context Guard用New Chat接續。**

### 2026-10-04 RES1-C2-PERF｜桌面效能改善交付，IN_PROGRESS

交付：正常Web核心br14.44MB／gzip16.68MB（四首原MP3另5.35MB，br含全部19.79MB），20Mbps／100ms新origin新檔ready8.49秒；600秒規則CPU539866→271115µs約減49.8%、600ticks與終態hash相同。View以state身分＋revision快取，無命令結算準備純規則參數，逐秒BUFF／天時／收益／事件不改；runtime字型覆蓋1809字元、metrics／wght保持並更名，原字型不改；Godot來源import尺寸／品質改動，原PNG／提示詞不改；Web音樂依需求另下載、HTTP503後实际選單關→開重試成功；stdlib br/gzip服務与生成companions工具。不依赖Node作核心或改schema3／core-flow-9。

修改：`.gitignore`、living_abode、abode_hud_controller、island_world、nine_realms_preview／ui_typography、TimeAdvancer／OfflineCoordinator、兩祖島＋四遠島`.import`、runtime兩TTF／manifest與字型README、音樂library、export_presets、run_all／start_web_server、perf與world Runner、subset／profile／texture／budget／compression／HTTP／metrics／static／preview工具、README／ROADMAP／docs02／07／08／handoff／本狀態／驗收及updata。檔案與來源詳[C2-PERF驗收](verification/res1-c2-perf.md)。原有dirty C1/C2/C3／BUFF工作保留，沒有commit／push／部署。

命令與結果：固定Godot4.7.2.ed1daf0bf，import／三preset export最终exit0；完整兩輪51/51 PASS exit0，107精確tick/font、世界26、presentation、CPU／texture／review保真exit0；最終fonttools4.61.1 corpus/hash／metrics／reserved-name check exit0；HTTP13案 br/gzip/q=0與MP3hash全部通過，Python／Node／PowerShell語法通過。world退出仍有FontAdvanced／CanvasItem／8 ObjectDB／1 resource清理診斷，不隱藏。首次型別、lossy PSNR、sandbox連線／user log與音樂全包時冷啟動超標均保留日誌。

瀏覽器：1280×720／DPR1.25正常双鏈，最終15秒59.45FPS／p95 16.8ms／max49.9ms；前一次59.85／16.8／33.4，嚴格平均60仍未過。844×390 CSS iframe実際管理／捲動／關閉／返回、50次Web切島warn/error空、Web async五種中斷retry49 PASS；48h分批本機18.19秒ready／86400上限／壽盡、真實reload只8秒新間隔。新檔冷啟動與p95／下載有界通過，不代表長離線／手機或完整60FPS放行。

交付4221正常版獨立origin [試玩](http://127.0.0.1:4221/launcher?metrics=1)，已有進度拒覆寫；本輪其他服務清理，原4175／4207未中斷。**未過／待驗：嚴格60FPS、長離線≤10秒、DPR2/3／最大zoom美術、指定手機觸控及效能、自然背景凍結／跨瀏覽器／長期Web/WASM/GPU記憶體與人工節奏**。下一 **RES1-C2-PERF-R2／裝置與人工放行**，不重做A/B／已通過完整桌面故障矩陣、不跳D。英文checkpoint置updata頂部，依Context Guard本階段交付後請New Chat接大型後續。

### 2026-10-04 RES1-C3｜正式美術與正常版接入（實作交付，人工驗收 IN_PROGRESS）

依當次使用者要求先製作正式美術並接遊戲，覆蓋前輪預覽限定／先效能順序。四張runtime PNG＋兩張參考＋六份提示詞／manifest；正常初始化附掛processing catalog，玩家築基後「經營→空島」保留原檔啟用，舊檔不自動改造。三島是首段切片；[30+容量／36島草案與有限材料鏈](15-island-expansion-and-art-direction.md)為後續方向，尚未實作。

修改：assets/abode/res1c3、living_abode／island_world／feature_navigation／island_management_panel、export_presets、導航／呈現／world Runner、island_preview_server／review_fixture／asset_audit工具、docs/15與C3驗收、狀態／交接文件及updata。命令：Godot4.7.2.ed1daf0bf，import與Web／IslandProgressionTest export exit0；run_all_runners.ps1最終50/50 PASS exit0；world runner22 PASS exit0（退出仍有font／CanvasItem／8 ObjectDB及1 resource清理警告）；Python素材稽核6RGBA／尺寸／提示詞／hash PASS；兩fixture只重封UTC、state一致；git diff --check exit0。正常Web獨立4206真實滑鼠驗證啟用、兩島開拓／命中、1280×720與844×390、身在遠島resize、重整保存及持續精煉產出銅精；[完整證據](verification/res1-c3-art-integration.md)。

交付：正常4175/index.html HTTP200且已更新匯出；4207/launcher正常版＋獨立origin雙鏈試玩，不讀寫其他origin玩家進度。4206測試服務驗完停止，4207交付服務保留。C/C3人工審美／節奏仍待驗；C2效能超標與實機／高DPR／自然凍結／跨瀏覽器／長期Web/GPU記憶體未放行，沒有新PNG版效能成績。下一大型任務C2-PERF＋人工，在New Chat接續，不跳D。

- **RES1-C2-R1：桌面保存追加驗收完成；整體C2仍IN_PROGRESS（2026-10-04）**。正式async＋C2命令賺得雙鏈fixture：quota／拒寫／讀回／索引／截斷49 checks，真實quota11，索引與quota各兩次真實reload7→8→6，實際雙分頁owner／拒寫／關閉接手8→8→6，拒讀／損壞各11；合計146 checks PASS，最終probe再跑retry49 PASS。**全量50/50 Runner／世界15 checks PASS、exit0；WebPersistenceTest最終export與Python語法／review fixture均exit0**。原生50次切島nodes854固定、預熱後static僅差72 bytes，不能推定Web／GPU長期記憶體。未壓縮20Mbps／100ms＋48h恢復ready67.84秒（含並行Runner負載，光下載約30秒）；本機恢復35.37秒；獨立1280×720／DPR約1祖島15秒實測48.60FPS／p95 33.4ms，**效能未達標**。raw74.38MB／gzip估算44.72MB，未達30MB。使用者明確選美術／節奏待驗；實機／高DPR／自然凍結／跨瀏覽器仍待補。修改probe、world runner及兩server，新增metrics／budget／review fixture工具、證據與文件；保存版本／規則／正式manifest不變、玩家namespace未操作。沙箱user://失敗中止後正常授權重跑，首失敗／負向錯誤保留；其他聊天BUFF修復／原未提交內容保留，未commit／push／部署。來源、命令、結果、截圖與預覽詳 [收尾驗收](verification/res1-c2-closure.md)。**下一RES1-C2-PERF（下載／render／長離線成本改善及重測），再人工／裝置放行，不跳D**；updata英文checkpoint已置頂，依Context Guard大型後續用New Chat。

- **RES1-C2：IN_PROGRESS（2026-10-04，程式／桌面候選驗收交付）**。隔離三島世界的獨立SVG島體／林場工坊／礦坑熔爐候選、同canonical route點擊、短Banner／返回、真實在途呈現已接入；原創向量来源／切層／提示／hash見assets/abode/res1c/manifest.json，未取得美術放行。Web重開／背景用application候選複本分批、platform 6ms排程預算與process_frame讓出，逐秒規則不改，完畢一次保存；正文捲动與摘要關閉避讓已修。長離線fixture暴露舊Encode的JSON表示／checksum不一致，改對讀回表示算hash，舊Verify不變，schema3／rules core-flow-9不改；不重簽未知或損壞原檔。**27 checks、checksum修正後50/50 Runner、補充世界／摘要14 checks及相關回歸PASS，exit0；預覽與正式Web匯出exit0**。IAB4198雙鏈／原料航運／T2運力10→20與加工10→5秒、重載保留；844×390世界地標／關閉／返回已驗。4200 48h分批畫面、4201拒寫→實際恢復／原生重試→86400收益上限／壽盡，再重載只11秒、不重結算48h；4199首次checksum拒載保留。首次型別／Time架構守門／退出診斷與未通過項詳 [C2驗收](verification/res1-c2.md)。**仍待：美術／節奏、指定手機／觸控／高DPR、自然背景凍結／跨瀏覽器、Web p95／記憶體，以及新async的完整quota／索引中斷／雙分頁追加矩陣**；不因單一拒寫擴張放行。正式manifest保持未附掛，玩家namespace未操作，未commit／push／部署。下一仍 **RES1-C2驗收收尾**，不跳D；英文checkpoint置updata頂部，依AGENTS Context Guard後續大型工作用New Chat。

- **RES1-C：IN_PROGRESS；C1 階段已交付（2026-10-03）**。`res1-c-1` 三島產業契約、1–3階採集／加工／倉儲、T2工程費與運力消耗、來源原文備份與候選保存成功後替換Session、Godot「經營→三島」操作頁已完成。新檔以採集／建築／修行命令走到Era2、開拓補料→兩链加工→運回祖島→T2真實升級，**87 checks PASS／最終49/49 Runner PASS、exit0**；規則schema3／core-flow-9、B檔仍可讀但不自動轉C。IAB4197／獨立namespace：1280×720遷移啟用／兩島開拓／實際銅精載貨1及祖島到貨1，844×390重載、切頁／捲動／加工滑鼠已驗；修正固定區佔用與成本換行，viewport已reset，warn/error空。正式manifest保持未附掛，沒有操作玩家進度。新增IslandProgression／IslandManagementPanel／C Runner／preview server及相關Session、保存、導覽、輪迴、export入口，檔案／命令／首失敗／截圖見 [C1驗收](verification/res1-c1.md)。**未完成：專用三島世界地標／切島Banner／世界點擊、長離線讓出主執行緒（native约8.3–12.2秒同步CPU）、完整Web雙鏈／T2升級與保存離線矩陣、實機／高DPR／美術與節奏放行**。整體C不標DONE。英文checkpoint已置updata頂部；依AGENTS Context Guard，本階段測試驗收後停在C1，下一大型 **RES1-C2** 請用New Chat，不跳RES1-D。沒有commit／push／部署。

- **RES1-B-WEB-R1／M1-C/D：DONE（2026-10-03，核心＋桌面 Web 故障矩陣）**。localStorage權威儲存＋lifetime Web Lock，次分頁拒絕寫入、關閉持鎖分頁後重載接手；讀取被拒／兩槽損壞不變成新檔；復原槽rotation、同revision游標選擇、倒退時鐘游標與schema2原文核對已修正。Web恢復共用OfflineCoordinator，完整間隔按24h／壽元政策推進；保存失敗暫停並保留source，滑鼠重試不重送命令。新故障Runner19 checks、正式固定入口**47/47 PASS／exit0**（含RuntimeInspector）；RES1-B 251 checks及三程序保存／離線／再載入exit0；正式Web匯出exit0。IAB4196：注入故障、真實quota耗盡、兩次重載、雙分頁、48h上限／倒退時鐘、schema2備份重試，及1280×720／844×390正式提示／滑鼠重試已驗。受控requestAnimationFrame暫停36ticks保存、失敗後重試46ticks已驗；IAB單純切分頁未證明自然背景凍結，實機／高DPR／跨瀏覽器／OS凍結與長離線CPU仍待驗。並行新增Debug沙盒的不存在Amount／Lifespan／Clock API造成編譯失敗，最小相依修復後重驗，保留首失敗與負向JSON／退出診斷。修改檔案／命令／原始JSONL／限制見 [驗收](verification/res1-b-web-r1.md)。RES1-B原型核心與相交Web保存門檻在此有界範圍完成；**正式manifest仍未啟用，下一RES1-C三島T2切片**，並補正式內容量長離線效能及裝置證據。M1-C/D完整跨裝置驗收不由本輪擴張為DONE。英文checkpoint已置updata頂部；依Context Guard下個大型任務用New Chat。以下同日較早RES1-B IN_PROGRESS／44/45及下一故障矩陣保留為歷史。

- **M3-A-R2 起手補給／道心天賦：DONE（2026-10-03，使用者選定方案）**。取消自動40%／80%，資源傳承天賦每級10%、0–10阶有完整收益、只對下次轉世開局已解鎖基礎資源按新庫容發放；預覽／發放共用公式，現有庫存不回收。修正天賦分頁巢狀ScrollContainer高度0造成空白，卡片交外層捲動、參悟44高；rules core-flow-8-talent-only-inheritance／schema3。六項相關Runner最終exit0（含零庫存免費採集重建茅屋）、Godot4.7.2 Web匯出exit0。IAB4192桌面實際104→99道心／1階、844×390再購至2階、重載89道心／2階及20%預覽，console warn/error空。初輪JSON浮點／整數Array對比失敗已修正，首次日誌及既有退出診斷保留；未跑全量／實機／高DPR。來源／命令／截圖見 [驗收](verification/talent-inheritance-r1.md)。靈界庫存無條件跨世保留仍待独立政策，不冒稱天賦效果。下一步收節奏／跨世政策回饋；大型RES1-B／M1-C/D用New Chat，英文checkpoint已置updata頂部。

- **RES1-B-R1／UI 資源列：DONE（2026-10-03，本輪使用者回饋修復）**。輪迴繼承天樞陣眼造成 EAR1 下品靈石鋸齒式扣料；EAR1 暫停靈界背景生產／消耗／回饋，Era2 恢復，滿倉零扣、近滿／缺料按實際產物扣。靈晶／靈液／道心／道證／獸魂改共用卡片、三態與內部捲動；rules core-flow-7-realm-capacity-gates，schema3 保持、未啟用 RES1-B opt-in。**新 Runner 738 checks、七項相關回歸最終 exit0、Godot4.7.2 Web匯出 exit0**。IAB4192隔離桌面／844×390 點擊捲動／關閉／重載，靈石100、靈晶89.3／靈液50保持，console warn/error空。短橫向完整模式沿用小視窗逐行捲讀；實機／高DPR待驗。初輪導覽斷言仍引用已移除 Label、測試未退出，定向終止並修正重跑通過；既有退出診斷保留，未聲稱全量通過。修改檔案／命令／日誌／截圖見 [本輪驗收](verification/resource-feedback-r1.md)。**下一大型任務仍 RES1-B／M1-C/D Web保存故障矩陣，請用 New Chat**；英文 checkpoint 已置 updata 頂部。

- **DEBUG-SUITE-PHASE3（2026-10-03）：第三步 離線數值快進模擬與極限推演沙盒，DONE**。交付純邏輯隔離沙盒模組 `SimulationSandbox`，支援純記憶體複製 `GameSession` 零污染快進推演：精確計算指定秒數下的壽元消耗年數、剩餘壽元、修煉時間增量、各項資源起止與淨增量、達標滿倉溢出預警，以及子系統事件結算（丹藥/BUFF 到期、宗門派遣完成、靈獸/機緣冷卻就緒）。支援 30 天極限壓測與終態健康檢測（保證無 NaN/負數/溢出）。`DebugActions` 擴充 `sim_offline`（預設 24h）與 `sim_stress`（30天極限壓測），`DebugPanel` 新增對應 2 顆快捷操作按鈕（擴充至 28 顆按鈕）。Tier 1 單元測試 `simulation_sandbox_runner.gd`、`runtime_inspector_runner.gd` 與 `debug_actions_runner.gd` 全數 PASS、exit 0，Web 匯出 exit 0。
- **DEBUG-SUITE-PHASE2（2026-10-03）：第二步 運行時狀態檢測與一致性診斷器，DONE**。交付純邏輯唯讀診斷模組 `RuntimeInspector`，支援產銷乘區第一原理拆解（建築基礎、Era 倍率、天賦、丹藥BUFF、天時、靈獸、宗門）與 GameState 全面健康檢測（境界等級範圍、負數/NaN 異常、孤立建築/資源引用、出戰靈獸合法性、宗門派遣上限、收據計數）。`DebugActions` 擴充 `inspect_health` 與 `inspect_prod`，`DebugPanel` 新增「運行時診斷與健康自檢」區塊（擴充至 26 顆按鈕）。Tier 1 單元測試 `runtime_inspector_runner.gd` 與 `debug_actions_runner.gd` 均 PASS、exit 0，Web 匯出 exit 0。
- **DEBUG-ACTIONS-R1（2026-10-03）：第一步 DEBUG 調試功能深度補完，DONE**。新增獨立解耦的 `DebugActions` 模組，覆蓋境界跳轉（era_step 越界保護／重置 LV1）、資源階梯增加／補滿至基礎倉容／清零、時間快進（time_warp 正式推進壽元與天候）、天時解鎖與步進、強制奇遇觸發、宗門免門檻加入／刷新／即時完成派遣／貢獻加發、四大靈獸直解／成熟期／獸魂加發／冷卻清除。`debug_panel.gd` 增設 `ScrollContainer` 與 24 顆快捷操作按鈕，`abode_modal_manager.gd` 接線派發並於成功後即時存檔與刷新 HUD。`debug_actions_runner.gd` 17 項邏輯與面板訊號驗證全部 PASS、exit 0，Web 匯出 exit 0。
- **RES1-B：IN_PROGRESS（2026-10-03，核心／CLI 隔離交付）**。整數秒批次／重複／原料保留／本批後停止與切配方、祖島 resources 單一權威＋遠島庫存、六條固定航線／在途貨物／容量競爭、實際兩級吞吐；600 秒一次／分段／離線一致、壽盡及輪迴清除。schema 3／rules core-flow-6-island-economy，可讀 schema 2；唯讀預覽、保存前保留原始 schema2 JSON、工作／貨物／游標／收據同快照、拒絕未知版本及非法容量。**251 checks PASS、三個 native 獨立程序保存／載入／離線／再載入 PASS**；十項相關回歸 exit 0、Web 匯出 exit 0。全量一輪 **44/45 通過、exit 1**：最後另一批新增 DebugActions 面板 Runner 失敗；不稱全量 PASS。來源／命令／首次失敗／資料隔離／限制見 [RES1-B](verification/res1-b.md)。正式 manifest 保持未啟用，多島介面尚未交付。**下一步 RES1-B／M1-C/D Web 重載、quota／拒絕儲存、多分頁／失敗重試矩陣**；通過後再 RES1-C 三島可玩切片。英文 checkpoint 已置 updata 頂部，下一大型工作使用 New Chat。

- **RES1-A：DONE（2026-10-03，首批契約／隔離核心）**。15 資源／8 配方，銅精／丹液／中品靈石／築基丹→金丹與 v2 靈材／陣芯；宣告來源、設施／技能與消耗依賴、循環／跨 Era 死鎖拒載、GameSession Craft／原子扣料／權威庫存讀取与築基丹鏡像衝突拒絕。新 Runner **145 checks PASS**、DAO1 唯讀純規則 **8/8 PASS**、全量 **42/42 PASS、exit 0**（最終日誌見驗收）。修改檔案／命令／首次失敗／PNG 匯入診斷／Amount 邊界／未通過項詳見 [RES1-A](verification/res1-a.md)。正式 manifest 未啟用新經濟；百年靈草產線、正式 Era3／消耗、計時／地方庫存／物流／保存遷移仍待 B–D，不稱多島已可玩。**下一 RES1-B**，並補相交 M1-C/D；英文 checkpoint 已置 updata 頂部，大型接續使用 New Chat。

- **RES1-DESIGN：DONE（2026-10-03，僅設計／靜態稽核）**。使用者要求優先：Era 逐步解鎖專業空島、T1→T2→T3 加工融合、彼此供給／運輸，材料實際用於設施與修行。已交付 [docs/14](14-multi-island-resource-progression.md)、[ADR-009](decisions/ADR-009-multi-island-resource-economy.md)、[資源稽核](verification/resource-progression-audit.md)、可重跑 audit 工具／JSON，並同步產品、呈現、入口與 Roadmap。DAO1 61 有效資源／30 配方／49 建築表記錄／10 倉儲／12 Era；DAO2 manifest 7 資源／10 建築／Era 1–2，另有子系統資源。不可再把完整承接缺口只寫成 Era 9–12。audit exit 0，UTF-8／連結／JSON／hash／git diff --check 驗證；沒有遊戲程式或規則變更，未跑 Godot／Web。**下一任務 RES1-A：Era 1–3 資源／配方依賴與 Craft 核心**，再 B 加工／物流／保存、C 三島、D Era 3／T3；M1-C/D 相交保存／離線證據仍為正式放行門檻。RES1-A–E 尚未實作，請以 New Chat 接續大型開發。

- **M2-D-UI3 R1（2026-10-03）：縮小空島文字修復，IN_PROGRESS**。黑體 600／明體 800、深墨實底與最低 18／24 顯示字級；修正地標／遠景標籤切換及淡字。四項相關 Runner 最終 PASS、exit 0，Web 匯出 exit 0；IAB 隔離 4190、1280×720 縮放及 844×390 拖曳閱讀已驗，console warn/error 空。初跑沙箱保存失敗與升權隔離重跑記錄保留，既有退出診斷仍在。短橫向保留遠景可能被左 HUD 遮擋；建成銘牌／採收 Web、使用者美術、實機／高 DPR 待驗。檔案／命令／截圖見 [本輪驗收](verification/ui-world-text-r1.md)。下一步收文字回饋；大型工作用 New Chat。

- **M2-D-TEXT1 R1（2026-10-03）：Era 內等級文字已接入，IN_PROGRESS 待視覺／裝置回饋**。成功晉階後顯示實際 LV／境界／剩餘壽元，全程不透明黑底，約 3.05 秒，可跳過；提升 Era 保留原突破演出。六項相關 Runner PASS／exit 0，Web 匯出 exit 0；IAB 隔離 4188／4189，1280×720 晉階／重載 LV9、844×390 完整文字／滑鼠跳過／恢復鏡頭通過，console warn/error 空。正式內容目前僅 Era 1／2，未捏造高階資料；實體手機／高 DPR／本輪 Web Esc 待驗。檔案、命令、首次失敗與截圖見 [驗收紀錄](verification/ui-text-transition.md)。下一步收閱讀節奏回饋；大型 M1-C/D 使用 New Chat。

- **UI8-COLOR-R1 成就文字對比：DONE（2026-10-03）**。修正深青玉卡片誤用 INK：摘要／說明／已領取標題改淺色，未達成標題、獎勵與成功訊息提高對比。只改 achievement_panel.gd；成就六項案例與 Web 匯出 exit 0，IAB 1280×720 實際領取及 844×390 捲動文字已驗，console warn/error 空；玩家 origin 未觸碰。見 [驗收與截圖](verification/achievement-contrast.md)。下一大型任務仍為 M1-C/D，請用 New Chat。

- **M4-A-R1：DONE（2026-10-03，正式 Session／桌面 Web 範圍）**。宗門／跨界／BUFF 成功、拒絕、同 command_id 重送及保存後重送通過；新增 **251 checks** 整合 Runner、固定入口 **40/40 PASS、exit 0**，最後舊任務 alias 修正後四項相關回歸亦 exit 0。修正每幀重建按鈕造成實際滑鼠派遣／升級無效、宗門獎勵 ID 與坊市靈晶漏入庫、拒絕初始化狀態及跨重載去重紀錄；schema 2 新增選填 command_receipts，最近 256 筆按 revision 淘汰、保存故障重試／損壞回復有隔離測試。Godot 4.7.2 版本／import／Web 匯出通過；IAB 隔離 origin 4186，1280×720／844×390 滑鼠任務派遣→完成通知→重整恢復→通知只導航→領獎清除、BUFF TIP、宗門功法／坊市及跨界／據點／捲動通過，console warn/error 空。修改來源、測試、工具與命令日誌詳見 [完整驗收](verification/m4-a-r1.md)。初次沙箱 user:// 寫入失敗及故障注入／既有退出診斷保留，不宣稱日誌零錯誤。Web 實際儲存為 localStorage；本輪未驗 IndexedDB、quota、多分頁、實機或高 DPR。**下一大型任務 M1-C/D Web 持久化與離線故障矩陣，請使用 New Chat**。

- **本輪使用者驗收（2026-10-03）**：使用者回覆「測試 OK」，建造清單訊息保留／收起／重開修復子項 DONE。此確認不擴張為整體 NAV1／UI8、高 DPR 或實體觸控通過。當時下一步選 **M4-A-R1 正式 Session 整合驗收**（本日後續已完成，見上方新紀錄）：現有宗門／跨界／BUFF 已接線，補成功／拒絕／同 command_id 重送／保存重載及真實 Web 路徑矩陣，通知包含宗門完成與 BUFF 詳情；不重做白名單或成就。相關核心與保存模組已存在，相依可開始，完整里程碑仍 IN_PROGRESS。之後優先 M1-C/D 瀏覽器持久化／離線／失敗重試，再依 M3-B 功能矩陣核對 Era 9–12；多語另定範圍。本次只核對文件／來源／既有日誌，未執行新測試。下個大型任務請用 New Chat。

- **M2-D-NAV1／UI5 建造清單訊息修復（2026-10-03）**：FeatureNavigation 不再覆寫 buildings 的訊息可見性，桌面開清單保留訊息、收起後可從下一步重開。修改 feature_navigation.gd、導覽 Runner 與交接紀錄。導覽／響應式兩項 Runner 與 Web 匯出 exit 0；IAB 桌面實際收起／重開、兩欄不重疊，console error/warn 空。既有退出診斷與短橫向自動暫收規則保留，觸控／高 DPR 待验，整體 IN_PROGRESS。見 [驗證紀錄](verification/nav1-ui5-feedback.md)。下一步收使用者視覺回饋；大型任務使用 New Chat。

- **M2-D-UI8 R1：圖示／TIP 已交付，IN_PROGRESS 待視覺／裝置驗收**。44px 圖字、BUFF hover 詳情及點開 PopupPanel；多狀態改 +N 整顆換頁，避免半截按鈕。39/39 Runner PASS、10 張隔離 native／圖示邊界／滑鼠 TIP、Web 匯出 exit 0、IAB 桌面／短橫向及機緣圖示入口通過。檔案、命令、既有退出警告與未驗項見 [UI8 R1](verification/core-status-ui8.md)。下一步收美術回饋，補瀏覽器多 BUFF／hover、實體觸控與高 DPR；大型工作用 New Chat。

- **M3-B 成就系統（Achievements）與 DEBUG 重置：DONE，核心契約／介面／全量回歸交付**。涵蓋 6 大維度（境界、營造、丹道、宗門、靈獸、輪迴）18 項成就，成就與領取狀態為跨世永久繼承之元進度（輪迴不重置）；提供原子性領取命令 `claim_achievement` 與防重複防偽領取；修復 SaveCodec 往返快照之整數正規化；DEBUG 工具面板新增「重置全部成就進度」按鈕；原生 `AchievementPanel` 已接入「修行」第 4 頁並整合待領取通知。**修復前輪 UI8 提到的 m1a changed_ids 污染問題，全量 39/39 Runner 全部 PASS、exit 0**。

- **M2-D-UI8：IN_PROGRESS，核心資訊與共用狀態列已交付**。道印／境界／層級、細修煉條，正文统一 16 墨字；桌面修煉／壽元／天時分行，短橫向以進度條承載修煉秒數提示、壽元與天時併排。宗門完成、靈獸可餵養、機緣待決與 BUFF 共用圖示提示列及＋N 分頁（R1 更新），壽盡輪迴捷徑保留。六項相關 Runner、八張 native、Web 匯出及 IAB 1280×720／844×390 已驗。來源／命令／限制見 [UI8](verification/core-status-ui8.md)；下一步收美術回饋、補宗門／靈獸實際瀏覽器通知及觸控。

- **M2-D-NAV1／UI5 回饋修正（2026-10-03）**：四入口字級統一 18、兩項模糊「待辦」改為輪迴／機緣具體提醒及 tooltip；洞府訊息改全 viewport 水平置中，短橫向避讓 HUD。修行入口短橫向滑鼠被資源面板攔截亦已修正，主導覽尺寸／可見性集中於 FeatureNavigation。38 Runner、相容回歸、Web 匯出及 IAB 1280×720／844×390 滑鼠驗證結果見 [本輪紀錄](verification/nav1-ui5-feedback.md)。來源、測試、規格及 updata 已更新；整體 NAV1／UI5 保留 IN_PROGRESS，使用者美術／高 DPR／實體觸控待驗。下一步先收這三處回饋，大型任務使用 New Chat。

- **M2-D-ISLAND1：IN_PROGRESS，實作／CLI／桌面 Web 已交付**。同一 hut 在當世 Era >= 2 顯示築基小院；靈木／靈草／靈石三種小景、解鎖／隨機間隔／最多兩件、核心命令／即時保存／失敗重試、輪迴清除、短橫式取景与地標導覽接線。最終 **38/38 Runner PASS、exit 0**，八張 native PNG、Web 匯出與 IAB 1280×720／844×390 鼠標採收、重載／返回。使用者美術／實體觸控／高 DPR 待補；[設計](13-island-scenery-and-courtyard-spec.md)、[檔案／命令／結果／缺口](verification/island-scenery.md)。下一步先收本輪視覺／節奏回饋；大型任務使用 New Chat。
更新：2026-10-03（M2-D-FX3 原生 Shader／粒子／泛光）。區分實作、測試與完整驗收；歷史缺口不作目前接手順序。

## 目前任務與下一步

- **M2-D-FX3：IN_PROGRESS，原生特效實作交付**。飛劍流光／拖尾、靈氣小光環、渡劫雷電／法陣與粒子、Compatibility 世界 Glow、題字局部 Gaussian 泛光；設定新增無收益特效試播。36/36 Runner、14 native PNG、Web 匯出 exit 0；IAB `1280×720`／`844×390` 實際播放／低特效／返回及直式提示、browser warning/error 查詢空。最後保存提示隔離小修另由突破 Runner／Web 匯出 exit 0 補驗。使用者本次特效要求優先；美術放行／實機／高 DPR／GPU 預算待補，直式提示既有字級問題仍保留。[檔案、庫評估、命令、失敗修正與驗收](verification/native-vfx.md)。

- **ART-A1 美術現況複核：DONE；兩項美術尚未完成驗收**。聚靈壇已有候選獨立圖，正式世界目前不顯示，中央對位／建前建後及放行待做；靈界洞天只有規則與操作面板，尚無據點專屬場景。已明訂聚靈壇建成＋美術通過才呈現，以及靈界場景與人界升境分開。[來源、圖片、命令及缺口](verification/landmark-and-spirit-art-audit.md)。本輪文件更新，Godot 版本檢查及 `git diff --check` exit 0；5 份文件嚴格 UTF-8／76 個本地連結檢查 PASS；未重跑遊戲／Web／實機測試。
- **ART-A1 的後續：聚靈壇中央對位美術，再製作靈界據點場景**。兩項保持未放行；本次追加 FX3 優先。後續大型美術／場景工作使用 New Chat，優先於下面的成就候選。

- **M2-D-NAV1：IN_PROGRESS，實作與回歸交付**。四主入口／九分頁、洞天與建築經營整合、共用跨界資源、靈獸與天道決策 UI；36/36 Runner、追加相容／響應式／機緣回歸、20 native PNG、Web 匯出及 IAB 桌面／短橫向滑鼠。使用者分類／視覺回饋與實體觸控／高 DPR 待補；[規範](12-feature-navigation-and-integration-spec.md)、[檔案／命令／結果與未完成項](verification/feature-navigation.md)。
- **DOC-A-R1 文件現況複核：DONE**。
- **M3-B 靈獸系統（Spirit Beasts）：DONE**。交付四大靈獸（玉狐、玄龜、火鳳、雲蛟）、四階成長階段（卵/幼體/成長/成熟）、餵食消耗與冷卻倒數、4階獸魂天賦樹、輪迴成熟獸魂結算與跨世繼承、TimeAdvancer 模擬數值與產率整合、GameSession 三項命令（acquire/feed/talent）及 SaveCodec 存檔相容性。全量 **35/35 Runner PASS、exit 0**。
- **優先：UI7／UI6-R1／FX2／TEXT1 回饋與裝置驗收**。常態材質已實作，先收視覺回饋，再驗高 DPR、實體觸控／GPU、音訊與效能。
- **下一工作：RES1-C2 世界／效能／完整玩法矩陣**；C1三島契約與隔離操作已有首項證據，M4-A-R1與成就原交付保留，B相交桌面Web故障範圍已完成。完整M1-C/D裝置範圍及C正式放行仍待補；後續大型任務使用New Chat。

FX3 文件檢查：9 份嚴格 UTF-8、103 個本地連結及 `git diff --check` PASS；完整回歸的 50 次切換記憶體為 1461.19 KB，通過原 1500 KB 門檻。英文交接已置於 `updata.txt` 頂部。

## 9/29–10/3 開發內容

| 日期 | 交付 | 證據與限制 |
| --- | --- | --- |
| 9/29 | UI-SETTINGS-R1：玩法／設定分開、齒輪入口、BGM 開關與 Web 手勢音訊啟動；境界 BGM 排程與輪迴重置 | living_abode、modal manager、bgm_era_playlist_runner；原創主旋律 A1 草稿仍待人工試聽 |
| 9/30 | M4-A-R1 接線已補；十二時辰／五行天候；M2-D-R1 橫式核心、短橫向縮放、直式旋轉提示 | Session 白名單已有宗門／跨界／BUFF；宗門成功命令有 Session runner；全命令拒絕／冪等／Web 流程未由此推定 |
| 9/30 | M4-B 五級世界地址、九界法則與尺度契約；UI1 原生材質樣板 | m4b_scale_law_runner；尺度資料不代表五級完整世界場景 |
| 10/1 | M5-A 七維法則、心印嚮往、版本化確定性 WorldGenerator／WorldDescriptor 與快照 | m5a_world_gen_runner；三種手工法則可玩驗收、串流與升生成版本保留舊世界的實際流程待補證 |
| 10/1 | M3-B 機緣；M5-B 14 項界域決策、26 種奇遇、地貌互斥與界域加權 | fortune／fortune_ui／m5b runners；逐界完整 UI／美術／人類試玩與長期負載待驗 |
| 10/1 | UI2–UI6 核心材質、世界文字、舊紙邊、引導隱藏、訊息閱讀區與思源黑體 | 各驗收頁保留 native／Runner／匯出；UI1 方向已放行，其餘不合併宣稱全裝置 DONE |
| 10/2 | UI6-R1 黑體 400／600＋粗明體 800；FX2 分境界金環雷電；TEXT1 原生文字試播 | TextServer 字重已驗；演出／試播有 native／CLI／匯出，真實 Web／手機及視覺待驗 |
| 10/2 | UI7 紙色墨字、霧面青玉選中、朱砂突破、墨色功能面板 | [UI7](verification/ui-quiet-materials.md)：34 Runner、21 native PNG、匯出；IAB 1280×720／844×390 滑鼠及 360×640 旋轉提示，DPR 約 1；美術／高 DPR／手機待驗 |
| 10/2 | ENV-TERMINAL 修復；Git 忽略引擎／模板／快取／build，倉庫同步 GitHub | [環境](verification/terminal-initialization-2026-10-02.md)、updata；文件複核未重做 ACL 修復；後續已依使用者要求進入文件 commit／push 流程 |
| 10/3 | M2-D-NAV1：四入口與分頁、經營整合、跨界共用資源、靈獸／決策 UI | 36/36 Runner；追加回歸、20 native PNG、匯出、IAB 滑鼠；分類／視覺／實機待補 |
| 10/3 | M3-B 靈獸系統（四大靈獸、成長階段、餵養冷卻、獸魂天賦、輪迴繼承與 Session 契約） | m3b_spirit_beast_runner；35/35 Runner 全數通過 exit 0；當時獨立介面待整合，後續本日 NAV1 已接入 |

日期依開發交接；10/2 的 53b864f 集中提交多日內容，不能用提交日期代替每項開發日期。

## 精簡任務板

| 任務 | 狀態與證據邊界 | 入口 |
| --- | --- | --- |
| RES1 | DESIGN／A／B及D1子範圍DONE；C／D2／完整D IN_PROGRESS，E TODO。D2核定Era／設施＋築基靈池、正常Era3／丹霞管理／回運／修行／保存已接，215／52 Runner／UI87及桌面兩版型Web子範圍通過；專用世界美術、完整Web新檔與人工／裝置／C/R2門檻待驗 | [規格](14-multi-island-resource-progression.md)、[D2驗收](verification/res1-d2.md)、[D1驗收](verification/res1-d1.md)、[稽核](verification/resource-progression-audit.md) |
| M2-D-ISLAND1 | IN_PROGRESS；小院／三種小景／保存／取景交付，38 Runner、八張 native、桌面 Web 鼠標；美術／實機待補 | [設計](13-island-scenery-and-courtyard-spec.md)、[驗收](verification/island-scenery.md) |
| M0-A | 桌面部分已驗；指定實體手機手勢／效能待補 | [驗收](verification/m0-a.md) |
| M0-B/C | DONE；來源 fixture、Amount/RNG 支援契約 | [M0-B](verification/m0-b.md)、[M0-C](verification/m0-c.md) |
| M1-A/B | DONE；核心、時間、修行／壽元與正流程 | [正流程](verification/core-positive-flow.md) |
| M1-C/D/E | CLI 契約通過；IndexedDB、quota、多分頁、跨程序與真實舊檔 corpus 待補 | [保存](verification/m1-c.md)、[離線](verification/m1-d.md)、[相容](legacy-compatibility.md) |
| M2-A/B/C | 首升境／演出／九界鉤子已交付；新玩家試玩依原 DoD | [M2-A](verification/m2-a.md)、[M2-B](verification/m2-b.md)、[M2-C](verification/m2-c.md) |
| M2-D-NAV1 | IN_PROGRESS；入口、操作與整合交付，分類／視覺及實機待補 | [規範](12-feature-navigation-and-integration-spec.md)、[驗收](verification/feature-navigation.md) |
| M2-D／R1 | 9/28 桌面指定範圍放行；橫式實作有回歸及 UI7 桌面 Web 補證，實機／效能待補 | [M2-D](verification/m2-d.md)、[規格](07-responsive-ui-web-spec.md)、[UI7](verification/ui-quiet-materials.md) |
| M2-D-R2/R3 | IN_PROGRESS；背景／島面構圖已實作，指定視覺放行待補 | [構圖](verification/m2d-background-framing.md) |
| M2-D-A1 | IN_PROGRESS；第二稿與五版草稿待試聽；已接 BGM 不等於此作曲任務完成 | [第二稿](audio/dao2-main-theme-v2.md) |
| REF-A／UI-ICON-R1 | 已交付；保留 9/28 原測試範圍及後續日期 | [重構](verification/ref-a.md)、[圖示](verification/ui-icons.md) |
| UI1–UI7／UI6-R1 | IN_PROGRESS；多輪材質與字型已實作，UI1 方向放行；最新視覺／裝置驗收未全齊 | [核心](verification/ui-core-materials.md)、[紙底](verification/ui-paper-hud.md)、[字型](verification/ui-source-han-sans.md)、[UI7](verification/ui-quiet-materials.md) |
| UI3／UI5 | IN_PROGRESS；世界題字、引導與訊息有測試／native／匯出 | [世界文字](verification/ui-world-typography.md)、[引導](verification/ui-guidance-messages.md) |
| FX2／TEXT1 | IN_PROGRESS；雷電與文字樣板已交付，視覺／Web／實機待驗 | [升境](verification/island-breakthrough.md)、[文字](verification/ui-text-transition.md) |
| M3-A | 輪迴／天賦／雙軌門檻／壽盡橫幅與演出已交付 | [驗收](verification/m3-a.md) |
| M3-B | 丹藥／BUFF／宗門／天時／機緣／靈獸／成就已交付；多語與高階修行後續核對 | [矩陣](verification/m3-b.md) |
| M4-A／R1 | R1 DONE；251 checks、40 Runner 與桌面兩版型真實 Web；實機／M1-C/D 全儲存驗收獨立待補 | [R1 驗收](verification/m4-a-r1.md)、[M4-A](verification/m4-a.md) |
| M4-B | 規則／資料／地址契約已交付；多尺度完整場景不由數值測試推定 | [九界規格](11-nine-realms-law-and-world-generation-spec.md) |
| M5-A／M5-B | 核心／資料已交付；整體 IN_PROGRESS，完整 Roadmap DoD 未全部補證 | [九界規格](11-nine-realms-law-and-world-generation-spec.md)、[複核](verification/doc-a-r1.md) |

## 必須保留的限制

- 正式界域切換仍以人界／靈界為主；九界法則、生成描述與決策資料不代表九界完整遊玩解鎖。
- 觸控、GPU、FPS／p95、冷啟動與長期記憶體未因 CLI 通過而完成；UI7 另記既有九界卡片裁切。
- Font RID／CanvasItem／ObjectDB 退出診斷及負面資料預期錯誤仍存在，不能稱日誌零錯誤。
- ensure_* 呈現初始化、彈窗堆疊與根場景演出鎖定依實際程式理解。
- 玩家保存與 fixture／預覽 origin 分離；FX3 新增原創程式化特效資源，未改規則、保存 schema 或既有 HTTP 日誌；4197 只服務本 worktree 匯出物。

## 歷史與按需閱讀

- [DOC-A-R1 前完整記錄](archive/development-status-2026-10-02-before-doc-a-r1.md)：保留原文與日期。
- [M0–M2 歷史](archive/development-status-m0-m2.md)、[M3–M4 歷史](archive/development-status-m3-m4.md)。
- [呈現索引](abode-presentation-map.md)、[AI 交接](ai-handoff.md)、updata.txt 頂部最新英文 checkpoint。

2026-10-05 推送確認：功能提交 `12c560e` 已普通 push 至 origin/main；fetch 後 HEAD 與 origin/main 完整SHA一致，ahead／behind=0／0，工作區乾淨，pull.ff=only。來源／文件 staged diff-check（排除原始log）exit0。測試服務4265以Ctrl+C停止（程序exit1為主動終止），其餘服務未操作。此紀錄另以文件checkpoint提交，不改已驗證程式。

2026-10-10 UIX-R2-NOTIFY追加：桌面Web實際領取仙家草廬成就後修行紅點清除；隔離tab／48216服務已關閉。

## 2026-10-19 EARLY-V1-D（RES1-D 與前期放行）D-1 進行中

- 任務 ID：`EARLY-V1-D`（D-1 分段）。狀態 **IN_PROGRESS**（未 DONE）。
- 使用者核定分段：D-1=同版正式 Web 隔離空白新檔、真實桌面滑鼠、自然時間走到金丹（Era3）首升；D-2=壽元耗盡→首次輪迴→第二世（另行約 12 小時排程）。
- 修改檔案：新增 `docs/verification/early-v1-d.md`；新增工具 `docs/verification/artifacts/early-v1-d/drive_era1.mjs`（智慧目標驅動）與其他校正腳本 `calib.mjs`/`geo.mjs`/`dumpstate.mjs`/`gatherdiag.mjs`/`catalogshot.mjs`；`updata.txt` 追加本段 checkpoint。**未改動任何規則／內容／存檔 schema，未 commit/push。**
- 已完成（真實滑鼠、無注入）：隔離服務 port 4380 服務 build/web；Edge CDP 9240；視口鎖定 1280×720（Emulation override，設計座標 1:1）；空白 S00/S01；Era1 智慧驅動完成整條建築鏈（hut2/wooden_house2/forest_farm3/stone_mine3/herb_farm3/storage_lingli1，cap 560）並升 Era1 Lv10；Era1→2 突破 (252,112) 成功 → era2 lv1；開拓青木島／玄礦島（各 20 木+10 石）；啟航 3 條航線；製造頁銅精/靈材一批入庫驗證。
- 未通過／未完成項：整段連續空白→金丹跑**尚未執行**；`持續製作` 啟動方式未確認；Era2（foundation_reservoir/storage_lingli2/量產/cap 2000/突破）與 Era3（丹霞、陣芯、金丹首升）驅動未建；`runner.mjs` Era1 段需改用新邏輯、Era2/Era3 座標未校正。
- 風險（重要）：另一代理（Codex）於 2026-10-19 交付 MFG-0/MFG-1 製造 UI 重構（`src/presentation/production_controller.gd`，`manufacturing_panel.gd` 拆分 `_start/_stop`）；`build/web` 於 00:12 重新匯出。此面板正是 Era2 驅動所依賴，長跑前須確認／凍結 build 或改服務固定匯出。
- 命令：`python tools\island_preview_server.py --port 4380 --normal-build`；`msedge --remote-debugging-port=9240 --app=http://127.0.0.1:4380/index.html`；`node --experimental-websocket docs\verification\artifacts\early-v1-d\drive_era1.mjs`（env CDP_PORT/HTTP_PORT/VIEW_*/DIR/MAX_MS）。
- 下一任務：開啟新對話，先確認 build 凍結，再完成 Era2/Era3 驅動與單一連續自然跑到金丹首升，並補離線與保存故障恢復；之後才排 D-2。
- 證據：`docs/verification/early-v1-d.md`、`docs/verification/artifacts/early-v1-d/`。
