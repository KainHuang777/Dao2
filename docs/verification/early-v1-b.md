# EARLY-V1-B：輪迴天賦量化與正式路徑驗收

## 2026-10-20 收結：DONE（桌面／Web 有界）

本段覆蓋下方 2026-10-18 的未完成狀態；舊量化表與歷史證據保留。

使用者本輪明確核定「維持現況，明訂為跨世進度」：靈界據點、靈晶與靈液獨立跨世保留，不算資源傳承天賦收益。規則差異 V2-022 由 open 改為 v2_decision。既有 `realms_data` 行為沒有改動；練氣期的靈界生產與仙池修行反哺仍暫停，築基後按既有規則恢復。輪迴詳情明列靈界保留，將重置建築明確寫為人界建築。

### 桌面瀏覽器證據

Windows 桌面 IAB，以真實滑鼠點擊、滾動及 iframe 重新開啟遊戲驗證。遊戲區為 1280×720、844×390、800×360 CSS px；寬式外層 viewport 1380×820，用來容納驗收工具列，沒有把外層高度冒充遊戲高度。這是桌面響應式驗證，非觸控／實機證據，沒有量測 FPS。瀏覽器 JPEG 原始證據皆以 `.jpg` 保存。

| 操作 | 實際觀察 |
| --- | --- |
| 48935／1280×720 購資源傳承 | Lv0→1，道心50→45，顯示下次轉世生效10%；revision1259 |
| 同 origin／844×390 購先天道體 | 內容內捲至第三卡，Lv0→1，道心45→30；revision1260 |
| 同 origin／800×360 購長生久視，拒寫 | 顯示保護／重試畫面；磁碟仍revision1260／道心30、沒有長生天賦 |
| 恢復寫入後點遊戲內重試 | 最終revision1262／道心20／三天賦各1；只扣一次，沒有重送研習 |
| 800×360 頁內二段確認轉世 | revision1263，reincarnation_count1→2，道心20→35；三天賦保留，Era1 Lv1／時間0／建築清除；靈力10、錢木0且鎖定 |
| 演出結束回洞府 | 壽元上限88（原80＋10%），修行進度可繼續；起手傳承在演出結束前已落盤 |
| 重開 iframe 真實重載 | revision1296，三天賦各1／道心35／世次2／靈力10；沒有重扣或重發轉世獎勵 |
| 48936 零天賦獨立 origin | 真實轉世後revision1259、天賦{}／道心15／世次2／靈力0；從0採集到20建茅屋，再補料升2階 |
| 零傳承重建重載 | revision1399／天賦{}／道心15／世次2／hut2，靈力92.2087603840593；生產恢復、建築保存 |

主矩陣使用既有 MFG-3 候選 `build/web-mfg3`，PCK SHA256 `9CBC5802D554DF73B94275CBBFE34D7EF2BBF24D4234D1D05E60854C695B3D5E`。本輪只改正式輪迴說明文字與規則註解，無天賦或收益邏輯修改。最終重新匯出 `build/web-early-v1b`，PCK SHA256 `DB6F12C4A35A8A37AED6FFF811F8CDA402C263BD79EA4EBA2999B4C44E83AFAB`；48937 補驗三橫式詳情內捲、政策文字與800×360真實購入，revision1259／道心45／資源傳承1。

fixture 為明示注資／壽盡診斷檔：前身是 earned Era2 檔，本輪設定世次1／道心50（零天賦案例0）／elapsed100000，刷新合法 envelope 時間。它只提供 UI 測試資格，**不是自然新檔流程或自然壽盡證據**；轉世及購入均由遊戲正式 UI 命令執行。首次種檔僅在新 origin 無槽位時進行，不覆寫既有槽位。

零傳承的瀏覽器證據終點為建屋升2階與重載，沒有聲稱本輪瀏覽器完整走到築基。完整再築基仍由本輪專項重跑的 **1010 模擬秒**證明。天賦 Lv0／1／2／5／10 效果矩陣與固定時長純天賦速度仍屬 CLI；Web 真實下一世包含天時等加成，不能把某次總修行增量冒充純1.1倍率。D-1/D-2 的自然流程證據維持各自原版範圍。

