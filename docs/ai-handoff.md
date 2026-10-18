2026-10-18 **UIX-R7-F5-D 輪迴動態效能驗收 DONE（桌面／Web有界；desktopRecoveryGate=PASS）**：依使用者「F5-D 效能驗收」指令完成原生與真實 Edge 瀏覽器 Web 效能驗收。原生探針（tools/f5d_native_probe.gd）實測 3600 幀平均 144.83 FPS、p95 6.99ms；真實 Edge 155 視窗（CDP 驅動，1280×720，DPR 1.0）執行 60 秒常態取樣（59.9969 FPS，p95 16.80ms，>20ms 0 幀，100% ≥55 FPS）與 300 秒（5 分鐘）長時段持續運行取樣（59.9969 FPS，60/60 窗口滿幀，尾端 10 秒 59.995 FPS 恢復，longestLowMs 0.0ms）。官方 tools/summarize_frame_metrics.py 判定 desktopRecoveryGate=PASS。冷啟動依政策暫緩常態阻擋；觸控／實機依 2026-10-17 政策延期。F5 拆層輪迴演出整體實作與效能驗收正式結案。[完整驗收](verification/uix-r7-f5d.md)。
2026-10-18 **UIX-R7-F5-C 匯出與全量回歸交付 DONE**：依使用者指令完成 Web 匯出（Godot 4.7.2 `--export-release Web build/web/index.html` exit 0）、Web 資源 brotli 壓縮及 BGM companion 檢查 exit 0，並於 PowerShell 成功執行全量測試套件 `tools/run_all_runners.ps1`（75/75 Runners 全部通過，exit 0）。正式輪迴演出已接線至 `reincarnation_mandala.gd` / `reincarnation_sequence.gd`，涵蓋三尺寸原生、低特效靜態、跳過與結束清理。
2026-10-18 **UIX-R7-F5-B 視覺接受／F5-C 開工**：使用者明確核定「F5-B 視覺接受，開始 F5-C」，接受最新B-F2轉盤在外框上方之呈現。B視覺閘門完成；C接正式輪迴頁／演出，驗三桌面尺寸、低特效、skip、保存與重開；D持續效能尚未開始。此段覆蓋下方B待接受歷史。

2026-10-18 **UIX-R7-F5-B-F2 方案2交付，IN_PROGRESS（待視覺接受）**：依使用者指出中央圖完整但仍遭外圈遮擋，改共同投影內的繪製順序為外框index0／轉盤index1，中央盤面位於外框上方。未重繪／未實作2px間隙，保留F1尺寸與中心。Godot4.7.2隔離匯出exit0、三原生尺寸／生命週期等checks failures=[]、八角度及384影格、裸盤整圈8秒錄影與Web滑鼠切裸盤已驗；非FPS證據。正式頁／一般Web／玩家資料未改，未commit/push。下一New Chat先收方案2視覺回饋，C／D未開。[驗收](verification/uix-r7-f5b-f2.md)。
2026-10-18 **UIX-R7-F5-B-F1 修訂試演交付，IN_PROGRESS（待視覺接受）**：依回饋重繪連續盤心，轉盤縮正0.86並對齊固定開口，修復主要刻紋被外殼截去的接合；文字改暖白芯／橙金強泛光與中文＋天城體梵文長柱，完整字群不拆連字，出場錯開避免重疊。八角度裸盤、合成／裸盤各8秒實際Godot渲染、384影格與原生三尺寸檢查failures=[]、桌面Web泛光開關／裸盤／短式等交付；非FPS證據。新盤原稿／prompt及Noto OFL保存，舊圖與舊錄影保留。正式程式／一般Web／玩家資料未改，未commit/push。下一New Chat先收F1視覺回饋，C／D未開。[驗收](verification/uix-r7-f5b-f1.md)。
2026-10-18 **UIX-R7-F5-B 隔離動態試演交付，IN_PROGRESS（待視覺接受）**：九層獨立Godot試演，盤面先轉後投影、固定朝向浮蓮／局部呼吸光、錯速霧與六道直排字；OFL文楷候選／授權與自寫Shader已保存。三尺寸原生檢查failures=[]、192影格8秒合成錄影、隔離Web三尺寸滑鼠／低特效／紙夜／重載通過；錄影非FPS證據。初輪型別／user目錄／連線失敗與修訂已記錄。正式程式／一般Web／玩家資料未改，未commit/push。使用者指定B授權接續，不追認A獨立接受；B視覺待接受，C／D未開。下一New Chat先收B回饋。[驗收](verification/uix-r7-f5b.md)。
2026-10-18 **UIX-R7-F5-A 素材／靜態檢查交付，IN_PROGRESS（待美術接受）**：內建ImageGen重建九個1024透明圖層，完整盤面／固定外殼／蓮花／遮罩／掛飾／流光／三霧；十次原稿與完整提示詞、manifest／SHA256、黑灰白底、拆層標示及四角度重組／裸盤已保存。Godot4.7.2離線包裝與安全邊／中央覆蓋檢查exit0，標示工具exit0；首跑user log寫入錯誤保留，最終指定專案log成功。靜態目視無露洞或花霧殘影；未宣稱動態／Web／FPS通過。正式程式／一般Web／玩家資料未改，未commit/push。下一New Chat先收A美術接受，再開F5-B隔離試演。[驗收](verification/uix-r7-f5a.md)。

2026-10-18 **UIX-R7-F5-PLAN 規劃DONE；實作TODO；F4視覺需重做**：使用者指出F4未讓原圖圓盤轉動，要求先規劃。新方向為完整拆層／補繪盤面、蓮花固定朝向浮動與邊緣呼吸光、雲霧左右漂移、豎排水墨字與局部柔光。已查Godot官方／Shader來源與授權；Compatibility／Web效果仍須實測，不宣稱已接入。僅文件，未改程式／素材／字型／匯出／玩家資料，未安裝插件。下一New Chat依F5-A先交拆層重組與四角度檢查，再F5-B隔離動態確認；視覺接受前不更新一般Web。 [完整規劃](22-reincarnation-layered-vfx-plan.md)。

2026-10-18 **UIX-R7-F4 輪迴動態試作交付，IN_PROGRESS（美術／持續FPS待驗）**：桌面300px命盤、反向符環／上浮六道文字與28光粒、6.2秒轉世演出最高460px；短式56px與低特效保持。75項UI、輪迴規則／UI及動態生命週期通過；三尺寸原生與桌面Web、隔離真實轉世→第2世結算已驗；一般與R7Web匯出／壓縮／字型通過。初次沙箱／缺字／短式失敗及退出診斷保留。沿用既有美術，未改收益規則、未commit/push。下一New Chat收試作視覺回饋，不開突破演出。 [驗收與命令](verification/uix-r7-f4.md)。

2026-10-18 **UIX-R11-DECISIONS 實作／桌面Web驗收交付，IN_PROGRESS（美術待接受）**：人界／靈界四張內建ImageGen透明圖印、固定界域與雙欄／短式單欄法令卡、效果／持有需求／冷卻施行與保存重試已接入。修正herb／lingqi正式資源接線、補目前界域命令驗證。Godot4.7.2，74固定Runner及最終63專項／五相關回歸exit0，21原生圖、兩版Web匯出壓縮／字型check通過；桌面三橫式、實付道藏／疏脈／靈潮、拒寫恢復重載1次與長文大數已驗。初輪圖印／長卡／重複字串失敗及既有退出診斷保留。保留SKS-P1與其他dirty成果，未commit/push；R8／R9美術狀態不變。下一New Chat先收R11回饋，本階段停止。[驗收與命令](verification/uix-r11.md)。

2026-10-18 **UIX-R10-FORTUNE DONE（桌面／Web有界；使用者美術接受）**：使用者明確回覆「R10 美術接受」，六張題材圖與天機奇遇現版呈現通過人工接受。既有58專項、72固定Runner分段、最終四相關回歸、21原生圖及桌面三橫式／付費／保存恢復／重載／長文證據沿用原日期；本輪核對既有log與R10Acceptance PCK hash一致，未重跑遊戲測試。僅更新README、ROADMAP、handoff、status、docs20、R10驗收及updata，未改程式／匯出／玩家資料，保留SKS-P1與其他dirty成果，未commit/push。歷史美術待接受聲明由本段覆蓋；R8／R9狀態不由此次核定變更。裝置項依既定政策延期，非當前阻擋。下一New Chat可由使用者核定UIX-R11天道決策，本輪止於R10收結。

2026-10-18 **RES1-E SKS-P1 DONE（批次 B1：`golden_core_formation` 承接；美術待生成）**：使用者核定 P3-1。結丹法 era3／前置 foundation_building:1／max 5／7650 點每級／time_multiplier 0.9（訓練時間 ×pow(0.9,N)，`Cultivation.apply_time_bonuses` skill_time_mult 通道接 game_session view、_apply_level_up、_apply_consume_pill 三處，線上離線一致）。`skill_system.gd` VERSION 2（支持 versions [0,1,2]、era/requires 新欄位、SKILL_ERA_LOCKED／SKILL_PREREQ_LOCKED、view 閘序 study>era>prereq>max>point）、save codec `core-flow-12-skills-p1`／skills≤7（save_manager 沿既有 reconcile→archive `save_before_skills_<sha>`→重試機制，未改檔）、技能頁「境界未達／前置未足」文案。Runner：`tests/sks_p1_runner.gd` 58 checks exit0 無 SCRIPT ERROR（log `build/sks_p1.log`）；B1 41、R8 101（修正 last-action 指向金丹卡後重跑）回歸 exit0。fusion-auditor 9/9 PASS；Era3 突破閘不受技能影響；game_session 內 training_complete／AFFORD_TOLERANCE hunks 屬既有 HUD-F1 dirty work，非本批。未通過：金丹題材圖未生成（manifest `pending_art`＋提示詞已存，待生成＋人工接受）；僅 headless CLI，Web 匯出／桌面三橫式未重跑；觸控延期。未commit／push。見[驗收](verification/res1-e-skills-p1.md)。下一步：R8／R9／R10 美術回饋→R11→SKS-P2 另行核定；建議 New Chat。

