# MAID-CORE-1 驗收紀錄

- 日期：2026-11-01
- 級別：L1（核心與受影響領域），另加一組共用核心 runner；**未跑 L3**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 設計：[docs/49](../49-maid-companion-system-design.md)

## 交付

- `src/simulation/maid_rules.gd`：三角色、羈絆門檻、九章、職掌節奏與上限常數。
- `src/simulation/maid_system.gd`：招募、職掌指派／暫停／清除／立即執行、章節領取、輪迴重逢、`advance`、跨世暫停、唯讀 View。
- `src/persistence/maid_save_contract.gd`：`state.maid` 嚴格驗證與正規化，上限 16384 bytes；不修復非法資料。
- `src/domain/game_state.gd`：新增可選 `maid` 區塊，加入 duplicate／snapshot。
- `src/persistence/save_codec.gd`：encode 驗證、decode 可選解析；schema 維持 6。
- `src/application/game_session.gd`：7 個命令、shape 檢查、View `maid`、`advance_time` 線上推進。
- `src/simulation/command_processor.gd`：7 個命令分派與酬載型別檢查。
- `src/persistence/sect_reform_save.gd`：7 個命令納入 release 候選交易白名單。
- `src/simulation/reincarnation_rules.gd`：輪迴時暫停職掌、設定重逢旗標，羈絆與章節保留。
- `src/presentation/maid_character_panel.gd`：四分頁、角色選擇、職掌／羈絆操作與 View 刷新；糯美子／丹霞立繪與 CG 佔位。
- `src/presentation/feature_navigation.gd`：標準命令信封、存檔、刷新、結果回饋。
- `tests/maid_core_runner.gd`、`tests/maid_ui_runner.gd` 更新；`tools/run_all_runners.ps1` 登錄新 runner。

## 命令與結果

1. `Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。
2. `--headless --path E:\WORK\Dao2 --import` → exit 0，無 SCRIPT ERROR。
3. `--script res://tests/maid_core_runner.gd` → `MAID-CORE checks=172 failures=[]`，`RUNNER_RESULT status=PASS exit=0`。測試含規則、契約、View、招募、單一職掌、備料／監造／煉丹、輪迴、章節、決定性、保存與 session 整合。刻意輸入 NaN 的契約測試會產生無害 JSON 警告。
4. `--script res://tests/maid_ui_runner.gd` → `MAID-UI checks=37 failures=[]`，exit 0。
5. `tools\run_all_runners.ps1 -Only 'maid_core_runner.gd,maid_ui_runner.gd,feature_navigation_runner.gd,ui_shell_policy_runner.gd'` → 4/4 PASS，matrix=single 1280×720。
6. 共用核心受影響組：`sect_reform_release_runner.gd,sect_reform_save_runner.gd,m1c_persistence_runner.gd,m3a_reincarnation_runner.gd,life_ledger_runner.gd,content_p2_talents_runner.gd` → 6/6 PASS。

## 邊界與未驗證

- 職掌自動化 v1 只在 `GameSession.advance_time` 線上推進；離線結算不執行職掌，跨世預設暫停並等待重逢確認。屬明確 v1 邊界，不是 DAO1 interval 的 parity。
- 未新增被動產量倍率、天賦 ID、宗門 token／市集品、靈獸槽或好感貨幣。
- 糯美子／丹霞立繪與初遇 CG 尚未交付，介面顯示待 Codex 補完；不由程式捏造美術完成。
- 未跑全尺寸矩陣、Web 匯出、桌面瀏覽器或觸控實機；不宣稱 L3 或瀏覽器互動通過。
- release 候選存檔路徑（`SaveManager.submit_sect_reform`）只驗證了命令已列入白名單與既有交易 runner 不回歸；本次沒有在 release 候選路徑下實際執行仙侍命令或做真實重載，列為未驗證。
- `set_duty_paused`、`clear_duty`、`claim_chapter`、`reunion` 的直接命令與 session 包裝僅有部分核心測試覆蓋；UI 未模擬 `action_requested` 的完整 payload 矩陣。
