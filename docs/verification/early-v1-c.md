# EARLY-V1-C：前期技能收尾與金丹可達性驗收

## 2026-10-20 人工美術接受／收結

**DONE（桌面／Web有界）**。使用者明確回覆「結丹法新圖接受」，接受本次金丹、青玉丹座與氣環新圖；manifest 的 `golden_core_formation.status` 更新為 `accepted`，附接受日期與原話。沿用下方同日既有 CLI／原生／桌面三橫式 Web、研習費用與保存恢復／重載驗證，C 的最後人工閘門完成。

本次修改 README、ROADMAP、ai-handoff、development-status、本報告、SKS-P1驗收、docs20／21／23、manifest 與 updata。PowerShell／Python 核對 UTF-8、JSON、來源圖／runtime SHA256及文件連結，並執行本次檔案 `git diff --check`；結果見本輪 development-status。未重新執行 Godot／Runner／瀏覽器／匯出，未改圖片、程式、規則、schema或玩家資料，未commit/push。下方待接受狀態保留為交付時歷史，本節覆蓋其現況。

下一任務為 EARLY-V1-D／RES1-D 人工節奏判定；本次不代表該項放行，也不啟動後續技能或TRIB工作。此階段停止，下一大型任務使用 New Chat。

## 2026-10-20 交付：程式／桌面 Web 已驗，待新圖人工接受

**IN_PROGRESS（僅待結丹法新圖人工美術接受）**。以下 2026-10-18 記錄保留為歷史；本節覆蓋其中「圖未生成／Web未驗」現況。R8 原六圖的接受不追認本張新圖。

- 使用內建 ImageGen 生成透明金丹＋青玉丹座＋金色氣環；原稿 1254×1254、runtime 336×336，完整 alpha bounds 裁切後 LANCZOS 等比縮放，四周至少16px透明安全邊；無繪圖補筆。單一 RGBA 物件組，文字／狀態／按鈕皆由 Godot 渲染。
- 圖片：[runtime](../../assets/ui/skills-painted/golden_core_formation.png)、[原稿](artifacts/early-v1-c/originals/golden_core_formation.png)、[完整提示詞](artifacts/early-v1-c/golden_core_formation-prompt.txt)、[紙底／112及80px預覽](artifacts/early-v1-c/art-paper-preview.png)。來源為本專案原創 AI 生成，未使用外部參考圖，不宣稱第三方商用授權；來源／用途／切層／尺寸／處理／SHA256 已寫入 manifest，狀態 `pending_human_acceptance`。
- 修正實際短橫式發現的成功訊息擠壓：技能頁小高度將成功／恢復提示併入固定點數頁首，來源留 TIP；頂部間距6→2。800×360的可捲區由118提升至122px，可完整顯示122px結丹法卡。正文仍16／頁首18、操作≥44px；保存錯誤與重試維持原顯示。不更改共同字型、分頁或關閉樣式。
- 本輪正式變更：`assets/ui/skills-painted/golden_core_formation.png`／`.import`／`manifest.json`、`src/presentation/skill_study_view.gd`、`src/presentation/system_actions_panel.gd`、`tests/uix_r8_skills_ui_runner.gd`。工具為 `tools/early_v1c_art.py`、`early_v1c_web_fixture.gd`、`early_v1c_web_server.py`、`early_v1c_native.gd`；各 Godot `.uid` 保留。未改技能數值／規則／schema／玩家進度，未 commit/push。

### 命令與驗證

引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。以下以 `APPDATA=E:/WORK/Dao2/build/early-v1c-user` 隔離原生資料，日誌放在本節 artifacts 目錄。

| 命令／測試 | 最終結果 |
| --- | --- |
| `python tools/early_v1c_art.py` | exit0；生成alpha包裝、manifest、三尺寸檢視圖 |
| `--headless --path . --editor --import` | exit0；[log](artifacts/early-v1-c/import-final-stdout.log) |
| `--headless --path . --script res://tests/early_v1c_skills_runner.gd` | 159 checks、exit0；[log](artifacts/early-v1-c/early_v1c_skills-stdout-20261020.log) |
| 同上，`tests/sks_p1_runner.gd`／`skills_b1_runner.gd`／`m3a_reincarnation_runner.gd` | 58／41及輪迴回歸均exit0；保留原遷移失敗／archive／retry證據 |
| 同上，`tests/uix_r8_skills_ui_runner.gd` | 最終106 checks failed=false、exit0；含七圖、成功後完整卡及保存拒寫重試；[log](artifacts/early-v1-c/ui-feedback-accepted-stdout.log) |
| 同上，`feature_navigation`／`m2d_responsive_ui`／`m3b_spirit_beast`／`m5b_realm_content`／`uix_r11_decisions_ui` runners | 五項均exit0；共用panel三模式回歸 |
| `--path . --script res://tools/early_v1c_native.gd`（非headless） | 最終19 checks failures=[]、exit0；三尺寸六張原生圖；[結果](artifacts/early-v1-c/native-result.json) |
| `PYTHONPATH=build/tool-deps python tools/subset_game_fonts.py --check` | exit0；[結果](artifacts/early-v1-c/font-final.json) |
| `--headless --path . --export-release Web build/web-early-v1c/index.html` | 最終exit0；[log](artifacts/early-v1-c/export-final-stdout.log) |
| `node tools/prepare_web_compression.mjs build/web-early-v1c` | 最終exit0；brotli及四個BGM companion通過；[log](artifacts/early-v1-c/compression-final.log) |
| `python tools/early_v1c_web_server.py --port 48938`＋Cua瀏覽器 | 隔離正式遊戲滑鼠研習／拒寫／恢復／重載通過；非自然流程或FPS證據 |

