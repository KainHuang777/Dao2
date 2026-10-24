2026-10-24 **SKS-P2 逐項設計交付完成；方案K待核定，實作TODO／整體IN_PROGRESS。** Era4–6各4項共12，含元嬰孕育；交付逐ID費用／前置／公式／白名單、技能點容量與等待、縮時回收、保存與12圖題材。無技能可獨立支付；多數單階等待10–27分鐘明列待核定，不改R46舊時間。L1靜態172項通過、1,270份既有來源／資產／測試／Web檔案hash保持；首輪自連結兩失敗及算例修正保留。未改正式遊戲／玩家資料、未生成圖、未跑Runner／Web／匯出／L3、未commit/push。見[方案K](35-sks-p2-design.md)、[驗收](verification/sks-p2-design.md)。本設計階段停止；下一New Chat核定或修訂K後接同一SKS-P2，不開其他P2／P3。下方為日期化歷史。

2026-10-23 **CONTENT-P1-PILL DONE（四圖與丹卡美術已接受；桌面／Web有界）**：使用者明確回覆「美術接受」，接受養木／育草／聚財／納靈四圖與本批丹卡呈現；沿用609專項／102原生、104／104唯一Runner及三橫式Web保存恢復／重載證據。本輪僅更新接受metadata、文件與英文交接，Python稽核另跑；未重跑Godot／Runner／瀏覽器／匯出，未改PNG／規則／玩家進度，未commit/push。見[接受與驗收](verification/content-p1-pills.md)。S／T／P均已收結；下方待接受／待核定文字保留為日期化歷史，本階段停止，下一New Chat由使用者指定大型任務。

2026-10-23 **CONTENT-P1-PILL 實作與桌面交付，IN_PROGRESS（四新圖／丹卡待美術接受）**：使用者核定P，新增養木／育草／聚財／納靈四丹，祖島單資源+100%／300模擬秒；Era2兩／Era3兩、刷新淨延拒絕、999999庫存上限，原八丹順序及加工8配方保持。schema5／pill_version1／rules core-flow-15-content-p1-pills，舊原文備份與只保存重試已接。最終609專項／102原生、104／104唯一Runner分段通過；三桌面橫式Web、40→34折扣、四BUFF並存、拒寫／重試／恢復／重載及淨延7秒已驗。正常候選build/web-content-p1-pills；兩包匯出／壓縮／四BGM交付，14份既有JSON還原，原build/web沿本輪起點hash74aa640f…保持。四張內建ImageGen透明原圖／prompt／hash與審閱見[驗收](verification/content-p1-pills.md)。未改玩家資料，未commit/push；英文交接已更新，本階段停止，下一New Chat先收四圖與丹卡美術回饋。

2026-10-23後續接受：使用者明確回覆「美術接受」，CONTENT-P1-TALENT三圖與天賦卡呈現已接受，本批DONE（桌面／Web有界）。S／T均已收結；下一CONTENT-P1-PILL仍需獨立採用P方案，不由本次美術接受代為核定，本輪沒有開工。見[接受紀錄](verification/content-p1-talents.md)。下方T待接受文字保留為日期化歷史。

2026-10-23後續：使用者指定`CONTENT-P1-TALENT`，依此採T方案實作三項五階輪迴天賦；正式接線與桌面Web交付完成，三張新圖待美術接受，狀態IN_PROGRESS。S已DONE，P仍待核定；下方T待核定文字為本日較早歷史。見[本批驗收](verification/content-p1-talents.md)。

2026-10-23後續接受：使用者明確接受CONTENT-P1-SKILL五圖美術，本批DONE（桌面／Web有界）。下一CONTENT-P1-TALENT先核定T方案，P仍待核定；本輪只收結，沒有開工T／P。見[接受紀錄](verification/content-p1-skills.md)。下方待美術接受文字保留為本日較早歷史。

2026-10-23 CONTENT-P1-SKILL：S方案五技能已加入正式定義，目前一般技能12（Era2九、Era3三）；skill_version3／schema5。規則與桌面驗收已交付，五圖待美術接受；天賦仍3、丹藥仍8，加工配方仍8。見[驗收](verification/content-p1-skills.md)。下方數量為各自日期基線。

