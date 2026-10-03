# M3-B 舊系統承接與子系統驗證紀錄

**2026-10-03 RES1 現況校正**：子系統已交付不等於完整 DAO1 資源／建築／配方／修行內容承接。DAO1 61 資源／30 配方，DAO2 manifest 僅 7 資源、10 建築與 Era 1–2，另有子系統內建資源。缺口從 Era 2 的完整依賴與 Era 3 起即存在；接手主線改為 RES1-A→B→C→D，Era 4–12 再逐段補齊，不只列 Era 9–12。[稽核與差異](resource-progression-audit.md)、[多島設計](../14-multi-island-resource-progression.md)。以下按日期的子系統證據仍保留原範圍。

2026-10-02 DOC-A-R1 現況補記：GameSession 白名單與宗門／跨界／BUFF 呼叫已補上；以下 9/28 UNKNOWN_COMMAND 記錄是歷史發現，不再表示目前尚未接線。宗門 Session 成功路徑已有 runner，本輪固定入口 34/34 PASS；全部新命令拒絕／冪等／保存及實際 Web 操作仍按 R1 補證，未宣稱完整端到端驗收。見 [複核](doc-a-r1.md)。

2026-09-28 歷史狀態複核：宗門規則與面板已實作，但 `GameSession.KNOWN_COMMAND_TYPES` 不接受 `join_sect`／宗門後續命令；其餘 BUFF／跨界新命令亦需同一整合修復。M4-A-R1 完成前，以下只記模組與當時 runner 結果，不能視為正式場景閉環。見 [REF-A](ref-a.md)。

狀態：IN_PROGRESS（逐項交付中：丹藥、BUFF、宗門、天時、機緣已實作並有測試；靈獸、成就等接續推進，非全量收尾）。

規格依據：[Roadmap M3-B](../../ROADMAP.md)、[來源基線 00-source-baseline.md](../00-source-baseline.md)。

---

## 已交付子系統

### 第一彈：丹藥與煉丹房系統（2026-09-26 交付）
1. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `pills: Dictionary`（持有丹藥庫存：`cultivation_pill`、`lifespan_pill`、`foundation_pill`）。
   - `pill_effects: Dictionary`（當世累積效果：`lifespan_bonus_years`、`production_multiplier`、`total_consumed`）。
   - `SaveCodec` 完整向後相容解碼。
2. **丹道系統模組 (`src/simulation/alchemy_system.gd`)**：
   - 聚靈丹（注修煉）、延壽丹（增壽元）、築基丹（增全局產率）。
   - 靈植場 $\ge 3$ 階或築基期解鎖，材料原子性扣除與即時生效。
3. **時間與輪迴聯動**：
   - `TimeAdvancer` 取出丹藥加壽即時延展壽盡邊界，並享受全局產率加成。
   - `ReincarnationRules` 轉世重塑肉身時清空當世持有丹藥與效果。
4. **介面與測試**：
   - `src/presentation/alchemy_panel.gd` 提供自適應視窗與頂部摘要橫幅；次級選單第 7 項直達。
   - `tests/m3b_alchemy_runner.gd` 與 `tests/m3b_alchemy_ui_runner.gd`（exit 0 / PASS）。

---

### 第二彈：BUFF 與狀態時效增益系統（2026-09-27 交付）
1. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `buffs: Dictionary` 記錄增益生命週期、剩餘秒數與疊加層數，具備向後相容解碼。
2. **BUFF 規則模組 (`src/simulation/buff_system.gd`)**：
   - 支援時效衰減、同類刷新、永久特質（長生龜息）及跨世道痕（transmigratable）繼承規則。
   - 預置四種經典增益：天靈氣湧（靈氣產率）、頓悟靈光（修煉速度）、破境餘韻（大境界突破自動觸發 120 秒雙倍產率）、長生龜息（壽元延長）。
3. **推進與指令整合**：
   - `TimeAdvancer` 接入每秒 tick 衰減、動態產率加成、修煉速度倍率與壽元上限。
   - `CommandProcessor` 接入 `apply_buff` 與 `remove_buff`；突破 `breakthrough_era` 自動施加「破境餘韻」。
   - `ReincarnationRules` 轉世清除肉身 BUFF，保留跨世道痕特質。
