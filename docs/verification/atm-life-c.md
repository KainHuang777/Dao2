# ATM-LIFE-C：機緣、宗門與靈獸事件回聲

日期：2026-10-23（Asia/Taipei）。**DONE（CLI／原生／桌面 Web 有界）。**

依 [整合計畫](../27-life-report-and-decision-ux-integration-plan.md) 與 [ADR-017](../decisions/ADR-017-life-event-echoes.md)，在原當世行跡／卷末／歷世閱讀區交付三條原創回聲：石壁之後、山門回程、同行漸長。前因與後續都必須已有權威收據或正式里程碑；不新增收益、事件抽選、RNG、保存欄位或schema。舊世沒有凍結回聲就保持原文。

## 修改

- 新增 `src/domain/life_echo.gd/.uid`：有界純函式、三種條件、同世／時序／個體與已知選項原文核對、凍結回聲讀取驗證。
- 更新 `src/domain/life_report.gd`：`report-1a-2-echo`，於原frozen_text內凍結echo_version=1與來源摘錄；JSON讀回正規化版本整數。
- 更新 `src/presentation/life_report_view.gd`：既有閱讀區的文楷18px回聲、共用「查記錄」內黑體16px來源；不另開分頁，原固定收益／確認／取消／保存重試保持。
- 新增 `tests/life_echo_runner.gd`、`life_echo_ui_runner.gd` 與UID，接固定入口；新增 `src/verification/life_echo_fixture.gd`、`life_echo_acceptance.gd/.tscn` 及UID與獨立export preset／feature。全部是隔離合成案例，不是自然養成或玩家進度。
- 沿既有來源、OFL與工具重建runtime字型subset；沒有新增美術資產、下載字型或第三方文稿。同步專題規範、狀態、README／ROADMAP／handoff與英文checkpoint。

## 命令與結果

使用既有 Godot `4.7.2.stable.official.ed1daf0bf`；APPDATA指向專案build/atm-life-c-profile，原生保存另用user://atm-life-c-ui。命令完整log位於本頁artifacts/atm-life-c/logs。

| 命令 | 結果 |
| --- | --- |
| `Godot --version`／`--headless --path . --import` | 版本確認；import各次exit0。保留歷史PNG格式、user目錄／嵌套專案等診斷，不稱乾淨匯入 |
| `Godot --headless --path . --script res://tests/life_echo_runner.gd` | 最後 **117 checks、failures=[]、exit0**（core-verified-117.log）：32組有無來源、選項／文案／同世／同齡與倒序、錯獸／缺instance、重讀及命令重送不重發、來源淘汰後凍結文字、舊世不補造、保存拒寫重試／重載／兩代復原、線上／批次／閉式／離線／async相同回聲及經濟RNG |
| `Godot --path . --script res://tests/life_echo_ui_runner.gd` | 最後 **25 checks、failures=[]、exit0**（ui-verified.log），1280×720／844×390／800×360原生7張PNG。正式route、18px、44px、無水平溢出、內捲、固定動作、來源／取消／保存保護與缺資料清除已驗 |
| `Godot --headless --path . --script res://tests/life_report_runner.gd` | 修正JSON整數正規化後既有 **16,400 checks、failures=[]、exit0**（report-regression-final.log） |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 固定 **96／96 Runner分段通過**：all-corrected.log前8項通過，第9項小傳型別差異失敗保留；修正後all-resume.log從小傳起88項exit0。batch_a另重跑三支丹藥runner，日誌有重複RUNNING，固定清單依去重後完整96項核對。最終各支SCRIPT ERROR 0；追加117專項與25原生補最後前置／測試強化，未倒填早期101項數字 |
| `python tools/subset_game_fonts.py`／`--check` | 兩者exit0，保留來源／授權；新敘事仍沿共用文楷 |
| Godot `--export-release Web build/web-atm-life-c/index.html`／`LifeEchoAcceptance build/atm-life-c-acceptance/index.html` | 正常候選與隔離包export exit0；Release fixture修正後獨立包再次export exit0。原凍結build/web保持 |
| `node tools/prepare_web_compression.mjs`（上述兩目錄） | Brotli往返核對與四首BGM companions成功，exit0 |
| `python tools/ui_shell_server.py --build build/atm-life-c-acceptance --port 4406` | 沙箱服務timeout；同命令經正常權限審核後本機服務可由IAB連入，沒有改防火牆／網路設定 |

三條回聲合計1276 bytes，完整範例小傳1554 bytes；沿原4096-byte文字額度、每世32KiB／當世64KiB及九世352KiB，沒有增加永久事件庫。測試耗時不是FPS或自然一生證據。

## 真實桌面 Web

