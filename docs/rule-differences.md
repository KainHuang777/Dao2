# 規則差異帳本

更新：2026-09-16。此表只記錄已固定的舊版規則、明確 v2 決策及尚未決定的差異；不把展示場景的數值當作遊戲規則。

| ID | 主題 | 狀態 | v2 目前處理 | 證據／後續 |
| --- | --- | --- | --- | --- |
| LP-001 | 建築費用三段指數、線性段與折扣 | `legacy_parity` | M0-B 固定等級 0／20／21／50／51 的 Decimal 字串結果；M1-A 以 AmountCompat 移植並通過全部 5 向量 | `m0-b-v1.json`；`tests/m1a_core_runner.gd` cost_parity |
| LP-002 | 新手僅靈力與茅屋，功能等級逐步解鎖 | `legacy_parity` | 固定空白、茅屋 2 級與完整 EAR1 鏈的可見項目；M1-A 實作真實空白初始（0 靈力、建築全 0、僅茅屋可見） | `m0-b-v1.json`；`tests/m1a_core_runner.gd` onboarding_parity／new_game_blank |
| LP-003 | 升級看容量上限，容差 0.1 | `legacy_parity` | M1-B 只實作資源容量上限 clamp（產出後超過 cap 即設為 cap）；舊版 499.89 失敗／499.9 通過的**升境容量需求**尚未實作（無升境路徑）。成本可負擔判定另採 `value+1e-6>=cost` 容差與 `<1e-9` 歸零 | 升境容量語意留 M2-B；`tests/m1b_time_runner.gd` CAPACITY CLAMP |
| LP-004 | 修煉時間幾何累積與多層加速下限 | `legacy_parity` | M1-B 已以 GDScript 移植並通過向量：累積 47.5、單級 33.75、加速 36／1；Era1 單級 60/69/79.35/91.2525…183.5413718；tick=60 秒 | `tests/m1b_time_runner.gd` TRAINING VECTORS；`docs/verification/m1-b.md` |
| LP-005 | 壽元按已經歷 Era 配額累加 | `legacy_parity` | M1-B 已實作並通過 4800／12000／44400／13500／68400 秒（累積 80／200／740 祀）、fallback（era1 80 其他 i×100）、inclusive `>=`；升境不重置本世年齡 | `tests/m1b_time_runner.gd` LIFESPAN VECTORS；突破／壽盡輪迴流程留後續 |
| LP-006 | 輪迴道心、道證與資源繼承 | `legacy_parity` | 固定普通／大道比例、境界保底、40%／80%起手、因果倉儲 | M3-A 補全資格、清除／保留清單與存檔往返 |
| LP-007 | Amount 的 `break_eternity` 字串／JSON | `legacy_parity` | 固定 0、十進位、`1e100`、`1e1000000`、`ee5` 的字串結果 | M0-C 實作完整 Amount 契約、算術及非法值邊界 |
| LP-008 | SeededRandom | `legacy_parity` | 固定 ASCII、繁中 UTF-16 seed、數字 seed 及 state 恢復序列 | M0-C 建立 GDScript 同序列實作或明確 bridge ADR |
| LP-009 | 建築等級上限＝min(maxLevel, 10)（無 building_mastery 技能） | `legacy_parity` | 舊版 `getBuildingLevelCap`：全域基礎上限 10，僅技能可提高；茅屋 maxLevel 2 → 2，木屋 50 → 10。M1-A 已實作 | `tests/m1a_core_runner.gd` level_caps；技能分支待未來技能內容 |
| LP-010 | era1 新手資源鎖定：onboarding 鏈外全鎖 | `legacy_parity` | 舊版新檔 `resource.unlocked` 僅含 onboarding 顯式解鎖＋鏈推進；`black_copper` 雖 CSV `unlocked=TRUE` 仍鎖。M1-A 已實作（僅 lingli 起始解鎖） | `tests/m1a_core_runner.gd` new_game_blank／gather RESOURCE_LOCKED |
| LP-011 | 茅屋起手成本雙軌 | `legacy_parity` | 舊版 `getBuildingBaseCostForOnboarding`：onboarding 活躍（新檔）baseCost={lingli:20}；非活躍（舊檔）={money:30}。M1-A 已實作（era1 新檔走 lingli 20） | `tests/m1a_core_runner.gd` upgrade（茅屋 0→1 扣 lingli 20） |
| V2-001 | 展示洞府的 float 每幀產出 | `v2_prototype_only` | 不可作為舊版或正式公式來源 | M2-A 移除展示 state，改讀正式 GameSession |
| V2-002 | 離線收益最多 24 小時 | `v2_decision` | 2026-09-16 落地：`CAP_MS=86400000`，收益窗走完整 per-tick、超出只推年歲與壽盡；游標提交至 now（含放棄區間）；倒退時鐘不給收益、不倒退游標；保存失敗可重試不雙領。`RULES_VERSION` 升為 `offline-24h-1` | `tests/m1d_offline_runner.gd`；`docs/verification/m1-d.md`。非舊版行為，不得宣稱原作如此 |
| V2-003 | 九界、無限宇宙與跨界物流 | `v2_new_content` | 不映射為舊版 Era；遠景不產生第二份經濟 | M4–M5 逐項驗證 |
| V2-004 | 命令錯誤碼與檢查優先序 | `v2_decision` | 舊版升級檢查回傳 bool 無錯誤碼且可見性先於 era；v2 定義命名錯誤碼，順序 era → 等階上限 → 可見性 → 前置 → 費用（gather：type → 鎖定）。錯誤一律不改狀態 | `tests/m1a_core_runner.gd` upgrade／gather／stale_revision |
| V2-005 | 「到期」釋義與訓練溢出模型 | `v2_decision` | 舊碼無「到期」字串；M1-B 釋義為「修練時間達到該級需求」（`trainingSeconds >= required`），壽盡為另一邊界。溢出採「升級時 `training_seconds=0`、捨棄超出需求」（舊 simulator 模型），非 runtime 的 wall-clock 累積門檻模型 | `docs/verification/m1-b.md`；`tests/m1b_time_runner.gd` LEVEL UP CONSUMES |
| V2-006 | 新快照信封與兩世代槽位 | `v2_decision` | 舊版無 v2 信封；M1-C 定 schema_version 2、`content_version`／`rules_version`／`amount_format_version`、整數時間為十進位字串、checksum 僅偵測損壞；兩世代槽位輪替（寫入→讀回比對→才更新 index），`read_best` 選 revision 最大且通過驗證者；Web 以 IndexedDB 為權威且須交易完成訊號（不以 `FileAccess.close()` 推定） | `docs/verification/m1-c.md`；瀏覽器落盤／兩分頁互斥未驗證 |
| V2-007 | 舊存檔匯入為主動、不補算、另存新槽 | `v2_decision` | 舊版格式 `1.0`（`v,o,t,p,r,b,s,beastData`，`s`=sect 非 skills；Decimal 為字串）。v2 匯入：使用者貼上／選檔（不自動讀舊站 localStorage）、`backfill_policy="none"`（不按舊時間戳補獎）、成功另存新槽且 `revision=max(prev+1,1)`、原文存 `legacy_import_raw`、未知 ID／金額問題列入報告且不寫入狀態；`max`／`rate` 重算不沿用 | `tests/m1e_import_runner.gd`；`docs/legacy-compatibility.md`；`docs/verification/m1-e.md`。非舊版行為 |
| V2-008 | 線上分段時間與手動晉階 | `v2_correction` | 2026-09-23 修正每幀 `delta` 被截斷的缺陷；未滿 60 秒的餘數存入快照並於離線承接。正式玩法採玩家命令晉階，時間只累積修煉；先前自動扣料取自平衡模擬器，與正式 UI 衝突。`RULES_VERSION=core-flow-2` | `tests/core_positive_flow_runner.gd`、`tests/m1b_time_runner.gd`；詳見 `docs/verification/core-positive-flow.md` |
| V2-009 | 產率倍率與新手資源來源 | `v2_correction` | 境界／道心倍率乘到建築產率，畫面與時間推進共用同一公式。練氣期已解鎖 basic 資源在資源總覽可手動採集，補齊金錢首源；採石場解鎖玄銅是對舊 onboarding 顯式清單的 v2 修正（舊 fixture 未列玄銅）。舊版 `money`=金錢、`stone_low`=下品靈石，修正 v2 誤標。 | `tests/core_positive_flow_runner.gd`、`tests/m1a_core_runner.gd`；`docs/verification/core-positive-flow.md` |
| V2-010 | 資源每秒入庫與境界 HUD | `v2_decision` | 2026-09-25 將結算步長改為 1 秒，產率仍以每秒為單位；離線固定產率區間合併運算，壽元仍 60 秒＝1 祀。舊快照的 0～60 秒餘數可讀並在下一次推進結算；`RULES_VERSION=core-flow-3`。HUD 分行顯示境界名稱、層數、修煉與壽元，資源顯示小數。 | `tests/core_positive_flow_runner.gd`、`tests/m1b_time_runner.gd`、`tests/m1d_offline_runner.gd`、`tests/m2d_responsive_ui_runner.gd` |

