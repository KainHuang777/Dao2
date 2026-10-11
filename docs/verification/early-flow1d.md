2026-10-10 **EARLY-FLOW1-D 自然流程有界 PASS；完整 D 仍 IN_PROGRESS**：同一隔離Web進度、真實滑鼠與自然時間，築基一層／F7→十層→金丹→丹液加工回運→中品石50／陣芯1→金丹二層→靈狐首次餵養成長50及最終重載通過。修復築基圓滿主突破按鈕隱藏與離線累計年歲標示；D132、R2 HUD52、B110、responsive、M2-B／離線回歸及Web匯出壓縮exit0。約41分鐘至十層、中品石规则500秒；全觀測約69分鐘含修復／診斷，非純玩家預算。使用者決定「先保留基線，試玩後判定」，未調成本或工時。人類節奏／實體觸控／高DPR仍待驗；R2有界DONE保持。下一New Chat收試玩節奏／裝置結果，不開R3或後段、不重做已過保存／FPS。較早自然流程待驗聲明保留為歷史。
[本輪驗收與證據](early-flow1d-natural.md)

# EARLY-FLOW1-D：可延後支線與金丹首段

日期：2026-10-10。**IN_PROGRESS：F5–G4來源與CLI接入；桌面Web有界驗證，整段自然時間／人類接受／實機仍待驗。**

## 交付

- `src/simulation/onboarding.gd`：F1–F4完成後主目標進F7；F5技能／F6宗門並列可選，不需完成或等任務領獎才突破。藏經閣木200／金錢500庫容瓶頸有說明與入口。F7讀正式View容量，區分聚靈壇2前置與築基靈池；不要求金丹道具或庫存滿倉。
- Era3首層依丹霞開拓、地方丹液製作／回祖島、祖島中品石50與陣芯1、實際扣料晉階推進。製造目標帶島／配方，丹液完工或在途時帶`liquid_home`；祖島單產線須串行。材料仍缺少時不宣稱可晉階。
- G4可選結契／首次餵食；取得靈獸不等於餵食。首次靈狐餵食仍為靈卵，50經驗、草50、基礎冷卻300秒。已有層級／技能／獸階直接讀現況，不倒退到練氣或雙島歷史。輪迴依原規則清除當世狀態。
- `src/presentation/abode_hud_controller.gd`、`island_world.gd`：主目標、可選技能／宗門與「說明」入口；明確展開說明時暫收島際導航，收起後恢復。沿用Godot容器、滾動內容、44px操作與現有canonical routes，未加世界名稱牌或HTML遊戲核心。
- 新增`tests/early_flow1d_runner.gd`與UID、註冊固定入口；C測試原本完成後停止的預期改成F7／G1。兩份runtime字型與manifest更新。開工前B／C未提交變更保留，未commit／push。

## 狀態與保存選擇

沒有新增存檔schema、支線略過偏好或永久介紹紀錄。「稍後」就是直接前往主目標，支線原頁隨時可進入；不需要點關閉才能解除門檻。F7資格／G3材料讀當前狀態；液體已被花掉但仍在金丹一層時，提示補足下一次晉階所需庫存，沒有捏造到貨歷史。G4讀已存的獸階／經驗，跨重載保留；命令／保存重試／演出都不另發獎。

## 命令與結果

Godot `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：4.7.2.stable.official.ed1daf0bf，exit0。`--headless --path . --editor --import`與正式Web `--export-release Web E:/WORK/Dao2/build/web/index.html`通過；最後匯出見[log](artifacts/early-flow1d/export-final.log)。bundled Node `tools/prepare_web_compression.mjs build/web`準備壓縮與BGM companions，exit0；[log](artifacts/early-flow1d/compression-final.log)。bundled Python `tools/subset_game_fonts.py`產生1828 codepoints的字型衍生物，原字型不改；[log](artifacts/early-flow1d/fonts.log)。

powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1全量59/59 exit0（含early_flow1d_runner 118 checks exit0與early_flow1b 110 checks exit0）；Godot 4.7.2 Web release匯出、bundled Node壓縮與字型子集1828檢核均通過 exit0。

D專項正常命令起點為C已驗的空白命令築基檔，往後不直接指定境界、層級、庫存或修煉進度。兩島真實完工／回運、F7不學技能／不入宗門到金丹、G1–G3實付五種料、G4實扣草與冷卻、分段重載、拒寫重試、損壞世代復原、舊檔／輪迴、精確路由與三版型說明都有測試。正常模擬累計4200秒含C築基起點的練氣時間，**不是Web自然時間或新玩家節奏**。另分支以正常成本建閣學冥想、加入／派遣宗門，證明支線可完成且不改F7。

初次沙箱`user://`日誌／儲存拒寫導致C UI未啟動；改正常授權隔離測試後C104 exit0。D初跑輔助器缺content、錯任務command名稱與錯場景路徑、後續錯屬性名稱都有保留log；修正後才取證。既有Font／CanvasItem／ObjectDB退出診斷仍在，損壞JSON的預期拒讀亦有ERROR，不宣稱日誌零錯誤。沒有auto-review拒絕。

## 真實瀏覽器與未通過項

CUA IAB、DPR約1，使用三個新隔離origin，玩家4175未觸碰。每個origin只seed一次由正常命令產生的fixture；重载僅按Play，不覆寫既有進度。

- 48175：`--fixture early-flow1d-ready.json`。從CLI已備料的金丹一層開始，真實滑鼠晉階二層、結契靈狐、餵食一次。畫面實際為靈卵／成長50／冷卻倒數，[首次餵食](artifacts/early-flow1d/web-first-feed.jpg)、[844](artifacts/early-flow1d/web-egg-844.jpg)、[800](artifacts/early-flow1d/web-egg-800.jpg)。直式旋轉遮罩及回橫式、真實重載在本輪驗證；最終證據於收尾補記。
- 48176：`--fixture early-flow1d-foundation.json`。F7「說明」真正可打開，可選技能能定位木料庫未建／容量不足；[說明](artifacts/early-flow1d/web-f7-details.jpg)。這只驗可選入口與目前主目標，不是整段自然築基1→10。
- 48177：`--fixture early-flow1d-golden.json`。真正開拓丹霞、地方丹液10秒完工，主目標帶入正確配方與回運航線；[完工](artifacts/early-flow1d/web-liquid-completed.jpg)。後續到貨／祖島加工的實際結果於收尾補記。

服務命令：bundled Python `tools/island_preview_server.py --port <48175|48176|48177> --normal-build --gzip --fixture <上述檔名>`。這些是CLI正常命令earned checkpoint起點，不是Debug／贈料；也不能當作完整新檔F5–G4自然通關。

**DoD尚缺**：同一正常玩家進度從F7築基準備到G4的整段自然等待／壽元餘裕與人類節奏接受；實體觸控／高DPR。完整EARLY-FLOW1、原UI1-C／C／D門檻不提升。不重做已通過FPS／保存矩陣，不因暫緩冷啟動阻擋。

依Context Guard於本接入／有界驗證階段checkpoint，下一New Chat仍續EARLY-FLOW1-D剩餘自然流程與回饋；不展開Era4或其他大型任務。
