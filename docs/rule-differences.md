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

`legacy_parity` 表示需要先與已固定來源一致，並不表示該規則永久不可改善。改動舊行為時，必須新增帶版本的 v2 決策與相對應案例，保留原 fixture 供遷移與回歸。
