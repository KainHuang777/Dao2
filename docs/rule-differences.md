# 規則差異帳本

2026-10-08 **V2-UI1A-R1（bugfix）**：輪迴後仍保留多島economy，Era1築基丹煉製原被錯送Era>=2才允許的加工路徑，已恢復既有Era1即時煉製；Era>=2仍走祖島唯一產線。費用／產出／服用效果不變，非DAO1全量parity。rules_version=core-flow-12-ui1a-era1-alchemy，schema3形狀不變；舊envelope仍可讀。[127檢查與限制](verification/res1-ui1-a.md)。


2026-10-05 **V2-RES1-D2（使用者核定方案，正常接線已交付、節奏待驗）**：採Era＋設施門檻替代一般技能點，不稱技能parity；保留聚靈壇每級100，新築基靈池每級1000、最高3、T1費用／聚靈壇2階前置，兩池階可達2300容量。沒有採用D1「原庫每級250」提案。金丹時間／基本料沿D1舊字面，額外丹液1＋陣芯1為v2初始費；丹霞唯一製丹液／成品回運、祖島T3與丹藥。rules core-flow-10-danxia／economy res1-d-2、schema3形狀不變，旧C归檔后候选提交不自动升版。215 checks、52/52与两版型Web子范围通过；完整D、美術／玩法與C/R2待驗。[ADR-011](decisions/ADR-011-era3-capacity-and-skill-gates.md)／[D2验收](verification/res1-d2.md)。以下D1提案按歷史保留。

2026-10-05 **V2-RES1-D1（isolated proposal，未採用正式平衡）**：fixture保留DAO1 Era3的240／1.22修行時間、2000靈力＋500錢＋50中品石費用、Lv9符咒10、壽元540／倍率2；每次另丹液1＋陣芯1是v2提案。一般技能目前缺失，隔離百年草用Era3門檻替代結丹法；靈力庫每級250提案解除正式1100容量不足2000突破阻擋，現行content與10級上限不變。B開拓包／固定航運仍工作值，未擴張為C正式成本。216 checks／8 source hash通過只證明隔離可達，不宣稱完整legacy_parity、一般技能已承接或Era3正常可玩；詳[來源與用途稽核](verification/res1-d1.md)。

更新：2026-09-16。此表只記錄已固定的舊版規則、明確 v2 決策及尚未決定的差異；不把展示場景的數值當作遊戲規則。

2026-10-03 新增 **V2-013（design adopted, implementation pending）**：Era 解鎖專業空島、靈材／陣芯等多階材料、時間加工、地方庫存與在途物流列 RES1 主線；它們是 v2 新機制，不能冒稱 DAO1 parity。本輪不改任何 runtime rules_version 或 schema。DAO1 的 30 配方／技能／丹方／合成加成先固定基線；現行 AlchemySystem 的築基丹成本与效果、Era 2 需求有來源差異，RES1-A 逐項決定承接／保留／遷移，不能以既有煉丹 PASS 當全量相容。規劃與來源：[docs/14](14-multi-island-resource-progression.md)、[稽核](verification/resource-progression-audit.md)。

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

| V2-011 | 洞府小景與築基外觀 | `v2_decision` | 2026-10-03 使用者要求優先交付；固定世界採木 +1 改為已解鎖資源的三種隨機小景，首次 12 秒／後續 45–90 秒、最多兩件、木 5–9／草 3–5／石 2–4、滿倉保留／不足一批只入剩餘容量、離線只出生不入庫、輪迴清除。原手動採集與建築公式不改；hut 的築基小院只改外觀。`RULES_VERSION=core-flow-4-scenery`，schema 2 新增小景內部版本 1。不是舊版 parity | `tests/abode_scenery_runner.gd`、`tests/abode_scenery_ui_runner.gd`；[契約](13-island-scenery-and-courtyard-spec.md)、[驗收](verification/island-scenery.md) |