2026-10-17 **RES1-C3 放行 DONE／RES1-E-SKILLS-PLAN 規劃交付（僅規劃與文件，未改程式／匯出／存檔）**：使用者實玩隔離 origin（4199 正常包）核定「RES1-C3 放行」，人類美術／節奏通過，RES1-C3 收結、RES1-C 整體 DONE（[驗收追記](verification/res1-c3-art-integration.md)）；裝置項延期非阻擋。同輪依 docs/20 尾階段 DoD 交付技能擴充規劃（盤點／Era1–3 核對 / Era4–12 分批清單，`golden_core_formation` 提案 P3-1、`nascent_soul_incubation` 待承接）：[計畫](21-res1-e-skills-expansion-plan.md)。技能源頭契約續沿 [ADR-012](decisions/ADR-012-optional-skills-with-islands.md)。未commit／push。下一步：R8／R9／R10 美術回饋 → R11 天道決策 → 技能逐批另按清單核定交付；本批尾階段已收，建議 New Chat。

2026-10-17 **UIX-R10-FORTUNE 實作／桌面驗收交付，IN_PROGRESS（美術待接受）**：六張ImageGen透明題材圖映射26既有事件；1120px圖文分欄／短式小題圖內捲，選項文案／代價／44px動作分離，刷新保留命中與結算訊息。修復herb／lingqi對正式靈草／靈力接線；保存拒寫／重試不重複結算。Godot4.7.2、58專項與72固定Runner分段通過，最終四相關回歸exit0；21原生圖、兩版Web匯出壓縮／字型check通過，桌面三橫式與真實付費拒寫恢復／重載保持1次已驗。初次失敗與既有退出診斷保留；未commit/push。使用者「R10」覆蓋歷史不開R10指示，R8／R9美術仍待接受。本階段停止，New Chat先接R10回饋，後續R11→RES1-E-SKILLS-PLAN。[驗收](verification/uix-r10.md)。

2026-10-17 **UIX-R9-F1 圖像減字修訂交付（美術待接受）**：委託品階改白／綠／藍／紫／金小圖示，名稱後直接顯示120s；貢獻與現有資源獎勵改圖示＋數字，無專圖才用文字。派遣改56px無框飛劍圖片按鈕，說明移TIP並收重複橫幅。Godot4.7.2、166專項與宗門UI／導覽／響應式回歸exit0、24原生圖、兩版Web匯出／壓縮／字型check通過；桌面Web三橫式、1280及800實際派遣→領80（1000→1080）通過。初輪版面／字型占用失敗與既有退出診斷保留；未commit/push。R9完整美術仍待接受，本輪不開R10。[驗收](verification/uix-r9-f1.md)。

2026-10-17 **HUD-F1-PROGRESSION-LIFE DONE（桌面範圍）**：修滿即顯示晉階；缺料禁用並揭露持有／需求，普通生產補足立即啟用。修正訓練四捨五入假滿。壽元改0起累計已用／上限，1/3黃、2/3橙、90%紅、壽盡80/80紅，圖示同步；短式保留44px與資源列。57專項、分段71 Runner及最終五項相關回歸通過，21原生圖、兩版Web匯出壓縮、字型check與桌面Web滑鼠晉階／重載／配色完成。初期失敗與既有退出診斷保留；未commit/push。R8／R9美術待接受，R10→R11→RES1-E-SKILLS-PLAN排程不變。本階段結束，下階段New Chat。[驗收](verification/hud-readiness-life-r1.md)。

2026-10-17 **UIX-R9-SECT 實作／桌面Web交付，IN_PROGRESS（美術待接受）**：13張ImageGen圖（五宗門／四功法／四委託題材）、1120px雙欄／短式單欄、固定貢獻／三分頁／內捲、派遣與真實成本狀態已接入；保存失敗留頁內、重試不重扣。Godot4.7.2，固定70 Runner通過；末輪版面修正後164專項與宗門UI／導覽／響應式回歸exit0，24張原生三橫式、兩版Web匯出壓縮／字型check通過。隔離Web實際入宗、派遣完成領獎、參悟50／兌換30／領80、拒寫恢復第二重925不重扣與重載、短式內捲返回／長文大數已驗。初次失敗與退出／anchor診斷保留；未commit/push。使用者已排R9→R10→R11→RES1-E-SKILLS-PLAN（盤點／分境界／可執行清單），技能尚未擴增；R8美術仍待接受。[驗收與命令](verification/uix-r9.md)。

2026-10-17 **UIX-R9-SECT 開工／尾階段技能規劃排程**：使用者核定接續宗門頁，覆蓋此前不開R9限制；R8仍為美術待接受。R9範圍為五宗門徽記、四功法圖、委託題材圖及山門／歷練／傳承／坊市，驗收入宗、派遣領獎、扣費、保存恢復與三桌面橫式。後續R10→R11→RES1-E-SKILLS-PLAN：技能內容盤點、分境界規劃、附相依與驗收的可執行清單；該尾階段尚未實作，不宣稱技能已擴增。詳見[批次計畫](20-feature-interface-art-plan.md)。

2026-10-17 **UIX-R8-SKILLS 實作／桌面Web驗收交付，IN_PROGRESS（美術待接受）**：六技能圖＋研習題圖、固定技能點／來源、1120px雙欄／短式單欄卷冊、當前／下階效果及保存重試已接入；修正重開CloseSeal與設定鈕遮擋。Godot4.7.2、92專項、69固定Runner分段通過；12張三橫式原生、最終Web真實研習／拒寫恢復不重扣／重載、長文大數與返回已驗。兩版Web匯出壓縮與字型check通過；初次失敗／舊斷言及退出診斷保留。未commit/push；下一New Chat只接R8美術回饋，不開R9。[驗收與命令](verification/uix-r8.md)。

2026-10-17 **UIX-R7-REINCARNATION DONE（桌面／Web有界；使用者美術接受）**：使用者明確回覆「R7 美術接受」，接受含F1圖像式壽盡／自動開頁、F2卷軸安全邊界與F3移除空白壽元槽的最終呈現。既有最終75 checks、三橫式原生／桌面Web、確認取消／天賦保存恢復／轉世重載與相關回歸證據有效，一般Web PCK hash與F3驗收一致。本輪只更新文件並核對既有log／hash，未改遊戲／匯出／玩家資料，未重跑Godot或Web。觸控／實機延期，非當前阻擋；未commit/push。下一候選為UIX-R8-SKILLS，待新對話明確開工，本輪不實作。[最終驗收](verification/uix-r7-f3.md)。

2026-10-17 **UIX-R7-F3 空白壽元槽移除**：依使用者回饋，移除僅壽盡時顯示且固定為0的ProgressBar；保留命燈、壽盡文字、收益、轉世確認取消與自動提醒。Godot4.7.2輪迴專項75 checks、三橫式原生24圖、兩版Web匯出及壓縮通過；桌面Web三尺寸核對與1280確認取消已驗。R7最終美術仍待接受，不開R8。[驗收](verification/uix-r7-f3.md)。

2026-10-17 **UIX-R7-F2 卷軸安全邊界修正已交付，R7美術待接受**：根因為背景Panel不自動套內容內距，輪迴手寫底部8px小於底軸約13px。共用正式卷軸上下20px、細軸上10／下14px，三手動頁沿同一StyleBox；短式搭配細軸與內欄間距避免壓縮內容。R7專項75、成就221、製造223／運輸220及相關回歸通過，24原生圖、Web匯出壓縮通過。既有退出診斷及中間回歸失敗已記錄；未commit/push，不開R8。[驗收與命令](verification/uix-r7-f2.md)。

2026-10-17 **UIX-R7-F1 圖像式壽盡／自動提醒已交付，R7美術待接受**：熄滅命燈、耗盡槽與收益卡取代長篇概覽，貨幣併固定分頁，主操作置中，重置細節可展開且確認時揭露；短橫式保留命燈與預期收益。壽盡沿正式路由主動開頁、等報告／演出結束，同狀態關閉不反覆搶頁，重載／新世／延壽後再壽盡可提醒。68專項與四相關回歸、三尺寸原生／桌面Web及匯出壓縮通過；既有退出診斷保留。未commit/push，不開R8。[驗收與命令](verification/uix-r7-f1.md)。

2026-10-17 **UIX-R7-REINCARNATION 實作／技術驗收已交付，IN_PROGRESS（美術待接受）**：使用者「R7開工」已覆蓋歷史不開R7指示。四張ImageGen透明手繪圖、固定GameTab／內捲／確認取消、天賦圖卡與保存重試已接入；修復轉世結算世次與導覽遮擋／輸入順序。R7專項55 checks、輪迴核心／UI及四相關回歸皆exit0，三尺寸15張原生圖、隔離Web實付參悟／拒寫恢復不重扣／確認取消／新世重載與返回已驗。一般Web與獨立驗收版匯出／壓縮成功，既有退出診斷及中間失敗如實保留。未commit/push；下一New Chat只接R7美術回饋，不開R8。[驗收與命令](verification/uix-r7.md)。

