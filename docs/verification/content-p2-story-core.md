# CONTENT-P2-STORY／STORY-1 核心與保存驗收

2026-10-27。**STORY-1 DONE（L1＋L2，1280×720預設單尺寸）；整批 IN_PROGRESS。** 使用者明確「採Y，接STORY-1」，[Y1／Y2／Y-save／Y-art](../40-content-p2-story-design.md)全部核定。美術製作計畫核定不等於20張實際圖已生成／接受。下一步為同批 STORY-2。

## 交付

- 正式48成就／56機緣；本批新增六類各3成就、18題／54分支。標題、全文、固定費用、結果與獎勵逐項對照核定JSON，沒有額外道心／道證／魂／技能點。事件維持權重60、人界／當世Era4–6資格、單獸互斥及免費離開；保留既有觸發頻率與單一待決。
- story_version=2、schema5、rules `core-flow-24-content-p2-story`；內容identity納入實際成就／機緣hash與`+content-p2-story`。其他子版本與各自驗證保持；歷史rules分支另用明確story1 fixture驗證。
- 固定`p2`物件保存起點及終身／當世六mask。只有正式親煉、有效服丹、祖島實際正到貨、委託領獎、市場購買、活動獸成熟會設bit；交易不偽造行為，委託派遣／完成不等於領獎。三島委託按指定群組判斷，護劫備材歸寒銀。輪迴僅清當世，終身／已解鎖／已領保留；DEBUG全成就重置同清新facts。
- v0／v1→v2保留舊30成就、P1事實、原待決全文／instance／digest／資格及既有獨立RNG。v0補合法RNG；P2行為清零，僅當前成熟的單獸可以補記，不以舊庫存或累計統計補造歷史。
- 原JSON逐字hash歸檔／讀回後才能提交同一候選；原文、主／備槽、讀回或索引故障保留保存閘。命令、在線／離線及再次匯入均受保護；損壞歸檔先另存損壞字節並讀回，再重試同一原文。其他子系統歸檔不互蓋。
- 整筆交易用Amount核對`after=before-paid+gain`；故事交易使用精確元件比較，修正通用近似比較把大庫存cap+1視為相等的問題，未改通用Amount。高階資源沿IslandEconomy祖島容量與在途預留，付款後驗容量，拒絕部分入庫、微小缺料及不可表達的扣／收益。免費離開不受滿倉限制。
- P2修煉助益先拒壽盡／零缺口，僅補當級缺口；回執v1增加P2限定的nominal／gained／overflow，既有回執原格式仍合法。不快轉世界時間、壽元、冷卻、物流、派遣或丹藥衰減。

## 修改檔案

| 範圍 | 檔案 |
| --- | --- |
| 資料／成就 | `content/encounters/encounters.json`、`src/simulation/achievement_system.gd` |
| 純事實／資格／交易 | `src/simulation/story_progress.gd`、新增`story_progress_p2.gd`及引擎產生的`.uid` |
| 成功觀測點 | `src/simulation/beast_system.gd`、`sect_system.gd`；既有alchemy／online／offline到貨均沿StoryProgress入口 |
| 事件與回執 | `src/simulation/fortune_system.gd`、`src/domain/decision_receipt.gd`、`src/application/game_session.gd` |
| 內容與保存 | `src/content/content_loader.gd`、`src/simulation/island_progression.gd`、`src/persistence/save_codec.gd`、`save_manager.gd`、`story_save_contract.gd` |
| 新runner | `tests/content_p2_story_runner.gd`、`content_p2_story_save_runner.gd`、`content_p2_story_events_runner.gd` |
| 依賴測試metadata | P1 story runner、P2 beasts／pills／sect save runner、P2 supply economy、SKS P2 core；更新目前總數／rules，獸保存runner用story1驗舊rules分支 |
| 工具／文件 | `tools/run_all_runners.ps1`新增三runner並加UTF-8 BOM相容Windows PowerShell5；`tools/story1_evidence.py`、`story1_audit.py`；核定proposal、方案40、README／ROADMAP／AI交接／狀態／內容計畫與`updata.txt` |

未改Godot呈現場景／世界、PNG、既有技能／丹／獸／宗門定義數值、引擎或凍結Web包。交付稽核依設計階段1405份基準核對，19份明列來源／測試變更，其餘hash保持；既有dirty成果保留。

## 命令與結果

