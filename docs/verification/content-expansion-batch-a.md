# 內容擴充 Batch A：丹藥與渡劫設計記錄（2026-10-11，設計階段，未實作）

狀態：DESIGN（使用者已逐條裁定；數值為提案，須於實作前由使用者核定）。本文件為第 1 步紀錄，尚未修改任何遊戲程式、內容或存檔。

## 1. 現況（唯讀盤點）

- 服用丹：`src/simulation/alchemy_system.gd` 硬編碼 `PILLS` 三種（`cultivation_pill` 聚靈丹、`lifespan_pill` 延壽丹、`foundation_pill` 築基丹），即時煉製，效果累加至 `state.pill_effects`，輪迴清空。效果軸只有修煉秒數／壽元／產率。
- 加工配方：`content/recipes/era1_3.json`（`res1-a-1`，`release_enabled:false`）8 條；`golden_core_pill` 只能產出，沒有服用效果。
- 渡劫：v2 目前沒有成功率擲骰；突破為確定性規則。
- 死資料：`content/realms/realms.json` 的 `pill_speed_mult`／`pill_success_bonus` 無 runtime 消費點。
- 舊版來源：`E:\Python\test1\src\data\PillConfig.ts`（唯讀）。舊版渡劫基礎成功率 50%，失敗降 1–3 階並清除丹效（`docs/00-source-baseline.md:62`）。

## 2. 使用者裁定（權威）

1. 渡劫基礎成功率：「EAR3 起突破基礎成功率為 80%，每提升 1 EAR 下降 10%，可透過天賦減少下降比例。服藥則每個 EAR 都有對應丹藥，不再是所有 EAR 通用一種渡劫成功率提升丹藥。」
2. 隨機性：「可以改寫紀錄種子來讓渡劫有隨機性」——允許隨機，但種子必須寫入存檔、可重現。
3. 數量與邊際遞減：「各 EAR 有各自丹藥，丹藥服用上限相對放大，每個可高達 99；數量越高邊際遞減、效果越差，效益最高可能只有前幾顆。」
4. 延壽：「延壽效果請依照目前壽命公式來換算，但建議 EAR3 之後再開。」
5. EAR 分配：「類似以上的規劃」——EAR1 加速修煉；EAR2 加強修煉丹與高階靈草；EAR3 開渡劫加成丹與短效產出加成丹；EAR4 開延壽丹與渡劫丹及高階丹材。

## 3. 提案公式（待核定）

### 3.1 渡劫成功率
- 基礎：`base(EAR) = max(0.30, 0.80 - 0.10 × (EAR - 3))`，EAR≥3；EAR1–2 不進渡劫。即 EAR3=80%、EAR4=70%、EAR5=60%…下限 30%。
- 天賦減少下降（`decline_reduction`）：Batch A 固定為 0；由 Batch C 的天賦提供。
- 丹藥加成（同一 EAR 的渡劫丹，單種）：`bonus(n) = B × (1 − r^n) / (1 − r)`，`r = 0.85`，`n` 為服用數量，上限 99。B 為單顆基礎加成（見 §4）。`n→∞` 時漸近 `B / 0.15`，故前幾顆貢獻最大。
- 最終成功率：`p = clamp(base − decline_reduction + bonus(n), 0.05, 0.95)`。

### 3.2 隨機與種子
- 每個 `GameState` 保存 `tribulation_seed`（整數）與 `tribulation_roll_index`。每次渡劫嘗試以 `(seed, roll_index)` 導出 roll ∈ [0,1)，成功條件 `roll < p`；嘗試後 `roll_index += 1` 並寫入存檔。
- 同一存檔、同一輸入必得同一結果；領域代碼不得讀系統時間或未記錄的亂數。
- 失敗後果：**未裁定**（舊版為降階並清丹效）。建議 A 階段採「失敗不降階、消耗本次丹藥」，待使用者核定。

### 3.3 丹藥服用上限
- 每種丹藥服用上限 99；單次 `count ∈ [1,99]`，超量拒絕（atomic）。
- 持續型加成（限時）採既有 BuffSystem 同 id 語意（取 max duration），不再疊加倍率；限時丹的 duration 上限 3600 秒。

## 4. 丹藥分期提案（EAR1–4）

