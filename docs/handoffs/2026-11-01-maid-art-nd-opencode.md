# MAID-ART-ND → OpenCode

> 最新：使用者要求糯美子約20歲圓頰、丹霞成熟御姐及完整劍結構，R1造型已由 [R2交接](2026-11-01-maid-art-nd-r2-opencode.md) 取代，請勿照下方舊檔名接回R1。R2已於2026-11-01獲使用者美術接受。

本次使用者指定 Codex 提供糯美子／丹霞美術，其餘工作由 OpenCode 接續，並明確不要求本輪測試。

素材入口為 `docs/maid-art/nuomeizi/README.md`、`docs/maid-art/danxia/README.md`。接入副本預備於 `assets/characters/{nuomeizi,danxia}/portrait.png` 與 `first-meeting.png`；各目錄的 manifest 保存完整來源紀錄。稿件已提供不等同使用者已接受；本次未接入 Godot，未執行 runner、引擎 import、Web 匯出或瀏覽器驗收。

接續時先核對使用者對本輪美術的回饋，再在現有介面完成：

1. `src/presentation/maid_character_panel.gd` 的 `PORTRAIT`／`MEETING` 目前只指向青蘅；按角色 ID 對應素材，沿既有完整 contain 看圖，撤換兩位的待提供占位。
2. 初遇與人物小傳目前有青蘅專用文字；替兩位提供各自的簡介／初遇文案，勿讓她們沿用青蘅護書避雨台詞。雲海試劍與丹房夜話僅為敘事展示，不新增獎勵或狀態。
3. `src/simulation/maid_system.gd` 的 `art_ready` 目前只對青蘅為 true；按專案呈現契約調整，不把美術可用當成招募／羈絆通過，不將 Texture 或 Node 引入規則。
4. 共用分頁、書籤、題字、CloseSeal、字型與縮窄容器遵守 docs/07、docs/19；本輪無新 UI 通則，無須重做青蘅布局。

不要重做已完成的 MAID-CORE-1／2、MAID-UI-1／2。後續驗收依使用者當次指示及 AGENTS 分級辦理；本次無 L1／L2／L3 或全量回歸聲稱。表情差分、終章 CG、設定三視圖及世界小像不在本次四張素材範圍。不要因四張圖已提供而標整體 MAID-CLOSE 完成。

所有既有 dirty 成果保留；代理未 commit／push。可手動 commit：本次為美術提供階段結束，完整仙侍大型任務仍未結束。
