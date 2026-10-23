# REPORT-2：歷世比較與有界同齡觀測

日期：2026-10-22（Asia/Taipei）。**DONE（CLI／原生／桌面 Web 有界）。**

範圍依 [整合計畫](../27-life-report-and-decision-ux-integration-plan.md) 與 [ADR-016](../decisions/ADR-016-bounded-life-history.md)。沿用九世／352 KiB，不改收益／RNG／原轉世流程，不將舊世未記錄資料補造為零。

## 修改檔案

- `src/domain/life_history.gd`：有界觀測、容量隔離投影、壓縮、驗證、精確區間讀取與 Amount 等價檢查；`life_ledger.gd` 接選填子版本、型別正規化與封存預算。
- `src/application/game_session.gd`、`src/simulation/command_processor.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`reincarnation_rules.gd`：新遊戲／成功命令／原時間邊界／清空前觀測及原道果收據封存。不切割原經濟運算、不增 RNG。
- `src/presentation/life_history_view.gd`、`life_history_plot.gd`、`reincarnation_panel.gd`、`abode_modal_manager.gd`、`src/abode/living_abode.gd`：正式歷世分頁、同單位比較、區間／表格／凍結小傳與簿冊重讀，保存故障仍可讀。
- `tests/life_history_runner.gd`、`life_history_ui_runner.gd`、`resource_account_assertions.gd`、`src/verification/res1d2_contract.gd`：新專項與既有比較契約。數值字串以 Amount 比較；經濟／RNG其餘欄位維持精確快照。
- `src/verification/life_history_fixture.gd`、`life_history_acceptance.gd/.tscn`、project／export preset／固定 runners：完全隔離合成資料，非自然玩法或玩家進度。
- 沿既有字型來源／OFL與生成工具更新 runtime subset；沒有新增圖形資產或第三方素材。

## 命令與結果

使用既有 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，`--version` 為 `4.7.2.stable.official.ed1daf0bf`。各命令 APPDATA 都指向專案 build/report-2-*，沒有讀寫玩家保存 origin。

| 命令 | 結果／證據 |
| --- | --- |
| Godot `--headless --path . --import` | 版本／import 原始日誌在 artifacts/report-2/logs。保留既有診斷，並非所有 ERROR 字樣為零。 |
| Godot `--headless --path . --script res://tests/life_history_runner.gd` | 最終專項 **282 checks、failures=[]**，見 all-verified.log 首項：真實觀測、同齡／Amount線上離線、缺資料、80,000祀、6KiB／16點／12列、未知版本／非法Amount與順序、完整重載、保存拒寫／再試／兩代復原、容量加成不初始化遊戲、最近九世及原總額度。 |
| Godot `--path . --script res://tests/life_history_ui_runner.gd` | 最終原生 **58 checks、failures=[]**，三尺寸圖、44px選擇器／選單、整圖可捲入閱讀視窗、區間切換、空紀錄清除舊圖／空選單、取消確認、保存保護歷世可讀、世界時間刷新不重建開啟中的選單。完整全量前段的UI為56項，最後兩項選單保護於ui-menu-native.log／ui-menu-headless.log追加至CLI／原生58，不倒填舊日誌。PNG是原生證據。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 固定94項分段驗證：all-verified.log前42項；all-verified-tail.log的PERF／資源回饋2項；all-verified-time-tail.log由M1-B續跑通過35項；skills-B1同解析度契約修正後由all-verified-skills-tail.log收最後15項。舊宗門UI fixture修正另以sect-fixture-final.log覆蓋當支結果，最後15項exit0，完整固定94／94分段通過；各支最後結果SCRIPT ERROR0，舊4筆明示保留而非稱整份歷史日誌為零。 |
| `python tools/subset_game_fonts.py`／`--check` | 首次check缺7字，依既有工具生成後check exit0。原字型與授權不變。 |
| Godot `--export-release Web build/web-report-2/index.html`／`LifeHistoryAcceptance build/report-2-acceptance/index.html` | 兩包初輪與交付候選 export exit0，壓縮與四 BGM companions exit0；最末menu兩包再次匯出／壓縮exit0，menu-export-exits.json與final-manifest.json記錄最後hash。 |
| `python tools/ui_shell_server.py --build build/report-2-acceptance --port 4405` | 既有127.0.0.1隔離服務供桌面IAB。沙箱服務無法從瀏覽器連入；以相同命令在允許的本機環境啟動後成功。沒有改防火牆／網路設定。 |

