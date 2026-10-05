# RES1-D2：容量／技能方案與正常整合

2026-10-05後續：D2-R1已補丹霞獨立島體／藥坊分層美術與世界／管理双向入口，53/53／最後world38＋管理87及桌面Web子範圍見[D2-R1](res1-d2-r1.md)。下文專用美術尚未交付屬前輪歷史；完整Web新檔／D2保存故障／人工／裝置及C/R2仍待驗，D2保持IN_PROGRESS。

2026-10-05（Asia/Taipei）。**IN_PROGRESS；方案、正常規則／管理接線與 CLI 保存契約已交付，完整 D 尚未放行。** 使用者核定 Era＋設施門檻與新增築基擴容設施，見 [ADR-011](../decisions/ADR-011-era3-capacity-and-skill-gates.md)。R2仍由AGY負責，C／C2／R2維持IN_PROGRESS。

## 交付與資料邊界

- 原聚靈壇每級100、上限10不變。新增築基靈池，聚靈壇2級前置、每階容量1000、上限3；T1工程費100錢／50木／20石、升級費倍率1.5。原庫2級＋新池2級＋基礎容量＝2300，可達突破要求2000；沒有金丹材料前置。
- 正常 `living_abode` 沿既有 `IslandProgression.attach` 載入並驗證新 `content/buildings/era2.json`／`content/eras/era3.json`。基礎 manifest／獨立舊規則載入器仍是Era1/2，不能把裸 ContentLoader 當完整正常初始化。加工資源仍由啟用命令加入單一祖島 resources，不新增另一套 Production 庫存。
- 一般技能／技能點不移植，採Era與設施；`legacy_skill`保留來源記錄，不代表學會技能。宗門功法不充當一般技能。金丹境內沿D1時間／基礎成本／Lv9符咒，丹液1＋陣芯1是v2初始平衡值、節奏待人類驗。金丹丹藥是物品，尚無服用效果，Era4仍無可玩定義。
- 四島管理：丹霞築基可見、金丹開拓，T1木20／石10；初級採集／工坊／倉儲與航運沿B/C開拓包。丹霞產低階／百年草、唯一製丹液，祖島共用靈力支付加工；新增 `liquid_home` 成品回運。原兩條草藥航線保持。青木靈材、玄礦銅精、祖島陣芯／丹藥／中品石／符咒，核心強制唯一加工歸屬。
- 祖島可操作五配方單批／持續加工、完成本批後停止；丹霞可升設施、設定保留／目標／運力。中文名稱排除無字型支援的emoji；丹霞只顯示相關庫存與共用靈力，固定關閉／內部捲動沿既有容器。
- **丹霞專用世界美術與世界入口未交付。** 管理頁可用，沒有借用其他島美術、沒有新增無地基名稱牌。世界仍展示既有三島。

## 保存／遷移

economy `res1-d-2`、rules `core-flow-10-danxia`；schema3形狀不變，原schema2讀取／歸檔契約保持。舊C `res1-c-1`繼續讀取與運轉，不自動改版；接續丹霞時preview只讀、先保存源檔並驗證 `save_before_d2` 原始JSON，候選Session提交成功後才替換live。原 `save_before_islands` 不被取代。失敗重試不重扣加工／工程費，不丟三島工作、貨物、設施或庫存。未知economy、配方／貨物版本仍拒絕。輪迴清除本世產業並保留原economy版本，舊C輪迴不偷升D2。

金丹突破在正常profile要求D2已啟用；修行View與命令使用同一門檻，避免沒有加工資源的存檔走入金丹。舊測試fixture的裸B/D1路徑不被這個正常profile門檻改寫。

## 命令與結果

