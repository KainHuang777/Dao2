# RES1-E SKS-P1 驗收：`golden_core_formation`（結丹法）承接

日期：2026-10-18（fusion 技能執行輪）。任務 ID：`SKS-P1`（[docs/21 批次 B1](../21-res1-e-skills-expansion-plan.md)）， 使用者核定 P3-1。源頭契約：[ADR-012](../decisions/ADR-012-optional-skills-with-islands.md)、 來源稽核 `docs/verification/artifacts/res1-d1-source-audit.json:83-94`。

## 交付範圍（凍結數值）

- `content/skills/era3.json`（新）：`golden_core_formation`／結丹法，era 3、requires `foundation_building:1`、max_level 5、cost 7650 skill_point/級、effect `time_multiplier` amount 0.9（×pow(0.9,N) 訓練時間）。舊版欄位 `effect_type time_reduction` 記為 legacy parity 對照，見 [rule-differences](../rule-differences.md)。
- `src/simulation/skill_system.gd`：VERSION 2、CONTENT_TAG `+skills-p1`、SUPPORTED_VERSIONS `[0,1,2]`、EFFECTS 新增 `time_multiplier`；attach 併載 era2.json＋era3.json（幂等）；新 def 欄位 `era`（預設 2）與 `requires {skill_id, level}` 校驗（值存在、level 未超目標 max_level）；learn() 閘序 study > era > prereq > max_level > unlock/點數；view() 理由同序；`SKILL_ERA_LOCKED`／`SKILL_PREREQ_LOCKED`；`_effect_text` 顯示「修煉時間 ×%.3f」；validate() limits 含 `golden_core_formation:5`。
- 訓練時間接線（僅 3 個正式呼叫點，皆以 `SkillSystem.effect(content, state.skills, "time_multiplier")` 作 skill_time_mult）：`src/application/game_session.gd`（view next_required）、`src/simulation/command_processor.gd`（_apply_level_up 與 _apply_consume_pill 訓練上限）。`cultivation.gd` 未改（`time_reduction` 參數維持 0.0）；fixture helpers（hud_readiness_acceptance.gd:14、pacing_sim.gd:175）維持 (0.0,1.0)。離線封閉式與 time_advancer 皆走同一 next_level_required_seconds 通道，線上／離線一致；訓練入帳（training_speed）通道未動。
- `src/persistence/save_codec.gd`：RULES_VERSION `core-flow-12-skills-p1`；decode 接受 skill_version ∈ [0,1,2]、skills ≤ 7、supported 增 `golden_core_formation:5`，再雙重過 `SkillSystem.validate`。save_manager 的 reconcile→archive（`save_before_skills_<sha256>`）→寫讀校驗→retry 機制沿既有實作，未改檔。
- `src/presentation/skill_study_view.gd`：按鈕文案 SKILL_ERA_LOCKED→「境界未達」、SKILL_PREREQ_LOCKED→「前置未足」＋TIP 變體；無專圖時沿用既有 graceful 無紋理路徑。
- 回歸更新：`tests/skills_b1_runner.gd`（7 defs/version 2/8 按鈕、金丹在 Era2 流程跳過）、`tests/uix_r8_skills_ui_runner.gd`（7 卡／8 按鈕、金丹豁免專圖檢查、last action 指向金丹卡）、`tools/run_all_runners.ps1` 註冊 `tests/sks_p1_runner.gd`。

## 執行方式（fusion）

主控拆解並凍結介面後派工：Worker-A 產 `tests/sks_p1_runner.gd`（11 段 58 checks）； Worker-B 產 `content/skills/era3.json`＋manifest 條目＋`docs/verification/artifacts/uix-r8/golden_core_formation-prompt.txt`。共用檔（skill_system／save_codec／3 個時間呼叫點／view／既有 runner 計數／runner 註冊）僅主控編輯。fusion-auditor 獨立對照 DoD 逐點審查：9/9 PASS，確認 Era3 突破閘 `_apply_breakthrough` 不受技能影響（突破契約互不借用成立）；審查發現 game_session.gd 內另有 `training_complete`／`level_up_missing_resources`／AFFORD_TOLERANCE hunks，經溯源屬既有 HUD-F1-PROGRESSION-LIFE dirty work（[記錄](../ai-handoff.md) 2026-10-17 條目），非本批變更。

## 命令與結果（PowerShell 5.1，引擎 .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe）

1. `--headless --import`（資源匯入通過；docs/verification/artifacts/uix-r10 內既有損毀 PNG 為先前輪次無關診斷，保留）。
2. `& <engine> --headless --path . --script res://tests/sks_p1_runner.gd` → `PASS: SKS-P1 58 checks`，exit 0，輸出無 SCRIPT ERROR（log：`build/sks_p1.log`）。涵蓋：attach 幂等／7 defs、era/prereq 鎖與 view 理由、7650 扣費且 receipt 重放不重扣、滿級 5、時間對照 `base*pow(0.9,N)`（N=1/2 各一次實際 reduced-requirement 晉階成功）、丹藥上限 clamp 至縮減後需求且超出拒絕、存檔 v2 往返＋decode 拒未知技能、v1→v2 遷移（revision+1、archive 鍵寫／讀回／失敗保槽／重試，重啟後遷移）、輪迴清除技能點、R8 面板 7 卡／8 按鈕、鎖定文案與禁用。
3. `tests/skills_b1_runner.gd` → `PASS: SKILL-B1 41 checks`，exit 0，無 SCRIPT ERROR（log：`build/skills_b1.log`）。
4. `tests/uix_r8_skills_ui_runner.gd` → 首跑 101 checks 全數失敗（old last-action 指針未指向第 7 張卡），修正為指向 `golden_core_formation.action` 後重跑 `UIX-R8 101 checks failed=false`，exit 0，無 SCRIPT ERROR（log：`build/uix_r8_rerun.log`）。首跑失敗屬回歸更新缺陷而非規則錯誤，如實保留。

## 限制與待驗（不得宣稱已通過）

- **金丹題材圖尚未生成**：manifest 條目 `status: "pending_art"`、不虛列 sha256；提示詞已存 `artifacts/uix-r8/golden_core_formation-prompt.txt`。View 無紋理時 graceful（既有路徑）。圖標待 ImageGen 生成＋人工美術接受後補 manifest 校驗欄 — 美術待生成／待接受，非本批程式 DoD 阻擋。
- 本輪僅 headless CLI 證據；未重跑兩版 Web 匯出／壓縮／字型 check／桌面三橫式瀏覽器互動（依 docs/21 共通約束屆時與批次集中驗證，或下個里程碑回報）。
- 觸控／實機依 2026-10-17 指令延期，非當前阻擋。
- 既有退出 Font／CanvasItem／ObjectDB 診斷保留，未宣稱零錯誤 log。
