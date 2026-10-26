# CONTENT-P2-PILL / PILL-1 核心與保存驗收

2026-10-25。**PILL-1 DONE（L1＋有界 L2，單尺寸）；CONTENT-P2-PILL IN_PROGRESS。** 使用者指定「接續 PILL-1」，沿[已核定方案 V](../37-content-p2-pill-design.md)，不重問數值。Godot 本機版本 `4.7.2.stable.official.ed1daf0bf`。沒有美術／UI／Web／自然長流程交付，也沒有 L3、commit 或 push。

## 交付

- `AlchemySystem.VERSION=2`，正式定義12→20；八丹只走既有 `refine_pill`／`consume_pill`，付款共用 Amount 成本；新丹不進既有折扣白名單，每項原料以 Amount 差值符號拒絕可表示不足。庫存與數量／當世前置／壽盡拒絕保持原子性；既有十二丹順序保留。
- 凝嬰900／虛明1800秒、共享0.85衰減／99顆，當級有效缺口封頂，核心 preview／receipt 提供實得與捨棄；不增加年歲或自動升級。兩指定島600秒×1.5、批1–6替換刷新與淨延，地方生產捕捉倒數前倍率，最後一秒仍有效；不改加工／船速。
- 靈力+10000／中石+1000，各當世5顆。`Production.add_pill_capacity` 在既有乘區及取整後加固定量；祖島 View／生產快取與未快取路徑／升境檢查／加工航運 `home_cap`／離線及歷世／機緣容量讀取已接。無新丹計數時沿既有結果；不贈現貨。已付加工預留與完工不丟失。
- 定心+3點、銀罡+5點與95%上限，`TribulationRules.state_probability` 供 preview、正式擲骰及回執共用；命令拒絕不清旗標／不前移 RNG，實際成功或失敗均清共享修行／準備旗標，擴容保留，輪迴清本世丹藥效果。
- schema5／economy `res1-e-46-1` 保持，rules 身份 `core-flow-21-content-p2-pills` 優先於 talent／skill；ContentLoader 原有 hash 來源包含丹藥及 BUFF 定義，隨新定義更新。Codec 驗證新庫存／共享計數／容量計數／旗標／效果與固定 BUFF 身份、有限時間；舊0／1不能攜新ID或新效果，未知新版本拒讀。
- load／share import 的原文 SHA256 歸檔、讀回與 pill 候選已納入 migration_pending。候選成功前 Session 命令、時間及 OfflineCoordinator 入口拒絕，錯候選也拒存。原文歸檔讀回損壞先另存 damaged 原文並讀回，再重存同一原始文字；所有失敗保留候選。雙槽皆壞不覆寫；重送 command_id／保存拒寫後重試／重載不二次扣付或服用。一般 Web 命令拒寫後暫停與重試沿用 living_abode 既有路徑，本輪沒有新增其瀏覽器證據。

## 修改檔案

`src/simulation/alchemy_system.gd`、`buff_system.gd`、`tribulation_rules.gd`、`production.gd`、`island_economy.gd`、`time_advancer.gd`、`offline_closed_form.gd`、`command_processor.gd`、`story_progress.gd`；`src/application/game_session.gd`；`src/domain/life_history.gd`；`src/persistence/save_codec.gd`、`save_manager.gd`；新增 `tests/content_p2_pills_runner.gd`、`content_p2_pills_save_runner.gd`；更新 `tests/content_p1_pills_runner.gd`、`content_p2_supply_economy_runner.gd` 舊常數斷言及 `tools/run_all_runners.ps1` 註冊。既有工作區其他未提交變更保留。新增靜態稽核工具 `tools/content_p2_pills_audit.py`；狀態、設計metadata與英文交接同步。

## 命令及結果

