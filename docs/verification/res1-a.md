# RES1-A：資源／配方與加工核心

2026-10-03。**DONE：首批內容契約與隔離 Craft 核心範圍**。相依 M0-B/C、M1-A/B、RES1-DESIGN 已具備；正式多島經濟／保存放行另依 RES1-B–D、M1-C/D。沒有新增 UI、島場景或正式升境資料。

## 內容與依賴契約

`content/recipes/era1_3.json` 為版本 `res1-a-1` 的 opt-in 契約，15 資源、8 配方。正式 manifest 仍為 7 資源、10 建築、Era 1–2；不能把契約計數寫成已上線內容。第一批刻意不涵蓋獸晶／妖丹／技能點等全部 Era 1–3 支線。

| 產物／ID | Era／每批投入→產出 | 設施門檻 | 來源與消耗 |
| --- | --- | --- | --- |
| 築基丹 `foundation_pill` | 1／靈草 50＋玄銅 20＋靈力 200→1 | herb_farm 3 | 延續現有 v2 Alchemy 成本；可服用、作金丹原料 |
| 銅精 `bronze_essence` | 2／玄銅 10＋下品靈石 5→1 | stone_mine 3 | DAO1 配比；陣芯原料，C 運輸／產業升級契約 |
| 丹液 `liquid` | 2／靈草 5＋靈力 50→1 | herb_farm 3 | DAO1 配比；後續丹藥／修行需求契約，實際消耗待 D |
| 中品靈石 `stone_mid` | 3／下品靈石 5＋靈力 10→1 | stone_mine 3 | DAO1 配比；金丹原料、Era3 境內消耗契約 |
| 金丹 `golden_core_pill` | 3／築基丹 3＋百年靈草 2＋中品靈石 5→1 | herb_farm 3 | DAO1 配比；Era4 晉階來源需求，正式效果／消耗待後續 |
| 符咒 `talisman` | 3／木 10＋下品靈石 5＋靈力 50→1 | stone_mine 3 | DAO1 配比；Era3 Lv9 特殊消耗契約 |
| 靈材 `spirit_timber` | 2／木 10＋下品靈石 5→1 | hut 2 | v2 新配方；陣芯原料、C 倉儲／碼頭升級契約 |
| 靈紋陣芯 `formation_core` | 3／靈材 2＋銅精 2→1 | hut 2 | v2 新配方；D 修行／產業升級契約 |

本表設施門檻使用已存在且只需 T1 建成的建築，代表 A 命令可驗的前置；B/C 再映射島工坊／精煉爐，不把現有建築重複結算。靈材／陣芯配比與每項隔離上限 1,000,000 是 v2 工作值，未經玩法平衡。A 即時整批加工；批次時間、重複製作、原料保留量、產物空間保留與停止／切方語意屬 B。

| 原料 | 來源 | 首批需求／後續需求 |
| --- | --- | --- |
| 靈力 `lingli`、金錢 `money` | 既有洞府供給；首段全域 | 加工、建造與修行；不要求搭船 |
| 木 `wood` | 既有林場；C 青木島另有唯一生產者 | 靈材、符咒、建造／倉儲 |
| 下品靈石 `stone_low`、玄銅 `black_copper` | 既有礦業；C 玄礦島專業供給 | 銅精、靈材、中品靈石、築基丹、符咒 |
| 靈草 `spirit_grass_low` | 既有 herb_farm；D 丹霞島 | 築基丹、丹液與現有煉丹 |
| 百年靈草 `spirit_grass_100y` | D Era3 丹霞島靈植產線契約；A 未新增自動產率 | 金丹原料；DAO1 golden_core_formation 技能來源保留於 fixture |

DAO1 Era2 境內技能為 basic_meditation:5，Era3 為 foundation_building:5 或 golden_core_formation:5；Era3 晉階基礎材料含靈力 2000／金錢 500／中品靈石 50，Lv9 另有符咒 10。來源原欄位完整保存在 fixture，沒有將它們誤接成 v2 已存在的宗門技能。首批六項舊配方本身沒有 prereq_skill／丹方學習 gate；百年靈草的舊來源技能與修行技能仍須在 D 建立正式取得／學習路徑。A 的 `skills` 必須空白，非空明確拒載，避免忽略未知前置。

內容驗證檢查版本、正數 Amount、資源引用、有效設施、來源／用途宣告、Era 一致與依賴閉包。各 Era 從已宣告可取得的 T1 起算，拒絕循環及「Era2 配方依賴 Era3 材料」。測試由 T1 開始實際合成 T2→T3、築基丹→金丹，不預載加工中間物。這是**宣告圖及命令的無死鎖證據**，不等於空白玩家已可取得 D 的百年靈草或進入正式 Era3；完整無 Debug 遊玩在 C/D 驗。

## 命令、庫存與 Amount

沿用 `GameSession.submit`，命令為 `craft`，payload 包含 `recipe_id`、正整數 `count`（1–1,000,000）、`recipe_version=1`。成功原子扣料／入庫、更新 revision 並保存既有最多 256 筆命令收據；拒絕不改任何 state。過時 revision、未知 ID／版本、缺設施、未解鎖、缺料、滿倉、不支援 Amount 均有命名錯誤。不截斷批數、不夾掉產物、不用動畫或 RNG 發獎。收據沿用有限去重窗口，不承諾永久歷史防重送。

