# 交接：前期節奏檢查機制（交 Opencode）

日期：2026-10-11。狀態：**腳本已寫、未執行、未驗證**。本階段不改任何遊戲數值。

## 背景與核定計畫
使用者要求先建立「前期數值節奏檢查機制與公式」，再調參。核定計畫見對話 artifact `implementation_plan.md`（C1–C10 檢查項、雙策略模擬）。使用者後來指示：此處不執行，由 Opencode 接手。

## 已存在的檔案（未跑過，可能有 GDScript 小錯）
| 檔案 | 用途 |
| --- | --- |
| `src/utils/pacing_metrics.gd` | 純公式（無 class_name，用 preload） |
| `src/utils/pacing_sim.gd` | Era1 積極／放置雙策略 bot，只用真實 `GameSession` 命令 |
| `tools/early_pacing_targets.json` | 門檻與假設（2 點擊/秒、300 秒回訪、20 次回訪點擊） |
| `tools/early_pacing_audit.gd` | 報告模式審計，輸出 `docs/verification/early-pacing-baseline.md/.json` |

## 任務清單
1. **首跑**：`.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/early_pacing_audit.gd`。修正語法／型別錯誤（常見風險：`Dictionary` 取值型別推導、`content.era()` 在 Era3 未附掛時為 null、get_view 呼叫次數造成模擬變慢）。若首次因 import 缺 `.uid` 失敗先跑 `--import`。
2. **單測** `tests/early_pacing_runner.gd`（加入 `tools/run_all_runners.ps1`）：
   - 公式：`gain_ratio(5,7)=0.4`、`delay_loss(2,300)=600`、`overflow_ratio(100,5,300)=1-100/1500`、`cap_pressure`、`afford_seconds` 邊界。
   - 與正式規則一致：`Production.compute_rates` 的 hut L2 = `0.3*(2+1)^1.5`；`BuildingCosts.compute_cost` hut(L0, onboarding)=20 lingli；`Metrics.chain_training_seconds(60,1.15,10)` ≈ 1007。
   - 模擬 smoke：`Sim.new(content).run("active", {...max_seconds:120...})` 不報錯且 purchases ≥ 1。
   - 基線階段門檻**只回報不阻擋**（audit 預設 exit 0；`-- --enforce` 才阻擋）。
3. **產出基線報告**並核對假設：Era1 練氣 17 分／築基 41.6 分純時鐘；蓋完新手鏈後 gate 無關 headroom 佔比；C7 積極／放置倍率；C9 可縮短比例；C10 Era2 島嶼 sink 耗盡時間與是否被關卡需要。
4. **回報**：更新 `docs/development-status.md`、`updata.txt`（英文置頂）；把基線結論與建議的調參方向（見下）整理成提案，待使用者核定後再改數值。

## 第二階段調參方向（尚未核定，勿實作）
- Era1 升層成本加入木／石／草（如 Lv3 起需木、Lv5 起需石、Lv7 起需草），讓建築線成為主流程。
- 讓主動消耗（運功／灌注／聚靈丹）可換修煉秒數，並避免滿額浪費；注意升層會把 `training_seconds` 歸零（多餘聚靈丹浪費）。
- Era2：島產出→運輸→家園消耗成鏈；升設施有明顯回饋；補中段 sink。

## 待使用者回答（預設值已寫入 targets.json）
1. 目標時長：練氣／築基 LV10 各幾分鐘（現約 17／42）。
2. 是否允許變更修煉規則（v2 差異，舊檔相容另議）。
3. 積極點擊速率與放置回訪間隔假設是否合理。

## 限制與注意
- 靜態表以「新手鏈完成」為參考狀態，早期建設期請看模擬結果。
- 島嶼分析是靜態估算，未跑 Era2 模擬。
- 遵守規範：不用 browser_subagent；測試用 headless 腳本。
