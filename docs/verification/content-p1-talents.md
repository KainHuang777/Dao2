# CONTENT-P1-TALENT

2026-10-23。使用者指定本任務，依 docs31 §4 採用 T 方案。**DONE（桌面／Web有界）：正式實作與驗收完成；三張新圖及天賦卡已於2026-10-23獲使用者明確美術接受。** P 丹藥仍待獨立核定。本批沒有開 Era4、改舊三項價格或起手資源，也不繼承人界建築／技能。

## 交付契約

輪迴天賦由3增至6項；新三項各五階，逐階5／10／20／40／80道心。第一世沒有贈點。購入立即影響後續行為，輪迴保留，不追補已結算收益。支出後持有道心的祖島全產倍率沿原公式下降。

| ID／名稱 | 效果及邊界 |
| --- | --- |
| `alchemical_past_wisdom` 丹心宿慧 | 聚靈丹／上品聚靈丹修煉收益每階＋10%，全滿＋50%；上品批次衰減後套用，最後受當層修煉上限限制，不自動晉階。其他丹、BUFF、壽元、平時修行不變。 |
| `artisan_past_wisdom` 百工宿慧 | 祖島木屋／林場／採石場／靈植場的產率貢獻每階＋8%，全滿＋40%。先按建築算貢獻，再套技能／全產等原乘區；包含木屋金錢及礦場玄銅。庫容、基礎率、茅屋、產點、手採、遠島、配方與航運不變。 |
| `beast_bond_past_wisdom` 靈契宿慧 | 僅靈狐，每階餵養經驗加數＋20%，與獸魂成長相加。50基礎經驗使每階恰加10 XP，程式用 `floor(舊成長後經驗)+10L` 避免浮點將115向下誤算114；與核定公式數學等價。草料／300秒冷卻／成熟拒餵／魂數不變。 |

`TalentSystem` 集中定義、成本與等級驗證。`Production.compute_rates` 新增可選talents參數，接Session View、逐秒、解析離線與Debug診斷；容量API保持。`AlchemySystem.consume` 接兩丹收益，`BeastSystem.feed_beast` 接靈狐經驗。UI仍由Session正式命令付款，沿共用GameTab／黑體／CloseSeal／容器／內捲／44px。

## 保存與復原

schema仍5，新增 `talent_version=2`，rules為 `core-flow-14-content-p1-talents`。舊存檔缺欄位讀作v1，只接受舊三ID；v2允許6ID，依各自5／10階上限檢查。未知ID、負數、非整數、字串、布林、非有限值、未知版本拒絕；JSON整數解碼為int。duplicate與snapshot皆保留版本。

`SaveManager` 載入舊檔後只提升天賦版本，不贈點或天賦；遷移保存前，以 `save_before_talents_<原文SHA256>` 備份完整原文並readback，失敗不提交新槽，原文待重試保留。成功後沿既有雙槽與index；重試只保存既有候選、不重送參悟。分享碼原文由使用者持有，解碼檢查後提升版本；不承諾全量舊版存檔相容。

## 驗證

Godot版本已確認 `4.7.2.stable.official.ed1daf0bf`；所有命令的APPDATA均指向build內專用profile，Web使用獨立4412／4413／4414來源，未讀寫玩家進度。正常候選 `build/web-content-p1-talents`；凍結 `build/web/index.pck` SHA256已核對保持 `7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400`。

| 命令／證據 | 結果 |
| --- | --- |
| Godot `--headless --path . --script res://tests/content_p1_talents_runner.gd` | 最後913 checks、failures=[]。逐階精確扣款、冪等、滿階／缺道心拒絕、每一建築／資源作用邊界、兩丹衰減批次／當層上限、四獸白名單、靈狐獸魂相加／成熟／冷卻、容量／舊丹保持、線上／離線、三舊項遷移及備份拒寫重試。[結果](artifacts/content-p1-talents/runner.json) |
| Godot原生 `--path . --script res://tests/content_p1_talents_ui_runner.gd` | 最後117 checks、failures=[]；三橫式、六張卡圖／完整高度／字級／44px／可達與返回，包含成功保存訊息。[結果](artifacts/content-p1-talents/native-ui.json) |
| Godot `--headless --path . --script res://tests/m3b_spirit_beast_runner.gd` | exit0，既有靈獸／命令／保存回歸通過。 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 固定100／100唯一Runner分段通過（head86＋SKS-P1單支＋tail13），SCRIPT ERROR0；初輪舊rules／三項數量斷言失敗已遷移並重跑。[覆蓋與原始紀錄](artifacts/content-p1-talents/runner-coverage.json)。 |
| `python tools/subset_game_fonts.py` 與 `--check` | 新文字的「追」缺字已補既有OFL子集，check exit0；沒有更換字族。 |
| Godot `--editor --import`、`--export-release Web`／`ContentP1TalentsAcceptance` | 最後UI回饋與XP精度修訂後，兩包重匯出皆exit0。 |
| `node tools/prepare_web_compression.mjs <兩候選目錄>` | 最後兩包Brotli往返與四首BGM companions皆exit0。 |
| `python tools/content_p1_talents_audit.py` | 28項來源／三圖alpha與原文hash／結果檢查通過，凍結Web保持。[稽核](artifacts/content-p1-talents/audit.json) |

### 桌面 Web

起點為明示Era3隔離fixture，CLI透過正式 `reincarnate` 命令取得20道心；暫停模擬時間以驗滑鼠。這不是自然時間從空白新檔走完Era3的Web證據。