2026-10-23 **CONTENT-P1-DESIGN 設計已交付，待核定**：[docs31逐項方案](31-content-p1-design.md)提出5技能／3五階輪迴天賦／4祖島專精丹與收益對照、保存／新通道及三組S／T／P核定表。下文下一任務為歷史；目前先收設計核定，核定S後接CONTENT-P1-SKILL，不自動將候選視為正式內容。schema現況為5，先前schema4文字按日期保留。

# RES1-E-SKILLS-PLAN：技能擴充盤點與分境界可執行清單

2026-10-21 **RES1-D已放行；跨系統數量擴充總表已建立**：[CONTENT-EXP-PLAN](25-system-content-expansion-plan.md)提出P1於Era2–3新增5項一般技能（7→12），後續SKS-P2／P3／P4各新增12項，累計24／36／48；均為數量提案，非正式新增。P2的nascent_soul_incubation含在12項內；高境界候選仍待RES1-E逐段稽核後命名／定值。本檔保留既有技能取得、保存、輪迴與SKS批次契約；新增CONTENT-P1-DESIGN先交5技能／3天賦／4丹藥逐項設計表，核定該部分後才實作。Era1維持0技能，宗門功法獨立計數。

2026-10-18 現況校正：SKS-P1 結丹法及正式修煉時間倍率已由使用者核定並接入，現行 schema4／rules core-flow-12-skills-p1／skill_version 2；58 專項與相關回歸通過。EARLY-V1-C 已補 Web 匯出、字型、壓縮及七項技能可達性／成本／輪迴清除證據；2026-10-20已補金丹題材圖（`accepted`）、三橫式真實瀏覽器研習／拒寫恢復／重載；使用者已核定「結丹法新圖接受」，EARLY-V1-C DONE（桌面／Web有界），見[EARLY-V1-C 報告](verification/early-v1-c.md)與[SKS-P1 驗收](verification/res1-e-skills-p1.md)。下文「未承接／提案／schema3」是 2026-10-17 原盤點歷史，不能作現況。SKS-P2～P4 仍依 RES1-D 與逐段稽核相依，前期版本不以 Era4–12 為放行條件；下一階段見[EARLY-V1](23-early-version-closure-plan.md)。

2026-10-17 規劃交付（使用者指定本批美術改造尾階段；依 [20-feature-interface-art-plan.md](20-feature-interface-art-plan.md) 尾階段 DoD）。**本輪僅規劃與盤點，未新增任何技能；不因規劃成立宣稱技能已擴增或 Era4–12 可玩。** 一般技能契約沿 [ADR-012](decisions/ADR-012-optional-skills-with-islands.md)；宗門功法（R9）與一般技能為不同取得通道，不互相冒稱承接。

## 1. 盤點表（可追溯來源）

### A. 現行一般技能（正式；解鎖＝Era≥2 且藏經閣 `library`≥1，`src/simulation/skill_system.gd:64`）

| ID | 名稱 | 上限 | 每階費（技能點） | 效果（每階） | 狀態／來源 |
| --- | --- | --- | --- | --- | --- |
| `basic_meditation` | 基礎冥想 | 5 | 90 | 靈力產率 ×1.1 | 已承接。B案 [skills-b1](verification/skills-b1.md)；值源自 master ff86f85，[DAO1 稽核](verification/artifacts/res1-d1-source-audit.json)同值 |
| `qi_condensation` | 聚氣術 | 5 | 1800 | 基礎靈力產率 ＋2 | 已承接（master 同ID；DAO1 稽核未列，屬 master 品項） |
| `foundation_building` | 築基功 | 5 | 3600 | 金錢產率 ×1.2 | 已承接，DAO1 稽核同值 |
| `qi_storage_1` | 納靈法 | 1 | 120 | 靈力容量 ＋200 | 已承接（master 品項） |
| `body_strengthening_1` | 強身術 | 1 | 1000 | 金錢容量 ＋2000 | 已承接（master 品項） |
| `building_mastery_1` | 建築精通・初階 | 1 | 200 | 四生產設施上限 ＋10 | 已承接（v2 改動：master 全域動態上限改單階＋10，見 [rule-differences LP-009](rule-differences.md)） |