2026-10-17 **UIX-R6 桌面／Web有界DONE；觸控／實機延期**：使用者核定未來任務暫不安排觸控與實機測試，待專案完成度夠高再啟動；含實機DPR2／3，非當前阻擋，未宣稱通過。R6比例已接受、221 checks與三橫式Web長文／領取／內捲／返回等已交付，本階段依調整後範圍結案。R7仍不開工。此次僅更新AGENTS、07、19、README、ROADMAP、handoff、status、20、R6驗收與updata；UTF-8／diff-check另驗，未改遊戲／匯出／存檔，未重跑Godot或Web。下一步等待使用者指定內容任務，不排實機。

2026-10-17 **最新接手：UIX-R6比例已接受／長文Web有界PASS**。使用者回覆「維持目前比例」，不再重問128／112尺寸。R6Acceptance獨立Web版（src/verification/uix_r6_acceptance.gd/.tscn、project feature override／preset）補三橫式長標題／大數顯示與800真實領取／成功訊息／內捲／返回；正常Web hash未變。221 checks／fixture CLI／匯出壓縮exit0。權威存檔為localStorage＋Web Lock，IndexedDB觀察不列R6必要缺口。完整R6仍IN_PROGRESS：僅實體觸控／DPR2or3待驗；不開R7、未commit/push。初跑fixture時序與歷史PNG import錯誤如實保留，見[驗收](verification/uix-r6.md)。

2026-10-17 **UIX-R6-F2 成就大圖回饋已交付；完整R6仍IN_PROGRESS**：依使用者回饋移除卡內說明，只留標題／獎勵與必要領取狀態；徽章72→桌面128px、短橫式最多112px，短式收起總覽，保存回饋時配適完整圖像。成就221 checks、四相關回歸、12張原生圖、Web匯出／壓縮通過。三橫式Web大圖／分類／內捲／返回與既有領取保存保持已複核；F1拒寫恢復提示修復保留。新比例人工接受、實機觸控／高DPR與長文大數Web仍待驗。未commit/push，下一New Chat收R6回饋，不開R7。[驗收與命令](verification/uix-r6.md)。

2026-10-17 **UIX-R6-F1 成就回饋／Web有界驗收通過；完整R6仍IN_PROGRESS**：修復全畫面保存重試成功後成就頁仍顯示失敗。成就專項195 checks及五相關Runner、Web匯出／壓縮／字型check皆exit0；IAB隔離origin正常採集建屋→實領靈木100→紅點清除→重載、三橫式分類／內捲／返回與旋轉恢復已補驗，最終版拒寫／恢復／重試不重發通過。美術接受、實體觸控／高DPR、長文大數Web與IndexedDB直接觀察仍待驗。未commit/push，不開R7；下一New Chat接成就回饋及剩餘裝置驗收。[驗收與命令](verification/uix-r6.md)。

2026-10-17 **UIX-R6-ACHIEVEMENTS IN_PROGRESS（成就頁來源／資產／CLI／原生交付）**：18枚內建ImageGen獨立透明手繪徽章、六分類代表圖與SegmentChips、功業／待領總覽、寬式雙欄／短橫單欄、固定回饋與返回已接入；領取保存失敗可明確重試，不重送獎勵。最終6項相關Runner皆exit0（成就頁188 checks）、三橫式12張原生圖、字型check、Web匯出／音樂與壓縮companions通過。IAB 127.0.0.1及localhost均ERR_CONNECTION_TIMED_OUT，Web實際互動／重載、人工美術／觸控／高DPR待驗，不標完整DONE。保留既有dirty成果與玩家進度，未commit/push。下一New Chat只收成就回饋與剩餘驗收，不開始R7輪迴。[驗收與命令](verification/uix-r6.md)。

2026-10-16 **UIX-ART-PLAN 規劃DONE／六頁實作TODO**：使用者指定每輪只做一個介面的資產生成、Godot接入、排版與驗收；順序為UIX-R6成就→R7輪迴→R8技能→R9宗門→R10機緣→R11天道決策。首輪從成就開始。素材清單、來源、共用風格、狀態／三尺寸驗收與New Chat提示見[六介面美術計畫](20-feature-interface-art-plan.md)。本輪僅規劃文件，未生成圖像、修改遊戲或跑Godot；既有dirty成果與Web待驗保留。

2026-10-11 **UIX-R4-F3 有界修訂 DONE**：依使用者回饋，建築圖56→88px（約57%放大），卡內改左圖／右資訊：名稱階級＋小動作在右上，材料ICON與庫存／需求在右下，保留雙欄與外環／壓暗禁用。四相關回歸／Web匯出壓縮exit0，三橫式IAB／實付升級／圖像展開詳情返回通過；人工比例／觸控／高DPR待驗。[驗收](verification/uix-r4-f3.md)。此段覆蓋F2卡內上下排版，其他契約保持。下一New Chat收比例回饋，不開大型下一任務。
2026-10-11 **UIX-R4-F2 有界修訂 DONE**：依使用者兩張參考圖恢復遊戲式雙欄建築卡；56px手繪縮圖、材料與庫存／需求納入同一卡框，僅保留縮圖外環。操作縮窄至64px／至少44px命中，缺料／前置／滿階壓暗。短橫式完整抽屜雙欄、暫收左側資訊，晉階／突破移至固定頁首，關閉恢復；桌面主動訊息可回單欄。最終六相關回歸、Web匯出／壓縮exit0，三橫式IAB／實付建造、升級、內捲、詳情返回與重載保留通過；人工美術／實體觸控／高DPR待驗。[驗收](verification/uix-r4-f2.md)。此段覆蓋R4-F1常態單欄，保留歷史。下一New Chat收本輪回饋，不開下一大型任務。
2026-10-11 **UIX-R3-F2 有界修訂 DONE**：依使用者核定統一資源三態／功能分頁／單選篩選的紙面＋青玉選中樣式與黑體，CloseSeal撤黑底；Era1隱藏空島／製造／運輸且情境路由回建築，Era2恢復，煉丹Era1保持。七項相關回歸exit0、Web匯出／壓縮、三橫式Web與隔離Era1／Era2驗收通過。新增[UI UX共用規範](19-ui-ux-guidelines.md)並接AGENTS必讀；人工／觸控／高DPR仍待驗。[驗收](verification/uix-r3-f2.md)。本段覆蓋R3-F1墨字／朱砂小印設計，歷史保留。

2026-10-11 **UIX-R3-F1 有界修訂 DONE**：分頁改卷首墨字目錄與朱砂小印，移除方塊底色／底線；可用項目按原順序排前、未開放項目灰化並標示『未開』排後，遠期隱藏保持，分頁不再使用tooltip。四項相關CLI回歸、Web匯出／壓縮與三橫式Web滑鼠切頁／返回通過；人工美術／實體觸控／高DPR待驗。[驗收](verification/uix-r3-feedback.md)。

2026-10-11 **UIX-R4-F1 有界修訂 DONE**：依使用者截圖移除重複橫向材料條、僅保留縮圖外環；營造簿上限400px單欄、56px列高／40px縮圖。六項相關回歸與三橫式Web滑鼠建造／升階／內捲／詳情返回通過，一般Web已同步；人工美術／實體觸控／高DPR待驗。[驗收](verification/uix-r4-feedback.md)。

2026-10-10 **最新接手：UIX-R4 建築清單圖形化有界DONE**。使用者明確指定R4；62/62 exit0及三橫式桌面Web通過，建造升級仍走原signal／Session。圖卡雙欄／短版單欄、就地材料圖示／庫存需求／局部不足、等級點與材料環、詳情紙面已交付；未加世界地塊。[驗收與命令](verification/uix-r4.md)，artifacts/uix-r4含截图、原圖、逐字提示、QC及全量log。保留所有dirty成果。下一New Chat收R4美術回饋，再界定UIX-R5；人工／實體觸控／高DPR待驗，不重跑已接受FPS／保存矩陣或暫緩冷啟動。

2026-10-10 **最新接手：UIX-R3來源／CLI／桌面Web已交付**。使用者已核定繼續UI改造，過往「未核定R3」為歷史。共用分頁／44px關閉、三態接入、分頁記憶回退、資源矩陣已完成；命令／日誌／三橫式與未驗限制見 [驗收](verification/uix-r3.md)。保留所有dirty成果；下一New Chat先收R3美術回饋，再續UIX-R4建築清單（必讀docs/08）。EARLY-FLOW人類節奏／觸控／高DPR保持待驗，勿重跑已接受FPS／保存矩陣或暫緩冷啟動。

2026-10-10 **UIX-R2-F1 卷軸試玩修訂已交付（美術回饋待確認）**：不放大外框，分頁／返回／目標／說明移除內層厚紙牌，選中用淡青玉與細底線，短卷軸換細青銅軸。HUD52、導航、responsive、B110與三尺寸原生渲染exit0；Web匯出壓縮／桌面滑鼠切製造／800×360返回通過。最終美術／實體觸控／高DPR仍待驗，節奏規則不改。
[修改與驗收](verification/uix-r2-f1.md)

2026-10-10 **EARLY-FLOW1-D 自然流程有界 PASS；完整 D 仍 IN_PROGRESS**：同一隔離Web進度、真實滑鼠與自然時間，築基一層／F7→十層→金丹→丹液加工回運→中品石50／陣芯1→金丹二層→靈狐首次餵養成長50及最終重載通過。修復築基圓滿主突破按鈕隱藏與離線累計年歲標示；D132、R2 HUD52、B110、responsive、M2-B／離線回歸及Web匯出壓縮exit0。約41分鐘至十層、中品石规则500秒；全觀測約69分鐘含修復／診斷，非純玩家預算。使用者決定「先保留基線，試玩後判定」，未調成本或工時。人類節奏／實體觸控／高DPR仍待驗；R2有界DONE保持。下一New Chat收試玩節奏／裝置結果，不開R3或後段、不重做已過保存／FPS。較早自然流程待驗聲明保留為歷史。
[本輪驗收與證據](verification/early-flow1d-natural.md)

