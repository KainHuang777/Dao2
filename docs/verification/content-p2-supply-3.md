2026-10-24 後續整批收結：**CONTENT-P2-SUPPLY DONE**，人工節奏／UI已接受，L3 116／116最終通過；見[整批驗收](content-p2-supply-closure.md)。下方保留本階段原日期、失敗與證據邊界，不改寫原結果。

# CONTENT-P2-SUPPLY — SUPPLY-3 管理、製造與正式入口

日期：2026-10-24。SUPPLY-3 技術子階段 DONE（L1／L2與桌面有界）；整體 CONTENT-P2-SUPPLY 保持 IN_PROGRESS。沒有執行 L3 或交付 Web 候選包。

## 交付範圍

- 正式 `living_abode` 改接 `attach_supply()`。讀取舊檔時先保存同一遷移候選，原文歸檔／讀回成功且雙槽提交成功後，才開始離線結算。`commit_supply_startup()` 保持舊 settled cursor；拒寫覆層只重試保存，保留原候選與離線時間。
- 管理清單可閱讀七島，按實際境界顯示灰色「未開」；成本直接讀核定島資料，依祖島可用庫存禁用。寒銀／古藥／太虛明示地方容量300、當島調度與無加工坊；世界入口禁用並說明目前使用管理清單，不借用既有三島世界美術。左側情境庫存略去無關的零庫存，保留地方／祖島付款與預留。
- 製造共11配方，量產配方、圖格、庫存、在途與詳情統一用 product_id；中品靈石量產仍產出中品靈石，名稱與庫存不再錯用 stone_mid_bulk。摘要只計真正有產線的四島。無專用圖的材料格常駐完整中文名與祖島／當地來源，不留無名空格。新增資源／九設施沿現有中文名稱、字印與共用元件，不新增美術。
- 運輸共12航線，新增五線支援三級。核心輸出 level_cap／upgrade_cost，UI直接讀取；原升階文案2＋2與實際10＋10不符，已修正為權威費用。升階保持已保存啟停、保留量與目標，不提交未保存草稿。
- 修正整合時發現的保存缺口：ResourceLedger／LifeHistory驗證接受三個核定新島 scope，仍維持原版本、筆數與bytes限制；歷世新經濟祖島容量改讀實際有效容量。原白名單會使新島產出後的保存被拒絕，不能只靠零庫存合成測試宣稱可玩。
- 舊故事版本0的 `next_life()` 不生成版本1 facts，避免合法舊檔輪迴後無法保存；正式載入器仍沿既有原文歸檔遷移到版本1，版本1輪迴邏輯保持。
- Session壽盡預檢納入既有延壽丹與BUFF壽元，與TimeAdvancer／正式View一致。未改丹藥效果或R46修行時間。
- 字型補入現有來源新增字元，使用既有 `subset_game_fonts.py` 重建 OFL 衍生字型與manifest；原始字型保持。沒有新PNG美術或第三方素材授權變更。

來源：`src/abode/living_abode.gd`、`src/application/game_session.gd`、`src/persistence/save_manager.gd`、`src/simulation/{island_progression,island_economy,story_progress}.gd`、`src/domain/{resource_ledger,life_history}.gd`、`src/presentation/{island_management_panel,manufacturing_panel,island_transport_panel,feature_navigation,island_world,recipe_row,ui_shell_resources,resource_accounts_view,building_catalog,resource_icon,recipe_material_tile,abode_hud_controller}.gd`；runtime字型兩檔與manifest。新增兩支SUPPLY-3 runner、review fixture／server工具，更新兩支舊UI runner的隔離目錄、新版本／數量斷言與deferred清理等待，登錄固定runner入口。

## L1／L2 命令與結果

所有 selector 執行前均用同一 `-Only ... -List` 預覽。固定入口使用單尺寸政策，沒有 `-Full`。舊UI runner在新內容下各約33／66秒，因此第二支的已確認長測試給90秒；合法流程逐秒模擬約十五萬模擬秒，明確給1500秒，不把原600秒逾時算成功。