`legacy_parity` 表示需要先與已固定來源一致，並不表示該規則永久不可改善。改動舊行為時，必須新增帶版本的 v2 決策與相對應案例，保留原 fixture 供遷移與回歸。
| V2-012 | 宗門正式庫存與跨重載命令收據 | `v2_correction` | 2026-10-03 M4-A-R1：宗門 herb／bronze 獎勵映射正式 spirit_grass_low／black_copper，坊市靈晶寫界域庫存；同快照新增最多最近 256 筆成功 command_id 收據，防止保存重載後重送扣料或發獎，按 revision 淘汰。schema 2 缺欄可讀，無法重建缺欄舊檔的歷史收據；rules_version=core-flow-5-session-receipts。 | tests/m4a_session_integration_runner.gd；docs/verification/m4-a-r1.md；並非舊規則全量相容承諾 |

| V2-014 | RES1-A 首批 Craft 政策 | `v2_change` | processing catalog=res1-a-1，正式未啟用。六項舊配方比率保留來源，築基丹延續 v2 50草＋20銅＋200靈力；靈材10木＋5石、陣芯2靈材＋2銅精為新配方。固定產量、全批原子成功／拒絕、嚴格足額／容量，無舊epsilon／暴擊／技能加成。資源Amount layer0≤1e12，超界拒絕；foundation resources權威、pills鏡像不一致拒絕。A 即時隔離契約，B 接計時／正式版本遷移 | [完整契約與限制](verification/res1-a.md)、145 checks、唯讀 DAO1 8 tests；不稱全量丹藥／Decimal parity |

| V2-015 | RES1-B 定時地方經濟與保存版本 | `v2_change` | opt-in economy=res1-b-1，schema 3／rules core-flow-6-island-economy；祖島 aliases resources、遠島地方庫存、加工開始扣料／保留產物、本批後停／切、固定六航線10秒載量10／20、出航扣庫存／到貨可花、保留容量共享；24h外與壽盡冻结加工／貨物；輪迴清除當世資產、原容量起手繼承一次。schema2保留原文且不自動啟用，未知工作／貨物版本拒絕。B原型價／產率／容量與運輸均非DAO1 parity；築基丹大額合法存量只扣一次，不套舊clamp | [完整契約與限制](verification/res1-b.md)，251 checks／native三程序；正式Web門檻與C玩法尚未放行 |
| V2-016 | EAR1 靈界耗料與滿倉轉換 | `v2_correction` | 輪迴保留設施，但 EAR1 暫停靈界背景生產／扣料／修煉回饋，Era2 恢復；按原料與剩餘庫容計算實際轉換量，滿倉不扣、近滿／缺料按部分量扣，扣料不截斷大額合法庫存。rules core-flow-7-realm-capacity-gates／schema3。非舊版 parity | [RES1-B-R1 驗收](verification/resource-feedback-r1.md)，738 checks／相關七項 Runner／隔離 Web |
| V2-017 | 僅天賦發放輪迴起手物資 | `v2_decision` | 使用者選定取消自動40%／80%；資源傳承0–10階提供新開局庫容0–100%，只給開局已解鎖基礎資源，下次轉世生效。既有庫存不回收；rules core-flow-8-talent-only-inheritance／schema3。LP-006的40%／80%僅保留為歷史來源，不再是現行規則 | [M3-A-R2驗收](verification/talent-inheritance-r1.md)，六項相關Runner／隔離Web實際購買與重載 |
| V2-018 | 三島設施與T2工程費 | `v2_decision` | C隔離profile res1-c-1：Era2開拓各木20石10，1–3階採集／加工／倉儲，T2付祖島工程費／航線運力；靈材只能青木加工，銅精只能玄礦，輪迴清設施／貨物。schema3／core-flow-9；數值候選非DAO1 parity，正式manifest未啟用 | [RES1-C1](verification/res1-c1.md)，87 checks／最終49Runner／隔離Web加工運回；完整C仍IN_PROGRESS |