2026-10-10 **UIX-R2 DONE（有界主 HUD／共用卷軸＋CLI／桌面 Web；使用者美術接受）**：本次使用者確認美術接受，R2 DoD 中的觸控／高 DPR 為獨立待驗項，不阻擋此有界範圍結案。現版 Godot 4.7.2 HUD 專項重跑 **52/52、exit0**；既有61/61（最終微調之前）、最終五相關回歸及三橫式 Web／實付晉階／重載證據有效，現有 PCK hash 與驗收一致。實體觸控／高 DPR、EARLY-FLOW1-D 自然時間及完整 UI1-C／C／D 仍待驗。本輪只核對與更新文件，未修改遊戲、匯出或玩家存檔。下一 New Chat 優先續 **EARLY-FLOW1-D 自然流程與節奏驗收**，可繼續既有四島／前期工作；未核定 UIX-R3，不直接跳 Era4–12。以下 IN_PROGRESS／等待美術段落保留為本日較早歷史。
2026-10-10 **UIX-R2 IN_PROGRESS（主 HUD／共用卷軸實作交付）**：青玉道印與四入口、朱紅真實待辦、青銅轉角、獨立目標掛軸、資源摘要／清單互斥與短橫式壽元已接入；空島／製造／運輸／系統頁共用卷軸，未全面重做頁內內容。61/61 全量後追加掛軸／短式微調，最終52專項＋五項相關回歸exit0；Web匯出／壓縮與三橫式實際滑鼠／金丹晉階重載通過。人工美術、實體觸控／高DPR待驗，不提升EARLY-FLOW1-D自然流程與C/D裝置缺口。下一New Chat收R2美術／裝置回饋，不開下一大型階段。
[驗收與命令](verification/uix-r2.md)

2026-10-10 **UIX-R2-DESIGN 已記錄（設計交付）**：使用者提供五張參考圖，指定玉質道印／主導覽與朱紅提示、卷軸詳細頁、青銅外框及少量雲紋；高解析／像素風共用設計語意。此前等待設計已解除，正式 UIX-R2 實作仍 TODO。範圍與驗收見 [UIX 設計](18-uix-components-and-hud-plan.md)。本輪僅文件，未改遊戲／匯出。

2026-10-10 最新使用者補充：**UIX-R2有指定設計，稍後提供**。R1有界收尾已完成；R2前置已滿足但等待設計稿，以下預設HUD分區只是暫擬，未核定、未開始R2實作。新對話接使用者設計再修訂範圍。

2026-10-10 **UIX-R1收尾DONE（有界），下一UIX-R2**：先讀[驗收](verification/uix-r1-finish.md)、[UIX範圍](18-uix-components-and-hud-plan.md)與updata頂部。R1正式ID／View、44px／裝飾輸入、主操作錨點／彈窗暫收、紙底對比、BGM跨境記錄與非掛起測試已修。60/60、74專項、最後六相關回歸及Web三橫式操作／真實突破晉階／重載通過，一般Web同步。48210已有金丹二層、48211已有築基進度；重開服務只Play勿seed，不碰4175。依Context Guard本輪不硬展開R2，下一New Chat正式HUD分區／短橫式可讀性；EARLY-FLOW1-D自然流程與裝置缺口不提升。

2026-10-10 **EARLY-FLOW1-D IN_PROGRESS（接入／CLI／桌面Web有界階段）**：F5技能／F6宗門可延後、F7金丹容量與主線、G1丹霞製作回運／G2祖島加工／G3實付首次晉階／G4靈狐首次餵食已接入。118專項、來源修正後59項分段回歸與Web匯出壓縮通過；三隔離origin驗入口、丹液到貨、實際晉階／餵食与重載。整段F7→G4自然時間、人類接受／實機仍待驗，不標DONE。[驗收](verification/early-flow1d.md)。下一New Chat續EARLY-FLOW1-D剩餘自然流程，不重做B／C、保存／FPS或暫緩冷啟動。

2026-10-10 **EARLY-FLOW1-C DONE（F1–F4 CLI／桌面Web／三橫式有界）**：啟用與雙島開拓→真實送料→兩島首批完工→兩種產物回祖島已接入。當世版本化供給紀錄支援部分小數到貨、材料已花掉、重載、拒寫重試／損壞復原與輪迴重置；舊檔不強迫補做。58/58 Runner、最後104專項、Web匯出／壓縮、正常命令築基fixture後真實滑鼠雙島約4分鐘與重載通過。人類接受／實機／高DPR及原UI1-C／C／D保留待驗，整體EARLY-FLOW1仍IN_PROGRESS。[驗收](verification/early-flow1c.md)。下一New Chat續EARLY-FLOW1-D（F5–G4），不重做C。

2026-10-10 **EARLY-FLOW1-B DONE（本段CLI／桌面Web／三橫式）**：核定Q1建築→Q2可選聚靈丹→Q3首次築基；目標／容量庫存澄清／可選入口／築基空島交接已接入。最終110專項、57/57 Runner、Web匯出／壓縮及正常新檔約13分鐘滑鼠築基／重載通過。人類節奏接受、實機／高DPR與原UI1-C／C／D保留待驗，整體EARLY-FLOW1仍IN_PROGRESS。[驗收](verification/early-flow1b.md)。下一New Chat續EARLY-FLOW1-C（F1–F4雙島供給），不重做B。

2026-10-10 **EARLY-FLOW1 IN_PROGRESS：現況稽核與流程提案已交付**。見[前期流程](17-early-progression-and-onboarding-plan.md)／[驗收](verification/early-flow1.md)：建築→可選煉丹→築基→雙島送料／加工／回運→可延後技能／宗門→金丹首升級→靈狐首次餵食為建議，具體次序尚未核定。實際門檻／完成／下一提示／卡關與保存設計邊界已整理；D2 215 checks、煉丹與靈獸回歸exit0，非自然時間或新教學Web驗收。未改遊戲規則／UI／schema／匯出，完整UI1-C／C／D待驗維持。下一New Chat核定順序後接EARLY-FLOW1-B練氣至首次築基。

2026-10-10 **EARLY-FLOW1 TODO（使用者核定優先方向）**：先整理練氣至金丹首段的開放順序與引導，沿玩家流程逐段調整系統。築基同時開宗門／技能／青木玄礦，但介紹次序與完成後引導尚未統一。已加入 [Roadmap](../ROADMAP.md) 的相依、交付與驗收；具體排序／新規則未核定，本輪未改程式。修改 ROADMAP.md、docs/development-status.md、docs/ai-handoff.md、updata.txt；以 PowerShell／apply_patch 編輯及回讀驗證，文件任務不跑遊戲測試。下一 New Chat 接 EARLY-FLOW1 現況與流程表，不開後段擴充，完整UI1-C／C／D待驗保持。
2026-10-09 **RES1-UI1-R6 DONE（有界空島圖形化）**：沿用製造／運輸手繪物品框，採集庫存／實際產率／容量條、地方原料產物、開拓與升階成本框／缺料恢復、固定切島／前往與短式下拉已接入。最終56/56（A217／B220）、三橫式Web／實際採集與倉儲升階／重載保留通過，一般Web同步。[驗收](verification/res1-ui1-r6.md)。人工美術／實機與完整UI1-C／C／D仍待驗；直式iframe提示偏小需後續核對。下一New Chat收空島回饋，不重做已過保存／FPS或暫緩冷啟動。
# 2026-10-09 RES1-UI1-C 最新接手

2026-10-09 **RES1-UI1-R5最新接手**：先讀[運輸圖形化驗收](verification/res1-ui1-r5.md)與updata。使用者要求製造圖形／簡化同步運輸；七航線現有手繪物品格與來源→目的庫存、缺貨紅框、真實載貨／倒數／進度、雙欄／短橫式並排與固定標題收據已接入。56/56（B210），最終B220／parity／responsive與Web三橫式／丹液補料回運／設定重載通過，一般build/web已同步。4300服務停止、驗收分頁關閉／override reset；origin有三條停航與丹液1，重開只Play勿seed。實機／高DPR／最終美術及完整C/D仍待驗，未更新Windows／commit／push。下一New Chat收運輸回饋或剩餘裝置，不重做既有FPS／400保存與暫緩冷啟動。

2026-10-09 **RES1-UI1-R4最新接手**：先讀[驗收](verification/res1-ui1-r4.md)與updata頂部。使用者示意要求更清楚物品框，recipe_material_tile改2px框／淡底／微陰影，灰青材料／青玉產出／朱紅缺料，取代R3無框樣式；ICON原圖不變。207／parity／responsive、三尺寸原生12圖及Web三橫式／製作築基丹1通過；build/web已同步。4299隔離服務停止／成功分頁關閉／override reset，origin已有丹1，重開按Play勿seed。未更新Windows／commit／push，完整UI1-C／C/D與實機仍待驗。下一New Chat收此版框線／底色回饋，不重做已過效能／保存、不開Era4。

2026-10-09 **RES1-UI1-R3最新接手**：先讀[驗收](verification/res1-ui1-r3.md)／updata頂部。資源ICON已從平塗向量換成ImageGen手繪透明PNG（assets/ui/resources-painted），完整prompt／source／QC／切層在manifest；材料格常態框與底色撤下，紅數字／6%淡紅缺料保留。207／parity／responsive、原生三尺寸12圖及Web三尺寸／實際製造通過，build/web已更新。4298隔離origin已有築基丹1，服務／本輪分頁已停止／關閉、override復原；重開按Play勿seed。未更新Windows／commit／push。最終質感／辨識與實機待驗，下一New Chat收回饋，保持完整C/D未放行限制。

