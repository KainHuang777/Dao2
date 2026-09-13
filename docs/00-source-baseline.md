# 修仙問道 v2｜需求來源與舊版基線

文件日期：2026-09-12。狀態：已讀分享對話、舊站與使用者提供的 `E:\Python\test1` 原始碼；存檔樣本候選已定位，尚未解析或做遷移測試。

本文件區分使用者要求、直接觀察、前次對話建議及 v2 新提案。後續實作不得把畫面文案直接視為完整公式，也不得把規劃數值宣稱為舊版規則。

## 1. 來源與讀取結果

| 來源 | 本次取得的證據 | 使用方式 |
| --- | --- | --- |
| [原始 ChatGPT 分享對話](https://chatgpt.com/share/6aa55217-908c-83ee-ba0d-f27a761d80b7)：「比較遊戲引擎協作方案」 | 瀏覽器成功讀取。使用者提出重寫修仙放置、參考 Idle Planet Miner，並明確要求 Godot AI-first 架構及前期規劃文件 | 承接產品及引擎方向 |
| [舊版修仙問道](https://dao-sooty-nine.vercel.app/) | 瀏覽器讀取首頁、遊戲說明、天賦／靈獸頁及功法頁；畫面版本 v0.46.6，Build 顯示 2026-09-09 17:46:48 UTC | 已觀察的需求基線，不代表完整遊戲稽核 |
| 本次使用者訊息 | 重現原本修仙問道放置玩法；驚豔視覺；修仙世界、九界、無限宇宙；指定 GPT-6 Astra | 本輪規劃的最高優先需求 |
| 使用者補充的 E:\Python\test1 | 已唯讀檢查，package.json 為 v0.46.6；TypeScript／Vite、PixiJS、React、break_eternity；包含規則、CSV、平衡模擬器與測試 | 公式、資料結構及跨語言重寫的主要證據；未執行舊專案或測試 |
| 本機 E:\WORK\Dao2 | 初始列目錄為空；父目錄與專案未找到 AGENTS.md；PATH 查詢未找到 godot／godot4 | Dao2 尚無 Godot 程式碼；遷移對照與原版測試來自 test1；不能據此認定整台電腦未安裝 Godot |

分享對話最後可見前一位助理準備規劃文件的說明與「套用程式碼修補程式」，未取得可下載的完整規劃文件。本次重新整理成工作區內可持續維護的 Markdown。

## 2. 舊站觀察記錄

此表保留「只看網站」時的證據強度；其中未知項目若已由原碼釐清，以第 4 節為準。網頁文案不覆蓋執行中的規則。

| 系統 | 觀察 | 證據強度與未解問題 |
| --- | --- | --- |
| 新手開局 | 練氣期（Era 1）、等級 1；靈力可點擊採集 +1，上限顯示 100；指引要求累積 20 靈力建造茅屋後開啟自動產出 | 首頁與指引實見；未進行完整新手通關 |
| 茅屋 | Lv.0/2；消耗 20 靈力；提示同時出現 +0.3/秒 → +0.85/秒，以及卡片 +0.85/秒 | 可能涉及基礎值、下一級值或天時加成，尚無法確定；不得據此還原產能公式 |
| 成長 | 升階、提升等級、修練進度；境界年歲、修練時間、壽元，初始壽元上限 80 祀 | 概念及欄位實見；祀與真實時間的換算、突破與壽盡行為未知 |
| 天時 | 一運：坎水運，畫面顯示 +10% | 實見一個狀態；影響範圍、週期、離線推進規則未知 |
| 資源與建築 | 說明提到靈石、靈木、靈鐵、靈草；聚靈陣、煉丹房、藏經閣 | 說明文案；與前期指引的「金錢」等實際資源命名需用原碼核對 |
| 功法 | 入口存在，開局顯示暫無可修煉功法；說明記載產出、修煉速度與境界需求 | 存在性確認；功法資料、研究費用與永久性的範圍未知 |
| 輪迴 | 說明表示重置修為與建築，保留道心與道證；UI 有輪迴次數、可用道心、道證位格 | 未實際執行輪迴，不承諾完整保留清單 |
| 天賦 | 可見先天道體、先天道胎、資源傳承、五靈根、長生久視、時光加速、因果倉儲等；部分有輪迴次數與 EAR 解鎖條件 | 可見內容證明有產出、消耗、上限、壽元、冷卻、傳承等效果類型；EAR 與 Era 的對應待查 |
| 道證 | 遊戲說明稱可解鎖輪迴天賦；UI 顯示「道證位格」與上限加成 | 兩者可能並存，不能自行合併成單一用途或消耗規則 |
| 靈獸 | 天賦／靈獸入口及獨立靈獸按鈕可見 | 養成與獲取未驗證；仍列入保留需求 |
| 宗門 | 說明有任務、貢獻與職位、雲海天市、天機任務、宗門功法 | 文案確認；刷新與領取規則、日常負擔待查 |
| 便利性 | 成就、修仙日誌、存檔與讀取、TC／SC／EN／JP 切換入口 | 入口確認，未測存檔結構與多語完整度 |
| 機緣與 Debug | 前次助理將其列入需求來源；舊站說明可見特殊機緣 | 機緣完整流程與 Debug 能力未直接驗證 |

本次沒有操作付費、輪迴、重置或匯入舊存檔，也沒有變更舊站程式碼。只以公開頁面和導覽檢視需求。

## 3. 技術考證

截至文件日期，官方下載檔案庫列出 **Godot 4.7.2 stable，2026-08-18**，因此 v2 的起始基線可鎖定 4.7.2，匯出模板使用同版；不是自動追蹤最新版。[官方下載檔案庫](https://godotengine.org/download/archive/)

Godot 官方文件確認 GDScript 適合此 Web 路線；Godot 4 的 Web 匯出使用 WebAssembly／WebGL 2.0 和 Compatibility renderer，C# 專案目前不支援 Web 匯出。單執行緒可避免多執行緒所需的跨來源隔離設定。背景分頁可能暫停遊戲處理，因此本案設計獨立的離線結算；瀏覽器儲存與音訊也需實測。[官方 Web 匯出文件](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

Godot 支援 CLI 資源匯入、腳本執行與匯出；匯出依賴預設組態及對應模板。Headless 可驗證規則與載入，不足以證明圖像品質。[官方 CLI 文件](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)

上述 stable 文件可能後續更新；M0 建立環境時需把版本、模板、文件擷取日期記入驗證紀錄。前次對話引用的 MCP 專案、星數與成熟度排名本次未逐項驗證，不作為選型依據。

## 4. 原始碼核對後的規則基線

下列為靜態讀碼結果，附精確定位供下一階段對照；不宣稱本輪已執行測試。舊資料中 `Era`／`EAR` 是修行境界，九界是 v2 新的世界層。

| 規則 | 讀碼結果 | 來源 |
| --- | --- | --- |
| 新手鏈 | schema v1 從靈力／茅屋起步，依序茅屋 2、木屋 2、林場 3、採石場 3、靈植場 3；可見性覆蓋 CSV 初始 unlocked | [onboardingUnlocks.ts](E:/Python/test1/src/balance/rules/onboardingUnlocks.ts:37) |
| 新手容量 | schema v1 茅屋每級增加 150 靈力容量，跨境界保留；不能直接寫成所有歷史存檔的全域效果 | [onboardingUnlocks.ts](E:/Python/test1/src/balance/rules/onboardingUnlocks.ts:13) |
| 境界 | 12 個境界，練氣至金仙，每境 10 級 | [eras.csv](E:/Python/test1/src/data/eras.csv:2) |
| 小等級 | 檢查累積修煉時間、功法與資源；時間為同境幾何累加，九升十另有材料 | [EraManager.ts](E:/Python/test1/src/utils/EraManager.ts:318)、[BreakthroughSystem.ts](E:/Python/test1/src/utils/BreakthroughSystem.ts:351) |
| 大境界 | 要求指定容量上限，並非把庫存當作同額突破費用 | [EraManager.ts](E:/Python/test1/src/utils/EraManager.ts:163) |
| 渡劫 | 金丹期起升境界有渡劫；基礎成功率 50%，多種加成後限制 0–100%；失敗掉 1–3 級、最低 1 級，結果都清丹藥效果 | [breakthrough.ts](E:/Python/test1/src/balance/rules/breakthrough.ts:54)、[BreakthroughSystem.ts](E:/Python/test1/src/utils/BreakthroughSystem.ts:157) |
| 年歲 | 一分鐘對應一祀；年齡由本世時間戳計算，升境不歸零 | [LifespanSystem.ts](E:/Python/test1/src/utils/LifespanSystem.ts:5) |
| 壽元 | floor(由 Era 1 累加到當境的 lifespan × (1＋天賦加成)＋丹藥加壽)；無加成練氣 80、築基 200、金丹 740 祀 | [LifespanSystem.ts](E:/Python/test1/src/utils/LifespanSystem.ts:82) |
| 壽盡 | 停止修煉／突破，資源更新返回 | [ResourceManager.ts](E:/Python/test1/src/utils/ResourceManager.ts:257) |
| 輪迴獎勵 | B 為建築等級總和，含倉儲；道心=max(floor(B/10),境界保底)，保底練氣0／築基15／金丹20／元嬰以上25；普通道證=floor(B/50)，大道=floor(B/30) | [lifespanRules.ts](E:/Python/test1/src/balance/rules/lifespanRules.ts:81) |
| 輪迴保留 | 保留天賦、累積道心道證、次數與最高境界；清建築／資源／已學功法，宗門另依傳承規則處理 | [ReincarnationSystem.ts](E:/Python/test1/src/utils/ReincarnationSystem.ts:31) |
| 起手傳承 | 第二世五種基礎資源給重置容量40%，第三世起80%；資源傳承每級另10%，受容量限制且不提前解鎖 | [reincarnationInheritance.ts](E:/Python/test1/src/balance/rules/reincarnationInheritance.ts:18) |
| 因果倉儲 | 宗門貢獻每級保留5%；秘銀／星隕鐵是每級各給100，不是前世庫存百分比 | [ResourceManager.ts](E:/Python/test1/src/utils/ResourceManager.ts:487) |
| 靈獸輪迴 | 成熟出戰獸給對應獸魂，當世持有獸清空 | [BeastManager.ts](E:/Python/test1/src/utils/BeastManager.ts:285) |
| 道心道證加成 | 道心0.15×log10(道心+1)，道證0.05×sqrt(道證)；天賦購買會消耗道心；前世記憶是功法折扣 | [talentRules.ts](E:/Python/test1/src/balance/rules/talentRules.ts:199)、[TalentSystem.ts](E:/Python/test1/src/utils/TalentSystem.ts:95) |
| 大數 | break_eternity 的 sign/layer/mag 分層表示；序列化字串可能超過普通科學記號範圍 | [break_eternity.js](E:/Python/test1/src/utils/break_eternity.js:532)、[toJSON](E:/Python/test1/src/utils/break_eternity.js:1489) |
| 存檔 | v=1.0；縮寫 JSON 主體 {v,o,t,p,r,b,s,beastData}；分享碼外包UTF-8 Base64；r中v/u/e為數量／解鎖／曾取得 | [saveSystem.ts](E:/Python/test1/src/utils/saveSystem.ts:59)、[ResourceManager.ts](E:/Python/test1/src/utils/ResourceManager.ts:773) |

初步發現的差異和風險：

- [main.ts:70](E:/Python/test1/src/main.ts:70) 的讀檔啟動路徑未見以保存時間補資源；[gameLoop.ts:31](E:/Python/test1/src/utils/gameLoop.ts:31) 用 RAF 秒差，壽元另用真實時間。v2 統一離線屬行為改善，需與壽元一起設計。
- [saveSystem.ts:214](E:/Python/test1/src/utils/saveSystem.ts:214) 主檔及備份同次寫相同内容；分散存儲及獸資料載入路径需在遷移驗證處理，不能宣稱分享碼涵蓋全部進度。
- [SimulationState.ts:27](E:/Python/test1/src/balance/simulation/SimulationState.ts:27) 目前 `MAX_ERA=8`，所以十二境界 CSV 存在不代表高階動態模擬全受測。
- [buildings.csv:28](E:/Python/test1/src/data/buildings.csv:28) 劍侍含測試用途的開放節奏註記；[BreakthroughSystem.ts:292](E:/Python/test1/src/utils/BreakthroughSystem.ts:292) 加成註解與現行純規則不同。先辨別正式／開發 profile，不照抄註解。
- [ReincarnationSystem.ts:132](E:/Python/test1/src/utils/ReincarnationSystem.ts:132) 執行輪迴未在該函式重查資格；v2 核心需要驗證，具體舊調用鏈在實作前補查。

## 5. 可沿用的驗證資產

| 資產 | 用法 |
| --- | --- |
| [formulaParity.test.ts:225](E:/Python/test1/tests/balance/formulaParity.test.ts:225) | 公式與 Manager 對照；抽成語言無關 fixture；709 行有容量記錄值，1209 行起有修煉時間基準 |
| [SeededRandom.ts:14](E:/Python/test1/src/balance/simulation/SeededRandom.ts:14) | 雜湊／Mulberry32／狀態還原的序列對照 |
| [SimulationRunner.ts:128](E:/Python/test1/src/balance/simulation/SimulationRunner.ts:128) | 短程狀態轉換及回鍋 schedule；操作次數與經過時間分開 |
| [simulation.test.ts:62](E:/Python/test1/tests/balance/simulation.test.ts:62) | 固定 seed、在線離線、容量、宗門、跨輪迴 RNG 情境 |
| [earlyGameOnboardingBaseline.test.ts:52](E:/Python/test1/tests/balance/earlyGameOnboardingBaseline.test.ts:52) | 零免費基礎產率、第一個自動化與新手可見性基線 |
| [earlyGameEra1To6Progression.test.ts:965](E:/Python/test1/tests/balance/earlyGameEra1To6Progression.test.ts:965) | Era5–6 市場與虛空鏈參考，避免只測開局 |
| [monteCarlo.test.ts:1488](E:/Python/test1/tests/balance/monteCarlo.test.ts:1488) | 長期回鍋候選基線；需顯式 RUN_A5_LONG_ACCEPTANCE，不能用一般測試成功替代 |
| [BalanceDataSource.ts:86](E:/Python/test1/src/balance/data/BalanceDataSource.ts:86) | 固定 source profile 和 SHA-256 manifest，避免比較不同資料 |

既有測試與文件中的歷史通過數、效能和「絕對精確」聲稱均不作本次測量結果。先建立輸入／輸出 fixture 包，再用相同資料版本測 Godot。旧測試不是所有舊行為都正確的保證。

## 6. 待補證據與處理方式

| 優先級 | 缺少資料 | 影響 | 現階段做法 |
| --- | --- | --- | --- |
| P0 | 原碼提交、dirty diff、正式與開發資料 manifest 尚未固定 | 基線可能漂移 | M0 記錄來源版本並抽 fixture；此輪不更改舊倉庫 |
| P0 | 存檔樣本尚未解析、跨語言 Amount 尚未驗證 | 無法保證所有舊存檔續玩 | 先完成格式矩陣及邊界測試 |
| P1 | 天時、機緣完整時間規則及所有輪迴調用路徑 | 離線和門檻行為需要補足 | 以代表性黃金案例逐項追查 |
| P1 | 原作九界名稱與設定是否存在 | 新世界設定可能不一致 | 本規劃九界全部標「v2 暫名提案」 |
| P1 | 基準手機、目標平台排序、資產與製作人力 | 效能與工期無法定案 | 主洞府採桌面橫版 Web-first；手機直式另列適配驗收，以里程碑取代交期承諾 |

三個 GPT-6 Astra 評審分別提供玩法、架構與製作風險意見，並在收到舊碼後補做唯讀核對。共識是先證明完整循環、保持模擬與特效分離、以手工差異世界驗證擴充。技術評審提出可把物流納入經濟，玩法評審主張先保真；最終採首版純呈現、跨界階段才評估實際運輸。對切片是否立即包含輪迴／第二界，採先突破、再輪迴、再跨界的獨立門檻。多視角一致不等於實測，本次沒有完成遊戲原型或使用者測試。
