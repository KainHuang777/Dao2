# M1-B 驗收紀錄｜統一時間與修行／壽元

日期：2026-09-16。狀態：**DONE**（有明確未實作邊界）。執行方式：fusion 編排（deepseek-v4.1-flash 主導，輕量 worker 並行，auditor 獨立稽核）。

## 目標與邊界

交付可注入 Clock、整數 tick、TimeAdvancer、確定事件順序與修行／壽元規則。不含突破與升境判定、離線收益（M1-D）、快照儲存（M1-C）、維持費與丹藥／天時。

## 產物

- `src/simulation/game_clock.gd`：可注入 `GameClock`（只讀注入值，不呼叫系統時鐘）。
- `src/simulation/time_advancer.gd`：`SECONDS_PER_TICK=60`、`ticks_for_elapsed`、`advance(state, content, ticks)`，事件與變更順序確定。
- `src/simulation/cultivation.gd`：累積／單級修練時間、加速套用、技能時間乘數、各級所需秒、升級費用。
- `src/simulation/lifespan.gd`：`max_lifespan_seconds`（含 fallback）、`is_exhausted`（inclusive `>=`）。
- `content/eras/era1.json`＋manifest `era_files`；`GameContent`／`ContentLoader` 擴充 era 定義與引用驗證；`Production.compute_rates` 增 `resource_multiplier`。
- `src/domain/game_state.gd`：新增 `training_seconds`、`total_elapsed_seconds`（入 snapshot）。
- `src/application/game_session.gd`：`clock`＋`advance_time(elapsed_seconds)`（floor 轉整數 tick、revision+1）、`get_view` 擴充修練進度／壽元／era。
- `tests/m1b_time_runner.gd`：契約測試。

## 驗收環境與命令

```powershell
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --headless --path . --import
& $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd
```

2026-09-16 實測：`--import` 退出碼 0；runner 退出碼 0，輸出 `PASS: M1-B clock, ticks, cultivation, lifespan, boundaries, determinism.`，無 `SCRIPT ERROR`、無 FAIL。

## DoD 對照

| 驗收 | 證據 |
| --- | --- |
| 可注入 Clock、整數 tick、TimeAdvancer、確定事件順序 | `game_clock.gd`；`time_advancer.gd` 每 tick 固定序：產量→容量 clamp→修練→升級→`total_elapsed += 60`→壽盡判定 |
| 600 秒一次 vs 分段一致 | runner `SEGMENTED EQUALS ONCE`：單次 600s 與 10×60s 的 snapshot（除去 revision）相等 |
| 容量滿 | `CAPACITY CLAMP`：hut=1 容量 250，長時間推進後值為 250 |
| 缺料 | `INSUFFICIENT RESOURCE`：時間足（300s）但 lingli 0 < 50 → 不升級、`training_seconds` 保留 300 |
| 到期（v2 釋義＝修練時間達到需求） | `LEVEL UP CONSUMES AND RESETS TRAINING`：達需求且可負擔 → 升級、歸零、扣料 |
| 壽盡 | `LIFESPAN EXHAUSTED BOUNDARY`：79 tick 不停、80 tick（=4800 秒）觸發 `lifespan_exhausted`、超量請求於 80 tick 停止 |
| 80／200／740 祀 | `LIFESPAN VECTORS`：4800／12000／44400 秒＝80／200／740 年 |
| 升境不重置本世年齡 | `AGE NOT RESET`：升級後 `total_elapsed_seconds` 由 1000 → 1060（未歸零） |
| domain 不讀系統鐘 | `NO SYSTEM CLOCK`：掃 `src/domain`、`src/simulation` 無 `Time.`／`OS.` 字符 |
| 修練公式 parity | `TRAINING VECTORS`：累積 47.5、單級 33.75、加速 36／1、Era1 單級 60/69/79.35/91.2525/104.940375/120.6814313/138.783646/159.6011929/183.5413718 |
| 頂級邊界 | `MAX LEVEL NO LEVEL UP`：level 10 時不升級、不歸零、無 `level_up` 事件 |
| 確定性 | `DETERMINISM`：相同序列兩 session 的 snapshot 與 view 相等 |

Era1 內容（`content/eras/era1.json`）對照唯讀來源 `E:\Python\test1\src\data\eras.csv`（SHA-256 `E71F03ABD8755993FF874B5CBD2C9ED7B428423BC455D3C44950EB715DECA404`）：maxLevel 10、baseTime 60、timeMultiplier 1.15、levelUp resources {lingli:50}、resourceMultiplier 1、lifespan 80、upgradeRequirements.capacity {lingli:500}。

## 未實作／不宣稱

1. 突破與升境（era++）判定未實作；`upgrade_requirements.capacity`（Era1 lingli 500）已載入與驗證，但**無升境路徑消耗**，LP-003 的容差 0.1 精確語意留 M2-B。
2. `resourceMultiplier`（Era1=1）只在核心產率路徑套用；Era1 無差別。
3. 維持費、丹藥／天時、`lv9Item`（Era1 無）、技能時間乘數來源（無技能內容）未接入，不得宣稱通過。
4. 訓練溢出採「升級時歸零、捨棄超出該級需求的部分」（舊 simulator 模型），非 runtime 的累積門檻模型；已記為 V2-005。
5. headless 契約測試非瀏覽器互動或畫面證據。