引擎 `4.7.2.stable.official.ed1daf0bf`，`--version` exit0；沒有升級引擎／模板。PowerShell與Godot命令如下，所有日志在本頁artifacts目錄：

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1d2_integration_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/res1-d2-final-contract.log
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/res1c_progression_runner.gd --log-file E:/WORK/Dao2/docs/verification/artifacts/res1-d2-ui-final.log
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web .\build\res1d2\index.html
& 'C:\Users\asus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/res1d2_preview_server.py
git diff --check
```

| 驗證 | 本輪結果／證据 |
| --- | --- |
| 正常profile D2 Runner | **215 checks PASS、exit0**，[最終獨立日誌](artifacts/res1-d2-final-contract.log)及全量D2子項。空白無Debug／贈料／預置Era／建築／時間，T1建祖業→築基→新靈池2階→金丹→開丹霞→T2→陣芯／丹藥→實際晉階扣料至Lv10，11561模擬秒。先用2靈材＋2銅精升丹霞工坊，再付陣芯原料，驗擴產／修行的實際競爭。 |
| D2保存故障 | 加工／丹液成品貨物進行中快照往返、600秒離線＝線上＝分段完整快照；舊C歸檔拒寫與候選index失敗保留live、重試一次接續且庫存／工作／貨物／設施保持；未知版本拒絕、損壞一代回另一slot；離線提交失敗重試、自然時間推到壽盡後輪迴清除。MemoryAdapter全在隔離資料，非實際瀏覽器quota證據。遷移／破壞邊界使用diagnostic clones，排除可達性證據。 |
| 全量固定入口 | **52/52 PASS、exit0**，[all-final](artifacts/res1-d2-all-final.log)，包含B守恆／運力／容量、D2與既有系統。新D2 Runner已註冊；D1隔離Runner仍獨立，沒有本輪重跑DAO1 audit／D1。 |
| 最後呈現修正 | 全量後調整丹霞顯示範圍／純文字配方名；受影響三島規則及管理UI **87 checks PASS、exit0**，[ui-final](artifacts/res1-d2-ui-final.log)，並以最終Web重新實際操作。未把較早全量當作呈現修正後又跑一次52項。 |
| Web匯出 | 初版與最終 `--export-release Web build/res1d2/index.html`均exit0，[export-final](artifacts/res1-d2-export-final.log)，已確認新JSON在PCK中。自動import／UID由引擎處理，未手改.godot／build來源。音樂companions由既有build/web/audio複製至獨立目錄，未更動正常包。 |
| 文本／差異 | `git diff --check` exit0（CRLF提醒），[diff-final](artifacts/res1-d2-diff-final.log)。保留先前dirty，沒有reset／clean／stash、commit／push。 |

保留失敗記錄：全量沙箱首跑 `user://` log／probe寫入失敗exit1；依專案授权用可寫入權限重跑。第一次授權全量在text_transition_runner新增Era3材料未預置處卡住，確認父子PID與腳本後僅停止本輪程序，exit-1；補UI diagnostic材料後最終52項通過。D2早期測試生成替換／Variant型別／遷移分支位置及測試壽元前置曾失敗；已修正，保留first／second／expanded等日志。初輪C遍歷新增丹霞配方而在Era2嘗試加工，改為明確兩專業島。負面損壞JSON預期報錯與既有RID／ObjectDB退出診斷仍在，不稱日誌零錯誤。PATH Python曾出現real-location提示；後續HTTP用已存在bundled Python，未安裝runtime。

## 真實瀏覽器

IAB、獨立 `http://127.0.0.1:4256/launcher`、normal Web預設 `dao2_saves` namespace；origin隔離，不讀其他origin玩家資料。fixture `res1-d2-earned-era3.json`由Runner空白命令流程在金丹Lv2產生，只種一次；不是手填贈料或從瀏覽器空白完整玩到金丹。瀏覽器操作均用滑鼠點Godot canvas，未直接呼叫遊戲函式代替輸入。

