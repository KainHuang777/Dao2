2026-10-24 續驗完成：**P2-S2 DONE（L2／桌面1280×720有界），SKS-P2整體IN_PROGRESS。** 十二PNG已從worktree整合且使用者美術接受；逐ID真實滑鼠與拒寫／重試／重載見[最新驗收](sks-p2-acceptance.md)。下方未生成／未驗為本段初交付歷史，保留原測試與失敗界線。

# SKS-P2 / P2-S2 合法流程與卷冊 UI 驗收（L2）

日期：2026-10-24
任務：`SKS-P2 / P2-S2`
等級：L2（規則領域。單尺寸 1280×720；未跑 L3、全尺寸矩陣、Web 匯出）
狀態：**IN_PROGRESS，P2-S2 未完成。** 合法流程、View 可讀資訊與 UI 已接；12 張正式圖尚未生成／美術接受，桌面瀏覽器真實滑鼠抽驗尚未執行。整體 SKS-P2 仍 IN_PROGRESS。

## 1. 本輪交付

- `src/simulation/skill_system.gd`：`view()` 每項新增 `scope`、`scope_islands`、`scope_open`、`scope_note`。12 項 P2 技能皆有作用範圍文字；三座地方島（deep／ancient／void）未開時，`scope_note` 明示「…未開 · 收益 0」。地方未開仍可研習，符合 docs/35 §2 的收益 0 規則；非 P2 技能維持空 scope，既有欄位與鎖定原因優先序不變。
- `src/presentation/skill_study_view.gd`：沿用既有淡紙卡、共用字型、44px 操作鈕與內層捲動；卡片新增「作用：…」列，並顯示未開島提示。當前階／下一階效果、每階點費、鎖定原因與按鈕文字仍由既有 View 欄位驅動，未新增顏色、字型或分頁規則。
- `tests/sks_p2_flow_runner.gd`：新增合法流程 runner，從既有已賺得存檔出發，只透過正式命令與 `SkillSystem.learn` 支付；不使用注入庫存、直接改技能或跳境。已登記 `tools/run_all_runners.ps1`。
- `tests/uix_r8_skills_ui_runner.gd`：新增 P2 卡片作用列斷言；未開地方島卡片必須含「收益 0」。
- `docs/verification/artifacts/sks-p2-art/`：12 份英文 ImageGen 提示詞與 `manifest-pending.json`（狀態 `pending-imagegen-human-acceptance`）。本環境無 ImageGen／API，**沒有 PNG、沒有 sha256**，也未以舊圖或占位圖冒充。

## 2. 合法流程（earned fixtures）

起點為 `docs/verification/artifacts/content-p2-supply-3/` 的已賺得存檔，皆經 `SaveCodec.decode` 成功、`skills` 為空、`skill_version=3`、economy 為 `res1-e-46-1`：

| 存檔 | SHA256 |
|---|---|
| earned-era3.json | `3c3ef46509b791efefbc11e45f3fba6e8f57364bdd784e8eef2c6c4a7a64a8f6` |
| earned-era4.json | `5c7b38f649d5aaee6c1c1ac1d2b9ada5d79a1a0aed824816fe246440d11c2895` |
| earned-era5.json | `abd155ec714a50a1e93eae2f70e9217dd91ecbf3532984114523703f1b2c0e29` |
| earned-era6.json | `517433be871d2cbdccf7fbc678b4043bb1f97fdd3715272faf29df5b94b3525d` |

流程：

1. Era3：開卷冊前技能點為未解鎖，12 項皆 `SKILL_STUDY_LOCKED`；建藏經閣 1 後點數解鎖，12 項轉 `SKILL_ERA_LOCKED`，正式 `learn_skill` 被拒，`skills` 仍為空（主線 0 技能）。
2. Era4／5／6 各自由獨立存檔載入，`reconcile` 至 skill_version 4；補足 `storage_wood=2` 的木頭容量後建藏經閣 3 與藏經殿 1，確認產點率／上限（Era4 15.588／36,200；Era5 23.383／86,200；Era6 31.177／86,200）。
3. 依正式命令購買 `foundation_building` 1（3,600）與 `golden_core_formation` 1（7,650）作為前置；點數不足時等待自然產點，不注入。
4. 逐 ID 等待至可負擔，提交正式 `learn_skill`，驗證扣除剛好等於單階費用、等級 1、當前／下一階文字、未來境界仍鎖定。
5. 每次結果皆以 `SaveCodec.encode` 落成快照。

### 逐 ID 首階結果

