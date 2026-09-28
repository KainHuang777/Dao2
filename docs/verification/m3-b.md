# M3-B 舊系統承接與子系統驗證紀錄

2026-09-28 狀態複核：宗門規則與面板已實作，但 `GameSession.KNOWN_COMMAND_TYPES` 不接受 `join_sect`／宗門後續命令；其餘 BUFF／跨界新命令亦需同一整合修復。M4-A-R1 完成前，以下只記模組與當時 runner 結果，不能視為正式場景閉環。見 [REF-A](ref-a.md)。

狀態：IN_PROGRESS（逐項交付中：已完成丹藥、BUFF、宗門子系統；天時、機緣、靈獸、成就接續推進，非全量收尾）。

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

## 後續待推進子系統（非阻塞主線 M4-B）
- **天時與天象運轉**（季節、陰陽時辰對草木靈氣之影響）
- **機緣奇遇與福地探索**
- **靈獸培育與護山守衛**
- **仙道成就與通天圖鑑**

---

## 驗證證據
- 全量 25 項 Runner 經 `tools/run_all_runners.ps1` 執行，退出碼均為 0。
- Web Release 匯出 exit 0。
