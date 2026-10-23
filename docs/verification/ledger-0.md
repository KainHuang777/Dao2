# LEDGER-0：最小事實、版本與九世封存

2026-10-22 · **DONE（CLI／桌面 Web 有界）**。本頁現況覆蓋同日的前置盤點與初輪失敗紀錄。

使用者指定 `LEDGER-0`，並在容量問題明確答覆「9世」。[ADR-013](../decisions/ADR-013-bounded-life-facts.md) 是正式資料契約；保存最近9個封存世、每世最多64事件／32KiB、當世64KiB，敘事子樹總上限352KiB。其他存檔、envelope、儲存字串與復原副本不在此額度。沒有接受卷末布局、十題優先或文稿，也未啟動 REPORT-1A。

## 已實作

- 新 `LifeLedger` 純資料記錄器；新檔complete、舊檔從導入年齡partial，未啟動missing、未支援種類unsupported。不推造以前建築、全生命峰值或不存在的0。
- GameState 深複製／snapshot 與 schema5；解碼支援2／3／4／5，敘事version1嚴格型別、欄位、順序、UTF-8字節和容量驗證。JSON數字按欄位還原原生型別。
- 成功命令的建屋、進境／劫成敗、研習／煉丹、入宗／領取、開島、同實例靈獸取得／成熟；時間內的宗門完成、航線到貨及壽盡。進境及劫成敗保留再次發生，其餘為首次已證明里程碑。不是每秒流水或完整資源帳。
- 在線、聚合、同步離線快速／回退、非同步與time-only路徑；快速推進補事實邊界，不新增RNG呼叫。當世峰值獨立於事件環更新。
- 第一批48事件固定保留、16最近事件環；整件略去計數、partial提示，不切UTF-8。每事件384bytes；凍結文字預留4096bytes，LEDGER-0尚不產生敘事文字。
- 轉世清空前以最新事實封存end_state、結束原因、settlement_id，再建立下一世；與原道果共用同一候選及雙槽保存，保存重試不再發獎／封存。預覽與 `get_life_record()` 深複製皆只讀，歷史不加入逐幀HUD View。
- 首次遷移寫入前，按原文SHA256保存並讀回核對 `save_before_ledger_<hash>`。支援的schema2／3／4不再被舊「所有older先rescue再重置」分支清空；schema1原rescue規則保持。未知／損壞敘事拒絕該槽並走原兩代選擇；兩槽無合法資料時拒絕新建與覆寫。

## 修改檔案

正式來源：`src/domain/life_ledger.gd`（含.uid）、`game_state.gd`；`src/application/game_session.gd`；`src/persistence/save_codec.gd`、`save_manager.gd`；`src/simulation/command_processor.gd`、`reincarnation_rules.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`offline_economy_jump.gd`、`island_economy.gd`、`sect_system.gd`。

驗證：`tests/life_ledger_runner.gd`（含.uid）、`tests/res1b_economy_runner.gd`、`tests/web_persistence_fault_runner.gd`、`tools/run_all_runners.ps1`；`src/verification/ledger_acceptance.gd`（含.uid）／`.tscn`，`project.godot` 與 `export_presets.cfg` 新增隔離驗證feature／preset，正式Web仍排除驗證來源。兩份既有runner將schema3重置fixture改為真正不支援的schema1，支援版本的保留／遷移另由新專項直接驗證。

文件：本頁、[前置盤點歷史](ledger-0-preflight.md)、ADR-013、docs27／30、README／ROADMAP／handoff／status／updata與本目錄artifacts。既有大量UI-SHELL／研究修改保持，未commit/push。

## 專項結果

[results.json](artifacts/ledger-0/results.json)：**302 checks，failures=[]，exit0**。包含：

- 真實建屋命令、拒絕不記、同command_id重送不記、深複製、型別一致往返；schema2／3／4導入起點，不把highest_era9當當世峰值。
- 未知version／錯型額外欄位／超限文字／事件序號／未來年齡／未知種類／schema5漏欄拒絕；checksum先於敘事信任。
- 同源在線逐秒／批次／快速／同步離線／非同步比較，實際委託第7秒完成、航貨第5秒到達，原經濟及RNG快照對照；time-only壽盡。
- 劫敗後再次進境不被首次合併；真實取得及餵至成熟共用同一實例ID；只讀API回傳深複製。
- 12次真實轉世保留第4～12世共9世；預覽後新事實入最終卷、拒寫／重試／重載／重送，道果及封存一次；最新敘事未知時復原舊槽、兩槽未知不覆寫；schema4原文遷移備份與拒寫。
- 1000個中英emoji合成事件保留64、略去936；超長事件整件略去，逐事件UTF-8與總量上限。此合成容量案例不是自然玩家生命或原始事件全保留承諾。

## 桌面 Web 證據

隔離 `http://127.0.0.1:4398/review`，正式Godot場景／滑鼠，測試fixture從第二世Era2 Lv4、100秒、跨世最高Era6開始；此為合成驗收資料，非自然玩家進度。

[9項Web檢查](artifacts/ledger-0/browser-observations.json)全部true：取消不封存；真正轉世count1→2、道心0→15、封存一份life_id2、partial／觀測峰值Era2／終點Era2 Lv4，current life_id3。實際拒寫、在拒寫中再按保存、恢復寫入後只重試保存；重載後仍15道心／一份相同封存。保存保護會暫停樹，開發DOM observer在拒寫期間亦暫停，該階段DOM是舊值；未將它當作提交後狀態。核心console記錄cycle2，恢復後與重載資料共同核對結果。