1280×720已真實滑鼠購入三項各一階，20→15→10→5，缺第二階道心時禁用。844×390已驗丹心第一階保存拒寫、拒寫中再試、恢復保存，始終一階／15道心。最後三來源逐項購入三項各一階後皆為5道心，重載仍各一階／5道心。844保存保護恢復後亦已重載，沒有重扣。[實際觀測](artifacts/content-p1-talents/web-observations.json)。外層按鈕只控制驗收iframe尺寸與拒寫，核心操作仍在正式Godot畫面。iframe實際1280×720／844×390／800×360；canvas client尺寸1279×719／844×389／800×360，沒有把前兩個一像素差異記成精確canvas尺寸。兩個IAB來源保留MutationObserver非Node診斷，未歸因Godot；800來源無error記錄。[尺寸與console原文](artifacts/content-p1-talents/web-sizes-and-console.json)。測試服務以Ctrl+C停止（exit1為主動終止），viewport override已reset。

### 試跑修正與診斷

- 全量初輪另有SKS-P1固定rules13、EARLY-V1-B固定三天賦的過時斷言，依本批規格改14／六項；其餘舊三天賦527項效果／保存檢查保留並通過。
- 初輪測試的GDScript型別推斷、驗收場景面板引用與StyleBox型別已修正；初次checksum fixture重算誤含舊checksum，測試資料已修正。未把這些初次失敗記成通過。
- 800短式卡高度及成功訊息占用已在正式Panel修正：卡內縮留白／行距，成功併入固定「天賦 · 已存」分頁；保存失敗仍獨立完整顯示，全球保存保護／重試保持。
- 初次服務沙箱拒連與同埠雙服務衝突已停止，改獨立埠4412–4414後可連線，沒有改防火牆或網路設定。
- 另行探索的歷史 `tests/uix_r7_reincarnation_ui_runner.gd`（不在現行Runner清單）尚用未探索新檔直接開輪迴，起始路由已被現行discovery gate拒絕，於讀卡前失敗後中止；不是本批驗收證據，沒有為舊測試放寬正式入口。誤打不存在的 `m3b_beast_runner.gd` 命令失敗，改用實際 `m3b_spirit_beast_runner.gd` 並通過。
- 原生退出仍有既有TextServer／CanvasItem／ObjectDB洩漏診斷；import保留舊JPEG內容誤名PNG的驗收圖診斷。exit0不等於沒有診斷，最終各支SCRIPT ERROR另核。

## 美術與交接

三張原創內建ImageGen透明RGBA圖完整保留，不裁切／重繪／縮放；來源、副本、提示詞、用途、hash、授權界線見[manifest](artifacts/content-p1-talents/art-manifest.json)，[三圖審閱](artifacts/content-p1-talents/art-review.md)。三張新圖及天賦卡已於2026-10-23接受，本批DONE（桌面／Web有界）。沒有第三方商用授權聲稱。

本批已收結；下一New Chat可指定CONTENT-P1-PILL並獨立採用P方案。未commit/push。

## 本批修改檔案

正式來源：`src/simulation/talent_system.gd`、`production.gd`、`alchemy_system.gd`、`beast_system.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`src/application/game_session.gd`、`src/domain/game_state.gd`、`src/persistence/save_codec.gd`、`save_manager.gd`、`src/presentation/reincarnation_panel.gd`、`src/debug/runtime_inspector.gd`。三張PNG及其import、既有輪迴manifest擴充、OFL runtime兩字型／manifest；`project.godot`、`export_presets.cfg`、兩支新Runner與UID、SKS-P1／EARLY-V1-B版本及數量斷言遷移、`tools/run_all_runners.ps1`、新驗收場景／fixture／UID與稽核工具。既有CONTENT-P1-SKILL Runner亦依現版codec再生其隔離fixture，沒有改其取得邏輯或技能。文件同步README、ROADMAP、docs19／21／25／31、handoff、development-status、驗收／資產證據與英文updata checkpoint。原有大量dirty成果保留，沒有以Git HEAD還原。

最後卡片另明示目前／下階百分比（滿五階顯示已圓滿），原生117項再通過；重匯出與兩包壓縮皆exit0。瀏覽器原始截圖是JPEG，已改用.jpg副檔名保留原bytes，沒有將新JPEG誤名PNG。

最終收尾：`python tools/content_p1_talents_audit.py` 28項／failures=[]；字型check、UTF-8／八份Web觀測／100支覆蓋與兩候選壓縮hash核對皆通過，針對本批修改的`git diff --check` exit0（僅LF→CRLF提示）。最後包hash見[final-builds.json](artifacts/content-p1-talents/final-builds.json)，最後800下階文字[Web截圖](artifacts/content-p1-talents/web-800-next-rank-final.jpg)。全量以實際清單100支為準，沒有沿用前批文件99推算101。未通過／待辦：三張新圖人工美術接受；歷史套件外UIX-R7探索失敗與退出／import／IAB診斷按上文保留。本階段到此停止。

## 2026-10-23 美術接受與收結

使用者明確回覆「美術接受」，接受三張題圖及本批天賦卡現版呈現，最後人工美術閘門完成，CONTENT-P1-TALENT標DONE（桌面／Web有界）。沿用913規則／117原生／100支Runner及三橫式Web證據；下方及較早待辦文字為當時歷史，由本段覆蓋。本輪只改三圖與輪迴manifest的接受metadata、審閱／規劃／狀態文件及英文checkpoint；沒有重跑Godot、Runner、瀏覽器、匯出或修改PNG、公式、schema、玩家進度。

執行`python tools/content_p1_talents_audit.py`重新核對來源與三圖hash、既有通過JSON及凍結包；另驗UTF-8與本輪文件diff-check。P方案尚未由本次接受核定，未開工；下一大型任務請使用New Chat。未commit/push。

本次接受收結檢查：Python稽核28項／failures=[]、凍結Web hash保持；三圖accepted metadata與十份文件UTF-8核對通過，文件diff-check exit0。
