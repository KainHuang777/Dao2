# RES1-D1：Era 3 前置、丹霞島與 T2→T3 隔離契約

2026-10-05（Asia/Taipei）。**DONE，僅稽核與記憶體隔離契約**。完整 RES1-D TODO；C／C2／R2 IN_PROGRESS，R2 由 AGY 負責。依使用者授權與 [D1 邊界](../handoffs/2026-10-05-codex-res1-d1.md)並行，本輪沒有正式內容、保存或畫面接線。

## 前置稽核與依賴

目前內容以 source 為準：正常 manifest 只有 Era 1–2；正常三島採 C 契約，B 原型雖有 `herb` 定義與草藥航線，也不表示 C 能開丹霞。以下的「隔離」指 `tests/fixtures/res1d1/era3.json`／`contract.gd` 與獨立 Runner；不是正常玩家資料。

| 需求 | 現行 source／DAO1 對照 | 實際狀態與 D1 處理 |
| --- | --- | --- |
| Era 2→3 | `content/eras/era2.json`；`CommandProcessor._apply_breakthrough` | 正常沒有 next Era，先返回 NO_NEXT_ERA。即使補 Era3，靈力容量 2000 仍不可達：resource 基礎100＋storage_lingli每級100×共用10級上限＝1100。隔離測試實際拒絕 INSUFFICIENT_CAPACITY；fixture 提議每級250，8級2100足額，所有升級仍以命令及 T1 扣料取得。**正式容量修正未交付**。 |
| DAO1 Era2 差異 | legacy fixture `era_requirements[2]` | 舊倍率1.5／時間1.18／費用靈力500＋錢100＋石50／冥想5／突破另要石容量1000；v2現行倍率2／時間1.2／費用靈力200／無技能／只要靈力容量2000，均保留現行差異，不暗改。 |
| Era3 Lv1–10 | DAO1 eras.csv／`Cultivation`／`CommandProcessor._apply_level_up` | fixture 採舊 base_time240、time_multiplier1.22、每次靈力2000＋錢500＋中品石50；Lv9另符咒10。新增每次丹液1＋陣芯1為 **v2 工作提案**，不是舊 parity 或已平衡價格。實際命令走到Lv10，每次逐項核對扣料。 |
| Era3 壽元／倍率 | legacy fixture Era3 | 540／2沿用 CSV 字面；既有 Lifespan 累加 Era 壽元，未改時間規則。隔離流程總11512模擬秒，小於當時壽限。 |
| Era3→4 | DAO1 Era3突破容量／Era4境內成本 | fixture 保留靈力容量10000＋下品石容量5000作需求記錄，**不提供Era4**，實際返回 NO_NEXT_ERA。此容量在現有建築上限仍不可達，正式後續需設施方案。金丹藥品在 Era3製造，舊Era4境內晉階費用是金丹3，不是Era2→3或Era3→4突破扣料。 |
| 技能取得 | DAO1 skills.csv、buildings.csv；`GameContent`、`CommandProcessor` | 舊基礎冥想：Era2／5級／技能點90；築基功：Era2／5級／技能點3600；結丹法：Era3／5級／築基功前置／技能點7650。舊library產技能點，scripture_hall增加技能点上限且需銅精5。DAO2沒有這套一般技能資料／狀態／learn_skill命令，宗門功法不等價。fixture 明示改為 **Era-only產線提案**，不用預置技能假裝取得；正式需決定承接技能或採此替代。 |
| 百年靈草 | DAO1 Resources.csv要求Era3＋結丹法；`IslandEconomy.ISLANDS.herb` | A只宣告來源；B原型已有每秒1、每資源容量100與herb_home航線。C明確拒開herb。隔離以B開拓／tick／航線實際取得；祖島Production沒有百年草產率，不雙算。 |
| 丹霞三態 | fixture `danxia`；B `open_island` | 可見Era2是契約文案，無UI驗收；可開Era3；祖島木20＋下品石10成功後才產出。缺料／Era不足拒絕原子。第一次採集／工坊／碼頭由B開拓包涵，第一運力不要求自身產物；正式分拆建設命令未做。 |
| 設施／生產歸屬 | A recipes；B ISLANDS；fixture producers | 木島靈材／礦島銅精／祖島陣芯；祖島煉丹及中品石、符咒重用hut2／herb_farm3／stone_mine3，全由T1可建。fixture ownership wrapper拒絕錯島。不是正式C白名單；丹霞丹液坊與成品回運需要後續路由整合。 |
| 運力／容量 | `IslandEconomy.ROUTES`、`free_space`、`reserved` | 六條既有固定航線，每10秒運10，升級運20（B費木20）；遠島各資源容量100，祖島加工契約上限1000000但既有T1產出仍受Production實際容量。目的地含在途保留；滿倉停產／不足空間縮小貨物。C的T2升級成本與擴容不是這輪B隔離證據。 |
| 加工依賴 | `ProcessingCatalog.validate`、`ProcessingSystem`、`IslandEconomy._start` | 所有配比／時間沿A/B，沒有重寫Craft或物流。循環與未來Era原料依賴拒載。明確保留Amount layer0≤1e12契約，不承諾全量大數。 |
| 保存／離線／輪迴 | SaveCodec／TimeAdvancer／既有B/C | 本輪僅重用TimeAdvancer記憶體推進。沒有新schema、codec、Session白名單、manifest或正常世界。B validate通過只證明原型狀態，**不等於正式D可保存**。 |

## 來源、價格與用途

