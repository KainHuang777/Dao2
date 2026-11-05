# MAID-VOICE 驗收紀錄

- 日期：2026-11-04
- 級別：L1／L2（仙侍＋引導受影響 runner 群，單一 1280×720）；**未跑 L3／全尺寸矩陣／Web 匯出**
- 引擎：Godot `4.7.2.stable.official.ed1daf0bf`
- 設計：[docs/49 §19](../49-maid-companion-system-design.md)
- 執行方式：fusion skill（worker A：仙侍文案；worker B：引導頭像語音；orchestrator：fuse、修正、引擎驗證）

## 交付

### 仙侍互動語音（worker A，orchestrator 驗證）

- `src/simulation/maid_rules.gd`：每位仙侍新增第四章收束章節——青蘅 `qingheng_4`「燈影同行」（羈絆 90、職掌動作 20 次）、糯美子 `nuomeizi_4`「以劍為盟」（90、15 次）、丹霞 `danxia_4`「同守一爐」（90、20 次）。首次職掌 10＋20＋30＋50＋90＝200，`同道`（200）門檻首次可達；`BOND_LEVELS` 未動。
- `src/presentation/maid_character_panel.gd`（1364→1515 行）：
  - 章節列 `for index in 3:` → `for index in 4:`；`BOND_SCRIPT` 補 `*_4` 三份腳本（兩行開場、兩選項、各分支回應、共同結語），標題與 `MaidRules.CHAPTERS` 一致；`BOND_CG` 不變（回憶按鈕沿用最後一行泛用綁定，移至第四章列）。
  - 新增常數 `VOICE_LINES`（7 種命令 × 3 位仙侍＝21 句，皆 ≤22 字）、`GREETINGS`／`DUTY_GREETINGS`（各 4 句，依 `bond_name` 初識／相知／信任／同道分層）、`REUNION_LINES`（每位一句，取代 `REUNION_LINE`）。
  - 新增 `static func voice_line(kind: String, maid_id: String) -> String`（未知種類／角色回空字串）；人物頁新增依羈絆分層的問候列（緊湊版面相容），重逢列跟隨所選角色。
- `src/presentation/feature_navigation.gd`：`_on_maid_action` 成功訊息改為 `voice_line(kind, maid_id)` 的角色語音（非空時覆蓋），失敗／錯誤映射與 `play_first_meeting` 流程不變；青蘅指派語音以「職掌已指派」開頭，保留 `maid_ui2_runner` 既有 prefix 釘選。

### 新手引導侍女頭像與語音（worker B，orchestrator 驗證）

- `src/presentation/abode_hud_controller.gd`（1423→1526 行）：
  - 新增 `GUIDE_VOICE`（21 鍵：era1 八項、F1–F7、G1–G4、complete、legacy，皆 ≤30 字且互異）、`GUIDE_PORTRAIT`（`assets/characters/qingheng/portrait.png`）、`GUIDE_NAME`（青蘅）。
  - 訊息面板標題列（`hint_title_row`）在 `hint_heading` 前加入 40×40 頭像與 15px 名籤；子順序為頭像→名籤→標題→展開→收起。
  - `_update_guide_presence(view)`：只在青蘅已招募且頭像載入成功時顯示並說話；`_guidance_voice_key(view)` 取 `early.step`／`early.route`／era1 `cultivation`；`_speak_guidance_voice(key)` 以 `青蘅：「…」` 推入 `_push_hint_log`，以 `_last_voice_key` 去重；`_rebuild_hint_log_display` 新增首分支 `青蘅：「` → 色 `6b4a7a`，既有分支優先序不變。
  - 鉤子：`_refresh_hud` 於 `_update_onboarding_guidance` 前呼叫 presence；early 分支、完成路徑、建築分支的 key 變更處各呼一次語音。未知鍵（H1–H6、F9 等）靜默略過。
  - 凍結面：`hint.text`／`hint_heading` 所有字串與改前逐位元組相同。
- orchestrator 修正：`_speak_guidance_voice` 內誤引用不存在的 `GUIDE_MID` → 改為 `_guide_maid_id != "qingheng"`（引擎跑前攔截的解析錯誤）。

### 測試

