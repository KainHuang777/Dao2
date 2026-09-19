# M1-B 執行計畫（fusion 簡報）

用途：供重啟後的 fusion 編排嚴格遵循。此檔是 M1-B 的凍結介面與規則來源；研究結論以本檔為準，必要時才重讀唯讀舊碼。對應 ROADMAP「M1-B — 統一時間與修行／壽元」。

## DoD（ROADMAP 原文）

- 交付可注入 Clock、整數 tick、TimeAdvancer、確定事件順序。
- 驗收：同命令時間點下，600 秒一次推進與分段結果一致；容量滿、缺料、到期、壽盡邊界正確；無加成 80／200／740 祀案例核對舊資料；升境不重置本世年齡。
- 在線由協調層提供經過時間，domain 不讀系統鐘；動畫或 FPS 不參與收益。暫未實作的丹藥／天時邊界不可宣稱通過。

## 核心時間常數（舊碼實證）

- `SECONDS_PER_TICK = 60`：`E:\Python\test1\src\balance\simulation\SimulationState.ts:21`。1 tick = 60 秒 = 1 年；60000ms = 1 年。
- 「祀」是舊版統一時間單位（= 年）。「80／200／740 祀」= Era 1／1–2／1–3 的累積壽元年（見下）。
- `computeProductionDelta(ratePerSecond, deltaSeconds) = Decimal(ratePerSecond) × deltaSeconds`：`src\balance\rules\production.ts`。

## 已驗證公式（Era1 投入前用 fixture 向量鎖定）

### 修練時間（LP-004）— `src\balance\rules\eraRequirements.ts`

- `computeCumulativeTrainingTime(a, r, n)`：r==1 → a×n；否則 a×(1−r^n)/(1−r)；結果為 −0 時回傳 0。
  - 向量：(10,1.5,0)=0；**(10,1.5,3)=47.5**。
- `computeSingleLevelTime(a, r, level)`：a × r^max(0, level−1)。
  - 向量：**(10,1.5,4)=33.75**。
- `applyTrainingTimeBonuses(raw, timeBonus, skillTimeMult, timeReduction)`：
  1. t = raw / (1 + timeBonus)
  2. t ×= max(0.1, skillTimeMult)
  3. t ×= max(0.1, 1 − timeReduction)
  - 向量：**(100,0.25,0.5,0.1)=36**；**(100,0,0.01,0.99)=1**。
- `computeSkillTimeMultiplier(skills)`：對 type=="time_reduction" 者累乘 `amount^level`（此處不套 0.1 下限）。
- `computeLevelUpResourceCost(amount, costReduction)`：`floor(amount × (1 − costReduction))`；Era9 的 `lv9Item` 同式（M1-B 不含 Era9）。
- `nextLevelRequiredSeconds`（`SimulationRunner.ts:1702`）：`applyTrainingTimeBonuses(computeSingleLevelTime(baseTime, timeMultiplier, eraLevel), 天賦+道心+道證加成, skillTimeMult, 0)`。無加成、無技能時 = `baseTime × timeMultiplier^(eraLevel−1)`。

### 壽元（LP-005）— `src\balance\rules\lifespanRules.ts`

- `getMaxLifespanSeconds({eras, eraId, talentBonus=0, pillBonus=0})`：
  - eraId = max(1, floor(eraId))；`totalYears += Σ_{i=1..eraId} (eras[i].lifespan 若存在且>0，否則 i==1?80:i×100)`。
  - `maxYears = floor(totalYears × (1+talentBonus) + pillBonus)`；回傳 `maxYears × 60`（秒）。
  - 向量（eras=[{1,80},{2,120},{3,540}]）：era1=**4800**；era2 + talent 0.1 + pill 5 =**13500**；era4 fallback（i=4 → 400）=**68400**。
  - 累積年：Era1=**80**、Era1–2=**200**、Era1–3=**740**（= ROADMAP 的 80／200／740 祀）。