IAB滑鼠，隔離origin4406，正式Godot iframe三橫式1280×720、844×390、800×360；外層尺寸鈕、拒寫鈕與state output為驗收工具，遊戲仍是正式Godot。寬式外層視口較iframe小時只檢查工具頁捲動，不將工具頁捲動當遊戲響應式解法。

- 實際捲讀回聲、點「查記錄」，可見「選項2」與來源摘錄；844／800固定底列、原生字級／44px保持。閱讀與取消後完整life_ledger和baseline相等。
- 拒寫後確認轉世：count1→2、道心0→20、archive0→1，凍結三條回聲。保存保護三尺寸可讀；拒寫重試後完整archive完全相等、仍20道心，沒有再封存／發獎。
- 恢復寫入後重試：save_failed=false、count2／heart20，完整archive仍相等。重載後count2／heart20／archive1，完整archive逐字相等；滑鼠從「歷世」選第二世，重讀原凍結三條回聲，800短橫式重讀後archive仍完全相等。最後console error／warn查詢為空。成功分頁及自有4406服務已關閉（Ctrl+C exit1為主動終止）；早期失敗data-URL分頁因政策無法關閉，保留此界線。

瀏覽器圖在工具對話；本頁磁碟PNG是原生，不冒稱Web截圖。[寬式回聲](artifacts/atm-life-c/echoes-1280x720.png)、[800來源](artifacts/atm-life-c/sources-800x360.png)、[保存保護](artifacts/atm-life-c/protection-800x360.png)。

## 失敗與修正

- 初次讀檔輸出過大被截斷，後改分段；數次PowerShell rg萬用路徑／舊猜測檔名查詢失敗，改查實際來源，未將查詢失敗當測試通過。
- 新核心runner初輪兩個Variant型別推斷解析錯誤已明確型別修正。閉式parity起初未提供economy version，回報bad_version；補上既有IslandEconomy.initial前置後，各路徑通過。初輪log保留。
- UI初輪fixture當世Era3／未轉世尚未達輪迴導覽門檻，實際回到煉丹頁，六項回聲斷言失敗；改為明示第二世合成資料，追加canonical頁確實可見斷言。不是放寬正式解鎖規則。
- 全量初輪在既有小傳封存精確相等檢查發現JSON把echo_version的int讀成float；補read正規化，原16,400項完整重驗通過。保留初輪all-corrected.log，未刪弱斷言。
- 初版驗收fixture以assert包住命令，Release會移除命令執行，Web只見晉階。改為先執行命令、再檢查結果；v2驗收marker重建早期測試資料。修正後Web確認正式收據及五個事實／同一靈獸身份均存在，再進入三尺寸與保存測試。不能用初版匯出成功宣稱內容通過。
- IAB第一次沙箱服務timeout後，該暫時分頁停在data-URL錯誤頁，URL政策阻止重綁。新建有效分頁完成測試；失敗分頁清理依工具結果記錄，不猜已關閉。
- 加強時間parity時，初稿使用Session便捷命令產生各次不同的牆鐘command_id，使來源hash與命令收據自然不同；改用同一組穩定command_id，比較同一邏輯命令後線上／各離線路徑的回聲、經濟與RNG。117項通過；沒有在正式遊戲抹去來源ID或放寬比對。
- 稽核首輪遇到尚未產出的final-manifest自連結，改為允許本次生成的唯一目標，再完成全部連結／輸出核對；最終Python稽核exit0（32份UTF-8來源／UID、10連結、7張原生圖、兩包／四BGM與凍結包hash）。
- 原生退出保留Font RID／CanvasItem／ObjectDB既有診斷；故意損壞最新保存的測試出現預期JSON錯誤。SCRIPT ERROR另行核對，不稱整份log零ERROR。

## 交接

本輪不展開下一大型任務。觸控／實機依使用者政策延期，非當前阻擋；沒有FPS／GPU或自然一生的新聲稱。未commit/push，沒有操作玩家保存origin。固定96／96（8＋88分段）及最後117專項／25原生、三尺寸桌面Web與保存流程已收結；Python稽核完整來源／UID／連結／兩包與原凍結包hash，git diff --check通過。十份受追蹤生成fixture已還原本輪開始前bytes，生成版本另保留於本任務artifacts/generated-fixtures。成功分頁與服務已清理；早期失敗分頁受URL政策限制無法關閉，已記錄。英文checkpoint已置updata.txt最頂部。下一任務：New Chat由使用者指定內容擴充或其他工作；ATM-LIFE-D人際／NPC仍後期另議，不自動開工。

完整來源與兩包hash見[最終manifest](artifacts/atm-life-c/final-manifest.json)；[命令退出碼](artifacts/atm-life-c/command-exits.json)、[瀏覽器觀測](artifacts/atm-life-c/browser-observations.json)、[fixture還原紀錄](artifacts/atm-life-c/restored-generated-fixtures.json)保留初輪與最後證據界線。