2026-10-09 **RES1-UI1-R2最新接手**：先讀[驗收](verification/res1-ui1-r2.md)與updata頂部。使用者接受R1分類，改要求製造更圖形化；八配方ICON＋需求量→產物、不足紅色／補料復原、tooltip及詳情、短橫式材料／操作並排已完成。56/56當輪A205，最後207／B140／world59／parity／responsive與Web三橫式／reload／旋轉通過；一般build/web已更新。4297服務與本輪分頁已停止／關閉，override復原；隔離進度已有築基丹1，重開按Play勿seed。最終圖示美術／觸控高DPR待驗，完整UI1-C/D狀態不提升。下一New Chat收圖形介面回饋，效能與保存已驗部分不重做。

2026-10-09 **RES1-UI1-R1最新接手**：先讀[本輪驗收](verification/res1-ui1-r1.md)與updata頂部。空島選中／成功收據／工程可用庫存／可展開本地原料產物，以及製造卡片內進度／來源庫存／單行總覽／固定篩選與寬式同屏資源已交付。56/56、最終164及運輸140／world59／parity／responsive、三橫式CSS滑鼠／重載／旋轉PASS，正常build/web已更新。完整UI1-C裝置／人工仍待驗；遵守最新AGY效能政策，冷啟動暫緩常態阻擋，不重做保存400矩陣。4296隔離試玩origin已有進度，沿用原檔；本輪停止服務並關閉分頁後可用驗收頁命令重開，按開啟隔離遊戲，不再seed。未commit／push、未改規則／schema／Windows包／4175玩家存檔。下一New Chat接使用者操作密度／回饋接受或剩餘裝置，不開Era4。

**IN_PROGRESS**：56/56回歸、九案例16份400 checks與新製造／運輸Web拒寫重試／重載／雙分頁保存PASS；三橫式／旋轉／世界滑鼠已有本輪證據。依 2026-10-09 使用者指令，效能門檻調整：
1. 末 10 秒幀率恢復只要高於 30 FPS 即可通過，300 秒/50 次切頁末 5 秒為 53.9957 FPS，重算後 `desktopRecoveryGate=PASS`。
2. 20Mbps 慢網冷啟動（14.80 秒）暫緩常態要求，待專案後期大型里程碑時再回報與集中優化（資產剪裁/本地儲存 Patch）。AI 與 CODEX 不得在此反覆糾結阻塞。
目前實體裝置觸控與人工驗收仍待驗。先讀[本輪驗收](verification/res1-ui1-c.md)及updata頂部。不重做已過保存矩陣，不跳Era4。

4293／4294／4295本輪服務已停止，全部本輪browser分頁關閉、override reset，origin資料保留。4294已有Era3測試進度，重開按開啟遊戲、勿再seed；4175玩家資料未觸碰。4293首次空白矩陣已結束，重新跑空白要新origin與新evidence並調整audit的精確來源；禁止刪玩家資料。重跑命令／版本hash、JPEG證據与待驗清單見驗收。本輪僅工具與紀錄變更，正式Godot來源／規則／schema未改；效能定位與美術壓縮尚未開始。

# 2026-10-05 R2最新接手提示

2026-10-05最新 **RES1-C2-PERF-R2 效能修復 PASS（AGY）**：持續 FPS 劣化根因已定位並修復（`building_catalog.gd` 每0.25秒無條件覆寫 ProgressBar 位置／尺寸的 reflow 風暴改為值比對保護、`abode_building.gd` 不可見物件 `_process` 提早返回、`abode_flows.gd` Immediate Draw 呼叫減量）；全量54/54 Runner／exit0，ADR-010 四組觀測全部恢復PASS、`desktopRecoveryGate=PASS`。[R2驗收](verification/res1-c2-agy-r2.md)。**R2 效能定位結案**；C／C2（實機觸控／高DPR／自然凍結／跨瀏覽器／長期GPU-WASM 與人工美術節奏）與完整 D 仍 IN_PROGRESS。下方 2026-10-04 NOT_PASSED／未重現紀錄為歷史。

2026-10-05 **SKILL-B1 已採用 B**：先讀 [ADR-012](decisions/ADR-012-optional-skills-with-islands.md) 與 [驗證](verification/skills-b1.md)。六技能選修，不回復舊Era2經濟或技能門檻；main為唯一正式開發入口，git pull --ff-only origin main，分歧先回報。舊保存分支保留。

2026-10-05 **Git接手入口**：正式進度只從E:/WORK/Dao2的main接續；舊7c23/Dao2工作樹已保存於codex/preserve-vfx-20261005並真正合併，原工作樹留備份分支勿當最新版。master ff86f85另保留於codex/preserve-master-20261005，一般技能／舊Era2模型與ADR-011衝突、未合併。後續明確使用git pull --ff-only origin main；兩側提交分歧或dirty阻擋須回報，不自動reset/rebase/force push。[整合驗證](verification/git-progress-integration-2026-10-05.md)。


2026-10-05追加 **D2-R1 Web 保存子階段 PASS；完整D2-R1／D2／D與C／C2／R2仍IN_PROGRESS**。先讀[Web驗收](verification/res1-d2-web-r1.md)與updata頂部。最終53/53／exit0、world38／管理89；九案例16報告400 checks，空白流程是自動正常命令／模擬秒（含215共用診斷），不是完整滑鼠通關。D2真實保存矩陣176項通過；正常開局滑鼠及丹霞拒寫／重試追加，保存恢復提示修復。4258新檔、4259金丹試玩存檔保留，頁面停launcher／override reset；4259按開啟隔離遊戲，勿再Seed。新正常包build/res1d2-web-live，測試包build/res1d2-web，原web／res1d2／res1d2r1不變。下一New Chat續自然時間完整滑鼠流程、人工／裝置／C-R2；R2交AGY，不重做已過保存矩陣或跳Era4。下方日期化歷史保留。

2026-10-05最新 **D2-R1世界／美術子階段交付，完整D2-R1／D2／D IN_PROGRESS**：丹霞兩張獨立PNG與雙向世界／管理入口、貨運視覺、控制列換行及遠景題字避讓已接。53/53／exit0；最後world38＋管理87、原三島26／響應式回歸、獨立Web與1280×720.4／844×390滑鼠重載證據見[驗收](verification/res1-d2-r1.md)。下一New Chat續正常Web空白完整首段與D2瀏覽器保存故障矩陣；人工／裝置／C-R2仍待驗，R2交AGY。先讀updata頂部，4257/launcher沿用進度，勿再種檔；build/res1d2r1獨立，原web／res1d2包不變。

2026-10-05最新 **RES1-D2 IN_PROGRESS（容量／技能方案與正常規則／管理接線已交付）**：使用者核定Era＋設施門檻及新增築基靈池；正常空白T1→金丹Lv10、丹霞丹液回運／T3／扣料與保存故障215 checks、52/52 Runner／exit0，最後呈現87 checks回歸／獨立Web匯出及1280×720.4／844×390滑鼠與重載通過。[D2驗收](verification/res1-d2.md)／[ADR-011](decisions/ADR-011-era3-capacity-and-skill-gates.md)。丹霞專用世界美術、完整Web新檔首段、人工玩法／裝置與C/R2門檻仍待驗，**D2／完整D IN_PROGRESS**；R2仍交AGY。下一New Chat續D2-R1，本輪不開下一大型階段；以下按日期保留歷史。


2026-10-05最新：**D1 DONE（稽核＋隔離216 checks）**，讀[res1-d1](verification/res1-d1.md)及updata頂部；8來源hash一致，空白開局到Era3 Lv10。正常靈力容量1100不達突破2000；容量250／無一般技能／丹液陣芯晉階成本是明示fixture提案，正式檔未改。獨立命令`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\res1d1_audit.ps1`及Godot `--headless --path . --script res://tests/res1d1_contract_runner.gd`；完整D／正式保存／世界仍待整合。R2仍AGY負責，C／C2／R2 IN_PROGRESS；下一D2先定容量與技能方案、共享核心單方修改，New Chat接續。下方TODO分工為此前歷史。

**同日最新使用者分工覆蓋下方接手順序：R2交AGY，Codex下一RES1-D1隔離子階段（TODO），可並行。**先讀[AGY交接](handoffs/2026-10-05-r2-agy.md)、[AGY Prompt](handoffs/2026-10-05-agy-r2-prompt.md)、[D1範圍與Codex Prompt](handoffs/2026-10-05-codex-res1-d1.md)。R2／C／C2仍IN_PROGRESS、完整D TODO，不以並行消除效能／保存／裝置放行門檻。本輪只建文件，未開始D1或對外傳送prompt。共享檔與build先協調；AGY量FPS時Codex暂停高負載測試／匯出。

先讀[持續劣化定位](verification/res1-c2-sustained-degradation.md)與updata頂部。本輪正常頂層1280×720／DPR約1三組300秒（含50次有間隔管理開關）與重載60秒59.744／59.564／59.744／59.847均恢復PASS；CPU237／GPU150同期資料、6／16／13契約PASS。沒有Godot來源／匯出／51 Runner變更。共用GPU process高CPU時仍近60、heap大小與FPS非單一對應；不是根因修復。前輪DPR1.25與木屋3階、此輪DPR1／木屋2階不同，原失敗未消除。R2／C／C2 IN_PROGRESS、D TODO。4248服務沿用，分頁停launcher／override reset，已有進度按開啟遊戲，勿種檔。後續由AGY完成根因修復並PASS（見頂部2026-10-05 RES1-C2-PERF-R2）。

# 給下一位 AI 的開發交接