| Era | ID | 費用 | 等待（模擬秒） | 學習後等級 | 當前→下一階 |
|---|---|---:|---:|---:|---|
| 4 | nascent_soul_incubation | 21,250 | 1,363 | 1 | ×1.150→×1.322 |
| 4 | nascent_soul_mastery | 21,000 | 1,348 | 1 | ×0.950→×0.902 |
| 4 | heavenly_craft | 12,000 | 769 | 1 | ×0.95→×0.90 |
| 4 | deep_vein_resonance | 9,000 | 578 | 1 | ×1.100→×1.210 |
| 5 | void_expansion | 30,000 | 1,283 | 1 | ×1.100→×1.210 |
| 5 | spirit_transformation | 35,000 | 1,496 | 1 | ×0.930→×0.865 |
| 5 | ancient_herb_attunement | 15,000 | 642 | 1 | ×1.100→×1.210 |
| 5 | spirit_sea_breath | 18,000 | 770 | 1 | ×1.150→×1.322 |
| 6 | void_mastery | 45,000 | 1,443 | 1 | ×1.100→×1.210 |
| 6 | void_refinement | 50,000 | 1,458 | 1 | ×0.900→×0.810 |
| 6 | void_essence_attunement | 24,000 | 700 | 1 | ×1.100→×1.210 |
| 6 | frontier_storekeeping | 20,000 | 583 | 1 | +100→+200 |

前置等待（含自然產點）：Era4 214 秒；Era5 144 秒；Era6 108 秒。以上為隔離存檔的單階購買，不是自然一生節奏或玩家進度。

### 作用島與收益 0

- Era4 僅寒銀島開啟：古藥島／太虛島相關卡片顯示「未開 · 收益 0」；寒脈共鳴訣（寒銀島）正常。
- Era5 寒銀島／古藥島開啟、太虛島未開：太虛島卡片與三島藏真法提示收益 0。
- Era6 三島全開：全部地方技能無未開提示。
- 所有 12 項皆可從 View 讀到作用文字，UI 卡片同步顯示。

### 拒寫 → 重試 → 重載

在 Era6 以 `frontier_storekeeping` 第 2 階（20,000）執行：正式學習成功後，`ToggleAdapter` 令第一次保存回 `R8_WRITE_DENIED`；第二次重試仍拒絕且狀態快照不變；恢復寫入後保存成功且狀態不變；重新設定並 `load_state` 後，等級 2、扣除後點數、藏經閣 3／藏經殿 1、skill_version 4 與供給 economy 均保留。

## 3. 命令與結果（L2，單尺寸 1280×720）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_all_runners.ps1 -Only 'sks_p2_core'
# PASS 8s

powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_all_runners.ps1 -Only 'sks_p2_flow' -TimeoutSeconds 900
# PASS 139.2s；關聯流程 137.687s，392 checks / 0 failures

powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_all_runners.ps1 -Only 'uix_r8_skills' -TimeoutSeconds 120
# PASS 5.6s；102 checks / failed=false（加入作用列與收益 0 斷言後）
```

`DAO_VIEWPORT_MATRIX` 未設為 `full`，只跑 1280×720。`sks_p2_flow` 為已確認的長流程（自然時間推進），依 AGENTS 使用 900 秒逾時；未反覆重跑。

### 產物

| 檔案 | 大小 | SHA256 |
|---|---:|---|
| earned-era3-library.json | 65,024 | `4690e9189b49c46a81803d55c0e59270b464c196162ed138719deffcbf2ccf69` |
| earned-era4-first-tier.json | 69,606 | `525835cf5032411853d0caef424c4b593af6e8c27b03211a1e8e08395d340aed` |
| earned-era5-first-tier.json | 72,843 | `efcc8e86376b76fe99232bb72edbaaa35d146d7a65593286bf38a042d9fc0853` |
| earned-era6-first-tier.json | 73,016 | `51fdfbdb4b5337b3b4dd459b332a8a76a14da5b28a20033b3472791e1ce71cf6` |
| flow-report.json | 19,278 | `6070777b95ec63020db9e34818aa8ce29d452dce11416b81ab5d6ff9b422d77c` |

## 4. 未完成／界線

- **12 張正式圖未生成、未美術接受。** 本環境無 CODEX／ImageGen 與影像 API；只交付提示詞與待生成 manifest。`uix_r8_skills_ui_runner.gd` 仍保留 `P2_ART_PENDING` 例外，未把缺圖說成通過。
- **桌面瀏覽器 1280×720 真實滑鼠抽驗未執行。** 本環境沒有瀏覽器自動化工具；需人工以含本次修改的本機 Web 包開啟卷冊，逐 ID 研習並驗拒寫 → 重試 → 重載。未以 CLI runner 冒充滑鼠命中或 Web 落盤證據。
- 未跑 L3、全尺寸矩陣、Web 匯出／壓縮、FPS 或觸控實機（觸控依 2026-10-17 指令延期）。
- 未改玩家進度、`build/`、`.godot/` 或既有正式存檔；未 commit／push。
- 因此 P2-S2 不可標 DONE，SKS-P2 亦未收尾。SKS-P2 的唯一 L3、候選包與三橫式桌面驗收留待里程碑結案。

## 5. 下一步

1. CODEX 依 `docs/verification/artifacts/sks-p2-art/prompts/` 生成 12 張透明 PNG，依 manifest 處理並補 sha256，交使用者美術接受。
2. 以含本次修改的本機包做一次 1280×720 桌面真實滑鼠卷冊抽驗與拒寫／重試／重載。
3. 上述完成後才更新 P2-S2 狀態；SKS-P2 收尾時再執行唯一 L3、Web 候選與三橫式桌面驗收。