候選 `build/web-early-v1c/index.pck` SHA256 `C24B8098BE761CE4CB4D9B40EB981CB0EA0F959F128B1D8B1FA0F74A9A05D66B`。既有凍結 `build/web/index.pck` 仍 `7E7E619DCAA28FB05E1C397ADCC24CE9071D9B53B4E8FA6379C186E0AF9F9400`，未覆寫。未因單張圖與局部排版修改重跑全量82 runners；以上為本輪適用的專項與共用panel回歸。

### 真實桌面瀏覽器結果

環境：Codex in-app browser、隔離origin `127.0.0.1:48938`，滑鼠與滾輪；外層1360×850容納控制列，遊戲iframe分別1280×720／844×390／800×360。DOM實讀canvas CSS為1279×719／843×389／799×359，沿既有canvas邊界差1px，非強制固定正式畫布。結束已恢復瀏覽器viewport。

fixture：從既有隔離技能檔解碼、重包官方SaveCodec；明示注入Era3 Lv1、點數8060、藏經閣／經書殿各1、築基功1、已入宗儲物法寶3；時間游標更新至當次，**不證明自然取得資源、貢獻或完整新檔節奏**。研習由真實滑鼠觸發正式命令。

| 範圍 | 結果／證據 |
| --- | --- |
| 初版1280結丹法 | 滑鼠實際研習，拒寫後重試恢復；0→1階，回執cost7650僅一次；修煉時間×1.000→×0.900、HUD需求240→216秒 |
| 最終800 | 基礎冥想2→3階，cost90；成功訊息與完整卡同屏；[圖](artifacts/early-v1-c/final-web-800.png) |
| 最終844 | 基礎冥想3→4階，寫入拒絕；拒寫狀態再次點重試仍失敗，恢復後成功，不變成5階；結丹法卡可完整捲至；[拒寫](artifacts/early-v1-c/final-web-denied-844.png)、[完整卡](artifacts/early-v1-c/final-web-844.png) |
| 最終1280 | 基礎冥想4→5階、滿階禁用；點數不足禁用、結丹法1階×0.900；[圖](artifacts/early-v1-c/final-web-1280.png) |
| 最終重載 | 基礎冥想5／築基功1／結丹法1仍保留；六個研習回執（冥想五次各90、結丹一次7650）不增加，沒有重扣；[圖](artifacts/early-v1-c/final-reload.png)、[原始證據](artifacts/early-v1-c/browser-evidence.jsonl) |
| 原生版面 | [1280](artifacts/early-v1-c/native-golden-1280x720.png)、[844](artifacts/early-v1-c/native-golden-844x390.png)、[800](artifacts/early-v1-c/native-golden-800x360.png)，完整圖／成本／44px操作及固定頁首 |

採集點數仍自然生產，因此畫面點數會隨經過時間增加；精確單次費用以正式保存回執核對，不將兩張相隔數秒的數字差當扣費。瀏覽器warn/error查詢為空，保存故障透過預期SecurityError注入並在遊戲顯示；[console](artifacts/early-v1-c/browser-console-final.json)。未宣稱IndexedDB、FPS或全七項各自Web購買；七項資格、扣費、重載、輪迴清除皆由159項規則與相關runner覆蓋。

### 初次失敗與限制

- 初次import將`--log-file`誤用`res://`，有無法建立`res://docs`及預設`user://`診斷；程序exit0，後續改絕對log及隔離APPDATA成功。原生／headless仍有既有Font RID、CanvasItem、ObjectDB退出診斷，不宣稱零錯誤日誌。
- 48937沙箱服務連線逾時／本機socket權限不足；以已授權的沙箱外loopback服務48938和新分頁完成。舊錯誤分頁的data URL造成一次導航／關閉工具拒絕，不是遊戲失敗。兩服務於完成後停止。
- 初版訊息併入頁首後，800的scroll118px仍低於card122px，UI測試兩次exit1；縮減容器間距後106 checks與原生19 checks通過，初次log保留。一次DOM讀取不支援跨frame contentDocument，改以frameLocator讀canvas尺寸成功。
- 尚需使用者接受本張金丹圖；在此之前整體C維持IN_PROGRESS。觸控／實機／高DPR及冷啟動依既定政策延期，非當前阻擋。下一步是新對話收美術回饋，接受後僅收結C；D人工節奏仍獨立，不自動開Era4或TRIB-C。