`legacy_parity` 表示需要先與已固定來源一致，並不表示該規則永久不可改善。改動舊行為時，必須新增帶版本的 v2 決策與相對應案例，保留原 fixture 供遷移與回歸。

## 2026-10-02 內容承接審核補記（既有實作差異，非本輪改規則）

| ID | 主題 | 狀態 | 審核結果／後續 |
| --- | --- | --- | --- |
| V2-011 | 簡化煉丹與通用合成未承接 | `v2_change`（已實作現況；完整設計核定待補） | Dao2 cultivation_pill／lifespan_pill 為另一套 ID／效果；同 ID foundation_pill 的配方已由草3＋靈力50改為草50＋玄銅20＋靈力200，服用變成當世產率加成。三丹 hardcode 不等於 Dao1 30 recipe。不聲稱 legacy_parity；先於 CONTENT1 記錄保留／改寫策略與庫存遷移，不默默覆蓋現有玩家物品。 |
| GAP-CONTENT-1 | 築基內容、跨境界解鎖、功法前置、一般配方缺席 | `未完成` | Dao2 正式內容僅7資源／10座 Era1建築，升境後新可見項0；四份 Dao1 CSV 與舊來源 manifest hash 不同。保留舊 fixture，建立新 profile，再依 CONTENT1／2 補齊。 |
| GAP-CONTENT-2 | 茅屋跨境容量與丹藥雙庫存 | `缺陷待修` | 本輪記憶體觀察升境靈力容量1400→1100；資源有築基丹但 pills 無時服用不足；足料煉製201超基礎容量200。未修改玩法或測試標準。 |