4. **介面與測試**：
   - `src/presentation/buff_hud_bar.gd` 接入自適應微徽章狀態列，無 BUFF 時自動隱藏零佔位。
   - `tests/buff_system_runner.gd`（exit 0 / PASS）。

---

### 第三彈：宗門系統、委託派遣、宗門真訣與坊市（2026-09-28 交付）
1. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `sect: Dictionary` 持久化門派、職位、貢獻、委託槽位、真訣與坊市限購紀錄。
2. **宗門規則模組 (`src/simulation/sect_system.gd`)**：
   - 門檻與五大宗門：築基期或轉世 $\ge 1$ 解鎖，可拜入太虛天闕、天劍聖宗、縹緲仙宮、萬佛靈宗或紫霄玄門。
   - 三大委託槽位派遣：5 種品質隨機懸賞、冷卻刷新、耗時倒數結算，產出貢獻、金錢、靈草、靈石、玄銅與頓悟靈光；全邏輯確定性，無系統時鐘依賴。
   - 宗門真訣倍率：神農靈訣（草木產能）、太虛吐納（靈氣產能）、天劍戰訣（修煉速度）、紫霄護體（壽元增益），支援 10 級修習與貢獻消耗。
   - 宗門坊市限購兌換靈草、朱果、聚靈丹。
3. **介面與測試**：
   - `src/presentation/sect_panel.gd` 接入三頁式自適應面板，主場景頂部自適應入口與次級選單第 10 項直達。
   - `tests/m3b_sect_runner.gd` 與 `tests/m3b_sect_ui_runner.gd`（exit 0 / PASS）。

---

## 2026-09-30–10-01 新增交付

- 天時：ChronoSystem 十二時辰與五行天候、時間推進／倍率／保存／HUD；m3b_chrono_runner。
- 機緣：FortuneSystem、FortuneModal、原子性決策與保存／輪迴重置；fortune 與 fortune_ui runners。
- M5-B 將奇遇資料擴充為 26 項並加當前界域偏向；14 項 RealmDecisionSystem 決策有 Session 與保存測試。
- 本次 34/34 Runner PASS，實機與完整 UI／Web DoD 不由此推定。參見 [九界規格](../11-nine-realms-law-and-world-generation-spec.md)、[複核](doc-a-r1.md)。

---

### 第六彈：仙道成就與功業圖鑑系統（2026-10-03 交付）
1. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `achievements: Dictionary` 記錄已達成時間戳、已領取標記及累計統計（`unlocked`、`claimed`、`stats`）。
   - 成就作為元進度（Meta-progression），在輪迴轉世（Reincarnation）時完全保留。
   - `SaveCodec` 支援向後相容解碼與統計欄位整數型別正規化。
2. **成就核心規則模組 (`src/simulation/achievement_system.gd`)**：
   - 涵蓋 6 大維度共 18 項經典成就（境界、營造、丹道、宗門、靈獸機緣、輪迴超脫）。
   - `check_achievements(state, content)` 進行條件判定與自動解鎖。
   - `claim_reward(state, content, id)` 原子性發放獎勵（道心、道證、資糧等）並防範未達成與重複領取。
   - `reset_achievements(state)` 供 DEBUG 功能隨時清空重置。
3. **指令與 DEBUG 調試工具整合**：
   - 指令白名單：新增 `claim_achievement`，並由 `GameSession.claim_achievement(id)` 封裝。
   - DEBUG 面板：`src/presentation/debug_panel.gd` 擴充「仙道成就調試」區塊與「重置全部成就進度」按鈕，已連接 `living_abode.gd` 立即落盤。
4. **介面與導航整合**：
   - `src/presentation/achievement_panel.gd` 接入成就總覽、進度條、卡片列表與領取按鈕。
   - `FeatureNavigation` 將成就整合至「修行」第 4 分頁，並依未領取獎勵數量在修行入口顯示動態提示。
5. **測試與全量驗證**：
   - `tests/m3b_achievement_runner.gd` 6/6 PASS（exit 0）。
   - 全量 `tools/run_all_runners.ps1` 39/39 Runner PASS（exit 0）。

## 後續待推進子系統

- 仙道圖鑑深化；多語與高階修行（Era 9–12）按 Roadmap 逐項核對。

## 歷史驗證證據
- 全量 25 項 Runner 經 `tools/run_all_runners.ps1` 執行，退出碼均為 0。
- Web Release 匯出 exit 0。
