# M3-B 第一彈：丹藥與煉丹房系統驗證紀錄

狀態：DONE（CLI／Domain／Simulation／Persistence／UI 全閉環）。

規格依據：[Roadmap M3-B](../../ROADMAP.md)、[來源基線 00-source-baseline.md](../00-source-baseline.md)。

---

## 交付項目

1. **領域模型與存檔擴充 (`GameState` & `SaveCodec`)**：
   - `pills: Dictionary`（持有丹藥庫存：`{ "cultivation_pill": int, "lifespan_pill": int, "foundation_pill": int }`）。
   - `pill_effects: Dictionary`（當世累積效果：`{ "lifespan_bonus_years": float, "production_multiplier": float, "total_consumed": int }`）。
   - `SaveCodec` 完整向後相容：解碼時若無新欄位，安全回退為預設 `{}`。

2. **丹道系統模組 (`src/simulation/alchemy_system.gd`)**：
   - 丹方與效果定義：
     - **聚靈丹 (`cultivation_pill`)**：消耗下品靈草 10、靈氣 50；服用直接注入 60 秒修煉進度。
     - **延壽丹 (`lifespan_pill`)**：消耗下品靈草 25、靈木 20、金錢 30；服用當世壽元上限永久增加 5 祀（300 秒）。
     - **築基丹 (`foundation_pill`)**：消耗下品靈草 50、玄銅 20、靈氣 200；服用永久提高洞府全局產率 10%。
   - 解鎖判定：`herb_farm`（靈植場）>= 3 階 或 `era_id` >= 2 解鎖煉丹房。
   - 煉製驗證（`can_refine`）與材料原子性扣除（`refine`）。
   - 服用驗證（`can_consume`）與即時效果生效（`consume`）。

3. **模擬與時間推進整合 (`TimeAdvancer` & `Lifespan`)**：
   - `TimeAdvancer.advance()` 與 `advance_time_only()` 取出 `pill_effects.lifespan_bonus_years`，即時延展壽元耗盡邊界。
   - 接入丹藥產率加成（`pill_effects.production_multiplier`），促進修仙產能。

4. **輪迴轉世規則聯動 (`ReincarnationRules`)**：
   - 轉世重塑肉身時，乾淨清空當世持有丹藥（`state.pills.clear()`）與當世丹藥效果（`state.pill_effects.clear()`）。

5. **互動 UI 面板 (`src/presentation/alchemy_panel.gd`)**：
   - 提供「洞府煉丹房」自適應視窗。
   - 頂部丹道加成摘要橫幅（加壽祀數、全局產率、累計服丹數）。
   - 丹藥卡片列表（名稱、品質、描述、煉製消耗、當前持有、單次煉製、服用按鈕）。
   - 支援寬式與窄螢幕（360×640）自適應排版與超過 44px 的安全點擊區。

6. **主場景接入 (`src/abode/living_abode.gd`)**：
   - 次級選單「更多功能」增加第 7 項「洞府煉丹」，工具列新增煉丹房按鈕。
   - 支援煉丹與服丹事件響應、即時 HUD 刷新與自動存檔。

7. **專屬測試**：
   - `tests/m3b_alchemy_runner.gd`（exit 0，解鎖門檻、材料扣除、庫存生成、服丹效果、壽元延展、存檔往返、輪迴重置全通）。
   - `tests/m3b_alchemy_ui_runner.gd`（exit 0，UI 面板開關、按鈕狀態、煉製服用響應、360×640 響應式佈局全通）。

---

## 驗證證據

1. **CLI 全量 Runner 測試**：
   - `powershell -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1`
   - 全量 19 項 Runner 全部 PASS（退出碼 0）。
2. **Web Release 匯出**：
   - `Godot --export-release Web build/web/index.html`：PASS（退出碼 0）。