- 新增 `tests/maid_voice_runner.gd`（248 checks）：規則面（第四章 id／羈絆 90／合法條件種類）、12 份 `BOND_SCRIPT` 形狀與文案兩兩互異、`GREETINGS`／`DUTY_GREETINGS`／`REUNION_LINES` 互異、`voice_line` 7×3 決定性＋未知回空（以 Script 資源直接呼叫證明靜態）、UI 分層問候／職掌切換／重逢跟隨。
- 新增 `tests/maid_guidance_voice_runner.gd`（46 checks）：未招募隱藏、真實建房＋`recruit_maid` 後頭像可見且僅一條語音、同 view 重刷不重複、合成 F2 逐字對表、未知 F9 不推送、標題字串凍結、子順序。
- `tests/maid_bond_chapter_runner.gd` 46→49 個 `check()` 呼叫（176 checks）：章節數 4、第四章列／重溫／回憶、記憶按鈕移至 row3。
- `tests/maid_bond_cg_runner.gd` 25→26 個 `check()` 呼叫（71 checks）：終列 index 3、`id+"_4"`、`_prepare` 補 `duty_actions = 20`、先領 `_3` 再領 `_4`。
- `tests/maid_core_runner.gd:80`：`size() == 3` → `size() == 4`（三→四章）。
- `tests/maid_first_meeting_runner.gd:65`：招募回饋釘選 `仙侍已入府。` → `已入府。案上那盞燈，替您亮著。`。
- `tools/run_all_runners.ps1`：登錄 `tests/maid_voice_runner.gd`、`tests/maid_guidance_voice_runner.gd`。
- 紅線未動：`maid_system.gd`、`maid_save_contract.gd`、`onboarding.gd`、`save_codec.gd`、`SCHEMA_VERSION` 零變更；章節旗標鍵集逐 id 對 `MaidRules.chapter()` 驗證，新增章節 id 對舊存檔向後相容。

## 命令與結果

1. `Godot --headless --path . --import` → exit 0（僅既有無關警告：`src/verification/r7f5b` 內另有 project.godot）。
2. `tools\run_all_runners.ps1 -Only 'maid,m2d_responsive,gather_guidance' -List` → 14 支（12 支 maid＋`gather_guidance_highlight`＋`m2d_responsive_ui`）；>5 支依 AGENTS.md 以共用核心（`maid_rules.gd` 餵全部 maid runner、`abode_hud_controller.gd` 餵引導 runner）認定為 L2 領域級。
3. 首輪 `tools\run_all_runners.ps1 -Only 'maid,m2d_responsive,gather_guidance' -TimeoutSeconds 120` → 11/14 PASS、3 FAIL，無 SCRIPT ERROR：
   - PASS：MAID-UI 53、MAID-CORE 266、MAID-OFFLINE 62、MAID-UI2 62、MAID-DUTY-PRESET 34、MAID-FIRST-MEETING 27、MAID-ART-R2 78、MAID-BOND-CG 71、MAID-STAND 33、GATHER GUIDANCE HIGHLIGHT 11、M2-D responsive PASS。
   - FAIL：`MAID-BOND-CHAPTER checks=176 failures=["the CG memory still shows its artwork","the CG memory exposes no chapter branches"]`、`MAID-VOICE checks=248 failures=["voice_line is static and stateless"]`、`MAID-GUIDANCE-VOICE checks=46 failures=["message panel stays open on the wide layout","hint text still states the next hut objective: …"]`。
4. 三項失敗均為 runner 斷言側（非 src 缺陷），orchestrator 修正：
   - `maid_bond_chapter_runner`：回憶按鈕按壓點 row2→row3（`_memory` 的最後一章守衛隨第四章移位，row2 按壓靜默無動作）。
   - `maid_voice_runner`：`get_script_method_list()` 反射靜態旗標在 4.7 不可靠 → 改為 `Script` 資源直呼 `voice_line` 行為檢查。
   - `maid_guidance_voice_runner`：`_pick_world` 點擊觸發直建路徑（自動開營造簿切頁、hint 變成功回饋）→ 改以 `session.submit({type:"upgrade_building", building_id:"hut"})` 乾淨建房（shell 留 home、hint 維持茅屋目標）。直建回饋覆蓋同 key 引導屬既有設計，非缺陷。
5. `tools\run_all_runners.ps1 -Only 'maid_bond_chapter,maid_voice,maid_guidance_voice' -TimeoutSeconds 120` → 3/3 PASS：`MAID-BOND-CHAPTER checks=176 failures=[]`、`MAID-VOICE checks=248 failures=[]`、`MAID-GUIDANCE-VOICE checks=46 failures=[]`（matrix=single 1280×720）。
6. 合併證據：14/14 runner 通過（首輪 11＋補跑 3），零 `SCRIPT ERROR`。輸出暫存：`%TEMP%\dao2_runners_5707068cfbeb4f85a0298b15f91a6c6b`（首輪）、`%TEMP%\dao2_runners_3b170f2f16584db181595345767d435c`（補跑）。

## 邊界與未驗證

- 只跑受影響 runner 群（L1/L2）；未跑 L3 全量、全尺寸矩陣、Web 匯出、桌面瀏覽器三橫式或觸控實機（觸控依 2026-10-17 延期）；不宣稱滑鼠命中／渲染／IndexedDB 證據。
- 第四章達 200 同道僅由規則與 runner 證明；實機全流程（真實累積 90 羈絆）未走。
- 引導語音只認 `GUIDE_VOICE` 已知鍵；hub H1–H6 與未知鍵靜默，屬刻意的首波範圍。
- 招募成功訊息由通用文案改為角色語音，屬呈現層 v2 變更；`maid_first_meeting_runner` 釘選已同步。
