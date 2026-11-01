# MAID-CORE-2 驗收紀錄

- 日期：2026-11-01
- 級別：L1（核心與離線領域，單一 1280×720）；**未跑 L3**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 設計：[docs/49 §11](../49-maid-companion-system-design.md)
- 規則差異：[V2-MAID-CORE-2](../rule-differences.md)

## 交付

- `src/simulation/maid_rules.gd`：新增 `MAX_ACTIONS_PER_CALL := 5`。
- `src/simulation/maid_system.gd`：`advance(content, state, ticks, max_actions)` 改為必填預算，內部 `clampi(max_actions, 0, MAX_ACTIONS_PER_ADVANCE)`；`max_actions <= 0` 直接回空、不扣冷卻；新增純函式 `offline_report(events)`。
- `src/simulation/offline_settlement.gd`：時間結算完成後，`full_ticks > 0` 且 `stopped == null` 時呼叫一次 `MaidSystem.advance(..., MaidRules.MAX_ACTIONS_PER_CALL)`；0 次時不附加 `report.maid`。
- `src/application/offline_coordinator.gd`：`compute_async` 同位置、同參數呼叫一次。
- `src/application/game_session.gd`：線上呼叫改傳 `MaidRules.MAX_ACTIONS_PER_CALL`。
- `src/presentation/offline_summary.gd`：有 `maid` 鍵時在「目前年歲」與「停止原因」之間加一行「仙侍職掌：離線完成 %d 次」；0 次輸出逐字不變。
- `tests/maid_offline_runner.gd`：新增，62 checks。
- `tests/maid_core_runner.gd`：更新 `advance` 呼叫並加預算案例，179 checks。
- `tests/m1d_offline_runner.gd`：加離線職掌案例（12h／暫停／缺區塊／壽元停止／轉世暫停／24h 上限）。
- `tests/offline_closed_form_parity_runner.gd`：`manual_settle` 同步加入職掌呼叫並加仙侍 parity 案例。
- `tools/run_all_runners.ps1`：登錄 `tests/maid_offline_runner.gd`。
- 紅線未動：`save_codec.gd`、`save_manager.gd`、`maid_save_contract.gd` 零變更。

## 命令與結果

1. `tools\run_all_runners.ps1 -Only 'maid_core_runner.gd','maid_offline_runner.gd','m1d_offline_runner.gd','offline_closed_form_parity_runner.gd' -TimeoutSeconds 180` → 4/4 PASS，matrix=single 1280×720。
2. `maid_core_runner.gd` → `MAID-CORE checks=179 failures=[]`，exit 0。
3. `maid_offline_runner.gd` → 62 checks、failures=[]，exit 0。
4. `m1d_offline_runner.gd` → exit 0。
5. `offline_closed_form_parity_runner.gd` → `PASS: OFFLINE_CLOSED_FORM_PARITY 16 checks`，exit 0。

## 邊界與未驗證

- 離線職掌在時間結算後一次執行，不與時間交錯，**不宣稱與線上逐 tick 等價**；經濟已展開時只記派工，成品於回線後才完成。
- `MAX_ACTIONS_PER_CALL` 是平衡常數，體感平衡仍待實機後調整；測試一律讀常數。
- 本次 `offline_closed_form_parity_runner` 約 80–90 秒，為既有 48h 參考結算成本；L1 以 `-TimeoutSeconds 180` 執行，未改動其他 runner 的預設 45 秒。
- 未跑全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機；不宣稱 L3 或瀏覽器互動通過。