原始：[web-evidence.jsonl](artifacts/early-v1-b/web-evidence.jsonl)（九筆按操作順序：拒寫舊槽、恢復、新世、新世重複快照、天賦重載、零天賦新世、建屋2階、零天賦重載、最終候選購入）；[1280購入](artifacts/early-v1-b/web-1280-purchased.jpg)、[拒寫](artifacts/early-v1-b/web-800-write-denied.jpg)、[恢復](artifacts/early-v1-b/web-800-retry.jpg)、[88壽元](artifacts/early-v1-b/web-next-life-88.jpg)、[零傳承起手](artifacts/early-v1-b/web-zero-start.jpg)、[零傳承升階](artifacts/early-v1-b/web-zero-hut2.jpg)、[零傳承重載](artifacts/early-v1-b/web-zero-reloaded.jpg)、[最終政策1280](artifacts/early-v1-b/final-policy-1280.jpg)、[844](artifacts/early-v1-b/final-policy-844.jpg)、[800](artifacts/early-v1-b/final-policy-800.jpg)。

### 命令、結果與修正紀錄

引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：4.7.2.stable.official.ed1daf0bf，exit0，沒有更新引擎或模板。

| 命令／工具 | 最終結果 |
| --- | --- |
| `--headless --path . --script res://tests/early_v1b_talents_runner.gd` | 初次原有506 checks PASS；新增政策後 **527 checks PASS**，exit0；[最終log](artifacts/early-v1-b/policy-final.log) |
| 同上 `tests/m3a_reincarnation_runner.gd` | PASS，exit0；[log](artifacts/early-v1-b/m3a_reincarnation_runner.log) |
| 同上 `tests/m4a_realm_runner.gd` | PASS，exit0；[log](artifacts/early-v1-b/m4a_realm_runner.log) |
| 同上 `tests/uix_r7_reincarnation_ui_runner.gd`，APPDATA隔離到build/early-v1b-appdata | **75 checks failed=false**，exit0；[log](artifacts/early-v1-b/ui-final.log) |
| `--headless --path . --script res://tools/early_v1b_web_fixture.gd` | 最終exit0；隔離fixture用SaveCodec合法編碼，不改玩家進度 |
| `python -m py_compile tools/early_v1b_web_server.py` | exit0 |
| `python tools/subset_game_fonts.py --check` | exit0，未修改字型 |
| `--headless --path . --export-release Web build/web-early-v1b/index.html` | 最終exit0；[log](artifacts/early-v1-b/export-final.log)，沒有SCRIPT ERROR；user目錄診斷與巢狀專案警告保留 |
| `node tools/prepare_web_compression.mjs build/web-early-v1b` | exit0，候選compression.json及BGM companions生成；未改一般Web |
| `python tools/early_v1b_web_server.py --port 48935/48936/48937`（48936加`--zero`） | loopback服務與HTTP200／存檔快照POST204已驗；48935/48936在最終改預設build前啟動，服務既有MFG3包。最終工具預設服務新候選 |

新增政策測試覆蓋零／一階傳承下相同靈界庫存與設施保留、合法保存往返、練氣不生產／不反哺與築基恢復反哺。這是規則證據，不冒充靈界有資產的真實瀏覽器跨世矩陣。

失敗如實保留：新增測試首輪漏 `sim_tick` metadata，523 checks中兩項encode失敗，補齊必填欄位後527通過（失敗log為final-runner.log）；初次驗收服務在工具管線內啟動逾時，改隱藏背景程序＋檔案log成功。初次瀏覽器截圖是JPEG卻以PNG副檔名保存，import失敗；依FF-D8檔頭改副檔名並移除本輪錯誤sidecar。首輪匯出目錄未建立導致exit1；建立候選目錄後重匯出exit0（失敗export.log與最終export-final.log均保留）。UI首跑未設隔離APPDATA，初始化offline_summary為Nil且未結束，已Ctrl+C停止；改專案內APPDATA後75 checks通過。初次相對log路徑亦有user://E:診斷，改絕對log路徑解決。最終UI仍有既有anchor／Font／CanvasItem／ObjectDB／resource退出診斷，不能稱零診斷。沒有因上述失敗修改規則或掩蓋log。

### 交接