本輪詳細證據與模型評估見 [M3-B-CONTENT-AUDIT](verification/content-progression-audit-2026-10-02.md)。

## 2026-10-02 M3-B-CONTENT2 築基內容切片補記

| ID | 主題 | 狀態 | v2 目前處理 | 證據／後續 |
| --- | --- | --- | --- | --- |
| LP-012 | Era 2 境界數值照 Dao1 `eras.csv` 原樣 | `legacy_parity` | max_level 10、壽元 120、level_up {base_time 120, time_mult 1.18, lingli 500／money 100／stone_low 50}、upgrade {level 10，capacity lingli 2000／stone_low 1000}。production 舊 era2.json 草稿值（lingli 200、time_mult 1.2、缺 money/stone_low）視為未接線草稿，不保留為 v2 差異。capacity 鍵去 `_max` 後綴（對齊 `Production.compute_caps` 以資源 id 為鍵與 `_apply_breakthrough` 原鍵查表；修正舊檔帶 `_max` 鍵永遠查 0 的潛在破格 bug） | `content/eras/era2.json`；`tests/m3b_content2_runner.gd` era2_parities／breakthrough 鏈 |
| LP-013 | Era 2 資源／建築／儲量數值照 Dao1 CSV | `legacy_parity` | 9 資源（含 beast_crystal_low era-3 前向標籤照抄）＋11 建築（library、scripture_hall、stone_mine_mid、iron_mine、hunter_camp、rice_field＋5 中級儲量）base_cost／effects／effect_weight／prereqBuilding 逐一對照；advCost 全 0 縮併入 base_cost | 對照 `docs/verification/artifacts/content-progression-audit/catalogs.json`；`tests/m3b_content2_runner.gd` |
| V2-012 | 建築 prereqTech（技能前置）不搬入 | `v2_change` | Dao1 非新手路徑本來就繞過 prereqTech（僅 A1 progression 語系使用），且 Dao2 尚無技能購買指令管道；era-2 建築僅受 era＋prereqBuilding 門檻 | `docs/verification/m3-b-content2.md`；技能購買任務時再回補 |
| V2-013 | resource_multiplier 1.5 生效於產率 | `v2_change` | Dao1 `resourceMultiplier` runtime 無消費者（僅平衡模擬器）；Dao2 由 `Production.compute_rates` 乘入。era-2 相關測試改讀內容定義倍率 | `tests/core_positive_flow_runner.gd`；`tests/m3b_content2_runner.gd` |
| V2-014 | 跨 era 資源解鎖走 ProgressionEvaluator status | `v2_decision` | 資源 unlock 陣列（era／building_level／ever_obtained）＋`unlock_eligible_resources` sweep，掛 `_apply_upgrade`／`_apply_breakthrough` 發 `resource_unlocked` 事件；era-1 資源（含 foundation_pill）維持既有權威路徑不變 | `src/domain/content_reconciliation.gd`；`tests/m3b_content2_runner.gd` unlock_sweep_gates；Dao1 A1 per-resource 語系為參考 |

