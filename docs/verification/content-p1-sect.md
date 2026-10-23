# CONTENT-P1-SECT 驗收紀錄

## 2026-10-23 美術接受：DONE（CLI／原生／桌面 Web 有界）

使用者明確回覆「美術接受」，接受丹房調息訣／靈契養成法兩張新圖及本批功法／商品卡片。已記入圖像 manifest 的 human_acceptance 與提案 delivery。先前唯一未完成的人工美術條件已滿足，CONTENT-P1-SECT 現為 **DONE**；以下待接受段落保留為日期化交付歷史。

沿用最終6,778核心、16合法築基路徑、69原生與107支唯一固定Runner，以及三橫式真實滑鼠／五模板／拒寫重試重載及自然委託證據。此輪僅改 metadata、狀態文件、稽核接受斷言及英文交接；沒有重跑遊戲、瀏覽器或匯出，沒有修改PNG、規則或玩家資料，未commit/push。`python tools/content_p1_sect_audit.py` 的本輪結果另列下方；不能把此輪文件收結稱為重跑全部測試。

本輪實際重跑：`python tools/content_p1_sect_audit.py` **exit0，55 checks／failures=[]，107 unique runners 的既有覆蓋核對通過**；包含兩項新增的人工接受證據斷言、原圖hash、來源與兩包壓縮hash核對。

本階段停止；下一大型任務請New Chat由使用者指定，不自動開CONTENT-P1-STORY。


## 2026-10-23 正式實作交付：IN_PROGRESS，僅兩張新功法圖／卡片待美術接受

使用者指令「CONTENT-P1-SECT，依已核定Q實作」已完成 Q1／Q2／Q3／Q-save 接線。宗門現為 **6 功法／20 模板／6 商品**。沿既有宗門頁、GameTab、CloseSeal、共用黑體與 UiIllustration B；沒有新增世界建築、改舊四功法收益、改舊四商品交付政策或開 STORY。

修改檔案：`src/simulation/{sect_system,alchemy_system,beast_system,command_processor,island_progression}.gd`、`src/domain/game_state.gd`、`src/persistence/{sect_save_contract,save_codec,save_manager}.gd`、`src/presentation/sect_panel.gd`、`src/abode/living_abode.gd`；三支 `tests/content_p1_sect_*_runner.gd` 與隔離 `src/verification/content_p1_sect_*`，既有 `tests/uix_r9_sect_ui_runner.gd`／`tests/sks_p1_runner.gd` 的診斷／版本斷言；`project.godot`／`export_presets.cfg`／`tools/run_all_runners.ps1`、本批 server／audit／fixture 還原工具、兩張 PNG／manifest、runtime 衍生字型、狀態／規範／英文交接。逐檔 hash 見稽核，17 個既有受保護檔案屬預期變更，其餘保護檔案保持。

### 實作與保存

- `SectSystem` 追加丹房調息訣、靈契養成法各五階，逐階成本完全沿 Q；新效果檢查入宗及當世 Era。`AlchemySystem.refinement_cost` 為四丹的顯示／檢查／實付／帳目／paid_cost 共用來源；靈狐 `feed_costs` 以整數百分比相乘後一次取整，其他三獸及經驗／冷卻保持。
- 五個新穩定 template_id 按品階內資格篩選，保留原 15 模板及權重；新模板只替換非金錢資源 profile。生成 Era、文字與完整獎勵凍結，派遣／領取認 instance ID，不重驗生成資格；未從舊名稱推斷新獎勵。
- 木匣及育草丹補給各終身十次。木匣使用與生產相同的基礎容量、宗門／天時／靈獸倍率及加工預留；滿倉或超倉全拒。目的庫存檢查使用複本讀既有初始化 helper，拒絕不改玩家狀態。購丹不自動服用。
- schema5 保持，根 `sect_version=1`、rules `core-flow-16-content-p1-sect`；`+content-p1-sect` 掛在正式 IslandProgression 內容身分，基礎 ContentLoader 的 SHA256 契約保持。
- 新 `SectSaveContract` 在 encode／decode 雙向驗證版本、32KiB、等級／限購、Amount 貢獻、候選／活動數、時間、counter、instance 去重及新模板 payload。v0 不能帶新功法／商品。合法舊文以 hash 命名備份並讀回，失敗不覆寫原槽；損壞／未來版本拒絕並保留原文，無合法槽時顯示具體 `SECT_*` 原因。重試只保存同份已執行狀態。