現行 v2 邊界（2026-10-18 校正）：藏經閣產點（首階金錢500／靈木200／下品靈石50／靈草20、最多3階、成本倍率1.8）；經書殿擴容量6000；技能點基礎容量200；不可手動採集；正式保存為 schema4、skill_version=2、rules_version=core-flow-12-skills-p1。輪迴清除技能、技能點、研習建築；技能點不適用資源繼承天賦。

### B. 宗門功法（正式；R9 通道，貢獻＋資源研習，`src/simulation/sect_system.gd:92`，Max 10）

| ID | 名稱 | 效果（每級） | 狀態 |
| --- | --- | --- | --- |
| `divine_farm` | 神農靈訣 | 靈草／靈木產能 +10% | 已實作（R9）；功能與效果驗收公開 [uix-r9](verification/uix-r9.md) 已交付 |
| `breathing_method` | 周天吐納法 | 全洞府修煉速度 +2% | 已實作 |
| `storage_talisman` | 乾坤納戒 | 全基礎資源容量 +10% | 已實作 |
| `essence_array` | 引靈大陣 | 靈氣儲存上限 +20% | 已實作 |

功法不使用技能點、不併入技能頁六格；後續擴充若新增功法，走 R9 宗門批次，不在本清單內實作。

### C. 舊版（DAO1／master ff86f85）未承接對照

| 舊 ID | 舊效果（DAO1 稽核） | 舊前置／成本 | 裁定 | 原因 |
| --- | --- | --- | --- | --- |
| `golden_core_formation` | 修煉時間倍率 ×0.9／階（正式時間通道） | Era3、前置`foundation_building:1`、7650點／級 | **SKS-P1 規則已承接**；金丹題材圖已接受，Web已驗 | 使用者核定 P3-1，max5，訓練時間按 pow(0.9,N)；突破門檻未借用技能。見[驗收](verification/res1-e-skills-p1.md) |
| `nascent_soul_incubation` | 全資源容量 ×1.15（all_max_multiplier） | Era4、前置`golden_core_formation:5`、21250點 | **待承接（Era4–6 批次主候選，值→提案）** | SKS-P1 已承接前置技能，但 Era4 內容／資源尚未可達；仍須核定前置階數及容量倍率提案值 |
| 修煉時間技能倍率通道（舊 SimulationRunner.ts `skillTimeMult`） | 訓練時間加成 | — | **已承接（SKS-P1）** | 正式 next-level 時間與服丹上限共用 skill_time_mult；線上／離線一致，見[驗收](verification/res1-e-skills-p1.md) |
| 舊 building mastery 技能 | 建築等級上限動態提升 | — | 已部分承接 | 以 `building_mastery_1` 單階＋10 等效（legacy_parity 差異已記錄） |
| 舊藏經閣／經書殿 | 技能點產出／容量 | — | 已承接（v2 成本） | ADR-012 採用值 |

## 2. 分境界缺口與規劃表

| 境界段 | 現況 | 缺口／裁定 |
| --- | --- | --- |
| Era1 | 0 項（設計如此：技能 Era≥2 解鎖） | **無缺口，不新增**。保持首段教學單純（[17 前期流程](17-early-progression-and-onboarding-plan.md)） |
| Era2 | 六項全 | 無缺口。值隨 RES1-C3（2026-10-17 玩家核定首批美術／節奏）維持工作值；新增批次數值另各自驗收 |
| Era3 | 1 項一般技能：`golden_core_formation` | SKS-P1 純縮時加成已交付；金丹題材圖已接受，桌面Web已驗。Era3 突破門檻仍由 Era＋設施／容量決定 |
| Era4–6 | 0 項；RES1-E Era4–6 資源尚未稽核 | 候選：`P4-1 nascent_soul_incubation`（承接舊ID，重新定前置與提案值）；其餘資源產率型技能在 RES1-E 該段稽核後命名，**禁止提前憑空設計** |
| Era7–9 | 0 項 | TODO：先做該段 RES1-E 資源／建築稽核，再列候選；目前無來源可追溯候選 |
| Era10–12 | 0 項 | 同上；另註 `era_id` 與九界 `realm_id` 為不同概念，技能不得跨綁九界章位（AGENTS 約束） |