- 桌面父viewport1280×790，iframe實測1280×720.4 CSS px（不是恰好720）；經營→空島→丹霞、中文材料／共用祖島靈力、點持續加工成功，低階草100→95、產物預留1、工坊2階5秒與「操作完成，已保存」可見。[桌面](artifacts/res1-d2-desktop.jpg)。
- 短橫式iframe**實測844×390**；管理內部捲動可到加工操作，固定關閉／返回與四導覽保留；滑鼠「本批完成後停止」，其後「尚未加工」。[短橫式](artifacts/res1-d2-compact.jpg)、[停止後](artifacts/res1-d2-compact-stopped.jpg)。沒有頁面捲軸替代Godot捲動。
- 同origin實際重載，離線摘要正常；回經營後祖島**丹液10**仍在，[重載到貨](artifacts/res1-d2-reloaded-liquid.jpg)。祖島「靈紋陣芯・製作一批」實際點擊成功，保存訊息及19秒剩餘可見；之後**靈紋陣芯1**入庫、靈力容量2300封頂，[T3成品](artifacts/res1-d2-t3-completed.jpg)。數量逐秒變化與實際完整扣料由CLI契約驗證，這組截圖不冒稱完整Web守恆故障矩陣。
- 初版測試包忘了音樂companions，首播BGM警告已保留；補複製並重載後沒有新增此警告。console紀錄仍包含首次警告，不稱整輪zero errors。
- 沒有新的FPS／GPU／高DPR／實機觸控／自然背景凍結／IndexedDB／跨瀏覽器或使用者美術與節奏驗收。Web儲存仍沿既有localStorage，native／MemoryAdapter結果不等於這些門檻。

[尺寸JSON](artifacts/res1-d2-viewport.json)記錄桌面DPR約1；嘗試從父DOM讀iframe canvas backing尺寸時API未提供contentDocument，該讀取失敗，不捏造backing尺寸。CLI／遊戲無此錯誤。瀏覽器[console](artifacts/res1-d2-console.json)保留首次BGM警告。測試結束頁面回launcher、釋放遊戲writer與GPU負載，viewport override已reset，4256服務與隔離進度保留可試玩。

最終D2 PCK SHA256 `f7bb896516d3616175faad682788fe03285553b3b5daf33269c1554cd4fa3fc9`；原正常 `build/web/index.pck`仍為交接基線 `134334491bd68be37fec0cdc292916c5f93020fae986e7ae3a6ecfec5e216eba`。沒有覆蓋AGY的正常Web／profile包；若AGY未來重新export目前來源，必須記明已包含D2，不能稱和舊包同源配對。

## 檔案、剩餘DoD與接續

新增兩份正式JSON、`tests/res1d2_integration_runner.gd`及引擎產生.uid、專屬HTTP工具／驗收／ADR／交接與artifacts。修改island_progression／island_economy／command_processor／reincarnation_rules／GameSession、SaveManager／SaveCodec、island_management_panel／island_world／building_catalog／living_abode／feature_navigation、小範圍C／TEXT1測試前置及固定Runner；沒有TimeAdvancer或R2診斷演算法變更。全量既有入口會重生其既有測試artifacts，這不算玩家進度或新的R2驗收。

共享修改範圍在[單方修改交接](../handoffs/2026-10-05-codex-res1-d2.md)先記錄；未聯絡／啟動AGY，無實際FPS時段協調證據，不冒稱協調完成。工程取得的程序快照不能證明另一位開發者沒有活動。

下一 **RES1-D2-R1**：丹霞專用分層美術與世界入口、正常Web無Debug從新檔完整首段／重開與故障矩陣、人工擴產／運力／修行取捨及辨識度、實機／高DPR與相關C/R2放行。使用者選定技能替代已完成，不需重問；容量工作值／金丹費用仍可依玩法回饋調平衡。D2與完整D不標DONE，C/R2也不因D2程序通過而改狀態。依Context Guard完成此有界接線階段，英文checkpoint置updata頂部，下一大型開發使用New Chat。