| EAR | 丹藥 id（提案） | 類型 | 效果（提案） | 成本（提案，資源來源） | 來源參照（舊版） |
|---|---|---|---|---|---|
| 1 | `cultivation_pill` 聚靈丹 | 即時修煉 | 修煉 +60 秒（既有） | 靈草 10＋靈力 50（既有） | 既有 |
| 1 | `foundation_pill` 築基丹 | 加工 | 產率 +10%（既有 v2，不變） | 靈草 50＋玄銅 20＋靈力 200（既有） | 築基丹 |
| 2 | `high_cultivation_pill` 上品聚靈丹 | 即時修煉 | 修煉 +300 秒，`n` 顆依 §3.3 遞減 | 百年靈草 5＋靈力 200 | 九轉／聚靈系列 |
| 2 | `spirit_tide_pill` 靈潮丹 | 限時 BUFF | 產率 ×1.5，300 秒（BuffSystem id `spirit_tide`） | 丹液 2＋靈力 100 | 靈潮爆發丹（legacy spiritBurst 2.0、300s；冷卻 600s 本批不實作） |
| 3 | `golden_tribulation_pill` 金丹渡劫丹 | 渡劫加成 | B = 0.03（成功率加成） | 築基丹 1＋中品石 3＋百年靈草 2 | 金丹 tribulationSuccess 0.03 |
| 3 | `quick_output_pill` 速產丹 | 限時 BUFF | 產率 ×1.2，600 秒（BuffSystem id `quick_output`） | 符咒 1＋丹液 2 | 化神丹 allProduction 0.01（短效化，數值待核定） |
| 4 | `tribulation_pill` 渡劫丹 | 渡劫加成 | B = 0.05 | 金丹渡劫丹 1＋高階靈草 3＋靈材 2 | 渡劫丹 tribulationSuccess 0.05 |
| 4 | `lifespan_pill` 延壽丹（**門檻由 EAR1 改為 EAR4**） | 壽元 | 壽元 +10 年（依 `floor(total*(1+talent)+pill)`，pill 直加年數） | 靈草 25＋木 20＋金錢 30（既有成本，數值待核定） | 延壽丹 lifespanBoost 500（單位換算待核定） |

注意事項：
- `lifespan_pill` 目前在 EAR1 可煉；依使用者「EAR3 之後再開」，本提案改為 EAR4 門檻。這是 **v2 變更**，須在 rule-differences 記錄，並通知既有存檔行為（已煉成的延壽丹效果保留，不溯及清除）。
- 延壽數值 10 年為提案，legacy 500／1440 的單位與 v2 年數不一致，須依使用者「依目前壽命公式換算」再核定。
- 高階靈草與丹材（`spirit_grass_100y`、靈材、金丹渡劫丹）皆為既有或 Batch B 前置資源，依賴需確認。
- `golden_core_pill` 目前無服用效果；本提案不改其加工配方，Batch A 只在 §4 新增服用消費面，待核定。

## 5. 版本與記錄要求

- 丹藥數據遷出 `AlchemySystem.PILLS` 至資料檔（建議 `content/alchemy/pills.json`），保留既有三種丹 id 與數值，除非本表明確變更。
- 存檔：新增 `tribulation_seed`、`tribulation_roll_index`，屬 schema 升版；必須包含版本、故障復原與重試行為，測試用隔離資料。
- rule-differences 需新增：V2-019（丹藥分期與服用上限）、V2-020（渡劫基礎成功率與隨機種子）、V2-021（延壽丹門檻遷移）。
- **紀錄修正**：先前 scout 報告稱「V2-014 記錄丹藥產率 +10% 非 parity」，經核對 `docs/rule-differences.md:43` 的 V2-014 實為 RES1-A 加工政策（固定產量、原子成功、無 RNG），不涉丹效。因此 V2-014 保留不改；渡劫隨機性與丹效以新列 V2-019–V2-021 取代對應範圍，不改寫 V2-014 的加工政策內容。

## 6. 待使用者核定事項

1. 渡劫失敗後果（建議：不降階、消耗本次丹藥；舊版為降階＋清丹效）。
2. §4 各丹數值、EAR 門檻與成本（尤其延壽 10 年、速產丹 ×1.2、靈潮丹 ×1.5）。
3. `lifespan_pill` 由 EAR1 移至 EAR4 是否接受。
4. 實作順序仍為 Batch A → B → C；Batch A 實作前須先完成本表核定。

## 7. 驗證計畫（實作時）

- Headless 規則測試：`base(EAR)` 表、`bonus(n)` 遞減、`p` clamp、同 seed 重現、存檔往返、99 上限拒絕、限時 BUFF 取 max。
- 每次 `--import` 後單次 runner，exit 0，stderr grep `SCRIPT ERROR` 必須為空。
- 不宣稱真實瀏覽器、FPS 或觸控結果。
