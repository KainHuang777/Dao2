# 開發狀態與交接紀錄

更新：2026-10-03（RES1-B-WEB-R1 桌面 Web 保存故障矩陣交付；下一 RES1-C）。區分設計、實作、測試與完整驗收；下方較早紀錄的「下一步」保留歷史，最新順序以首項 RES1 為準。

## 目前任務與下一步

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

- **M2-D-NAV1：IN_PROGRESS，實作與回歸交付**。四主入口／九分頁、洞天與建築經營整合、共用跨界資源、靈獸與天道決策 UI；36/36 Runner、追加相容／響應式／機緣回歸、20 native PNG、Web 匯出及 IAB 桌面／短橫向滑鼠。使用者分類／視覺回饋與實體觸控／高 DPR 待補；[規範](12-feature-navigation-and-integration-spec.md)、[檔案／命令／結果與未完成項](verification/feature-navigation.md)。
- **DOC-A-R1 文件現況複核：DONE**。
- **M3-B 靈獸系統（Spirit Beasts）：DONE**。交付四大靈獸（玉狐、玄龜、火鳳、雲蛟）、四階成長階段（卵/幼體/成長/成熟）、餵食消耗與冷卻倒數、4階獸魂天賦樹、輪迴成熟獸魂結算與跨世繼承、TimeAdvancer 模擬數值與產率整合、GameSession 三項命令（acquire/feed/talent）及 SaveCodec 存檔相容性。全量 **35/35 Runner PASS、exit 0**。
- **優先：UI7／UI6-R1／FX2／TEXT1 回饋與裝置驗收**。常態材質已實作，先收視覺回饋，再驗高 DPR、實體觸控／GPU、音訊與效能。
- **下一工作：RES1-C 三島 T2 操作切片**；M4-A-R1 與成就的原交付保留，M1-C/D Web 持久化／離線故障驗收與 RES1-B 相交部分仍須補齊。多島資源玩法尚未實作；後續大型任務使用 New Chat。

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
| RES1 | DESIGN／A DONE（A 為首批契約／隔離核心）；B DONE（原型核心／251 checks／native三程序＋桌面Web故障矩陣）；C–E TODO；正式多島未放行 | [規格](14-multi-island-resource-progression.md)、[稽核](verification/resource-progression-audit.md) |
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
- 玩家保存與 fixture／預覽 origin 分離；本輪未改規則、資產、存檔或既有 HTTP 日誌。

## 歷史與按需閱讀

- [DOC-A-R1 前完整記錄](archive/development-status-2026-10-02-before-doc-a-r1.md)：保留原文與日期。
- [M0–M2 歷史](archive/development-status-m0-m2.md)、[M3–M4 歷史](archive/development-status-m3-m4.md)。
- [呈現索引](abode-presentation-map.md)、[AI 交接](ai-handoff.md)、updata.txt 頂部最新英文 checkpoint。
