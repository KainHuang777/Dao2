# 開發狀態與交接紀錄

更新：2026-10-02（CONTENT-AUDIT／DOC-A-R1）。區分實作、測試與完整驗收；歷史缺口不作目前接手順序。

## 目前任務與下一步

- **M3-B-CONTENT-AUDIT（2026-10-02）：DONE（清單與模型檢查，非內容修復）**。依使用者提供的本機 Dao1 `D:\Temp\temp\Dao\Dao` 唯讀核對：61 資源／59 建築含倉儲／30 合成配方；Dao2 只載 7 資源／10 座 Era 1 建築，另有三種重設計丹藥。CSV audit／Godot 記憶體 probe 均 exit 0，正式升到 Era 2 新可見內容為 0。advanced 拒載、跨境界解鎖／通用配方／功法缺席、資源 UI 寫死、丹藥雙庫存、內容升版補 ID 與茅屋容量退縮均待處理。來源四份 CSV 與 M0-B 固定 hash 不同，未覆寫舊 fixture。詳見 [清單與模型報告](verification/content-progression-audit-2026-10-02.md)。本輪僅新增審核工具／證據與文件，保留既有修改。
- **M3-B-CONTENT1（2026-10-02）：DONE（CLI 契約層）**。新模組 progression／content_schema／content_reconciliation＋新 runner 與 fixtures；content_loader 拒未知欄位並將 recipe／consumable／skill／新資源欄位納入 content hash；foundation_pill 改 resource Amount 單一權威（容量 clamp 200、CAPACITY_FULL），sect/fortune 發放與 share import 均一致走權威／reconcile；舊存檔載入走版本化 reconciliation（zero-fill 不解鎖、衝突保留既有值、不重發丹藥）。互動審核發現並修復 share import、sect/fortune bypass、NaN/inf、unlock_skill 逃漏與 requirement 未交叉驗收等缺口。`--import` exit 0；新 runner PASS；`run_all_runners.ps1` **35/35 PASS exit 0**。未搬 Dao1 CSV、未新增 Era 2 正式 content（下接 CONTENT2）；瀏覽器／IndexedDB／實機待驗項不變。見 [M3-B-CONTENT1](verification/m3-b-content1.md)。
- **M3-B-CONTENT2（2026-10-02）：DONE（完整 Era 2 經濟切片；headless CLI 驗收）**。正式內容新增 Era 2 切片：`content/eras/era2.json`（Dao1 legacy 數值；capacity 鍵去 `_max` 修正潛在破格 bug）、`content/resources/era2.json`（9 資源含 unlock 陣列）、`content/buildings/era2.json`（library／scripture_hall／stone_mine_mid／iron_mine／hunter_camp／rice_field＋5 中級儲量）、`content/recipes/era2.json`（3 配方）、`content/skills/era2.json`（6 技能），全經 manifest 接線。源碼：`content_reconciliation.gd` 新增 `unlock_eligible_resources`；`command_processor.gd` 掛 `_append_progression_unlocks` 於升級／破格（發 `resource_unlocked` 事件）。E2E 鏈 headless 驗證：era-1 門檻 lingli_max 500（storage_lingli 5 級）→ 破格 → 中級儲量即刻滿足 era-3 門檻 2000／1000。`--import` exit 0；新 runner PASS；`run_all_runners.ps1` **35/35 PASS exit 0**（`tmp\m3b2_suite4.log`，SCRIPT ERROR 0；中途 suite3 紀錄已修 m1c 比較器與 core_positive_flow 回歸）。prereqTech 不搬＝V2-012、resource_multiplier 生效＝V2-013 等平價決策見 `docs/rule-differences.md`。瀏覽器／觸控／IndexedDB 本輪未驗；技能購買／生效指令管道未做（下接 M3-B 技能或 UI 任務）。見 [M3-B-CONTENT2](verification/m3-b-content2.md)。
- **M3-B-SKILL-CMD（2026-10-02）：DONE（headless CLI 契約層）**。新增 `learn_skill` 指令管道接通 6 個 era-2 技能內容：`SkillSystem`（flat 定義表價扣 skill_point、can_learn 六種原因、事件 `skill_learned`、changed_ids 含資源與 skills）、CommandProcessor 分支（EMPTY_SKILL_ID／failure 包裝）、GameSession 白名單＋shape 校驗＋便捷方法＋get_view `skills`（6 技能攜 level／max／cost／can_learn／reason）。新 runner T1–T10 共 71 checks：成功購買（100−90=10）、至 max 拒絕 SKILL_MAX_LEVEL、餘額不足不動狀態、成本不隨等級變動（V2-015）、save↔load roundtrip 與 reconcile zero-fill、GameSession e2e。`--import` exit 0；單跑 exit 0（71 PASS／0 FAIL）；`run_all_runners.ps1` **37/37 PASS exit 0**（補上遺漏的 m3b_content2_runner，36→37）。獨立稽核 VERDICT PASS（D1–D10）。成規差異記 V2-015／V2-016於 `docs/rule-differences.md`。UI 整合（HUD／模態接 learn_skill）、瀏覽器／觸控／IndexedDB 本輪未驗；技能 effects 接線待內容。見 [M3-B-SKILL-CMD](verification/m3-b-skill-command.md)。
- **M3-B-SKILL-EFFECT（2026-10-02）：DONE（headless CLI 契約層）**。技能 effects 接線完成（Dao1 平價）：`production.gd` 的 `compute_rates(…, skills={})`／`compute_caps(…, skills={}, skill_max_multipliers={})` 支援 `*_rate`（amount×level）、`*_multiplier`（amount^level）、`*_max`／`all_max`（平加 amount×level）；`command_processor.gd` 的 `level_cap` 支援 `building_level_cap`，`_apply_level_up` 與 `game_session.gd:178` 均走 `Cultivation.skill_time_multiplier`；呼叫端（time_advancer／game_session／living_abode／reincarnation_rules）補傳 `state.skills`。`content/skills/era2.json` 六技能補 Dao1 CSV effect 欄位；`content_schema.gd` 接受選填 effect（type 非空、amount 數字 ≥0）。新 `tests/m3b_skill_effect_runner.gd`（非空洞乘法測試採臨時改 content rate 並還原的作法）；runners 合計 38。`--import` exit 0 無 SCRIPT ERROR（`tmp\m3b2_import3.log`）；全套 **38/38 PASS exit 0**（`tmp\m3b2_suite8.log`，主控台實錄 SUITE_EXIT=0）。獨立 fusion-auditor 審計後已修：game_session:178 漏接、空洞乘法測試、runner 註解。接受限制：schema 無 effect-type 白名單、`skill_max_multipliers` 參數保留無呼叫端（V2-016 更新見 `docs/rule-differences.md`）。瀏覽器／觸控／IndexedDB 本輪未驗；UI 未顯示效果數值。見 [M3-B-SKILL-EFFECT](verification/m3-b-skill-effects.md)。
- **下一任務候選**：M3-B 靈獸／成就，或技能 effects UI 呈現（get_view 已攜 skills，讓 HUD／模態顯示效果與入手途徑），先核對 Roadmap 相依。後續大型任務使用 New Chat。
- **DOC-A-R1 文件現況複核：DONE**。核對 9/28 後 Git 差異、updata、來源、測試入口與日誌；同步 README、Roadmap、AI 交接、M3-B／M4-A／REF-A 驗收入口。版本檢查 exit 0；首次 Runner 因沙箱不能寫隔離 fixture exit 1，正常授權重跑 **34/34 PASS、exit 0**。未重跑 Web 匯出或瀏覽器；修改、命令與限制見 [複核紀錄](verification/doc-a-r1.md)。
- **ENV-CLONE-1 環境安裝與 Runner 複跑（本機 clone）：DONE**。乾淨 clone 安裝 Godot `4.7.2.stable.official.ed1daf0bf`（`tools\godot\4.7.2\`＋`_sc_` 自包含 templates）；`--import` exit 0（196 素材）。首跑發現 `bgm_era_playlist_runner.gd` 與 `living_abode.gd:1009` 的 era 防護不一致（直接改 `state.era_id` 繞過 `_process` 流程）且失敗路徑未 quit 掛起整組；依證據修正測試（不動 src），複跑 **34/34 PASS、exit 0**。DOC-A-R1「34/34」對 `b9f6685` 不成立，以本頁為準。Web 匯出／瀏覽器／裝置驗收本機未驗，見 [ENV-CLONE-1](verification/env-setup-clone-2026-10-02.md)。
- **優先：UI7／UI6-R1／FX2／TEXT1 回饋與裝置驗收**。常態材質已實作，先收視覺回饋，再驗高 DPR、實體觸控／GPU、音訊與效能。
- **WEB-RERUN-1（2026-10-02）：CLI 前置完成**。本 clone 重跑 import exit 0、**34/34 Runner PASS exit 0**、presentation parity PASS、Web 匯出 exit 0（首次建 build/web：pck 32.17MB＋wasm 37.68MB）、HTTP 4175 固定 origin 回應 200；UI7 guidance 5 張／FX2 8 張／TEXT1 4 張新 native PNG。真實瀏覽器互動與真機驗收仍待做，見 [驗收紀錄](verification/web-export-rerun-2026-10-02.md)。
- **下一功能候選：M3-B 靈獸或成就**。M5 完整 DoD 仍有遊玩／美術／負載證據缺口，先核對 Roadmap 相依。後續大型任務使用 New Chat。

## 9/29–10/2 開發內容

| 日期 | 交付 | 證據與限制 |
| --- | --- | --- |
| 9/29 | UI-SETTINGS-R1：玩法／設定分開、齒輪入口、BGM 開關與 Web 手勢音訊啟動；境界 BGM 排程與輪迴重置 | living_abode、modal manager、bgm_era_playlist_runner；原創主旋律 A1 草稿仍待人工試聽 |
| 9/30 | M4-A-R1 接線已補；十二時辰／五行天候；M2-D-R1 橫式核心、短橫向縮放、直式旋轉提示 | Session 白名單已有宗門／跨界／BUFF；宗門成功命令有 Session runner；全命令拒絕／冪等／Web 流程未由此推定 |
| 9/30 | M4-B 五級世界地址、九界法則與尺度契約；UI1 原生材質樣板 | m4b_scale_law_runner；尺度資料不代表五級完整世界場景 |
| 10/1 | M5-A 七維法則、心印嚮往、版本化確定性 WorldGenerator／WorldDescriptor 與快照 | m5a_world_gen_runner；三種手工法則可玩驗收、串流與升生成版本保留舊世界的實際流程待補證 |
| 10/1 | M3-B 機緣；M5-B 14 項界域決策、26 種奇遇、地貌互斥與界域加權 | fortune／fortune_ui／m5b runners；逐界完整 UI／美術／人類試玩與長期負載待驗 |
| 10/1 | UI2–UI6 核心材質、世界文字、舊紙邊、引導隱藏、訊息閱讀區與思源黑體 | 各驗收頁保留 native／Runner／匯出；UI1 方向已放行，其餘不合併宣稱全裝置 DONE |
| 10/2 | UI6-R1 黑體 400／600＋粗明體 800；FX2 分境界金環雷電；TEXT1 原生文字試播 | TextServer 字重已驗；演出／試播有 native／CLI／匯出，真實 Web／手機及視覺待驗 |
| 10/2 | UI7 紙色墨字、霧面青玉選中、朱砂突破、墨色功能面板 | [UI7](verification/ui-quiet-materials.md)：34 Runner、21 native PNG、匯出；IAB 1280×720／844×390 滑鼠及 360×640 旋轉提示，DPR 約 1；美術／高 DPR／手機待驗 |
| 10/2 | ENV-TERMINAL 修復；Git 忽略引擎／模板／快取／build，倉庫同步 GitHub | [環境](verification/terminal-initialization-2026-10-02.md)、updata；文件複核未重做 ACL 修復；後續已依使用者要求進入文件 commit／push 流程 |

日期依開發交接；10/2 的 53b864f 集中提交多日內容，不能用提交日期代替每項開發日期。

## 精簡任務板

| 任務 | 狀態與證據邊界 | 入口 |
| --- | --- | --- |
| M0-A | 桌面部分已驗；指定實體手機手勢／效能待補 | [驗收](verification/m0-a.md) |
| M0-B/C | DONE；來源 fixture、Amount/RNG 支援契約 | [M0-B](verification/m0-b.md)、[M0-C](verification/m0-c.md) |
| M1-A/B | DONE；核心、時間、修行／壽元與正流程 | [正流程](verification/core-positive-flow.md) |
| M1-C/D/E | CLI 契約通過；IndexedDB、quota、多分頁、跨程序與真實舊檔 corpus 待補 | [保存](verification/m1-c.md)、[離線](verification/m1-d.md)、[相容](legacy-compatibility.md) |
| M2-A/B/C | 首升境／演出／九界鉤子已交付；新玩家試玩依原 DoD | [M2-A](verification/m2-a.md)、[M2-B](verification/m2-b.md)、[M2-C](verification/m2-c.md) |
| M2-D／R1 | 9/28 桌面指定範圍放行；橫式實作有回歸及 UI7 桌面 Web 補證，實機／效能待補 | [M2-D](verification/m2-d.md)、[規格](07-responsive-ui-web-spec.md)、[UI7](verification/ui-quiet-materials.md) |
| M2-D-R2/R3 | IN_PROGRESS；背景／島面構圖已實作，指定視覺放行待補 | [構圖](verification/m2d-background-framing.md) |
| M2-D-A1 | IN_PROGRESS；第二稿與五版草稿待試聽；已接 BGM 不等於此作曲任務完成 | [第二稿](audio/dao2-main-theme-v2.md) |
| REF-A／UI-ICON-R1 | 已交付；保留 9/28 原測試範圍及後續日期 | [重構](verification/ref-a.md)、[圖示](verification/ui-icons.md) |
| UI1–UI7／UI6-R1 | IN_PROGRESS；多輪材質與字型已實作，UI1 方向放行；最新視覺／裝置驗收未全齊 | [核心](verification/ui-core-materials.md)、[紙底](verification/ui-paper-hud.md)、[字型](verification/ui-source-han-sans.md)、[UI7](verification/ui-quiet-materials.md) |
| UI3／UI5 | IN_PROGRESS；世界題字、引導與訊息有測試／native／匯出 | [世界文字](verification/ui-world-typography.md)、[引導](verification/ui-guidance-messages.md) |
| FX2／TEXT1 | IN_PROGRESS；雷電與文字樣板已交付，視覺／Web／實機待驗 | [升境](verification/island-breakthrough.md)、[文字](verification/ui-text-transition.md) |
| M3-A | 輪迴／天賦／雙軌門檻／壽盡橫幅與演出已交付 | [驗收](verification/m3-a.md) |
| M3-B | 丹藥／BUFF／宗門／天時／機緣已交付；靈獸、成就等未交付 | [矩陣](verification/m3-b.md) |
| M4-A／R1 | 領域／面板／保存與白名單已接線；R1 全命令／Web 完整驗收需補證 | [M4-A](verification/m4-a.md)、[複核](verification/doc-a-r1.md) |
| M4-B | 規則／資料／地址契約已交付；多尺度完整場景不由數值測試推定 | [九界規格](11-nine-realms-law-and-world-generation-spec.md) |
| M5-A／M5-B | 核心／資料已交付；整體 IN_PROGRESS，完整 Roadmap DoD 未全部補證 | [九界規格](11-nine-realms-law-and-world-generation-spec.md)、[複核](verification/doc-a-r1.md) |

## 必須保留的限制

- 正式界域切換仍以人界／靈界為主；九界法則、生成描述與決策資料不代表九界完整遊玩解鎖。
- 觸控、GPU、FPS／p95、冷啟動與長期記憶體未因 CLI 通過而完成；UI7 另記既有九界卡片裁切。
- Font RID／CanvasItem／ObjectDB 退出診斷及負面資料預期錯誤仍存在，不能稱日誌零錯誤。
- ensure_* 呈現初始化、彈窗堆疊與根場景演出鎖定依實際程式理解。
- 玩家保存與 fixture／預覽 origin 分離；本輪未改規則、資產、存檔或既有 HTTP 日誌。

## 歷史與按需閱讀

- [DOC-A-R1 前完整記錄](archive/development-status-2026-10-02-before-doc-a-r1.md)：保留原文與日期。
- [M0–M2 歷史](archive/development-status-m0-m2.md)、[M3–M4 歷史](archive/development-status-m3-m4.md)。
- [呈現索引](abode-presentation-map.md)、[AI 交接](ai-handoff.md)、updata.txt 頂部最新英文 checkpoint。