每組先執行同 selector 的 `-List`，預設 `matrix=single`（1280×720），未執行 Full。原生工具因沙箱阻擋 Godot 測試 user:// 寫入而以已授權權限執行。

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --version
.\tools\run_all_runners.ps1 -Only 'content_p2_pills_runner.gd,content_p2_pills_save_runner.gd,content_p1_pills_runner.gd,trib0_outcome_runner.gd' -List
.\tools\run_all_runners.ps1 -Only 'content_p2_pills_runner.gd,content_p2_pills_save_runner.gd,content_p1_pills_runner.gd,trib0_outcome_runner.gd'
.\tools\run_all_runners.ps1 -Only 'content_p2_talents_runner.gd,content_p2_supply_economy_runner.gd,offline_closed_form_parity_runner.gd,m1c_persistence_runner.gd,m1d_offline_runner.gd,m1e_import_runner.gd,buff_system_runner.gd,m3b_alchemy_runner.gd,life_history_runner.gd' -List
.\tools\run_all_runners.ps1 -Only 'content_p2_talents_runner.gd,content_p2_supply_economy_runner.gd,offline_closed_form_parity_runner.gd,m1c_persistence_runner.gd,m1d_offline_runner.gd,m1e_import_runner.gd,buff_system_runner.gd,m3b_alchemy_runner.gd,life_history_runner.gd'
.\tools\run_all_runners.ps1 -Only 'offline_closed_form_parity_runner.gd' -TimeoutSeconds 240
```

**13支唯一 runner 最終分段通過，非單一全綠命令或全量回歸。** 最後小修僅補受影響 selector（見原始日誌索引），沒有重跑全部九支。L2超過5支的理由：共同修改丹藥保存驗證／遷移閘、容量、BUFF到期及離線通道，需覆蓋保存三支、BUFF／舊丹、供給、天賦、歷世及離線等價依賴。

| 範圍 | 最終結果／日誌組 |
| --- | --- |
| 新丹核心 | 560 checks，0 failures；`25d7dc0ea94546818aa7d02244173b17` |
| 新保存／逐ID重送與重載 | 484 checks，0 failures；`12876a86dfa9465496660749aebd197b`（亦有單跑通過） |
| 舊P1丹與渡劫 | P1 609 checks，渡劫 runner 通過；初次全四支通過 `46592f11015a494aa28734029dfbd1d9`，P1最終補驗 `40678803c33a4b8fa07b685daf114a27` |
| L2其餘七支 | `17ebfb5974ff418a9ec5d5618b24a833` 通過七支；歷世最終另補 `40678803c33a4b8fa07b685daf114a27` |
| 供給 | 修正 rules 身份斷言後283 checks通過，`e47e9976a2bd4a82ac0dda2bf7f35039` |
| 48小時離線對照 | 原45秒逾時保留；獨立240秒上限重跑92.3秒完成，`d64b8fdf2e9a4339aeb16fb52cedb528`。含逐秒參考路徑，不是Web恢復性能數據 |

測試涵蓋逐ID煉1／99、非法數量與滿庫、每項原料的最接近可表示不足、折扣不外溢、當級／99共享上限、593→600淨延7、600秒到期前後、分段與closed-form一致、地方滿倉、調度／技能／拓脈相乘、擴容第5／6顆與獸魂／技能乘區、已付預留、正式成功／失敗擲骰、拒絕不擲骰、95%無效、輪迴清除、舊0／1 load及import與多處拒寫／讀回故障、兩種子版本同時遷移、未知版本／雙壞槽保護、八ID正式命令重送及保存重載。

## 保留失敗與證據限制

1. 初次一次直接相關天賦 runner 通過1126 checks，但先於 `-List` 及批量備份執行；這是操作順序疏漏，不用作本輪新核心唯一證據。後來已循固定入口重驗；該次報告以可信歷史hash備份逐字復原，見 restoration 記錄。
2. 初次沙箱 user:// 日誌寫入失敗，渡劫 scene 初始化 SAVE_FAILED／nil.hide 並逾時；改為原生授權工具後通過。兩個沙箱暫存日誌目錄已不可讀回，本頁保留從工具輸出記錄的失敗摘要，不宣稱已封存這兩輪完整raw。
3. 新核心最初兩個測試推導型別未宣告；保存驗證器異型別 `!=` 曾觸發 SCRIPT ERROR，已改為先驗 typeof。舊P1的12丹／version1／future2及供給舊rules斷言修正；原失敗保留於工具紀錄及可取得日誌。
4. 新測試fixture曾缺99顆批服庫存、築基丹鏡像、library欄位／skill解鎖、護劫服用Era及工坊前置，逐項修正。重載對比按JSON數字表達比對，不把合法 int／float 容器正規化當收益差異；原差異診斷日誌保留。
5. 48h離線參考超過45秒，僅此支放寬至240秒；原逾時不改寫成功。預期壞JSON與既有退出診斷保留，不稱日誌零錯誤。
6. 以上為合成隔離規則／保存fixture及既有領域測試，不是自然採料、當次Web滑鼠、實際IndexedDB或美術接受。未匯出Web包／未L3／未改玩家進度／未commit或push。

最終 `python tools/content_p2_pills_audit.py`：90項靜態檢查通過；13支最新runner證據、嚴格UTF-8、報告連結、核定費用／Era及保存身份一致。相關來源 `git diff --check` exit0。10045份JSON基準核對，1份變動先封存後復原；另將首支直接天賦測試輸出依先前已驗hash備份復原至826項原報告，不將重建文字冒充備份。

原始日誌與摘要見[日誌索引](artifacts/content-p2-pills/logs-index.json)、[核心](artifacts/content-p2-pills/core.json)、[保存](artifacts/content-p2-pills/save.json)、[產物復原](artifacts/content-p2-pills/restoration.json)、[最終靜態稽核](artifacts/content-p2-pills/delivery-audit.json)。

## 下一步與停止點

依 Context Guard 在 PILL-1 停止，下一 New Chat 接 **PILL-2**：八卡／八圖、已賺得Era4起點到Era6代表合法流程，至少一丹自然採料→加工／回運→煉製→有效服用，其餘逐ID隔離證據分列；同功能完成一次當次包1280×720桌面真滑鼠抽驗。八圖仍未生成／未美術接受，整批保持IN_PROGRESS。人工接受八圖／卡片與節奏後才執行一次整批L3。保留R46時間、不開Era7或其他P2／P3。