引擎版本：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`，exit0。`--headless --path . --editor --import --quit --log-file .tmp/story1-import.log` exit0；保留user目錄診斷，沒有重裝／更新引擎。註冊新class使用引擎正常import，未手改`.godot`。

每組執行前均用`tools/run_all_runners.ps1 -Only '…' -List`預覽；下面選取均非Full。新三runner為L1；共用保存／時間／宗門／丹藥／獸／回執依賴超過5支，因此後續按L2精選，不擴全量。

| 級別／精選範圍 | 結果 |
| --- | --- |
| L1 `-Only 'content_p2_story'` | 3／3 exit0；核心1305、保存最終557、事件547 checks，均`failures=[]`。保存新增型別／邊界檢查後只單支補驗，未重跑整域 |
| L2 11支完整檔名精選（見下方） | 原命令exit1：10支通過，M1-C隔離預設user目錄寫入失敗；原日誌保持 |
| L2 `-Only 'm1c_persistence_runner.gd'`，`DAO_TEST_STORAGE_ROOT=E:\WORK\Dao2\docs\verification\artifacts\content-p2-story\isolated-storage` | 同一來源，專案內隔離磁碟路徑補驗1／1 exit0；不是玩家存檔 |
| L2 `-Only 'sks_p2_core_runner.gd'` | 1／1 exit0；更新rules24預期，其餘技能契約保持 |
| 靜態 `python tools/story1_evidence.py backup`／`restore` | 28312份既有verification JSON核對，1份差異先封存再逐字復原 |
| 靜態 `python tools/story1_audit.py` | 1522 checks，`failures=[]`，1405份既有來源／資產／測試／設定／凍結包核對 |
| 靜態 `git diff --check -- <本次來源／測試／文件>` | exit0；LF→CRLF提示不是內容錯誤 |

L2原11支：`content_p1_story_runner.gd`、`content_p1_story_events_runner.gd`、`content_p2_pills_runner.gd`、`content_p2_pills_save_runner.gd`、`content_p2_sect_runner.gd`、`content_p2_sect_save_runner.gd`、`content_p2_beasts_runner.gd`、`content_p2_beasts_save_runner.gd`、`content_p2_supply_economy_runner.gd`、`decision_receipt_runner.gd`、`m1c_persistence_runner.gd`。完整命令在[原始日誌](artifacts/content-p2-story/logs/story1-l2-first-command.log)。合計**15支唯一runner最終分段通過**，不是單次全綠或全量回歸。

新三runner的[核心結果](artifacts/content-p2-story/core.json)、[保存結果](artifacts/content-p2-story/save.json)、[事件結果](artifacts/content-p2-story/events.json)與[交付稽核](artifacts/content-p2-story/delivery-audit.json)均保留。全部可用原stdout／stderr及原失敗命令已複製至[logs](artifacts/content-p2-story/logs/)，未將失敗結果回寫成成功。

## 證據範圍與原失敗

- 54分支全部透過正式Session命令成功／重送／再決策拒絕；逐付款資源缺料、微小缺料、不可表達付款、逐收益滿倉／部分空間／精度、壽盡及零修煉缺口均驗原子性。18成就正式領獎／再領拒絕及滿倉／精度／壽盡已有精選證據。
- 八丹親煉與服用、十模板派遣→未完成拒領→完成仍未設bit→領獎、兩市場首購、五航線實到與online／offline／prepared路徑已有**出資fixture**證據。四獸以950XP fixture做最後一次正式餵養及正式壽盡輪迴，驗四個不同世次的成熟位元；不冒充自然養滿或新檔自然進程。
- 滿倉航運依法阻止出發；另測觀測器delta=0不設bit。初版把「已滿倉仍塞入超容量在途貨」當合法狀態的測試已修正，沒有藉此修改物流經濟，也不聲稱正常系統會接受該非法狀態。
- 首輪測試曾因不完整建築容量fixture、保存fixture缺成就字典、以及近似Amount比較失敗；已修正來源／fixture並補驗。PowerShell5把無BOM腳本的全形標點讀錯，造成FAIL正則解析中斷；補BOM後執行正常，未算原命令成功。第一次錯誤的註冊指令及selector失敗亦保留於本次命令紀錄／交接界線。
- 預設`user://logs`在沙箱不可寫診斷與負面匯入預期錯誤仍保留。M1-C最終改用其既有`DAO_TEST_STORAGE_ROOT`隔離入口通過；未要求擴權或寫玩家進度。
- 保存測試覆蓋v0／v1載入與匯入、原文寫／讀／損壞讀回、主／備槽／索引、同候選多次拒寫／恢復、第二次匯入鎖、命令與在線／離線鎖、其他子版本共同升級、損壞／未來雙槽保護；4／16／12KiB限額保持。P1待決與RNG精確保留、P2 pending篡改與未知ID／型別／mask／subset／起點檢查均已驗。

## 未通過項與下一任務

STORY-1指定CLI／核心保存範圍沒有未解失敗。**20圖尚未生成／未接受，正式卡片／自然代表流程與桌面Web尚未驗；整批不標DONE。** 本輪未跑L3、全尺寸、Web匯出／壓縮、瀏覽器、FPS；沒有commit／push。既有長時WebGL限制保持，未宣稱修復；實機項延期且非當前阻擋。

下一New Chat直接接**STORY-2**：18徽章＋2透明題圖、正式View與成本／實得／捨棄可讀呈現；合法已賺得Era4–6起點的代表行為→成就實領，至少自然時間觸發一題P2機緣，決策保存重載；L2單尺寸原生與當次包桌面滑鼠拒寫／再次重試／恢復／重載／返回。各ID合成資格與自然代表證據分列，不等待自然抽齊18題，不重問Y。使用者接受圖／卡片／文稿／節奏後才做本批唯一L3。