[唯讀來源快照](artifacts/res1-d1-source-audit.json)保存8個不同檔案hash、4條技能與2條技能建築原始CSV欄位，以及A固定的Era／資源基線。8個hash與res1-a-source.json全部一致；沒有執行DAO1 runtime，未寫來源專案。技能成本數字是CSV `cost_amount`字面，不稱每級公式已移植；配方投入是原料費，不是買賣價格。本輪未新增商店或猜售價。

| ID | A/B 每批輸入→1產物／秒數 | 前置、用途與差異 |
| --- | --- | --- |
| `spirit_timber` | 木10＋下品石5／10秒 | Era2／木島hut2；v2材料，經timber_home到祖島，投入陣芯2。 |
| `bronze_essence` | 玄銅10＋下品石5／10秒 | Era2／礦島stone_mine3；DAO1配比，經bronze_home到祖島，投入陣芯2。 |
| `formation_core` | 靈材2＋銅精2／20秒 | Era3／祖島hut2；v2 T3，隔離每次境內晉階消耗1，屬新增工作成本。 |
| `liquid` | 低階草5＋靈力50／10秒 | Era2／祖島herb_farm3；舊配比，隔離Era3晉階每次消耗1。丹霞草原料經grass_home運回；本輪没有丹液成品航線。 |
| `foundation_pill` | 低階草50＋玄銅20＋靈力200／20秒 | Era1／祖島herb_farm3；維持現有v2成本，舊為草3＋靈力50。金丹每批消耗3；服用效果不變。 |
| `stone_mid` | 下品石5＋靈力10／10秒 | Era3／祖島stone_mine3；舊配比，金丹消耗5、Era3晉階消耗50。 |
| `golden_core_pill` | 築基丹3＋百年草2＋中品石5／30秒 | Era3／祖島herb_farm3；舊配比，**藥品不是境界**；無服用效果，Era4境內用途只保留舊來源記錄，未接可玩消耗。 |
| `talisman` | 木10＋下品石5＋靈力50／10秒 | Era3／祖島stone_mine3；舊配比，实际Lv9→10扣10。 |

所有合成保持A的固定產量、嚴格足額、無合成暴擊／舊費用容差；A單批材料上限1000000與B基礎產率／開拓包／航運時間是v2工作值。新手／Era2數值不從舊CSV回灌。百年草技能替代、靈力庫250與丹液／陣芯晉階費僅是版本化fixture提案，尚未核定正式平衡。

完整入口路徑：空白Era1採集T1建祖業與容量 → 用現行Era1/2修行命令升至Era3（突破時所有未來材料仍0）→ 用祖業木／石開三專業島 → 木石互供製靈材／銅精並回運 → 祖島陣芯 → 丹霞草藥回運製丹液／百年草接築基丹與中品石製金丹 → Era3晉階扣實際T2/T3與Lv9符咒。沒有Debug命令、預置Era／建築／修行時間／中間物出現在此可達流程。

## 測試與命令

Godot `4.7.2.stable.official.ed1daf0bf`，`--version` exit0。獨立入口不註冊共用全量清單，不匯出Web、不批次import或壓縮；未啟動或傳訊AGY，沒有聲稱與AGY完成FPS時段協調，也沒有取得同期FPS證據。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\res1d1_audit.ps1
.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1d1_contract_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/res1-d1-delivery.log
```

- 初輪120 checks／exit0；追加完整Lv10與邊界後207、211 checks／exit0；最終 **216 checks／exit0**，見 [delivery日誌](artifacts/res1-d1-delivery.log)。隔離完整流程11512模擬秒，正常內容與玩家檔不變。
- 成功、Era拒絕、真實容量阻擋、來源不足／T3不足／Lv9符咒不足、修行時間不足、錯島／未知配方、滿倉、容量保留、運力差異、原料＋在途＋目的地守恆、600秒一次／分段完整快照一致有代表測試。為獨立測邊界而修改的diagnostic clones明確排除可達證據。
- PowerShell 5首跑audit因未指定UTF8解碼而失敗exit1；加上Get-Content／Import-Csv明確UTF8後 [audit日誌](artifacts/res1-d1-audit.log) exit0，8 hash／4 skills／2 buildings。較早探路的幾個猜測檔名不存在；已由rg定位真實cultivation.gd與CSV，不用缺檔推定功能。
- 沒有重跑共用51 Runner；歷史51/51不當本輪結果。沒有新瀏覽器／觸控／IndexedDB／保存故障／效能／使用者美術或玩法驗收。

## 檔案與下一階段

新增tests/res1d1_contract_runner.gd、tests/fixtures/res1d1/{era3.json,contract.gd}、tools/res1d1_audit.ps1、本驗收與專屬artifacts。更新README／ROADMAP／ai-handoff／development-status／rule-differences／updata及D1交接索引；保留原有dirty。沒有修改src、content、project、export presets、共用fixtures或Web build，也沒有commit／push。

下一 **RES1-D2正式整合準備（尚未開始）**：先決定正式容量方案、一般技能承接或Era-only替代；安排共享核心單方修改，再整合C版本丹霞／唯一加工歸屬／丹液成品航線、設施與修行需求。保持版本／故障復原／重試與舊三島保存契約，補無Debug正常玩家首段、重載／離線／輪迴及完整玩法；正常畫面／美術與相關C/R2放行仍待驗。不因D1子範圍DONE認定這些門檻已通過。

依AGENTS Context Guard停止本輪階段，英文checkpoint置updata頂部，下一大型整合使用New Chat。