### 命令與實測

1. `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：`4.7.2.stable.official.ed1daf0bf`，exit0；未更新引擎／模板。
2. `--headless --path . --script res://tests/content_p1_sect_runner.gd`：最終 **6,778 checks，failures=[]，exit0**。包含十二丹、六功法階、四丹火階、三批量、靈狐天賦／獸魂及實付、其他獸排除、實際 4,000 次生成與五 ID 覆蓋、資格／凍結／舊實例、拒絕原子性、跨世、原文備份與故障重試、壞資料具體錯誤。
3. `--headless --path . --script res://tests/content_p1_sect_progression_runner.gd`：**16 checks，exit0**。從既有合法築基保存起，無直接補庫存；正式入宗、派遣／CLI 模擬等待／領獎、學習與購丹、保存重載。模擬工時 780 秒，並非瀏覽器自然等待。[來源與逐件記錄](artifacts/content-p1-sect/progression.json)。
4. `--path . --script res://tests/content_p1_sect_ui_runner.gd`：**69 checks，failures=[]，exit0**；1280×720／844×390／800×360，十二張原生截圖。檢查新圖、44px、完整卡寬高、可達操作與返回。例：[丹房寬式](artifacts/content-p1-sect/native-1280-1-4.png)、[靈契寬式](artifacts/content-p1-sect/native-1280-1-5.png)、[800丹房](artifacts/content-p1-sect/native-800-1-4.png)。
5. `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` 及 `-StartAt tests/uix_r9_sect_ui_runner.gd`／`tests/m1a_core_runner.gd`／`tests/sks_p1_runner.gd` 分段：依實際固定清單覆蓋 **107／107 唯一 Runner（含 tools 入口）**；最後 14 支整段 exit0。另以 [focused-final.log](artifacts/content-p1-sect/focused-final.log) 重跑六支直接相關 Runner，全通過。有效分段無 SCRIPT／SHADER ERROR；初輪失敗不刪除。[交付稽核](artifacts/content-p1-sect/audit.json) 依各段中斷點去重核對，沒有把發出命令當成功。
6. `python tools/subset_game_fonts.py --check`：初次缺七字，已沿原工具生成衍生字型；最後 check exit0，原始字檔未改。`--editor --import --quit`、兩候選 `--export-release`、`node tools/prepare_web_compression.mjs <candidate>` 的最終結果由稽核核對。
7. `python tools/restore_content_p1_sect_fixtures.py`：**15 份先前生成 fixture／報告還原**。其中舊丹藥 fixture 從先前接受版 PCK 在無 loose source 的目錄讀出，SHA256 與設計開始時基線一致才還原。[還原清單](artifacts/content-p1-sect/fixture-restoration.json)。這些都是測試資料，不是玩家進度。

### 真實桌面 Web

`python tools/content_p1_sect_server.py`，僅 localhost `48423`；驗收版使用獨立 `dao2_content_p1_sect_acceptance` localStorage＋Web Lock，鎖定啟動與保存共用同一命名空間。工具頁明示資助案例、自然時鐘／CLI 等價模擬完成按鈕，沒有把模擬按鈕當自然時間證據。IAB 的原生 click／scroll 操作 canvas；844 的邏輯座標依正式 360 高畫布換算，未以函式呼叫冒充滑鼠命中。

