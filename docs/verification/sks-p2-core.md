# SKS-P2 / P2-S1 核心驗收

日期：2026-10-24。級別：**L2 領域（單一尺寸 1280×720，共用核心依賴 12＋1 支 runner）**。範圍：SKS-P2 核心子階段（技能資料、效果、折扣、保存版本）。整體 SKS-P2 仍 IN_PROGRESS；P2-S2 合法流程／UI／12 圖未開始。

依使用者「fusion skill SKS-P2 / P2-S1」指示，方案 K1（十二技能逐項數值）、K2（容量／產率／折扣／等候契約）、K3（保存版本）**依[設計文件](../35-sks-p2-design.md)原案實作**，數值不改；K-art（12 張透明 PNG 與卡片）**留給 CODEX／P2-S2**，本輪未生成任何圖。

## 交付

- `content/skills/era4_6.json`：Era4–6 各 4 項共 12 定義。`nascent_soul_incubation`（元嬰孕育，5 階，21250）、`nascent_soul_mastery`（元嬰大成，3，21000）、`heavenly_craft`（天工煉靈法，3，12000）、`deep_vein_resonance`（寒脈共鳴訣，3，9000）、`void_expansion`（虛空擴展，3，30000）、`spirit_transformation`（化神凝意法，3，35000）、`ancient_herb_attunement`（古藥養靈術，3，15000）、`spirit_sea_breath`（神海納息訣，3，18000）、`void_mastery`（太虛御物法，3，45000）、`void_refinement`（煉虛歸真訣，3，50000）、`void_essence_attunement`（太虛採元術，3，24000）、`frontier_storekeeping`（三島藏真法，3，20000）。僅四項時間／孕育技能前置 `golden_core_formation` 1。
- `src/simulation/sks_p2_rules.gd`（新）：凍結純函式與 23／7／6 ID 白名單、1.15／1.1／1.1／1.1／0.05／100 常數；`cap_multiplier`、`home_rate_multiplier`、`local_rate_multiplier`、`local_capacity_bonus`、`lingli_discount_multiplier`、`discounted_amount`。無 Node／Texture／幀率／RNG。
- `src/simulation/skill_system.gd`：`VERSION` 3→4、支援版本 0–4、新效果種類、`P2_CONTENT_TAG="+content-sks-p2"`、attach 讀取 era4_6.json、v4 併入 24 ID 上限、`skill_count_limit(version)`、新效果文案。
- `src/simulation/production.gd`：`compute_caps` 在既有整數截斷後套用容量倍率並**只做一次** `floor_amount()`；`compute_rates` 對六種祖島資源套用太虛御物倍率。`skill_point` 不在 `study_cap` 二次相乘。
- `src/simulation/island_progression.gd`：供給三島容量＝300＋三島藏真 100×階（已開島，300→600），不影響舊島與 cargo。
- `src/simulation/island_economy.gd`：`effective_inputs()` 為折扣唯一來源（`_check_start`、`_start` 扣料、`manufacturing_view` 需求同源）；`rate()` 套用島嶼倍率；`home_cap()` 最終 `floor`。
- `src/persistence/save_codec.gd`：`SKS_RULES_VERSION="core-flow-19-content-sks-p2"`（`skill_version>=4` 時），解碼技能數上限改版本感知（v0–3 仍 12、v4 為 24）。schema 5 不變。
- `tests/sks_p2_core_runner.gd`（新，81 checks）、`tests/sks_p2_core_runner.gd` 註冊於 `tools/run_all_runners.ps1`。
- 更新受影響既有 runner：`content_p1_skills`、`content_p1_skills_ui`、`early_v1c_skills`、`skills_b1`、`sks_p1`、`uix_r8_skills_ui`、`content_p2_supply_economy`（12→24 定義、version 3→4、非法版本 4→5、按鈕 13→25、P2 圖待生成例外清單）。

## 決策與界線

- **不需 economy 子版本**：`IslandEconomy.validate` 僅檢查工作 `reserves` 為配方輸入子集合，不重算已付費用；折扣只改新工作的實際支付與需求量，已開始工作保留原支付、剩餘時間，不回溯、不退費、不重算。economy 版本維持 `res1-e-46-1`，舊存檔遷移仍可驗。
- **舊檔不追認**：既有 v4 檔技能缺鍵補 0、不寫 24 個零；離線不回溯補發；舊代碼拒絕新 ID。
- **主線零技能**：skills 空時所有 P2 倍率為 1.0，內容仍可完成；12 項皆非必要。

## 命令及結果

```
.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
# exit0，4.7.2.stable.official.ed1daf0bf

.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
# exit0，輸出無 SCRIPT ERROR

.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/sks_p2_core_runner.gd
# exit0，PASS: SKS-P2 81 checks

powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'sks_p1,sks_p2,content_p1_skills,content_p2_supply,skills_b1,early_v1c_skills,uix_r8_skills'
# 首輪：8 PASS、3 FAIL（content_p2_supply_economy 9.8s／content_p1_skills 3.9s／uix_r8_skills 6.1s）
# 修正後重跑 -Only 'content_p1_skills_runner.gd,content_p2_supply_economy_runner.gd,uix_r8_skills_ui_runner.gd'：3／3 PASS

powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_progression_runner.gd' -TimeoutSeconds 1500
# PASS（1187s），無技能舊子版本長流程到煉虛十層 150253 模擬秒與壽盡輪迴仍成立
```