- 壽盡判定（`SimulationRunner.ts:522-529`）：每 tick `totalElapsedSeconds += 60`，若 `isFinite(max) && totalElapsedSeconds >= max` → 壽盡。**升境（`era+=1`）只重設 eraLevel 與 trainingSeconds，不重設 totalElapsedSeconds**（`SimulationRunner.ts:403-405`）；只有輪迴才 `totalElapsedSeconds = 0`（`:581`）。

### 容量容差（LP-003）— `eraRequirements.ts:158`

- `checkCapacityRequirements(capacityReqs, currentMaxByResource)`：鍵去 `_max`；`current < required − 0.1` 才算缺口。
  - 向量：{lingli_max:500} vs lingli 499.89 → 缺口；{lingli_max:500, stone_low_max:1000} vs lingli 499.9, stone_low 1000 → 無缺口。
- **LP-003 的 v2 精確語意仍待本任務以 Amount 比較落地**：不可直接沿用 float `−0.1`；需在 rule-differences 記錄等價判定與容差。

### 每 tick 步驟（舊版 `SimulationRunner.applyTick`，M1-B 取確定性子集）

舊版順序（`SimulationRunner.ts:4-15` 註解 + 實作）：策略 → 解鎖資源 → 產量累加 → 容量 clamp → 修練累加與自動升級 → 突破 → Era++ → 停滯。壽元判定在 7.5。

- 產量（`:275-325`）：對每個**已解鎖**資源：`total = (base_rate × era.resourceMultiplier + 建築 rate 加成) × (1 + 道心加成 + 全域天賦加成)`；`resources += total × 60`（Decimal）。`lingli` 另扣 `computeLingliMaintenance(era, eraLevel)`（M1-B 範圍外，Era1 無維持資料，標記不實作）。
- 容量 clamp（`:327-340`）：`have > cap` → 設為 cap（溢出可記錄），`have < 0` → 0。
- 修練（`:342-394`）：`trainingSeconds += 60`；若 `eraLevel < maxLevel` 且 `trainingSeconds >= required && required > 0`，且前置與資源足夠 → 扣料、`eraLevel += 1`、`trainingSeconds = 0`。資源不足則**不升級、不歸零**（時間持續累積）→ 即「缺料」邊界。
- 突破／Era++：M1-B 只做「升境不重置年齡」的年齡語意；完整突破判定屬後續。

## Era 內容（**scout 必查，目前未固定**）

M1-B 需要 Era 資料：`maxLevel`、`levelUpRequirements{baseTime, timeMultiplier, resources{}, capacity{}}`、`resourceMultiplier`、`lifespan`。M0-B fixture 只固定了 `lifespan`（80/120/540）。**Era1 的 baseTime／timeMultiplier／levelUp resources 尚未抽出**。

- scout 任務：從 `E:\Python\test1` 的 Era CSV／`EraData` 抽出 Era1（必要時 Era2–3 的 lifespan）值，附檔名與行號，並與 fixture 交叉核對。
- 後續：新增 `content/eras/era1.json` 並納入 manifest 與 `content_version`；`ContentLoader` 擴充驗證（era 欄位、levelUp resources 引用資源存在）。此為 orchestrator 擁有。

## 凍結介面（workers 必須完全照用）

### `src/simulation/game_clock.gd`（class_name GameClock）— worker-a

- `var utc_seconds: float`
- `static func create(initial_utc_seconds: float) -> GameClock`
- `func now() -> float`（只回傳注入值，**不得**呼叫系統時鐘）
- `func advance(seconds: float) -> float`（累加並回傳新值；負值忽略）
- `func set_now(value: float) -> void`

### `src/simulation/time_advancer.gd`（class_name TimeAdvancer）— worker-a

- `const SECONDS_PER_TICK := 60`
- `static func ticks_for_elapsed(elapsed_seconds: float) -> int`（floor；<0 → 0）
- `static func advance(state: GameState, content: GameContent, ticks: int) -> Dictionary`
  - 回傳 `{"ticks_advanced": int, "events": Array, "changed_ids": Array, "stopped": String|null}`
  - 每 tick 固定順序：① 產量累加 ② 容量 clamp ③ 修練累加與自動升級（缺料則不升級）④ `total_elapsed_seconds += 60` 後判壽盡（`>=` 即 `lifespan_exhausted`，設 `stopped` 並停止）。
  - 事件為 Dictionary `{kind, ...}`，kind 至少：`resource_produced`／`level_up`／`lifespan_exhausted`；順序確定。