## 真實桌面 Web

IAB／滑鼠，隔離 origin4405；遊戲 iframe 三橫式1280×720、844×390、800×360。外層尺寸／拒寫／state output是既有驗收工具，正式頁仍為Godot。

1. 從輪迴點「歷世」，選第二世及祖島靈木；80,000祀完整軸，最末觀測區間78,000–80,000祀顯示庫存331→337／總容量150，沒有以容量推論溢出或改寫合成數據。選單實際滑鼠命中、區間切換與內捲可讀；三尺寸保持固定分頁。
2. 844選第一世，明示未有紀錄、不補造曲線；閱讀與一次轉世確認後取消，完整ledger JSON與baseline完全相等。
3. 拒寫後再正式確認：輪迴計數2→3、道心仍20、archive2→3（此合成第三世原收益0）；原保存保護中可選第二世／長壽資料。拒寫再試，完整archive保持相同，不再封存或發獎。
4. 保存保護三尺寸可選世／內捲且重試固定。恢復寫入→原重試→既有演出；完整archive仍相同。重載後count3／heart20／archive3，封存完整JSON完全相等。背景重試可沿原流程推進新世，不能把新世時間變動誤認為舊世改寫。

Web截圖在工具對話紀錄，磁碟PNG均明示原生截圖。最終包再次重載仍count3／heart20／archive3，完整封存完全相等；缺資料頁無空資源選單、無假零數量軸。console查詢保留一筆來源未歸屬的MutationObserver TypeError，沒有乾淨console聲稱。見[瀏覽器觀測](artifacts/report-2/browser-observations.json)，不以發出命令代替成功。

服務4405已在自有session以Ctrl+C停止（exit1為主動終止）；成功驗收分頁已關閉、viewport override已reset。兩個早期失敗data-URL分頁因URL存取限制無法由工具關閉，仍列於暫時分頁清單，未冒稱已清除；正常驗收分頁與遊戲保存皆不受影響。

## 失敗與修正