修改來源：`src/presentation/reincarnation_panel.gd`（說明文字）、`src/simulation/reincarnation_rules.gd`（核定政策註解）、`tests/early_v1b_talents_runner.gd`（政策回歸）、新增 `tools/early_v1b_web_fixture.gd` 與UID、`tools/early_v1b_web_server.py`；另更新本報告、V2-022、docs/23、README／ROADMAP／handoff／development-status與英文updata頂部。

未改公式、schema、玩家資料；不覆寫D凍結Web與origin。`build/web/index.pck`仍SHA256 `7E7E619DCAA28FB05E1C397ADCC24CE9071D9B53B4E8FA6379C186E0AF9F9400`。沒有commit/push，保留工作區其他未提交成果。裝置項與冷啟動依政策延期，非本輪阻擋。沒有新美術或FPS承諾。

本階段收結停止；下一個New Chat接 **EARLY-V1-C：結丹法題材圖與三桌面尺寸實際研習／保存恢復／重載**。D人工節奏判定與渡劫C/D不因本次收結改DONE。

最終資料檢查：九筆原始Web快照與[摘要](artifacts/early-v1-b/web-summary.json)一致；JPEG檔頭、UTF-8、V2-022與三項壓縮manifest檢查通過，`git diff --check` exit0（既有LF／CRLF提醒保留）。本輪三個隔離伺服器已停止、驗收分頁已關閉、臨時viewport覆寫已重設。

## 2026-10-18 歷史交付

2026-10-18。狀態 **IN_PROGRESS**：規則、正式命令、隔離存檔、天賦收益／等待表已交付；桌面 Web 實際操作與靈界跨世保存政策仍未完成，因此不標 DONE。

## 結論

- 三項天賦的購入、預覽、真正轉世、保存重載、下一世生效與零傳承重建，均以 `GameSession.submit` 的正式命令及隔離存檔驗證。
- 天賦成本與公式未改；仍為 `base 5／10／15 × 2^level`、上限 10 階、道心扣費。
- 首二次輪迴的自然道心底線為 20（Era3）與 15（Era2），合計 35。以底線收入計，首世可理解選擇為：資源傳承 Lv1／Lv2、長生久視 Lv1、先天道體 Lv1；第二次可再加長生久視 Lv2 或資源傳承 Lv2，其餘需更多建築等級或更多次輪迴。
- 資源傳承只給下一世「已解鎖基礎資源」的新庫容比例；前世靈力庫存 777 不會被當作起手量。零傳承重建 Era1→Era2 為 1010 模擬秒。
- 靈界 `realms_data` 目前不經輪迴清除，這是獨立政策缺口，不是天賦效果。

## 執行命令與結果

Godot：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`（`4.7.2.stable.official.ed1daf0bf`）。

| 命令 | 結果 |
| --- | --- |
| `--headless --path . --editor --import` | exit 0；僅既有 `res://src/verification/r7f5b/project.godot` 被忽略警告；無 `SCRIPT ERROR` |
| `--headless --path . --script res://tests/early_v1b_talents_runner.gd` | `PASS: EARLY-V1-B 506 checks`；exit 0；無 `SCRIPT ERROR` |
| `--headless --path . --script res://tools/early_v1b_observation.gd` | `EARLY-V1-B observation: variants=27 checks=145 failures=0`；exit 0 |

專項回歸：`tests/sks_p1_runner.gd` 58 checks、`tests/m3a_reincarnation_runner.gd`、`tests/skills_b1_runner.gd` 41 checks、`tests/uix_r8_skills_ui_runner.gd` 101 checks 均 exit 0。

產物：[observation.md](artifacts/early-v1-b/observation.md)、[observation.json](artifacts/early-v1-b/observation.json)。規則 `core-flow-12-skills-p1`、schema 4、content `c1b7f1520764d30194af498e0b0c9a12683f53c182716283dd3742ecfde67384+res1-d-2+skills-p1`。

## 正式化界線

- 購買：官方 `learn_talent`；消耗、升級、回執重播與道心不足原子拒絕均驗。
- 預覽：官方 `get_reincarnation_preview`；天賦差異由 `view.talents` 與 `ReincarnationRules.inheritance_ratio` 呈現。
- 轉世：官方 `reincarnate`；fixture 只設 Era3／Lv10、`rebirth_lotus=1`、靈力 777、道心 20000、錢／木解鎖。`rebirth_lotus` 無正式內容條目，僅作資格 fixture，不宣稱可達。
- 保存：`SaveCodec.encode/decode` 與 `SaveManager` 的隔離 `Memory` adapter；另注入槽位寫入失敗，確認舊槽保留、重試成功。
- 觀測皆為模擬秒；不是 wall-clock、真人節奏或瀏覽器證據。