2026-10-04最新 **R2正常恢復／長觀測驗收 NOT_PASSED**：正常60秒59.880、首組300秒59.823通過；有間隔50次管理操作的300秒54.740（末45秒低谷）、同頁延長300秒48.088、重載60秒35.105均未恢復。無遊戲對照59.997只作診斷，不替代遊戲通過；木屋2→3／扣料重載、三島滑鼠與完整模式正常。Python16／Node13契約通過，無新Godot來源／匯出／51 Runner。**R2／C／C2 IN_PROGRESS、D TODO**；下一定位持續劣化，裝置／人工另待驗。[本輪驗收](verification/res1-c2-recovery-browser.md)。較早政策修訂與通過結果保留歷史，New Chat續同R2。
4248服務保留（session6020），正常隔離origin；分頁停launcher釋放writer鎖，已有進度按開啟隔離遊戲，勿重種。先讀updata頂部／本輪驗收，失敗raw保留，下一針對持續低FPS取證，不為單一59.x或可恢復尖峰優化。


2026-10-04最新使用者要求：[ADR-010放置FPS恢復標準](decisions/ADR-010-idle-frame-recovery-budget.md)，優先於下方全部歷史「嚴格60未過」。常態目標60、偶發30後回升可接受；55／5秒窗／80%及末10秒恢復是工程定義，低谷10秒警示不直接阻擋。工具desktopRecoveryGate取代strictDesktopGate，正常`/metrics.html?sampleSeconds=60`／300做恢復／長期觀測，profile仍排除。16 summary＋13 observer契約通過，舊三組15秒短窗口符合但INSUFFICIENT_EVIDENCE，沒有新瀏覽器／全量Godot／匯出。R2仍IN_PROGRESS，下一按恢復與持續劣化驗收，不再為平均59.x或可恢復33ms無限優化；手機等獨立待驗、不自動進D。launcher的sampleSeconds轉交要重啟服務，直接metrics頁動態讀新JS。[本輪驗收](verification/res1-c2-idle-fps-policy.md)，New Chat續同R2。

2026-10-04最新R2：[長幀入口追蹤](verification/res1-c2-main-loop-tracing.md)與updata頂部。preflight＋LoAF診斷交付；83.3ms rAF對應MainLoop_runner84.1ms，同窗process0.4／preflight0.1／HUD保存0，沒有WASM內call stack，不指定GC或GPU根因。51/51／world26、正常與profile export／compression、JS／Python契約通過；正常頂層1280×720三組pooled57.887FPS／p95 16.9ms，嚴格60未過，非配對改善。4247服務（session96276）保留：bundled Python `tools/island_preview_server.py --port 4247 --profile-build --gzip --review-fixture --metrics-log res1-c2-task-profile-metrics.jsonl`，正常 `/launcher?metrics=1`／頂層診斷 `/profile.html?profileSeconds=60`；兩build PCK相同，normal無CPU橋接。已有隔離資料按開啟遊戲，拒覆寫；override已reset，分頁停launcher。下一仍R2引擎迴圈內／其他節點／繪圖與33ms掉幀追蹤、嚴格FPS／裝置與人工，**R2/C/C2 IN_PROGRESS、D TODO**，New Chat；以下是歷史。

2026-10-04最新R2子階段：讀[View／encode與長幀](verification/res1-c2-view-encode-longframes.md)與updata頂部。固定快照encode17.368→14.9985ms；定時View少重建、明確刷新保留。51/51／resource754／world26／Web retry49通過；非profile59.619FPS／p95 16.8ms／max183.3，嚴格60未過。另60秒profile捕捉166.8ms rAF與180ms LongTask，同窗已量process0.3ms，沒有call stack、不能歸因GC／GPU。4244正常隔離試玩保留，已有進度按開啟隔離遊戲；profile選項`/launcher?profile=1&profileSeconds=60`只作診斷，保持raw報告收起。**R2/C/C2 IN_PROGRESS、D TODO**；New Chat續同R2未覆蓋task／引擎／節點耗時與裝置／人工缺口，以下同日紀錄保留歷史。

2026-10-04最新HUD子階段：讀[驗收](verification/res1-c2-hud-optimization.md)及updata頂部。feature_navigation.layout(vp,view)沿用當輪View，無參數resize走既有身分/revision保護；catalog.refresh新增預設false的defer_resource_refresh，HUD等shared合併後一次更新，資源/材質以副本與Era/模式/名稱/紙底失效。最終51/51、資源顯示752、world26通過；正常Web已重新匯出並準備音樂／壓縮，PCK35539625…，br14,451,078 bytes。profile三組HUD5.58–5.82ms；非profile三組pooled59.508FPS／p95 16.8ms，max183.4ms，嚴格60未過。遊戲sample1280×721／DPR約1（iframe DOM1280×720），時間狀態不同，不能泛稱精確配對。4243正常隔離試玩保留，已有資料按開啟遊戲，勿種檔覆寫；4242已停。下一同R2剩餘View／保存編碼與長幀，保留故障契約與門檻，R2/C/C2 IN_PROGRESS、D TODO，用New Chat。以下同日定位紀錄為歷史。

2026-10-04最新R2耗時定位：讀[profile證據](verification/res1-c2-perf-r2-profile.md)及updata頂部。三組HUD12.7–12.8ms（navigation5.0–5.1／catalog3.7–3.9），保存18.1–22.7ms，encode13.8–18.5、commit4.1–4.2；tick1.2–1.3。新增RuntimeProfile預設關閉，僅`/launcher?profile=1`啟用；`--profile-build`服務獨立build/web-profile。基礎版51/51、最後world26，未做效能改善／完整Web故障重跑／200ms重現，profile不可判FPS通過。下一同R2改善FeatureNavigation重複get_view及BuildingCatalog重複資源／樣式更新，配對非profile驗收；R2/C/C2 IN_PROGRESS，D TODO。正常build/web未重匯出。請New Chat接後續。

2026-10-04最新R2 FPS子階段：先讀[桌面複測](verification/res1-c2-perf-r2-fps.md)及updata頂部。v3量測／重算工具13契約PASS；同iframe1280×650／DPR1.25三遊戲pooled59.019FPS、p95均16.8／max200ms，三無遊戲對照59.997。嚴格60未過；下一同R2實測每秒Session／View、0.25秒HUD、15秒同步保存各段成本後改善，未定位不能改保存／收益，不跳D。新4238正常版隔離試玩保留，4236本輪未驗；本輪未改Godot來源／export／跑51 Runner，下面為前輪證據。以New Chat接profile階段。