`ProcessingInventory.read` 統一讀 `state.resources`，回傳 Amount 副本。築基丹的 `state.pills.foundation_pill` 只作相容鏡像，讀取不相加；兩處不一致時拒絕 `INVENTORY_CONFLICT`，不猜測哪份舊資料正確。Craft 消耗／產出築基丹同步鏡像。靈晶／靈液的 realm float 不在首批配方，讀取此類缺正式 slot 的 ID 明確拒絕；其 Amount 遷移屬 B。其他既有 Alchemy／Realm 操作未在 A 全面改写，不宣稱舊進度已完成庫存遷移。

本輪支援非負 layer 0、數值 ≤ 1e12 的庫存／費用／產物；科学記號解析後落在此範圍可用。更高層／超界明確拒絕，不借近似減法承諾完整大數。費用與容量在此支援域內嚴格比對 mag，避開 `AmountCompat.compare_to` 的相對近似相等造成滿倉超收／大額少付。未修改既有 Amount 全域契約。

正式 ContentLoader 不自動附掛 `processing_catalog`，release 對 craft 回 `PROCESSING_NOT_ENABLED`，不增加另一份玩家存檔。不將未驗地方庫存／時間的新經濟混入現有 schema 2。B 必須把資料納入正式 manifest／content hash、rules/schema 版本，提供舊中央庫存映射、鏡像衝突預覽與復原、重試及未知配方處理，才可開啟。A Runner 只用記憶體隔離 Session。

## 舊規則參照與明確差異

fixture `tests/fixtures/legacy/res1-a-source.json` 固定 Resources／eras 等 CSV，以及 craft.ts、recipe.ts、ResourceManager.ts SHA-256。`res1a_reference.test.ts` 在 Dao2 讀取原純規則並驗 hash，8/8 PASS；未啟動 DAO1 遊戲、未寫來源路徑。六項配方無加成／無暴擊的參照向量、暴擊 3×、0.5 加成得到 9、容量夾到 4、epsilon 允許 9.995 支付 10、丹方 gate 已執行。

runtime 使用 Decimal，而 craft.ts 純規則使用 number；runtime 暴擊依 Math.random，純規則可注入隨機回呼。兩者都包含相對費用容差、加成與產物夾限；此次讀碼與純規則向量不代表全套 Manager Decimal 大數 runtime parity。

v2 A 工業材料與金丹採固定產量、全批成功或拒絕、嚴格足額，不承接舊 epsilon／暴擊／heavenly_craft／建築／宗門／靈獸加工加成。築基丹維持現有 Alchemy 的 50 草＋20 銅＋200 靈力以及服用 +10% 當世產率；DAO1 的 3 草＋50 靈力 fixture 原封保留。金丹目前只是加工材料，不新增或猜測可服用效果；既有聚靈丹／延壽丹保留現有規則。未宣稱丹藥或法器加工全量 parity。

## 檔案、命令與驗證

新增：content/recipes/era1_3.json、src/content/processing_catalog.gd、src/simulation/processing_inventory.gd、processing_system.gd、tests/res1a_processing_runner.gd、兩個 legacy fixture／reference 檔、本驗收。修改：GameContent opt-in 屬性、GameSession 白名單、CommandProcessor 分派、全量 Runner 入口及狀態／來源／差異／交接文件；保留已有未提交設計變更及 Godot UID。

環境：Windows／Godot `4.7.2.stable.official.ed1daf0bf`；Compatibility，未更動引擎與模板。

| 命令／日誌 | 實際結果 |
| --- | --- |
| `Godot_v4.7.2-stable_win64_console.exe --version` | exit 0，同版 |
| `--headless --path . --import` | exit 0，但四份既存 world-text PNG 損壞匯入失敗、根憑證讀取診斷；不可稱匯入全數成功 |
| `--headless --path . --script res://tests/res1a_processing_runner.gd` | 首輪 JSON float／int membership 誤判，第二輪發現近似比較滿倉錯誤；修正後 138 checks，再補驗最終 **145 checks PASS、exit 0**；見 [最終日誌](artifacts/res1-a-processing-final.log) |
| `vitest.cmd run --root E:/WORK/Dao2 --reporter verbose tests/fixtures/legacy/res1a_reference.test.ts` | **8/8 PASS、exit 0**；見 [DAO1 日誌](artifacts/res1-a-legacy-reference.log) |
| `powershell -NoProfile -ExecutionPolicy Bypass -File ./tools/run_all_runners.ps1` | 首次沙箱阻擋既有 user:// fixture，exit 1；正常授權重跑 **42/42 PASS、exit 0**，見 [日誌](artifacts/res1-a-all-runners-authorized.log)；最後追加檢查後再次 **42/42 PASS、exit 0**，見 [最終日誌](artifacts/res1-a-all-runners-final.log) |

仍有沙箱 user:// log／根憑證診斷、既有負面資料預期錯誤及 Font RID／CanvasItem／ObjectDB 退出診斷，不宣稱零錯誤日誌。本輪不涉及 UI／Web 匯出，未使用瀏覽器，也未宣稱 IndexedDB、裝置、離線加工或玩家保存驗收。

下一任務 **RES1-B**：批次時間、地方庫存、固定航線、產物容量保留、版本遷移／離線／輪迴与故障重試；正式啟用前補相交的 M1-C/D。依 Context Guard 將英文 checkpoint 置於 updata.txt 頂部，使用 New Chat 接續。