- 三橫式各新功法／商品實際滑鼠付費。844／800 皆從 10,000 貢獻、0 木起，木匣 +100 木／−60 貢獻、草丹 +1／−45、靈契首階 −100 木／−90、丹房首階 −5 石／−60，結尾 **9,745 貢獻、兩功法各1階、丹1顆**。例：[844](artifacts/content-p1-sect/web-844-alchemy.png)、[800](artifacts/content-p1-sect/web-800-alchemy.png)。
- 1280 丹房首階拒寫後，同份狀態為 9,940 貢獻／99,995 石／1階；恢復權限，按實際保存保護覆層的重試，再真正 reload，三值保持，不重扣。原覆層擋住頁內重試時改點畫面上真正可用的入口。[拒寫畫面](artifacts/content-p1-sect/web-write-denied.png)。
- 五個 template_id 逐一用可控隔離 fixture 真實派遣／領取，完成時間使用明示的模擬控制；貢獻分別 10,015／10,030／10,060／10,120／10,300。這一組不宣稱自然等待。
- 另從合法築基原保存，以真實滑鼠入宗，實際自然等待並領取 60 秒晨露草、120 秒雙島回運、再刷新後120秒雙島回運，貢獻 26＋54＋58＝138；實付丹房首階與育草丹後 **33 貢獻／丹房1階／育草丹1顆**，真正重載保持。[自然流程結果](artifacts/content-p1-sect/web-earned-natural.png)。含使用者對話中斷期間的背景經過，不是新手總時長／節奏預算；沒有使用模擬完成控制取得這三筆貢獻。
- [逐次觀察 JSON](artifacts/content-p1-sect/web-observations.json) 區分上述案例；最後可控付費頁的 browser warn/error 查詢空，不以此宣稱整個引擎歷史日誌零錯誤。
- 最終來源重新匯出後再真正 reload 800 案：Era3／9,745貢獻／兩功法各1／育草丹1保持，最終 browser warn/error 為空。[最終畫面](artifacts/content-p1-sect/web-final-800.png)、[最後診斷](artifacts/content-p1-sect/browser-final-logs.json)。本輪建立的測試服務已停止，分頁已關閉、臨時視口已重設；停止服務的 exit1 為主動 Ctrl+C，不是匯出或回歸失敗。

### 圖像、匯出與限制

兩張內建 image_gen 原創透明 RGBA：[丹房](../../assets/ui/sects-painted/alchemy_herb_conservation.png)、[靈契](../../assets/ui/sects-painted/fox_feed_conservation.png)。[逐字提示詞／用途／切層／授權界線](../../assets/ui/sects-painted/content-p1-manifest.json) 與 `artifacts/content-p1-sect/originals/` 保留原圖；PNG 未經改畫，B 描邊柔影由正式 UiIllustration 提供。委託沿既有題材／品階圖，兩商品沿既有木與已接受育草丹圖。**兩張新圖與本批功法／商品卡片仍待使用者美術接受，因此整體 IN_PROGRESS。**

正常候選 `build/web-content-p1-sect`，隔離候選 `build/content-p1-sect-acceptance`；各含壓縮 companions 與四首 BGM。凍結 `build/web/index.pck` SHA256 保持 `74aa640f734044c59bbe1a1d67f473cf9b705ca74d50169d2aeb04bc62106e4f`。最終來源／資產／兩包 hash 與稽核結果見 [audit.json](artifacts/content-p1-sect/audit.json)。

保留初輪：測試型別推斷／META 字串錯誤、JSON 整數／浮點 Dictionary 對照修正、測試庫存需逐次消耗、短橫卡片與雙欄延後重排、舊四商品數／舊 rules 斷言、基礎內容 SHA256 契約、初次目的匯出目錄不存在、localhost 沙箱連線逾時、驗收 Web Lock 命名空間不一致與換包載入中的工具逾時。最終修正後均有後續證據；負面損壞資料的 JSON_PARSE、原生 Font RID／CanvasItem／ObjectDB 退出診斷與初次沙箱 user:// 日誌／保存權限錯誤仍記錄，不稱乾淨日誌。

沒有 FPS／GPU／冷啟動預算聲稱。觸控／實機延期，非當前阻擋。未改玩家進度、未 commit／push。依 Context Guard，英文 checkpoint 已置 `updata.txt` 最頂部；本階段停止，下一 New Chat 只收兩圖／本批卡片美術回饋，不開 CONTENT-P1-STORY。

---

以下保留設計與核定當時的歷史紀錄。

2026-10-23 後續核定：使用者回覆「採Q」，Q1／Q2／Q3／Q-save全部接受，已寫入提案JSON的approval；正式實作仍TODO、整體IN_PROGRESS。下方待核定文字屬此前設計交付歷史。此輪只更新核定／交接與稽核的核定證據斷言，再跑合成稽核；未改正式規則或執行遊戲驗收。下一New Chat直接按已核定Q接線，不重問數值。