## 2026-10-02 M3-B 技能購買補記

| ID | 主題 | 狀態 | v2 目前處理 | 證據／後續 |
| --- | --- | --- | --- | --- |
| V2-015 | 技能購買成本為定義表價（flat），不搬舊版級距曲線 | `v2_difference` | Dao1 skillCost 依 `base*(1-rate)^level` 逐級算價；era2 skill defs（v2 內容切片）僅有單一 `cost`／`cost_resource` 欄位，無 per-level 成長欄位，故 `SkillSystem.get_cost` 取定義價不隨 level 變動（如 basic_meditation 每級 90sp）。era／prereq 把關不搬：era-2 技能實際由 skill_point 資源解鎖（era 2＋library L1）間接把關 | `src/simulation/skill_system.gd`；`tests/m3b_skill_runner.gd` flat_cost_not_scaling；Dao1 `src/balance/rules/skillCost.ts` 為來源參考 |
| V2-016 | era2 技能 effects 已接線（Dao1 平價公式）；新增三方 v2 取捨 | `v2_change` | 已搬 Dao1 套用規則：`*_rate`＝amount×level、`*_multiplier`＝amount^level、`*_max`／all_max＝平加 amount×level、`building_level_cap`＝上限＋amount×level、升級時間乘數＝amount^level（Dao1 time_reduction 同型，floor 0.1 已在 `Cultivation` 既有實作）。era2 六技能 effect 欄位亦為 Dao1 CSV 平價。接受限制：①schema 無 effect-type 白名單（typo 型視為 inert 內容，運行時靜默無效）；②`compute_caps` 的 `skill_max_multipliers` 參數保留但目前無呼叫端傳值，`all_rate_multiplier`／`all_max_multiplier` 型效果 schema 接受但運行時忽略（era2 內容無此型，Dao1 有使用 `all_max_multiplier`） | `docs/verification/m3-b-skill-effects.md`；`src/simulation/production.gd`；`tests/m3b_skill_effect_runner.gd` |