2026-10-04 PERF-R2 續輪（最新）：20Mbps／100ms長離線 ready **9.801／9.777秒**，兩個新origin通過10秒；原生48h CPU **2.662→0.886秒**、完整終態hash不變。最終51/51、145精確檢查、async27、world26、Web C2 retry49通過。桌面 **59.930FPS／p95 16.8ms**，嚴格60仍未過；人工／手機／高DPR等仍待驗，R2／C／C2維持IN_PROGRESS，不跳D。 使用最新 `FrameBudget` 14ms；保留正常版隔離試玩 [4236](http://127.0.0.1:4236/launcher?metrics=1)，已有隔離進度拒覆寫。先讀 [R2續輪](verification/res1-c2-perf-r2.md#2026-10-04-續輪交付節流長離線缺口)與updata頂部；以下更新行為較早歷史。

更新：2026-10-04（PERF-R2續輪：節流長離線9.801／9.777秒有界通過；最終51/51＋145精確；嚴格60FPS／裝置與人工仍待驗）。較早結果保留歷史。

## 閱讀與恢復工作

1. 根目錄 `AGENTS.md`：開發約束。
2. `ROADMAP.md`：產品目的、任務 ID、相依與完成定義。
3. `docs/development-status.md`：實際進度與證據，找到當前未完成工作。
4. 按任務讀 docs/02 技術架構、docs/00 舊規則來源；美術任務讀 docs/04、06。
5. 涉及世界場景、HUD、輸入、畫面尺寸、Web shell 或 Web 匯出時，閱讀 `docs/07-responsive-ui-web-spec.md`；它規定 `1280×720` 構圖基準、Godot 響應式版型與瀏覽器證據，不可用固定畫布取代適配。
6. 涉及新建築、修行境界（Era）擴充、島面與可布置空間時，閱讀 `docs/08-building-presentation-and-era-expansion.md`；多數建築進營造清單，只有有圖形化地基與獨立美術的少數地標可進世界場景。
7. 涉及功能入口、群組分頁、資源或升級清單整合，必讀 `docs/12-feature-navigation-and-integration-spec.md`；新系統不得塞進 More 或新增重複入口。

如果工具不自動讀 AGENTS.md，請在首個提示明確要求閱讀。歷史文件 docs/03 保留初期推理與案例，開發順序以根目錄 Roadmap 為準。不要因舊文有「下一步建立環境」而重裝。

依修改類型查 [呈現層索引](abode-presentation-map.md)。歷史長記錄已歸檔，不作每次必讀；目前缺口與驗證以 [開發狀態](development-status.md) 為準。

## 最新接手狀態

- **2026-10-04 PERF-R2續輪最新**：長離線節流兩新origin9.801／9.777秒，最終51/51＋145精確、world26、Web C2 retry49。FrameBudget14ms；桌面59.930FPS／p95 16.8ms、嚴格60仍未過。固定點快取不跨命令，祖島Amount／乘區變化立即失效；全部計數仍逐秒。4236正常版隔離試玩保留。先讀R2末節與updata頂部；下一同R2嚴格FPS／人工與装置，D TODO。下列10ms／121項紀錄為同日較早階段。

- **2026-10-04 PERF-R2 最新**：讀 [R2驗收](verification/res1-c2-perf-r2.md)／updata頂部。最終51/51、121精確tick/font（含零tick／已壽盡不得初始化靈獸）、Web retry49通過。本機48h ready18.03→7.75秒，結算rAF p95 16.8／max17ms；20Mbps／100ms新檔8.45秒、長離線13.55秒仍超10秒；桌面59.80FPS／p95 16.8ms，嚴格60仍未過。準備只限無命令結算；BUFF到期、時辰切換與當秒庫存／預留仍保持原順序，FrameBudget10ms只決定讓出。三preset最終匯出並準備companions，正常PCK hash `dac46aa8a5e2f2240e6faaf065e002f794d70c30bb7d710950caec7e91018789`、核心br14,445,165 bytes。保留正常版隔離試玩4230服務：`python tools/island_preview_server.py --port 4230 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-r2-final-active-metrics.jsonl`；已有進度拒覆寫。下一仍PERF-R2節流長離線／嚴格FPS、指定裝置與人工，不跳D，不重做已過A/B／保存矩陣。用New Chat接大型後續工作。

- **2026-10-04 RES1-C2-PERF最新**：讀[效能驗收](verification/res1-c2-perf.md)與updata。核心br14.44MB／含四原MP3共19.79MB，新檔20Mbps／100ms8.49秒，p95 16.8ms；平均59.45–59.85未嚴格60、48h恢復本機18.19秒仍待改善。51/51、107精確tick/font、world26、真實Web retry49／音樂503後選單重試／兩橫式／50次Web切島通過。三preset匯出後**必須準備音樂companions**：`node tools/prepare_web_compression.mjs build/web`（其餘preset換目錄），再`python tools/web_static_server.py --port 4175 --directory build/web`；一般`start_web_server.ps1`會自動準備，無Node仍copy原MP3與gzip。只Godot export不會建立audio/bgm companions。Runtime字型用bundled Python＋build/tool-deps/fonttools4.61.1執行`tools/subset_game_fonts.py --check`，新增文字缺字時再生成，不改原TTF。預覽4221服務保留：`python tools/island_preview_server.py --port 4221 --normal-build --gzip --review-fixture --metrics-log res1-c2-perf-responsive-metrics.jsonl`；已有資料拒覆寫，844×390測試按鈕是可驗證iframe，不是實體手機。原4175／4207未中斷。下一PERF-R2／裝置與人工放行，New Chat，不跳D；舊紀錄保留歷史，勿重做A/B或已通過矩陣。

- **2026-10-04 RES1-C3 本輪最新**：正常版已附掛processing／空島入口，築基後玩家保留原檔啟用；前輪「正式未附掛／只有preview」由當次要求覆蓋。四張PNG＋兩參考＋提示詞／manifest，最終50/50、正常world22與兩版型Web開拓／重開／精煉通過；world退出清理警告有記錄。读[C3](verification/res1-c3-art-integration.md)、[30+容量與考據](15-island-expansion-and-art-direction.md)與updata。實際仍首批三島，後續未實作。正常4175已更新；`python tools/island_preview_server.py --port 4207 --normal-build --review-fixture`保留試玩，獨立origin正常namespace，已有檔拒覆寫。C/C3人工美術／節奏與C2效能／裝置待驗；下一C2-PERF＋人工，New Chat接大型工作，不重做已通過矩陣／A/B，不跳D。下方C2-R1等按歷史保留。

- **2026-10-04 最新RES1-C2-R1**：讀 [收尾驗收](verification/res1-c2-closure.md)／updata。桌面async追加矩陣146 checks、最後retry49回歸、全量50/50及world15 checks PASS；原生50switch memory穩定僅有界證據。20Mbps／100ms未壓縮含48h恢復ready67.84s、獨立桌面48.60FPS／p95 33.4ms、gzip估算44.72MB，未達預算；使用者美術／節奏明確待驗。正式manifest仍未附掛，下一 **C2-PERF**，不重做已通過保存矩陣／A/B、不跳D。`WebPersistenceTest` export → `python tools/web_persistence_server.py --port 4202` → `?case=c2retry/c2quota/c2indexreload/c2quotareload/c2lock/c2denied/c2corrupt`；reload兩案要真的重整兩次，lock要兩個分頁且關閉owner後reload。review工具只重封UTC不改command-earned state：`--script res://tools/res1c2_review_fixture.gd`，server `--port 4205 --review-fixture`，已有資料拒覆寫；不要用48hfixture當可長期試玩檔。metrics來源工具 `--throttle-mbps 20 --latency-ms 100`／`/launcher?metrics=1`，禁止手改build。大型下一步用New Chat。

- **2026-10-04 RES1-C2 IN_PROGRESS，程式／桌面候選已交付**：先讀 [C2驗收](verification/res1-c2.md)／development-status／updata頂部。27 checks、checksum修正後固定50/50及世界14 checks、Web雙鏈／T2升級與重載、48h分批拒寫／恢復／重試／再重載已驗。新增SVG候選未美術放行，正式catalog仍未附掛。FrameBudget在platform，coordinator不直接讀Time；舊有效checksum驗證保持，Encode修正實際JSON表示往返。`run_all_runners.ps1`含新offline runner並產生48hfixture；另跑world runner。preview server支援`--port 4198`、`--port 4201 --offline-fixture`；`/launcher?fault=write`使用既有namespace受限故障條，`/fault.html`是工具頁，不改build。已有隔離進度拒覆寫。下一C2美術／裝置與新async完整故障追加矩陣／效能收尾，不跳D；用New Chat。

- **2026-10-03 RES1-C IN_PROGRESS，C1階段已交付，下一 C2**：先讀 [C1驗收](verification/res1-c1.md)／development-status及updata頂部。三島設施／T2消耗、遷移備份／重試與Godot操作頁已有87 checks、最終49/49 Runner、IAB1280×720／844×390滑鼠證據。正式manifest沒有附掛；只有IslandProgressionTest feature使用`dao2_islands_preview`，native override僅測試用。以C Runner生成earned-era2 fixture→export IslandProgressionTest→`python tools/island_preview_server.py`→4197/launcher；已有隔離進度按開啟遊戲，拒絕覆寫。下一C2補專用三島世界／Banner／世界命中與長離線分批讓出主執行緒、完整Web雙鏈／T2升級／重載離線矩陣，通過才做正式內容啟用。不要重做A/B或誤認C已DONE／跳D。依Context Guard用New Chat接續。

- **2026-10-03 RES1-B-WEB-R1 DONE，下一 RES1-C**：251 checks／native三程序與桌面Web保存故障矩陣已交付、最終固定入口47/47 PASS、exit0。讀 [驗收](verification/res1-b-web-r1.md)／development-status及updata頂部。localStorage＋lifetime Web Lock，拒絕讀寫／quota／損壞／索引中斷／重載與重試、受控Web幀恢復已驗；正式manifest保持opt-in。自然分頁／OS背景凍結、裝置與長離線CPU另待驗。本節後續A／B待做順序是本日較早歷史，不重做已交付核心。下個大型任務用New Chat。

- **2026-10-03 RES1-A 已完成首批契約／隔離核心，下一 RES1-B**：讀 [驗收](verification/res1-a.md) 與 updata 頂部。15 資源／8 配方、145 checks、新舊差異與唯讀 DAO1 8/8 參照、全量 42 Runner PASS。正式 ContentLoader 不附掛 processing_catalog，Craft 為 opt-in；正式 manifest／schema／rules 未變，新經濟不可先接玩家保存。B 將 A 的即時命令契約接批次時間、地方庫存、固定航線、容量保留、版本遷移與離線／輪迴／故障重試，補相交 M1-C/D 後開啟；百年草取得、Era3 技能／材料消耗與 UI 在 C/D。以下 A TODO 為較早歷史方向。

- **2026-10-03 RES1 最新指示優先於本節後續歷史次序**：使用者重申 Era 解鎖資源島、多階加工／融合與實際供給運輸。RES1-DESIGN 文件與靜態來源稽核 DONE，runtime 尚未改；先讀 [docs/14](14-multi-island-resource-progression.md)、[ADR-009](decisions/ADR-009-multi-island-resource-economy.md)、[稽核](verification/resource-progression-audit.md)。DAO1 61 資源／30 配方，DAO2 manifest 7／10 建築／Era 1–2，完整承接缺口從 Era 2–3 起。**下一 RES1-A（資源／配方／需求契約與 Craft 核心），再 B 加工／庫存／物流／保存、C 三島、D Era 3／三級材料**；M1-C/D 相交持久化／離線驗收仍是正式放行條件。已建立英文 checkpoint，使用 New Chat 開始實作，不把設計表當已上線玩法。

- 2026-10-03 M4-A-R1 DONE：251 checks／40 Runner、兩版型 IAB 真實滑鼠及重整恢復通過；rules_version=core-flow-5-session-receipts，schema 2 選填最近 256 筆成功命令收據。最後舊任務 alias 修正另重跑四項相關 Runner，全部 exit 0。Web adapter 實際是 localStorage；下一步 M1-C/D 權威儲存與離線故障矩陣，實機／高 DPR 獨立待驗。看 verification/m4-a-r1.md 及 updata.txt 頂部；使用 New Chat，不重做白名單。本節以下為本日較早接手紀錄，已由此項取代後續順序。

- 2026-10-03 最新：成就已交付，固定入口 39 Runner，UI8 R1 全量 39/39 PASS；建造訊息修復另有兩項 Runner／Web 證據且使用者測試 OK。下一步 M4-A-R1 補正式 Session 成功／拒絕／冪等／保存與 Web 矩陣，不能重做已存在白名單。再補 M1-C/D 瀏覽器持久化與離線證據；實機／高 DPR 仍待驗。下列按日期的 38 Runner 為歷史結果。
- FX3 飛劍／靈氣／雷電／法陣的原生粒子、Shader、世界 Glow 與局部題字泛光已接。設定「引擎特效樣板（試播）」可以零收益查看；驗收與庫授權見 verification/native-vfx.md。聚靈壇／靈界據點專屬美術仍未放行，不把光環當作建築完成品。

- NAV1 四主入口與九分頁已實作；靈獸核心及正式操作頁已接，下一步收分類／視覺回饋與實機驗收，見 verification/feature-navigation.md。

- Session 已放行宗門／跨界／BUFF，不能照 9/28 提示重做白名單；全部新命令端到端／Web 證據仍按 R1 補齊。
- M4-B、M5-A／B 已有核心／資料實作；完整可玩／美術／試玩／長期負載尚未全驗。最新 UI7 已實作，優先收 UI／字型／演出回饋與裝置驗收。
- 倉庫 origin 為 https://github.com/KainHuang777/Dao2.git，main 追蹤 origin/main；引擎／模板、.godot、build 被忽略。乾淨 clone 不含本機引擎，需同版 4.7.2 執行檔及模板，不自動更新環境。
- 執行政策 Bypass 僅作用於該測試子程序。若沙箱阻擋隔離 user:// fixture，記錄失敗並使用正常授權重跑；不要改玩家存檔。

## 實際路徑與現有檔案

| 路徑 | 已有用途 |
| --- | --- |
| `project.godot`、`export_presets.cfg` | 已鎖定環境；主場景 living_abode；Web 單執行緒 |
| `scenes/living_abode.tscn` | Node2D 啟動場景，運行時建構地形、建築、鏡頭和 HUD |
| `src/abode/living_abode.gd` | 世界與正式 Session／保存協調、公共相容入口 |
| `src/presentation/abode_hud_controller.gd` | HUD 組裝／版型／數值與引導更新 |
| `src/presentation/abode_modal_manager.gd` | 次級彈窗掛載／位置／事件分發 |
| `src/abode/abode_state.gd` | 純展示經濟，尚用 float、無持久化、無正式離線 |
| `src/abode/abode_camera.gd` | 平移、滑鼠／觸控縮放、HUD 排除、遠近景；待完整手勢驗收 |
| `src/abode/abode_building.gd` | 獨立 sprite、命中區、標籤、選取及升級特效 |
| `src/abode/abode_flows.gd` | 飛劍與靈氣的程式動畫；不發放資源 |
| `assets/abode/` | terrain、sky、hut、garden、altar、sword 分層圖片 |
| `assets/fonts/`、`src/presentation/ui_typography.gd` | 思源黑體 TW VF 400／600 資訊字與粗明體 800 題字；保留字型授權 |
| `docs/abode-art/` | 生成提示詞、原始與處理紀錄，非正式遊戲模組 |
| `scenes/web_probe.tscn`、`src/presentation/web_probe.gd` | 舊計數探針；`user://web_probe_state.json`；與洞府不同存檔契約 |
| `tools/test_runner.gd` | 基本 JSON／user 儲存與字型探針 |
| `tests/abode_state_runner.gd` | 展示產率、升級、藥圃停止測試 |
| `tests/living_abode_runner.gd` | 直接呼叫場景選取／升級／停產／鏡頭函式，非真實輸入 E2E |
| `docs/visual-prototype/` | 早期 HTML 視覺提案，不能作為正式遊戲核心 |
| `src/效果圖/` | 現有參考圖，勿任意刪除；export_presets.cfg 已排除 release 打包 |
| `build/`、`.godot/` | 匯出與快取，可重建；修改來源後重新生成 |

舊來源 `E:\Python\test1`、塔防參考 `E:\WORK\GodTower` 僅供讀取。其他機器沒有這些路徑時，可先做不依賴來源的驗收；公式 fixture 任務應報缺來源，不從記憶或圖片猜公式。

## 可重跑命令（目前已存在的入口）

以下在 Windows PowerShell 執行。每一步確認退出碼；2026-10-03 ISLAND1 重跑固定入口 38/38 PASS，清單以 tools/run_all_runners.ps1 為準。追加呈現層回歸不在固定入口；歷史結果見各驗收頁，本輪未重跑。非 Windows 接手者需提供同版本當地 Godot 執行檔與模板，保留來源專案設定。

```powershell
Set-Location 'E:\WORK\Dao2'
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
if ($LASTEXITCODE -ne 0) { throw 'Godot version check failed' }
& $daoEngine --headless --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
if ($LASTEXITCODE -ne 0) { throw 'A runner failed' }
& $daoEngine --headless --path . --script res://tests/abode_presentation_parity_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Presentation facade regression failed' }
New-Item -ItemType Directory -Path '.\build\web' -Force | Out-Null
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
```

另外開一個終端啟動本機 HTTP（若已有相同服務，先確認不用重開）：

```powershell
Set-Location 'E:\WORK\Dao2'
python -m http.server 4175 --bind 127.0.0.1 --directory '.\build\web'
```

開啟 `http://127.0.0.1:4175/index.html`；不要直接雙擊本機 HTML。此服務只提供 build/web，不公開整個專案。停止該終端中的服務用 Ctrl+C，不終止不相關程序。若換 port，origin 與瀏覽器存檔也不同；存檔回歸必須保持固定 origin。

現有 Godot 採 `_sc_` 自我包含模式，模板在引擎旁 `editor_data/export_templates/4.7.2.stable/`；引擎與模板被 .gitignore 排除。若工具沙箱阻止引擎寫入，使用該工具的正常授權流程，不繞過限制。

周天探針不再是主場景；M0-A 需提供獨立 export/config 的可重跑方式，不直接改 release main_scene 又忘記還原。`tools/` 被 release 排除，CLI runner 可從源專案執行；不要把 runner 的存在當作 release 可載入保證。

## 瀏覽器驗收的正確做法

- 先等實際場景可互動；loader 截圖與 console 的 ABODE_READY 都不足以證明畫面品質。
- 從當次截圖／viewport 確認座標，記錄 CSS 尺寸和 DPR；不要複用上一回的固定座標。Godot 畫布內部文字通常不在 DOM，不能把 AX 的 canvas fallback 文字視為畫面錯誤。
- 真實點建築／按鈕並核對文字與狀態；拖曳檢查位置、縮放檢查比例及命中；UI 上拖放後再點世界，確認不黏住拖曳。
- 測試暫停藥圃前後一段固定時間的靈草增量，恢復後繼續；鏡頭切換與低特效不能改產率。展示版允許重載重置，正式存檔接入後更新此預期。
- 周天持久化記錄初值、點後值、重載值；不能以檔案存在、函式返回或 headless JSON 往返代替瀏覽器持久化。
- 缺瀏覽器自動化能力就提供人工步驟並標待驗證，不擅自宣稱全通過。手機模擬 viewport 不等於實體手機 GPU、觸控或效能驗證。

## 任務與驗收紀錄模板

每項工作在既有 `docs/verification/<task-id>.md` 建立或追加紀錄：

```text
任務 ID／日期／狀態：
目標與非目標：
已滿足相依：
來源 hash 或規則版本：
修改檔案：
驗收環境（引擎、OS、瀏覽器、裝置、CSS尺寸/DPR）：
命令／退出碼／結果（實測或未執行）：
瀏覽器操作、預期、觀察、截圖路徑：
資料安全／存檔相容影響：
未通過項、阻塞原因、下一步：
```

調整已決定的架構或規則時，在 `docs/decisions/ADR-xxx.md` 記錄理由、替代方案、影響及驗證，並更新 Roadmap。ADR-001–007 已存在 docs/03，不重用編號。

## 上下文管理與主動剎車協定（Context Guard & Checkpoint）

1. **防禦 Context Drift**：長 Session 會累積過多終端輸出與代碼檢視，導致模型注意力分散、代碼品質下降與幻覺。
2. **主動剎車標準**：
   - 當前任務（Task/Bugfix）已完成且測試通過，準備進行下一個不相關的大任務時。
   - 單一對話對話輪數過多、或終端大量錯誤日誌累積時。
3. **固化與交接 SOP**：
   - **寫入 `updata.txt`**：按照專案規定，在最頂部追加最新英文更新日誌（含變更檔案、關鍵邏輯、測試驗證結果）。
   - **更新狀態**：將當前進度與下一步標記在 `docs/development-status.md`。
   - **提示重啟**：在回覆末端提示使用者點擊「New Chat」開啟新對話。
4. **冷啟動接手**：新開啟的對話**不依賴任何舊歷史記憶**，只需閱讀 `AGENTS.md`、`updata.txt`（頂部最新日誌）與 `docs/development-status.md`，即可 100% 精準恢復上下文並立刻推進下一任務。

## 可直接貼给下一個 AI 的提示

> 請接續 E:\WORK\Dao2。先閱讀 AGENTS.md、README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md 與 updata.txt 頂部 checkpoint；按呈現層索引定位來源，UI 必讀 docs/07。使用現有 Godot 4.7.2／GDScript／Compatibility／單執行緒 Web。34 Runner 於 2026-10-02 重跑通過，Session 白名單已補，M4-B 與 M5-A／B 核心資料已交付；不重做舊接線，也不把數值測試當作九界完整遊玩驗收。先接續最新 UI7、混搭字型、FX2／TEXT1 的回饋及裝置驗收，再選靈獸／成就或補 M5 完整 DoD；缺少證據的項目照狀態頁保留待驗。

## RES1-B 冷啟動入口（2026-10-03）

先讀 [B 驗收](verification/res1-b.md) 及 updata 頂部：核心 251 checks／native 三程序交付，整體 IN_PROGRESS；下一 RES1-B／M1-C/D Web 故障矩陣，尚未進 RES1-C。重跑 `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_res1b_verification.ps1`。測試資料只在 docs/verification/artifacts/res1-b-cross-process；全量最近一輪 44/45、exit 1（其他新增 DebugActions 面板失敗），不要忽略。schema3 decoder支援舊schema2，但正式processing catalog仍未啟用；瀏覽器matrix不能由native結果推定。