## 成本與累積成本

| 天賦 | Lv1 | Lv2 | Lv5 | Lv10 | Lv10 累積 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 資源傳承 `resource_inheritance` | 5 | 10 | 80 | 2560 | 5115 |
| 長生久視 `lifespan_extension` | 10 | 20 | 160 | 5120 | 10230 |
| 先天道體 `innate_dao_body` | 15 | 30 | 240 | 7680 | 15345 |

三項全滿合計 30690 道心。10 階後購入以 `TALENT_MAX_LEVEL` 原子拒絕，不扣費。

## 收益與等待差異表

基準：壽元 4800 模擬秒；Era1 Lv1 升階需求 60 模擬秒；Era3 Lv10 需求 1436.977 模擬秒（未計金丹縮時）。「下世靈力」為新檔已解鎖基礎資源中的靈力起手量；錢、木在下世新開局為 0 且鎖定。

| 天賦／階 | 累積道心 | 壽元增量 | 修行速度 | 下世靈力起手 | 首世 20 可負擔 | 首二世 35 可負擔 |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| 資源傳承 Lv1 | 5 | 0 | ×1.0 | 10 | 是 | 是 |
| 資源傳承 Lv2 | 15 | 0 | ×1.0 | 20 | 是 | 是 |
| 資源傳承 Lv5 | 155 | 0 | ×1.0 | 50 | 否 | 否 |
| 資源傳承 Lv10 | 5115 | 0 | ×1.0 | 100 | 否 | 否 |
| 長生久視 Lv1 | 10 | +480 | ×1.0 | 0 | 是 | 是 |
| 長生久視 Lv2 | 30 | +960 | ×1.0 | 0 | 否 | 是 |
| 長生久視 Lv5 | 310 | +2400 | ×1.0 | 0 | 否 | 否 |
| 長生久視 Lv10 | 10230 | +4800 | ×1.0 | 0 | 否 | 否 |
| 先天道體 Lv1 | 15 | 0 | ×1.1 | 0 | 是 | 是 |
| 先天道體 Lv2 | 45 | 0 | ×1.2 | 0 | 否 | 否 |
| 先天道體 Lv5 | 465 | 0 | ×1.5 | 0 | 否 | 否 |
| 先天道體 Lv10 | 15345 | 0 | ×2.0 | 0 | 否 | 否 |

修為速度以 60 模擬秒實測：Lv1／2／5／10 分別累積 66／72／90／120 修行秒；升階需求不變。壽元增量為 Lv1／2／5／10 的 +480／+960／+2400／+4800 秒。

首世 20 與次世 15 是 Era3／Era2 的保底道心；建築等級總和更高時收入會提高，本表不把 20000 fixture 道心計入自然收入。因此「可負擔」是可理解的最低門檻，不是玩家唯一收入。

## 轉世與下一世

- 購買後轉世：世次 +1、天賦保留、Era1／Lv1、訓練與總時間歸零、技能／建築／丹藥清除、技能點 0 且鎖定。
- 資源傳承 Lv1／2／5／10 的下世靈力起手為 10／20／50／100；前世持有 777 不影響結果。
- 長生久視只提高本世與後續壽元上限；先天道體只提高修行累積，不改變單級需求。
- 零傳承重建：不使用天賦、只以正式 build／gather／upgrade／level_up／breakthrough，Era1→Era2 為 1010 模擬秒。
- 存檔重載保留三項天賦與道心，倍率一致；寫入失敗不覆寫舊槽，重試成功。

## 未完成／未宣稱

- 桌面 Web 實際購買、轉世、重載與 zero-inheritance 重建尚未以真實瀏覽器操作；本輪只有 headless CLI。
- 靈界跨世保存政策未定：`ReincarnationRules.apply_reincarnation` 未清 `realms_data`，洞府／靈晶／靈液跨世保留。需另案核定，不能算作資源傳承收益。
- `rebirth_lotus` 不是正式可達內容；真正前期轉世仍主要靠壽元耗盡。
- 未涵蓋真人節奏、FPS、觸控、實機、冷啟動。