日誌：`C:\Users\asus\AppData\Local\Temp\dao2_runners_8f5e717603314cceafc0aa8f3d74e79f`（首輪 L2）、`..._8359ff8a4b42441899010c1127d0a856`（長流程逾時診斷）、`..._6a602c3007134a35ac6e1ee9b59b0c29`（三支修復補驗）、`..._c53c17c15f204e6c9890c4d4955e46d0`（長流程 1187s）。首輪失敗與逾時未改寫，保留為真實過程。

部分 runner 會改寫既有證據檔（`content-p2-supply-3/earned-*.json`、`content-p1-skills/native-ui.json`／`progression.json`、`early-v1-c/runner-measurement.json`、`skills-b1-fixture.json`、`src/verification/content_p1_skills_fixture.json`）。本輪新輸出另存 `artifacts/sks-p2-core/generated/`，13 份原檔以 `git checkout --` 逐字還原，不改寫舊證據；匯入另生的三個 jpg `.import` 暫存檔已刪除，未動 `.godot/`。`src/simulation/sks_p2_rules.gd.uid` 與 `tests/sks_p2_core_runner.gd.uid` 由引擎匯入產生，保留。

追加收斂：三島藏真容量改為僅對已開島加乘（未開島維持 300），與設計「opened only」一致；skills 為空時加成為 0，卷冊與經濟結果不變。補驗 `-Only 'sks_p2,content_p2_supply_data,content_p2_supply_economy'` 3／3 PASS（日誌 `C:\Users\asus\AppData\Local\Temp\dao2_runners_9a39ef7f572d49b290546aa9c3e08713`），新增關閉島容量檢查後為 81 checks。另一次較寬 selector `-Only 'sks_p2,content_p2_supply'` 以預設 45 秒執行時，長流程 runner 於 Era3 即逾時（49.6 秒，日誌 `..._ad958d11774d4ee8865cba26098f238a`）；該支已由上方 1187 秒完整通過，逾時屬預算而非腳本錯誤，保留不隱藏。

## 覆蓋的邊界

- 定義／前置：24 定義、每境四項、12 唯一 ID、僅四項需金丹；版本 4 接受、3 拒絕新 ID、未來版本拒絕。
- 學習：無據點／境界鎖／前置未滿／滿階／技能點不足／重複命令 id；成功扣點。
- 效果：0 階與滿階、三時間技能疊乘並與金丹 0.9 同通道、容量只乘一次（精鐵 3000→6034→8031、技能點 200→402 且 `study_cap` 不二次相乘）。
- 產率：寒銀島精鐵 0.1×調度2×1.331=0.2662、古藥 0.05324、太虛 0.06655；未開島 0；祖島／外島互不滲透；元嬰白名單外資源（靈氣、靈晶、貢獻）不變。
- 容量：三島 300→600（僅已開島；未開島維持 300）；技能降階造成超容時不刪資源、不釋放預留，只阻新工作（以 450 存量＋三島藏真 2＝500 合法、0 階判 `ECONOMY_LOCAL_AMOUNT` 驗證）。
- 折扣：`stone_mid_bulk` 靈力 1000→950／900／850、`stone_high` 50→47.5／45／42.5；礦石 500／3、產出 100／1、工時不變；舊單件 `stone_mid` 與丹術不受折扣；`_check_start`、扣料、UI 需求同源；已開工作不重算、下一批讀當前階。
- 保存：v4 往返、rules 身分、缺鍵補 0、v3 舊檔仍讀、兩槽復原與只保存重試沿用；輪迴清空 12 技能與技能點、`skill_version` 保持 4。

## 未驗證／未執行

- **未生成 12 張圖**（K-art 留 CODEX／P2-S2），美術未接受；`uix_r8_skills_ui_runner` 對 P2 卡圖暫列待生成例外。
- **未跑 P2-S2 合法流程與真實滑鼠**：Era3 自然進程開據點後逐 ID 首階、等候記錄、當前／下階文案、窄螢幕版面、保存拒寫→重試→重載皆未驗。
- **未跑 L3／全量矩陣／Web 匯出與壓縮／三橫式瀏覽器**；無渲染，故 60 FPS 與實機效能未測。觸控／實機依 2026-10-17 指令延期，非本輪阻擋。
- 未改玩家進度、未改 `.godot/` 或 `build/`、未 commit／push。

## 下一任務

New Chat 接同一 SKS-P2 的 **P2-S2**：合法流程與技能卷冊 UI（含 12 圖由 CODEX 產圖後接入）；只在 SKS-P2 整個里程碑收尾時做一次 L3 與候選包。