輪迴行為一律沿 ADR-012：任何新技能、新技能點與新研習建築在輪迴清除，不參與資源繼承天賦。

## 3. 分批可執行清單

共通約束（適用每一批）：數值出現「Δ 提案」標記者，皆需使用者核定後才進入該批實作；實作前修改 `rules_version` 主內容掛段並按 [ADR-012 §保存](decisions/ADR-012-optional-skills-with-islands.md) 的 skill_version 遷移程序（缺欄補零＋原JSON雜湊備份＋讀回比對＋拒寫重試）；每批交付含專項 runner、相關回歸、字型子集check、兩版Web匯出壓縮與桌面三橫式驗收；圖像走 ImageGen 題材透明PNG＋提示詞／manifest 紀錄（docs/08／19 規範）。

| 批次／任務ID | 範圍 | 相依 | 修改模組（預估） | 圖像 | 保存 | 驗收 | RES1-E 相交 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1／`SKS-P1`（Era3 可選補承接）— **已交付 2026-10-18**：`time_multiplier` 0.9 凍結、era/requires 欄位與 v1→v2 遷移落實，runner 58 checks＋回歸 exit0；金丹題材圖已於2026-10-20接受，[驗收](verification/res1-e-skills-p1.md) | `golden_core_formation` 純加成（時間−10%為 Δ提案） | **使用者核定 P3-1；否則本批取消** | `content/skills/era3.json`（新檔）＋manifest 附掛；`skill_system.gd` 解鎖表／時間通道;正式時間加成介面（training time） | 1 張金丹題材圖（**2026-10-20已接受**） | `skill_version=2`；rules `core-flow-12-skills-p1` | 新 runner：扣費／前置／防重扣／時間結果對照；技能頁R8既有View渲染 | 與 Era3 突破契約**互不借用**：技能不解鎖金丹門檻 |
| B2／`SKS-P2`（Era4–6） | `nascent_soul_incubation`（前置重定 Δ提案）＋該段稽核後命名候選 | RES1-E Era4–6 資源／建築稽核交付；RES1-D 收結；Era4 多島內容可達 | `content/skills/era4[5,6].json`；all_max_multiplier 效果通道（Production／容量計算新增） | 每技能 1 張題材圖 | `skill_version` 沿 B1 規則；舊檔補零遷移保留 | runner＋桌面Web（技能點真實取得路徑不可省）；輪迴清除驗證 | 技能效果僅引用已實作資源ID；違者改批 |
| B3／`SKS-P3`（Era7–9） | 該段稽核後填列 | B2；RES1-E Era7–9 稽核 | 同 B2 模式 | 同上 | 同上 | 同上 | 同上 |
| B4／`SKS-P4`（Era10–12） | 該段稽核後填列 | B3；RES1-E Era10–12 稽核；九界 realm 接線不影響技能 | 同上 | 同上 | 同上 | 同上 | 同上 |
| 文件同步 | 每批完成更新 status／handoff／updata 本欄 | — | 文件 | — | — | traceability：本清單＋批次驗收連結 | — |

## 4. DoD 核對（本檔）

- [x] 盤點表三群組（現行一般技能／宗門功法／舊版未承接）含來源與裁定。
- [x] 分境界表：Era1–3 已核對；Era4–12 列批次與阻擋條件，未承諾未實作境界可玩。
- [x] 分批清單：任務ID、相依、模組、圖像、保存遷移／重試、規則／UI／桌面Web驗收、RES1-E 相交依賴。
- [x] 提案與已核定狀態分流（Δ 提案標記；無核定數值承諾）。
- [ ] 各批次實作（另按本清單逐批交付，不併入 R9–R11）。
- [x] 同步 Roadmap／status／handoff／updata（本輪完成）。
