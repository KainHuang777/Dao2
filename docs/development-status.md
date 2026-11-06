# 開發狀態與交接紀錄

<a id="ui-sect-gate-portrait-r1"></a>
## 2026-11-06 UI-SECT-GATE-PORTRAIT-R1（五宗首頁直式圖：實作／L1及原生檢查完成；L2 Chrome與美術接受待驗）

- **範圍／規劃**：使用者指出新版宗門首頁已採直式圖片欄，原橫圖不合版面。本次承接SECT-REFORM及UI-JOURNEY-LAYOUT-B-R1，依[圖片適配計畫](sect-life/gate-portrait-r1.md)完成五宗直圖及正式Godot接線；整項保持 **IN_PROGRESS**，未將工具受阻的Chrome驗收或使用者美術接受寫為DONE。
- **圖片／來源**：內建image_gen以原五宗山門圖為各自編輯輸入，五次獨立生成1024×1536（2:3）直圖，原檔逐位元組複製至 `assets/ui/sect-life/{taixu,tianjian,piaomiao,wanfo,zixiao}-gate-portrait.png`。保持書卷／劍／藥圃／蓮池／觀星雷法各宗識別，完整山門與縱向景深；原橫圖保留供低高度使用。提示詞、來源、雜湊與單層靜態用途存於 `docs/sect-life/gate-portrait-r1/`，未新增第三方參考或主張第三方商用授權。五張已目視檢查；正式美術接受待使用者回饋。
- **修改檔案**：`src/presentation/sect_life_folio.gd`依實際內容高度≥300載入直圖，低於300用原橫圖；新增resized→adapt，容器完成排版後自動切圖，路徑相同不重載。沿原完整等比contain、忽略圖片輸入。`tests/sect_life_ui_runner.gd`增加五宗資源／2:3／可用高度75%以上／短版切換與還原／可選原生截圖檢查。新增規劃、資產與manifest，更新docs19共同規範與交接。正文、比較、固定拜入、同門立繪及正式規則／存檔沒有新增行為。
- **環境與L1／L2領域CLI**：Godot `--version`為`4.7.2.stable.official.ed1daf0bf`，`--headless --path . --import` exit0。先執行 `tools/run_all_runners.ps1 -Only 'sect_life_ui_runner.gd,sect_tournament_ui_runner.gd,uix_r9_sect_ui_runner.gd' -List`確認3支，再以相同selector執行；最終 **3/3 PASS，matrix=single，exit0**（tournament約5.3s、life11.2s、uix17.3s），工具log識別 `dao2_runners_e9f1e414290446999ff35d1768e139da`。這是受影響領域驗證，非全量回歸；UI完整L2仍欠Chrome抽驗。
- **原生圖像**：`DAO_GATE_CAPTURE=1`搭配 `Godot --path . --script res://tests/sect_life_ui_runner.gd` → **155 checks／PASS／exit0**。1280×720同視窗中驗證內容高度調整，不是全尺寸矩陣。五宗PNG及日誌在 `.test-output/gate-portrait/`，五張畫面均已目視確認完整山門、圖文雙欄及比較／拜入按鈕可見。CLI可證明命令訊號，不能代稱Chrome真實滑鼠通過。
- **失敗與修正**：第一輪把載圖提取方法時漏保留 `_gate_page`後文仍使用的`id`，造成Parse Error／首runner逾時，當輪不算成功；已補回。當時原生執行已停止，初次Web匯出雖exit0但含壞腳本，不作交付證據。第二輪縮放檢查失敗，確認父層set_layout_bounds早於容器實際尺寸套用；新增folio.resized接線後最終三支與原生155通過。保留失敗日誌，未延長逾時、未隱藏SCRIPT ERROR。最終匯出無SCRIPT ERROR／Parse Error，既有user://不可開啟診斷保留，不稱日誌零錯誤。
- **本機Web更新**：最終 `Godot --headless --path . --export-release Web build/web/index.html` exit0；`node tools/prepare_web_compression.mjs build/web` exit0。日誌為 `.test-output/gate-portrait/export-final.log`及`compression.log`；最終PCK SHA256 `edf83aada55673b030da8f3dff5704d7c39ed8b5ccecd5cf3acef79784b83571`。更新本機一般測試Web，非候選包、不觸發L3。
- **Chrome受阻／未通過項**：computer-use技能的sky工具可啟動Chrome，但取得新分頁視窗時回覆「could not determine the current browser URL on Windows with enough confidence to enforce policy」，本輪Computer Use即停止；未繞過限制或改用Edge，未做瀏覽器輸入／截圖驗收。因此Chrome1280×720五宗切換／比較捲動／拜入入口抽驗 **待驗**，可於重載新build後依規劃文件步驟人工檢查。不影響已完成的CLI與原生證據。
- **交付稽核／下一步**：`python tools/delivery_check.py --web build/web` **PASS**（Web7/7；受保護路徑1筆為開始前既有`docs/verification/artifacts/sect-life-close/`，本輪未修改；沒有新寫入該路徑），`git diff --check` exit0，保留既有LF/CRLF提示。manifest保持`PENDING_USER_VISUAL_REVIEW`，不虛報ACCEPTED；本輪未執行`--manifest`的已接受閘。下一步先收五宗新版圖片回饋與補Chrome抽驗，不展開下一大型任務。英文checkpoint置頂updata並保留5筆；可手動commit（本圖片適配實作階段結束，非大型任務結束），代理未commit／push。後續大型工作請開New Chat。

<a id="sect-life-close-l3"></a>
## 2026-11-06 SECT-LIFE-CLOSE-L3（宗門改版全量 L3 181/181 PASS；Chrome 1280/844 Web 已驗，800 Web viewport 待驗）

- 使用者核定：宗門改版完成後進入完整 L3；本輪完成 SECT-LIFE 正式範圍收尾。
- 全量 L3：`tools\run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 3600` → **181/181 PASS（matrix=full）**；日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_8d08c6abb59341329a8a2ba0310347de`。無 timeout、無 SCRIPT ERROR。
- 修正 11 支 L3 失敗：`m2b_breakthrough`（改用已遷移、可存檔的 session）、`life_report_ui`/`resource_accounts_ui`（fixture 補 `SectLife.reset_life`）、`uix_r9_sect_ui`（新五宗 folio 流程、`SectLife.view` 空 life guard、`_fit_card_grid` 面板寬度運算打破 scroll 溢出）、`imm3c_page_consistency`（sect full-folio 改用 rail resource drawer）、`early_flow1b`/`early_flow1d`（目標導覽同步選取建物詳情）、`life_report_ui`/`life_echo_ui`（compact 書籤列移入 scroll、panel margin/resize 同步、report 標題自動捲入）、`maid_guidance_dock`（entry 避開 toolbar、tab 以 intersects 判定）、`early16_ui_shell`（dismiss 後 dock VBox 不再攔截 hover）。
- 主要修改：`src/simulation/sect_life.gd`、`src/presentation/feature_navigation.gd`、`src/presentation/abode_hud_controller.gd`、`src/presentation/reincarnation_panel.gd`、`src/presentation/management_workbench.gd`、`src/presentation/maid_guidance_dock.gd`、`src/presentation/ui_shell_controller.gd`、`src/presentation/sect_panel.gd`；測試 `tests/m2b_breakthrough_runner.gd`、`tests/life_report_ui_runner.gd`、`tests/resource_accounts_ui_runner.gd`、`tests/uix_r9_sect_ui_runner.gd`、`tests/imm3c_page_consistency_runner.gd`、`tests/maid_guidance_dock_runner.gd`、`tests/early16_ui_shell_runner.gd`。
- Web/交付檢查：Godot `--headless --path . --export-release Web .\build\web\index.html` → WEB_EXPORT_OK；`node tools\prepare_web_compression.mjs build\web` → quality 9（index.js br 64,438 B；index.wasm br 7,996,785 B；index.pck br 192,116,232 B）；`python tools\delivery_check.py --web build\web` → **PASS**（Web 7/7 檔案符合 compression.json、protected evidence 0 變更）；`PYTHONPATH=build\tool-deps python tools\subset_game_fonts.py --check` → `ok:true`；`git diff --check` → OK（僅 LF→CRLF 提示）。
- 桌面 Chrome（2026-11-06 指定 Chrome，不用 Edge）：1280x720 與 844x390 載入真實 Godot Web build 並截圖至 `docs/verification/artifacts/sect-life-close/web-1280x720.png`、`web-844x390.png`；皆可見浮島場景、離線收益摘要與底部導覽。**800x360 Web viewport 待驗**：headless Chrome 只截到「正在結算離線產業…」載入畫面，重試出現 `net::ERR_CONNECTION_REFUSED`（本機 static server 連線問題），未取得最終畫面；Godot 全尺寸矩陣的 800x360 已由 L3 通過，實機/桌面 Chrome 800 以 `tools\start_web_server.ps1` 或 `python tools\web_static_server.py --port 4175 --directory build\web` 手動補驗（勿用 Edge）。
- 狀態：SECT-LIFE 正式範圍與 CLOSE L3 完成；代理未 commit，請使用者手動 commit。下一步：手動補 Chrome 800x360 Web 截圖/檢查；觸控與實機驗收依 2026-10-17 指令延期，非當前阻擋。

<a id="ui-journey-layout-b-r1"></a>
<a id="ui-sect-layout-b-r1"></a>
## 2026-11-06 UI-JOURNEY-LAYOUT-B-R1 / UI-SECT-LAYOUT-B-R1（遊歷四頁全蓋板＋主／子分頁全靠左＋右側100%全高內容，實作與L1 DONE，L2桌面Chrome待驗）

- **使用者核定方案**：繼宗門（`sect`）完成「**方案 B：全蓋板 ＋ 主／子分頁全靠左（右側 100% 由頂到底全給內容）**」後，使用者指出點擊左欄其他分頁會回到舊版介面，要求一併整改成方案 B，並透過三項選單確認：
  1. **適用範圍**：套用至**遊歷（`journey`）四個功能頁**（`sect` 宗門、`fortune` 機緣、`decisions` 天道決策、`characters` 人物；`realms` 九界保留世界地圖預覽）。
  2. **子分頁與選擇器整合**：各頁的子分頁／選擇器全數垂直整合至左欄——人物頁左欄直排角色選擇（`青蘅／糯美子／丹霞` secondary `GameTab`）與四段小傳書籤（`人物／初遇／職掌／羈絆` `ArrowBookmarkTab`）；機緣頁左欄直排題頭統計與「`當前機緣／抉擇簿`」secondary `GameTab`；天道決策頁左欄呈現題頭與界域決策說明。
  3. **資源呈現**：左欄底端統一收納 `ShellEntries`（「資源／訊息」按鈕，點擊開啟資源抽屜），不放常駐寬庫存欄，右側 100% 留給各頁主要內容。
- **交付內容**：
  1. **全蓋板模式擴展至遊歷四頁**：`ui_shell_policy.gd` 定義 `JOURNEY_FOLIOS = ["characters", "sect", "fortune", "decisions"]`，在四頁統一回傳 `hud = "hidden"`、`resource_presentation = "summary"`（開資源抽屜時為 `"drawer"`）；`ui_shell_controller.gd` 於 `full_folio` 隱藏左上 `compact_hud`、左下四主入口 `abode.toolbar` 與右上 `abode.settings_menu`，工作台紙面擴展至全畫面（`1280×720` 下為 `Rect2(16, 16, 1248, 688)`），並將工具抽屜遮罩高度擴展至全畫面（`vp.y - 16`）。
  2. **四頁共用左欄主導覽、右上 `CloseSeal` 與左下資源入口重掛載**：`management_workbench.gd` 在遊歷四頁統一將 `feature_navigation.bar`（宗門／機緣／天道決策／人物）移入當前頁左欄頂部 `left_nav_host` 並切換直排（`set_vertical_tabs(true)`），將 `CloseSeal`（`×`）移入右上角 `close_host`（44×44，不佔頂部橫列，`top_bar_h = 0`）；`ui_shell_controller.gd` 統一將 `ShellEntries`（資源／訊息）移入當前頁左欄底端 `left_entry_host` 直排。在遊歷四頁之間切換時無縫交接左欄導覽與資源入口；切往經營／修行分頁或返回洞府時完整還原原父節點與橫向分頁。
  3. **各頁左欄子分頁整合與右側 100% 全高內容**：
     - **宗門（`sect_panel.gd`、`sect_life_folio.gd`）**：左欄直排宗門題頭／貢獻、山門五宗分頁或入宗後五項功能子分頁（歷練／秘術／坊市／同門／大比）；右側 100% 全高工作區（山門與同門閱讀欄高度 `>= 560px`）。
     - **人物（`maid_character_panel.gd`）**：`section_body` 改為左欄 `section_scroll`（`left_nav_host`、題頭、`maid_row` 角色直排 secondary `GameTab`、`section_tabs` 四段直排 `ArrowBookmarkTab`、`left_entry_host`）＋ `VSeparator` ＋ 右側 100% 全高 `content`（立繪畫框、直式名籤與書籤小傳）；右上角由獨立 `_overlay_layer` 承載 44×44 `close_host`。
     - **機緣（`fortune_modal.gd`）**：建立 `_main_split`（左欄 `_left_scroll` 承載 `left_nav_host`、機緣題頭／計數、直排 secondary `GameTab`「當前機緣／抉擇簿」與 `left_entry_host`）＋ `VSeparator` ＋ 右側 100% 全高 `_content`（奇遇插畫、敘事內捲、選項與底部時限條，或抉擇簿統計／篩選與歷史清單）。
     - **天道決策（`system_actions_panel.gd`、`realm_decision_view.gd`）**：當 `embedded == true`（`decisions` 路由）時啟用左欄 `_left_scroll`（`left_nav_host`、「天道決策」題頭／副標、`left_entry_host`）＋ `_split_sep` ＋ 右側 100% 全高 `box`（雙欄門檻調整為 `960px`，1280×720 下右側寬約 `1027px` 可雙欄舒展）；非嵌入之 `skills`／`beasts` 維持原版面。
- **修改檔案**：`src/presentation/ui_shell_policy.gd`、`src/presentation/feature_navigation.gd`、`src/presentation/management_workbench.gd`、`src/presentation/ui_shell_controller.gd`、`src/presentation/maid_stand_display.gd`、`src/presentation/sect_panel.gd`、`src/presentation/sect_life_folio.gd`、`src/presentation/maid_character_panel.gd`、`src/presentation/fortune_modal.gd`、`src/presentation/system_actions_panel.gd`、`src/presentation/realm_decision_view.gd`；測試 `tests/ui_shell_policy_runner.gd`、`tests/ui_shell_matrix_runner.gd`、`tests/sect_life_ui_runner.gd`、`tests/maid_ui_runner.gd`、`tests/maid_ui2_runner.gd`、`tests/maid_first_meeting_runner.gd`、`tests/decision_ui_runner.gd`；文件 `docs/19-ui-ux-guidelines.md`、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改遊戲規則、存檔 schema 或美術資產。
- **L1 命令與結果**：Godot `--version`=4.7.2.stable.official.ed1daf0bf；依分級驗收精選受影響之遊歷四頁與 UI Shell runner（`matrix=single` 單一尺寸 `1280×720`）：
  1. 宗門與導覽群組（前階段已驗且相容）：`sect_tournament_ui_runner.gd,sect_life_ui_runner.gd,ui_shell_policy_runner.gd,m3b_sect_ui_runner.gd`（logs `c370fffb7fce41969d4b4baac52563f5`）及 `sect_reform_ui_runner.gd,content_p2_sect_ui_runner.gd,content_p1_sect_ui_runner.gd,feature_navigation_runner.gd`（logs `fb8dc7b6212f42b2b5d55abe2cce1663`）→ **8/8 PASS**。
  2. 人物、機緣與決策專項：`tools\run_all_runners.ps1 -Only 'maid_ui_runner.gd,maid_ui2_runner.gd,maid_first_meeting_runner.gd,uix_r10_fortune_ui_runner.gd,uix_r11_decisions_ui_runner.gd' -Parallel 3` → **5/5 PASS**（logs `bdb5bbf97763419182de019c345ded4e`）。
  3. Shell、機緣與導覽整合：`tools\run_all_runners.ps1 -Only 'early16_ui_shell_runner.gd,decision_ui_runner.gd,ui_shell_policy_runner.gd,m3b_fortune_ui_runner.gd,feature_navigation_runner.gd' -Parallel 3`（初次 `decision_ui_runner.gd` 因轉世測試 fixture 未同步重置 `SectLife` 報 `SECT_LIFE_SEQUENCE`，其餘 4 支 PASS，logs `c843345a2a874db9a7a914ee9ca3ce98`；補 `SectLife.reset_life(state)` 後重跑 `-Only 'decision_ui_runner.gd,sect_life_ui_runner.gd'` → **2/2 PASS**，logs `d2975daa128c4affb60eafcf0774aa63`）。
  4. 全路由矩陣：`tools\run_all_runners.ps1 -Only 'ui_shell_matrix_runner.gd' -TimeoutSeconds 90` → **1/1 PASS**（60.4s，42 個 route×mode 組合全數通過，驗證遊歷四頁 `hud == "hidden"`、全畫幅紙面、左欄直排與跨路由還原，logs `801b5e7e85594f628ae820f96dd28728`）。
  5. `python tools\subset_game_fonts.py --check` → **PASS**（`"ok": true`）。
  合計 17 支受影響 L1 runner 全數 PASS。未跑 L3，不稱全量或全尺寸回歸。
- **中間失敗與修正紀錄**：
  1. `MaidCharacterPanel` 繼承自 `PanelContainer`，直接子節點的 `position`／`size` 會被容器覆寫；改以中間層 `_overlay_layer := Control.new()`（`MOUSE_FILTER_IGNORE`）承載右上角 44×44 `close_host`。
  2. `tests/decision_ui_runner.gd` 測試 fixture 手動設定 `state.reincarnation_count = 1` 並呼叫 `SectLineage.next_life(state)` 時未呼叫 `SectLife.reset_life(state)`，導致 `sect.life.life_seq = 0` 與轉世次數不符而在保存時觸發 `SECT_LIFE_SEQUENCE`；補上 `SectLife.reset_life(state)` 後重跑通過。
- **Web 更新與交付檢查**：`Godot --headless --path . --export-release Web build/web/index.html` exit 0、`node tools/prepare_web_compression.mjs build/web` exit 0，已同步更新本機 `build/web`（非候選包交付，不升 L3）。`python tools/delivery_check.py --web build/web` PASS（Web 7/7、受保護證據變更 0），`git diff --check` exit 0。
- **下一步／Context Guard**：遊歷四頁方案 B 實作、L1 與本機 `build/web` 更新已完成；桌面 Google Chrome（`1280×720`）L2 滑鼠視覺抽驗待驗（使用者可直接重新整理本機網頁，在宗門／機緣／天道決策／人物四頁間切換檢視）。可手動 commit（本遊歷四頁全蓋板與左欄整合階段結束，非大型里程碑結案）；代理未 commit／push。建議開啟 New Chat 進行後續任務。

<a id="ui-building-nav-r1"></a>
## 2026-11-06 UI-BUILDING-NAV-R1（建築捷徑直達清單／明確返回，實作與L1 DONE，L2 Web滑鼠待驗）

- **使用者指定驗收瀏覽器**：2026-11-06要求今後一律使用Google Chrome，不再用Edge；已同步AGENTS.md與ai-handoff，下一次本任務L2改用Chrome。此次僅更新指引與交接，未重跑遊戲／匯出／瀏覽器驗收，既有Edge中止記錄與待驗狀態保持。

- **使用者要求／實作**：截圖單棟茅屋內頁「收起」無法點擊，且希望各「前往」直接到建築清單。本次將按鈕改「返回建築清單」，回呼改走既有清單導覽，完整清除selected_id／詳情槽並重建清單呈現；引導主目標與選修技能的建築捷徑改用集中`open_buildings(id)`。島嶼流程的建築目標只切全部分類並捲到卡片，不自動展開卡片。玩家手動查看詳情仍保留，升級／建造與共用卷首關閉不變；不改規則、保存、收益或玩家資料。
- **修改檔案**：`src/abode/living_abode.gd`、`src/presentation/abode_hud_controller.gd`、`src/presentation/feature_navigation.gd`、`tests/early16_ui_shell_runner.gd`；`docs/19-ui-ux-guidelines.md`同步共用建築導覽通則，README／ROADMAP／updata交接更新。先前未提交成果保留。
- **診斷界線**：目前來源在隔離原生輸入事件中可命中舊收起並返回，未可靠重現使用者Web包的失效原因，不宣稱找到遮罩或訊號根因。採明確返回清單與統一捷徑路由修訂，避免非必要內頁；新版按鈕以Viewport真實mouse motion／press／release派送驗證，非直接emit pressed。原生事件證據不等於真實瀏覽器互動。
- **L1**：Godot `--version`=4.7.2.stable.official.ed1daf0bf；先`tools/run_all_runners.ps1 -Only 'early16_ui_shell_runner.gd,feature_navigation_runner.gd,uix_r4_building_cards_runner.gd' -List`確認3支，再同selectors `-Parallel 3`。navigation／building_cards PASS（logs `bbe2f3d1602c422dacf434c4cb4c0329`）；最終shell補驗`-Only 'early16_ui_shell_runner.gd'` PASS、exit0、matrix=single（logs `f07e1a80dbf845d3a93519949b036fa3`，輸出`.test-output/building-nav/final-runner.log`）。合計3支分批通過；新增返回按鈕實際hover命中／點擊回清單、目標捷徑不開詳情、全部分類與導航唯讀檢查。沒有全量或全尺寸宣稱。
- **中間失敗保留**：初次把新增詳情操作插在既有工作台初始布局斷言前，`identity content stays grouped`失敗；將原有布局檢查保留原進入頁面時點，互動回歸放在其後，最終通過，不推定一般HUD問題已獨立修復。測試編輯另有縮排及Variant型別推斷Parse Error，已修正並補驗；中間失敗不計PASS，未放寬45秒逾時。既有user://日誌開啟／退出資源診斷保留。
- **Web更新**：`Godot --headless --path . --export-release Web build/web/index.html` exit0，`node tools/prepare_web_compression.mjs build/web` exit0；logs `.test-output/building-nav/export.log`／`compression.log`。這是本機一般Web更新，非候選包交付、不升L3；包含本輪與先前VISIT-ROUND來源。使用現有本機服務的玩家需重新載入新版檔案，未操作玩家保存或既有服務。
- **L2待驗／工具限制**：使用[computer-use技能](C:/Users/asus/.codex/plugins/cache/openai-bundled/computer-use/26.1029.61003/skills/computer-use/SKILL.md)列視窗成功，但取得Edge視窗時，工具回報無法可靠判定目前瀏覽器URL以執行政策，要求停止；已停止瀏覽器操作，未換工具繞過，無新版Web截圖或滑鼠通過聲稱。仍需在1280×720桌面開新包：引導前往→完整清單；手動詳情→返回建築清單；清單升級動作保持；技能與島嶼建築捷徑不進單棟頁。
- **交付／下一步**：`python tools/delivery_check.py --web build/web` PASS（Web7/7、受保護證據變更0）；`git diff --check` exit0，既有LF／CRLF提示保留。整體UI修訂的L2待驗，實作／L1子階段完成；未跑L3／FPS。英文checkpoint置頂保留5筆。可手動commit（本UI實作階段結束，非大型任務結束），代理未commit／push；下一New Chat補本UI-BUILDING-NAV-R1的L2，或使用者先試新版回饋，不在此上下文啟動大型下一任務。


<a id="sect-life-visit-round"></a>
## 2026-11-06 SECT-LIFE-VISIT-ROUND（每輪三位各一次／整輪完成後冷卻，L1／L2階段DONE）

- **任務／結果**：修正逾期主章可連讀六件與日常可能連續同人。保留單一凍結待決槽，前三章／後三章分兩輪；日常從本輪未回答人物無放回抽樣，每輪三位各一次。第三件回答或婉拒後，從當下宗齡開始180個accepted seconds冷卻；180秒是本次實作預設，並非使用者指定秒數。輪內原到齡／入門資格保持，未處理槽不覆寫；長離線不回答、不補輪、不累積補領債務；零tick／暫停不推進，死亡唯讀，輪迴清本世輪次。收益預留12／600秒與單件凍結獎勵保持。
- **修改檔案**：`src/simulation/sect_life.gd`、`sect_tournament.gd`；`src/persistence/sect_life_save.gd`、`sect_save_contract.gd`、`save_codec.gd`、`sect_reform_release.gd`；`tests/sect_life_core_runner.gd`、`sect_life_save_runner.gd`、`sect_life_content_runner.gd`、`sect_tournament_runner.gd`；`docs/51-sect-life-design.md`及本交接、README／ROADMAP、updata。未修改UI、美術、經濟公式或SaveManager交易流程；既有未提交成果保留。
- **版本／遷移**：sect7／life4／schema10／rules `core-flow-30-sect-life-visit-round-1`，新增版本化`visit_round.mask`與內容tag。schema6～9仍依各自原rules可讀寫；startup藉既有來源SHA歸檔、凍結候選、精確讀回與重試升版。舊主章按已讀章數恢復本輪；第三／六章已讀且無待決者從升版宗齡開始新180秒等待；已有後續主章／日常待決完整保留，日常作新輪首件。instance、選項／獎勵、章節／分支、好感、宗齡、兩條RNG、預留、大比與經濟不重抽／重發。升版不推進時間或消耗RNG，life8192／sect32768上限不變；合法近上限來源仍沿既有不可升版保留舊版路徑。
- **L1命令／結果**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。先`tools/run_all_runners.ps1 -Only 'sect_life_core_runner.gd,sect_life_save_runner.gd,sect_life_content_runner.gd,sect_tournament_runner.gd' -List`確認4支；同選取`-Parallel 3`補驗中content／save／tournament均PASS（logs `1092db0bb0fa45c689088a9b15be6c0b`）。最後core新增案例校正後`-Only 'sect_life_core_runner.gd' -List`及同範圍執行PASS、exit0（logs `f34a8843e039441380f5cd18072bdf34`）。最終四支受影響範圍均通過，matrix=single，沒有全量宣稱。
- **新增驗證**：五宗跨兩輪主章與兩輪日常，各輪三人唯一；待決延遲閱讀不換件；第三件含婉拒開始冷卻；179秒不開／180秒僅開單槽；TimeAdvancer整段／分段／OfflineClosedForm跨冷卻邊界一致；長時間不累積輪次、零tick、死亡拒答、輪迴清除。schema9每個已讀章數0～6、有／無待決的14種升版，檢查來源歸檔拒寫、候選損壞讀回、原權威不變、相同候選重試、精確重載與startup冪等；第三件拒寫不開始冷卻、重試只開始一次、command replay不延後冷卻。既有所有宗門內容／分支、舊schema7／8與大比、容量、凍結獎勵及損壞世代復原沿原測試通過。
- **L2依賴命令／結果**：因共用SaveCodec與宗門版本識別變更，額外精選`sect_life_entry_runner.gd,sect_life_ui_runner.gd,sect_tournament_ui_runner.gd,sect_reform_release_runner.gd,sect_reform_save_runner.gd`，先`-List`列5支，再同範圍`-Parallel 3` → **5/5 PASS、exit0、matrix=single**，logs `0a0899ab43b74347888da25862975e08`。合計9支受影響runner分批通過；本輪無UI改動，因此未要求UI的桌面Web抽驗，未匯出測試或候選包。
- **失敗與修正**：首輪新增版本Array membership不接受JSON讀回float，造成`SECT_LIFE_FIELDS`／候選未發布，已改顯式數值比較；該輪及串行失敗不算通過。新增測試曾直接把SectLife.advance一次大步與逐秒比較，待決tick本來取各呼叫當下，非TimeAdvancer的逐秒契約，已改用正式TimeAdvancer／OfflineClosedForm比較冷卻邊界，補驗core通過。沒有放寬45秒逾時或隱藏SCRIPT ERROR。既有user:// log開啟診斷保留，不稱零錯誤日誌。
- **交付檢查／限制**：`python tools/delivery_check.py` PASS，受保護證據變更0；`git diff --check` exit0（保留既有字型import與UI檔案LF／CRLF提示）。未跑L3／全尺寸／FPS，未改`build/web`與隔離Web包，因此既有Web包仍是舊訪帖規則，不能當新版證據。本階段是規則與保存交付，不宣稱自然桌面玩法節奏或整體SECT-LIFE結案。
- **下一步／Context Guard**：新對話續`SECT-LIFE-PACING`自然節奏／大比等待與收益體感；若要實際玩新版，先局部匯出含本次來源的隔離測試包，再桌面抽驗，整批CLOSE才跑一次L3。英文checkpoint置updata頂端並保留5筆。可手動commit（VISIT-ROUND階段結束，非大型任務結束）；代理未commit／push。下一大型階段請開New Chat。

<a id="sect-life-gate-text-r1"></a>
## 2026-11-06 SECT-LIFE-GATE-TEXT-R1（山門頁比照敘事文字層級，L1／L2階段DONE）

- **範圍／呈現**：依使用者截圖將拜入山門頁比照同門格式：宗名28px朱紅明體、定位20px墨青文楷、特色／功法／規矩／同門／守護獸22px朱紅明體題簽，正文18px黑體／6px行距，功法名18px青玉強調，研習門檻獨立16px。五宗比較以20px青玉宗名＋18px特色分段；五宗選擇沿secondary GameTab。底部比較／拜入沿共用44px紙面框按鈕、手形游標與焦點；山門也啟用真實scroll range提示。原圖等比、既有特色文案／功法／門檻／許可及拜入命令保持，不創造新效果或獎勵。
- **修改檔案**：`src/presentation/sect_life_folio.gd`抽出本Folio內共用_heading／_prose／_paper_action，山門與既有同門沿相同角色與操作；`tests/sect_life_ui_runner.gd`補宗名／定位角色及山門提示可見檢查；`docs/19-ui-ux-guidelines.md`同步山門通則，README／ROADMAP／本交接與updata更新。未改規則、保存、字型或美術資產；先前未提交工作保留，代理未commit／push。
- **L1**：本機Godot `--version`=4.7.2.stable.official.ed1daf0bf。先`tools/run_all_runners.ps1 -Only 'sect_life_ui_runner.gd,m3b_sect_ui_runner.gd,sect_tournament_ui_runner.gd' -List`確認3支，再同範圍`-Parallel 3` → **3/3 PASS、matrix=single、exit0**，logs `3d3046b6b20f426aad05e2e9bee400fa`。保留五宗精確美術／拜入目標訊號／原三頁／同門固定選項／收益與保存鎖定；沒有全量或全尺寸宣稱。`python tools/subset_game_fonts.py --check` PASS，本輪不需重建字型。
- **Web命令**：隔離`SectReformUiReview`匯出與`node tools/prepare_web_compression.mjs build/sect-reform-ui-review`均exit0，log在`.test-output/gate-text-browser/export.log`／`compression.log`。PCK SHA256 `a4e02a40802b5e557f0a0c50f67ee7a98b24abd0077543ce783d33c3d682a94e`。一般build/web未同步，只更新本機測試包，不是候選交付，不觸發L3。
- **L2桌面抽驗**：新隔離origin48585、`review.html?life=gate`，合成未入宗築基資料，沒有操作原進度。Edge外框暫設1600×820以操作shell，DOM iframeCSS1280×720／DPR約1，完成reset。真實滑鼠太虛→天劍→太虛，山門圖／宗名／定位／特色與拜入按鈕對象同步；天劍內捲到末尾提示更新，同門／守護獸／許可規則可讀，功法B名與金丹門檻分層；五宗比較展開／收起正常。未點立誓拜入，revision12、tokens0、pendingfalse保持，無收益命令。截圖`taixu-top.png`／`tianjian-bottom.png`／`methods.png`／`comparison.png`／`final.png`與`state.json`在`.test-output/gate-text-browser/`。只抽驗桌面，不宣稱自然玩法或最終視覺接受。
- **限制與收尾**：browser保留BGM01下載失敗／可重試警告（UTC16:09:25，即台北2026-11-06 00:09:25），不稱console空；既有user://／退出診斷不抹除。測試分頁已關閉、服務Ctrl+C停止（exit1為主動停止），其他頁未操作。`python tools/delivery_check.py --web build/sect-reform-ui-review` PASS（Web7/7、受保護證據變更0），`git diff --check` exit0。無L3／FPS／實機宣稱，觸控實機延期非當前阻擋。
- **下一步**：收山門頁格式視覺回饋；之後續核對SECT-LIFE自然節奏／剩餘範圍，再整批CLOSE一次L3。英文checkpoint置updata頂端並保留5筆。可手動commit（山門頁格式修訂階段結束，非大型任務結案）；代理未commit／push。下一大型階段請開New Chat。

<a id="sect-life-ui-text-r2"></a>
## 2026-11-05 SECT-LIFE-UI-TEXT-R2（姓名符號／閱讀提示／回應與收穫，L1／L2階段DONE）

- **2026-11-06使用者確認**：使用者表示本修訂階段結束，R2視覺回饋收束；僅接受本次介面修訂，不擴張為自然玩法節奏或整體SECT-LIFE結案。下一建議子段為`SECT-LIFE-PACING`：以自然時鐘的桌面隔離流程核對入宗引導、同門相會頻率及首屆大比三段／領獎的等待與收益體感；本輪僅核對下一步，未啟動新實作或驗收。
- **使用者回饋與交付**：直列姓名撤下方向錯誤的橫向【】，改上下圓點收尾，短高度橫排名仍用【姓名】。正文保留18px及單一內捲，閱讀區下緣固定24px提示行，尚有內容時顯示「下方尚有內文，請向下捲動 ↓」，到底顯示「已讀至內文末尾」，無溢出時空白；依實際scroll range更新，不改閱讀／遊戲狀態。A／B／略過三項各為一組固定回應卡：44px共用紙面框按鈕、手形游標及原生hover／焦點，下面獨立16px青玉強調「收穫」，移除原本正文尾端重複獎勵段落；文字與收益一一對應，禁用／tooltip／正式instance command保持。本修訂視覺已於2026-11-06由使用者確認階段結束，整體SECT-LIFE不結案。
- **修改檔案**：`src/presentation/sect_life_folio.gd`、`tests/sect_life_ui_runner.gd`、`docs/19-ui-ux-guidelines.md`與交接；既有字型工具補runtime缺少的U+2193箭頭，兩runtime TTF與manifest更新，原始TTF未改。既有未提交工作保留，未改規則／存檔／經濟／美術資產／共用操作元件。
- **L1命令與結果**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。先`tools/run_all_runners.ps1 -Only 'sect_life_ui_runner.gd,sect_tournament_ui_runner.gd,m3b_sect_ui_runner.gd' -List`列3支，再同selectors `-Parallel 3` → **3/3 PASS，matrix=single、exit0**；logs `d6aa02f8c01640a1b80cc0adfe1fbb52`。新增方向中立名籤、3固定回應組、精確收益對應、長文300次重複的溢出提示／到底更新；既有五宗15人、44px、命令唯讀／保存鎖定仍通過。沒有全量或全尺寸宣稱。
- **字型與Web包**：首次`python tools/subset_game_fonts.py --check`因U+2193缺字失敗，不算通過；既有工具重建後check PASS。`Godot --headless --path . --export-release SectReformUiReview build/sect-reform-ui-review/index.html`及`node tools/prepare_web_compression.mjs build/sect-reform-ui-review` exit0，輸出`.test-output/sect-text-r2-browser/export.log`／`compression.log`。最終PCK SHA256 `1a0b17bc0341fc6ee47d0bec163cc9a872e98c4e1a476e9ae3a2741f3bf367c3`。只更新本機隔離測試包，一般build/web未同步，不是候選交付，不觸發L3。
- **L2真實桌面滑鼠**：Edge同origin48584既有隔離檔；暫設外框1600×820以完整操作shell，DOM實測iframeCSS1280×720／DPR約1，結束reset。目視確認姓名圓點、分層正文、三回應與各自獎勵完整可見；正文內捲後提示從尚有內文變為已到末尾，回應卡不跟著移動。實際點B「先理卷次」：revision10→11、貢獻10000→10001、沈照微交情0→4、pending_story清空、回應卡移除，與所示收穫一致且顯示已保存。只操作隔離資料，不是使用者正常進度；載入時舊隔離檔曾自然離線結算，不能稱全輪revision不變。`before.json`／`after.json`與`top.png`／`bottom.png`／`resolved.png`在`.test-output/sect-text-r2-browser/`。不以此宣稱自然玩法節奏放行。
- **限制／收尾**：browser日誌保留15:51:23的既有BGM02 Failed to fetch／下載失敗重試警告，不稱console空；未改音訊。`python tools/delivery_check.py --web build/sect-reform-ui-review` PASS（Web7/7、受保護證據變更0），`git diff --check` exit0。測試服務Ctrl+C停止（exit1為主動停止），原Edge頁留原處、其他使用者頁未操作。未跑L3／FPS／實機，觸控實機延期且非當前阻擋。
- **下一步／交接**：本R2視覺回饋已收束；下一核對自然節奏接受，再進整批CLOSE的L3；不開下一大型階段。updata英文checkpoint置頂並保留5筆。可手動commit（本次回應區修訂階段結束，非大型任務結束）；代理未commit／push。下一大型階段請開New Chat。

<a id="sect-life-ui-text-r1"></a>
## 2026-11-05 SECT-LIFE-UI-TEXT-R1（同門文字層級修訂，實作與L1／L2階段DONE，待視覺回饋）

- 任務範圍：接使用者截圖，區分姓名／交情等級／交情數值／座右銘／章名／故事正文。姓名24px文楷直列【名籤】置立繪旁；低高度22px橫排；青玉20px等級、獨立16px交情文字及真實0～100細條同列可換行；座右銘20px文楷、朱紅22px明體章名、18px黑體正文／6px行距。沿單一紙面及閱讀內捲、44px固定選項；沒有新增美術、規則或保存變更。最終視覺接受待使用者回饋。
- 修改檔案：`src/presentation/sect_life_folio.gd`、`tests/sect_life_ui_runner.gd`、`docs/19-ui-ux-guidelines.md`與交接；現有`tools/subset_game_fonts.py`更新runtime兩字型與manifest，只補字型子集，不改原始字型。其他既有未提交工作保留。
- L1：本機Godot4.7.2。先`tools/run_all_runners.ps1 -Only 'sect_life_ui_runner.gd,sect_tournament_ui_runner.gd,m3b_sect_ui_runner.gd' -List`列3支，同範圍`-Parallel 3`全部PASS、單一1280×720，logs `10f6c502b7bc40b98fed3616fbd0fd51`。畫面核對後名籤移出正文標頭／交情資訊改同列，各小修精選同門runner補驗，最終補驗`-Only 'sect_life_ui_runner.gd'`，含交情短句不逐字折行檢查（結果追加於下）。涵蓋名籤、精確交情0及進度0、18px正文、既有五宗15人切換／44px選項／唯讀與保存鎖定，不稱全量回歸。
- 字型／匯出：`python tools/subset_game_fonts.py --check`首次指出U+3014/U+3015缺字（不算通過），既有工具重建後`--check` PASS。隔離`SectReformUiReview`匯出／壓縮，僅本機測試包；一般build/web未同步，不是候選交付，不觸發L3。初次畫面發現直列名籤塞標頭使正文過低，改置立繪旁；交情等級／數字／細條合列以留正文空間。中間Web抽驗發現HFlow內文字自動折行造成逐字直排，修正等級／數值Label不自拆行，由HFlow整項換行，並加短句高度回歸；中間版本不算L2通過，採最終包驗收。過程中既有user://與退出診斷保留。

- 最終補驗：同門runner含新增交情短句高度檢查PASS，logs `7ae563fca6ee4805801431857e1e9be7`；最終來源匯出exit0，`node tools/prepare_web_compression.mjs build/sect-reform-ui-review` exit0。最終PCK SHA256 `a38e24903295566e47b4f604fd14da85378227396a9eae64c86de2131d130493`，`python tools/delivery_check.py --web build/sect-reform-ui-review` PASS（Web7/7、受保護證據變更0），`git diff --check` exit0。
- L2桌面Web：Edge同origin48584原隔離存檔；外框暫設1600×820，DOM iframeCSS1280×720、DPR約1，最後reset。真實滑鼠：正文內捲到尾端、三項獎勵說明及固定選項可見；換陸景行同步姓名／肖像／座右銘／交情；最近記錄／返回與切回沈照微正常。截圖` .test-output/sect-text-browser/final-top.png`、`final-scroll.png`、`lu.png`與`state.json`。零交情仍顯示0／100及初識，沒有假填滿；未點回答或領獎，導覽過程revision8／貢獻10000／tokens24／交情0保持。載入舊隔離檔的離線結算曾讓revision6→8及宗齡前進，這是load前後，不能宣稱整輪狀態完全不變；本輪不驗自然時距。
- 日誌限制：browser日誌保留15:36:41的BGM下載Failed to fetch／03曲失敗重試警告（中間匯出／重載期間），未因此判定文字功能失敗，也不稱console空。未新增音訊變更。最終匯出log在`.test-output/sect-text-browser/export-final.log`，本輪不宣稱無既有user://診斷。服務Ctrl+C停止（exit1為主動停止），原Edge頁留原處，其他使用者頁未操作。
- 下一步／交接：本次實作及L1／L2階段DONE，收使用者對名籤／交情／座右銘／正文的視覺回饋。一般build/web未更新；整體SECT-LIFE仍待視覺與節奏接受及整批CLOSE的L3，觸控／實機延期且非當前阻擋。本輪沒有L3／FPS宣稱。英文checkpoint已更新，updata保留5筆。可手動commit（文字層級修訂階段結束，非大型任務結束）；代理未commit／push。下一大型階段請用New Chat。

<a id="sect-life-ui-tabs-r1"></a>
## 2026-11-05 SECT-LIFE-UI-TABS-R1（分頁層級修訂，實作與L1／L2階段DONE，待使用者視覺回饋）

- 任務：接使用者截圖回饋與剩餘範圍核對；宗門內層五分頁從卷首主分頁中建立可辨層級。本次續驗已滿足實作／L1／L2子階段DoD；整體SECT-LIFE不結案，使用者最終視覺與自然節奏接受另待回饋。
- **2026-11-05桌面續驗（L2 PASS）**：使用者授權接續抽驗。本輪Edge擴充連線已可辨識，重新啟動同origin `python tools/sect_reform_ui_server.py --port 48584`，接回原隔離測試頁並reload。PCK SHA256仍`1a338c3f998e24217487682e61b8c7a4726c31f042ba6234b8cba17a6c20bc0e`，與前輪已通過4支runner的來源一致，未再改程式／匯出，引用前輪L1，不重跑相同驗收。瀏覽器外框暫設1600×820以完整操作測試shell，DOM實測iframe CSS1280×720／DPR約1，完成後reset；不是全尺寸矩陣。
- **實際操作證據**：滑鼠依序點歷練→秘術→坊市→同門→大比，五項均切換正確，細分隔／淡底／選中提示可見。秘術與坊市展開原庫存欄，敘事／大比收回；沒有分頁被擠出紙面。Tab轉到原資源操作，Shift+Tab返回大比焦點框，再Shift+Tab到未選中同門，Enter切同門成功；單一卷首CloseSeal返回洞府，再由遊歷重開同門成功。DOM報告revision4、貢獻10000、tokens24、pendingfalse保持；未點故事選項或購買／參悟，不改收益／待決故事。這是合成金丹起點／暫停時鐘，不證明自然節奏或玩家完整通關。
- **證據位置／限制**：`.test-output/sect-tabs-browser/keyboard-fellows.png`（焦點）、`fellows-final.png`（重開同門）、`state.json`（DOM承載狀態與尺寸）、`final-dom.txt`；browser本輪warn/error查詢空。已目視確認外層青玉主分頁與內層分隔籤條有區別；美術接受由使用者決定。前輪連線／網址判定失敗保留下方作歷史，不再為目前抽驗阻擋。測試服務已Ctrl+C停止（exit1為主動停止），既有Edge頁留原處，不操作其他使用者頁。
- 修改：`src/presentation/components/game_tab.gd`新增可選secondary；`src/presentation/ui_material.gd`集中淡墨青底、細分隔框、選中3px底線及2px焦點框；`src/presentation/sect_panel.gd`五項自然寬連續排列，移除前三項獨占stretch，五項均可鍵盤聚焦；`tests/sect_life_ui_runner.gd`補44px／分隔／五頁切換與容器內界線檢查；docs/19同步通則。外層與人物直式書籤沿原樣，未改規則／保存／收益或美術資產。
- 命令與結果：本機Godot `--version`=4.7.2.stable.official.ed1daf0bf。`tools/run_all_runners.ps1 -Only 'sect_life_ui_runner.gd,sect_tournament_ui_runner.gd,m3b_sect_ui_runner.gd,uix_r1_components_runner.gd' -List`精選4支；同範圍`-Parallel 3`最終4/4 PASS、matrix=single、exit0，logs id `9193926a45194c42a223a9eaca15ec76`。最初樣式key型別推斷錯誤造成SCRIPT ERROR與逾時，補顯式String後另輪全部通過；初輪自動串行重試也通過，但只引用修正後獨立一輪為證據。既有user://日誌與退出診斷仍保留。
- Web：`Godot --headless --path . --export-release SectReformUiReview build/sect-reform-ui-review/index.html` exit0；`node tools/prepare_web_compression.mjs build/sect-reform-ui-review` exit0，PCK SHA256 `1a338c3f998e24217487682e61b8c7a4726c31f042ba6234b8cba17a6c20bc0e`。僅更新本機隔離測試包，未更新一般build/web，不是候選交付，不觸發L3。
- 前輪未通過／未完成（本輪L2已補驗）：IAB連sandbox port48583逾時；改本機授權port48584後IAB仍陷錯誤頁URL策略，沒有看到新版遊戲。啟動既有Edge開同隔離頁，Computer Use於取得視窗時因無法可靠判定瀏覽器URL而停止，遵從停止UI操作。沒有新版截圖／真實滑鼠／視覺接受證據，不能記L2通過。手動可啟動`python tools/sect_reform_ui_server.py --port 48584`後開`http://127.0.0.1:48584/review.html?life=1`，檢查五項集中分隔、選中底線、逐頁切換、Tab焦點與單一卷首返回。
- 剩餘範圍核對：ENTRY／CORE／UI／TOURNAMENT／CONTENT／ART各子段既有證據沿前紀錄；新版桌面抽驗已補齊；剩餘使用者視覺回饋，再收自然時距／大比風險與收益節奏接受。整批正式範圍確定後才CLOSE一次L3，不把合成起點／加速命令當自然節奏通過。觸控與實機延期，非當前阻擋。下一任務為收本UI-TABS-R1視覺回饋與剩餘節奏範圍，不自動展開新大型任務。
- 英文checkpoint已置updata最頂，保留最新5筆。可手動commit（本次實作checkpoint，非大型任務結束）；代理未commit／push。下一New Chat可從本anchor續接。
- 收尾檢查：`python tools/delivery_check.py --web build/sect-reform-ui-review` PASS（Web7/7、受保護證據變更0），`git diff --check` exit0。測試服務48583／48584已Ctrl+C停止（exit1為主動停止）；Edge頁未再操作。

<a id="sect-life-art-integrate"></a>
## 2026-11-05 SECT-LIFE-ART-INTEGRATE（四宗正式Godot美術整合，階段DONE，L1／L2）

- **範圍／結果**：接續已接受的SECT-LIFE-ART-FOUR-R1，4張山門＋12張人物原檔接入正式SectLifeFolio，取代四宗舊宗印占位；加太虛共5山門／15人物。原圖與runtime共20件逐一SHA256一致，未裁切／縮製／修畫，保留透明alpha；GameTab／紙面／CloseSeal／內捲／44px固定動作與等比顯示沿原實作。只載入當前選中圖，沒有新增世界地標或動態霧光。本輪未改規則、存檔、經濟、字型或玩家資料，也未新增共用UI通則。
- **修改檔案**：src/presentation/sect_life_folio.gd改五宗圖檔映射、移除舊太虛限定／四宗占位分支與未用常數；assets/ui/sect-life/新增16PNG及Godot產生的import側檔；tests/sect_life_ui_runner.gd補5山門／15人物精確resource_path、等比與輸入忽略檢查。docs/sect-life/art-four-v1/manifest.json補runtime路徑與processing，README／review同步；art-v1/manifest只修過時remaining；docs51與本交接更新。開工前既有未提交成果全部保留，代理未commit／push。
- **L1／L2命令與證據**：本機Godot `--version`=4.7.2.stable.official.ed1daf0bf；`--headless --path . --editor --import` exit0。先 `tools/run_all_runners.ps1 -Only 'sect_life_ui_runner,sect_reform_ui_runner,sect_tournament_ui_runner' -List` 確認3支，再相同selectors `-Parallel 3` → **3/3 PASS，matrix=single（1280×720）**；logs標識dao2_runners_3a2471c02e71475abbda4494c43e49c3，終端保留成功結果（沙箱暫存stdout路徑結束後已不可存取，沒有假稱已複製永久log）。涵蓋正式同門、原宗門UI與相鄰大比頁；L2沿用同來源這組L1證據，加下面桌面Web抽驗，不重跑相同CLI。runner輸出guard通過、受保護證據未變更。無L3／全量／全尺寸宣稱。
- **L2桌面Web**：`--export-release SectReformUiReview build/sect-reform-ui-review/index.html`與`node tools/prepare_web_compression.mjs build/sect-reform-ui-review` exit0；只更新本機測試包，一般build/web未重匯出。Chrome獨立origin48579，DOM量測iframe CSS1280×720，合成築基未入宗起點（不是自然時間玩法證據）。真實滑鼠依序太虛→天劍→縹緲→萬佛→紫霄，山門畫面與宗名對應；立誓拜入紫霄後，同門頁謝歸辰→周問序→寧照夜人物透明顯示正確，最近記錄收圖／返回人物恢復。拜入revision8→9，之後導覽revision9與交情0保持、pending=false。圖片不遮正文與操作。截圖／DOM-backed狀態保留`.test-output/sect-art-browser/`；最終warn/error查詢空。未把桌面抽驗擴稱十五人逐一瀏覽器驗證，全部圖檔對應由CLI檢查。無viewport override，驗收tab已關；48578／48579服務均以Ctrl+C停止（exit1為主動終止），其他服務未動。
- **診斷／限制**：首次48578沙箱服務對桌面瀏覽器不可達，改以正常授權、僅綁127.0.0.1的48579服務完成；失敗未算通過。import/export既有user://目錄診斷保留，程序exit0且無SCRIPT ERROR，不稱零日誌錯誤。靜態原畫已接受；獨立霧光／頭像衍生非本輪交付，沒有虛構動畫或FPS驗收。整體SECT-LIFE尚未CLOSE。
- **交付檢查／下一步**：`python tools/delivery_check.py --web build/sect-reform-ui-review --manifest docs/sect-life/art-four-v1/manifest.json --manifest docs/sect-life/art-v1/manifest.json`→ **PASS**（Web 7/7、四宗manifest 16/16、太虛4/4、受保護證據變更0）；`git diff --check` exit0，既有LF／CRLF提示保留。本階段完成後主動checkpoint；下一New Chat收正式Godot畫面回饋並核對整體SECT-LIFE剩餘範圍，全部核定範圍完成時才做CLOSE唯一L3。**可手動commit（美術整合階段結束，非整體大型任務結束）；代理未commit／push。**

<a id="sect-life-art-four-r1"></a>
## 2026-11-05 SECT-LIFE-ART-FOUR-R1（四宗16張原畫美術已接受，正式接入待續）

- **美術接受追加（2026-11-05）**：使用者明確回覆「美術接受」，四宗4張山門＋12位同門原畫全部接受。manifest頂層及16件資產均改為ACCEPTED，補接受日期／範圍；review／README與交接同步。16原圖SHA256核對全數一致，未重生／修畫／裁切或替換原圖。本次僅metadata／文件更新；`python tools/delivery_check.py` PASS、`git diff --check` exit0，不跑遊戲runner／import／匯出。此接受涵蓋插畫，正式runtime／Godot接線與UI驗證尚待下階段；下方待審閱描述為首稿交付時歷史。下一New Chat可直接接四宗正式美術整合與相依L1／L2。可手動commit（美術接受階段，非大型任務結束）；代理未commit／push。
- **任務／範圍**：使用者要求「接續四宗美術」，承接已接受太虛畫風與CONTENT人物名冊。完成天劍／縹緲／萬佛／紫霄各1山門＋3成年同門，共16張原圖及[分宗審閱索引](sect-life/art-four-v1/review.md)。這是首稿checkpoint，非完整ART／UI或SECT-LIFE DONE；依docs51第7、8節保留使用者美術審閱後再正式整合。
- **產物與來源**：新增 `docs/sect-life/art-four-v1/` 的 `originals/`、16份完整 `prompts/`、`manifest.json`、`generated-sources.json`、`review.md`、`README.md`。built-in image_gen逐件生成16次，沒有外部參考圖輸入；先視覺查看已接受太虛山門／沈照微原稿，再以文字描述延續手繪水彩／礦物顏料質感。來源、用途、切層、原圖SHA256、尺寸與授權界線均保留；不宣稱第三方商用授權，manifest為PENDING_USER_REVIEW。
- **視覺與切層**：天劍劍碑／石階、縹緲藥谷／梯圃、萬佛蓮燈／寺門、紫霄雷台／觀測；12人物依已接受衣色／持物製作。四景1672×941 RGB，12人1086×1448 RGBA，alpha extrema全0～255、全透明面積35.71%～50.56%。原圖已逐件顯示並檢視輪廓／手部／持物；腰下半身收幅，部分寬袖／衣擺接近邊緣，正式縮製時需保留比例。原圖僅byte-identical複製，沒有裁切／縮放／修畫／alpha清理；人物與主景獨立，景內霧光未另切層。臉部辨識與最終美術接受仍由使用者審閱，不由靜態檢查代判。
- **命令／檢查**：本機Godot `--version` 回報4.7.2.stable.official.ed1daf0bf。PowerShell內嵌Python／Pillow完成原圖複製、完整提示詞留存、16PNG解碼／SHA256／唯一ID／提示詞存在、12透明層、UTF-8與審閱本地連結檢查PASS；太虛已接受4原圖SHA256仍一致。 `python tools/delivery_check.py` RESULT PASS、受保護證據變更0；`git diff --check` exit0，僅既有來源的LF→CRLF提示。 `python tools/trim_status_docs.py` 用於README／ROADMAP最新3筆歸檔；updata保留最新5筆，移出歷史另存archive。
- **驗收級別與邊界**：純美術／文件靜態檢查，未觸發遊戲L1／L2／L3、import、Web匯出、瀏覽器操作或效能量測。沒有修改正式Godot來源、runtime資產、玩家資料、存檔版本或build；既有未提交ENTRY／CORE／UI／TOURNAMENT／CONTENT／字型成果保留。Markdown只是審閱索引，沒有新增正式UI規範。16次生成均成功；新增checkpoint首次diff-check指出updata檔尾空白行，已移除後重驗exit0，原失敗不算通過。美術接受、runtime縮製／頭像與正式接線尚未完成。
- **下一步／交接**：於本首稿checkpoint主動停止；New Chat收四宗山門與12人物美術回饋，接受後再接runtime／Godot與相依L1／L2（整批CLOSE才一次L3）。**可手動commit（四宗原畫首稿階段結束，非大型任務結束）；代理未commit／push。**

<a id="sect-life-content"></a>
## 2026-11-05 SECT-LIFE-CONTENT（五宗內容正式接入，階段DONE，L1／L2）

- **接受與交付**：使用者本輪明確接受12人／24章審閱稿並要求實作。天劍／縹緲／萬佛／紫霄各3人／6章／3回訪接正式規則、同門Folio與大比熟面孔；加既有太虛共15人／30主章／15回訪。章序、A／B／婉拒及E4～E6的三種前旗回顧、分支A動作均依接受文稿。太虛原ID／全文／獎勵／RNG保持；經濟、時距、600秒預留12、好感100與單槽規則不變。v2原創，不宣稱DAO1 parity。
- **版本／遷移**：sect6／schema9／life3／content2，rules `core-flow-29-sect-life-content-2`，content加`+sect-life-content-2`。舊schema7／8按原規則讀取；沿SaveManager既有hash來源歸檔、凍結候選、精確讀回與拒寫重試升版。其餘四宗只補3人；宗齡／entry／兩流RNG／預留／舊委託／功法／貢獻及既有competition保留，不補歷史故事。新報名`roster_version=2`指定三熟面孔，舊已報名缺此鍵仍解析舊名冊，未改計分版本與抽樣順序。跨宗NPC、故事、recent與旗均嚴格拒讀。
- **UI／美術範圍**：Folio依本宗取人物、問候、正文、獎勵人名及記錄，沿GameTab／InscriptionAction／紙面、16px正文／44px動作與既有內捲。四宗明示「宗印占位 · 人物插圖尚待審閱」，不借用太虛立繪；文字接受不擴為新山門／人物美術接受。本輪未新增共用UI通則。
- **修改檔案**：新增src/simulation/sect_life_catalog.gd與.uid、tests/sect_life_content_runner.gd與.uid；修改SectLife、SectLifeContent、SectLifeSave、SectSaveContract、SectReformRelease、SaveCodec、SectLifeFolio、SectTournament／Folio；更新life core依賴的save／UI／tournament runner、隔離review harness及runner註冊。既有字型工具重建兩runtime字型與manifest。接受稿、docs51、README／ROADMAP、本狀態與updata更新；開工時既有ENTRY／CORE／ART／UI／TOURNAMENT等未提交成果保留，未改玩家檔，未commit／push。
- **L1／L2命令**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。各組先`tools/run_all_runners.ps1 -Only '…' -List`；首L1選content／core／save／tournament四支。共用保存與宗門UI改動，L2選content、core、save、life_ui、entry、tournament、tournament_ui、reform_release、reform_lineage共9支，`-Parallel 3`、matrix=single，**9/9 PASS**（logs標識`dao2_runners_34ab3db4434449d0bb4041dd4ce7308a`；終端保留各支結果，沙箱暫存檔非永久證據）。補齊五宗故事拒寫／重試／命令去重與四宗合併容量測試後，只重跑content／save兩支，**746／44 checks PASS，2/2**；最後logs `dao2_runners_fbbe27b2837c4ffdbbc8af865da377d4`，stdout／stderr已複製`.test-output/sect-content-final-logs/`。UI五宗49 checks已納L2；核心含既有整段／分段與離線共用路徑。沒有全量／全尺寸／L3宣稱。
- **保存容量實測**：四舊最大文字委託＋全部功法／坊市／獸許可＋六章旗／滿好感／五宗meta／四故事recent／待決日常／八席凍結大比與四屆歷史，Godot緊湊UTF-8 JSON：太虛sect9998／life1968、天劍10015／1983、縹緲10005／1973、萬佛9961／1935、紫霄10016／1988 bytes；五宗encode／decode通過，保持32768／8192。近上限舊sect保留玩法與SECT_SIZE不啟用行為通過；上述是明列合成內容，非任意擴充舊字典的尺寸保證。
- **桌面Web L2**：同版`--headless --path . --editor --import`、`--export-release SectReformUiReview build/sect-reform-ui-review/index.html`及`node tools/prepare_web_compression.mjs build/sect-reform-ui-review`均exit0；僅本機測試包，未更新一般build/web、非候選交付。Chrome隔離origin48562、實測iframe CSS1280×720，金丹合成起點；實際滑鼠天劍首章B→拒寫覆層（權威貢獻10000／交情0／章mask0、pending=true）→恢復寫入→按重試（10001／顧硯霜交情4／sheath=sort）→最近記錄→真實重載，仍10001／交情4／一筆B記錄、pending=false。重載後revision11。保存重試及重載有時鐘補算，不能把harness標稱暫停擴張為全程零宗齡；沒有自然30章節奏／FPS證據。重載截圖與DOM-backed狀態`.test-output/sect-content-browser/reloaded.png`／json，含前後狀態的服務觀察`.test-output/sect-content-browser/observations.json`。最後console warn/error查詢空；服務favicon404與引擎沙箱user://log診斷保留，不稱全日誌零錯誤。沙箱loopback不可連，改僅127.0.0.1的正常授權服務；未繞過安全提示。兩測試服務已Ctrl+C停止（exit1為主動停止），原一般服務未動，未設viewport override。
- **失敗與修正**：初輪JSON讀回的version陣列成員型別判斷造成遷移失敗，改整數契約與明確2／3比較；新合成五宗fixture只改身份造成傳承／成就不一致，改用既有SectLineage.observe並重生本宗委託，保持已取得的永久成就。初輪失敗／SCRIPT ERROR／timeout均未算成功；修正後以上範圍重驗通過。無剩餘本CONTENT阻擋。
- **交付檢查**：`python tools/subset_game_fonts.py --check` PASS；`python tools/delivery_check.py --web build/sect-reform-ui-review` →RESULT PASS（7/7壓縮manifest，受保護證據變更0）；`python tools/trim_status_docs.py`確認無額外前言需歸檔。初次diff-check發現updata尾端多一空行，已修正；最終`git diff --check` exit0，既有LF／CRLF提示保留。固定表逐字對照接受稿、UTF-8與五筆checkpoint靜態檢查通過。
- **下一步／checkpoint**：CONTENT階段DONE，整體SECT-LIFE尚未結案。以New Chat收文字／操作回饋，或接四宗山門／人物美術先審；全部核定範圍完成後才啟動CLOSE唯一L3。可手動commit（CONTENT階段結束，非整體宗門生活結案）；代理未commit／push。

### 同日較早：文稿子階段紀錄（接受前狀態，已由上方接續）

- **範圍／交付**：使用者接續CONTENT；依docs50／51的五宗15人30章目標，完成[四宗人物與章節審閱稿](sect-life/content-v1-review.md)。新增天劍／縹緲／萬佛／紫霄各3名成年同門、6個主題章節、3種短回訪，合計12人24章12回訪；加既有太虛後為目標15人30章，未宣稱正式五宗可玩。每章完整正文、A/B動作與選後回應；E4～E6分別承接E1～E3的A／B／婉拒，列明固定旗enum。四宗題材為劍器進退、觀察校量、照看傾聽、星圖陣界，附大比席位2／4／6熟面孔與現有三段題材的對應。
- **先審依據／狀態**：docs51第8節明定「新人物名字、山門與人物畫風先交使用者審閱」；本輪先交具體12人名冊與完整文稿，姓名及題材尚未獲接受，正式接入等待此項審閱。這是本地設計要求，不是工具自動審核拒絕。未新生成山門／立繪，也不把文字接受當作新美術接受。人物均為本世友情／合作／競爭；v2原創，不宣稱DAO1 parity。
- **規則／保存接入準備**：文稿沿現有0／60／120／240／360／480宗齡、六章序列、0～2貢獻、600秒最多預留12、好感100與單槽／離線不代選。列出現有SectLife／SectLifeSave／Folio太虛硬編限制、跨宗ID／旗驗證、版本化啟用與舊待決／舊賽事保留要求；未預佔新schema／sect／content版號。其餘四宗遷移須保留宗齡、entry、兩流RNG、經濟及既有賽事，只補本宗三人，不補歷史故事。插圖待審時可用明示宗印占位；共用UI規則保持。
- **修改檔案**：新增docs/sect-life/content-v1-review.md；docs51補入口；README／ROADMAP一行連結、本狀態與updata／必要歸檔。開工時ENTRY／CORE／ART／UI／TOURNAMENT及字型等未提交成果保留；本輪沒有修改src／tests／content／assets、玩家資料或build。
- **靜態檢查**：本機Godot `--version`=4.7.2.stable.official.ed1daf0bf。inline Python核對12人／24章／12回訪、48個唯一ASCII ID且均≤48 UTF-8 bytes、每宗E1～E6齊全、24段正文99～110字、48段主章選後回應30～60字、本地連結／嚴格UTF-8／行尾空白通過。純文稿子階段依分級驗收只做靜態檢查；未跑L1／L2／L3 runner、import、Web匯出、瀏覽器、FPS或自然節奏試玩，既有大比證據不作新內容驗收。
- **交付檢查**：初次文長檢查發現兩段選後回應為61／62字，已縮至規範內；最後inline Python斷言PASS（含24個唯一旗鍵、36段A／B／婉拒回顧及最新5筆checkpoint）。`python tools/trim_status_docs.py`完成README／ROADMAP前言歸檔；`python tools/delivery_check.py` →RESULT PASS、受保護證據變更0；`git diff --check` exit0，既有LF／CRLF提示保留，不稱零診斷。無遊戲回歸或全量驗收宣稱。
- **下一步／checkpoint**：請審閱名冊與文稿；接受後以New Chat接SECT-LIFE-CONTENT正式四宗資料／原子保存遷移／既有Folio與大比熟面孔接線，再做受影響L1／L2。全部宗門生活範圍最終CLOSE才跑一次L3。可手動commit（文稿子階段結束，非CONTENT實作或整體宗門生活結案）；代理未commit／push。

<a id="sect-life-tournament"></a>
## 2026-11-05 SECT-LIFE-TOURNAMENT（宗門大比，階段DONE，L1／L2）

- **範圍／交付**：依docs51已定稿模型接正式Godot宗門「大比」分頁。五宗共用8席三段策略，題材分宗；太虛席位2／4／6為沈照微／陸景行／唐溪禾的當屆同境投影。宗齡300秒起、其後600秒一屆；邀請／已報名均單槽保留，不補領錯過屆，跳過／棄賽／領獎後排下一未來屆。無報名費／截止／丹藥準備費，離線不代選或代領，關頁可續；壽盡唯讀，輪迴清本世賽事與四筆回顧、保留五宗最佳／魁首稱號推導。
- **評分／原子性**：報名凍結境界組、層數、共通吐納＋本宗有效專法（合計封頂10）、準備段與宗齡tick。獨立tournament流依序三硬幣→21偏移→Fisher-Yates籤序；讀頁不重抽。策略穩健+5／進取半數−4或+12／觀察準備段+7其他+2，另有準備+4；不讀BUFF／好感／傳承作加分。總分→最低段→籤序排名；分數／名次／獎勵讀回重算。獎表18／14／10／6（總額），只在明確領獎原子發貢獻，清槽及世序／屆序去重；不加委託計數、獸印或傳承有效世。
- **保存／相容**：sect5／schema8／life.version2／scoring_version1，rules `core-flow-28-sect-tournament-1`、content加`+sect-tournament-1`。舊sect4／schema7／life1沿原規則可讀；啟動同一來源歸檔→候選→精確讀回升版，保留舊entry、故事、好感、RNG、委託與經濟。舊版不得夾帶competition。五命令加入Session／CommandProcessor／SectReformSave白名單；拒寫不替換權威、重試凍結資料、同command_id去重。既有32KB與life8192限制不變；原最大四委託／功法／獸權利／六章／四故事紀錄／五宗meta再加八席凍結大比與四屆歷史，Godot UTF-8 JSON為 **sect9979、life1949 bytes**，encode／decode通過；這是明列合成量測，不宣稱任意舊擴充字典皆有同大小。近上限舊檔保留原玩法與SECT_SIZE不啟用行為亦通過。
- **UI／檔案**：新增 `src/simulation/sect_tournament.gd`、`src/presentation/sect_tournament_folio.gd`、`tests/sect_tournament_runner.gd`／`sect_tournament_ui_runner.gd`及.uid。修改SectLife、SectLifeSave、SectSaveContract、SaveCodec、SaveManager、SectReformRelease／Save、GameSession、CommandProcessor、SectPanel、ModalManager、runner註冊、原生活保存runner、隔離review harness；docs51補欄位對應。共用GameTab／InscriptionAction／紙面／單一關閉／容器內捲保持，操作與當前段落風險列固定，棄賽需另按確認；正文16px、動作至少44px，保存保護沿既有全域重試。未新增美術與通用UI規則。既有字型工具補缺字並檢查通過；開工前未提交ENTRY／CORE／ART／UI等成果保留。
- **L1／L2命令與結果**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。每組均先 `tools/run_all_runners.ps1 -Only '…' -List`。最後 `-Only 'sect_tournament_runner,sect_tournament_ui_runner,sect_life_save_runner' -Parallel 3` → **3/3 PASS，matrix=single，109／15／40 checks**，logs `dao2_runners_5ff848ddfa8f41a796fec1cf924826a0`、完整stdout／stderr複製於 `.test-output/sect-tournament-final-logs/`。涵蓋同分／兩硬幣結果／五宗／死亡／離線、凍結續段、報名及領獎拒寫重試、防重領、篡改抽樣／混合階段拒讀、schema7來源歸檔遷移、滿載容量與UI唯讀信號／焦點／固定風險及領獎。共用保存／生活依賴採L2：另core／life_ui／sect_reform_release／sect_reform_lineage均PASS（分組 `b5ff7aa532d040da984d24d00ebbd987`、`28fccc1c233247118fa767e0dda5d6a0`），合計7支不同領域runner，未跑全量。初輪測試型別推導錯誤、JSON浮點版本enum檢查造成讀回失敗與其後SCRIPT ERROR／timeout均未計成功；改為整數契約檢查與正規化後重跑通過。沙箱user://log／import目錄診斷及既有anchor警告仍存在，不稱零診斷。
- **桌面瀏覽器／證據**：本機測試preset `--headless --path . --export-release SectReformUiReview build/sect-reform-ui-review/index.html`、`node tools/prepare_web_compression.mjs build/sect-reform-ui-review` 最終均exit0，非候選包／未同步一般build/web。Chrome最終隔離origin48541、iframe CSS1280×720、DPR約1，合成金丹會員／暫停在線時鐘；真實滑鼠報名→觀察→重載返回（基準／三硬幣／首段不變）→進取→穩健→第8名。領獎故障開關拒寫，權威仍settled／10000貢獻且保存保護；恢復並按重試後10006／current=null／recent一筆claimed rank8／best8；再次重載revision37仍相同，沒有可重領按鈕。`.test-output/sect-tournament-browser/`留denied／claimed／reloaded JPG及狀態JSON；原server觀察日誌 `.test-output/sect-ui-browser.jsonl`。最終warn/error查詢空。初次沙箱loopback不可連，改正常授權127.0.0.1服務；未繞過瀏覽器安全提示。先前48540僅前版抽驗，不冒充最終風險列證據。瀏覽器override已重設、驗收分頁已關閉。
- **交付／限制／下一步**：`git diff --check`、`python tools/subset_game_fonts.py --check`及 `python tools/delivery_check.py --web build/sect-reform-ui-review` PASS（7/7壓縮manifest，受保護證據變更0）；匯出與壓縮日誌在 `.test-output/sect-tournament-*-final.log`，通用摘要 `.test-output/sect-tournament-delivery.log`。此為TOURNAMENT有界階段DONE，非完整SECT-LIFE結案；自然時間節奏與最終視覺接受未由合成桌面／CLI推定，未跑L3或全尺寸／效能重測，實機依政策延期非當前阻擋。下一New Chat先收本階段視覺／玩法回饋，再接SECT-LIFE-CONTENT（擴其餘四宗，補齊五宗共15人／30事件）；整批CLOSE才一次L3。**可手動commit：宗門大比階段結束，非大型SECT-LIFE任務結束；代理未commit／push。**


<a id="sect-life-ui"></a>
## 2026-11-05 SECT-LIFE-UI（山門／同門正式 Godot 接入，階段DONE，L1/L2）

- **範圍與交付**：承接已接受的太虛四圖及 CORE-1／CORE-SAVE；新增原生 `SectLifeFolio`，未入宗為五宗選擇、選中圖像／專法與守護獸說明、五宗比較、單一立誓動作；太虛使用接受山門，其他四宗復用既有宗印。已入宗保留歷練／秘術／坊市，新增同門頁、三人立繪與交情、待決訪帖、A／B／婉拒、最近四筆分支回應。正文為Godot內捲，動作固定於閱讀區之外，44px命中；使用既有GameTab／InscriptionAction／共同紙面與Shell關閉，不新增通用UI規則。低高度縮小立繪，靜態資產無逐幀霧光；非太虛不展示假同門內容。
- **命令／保存**：讀 `SectLife.view` 的凍結實例與報酬，透過 ModalManager→Session.resolve_sect_story，沿既有候選交易、保存保護與重試。保存待決或壽盡時禁止選擇，記錄仍可讀；只增加安靜遊歷通知與同門訪帖標記，不自動搶頁、代選或發獎。宗齡tick不重建選項，保留鍵盤焦點；重載／重試後能從權威recent讀回上次回應。本輪沒有改規則、schema、存檔欄位、經濟或大比。
- **檔案／美術來源**：新增 `src/presentation/sect_life_folio.gd`、`tests/sect_life_ui_runner.gd`及引擎.uid、`assets/ui/sect-life/`四PNG／import；修改 `sect_panel.gd`、`abode_modal_manager.gd`、`feature_navigation.gd`、runner註冊與隔離 `sect_reform_ui_review.gd`／server，以及 `tests/m3b_sect_ui_runner.gd` 的選宗斷言。資產為已接受原圖的逐位元複製，四份SHA256對照原manifest通過；完整提示詞與來源保留於 `docs/sect-life/art-v1/`，manifest補runtime用途，沒有重生／改畫／縮製原圖或擴其餘四宗。使用既有工具補runtime字型缺字（原授權字型未改）。保留開工前ENTRY／CORE／DESIGN等未提交成果。
- **L1／L2命令與結果**：本機Godot `--version`＝4.7.2.stable.official.ed1daf0bf。所有selector先 `-Only '…' -List`。初組entry／sect_reform_ui／feature_navigation通過；UI runner首輪型別宣告與測試未設定SaveManager供給content造成坊市SCRIPT ERROR，均已修正，不計通過。L2 `tools/run_all_runners.ps1 -Only 'sect_life_ui_runner,sect_life_save_runner,sect_reform_ui_runner,uix_r1_components_runner' -Parallel 3` →4/4 PASS（單一1280×720），日誌 `dao2_runners_ab8008ff1f724dd4b4f7e38686e39de3`；追加舊宗門UI依賴 `-Only 'm3b_sect_ui_runner,content_p2_sect_ui_runner' -Parallel 2` →2/2 PASS，日誌 `dao2_runners_6659efffe09f4875be149b671c491cb5`；舊m3b的「五個獨立拜入」斷言同步為五宗選擇下的單一立誓與原Era資格。合計8支不同相關runner通過。最後UI小修僅補 `-Only 'sect_life_ui_runner'` →24 checks PASS，日誌 `dao2_runners_26d67295f4d146d88c051cbdf63baad0`。範圍含唯讀渲染／信號、凍結零貢獻、分支文字、原三頁、保存鎖定、焦點、固定動作與從記錄返回選宗的圖像、換世清除暫態回應；不是全量回歸。各輪stdout／stderr依[LOGS]所列暫存路徑；`.test-output/`保留隔離產物。沙箱user:// log寫入診斷、既有anchor警告有記錄，不宣稱零診斷。
- **桌面瀏覽器**：`--headless --path . --export-release SectReformUiReview build/sect-reform-ui-review/index.html`與`node tools/prepare_web_compression.mjs build/sect-reform-ui-review`為本機測試更新，非候選包。Chrome兩個隔離origin 48527／48528；iframe CSS1280×720、DPR約1，合成金丹會員與築基未入宗資料，未覆寫正常玩家進度。實際滑鼠讀故事B、拒寫→保存保護→恢復／重試，10000→10001貢獻、沈交情0→4、chapter_mask1／book=order，重載仍保留；記錄頁顯示B回應。五宗切換、太虛山門／天劍宗印、比較內捲與固定拜入動作已觀察。證據 `.test-output/sect-life-browser/`。沙箱內server無法被Chrome連線後，改正常授權loopback服務；未繞過瀏覽器安全警告。這是桌面實際輸入／重載證據，不代表自然完整六章節奏。
- **交付檢查**：最後局部Web匯出／壓縮exit0；`python tools/subset_game_fonts.py --check`、四圖原稿／runtime hash核對、`git diff --check`及 `python tools/delivery_check.py --web build/sect-reform-ui-review` 均通過（7/7壓縮manifest，受保護證據變更0），摘要在 `.test-output/sect-life-delivery.log`。最終Chrome重載可讀上次回應、唐溪禾E2立繪／三選項與太虛山門；圖為 `fellows-final.png`、`gate.png`與 `records.png`。桌面console warn/error查詢空；viewport override已重設，隔離分頁已關閉。一般 `build/web` 未同步，不引用其舊包為本輪證據。
- **界線與下一步**：此為有界UI階段；大比、其餘四宗15人30事件、可選霧光／裁切頭像仍留後續，不把完整SECT-LIFE或ART全範圍結案。未跑L3／全尺寸／效能重測；實機依使用者政策延期，非當前阻擋。下一步New Chat收UI視覺回饋或接SECT-LIFE-TOURNAMENT。可手動commit（UI階段結束，非大型任務結束）；代理未commit／push。


<a id="sect-life-art-ui-r1"></a>
## 2026-11-05 SECT-LIFE-ART-UI-R1（太虛四圖美術已接受；正式UI待完成）

- **使用者美術接受（2026-11-05追加）**：使用者明確回覆「美術 接受」，太虛山門及沈照微／陸景行／唐溪禾四張原圖已接受，manifest改為ACCEPTED並註明範圍。此接受不提升UI布局、瀏覽器互動或正式Godot接入的驗證狀態；下方首稿交付時的待審閱描述保留為歷史。下一步New Chat接正式Godot山門／同門UI與必要衍生資產，不重生已接受原圖、不提前擴其餘四宗。本次僅metadata／文件更新，原圖SHA256四份核對通過，`git diff --check`與通用`delivery_check.py`通過；不跑遊戲runner或匯出。可手動commit（美術接受checkpoint，非大型任務結束）；代理未commit／push。
- **範圍與審閱邊界**：使用者指定「ART／UI」，承接CORE階段；依docs51第7、8節「新人物名字、山門與人物畫風先交使用者審閱」，交付太虛一宗山門、沈照微／陸景行／唐溪禾三位成年同門與可操作的[UI審閱稿](sect-life/art-v1/review.html)。這是ART／UI首稿checkpoint，不把正式ART／UI或整個SECT-LIFE標DONE；沒有變動遊戲規則、保存或正式Godot接線。現有未提交ENTRY／CORE／DESIGN／字型成果保留。
- **美術產物**：新增`docs/sect-life/art-v1/originals/`四PNG，built-in image_gen分別生成，無外部參考圖；山門1672×941 RGB，沈／陸各1086×1448 RGBA，唐1081×1455 RGBA，三人alpha extrema均0～255。`prompts/`保留四份完整提示詞，`manifest.json`記錄日期、工具、用途、原圖hash、大小、切層及授權界線，acceptance=PENDING_USER_REVIEW。原圖直接複製，沒有修畫／裁切／縮製；人物透明層與介面文字獨立，山門現為靜態主景，前霧／光及正式頭像衍生圖待首稿接受後製作。沒有新洞府地標，也未以整景圖替代互動世界。
- **UI審閱工具**：新增`review.html`、`review-content.js`及README；沿共同紙面、黑體、青玉選中／細金線及唯一叉號的方向。五宗可切換，僅太虛有新山門；三人可切各自兩章，A／B／婉拒示範回應，最近四次點選留在記憶體，叉號／Escape收卷後可重開。高度不足設計為人物頭像及正文內捲，動作CSS最小44px；直式旋轉提示。標題／正文／基礎選項／回應從現有SectLifeContent revision1抽出，示例報酬不替代正式pending_story凍結報酬，後三章不假裝帶入前章旗標；沒有宗齡或結算實作。HTML只作開發審閱工具；正式UI仍需Godot容器、共用元件、Session命令／View及保存重試接入。
- **命令與驗證**：本機Godot `--version`=4.7.2.stable.official.ed1daf0bf。Python／Pillow驗四張PNG解碼、manifest SHA256、三張透明alpha；`node --check`驗內嵌腳本與review-content.js通過，本地圖片／字型／紙面路徑與五宗既有圖存在檢查通過。首輪靜態檢查發現相對資源路徑多退一層，已修正後重跑PASS，原失敗不計通過。純美術／審閱工具，無L1／L2／L3遊戲runner、Godot import、Web匯出或候選包；不因新對話重跑前輪核心測試。
- **未通過／瀏覽器限制**：使用computer-use技能並以Browser Use開`file:///E:/WORK/Dao2/docs/sect-life/art-v1/review.html`遭政策拒絕：僅允許HTTP／HTTPS，未授予file協定存取；已停止，沒有以其他操作路徑規避。**桌面實際畫面、滑鼠、焦點、短橫式布局均未驗證**，不能把CSS或語法檢查當作L2桌面證據；未捏造截圖。使用者可直接開本地HTML審閱，步驟見該目錄README。
- **交付與下一步**：`git diff --check` exit0、通用`python tools/delivery_check.py` RESULT PASS，受保護證據變更0；本輪新增文件UTF-8／本地連結檢查PASS；不對待接受manifest使用要求ACCEPTED的交付選項。先收使用者對四張圖與圖文比例回饋；接受後用New Chat完成ART衍生資產與正式Godot同門／山門UI、通知／記錄、原三頁及保存保護，跑相依L1／L2與桌面1280×720抽驗；TOURNAMENT／CONTENT依原順序，整批CLOSE才L3。**可手動commit：這是首稿階段checkpoint，非ART／UI或SECT-LIFE大型任務結束；代理未commit／push。**

<a id="sect-life-core"></a>
## 2026-11-05 SECT-LIFE-CORE（CORE-1／CORE-SAVE 階段DONE，L1／L2）

- **範圍／結果**：承接ENTRY與設計基線，實作太虛三同門、六個一次性章節與三種日常回訪；每章A／B／婉拒，後章按既有選擇或婉拒提供對應文字。宗齡只累計入宗後正式接受tick（60秒一祀），固定章優先、單一待決槽，未讀不覆寫、不補離線事件佇列、不代選／代領。日常於E6完成後180／240／300秒等機率排程，三模板等機率；故事RNG與預留的大比RNG域分離，不消耗原派遣流。好感0～100；每600宗齡秒epoch預留最多12故事貢獻，每件最多2，生成時凍結、婉拒不退預留、跨epoch不更換已承諾獎勵。故事不計委託領取、傳承有效世或守護獸保底；全為v2新增，不宣稱DAO1 parity。
- **時間／本世邊界**：TimeAdvancer有效生產與年歲only路徑接同一helper；有life的離線回共用逐秒路徑，未另做跳步公式。0tick不改狀態，壽盡最後接受秒累計宗齡但不生成事件，壽盡不可選；宗齡與serial有界不回繞。輪迴清好感、章旗、待決與宗齡，保留五宗小型memories／best_ranks；再入宗重新建立當世NPC與域分離種子。其他四宗只累宗齡，未捏造其生活內容；大比資料／操作尚未實作。
- **保存／遷移**：新增sect_version=4、schema7、rules `core-flow-27-sect-life-1`、content `+sect-life-1`與內部life/content/rng revision1；舊schema2～6仍讀取，舊sect版本不可夾帶life。保留原宗門改版版本組與能力，啟動時在其成功提交後另做生活候選遷移，原文按hash歸檔、精確讀回才替換權威。舊入宗宗齡從0，不從年歲推算；既有entry收據完整保留，缺收據才建立legacy_review，已派遣可作證、未知first_claim不推算。**實作對設計鍵集的收斂**：`sect.entry`繼續是唯一onboarding權威，SectLife直接讀SectEntry.receipt，不重複保存`life.onboarding`，避免ENTRY／CORE兩份旗標分歧。resolve_sect_story經Session白名單、revision／command_id、SectReformSave候選交易；固定選項報酬讀回重算、舊instance拒絕、拒寫／遺失回應重試不重抽、不重獎，損壞最新代回上一個合法代。未知內容revision拒讀並沿既有復原，不套新報酬。
- **32KB證據／界線**：固定life鍵數、三NPC、六旗標、四recent、五宗meta、單槽凍結選項；life≤8192 bytes、整塊sect仍≤32768。Godot UTF-8 JSON合成「四份合法舊委託（各128-byte ID／128-byte名稱／1024-byte說明／8報酬）＋全功法／坊市＋全守護獸許可／舊許可＋滿好感／六旗／五宗meta／四recent／待決」為 **sect9357、life1327 bytes**，完整encode／decode通過。此為明列欄位的有界合成量測，不宣稱每個任意舊擴充字典皆有相同大小。另以接近舊32KB上限的合法擴充字典驗證：超過合併容量時不截斷／刪舊資料、不升版，startup回`life_unavailable=SECT_SIZE`，舊玩法保持可用，沒有卡住的候選交易。
- **修改檔案**：新增`src/simulation/sect_life.gd`、`sect_life_content.gd`、`src/persistence/sect_life_save.gd`及Godot.uid；新增`tests/sect_life_core_runner.gd`、`sect_life_save_runner.gd`及.uid。修改game_session、command_processor、sect_system、time_advancer、offline_closed_form、save_codec、save_manager、sect_save_contract、sect_reform_release／save、living_abode啟動接線與runner清單；既有release測試的未來schema由硬編7改為`LIFE_SCHEMA_VERSION+1`。README／ROADMAP僅一行連結，此處為結案文字；docs51追加實作對應，updata英文checkpoint／5筆保留與歸檔。開工前ENTRY／PLAN／DESIGN及字型等未提交成果保留，未commit／push。
- **命令／實際驗證**：引擎`--version`確認 **4.7.2.stable.official.ed1daf0bf**。import初輪發現新增Session字典語法問題，修正後CLI編譯／runner成功；初版新runner的型別推導、整份JSON位元組相等斷言亦已修正，失敗／timeout未算通過。每次先`-Only ... -List`核對。L1最初entry／core／save重跑3/3 PASS。因本次改共用保存及時間，L2納入其依賴、超過5支但不擴全量：`tools/run_all_runners.ps1 -Only 'sect_life_core_runner.gd,sect_life_save_runner.gd,sect_life_entry_runner.gd,sect_reform_release_runner.gd,sect_reform_save_runner.gd,sect_reform_lineage_runner.gd,m1b_time_runner.gd,m3a_reincarnation_runner.gd' -Parallel 3 -TimeoutSeconds 90` → **8/8 PASS，matrix=single，exit0**；core51／save39／既有release750 checks。摘要`.test-output/sect-life-l2-final.log`，完整stdout／stderr留存`.test-output/sect-life-l2-logs/`，原[LOGS]目錄`dao2_runners_5012481699c349c6982d8dcde94a5f0c`。
- **長對照與失敗記錄**：`offline_closed_form_parity_runner.gd`既有48h逐秒參考測試90秒timeout，未算成功；確認其172800秒雙路徑內容後只對該支延長，`tools/run_all_runners.ps1 -Only 'offline_closed_form_parity_runner.gd' -TimeoutSeconds 300` → **1/1 PASS，100.4秒，exit0**。摘要`.test-output/sect-life-offline-long.log`，完整日誌`.test-output/sect-life-offline-logs/`。原L1語法／測試失敗見`sect-life-l1.log`、修正後3/3見`sect-life-l1-r2.log`；新增schema7後舊測試誤視為future的兩項失敗見`sect-life-l2-dependencies.log`，已改用8並由最終750 checks確認；中間保存斷言修正見`sect-life-core-save-final.log`。本輪合計**9支不同領域runner通過**，不稱全量回歸。
- **交付／邊界**：`git diff --check` exit0；`python tools/delivery_check.py` RESULT PASS，受保護`docs/verification/artifacts`／`src/verification`變更0；runner輸出隔離`.test-output/`。未修改正式介面布局／字型資產，無Web匯出、候選包、瀏覽器、FPS或自然等待驗收宣稱；新內容目前供核心View／命令使用，正式同門頁、通知／記錄閱讀及美術待ART／UI。觸控／實機依指示延期，非當前阻擋。人物名字仍沿設計候選；本輪沒有生成美術。
- **下一任務／checkpoint**：CORE-1／CORE-SAVE階段結束，整體SECT-LIFE未結案；請New Chat接ART太虛山門／三同門風格審閱，再接UI同紙面／同門操作與L2桌面抽驗，之後TOURNAMENT／CONTENT，整體CLOSE才一次L3。本輪不開下一大型階段。**可手動commit：這是CORE階段結束，非整個SECT-LIFE大型任務結束；代理未commit／push。**

<a id="sect-life-entry"></a>
## 2026-11-05 SECT-LIFE-ENTRY（入口階段DONE，L1／L2）

- **範圍／行為**：依使用者指定ID實作DESIGN入口。首世Era1隱藏宗門分頁、情境入口及通知，核心仍拒絕入宗；Era2保留手動拜山，首批供給完成後於既有F6動作顯示「山門訪帖」，使用完成旗標、不以庫存／開頁推算。返世可Era1入宗；無供給歷史的舊檔不強迫補做。邀請採安靜入口，不主動跳頁；稍後、離開宗門或CloseSeal返回會經Session記錄已讀，重載不反覆邀請，手動入口保留。
- **導覽與舊檔**：新入宗可見禮或略過；推薦當前合資格最短委託，仍由玩家按派遣，沒有任務時保留正常刷新／冷卻。只有成功派遣／成功領取寫首次旗標，首報介紹現有50貢獻坊市用途及成本，不強迫購買。既有已入宗無新收據者顯示無獎回顧，已有派遣可作證、未知首次領獎不臆測。略過不代派遣、不解故事、不領獎、不擋金丹，輪迴清收據。原歷練／秘術／坊市與保存回饋保持。E1同門首遇仍屬CORE，本輪無NPC／故事／宗齡實作。
- **入口保存子契約**：`sect.entry.version=1`固定六bool／七鍵，僅入口收據；缺欄位唯讀推導舊檔回顧，不靠讀頁遷移。新`ack_sect_entry`加入GameSession、CommandProcessor及SectReformSave交易白名單；沿原command_id去重、候選提交／精確讀回／拒寫重試與上一代恢復。SectSaveContract驗證鍵數／bool／首次領取前必有派遣；沿既有32768 bytes整塊上限。現有schema6／sect3／rules26及經濟內容不變，這是有內部版本的選填教學收據擴充；不將它冒充完整life／CORE-SAVE。後續CORE需明確把entry收據接至life.onboarding，保留已讀／略過／成功歷史，仍先證明滿載life與舊四任務的32KB契約再啟用新生活資料。
- **修改檔案**：新增`src/simulation/sect_entry.gd`及Godot生成.uid、`tests/sect_life_entry_runner.gd`及.uid、`tools/sect_life_entry_review.html`；修改sect_system、game_session、command_processor、sect_save_contract、sect_reform_save、FeatureUnlocks、HUD／modal manager／feature_navigation／sect_panel、兩既有入口測試與runner清單。既有`sect_reform_ui_review.gd`僅加`?entry=1`隔離新成員教學fixture，不改一般遊戲啟動；原namespace加獨立origin防止覆寫玩家進度。新增文字以原工具重建runtime雙字型與manifest，來源TTF及授權未動。文件／updata與必要歸檔更新，保留開始時已有DESIGN／PLAN未提交工作。
- **L1／L2命令與結果**：引擎`--version`=4.7.2.stable.official.ed1daf0bf；`--headless --path . --editor --import` exit0（有既存user://診斷，非互動證據）。每次執行前先`-Only ... -List`。首輪選entry／sect_reform_save／hub_onboarding／feature_navigation／uix_r1_components：其餘4支PASS；entry初版測試API參數／合成返世次序／儲存目標槽錯誤已修正，曾exit1與timeout，未算成功。最終`tools/run_all_runners.ps1 -Only 'sect_life_entry_runner.gd,sect_reform_ui_runner.gd,m3b_sect_runner.gd,m3b_sect_ui_runner.gd'` **4/4 PASS、exit0、單尺寸**；專項38 checks涵蓋三路、旗標供給、正常首報、不送獎、重載／去重、拒寫候選重試與損壞回上一代。最終日誌目錄`dao2_runners_14829852ad314560b75e502937180b59`，輸出均隔離`.test-output/`，guard無受保護證據變更。合計8支不同受影響runner通過，非全量回歸／非L3。
- **L2桌面Web**：本次來源以`--export-release SectReformUiReview build/web-sect-life-entry/index.html`及`node tools/prepare_web_compression.mjs build/web-sect-life-entry` exit0；僅局部測試包，未更新一般build/web、未交付候選包。`Copy-Item tools/sect_life_entry_review.html build/web-sect-life-entry/review.html`是測試launcher產製，未手改匯出來源。Chrome獨立origin `http://127.0.0.1:48516/review.html`，1280×720 iframe：真實滑鼠見禮（revision7→8）、推薦派遣（→9、修補山門法陣120s）、略過（→10）、秘術分頁與實際reload通過；重載沿自然離線時間保留派遣及略過，不重播教學、不代領。這是合成已入宗／有資源fixture抽驗，不宣稱自然首世全程或Web首報通關。截圖`.test-output/sect-life-entry-browser.png`。初次沙箱server不可達，改用正常提權本機server後成功，並非瀏覽器功能故障。
- **靜態交付**：`python tools/subset_game_fonts.py --check`初次發現缺字，已以無參數工具重建，複驗PASS；`python tools/trim_status_docs.py`完成README／ROADMAP舊段歸檔；`git diff --check` exit0；`python tools/delivery_check.py --web build/web-sect-life-entry` RESULT PASS、7/7包雜湊相符、受保護證據變更0。沒有新圖形資產或新共用UI樣式，沿既有同紙面、GameTab、CloseSeal、44px與內捲。
- **下一任務／checkpoint**：ENTRY階段結束，整體SECT-LIFE尚未完成。下一New Chat接`SECT-LIFE-CORE`的CORE-1及CORE-SAVE（先太虛三同門六章，生活資料正式落盤前完成保存容量與遷移），人物／山門另依ART審閱。本輪不開下一大型任務。可手動commit（階段結束）；代理未commit／push。

<a id="sect-life-design"></a>
## 2026-11-05 SECT-LIFE-DESIGN（設計階段DONE，正式實作未開始）

- **授權／範圍**：使用者指定`SECT-LIFE-DESIGN`，依前輪推薦方向推進；交付[設計基線](51-sect-life-design.md)及[算表](sect-life/design-v1-tables.md)。太虛三位成年同門沈照微／陸景行／唐溪禾、六章A/B／婉拒及三種短回訪；兩段章節記憶、入口／序章狀態機、8席三段大比精確評分／同分與收益表、最小保存鍵集／遷移及美術布局／提示詞草案齊備。名字／視覺仍為可審閱候選，未生成資產。
- **數值結論**：來源普通委託60秒15～30貢獻，不隨Era增加；設計採600秒故事預留最多12＋大比最多18=30，為普通連續派遣理論下界150的20%。日常縮小為0～2貢獻，無材料／壽元／永久倍率；延後領取可集中現金流，20%僅為生成epoch長期界線。大比依當世有效功法與level凍結基準，對手不隨玩家同步抬升；648組策略顯示入門6～8、中段2～7、充分準備1～2名，不宣稱自然勝率。
- **保存界線**：life內部版本候選1，正式schema／sect版號待CORE依當時來源分配。life合成寬欄位JSON3979 bytes（預算8192）；既有22528＋life8192＋餘量2048=32768僅為准入預算。既有四委託＋全功法／獸許可＋正式life的Godot合併上界尚未驗證，明列CORE-SAVE門檻，不能稱保存相容已通過。離線年歲only、壽盡／輪迴、候選拒寫重試、舊檔未知歷史與去重均有設計。
- **修改檔案**：新增docs/51、docs/sect-life/design-v1-tables.md、tools/sect_life_design_model.py；docs/50補後續設計入口，README／ROADMAP一行狀態；本狀態、updata及必要歸檔。未改src／content／tests、存檔或正式UI；docs/19沿用既有通則，未另立新樣式。
- **驗證**：`python tools/sect_life_design_model.py` PASS（來源假設、收益界線、648評分組合、同分／對手偏移檢查及合成容量）；本機Godot `--version`=4.7.2.stable.official.ed1daf0bf。9份變更文件／工具嚴格UTF-8及行尾空白、PLAN／DESIGN／算表21個本地連結、updata最新5筆檢查PASS；`python tools/trim_status_docs.py`全部無須再裁切；`python tools/delivery_check.py` RESULT PASS、受保護證據變更0。首次`git diff --check`發現updata檔尾多空行，已移除並重跑exit0。純設計驗證，未跑L1／L2／L3遊戲runner、Web匯出或瀏覽器；不使用歷史遊戲測試替新玩法放行。
- **下一任務**：`SECT-LIFE-ENTRY`，先首世／返世／舊已入宗三路與可延後邀請；CORE-SAVE需在新生活資料正式落盤前完成。人物／山門美術另依ART審閱；正式實作等待下一任務指示。本段主動checkpoint，下一大型實作用New Chat。可手動commit，屬設計階段結束，整體SECT-LIFE尚未完成；代理未commit／push。

<a id="sect-life-plan"></a>
## 2026-11-05 SECT-LIFE-PLAN：宗門Era2揭露、同門生活、大比與山門美術（規劃DONE，實作待核定）

- **使用者要求**：評估宗門延至Era2開放並加入引導，依隨機／年份觸發同門互動、選擇獎勵及宗門大比名次，選宗畫面更華麗。交付 [完整提案](50-sect-life-onboarding-and-events-plan.md)，沒有改正式玩法、數值、玩家存檔或資產。
- **來源核對**：`FeatureUnlocks.check("sect")` 首世Era1是PREVIEW，Era2或已轉世為AVAILABLE；`SectSystem.UNLOCK_ERA=2`，實際拜入亦允許reincarnation_count≥1。目前並非首世練氣即可真正拜宗，問題是預覽揭露太早／缺乏完整入宗體驗。`Onboarding`已有F6可選支線，但主要只提示加入並派遣，沒有本案所述生活事件／大比。`Lifespan`目前1祀=60模擬秒；不能用現實年份安排宗門事件。
- **推薦方向，待核定**：首世Era1隱藏、Era2揭露，邀請讓位於首批產業供給教學且不堵金丹；保留轉世熟手早入宗例外及既有已入宗存檔。固定序章＋宗齡章節＋低頻隨機事件，同門先做友情／競爭與兩段分支；先太虛三人六事件切片，再擴五宗15人30事件。大比先做同境界8人三段策略試煉，參與保底、前三名獎勵、確定性排名與一次領取，不預建完整戰鬥／多人系統。選宗為同紙面「五宗山門訪帖」，五宗宗印切換山門主圖、效果比較與單一立誓動作。
- **規劃包含**：初版時間／獎勵試算基準（均非最終核定數值）、選擇例子、離線待決槽與屆次去重、報名凍結參賽基準、NPC關係跨世邊界、既有32KB宗門存檔限制及版本化遷移／故障重試；ENTRY／CORE／ART／UI／TOURNAMENT／CONTENT／CLOSE相依與分級驗收。沿既有五宗／功法／傳承／守護獸，不把產業高階材料改成宗門獨占。
- **檔案／驗證邊界**：新增docs/50、此狀態、README／ROADMAP一行連結及updata／必要歸檔。純規劃，只做來源與文件靜態檢查、通用delivery_check；未執行遊戲runner、Web匯出或新美術生成，不把歷史L2當新方案證據。docs/19維持已核定UI通則，新美術方向只在提案中標示待審。
- **靜態結果**：新提案嚴格UTF-8、6個本地連結與行尾空白檢查PASS；`python tools/trim_status_docs.py` 完成README／ROADMAP最新3筆前言歸檔，updata維持5筆；`python tools/delivery_check.py` →RESULT PASS、受保護證據變更0；`git diff --check`相關文件exit0。無本輪遊戲驗收級別／玩法通過宣稱。
- **下一步**：先由使用者核定整體方向，再展開SECT-LIFE-DESIGN的人物／事件表、大比評分與獎勵試算；尚未授權正式玩法實作。新的大型實作請開New Chat。可手動commit：此為規劃階段結束，非宗門生活大型任務結案；代理未commit／push。

<a id="journey-ui-integrate"></a>
## 2026-11-05 JOURNEY-UI-INTEGRATE：宗門／機緣／天道決策同紙面（L1/L2，DONE）

- **需求／交付**：使用者回報遊歷只有人物完成整合，要求其他幾頁一併處理。將宗門、機緣、天道決策與人物列為共用 `JOURNEY_FOLIOS`，主分頁與當頁主體由同一工作台紙面管理；卷首只有一個CloseSeal。宗門／機緣子頁撤下自身外框與重複關閉，天道決策共用actions面板取消嵌入時的第二層紙；離開整合頁還原父節點與材質。局部修行HUD仍在卷首上方，沒有庫存需求時不留空白左欄；有需求時保留原庫存／資源抽屜。內部分頁、拜宗、委託／功法／坊市、機緣待決／抉擇簿、決策施行、保存失敗與重試及未開放條件保持。九界地圖預覽維持原場景呈現，不在本輪功能頁整合範圍。
- **修改檔案**：`src/presentation/ui_shell_policy.gd`（四頁共用清單）、`ui_shell_controller.gd`（工作台路由及局部HUD避讓）、`management_workbench.gd`（掛載／恢復、按需求顯示stock）、`sect_panel.gd`、`fortune_modal.gd`、`system_actions_panel.gd`（嵌入材質與關閉策略）；`tests/ui_shell_matrix_runner.gd`（同祖先、紙面、單一關閉、底部避讓斷言）；docs/19、此紀錄、README／ROADMAP一行連結與updata。未改規則、存檔、資產或其他內頁布局；保留開工前未提交工作。
- **L2領域驗證**：Godot `4.7.2.stable.official.ed1daf0bf`。先 `tools\run_all_runners.ps1 -Only 'sect_reform_ui,uix_r10_fortune_ui,uix_r11_decisions_ui,ui_shell_matrix,maid_ui_runner' -List` 核對5支，再同參數 `-TimeoutSeconds 90` →5/5 PASS（matrix=single）。涵蓋三頁操作／未開預覽、人物回歸與共用Shell資源／覆層／跨頁矩陣。記錄 `.test-output/journey-ui-integrate-l2.log`，stdout/stderr見 `[LOGS] C:/Users/asus/AppData/Local/Temp/dao2_runners_1b619eb929964aedafde8c5b09a47bd4`。非headless執行 `ui_shell_matrix_runner.gd` →653 checks PASS，1280×720原生截圖在 `.test-output/journey-ui-integrate-native/docs/verification/artifacts/ui-shell-2/`；包含已開放診斷fixture的宗門、待決機緣及決策，非真實玩家通關。

- **Web／交付檢查**：`--headless --path . --export-release Web build/web/index.html` 與 `node tools/prepare_web_compression.mjs build/web` exit0，一般Web同步，僅本機測試更新，非候選包／發佈。Chrome隔離origin `127.0.0.1:49189`、1280×720／DPR約1：真實滑鼠關摘要→遊歷人物→宗門→機緣→天道決策→卷首CloseSeal回洞府通過；三頁同紙面與禁用預覽狀態有截圖，未注入玩家進度或宣稱瀏覽器已完成全部玩法。截圖 `.test-output/journey-ui-integrate-browser/sect-1280x720.png`、`fortune-1280x720.png`、`decisions-1280x720.png`、`home-after-close.png`；console warn/error查詢空，viewport已還原、隔離分頁關閉。`python tools/delivery_check.py --web build/web` → RESULT PASS，7/7hash符合；相關來源／文件 `git diff --check` exit0，受保護tracked證據零變更，37個開工前既有未追蹤`.png.import`保持。
- **邊界／交接**：本輪L2五支runner、單一1280×720原生與桌面瀏覽器，未跑L3／全尺寸矩陣／效能／實機；既有RID／ObjectDB退出診斷保持，不宣稱零錯誤日誌。README／ROADMAP保留一行狀態連結，日期前言透過 `trim_status_docs.py` 歸檔；updata最新5筆外歸檔至 `docs/archive/updata-2026-11-05-journey-ui-integrate.txt`。下一步只收整合畫面的使用者回饋，新的大型工作請開New Chat。可手動commit：這是遊歷UI整合階段結束，非大型里程碑結案；代理未commit／push。

<a id="maid-guide-stable"></a>
## 2026-11-05 MAID-GUIDE-STABLE：外置氣泡與人物大小固定（L1/L2，DONE）

- **需求／交付**：使用者回報升級提示讓仙侍忽大忽小，要求外置氣泡、避免遮蓋及可關閉。`maid_stand_display.gd` 將氣泡從人物VBox移出，人物圖、狀態與人物頁操作不再隨氣泡顯隱重新分配。經營在邏輯寬度≥1600／高度≥600時，左側固定增留312px氣泡欄（300＋12間距）；關閉不回收欄寬。洞府使用左側安全空間，候選矩形須避開完整工作台、HUD、庫存、詳情、訊息、設定、底部入口；沒有安全空間時不顯示自動氣泡、不消耗提醒額度。取消仙侍整面板跨卡片的長TIP，姓名／狀態／動作TIP保持。
- **手動／關閉**：空間不足（含1280經營）時，「引」開共用Shell遮罩閱讀區，保留目標、詳情與自動提示開關；只有Shell單一關閉入口。外置氣泡的「×」收起且本步不再自動提醒，下一目標才恢復資格；取消自動提示則整次執行靜默，手動仍可讀。手動閱讀清除待播並重設間隔，避免點目標後立即重播；7秒／50秒／同一步兩次上限保持。沒有改遊戲規則、玩家存檔、角色選擇偏好或資產。
- **修改範圍**：`src/presentation/maid_stand_display.gd`、`maid_guidance_dock.gd`（外置呈現／Shell閱讀host／顯式詳情覆層／關閉去重）、`tests/maid_guidance_dock_runner.gd`；docs/19、此狀態、README／ROADMAP一行連結及updata。保留開工前未提交成果。
- **L1／L2**：Godot `4.7.2.stable.official.ed1daf0bf`；每組先 `-Only ... -List`。首組 `tools\run_all_runners.ps1 -Only 'maid_guidance_dock,maid_stand,ui_shell_integration' -TimeoutSeconds 90`：stand／integration PASS，dock因改用洞府驗證外置提醒後的覆層斷言及手動待播重現而FAIL，未算通過。修正詳情走顯式messages覆層與手動清待播後，`-Only 'maid_guidance_dock,m2d_responsive_ui,ui_shell_matrix' -TimeoutSeconds 90` →3/3 PASS（dock37 checks），matrix=single；合計受影響5支runner。日誌首輪 `.test-output/dao2_runners_1d924a42b8ae4b30bb61fa7bdc1a7bad`，最後 `.test-output/maid-guide-stable-l2.log`／`dao2_runners_e5165c2bf67c4a08924fb1fd6897f14e`；中間headless重現紀錄 `.test-output/maid-guide-stable-rerun.log` 保留，不以native成功掩蓋headless失敗。
- **布局證據**：native `--path . --resolution 1280x720 --script res://tests/maid_guidance_dock_runner.gd -- --maid-bubble-wide` →41 checks PASS；該指定診斷額外檢查1920×1080使用者截圖相關的寬式專用欄，不是全尺寸矩陣。截圖於 `.test-output/maid-guide-stable-native/maid-guide/`。同一人物圖global rect在出現、到期、手動關閉、閱讀覆層返回前後完全一致；寬式氣泡不與整張工作台或仙侍面板相交；1280經營不自動蓋卡片。這組native在最後僅清手動待播的修正前產出，證明布局；最終待播契約由上述headless37檢查確認。

- **Web／交付**：最終來源 `--export-release Web build/web/index.html`、`node tools/prepare_web_compression.mjs build/web` exit0，一般Web同步；僅本機局部測試更新，非發佈／候選包。Chrome隔離origin `127.0.0.1:49188`，1280×720滑鼠開經營→引→單一CloseSeal關閱讀區通過。追加1920×720有額外橫向空間的抽驗：引打開左側獨立氣泡→外置×收起，人物與工作台保持原大小及位置，氣泡不蓋工作台；1920×1080雖CSS較大，但Godot保持1280×720邏輯縮放，不誤記為已達外置欄條件。Web證據於 `.test-output/maid-guide-stable-browser/reader-1280x720.png`、`wide-before.png`、`wide-outside.png`、`wide-after.png`。`python tools/delivery_check.py --web build/web` → RESULT PASS，7/7檔案hash符合；相關來源／文件diff-check exit0，受保護tracked證據零變更，37個既存未追蹤`.png.import`保持。updata最新5筆外歸檔至 `docs/archive/updata-2026-11-05-maid-guide-stable.txt`，README／ROADMAP前言由 `trim_status_docs.py` 保留最新3筆。
- **邊界／下一步**：L1／L2相關5支runner與有理由的單一寬式布局抽驗，未跑L3／全尺寸矩陣／長效能或實機。既有Font RID／CanvasItem／ObjectDB退出診斷與沙箱log寫入錯誤保留，不宣稱零錯誤日誌。下一步只收使用者對外置提示與空間不足時手動閱讀的回饋；下一大型工作請開New Chat。可手動commit：這是仙侍提示修正階段結束，非大型里程碑結案，代理未commit／push。

<a id="maid-ui-integrate"></a>
## 2026-11-05 MAID-UI-INTEGRATE：人物頁同紙面與直排書籤（L1/L2，DONE）

- **使用者要求／交付**：參考建造清單，將人物頁外層遊歷分頁與主體整合；內層「人物／初遇／職掌／羈絆」改共用ArrowBookmarkTab左側直排，角色選擇集中於人物標題旁。主分頁仍橫向、內頁書籤縱向，兩層有明確方向與位置；卷首共用CloseSeal，撤下人物自己的第二層紙底。敘事頁不放庫存／空白個人卡左欄，局部HUD仍位於整張紙上方。短高度時書籤欄內捲跟隨焦點，人物正文與原有內捲保持。
- **修改檔案**：`src/presentation/maid_character_panel.gd`（embedded呈現、共用直排書籤、內容容器與角色列）、`management_workbench.gd`（同紙面掛載與恢復、不為人物放stock）、`ui_shell_controller.gd`（characters納入整合、避讓局部HUD）、`tests/maid_ui_runner.gd`（新增5項布局斷言）；docs/19、此紀錄、README／ROADMAP與updata。未改角色美術、共用書籤繪圖、招募／職掌／羈絆規則、命令或存檔；保留開工前其他未提交成果。
- **L1／L2證據**：Godot版本 `4.7.2.stable.official.ed1daf0bf`。每組先以同selector `-List` 確認；`tools\run_all_runners.ps1 -Only 'maid_ui_runner,maid_ui2_runner,maid_bond_chapter,ui_shell_integration,maid_voice_runner' -TimeoutSeconds 90` →5/5 PASS；補上新布局斷言後 `-Only 'maid_ui_runner,ui_shell_matrix,maid_art_r2_runner' -TimeoutSeconds 90` →3/3 PASS，合計7支相關runner，matrix=single。日誌在 `.test-output/dao2_runners_08e643824adc4072a356ba598f31f004`、`dao2_runners_56272bc852e84703ac2aecda8e22486e`；各輪stdout/stderr見[LOGS]指定路徑。非headless執行maid_ui_runner →58 checks PASS，截圖於 `.test-output/maid-ui-integrate-native/maid-ui/`；人物頁主分頁與內容同祖先、單一外紙、無stock、共用書籤、書籤在內容左側及上到下順序已驗證。

- **Web／交付檢查**：本輪來源 `--headless --path . --export-release Web build/web/index.html` 與 `node tools/prepare_web_compression.mjs build/web` exit0，一般Web已同步；這是局部測試更新，非候選包／發佈。Chrome隔離origin `127.0.0.1:49187`、CSS 1280×720／DPR約1，實際滑鼠關閉摘要→遊歷人物→左側初遇／職掌→人物→完整立繪→Escape返回同一人物頁通過；主分頁、角色選擇、內頁書籤與內容保持同紙。截圖在 `.test-output/maid-ui-integrate-browser/`，`person-1280x720.png` 與 `person-return-1280x720.png` 為最終同版證據；console warn/error查詢空，已還原viewport並關閉隔離分頁。`python tools/delivery_check.py --web build/web` → RESULT PASS、7/7檔案hash符合；`git diff --check` 相關來源／文件exit0，受保護證據tracked diff空，37個開工前既有未追蹤`.png.import`保留。README／ROADMAP由 `python tools/trim_status_docs.py` 保留最新3筆前言；updata最新5筆以外歸檔至 `docs/archive/updata-2026-11-05-maid-ui-integrate.txt`。
- **邊界／下一步**：只執行相關L1／L2與1280×720桌面抽驗，未跑L3／全尺寸矩陣或實機；既有RID／ObjectDB退出診斷保持，不宣稱零錯誤日誌。沒有改動既有職掌表單本身、章節對話或規則／存檔。下一步收使用者對同紙面與書籤大小／位置的視覺回饋；後續大型工作使用New Chat。可手動commit：此為人物UI階段結束，非大型里程碑結案；代理未commit／push。

<a id="maid-guide-dock"></a>
## 2026-11-05 MAID-GUIDE-DOCK：經營仙侍陪伴與常駐引導氣泡（L1/L2，DONE）

- **範圍／相依**：使用者接受建築／經營頁保留仙侍、常駐引導圖印、間隔提醒的方案後要求執行；延續既有 MAID 侍立與前期引導，不另開規則或大型里程碑。
- **交付**：洞府與經營共用侍立；足夠寬高時為經營工作台預留252px陪伴欄（含12px間距），仙侍避讓設定與底部導覽。其餘收為頭像＋44px「引」圖印，加入原Shell入口容器；人物敘事及重要覆層維持原布局。嵌入建築頁撤下重複下一步長條。氣泡放真實目標／缺料摘要、查看目標、詳情、自動提示開關與共用CloseSeal；完整文案留TIP及既有訊息閱讀覆層，導航送呈現動作，不直接建造或改庫存。未招募時仍為純立繪展示，提示署名「修行指引」。
- **提醒契約**：新目標／就緒狀態先提示一次，7秒收起；同一步停留50秒再提示一次，上限兩次。刷新／換頁不重置計數；覆層、演出、設定選單及隱藏期間不累計、不補播；手動氣泡不自動消失。自動提示可取消，手動入口仍可用；此開關與計數只在本次執行有效，沒有新增玩家存檔欄位、規則或收益。
- **修改檔案**：`src/presentation/maid_guidance_dock.gd`（新增及引擎產生.uid）、`maid_stand_display.gd`、`building_catalog.gd`、`ui_shell_controller.gd`；`tests/maid_guidance_dock_runner.gd`（新增及.uid）、`maid_stand_runner.gd`、`m2d_responsive_ui_runner.gd`；`tools/run_all_runners.ps1`；docs/19、docs/49、此狀態、README／ROADMAP一行連結與updata。保留本輪開始前尚未提交的MAID-VOICE／書籤等工作，不回退、不代為commit。
- **L1／L2命令與結果**：Godot `--version` = `4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import` exit0。所有選取先用同參數 `-List` 核對。首組 `tools\run_all_runners.ps1 -Only 'maid_stand,maid_guidance_dock,ui_shell_integration,m2d_responsive_ui,gather_guidance_highlight' -TimeoutSeconds 90`：沙箱內舊runner的user://寫入失敗，integration／gather逾時，不算通過；正常授權執行後integration／gather通過，侍立／響應式舊布局斷言及建築embedded即時可見性問題已修正。補跑 `-Only 'maid_stand,maid_guidance_dock,m2d_responsive_ui'` →3/3 PASS（33／28 checks及responsive）；`-Only 'maid_guidance_voice,early16_ui_shell,ui_shell_matrix'` →3/3 PASS。合計受影響8支runner通過，matrix=single，未跑L3或全量。最後僅精簡氣泡文案後 `-Only 'maid_guidance_dock'` →1/1 PASS（28 checks）。日誌分別在 `.test-output/dao2_runners_ed69a1f6503d4c1ca2167759563727a9`、`dao2_runners_e37cc75b2437470c9baf0f79375611d1`、`dao2_runners_d1b87475ce784b4cae8b9be864e2feae`；stdout/stderr位置由各輪[LOGS]列出。
- **原生／桌面Web**：非headless執行同一dock runner →28 checks PASS，1280×720原生截圖於 `.test-output/maid-guide-native-final/maid-guide/`（這組在最後氣泡摘要文字精簡前，僅證明布局）。本輪來源局部匯出 `build/web-maid-guide` exit0，Chrome隔離origin `127.0.0.1:49186`、CSS 1280×720、DPR約1，真實滑鼠關摘要→經營→引圖印→取消自動提示→詳情閱讀；覆層隱藏仙侍並保留建築頁，刷新後以最終摘要版本補驗圖印／目標。最終截圖於 `.test-output/maid-guide-browser/management-guide-1280x720.png`。IAB與沙箱服務連線失敗，改用桌面Chrome與正常授權loopback服務完成，未繞過安全警告；瀏覽器控制台warn/error查詢空。一般Web包同步同版來源，僅本機測試更新，非候選包／發佈。
- **交付檢查**：一般Web `--export-release Web build/web/index.html`、`node tools/prepare_web_compression.mjs build/web` exit0；`python tools/trim_status_docs.py` 將README／ROADMAP超過最新3筆的前言歸檔；updata保留最新5筆，其餘存 `docs/archive/updata-2026-11-05-maid-guide-dock.txt`。`python tools/delivery_check.py --web build/web` → RESULT PASS，7/7來源／壓縮及音訊hash符合manifest。受保護證據目錄的37個既有未追蹤`.png.import`保持原樣，tracked diff為空；相關來源／文件 `git diff --check` exit0。
- **邊界／交接**：既有Font RID／CanvasItem／ObjectDB退出診斷與沙箱log寫入失敗保留；不宣稱零錯誤日誌。新runner驗證摘要缺料、提示期限／間隔／上限、手動入口、關閉自動提示、遮罩暫停、原頁恢復、目標導航與全快照零變更。既有受保護證據目錄未有tracked變更，開工前既存`.png.import`不列為本輪成果。未重做L3、效能或觸控實機（延期，非當前阻擋）。下一步只收使用者對陪伴欄與提示頻率的回饋；新大型工作請用New Chat。可手動commit：這是仙侍引導功能階段結束，非大型里程碑結案；代理未commit／push。

<a id="maid-voice"></a>
## 2026-11-04 MAID-VOICE：仙侍語音文案、第四章收束與新手引導侍女相伴（L1/L2，DONE）

- **任務背景**：使用者要求「針對目前侍女系統的文案以及相關互動內容再進行更多補充，另外將新手引導的對話也加入侍女的頭像，像侍女在引導你一樣」。以 fusion skill 分工：worker A 補仙侍文案與互動語音，worker B 給新手引導加侍女頭像與語音，orchestrator fuse 後統一引擎驗收。
- **第四章收束（規則層唯一變更）**：`MaidRules.CHAPTERS` 每位新增第四章——青蘅「燈影同行」（羈絆 90、職掌動作 20）、糯美子「以劍為盟」（90、15）、丹霞「同守一爐」（90、20）。首次職掌 10＋20＋30＋50＋90＝200，`同道`（200）首次可達；`BOND_LEVELS`、章節旗標鍵集、`maid_save_contract.gd`、`SCHEMA_VERSION` 全部不動，舊存檔向後相容。
- **互動語音**：`maid_character_panel.gd`（1364→1515 行）新增 `VOICE_LINES`（7 種命令 × 3 位＝21 句，≤22 字）、`GREETINGS`／`DUTY_GREETINGS`（各 4 句，依羈絆初識／相知／信任／同道分層）、`REUNION_LINES`（每位一句）、`static voice_line(kind, maid_id)`；人物頁新增分層問候列，章節列擴為 4 行並補 `BOND_SCRIPT *_4` 三份腳本，回憶 CG 按鈕隨最後一章移至第四章列。`feature_navigation._on_maid_action` 成功訊息改用角色語音（錯誤映射與自動初遇流程不變）。
- **引導相伴**：`abode_hud_controller.gd`（1423→1526 行）在訊息面板標題列加入青蘅 40×40 頭像與名籤（僅已招募且頭像載入成功時顯示）；`GUIDE_VOICE` 21 鍵（era1 八項、F1–F7、G1–G4、complete、legacy，≤30 字）在引導 key 變更時以 `青蘅：「…」` 推入訊息記錄（紫色 `6b4a7a`、去重）；`hint.text`／`hint_heading` 既有字串逐位元組不變。orchestrator 並攔截修正 `_speak_guidance_voice` 誤引用 `GUIDE_MID` 的解析錯誤。
- **修改檔案**：`src/simulation/maid_rules.gd`、`src/presentation/maid_character_panel.gd`、`src/presentation/feature_navigation.gd`、`src/presentation/abode_hud_controller.gd`、`tests/maid_bond_chapter_runner.gd`、`tests/maid_bond_cg_runner.gd`、`tests/maid_core_runner.gd`、`tests/maid_first_meeting_runner.gd`、新增 `tests/maid_voice_runner.gd`／`tests/maid_guidance_voice_runner.gd`、`tools/run_all_runners.ps1`、`docs/49`（新增 §19）、`docs/verification/maid-voice.md`、`docs/development-status.md`、`updata.txt`。未動 `maid_system.gd`、`maid_save_contract.gd`、`onboarding.gd`、`save_codec.gd`、美術、字型或 Web 匯出。
- **命令與結果（L1/L2，單一 1280×720）**：`Godot --headless --path . --import` → exit 0。`tools\run_all_runners.ps1 -Only 'maid,m2d_responsive,gather_guidance' -List` → 14 支（>5 依共用核心 `maid_rules.gd`／`abode_hud_controller.gd` 認定 L2 領域級）；首輪 `-TimeoutSeconds 120` → 11/14 PASS、3 FAIL（皆 runner 斷言側：回憶按壓點隨第四章移位、反射靜態旗標不可靠、引導 runner 誤觸直建路徑），無 SCRIPT ERROR；修 runner 後 `-Only 'maid_bond_chapter,maid_voice,maid_guidance_voice'` → 3/3 PASS。合併 14/14：MAID-UI 53、MAID-CORE 266、MAID-OFFLINE 62、MAID-UI2 62、MAID-DUTY-PRESET 34、MAID-FIRST-MEETING 27、MAID-ART-R2 78、MAID-BOND-CG 71、MAID-STAND 33、GATHER GUIDANCE HIGHLIGHT 11、M2-D responsive、MAID-BOND-CHAPTER 176、MAID-VOICE 248、MAID-GUIDANCE-VOICE 46 checks，failures 全空。
- **邊界／未驗證**：未跑 L3 全量、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）；第四章 200 同道僅由規則與 runner 證明，未走實機全流程；hub H1–H6 引導鍵靜默屬首波刻意範圍。招募成功文案改為角色語音屬呈現層 v2 變更，`maid_first_meeting_runner` 釘選已同步。
- **下一任務**：由使用者指定（docs/48 後續角色、下一里程碑，或先實機體驗新語音）。本階段為仙侍功能階段結束（非大型任務結案），可手動 commit；代理未 commit／push。

<a id="reincarnation-vertical-tabs"></a>
## 2026-11-02 REINCARNATION-VERTICAL-TABS：轉世次分頁改直立排列分隔 HUD 與內文（L1，DONE）

- **任務背景**：使用者指正轉世內容的二級分頁（轉世、天賦、歷世）應採用直立式排列（由上往下），作為左側 HUD 狀態欄與右側轉世內容本文之間的分隔書籤，解決原本橫置於上方與外層 HUD 分頁疊合的問題。
- **方案與實作（方案 B：垂直垂掛箭籤條）**：
  1. `src/presentation/components/arrow_bookmark_tab.gd`：維持垂直垂掛箭籤形態（底部倒三角箭頭 ▼，直排文字「轉\n世」、「天\n賦」）；尺寸調整為 46×58px（滿足 ≥44px 命中規範）；選中時籤條向右微探 3px、hover 時微探 1.5px，深青玉底描金線，未選中古宣紙墨線，具備立體抽拉層次感。
  2. `src/presentation/reincarnation_panel.gd`：重構內部佈局為水平結構 `_main_body_row`，左側為直立書籤欄 `_tab_row`（VBoxContainer，由上往下放置轉世、天賦、歷世），右側為 `_content_column`（包含頂部右對齊的題記列「道心／道證」與 `_body_scroll` 滾動本文），右側外緣繪製古籍書脊墨線；底部保留水平居中的操作列。
- **修改檔案**：`src/presentation/components/arrow_bookmark_tab.gd`、`src/presentation/reincarnation_panel.gd`、`updata.txt`、`docs/development-status.md`。
- **命令與結果（L1，1280×720）**：`tools\run_all_runners.ps1 -Only 'm3a_reincarnation_ui,content_p1_talents_ui,content_p2_talents_ui,ui_shell_integration,reincarnation_motion' -TimeoutSeconds 120` → 5/5 PASS（content_p2_talents_ui 9.9s、content_p1_talents_ui 8.5s、ui_shell_integration 9.1s、reincarnation_motion 2.0s、m3a_reincarnation_ui 8.2s，failures=`[]`，無 SCRIPT ERROR）。
- **Web 匯出更新**：已透過 Godot console 匯出更新至 `build/web/index.html`，並經 Brotli 壓縮處理完畢，提供使用者即時檢視。
- **未通過／未驗**：無 L2/L3、全尺寸矩陣、觸控或實機驗證（觸控依規範延期）。
- **下一任務**：由使用者確認畫面效果後指定下一步。本階段已完成，可手動 commit。

<a id="early-flow1d-supply-fix"></a>
## 2026-11-02 EARLY-FLOW1-D 現行 SUPPLY 檔突破與引導修復（L1，DONE）

- **任務**：使用者指定以 fusion skill 處理 EARLY-FLOW1-D。D 已於 2026-10-21 放行，但 2026-10-24 供給制啟用後出現「現行存檔無法築基→金丹」的真實回歸。
- **缺陷**：`src/simulation/command_processor.gd:237` 與 `src/application/game_session.gd:251` 僅接受 `res1-d-2`；現行存檔為 `res1-e-46-1`（hub 預設開啟），突破一律回 `DANXIA_ACTIVATION_REQUIRED`，HUD 亦顯示容量未足。舊 `early_flow1d_runner` 只用 `attach` 的 `res1-d-2` 路徑，因此維持綠燈而無法發現。
- **修改**：`src/simulation/island_progression.gd`（新增 `era3_extension_active()` 接受 D2／SUPPLY）、`src/simulation/command_processor.gd`、`src/application/game_session.gd`、`src/simulation/onboarding.gd`（era2 遷移檔路由、F7 晉階材料文案、G1 hub 丹霞產線與非 hub 丹霞目標）、新增 `tests/early_flow1d_hub_runner.gd`（48 checks）、`tools/run_all_runners.ps1` 註冊。未改 schema、存檔格式或經濟規則。
- **命令與結果（L1，1280×720）**：`tools\run_all_runners.ps1 -Only 'early_flow1d,early_flow1b,early_flow1c,early_v1c_skills,content_p1_accept' -TimeoutSeconds 600` → 6/6 PASS：content_p1_accept 119.7s、early_flow1b 23.2s、early_flow1c 32.9s、early_flow1d 108.0s、early_flow1d_hub 8.9s、early_v1c_skills 42.7s；無 SCRIPT ERROR。
- **獨立稽核**：fusion-auditor 靜態核對 diff，確認指令／View 閘門一致、舊 `res1-d-2` 不受影響、hub G1 產物回祖島；其指出 legacy era3 G1 使用 `active()` 的邊角，已改為 `era3_extension_active()`。剩餘：hub 開丹霞成本未逐項斷言、自然時間與裝置仍延期。
- **未通過／未驗**：無瀏覽器、自然時間、觸控、高 DPR、Web 匯出證據；本輪僅 headless L1。
- **下一任務**：由使用者選定（docs/48 下一角色或下一里程碑）；D 不再列為待續自然流程。此為功能階段，可手動 commit。

<a id="maid-parallel"></a>
## 2026-11-01 MAID-PARALLEL-1：多仙侍並行職掌（L1，DONE）

- **範圍／交付**：兌現 docs/49 §10「多仙侍並行職掌」。以使用者核定的「全面並行＋公平輪轉」解掉舊 `DUTY_BUSY` 全府鎖：三位仙侍可同時持有職掌，每位仍最多一個；重新指派只取代自己的職掌。不改羈絆、章節、獎勵、庫存、schema 或存檔格式，也不新增 persisted 欄位。
- **推進／公平性**：`MaidSystem.advance` 改為就緒者輪轉——先收集所有未暫停且非空的職掌並依 `ids.sort()` 排序，將共享 `remaining` 推進到最早到齊的冷卻，再從冷卻歸零者中挑「累計 `duty_actions` 最少、其次 id 較小」者執行一次，成功後重置自己的節奏。共享 `MAX_ACTIONS_PER_CALL` 不變，並行不放大單次結算收益；冷卻剛好在本次剩餘時間用完時歸零者仍會執行該次動作，維持與單一職掌相同的邊界語意。決定性只依 state＋content，無 RNG／系統時鐘／幀率相依。
- **產線／建築**：備料與煉丹若同時佔用同一條 home 產線，後到者沿用既有 `craft`／`refine_pill` 的 `JOB_BUSY` 記為 `BLOCKED`，於下一冷卻週期重試；不排隊、不搶佔、不改經濟 schema。監造走既有即時 `upgrade_building`，仍受可見、解鎖、資源、前置與等級上限檢查，可與產線職掌並行。
- **View／UI**：`get_view()["maid"]` 新增唯讀 `active_duties`（生效中仙侍 id，順序同 `MaidRules.MAIDS`），`active_duty` 保留為其第一個值供侍立展示與舊 UI 相容。職掌分頁「生效中」列改列全部值班仙侍並標註所選角色；`DUTY_BUSY` 文案改為「產線暫時忙碌，稍後會自動重試。」，指派成功改為「職掌已指派，將按時自動推進。」；指派按鈕不再因他人值班而停用。
- **修改檔案**：`src/simulation/maid_system.gd`、`src/presentation/maid_character_panel.gd`、`src/presentation/feature_navigation.gd`、`tests/maid_core_runner.gd`、`docs/49-maid-companion-system-design.md`（§2、§10、§11.2、§11.3、§11.10，新增 §18）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改 `maid_rules.gd`、`maid_save_contract.gd`、`save_codec.gd`、`save_manager.gd`、`SCHEMA_VERSION`、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_core,maid_duty_preset,maid_offline,maid_ui2,maid_stand' -TimeoutSeconds 90` → 5/5 PASS（MAID-CORE 266、MAID-DUTY-PRESET 34、MAID-OFFLINE PASS、MAID-UI2 62、MAID-STAND 33 checks，failures=`[]`，無 SCRIPT ERROR）；另以 `-Only 'maid_ui'` 補跑受影響的 `maid_ui_runner`、`maid_ui2_runner` → 2/2 PASS。新案例涵蓋三位同時指派、`active_duties` 三筆且 `active_duty == active_duties[0]`、暫停一位後剩兩筆、恢復不再被他人值班阻擋、60 秒共享 5 次預算下三位 `duty_actions` 皆 >0、契約有效；既有單一職掌推進、離線 `BLOCKED` 經濟案例與 UI「生效中：」斷言皆維持通過。
- **邊界／未驗證**：只跑 L1 單尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。公平性以「少服務者優先」的無狀態規則達成，未新增每輪輪值游標、佇列或經濟調度器；`active_duty` 的單值語意仍供侍立展示使用，未改為多值。可手動 commit：本次為仙侍職掌階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-duty-preset"></a>
## 2026-11-01 MAID-DUTY-PRESET：職掌預設組合、保留量 UI、材料不足提示細化（L1，DONE）

- **範圍／交付**：兌現 docs/49 §10「職掌預設組合、保留量 UI、材料不足提示細化」。`MaidRules` 新增 `DUTY_PRESETS`／`duty_presets(kind)`：管家備貨與丹藥補給各有常備（目標 5、保留 20%）、充裕（10、10%）、趕工（20、0%）三個確定性組合，監工為空；只作 UI 起點，不自動指派。職掌分頁新增 44px 預設按鈕列與逐材料「保留量」步進器（≥150×44），套用預設只改本機目標與 `floor(庫存 × 比例)` 保留值，不送命令、不寫狀態。
- **命令／讀取**：指派時 `assign_maid_duty` 的 `duty.reserve` 改由保留量步進器收集（>0 才寫入，鍵為資源／丹藥 id），管家備貨與丹藥補給皆適用，監工不受影響；命令型別、`GameSession._is_valid_shape` 與契約鍵集不變。`MaidSystem.get_view()` 的選項補上配方 `inputs`（`per_batch`、現有 `stock`）與丹藥 `cost`（`per_unit`、現有 `stock`）；既有職掌另附唯讀 `shortage`／`shortage_text`，以實際批次或預估批次挑出最吃緊輸入，文字如「低階靈草不足 60（需 60，現有 0，保留 40）」，無保留時省略保留子句。`shortage` 不落盤，`to_snapshot_dict()` 的 `maid` 區塊不含該鍵；`MaidSaveContract` 嚴格鍵集、`save_codec.gd` 與 `SCHEMA_VERSION` 均未更動。
- **UI 提示**：分頁在「尚無可用目標」以外，優先顯示已指派職掌的 `shortage_text`；尚未指派或剛調整目標／保留量時，以同一批次規則在本機預覽不足，材料足夠即隱藏。切換仙侍會清空保留量列並依新職掌重建；短橫式沿用既有堆疊規則，預設列與保留量列一併改為垂直排列，按鈕與步進器維持 44px 命中。
- **修改檔案**：`src/simulation/maid_rules.gd`、`src/simulation/maid_system.gd`、`src/presentation/maid_character_panel.gd`、`tests/maid_core_runner.gd`、`tests/maid_duty_preset_runner.gd`（新增，含 Godot import 產生的 `.gd.uid`）、`tools/run_all_runners.ps1`、`docs/49-maid-companion-system-design.md`（新增 §17）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改 `maid_save_contract.gd`、`save_codec.gd`、`save_manager.gd`、`SCHEMA_VERSION`、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_core,maid_duty_preset,maid_ui2'` → 3/3 PASS（MAID-CORE 251、MAID-DUTY-PRESET 34、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）。新案例涵蓋：預設組合常數與未知職掌、配方輸入／丹藥成本與現有庫存、三種職掌的 `shortage` 最吃緊輸入與保留量文字、存檔 JSON 不含 `shortage`、分頁預設列 3 顆 44px 按鈕、保留量三個 ≥150×44 步進器、常備套用後目標 5 與保留 40/40/400 且狀態零變更、指派負載帶非空 `reserve` 並落盤、材料不足時顯示含「不足／保留」的提示、補足後隱藏、監工不顯示預設與保留量、切換仙侍後重建，以及短橫式堆疊。
- **邊界／未驗證**：只跑 L1 單尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。不足提示為 View 即時計算，未新增離線報告欄位或新命令；材料足夠時不顯示「已足夠」等新文案。可手動 commit：本次為仙侍小功能階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-bond-chapter"></a>
## 2026-11-01 MAID-BOND-CHAPTER：羈絆章節對話分歧與已讀回放（L1，DONE）

- **範圍／交付**：兌現 docs/49 §10「羈絆章節對話分歧與已讀回放（仍不得改規則）」，在 MAID-BOND-CG 之後補上章節對話本身。`maid_character_panel.gd` 新增 `BOND_SCRIPT`：以既有九個章節 id 為鍵（每位仙侍三章），每章含兩行開場、兩個分歧選項、每個選項各有專屬回應，最後收束到共同結語；章節標題與 `MaidRules.CHAPTERS` 完全一致。已招募且該章已領取（沿用 `claim_chapter` 既有永久旗標，即已讀）時，章節列新增 44px「重溫」；未領取／未招募時隱藏。第三章同時保留既有「回憶」CG 入口。
- **分歧／純重播**：按下「重溫」只發 `chapter_requested(title, script)`，由 `maid_portrait_viewer.present_chapter()` 在共用 shell tool overlay 顯示純對話檢視器（隱藏立繪）：開場＋兩個 44px 分支按鈕，選定後只顯示該分支回應與共同結語，並提供 44px「重新閱讀」回到開場重選。分支選擇只存在本次檢視器內，不新增旗標、schema 或存檔欄位；不送命令、不發羈絆／獎勵、不重領章節，`to_snapshot_dict()` 在開場、選分支、重讀、關閉前後完全相同。一般立繪與 CG 回憶會隱藏分支區，`present_chapter` 也清空圖像，互不殘留。
- **修改檔案**：`src/presentation/maid_character_panel.gd`、`src/presentation/maid_portrait_viewer.gd`、`src/presentation/feature_navigation.gd`、`tests/maid_bond_chapter_runner.gd`（新增，含 Godot import 產生的 `.gd.uid`）、`tools/run_all_runners.ps1`、`docs/49-maid-companion-system-design.md`（新增 §16）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未動 `maid_rules.gd`、`maid_system.gd`、`maid_save_contract.gd`、`save_codec.gd`、`save_manager.gd`、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_bond_chapter,maid_bond_cg_runner,maid_ui_runner,maid_ui2_runner' -TimeoutSeconds 240` → 4/4 PASS（MAID-BOND-CHAPTER 138、MAID-BOND-CG 68、MAID-UI 53、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）。新案例涵蓋九份腳本的標題對齊、兩行開場、兩個相異選項、每分支專屬回應、共同結語、同角色章節不重複文案、未領取章節隱藏重溫、44px 命中、共用遮罩純對話檢視器、兩分支互不顯示對方內容、重新閱讀復原選項、第三章重溫與 CG 回憶並存、換仙侍後標題與文案跟隨，以及全程快照零變更。另跑受影響的 `maid_stand_runner`、`ui_shell_integration_runner` → 2/2 PASS（MAID-STAND 33、UI-SHELL-1 44 checks）。`python tools\delivery_check.py` → RESULT PASS（受保護證據零變更）。
- **邊界／驗證下限**：只跑 L1 單尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延後）。分支選擇刻意不持久化（「不得改規則」），「已讀」僅由既有章節領取旗標表示；未新增第二次獎勵或戰鬥／數值判定。可手動 commit：本次為仙侍小功能階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-display-pref"></a>
## 2026-11-01 MAID-DISPLAY-PREF：洞府侍立展示偏好跨存檔／輪迴（L1，DONE）

- **範圍／交付**：兌現 docs/48 §8「展示偏好跨世保留」，並補上 docs/49 §13 原本標為「未跨存檔／輪迴保存」的缺口。`state.maid` 巢狀區塊升為 `version = 2`，新增 `display: {expanded: bool, maid_id: String}`；`maid_id == ""` 表示自動跟隨當值職掌。`MaidSaveContract` 接受舊版 v1 並在 `normalize` 一律升級為 v2、補預設 `{expanded: true, maid_id: ""}`；v2 必須恰好三鍵，`display` 的鍵集、型別與非空角色 id 皆須合法，否則回 `MAID_DISPLAY` 由 `SaveCodec` 拒絕。最上層 `SCHEMA_VERSION` 維持 6，存檔外層格式不變。
- **命令／讀取**：新增 `set_maid_display`（payload `{expanded, maid_id}`，`maid_id` 可空），已加入 `KNOWN_COMMAND_TYPES`、`GameSession._is_valid_shape`、`CommandProcessor._apply`、`SectReformSave.COMMANDS`；只寫 `state.maid.version` 與 `display`，不動 `maids`、羈絆、章節、庫存或職掌，相同值為 no-op，未知角色回 `UNKNOWN_MAID`。`MaidSystem.get_view()["maid"]` 新增 `display`，`MaidSystem.display()` 對缺欄或損壞值回預設且不寫狀態。
- **UI／輪迴**：`maid_stand_display.refresh()` 讀取 `view.maid.display` 還原展開與手動選角；`cycle()`／`set_expanded()` 本地更新後送命令，成功即存檔並刷新 HUD，失敗由刷新回退。合成 view 無 `display` 時保留原「手動優先、否則跟隨當值」行為。`MaidSystem.on_reincarnate` 與 `ReincarnationRules.apply_reincarnation` 不碰 `display`，展開狀態與手動選角跨世保留。
- **修改檔案**：`src/persistence/maid_save_contract.gd`、`src/simulation/maid_system.gd`、`src/simulation/command_processor.gd`、`src/application/game_session.gd`、`src/persistence/sect_reform_save.gd`、`src/presentation/maid_stand_display.gd`、`tests/maid_core_runner.gd`、`tests/maid_stand_runner.gd`、`docs/49-maid-companion-system-design.md`（§5／§6／§7／§8／§13，新增 §15）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改 `save_codec.gd`、`save_manager.gd`、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_core,maid_stand,maid_ui_runner,maid_ui2_runner' -TimeoutSeconds 240` → 4/4 PASS（MAID-CORE 210、MAID-STAND 33、MAID-UI 53、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）。新案例涵蓋：v1→v2 遷移與預設值、`MAID_DISPLAY` 各類非法值、命令 no-op／未知角色／壞 payload、存檔編解碼往返保留 `display`、`on_reincarnate` 與完整 `apply_reincarnation` 後保留、洞府收合後磁碟存檔為 `{expanded: false, maid_id: "qingheng"}`、展開後 `expanded: true`、view 可還原展示狀態，且仙侍名冊（羈絆／章節／職掌）完全未變。`python tools\delivery_check.py` → RESULT PASS（受保護證據目錄變動 0）。
- **未驗證／下一步**：只跑 L1 單尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。舊存檔實際落盤遷移僅以 runner 內的 v1 合成存檔驗證，未以歷史存檔樣本重跑；`SCHEMA_VERSION` 未升版，跨版本回退（新版存檔給舊程式）不保證可讀。可手動 commit：本次為仙侍展示偏好階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-first-meeting"></a>
## 2026-11-01 MAID-FIRST-MEETING：招募成功後自動進入首次相遇（L1，DONE）

- **範圍／交付**：使用者要求「首次相遇自動觸發（目前只有人物頁的『初遇重溫』，未自動觸發）」，並選定「招募成功後自動播放」。人物頁新增 `play_first_meeting(maid_id)`：切到該仙侍、重設對話與捲動、進入初遇分頁並把焦點放在第一個選項；`feature_navigation._on_maid_action` 在 `recruit_maid` 命令成功且存檔成功後、刷新 View 之後呼叫，成功訊息「仙侍已入府。」在自動切頁後仍保留。未新增持久旗標、schema 或存檔格式：`recruit_maid` 本身一次性，重逢／輪迴不會重播。
- **邊界**：招募失敗、條件不足或存檔失敗時不切換；其他仙侍命令（指派／暫停／領章／重逢等）行為不變。自動播放入口只發呈現動作，不送新命令、不重複給獎；手動「初遇重溫」與「重新相遇」維持原樣。
- **修改檔案**：`src/presentation/maid_character_panel.gd`（新增 `play_first_meeting`）、`src/presentation/feature_navigation.gd`（招募成功後刷新並自動播放）、`tests/maid_first_meeting_runner.gd`（新增，含 Godot import 產生的 `.gd.uid`）、`tools/run_all_runners.ps1`、`docs/49-maid-companion-system-design.md`（§9）、`docs/development-status.md`、`updata.txt`。未改 `maid_system.gd`、`maid_save_contract.gd`、`save_codec.gd`、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_first_meeting,maid_ui_runner,maid_ui2_runner' -TimeoutSeconds 180` → 3/3 PASS（MAID-FIRST-MEETING 27、MAID-UI 53、MAID-UI2 62 checks，failures=`[]`，無 SCRIPT ERROR）；受影響的 `maid_art_r2_runner` 另跑 → PASS（78 checks）。新 runner 以空白存檔建茅屋、從羈絆分頁按招募，斷言：招募成功自動切到初遇分頁、選中該仙侍、`selected_reply == -1`、青蘅 `first-meeting.png` 與開場白正確、選項顯示且「重新相遇」隱藏、成功訊息保留；只允許 `maid`／`revision`／`command_receipts` 及刷新時既有的 `achievements`／`life_ledger` 記帳變動，其餘狀態切片不變；回覆→重播→回到人物頁的流程可逆且刷新不再改動狀態。`python tools\delivery_check.py` → RESULT PASS（受保護證據目錄變動 0）。
- **未驗證／下一步**：只跑 L1 單尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。緊湊版面沿用既有隱藏選擇列規則，未另做自動播放專用版面；未在 Web 包重跑招募流程。可手動 commit：本次為仙侍小功能階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-bond-cg-integration"></a>
## 2026-11-01 MAID-BOND-CG-INTEGRATION：三張羈絆終章 CG 接入回憶重播（L1，DONE）

- **範圍／交付**：依 [交接](handoffs/2026-11-01-maid-bond-cg-opencode.md)，把三張已接受的第三章羈絆終章 CG 接進人物頁羈絆分頁：青蘅「前世燈火」、糯美子「劍鳴舊世」、丹霞「丹心照夜」。每列章節新增「回憶」按鈕，僅在該角色已招募、第三章已領取且為最後一章時顯示；領取前與第一／二章不顯示。沿用既有 `chapters[<id>_3]` 永久旗標，未新增規則、旗標、schema 或存檔格式。
- **按需載入／呈現**：`maid_character_panel.gd` 新增 `BOND_CG` 表（只存路徑、標題、敘事），點擊時才 `load(path)`，三張 CG 均未 `preload`；缺檔不開啟。`maid_portrait_viewer.gd` 新增 `present_memory()`，沿用共用 tool overlay、遮罩、`CloseSeal` 與 Escape／返回，圖像維持 `EXPAND_IGNORE_SIZE`＋`STRETCH_KEEP_ASPECT_CENTERED` 完整 contain（不裁切頭飾、劍尖、右側劍鞘／流蘇，不拉伸），圖下敘事 `Label` 在檢視器內捲動；一般立繪 `present()` 會隱藏並清空敘事區。`feature_navigation.gd` 接 `memory_requested` 訊號。
- **純重播邊界**：開關回憶只發呈現訊號，不送命令、不改庫存、不重新領取、不發羈絆或資源；測試以 `to_snapshot_dict()` 比對開啟／關閉前後完全一致。第三章領取後按鈕只重播，不重複給獎。
- **修改檔案**：`src/presentation/maid_character_panel.gd`、`src/presentation/maid_portrait_viewer.gd`、`src/presentation/feature_navigation.gd`、`tests/maid_bond_cg_runner.gd`（新增）、`tools/run_all_runners.ps1`、`docs/49-maid-companion-system-design.md`（新增 §14）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`；Godot import 產生三張 CG 的 `.import` sidecar。未改規則、`maid_system.gd`、schema、存檔、美術原圖或字型。
- **驗收級別／結果（L1，單一 1280×720）**：`--headless --path . --import` exit0；`tools\run_all_runners.ps1 -Only 'maid_bond_cg_runner,maid_ui_runner,maid_ui2_runner,maid_art_r2_runner' -TimeoutSeconds 180` → 4/4 PASS，MAID-BOND-CG 68、MAID-UI 53、MAID-UI2 62、MAID-ART-R2 78，共 261 checks，failures=`[]`，無 SCRIPT ERROR。新 runner 斷言涵蓋：無預載 CG、三張路徑可解析且互異、第三章領取前／第一二章不顯示回憶、領取後顯示且命中 ≥44px、開啟後為共用 overlay 與正確 CG 路徑／標題／敘事、`KEEP_ASPECT_CENTERED`、1672×941、關閉後回到羈絆頁、狀態與章節旗標不變且不重複領取。測試以直接設定第三章門檻後呼叫 `MaidSystem.claim_chapter` 建立旗標，避開直接改狀態觸發的 durable save 衝突。
- **未驗證／下一步**：本輪使用者只要求 L1，未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器 1280×720 抽驗或觸控實機（觸控依 2026-10-17 延期）；交接中的桌面瀏覽器抽驗留待需要出包或 L2 時補做，不宣稱已通過。仙侍大型任務仍非本次結案。可手動 commit：本次為羈絆 CG 接入階段結束，非大型任務結案；代理未 commit／push。

<a id="maid-art-bond-cg"></a>
## 2026-11-01 MAID-ART-BOND-CG：三位仙侍羈絆終章 CG 美術接受（美術階段 DONE）

- **分工／範圍**：使用者指定 P1 三張終章 CG，美術由 Codex 完成，其餘程式交 OpenCode。使用者於 2026-11-01 明確表示「三張羈絆終章 CG 接受」；三張交付稿已標 `ACCEPTED`，美術階段 DONE，正式程式接入尚未完成。依 docs/48 §7、docs/49 §3：青蘅「前世燈火／燈下候歸」、糯美子「劍鳴舊世／劍廬夜雨」、丹霞「丹心照夜／丹爐守夜」。
- **交付檔案**：`docs/maid-art/<id>/bond-*-r1.png` 原稿與 `assets/characters/<id>/bond-*-r1.png` 原樣複本各三張。完整提示詞 `docs/maid-art/bond-cg-prompts-r1.json`；局部修訂 `bond-cg-revisions-r1.json`、`bond-cg-cleanup-r1.json`；生成紀錄 `bond-cg-generation-record-r1.json`；SHA256／參照 hash／尺寸／用途／切層／來源及授權 `bond-cg-manifest-r1.json`；審閱紀錄 `bond-cg-acceptance-r1.json`。交接：[OpenCode](handoffs/2026-11-01-maid-bond-cg-opencode.md)。未覆寫舊立繪、初遇、既有 manifest 或 nd-r2 接受紀錄。
- **生成與目視**：內建 image_gen，三次場景生成＋三次局部修訂，共六次；以青蘅正式 portrait＋baseline、糯美子／丹霞正式 portrait-r2＋turnaround-r2 作參照。糯美子修訂將完整劍刃／劍尖移入中段；丹霞第一次移除背景字牌未成功，第二次精確定位移除成功。選稿已核對臉型／髮瞳衣飾辨識、手與書燈／劍／藥罐丹爐，未見明顯多肢或可見 UI／文字。細部刺繡／髮飾仍有生成差異；糯美子空鞘尖端約在寬度94%、裝飾流蘇約98%，頭頂髮飾也接近上緣，後續必須完整 contain，不能宣稱任意 cover 裁切皆安全。
- **尺寸／切層／授權**：三張都是 1672×941 RGB、約16:9單層場景（人物／背景／前景光效未拆層），保留內建原始輸出，未程式修圖／放大／裁切。製作目標2560×1440未達原生尺寸，差異已隨交付說明，使用者接受現有三張稿；仍不冒充高解析原稿。來源為 AI 生成＋專案既有角色參照，沿用青蘅上游使用者參照作者／授權未明的限制；未新增外部圖片，不主張獨占或第三方商用清查完成。
- **驗證（靜態素材交付，非 L1／L2／L3 遊戲回歸）**：本機引擎 `--version` → `4.7.2.stable.official.ed1daf0bf`／exit0；Python/Pillow PNG 解碼、尺寸／模式與原始來源＝原稿＝專案複本 SHA256核對3/3通過；JSON／參照／提示詞核對通過。`python tools/delivery_check.py --manifest docs/maid-art/bond-cg-manifest-r1.json` → assets ok=3/3，exit1唯一原因為 acceptance 尚非 ACCEPTED（保留待確認狀態，不偽造放行）；`python tools/delivery_check.py` → RESULT PASS／exit0；`git diff --check` → exit0（既有 LF→CRLF 提醒）。`python tools/trim_status_docs.py` 依共用工具整理索引。未跑 runner、Web 匯出或遊戲互動驗收，本輪只有美術／metadata／交接。
- **接受後檢查（純 metadata，非遊戲回歸）**：acceptance JSON 記錄使用者原句、日期與三張原始 SHA256，manifest 同步 `ACCEPTED`；接受後 `delivery_check.py --manifest docs/maid-art/bond-cg-manifest-r1.json` → assets ok=3/3、RESULT PASS／exit0；`git diff --check` → exit0。圖片內容未更動，未重跑遊戲回歸。前項 exit1 為接受前歷史結果。
- **下一步／Checkpoint**：三張美術已接受，由 OpenCode 按既有第三章旗標接回憶／重播並完成受影響驗證；不把放進 assets 當已接入。英文 checkpoint 已更新 `updata.txt` 並保留最近5筆。本輪為美術階段結束，非整體仙侍里程碑結案；可手動 commit，代理未 commit／push。後續大型工作請用 New Chat，OpenCode 可直接讀本輪交接。


<a id="maid-stand"></a>
## 2026-11-01 MAID-STAND：洞府侍立可收合展示（L1，DONE）

- **範圍／交付**：使用者要求「洞府內的仙侍展示（可收合）」，並順手修正 docs/49 第 4 行過時的「待 OpenCode 接入」。新增 `src/presentation/maid_stand_display.gd`：寬式洞府首頁在訊息面板右側顯示已驗收立繪的上半身（`AtlasTexture` 裁切 540×780、`STRETCH_KEEP_ASPECT_COVERED`）、角色名、職位與職掌狀態；「前／後」切換展示角色、「人物頁 · 初遇」走既有 `characters` route、`CloseSeal` 收合成右下「仙侍」小籤。預設展示 `active_duty`，玩家手動切換後以手動選擇為準；切換只讀 `view.maid`，不派工、不發羈絆、不寫 `GameState`。
- **安全區**：只在洞府首頁、無 overlay、WIDE 版面、選島器關閉，且展開區不與訊息面板／底部工具列重疊時顯示；空間不足（短橫式、窄橫式、選島器展開）整個元件讓位，不遮住突破、保存恢復、訊息或核心世界目標，也不改相機 `world_safe_rect` 契約。
- **修改檔案**：`src/presentation/maid_stand_display.gd`（新增）、`src/abode/living_abode.gd`（`maid_stand` 欄位）、`src/presentation/abode_hud_controller.gd`（建構、layout、refresh 掛鉤）、`tests/maid_stand_runner.gd`（新增）、`tools/run_all_runners.ps1`、`docs/49`（第 4 行狀態＋§13）、`docs/48`（實作註記）、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改規則、schema、`maid_save_contract.gd`、`save_codec.gd`、美術或字型。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_stand' -TimeoutSeconds 180` → 1/1 PASS，`MAID-STAND checks=26 failures=[]`，無 SCRIPT ERROR。收尾再跑受影響的 `maid_ui_runner`、`ui_shell_integration_runner`、`living_abode_runner` → 4/4 PASS（MAID-UI 53、UI-SHELL-1 44 checks，皆 failures=`[]`）。新增斷言：寬式展開、立繪裁切來源與載入、訊息面板右側不重疊、底部工具列上方、44px 命中、前／後切換與手動選擇優先於當值、收合／展開、人物頁往返後展示回歸、狀態 snapshot 完全不變、844×390 短橫式讓位。另以非 headless 原生 1280×720 跑同一 runner 產生 `stand`／`collapsed` 兩張截圖（`.test-output/maid-stand/`），目視確認半身、標題、訊息區與工具列版面。
- **未驗證／下一步**：未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。展示偏好目前只在當次遊戲內有效，未跨存檔／輪迴保存；若要落實 docs/48 §8 需另開 `MaidSaveContract`／schema 任務。短橫式目前直接讓位，未做緊湊展開變體。可手動 commit：本次為仙侍後續小功能，非大型任務結案；未 commit／push。

<a id="maid-roster-browse"></a>
## 2026-11-01 MAID-ROSTER-BROWSE：未招募仙侍可切換閱覽（L1，DONE）

- **範圍／交付**：使用者要求「換下一位仙侍」，並選定「未招募也能切換查看」。三位仙侍選擇列（青蘅／糯美子／丹霞）原本只在人物分頁顯示，現在職掌、羈絆分頁與非緊湊版面的初遇重溫頁也會顯示（緊湊版面的初遇頁為保留對話高度仍隱藏），任何分頁都能直接換仙侍；未招募角色仍可閱覽立繪、小傳與初遇，其選擇鈕加上「尚未招募 · 可先閱覽人物與初遇」提示。切換僅改呈現，`select_maid` 重置對話與職掌選擇，不寫狀態。
- **修改檔案**：`src/presentation/maid_character_panel.gd`（`_sync` 選擇列常駐＋未招募 tooltip）、`tests/maid_ui_runner.gd`、`tests/maid_ui2_runner.gd`、`docs/49-maid-companion-system-design.md`、`docs/development-status.md`、`updata.txt`。未改規則、`maid_system.gd`、schema、存檔、美術、字型或 Web 匯出。
- **驗收級別／結果（L1，單一 1280×720）**：`tools\run_all_runners.ps1 -Only 'maid_ui_runner,maid_ui2_runner,maid_art_r2_runner' -TimeoutSeconds 180` → 3/3 PASS，MAID-UI 53 checks（新增 16）、MAID-UI2 62 checks（新增 6）、MAID-ART-R2 78 checks，共 193 checks，failures=`[]`，無 SCRIPT ERROR。新增斷言：空存檔下三位角色皆可切換且立繪／小傳／招募條件可見並標示未招募、切換不改變 `to_snapshot_dict()`；職掌頁與羈絆頁切換列仍可見且切換後職掌文字跟隨新角色、留在原分頁。
- **未驗證／下一步**：只跑 L1 三支 runner 與單一尺寸；未跑 L2／L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（觸控依 2026-10-17 延期）。另以 `DAO_VIEWPORT_MATRIX=full` 直接跑 `maid_ui_runner` 作診斷（非验收）：僅 `page clears main navigation` 在緊湊人物頁失敗，已用原始 `mode == "person"` 版本對照確認屬既有項目，非本次改動引入。`tools/maid_art_r2_web_check.mjs` 的職掌／羈絆滾輪座標以舊版面量測，新增選擇列可能使緊湊尺寸座標需重校，未宣稱 Web 流程仍通過。可手動 commit：本次為仙侍後續小改，非大型任務結案；未 commit／push。

<a id="maid-close"></a>
## 2026-11-02 MAID-CLOSE：仙侍整批收尾完整 L3（全量 runner＋全尺寸矩陣＋Web 三橫式，DONE）

- **範圍／交付**：使用者指示「進 L2＋L3（即 docs/48 的 MAID-CLOSE）」。本輪補齊 2026-11-01 L3 限定輪未做的全專案 runner 矩陣、全尺寸矩陣、重新匯出與新包桌面三橫式。唯一遊戲程式修正：800×360 人物面板最小高度 189px 大於可用 156px，`PanelContainer` 長出底部導覽；`maid_character_panel.set_layout_bounds()` 於緊湊版面把名冊選擇列併入標題列（單列四頁籤＋三位仙侍），寬式仍還原兩列。修正後 800×360 最小尺寸 620×141、面板 768×156，完全落在紙面內。
- **修改檔案**：`src/presentation/maid_character_panel.gd`（緊湊單列標題）、`assets/fonts/runtime/Dao2Sans-VF.ttf`／`Dao2Serif-VF.ttf`／`manifest.json`（仙侍文案缺字，子集重建至 2048 碼位）、`docs/verification/maid-close.md`（改寫為完整 L3＋保留 11-01 歷史）、新增 `docs/verification/artifacts/maid-close-web-l3/`（38 張截圖＋報告）與 `docs/verification/artifacts/maid-art-r2-l3-fixture.json`、`docs/development-status.md`、`README.md`、`ROADMAP.md`、`updata.txt`。未改規則、schema、存檔、美術或經濟數值；`tests/maid_ui_runner.gd` 最終未留診斷輸出。
- **L2（MAID 領域，1280×720）**：`tools\run_all_runners.ps1 -Only 'maid' -TimeoutSeconds 240` → 10/10 PASS：MAID-UI 53、MAID-CORE 266、MAID-OFFLINE 62、MAID-UI2 62、MAID-DUTY-PRESET 34、MAID-FIRST-MEETING 27、MAID-ART-R2 78、MAID-BOND-CG 68、MAID-BOND-CHAPTER 138、MAID-STAND 33，共 821 checks，failures=`[]`，無 SCRIPT ERROR。
- **L3 全量與全尺寸**：`-Full -Parallel 3 -TimeoutSeconds 120`（170 支、`DAO_VIEWPORT_MATRIX=full`）首輪 9 支未過——`maid_ui` 真實失敗（800×360，修正後 153 checks 全過），其餘 8 支為 120 秒逾時（story／beasts／pills／talents／supply_progression／content_p1_accept／early_flow1d／sks_p2_flow），逾時時皆持續推進、無 SCRIPT ERROR。修正後 `-Only 'maid' -Matrix full -Parallel 3 -TimeoutSeconds 300` → 10/10 PASS；8 支長流程以 600 秒重跑 7 支 PASS（260–494s），`content_p2_supply_progression` 以 1800 秒重跑 PASS 1135.9s；`early_flow1d` 為 8 支中唯一讀 `DAO_VIEWPORT_MATRIX` 者，另以 `-Matrix full` 重跑 PASS 134.1s，其餘 7 支無尺寸分支，單尺寸結果等同全尺寸。
- **Web／瀏覽器**：`--import` exit 0；`--export-release Web build/web-maid-close` exit 0（pck 159,007,356 B、wasm 39,514,754 B）；`prepare_web_compression` exit 0（br 合計 166,377,244 B）。fixture PASS（actions=4 units=20）。Chrome `156.0.8078.79`（CDP 9252、伺服器 48352）跑 `maid_art_r2_web_check.mjs` → `MAID-ART-R2-WEB PASS errors=[]`：1280×720（1279×719）、844×390（843×389）、800×360（799×359）皆無溢出、存檔還原 `actions=4`、流程後 schema=6；緊湊尺寸切換角色／立繪開關有變化、職掌與羈絆可捲動；主控台 92 行無 SCRIPT ERROR。首次自訂 `SAVE_NAMESPACE` 未還原存檔，因應用固定使用 `dao2_saves`（`living_abode.gd:354`），改回預設後通過。800×360 截圖確認單列標題列與完整小傳收束。
- **收尾檢查**：`python tools/delivery_check.py --web build/web-maid-close` → RESULT PASS／exit 0（Web 7/7、head `b6130f35`、34 筆變更）；`subset_game_fonts.py --check` exit 0（2048 碼位）；`git diff --check` exit 0。證據見 [MAID-CLOSE 驗收](verification/maid-close.md)。
- **邊界／下一步**：首輪 9 支未過已逐一修正或提高上限重跑通過，未再整批重跑第二次 `-Full`，故記錄為「170 支皆已於全尺寸矩陣或等效重跑通過」，不寫成單次 `-Full` 零失敗。未驗觸控、實機、DPR 2／3、旋轉、FPS、IndexedDB 落盤（依 2026-10-17 延期）。`build/web-maid-close` 為本機測試包，非交付候選包，pck 159.0 MB 屬已延後的冷啟動議題。依 docs/48 第 128 行，下一位角色或是否回到 EARLY-FLOW1-D 由使用者選定（先前建議 B＋青蘅）；仙侍首位角色整批收尾完成。可手動 commit：本次為大型里程碑（MAID-CLOSE）結束，適合手動 commit 整批仙侍工作；代理未 commit／push。

<a id="maid-art-nd-r2-web"></a>
## 2026-11-01 MAID-ART-ND-R2 Web 匯出與桌面瀏覽器流程（L3 限定：Web＋瀏覽器，階段 DONE）

- **範圍／交付**：使用者指定本輪「只跑 Web 匯出與瀏覽器流程」，故只做 Web 匯出、桌面 Chrome 點擊流程與字型子集修正；未跑全量 runner、全尺寸 runner 矩陣、觸控實機。新增 `tools/maid_art_r2_web_fixture.gd`（離線 10 分鐘、青蘅職掌執行中，自檢 `actions=4 units=20`）與 `tools/maid_art_r2_web_check.mjs`（注入存檔、等待新的 `ABODE_READY:`、canvas 換算點擊、逐尺寸斷言）。
- **瀏覽器驗收發現並修正**：人物頁小傳出現豆腐方塊，`subset_game_fonts.py --check` 指出 17 個缺字碼位；依工具既定流程重建 `assets/fonts/runtime` 兩個子集字型（覆蓋 1980→1997 碼位）後 `--check` 通過，重新匯出再截圖已無缺字。另確認小傳捲動區可用滾輪捲到收束句第二行，預設視窗的下緣裁切屬預期捲動行為。
- **修改檔案**：`assets/fonts/runtime/Dao2Sans-VF.ttf`、`assets/fonts/runtime/Dao2Serif-VF.ttf`、`assets/fonts/runtime/manifest.json`；新增 `tools/maid_art_r2_web_fixture.gd`、`tools/maid_art_r2_web_check.mjs`、`docs/verification/maid-art-r2-web.md`、`docs/verification/artifacts/maid-art-r2-l3-fixture.json`、`docs/verification/artifacts/maid-art-r2-l3-web/`；`README.md`、`ROADMAP.md`、`updata.txt`。
- **驗收級別／結果**：Web 匯出＋桌面瀏覽器（Chrome `156.0.8078.79`，CDP 9250，靜態伺服器 48350）。`--import` exit 0；`--export-release Web build/web-maid-art-r2` exit 0；`prepare_web_compression` exit 0（pck 152,965,544 B、sha256 `8ba70e3c…37d380`、br 合計 160,332,407）；`node --experimental-websocket tools/maid_art_r2_web_check.mjs` → `MAID-ART-R2-WEB PASS errors=[]`：1280×720 canvas 1279×719、無頁面溢出、存檔還原 `actions=4`、流程後存檔完整 schema=6，並完成世界→人物→糯美子／丹霞切換→完整立繪開啟／Escape 關閉→初遇重溫→職掌→羈絆→關閉面板 11 張截圖；844×390（843×389）與 800×360（799×359）canvas 貼合、無溢出、存檔還原皆 PASS，主控台無 SCRIPT ERROR。`delivery_check.py --web build/web-maid-art-r2` RESULT PASS（7/7）、`subset_game_fonts.py --check` exit 0、`git diff --check` exit 0。證據見 [Web驗收](verification/maid-art-r2-web.md)。
- **未驗證／下一個任務**：短橫式兩尺寸未執行人物面板點擊流程（離線摘要關閉鈕座標未按緊湊版面校準，不宣稱通過）；未驗觸控、實機、DPR 2／3、FPS、IndexedDB 落盤（依 2026-10-17 指令延期）；`build/web-maid-art-r2` 為本機測試包，非交付候選包。pck 因 R2 角色圖增至 152.9 MB，屬已延後的冷啟動／資產預算議題。MAID-CLOSE 仍未宣稱完成，仙侍任務維持 IN_PROGRESS。可手動 commit：本次為 R2 整合的 Web／瀏覽器驗證階段結束，非整個仙侍任務結案；未 commit／push。

<a id="maid-art-nd-r2-integration"></a>
## 2026-11-01 MAID-ART-ND-R2 接入：糯美子／丹霞立繪與初遇正式接入（L1＋原生渲染抽驗，整合階段 DONE）

- **範圍／交付**：依 [R2交接](handoffs/2026-11-01-maid-art-nd-r2-opencode.md)，以 Fusion 流程把已接受六張 R2 美術接入人物頁。`ART` 表按角色路由（青蘅 canonical；糯美子／丹霞 `portrait-r2.png`、`first-meeting-r2.png`），沿用 `EXPAND_IGNORE_SIZE`＋`STRETCH_KEEP_ASPECT_CENTERED` 完整 contain；`STORIES` 為每位角色提供小傳、引句、標籤、結語、印章、初遇場景／開場／兩則回覆與選項；`select_maid` 切換時重置對話並刷新立繪／CG；完整立繪檢視器標題顯示當前角色；`MaidSystem.ART_READY` 僅供應 View 的 `art_ready`，不參與招募／羈絆／職掌判定，規則層無 Texture／Node。
- **敘事邊界**：糯美子「雲海試劍」、丹霞「丹房夜話」只作叙事文案，無獎勵、無狀態、無 schema 變更；青蘅雨夜書卷文案保留。
- **修改檔案**：`src/presentation/maid_character_panel.gd`、`src/presentation/maid_portrait_viewer.gd`、`src/presentation/feature_navigation.gd`、`src/simulation/maid_system.gd`、`tests/maid_art_r2_runner.gd`（新增）、`tools/run_all_runners.ps1`；Godot import 產生四位角色共八份 `.import` sidecar。
- **驗證級別／結果（L1＋原生渲染抽驗）**：`--headless --path . --import` exit0、無 SCRIPT ERROR；`tools\run_all_runners.ps1 -Only 'maid_ui_runner,maid_ui2_runner,maid_art_r2_runner'` 3/3 PASS（MAID-UI 37、MAID-UI2 56、MAID-ART-R2 78 checks，全 failures=[]，無 SCRIPT ERROR）。另以非 headless 原生 1280×720 跑同一 runner 產生六張截圖，目視確認劍尖／鞋／髮與 CG 完整、標題與小傳正確；證據見 [驗收](verification/maid-art-nd-r2.md) 與 `docs/verification/artifacts/maid-art-r2-20261101/`。
- **未驗證／下一步**：未跑 L3 全量、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機（依 2026-10-17 指令延期）；未宣稱 MAID-CLOSE。整體仙侍任務仍 IN_PROGRESS；下一步可做跨尺寸抽驗或待使用者指示。可手動 commit：本次為 R2 接入階段結束，非大型仙侍任務結束；未 commit／push。

<a id="maid-art-nd-r2"></a>
## 2026-11-01 MAID-ART-ND-R2：三向設定／體型與劍結構修訂（美術已接受，OpenCode 接續接入）

- **2026-11-01 使用者接受（最新）**：使用者「美術確認」，接受糯美子／丹霞 R2 三向設定、透明立繪與初遇 CG 共六張，包含年齡體型差異與完整劍結構；[接受紀錄](maid-art/nd-r2-acceptance.json) 保存原話與六張 SHA256，兩份 manifest-r2 標為 ACCEPTED。本次僅更新接受metadata／索引／交接，圖片與程式原樣，未執行遊戲測試。下一步直接由 OpenCode 依 [R2交接](handoffs/2026-11-01-maid-art-nd-r2-opencode.md) 接入，不重做美術選擇；整體 MAID-CLOSE 未完成。接受metadata靜態檢查：六張原圖與四張副本SHA256不變；兩份 `delivery_check.py --manifest .../manifest-r2.json` 最終均exit0／ACCEPTED、2/2 PASS，trim與diff-check均exit0。初次manifest檢查因參照三向圖沒有runtime鍵而KeyError／exit1，已將三向圖移至reference_assets、保留六圖接受範圍後修正，未改檢查工具或圖片。以下待接受文字保留為本日較早歷史。可手動 commit：美術接受階段結束，非大型仙侍任務結束；未 commit／push。

- **最新要求**：使用者指出 R1 三人體型近似、糯美子像只有劍鞘，要求約20歲嬰兒肥的糯美子及成熟御姐丹霞。R1 確未製作兩人的多向圖；本輪補正／側／背設定，並同步重作兩位立繪與初遇 CG。此子階段素材已交付，不等於使用者已接受或整體 MAID-CLOSE 完成；青蘅沿已接受稿、不重畫。
- **設定差異**：[三人比例設定 R2](maid-art/character-proportions-r2.md) 記錄糯美子成年約20歲、圓頰笑容、較短頭身／頸腿、短披與長褲平靴；丹霞成年約32–35歲、長橢圓臉／細長眼、長頸長腿、較明確肩腰胯與合身長衣。158／176cm、6.5／8頭身是設計目標而非精確量測保證。糯美子三向附完整出鞘劍＋空鞘；立繪／CG 已能辨認劍首、黑柄、金護手、銀刃與獨立空鞘，修正 R1 被遮擋的結構。
- **檔案／參照鏈**：`docs/maid-art/{nuomeizi,danxia}/` 各新增 `turnaround-r2.png`、`portrait-r2.png`、`first-meeting-r2.png` 與各自 `*-r2-prompt.json`；兩位 README 指向 R2。`assets/characters/{nuomeizi,danxia}/` 新增 `portrait-r2.png`、`first-meeting-r2.png`、`manifest-r2.json`，保留所有 R1 及舊 canonical 副本。另新增 [OpenCode R2交接](handoffs/2026-11-01-maid-art-nd-r2-opencode.md)，R1交接標示後續版本。docs49、根README／ROADMAP索引與英文updata同步。沒有 Godot來源、規則、schema、玩家進度或build修改。
- **生成與目視**：使用內建 image_gen 技能共六次；R1僅作服裝／色系基礎並明確改臉體，R2三向→立繪→初遇沿同一角色參照。三向圖各1536×1024 RGB，立繪各1024×1536 RGBA，CG各1672×941 RGB。正／側／背與臉部、道具可讀，角色無明顯多肢；頭身、臉與輪廓差異比 R1 清楚，但不能把生成圖視為正投影精密藍圖，刺繡／小配件有變化。糯美子立繪 alpha≥128 bbox `(33,11,949,1498)`、丹霞 `(109,13,1001,1514)`；未達提示詞各邊8%留白，保留完整contain並標註，不聲稱邊緣已接受。未程式去背／合成／裁切；設定圖非動畫幀。上游青蘅使用者例圖授權未知限制延續，未新增第三方圖參照。
- **命令／範圍**：PowerShell `Copy-Item` 保存六張原稿；Python/Pillow 讀取尺寸／alpha、SHA256、六份完整prompt／參照存在與四份原樣接入副本檢查 exit0。通用 `python tools/delivery_check.py` exit0／RESULT PASS（受保護證據目錄7筆皆為本輪開始前已有變更）；`python tools/trim_status_docs.py` exit0，歸檔 README／ROADMAP 舊索引；`git diff --check` exit0，僅既有 LF→CRLF 提醒。未執行引擎、import、遊戲runner、L1／L2／L3、Web匯出或瀏覽器測試，沿使用者本輪前指示，不宣稱遊戲驗收或美術接受。
- **下一步**：先收本輪圓頰／成熟度／體型與劍的視覺回饋，之後交 OpenCode 依 R2 manifest 接人物圖片／專用小傳／初遇文字及 art_ready；R1體型方向已被此回饋取代，不得混接舊稿。不自行開始下一功能。可手動commit：本次為美術修訂子階段結束，非大型仙侍任務結束；代理未commit／push。後續使用New Chat。

<a id="maid-art-nd"></a>
## 2026-11-01 MAID-ART-ND：糯美子／丹霞四張美術提供階段 DONE（美術待接受，OpenCode 接續）

- **授權／範圍**：使用者澄清由 Codex 提供 Nuomeizi／丹霞美術，完成後轉 OpenCode 繼續，並指定本輪不進行測試。交付兩位各一張透明全身立繪及一張橫式初遇 CG；不延伸遊戲接入或其他功能。此處 DONE 僅指四張素材提供階段，使用者美術接受仍待確認，整體仙侍／MAID-CLOSE 未完成。
- **檔案**：`docs/maid-art/{nuomeizi,danxia}/` 各含 `portrait-r1.png`、`first-meeting-r1.png`、`prompts-r1.json`、README；`assets/characters/{nuomeizi,danxia}/` 各含 byte-identical 的 `portrait.png`／`first-meeting.png` 及 manifest（原稿、來源路徑、SHA256、用途、切層、參照與授權限制）。另有 [OpenCode 交接](handoffs/2026-11-01-maid-art-nd-opencode.md)。根 README／ROADMAP 一行索引與英文 updata 同步；docs49 的美術待提供狀態更新。既有 dirty 程式、測試、字型及驗證資料均保留。
- **美術**：內建 image_gen 共四次。糯美子沿墨紅短披／黑髮高馬尾／琥珀瞳／佩劍，初遇為雲海試劍；丹霞沿藕紫藥衣／梅棕半挽髮／紫瞳／青瓷藥瓶，初遇為丹房夜話。青蘅僅作畫風參照，兩張 CG 各沿自己的主立繪作身分參照。延續青蘅上游例圖作者／授權未知的限制，未新增外部圖參照，不宣稱第三方商用授權或獨占性。
- **目視與靜態素材檢查**：兩張立繪皆 1024×1536 RGBA、兩張 CG 皆 1672×941 RGB；人物／髮衣／道具合層，CG 人物／環境合層，無嵌入 UI 文字。臉髮、衣色與主要道具在各自兩圖保持辨識，未見明顯多肢；刺繡／細部飾物有生成差異。兩張立繪 alpha≥128 包圍盒分別為 `(32,8,1013,1524)`、`(12,9,1007,1522)`，留白未達提示詞 7%，接入須完整 contain，不宣稱邊緣已獲接受；未以程式去背或修圖。未製作三視設定、表情差分、終章 CG 或世界小像。
- **命令／結果**：PowerShell `Copy-Item` 保存四張內建原稿；Python/Pillow 讀取尺寸／alpha、hash 與原樣複製、JSON 提示詞完整性靜態檢查 exit0。`delivery_check.py --manifest assets/characters/nuomeizi/manifest.json` 與丹霞同命令各為 assets ok=2/2，但各 exit1，原因僅為 acceptance 尚非 ACCEPTED；保留 `DELIVERED_PENDING_USER_REVIEW`，不偽造使用者接受。`git diff --check` exit0（既有 LF→CRLF 提醒）。中途補提示詞的兩次 apply_patch 因同檔重複操作／預期內容不匹配失敗，改用精確 patch 後四份提示詞已完整保存。`python tools/trim_status_docs.py` 完成 README／ROADMAP 舊段落歸檔；`python tools/delivery_check.py` exit0／RESULT PASS，所列受保護證據目錄 7 筆為本輪開始前即存在的變更。收尾 diff 首次發現 ROADMAP 末尾空行，移除並將本輪索引移至頂部後重查。
- **驗收邊界／下一步**：僅美術目視與檔案靜態檢查；依本次使用者要求未執行 Godot、import、runner、L1／L2／L3、Web 匯出或瀏覽器驗收，沒有全量通過主張。`maid_character_panel.gd` 仍只接青蘅圖像／敘事，`maid_system.gd` 的 art_ready 仍只對青蘅為 true，正式接入未完成。現在可轉交 OpenCode，先承接使用者美術回饋，再按交接完成兩位圖片、簡介與初遇專用文字。可手動 commit：本次是美術提供階段結束，非大型仙侍任務結束；代理未 commit／push。後續用 New Chat 接續。

<a id="maid-ui-2"></a>
## 2026-11-01 MAID-UI-2：職掌／羈絆呈現修正與桌面 Web 抽驗（L2，呈現階段 DONE）

- **範圍／交付**：使用者「使用 fusion skill 接 MAID-UI-2」。修正 MAID-CORE-1 啟用後未經視覺驗證的職掌／羈絆分頁，並驗證 MAID-CORE-2 的離線摘要仙侍行；不新增規則、資源或 schema，`save_codec.gd`／`save_manager.gd`／`maid_save_contract.gd` 零變更。
- **呈現修正**：回饋列移入職掌／羈絆捲動區，短橫式不再撐到底部工具列下；目標 `SpinBox` 只在 View 值變動且未取得焦點時同步；捲動區 `follow_focus`；移除重複「已暫停」並改用強調字重；`duty_picker` 補 44px 列高與 tooltip；目標欄可見性改由職掌種類推導；切換分頁／角色清除殘留回饋。
- **文字／錯誤**：`MaidSystem.status_text()` 補 `UNKNOWN_RECIPE`／`UNKNOWN_PILL`；職掌配方選單改顯示名稱並以 `_plain_name()` 去除 emoji 前綴（不再出現 `foundation_pill`）；`feature_navigation` 仙侍錯誤鍵改為核心實際回傳的 `BUILDING_UNKNOWN`。
- **修改檔案**：`src/presentation/maid_character_panel.gd`、`src/simulation/maid_system.gd`、`src/presentation/feature_navigation.gd`、`tests/maid_ui2_runner.gd`（新增）、`tools/maid_ui2_web_fixture.gd`（新增）、`tools/maid_ui2_web_check.mjs`（新增）、`tools/run_all_runners.ps1`、`docs/49`、`docs/verification/maid-ui-2.md`（新增）、`README.md`、`ROADMAP.md`、`updata.txt`。
- **驗證級別／命令與結果**：L2。`--headless --path . --import` exit 0；`tools\run_all_runners.ps1 -Only 'maid'` → 4/4 PASS（`maid_ui2` 56 checks、failures=[]、exit 0）。Web 匯出 `build/web-maid-ui2` 與壓縮 exit 0；fixture 自檢 `actions=4 units=20`；桌面 Chrome `156.0.8078.79` 1280×720 抽驗 `MAID-UI2-WEB PASS errors=[]`（離線摘要「仙侍職掌：離線完成 4 次」、職掌頁顯示「築基丹」、羈絆頁「青蘅・初識 30 點」）。`delivery_check.py --web build/web-maid-ui2` RESULT PASS、`subset_game_fonts.py --check` exit 0、`git diff --check` 無誤。
- **未驗證／界線**：未跑 L3、全量 runner、全尺寸矩陣；未驗觸控、實機、DPR 2／3、FPS 或 IndexedDB 落盤；`build/web-maid-ui2` 為本機測試包，非交付候選包，`build/web` 未更新。糯美子／丹霞美術仍待補。可手動 commit：本次為 MAID-UI-2 呈現階段結束，非整個仙侍大型任務結束。詳見[驗收](verification/maid-ui-2.md)。

<a id="maid-core-2"></a>
## 2026-11-01 MAID-CORE-2：離線職掌有限補算（L1，核定並實作，核心階段 DONE）

- **範圍／交付**：使用者「核定 §11；補 docs/rule-differences.md 的 V2-MAID-CORE-2 並依 §11.9 實作＋跑 4 支 L1 runner」。完成設計核定、規則帳本條目、核心／離線／UI 實作與 L1 驗收。
- **核心決策**：離線只讓已存在且 `paused == false` 的職掌以結算後庫存執行至多 `MAX_ACTIONS_PER_CALL := 5` 次動作；`MAX_ACTIONS_PER_ADVANCE := 1000` 僅留作絕對上限。`MaidSystem.advance` 改為必填 `max_actions`，內部 `clampi`，`<= 0` 直接回空且不扣冷卻。同步 `OfflineSettlement.settle`、非同步 `OfflineCoordinator.compute_async` 於時間結算後各呼叫一次；線上 `GameSession.advance_time` 同步改傳 5。`stopped != null`、bootstrap、rollback、`full_ticks == 0` 與 `time_only_ticks` 一律 0 次。不自動招募／指派／恢復／領章／重逢；跨世維持暫停；只沿用既有一次性首次職掌 +10 羈絆；不新增資源、倍率、貨幣或 schema（維持 6）。
- **報告／UI**：`report.maid = {actions, units, kinds, first_duty}` 只由 `MaidSystem.advance` 回傳 events 推導，0 次時整個鍵省略；`OfflineSummary` 只在有鍵時於「目前年歲」與「停止原因」間加一行，0 次輸出逐字不變；保留 autowrap 與 ScrollContainer，不新增控制項。`last_offline_report` 仍只作留痕、不讀回。
- **明確界線**：離線職掌在時間結算後一次執行，**不宣稱與線上逐 tick 等價**；經濟已展開時只記派工，成品回線後才完成。`MAX_ACTIONS_PER_CALL` 為平衡常數，體感平衡待實機後調整。桌面聚焦長間距的舊漏洞由共用 5 次上限封頂；改走 `OfflineCoordinator` 仍列非阻擋後續。
- **修改檔案**：`src/simulation/maid_rules.gd`、`src/simulation/maid_system.gd`、`src/simulation/offline_settlement.gd`、`src/application/offline_coordinator.gd`、`src/application/game_session.gd`、`src/presentation/offline_summary.gd`、`tests/maid_offline_runner.gd`（新增）、`tests/maid_core_runner.gd`、`tests/m1d_offline_runner.gd`、`tests/offline_closed_form_parity_runner.gd`、`tools/run_all_runners.ps1`、`docs/49`、`docs/rule-differences.md`、`docs/verification/maid-core-2.md`（新增）、`README.md`、`ROADMAP.md`、`updata.txt`。`save_codec.gd`、`save_manager.gd`、`maid_save_contract.gd` 零變更。
- **驗證級別／命令與結果**：L1，單一 1280×720，`tools\run_all_runners.ps1 -Only 'maid_core_runner.gd','maid_offline_runner.gd','m1d_offline_runner.gd','offline_closed_form_parity_runner.gd' -TimeoutSeconds 180` → 4/4 PASS。`maid_core_runner` 179 checks、`maid_offline_runner` 62 checks、`offline_closed_form_parity_runner` 16 checks，全部 failures=[]、exit 0。延長 timeout 僅因 parity runner 既有的 48h 參考結算約 80–90 秒，非本次新增成本。
- **未驗證／下一步**：未跑 L3、全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機，不宣稱全量回歸。可手動 commit：本次為 MAID-CORE-2 核心階段結束，非整個仙侍大型任務結束。

<a id="maid-core-1"></a>
## 2026-11-01 MAID-CORE-1：三位仙侍核心、職掌與羈絆（L1，核心階段DONE）

- **範圍／交付**：使用者選定方案B後，完成前期三位仙侍的可玩核心：青蘅「定量備料」、糯美子「定量監造」、丹霞「定量煉丹」。每位角色有具名招募條件、四階羈絆（初識0／相知40／信任100／同道200）、三章一次性羈絆章節，章節只給羈絆點與記憶旗標，不發資源。同一時間僅一位仙侍有生效職掌；每次最多5批次，備料／煉丹保留量不足即停，監造只升單一指定建築且受既有等級上限約束。職掌透過既有`craft`／`upgrade_building`／`refine_pill`命令執行，不直接改資源、建築或庫存。
- **跨世／時間邊界**：`state.maid`為永久區塊，羈絆、章節、選擇與重逢旗標跨世保留；輪迴時職掌暫停、冷卻歸零、設定重逢待確認，重逢只清旗標不重發首次獎勵。職掌v1只在線上`GameSession.advance_time`依固定節奏推進（備料／煉丹10秒、監造30秒），離線結算不執行，屬明確v1邊界。未新增被動產量倍率、天賦ID、宗門token／市集品、靈獸槽或好感貨幣。
- **保存**：新增可選頂層`state.maid`，`MaidSaveContract`嚴格驗證與正規化，上限16384 bytes，非法資料不修復；schema維持6，release候選交易白名單加入7個仙侍命令。`GameState`duplicate／snapshot、`SaveCodec`encode／decode、`GameSession`命令與View、`CommandProcessor`分派、`ReincarnationRules`跨世掛鉤均同步。
- **介面**：人物頁四分頁（人物／初遇重溫／職掌／羈絆）、三角色選擇、職掌目標與操作、章節領取、招募與重逢；標準`action_requested`信封經`feature_navigation`送出，成功後存檔並刷新HUD。糯美子／丹霞立繪與初遇CG暫顯示「待Codex補完」，未捏造美術。
- **修改檔案**：新增`src/simulation/maid_rules.gd`、`maid_system.gd`、`src/persistence/maid_save_contract.gd`、`tests/maid_core_runner.gd`及UID、`docs/49-maid-companion-system-design.md`、`docs/verification/maid-core-1.md`；修改`game_state.gd`、`save_codec.gd`、`game_session.gd`、`command_processor.gd`、`sect_reform_save.gd`、`reincarnation_rules.gd`、`maid_character_panel.gd`、`feature_navigation.gd`、`maid_ui_runner.gd`、`run_all_runners.ps1`。新介面字串使runtime字型子集新增8字，原始字型未改。
- **L1命令與結果**：Godot`4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import` 最終exit0、無SCRIPT ERROR。`maid_core_runner.gd` 172 checks／failures=[]／exit0；`maid_ui_runner.gd` 37 checks／exit0。`run_all_runners.ps1 -Only 'maid_core_runner.gd,maid_ui_runner.gd,feature_navigation_runner.gd,ui_shell_policy_runner.gd'` 4/4 PASS；另跑共用核心6支（release／save／m1c／m3a／ledger／talents）6/6 PASS。`subset_game_fonts.py --check`、`delivery_check.py`、`git diff --check`通過。刻意NaN契約測試有無害JSON警告。
- **未驗證／界線**：未跑L3全量、全尺寸矩陣、Web匯出、桌面瀏覽器或觸控實機；release候選存檔路徑未做真實瀏覽器重載；離線職掌與糯美子／丹霞美術仍待後續。整體仙侍大型任務維持IN_PROGRESS。下一任務建議Codex補糯美子／丹霞立繪與初遇CG，再作MAID-UI-2桌面瀏覽器抽驗或MAID-CORE-2離線職掌設計。可手動commit：本次為核心階段結束，非大型仙侍任務結束。詳見[驗收](verification/maid-core-1.md)。

<a id="maid-ui-1"></a>
## 2026-11-01 MAID-UI-1：R3人物頁與初遇重溫接入（L2，呈現階段DONE）

- **範圍／交付**：使用者「接MAID-UI-1，沿已接受R3接入Godot人物頁與初遇展示」。新增唯一canonical `characters` route於「遊歷→人物」，Era1可見；四主入口不變。青蘅沿R3透明全身立繪、直式文楷題字、淡墨畫框、朱色書香印及有缺口的書籤小傳；正文／對話／操作仍為共用黑體，文字獨立渲染。人物／初遇重溫沿GameTab，職掌／羈絆明示未開且禁用。既有docs48經營職掌歸屬只是未核定候選，本次先接敘事歸屬，不開第二入口。
- **互動／響應式**：初遇兩個回應、重新相遇、人物返回均為記憶體呈現。CG首次進初遇才載入，圖片皆contain；完整立繪走共用shell工具遮罩、固定CloseSeal與Escape，較頁面取得更大高度，工具關閉恢復原route。頁內Escape先從初遇回人物，再回洞府。短橫式收裝飾／題字內距，初遇改場景與對話並排、選項同行；正文維持18px及單區內捲、操作≥44px。補上容器最小高度改變後重新套用bounds，修復首次排版舊高度蓋住主導覽。
- **修改檔案**：新增`src/presentation/maid_character_panel.gd`、`maid_portrait_viewer.gd`及UID；接`feature_navigation.gd`／`ui_shell_policy.gd`／`feature_unlocks.gd`；`ui_typography.gd`集中新增`character_title_font()`。`assets/characters/qingheng`包含兩張原圖逐byte複製、import與來源／用途／分層／提示詞／授權manifest。保留R2原稿／R3接受紀錄；原參考圖商用授權狀態不提升。runtime字型補本次缺字，原始OFL字型不改。新增`tests/maid_ui_runner.gd`及UID並登錄runner；既有navigation測試更新Era1遊歷回退／單頁計數，policy測試更新14route。docs19／12／48、README／ROADMAP／英文updata同步。
- **L1／L2 CLI**：本機`Godot_v4.7.2-stable_win64_console.exe --version`為`4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import` exit0。先執行`run_all_runners.ps1 -Only 'maid_ui_runner.gd,feature_navigation_runner.gd,ui_shell_policy_runner.gd,ui_shell_matrix_runner.gd' -List`，精選4支。初輪新頁高度／舊route數斷言失敗均已修正；matrix初次並行45秒逾時，工具自動串行重試41.4秒PASS，並未將逾時算成功。其後3支（maid／feature_navigation／ui_shell_policy）單尺寸L1全部PASS，最終新頁改共用看圖overlay後再精選maid runner PASS（37 checks，exit0、無SCRIPT ERROR），日誌`dao2_runners_33a6882a6cdc42d995ae010d2888d869`。狀態快照對照涵蓋兩分支、重播、看圖，未改GameState；保存工具遮罩／返回、跨頁互斥、洞府相機與群組記憶也通過。這是受影響領域L2，未跑L3、不宣稱全量回歸。
- **原生渲染**：使用隔離`DAO_TEST_STORAGE_ROOT`跑`--script res://tests/maid_ui_runner.gd`（1280×720），及僅新頁的`-- --maid-short`（800×360單尺寸診斷）；最後短式37 checks／exit0，人物／初遇／完整立繪原生PNG檢視通過。輸出在`.test-output/maid-native-final2/maid-ui`及`.test-output/maid-viewer-short/maid-ui`。新增短式診斷不擴成其他領域全尺寸矩陣；新runner預設仍按DAO_VIEWPORT_MATRIX只跑首尺寸。記錄了user://／shader-cache受限，以及既有場景anchor、退出時RID／ObjectDB告警；沒有把exit0當作記憶體無洩漏保證。
- **Web L2實測**：`--headless --path . --export-release Web build/web-maid-ui1/index.html` exit0（局部本機測試匯出，不是交付候選包）；`node tools/prepare_web_compression.mjs build/web-maid-ui1`完成。沙箱48341服務對Chrome不可達；正常權限僅綁本機的`python tools/web_static_server.py --port 48342 --directory build/web-maid-ui1`後連線成功。Chrome重載最終匯出，viewport讀值1280×720／DPR約1、canvas buffer1280×720（CSS讀值約1279×719）；瀏覽器error／warn紀錄空；使用滑鼠走遊歷→人物、點完整立繪、Escape回人物、初遇重溫、避雨回應→重新相遇→書卷回應、Escape回人物、CloseSeal回洞府，畫面與回應均正常。截圖在本次工具對話中；不將原生PNG稱為瀏覽器截圖。此獨立origin從空白建立測試進度，不讀／覆寫其他origin的玩家檔。沒有FPS或存檔落盤專項主張。48341沙箱測試服務已停止（Ctrl+C／exit1為人工中止）；48342本機試玩服務及人物頁分頁保留，暫時viewport override已重設。
- **通用收尾**：`python tools/subset_game_fonts.py --check`初次缺20字，生成runtime衍生字型後通過；原始字型保持。`python tools/trim_status_docs.py`、`python tools/delivery_check.py --web build/web-maid-ui1 --manifest assets/characters/qingheng/manifest.json`及`git diff --check`全部exit0／PASS，Web 7/7、原圖hash 2/2、受保護證據目錄0變更；清理由Godot import新產生的5份證據PNG import sidecar，既有JSON／PNG證據未改。工作區本輪前已存在美術／文件dirty成果，均保留；未commit／push。
- **界線／下一步**：本次MAID-UI-1呈現DoD完成，整體MAID-ART／仙侍大型任務仍IN_PROGRESS。沒有首次自動觸發、角色保存／遷移、好感、委派、任何收益或新schema；未開入口不推定核定核心。下一New Chat收正式Godot人物頁／初遇視覺回饋，再按需求補同立繪表情差分；首次觸發／系統核心仍須另行定義。可手動commit：本次為呈現階段結束，並非大型仙侍任務結束。

<a id="maid-art-r3"></a>
## 2026-11-01 MAID-ART-LAYOUT-R3：人物裝飾版（美術已接受）

- **使用者接受（最新）**：2026-11-01「美術接受，告訴我下一步」，R3人物美術／布局標 **ACCEPTED_ART_LAYOUT**，涵蓋本版人物、直式題字、畫框、朱印及書籤介紹；接受紀錄為 `docs/maid-art/qingheng/layout-r3-acceptance.json`。不將此回寫成代理瀏覽器測試已通過，也不推定仙侍委派／好感／收益已核定。此次僅更新接受metadata與交接，未改圖像／HTML／遊戲來源；JSON／UTF-8靜態檢查、delivery_check及diff-check通過。下方待審文字為當時歷史。
- **範圍／狀態**：使用者指定補人物裝飾介面、直式毛筆筆意「侍女・青蘅」與書籤字版。R3檔案已交，視覺／響應式審閱仍待完成，完整MAID-ART維持 **IN_PROGRESS**；未標正式Godot接入或整體DONE。
- **修改檔案**：新增 `docs/maid-art/qingheng/layout-review-r3.html`，保留R2原稿；人物左側直式身分／姓名、朱印、淡墨雙線框，右側燕尾書籤小傳與卷末句。沿原R2立繪／CG，未改圖像。復用既有LXGWWenKaiTC題字／敘事短句及SourceHanSansTW正文／操作；CSS裝飾、文字與圖像獨立。維持完整contain看圖、既有切換／回應／關閉預覽，短橫式縮內距／名籤與收朱印，正文內捲。docs19同步限定人物敘事題字方向；樣張README、根README／ROADMAP與updata更新，舊updata第5筆移archive。既有未提交成果保留。
- **驗收級別／命令結果**：僅HTML／文件靜態驗證，非L1／L2／L3遊戲驗收。Python檢查UTF-8、ID唯一、本地圖片／字型引用存在、直式題字及JS提取PASS；`node --check .test-output/maid-layout-r3/review.js` exit0；`python tools/trim_status_docs.py` exit0、無新增狀態歸檔；`python tools/delivery_check.py` RESULT PASS，受保護驗證目錄0變更。首次 `git diff --check`發現updata末尾多空行，移除後重查。
- **未完成／工具限制**：本機 `python -m http.server 48331 --bind 127.0.0.1` 與額外正常權限48332服務已嘗試；PowerShell探測48331通訊端遭權限拒絕，IAB第一次localhost導航逾時，第二次導航遭既有錯誤頁data URL政策拒絕，停止瀏覽器嘗試。未取得有效畫面、桌面滑鼠或尺寸驗證，不宣稱實際排版已通過。可雙擊R3 HTML檢視，切人物／初遇、點完整立繪及Escape返回，縮短橫式觀察正文內捲／固定關閉。未跑Godot runner或匯出，未改規則／schema／玩家存檔／build，未部署／commit／push。
- **下一任務（接受後）**：`MAID-UI-1`，建議New Chat接Godot人物頁與初遇展示，復用共用入口／GameTab／CloseSeal／UiTypography，實作直式題字、書籤字版與完整看圖；初遇先作可重播展示，不設首次觸發／保存／獎勵。L1精選受影響runner（先-List），功能完成一次L2桌面Web 1280×720抽驗；不因本階段升L3。先完成呈現，再按需要補同立繪表情差分；系統核心另議。可手動commit（本輪設計審閱稿checkpoint，整體大型任務未結束）。


<a id="maid-art"></a>
## 2026-10-31 MAID-ART-BASELINE-R2：E設定／透明立繪／角色頁與初遇構圖（審稿交付）

- **範圍與狀態**：依使用者「接角色設定基準、透明立繪與角色頁／初遇構圖」，完成本輪可審閱產物；新稿／布局接受仍待回饋，完整MAID-ART **IN_PROGRESS**，未將仙侍B／MAID-CORE視為核定。下方同日「設定／布局待製作」為本輪前歷史。
- **修改檔案**：`docs/maid-art/qingheng/character-baseline-r2.md`固定E成年身分、臉髮／衣飾／配色／性格、初遇文案與Godot容器接入對照；同目錄新增正側設定圖、透明立繪初稿／清理替代稿、雨夜初遇CG、`layout-review-r2.html`與`production-r2-prompts.json`／`production-r2-manifest.json`。README索引、根README／ROADMAP一行狀態與updata同步；既有未提交內容完整保留。
- **美術與切層**：內建image_gen共4次，均沿已接受E或本輪主立繪作參照。設定1536×1024 RGB、初遇1672×941 RGB（人物環境合層）；主立繪1024×1536 RGBA（人物／書筆合層）。上游例圖來源／授權未知沿R1保留，未新增外部圖參照。完整提示詞、原稿來源／hash、用途與接受邊界已保存。
- **目視／透明檢查**：主要臉型、藍髮藍瞳、白花金飾、青白竹紋衣與書筆連貫，初遇改護書姿態；未見明顯多肢，細部髮簪／刺繡仍有生成差異。主立繪alpha0–254、545069個全透明像素；alpha≥128包圍盒(21,22,1004,1516)，可見輪廓內縮約2%，未達提示詞5%目標。四邊最大alpha為0／0／1／0，左邊有極淡殘點。R2b清理替代稿未明顯改善留白，列NOT_SELECTED並保留；主立繪仍用R2供審。不能宣稱邊緣已獲正式美術接受。
- **布局**：寬式立繪46%＋右側人物介紹；緊湊橫式160px預覽＋內捲正文、獨立完整看圖；初遇CG與底部對話／兩回應分層。固定頁首／圖形關閉、18px正文、44px動作與直式旋轉提示沿既有方向。職掌／羈絆僅未開示位，無虛構好感、庫存與獎勵。HTML只是審閱工具，正式GameTab／CloseSeal／canonical route仍待Godot實作，不更改docs19共用通則。
- **驗收級別與命令**：美術目視＋文件／資產靜態檢查，非L1／L2／L3遊戲驗收。PowerShell Copy-Item保存4張內建原稿；Python/Pillow verify、尺寸／hash／alpha檢查4/4 PASS；Godot `--version`為4.7.2.stable.official.ed1daf0bf。僅版本查詢，未啟動遊戲runner或匯出。4組prompt／asset對應、SHA256／參照檔、嚴格UTF-8、HTML圖片／字型及Markdown本地連結、updata最近5筆檢查PASS；`node --check .test-output/maid-art-r2/review-script.js` exit0。`python tools/trim_status_docs.py` exit0、無新增歸檔；`python tools/delivery_check.py` RESULT PASS（12筆工作區變更、受保護驗證目錄0變更）；`git diff --check` exit0。
- **未驗／工具限制**：computer-use的Chrome新分頁控制回傳`Computer Use app approval timed out`；IAB開本地file URL被瀏覽器安全政策拒絕（僅准http/https），未繞過限制。沒有瀏覽器截圖、滑鼠或尺寸實測證據；HTML可雙擊人工審閱。首次嘗試讀取不存在的`docs/04-asset-production.md`失敗後以rg確認實際文件名稱，未影響產物。未改Godot來源、規則、schema、玩家進度或build，未部署／commit／push。
- **下一任務**：先審閱本輪臉／衣飾、透明輪廓、角色占屏與雨夜氣氛，若需修訂沿E及同一立繪局部調整；接受後另開New Chat接表情差分／正式接入範圍，不自動啟動CORE。可手動commit（本輪美術／構圖子階段交付，完整仙侍大型任務未結束）。

## 2026-10-31 MAID-ART：首位青蘅三畫風樣張（人物比較子階段交付，待選定）

- **使用者選定（最新，覆蓋下方待選歷史）**：使用者「接受 推薦」，採用推薦的 **E青藍書卷** 作青蘅主方向，確認成年女性、深藍長髮／藍瞳、青白漢服、溫柔書卷氣與細緻二次元呈現。D僅保留未採用候選，不視為核定另一角色。樣張畫風／造型選定子階段完成；完整MAID-ART仍IN_PROGRESS，角色設定基準、透明主立繪／差分與角色頁／初遇布局待下一階段。不由美術接受推定系統B／CORE已核定。
- **接受紀錄與驗收**：reference-r1-manifest.json記錄E的ACCEPTED_ART_DIRECTION、日期、原話與選定範圍；原PNG、提示詞與來源授權紀錄未變。樣張README、README／ROADMAP一行狀態與英文updata同步。純metadata／文件更新，僅JSON／原圖hash與通用delivery_check、git diff --check靜態檢查通過；未重跑遊戲測試、生成圖片、匯出或部署。下一New Chat沿E接設定與布局，不重問畫風。可手動commit（美術選定階段結束，完整仙侍任務未完成），代理未commit／push。

- **使用者例圖修訂R1（最新）**：使用者提供AI娘對照圖，指定參考GPT與文心一言角色風格。內建image_gen直接參照該圖各生成D銀白仙姬、E青藍書卷，保留成年角色定位，依例圖改為大眼二次元臉、銀白／深藍髮與繁複衣飾；不是原青蘅髮色／眼色鎖定稿。兩張已交付，風格／角色設定仍待使用者接受，整體MAID-ART IN_PROGRESS。
- **R1檔案與來源**：docs/maid-art/qingheng新增D／E原圖、reference-r1-prompts.json與reference-r1-manifest.json，樣張README新增兩圖對照；輸出均1024×1536 RGB、單層帶背景。參照為使用者Downloads原檔，只記路徑與SHA256，不複製為正式遊戲素材；其作者／授權未知，未聲稱第三方商用授權或生成圖獨占性。前輪A–C與其無外部參照紀錄原樣保留。
- **R1檢視／驗收**：臉、手與書筆／茶杯未見明顯畸形，全身可見；飄帶部分仍貼畫邊，正式立繪須補留白。PowerShell Copy-Item保存2張原稿；Python/Pillow verify、格式與hash／UTF-8／JSON／索引連結靜態檢查通過；通用delivery_check與git diff --check通過。僅美術／文件靜態檢查，未執行引擎、遊戲runner、Web匯出或瀏覽器驗收；未改遊戲／存檔／build。下一步由使用者選D／E或提出混合修訂，再於New Chat接設定與布局。本次修訂子階段結束，可手動commit，未commit／push。

- **授權與範圍**：使用者「接續首位角色樣張」，沿docs48首位候選青蘅製作同角三畫風比較。人物樣張交付子階段完成；完整MAID-ART仍 **IN_PROGRESS**，使用者尚未選畫風、臉型、魅力尺度與占屏比例；本指令不等同採納B系統規則或授權CORE實作。
- **交付**：[樣張索引](maid-art/qingheng/README.md)含A工筆仙氣、B日系仙俠、C成熟華麗，三張原稿均1024×1536 RGB；同目錄保存prompts.json與manifest.json（來源、參照關係、SHA256、格式、用途／切層與授權狀態）。內建image_gen共四次：A生成；B／C參照A轉畫風；B初稿過於接近A，再作B-r2，初稿未列正式交付。無第三方圖參照。
- **目視檢查與限制**：三圖成年人物、臉、茶具、雙手與服飾未見明顯畸形，B-r2線條／色塊與A、C有明顯差異；同角主要特徵保持，臉部比例仍隨風格變化。托盤遮住部分手指；左側飄帶觸及畫邊，正式立繪須擴留白。C以材質與光影加強華麗，臉型仍接近A。皆為單層帶背景樣張，非透明全身成品或正式UI截圖；角色頁／初遇布局尚未製作。
- **修改與驗收級別**：僅新增docs/maid-art/qingheng原圖與metadata、README／ROADMAP一行狀態、本節、英文updata與溢出歸檔。美術目視＋文件靜態檢查，非L1／L2／L3遊戲驗收；無Godot來源、規則、schema、玩家存檔、現有資產或build變更，未跑引擎／runner／匯出／遊戲瀏覽器驗收。
- **命令與結果**：PowerShell Copy-Item將三張內建生成原稿保存專案，Python/Pillow verify確認3/3可解碼、尺寸與RGB格式，manifest保存SHA256。Python靜態檢查UTF-8／JSON／原圖hash／樣張索引本地連結；`python tools/trim_status_docs.py` exit0、無需新增歸檔；`python tools/delivery_check.py` RESULT PASS（9筆變更，受保護證據0）；`git diff --check` exit0。沒有遊戲全量回歸聲稱。
- **下一步**：使用者比較A／B／C或指定混合，再以選定設計做角色基準與角色頁／初遇布局；選定前不批量產表情／CG、不接CORE。本次為人物樣張子階段結束，可手動commit；代理未commit／push。依Context Guard，後續布局／實作請New Chat接續。

<a id="maid-design"></a>
## 2026-10-31 MAID-DESIGN：侍女／仙侍系統與大型角色插圖（提案交付，待使用者選定）

- **範圍與狀態**：使用者表示現有工作已完成，itch.io 回饋畫面吸引力與女性角色不足，要求先提供DAO1侍女系統優化方案。本輪僅設計，提案已交付；系統／畫風／角色均 **PROPOSED**，未視為核定或遊戲實作DONE。
- **提案**：[docs48](48-maid-companion-system-proposal.md) 核對DAO1的maid／sword_maid糯美子、自動合成／建築／功法來源與Era3門檻，推薦首位前移練氣、具名女性角色＋有界委任＋三章羈絆＋大型立繪／兩張CG。首版一位青蘅，劍侍與丹師列候選擴充；保留現有持續製造，不另設新產出乘區。大圖覆蓋初遇、人物頁、可收合洞府展示與回憶，沿共用UI與canonical route。
- **檔案**：新增docs48，README／ROADMAP僅加狀態連結，updata頂部英文checkpoint並維持五筆；舊日期段落按既有trim工具處理。未修改Godot來源、規則、保存schema、現有資產或Web包；DAO1保持唯讀。
- **驗收級別與結果**：文件靜態檢查，非L1／L2／L3遊戲驗收。`python tools/trim_status_docs.py`僅歸檔README多出的舊日期段落；`python tools/delivery_check.py`為RESULT PASS，7筆變更且受保護證據0；7份變更文件嚴格UTF-8與提案／狀態本地目標存在檢查PASS。初次`git diff --check`指出updata末尾空行，修正後重跑exit0；無遊戲失敗結果。不啟動引擎、runner、Web匯出或瀏覽器。方案接受與美術效果尚未驗證，沒有新市場／留存數據。
- **下一步**：先收使用者對A純美術／B仙侍系統／C完整道侶的選擇，推薦B與首位同角三種畫風樣張。後續大型MAID-ART／CORE須New Chat接續，不在本輪展開；未commit／push，可手動commit（提案階段結束，系統大型任務尚未開始）。

<a id="sect-reform-ui"></a>
## 2026-10-31 SECT-REFORM-UI：宗門／守護獸操作與五獸四階圖稿接入（UI與美術已接受，L3完成）

- **2026-10-31 L3 完成（OpenCode，最新狀態）**：本節以下為 L3 前歷史；SECT-REFORM／CLOSE 已 **DONE**。環境 Godot `4.7.2.stable.official.ed1daf0bf`。首次 L3（`-Full -Parallel 3 -TimeoutSeconds 60`）為 121/160，39 支失敗；逐支修正後以 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 2400` 重跑，結果 **`SELECTED 160 RUNNERS PASSED (matrix=full)`**，日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_8d079eda9d9743ee98ffa241002498ae`、主控台 `.test-output/L3-full-final2.log`。2400 秒僅套用於已確認的長時模擬（supply 1493 秒、pills 551 秒、beasts 524 秒、talents 467 秒、story 300 秒、sks_p2 229 秒），未放寬任何斷言；其餘 runner 多在數十秒內完成。
- **修正範圍**：產品端修正 `src/simulation/sect_lineage.gd`（`life_peak_era` 為衍生值，不再阻擋直接設定境界的合法遷移）、`src/presentation/sect_panel.gd`（800×360 拜宗卡精簡版）、`src/presentation/ui_shell_controller.gd`／`management_workbench.gd`（精簡工作區高度與間距）、`src/verification/life_echo_fixture.gd`（reform-active 合成流程）。測試端更新 47 支：保存／codec 舊版 fixture、reform 候選提交後重讀 `session.state`、成就 64（48 正式＋16 傳承）、舊宗門 UI 固定 legacy 呈現、coroutine `await`、embedded 工作台斷言、`OUTPUT_FULL` 轉庫存語義、技能文字／按鈕幾何，及 `content_p2_supply_progression_runner.gd` 三處行為不變的快取。未放寬任何收益／數值斷言或保存契約。
- **Web 匯出與壓縮**：`tools/package_itch_web.ps1` → `[EXPORT] PASS`（log `.test-output/itch-20261031-104425-137/export.log`）、pack `20261031-104416-f5df180f`、13 檔、zip 148,485,704 bytes、SHA256 `e97cebd57116d05dd7262861ee722cd91adfa3aedae0a81bd498e6fec1bd350a`、`[web] itch-web: 7/7 files match compression.json`、`RESULT PASS`。
- **桌面三橫式**：以 `python tools/web_static_server.py --port 4492 --directory build/itch-web` 服務現行包，Edge 156.0.4314.50 乾淨 profile 驗 1280×720／844×390／800×360；三者 canvas 分別 1279×719／843×389／799×359、無文件溢出、storage `ready`、4 個 `dao2_saves:` 鍵、schema 6 保存、點擊 (88,664) 前後截圖不同；`consoleIssues`／`errors` 皆空。截圖與 `landscape-report.json` 在 `docs/verification/artifacts/sect-reform-l3-web/`。4492 原有舊 review server 已停止，改由靜態伺服器提供 itch 包；4491 逾時仍為歷史。後端為 `WebStorageAdapter` localStorage，不稱 IndexedDB。
- **交付檢查**：`python tools/delivery_check.py --web build/itch-web` → `RESULT PASS`、Web 7/7 hash 相符、`[git] 144 changed entries; head=f5df180f`。觸控／實機與冷啟動預算仍依使用者指令暫緩，未列為本輪阻擋；未發布 itch、未 commit／push。

- **2026-10-31 使用者接受與分工（L3 前歷史）**：使用者明確表示「五獸美術與閱讀密度接受。L3 我會交給OPENCODE 運行」。五獸四階圖稿及目前宗門／靈獸閱讀密度標為**ACCEPTED**；SECT-REFORM-UI本階段實作、L1／L2與人工接受完成，整批SECT-REFORM／CLOSE仍**IN_PROGRESS，L3待OpenCode**。本輪僅更新文件及美術metadata，沒有重跑runner、Godot import、Web匯出或瀏覽器驗收。以下待美術接受文字均為此前歷史，不再列為當前缺口。
- **OpenCode L3交接**：沿目前未提交工作區，先讀AGENTS.md及本節證據，不重做CORE／BEAST／UI。依既有工具先`powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Full -List`，再`powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 60`；60秒沿已測release約41–46秒所需，逾時／SCRIPT ERROR或串行重試失敗不得當通過。L3另需現行來源的正常Web匯出／壓縮及1280×720、844×390、800×360桌面瀏覽器三橫式，最後`python tools/delivery_check.py --web build/實際匯出目錄`。本地測試服務支援`--port 4492`；4491逾時保留歷史。合成review不替代正常包／自然流程，localStorage不得稱IndexedDB。既有未通過項按實際範圍保留，不以美術接受消除；不安排已暫緩的觸控實機，不把冷啟動預算作常態阻擋。
- **結果回填與邊界**：OpenCode將實際L3命令、版本／來源、runner群組／日誌、Web包hash、三橫式操作及失敗項回填本節後才判定整批DoD；本輪不宣稱全量通過。圖稿manifest／review索引已同步接受日期與使用者原話；無新視覺通則，docs19不需新增規範。代理不啟動L3、不代送外部訊息、不commit／push；可手動commit（UI接受階段結束，整批改版仍待L3）。

- **2026-10-31 接續驗收（本輪最新，L2桌面Web）**：使用者「接續驗收」，補完前輪未驗的1280×720桌面Web滑鼠／拒寫／重試／重載有界抽驗；整項UI與整批改版仍IN_PROGRESS，五獸個別外觀與閱讀密度待使用者接受，尚未執行唯一L3。下方「Web全部未驗」為前輪歷史，由本段範圍覆蓋。
- **環境與連線**：引擎`--version`確認4.7.2.stable.official.ed1daf0bf；4491本輪IAB、Edge及提升權限HTTP探針仍逾時（一般權限探針通訊端拒絕）。改用僅綁127.0.0.1的4492後Edge可達，不改防火牆／Proxy／安全設定；`python tools/sect_reform_ui_server.py --port 4492`為現行入口。工具新增可選port，撤下未接線的era4／era6情境選單，正確標示金丹合成起點。獨立origin與`dao2_sect_reform_ui_review_v1` namespace，不寫玩家保存。
- **滑鼠與落盤證據**：外窗1680×800、遊戲iframe1280×720；宗門委託→秘術、購太虛內景經0→1（貢獻10000→9920）；拒寫購2階時live仍1、revision6、pending=true，固定重試覆層可讀。恢復寫入點重試後2階／貢獻9800，只扣120一次。修正後最終包再拒寫購3階，仍2階／pending=true；恢復後3階／貢獻9620，只扣180一次，頁內正確顯示「保存已恢復，操作結果已保存。」。修行→靈獸、清單內捲至白澤，以12信物兌換：24→12、permit=true、active空；另按結契才建立白澤egg／XP0，資格保留；再正式餵養XP0→50。重載保留信物12、白澤資格、持獸與XP50、功法階數（重載時仍會按正式規則結算離線秒數，不宣稱revision或冷卻完全不變）。這是合成已資助起點與暫停線上時鐘抽驗，非自然時間通關、成熟／輪迴滑鼠流程或IndexedDB；實際後端localStorage。
- **本輪修正與L1**：首次恢復後發現SectPanel保留QuotaExceededError舊提示；`set_command_result`依權威pending候選標記待存，恢復時同步清提示與tooltip。修改`src/presentation/sect_panel.gd`、`tests/sect_reform_ui_runner.gd`，新增真實候選拒寫／同候選恢復回歸。先List三支後`run_all_runners.ps1 -Only 'sect_reform_ui_runner.gd,content_p2_sect_ui_runner.gd,m3b_sect_ui_runner.gd' -Parallel 3`→3/3 PASS／exit0／單尺寸，11.5／12.7／7.2秒；組`beda1f9aea0346f4936012426c968fc7`，新UI100 checks／failures=[]。摘要`.test-output/sect-ui-acceptance-l1.log`，輸出隔離guard無保護證據變更，未跑Full。
- **現行包與證據**：修正前後各`--headless --path . --export-release SectReformUiReview build/sect-reform-ui-review/index.html`均exit0；最終log`.test-output/sect-ui-acceptance-export-final.log`。最終`node tools/prepare_web_compression.mjs build/sect-reform-ui-review`exit0，PCK137339496 bytes／SHA256`6831f628327e0d43f6df1dbe29cc0bb6b021b47e57ce8bc78cca3793c62648f0`。瀏覽器補驗已重載此包；console warn/error查詢空。觀測`.test-output/sect-ui-browser.jsonl`；截圖`sect-ui-web-denied.png`、`sect-ui-web-beast-fed.png`、`sect-ui-web-recovered-final.png`均在`.test-output/`。未更新一般Web、未發布itch、未做候選包交付。
- **收尾**：`python tools/subset_game_fonts.py --check`、`git diff --check` exit0；`python tools/delivery_check.py --web build/sect-reform-ui-review` RESULT PASS、7/7壓縮hash相符、受保護證據變更0（摘要`.test-output/sect-ui-acceptance-delivery.log`）。沿既有素材，不重生成五獸；未由代理代替使用者接受美術。本階段可手動commit，代理未commit／push；依Context Guard在此checkpoint，下一New Chat收美術／閱讀密度與內容回饋，整批接受後才唯一L3。

- **狀態／範圍**：使用者指定`SECT-REFORM-UI`。本輪交付Godot原生接線與五新獸四階圖稿；完整UI及整批SECT-REFORM仍**IN_PROGRESS**。未執行L3、正式Web候選交付、發布或commit／push；原CORE／BEAST／hub／部署未提交成果保持。
- **呈現與操作**：拜宗卡補五宗取捨／每世一次與共通法保留；既有秘術分頁新增十專法（持有／當世啟用階數、逐階貢獻＋下石、Era／A前置、領域及秒數取整）、有效世3件進度及五條傳承揭露／1-3-5世／道心購買與休眠原因。舊身分未明可經正式命令確認。委託顯示已凍結信物／發現，已有資格轉+2，歷史委託不追贈；領取結果顯示實得與溢出。成就冊沿原圖印領取，16項新成就重用宗門插圖並顯示條件／有效世進度。
- **靈獸頁**：六舊獸＋五新獸共11張持久卡，新增永久資格來源（免費靈狐／舊檔權利／委託或信物）、12信物指定兌換與上限120；發現／兌換不自動結契，當世境界／產地／唯一獸槽仍由權威View禁用。新增20個種屬魂樹按鈕、五新獸實際餵費／下次XP與四階AtlasTexture。所有動作送既有Session／候選保存／receipt路徑，UI不改庫存或抽RNG。`GuardianDiscovery.redeem_requirements`與命令共用eligibility，View在一次完整release驗證後共用，不為10目標反覆驗證整份保存。
- **檔案**：新增`src/presentation/sect_reform_ui.gd`及UID、`tests/sect_reform_ui_runner.gd`及UID、隔離fixture／review場景與UID、`tools/sect_reform_ui_server.py`；修改SectPanel、BeastCareView、AbodeModalManager、FeatureNavigation、AchievementPanel及AchievementSystem／BeastSystem／GuardianDiscovery的唯讀投影。`living_abode.gd`僅加隔離namespace，`project.godot`／`export_presets.cfg`新增SectReformUiReview；run_all登錄新runner。正式共用GameTab／CloseSeal／字型／容器／44px沿用，沒有另立共用視覺通則。
- **圖稿與字型**：內建image_gen逐獸生成五張1254×1254 RGBA透明2×2成長圖；每張依左上卵／右上幼獸／左下成長／右下成熟分區，由AtlasTexture選取，不改規則或收益。五圖在`assets/ui/beasts-painted/sect-reform/`，manifest記來源、完整prompt、分區、SHA256、alpha0–255、用途與授權界線；未使用第三方參考圖，**個別外觀待使用者接受**，不宣稱商用法律清查或美術已接受。圖稿索引`docs/sect-reform/guardian-art-review.html`。`subset_game_fonts.py --check`初次缺14字失敗，已依既有工具重建兩套OFL衍生字型並更新manifest，最後check通過；原字型未改。
- **L1／L2證據**：本機Godot `4.7.2.stable.official.ed1daf0bf`；隔離APPDATA import exit0，UID由引擎產生。每組先完整selector `-List`；單尺寸1280×720、輸出皆`.test-output/`。`fab871eb008647b7b80e8a25d18a80fb`組的discovery（6.6–9.1秒）、content_p2_beasts_ui（18.7秒）、content_p2_sect_ui（13.8秒）各PASS，但新fixture當時失敗，整組exit1，不稱4/4。初輪m3b_sect_ui另PASS（8.3秒）；第一輪舊測試六獸數量與第一組功法定位不符，舊卡數斷言已同步11，未放寬舊成本／資格。共用成就／發現／完整保存依賴超過5支，按L2分組補驗，沒有Full。
- **最終專項／保存領域**：`sect_reform_release_runner.gd,sect_reform_lineage_runner.gd -Parallel 2 -TimeoutSeconds 60` →2/2 PASS／exit0（41.2／14.7秒，`4ceda551362d4ab2affb5e14bd666235`，摘要`.test-output/sect-ui-core-final.log`）；release原已知約41–46秒，沿合理60秒。現行`m3b_achievement_runner.gd` PASS／3.4秒（`1d9bdd6ff6804940a99c8cf615b01033`，當組新codec fixture仍失敗）。最後`sect_reform_ui_runner.gd,sect_reform_discovery_runner.gd -Parallel 2` →2/2 PASS／exit0，8.9／6.6秒（`31b07c7f60574ae993c7ad58f040e7bc`，摘要`.test-output/sect-ui-final4.log`）；新UI **95 checks／failures=[]**，含完整codec、十法／11獸／20天賦、內捲可達、持久滑鼠目標、發信號不改狀態／RNG、四階圖選擇與16項成就插圖／條件。上述共8支不同runner各有PASS，不是一次全量回歸。
- **額外失敗及修正**：合成fixture先填1有效世但總世數0，被SECT_LINEAGE_TOTAL正確拒絕；補世序後完整codec先後揭露STORY_CURRENT_LIFE／LEDGER_LIFE_ID，已同步合成敘事／帳簿，新增codec斷言，正式遷移未放寬。額外試跑未登錄的`uix_r6_achievement_ui_runner.gd`，615 checks但失敗（`52d56f7ffbb449dd81194affe5e5ee7f`）：寫死48卡及舊保存失敗後live發獎語義，與現行候選保存不符；未將它加入固定runner或聲稱通過。本輪新UI專項補16新成就圖與進度，現行成就／lineage／release runner各PASS；該歷史測試仍待日後獨立更新。
- **Web／瀏覽器限制**：`SectReformUiReview`本機隔離包匯出exit0；合成fixture不屬自然流程，backend實為**WebStorageAdapter localStorage**，不能稱IndexedDB。headless review最終抵達`SECT_REFORM_UI_REVIEW_READY`／exit0，無SCRIPT ERROR；強制quit的字型／CanvasItem／ObjectDB釋放警告仍在，不當作渲染或滑鼠證據。`127.0.0.1:4491/review.html`內建瀏覽器兩次ERR_CONNECTION_TIMED_OUT；本機服務啟動含正常權限與工具提升權限，唯讀HTTP探針仍逾時。切換本機Edge後Computer Use因無法可靠識別目前網址、無法執行政策而**中止當輪電腦操作**；未再繞過、未實際點任何遊戲動作。故1280×720真滑鼠／拒寫／重試／重載與畫面可讀性全部未驗，不能以CLI取代。review可用後人工依序：宗門秘術購A1→靈獸12信物兌換→另按結契→餵養；開頁首拒寫後作另一筆合法命令→確認live未重扣、固定重試→恢復正常重試→重載核對同一資格／信物／獸與階數。
- **交付檢查**：`python tools/trim_status_docs.py`僅歸檔README／ROADMAP超過3筆的前言；`python tools/subset_game_fonts.py --check`最終exit0。`python tools/delivery_check.py --web build/sect-reform-ui-review` RESULT PASS、Web 7/7 hash相符、受保護證據變更0；`git diff --check`初抓updata尾端多空行，移除後exit0，僅既有LF／CRLF提示。updata保留恰5筆、舊第五筆移至`docs/archive/updata-2026-10-31-sect-ui-trim.txt`。最後僅review harness補暫停時鐘下同正常preflight的pending保存提示，CLI smoke抵達READY／exit0；此小修在包後，沒有冒用包作本輪瀏覽器證據，下一輪須重匯出。
- **交付與下一步**：下一New Chat先恢復桌面瀏覽器可控連線，直接使用本輪來源重新局部匯出並完成一次L2真實互動與原生畫面驗證；再收五獸／宗門閱讀密度與內容接受。這是UI接線檢查點，**未達整項UI DoD**；整批接受後才唯一L3，不重做BEAST1/2/3。可手動commit（階段檢查點，非整批改版結束）；代理未commit／push。


<a id="sect-reform-beast"></a>
## 2026-10-31 SECT-REFORM-BEAST-3：祖父權利／完整版本遷移與保存接線完成（L2，整批SECT-REFORM IN_PROGRESS）

- **範圍／狀態**：使用者「BEAST-3：祖父權利及完整版本遷移」，其後「繼續」。本子段DONE：六舊獸逐種祖父權利、完整schema6／sect3／talent4／beast2、原文歸檔與同候選保存、正常啟動、正式命令層結契／養成與唯讀View已整合。這是規則／原生保存交付；五新獸美術、宗門／靈獸操作UI與Web實際保存互動留SECT-REFORM-UI，完整改版仍IN_PROGRESS，未以本段宣稱可交付Web包或美術完成。
- **修改檔案**：新增`src/persistence/sect_reform_release.gd`及UID、`tests/sect_reform_release_runner.gd`及UID；修改`beast_save_contract.gd`、`sect_save_contract.gd`、`save_codec.gd`、`save_manager.gd`、`beast_system.gd`、`guardian_discovery.gd`、`talent_system.gd`與runner登錄。`sect_reform_save.gd`／`guardian_beasts.gd`更新歷史候選註解；`sect_reform_guardian_runner.gd`改驗「部分beast2仍不可保存」、`content_p2_beasts_save_runner.gd`把未知未來獸版本案例由2改3，保留「beast2配舊版本集」的拒讀案例；`sect_reform_save_runner.gd`正常主場景斷言改驗完整發行版本。README／ROADMAP只留一行入口，docs47記技術契約，updata保留最近5筆。前輪CORE／hub／部署工作保持；未改參考專案、玩家進度或commit／push。
- **祖父權利**：永久ledger擴成`sect.guardian={version:1,guardian_tokens,permits,legacy_permits}`；legacy固定六舊物種白名單true旗標，五新獸不能冒充legacy。從未變更來源逐種檢查：當世active、同種魂>0、同種已學天賦，或原物種Era／原供給條件符合，即給永久legacy資格；忽略唯一槽占用與壽盡，不依highest_era回填未符合權利。原龜／鳳legacy不新增deep／ancient門檻，鹿／鶴仍保留原開島與版本門檻，雲蛟legacy沿原Era8，不能拿券繞原當世境界。新許可採BEAST-2池與新來源；靈狐繼續免費。已有legacy許可的重複發現亦轉+2信物，不另發新券，兌換已擁legacy目標拒絕不扣。
- **遷移／版本**：`SectReformRelease.prepare`只從已驗證／已提交且與live一致的原文組成完整候選。無CORE者在同候選建立身分／十法／lineage／私有RNG；已啟用CORE者保留原core_save來源身分、RNG游標、lineage與新信用任務，不重播或重新播種。五新魂鍵與二十天賦鍵初始化0、信物0、新permits空；不送新獸、不回填歷史宗門世數。舊獸XP／stage／cooldown、魂樹、八法／貢獻／限購、舊任務／剩時／資源、hub已付工作／真實在途貨物／政策與庫存不改。正常`commit_sect_reform_startup`在離線／開操作之前完整遷移；完整狀態重啟不重發。歷史模組VERSION基線1／2／3與舊測試初始狀態保留，完整發行版由`SectReformRelease`統一提交3／4／2；唯讀decode不暗升版。
- **codec／邊界**：完整狀態才寫schema6、rules=`core-flow-26-sect-reform-1`及content尾標`+sect-reform-1`；hub_version1、Amount1、generator1與hub實際規則仍保留，不以舊rules字串優先序遮蔽本次改版。可唯讀解碼schema2–5，尚未提交改版的歷史狀態維持schema5，不能把三個feature版本拆開升級、把新ledger塞回舊schema或拿schema6包舊狀態。拒絕未知ID／非法legacy旗標／缺新鍵／跨獸天賦前置／active無資格、錯配task世序／宗門、錯誤rules/content標記，以及近整數小數schema／talent版本。TalentSystem.reconcile不把4降回3。任何保存槽含未來schema>6時，load／普通save／候選重試均停止，不能因另一槽較舊而覆蓋未來原文；兩槽原字串保持。
- **候選交易／復原**：重用CORE同一歸檔／候選／receipt機制，精確原文含空白與checksum以hash歸檔並讀回；衝突原文先救援到damaged hash再修復。拒寫／拒讀／不符時live不變，凍結同一JSON、權利、版本與RNG；全部Session命令／時間及替代import阻擋，匯出精確原文。已落盤但回應／index遺失時讀兩槽逐位元組辨識完整候選，正常恢復最高有效世代，避免重扣。未落盤重啟回最後有效舊世代；重新準備的權利／seed／完整語意相同，但歷史JSON數字往返可能使文字表示不同，因此不聲稱未持久化候選跨程序的字串完全相同；同次pending重試及已落盤恢復則驗精確bytes。兌換、結契、餵養、買獸魂天賦、領派遣與輪迴均用原Session白名單／revision／receipt，重載receipt不再扣料／發魂／加信用。
- **正式規則／View**：五新獸可由`acquire_beast`以權威許可ledger自主結契，仍驗Era3、herb、空槽、未壽盡；每世唯一名額涵蓋11獸，許可不消耗。舊獸按免費／legacy／新許可來源驗資格，未遷移的隔離beast2不能當正式結契入口。新獸餵料View接同一成本helper；View新增五獸care／11獸requirements／資格來源ledger，不帶保存hash、不抽RNG、不改狀態。一次View只驗完整ledger一次，再共用同一取得helper，避免逐物種重複序列化整份保存。原六獸24天賦的UI定義不以未製作素材硬擴；本輪沒有改Control、字體、卡片或美術。
- **L1／L2命令與結果**：Godot `--version`=`4.7.2.stable.official.ed1daf0bf`；初次與最終隔離headless editor `--import --quit`驗引擎與UID，未更新環境。每輪先同完整檔名selector `tools/run_all_runners.ps1 -Only '...' -List`，APPDATA／輸出隔離，matrix=single1280×720。首組五支`sect_reform_release_runner.gd,sect_reform_save_runner.gd,sect_reform_discovery_runner.gd,sect_reform_guardian_runner.gd,content_p2_beasts_save_runner.gd -Parallel 3 -TimeoutSeconds 45`，四支舊runner PASS，新專項失敗，整組exit1（`9e2b6c5955b24dd187883a45216fd6d1`），不稱5/5。完整保存／codec／啟動／離線／輪迴等共用依賴超過5支，按L2分組補驗，沒有Full。`sect_reform_release_runner.gd,sect_reform_save_runner.gd,m1c_persistence_runner.gd -Parallel 3 -TimeoutSeconds 60` → **3/3 PASS／exit0**（`632541e4b4064e75ac7b9dd615ffab7e`，41.7／22.0／3.9秒；保存356項），摘要`.test-output/beast3-save-domain.log`。新專項此前實測33.8–41.7秒、舊保存曾並行45.1秒，故本組合理上調60秒，沒有把逾時當通過。
- **領域／最終專項**：`m1d_offline_runner.gd,m3a_reincarnation_runner.gd,content_p2_talents_runner.gd,content_p2_sect_save_runner.gd -Parallel 3 -TimeoutSeconds 45` → **4/4 PASS／exit0**（`4cf73479e30347c3bfe5b019f135fbc3`，4.5／3.2／6.1／9.3秒），摘要`.test-output/beast3-dependencies.log`。最後View共用驗證／命令同值補齊後，單支先List再`-Only 'sect_reform_release_runner.gd' -TimeoutSeconds 60` → **750 checks／failures=[]／exit0／46.2秒**，日誌`63f237fe453241c28095a9bf378e6423`，報告`.test-output/dao2_runners_63f237fe453241c28095a9bf378e6423/docs/verification/artifacts/sect-reform/release.json`，摘要`.test-output/beast3-final.log`。本輪累計十支不同runner各有PASS證據；不是一次全綠或全量回歸。四凍結任務代表payload實測3921 bytes，保留32KiB cap。
- **案例／過程失敗**：六獸各Era／來源、占槽／壽盡／歷史投資資格，無免費新券；歸檔拒寫／拒讀／衝突救援、候選拒寫／隱藏讀回／回應遺失／index失敗、pending重試／雙import阻擋／未落盤與已落盤重啟、schema2–5鏈及未來版本原文保護；六種命令各四種保存故障、收據重放／重載不重扣；真實私有流生成發現→正式派出／模擬完成→領許可→結契→20次正式餵命令與19段模擬冷卻成熟→正式壽盡輪迴1魂→T1→二世保存重載、下世Era／來源不足仍拒結契；另隔離FileStorageAdapter新Godot程序驗許可／餵養Amount與receipt。非自然完整遊玩或WebIndexedDB證據。最初新runner函式誤名seed與全域同名造成parse失敗（`d8ffdeab13c046959377c3941a54991f`）；首組及串行重試仍失敗，因測試把JSON數字往返的字典／文字差異當重抽、hub fixture漏下石／解鎖、CORE fixture重用舊Memory槽；其後單支`8b13d538017e43f29711bbc53feac315`仍有兩斷言失敗。已修fixture與比對界線，保留原失敗，不放寬正式權利或codec。`e964bd0509de4358aa2ac3b74d039538`單支33.8秒先通過，再加完整20餵／未來版本／View等案例形成上述最終750。
- **交付檢查**：最終`--headless --editor --import --path . --quit` exit0，`.test-output/beast3-final-import.log`無SCRIPT ERROR／Parse Error，兩新檔UID均由引擎生成。`python tools/trim_status_docs.py`無需歸檔前言；`python tools/delivery_check.py` RESULT PASS，受保護證據變更0；`git diff --check` exit0（既有部署／舊測試LF／CRLF提示保留）。本輪來源／測試／文件嚴格UTF-8及updata恰5筆檢查通過，舊CORE-2交接移`docs/archive/updata-2026-10-31-beast3-trim.txt`。
- **交接／下一步**：下一New Chat接`SECT-REFORM-UI`，讀docs19／07及docs47，製作宗門／發現與信物／許可來源／自主結契操作、五新獸美術（個別外觀尚未接受），合併一次當次包的L2桌面Web真滑鼠／保存拒寫重試與重載；不要把本輪CLI與FileStorageAdapter證據冒充Web。核心規則／遷移已完成，不重做BEAST-1／2／3或先跑全量。整批UI／內容／美術核定後才唯一L3收尾。依Context Guard於本子階段停車，英文checkpoint已更新；可手動commit（子階段結束，非整批宗門改版結束），代理未commit／push。

## 2026-10-30 SECT-REFORM-BEAST-2：凍結發現／信物／永久許可隔離核心完成（L2，完整BEAST IN_PROGRESS）

- **範圍／狀態**：使用者「BEAST-2」接續本日BEAST-1，以docs47第二稿§5.3–5.5作規則基準。本子段DONE：凍結發現、永久許可ledger、信物保底／重複轉換／滿額、指定兌換與固定五抽完成隔離實作。完整BEAST／SECT-REFORM仍IN_PROGRESS；祖父權利、完整schema6／sect3／talent4／beast2遷移及正式結契入口留下一段，沒有新增UI／美術或聲稱玩家已可使用。
- **修改檔案**：新增`src/simulation/guardian_discovery.gd`、`tests/sect_reform_discovery_runner.gd`及各UID；修改`sect_system.gd`、`command_processor.gd`、`game_session.gd`、`sect_reform_save.gd`、`sect_save_contract.gd`、`tools/run_all_runners.ps1`。`m3b_sect_ui_runner.gd`／`m4a_session_integration_runner.gd`同步刷新不得force的契約，等待模擬300秒再刷新；後者舊fixture未知宗名改正式太虛名，不放寬未知宗名拒絕。README／ROADMAP僅狀態入口，docs47記資料形狀，updata保留最近5筆英文交接。既有CORE／hub／部署未提交成果保留，未commit／push，未寫玩家進度。
- **抽樣／凍結**：候選專用流每槽固定品階→模板→貢獻→事件→種類五個next，三槽15步；事件未中、Era不足或池空仍消耗後兩值。品階固定順序，模板按穩定ID排序，匿名舊模板固定`legacy_{rarity}_{index:02d}`，池按固定ID排序／整數權重累加。同宗新獸權重3、其餘1，不改事件率（史詩10%、傳說20%）；資格已持有亦留池。依實際Era與herb／deep／ancient開啟判池，靈狐不入池；雲蛟尚無完整正式餵料供給，Era8亦不臆造新來源放行，十項許可白名單保留其ID。新task獨立`guardian_reward`存版本、pool版本、生成世序／Era／宗ID、token_base、permit_id、排序池與來源布林，沿原`lineage_credit`，不塞進8鍵資源reward字典。`guardian_template_id`供穩定模板核對，不存RNG抽值或抽樣歷史。
- **領取／兌換**：永久資料為`sect.guardian={version:1,guardian_tokens:0..120,permits:{固定ID:true}}`，不屬資源庫存。每合格新委託領取+1；新資格記true，重複另+2；120飽和，事件明列tokens_gained／tokens_overflow，原凍結材料照常發放。當世已持獸仍可收資格，不發魂、不自動占獸槽。新`redeem_guardian_permit`僅接受`{target_id}`，未壽盡／已入任一宗／當下供給與Era／未持資格／足12信物才原子扣12並給許可；不接受permit_owned等玩家授權布林。領取先驗凍結欄位、版本、世序／身分與完成時間，不依現時降境／失去來源／壽盡剝奪已凍結資格。舊委託無metadata不補發信物／資格，也不補lineage信用。刷新／派出在候選壽盡後拒絕，玩家force刷新不能跳300秒，內部首次入宗與原空候選免等保持。
- **保存／發行邊界**：沒有啟動新遷移、免費授權或臨時保存flag；ledger只在隔離beast2候選中建立，正常startup不初始化。正式schema5／sect2／talent3／beast1與rules／content hash未升版；codec仍拒絕beast2，並明確拒絕把ledger或新task欄位偽裝成sect2／beast1。`permit_owned`從經驗證ledger讀值，尚未接正式新獸結契。新兌換命令已列Session及`SectReformSave.COMMANDS`，沿同一候選／receipt／revision路徑，沒有另造發獎保存機制；本輪驗的是候選命令去重及既有CORE保存交易回歸，**不宣稱新ledger已可落盤、拒寫重試／重載或Web保存已實測**。這些須下一段完整版本遷移後驗證。
- **命令／驗收級別**：本機Godot `--version`=`4.7.2.stable.official.ed1daf0bf`；隔離APPDATA的`--headless --editor --import --path . --quit` exit0，UID由引擎生成。先以完整runner檔名同selector `-List`再執行。首組L1：`tools/run_all_runners.ps1 -Only 'sect_reform_discovery_runner.gd,sect_reform_guardian_runner.gd,sect_reform_save_runner.gd,sect_reform_lineage_runner.gd,content_p2_sect_save_runner.gd' -Parallel 3 -TimeoutSeconds 45` → **5/5 PASS／exit0**（新專項當時1307 checks），日誌`deae99e316174cd1967be693c2c134b6`，摘要`.test-output/beast2-l1.log`。共用宗門生成／保存／命令與force政策依賴超過5支，合併按L2領域：另選`sect_reform_discovery_runner.gd,content_p1_sect_runner.gd,content_p2_sect_runner.gd,m3b_sect_ui_runner.gd,m4a_session_integration_runner.gd`同參數，四支既有runner PASS（5.1／16.5／5.4／4.9秒），新專項擴充fixture當時失敗，整組exit1，不稱5/5。最終單支先List再`-Only 'sect_reform_discovery_runner.gd' -TimeoutSeconds 45` → **1510 checks／failures=[]／exit0／5.5秒**，日誌`0042c98e5b4247ec8fec669277cd0c34`，報告`.test-output/dao2_runners_0042c98e5b4247ec8fec669277cd0c34/docs/verification/artifacts/sect-reform/discovery.json`，摘要`.test-output/beast2-final3.log`。累計九支不同runner各有PASS證據，單尺寸1280×720；沒有Full／L3／Web匯出／瀏覽器或自然等待聲稱，測試檔涉及UI僅驗命令相容，正式UI未修改。
- **案例／過程失敗**：涵蓋Era1–8×8來源組合、池數／單目標／權重左右邊界、兩事件率邊界、75槽與全域RNG／多次View獨立、精確15步、正式派出→模擬完成→正式領取12次／lineage只計一次、跨宗兌換、先兌換後領取變重複、滿120溢出、降境／壽盡後領凍結資格、legacy0新獎、固定ID／型別／NaN／無窮／負值／世序／宗ID／模板錯配及額外payload原子拒絕、候選receipt去重、宗門輪迴清理保留永久ledger。擴充View案例初用簡化economy缺inventory／正確供給版本／facilities，先後三輪`fad95681e73a41dd90815cbfb6dbd68f`、`f925e51cc5f94db1be1cc7e8ac1290ee`、`aa3ce48d20dc4fd7a4bfa146d1da758b`雖顯示內部1395檢查無斷言失敗，仍因SCRIPT ERROR被工具正確判失敗，未計成功。已改用既有`IslandProgression.command(...,"activate_islands",{})`建立完整fixture，最終無SCRIPT ERROR。這些是測試fixture修正，沒有為錯誤放寬正式經濟驗證。
- **交付檢查**：`python tools/trim_status_docs.py`無需歸檔前言；`python tools/delivery_check.py` RESULT PASS，受保護證據變更0。首次`git diff --check`抓到updata末尾額外空行，已移除並重驗。updata僅保留5筆，舊CORE-1交接移`docs/archive/updata-2026-10-30-beast2-trim.txt`；本輪新來源／測試／文件嚴格UTF-8檢查及最終`git diff --check`通過。
- **交接**：下一New Chat接`SECT-REFORM-BEAST-3`（祖父權利＋完整發行版本遷移／保存＋正式結契規則，名稱為本輪交接細分），沿docs47§7逐種保留原六獸權利、舊派遣／魂樹／已付hub工作與貨物，歸檔原文、凍結同一候選／seed／receipt、拒寫重試及讀回已提交辨識；成功後才開新許可／結契／View。不要把本段隔離ledger稱為已保存／玩家可操作，不另算lineage_credit，不製作未核定外觀。完整BEAST後再UI／美術，整批最終收尾才一次L3。本子階段結束，可手動commit；依Context Guard停止展開下一階段。

## 2026-10-30 SECT-REFORM-BEAST-1：五獸養成／效果隔離核心完成（L1，完整BEAST IN_PROGRESS）

- **範圍／狀態**：使用者「BEAST」接續CORE-SAVE，以docs47第二稿作本段規則實作基準。BEAST-1 DONE：五物種／二十固定魂樹天賦、養成／壽盡限制、同種結魂與共用效果接入並完成隔離驗證。完整BEAST／SECT-REFORM仍IN_PROGRESS；發現、信物、永久許可、祖父條款、整批版本遷移及正式結契尚未交付。五獸名字沿候選，個別外觀與美術接受另段。
- **修改檔案**：新增`src/simulation/guardian_beasts.gd`及UID、`tests/sect_reform_guardian_runner.gd`及UID；修改`beast_system.gd`、`sect_specialization.gd`、`lifespan.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`tools/run_all_runners.ps1`。前輪CORE／hub／部署未提交工作保留，未寫玩家進度、未commit／push。
- **規則／效果**：五獸獨立魂鍵、天賦ID完整白名單；同種四階費1／2／3／5魂，XP50／65／75、草費50／30、300秒冷卻，完整養成20／16／14餵，滿樹420草／65分鐘冷卻。舊靈狐／龜鳳功法與宿慧不擴及新獸；卵不受T1啟動被動，跨獸不加XP／減費／付款。白澤修速、狻猊／芝靈兔白名單採集、蓮心象壽元與星紋貘lingli容量接既有權威helper；新同軸與專法／傳承相加，原六獸乘區維持。原生被動不限所屬宗門；餵養及買魂樹在壽盡後拒絕，不能靠象T1復活。既有輪迴流程只結當世實際物種1魂，溢位整筆拒絕保留原世。prepared在無島時亦檢查獸種／stage／天賦signature；beast2隔離候選離線回逐秒權威路徑。
- **正式保存邊界**：本段沒有升版。schema5／sect2／talent3／beast1、rules及content hash維持；`GuardianBeasts.VERSION=2`只識別測試中的未發行候選，正式codec仍拒絕beast2，亦拒新ID冒充beast1。原六獸／24天賦註冊與現有UI清單不變。新獸正式`acquire_beast`保持拒絕，沒有可讓玩家傳入permit布林的命令；隔離資格helper的permit_owned只供未來權威許可ledger呼叫，不能當授權來源。沒有新增暫時保存flag或發免費資格；下段須完成完整許可／遷移後才開結契及View／UI。
- **驗證／命令**：本機`Godot --version`=`4.7.2.stable.official.ed1daf0bf`；`--headless --editor --import --path . --quit` exit0（既有user://開啟及巢狀project警告保留）。L1先`-Only 'sect_reform_guardian_runner.gd,m3b_spirit_beast_runner.gd,content_p2_beasts_runner.gd,sect_reform_effects_runner.gd,sect_reform_save_runner.gd' -List`確認5支，再同selector `-Parallel 3 -TimeoutSeconds 45`、隔離APPDATA，四支既有runner PASS（3.2／13.7／4.7／18.6秒），日誌`a08a73fae5264117b7bd4047095174db`；該輪新runner失敗，因此整組exit1，不能稱5/5通過。修正新runner後先List再單支重跑，最終**2555 checks／failures=[]／exit0／4.5秒**，日誌`b86d415172e941edb094a8449801fd96`，報告`.test-output/dao2_runners_b86d415172e941edb094a8449801fd96/docs/verification/artifacts/sect-reform/guardian.json`。累計5支不同runner各有通過證據，單一尺寸；含成長邊界、Amount扣料、跨物種隔離、完整規則輪迴、同層34%、線上離線完整快照一致與codec防誤放行。沒有Full／L3、Web匯出或瀏覽器聲稱。
- **過程失敗**：新runner首輪float推斷parse失敗，修正後前版2522項檢查無失敗但漏`RunnerResult.finish`標記，工具正確判失敗；補完整輪迴案例時誤把事件內gained_beast_souls當頂層，發生SCRIPT ERROR，亦未計成功。已改事件讀取及結果標記，最終報告如上。
- **交付檢查**：`python tools/trim_status_docs.py`無需歸檔前言；`python tools/delivery_check.py` RESULT PASS、受保護證據變更0；`git diff --check` exit0（既有部署LF／CRLF提示保留）。`updata.txt`保留最近5筆，舊條目移`docs/archive/updata-2026-10-30-beast1-trim.txt`。
- **交接**：下一New Chat接`SECT-REFORM-BEAST-2`，實作凍結發現／信物／永久許可及五抽值固定步數，保留lineage_credit與CORE候選保存交易；再接祖父條款與完整schema6／sect3／talent4／beast2遷移，驗收通過才開正式新獸入口。不得把本段隔離測試當成新版本可保存或玩家可操作證據；UI／素材另段，整批最終收尾才一次L3。本子階段結束，可手動commit；依Context Guard停止展開下個大型階段，英文checkpoint已更新。

<a id="sect-reform-core"></a>
## 2026-10-30 SECT-REFORM-CORE-SAVE：整批核心保存整合完成（L2，完整發行整合仍IN_PROGRESS）

- **任務／範圍**：使用者「整批保存整合」接續CORE-3。本子段DONE：精確原文hash歸檔／損壞歸檔救援、完整CORE候選、確定性宗門RNG、候選讀回／已提交receipt辨識、拒寫同候選重試、重載與正常Godot啟動均接入。完整SECT-REFORM／CORE發行整合仍IN_PROGRESS；五新獸、信物／發現／許可及祖父條款與schema6／sect3／talent4／beast2留BEAST整合，不以常數升版冒稱完成。正式新操作UI另段；沒有Web匯出、瀏覽器IndexedDB、自然節奏或L3聲稱。
- **修改檔案**：新增`src/persistence/sect_reform_save.gd`及UID、`tests/sect_reform_save_runner.gd`及UID；修改`src/persistence/save_manager.gd`、`sect_save_contract.gd`、`src/application/game_session.gd`、`src/simulation/sect_system.gd`、`src/abode/living_abode.gd`及`tools/run_all_runners.ps1`。docs46／47記實際契約與發行邊界，README／ROADMAP僅狀態入口，updata維持最近5筆英文交接。進場前部署、hub與CORE-1／2／3未提交成果完整保留；沒有commit／push、來源參考專案或玩家進度寫入。
- **遷移／歸檔**：`activate_sect_reform`驗證最佳有效槽與live來源一致、save_id相符，duplicate_state組合核心欄位。`sect.core_save={version:1,source_hash,save_id}`保存來源識別；未知舊宗名保留待確認，未入宗清ID，已知舊名為權威。已有十法／lineage保留，缺者初始化feature與當下peak／0歷史，舊委託／活動派遣、舊獸、hub已付工作／貨物／政策／庫存不改。原文包含空白及checksum存`save_before_sect_reform_{sha256}`並讀回；同鍵異內容先寫damaged hash並讀回，再恢復原文。歸檔拒讀／拒寫／不符時停止；重試保留同一候選，遷移中share export回傳精確原文。舊schema2–5／sect0等先走既有遷移及各自原文歸檔，再接CORE。schema5／sect2／talent3／beast1、hub rules／content hash不變；core_save的save_id為種子來源身分，不限制日後分享匯入另存新有效save_id。
- **交易／恢復**：啟用後宗門命令、learn_talent、claim_achievement、輪迴及現有acquire／feed／beast talent透過同一Session白名單、expected_revision及receipt，僅在候選扣料／結算；凍結完整JSON後兩槽提交／讀回，再換live。失敗時原live不變、禁止全部Session命令／時間／離線與第二次import；既有save重試只能提交同候選。逐位元組比對含receipt、費用／獎勵、RNG、revision與save_id的完整候選，識別寫入成功但回應、讀回或index失敗；依SaveSlots既有最高有效revision恢復，可讀回已持久化候選即認定提交，不要求舊index仍指向它。讀取未可信／不同較新有效revision仍阻擋，不覆寫別世代。重載若沒持久化恢復最後成功世代；已持久化則receipt去重，不重扣／重算宗門世數／獸魂。輪迴候選補齊library／scripture_hall零級，避免重載額外revision；新receipt中的Amount轉serialize字串，不留Object顯示ID。
- **RNG／正常接線**：來源save_id＋原文hash＋固定`sect-reform-1`標籤導出`sect.rng={version:1,state:u32}`；只啟用後的未來宗門任務改用SeededRandom，稀有度／模板／貢獻消耗獨立保存流，View與拒寫重試不重抽。未啟用的歷史規則呼叫保留原global RNG。正常`living_abode._init_core`先完成既有遷移保存，再`commit_sect_reform_startup`，CORE候選成功才離線結算／開操作；新檔先保存基線再歸檔。候選待存時_process不推進規則，重用既有保存錯誤／15秒重試；Web重試先提交凍結候選，再從已提交cursor結算，沒有另造UI樣式。此Web分支僅有來源／CLI證據，本輪未更新測試包／瀏覽器，不能稱IndexedDB實測通過。
- **L2命令／結果**：Godot `--version`=`4.7.2.stable.official.ed1daf0bf`；初次與最終隔離`--headless --path . --editor --import --quit`均exit0，最終`.test-output/sect-save-final-import.log`無SCRIPT ERROR／Parse Error，UID由引擎產生。每組先同selector `tools/run_all_runners.ps1 -Only '完整runner檔名列表' -List`，APPDATA隔離`.test-output/sect-save-appdata`、matrix=single1280×720、timeout45。CORE五支`sect_reform_save_runner.gd,sect_reform_identity_runner.gd,sect_reform_effects_runner.gd,sect_reform_lineage_runner.gd,content_p2_sect_save_runner.gd -Parallel 3` → **5/5 PASS／exit0**，日誌`340df22d3e5348fa9bf9192425850e23`（`.test-output/sect-save-core-group.log`）。正常啟動接線後，專項單支再驗 → **356 checks／failures=[]／exit0／18.5秒**，日誌`960dcf4fcff54ee99f674c79c138ed7c`，報告`.test-output/dao2_runners_960dcf4fcff54ee99f674c79c138ed7c/docs/verification/artifacts/sect-reform/save.json`；包含Memory故障矩陣、schema2–5鏈、舊名／投資／歷史界線、真實hub工作／貨物、學法單次扣款、有效世／舊獸魂／稱號／傳承原子保存、未回應持久化重載去重、隔離FileStorageAdapter新程序讀回，以及真實Godot主場景headless啟動。
- **L2共用依賴／過程失敗**：共用保存、離線、輪迴與主場景啟動需超過5支，另精選`m1c_persistence_runner.gd,m1d_offline_runner.gd,m3a_reincarnation_runner.gd,content_p2_beasts_save_runner.gd,content_p2_story_save_runner.gd,world46_runner.gd -Parallel 3 -TimeoutSeconds 45` → **6/6 PASS／exit0**，日誌`c771ff4280f44f439d253c6e7ba5cfcb`（`.test-output/sect-save-dependencies.log`）。本輪合計11支不同runner有PASS證據，不是Full／全量。初版測試錯用Amount helper並與全域seed名稱衝突造成parse失敗；更正後248 checks／exit0但漏RunnerResult.finish，被工具正確判失敗，未冒稱通過；補標記及案例後307 checks發現輪迴重載補零級設施與cargo fixture目的庫存已達target，前者修候選，後者調正fixture，最終356通過。NaN非法輸入驗證會有預期JSON警告，最終沒有SCRIPT ERROR。初次嘗試跨工具用TEMP讀前輪日誌路徑失敗，後續以已保存工作區log／JSON為權威。所有runner受保護證據guard通過。
- **交接／下一步**：依Context Guard於本子階段停止。下一New Chat接`SECT-REFORM-BEAST`，沿docs47建立五獨立新獸／20天賦／五魂池、發現／信物／許可與舊資格祖父條款；再以同候選保存機制整合完整發行版本，未來新命令加入`SectReformSave.COMMANDS`，不可另發獎或拆算lineage_credit。尚未製作或接受新獸美術，完整CORE發行整合／改版仍IN_PROGRESS，既有hub缺口保留；不因這個checkpoint觸發L3。可手動commit（本子階段結束，非大型任務結束）；代理未commit／push。收尾`python tools/trim_status_docs.py`無需新增前言歸檔；`python tools/delivery_check.py` RESULT PASS、受保護證據變更0；`git diff --check` exit0（既有部署檔LF／CRLF提示保留）。當輪檔案嚴格UTF-8及英文checkpoint恰5筆檢查通過。

## 2026-10-30 SECT-REFORM-CORE：CORE-3有效世數／宗門成就／傳承完成（L2，完整CORE IN_PROGRESS）

- **範圍／狀態**：依使用者「CORE-3：有效世數／宗門成就／傳承天賦」與docs47第二稿，本子段DONE。五宗有效世數、15項宗門稱號＋五宗問道、五條3階傳承天賦、命令／唯讀View及獨立版本保存驗證已接入。完整CORE／SECT-REFORM仍IN_PROGRESS；下一整批保存整合，BEAST與正式操作UI另段，未做Web匯出／瀏覽器／L3或自然節奏接受。
- **修改檔案**：新增`src/simulation/sect_lineage.gd`及UID、`tests/sect_reform_lineage_runner.gd`及UID；修改`sect_system.gd`、`sect_specialization.gd`、`talent_system.gd`、`achievement_system.gd`、`command_processor.gd`、`reincarnation_rules.gd`、`lifespan.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`src/application/game_session.gd`、`src/persistence/sect_save_contract.gd`、`save_codec.gd`與runner登錄。CORE-2 runner僅在人工設定輪迴數的fixture同步新世序，不放寬既有驗收。docs46／47記實際資料契約，README／ROADMAP僅狀態入口，updata英文交接維持最近5筆。既有部署、hub與前兩段未提交變更均保留。
- **有效世／成就**：新委託生成附固定`lineage_credit={version:1,life_seq,sect_id}`；只有正式成功領取加1，派出／時間到／舊候選或舊活動派遣均不補算；既有receipt與清除活動實例防重領。成功正常輪迴前按當世所屬、最高Era>=2與至少3件領取結算，每世一次；先增加對應宗門累計並揭露成就，再遞增世序與重置當世資料。原壽盡／輪迴建築資格保持。達1／3／5有效世揭露對應天賦階數，五宗各1開五宗問道；16獎勵全為claimed稱號收藏，0道心／道證／貢獻／材料／獸魂。稱號領取與天賦購買先後無關；揭露前成就／傳承View顯示未明傳承，揭露後提供門檻、進度、費用、持有與休眠原因。
- **傳承／效果**：沿既有`learn_talent`白名單與revision／receipt購買，逐階5／10／20道心；跨世永久持有，未入宗／他宗亦可購買，但只當世對應宗門且Era>=2啟用。太虛修速、天劍指定外島礦、縹緲指定外島草、萬佛壽元比例、紫霄祖島靈力容量各階+2%，接CORE-2同一加法層；不擴加工、丹效、木材或其他材料庫容。萬佛沿`Lifespan.for_state`且壽盡拒絕購買自救。已學傳承加入prepared signature；有lineage feature的離線與空島啟用前多秒推進均回共同逐秒路徑，保持邊界一致，未聲稱新的快徑效能。
- **版本／保存邊界**：使用`sect.lineage.version=1`，內含5鍵completed_lives、5鍵learned及有界當世欄位；舊`state.talents`、schema5／sect2／talent3／beast1與hub rules不變。唯讀解碼不初始化，首次生成新委託時從當下Era及現有總輪迴序號開始，歷史宗門世數一律0。保存／解碼拒絕未知版本／ID／非法flag、小數／NaN／無窮／負數／超上限、錯配世序／宗門／任務、無門檻的已學階數與偽造稱號；計數到2147483647拒絕整筆相關命令，不夾值發獎。驗證拒寫保留同一結算結果、同候選重試、最後成功世代恢復及重載receipt不重算；**原文hash歸檔、整批schema6候選遷移與寫入成功但回應失敗後的讀回識別仍未實作**，留下一整合，不以本段MemoryAdapter證據冒充完成。
- **L2驗收／命令**：涉及輪迴、成就、天賦、專法效果及保存等共享依賴，採8支不同runner的領域範圍，不擴Full。Godot `--version`=`4.7.2.stable.official.ed1daf0bf`；兩次隔離headless editor `--import --quit`均exit0，最終`.test-output/sect-lineage-final-import.log`無SCRIPT ERROR／Parse Error。每組先相同`-Only '完整runner檔名列表' -List`；APPDATA隔離`.test-output/sect-lineage-appdata`，matrix=single1280×720、預設timeout45。最終`sect_reform_lineage_runner.gd` → **1316 checks／failures=[]／exit0**，日誌ID`148c7ba2ef6f45329719ab8e87f2be1a`、10.5秒，副本`.test-output/lineage-delivery-tests_sect_reform_lineage_runner.gd.initial.log`。含25次五宗正常命令模擬有效世、1／3／5全階扣費、領前／領後、Era1／他宗休眠、降境保留峰值、舊檔不回填／舊派遣0信用、線上離線／prepared失效、保存拒寫／恢復／重試／重載及溢位原子拒絕。此為加速規則測試，非自然遊玩或滑鼠證據。
- **其他領域證據／過程失敗**：`sect_reform_identity_runner.gd,sect_reform_effects_runner.gd,sect_reform_lineage_runner.gd -Parallel 3`最終3/3 PASS／exit0（identity163、effects437，日誌`8b26cd8430544ab7af32168a27768117`，`.test-output/sect-lineage-final-core.log`）；`sect_reform_lineage_runner.gd,m3a_reincarnation_runner.gd,early_v1b_talents_runner.gd,content_p2_talents_runner.gd -Parallel 3`最終4/4 PASS／exit0（talents1126、early527，日誌`fa0cd956a75e4d54abc4158180048a4a`，`.test-output/sect-lineage-final.log`）。`content_p2_sect_save_runner.gd`957 checks與`m3b_achievement_runner.gd`6案例各PASS（`eb6cc87fbda245f89b8eb6acfa802c84`）；該4支組當時identity／effects失敗、整組exit1，未稱整組成功，後由上述3支組補過。最初新runner發現靜態初始化循環漏16成就，改固定const registry；空島前離線分段差異改lineage沿逐秒；非法identity版本先驗型別再取View；測試fixture直接變更Era／輪迴數造成peak／seq不一致、錯用story_progress欄位與陣列越界亦已修正，含兩次45秒SCRIPT ERROR逾時均不算成功。登錄runner時PowerShell UTF-8 BOM暫失使regex解碼失敗，恢復原BOM後正常；沒有改regex或放寬失敗判定。所有正式runner的protected-evidence guard無變更。
- **交接／下一步**：本輪主動checkpoint，下一New Chat接CORE整批保存整合，按docs47§7.2處理原文歸檔／讀回、完整候選遷移、已提交receipt讀回識別及復原；不要先跳BEAST／UI或L3。此為子階段完成，可手動commit，並非整個宗門改版結束；代理未commit／push。收尾`python tools/trim_status_docs.py`無需歸檔前言、`python tools/delivery_check.py` RESULT PASS／受保護證據變更0、`git diff --check` exit0（既有部署檔LF／CRLF提示保留）。未聲稱全量回歸通過。

## 2026-10-30 SECT-REFORM-CORE：CORE-2十專法／效果完成（L2，完整CORE IN_PROGRESS）

- **範圍／狀態**：依使用者「CORE-2」及docs47第二稿，十專法規則子段DONE。A/B逐階貢獻與下石費、當世宗門／Era與A前置、永久持有但依當世0／3／5階啟用、壽盡拒絕購法均已接入。舊八法、任務與商品不重置；未實作五傳承／十六成就、有效世數或整批schema6遷移，完整CORE與SECT-REFORM仍IN_PROGRESS。正式操作UI留SECT-REFORM-UI，當前由既有學法命令及新增View取得資料。
- **修改檔案／行為**：新增`src/simulation/sect_specialization.gd`與UID、`tests/sect_reform_effects_runner.gd`與UID，登錄`tools/run_all_runners.ps1`。修改`sect_system.gd`、`alchemy_system.gd`、`island_economy.gd`、`island_progression.gd`、`production.gd`、`story_progress.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`lifespan.gd`、`reincarnation_rules.gd`、`src/application/game_session.gd`、`src/debug/simulation_sandbox.gd`、`src/persistence/sect_save_contract.gd`。太虛修速加法／自然靈力、天劍指定外島礦與六加工、縹緲指定外島草與六丹Amount直接草費、萬佛平坦年數／比例、紫霄祖島靈力／七材料容量已接入。草費按單顆Amount折扣後乘批量，保留舊折扣次序；加工起工取整，已付款remaining／庫存跨資格變動與重載凍結。新容量與既有storage在同一加法層接一次，正式供給Production／home_cap／StoryProgress讀值一致，保留丹藥平坦庫容順序；超倉停止新增、不刪已持。共用`Lifespan.for_state`覆蓋Session／壽盡／輪迴／離線／HUD View與sandbox。宗門身分／Era／已學等級加入prepared signature；持有新專法feature的離線保守回逐秒共同路徑，含尚未啟用空島時的BUFF到期邊界。
- **版本／保存**：獨立`sect.techniques_version=1`僅首次學新專法時寫入，仍使用schema5／sect2；十個固定ID及0–5等級由contract驗證，未知feature版本、缺marker的新ID、降至sect0／1拒絕。舊快照不自動改寫；未學者不贈專法。驗證既有命令revision／receipt去重、保存拒寫保留同一結果、同候選重試／重載後不重扣。整批改革原文hash歸檔、schema6候選交易與寫後回應失敗讀回識別仍留後段，不以本段保存測試冒充完成。
- **驗收級別／結果**：Godot `--version`=`4.7.2.stable.official.ed1daf0bf`，headless editor import／類別註冊exit0（最後掃描詳見工具輸出）。隔離APPDATA `.test-output/sect-effects-appdata`，每組先同selector `-List`，matrix=single。新專項最終 **437 checks／failures=[]／exit0**，報告`.test-output/sect-core-2-final/docs/verification/artifacts/sect-reform/effects.json`。含十法全部逐階扣費、前置／境界、跨世互斥、壽盡自救拒絕、修速加法、自然靈力、正式供給及空島啟用前各五宗20秒對照逐秒（含5秒BUFF到期）、實際白名單採集、六丹批量草費、容量權威、prepared失效、超倉與已付批次重載／下批重算。
- **L2命令與證據**：共用壽元／容量／加工／保存／離線依賴需超過5支，限 **12支不同runner各有PASS證據**，非全量。`-Only 'sect_reform_identity_runner.gd,m3b_sect_runner.gd,content_p1_sect_runner.gd,content_p2_sect_runner.gd,content_p2_sect_save_runner.gd,offline_closed_form_parity_runner.gd,res1c2_offline_runner.gd,hub_economy_runner.gd,m3b_alchemy_runner.gd' -Parallel 3 -TimeoutSeconds 60`：8支PASS，48h parity初次與串行重試皆逾時，整組exit1（日誌`280002f56f424550bbd83d1c91140c71`）。確認該runner含172800秒完整逐秒參考後，**僅此支**`-TimeoutSeconds 300` → PASS／129.7秒／exit0，日誌`aebc179feee14ae1bf8e61c0aa45e3ef`。容量與無加成Amount保護微修後補`sect_reform_effects_runner.gd,m3b_alchemy_runner.gd,hub_economy_runner.gd` → 3/3／exit0，日誌`c8ecf126efa946a9a127a56abca68ed1`；追加空島前離線及版本拒絕後最終`sect_reform_effects_runner.gd,content_p2_sect_save_runner.gd` → 2/2／exit0，日誌`66a4068c1b7d48dc9b387c69dd82ed9b`（4.7／8.8秒）。補壽元依賴`m3a_reincarnation_runner.gd,content_p2_pills_runner.gd -Parallel 2 -TimeoutSeconds 45` → 2/2／exit0，日誌`79c792236cbf4351b2b193def15c0aa7`（3.8／26.4秒）。未跑Full／L3、Web匯出或瀏覽器；沒有UI／自然節奏接受聲稱。
- **過程失敗與修正**：新runner首版型別推斷與錯誤Alchemy helper名稱造成parse失敗，修正後執行；第一次容量fixture未啟用正式供給，誤比舊固定加工cap，改成實際啟用供給並獨立檢查權威值；加工fixture未解鎖材料導致拒絕與後續缺job SCRIPT ERROR／45秒逾時，改正fixture並加拒絕時停止保護；直接篡改unlocked但保留當世ID導致凍結存檔驗證失敗，改走既有宗門新世重置helper。這些失敗均未計成功。既有48h parity逾時如上保留紀錄。
- **交接／下一步**：下一New Chat接`SECT-REFORM-CORE-3`有效世數／宗門成就／傳承天賦，再接整批保存整合；本輪不提前BEAST／UI或L3。README／ROADMAP只更新指標，docs46／47更新實作邊界，英文checkpoint保留最近5筆。原部署未提交工作與hub歷史缺口保留。此為子階段結束，可手動commit；代理未commit／push。收尾`python tools/trim_status_docs.py`無需歸檔前言；`python tools/delivery_check.py` RESULT PASS、受保護證據變更0；`git diff --check`修正checkpoint尾端空白行後exit0（既有部署LF／CRLF提示保留）。

## 2026-10-30 SECT-REFORM-CORE：CORE-1身分核心完成（L1，完整CORE IN_PROGRESS）

- **授權／範圍**：使用者「後續 CORE」指示接續，沿docs47第二稿CORE參數實作。本輪獨立子段`CORE-1`完成五宗穩定ID、名稱alias相容、未知舊身分一次確認與保存契約。尚未實作十專法、五傳承／十六成就、有效世數或整批schema6遷移，完整CORE／SECT-REFORM均不標DONE；BEAST細項／個別新獸美術不由本次指示推定已接受。
- **修改檔案／行為**：新增`src/simulation/sect_identity.gd`及UID；修改`sect_system.gd`、`command_processor.gd`、`game_session.gd`、`sect_save_contract.gd`；新增`tests/sect_reform_identity_runner.gd`及UID，登錄`tools/run_all_runners.ps1`。新入宗同步ID與正式名，未知／型別錯誤／雙欄錯配拒絕；保留舊名稱呼叫與空值預設太虛。舊檔唯讀按完整正式名判讀，忽略舊預設taixu ID；未入宗無當世ID。未知名稱View回傳identity_pending、停刷新但舊功法／任務可啟動領取；新指令resolve_legacy_sect_identity只允許一次五選一，不刷任務、不耗費／給獎。Session白名單、revision與receipt接線；新世清ID、保留歷史名及既有投資。正式確認UI留UI階段，當前僅命令／View。
- **版本／保存邊界**：獨立`sect.identity_version=1`明確feature只在新入宗／確認時寫入；contract拒絕未知版本／非法型別／ID名錯配／未入宗仍有ID。原schema5、sect2、talent3、beast1及rules不變，無自動重寫舊保存，未批次啟用reform。驗證了唯讀解碼原宗門資料不變、拒寫同候選重試、保存／重載receipt去重；**不代表**原文hash歸檔、整批候選交易或寫後回應失敗讀回識別已完成，這些仍須後續CORE整合。
- **L1命令／結果**：Godot --version=`4.7.2.stable.official.ed1daf0bf`。先同selector `-List`確認5支，再以隔離APPDATA `.test-output/sect-identity-appdata`執行 `tools/run_all_runners.ps1 -Only 'sect_reform_identity_runner.gd,m3b_sect_runner.gd,content_p1_sect_runner.gd,content_p2_sect_runner.gd,content_p2_sect_save_runner.gd' -Parallel 3 -TimeoutSeconds 60` → **5/5 PASS、single1280×720、exit0**，日誌ID`8f18c06c10e347eca90cf02fb37fb3ad`（最慢P2宗門14.5秒）。補強舊快照／stale／非法確認測試後，以單支同selector先List再跑 → **163 checks、failures=[]、exit0**，日誌ID`1d92666a626446ccaaf4ac1f9e40066f`，2.6秒（最後明驗STALE_REVISION）。runner隔離輸出於.test-output，受保護證據目錄無變更。未做Web匯出／瀏覽器／Full／L3，沒有UI或新玩法接受聲稱。
- **本輪失敗與修正**：初次類別註冊命令漏--quit，完成掃描後以Ctrl+C結束exit1，不算驗收，曾有user://與既有巢狀project警告；正式runner改隔離APPDATA。首次List因新runner尚未登錄而拒絕，登錄後通過。追加快照測試曾因JSON int/float字典直接比對產生5項失敗；改成雙方JSON正規化比對並獨立驗decode，最終163項通過，未改遊戲資料去迎合測試。跨工具呼叫讀暫存log路徑失敗，最後單支在同一命令讀log確認摘要，未冒充其他缺失日誌已查閱。
- **交接／下一步**：本子段完成，下一New Chat接`SECT-REFORM-CORE-2`十專法／效果接入（含壽元共用helper、容量權威來源、加工凍結／離線cache），再接傳承／輪迴／整批保存；遵循L1／L2，不提前BEAST／UI或L3。既有部署未提交檔案與hub未完成／失敗證據保留。本段可手動commit；未commit／push。`python tools/trim_status_docs.py`無需歸檔前言，`python tools/delivery_check.py` RESULT PASS／受保護證據變更0，`git diff --check` exit0（LF／CRLF提示保留）。

<a id="sect-reform-design"></a>
## 2026-10-30 SECT-REFORM-DESIGN：逐項設計稿與算表交付（IN_REVIEW，待新數值／內容核定）

- **範圍／狀態**：依使用者指定接續DESIGN，完成八舊法相容表、十專法、五條傳承天賦／十六成就、守護獸對應與同階首次取得、事件率／條件權重／信物保底、Era1–6比較、舊檔逐項遷移及拒寫重試方案。設計稿交付完成，DESIGN狀態IN_REVIEW；五宗各有不同新獸與增加美術／內容方向已由使用者明確核定；第二稿新數值／名字／造型與天賦細項尚待審，不標正式玩法DONE，不開始CORE。既有五宗方向不重問。
- **修改檔案**：新增 [docs47](47-sect-reform-numeric-design.md)、[算表](sect-reform/design-v1-tables.md)、tools/sect_reform_design_model.py（離線設計計算器，非正式規則／驗收closure工具）；更新docs46與README／ROADMAP狀態入口、updata.txt英文checkpoint並維持最近5筆，舊項保留於docs/archive。未改src／content／schema／素材、任何Web／itch包或玩家進度；保留進場前未提交部署工具與hub歷史失敗。
- **設計數值**：五宗各A/B五階，共2638貢獻＋201下石；當世Era分段啟用，不能用跨世已學滿跳境界。各宗1/3/5有效世（築基＋該世正式領3件新委託＋成功輪迴）開天賦1/2/3階，費5/10/20道心，成就只稱號。五個獨立新獸（白澤／狻猊／芝靈兔／蓮心象／星紋貘為候選名），五種魂池與20個種屬天賦，皆金丹＋丹霞可首契；史詩10%／傳說20%事件率合單槽1.4%，同宗選種3:1；每合格領取1信物、重複另+2、12指定資格、上限120與資格跨世。靈狐保留免費，原獸舊權利以legacy許可完整保留。
- **核對／限制**：現行神農實碼只祖島草路徑、引靈大陣只lingqi靈氣容量，均不偷偷改成木／lingli靈力；舊八法不退款、不取消原未入宗收益。算表區分生成槽與玩家挑選後的領取率，12件保底不冒稱自然4小時SLA；萬佛Era1–4按實際啟用階數重算，沒有低境界全滿收益。使用者後續選定五宗不同新獸，第二稿已移除一家族五契相／共用魂池方案；各樹需11同種魂，五樹全滿至少55次成熟輪迴，成熟只給當世持獸的一枚同種魂。素材預算最低20張成長主圖＋5魂圖＋2通用圖示，共27張來源圖，尚未製作／美術放行。schema6／sect3／talent4／beast2及rules26為已核對基線後的候選版本，實作前須再查是否占用。
- **驗證級別／命令**：純設計／靜態，依分級政策不跑遊戲runner、import、Web匯出或L3。Godot --version為4.7.2.stable.official.ed1daf0bf；`python tools/sect_reform_design_model.py --write`產生算表，`--check`通過成本／壽元／機率／保底／道心機會成本一致性，另核對八舊法與五品階參數符合當前來源。`python tools/trim_status_docs.py`無需新增歸檔前言；9檔嚴格UTF-8／Python AST／45處當輪本地連結及anchor／checkpoint恰5筆PASS，`python tools/delivery_check.py` RESULT PASS、受保護證據變更0。首次diff檢查發現updata末尾多餘空白行，已移除並以獨立`git diff --check`重驗exit0；既有部署檔LF／CRLF提示保留。這些不是遊戲L1／L2或全量回歸。
- **第二稿修訂／驗證**：使用者的獸種選擇只核定五種新獸與較多內容工作，不自動核定其餘倍率／命名。已同步docs46／47、算表／計算器、README／ROADMAP與英文checkpoint；數值模型新增五物種各4節點／11魂及跨種隔離算表，抽選池仍5→7→8→9，原機率／保底算術不變。`python tools/sect_reform_design_model.py --write`及`--check`PASS；10檔UTF-8／Python AST／47處當輪本地連結及anchor／五物種與20個唯一天賦ID／checkpoint恰5筆PASS；trim_status_docs無需再歸檔前言，delivery_check RESULT PASS、受保護證據變更0，獨立git diff --check exit0（既有部署檔LF／CRLF提示保留）。依純文件修訂政策未跑遊戲runner／匯出／L3。
- **待核定／下一步**：docs47第9節四組為本輪新決策核定點：功法／傳承數字、五新獸候選名字／造型與獨立魂樹細項、1.4%／3:1／12信物、legacy權利與版本遷移；五宗各有新獸的方向不重問。依docs46的CORE前置，收到核定後才以New Chat展開SECT-REFORM-CORE；本輪不硬開下一大型階段。此設計階段可手動commit，非SECT-REFORM大型任務結束；未自行commit／push。

<a id="sect-reform-plan"></a>
## 2026-10-30 SECT-REFORM-PLAN：宗門改版開工文件完成（文件／靜態驗證）

- **範圍／狀態**：使用者接受五宗平行專精、共通＋專屬功法、跨世成就與隱藏傳承天賦、同宗守護獸取得加權與信物保底，要求建立文件。本輪PLAN文件階段DONE；DESIGN與正式實作TODO，不宣稱玩法已接入或大型任務結案。
- **修改檔案**：新增docs/46-sect-identity-and-inheritance-plan.md；README／ROADMAP放摘要與狀態連結，ROADMAP登錄分段任務；updata.txt追加英文checkpoint並維持最近5筆，舊項由docs/archive保留。未修改遊戲程式、正式資料／數值、schema、素材、一般Web／itch包或玩家進度；保留既有部署工具與未提交修改。
- **來源／決策**：正式五宗仍共用8功法／30模板／8商品；Era≥2或輪迴≥1可入宗。六獸目前直接結契，非任務掉落；DAO1史詩10%／傳說20%是該品階條件機率。新文件明列穩定宗門ID缺口、當世有效世數／跨世累計、專屬效果作用域、資格與自主結契分離、凍結抽選與信物保底、舊直接結契的遷移，以及保存復原／重試／去重。
- **尚待定案**：1／3／5世、築基＋3委託是候選值；各宗功法成本／倍率、天賦階數／道心費、五宗獸種與同階可達性、機率／權重／保底成本、資格與信物跨世政策、舊投入轉換及版本遷移需DESIGN逐項表。突破信物仍獨立待設計，不擅自把產業材料改宗門獨占。
- **驗證級別／命令**：純文件／靜態；依分級政策不跑遊戲runner／Godot import／Web匯出或L3。使用python tools/trim_status_docs.py歸檔前言，檢查本輪文件嚴格UTF-8與本地連結，再執行python tools/delivery_check.py及git diff --check；delivery_check RESULT PASS、受保護證據變更0、git diff --check exit0。首次連結檢查發現trim搬移前言後相對連結未改基準，已修正本輪搬移的兩條連結並重驗；最終8檔UTF-8與本輪範圍連結、checkpoint恰5筆通過。既有部署檔LF／CRLF提示保留。無新增遊戲通過聲稱，hub原Full未完成／失敗仍保留。
- **下一步／交接**：New Chat接SECT-REFORM-DESIGN，按docs46完成可比較的逐項規則表，無需重問已核定玩法方向；確認新數值與內容後才接CORE→BEAST→UI。正式實作前重新核對實際來源／工作區與受影響依賴。本文件階段可手動commit；未自行commit／push。


<a id="itch-deploy-workflow"></a>
## 2026-10-30 ITCH-DEPLOY-WORKFLOW：草稿部署與一鍵更新流程完成（工具L1＋託管桌面抽驗）

- **範圍／結果**：依使用者要求部署目前正式來源到既有 `kainhuang/dao-ascendant:html5`；專案5261584、upload20143590、build2249728，butler status確認完成，版本 `20261030-123219-f5df180f`。https://kainhuang.itch.io/dao-ascendant 可供登入擁有者試玩；**Draft／$0 or Donate 維持，未公開**。部署工具與草稿試部署階段DONE；不是ERA2-HUB-ECONOMY或全遊戲結案。
- **檔案／工作流**：新增根目錄 `deploy_itch_web.bat`，預設全新匯出→校驗→butler push；新增 tools/deploy_itch_web.ps1（Prepare／Push／Verify／Browser／Login、DryRun、ReuseExport、版本）、setup_itch_butler.ps1（官方broth、本專案build/tools、不改PATH）、itch_web_package.py、test_itch_web_package.py。重整既有package_itch_web.ps1，保留舊batch僅打包入口；更新docs45指南。沒有改Godot遊戲來源、規則、數值、schema或一般build/web。
- **封裝／命令**：Godot4.7.2.stable.official.ed1daf0bf，隔離APPDATA與全新Web匯出到build/itch-web；匯出exit／SCRIPT ERROR／Parse Error會阻擋，Node準備br與四首原BGM。Python明確允許runtime與圖示9檔＋BGM4檔，校驗根index.html、來源指紋、BGM及輸出／ZIP hash，檢查路徑／重複／空檔與官方HTML5大小限制；ZIP原子替換、sidecar含版本／目標／SHA。ReuseExport不以mtime判新舊，變動或缺檔即拒絕。`powershell -NoProfile -ExecutionPolicy Bypass -File tools/deploy_itch_web.ps1 -Action Prepare` exit0；日誌`.test-output/itch-20261030-123228-004/`。ZIP141557423 bytes、13檔、解壓171575918 bytes、最大126378936 bytes；SHA256 `e65fa960f737706ac64d5e6fe5c8936d0b7bb21b2c3e6bfe2b3cf2e894bd7a7f`。
- **上傳／授權**：官方butler15.32.0已在build/tools/butler；使用者同意持續上傳授權，login exit0，使用標準使用者憑證目錄，不讀取／顯示token、不存入Git／manifest／文件。Push -ReuseExport -DryRun exit0，13檔／2資料夾／0symlink；實際Push -ReuseExport在信箱驗證後exit0，butler status核對上述版本。html5檔勾選This file will be played in the browser並Save。日後雙擊deploy_itch_web.bat更新同頻道；網路故障可ReuseExport重試，不自動更改公開狀態。
- **L1與失敗**：`python -m unittest discover -s tools -p test_itch_web_package.py -v`最終8/8 PASS（舊來源／ZIP與匯出篡改／缺音樂／前包保留／路徑逃逸／容量限制）；3份PowerShell AST語法PASS，Verify入口PASS。首輪fixture使用沙箱Temp遇WinError5，改專案.test-output隔離後重跑通過。Chrome chooser兩次file URLs權限失敗，未計成功；使用者開啟權限後browser連線後來重註冊為Chrome4，已恢復。改butler後首推400「Please verify your account's email address before uploading a build」，使用者親自驗證後再推成功。
- **真實託管抽驗**：初次內嵌about:blank，直開實際託管HTML確認能啟動，關閉診斷頁後重載草稿即正常。Enter fullscreen測試有平台TypeError:not granted與screen.orientation.lock不支援，改itch啟動方式為Click to launch in fullscreen（CSS展開內容視窗），不改安全設定。最終實際1536×674 CSS桌面視窗，滑鼠關摘要→前往目標→靈氣0→1，重載同頁／同build→關摘要→重開資源仍1.00；無fixture注入、清storage或debug賺料。1280×720 viewport override未生效、已reset，不冒稱1280或三尺寸通過。logs保留04:44:49原生全螢幕兩筆歷史錯誤，最終CSS啟動／採集／重載無新增阻擋錯誤，不稱整輪零錯誤。證據`.test-output/itch-upload-channel.png`、itch-gather-before-reload.png、itch-deployed-play.png；遊戲／編輯頁已保留。
- **證據邊界／交接**：通用delivery_check --web build/itch-web為7/7 PASS、受保護證據變更0；最後diff-check見工具輸出。遊戲來源沿2026-10-30 hub版本（HEAD f5df180f相對e32de525僅文件），引用原定向／三橫式證據的原範圍；原Full初跑88PASS／13FAIL後停止、其餘未完成依舊未通過。未跑新L3、未宣稱全量／候選里程碑放行；這是使用者指定的私有試部署。下一New Chat備妥封面／實際截圖與公開前檢視，或接原hub剩餘失敗，本輪不擴大玩法修復／公開。部署階段完成，可手動commit；未自行commit／push。

<a id="itch-page-draft"></a>
## 2026-10-30 ITCH-PAGE-DRAFT：itch.io 專案草稿已建立（頁面資料完成；部署待續）

- **範圍／狀態**：使用者插入 itch.io 建頁任務；Chrome 擴充功能安裝後已能連線。建立唯一專案 `5261584`，頁面 https://kainhuang.itch.io/dao-ascendant ，編輯 https://itch.io/game/edit/5261584 。已保存 Draft，未公開；僅頁面資料階段完成，不宣稱遊戲已上傳或 itch.io 試玩通過。
- **已保存**：名稱 Dao Ascendant；短描述 `A xianxia idle game about floating islands, cultivation, and the pursuit of immortality.`；完整英文介紹及目前繁體中文／桌面滑鼠建議；Games／HTML／In development／Simulation。依使用者核定 $0 or Donate，建議贊助保留平台預設 US$2（可跳過）。標籤 crafting／fantasy／idle／incremental／management／singleplayer／xianxia。Metadata 設繁體中文、Mouse、1–1 人、單次目標 A few minutes；工具 Godot。嵌入尺寸 1280×720、全螢幕按鈕開；自動播放、外層捲軸、Mobile friendly、SharedArrayBuffer 關。重新進入編輯頁確認尺寸、標籤與 Draft 保存。
- **AI／未定事項**：使用者追加確認四首 BGM 也是 AI 生成，已勾選並保存 Sounds；重新載入確認 Graphics／Sounds／Text & Dialog／Code 四類皆已揭露，Draft 維持未公開。帳號顯示尚未設定收款，未操作帳號收款／付款資料。封面、截圖、遊戲 ZIP 均未上傳。
- **檔案／工具核對**：現有 `build/dao2-itch-web.zip` 143116020 bytes、13 entries，Python zipfile CRC PASS、4 首 BGM 齊備；index.js／index.wasm 與 build/web 一致，但 index.html／index.pck 不同，因此未上傳這份舊 ZIP，未重新匯出／打包。只做頁面與靜態檢查，不觸發遊戲 runner／L3。Chrome 中途 DOMSnapshot／單次 locator 逾時，改以畫面及最新 AX 恢復；標籤 Enter 曾觸發首次建頁，後續沿相同 ID 編輯，沒有重建第二份。
- **交接／證據**：畫面 `.test-output/itch-draft-info.png` 及追加 `.test-output/itch-ai-disclosure.png`（忽略目錄），Chrome 編輯頁已保留供續接；不在文件保存 secret URL。通用 `python tools/delivery_check.py`、`git diff --check` 以本輪工具結果為準。下一步選擇本次部署所用版本、準備封面／截圖及相符 ZIP；上傳後才做 itch.io 實際試玩，使用者核定後再公開。原 ERA2-HUB-ECONOMY 未結案缺口維持。此頁面資料階段可手動 commit 紀錄；未 commit／push。

<a id="git-branch-cleanup"></a>
## 2026-10-30 GIT-BRANCH-CLEANUP：保留 main、清理已合併 master（DONE，靜態／Git 驗證）

- **範圍／驗收**：使用者插入之 Git 維護任務；確認遠端分支、主線領先及完整包含關係，只刪除已合併分支。未修改遊戲來源、未新增提交或推送 main。
- **證據**：成功 fetch 後，遠端預設 HEAD 指向 main；main／origin/main 同為 `e32de525a9084f65e739c9fbe99d7aaf7784df02`，ahead／behind=0／0。origin/master=`0cee548f6fdae496199bc1952e2c8dae70ef53ba`，`git merge-base --is-ancestor origin/master origin/main` exit0，`git rev-list --left-right --count origin/main...origin/master`=3／0，master 無獨有提交。
- **執行結果**：`git push --force-with-lease=refs/heads/master:0cee548f6fdae496199bc1952e2c8dae70ef53ba origin :refs/heads/master` 成功刪除 master；精確 lease 防止誤刪查核期間新增進度。隨後 `git fetch origin --prune`、`git ls-remote --symref origin HEAD 'refs/heads/*'`、`git branch -avv` 確認遠端僅 main，本機僅 main（origin/HEAD 是符號參照）。兩個 detached HEAD worktree 未改動，沒有替其他機器切換或刪除本機分支。
- **環境／驗證**：首次沙箱 fetch 因 .git/FETCH_HEAD 權限失敗、ls-remote 因網路失敗；經授權執行環境重試皆成功，不把首次失敗算通過。僅 Git 與文件變更，依分級規則不跑遊戲 runner／Godot／Web 匯出；通用 `python tools/delivery_check.py` 與 `git diff --check` 結果見本次最終工具輸出。
- **交接**：其他機器先在乾淨工作區切換 main，再執行 `git fetch --prune origin`、`git pull --ff-only origin main`；此操作只清遠端追蹤參照，不會自動刪除其他機器的本機 master，有未提交／獨有進度者須先保留。Git 清理階段 DONE；ERA2-HUB-ECONOMY 大型任務仍 IN_PROGRESS，下一 New Chat 依原交接處理剩餘失敗。可手動 commit 本次維護紀錄，未自行 commit。

<a id="era2-hub-economy"></a>
## 2026-10-30 ERA2-HUB-ECONOMY：祖島集中加工與玄礦先行（IN_PROGRESS）

- **核定／實作**：外島採集原料、回祖島扣料與入庫；以原島鍵保留平行產線及升級。新增wood_home／raw_stone_home／copper_home，舊跨島送料不再新出航，舊貨物依舊目的地到貨；已付款批次在原地完工，後續批次用祖島庫存。hub_version=1、rules_version=core-flow-25-ancestral-hub；低階舊契約預設不變，正式SaveManager首次啟用使用hub:true，既有檔由「改用祖島集中製造（保留原檔）」交易式啟用。原檔按來源雜湊歸檔／校驗，候選提交成功才替換live；拒寫、損壞歸檔修復與重試不重扣。
- **引導／介面**：H1玄礦→H2原料回祖島→H3單批銅精→H4青木與可選持續→H5靈木供給→H6祖島靈材。已有材料可直接製造、完成史不因耗用重置、無歷史舊檔不補做。缺料可原配方就地啟用補給，保留航線政策；在途倒數、來源／保留量／目標／容量分別提示，開拓不足定位建築。新工作顯示於祖島，左庫存依實際來源與產物位置；短式合併管理入口並揭露操作，不推薦停止。
- **檔案**：simulation/island_economy、island_progression、onboarding、command_processor，application/game_session、persistence/save_codec與save_manager；presentation/island_flow_model／panel、feature_navigation、manufacturing_panel、island_management_panel、island_world、ui_shell_resources；hub_economy／hub_onboarding／era2_island_flow runner與登錄，docs14／16／17／19。前輪dirty成果與其他工作新增部署工具保留。
- **驗證進行中**：Godot4.7.2確認。L1/L2皆先List：hub_onboarding最終11checks PASS；hub_economy最終70checks PASS（.test-output/hub-browser-refresh.log）；hub/core＋onboarding＋early_flow1c/d選4支PASS（4／2.6／39／112秒）。early_flow1b PASS27.7秒；shell PASS17.9秒。flow首輪暴露舊航線庫存表與模式未刷新，修復後60checks單尺寸PASS13.9秒；短式頁首後補flow PASS17.8秒。首個onboarding runner缺RUNNER_RESULT標記失敗已修，不算PASS。L3已啟動Full／Parallel3／Timeout180，完整結果待收；宗門／天賦短式長卡舊全高斷言改完整內容高度與捲動後按鈕可達，單獨Matrix full兩支PASS25.5／21.7秒。長流程初輪逾時仍待串行確認，未宣稱全量通過。
- **Web目前證據**：最終本機build/web-hub匯出與壓縮，delivery_check壓縮7/7、受保護證據變更0；一般build/web未覆寫。4494隔離origin使用重編碼、decode驗證的命令賺得Era2來源，無玩家資料。1280桌面滑鼠開玄礦→祖島單批銅精（祖島產物1）→持續模式、原料航線進階設定已操作。最終短式與重載尚在驗證；不冒充自然新手通關。
- **最終補驗／限制**：最後核心快路徑保留舊模式單產線預留查詢，hub模式才合計多產線；SaveManager正式啟用預設hub，舊契約可明確hub_enabled=false。最後4支List後L1/L2：hub_economy／hub_onboarding／res1b_economy／res1c_progression PASS4.2／2.4／25.4／21.6秒，.test-output/hub-core-final.log。補修後flow／manufacturing／P1天賦3支Matrix full PASS22.3／63.8／20秒，.test-output/hub-final-targeted.log。原生最終三尺寸102checks、failures=[]、exit0，.test-output/hub-native-final.stdout與era2-flow PNG已目視。退出仍有既有anchor／Font RID／CanvasItem／ObjectDB診斷，不稱零錯誤。
- **L3未通過／主動中止**：Full List選152支，Parallel3／Timeout180執行到88支初輪PASS、13支FAIL後中止，不是完整152支回歸、沒有完成自動串行重試。記錄.test-output/hub-l3.log。宗門／P1與P2天賦長卡測試已依內捲契約修正並各別全尺寸補過；res1c舊路線測試明確採舊模式後補過。未解項仍含life_report_ui短式閱讀區、uix_r2_hud對StyleBoxEmpty.texture舊斷言、res1d2_world對舊面板門檻斷言、res1_ui1b運輸契約，以及story／beasts／pills／talents／supply長流程180秒逾時。不得稱這些已通過或全部只是環境問題，需下一輪定位後精選重跑，不重跑已過的全量範圍。
- **Web最終補驗**：本輪已在1280×720／844×390／800×360桌面瀏覽器操作，最短式可內捲至加工控制並滑鼠安排停止；實際reload保留玄礦開拓、祖島銅精及持續工作，H4青木提示保留，console warn/error=[]。首次4492沙盒服務連線失敗、舊fixture六小時離線等待不算正常通關證據；重新編碼並decode的fixture以4494獨立origin重驗。初次自訂目標輸入實際保存3100，未冒稱輸入340成功；來源與目的庫存、滿倉原因正確，缺料到貨／精確數量則由功能runner驗證。最新一般build/web已用正式export-release與壓縮同步（結果以hub-release-final.log／hub-release-compression.log及delivery_check為準）。
- **最終稽核**：一般Web匯出／壓縮exit0，`python tools/delivery_check.py --web build/web` PASS，7/7檔案一致、受保護證據變更0；`git diff --check`修正updata尾端空白後補驗。
- **交接／未結案**：本次經濟與引導功能接入、L1/L2及桌面操作已完成，**大型任務ERA2-HUB-ECONOMY仍IN_PROGRESS**，L3未通過。可手動commit目前階段，未自行commit／push。依Context Guard下一New Chat先處理上述未過契約與逾時，不開新大型玩法；最終美術／操作體感由使用者回饋。


<a id="ui-island-list-r3"></a>
## 2026-10-29 UI-ISLAND-LIST-R3：共用工作分頁、點島圖與相關庫存（L2，階段DONE）

- **需求／交付**：依使用者新圖回饋，Era2固定一組GameTab「總覽／製造／運輸／設施」，撤下各島重複的三個文字按鈕。點島體圖切對象，沿既有UiMaterial紙面選中樣式與44px以上命中、島名標當前，工作仍在島列下方展開。共用分頁依所選島的開拓／航線兩端／祖島設施條件禁用並提供TIP；這是入口整合，沒有改權限或經濟門檻。缺料開島後可續原配方；主動換島保持製造／運輸／設施類型，離開設施後的殘留狀態不再把製造切島帶回設施。相同canonical route換島也保持外層「空島」選中。
- **左側庫存／檔案**：`island_flow_panel.gd`、`feature_navigation.gd`、`management_workbench.gd`、`ui_shell_controller.gd`、`ui_shell_resources.gd`與`inventory_panel.gd`。寬式個人卡下重用InventoryPanel，製造只列配方原料、產物實際可用量與分開的祖島回運庫存；右側仍顯示每批需求／產出。運輸只列實際兩端資源，設施／開拓只列祖島成本材料。切島／配方／航線即時換內容，扣料與完工依正式View更新，預留及精確值保留共用TIP，不加總地方／祖島／在途。flow的欄數提示在320px可用寬度同列放三個88px格，其餘頁維持原欄數；不足仍內捲，短式沿原資源抽屜。重用原島圖及UI，不新增資產／規則／數值／schema／玩家保存；完整管理沿R2按鈕修正，不重排。docs19／07／16同步本輪通則。
- **L2 CLI／原生**：本機`Godot --version`=4.7.2.stable.official.ed1daf0bf，隔離APPDATA `.test-output/list-r3-appdata`。先 `tools/run_all_runners.ps1 -Only 'era2_island_flow_runner.gd,early16_ui_shell_runner.gd,imm1a_inventory_runner.gd' -List` 選3支。首輪重複key變數解析錯誤導致SCRIPT ERROR／timeout，終止後以兩個來源`--check-only`定位並修正，不算PASS。最終shell／inventory同selector先List，`-Parallel 2 -TimeoutSeconds 60` **2/2 PASS、16.7／14.5秒**，日誌581c770b72f2486aad377b7c4a073456。庫存舊斷言原要求短式可見摘要含需求，與既有「需求完整TIP／摘要容量」契約不符，先FAIL；`tests/imm1a_inventory_runner.gd`改核對短式TIP需求與可見容量後PASS。`tests/era2_island_flow_runner.gd`新增共用分頁門檻、無列內三鈕、原料／產物／祖島分隔、切島／航線庫存及完工更新斷言。原生單尺寸1280×720 **89 checks、failures=[]、exit0**，`.test-output/list-r3-native-final.log`與`list-r3-native-final/era2-flow/` PNG已目視；最後補切島維持模式及父分頁選中，只重跑此單支List／CLI，**19.8秒PASS、92 checks**，日誌aa8c97a32dbc47e3807cde7ce700693b，摘要`.test-output/list-r3-flow-delivery.log`。3支為跨定向範圍，不稱一次乾淨3/3或全量；既有anchor／Font RID／CanvasItem／ObjectDB關閉診斷保留。
- **Web**：最後來源以隔離APPDATA執行`Godot --headless --path . --export-release Web build/web-island-tabs/index.html`與`node tools/prepare_web_compression.mjs build/web-island-tabs`，exit0；一般build/web未改，僅本機L2測試包。`.test-output/list_r3_server.py` session71956，只綁127.0.0.1:4486／launcher，使用本輪已經SaveCodec encode/decode的命令賺得Era2 fixture。IAB外1280×800／iframe1280×720滑鼠：青木開拓→共用製造，左側靈木／靈石／靈材三格同時可見；缺料開玄礦、共用製造續原靈材；點玄礦圖換銅精及玄銅庫存、切設施見對應祖島費用、回青木並啟動補料航線。運輸左欄來源140／目的0不含在途10；到貨後製造扣料靈木150→140、靈石60→55，完工靈材0→1、祖島仍0，與右側狀態相符。最後父分頁選中小修包另重載並抽查換島／選中及已開拓與產物保存。這是fixture UI驗證，不是自然時間新手通關；無L3／全尺寸／FPS。
- **最後修復**：Web主控台捕獲島圖首次`get_meta("selected",null)`仍報缺鍵，改為先`has_meta`再讀取；只補單支flow List／CLI，**18.7秒PASS（92 checks）**，日誌b44a5eb918734569a5859b61d6c91d06，摘要`.test-output/list-r3-flow-meta-final.log`。同來源重新匯出／壓縮後，關閉舊分頁釋放writer，以乾淨IAB新分頁開既有進度，開空島／製造，左側產物1保留、三格完整可見；console warn/error=[]。前一分頁的meta錯誤不冒稱為零錯誤。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-island-tabs`壓縮7/7相符、受保護證據變更0，最終`git diff --check`檢查空白。額外CIM只讀程序清單受沙盒限制，未以該失敗清單終止任何程序；暫存日誌路徑跨沙盒不可再次讀取時，採同輪runner輸出與專案內摘要。下一New Chat收使用者對共用分頁、點島圖、左欄密度與可用數量辨識的回饋，再討論完整管理布局。**階段完成，可手動commit**；未自行commit／push。

<a id="ui-island-list-r2"></a>
## 2026-10-29 UI-ISLAND-LIST-R2：同清單製造／運輸與完整管理按鈕（L2，階段DONE）

- **範圍／實作**：依使用者三圖回饋，Era2保留簡明島圖清單，頁首合為「空島」，選中島列下方一次展開製造／航線／設施；材料與進度、操作相鄰，不再切到材料置中而按鈕在頁尾的空曠頁。青木／玄礦直接開拓，祖島列於首島開拓後提供合成及到貨航線，丹霞仍明示金丹門檻。缺料可開來源島／啟動對應補料航線，再續原配方；僅來源島顯示繼續製造，不覆蓋其他島入口。選擇器、單批／持續、停工、回運、三種設施升級仍送原命令，保留航線目標／保留量／等級。單一清單內捲，固定關閉／保存回饋與重試，換島展開後捲至該島。完整管理只修直排按鈕為自然文案寬度、單行與44px命中，整體布局未重做。
- **檔案**：`island_flow_panel.gd`、`feature_navigation.gd`、`island_management_panel.gd`；擴充`era2_island_flow_runner.gd`，`res1_ui1a_runner.gd`改檢查實際工作區容納欄數，不再假設1280 viewport等於配方可用寬度。docs19／07／16同步新原則。重用現有島圖／祖島terrain，沒有新資產／規則／數值／schema或玩家檔修改；保留前輪未提交成果。
- **L2 CLI／原生**：引擎4.7.2.stable.official.ed1daf0bf。各組均先同selector `-List`，隔離APPDATA `.test-output/list-r2-appdata`，單尺寸1280×720。第一組`era2_island_flow_runner.gd,early16_ui_shell_runner.gd,feature_navigation_runner.gd -Parallel 3 -TimeoutSeconds 60`：shell17.3秒／navigation17.7秒PASS；flow因測試檢查隱藏的祖島設施鈕FAIL，修正僅檢查可見動作。第二組`era2_island_flow_runner.gd,res1_ui1a_runner.gd,res1_ui1b_runner.gd -Parallel 3 -TimeoutSeconds 150`：flow16.1秒及transport102.9秒PASS，manufacturing因舊固定雙欄斷言FAIL。調整為工作區容納檢查後，`era2_island_flow_runner.gd,res1_ui1a_runner.gd -Parallel 2 -TimeoutSeconds 90` **2/2 PASS**，19.6／65.7秒，日誌31951ba858734e80afd3a189ed0bc33b。以上是5支領域跨定向執行，不能稱一次乾淨5/5或全量。最後續接文案、固定重試與單行按鈕小修，只重跑flow原生：`Godot --path . --script tests/era2_island_flow_runner.gd --log-file .test-output/list-r2-native-delivery.log`，`DAO_TEST_STORAGE_ROOT=.test-output/list-r2-native-delivery`，**90 checks、failures=[]、exit0**；已目視PNG（`era2-flow/manufacture-inline-1280x720.png`等）。既有anchor／Font RID／CanvasItem／ObjectDB退出診斷保留。
- **Web**：最終隔離APPDATA執行`Godot --headless --path . --export-release Web build/web-island-integrated/index.html`及`node tools/prepare_web_compression.mjs build/web-island-integrated`，exit0；只作本機L2測試包，一般build/web未更新、非候選交付。`.test-output/list_r2_server.py` session72706、127.0.0.1:4484／launcher，讀取經SaveCodec驗證的命令賺得Era2 fixture。桌面IAB外1280×800／iframe1280×720，滑鼠開青木→製造缺料→開玄礦→啟動ore_wood→實際到料→單批靈材製造→本島1→timber_home回運→祖島1，以及完整管理／返回、重載保留已開拓狀態有界驗證。最終按鈕單行補修後重載抽查完整管理；fixture測試不冒充自然新手通關。無新L3／全尺寸矩陣／FPS。
- **交付／下一步**：通用`python tools/delivery_check.py --web build/web-island-integrated`核對壓縮7/7與受保護證據變更0；`git diff --check`作最終空白稽核。首輪docs07／16尾端空白已修正；早期未設隔離APPDATA的export有user://開啟錯誤，最後隔離匯出成功，以最後記錄為準。下一New Chat收使用者對同清單展開密度、操作位置與祖島入口的回饋，再討論完整管理的進階布局；不逕自展開下一大型任務。本階段完成，**可手動commit**；未自行commit／push。

<a id="ui-island-list-r1"></a>
## 2026-10-29 UI-ISLAND-LIST-R1：開拓圖像清單與列內操作（L2，階段DONE）

- **需求／範圍**：依使用者兩張截圖及「執行」核定，承接ERA2-FLOW-UI1回饋，將Era2開拓由空曠單島頁改為圖像清單。青木／玄礦列內開拓，丹霞顯示金丹解鎖；島體縮圖、用途、狀態與成本／48px操作同組，移除該頁下拉選島，清單從頂端排列、內容可內捲。已開拓列提供管理及開始／繼續製造；原管理設施升級與返回清單、缺料來源跳轉及未完成配方保持。這是Era2開拓頁修訂，Era3–6完整管理、製造／運輸版型未重做。
- **檔案／契約**：`src/presentation/island_flow_panel.gd`重用UiIllustration與res1c3／res1d2既有島體、RecipeMaterialTile、UiTypography及共用按鈕；列節點只建一次、正式View刷新庫存與門檻，只送既有open_island命令，沒有新資產／規則／數值／存檔schema。`feature_navigation.gd`依來源島是否已開拓決定清單或管理詳情；`tests/era2_island_flow_runner.gd`沿原真實Session鏈，增加缺料禁用、金丹鎖定、實際島圖、管理返回與清單內幾何斷言。docs19同步使用者新規則，docs07／16修正開拓「一次一島／完全不捲」歷史限制。保留前輪未提交成果及玩家進度。
- **L2 CLI／原生**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。先 `tools/run_all_runners.ps1 -Only 'era2_island_flow_runner.gd,early16_ui_shell_runner.gd,feature_navigation_runner.gd' -List`確認3支，隔離APPDATA `.test-output/frontier-appdata`；同selector `-Parallel 3 -TimeoutSeconds 60`，shell／navigation分別19／19.2秒PASS，新runner因測試誤用AmountCompat.from_float解析失敗（不計通過）。改用zero後先單支List、單支重跑15秒PASS（日誌e2c2d26538cf4ac2a2d59aa1d68f5dbb）。原生同runner `DAO_TEST_STORAGE_ROOT=.test-output/frontier-native`、`--path . --script tests/era2_island_flow_runner.gd --log-file .test-output/frontier-native.log`，1280×720 **62 checks、failures=[]、exit0**；已目視未開拓與後續頁PNG。最後僅頁首增加題名並把完整管理靠右，補同單支List／CLI **16.2秒PASS**（25dee66853ee4db79ebd0ca6bf41b068），最後排版由Web確認。三支領域跨定向驗證通過，不寫成一次乾淨3/3；無全量／L3／全尺寸。原生仍有既有anchor／Font RID／CanvasItem／ObjectDB退出診斷。
- **Web**：本次來源 `Godot --headless --path . --export-release Web build/web-frontier-list/index.html`、`node tools/prepare_web_compression.mjs build/web-frontier-list` exit0；最後頁首小修後重匯與壓縮成功。僅L2本機測試包，一般build/web未覆寫。`.test-output/frontier_server.py`只綁127.0.0.1:4482，重用island_preview_server.Handler，fixture來自本輪runner已decode驗證的earned Era2狀態，獨立origin／正常dao2_saves命名不覆寫其他origin玩家檔。IAB外1280×800／遊戲1280×720，真實滑鼠經營→開拓→青木開拓→管理→返回清單→開始製造→缺料精確回玄礦→玄礦開拓→繼續原靈材配方通過，丹霞始終鎖定。實際重載launcher並重新開遊戲，關摘要後回開拓清單，青木／玄礦均維持已開拓，未重新扣料；追加`frontier-web-reloaded.jpg`。截圖`.test-output/frontier-web-unopened.jpg`／`frontier-web-opened.jpg`；console warn/error=[]。這是fixture上的UI操作，不冒充自然時間新手通關。初4472啟動頁404不計通過，停止本輪兩個失效服務session後改4482就緒；本機網路服務以已授權的提權命令啟動，未繞過任何瀏覽器安全警告。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-frontier-list` RESULT PASS（7/7壓縮符合、受保護證據變更0）；`git diff --check` exit0，僅既有CRLF提示。下一New Chat收取本頁圖像比例、密度與列內操作回饋；不在本輪開下一大型任務。**階段完成，可手動commit**；未自行commit／push。

<a id="ui-hud-integrate-r2"></a>
## 2026-10-29 UI-HUD-INTEGRATE-R2：完整個人狀態卡與工作台同紙（L2，階段DONE）

- **需求／範圍**：使用者偏好洞府完整道印HUD，指出前輪兩行版不一致，要求與整合介面並置。本輪承接同一HUD回饋，不擴大型任務。寬式經營與輪迴頁左欄重用原`header_box`及道印／境界／層級／真實修煉秒數與進度／壽元門檻色／天時／通知／原晉階突破回呼，庫存在下，右側操作；同張工作台紙面、頂部16px，不另留橫條空間。原節點在覆層／切頁／回洞府還原，不建立第二組操作。短式與其餘既有獨立頁局部HUD增加共用DaoSeal，保持44px控制與兩行資訊。沒有規則、數值、存檔schema、新資產或玩家進度修改。
- **檔案／測試**：`ui_shell_controller.gd`集中控制完整卡的節點與操作歸屬、短卡道印；`management_workbench.gd`寬式左欄320px起，無庫存／暫收庫存仍保留個人卡；`early16_ui_shell_runner.gd`查完整卡同紙包含與短卡邊界；`ui_shell_matrix_runner.gd`改驗實際不與分頁相交及唯一動作host。docs07／19同步使用者偏好。保留先前未提交UI-DOCUMENT、CARD-DENSITY、R1成果。
- **L2**：Godot `--version`=4.7.2.stable.official.ed1daf0bf。先同selector `-List`選5支，`tools/run_all_runners.ps1 -Only 'early16_ui_shell_runner.gd,ui_shell_integration_runner.gd,hud_readiness_life_runner.gd,ui_shell_matrix_runner.gd,m2d_responsive_ui_runner.gd' -Parallel 3 -TimeoutSeconds 90` → **5/5 PASS、matrix=single1280×720、exit0**（15.9／13.4／9.7／49.0／15.3秒），隔離APPDATA `.test-output/hud-r2-appdata`，日誌`dao2_runners_23c71ba06c9443169ba8a2b5da6e2875`。最後僅工作台頂距72→16後，以同單支`early16_ui_shell_runner.gd -List`核對，再原生執行該runner → **63 checks、failures=[]、exit0**；最後原生PNG及log `.test-output/hud-r2-native-final/`與`.test-output/hud-r2-native-final.log`，已目視。仍有既有anchor／Font RID／CanvasItem／ObjectDB退出診斷，不稱零錯誤。
- **Web**：最終`Godot --headless --path . --export-release Web build/web-hud-integrated/index.html`與`node tools/prepare_web_compression.mjs build/web-hud-integrated` exit0，僅L2本機包，一般build/web未更新，不觸發L3。`python -u tools/web_static_server.py --port 4474 --directory build/web-hud-integrated --no-gzip`需沙盒外localhost權限，session60471只監聽127.0.0.1。IAB1280×720以滑鼠開經營，實際可見完整道印／修煉倒數／壽元／天時與下方採集同紙；資源抽屜→CloseSeal還原、返回洞府／再開通過；自然修煉功滿後，原晉階缺料按鈕／缺靈氣原因仍完整在卡內，未假冒成功晉階。console warn/error=[]。這是隔離origin正常早期操作，不是整段自然通關。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-hud-integrated` PASS（7/7壓縮檔符合、受保護證據變更0），`git diff --check` exit0；無全量／L3／新FPS。下一New Chat收使用者對完整個人卡、左欄密度與同紙布局的視覺回饋。本階段完成，可手動commit；未自行commit／push。

<a id="ui-hud-compact-r1"></a>
## 2026-10-29 UI-HUD-COMPACT-R1：功能頁個人HUD局部化（L2，階段DONE）

- **範圍**：回應使用者指出最上方個人HUD未整合、不能呈跨版橫條。`ui_shell_controller.gd` 移除固定680px寬度，依目前容器最小尺寸收合；境界／層級18px強調、壽元16px第二行、細修煉條；原晉階／突破與BUFF／通知／壽盡輪迴控制緊鄰，44px命中／TIP／原回呼／壽元門檻色保持。洞府完整HUD沿原版。docs07／19同步規範，沒有新圖／規則／數值／schema／玩家保存修改；保留既有UI-DOCUMENT與CARD-DENSITY未提交成果。
- **修改／驗證**：`tests/early16_ui_shell_runner.gd` 加兩行／局部寬度／工作台避讓檢查；`tests/m2d_responsive_ui_runner.gd` 的兩處已整合資源欄檢查改用global_position（原先以局部y=0和全域HUD比較，非實際重疊）。Godot `--version` =4.7.2.stable.official.ed1daf0bf。先 `tools/run_all_runners.ps1 -Only 'early16_ui_shell_runner.gd,ui_shell_integration_runner.gd,hud_readiness_life_runner.gd,ui_shell_matrix_runner.gd,m2d_responsive_ui_runner.gd' -List` 選5支；同selector `-Parallel 3 -TimeoutSeconds 60`，隔離APPDATA `.test-output/hud-card-appdata`，最終 **5/5 PASS，matrix=single1280×720，exit0**，日誌 `dao2_runners_a6e9becc7fb3437a850dcd4c6c4aedc3`；耗時16.8／13.9／11.3／52.4／16.8秒。首次組合有integration的HUD高度與responsive舊座標斷言FAIL，修正上下內距／行距及座標後最終組合通過，首次不算通過。既有anchor／RID／ObjectDB退出診斷保留。
- **原生／Web**：最終原生 `Godot --path . --script tests/early16_ui_shell_runner.gd` 單尺寸63 checks PASS；隔離輸出 `.test-output/hud-card-native-final/`，目視金丹狀態／通知與工作台。`Godot --headless --path . --export-release Web build/web-hud-card/index.html` 及 `node tools/prepare_web_compression.mjs build/web-hud-card` exit0。只更新本機測試包，一般build/web未改，不交付候選包、不觸發L3。沙盒外 `python -u tools/web_static_server.py --port 4472 --directory build/web-hud-card --no-gzip`（session67947）僅綁127.0.0.1。IAB實際1280×720滑鼠關離線摘要、輪迴→經營、CloseSeal返回洞府／重開通過，壽盡兩行及輪迴捷徑可見、分頁無遮擋；console warn/error=[]。該origin載入既存隔離壽盡測試資料，並非本輪從空白自然玩到壽盡，正常修煉／動作／通知依CLI與原生證據。預覽頁已保留。
- **交付／下一步**：通用 `python tools/delivery_check.py --web build/web-hud-card` 與 `git diff --check` 結果見同輪輸出；未跑全量／L3／FPS。下一New Chat收取個人HUD大小、層次與工作台整合的視覺回饋，不在此啟動下一大型任務。此為**階段完成，可手動commit**；未自行commit／push。

<a id="ui-card-density-r1"></a>
## 2026-10-29 UI-CARD-DENSITY-R1：物件卡片寬度與操作群組（DONE，L2）

- **需求／範圍**：使用者指出天賦橫跨整頁、文字只佔少量寬度、按鈕相隔過遠，要求連同同類版型修正。本階段承接UI-DOCUMENT-R1的介面回饋，修改天賦／技能／靈獸／宗門圖像卡，不展開下一大型任務。
- **實作／檔案**：`src/presentation/reincarnation_panel.gd`的天賦列表改GridContainer，可用寬度至少1000px雙欄，列表上限1120px／單欄760px；圖像保留左側，效果下方集中成本與44px參悟按鈕，按鈕不隨成本欄拉高；不足提示使用完整說明欄，避免窄成本格把卡片拉高。`skill_study_view.gd`沿相同寬度上限並集中成本／研習；`beast_care_view.gd`因四段天賦保留單欄860px，成本與結契／餵養靠近說明；`sect_panel.gd`既有單／雙欄清單加1120／860px上限。煉丹已為材料→產物→操作群組，檢查後保留；沒有改敘事、歷世、帳目或世界列表。docs19記錄使用者核定的有界圖文與操作距離原則，docs07連結共用規範。沒有新增資產、規則、數值、存檔schema或修改玩家進度；既有工作區修改保留。
- **L2 CLI**：引擎`--version`為4.7.2.stable.official.ed1daf0bf。各組先以同selector `-List`核對，再設`APPDATA=.test-output/card-appdata`。第一組 `tools/run_all_runners.ps1 -Only 'content_p2_talents_ui_runner.gd,content_p1_talents_ui_runner.gd,content_p2_beasts_ui_runner.gd,content_p1_skills_ui_runner.gd' -Parallel 3 -TimeoutSeconds 60` **4/4 PASS、matrix=single、exit0**，日誌537bf2f8b03347f5b336c1dc175e7bd7；第二組宗門兩支 `-Only 'content_p2_sect_ui_runner.gd,content_p1_sect_ui_runner.gd' -Parallel 2 -TimeoutSeconds 60` **2/2 PASS**，日誌3226fca2b64949a5904b8eb2cf6487ce。最後不足提示小修僅補天賦P1/P2兩支，**2/2 PASS、各13秒**，日誌b4edfe6fd923403f8f1cf5949c369515。共六支領域依賴跨定向執行通過，沒有全量／L3／全尺寸矩陣。三支既有UI runner新增卡片寬度及成本／動作距離斷言。
- **原生**：隔離`DAO_TEST_STORAGE_ROOT`分別為`.test-output/card-native-final`、`card-skills-native`、`card-beasts-native`，原生執行talents P1／skills P1／beasts P2三支，單尺寸1280×720分別57／39／77 checks、failures=[]、exit0；已目視三類PNG。天賦57項截圖為最後不足提示移欄前同一組圖文／雙欄布局，不冒充最後移欄圖；移欄由最終CLI及Web補驗。關閉仍有既有Font RID／CanvasItem／ObjectDB診斷，不稱零警告。
- **Web**：`Godot --headless --path . --export-release Web build/web-card-density/index.html`與`node tools/prepare_web_compression.mjs build/web-card-density`成功；僅本機L2測試包，一般build/web未覆寫。隔離服務`.test-output/card_server.py`（4468，既有技能測試fixture）與`card_talents_server.py`（4470，既有document-fixture合成輪迴測試檔），均只綁127.0.0.1；獨立origin正常namespace，不覆寫玩家檔。外1280×800／iframe1280×720，真實滑鼠切技能、研習基礎冥想0→1、技能點6200→6110、轉靈獸、關閉／開輪迴／天賦與雙欄不足狀態已驗；這是UI合成／既有fixture驗證，不是自然時間通關。最終移欄包重載後確認不足提示完整單行、後段天賦可捲動及CloseSeal返回洞府，warn/error查詢空；截圖`.test-output/card-web-talents-final.png`，另有`card-web-skills.png`／`card-web-beasts.png`。
- **交付／下一步**：通用`python tools/delivery_check.py --web build/web-card-density` RESULT PASS（7/7壓縮檔符合、受保護證據變更0），`git diff --check` exit0，僅既有CRLF提示。下一New Chat僅收此卡片密度與操作距離的使用者回饋。本階段DONE，可手動commit，未自行commit／push。


<a id="ui-document-r1"></a>
## 2026-10-29 UI-DOCUMENT-R1：輪迴工作台整合與卷宗排版（L2完成；美術回饋待收）

- **需求／範圍**：依使用者附圖，整合分散區塊及調整文字質感，參考古代文書／銀票的題名、題簽、正文、註記層級。本階段完成輪迴／天賦／歷世所在工作台；其他修行頁及歷世數據表的全面重排未納入，不宣稱全遊戲介面已完成。
- **修改**：`management_workbench.gd`與`ui_shell_controller.gd`讓輪迴路由沿同一紙面承載主導覽及原頁面，保留單一CloseSeal；離頁／資源覆層恢復原父節點。`reincarnation_panel.gd`提供冪等embedded模式，收起重複背景／標題列，內容由垂直置中改頂端排列，撤下整片灰紅／灰綠卡底；狀態題名改明體22px。`life_report_view.gd`沿UiTypography既有明體800／900、文楷及黑體，主題名32px／短式24px，朱紅題簽、正文行距8px、段間12px／短式6px、資料註記降色；查記錄、詳情及轉世使用共用InscriptionAction。重用原字型／圖像，沒有新資產、玩法、數值、schema或玩家進度變更。docs07／19同步本次共用方向。
- **L2驗證**：Godot `--version`為4.7.2.stable.official.ed1daf0bf。先 `tools/run_all_runners.ps1 -Only 'life_report_ui_runner.gd,early16_ui_shell_runner.gd,ui_shell_matrix_runner.gd,life_history_ui_runner.gd,life_echo_ui_runner.gd' -List`確認5支。最終設`APPDATA=.test-output/document-appdata`，同選取 `-Parallel 3 -TimeoutSeconds 60` **5/5 PASS，matrix=single**；耗時11.4／15.0／41.4／10.7／10.8秒。日誌dao2_runners_144debdba61f44938ff4fc1279355154；runner guard未報受保護證據寫入。`tests/life_report_ui_runner.gd`補工作台歸屬、無重複紙面／關閉及實際父分配footer斷言。
- **原生／Web**：隔離APPDATA及`DAO_TEST_STORAGE_ROOT=.test-output/document-native`，原生執行life_report_ui_runner，1280×720四種人生狀態及保存保護 **69checks／exit0**；PNG在`.test-output/document-native/docs/verification/artifacts/atm-life-a/`，最終log `.test-output/document-native.log`。本機專用Web匯出 `--headless --path . --export-release Web build/web-document-r1/index.html`、`node tools/prepare_web_compression.mjs build/web-document-r1`成功，非候選包、未更新一般build/web。合成LifeReportFixture經SaveCodec encode/decode驗證後放在全新4466origin，只供畫面／命中驗證，不冒充正常遊戲賺取進度。服務`.test-output/document_server.py`（session79375、127.0.0.1:4466）；IAB外1280×800／遊戲iframe1280×720，實際滑鼠關摘要→卷首→查記錄展開→內捲→天賦→歷世→單一CloseSeal返回洞府→重開輪迴通過，warn/error查詢空；收益／轉世操作列固定可見。未執行新L3、全尺寸矩陣或FPS測試。
- **失敗與限制**：首輪runner未設專案內APPDATA，歷世／回聲遇user://無法寫入，後續Nil／timeout；中止該輪，不計PASS，改隔離APPDATA重跑5/5通過。首個Web export因目標目錄不存在失敗，建立目錄重匯成功；原生既有anchor／RID／ObjectDB關閉診斷仍在，不稱零警告。最終字型／紙面氣質仍待玩家主觀回饋。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-document-r1` RESULT PASS（7/7壓縮符合、受保護證據變更0），`git diff --check` exit0；下一New Chat先收此卷宗排版與整合方向回饋，再決定其他修行頁的同類收斂，不在本輪展開下一大型任務。本階段完成，可手動commit；未commit／push。


<a id="era2-flow-ui1"></a>
## 2026-10-29 ERA2-FLOW-UI1：築基空島逐步操作已接入（L2；體感待回饋）

- **需求／狀態**：依使用者本輪指令，Era1維持現版，先改善Era2開拓→製造→缺料來源開拓／升級→運輸→滿足資源。**本階段正式實作、領域CLI與桌面Web有界驗收完成**；不是全遊戲介面／Era3–6重做或人類體感接受，不開下一大型階段。日常操作不需垂直捲動，完整管理的長清單與進階設定仍可內捲。
- **實作**：新增 `src/presentation/island_flow_model.gd`／`island_flow_panel.gd`及UID。模型只讀正式View，無新教學進度存檔；首島開拓後顯示製造，兩島開拓後顯示運輸，缺料捷徑仍可直接查看既有航線。新面板一次一島／配方／航線，材料ICON→產物、來源ICON→目的庫存；不足材料朱紅與短狀態，單一可操作建議亮示，低特效靜態／隱藏停止動畫。選擇器可重複直接使用，缺料開島後返回原配方；單批／持續、啟停航線與三種設施升級沿既有命令。完整批數／保留量／目標／運力及所有舊功能仍在可來回的完整管理，不清草稿、不覆寫已保存航線設定。
- **接線／檔案**：`feature_navigation.gd` 統一命令與保存回饋、情境跳轉同步、階段分頁及模式返回；`management_workbench.gd` 擁有新面板並於逐步模式收起重複左庫存。窄式材料與狀態／操作並排；保存故障保留短狀態、完整TIP與只保存重試。`tests/era2_island_flow_runner.gd`＋UID／runner登錄；`tests/feature_navigation_runner.gd` 更新本次明確核定的分階段顯示斷言。共用規範docs07／19、docs16同步。沒有改數值、配方、正式規則、schema或玩家進度；重用既有圖像，沒有新增美術資產。
- **L2領域證據**：先List精選5支，`-Only 'era2_island_flow_runner.gd,early16_ui_shell_runner.gd,res1_ui1a_runner.gd,res1_ui1b_runner.gd,feature_navigation_runner.gd' -Parallel 3 -TimeoutSeconds 240`，日誌 `.test-output/dao2_runners_82b649b81e48425fa6240787e89f026d`：前4支PASS（18.1／18.1／58.3／102.3秒），navigation因舊「築基即三頁全開」斷言FAIL；調整後最終受影響2支重跑PASS（16.6／19.4秒、單尺寸、exit0，`.test-output/dao2_runners_8bb50b22a56c4a68a9ccb9739e35f4ce`）。這是跨定向執行的5支領域證據，不寫成一次5/5乾淨全跑。最後測試本身增加有效browser fixture檢查，其後無遊戲來源變更。
- **新流程契約**：同一舊命令賺得Era2 fixture，開拓扣料→製造缺料→精確來源島→補料航線→實際到貨→craft→產物回祖島；保存encode/decode、重開選擇、完整管理／返回、唯讀刷新、啟停不改target/reserve/level及保存錯誤提示皆驗。測試使用加速模擬秒，不是自然遊戲通關。最終原生專項 `DAO_VIEWPORT_MATRIX=full`（僅此runner，非L3）1280×720／844×390／800×360 **67checks PASS**，`.test-output/era2-native.log`，PNG在 `.test-output/era2-native/era2-flow/`。比較實際workbench.pages範圍，並非僅測被min-size撐大的面板；各日常主動作可見、無垂直scroll元件。
- **Web與實際桌面**：本機Godot4.7.2（前輪／本輪import已核對），`--headless --path . --export-release Web build/web-era2-flow/index.html`、`node tools/prepare_web_compression.mjs build/web-era2-flow` exit0；一般build/web未覆寫。最終PCK與7份壓縮對照以compression.json／通用delivery_check為準。重用island_preview_server Handler的本機工作腳本 `.test-output/era2_browser_server.py`，127.0.0.1:4464，正常dao2_saves namespace但獨立origin，無玩家檔。IAB外1280×800／遊戲iframe1280×720：中間來源滑鼠開青木→缺料→開玄礦通過；最後來源重載兩島保存後，以ASCII階段數字顯示，實際滑鼠製造缺石→ore_wood啟航→青木收到40下石→製造靈材1→timber_home啟航→祖島靈材1→完整管理／逐步操作返回通過，console warn/error查詢空。沒有FPS或新完整保存故障矩陣聲稱。測試服務保留供隔離試玩，不是發布候選包，不觸發L3。
- **失敗／修正**：第一輪新runner在啟動摘要尚未收尾時點擊後續導覽，另缺料模型先回本地採集、沒優先顯示跨島瓶頸；加啟動等待並修正模型後通過。原生曾發現短式兩層分頁擠出動作、原幾何斷言漏查工作區，合併分頁／短式左右排並加實際父範圍後通過。中間Web圈號不在字型子集中，改ASCII1/2/3；玄礦兩原料概覽撤下誤導轉換箭頭。首個4463 browser測試fixture sim_tick字串含小數，SaveCodec拒讀FIELD_TYPE:sim_tick；修正測試meta為整數、先decode驗證，再以新4464origin測試，不改存檔規則或繞過保護。4463服務已停止，失敗不算PASS。既有關閉RID／ObjectDB與anchor警告仍存在，不稱全日誌零警告。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-era2-flow` PASS（7/7壓縮符合、受保護證據變更0），`git diff --check`通過；無全量／新L3。下一New Chat收取玩家對此Era2逐步流程、圖像密度與二次操作的體感回饋；不重調Era1、不重跑不受影響領域。本**階段完成，可手動commit**；未commit／push。原有本機連線診斷與Era1核查文件變更保留。

<a id="early-16-balance-install-check"></a>
## 2026-10-29 EARLY-16-BALANCE 接入核查：已入正式遊戲；Era1 節奏問題仍保留（L1）

- **範圍／結論**：依使用者反映 Era1 升幾層後等待進階無聊，核對 OpenCode BALANCE-A/B/C 是否入遊戲。正式 `living_abode.gd:440–448` 經 ContentLoader → IslandProgression.attach_supply → SupplyContent 載入 `content/supply/era4_6.json`，不是只留在提案。B/C主要改Era4–6；A為稽核。此輪未改數值、規則、UI、匯出或玩家資料。
- **包內證據**：以 Python struct 唯讀解析 Godot PCK V4目錄，`build/web/index.pck` 與 `build/web-ui-shell/index.pck` 內 `content/eras/era1.json`、`content/supply/era4_6.json` 均逐位元組等於目前來源（4/4 SOURCE_MATCH）。SHA256依序為 `7f427b127c109125a6ab773573d21187fc903700e51b921c2c82decbfad926d1`／`16aff31416624bc20c0994d9264481a80f2e4586b1b94b82b7c9d4c9e3bf17ce`。不據此推定使用者目前瀏覽器載入哪個URL或快取版本。
- **已實作內容**：Era4–6修行倍率1.25／1.30／1.40、每階靈力3200／10000／38000；三境無加成訓練鐘38.05→31.04小時。聚靈庫4/5上限3、修行陣4/5/6上限2、二級材料需求及供給航線自動啟用／target3000均在正式資料。既有玩家航線設定保留，不因新預設強制改寫。
- **Era1未解決**：正式資料仍base_time60、倍率1.15、10層，每階靈力50；現有分段耗材從目前3／5／7層起累加木40／下石40／低草30，突破要求靈力容量500。無加成純訓練合計1006.99秒（16.8分），不等於實際通關時間。既有基線的主動無丹模擬新手建設187秒、可突破1286秒（21.4分），用丹873秒（14.6分）；假設每秒操作／每秒2次採集，並非真人牆鐘。新手鏈後78級建築空間中69級（88%）不提升晉階門檻所需產率或容量，故支線升級與主線等待耦合不足。C1仍26/92參考列容量不足FAIL；其為固定參考建設狀態，不能稱整線死鎖。C9 OK只代表主動比放置快，不證明等待有趣。
- **本輪驗收**：Godot `--version` =4.7.2.stable.official.ed1daf0bf；`python tools/compile_r46_content.py --check` PASS。先 `tools/run_all_runners.ps1 -Only 'early_pacing_runner.gd,content_p2_supply_data_runner.gd' -List` 選2支，再同selector `-TimeoutSeconds 180`，隔離APPDATA `.test-output/balance-check-appdata` → **2/2 PASS，matrix=single，exit0**（2.4／6.5秒），日誌 `dao2_runners_9f77b3627ddf47c3a87e5a09bedbf1e1`。不重生稽核報告、不重跑L3／Web匯出／瀏覽器。通用delivery_check及diff-check見本輪工具輸出。
- **下一步**：Era1單獨做新手鏈後的操作／解鎖／等待節奏調整，先以目前值為基線界定可縮短的空窗，不能把既有BALANCE完成視為已解決本次回饋。此為核查階段完成，可手動commit；沒有新的大型平衡實作結案，未commit／push。下一較大型調整使用New Chat。

<a id="early-16-ui-shell"></a>
## 2026-10-29 EARLY-16-UI-SHELL：集中工作台正式接入，CLI／原生完成，L2 Web待驗

- **範圍／狀態**：依使用者「主介面實作」與既有集中工作台方向，接入正式Godot經營四頁，不再只是HTML原型。實作與領域CLI已完成；**L2桌面Web抽驗未完成，整段維持IN_PROGRESS**。沒有執行新的L3；上方EARLY-16-INTEGRATION-L3是先前來源的里程碑證據，不能拿來宣稱新工作台Web已通過。
- **修改檔案**：新增 `src/presentation/management_workbench.gd`／`.uid`，以PanelContainer＋VBox／HBox容器擁有共用分頁、庫存與頁面內容；`ui_shell_controller.gd` 接經營容器／覆層還原與功能頁局部HUD（上限680px）；`building_catalog.gd`、`island_management_panel.gd` 增加嵌入模式，隱藏重複標題／關閉，保留目標、篩選、原成本與命令。製造／運輸沿繼承接入，不重建草稿或Session。寬式左庫存含祖島／當地語意，短式原資源入口可讀；單一CloseSeal返回洞府。舊靈界據點仍沿原modal。新增 `tests/early16_ui_shell_runner.gd`／`.uid`、登錄 `tools/run_all_runners.ps1`；兩個既有runner改以global_position比較跨父節點矩形。共用規範docs07／19同步，既有工作區其他修改保留；無規則、數值、schema或新美術變更。
- **修正／失敗記錄**：首次List使用不存在的ui_shell2_integration名稱，selector檢查拒絕後改用實際ui_shell_matrix名稱。首次5支組合中shell／navigation通過、matrix舊本地座標斷言失敗，製造／運輸60秒逾時，整組exit1。改global座標後matrix串行PASS。其後6支L2組合有5支PASS、運輸7項「返回保留草稿提示」斷言失敗，串行180秒逾時，整組仍exit1。定位為同幀切頁時容器尚未排序、舊短版尺寸使提示暫藏；workbench現在依容器內距／分頁最小高度／庫存欄寬即時供給配置，下一幀由容器細化，不等待下一幀才恢復提示。未更動航線草稿或規則以壓測試。
- **L1／L2命令與結果（單尺寸1280×720）**：引擎 `--version` = `4.7.2.stable.official.ed1daf0bf`。所有run_all呼叫皆先同selector `-List`。L2六支涵蓋共用殼／全route／經營建築／空島／製造／運輸／navigation，因領域共用依賴故超過5支，未擴全量。`-Only 'early16_ui_shell_runner.gd,ui_shell_integration_runner.gd,ui_shell_matrix_runner.gd,res1_ui1a_runner.gd,res1_ui1b_runner.gd,feature_navigation_runner.gd' -Parallel 3 -TimeoutSeconds 180` 的五支PASS與運輸FAIL日誌 `dao2_runners_9a44485407cc40049bb9e9a9ee3504c3`。修正後精選 `early16_ui_shell_runner.gd,ui_shell_matrix_runner.gd,res1_ui1a_runner.gd`、`-Parallel 3 -TimeoutSeconds 180` → **3/3 PASS**（17.9／51.5／67.8秒），日誌 `dao2_runners_29a5e2d8c86144e88aee80f1676365ba`；運輸單支 `-TimeoutSeconds 300` → **1/1 PASS、131.1秒**，日誌 `dao2_runners_0a0dee472d034b5caaf8c7e776e0b0c2`。延長運輸僅因其包含七航線多次命令與50次切頁，非泛用放寬。其餘shell_integration與feature_navigation沿同輪已過14.6／17.7秒證據，未受當幀管理頁密度修正影響。六支各有通過證據，不把失敗的整組命令寫成6/6 exit0。新工作台單尺寸55項、最終原生三橫式161項通過。
- **隔離／原生**：本輪命令環境 `APPDATA=E:\WORK\Dao2\.test-output\shell-appdata`；測試保存／輸出沿RunnerResult與DAO_TEST_STORAGE_ROOT，不覆寫玩家資料或受保護證據。最終原生 `Godot --path . --script tests/early16_ui_shell_runner.gd`，環境 `DAO_VIEWPORT_MATRIX=full`、`DAO_TEST_STORAGE_ROOT=E:\WORK\Dao2\.test-output\shell-native-final` → exit0／161 checks／failures=[]。這是受影響工作台的原生尺寸檢查，非L3全尺寸runner矩陣。12張PNG在 `.test-output/shell-native-final/docs/verification/artifacts/early16-ui-shell/`；已目視1280建築與800運輸（前版亦檢查800製造），固定分頁／單一叉號／內捲可辨；非瀏覽器滑鼠證據。退出仍有既有Font RID／CanvasItem／ObjectDB診斷，不稱零錯誤。
- **Web與工具限制**：最終 `Godot --headless --path . --export-release Web build/web-ui-shell/index.html`、`node tools/prepare_web_compression.mjs build/web-ui-shell` → exit0，僅本機測試包，不交付候選包、不因此觸發L3，也未覆寫一般build/web。`python tools/web_static_server.py --port 4451 --directory build/web-ui-shell` 啟動成功；IAB導航 `http://127.0.0.1:4451/index.html` 回報ERR_CONNECTION_TIMED_OUT；讀取故障指引後嘗試本機Edge，Computer Use app approval逾時，未取得瀏覽器畫面或滑鼠證據，沒有繞過。**Web待驗**，先前L3與其他包的截圖不替代本次來源。
- **交付／下一步**：`python tools/delivery_check.py --web build/web-ui-shell` → RESULT PASS、7/7 manifest、受保護證據目錄變更0；`git diff --check`通過（有既有CRLF提示）。依Context Guard在此checkpoint，下一New Chat用本次包補1280×720桌面滑鼠：切四頁、製造展開／收起、運輸草稿／返回、庫存覆層／關閉、回洞府／資源偏好；同時收集中工作台視覺回饋。桌面CLI範圍完成，L2 Web未DONE；觸控／實機仍延期且非阻擋。**本實作階段可手動commit，未自行commit／push**；不在本輪展開下一大型工作。

### 2026-10-29 追加：Codex localhost 權限定位／連線恢復

- 使用者要求定位 Codex 環境／授權差異。只做網路診斷，未改遊戲來源、系統安全設定、Codex 設定或瀏覽器安裝。
- 隔離 Python 同程序 HTTP 自測：預設沙盒可 bind，但 localhost urlopen 報 WinError 10013；相同命令 require_escalated → DAO2_LOOPBACK_OK、exit0。正式測試包同網址對照：沙盒內 WinError 10013／exit1，沙盒外 HTTP 200、5465 bytes／exit0。可確認目前沙盒網路權限阻擋 localhost 客戶端；不是單靠 Edge 版本推測。
- 已授權以沙盒外啟動 `python -u tools/web_static_server.py --port 4460 --directory build/web-ui-shell --no-gzip`（exec session 78305），只監聽127.0.0.1。內建瀏覽器導航 http://127.0.0.1:4460/index.html 成功，實際截圖可見洞府與離線摘要；分頁已 markHandoff。此服務保留供下一步抽驗。未操作玩家正式 origin。
- 本機 config 讀到 windows.sandbox=elevated；Windows 25H2 build26200.9711。上一輪 app update 回報26.1023.51421/build22530/up_to_date；版本差異存在，尚無證據證明更新回歸。Chrome connector unavailable 與 Edge URL辨識拒絕是獨立工具限制；未繞過。
- 後續測試服務／localhost CLI 請求需按需 require_escalated；不需全域關閉沙盒。先前逾時與服務停止不可全當作版本故障。本輪僅完成連線診斷，未補四頁滑鼠驗收、未跑runner／Web匯出／L3；L2 Web仍IN_PROGRESS。收尾執行 delivery_check，結果見同輪工具輸出。下一步沿4460頁面續桌面1280×720抽驗與視覺回饋；此診斷checkpoint可手動commit，無commit/push。

<a id="early-16-integration-l3"></a>
## 2026-10-29 EARLY-16-INTEGRATION-L3：大型里程碑 L3 收尾 DONE（全尺寸矩陣／Web／桌面三橫式）

- **範圍與級別**：依使用者要求執行大型里程碑 L3 收尾，非日常 L1／L2。涵蓋 148 支 runner 全尺寸矩陣、presentation parity、正式 Web 匯出與 Brotli 壓縮、桌面瀏覽器 1280×720／844×390／800×360 實際滑鼠抽驗。觸控／實機依 2026-10-17 指令延期，非本輪阻擋，也未宣稱通過。
- **首次矩陣與修正**：`run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 1800` 首輪 145/148，日誌 `dao2_runners_882e12b7e93a496eac496acc0aa68e00`；三支失敗皆為舊測試假設，非規則回歸：
  - `tests/early16_ui_a_runner.gd`、`tests/uix_r11_decisions_ui_runner.gd` 仍在最大捲動後要求置中動作完整包圍；改以 `reveal()` 把目標捲入可視區再斷言，保留「動作垂直置中」新規則。
  - `tests/content_p2_talents_runner.gd` 清除 routes 後被 BALANCE-C 自動建立航線及每 10 秒出貨干擾；改 `stop_routes()` 明確停用所有已開端點供給航線。
  - 本輪只改這三支測試，未改正式規則、數值、schema 或 UI。
- **修正後補驗**：`-Only 'early16_ui_a_runner,uix_r11_decisions_ui_runner,content_p2_talents_runner' -Matrix full -Parallel 3 -TimeoutSeconds 300` → 3/3 PASS，日誌 `dao2_runners_0f23d52d364e44cfba7645bd5f67402d`。
- **L3 全量**：`-Full -Parallel 3 -TimeoutSeconds 1800` → **148/148 PASS（matrix=full）**，日誌 `dao2_runners_da257e8605064f9ea050f9374fdb116b`，隔離輸出 `.test-output\dao2_runners_da257e8605064f9ea050f9374fdb116b`，evidence guard 通過。最慢：supply_progression 1520.0 秒、pills_flow 545.4、beasts_flow 443.1、talents_flow 407.9、story_flow 238.6、sks_p2_flow 204.3。`m3b_fortune_runner` 首輪出現 `Session resolve_fortune command should succeed` 與 `Total claimed should be 1` 兩個斷言失敗，串行重試 1.8 秒 PASS，最終群組 PASS；此為間歇性測試，未當作穩定單次證據。
- **presentation parity**：`DAO_VIEWPORT_MATRIX=full` 執行 `tests/abode_presentation_parity_runner.gd` → `RUNNER_RESULT status=PASS exit=0`（REF-A public facade、stacking、four layouts、signal identity、replacement session、save ordering、teardown）。
- **Web**：`--headless --path . --import` exit0；`--export-release Web .\build\web\index.html` exit0；`node tools/prepare_web_compression.mjs build/web` exit0，manifest 7/7 檔符合，index.pck 126,331,104 bytes、br 總計 133,711,637 bytes。`python tools\delivery_check.py --web build\web` 執行時 RESULT PASS、受保護證據變更 0。
- **桌面瀏覽器三橫式**：Edge 156.0.4314.50 headless CDP（WebGL 2.0／SwiftShader），本機 `python tools\web_static_server.py --port 4175 --directory build\web`。三個尺寸的 canvas CSS／buffer 均等於視口（1280×720、844×390、800×360），documentScroll 等於視口、無頁面捲軸；日誌有 `ABODE_READY`、`BGM_WEB_READY`。以 CDP 實際滑鼠事件關閉離線摘要，再點「經營」開啟「洞府建築」面板，三尺寸皆成功。截圖為暫存輸出，未新增受保護 artifacts；未測 FPS，也未測觸控／實機。
- **未完成／下一步**：P3／P4 仍延後；集中工作台新主介面仍為原型，尚未正式接入；觸控／實機依指令延期。**L3 收尾已完成**，此大型階段可手動 commit；本輪未 commit／push。

<a id="early-16-ui-action-r1"></a>
## 2026-10-29 EARLY-16-UI-ACTION-R1：主介面現況核對／無框題字入口，實作與L1完成，Web待驗

- **主介面核對**：集中工作台＋局部HUD只有 `docs/visual-prototype/early16-shell/` 原型及使用者方向選定，正式Godot殼尚未接入；EARLY-16-INTEGRATION-L2是既有UI／規則整合，不能算新主介面完成。本輪依使用者截圖先處理超寬操作，不擅自展開整個主介面重構。
- **修改與檢查範圍**：新增 `src/presentation/components/inscription_action.gd`（及引擎.uid），原生文字自然寬、無框、常態短底線、hover／pressed／鍵盤焦點／disabled。`reincarnation_sequence.gd` 用CenterContainer收束內容寬560，去除全幅卷軸，淺字結算及26px金色入口（短版20px）；mandala隱藏後釋放舊高度、結果重新垂直置中，跳過統一完成文案，完成回呼加播放／結果狀態保護。`realm_teleport_modal.gd` 跨界主操作、`save_controls.gd` 舊檔匯入採同元件；其餘本輪啟動時既有修改保留。檢查突破演出已有HFlow自然寬操作、離線摘要已有CloseSeal，未硬換其布局。選島圖像清單與分頁不屬此超寬單動詞問題。其他動態列表未宣稱全面遷移。
- **驗收（L1，1280×720）**：Godot `--version` = `4.7.2.stable.official.ed1daf0bf`。先 `tools/run_all_runners.ps1 -Only 'm3a_reincarnation_ui_runner.gd,early16_ui_b_runner.gd,ui_shell_integration_runner.gd,imm3a_cost_detail_runner.gd' -List` 選4支；執行首輪early16_ui_b／imm3a PASS，UI shell／m3a因沙箱user://不可寫而初始化失敗、SCRIPT ERROR／90秒逾時（串行重試同失敗），整組exit1，日誌 `dao2_runners_08d1a6e79f1140118707bc5913019a4a`。設定該命令環境 `APPDATA=E:\WORK\Dao2\.test-output\action-r1-appdata`，精確List後重跑兩支→2/2 PASS、exit0，日誌 `dao2_runners_f13d0dd618864a5e92d8bd759111ba0f`。沒有改系統APPDATA或玩家進度。新增m3a斷言涵蓋樣式、寬度、命中、範圍、焦點及結果垂直置中；最後置中修正後單支補驗結果見下。
- **原生／Web**：新增只讀 `tools/inscription_action_preview.gd`（及.uid），`Godot --path . --script tools/inscription_action_preview.gd` 生成 `.test-output/action-r1/reincarnation-1280.png`，預設不載入／保存玩家資料；`-- --hold` 可留畫面人工點擊。樣張背景用現有輪迴圖、只呈現正式元件，不是完整世界場景或新圖像資產。1280×720原生Compatibility渲染確認無長框與裁切、入口278×61，非瀏覽器滑鼠證據。正式Web測試匯出到 `build/web-action-r1`（非候選包、一般build/web不變）；首輪export exit0但user://診斷存在，修正測試環境後另補匯出。IAB本機4443連線逾時；後續4444導航受瀏覽器URL政策阻擋，沒有繞過。**Web實際畫面／滑鼠待驗，L2尚未完整通過**，不宣稱L3／全量。
- **最後補驗／交付檢查**：置中修正後m3a單支PASS、11.3秒、exit0，日誌 `dao2_runners_f95b5872241f47699d9345cad7805de7`；原生截圖exit0，最終隔離APPDATA Web export／compression exit0。`python tools/delivery_check.py --web build/web-action-r1` RESULT PASS、7/7檔案符合manifest、受保護證據變更0；`git diff --check` 通過（updata尾空行已修正）。`trim_status_docs.py` 曾按非空行切斷最新多行段落，已將該完整段落還原移至文件主標題下，保留既有歷史；未改工具。兩個本輪測試server已停止；首次沙箱CIM清理失敗後，改用正常授權命令按精確port清理成功。
- **手動桌面驗收步驟**：以 `tools/web_static_server.py --directory build/web-action-r1 --port <可用port>` 開隔離origin，正常進入輪迴完成結果，核對置中、hover／Tab焦點及點擊「重聚仙靈 · 入世修行」關閉；跨界與存檔工具核對主操作自然寬、原命令與禁用行為。未取得該證據前不標整個階段DONE。
- **下一步**：收無框入口視覺回饋並完成桌面Web抽驗；新主介面仍需集中工作台製造／運輸細化與正式Godot殼接入。階段checkpoint可手動commit，大型任務未結束；未commit／push。依Context Guard下一大型工作使用New Chat。

<a id="early-16-ui-design"></a>
## 2026-10-29 EARLY-16-UI-DESIGN：集中工作台方向已選定，待細化／接入

- 使用者要求先出2～3個設計原型，解決外層分頁／營造簿分離及滿版長條HUD。交付 `docs/visual-prototype/early16-shell/designs.html`、`preview.html`、`README.md`：集中工作台、側開工坊、整頁經營簿。使用者回覆「我個人偏向集中工作台」，記為後續布局方向；其他兩案保留比較。
- **本輪決策**：採集中工作台為細化基線：經營分頁、祖島可用資源、目標／分類與建築卡合為單一工作面板；單一頁首關閉；修行HUD縮為左上局部區塊。保留既有紙面／青玉、字型、44px與前期開放門檻。此為布局方向選擇，製造／運輸完整內容及短橫式仍待細化，正式Godot接入尚未開始。
- **本輪驗證**：純決策文件更新，L1靜態；未觸發遊戲runner／Web匯出。`python tools/delivery_check.py` PASS、受保護證據變更0。前輪原型語法／瀏覽器限制沿原範圍，不新增目視驗證聲稱。
- **下一步**：New Chat沿集中工作台細化製造／運輸及短橫式，再接共用殼。設計方向記錄階段可手動commit，大型任務未結案；未commit／push。

<a id="early-16-integration-l2"></a>
## 2026-10-29 EARLY-16-INTEGRATION-L2：BALANCE＋UI 整段整合 DONE（L2）；大型 L3 收尾未跑

- **範圍與狀態**：承接使用者「L2 整合與介面線收尾」。BALANCE-A／B／C 與 UI-A／B／C 的整段 L2 整合已完成：數值／經濟／供給／節奏 12 支、介面／航線契約 12 支（修正後重跑）全數 PASS，Era3→6 自然賺得長流程 1401.7 秒 PASS。本輪級別 **L2**、1280×720 單尺寸；未跑 L3、全尺寸矩陣、Web 匯出（無新 UI）或瀏覽器抽驗（本機無瀏覽器自動化工具，待人工桌面抽驗）。
- **修正一（長流程整帳）**：`tests/content_p2_supply_progression_runner.gd` 的 `ladder()` 由逐項備料改為整張升級帳循環結清（最多4輪，每輪備齊後重讀實際持有值，不足則重備）。原本先備中石5000再製化神丹4，製丹配方再耗中石20，導致送命令時只剩4980而報 `INSUFFICIENT_RESOURCE stone_mid required5000 available4980`；此為測試備料順序，不是規則死鎖。首版誤用 GDScript 保留字 `pass` 造成 Parse Error，改 `bill_pass` 後通過。
- **修正二（正式規則：航線預設外洩）**：`src/simulation/island_economy.gd` `_configure_route` 原本對所有已擴充狀態航線套用供給 `route_policy` 預設，BALANCE-C 的 target 3000 因而外洩到 legacy 航線（如 `timber_home`），與 `transport_view()` 只對供給航線用 policy 的判斷不一致，`res1_ui1b_runner` 的 `TARGET_REACHED` 契約因此失敗。改為僅供給航線取 policy 預設，legacy 回復 BALANCE-C 前行為（擴充狀態 enabled=false、reserve0、target100、level1；非擴充 enabled=true），供給航線仍 enabled=true、target3000、Lv1上限3。
- **L2 命令與結果**：皆先 `-Only ... -List` 再執行，`matrix=single`。數值組 12 支（supply data/economy/ui、res1a/b/c/d2、m2b、island_breakthrough、early_pacing 1/2/2-pill）`-Parallel 3 -TimeoutSeconds 300` → 12/12 PASS、exit0，日誌 `dao2_runners_f743d6a1a37b45d3bf2231f9615abd2f`。長流程以 `-TimeoutSeconds 1800` 重跑 → 1/1 PASS、1401.7 秒，日誌 `dao2_runners_890b61623693461fa2cd73db911f872a`。UI／航線組 10 支加 res1b、res1d2 共 12 支 `-Parallel 3 -TimeoutSeconds 300` → 12/12 PASS、exit0，日誌 `dao2_runners_8ad036aa46f34b408e87d354101072d4`；修正二落地後另以 res1_ui1b＋supply data/economy/ui 4 支定向重跑 → 4/4 PASS，日誌 `dao2_runners_58dec64d5a184bef8f5fb8885b956fe2`；再因航線預設影響其他設定路徑，補跑 res1c_progression、res1c2_offline、content_p2_story_flow、early_flow1c、early_flow1d → 5/5 PASS，日誌 `dao2_runners_3e41d06cd4b44af1a2d3a41c92895f03`（story_flow 238.8 秒）。超過5支因屬跨規則／內容／供給UI／共用殼的整合領域，並非全量。
- **限制**：長流程約23分鐘，只適合整合／里程碑重跑，`-TimeoutSeconds` 需 ≥1800，不可當日常 L1。Era1 C1 稽核 FAIL 為既有問題，不在本輪範圍。既有瀏覽器證據僅涵蓋 UI-C 當時範圍，不含 BALANCE-C 供給內容，故不宣稱整合後 Web 已抽驗。
- **收尾／下一步**：docs44 兩線標整合 DONE，README／ROADMAP／ai-handoff 更新一行狀態。L3（`-Full -Parallel 3`、全尺寸矩陣、Web 匯出與三橫式）留待大型任務／里程碑結案或使用者明確要求時執行；P3／P4 仍後排。本輪不自行 commit／push；**整合子階段完成，可手動 commit，大型 Era1–6 打磨尚未結案。**
- **2026-10-28 第一輪紀錄（歷史）**：使用者確認另一代理負責長流程後，本線先完成介面／航線契約子階段，長流程當時保留未驗；以下為該輪內容。
- **本輪修改**：`tests/content_p2_supply_economy_runner.gd` 新增16項舊檔航線契約：已開島但缺航線的存檔 encode/decode、View唯讀、600秒逐秒／整段離線／六段離線一致、懶補預設、保留停用／reserve7／target99／Lv3、停航不出貨、自動航線實際到貨、再次保存／載入。`docs/19-ui-ux-guidelines.md` 修正一處尚稱K系統為候選的過時文字，與既有萬／億核定一致。未修改正式規則、數值、UI來源或保存schema；長流程腳本的同期變更不是本輪所寫，保留未覆寫。
- **L2命令與結果**：本機引擎 `--version` 為 `4.7.2.stable.official.ed1daf0bf`；`python tools/compile_r46_content.py --check` PASS。先 `tools/run_all_runners.ps1 -Only 'content_p2_supply_progression_runner.gd,content_p2_supply_data_runner.gd,content_p2_supply_economy_runner.gd,content_p2_supply_ui_runner.gd,early16_ui_a_runner.gd,early16_ui_b_runner.gd,early16_ui_c_runner.gd,imm3c_page_consistency_runner.gd' -List` 確認8支，再以相同selector加 `-Parallel 3 -TimeoutSeconds 1800` 執行。長逾時僅針對已有1121～1305秒紀錄的完整流程；其餘受選測試均快速結束。7支短測試PASS，長流程FAIL，整組exit1，**不計8/8通過**。日誌ID `dao2_runners_9e813e2717d1432b992f6fe5a6ff4a6f`，輸出 `.test-output/dao2_runners_9e813e2717d1432b992f6fe5a6ff4a6f/`。超過5支因本次為數值／經濟／供給UI／共用UI與跨頁字形整合領域，並非全量。
- **新增契約補驗**：精確 `-Only 'content_p2_supply_economy_runner.gd' -List` 後同selector執行，`-TimeoutSeconds 45` → 1/1 PASS、15.7秒、305 checks／failures=[]、exit0。日誌ID `dao2_runners_d52c41aa0b4548ec9bfc4123ecb4dee5`；JSON位於 `.test-output/dao2_runners_d52c41aa0b4548ec9bfc4123ecb4dee5/docs/verification/artifacts/content-p2-supply/economy-contract.json`。兩次執行的證據guard未報變更。
- **長流程失敗**：從既有合法賺得Era3來源（SHA256 `902a68acf6263c0e269dac59bdbeb48a1c3f4f75e80dcddb384757e2bcfa37a1`）經正式命令到Era6第二層，模擬年齡55163秒時升級命令報 `INSUFFICIENT_RESOURCE: stone_mid required5000 available4980`。驅動先備中石、後製化神丹，後者再消耗20中石，整張升級帳未重新核對；不是足以證明規則死鎖的結果。71 checks、3 failures，Era6 Lv10與壽盡／輪迴尾段未通過。失敗報告與最後合法Era6 Lv2存檔保留於上述輸出的 `supply3-flow/earned-flow.json`／`last-earned-level.json`，不是空白新檔自然時間或瀏覽器證據。
- **並行變更**：本輪啟動時長流程腳本無工作區差異，執行期間出現外部修改。自動串行重試讀到中間版本並報第102行 `Expected loop variable name after "for"`／SCRIPT ERROR，不能計成功；之後實檔已改為 `bill_pass` 並加入整張成本重備邏輯，但本輪未取得該版本的通過證據。使用者確認另一代理正在處理，本輪保留其長流程工作，不覆寫、不再重跑。不要以目前 `DAO_SUPPLY3_RESUME` 直接載入Lv2聲稱能續跑升級：既有resume分支跳過整段ladder，原用途為Lv10尾段補驗。
- **限制／下一步**：長流程由使用者確認的另一作業續驗Era6與輪迴，本輪不推定其已通過；Codex下一新對話承接具體介面回饋，或在長流程完成後核對整合／大型收尾範圍。既有Era1 C1稽核FAIL保留，BALANCE整體、UI大型收尾與P3/P4狀態不提升。未執行L3、全尺寸、Web匯出或新瀏覽器抽驗；2026-10-28 UI-C桌面證據只引用其原範圍，不代表含BALANCE-C的Web整合已通過。本輪只改測試與規範文字，無新遊戲UI，故不重做桌面瀏覽器驗收。交付檢查與diff-check見收尾結果。未commit／push；本輪介面／航線契約子階段可手動commit，完整整合尚未結案。
- **收尾結果**：`python tools/delivery_check.py` → RESULT PASS，兩個受保護證據目錄變更0；`git diff --check` 首次指出updata末尾多空行，移除後exit0。`python tools/trim_status_docs.py` 已將入口舊前言歸檔、各保留最新3筆；updata保留5筆，移出項存 `docs/archive/updata-early16-integration-l2-2026-10-28.txt`。依Context Guard本子階段停在此處，下一輪使用New Chat。

<a id="early-16-balance-c"></a>
## 2026-10-28 EARLY-16-BALANCE-C：經濟升級曲線與離島供需 DONE（L1，數值子階段）

- **範圍**：依 BALANCE-A／B 與 docs44 第二節，補經濟建築每級成本／收益／上限、Era4–6二級材料需求與離島航線協調；不改UI、不改修行時間、不開Era7。使用者指定「C 經濟曲線（建築升級曲線／離島供需）」。
- **修改檔案**：`docs/design-data/res1-e-46-proposal.json`（新增 `v2_balance_c`、設施升級欄位、Era材料、航線預設與決策）、`tools/compile_r46_content.py`（讀取設施 `max_level`／`cost_factor`／`effect_weight` 與航線 `enabled`／`target`）、重生成 `content/supply/era4_6.json`、`src/simulation/island_economy.gd`（供給航線預設與懶補種）、`tests/content_p2_supply_data_runner.gd`、`tests/content_p2_supply_economy_runner.gd`、`tests/content_p2_supply_ui_runner.gd`（UI-C後TIP斷言）、`tools/early_pacing_audit.gd`、重生成 `docs/verification/early-pacing-baseline.md`／`.json`、docs34／37／rule-differences／44、本狀態與updata。未改 `src/presentation/`、schema或rules_version。
- **建築升級**：`core_storehouse_4/5` max1→3、成本倍率1→1.8；L1→2約1.89×、L2→3約3.56×基礎費，容量按等級線性2×／3×。`cultivation_focus_4/5/6` max1→2、成本倍率1→6.0、effect_weight0；L1效果不變，L2為2^1.5≈2.828×。調度建築維持max1，避免放大離島過剩。所有等級仍當世清除。
- **材料需求**：Era4每階加寒鐵12；Era5秘銀5→18、每階加千草12；Era6每階加化神丹4。九級同ID覆寫後該境總量為寒鐵101、千草106、化神丹37；E4／E5／E6需求占比8.2%／6.3%／5.2%／6.4%，C11由WARN轉OK。
- **運輸**：供給航線改為開島自動建立、`enabled=true`、target3000、reserve0、Lv1；`_seed_supply_routes` 只補缺失航線，不覆寫玩家既有停用／target／reserve／level，舊檔在兩端島已開時於tick懶補種。legacy航線行為不變。
- **命令與結果**：`python tools\compile_r46_content.py --check` → `PASS: R46 runtime data matches approved proposal-1`。`Godot --headless --path . --script tools\early_pacing_audit.gd` → `PACING AUDIT: 16 findings, 1 FAIL`；C11、C12、C13、C14、C15、C16全部OK。訓練鐘維持12385.11／25612.00／73728.93秒（31.04小時），突破餘裕與B輪相同；Era6中石仍占59.0%，為刻意保留的後段瓶頸。
- **驗證（L1，1280×720單一尺寸）**：先 `-Only 'content_p2_supply_data_runner,content_p2_supply_economy_runner,res1b_economy_runner,res1a_processing_runner,content_p2_supply_ui_runner' -List`，再同selector執行 → 5/5 PASS、exit0，日誌 `dao2_runners_2b6902d01eb6484ab036234d4eb719d5`（ui 5.4s／data 1.3s／economy 12.8s／processing 1.7s／legacy economy 17.4s）。首輪supply_ui失敗源自UI-C已把材料來源移入TIP、舊斷言仍讀隱藏caption；改為驗證完整TIP後單支及整組重跑通過。未跑全量、未跑L3、未匯出Web（純數值／規則，無新UI）。
- **失敗與限制**：`content_p2_supply_progression_runner` 以600秒執行時在Era6二層超時（601.7秒，非SCRIPT ERROR；日誌顯示E3–5與Era6建設合法推進），未計通過；該完整流程runner不適合作L1，留待L2／整合以更長逾時重跑。C1仍為Era1參考鏈既有FAIL（26/92），C2／C4／C6／C8警告同理源於稽核只建指定倉儲0級；本輪不以全面改Era1成本／容量壓警告，避免擾動既有新手節奏。
- **收尾／下一步**：docs34補升級表與島鏈、docs37記化神丹需求、rule-differences新增 `V2-EARLY-16-BALANCE-C`（明記v2非legacy parity）、docs44標C完成。`python tools\delivery_check.py` 與 `git diff --check` 見下。**BALANCE-C子階段完成，可手動commit；完整EARLY-16-BALANCE仍IN_PROGRESS。** 下一為BALANCE整段L2整合與Codex介面線收尾，待使用者指定；P3／P4仍後排。未commit／push。

<a id="early-16-ui-c"></a>
## 2026-10-28 EARLY-16-UI-C：資源數字與入口超框 DONE（L2，介面子階段）

- **使用者決策／交付**：使用者明確選「保留萬／億，空間不足用科學記號」，K／M／B／T不採用。`NumberFormatter.fit_amount` 依實際字型／可用寬度選短格式，計入描邊安全空間；一般短格式修正科學記號進位、單位臨界epsilon進位及極小非零變零，所有數量向零截斷。最窄材料格連指數也放不下時用保留負號的微／巨字印，未知／非有限／未提供用？；完整支援表示始終留TIP。`exact_amount` 原生浮點改保留JSON可序列化精度，整數原字串不經float、layer Amount仍只承諾既有契約精度。
- **修改來源**：`src/utils/number_formatter.gd`；`inventory_item_cell.gd` 使用20px依字寬數量、未知圖用有完整TIP的未識字印；`recipe_material_tile.gd` 共用數量setter、短版12→16px且不拉長正方形、完整可用／需求TIP與文字缺料；`inventory_panel.gd` 完整名稱可換行、詳情附完整TIP；`ui_shell_controller.gd` 資源入口改用途標題且取消clip_text，短技能頁保留已更新／未完成及完整回饋TIP；`alchemy_panel.gd`、`island_management_panel.gd`、`island_transport_panel.gd` 移除對共用數量Label的覆寫，煉丹顯示需求／持有各自數量，運輸未開端點？及完整來源／保留／目標TIP；`components/resource_chip.gd` HUD撤下會進位的w格式，沿共用圖示／短格式，`abode_hud_controller.gd` HUD可用／容量TIP不再四捨五入至2位。成本、庫存、足額、缺料、滿倉、命令payload及保存schema均未由本UI任務改動。
- **測試補強／實際範圍**：新增 `tests/early16_ui_c_runner.gd`／引擎產生.uid，登錄 `tools/run_all_runners.ps1`；204 checks含萬／億／科學臨界、極小值／負值／大值／layer、未知與非有限、完整TIP與來源／容量／需求並列、實際字形加描邊邊界、正方形／16px與真實短缺。更新imm1a、m3b_alchemy、res1_ui1b與uix_r1的格式預期；imm3c逐頁材料格補實際字形／描邊寬度，uix_r8補資源入口實際字寬與不裁切。多尺寸沿DAO_VIEWPORT_MATRIX，本輪只1280×720；compact為同視窗內48px元件案例，不是全尺寸矩陣。
- **L1→L2命令／結果**：每輪先 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only '<精確runner檔名清單>' -List`，再以相同selector執行。首組 `early16_ui_c_runner.gd,imm1a_inventory_runner.gd,imm3a_cost_detail_runner.gd,uix_r8_skills_ui_runner.gd,ui_shell_integration_runner.gd` 為4／5，未知圖印舊測試預期失敗、exit1；更新完整TIP預期後 C／imm1a補跑2／2 PASS，日誌 `dao2_runners_bb081beb44cc4aa4a0508b54b94b5314`。跨頁追加 `early16_ui_c_runner.gd,uix_r1_components_runner.gd,m3b_alchemy_ui_runner.gd,imm3c_page_consistency_runner.gd,res1_ui1b_runner.gd -Parallel 3 -TimeoutSeconds 120`：5／5 PASS、exit0，日誌 `dao2_runners_1140fc14789a48c1b2a6c42e81c93fc7`（204／0，運輸89.9秒，120秒僅因既有長測試）。最終字形斷言／HUD補驗 `imm3c_page_consistency_runner.gd,uix_r8_skills_ui_runner.gd,ui_shell_integration_runner.gd -Parallel 3`：3／3 PASS、exit0，日誌 `dao2_runners_ae56b617c1f841bbbb732890b9439ea3`。合併 **9支不同受影響runner均有PASS、matrix=single、evidence guard無變更**；共用格式涵蓋庫存／成本／技能／HUD／煉丹／空島／運輸／頁殼，故按L2超過5支，不是全量。另直接 `Godot --headless --path . --script tests/number_formatter_test.gd` 既有formatter契約PASS／exit0。
- **失敗與限制**：初次List誤含未登錄的number_formatter_test被拒，之後改為精確登錄清單、formatter獨立執行；庫存舊圖印預期失敗已如上修正，不計通過。formatter獨立命令在沙箱顯示user://日誌不可寫但契約PASS；正式runner／import／export用正常本機權限及隔離保存。既有anchor／RID退出診斷保留，不稱日誌零警告。數值線同期新增 `content/supply/era4_6.json` 及工具／報告／文件變更（BALANCE-B）；完整保留，UI驗收不冒稱數值線通過。
- **新版Web與真實桌面**：引擎版本 `4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import`、最終 `--export-release Web build/web-early16-ui-c/index.html` exit0；`node tools/prepare_web_compression.mjs build/web-early16-ui-c` exit0。PCK 126322232 bytes，sha256 `f25069a377a99905c4f588f8985a167398253c95bfa25bd51c6de3181e6bee52`。跨頁覆寫補正前曾產生中間包，已用最終來源重匯出／重壓縮，瀏覽器只在最終包進行。沿既有island_preview_server Handler暫指本包與 `src/verification/content_p1_skills_fixture.json`，測試服務127.0.0.1:4432、正常dao2_saves namespace且origin與玩家隔離。IAB外窗1280×800、iframe實測 **1280×720 CSS px／DPR1.25**：實際關閉摘要、開修行→煉丹（需求格）、切技能（90／1800成本）、點技能資源入口與物品選中詳情（6200／容量未提供／當世來源）、關閉抽屜並研習基礎冥想0→1（6200→6110，成本／入口／成功回饋刷新）通過。截圖 `.test-output/early16-ui-c/browser/skills.png`、`inventory.png`、`skills-updated.png`；browser warn/error查詢空。這是桌面輸入及顯示證據，非自然通關、保存故障／IndexedDB、FPS或全頁瀏覽器驗收。
- **收尾／下一步**：docs19同步使用者核定的共用單位與呈現規則、docs44記錄接線與狀態，README／ROADMAP／ai-handoff只放狀態連結，英文checkpoint置updata頂部並保留5筆。`python tools/delivery_check.py --web build/web-early16-ui-c`：7／7壓縮檔match、evidence目錄變更0、RESULT PASS；`git diff --check` exit0。測試服務Ctrl+C停止（主動終止exit1），IAB測試分頁關閉、視口覆寫清除。普通build/web未同步；本包是L2本機測試包，未製作發布候選包／未跑L3。UI-A／B／C子階段各已完成，Era1–6打磨大型任務及數值線仍進行中，整合後的大型收尾再依規範做一次L3。本輪不自行展開該收尾或P3／P4。**UI-C階段完成，可手動commit；未commit／push。下一New Chat核對數值線整合後的介面／整體收尾範圍，或承接使用者回饋。**


<a id="early-16-balance-b"></a>
## 2026-10-28 EARLY-16-BALANCE-B：Era4–6 成長曲線 DONE（L1，數值子階段）

- **範圍**：依 BALANCE-A 基線改 Era4–6 修行時間倍率、每階靈力需求與升下境容量；不動 `base_time`、壽元、資源倍率、其餘費用與 Era6 容量（本段不開7）。目標：E4–5 靈力占該境鐘 ≤55%、突破存量餘裕 ≥1.5x、縮短三段總鐘，同時 Era6 中石占比 ≤60%。
- **修改檔案**：`docs/design-data/res1-e-46-proposal.json`（新增 `v2_balance` 記錄改動前後與核定來源；三境數值）、重生成 `content/supply/era4_6.json`、`docs/34-res1-e-46-design.md`、`docs/37-content-p2-pill-design.md`、`docs/rule-differences.md`（新增 V2-EARLY-16-BALANCE-B 條目，明確記為 v2 而非 legacy parity）、重生成 `docs/verification/early-pacing-baseline.md`／`.json`、`docs/44` 狀態、本狀態與 updata checkpoint。未改 `src/`、schema、rules_version 或 UI。
- **數值改動**：時間倍率 1.28／1.35／1.45→1.25／1.30／1.40；每階靈力 5000／15000／40000→3200／10000／38000；升下境容量 E4 靈力 50000→40000、下石 20000→16000（錢 10000 不變），E5 靈力 200000→170000、下石 100000→80000。
- **命令與結果**：`python tools/compile_r46_content.py` → `Wrote content/supply/era4_6.json`；`python tools/compile_r46_content.py --check` → `PASS: R46 runtime data matches approved proposal-1`。`.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools\early_pacing_audit.gd` → `PACING AUDIT: 16 findings, 1 FAIL`（仍僅既有 C1 Era1）。
- **改後證據**：E4／5／6 訓練鐘 206.4／426.9／1228.8 分（12385.11／25612.00／73728.93 秒；3.44／7.11／20.48 小時），三段合計 2282.9→1862.1 分（38.05→31.04 小時，−18.4%）。靈力占該境鐘 68.3%／60.6%／42.2% → 49.7%／50.1%／49.6%。突破存量餘裕 E4 靈力1.53x、下石1.59x、錢3.12x；E5 靈力1.54x、下石1.57x → **C12 由WARN轉OK**。技能5（×0.9⁵）時間 7313.29／15123.63／43536.19 秒。C11 仍WARN（寒鐵E4 0.4%、秘銀E5 1.8%、千草E5 0.5%、化神丹E6 0.9%，屬二級資源需求覆蓋，留待C）；C16 OK。Era6 中石占縮短後鐘 47.7%→59.0%，仍在60%門檻內，但已成主要瓶頸。
- **驗證（L1，1280×720單一尺寸）**：先 `powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_all_runners.ps1 -Only 'content_p2_supply_data_runner,content_p2_supply_economy_runner,sks_p2_core_runner' -List` 確認3支，再同selector執行 → 3/3 PASS、exit0，日誌 `dao2_runners_9ffc4e4c26814ce6be5ac7c7180b7ff0`（data 1.4s／economy 13.1s／sks core 1.9s）。`content_p2_supply_data_runner` 直接比對 proposal 與 runtime 內容一致，是本次同步的關鍵回歸。未跑全量、未跑L3、未匯出Web（純數值無UI變更）。
- **限制**：稽核為靜態模型，無玩家存檔；離線、第一世／輪迴與代表選修路徑的實際牆鐘未在本輪重測（歷史完整流程 runner 約1121秒，非L1）。C1 Era1 26/92列為既有FAIL，不屬本階段。舊 14097.21／31757.13／91114.23 秒與 docs34 舊表保留為歷史基線。
- **下一步**：`EARLY-16-BALANCE-C` 經濟建築升級曲線與空島供給／消耗／運輸；已知瓶頸為 Era6 中石（1.04/s、59.0%鐘）與二級空島過剩71–282x、航運預設關閉。P3／P4仍後排。
- **收尾**：`python tools/delivery_check.py` 唯讀檢查；未commit／push。**BALANCE-B子階段完成，可手動commit；完整EARLY-16-BALANCE仍IN_PROGRESS。** 依Context Guard於此checkpoint，下一New Chat接BALANCE-C。

<a id="early-16-ui-b"></a>
## 2026-10-28 EARLY-16-UI-B：圖示關閉 DONE（L2，介面子階段）

- **交付／來源**：`src/presentation/components/close_seal.gd` 改用兩條抗鋸齒向量線繪製叉號，移除文字×依賴；常態透明、hover淡墨、pressed更深、disabled灰墨，鍵盤焦點沿既有共用金色框。44×44命中、`關閉` TIP與accessibility_name、Tab／Enter啟用；不使用逐幀動畫或新增圖形資產。既有CloseSeal使用者同步沿用圖形。
- **遷移盤點**：`building_catalog.gd`、`island_management_panel.gd`、`offline_summary.gd`、`v2_rules_notice.gd`、`debug_panel.gd`、`realm_teleport_modal.gd` 七處文字關閉改共用元件；`save_controls.gd` 保留一個固定頁首CloseSeal並移除內容動作列文字關閉。Debug／跨界原捲動標題改錨點VBox固定頁首，離線／規則通知關閉移到固定標題列。舊深色dialog集中使用CloseSeal.paper_header沿UiMaterial.hud_paper，標題深墨，修正瀏覽器發現的叉號低對比。共用殼既有全域覆層關閉仍保留；「關閉」資源顯示模式／Debug開關狀態不是關閉動作。確認／領取／繼續／返回修煉與原返回路由不改，未修改規則、數值、庫存、保存schema或命令。
- **測試檔案**：新增 `tests/early16_ui_b_runner.gd` 與引擎.uid、登錄 `tools/run_all_runners.ps1`；更新 `tests/uix_r1_components_runner.gd` 的圖形／鍵盤契約與歷史 `tests/res1c2_world_runner.gd` 離線關閉節點路徑（此歷史runner未登錄／未執行，不列通過）。新專項56 checks：滑鼠／Enter各一次回呼、disabled不觸發、七頁一個本地共用關閉、命中及頁內幾何、長內容確實捲動且關閉矩形固定、原close_requested／closed或hide。多尺寸沿DAO_VIEWPORT_MATRIX，本輪僅1280×720；受限面板580×340。
- **L1→L2命令／結果**：每次先 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'early16_ui_b_runner.gd,uix_r1_components_runner.gd,feature_navigation_runner.gd,ui_shell_integration_runner.gd,early16_ui_a_runner.gd' -List`（後續精選相同檔名子集）再執行。5支PASS／exit0，日誌 `dao2_runners_8fe27f40a7ef4bf4aaa2af0d89c405d7`；紙面頁首小修後4支補驗（B／A／shell integration／components）PASS，`dao2_runners_1fae33135d534486b1a319794b37ad9f`；新專項加入實際捲動斷言後最終56 checks／exit0，`dao2_runners_24a371f44c9f4c4ab5b6cb8bdf7ed483`。共用元件與跨頁殼按L2；非全量、未跑L3，evidence guard通過。
- **失敗／修正**：最初selector包含未登錄的res1c2_world，List拒絕後改精選5支；新runner初次缺RunnerResult.finish雖49 checks零失敗仍被正確判FAIL，已補正式結果標記。沙箱user://寫入失敗令shell整合SCRIPT ERROR／45秒timeout，改正常本機權限隔離測試後PASS。捲動補強曾將filler加為Label子節點而不撐大正文，2條斷言失敗，改直接加長Label文字後56 checks PASS。這些失敗不計成功。既有引擎anchor／RID退出診斷不宣稱消失。
- **新版Web與實際桌面**：版本 `4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import`、`--export-release Web build/web-early16-ui-b/index.html`、`node tools/prepare_web_compression.mjs build/web-early16-ui-b` 均exit0。PCK SHA256 `920f3da2a259cd1f190a715019de9e0c7723875c539968166a8b64d32d97452a`。本機測試包，普通build/web未同步，無發布候選包。既有island_preview_server Handler於127.0.0.1:4431服務本包，獨立origin正常空白檔，無fixture注入；沙箱服務無法由桌面存取後停用並以正常權限單一服務重開。IAB頂層1280×720 CSS px、DPR1.25：實際關閉離線摘要、營造簿回洞府、存檔頁本地叉號返回、Debug長內容捲至宗門／靈獸／診斷後頁首固定且可關閉；未點Debug贈料／改規則。warn/error查詢空。截圖 `.test-output/early16-ui-b/browser/`：offline、buildings、save、debug-scrolled.png。未推定自然通關、保存故障、FPS或全部七頁瀏覽器證據；其餘頁面為CLI整合／幾何證據。
- **收尾／下一步**：`python tools/delivery_check.py --web build/web-early16-ui-b`：7/7壓縮檔match、RESULT PASS，證據目錄變更0。本輪測試服務以Ctrl+C停止（主動終止exit1）、瀏覽器測試分頁關閉與尺寸覆寫清除。`git diff --check` exit0。共用規範／docs44更新接線，README／ROADMAP／ai-handoff僅一行狀態連結；英文checkpoint置updata頂部、最多5筆。現有UI-A及OpenCode數值線成果保留（本輪觀察到數值線A完成交接），未納入UI通過範圍。未commit／push。**UI-B階段完成，可手動commit；完整EARLY-16-UI仍IN_PROGRESS。下一New Chat接UI-C資源數字與超框，K/M/B/T仍候選待確認；P3／P4後排。**

<a id="early-16-ui-a"></a>
## 2026-10-28 EARLY-16-UI-A：列尾動作對齊 DONE（L2，介面子階段）

- **交付與檔案**：`building_catalog.gd` 將升級鈕移到圖像／資訊列的最右側，按整列垂直置中，詳情鈕也置中；列間距8→4，保留104×108建築縮圖與原字級，避免數字刷新撐寬。`island_management_panel.gd` 的採集／倉儲設施改為可展開文字／材料欄＋右側置中升階鈕。`island_transport_panel.gd` 的啟停／設定移出文字底列，整組在卡右側置中；一般版上下排列、短式並排，窄於430px的受限容器改上下內容並靠右放動作。`realm_decision_view.gd` 的施行鈕由貼底改置中；`realm_teleport_modal.gd` 的據點升級鈕按標題列置中。`recipe_row.gd` 的模式區展開，開始／停止及設定保持右側且置中。未修改規則、數值、成本、View／命令payload或存檔schema。
- **盤點邊界**：技能卡、靈獸主列／天賦列、宗門任務／研習／坊市、輪迴天賦的原展開文字欄與置中動作沿用；煉丹原材料列右側動作群已有容器置中。成就徽章、機緣選項整格、九界標記嚮往、獨立確認／取消與固定頁首動作依各自語意保留。文字關閉／CloseSeal圖形與資源超框仍屬UI-B／C，不藉UI-A改格式或數值。
- **測試補強**：新增 `tests/early16_ui_a_runner.gd`（連同Godot產生的.uid）並登錄 `tools/run_all_runners.ps1`。以實際Control矩形驗建築／設施的卡片安全右內距、動作中心Y與44px，航線一般及410px受限容器、長法令標題／缺料→就緒→已施行顯示、內捲末項可達及刷新不改快照；技能／靈獸既有列與製造可見列作比較。多尺寸沿DAO_VIEWPORT_MATRIX；本輪matrix=single，非全尺寸驗收。
- **L1→L2命令與結果**：先 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'early16_ui_a_runner.gd,uix_r4_building_cards_runner.gd,uix_r11_decisions_ui_runner.gd,imm3a_cost_detail_runner.gd,recipe_row_runner.gd' -List` 確認5支，再同selector執行。原成本詳情10.6s／法令命令9.1s／配方2.6s通過；新專項與建築測試修正後先List再選兩支重跑，10.9s／3.7s均PASS、exit0，最終日誌 `dao2_runners_ae01e6ba438d49a6b4d1617e42af0999`。領域追加先List再執行 `-Only 'res1_ui1b_runner.gd,imm3c_page_consistency_runner.gd' -TimeoutSeconds 120`，2／2 PASS（航線82.1s／跨頁18.8s），exit0，日誌 `dao2_runners_47c5b63a5a6c4ba384d71758525be286`。120秒只因航線既有合理長測試約82秒。合併**7支受影響runner均有PASS，1280×720，guard通過**；本次UI領域跨建築／設施／運輸／製造／法令，按L2記錄，未跑L3。
- **失敗與修正**：新runner初次snapshot型別推斷錯誤，後續誤用transport.refresh少一參數導致SCRIPT ERROR／45秒timeout，另把隱藏配方未布局位置計入幾何斷言；均已修正，不計該輪成功。建築測試確實抓到10000.25庫存把窄卡撐寬6px，縮小容器間距後原刷新／尺寸回歸通過。一次Python診斷因系統預設cp950讀UTF-8失敗，改明確UTF-8後成功；未變更遊戲文字。沙箱下user://日誌不可寫，正式Web匯出與一次診斷改正常本機權限；既有anchor／RID退出診斷保留，不稱零警告。
- **新版Web**：引擎 `4.7.2.stable.official.ed1daf0bf`；`--headless --path . --import` exit0；初次匯出因目標資料夾不存在exit1，建立專案內資料夾後 `--headless --path . --export-release Web build/web-early16-ui-a/index.html` exit0。`node tools/prepare_web_compression.mjs build/web-early16-ui-a` exit0。PCK 126318056 bytes，sha256 `9ee0fb0d88227d540ac719d5e49ba3bf8187f2fef497dd4775ca22074ec80e4f`。只更新本機測試包，沒有製作發布候選包。
- **真實桌面抽驗**：沿既有island_preview_server Handler服務新origin `127.0.0.1:4429`，BUILD指向本次包，既有 `content_p1_skills_fixture.json` 作隔離測試快照，使用正常dao2_saves namespace但與玩家origin分離。最初重複服務導致連線逾時，關閉兩個本輪服務後單一服務正常。IAB頂層 **1280×720 CSS px／DPR約1**：實際點營造聚靈壇2→3、青木倉儲1→2、法令編纂道藏施行並進冷卻，成功／禁用後動作仍對齊；運輸在途／已達目標／未開島禁用及製造模式／停止／設定亦目視通過。截圖 `.test-output/early16-ui-a/browser/` 的buildings、building-upgraded、facility、facility-upgraded、transport、manufacturing、decisions.png。browser warn/error查詢空；不推定全頁自然通關、保存故障或FPS證據。
- **收尾／下一步**：通用 `python tools/delivery_check.py --web build/web-early16-ui-a`：7／7壓縮檔match、RESULT PASS；`git diff --check` 最終exit0（updata末尾多餘空白行已修正）。evidence guard路徑變更0；收尾另見數值線 `tools/early_pacing_audit.gd`／`tools/early_pacing_targets.json` 及 `docs/verification/early-pacing-baseline.json`／`.md` 在本輪期間有外部變更，完整保留，未納入本UI交付或驗收。測試服務已Ctrl+C停止（主動終止exit1）；README／ROADMAP／ai-handoff只加入口，docs19沿既有規範補接線指向，docs44標記A完成／B下一。英文checkpoint置updata頂部，最多5筆。工作區原有規劃文件變更保留，未commit／push。本次 **UI-A子階段完成，可手動commit**；完整EARLY-16-UI仍IN_PROGRESS。下一New Chat接 `EARLY-16-UI-B` 圖示關閉，OpenCode數值線獨立；P3／P4仍後排。

<a id="early-16-balance-a"></a>
## 2026-10-28 EARLY-16-BALANCE-A：Era1–6 基線稽核擴充 DONE（工具線，未改遊戲數值）

- **範圍**：只讀基線稽核，不改 `src/`、`content/`、存檔或UI。把 `tools/early_pacing_audit.gd` 從 Era1–3／Era2 空島擴到 Era1–6：接上 `IslandProgression.attach_supply`、逐境界列突破需求與容量、二級資源供需、空島產率／運輸、配方瓶頸、補給建築取得成本。
- **修改檔案**：`tools/early_pacing_audit.gd`、`tools/early_pacing_targets.json`（新增 C11～C16 門檻）、重生成 `docs/verification/early-pacing-baseline.md`／`.json`。
- **命令與結果**：`.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools\early_pacing_audit.gd` → `PACING AUDIT: 16 findings, 1 FAIL`（僅C1 FAIL，其餘WARN／OK）。
- **主要證據**：Era1–6 訓練鐘 16.8／41.6／90.7／235.0／529.3／1518.6 分（E4–6 合計約38小時）。E4–6 靈力占各自鐘 68.3%／60.6%／42.2%；突破庫存／容量餘裕僅 1.23–1.31x（E4靈力、E4石、E5靈力、E5石）。二級空島產出遠超消耗：秘銀71x、寒鐵282x、千年靈草254x；對應需求占比僅0.4%–1.4%。補給建築取得成本僅占境界鐘0.1%–2.9%，等於免費解鎖。航運預設 `route_policy.enabled=false`、一級1/s，空島300容量在1500–3750秒滿倉。Era1 C1 仍為26/92列容量低於下一級成本。
- **限制**：靜態模型，無玩家存檔／輪迴狀態；離線與第一世／輪迴對照留待B。C14「航運預設關閉」是現行設計狀態，不是已判定缺陷。
- **下一步**：`EARLY-16-BALANCE-B` 成長曲線（用此基線決定Era4–6靈力與突破需求、時間倍率的改動幅度）。

<a id="early-16-workstreams"></a>
## 2026-10-28 EARLY-16 分工：OpenCode 數值／Codex 介面（規劃交付 DONE，實作各自 TODO）

使用者指定將數值與介面拆開：數值由使用者交給OpenCode跑模型及修改，介面留給Codex。原 `EARLY-16-POLISH-A` 混合盤點不再作Codex下一任務；改分 `EARLY-16-BALANCE` 與 `EARLY-16-UI`。完整分工、可複製OpenCode指令、批次與DoD見[docs44](44-era1-6-balance-and-ui-workstreams.md)。Era7–12的P3／P4繼續暫時後排。

- **OpenCode數值線／基線DONE、調整TODO**：Era1–6成長節奏與數值、經濟建築升級成本／收益／最大等級、空島原料到二級資源與合成物的供給／消耗／運輸鏈。A已把稽核擴至Era4–6與補給空島，證據見[EARLY-16-BALANCE-A](#early-16-balance-a)；後續依證據分批改正式數值。模型需比較現版與調整版、第一世／輪迴後與代表選修路徑；Codex不代跑或擅改此線。
- **Codex介面線／TODO**：`EARLY-16-UI-A`列尾動作靠右且垂直置中；`UI-B`共用圖形關閉與可見文字入口遷移；`UI-C`資源數字／入口超框及短格式。下一Codex先UI-A，與數值模型可獨立進行。
- **實際來源核對**：技能卡已有展開文字區與垂直置中動作，不將所有頁假定為錯誤；多個面板及存檔頁仍建立文字關閉入口，需按正式可見路由確認。CloseSeal本體目前為文字×。資源格與材料格直接使用NumberFormatter，現行為萬／億／超大數科學記號，尚無按可用寬度選短格式。
- **共用規範**：同步docs19記錄使用者指定的列尾對齊、圖示關閉與資源顯示要求。K／M／B／T候選方案在docs44定義，尚未當作使用者核定切換；完整值留TIP／詳情、不改Amount契約、庫存或成本判斷。先處理不依賴單位選擇的UI-A／B。
- **變更範圍**：新增docs44；更新docs19、README／ROADMAP／ai-handoff入口、技能與內容排程入口、本狀態及英文checkpoint。只讀檢查來源，未修改遊戲程式、數值、素材、存檔或Web包；本次交付是具體分工與可執行批次，未宣稱UI問題已修復。
- **驗收**：純規劃／文件靜態檢查及 `python tools/delivery_check.py`；不觸發runner／Web匯出／L3。後續實作按影響做L1／L2，觸控／實機延期政策保持。

分工規劃階段完成，可手動commit；不是數值或介面大型任務結案。未commit／push。依Context Guard於此checkpoint，下一New Chat可直接「Codex接EARLY-16-UI-A」，OpenCode另接EARLY-16-BALANCE。

<a id="early-16-polish"></a>
## 2026-10-28 EARLY-16-POLISH：Era1–6 數值與介面打磨優先（排程已更新，實作 TODO）

> 同日後續使用者已指定分工，原混合盤點順序由[OpenCode數值／Codex介面](#early-16-workstreams)覆蓋；下文保留前次排程歷史。

使用者明確將 `RES1-E-79 → CONTENT-P3／SKS-P3` 與 `RES1-E-1012 → CONTENT-P4／SKS-P4` 暫時後排；目前優先打磨 Era1–6 的數值及相關介面。此決策覆蓋舊交接中的「下一P3」或長期相依被當作立即開工順序的解讀。兩批擴充保留規劃與ID，待使用者後續指定恢復優先；不設定自動恢復日期。

- **目前任務 EARLY-16-POLISH／TODO**：依現有 Era1–6 已接線規則、資源／加工／航運、技能／丹藥／宗門與輪迴，改善成長節奏、成本與收益，以及操作資訊與回饋。保留既有已接受美術及共用UI規範。
- **首個子階段 EARLY-16-POLISH-A／TODO**：建立現行數值與可達路徑基線，列出各境界突破／容量／產率／加工及航運等待、技能與丹藥的投入回報、第一世與輪迴後差異；核對對應介面的成本、缺料原因、進度、禁用理由與操作步數。交付具體瓶頸、優先級、改前／改後建議與驗收案例，避免無依據先全面改數字。
- **後續按問題分批修正**：優先解決卡關、無效選擇、等待失衡與資訊不清；再做數值與介面聯動驗證。數值差異記為明確v2調整，不以展示值取代正式公式，不新增Era7–12內容。
- **驗收**：盤點／排程只做靜態檢查；實作子階段採受影響1～5支L1，功能完成採L2及UI新版包桌面1280×720抽驗。僅大型任務最終收尾才做一次L3，不因這次改排程跑全量或匯出。觸控／實機與慢網冷啟動延期政策保持。
- **本次變更與結果**：同步ROADMAP、內容／技能排程與交接入口、英文checkpoint；未修改遊戲數值、來源、素材、存檔或Web包。IMM-4-R1／R2依最新記錄已完成，不沿用更早審查的TODO重開。

排程調整階段完成；下一New Chat可從EARLY-16-POLISH-A開始，暫不展開P3／P4。未commit／push，可手動commit（本次是排程階段結束，不是Era1–6打磨大型任務完成）。

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