本輪收尾：`git diff --check`（本輪來源／文件）exit0；9份文件嚴格UTF-8、報告本地連結、runtime與原稿SHA256／alpha安全邊、最終六筆回執總成本8100（7650＋5×90）核對通過，見[完整性結果](artifacts/early-v1-c/final-integrity.json)。文件同步使用`python tools/early_v1c_checkpoint.py`；兩個本輪服務以Ctrl+C停止，exit1為主動終止而非驗收失敗。

## 2026-10-18 歷史交付

2026-10-18。狀態 **IN_PROGRESS**：七項技能的規則、正式可達路徑、點數產出／容量、成本、效果、保存重載、輪迴清除，以及 Web 匯出／字型／壓縮已交付；金丹題材圖、人工美術接受與三橫式真實瀏覽器研習／保存重試仍未完成，因此不標 DONE。

## 結論

- 六項築基技能與結丹法均可在正式路徑習得；費用／效果未改。
- 正式可達瓶頸已量化：藏書閣＋藏經閣的技能點上限 6200，結丹法 7650，缺口 1450。自然累積會卡在 6200。
- 唯一已驗的正式補足路徑為宗門功法 `storage_talisman`：Lv3 提供 +30% 儲存上限，技能點上限 8060，足以習得結丹法。Lv3 為由 7650／6200 推得的最低階；Lv10 上限 12400 為公式推導。
- 輪迴以官方命令清除技能、技能點與研習建築，並重新鎖定技能點；天賦保留但不繼承技能點。
- Web 匯出、字型重建與 `--check`、brotli 壓縮均 exit 0。真實瀏覽器三橫式研習／拒絕保存／重載與金丹圖仍待補。

## 執行命令與結果

Godot：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`（`4.7.2.stable.official.ed1daf0bf`）。

| 命令 | 結果 |
| --- | --- |
| `--headless --path . --editor --import` | exit 0；僅既有 `res://src/verification/r7f5b/project.godot` 警告；無 `SCRIPT ERROR` |
| `--headless --path . --script res://tests/early_v1c_skills_runner.gd` | `PASS: EARLY-V1-C 159 checks`；exit 0 |
| `--headless --path . --script res://tools/early_v1c_skill_observation.gd` | `EARLY-V1-C OBSERVATION \| checks=12 failures=0 golden_reached=true gap_7650_6200=1450.0`；exit 0 |
| `--export-release Web build/web/index.html`（字型重建後） | exit 0 |
| `python tools/subset_game_fonts.py --check`（`PYTHONPATH=build/tool-deps`） | exit 0 |
| `node tools/prepare_web_compression.mjs build/web` | exit 0 |

專項與回歸：`tests/sks_p1_runner.gd` 58 checks、`tests/skills_b1_runner.gd` 41 checks、`tests/uix_r8_skills_ui_runner.gd` 101 checks、`tests/m3a_reincarnation_runner.gd` 均 exit 0。SKS-P1 的遷移失敗／archive／retry 證據保留於 [res1-e-skills-p1.md](res1-e-skills-p1.md)。

產物：[observation.md](artifacts/early-v1-c/observation.md)、[observation.json](artifacts/early-v1-c/observation.json)、[runner-measurement.json](artifacts/early-v1-c/runner-measurement.json)。

## 技能點產出與容量

| 來源／狀態 | 數值 |
| --- | --- |
| 藏書閣 Lv1（Era2） | 2.0 點／模擬秒；基礎上限 200，約 100 秒滿 |
| 藏書閣 Lv2 | 5.656854 點／模擬秒 |
| 藏書閣 Lv3 | 10.392305 點／模擬秒 |
| 藏經閣 | +6000 上限；合計 6200 |
| 實測銀行 | 6200 點用 630 模擬秒填滿（Lv1） |
| 宗門儲物法寶 Lv3 | 上限 8060（6200 × 1.3） |

## 七項技能量測表

取得秒數以「累積至該費用 ÷ 2.0 點／秒」推導；實測等待為已具部分點數的正式 session，因此較短。

