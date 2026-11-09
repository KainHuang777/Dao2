# 築基節奏調優與內容充實計畫（ERA2-PACING-EXPANSION）

## 任務編號
- **總任務 ID**：`ERA2-PACING-EXPANSION`
- **子階段 1（死鎖解除）**：`ERA2-PACING-A1`
- **子階段 2（建築充實）**：`ERA2-PACING-B2`

## 背景與問題診斷
1. **丹液死鎖問題（Era2 Lv5）**：
   - 築基五層起強制要求「丹液 5」，但產出靈草的丹霞島（`herb`）鎖死在金丹期（`era: 3`）。
   - 原系統架構設計允許在 Era 2 走「祖島替代產線」，但 `level_up_supply_panel.gd` 未包含 `liquid`，且按鈕反查錯誤指向丹霞島，導致引導中斷與操作死鎖。
2. **前期節奏發呆問題（對標《貓國建設者》）**：
   - Era 1 建築單調；Era 2 只有唯一建築 `foundation_reservoir`。建造完畢後，整段築基期退化為純等待修煉條與運送材料，缺乏階段性正向反饋與目標。

---

## 子階段規劃

### 階段一：ERA2-PACING-A1（打通祖島丹液鏈路，解除死鎖）
1. **修改 `src/presentation/level_up_supply_panel.gd`**：
   - `RECIPES` 擴充為 `["spirit_timber", "bronze_essence", "liquid"]`。
   - `offers_help` 支援 `missing.has("liquid")`。
   - 當 `id == "liquid"` 且 `era_id == 2` 時，產地指定為祖島（`"home"`），按鈕標題為「煉製丹液」，發送 `recipe_requested("liquid")`。
2. **完善 `src/presentation/feature_navigation.gd`**：
   - 點擊 `liquid` 時導航至祖島合成線的丹液配方卡片。
   - 若祖島藥田（`herb_farm`）未達 3 級，提供提示或跳轉至營造清單。
3. **完善 `src/simulation/onboarding.gd`**：
   - 築基四層進階文案提示：「五層晉階需丹液。可先在祖島將藥田建至三級產靈草，再於祖島工坊煉製丹液」。
4. **L1 單元驗證**：
   - 執行 `tests/era2_island_flow_runner.gd` 與 `tests/early_flow1d_hub_runner.gd`。

### 階段二：ERA2-PACING-B2（充實 Era2 建築，提升緊湊感）
1. **擴充 `content/buildings/era2.json`**：
   - **`alchemy_chamber`（煉丹靜室）**：煉丹與丹液週期縮短 15%；前置為藥田 3 級 + 靈池 1 級；成本靈木 30、玄銅 15、下品靈石 10。
   - **`spirit_array_plate`（聚靈陣盤）**：修煉速度 +10%；前置為草廬 2 級 + 靈力倉庫 2 級；成本金錢 50、玄銅 20、下品靈石 20。
   - **`dock_post`（飛舟渡口）**：全航線運輸時間縮短 15%（10s -> 8.5s）；前置為林場 3 級 + 採石場 3 級；成本靈木 40、玄銅 20。
2. **接入加成計算**：
   - 在 `building_system.gd` 或對應倍率計算模組中應用效果。
3. **相容性與 L1/L2 驗收**：
   - 確保已有存檔載入不崩潰，新建築正常購買與升級。

---

## 驗收標準（DoD）
1. Era2 Lv5 缺丹液時，補給面板能正確開啟並提供「煉製丹液」按鈕。
2. 點擊後直達祖島丹液配方，清楚告知藥田 3 級前置。
3. Era2 建築清單包含三棟新設施，可正常建造且數值加成生效。
4. 全程符合 KISS 原則與 `AGENTS.md` 分級驗收規範。