1280×720完成轉世互動，重載後以工具切844×390、800×360核對資料穩定；這兩尺寸是resize／重載後呈現觀察，不冒充各自重做整條轉世矩陣。沿現有HUD／輪迴UI，未加入小傳頁、美術或新共用UI樣式。

[1280恢復收據](artifacts/ledger-0/web-recovered-1280.jpg)、[844重載](artifacts/ledger-0/web-reload-844.jpg)、[800重載](artifacts/ledger-0/web-reload-800.jpg)。截圖API原始bytes為JPEG，已按簽名用.jpg保存；不是以轉檔或圖片編輯修圖。

## 命令、失敗與診斷

所有最終CLI使用 `$env:APPDATA='E:/WORK/Dao2/build/ledger-0-user'` 隔離。使用既有4.7.2.stable.official.ed1daf0bf、Compatibility、單執行緒Web；未更新引擎／模板。

| 命令 | 結果與界線 |
| --- | --- |
| Godot `--version` | exit0，4.7.2。 |
| Godot `--headless --path . --editor --import --quit` | exit0；原有研究／樣張JPEG誤名PNG、user目錄、巢狀project診斷保留，不宣稱乾淨import。 |
| Godot `--script res://tests/life_ledger_runner.gd` | 最終302 checks／exit0。初輪型別推導parse error；下一輪fixture缺processing catalog／使用不支援fast空economy／缺少舊版載入保護，均已修正，日誌保留。 |
| Godot `--script res://tests/m1c_persistence_runner.gd` | 型別復原修正後exit0；負面Base64案例仍有預期引擎ERROR。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 初輪res1b舊schema3重置測試失敗及低階命令缺command_id SCRIPT ERROR；第二輪m1c嚴格Dictionary型別往返失敗，皆修正。最終 **86／86 Runner exit0，SCRIPT ERROR 0**；初輪日誌不刪。 |
| Godot `--export-release Web build/web-ledger-0/index.html` | exit0；正常候選，未覆寫凍結build/web。 |
| Godot `--export-release LedgerAcceptance build/ledger-0-acceptance/index.html` | exit0；隔離驗收feature，正常release排除此fixture。型別修正後再匯出／壓縮及實際重載亦成功，仍15道心／同一份封存。 |
| `node tools/prepare_web_compression.mjs <各候選目錄>` | 已完成包exit0，含原始BGM複製及br；初包未複製BGM前瀏覽器曾報BGM下載失敗，未稱console全空。 |
| `python tools/ui_shell_server.py --build build/ledger-0-acceptance --port 4398` | 正常授權localhost服務可達；初次尚未啟動4397即開頁connection refused、沙箱4397後timeout保留，不計為通過。 |

初次截圖以.png命名JPEG導致本輪export掃描也報錯，已依bytes簽名更名本輪三圖並移除它們新生的.png.import；沒有改既有研究圖。前置文件檢查器的換行／cp950問題見前置歷史與原始JSON，不混稱遊戲測試失敗。

[UTF-8原始日誌](artifacts/ledger-0/logs/ledger-0-full-final.log)、[最終摘要](artifacts/ledger-0/final-checks.json)、[來源與建置hash](artifacts/ledger-0/final-source-hashes.json)已固化；完整原始工作日誌仍在 `build/ledger-0-*.log`。最終正常PCK為`acb80db98d103d93…`、隔離PCK為`5f8c27b1a29b7803…`；凍結build/web仍`7e7e619dcaa28fb0…`。未作FPS／冷啟動／觸控實機聲稱。

## 結案閘門與下一步

最終302專項、86／86固定入口、Web9項、兩候選匯出／壓縮／BGM、來源／文件檢查滿足本批DoD。下一批為ATM-LIFE-A／REPORT-1A，布局與選文尚待既定人工審閱，不由本輪九世容量決定代為接受。依Context Guard在此停止，下一大型階段使用New Chat。未commit/push。

補充證據界線：瀏覽器日誌保留初包BGM404警告（最終服務同資產已200），及一筆未附來源URL的MutationObserver TypeError；未將它斷言為遊戲程式或宣稱console全空。三橫式資料／正式操作與重載結果仍成立。驗收viewport已重設、分頁關閉，自有服務兩session以Ctrl+C停止（exit1為主動停止）。

清理與資料安全：依前置hash只還原起初等於HEAD的測試重生fixture；未還原使用者原本dirty檔。僅刪除前置時間後新生、未追蹤且在docs內的47份.import sidecar，[逐檔清單](artifacts/ledger-0/import-sidecar-cleanup.json)保留，未刪任何來源圖或.uid。原始fixture還原清單見[紀錄](artifacts/ledger-0/fixture-restoration.json)。

結案檢查：37份來源／文件嚴格UTF-8、16個本地連結、兩包壓縮與各四首BGM hash核對通過；diff-check exit0。最初結案檢查發現新增preset末端多一空行，已移除，初始JSON保留；此為空白修正，未改通過全量測試的正式程式。10份原先乾淨的重生fixture已精確還原；既有dirty來源均保留。