- 首次讀檔輸出過大被截斷，後續改按範圍讀取；`rg docs/26*` 等 PowerShell glob不成立，改用實際檔案／目錄查詢。
- 初次 import 的 `scale` 與 Control 原屬性衝突、錯誤的 ResourceIcon 類名已修；原始 import-initial.log保留。
- 新測試誤用 GameState.clone、對null容量呼叫Amount、輪迴後未解鎖wood的fixture，造成script error與程序停留；均修正前置／API並重驗，未放寬正式規則。自有失敗session以Ctrl+C終止；CIM程序查詢遭環境拒絕，沒有因此停止其他程序。
- 第一版短橫圖高144超過閱讀區，改compact72並加完整圖可見檢查。空紀錄替換會清除舊圖／選單；缺觀測不再給假0數量尺度。
- 全量初輪res1b與後續D2比較直接比完整觀測字串，浮點尾數於Amount精度內仍判不同。新增逐點同齡／種類／null／Amount檢查，原經濟與RNG仍精確；沒有跳過history。早期分段與失敗完整保留於 all-initial／all-resume／all-resume-d2.log。
- 保存保護現在同時含當次結果與歷世簿冊；原兩支UI測試以整棵樹僅有一個簿冊判定，已改核對可見且對應同份權威收據／帳目的閱讀元件，沒有削減保存不重扣檢查。首次測試修改誤取空的pending report，已改取當次權威decision book，原script error與中斷日誌保留。
- 容量投影複核發現舊study_cap helper本身也會初始化遊戲，且已合成容量後再次呼叫會重算加成；去除此重複呼叫，乘區全部在隔離projection求值。專項以明確空chrono／beasts字典驗證完全不初始化原狀態，282項重驗通過。
- RES1-C2 PERF參考算法直接呼叫`_advance_legacy + IslandEconomy.tick`，原本沒有新增觀測而使history快照不同；補接相同的提交後觀測，保留未快取參考算法及精確經濟／RNG／貨運快照，不以刪除history掩蓋失敗。固定全量分段覆蓋全部94項，含42項前段、2項中段、35項時間／後續系統段，以及技能起最後15項，原失敗日誌保留，沒有偽造單一乾淨94項log。
- M1-B原比較將兩種合法解析度直接視為同份歷史：單次600秒聚合只有起終2點，十次60秒則有11點。保留整份經濟／RNG／資源帳精確快照，另外驗證兩份history、明確點數及共同起終點；不為補圖切割舊經濟演算法。
- Skills-B1也包含3100→3160秒的舊聚合／逐秒對照；逐秒真實觀測3120，聚合路徑沒有此點。依同一契約驗證合法稀疏解析度、所有共同歷史點精確相同與完整經濟／RNG／帳目快照，不捏造聚合中點；原失敗保留後重跑。
- 舊宗門UI fixture繞過ContentLoader、資源沒有max欄位，新增觀測呼叫原Production.compute_caps時產生4筆script error（該舊runner仍exit0）；已補齊fixture的明確容量，單獨重跑exit0且SCRIPT ERROR0。舊4筆保留於all-verified-time-tail.log，最後各Runner的結果用乾淨重跑覆蓋，沒有把舊整份log稱作零script error。
- 最終閱讀檢查補上開啟選單時延後資料重建，避免世界時鐘刷新打斷真實滑鼠。最後原生58項；兩包再匯出／壓縮exit0，最末Web包800滑鼠選世與完整封存相等已驗，服務及成功分頁再次清理。
- 本機首開服務未啟動而refused；沙箱服務timeout；失敗分頁data-URL無法重新綁定，改在服務可達後開有效測試URL。第一次非沙箱服務的自動審核因帳號額度不足未完成，命令未執行；使用者明確要求繼續後重試同一命令成功。不是安全判定，也沒有繞過審核。
- 原生退出保留 Font RID／CanvasItem／ObjectDB／resources in use等既有診斷；負面保存測試有預期JSON錯誤。SCRIPT ERROR另行核對，不稱整份日誌零錯誤。CLI耗時不是FPS／GPU證據。

## 結案與交接

最終固定94／94（42＋2＋35＋15分段、另補乾淨宗門UI fixture重跑）與282專項／58原生已收結。`python tools/life_history_audit.py`核對65份來源／UID嚴格UTF-8、全部本輪連結、12張原生PNG、兩包壓縮／四BGM companions與SHA；各支最後結果SCRIPT ERROR0。全量前段UI為56，最後空選單／刷新保護的58另以ui-menu-native.log驗證，不倒填舊數字。正常候選 `build/web-report-2`；原凍結 `build/web/index.pck` 仍 SHA256 `7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400`。未commit／push，未改玩家資料；觸控／實機沿既有政策延期，非當前阻擋。下一大型候選為 `ATM-LIFE-C`，只在New Chat由使用者指定，本輪不展開。


正常與隔離包、完整分段／初輪日誌及來源hash見[最終manifest](artifacts/report-2/final-manifest.json)。原生合成例圖：[寬式觀測](artifacts/report-2/plot-1280x720.png)、[短式觀測](artifacts/report-2/plot-800x360.png)、[保存保護](artifacts/report-2/protection-844x390.png)。原先乾淨的十份受追蹤generated fixture已還原原bytes；本輪生成版本與SHA保留於artifacts/report-2/generated-fixtures及restored-generated-fixtures.json，其他既有dirty成果保持。