### `src/simulation/cultivation.gd`（class_name Cultivation）— worker-b

- `static func cumulative_training_time(base_time: float, time_multiplier: float, current_level: int) -> float`
- `static func single_level_time(base_time: float, time_multiplier: float, current_level: int) -> float`
- `static func apply_time_bonuses(raw: float, time_bonus: float, skill_time_mult: float, time_reduction: float) -> float`
- `static func skill_time_multiplier(skills: Array) -> float`
- `static func next_level_required_seconds(era_def: Dictionary, era_level: int, time_bonus: float, skill_time_mult: float) -> float`
- `static func level_up_cost(era_def: Dictionary, era_level: int, cost_reduction: float) -> Dictionary`（值為 `AmountCompat`）

### `src/simulation/lifespan.gd`（class_name Lifespan）— worker-c

- `static func max_lifespan_seconds(eras: Array, era_id: int, talent_bonus: float = 0.0, pill_bonus: float = 0.0) -> float`
- `static func is_exhausted(total_elapsed_seconds: float, max_lifespan_seconds: float) -> bool`（需 `is_finite` 且 `>=`）

### `tests/m1b_time_runner.gd` — worker-d（SceneTree runner，範本見 `tests/m1a_core_runner.gd`）

至少涵蓋：修練四向量與 single/cumulative；壽元三向量與累積 80/200/740；`ticks_for_elapsed`；600 秒一次 vs 10×60 秒分段 → `to_snapshot_dict()` 相等；容量滿 clamp；缺料（時間足但資源不足）不升級且 training 持續累加；壽盡邊界（`==` 即觸發）；升境不重置 `total_elapsed_seconds`；確定性（兩次相同序列相等）；掃描 `src/domain`、`src/simulation` 無 `Time.`／`OS.` 系統時鐘呼叫。

## 檔案所有權分割（單一寫者）

| 擁有者 | 檔案 |
| --- | --- |
| worker-a | `src/simulation/game_clock.gd`、`src/simulation/time_advancer.gd` |
| worker-b | `src/simulation/cultivation.gd` |
| worker-c | `src/simulation/lifespan.gd` |
| worker-d | `tests/m1b_time_runner.gd` |
| orchestrator | `src/domain/game_state.gd`、`src/application/game_session.gd`、`content/**`、`src/content/content_loader.gd`、`docs/**` |
| scout | 唯讀（僅回報） |

GameState 新增（orchestrator）：`training_seconds: float = 0.0`、`total_elapsed_seconds: float = 0.0`，並納入 `to_snapshot_dict()`。GameSession 新增（orchestrator）：`advance_time(elapsed_seconds: float) -> Dictionary`（以 `TimeAdvancer.ticks_for_elapsed` 轉整數 tick，套用後 revision+1），`get_view()` 增加修練進度、`total_elapsed_seconds`、`max_lifespan_seconds`。

## 驗收命令（orchestrator 執行一次，序列化）

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
$out = & $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd 2>&1
$code = $LASTEXITCODE
$out | Out-File -Encoding utf8 'C:\Users\asus\AppData\Local\Temp\opencode\m1b_run.txt'
"EXIT=$code"
# 必須：EXIT=0、輸出含 PASS 行、且無 "SCRIPT ERROR"（SCRIPT ERROR 不計入 runner failures）
```

## 未定項（scout 先解）

1. Era1 `baseTime`／`timeMultiplier`／levelUp resources／maxLevel／resourceMultiplier（決定修練與升級向量）。
2. 「到期」的舊版語意（疑似「修練時間到期」或某計時到期）；需在舊碼確認，不可臆測。
3. `computeLingliMaintenance` 是否屬 M1-B（傾向範圍外，Era1 無資料）；需明示不實作且不宣稱通過。
4. 未移植的丹藥／天時／突破邊界須在 `docs/verification/m1-b.md` 列為未實作。