```powershell
.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_ui_runner.gd,res1_ui1a_runner.gd,res1_ui1b_runner.gd' -TimeoutSeconds 90
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_ui_runner.gd,m1a_core_runner.gd,resource_accounts_runner.gd,life_history_runner.gd,m3b_alchemy_runner.gd'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_ui_runner.gd,res1b_economy_runner.gd'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'recipe_row_runner.gd,content_p2_supply_economy_runner.gd'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_progression_runner.gd' -TimeoutSeconds 1500
python tools/subset_game_fonts.py --check
python tools/subset_game_fonts.py
# 同版引擎重新匯入後匯出隔離本機測試包
.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release Web build/web-supply3-local/index.html
# 後續只補尾段（使用原長流合法快照，未重跑前段）
$env:DAO_SUPPLY3_RESUME = 'res://docs/verification/artifacts/content-p2-supply-3/earned-era6-level10.json'
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1 -Only 'content_p2_supply_progression_runner.gd,content_p2_supply_ui_runner.gd' -TimeoutSeconds 180
```

證據均在 [本批目錄](artifacts/content-p2-supply-3/)：

- `ui-final-command.log`：三支介面回歸通過；`ui-routes-final-command.log`：當時新UI 62 checks及RES1-B通過，後續調度／未啟用／舊故事邊界補到76項；包含新島產出後保存往返、首次遷移拒寫／原候選重試／游標與離線順序、超過原壽限後延壽仍可推進、三級航線與保留設定。
- `core-final-command.log`：原命令exit1，四支核心依賴已PASS，新UI當時有型別推斷parse error；該UI由 `ui-save-final-command.log` 及後續最終76項補驗，不能把原批次改成exit0。
- `economy-dependencies-command.log`：原SUPPLY-2經濟283項及RecipeRow通過；該輪SUPPLY-2報告先讀取原bytes，另存本批結果後 finally 逐字還原舊報告。
- `dispatch-final-command.log`／`preactivation-final-command.log` 證明調度需先開對應島、未啟用新航線唯讀；後續尾段加入v0／v1故事輪迴斷言後為75項；材料常駐名稱補驗後最終76項。
- `flow-command.log` 原600秒逾時且Era4–6保存失敗；正式修復後重跑 `flow-final-command.log`，此命令1121.9秒走到Era6 Lv10、150253秒，92項中88通過／原輪迴4項失敗（尚未壽盡，測試過早）。保留 `earned-flow-long-before-tail-failure.json`。從已賺得Lv10只補8147秒至壽盡，不重跑前段；首尾段輪迴成功但舊story0保存失敗，保留 `earned-flow-tail-before-story-failure.json`。修正版本0 facts後，`flow-story-tail-final-command.log` exit0：尾段13項及當時UI75項通過；最後材料名稱補驗 `labels-final-command.log` 的UI76項與RecipeRow通過，`earned-flow.json` failures=[]。**不是一次完整命令全綠**；既有前段88項與最後尾段組合證明本階段路徑。
- `fonts-check.log` 原缺4字失敗；重建後 `fonts-final-check.log`、最終 `fonts-delivery-check.log` 成功。`export-font-final.log` 在沙箱字型reimport存取違規（-1073741819），後續正常權限 `import-fonts-retry.log`、`export-font-retry.log` 與最後 `export-delivery-local.log` exit0。沒有更新引擎／模板或手改 `.godot/`／匯出物修來源。
- 後續各輪stdout／stderr留在本批 `logs/dao2_runners_*`；含故意故障注入及沙箱 `user://logs`／既有退出RID、ObjectDB診斷，不宣稱日誌零錯誤。最早三次UI／probe完整暫存log未複製，本輪對話tool輸出與 `initial-failures.json` 保留摘要，不能宣稱所有原始stdout都已保存。

## 合法流程證據

使用既有已驗證 `res1-d2-earned-era3.json`（Era3 Lv2、當世4783秒、skills空），先正式遷移，再以Session命令與TimeAdvancer秒步進取得材料、配方、建築、調度、境內晉階及渡劫。不賦值修煉、境界、庫存或RNG。各階段 `earned-era3/4/5/6.json` 與 `last-earned-level.json` 是命令取得的快照；`review-*.json` 只重封保存UTC／save_id以避免瀏覽器審閱先結算長離線，工具核對state逐字結構相等。

玄龜是已賺得Era4狀態的合法分支：取得後實扣30精鐵＋100下石餵養，再回到同一分支前狀態繼續主線；主線保留空靈獸位至Era6，以實料取得／餵火鳳。兩隻不是同一時間共養；尚未驗成熟／獸魂最優策略。無技能前段長等候與材料供給時間記於 `earned-flow-long-before-tail-failure.json`；最終 `earned-flow.json` 是只補壽盡／輪迴的尾段，不能把它的13項當作重跑全流程。