| 技能 | Era | 費用 | 上限 | 前置 | 效果 | 取得秒（Lv1 產率） | 實測等待 |
| --- | ---: | ---: | ---: | --- | --- | ---: | ---: |
| `basic_meditation` | 2 | 90 | 5 | 無 | 靈力產出 ×1.1／級 | 45 | 0 |
| `qi_condensation` | 2 | 1800 | 5 | 無 | 靈力產率 +2／級 | 900 | 800 |
| `foundation_building` | 2 | 3600 | 5 | 無 | 金錢產出 ×1.2／級 | 1800 | 1700 |
| `qi_storage_1` | 2 | 120 | 1 | 無 | 靈力上限 +200 | 60 | 0 |
| `body_strengthening_1` | 2 | 1000 | 1 | 無 | 金錢上限 +2000 | 500 | 400 |
| `building_mastery_1` | 2 | 200 | 1 | 無 | 四項生產設施等級上限 +10 | 100 | 0 |
| `golden_core_formation` | 3 | 7650 | 5 | `foundation_building` Lv1 | 修煉時間 ×0.9^級 | 3825 | 730 |

`building_mastery_1` 只作用於木屋、林場、石礦、藥田；倉庫、茅屋、靈池不受影響，已逐項驗證。`foundation_building` Lv2 的費用與 `1.2^2` 效果、滿階／前置／境界／研習建築鎖的原子拒絕均已驗。

## 金丹瓶頸與正式可達性

- 基礎可達上限 6200；結丹法費用 7650；缺口 **1450**。
- 在無儲存加成下，自然累積 16000 模擬秒仍固定在 6200，官方 `learn_skill` 以 `INSUFFICIENT_SKILL_POINT` 原子拒絕。
- 正式路徑：官方 `join_sect` → 官方 `learn_sect_technique("storage_talisman")` Lv1–3 → 累積至 7650 → 官方 `learn_skill`。實測扣除 7650，`next_level_required_seconds` 由 240 降為 216。
- 宗門貢獻 1000、木材 950 是在官方入宗後注入的 fixture；歷練任務生成含 RNG，非確定性。技能購買與研習本身仍為官方命令。
- Era3 Lv10 基準 1436.977 模擬秒；結丹法 Lv1–5 的必要時間為 1293.279／1163.951／1047.556／942.800／848.520，累積節省 1888.777 模擬秒（公式推導，Lv1 效果有 view 實測）。

## 保存、重載與輪迴

- 技能、技能版本 2、技能點、藏書閣／藏經閣可完整往返；未知技能在 encode 與被竄改的 decode 均拒絕。
- 隔離 `Memory` adapter 寫入拒絕會回報失敗；重試成功；重載保留結丹法與技能點。
- 官方 `reincarnate`（`rebirth_lotus` 僅資格 fixture）後：技能清空、技能點 0、`skill_point` 重新鎖定、`ever_obtained` 重置、藏書閣／藏經閣歸零、Era1 Lv1、得保底道心 15。
- 輪迴後習得天賦，第二次轉世仍保留天賦，但不發技能點；新世無藏書閣故無技能點生產。

## Web 匯出與字型

- 首次字型 `--check` 失敗：`Dao2Sans-VF.ttf: missing glyphs [28528]`（U+6F70），來源是既有 TRIB-0 文案 `src/presentation/breakthrough_sequence.gd:73`，非本任務新增。
- 重建字型：`PYTHONPATH=build/tool-deps python tools/subset_game_fonts.py`，覆蓋 1832 codepoints。
  - `Dao2Sans-VF.ttf` sha256 `e7144e98b62c4440f40f221209b53e215a563bfbcd3d9677809ed9f721b076ea`，934260 bytes。
  - `Dao2Serif.ttf` sha256 `c371d5b5043b03b1492999d0364cab4aa90b55be066768b4bee05a2053043cd7`，1311896 bytes。
- 重建後 `--check` exit 0；Web 重新匯出 exit 0；壓縮 quality 9、4 個 BGM companions，`index.pck` 34690504 bytes、sha256 `9DF6F9C09210D0C6945DD1EFC48B17D6A68CC8A328446C8012BC42928A786425`。

## 未完成／未宣稱

- **金丹題材圖待生成＋人工美術接受**：`assets/ui/skills-painted/manifest.json` 的 `golden_core_formation` 仍為 `pending_art`，沒有 PNG、來源尺寸、runtime 尺寸、alpha、processing、sha256；鍵名仍是 `runtime_png` 而非已接受條目的 `runtime`。本輪沒有影像生成工具，也沒有以程式繪圖冒充。
- **真實瀏覽器三橫式未驗**：1280×720／844×390／800×360 的實際滑鼠研習、6200→6110 扣點、拒寫恢復、重載保留、DOM／canvas 尺寸與 console 乾淨度均未取得。headless／CLI 不能替代。
- 觸控、實機、高 DPR、冷啟動依政策延期，非本輪阻擋，也不能寫成通過。
- `rebirth_lotus` 無正式內容；前期實際轉世仍靠壽元耗盡。