2026-10-23。**設計階段交付，方案Q待核定；整體IN_PROGRESS，正式實作TODO。**

## 範圍與產物

- [逐項方案與Q核定表](../32-content-p1-sect-design.md)：兩功法、每品階一項委託、兩商品；成本、公式、Era／島／獸條件、收益、輪迴、保存與接線驗收。
- [機器可讀提案](../design-data/content-p1-sect-proposal.json)：九個候選穩定ID；尚非runtime定義。
- [稽核工具](../../tools/content_p1_sect_design_audit.py)：Decimal合成比較、讀原碼常數、來源與凍結包保護；不執行遊戲或修改保存。
- `artifacts/content-p1-sect-design/session-start.json`：設計開始時正式來源／content／tests／assets／專案設定及存在的build/web/index.pck SHA256。
- `artifacts/content-p1-sect-design/analysis.json`：命令後產生的實際checks／failures、成本表與情境。

## 前置與現況

S／T／P已有使用者美術接受紀錄與桌面有界DONE；本輪讀Roadmap、README、交接、開發狀態、架構、docs25／31與正式宗門／丹藥／靈獸／保存來源。Git存在且有大量既有dirty成果，未reset／commit／push。引擎本機4.7.2已驗。

宗門目前4功法／15模板／4商品；方案目標6／20／6，**仍非正式可玩數**。原碼跨世保留功法、貢獻、限購；原四功法沒有入宗效果gate。本輪將新功法的gate獨立規範，沒有順手更改舊數值。新方案不引用尚未供給的高境界獸料。

## 命令與證據邊界

1. PowerShell `Get-Content`／`rg`、`git status --short`：讀取與盤點exit0。
2. `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。
3. 首次 `python tools/content_p1_sect_design_audit.py --capture-baseline` 建立只讀保護基線；後續以 `python tools/content_p1_sect_design_audit.py` 重跑。實際結果另記下方，不能把尚未執行寫成通過。

合成案例包含12丹×6功法階×4丹火階×4批量、144種靈狐餵養組合、240種模板資格組合、30種草丹產率／頭房比較。算表證明所提數學關係與來源盤點，沒有證明runtime已實作、命令原子性、自然節奏或瀏覽器保存。

沒有跑import／Godot Runner／原生渲染／瀏覽器互動／字型生成／Web匯出／FPS。沒有新增美術、修改schema、寫玩家進度或凍結Web包。觸控／實機延期，非當前阻擋。

## 正式實作尚待完成

方案Q核定後仍需完成：兩成本helper與所有拒絕分支、五模板生成／凍結／領取、兩商品有界全額交付、sect_version與原文備份／只保存重試、既有UI接線、兩功法ImageGen圖與人工接受、專項及回歸、三桌面橫式逐ID滑鼠／故障重試與重載、候選匯出。詳細矩陣在設計§6；滿足之前不得整體標DONE。

下一步：收Q1／Q2／Q3／Q-save具體決定，在New Chat續同一CONTENT-P1-SECT實作；不開STORY、不重做已接受S／T／P。

## 實測結果

- 首次capture命令exit1：8,197 checks，一項失敗為文件預估的委託平均值。來源計算正確應為66.2貢獻／192秒，已修正文稿與斷言；原始報告保留於 `artifacts/content-p1-sect-design/initial-analysis.json`。
- 修正後普通稽核exit0：**8,199 checks、failures=[]**（增加兩個交付連結檢查後最終重跑）；1,152丹藥費用／144靈狐／240模板資格／30商品情境。1,156受保護檔案 `protected_changes=[]`，13個重點來源hash列於報告。
- 命令結果摘要見 [command-results.json](artifacts/content-p1-sect-design/command-results.json)；最新完整算表見 [analysis.json](artifacts/content-p1-sect-design/analysis.json)。
- 修改：新增docs32、提案JSON、此驗收頁、稽核工具與本批證據；README／ROADMAP／docs25／交接／開發狀態及updata頂部更新。本輪不改正式來源或執行其驗收。

2026-10-23 核定後重跑：`python tools/content_p1_sect_design_audit.py` exit0，8,199 checks／failures=[]，1,156受保護檔案保持。此結果含明確Q核定證據檢查，仍為合成設計稽核。