實際路徑：Era3起點4783秒 → Era4 12183秒 → Era5 26963秒 → Era6 58903秒 → Era6 Lv10 150253秒 → 158400秒壽盡 → 第二世Era1／七島清空。三次既有seed渡劫為80%／70%／60%且本次都成功，不能推論每名玩家首世必達。相對起點前進145470秒（約40.41小時模擬時間），Lv10距壽盡8147秒；量產加工等待4720秒、Era6純等修煉85200秒（其他工作同時累積修煉），不是自然瀏覽器長跑或最優操作。沒有購買技能或灌入庫存／訓練；玄龜為明示分支、火鳳主線一次餵養。

CLI供給長流保留該舊fixture的story／pill／sect子版本0，不冒充當前P1全內容整合自然流程；正式Web載入與首次歸檔已另由SaveManager升版驗證。本批補上v0輪迴保存，是對codec仍允許之舊契約的修復，未以直接改版本繞過驗證。`reborn-readback.log` 的正式codec讀回／重封state相等成功。

## L2 桌面 Web 抽驗

同次來源的本機隔離包 `build/web-supply3-local`；IAB桌面實際滑鼠，遊戲iframe固定1280×720（外層review工具1400×840），未做三尺寸矩陣。自訂Python server只提供匯出物、已賺得fixture與可開關的測試寫入拒絕；不使用玩家origin。48443是舊D2案例，48444是已賺得Era6案例。

- 首次載入拒寫停在保存覆層，舊保存仍D2；取消拒寫後點原地重試，保存升為res1-e-46-1，才顯示52秒離線結算。此項在本輪較早測試包驗證，其startup gate來源與最終包相同；後續改動為顯示、權威費用View與補字。
- 最終包重載後檢查七島、灰色未開、寒銀正確成本與無世界美術／無工坊狀態；[截圖](artifacts/content-p2-supply-3/web-era3-deep-final.png)。
- Era6以滑鼠啟動量產，庫存60→160，產物圖格為中品靈石100；[截圖](artifacts/content-p2-supply-3/web-bulk160-final.png)。
- 十二線摘要、寒銀三回運、10＋10實費、三級上限可讀；一→二級後，二→三級拒寫保護→恢復只保存，[拒寫](artifacts/content-p2-supply-3/web-route-refusal-final.png)、[恢復三級](artifacts/content-p2-supply-3/web-route-level3-final.png)。重載保存仍三級，保留enabled=true、reserve=0、target=3000。沒有把UI信號單測稱作真實滑鼠。
- 初次瀏覽器連線／原生app核准逾時保留；前景終端服務監聽但HTTP逾時，改正常權限隱藏背景Python程序後成功，沒有改防火牆／網路安全設定。首次Godot載入與原地重試需等後續frame顯示，不把AX當下無改變當作失敗或重送命令。

## 邊界與下一步

沒有執行L3，不稱全量回歸；沒有製作交付候選包、變更玩家資料、commit或push。新島世界美術與其他P2批次未開工。最後材料名稱包另於48446抽驗化神丹的千年靈草／秘銀完整名稱與來源、產物名及44px操作；[材料名稱截圖](artifacts/content-p2-supply-3/web-trans-labels-final.png)，console查詢空。最後匯出記錄為 `export-labels-final.log`，本機壓縮伴隨檔已由 `compression-labels-final.log` 更新。

最後本機包再次重載並確認中品靈石160、航線三級及console警告／錯誤查詢空；[最後包截圖](artifacts/content-p2-supply-3/web-bulk160-reloaded-delivery.png)。瀏覽器驗收頁及本輪四個Python服務已關閉。

最終靜態稽核75項／failures=[]與當次包來源hash見 `delivery-audit.json`；首輪只因Godot ANSI色碼令文字比對失敗，保留 `delivery-audit-initial.json`，去除色碼後通過（原始log不修改）。11支唯一相關runner有精選／補驗證據（含上述長流程失敗與尾段組合），不是11支全範圍乾淨命令。

整體供給內容仍需人工整合節奏／本批UI回饋及整批收尾驗收；不要因本輪文件更新再跑遊戲回歸。完成當前階段後依Context Guard交接New Chat。
