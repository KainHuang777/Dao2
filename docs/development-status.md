# 開發狀態與交接紀錄

2026-09-27 M3-A 輪迴門檻對齊舊版與 HUD 壽盡直達橫幅交付：嚴格修正 `src/simulation/reincarnation_rules.gd` 輪迴資格門檻，徹底移除過渡性的「築基期（era_id >= 2）直接放行」設定，完全回歸 Dao1 經典雙軌門檻：（1）被動壽元已盡（含天賦、丹藥與 BUFF 累加壽元）；（2）主動提前輪迴需修築特定輪迴建築【往生蓮臺】（`rebirth_lotus`）或【太虛輪迴境】（`void_mirror`）。於主場景 `src/abode/living_abode.gd` 的 `header_box` 實作頂層高醒目度的仙俠風懸浮警示卡 `LifespanBanner`（亮橘暖金發光邊框），於壽元已盡時立即彈出「⏳【壽元已盡 · 天命難違】」，並配備「🪷 輪迴證道」專用按鈕直達轉世面板；壽元未盡時自動隱藏零佔位。同步更新 `reincarnation_panel.gd` 資格提示文字。更新 `tests/m3a_reincarnation_runner.gd`、`tests/m3a_reincarnation_ui_runner.gd`、`tests/core_positive_flow_runner.gd`、`tests/m2c_nine_realms_runner.gd`、`tests/m2d_slice_release_runner.gd`、`tests/m3b_alchemy_runner.gd` 與 `tests/buff_system_runner.gd`。全量 23 項 Runner 與 Web Release 匯出均 exit 0。

2026-09-27 M4-A 手工第二界（靈界 · 天靈洞天）與雙界法則系統全閉環交付：完成靈界體系規則模組 `src/simulation/realm_system.gd`。定義三大活躍據點（天樞陣眼 `celestial_hub`、化靈仙池 `pure_pool`、虛空引靈台 `void_beacon`），支援至 10 級擴建。實作跨界法則與機會成本供給取捨：天樞陣眼每級每秒消耗人界靈石轉化極品靈晶；化靈仙池每級每秒消耗極品靈晶凝練天青靈液；化靈仙池提供全洞府修煉速度 +15%/級跨界反哺加成；虛空引靈台擴充靈界專屬資源容量上限。`TimeAdvancer` 接入雙界並行模擬（不論玩家當前身處人界或靈界，兩界產能與消耗持續運轉）。`GameState` 與 `SaveCodec` 擴充 `current_realm` 與 `realms_data`，具備向後相容解碼。`CommandProcessor` 接入 `switch_realm` 與 `upgrade_realm_outpost` 指令。`living_abode.gd` 接入金色高亮遠景「靈界方向 · 【跨界神遊】」天標、自適應跨界神遊面板 `RealmTeleportModal`、次級選單入口「靈界洞天」與切景天幕色調調諧。新增 `tests/m4a_realm_runner.gd`（exit 0，解鎖條件、切界返家、據點升級、並行模擬與機會成本、修煉反哺、存檔往返、UI 面板全通）。全量 23 項 Runner 與 Web Release 匯出均 exit 0。

2026-09-27 M3-B 第二彈：BUFF 與狀態時效增益系統全閉環交付：完成 BUFF 系統規則模組 `src/simulation/buff_system.gd`，支援時效衰減、同類刷新、永久特質（長生龜息）及跨世道痕（transmigratable）繼承規則。首發預置「天靈氣湧」、「頓悟靈光」、「破境餘韻」與「長生龜息」四種經典修仙增益。`GameState` 與 `SaveCodec` 擴充 `buffs` 持久化欄位並保持向後相容。`TimeAdvancer` 接入每秒 tick 衰減、動態產率、專屬資源加成、修煉速度倍率與壽元上限。`CommandProcessor` 接入 `apply_buff` 與 `remove_buff`，並在大境界突破（`breakthrough_era`）成功時自動為玩家施加 120 秒「破境餘韻」。`living_abode.gd` 與 `src/presentation/buff_hud_bar.gd` 接入自適應微徽章狀態列，無 BUFF 時自動隱藏零佔位；`debug_panel.gd` 擴充一鍵施加測試 BUFF。新增 `tests/buff_system_runner.gd`（exit 0，生命週期、衰減、倍率、大境突破連動、存檔往返、輪迴保留/清空及 HUD UI 全通）。全量 22 項 Runner 與 Web Release 匯出均 exit 0。

2026-09-27 M2-D 淚瀑遠景 v5（待 AGY 視覺驗收）：依使用者新提供的 GPT 修正近景參考，將眼下水路加厚為瀑簾，落至苔蘚平台後接成島緣與下方多級寬瀑；維持風化塊石、殘缺古貌與獨立遠方空島。新增 `assets/abode/sky_tearfall_island_v5.png`，`living_abode.gd` 預載 v5；`tearfall_sky.gdshader` 加寬眼下水流遮罩並延長至承水平台；`export_presets.cfg` 排除保留作歷史的 v1／v3／v4。來源、使用者參考副本、提示詞、授權與切層見 `docs/abode-art/sky-tearfall-island-v5.md`。Godot 4.7.2 import exit 0；`island_breakthrough_runner.gd` exit 0／PASS；Web Release export exit 0。生成圖已目視核對，真實 Web 動態與窄螢幕觀感仍待 AGY。下一步固定本機 origin Ctrl+F5 檢查眼下瀑簾與多級水路，再重播突破確認整體搭配。

2026-09-27 M2-D 淚瀑遠景 v4 修正（待 AGY 視覺驗收）：使用者指出 v3 的島緣瀑布失去石佛流淚設定，改以 `assets/abode/sky_tearfall_island_v4.png` 恢復雙眼角→風化臉頰水路→殘破平台→較寬瀑簾的視覺連結；保留古老殘破石面塔、独立懸空島身、寬瀑與雲霧。`living_abode.gd` 預載 v4；`tearfall_sky.gdshader` 增低幅臉頰水流遮罩，眼睛保持静止；`export_presets.cfg` 排除已停用 v1／v3 遠景，原始資產保留。資產來源／授權／切層／提示詞見 `docs/abode-art/sky-tearfall-island-v4.md`。Godot 4.7.2 import exit 0；`island_breakthrough_runner.gd` exit 0／PASS；Web Release export exit 0。生成圖已目視確認淚水與瀑簾連結，實際瀑布動態、窄螢幕與 GPU 觀感仍待 AGY；下一步固定本機 origin Ctrl+F5 驗收新版遠景與突破重播。

2026-09-27 M2-D 遠景美術 v3 修訂（待 AGY 視覺驗收）：依使用者兩輪修訂，改用具吳哥古蹟塊石／殘破質感的獨立佛首空島，露出懸空島底、碎塊及周邊雲海間隙；水流改為三處加寬的島緣瀑簾，取消成對眼部水柱。新增 `assets/abode/sky_ruin_island_v3.png`，`living_abode.gd` 接入新圖，`tearfall_sky.gdshader` 對齊寬瀑遮罩並收斂增亮；突破文字不直接稱作淚瀑。`export_presets.cfg` 排除保留作歷史的 v1 圖，避免重複打包。來源、授權、切層和兩版提示詞見 `docs/abode-art/sky-ruin-island-v3.md`。Godot 4.7.2 import exit 0；`island_breakthrough_runner.gd` exit 0／PASS；Web Release export exit 0；本輪相關已追蹤檔案 diff-check exit 0。生成圖已目視核對，真實 Web 動態、窄螢幕觀感及觸控仍待 AGY；下一步使用固定本機 origin 強制更新新版 build 進行驗收。

2026-09-27 M2-B 演出擴充／M2-D 美術接入（待 AGY 本輪視覺驗收）：接入常駐流淚石佛／懸山遠景與局部瀑布 Shader、独立空島法陣／靈光／弧光／碎岩／光點／雲海波環；正式練氣→築基命令先提交與保存，演出 5.6 秒可跳過／重播，低特效 1 秒，重播不改快照；關閉／失去前景焦點恢復原鏡頭與 HUD，保存失敗有重試且不再次升境。修改檔案與 AGY 操作單見 `docs/verification/island-breakthrough.md`；資產、切層與提示詞見 `docs/abode-art/sky-tearfall-v1.md`。固定 Godot 4.7.2，相關六個 runner（M2-B、新 island-breakthrough、M2-D responsive／slice、M2-A、M2-C）均 exit 0／PASS，Web Release 匯出 exit 0。初次新增腳本的語法／型別錯誤已修正；headless 結束仍有資源未釋放訊息，整工作樹 diff-check 另有既有 AGY `game_state.gd` EOF 空白行。未通過項：本轮真實 Web Shader／畫質、滑鼠／觸控、實機效能與 IndexedDB；本次擴充驗收仍 IN_PROGRESS，不覆蓋原 M2-D 歷史放行。下一步：使用最新 `build/web` 在 AGY 依操作單驗收。保留 AGY 既有煉丹／DEBUG 與其他核心修改。

2026-09-26 M3-B 第一彈：丹藥與煉丹房系統全閉環交付：完成丹藥系統規則模組 `src/simulation/alchemy_system.gd`、`GameState` 與 `SaveCodec` 持久化欄位（`pills`、`pill_effects` 向後相容）、`TimeAdvancer` 丹藥加壽與產率倍率接入、`ReincarnationRules` 轉世清空肉身丹藥重置、`CommandProcessor` 接入 `refine_pill` 與 `consume_pill`。主場景 `src/abode/living_abode.gd` 與 `src/presentation/alchemy_panel.gd` 接入自適應煉丹房面板、次級選單入口「洞府煉丹」與 HUD 即時同步。新增 `tests/m3b_alchemy_runner.gd` 與 `tests/m3b_alchemy_ui_runner.gd`（exit 0）。全量 19 項 Runner 與 Web Release export 均 exit 0。

2026-09-26 M2-D 視覺、裝置與首切片放行完成：使用者於真實瀏覽器環境進行完整操作與視覺驗收，確認緊湊營造清單、內嵌採集、直式/橫式自適應排版、空島地標點擊與流暢度通過。M2-D 正式標記為 DONE。

2026-09-25 M2-D 資源列內嵌直覺採集與 Era 2 規則確認：依使用者建議，將左下角獨立採集動作槽與下拉選單廢止，改在左側已解鎖基礎資源卡（靈氣、金錢、靈木）後方直接內嵌「採集」按鈕；滿倉時按鈕自動 disabled。確認核心規則：手動採集（Gather）嚴格限定於 Era 1（練氣期），突破至 Era 2（築基期）後自動隱藏所有採集按鈕，完全轉由洞府設施自動產出（對齊核心 `MANUAL_GATHER_ERA` 約束）。修改 `src/presentation/building_catalog.gd`、`src/abode/living_abode.gd`、`tests/m2d_responsive_ui_runner.gd`、`tests/core_positive_flow_runner.gd`。全量 17 項 Runner 與 Web Release export 均 exit 0。

2026-09-25 新手體驗節奏優化與九界轉生時機調整：依使用者反饋，移除首次採集靈氣時打斷操作的九界宇宙鏡頭切換（`seen_nine_realms_hook`），將新手期注意力集中於快速理解學習核心玩法；九界鉤子切換時機移至「首次轉生（Reincarnation）」完成時觸發，呼應天地玄黃再塑仙身之世界觀。同步記錄待辦設計：未來於 M3/M4 擴充九界與轉生關聯時，將「標記為嚮往」賦予實質增益或轉生專屬法則效果（目前保持零副作用基礎標記）。更新 `src/abode/living_abode.gd`、`tests/m2c_nine_realms_runner.gd`、`tests/m2d_slice_release_runner.gd`。全量 17 項 Runner 與 Web Release export 均 exit 0。

2026-09-25 M2-D 資源面板裁切與境界按鈕重疊修復：修復修煉進階按鈕出現時基本資訊框向下撐開卻未同步下推縱向資源面板（`resource_ribbon`）導致重疊遮擋的問題；提取 `_reflow_resource_ribbon()` 並在 `_reflow_header()` 觸發時動態下移資源面板保持 8px 間距。修復資源清單因 `resource_grid` 缺乏 `size_flags_horizontal = SIZE_EXPAND_FILL` 及 Label `clip_text = true` 導致卡片水平塌陷為 24px 空框（文字裁切消失）的 Bug，為 `resource_grid` 與 `value_label` 補齊 `SIZE_EXPAND_FILL`，完整恢復資源名稱、讀數與產率顯示。`tests/m2d_responsive_ui_runner.gd` 增補卡片寬度 (>100px) 與境界按鈕動態展開不重疊斷言。全量 17 Runner 與 Web Release export 均 exit 0。

2026-09-25 M2-D 介面擴充性修正：依使用者 1920×902 截圖，移除頂部橫向資源帶排版，改為左側「關閉／數量／完整」三態縱向清單（預設數量、滿倉變色、完整容量／產率、內部捲動、納入後續 Era 資源）；底部新增明確「空島／營造」雙分頁；右側建築列固定 48 高，成本只在展開後顯示，保留需求進度條，取消標準密度。短直式建築詳情使用聚焦版型，避免內容被擠出。修改 `src/abode/living_abode.gd`、`src/presentation/building_catalog.gd`、`tests/m2d_responsive_ui_runner.gd`、docs/07/09/10、docs/verification/m2-d.md 與本狀態檔。Godot 4.7.2 import、全量 17 Runner、Web Release export exit 0；實際瀏覽器與手機觸控待驗，M2-D 仍 IN_PROGRESS。下一步在 AGY 對照五種 viewport 進行視覺／滑鼠實測，後續進行手機觸控及 IndexedDB 驗收。

2026-09-25 M2-D 營造簿介面重構：依 `docs/10-realm-grinder-ui-restructure-plan.md` 修改 `src/abode/living_abode.gd`、`src/presentation/building_catalog.gd`：修行 HUD 兩模式固定，資源移至獨立頂部讀數列並可在固定高度捲動，手動採集為獨立動作與目標選單；桌面管理欄移右，建築依全部／生產／倉儲分類，列內提供成本、直接建造／升級及展開快速資訊，完整詳情仍在同欄。縮短直式管理頁暫收採集動作槽以保建築高度。同步更新 `docs/07-responsive-ui-web-spec.md`、`docs/verification/m2-d.md`、`tests/m2d_responsive_ui_runner.gd`、`tests/core_positive_flow_runner.gd`。Godot 4.7.2 `--import`、全量 17 Runner、Web Release export 均 exit 0；瀏覽器畫面工具初始化回報 `trusted Node process exited unexpectedly`，未取得真實滑鼠／觸控、CSS 視覺或 IndexedDB 證據。M2-D 保持 IN_PROGRESS；下一步在 AGY 以本次 Web build 驗收實際版面與命中。

2026-09-25 M2-D 雙狀態 Godot 畫面實作：`src/abode/living_abode.gd` 將空島 HUD 收為境界／壽元／當前目標與最小資源採集卡，移除常駐系統訊息與重複詳情，底部以單列營造／神識／更多三入口保留；`src/presentation/building_catalog.gd` 改成單一管理欄，資源固定於建築列表之上，列表獨立捲動，建築詳情在同欄替換列表並恢復返回位置，短螢幕暫收非必要資訊。`tests/m2d_responsive_ui_runner.gd` 和 `tests/living_abode_runner.gd` 更新為兩狀態契約；`docs/07-responsive-ui-web-spec.md`、`docs/09-two-mode-main-ui-plan.md`、`docs/verification/m2-d.md` 同步。Godot 4.7.2 `--import`、全量 17 Runner、Web Release export 均 exit 0；真實瀏覽器點擊、CSS 視覺、手機觸控與 IndexedDB 落盤未在本輪驗證，M2-D 保持 IN_PROGRESS。下一步在 AGY 依 M2-D 驗收表重測新 build，不得引用先前右欄版型的測試結果。

## 目前可用成果

2026-09-25 M2-D 最新介面重構規劃：使用者肯定「下一步」，但指出資源／洞府核心混雜與字體尺度失序，要求參考 Realm Grinder。新增 `docs/10-realm-grinder-ui-restructure-plan.md`，提出上方身份／資源列、左空島右營造簿、獨立採集動作、建築列直接升級與三種字級角色；保留雙模式與手機重排。現行程式仍為 docs/09，本輪未改遊戲或執行測試；下一步為 Godot 樣式／列元件與實際畫面驗證。

- Godot 4.7.2.stable.official.ed1daf0bf／同版模板、Compatibility、單執行緒 Web 已安裝並成功匯出。
- 主場景為 `scenes/living_abode.tscn`；獨立圖片位於 assets/abode；美術提示詞位於 docs/abode-art。
- 2026-09-13 先前 CLI：`abode_state_runner.gd` 通過；`living_abode_runner.gd` 通過，輸出 `PASS: living abode selects buildings, upgrades, pauses production, and changes scale.`；主場景啟動輸出 ABODE_READY；Web export 成功。主洞府的最新工作基線為 1280×720 橫版桌面優先；手機版需另做直式適配，不能等比例縮小本 HUD。
- 同日先前瀏覽器：點茅屋有 ABODE_SELECT: hut 與詳情；點升級有 ABODE_UPGRADE: hut level=2 與畫面更新；點神識展開有 ABODE_REGION 與多浮島遠景。橫版重排後重新檢查 1280×720 16:9 畫布：繁中標題、資源、建築底牌與右側詳情均清楚可見，點茅屋後右側升級卡正常出現。
- 使用者先前確認舊周天探針繁中正常，點擊計數重載後保留；洞府展示無存檔。兩者不能混用。
- 上一輪服務使用 localhost:4175，當前是否仍在運行必須重新檢查。不可把暫時服務當作已部署產品。

## 任務板

| 任務 | 狀態 | 剩餘工作 |
| --- | --- | --- |
| M0-A | IN_PROGRESS（桌面 Web 完成） | 可重跑整合入口、獨立計數探針 export、瀏覽器重載／HUD／滑鼠拖曳與滾輪已通過；實體觸控／雙指與裝置矩陣待 M2-D 前補證 |
| M0-B | DONE | 2026-09-14 已固定唯讀來源的雜湊／資料 profile，建立代表性黃金 fixture 與隔離 reference runner；詳見 `docs/verification/m0-b.md`。完整 Amount 契約留給 M0-C。 |
| M0-C | DONE | 2026-09-14 交付 `src/domain/amount_compat.gd`、`seeded_random_compat.gd` 與黃金 fixture／契約 runner（Git `9e35c43`）；支援邊界與 ADR-008 見 `docs/verification/m0-c.md`。2026-09-15 本輪重跑 import 與 `m0c_compat_v3_runner.gd` 通過。 |
| M1-A | DONE | 2026-09-16 交付 domain／simulation／application 最小核心、era1 內容與驗證器、`tests/m1a_core_runner.gd`（exit 0）；詳見 `docs/verification/m1-a.md`。場景接線留 M2-A。 |
| M1-B | DONE（2026-09-23 修正分幀時間與手動晉階） | 2026-09-16 交付 Clock、TimeAdvancer、修行／壽元；2026-09-23 核心正流程稽核發現線上分幀時間被逐次丟棄、模擬器自動晉階扣光首分鐘靈氣，已修正並更新 `m1b_time_runner.gd`。維持費、丹藥天時未實作。 |
| M1-C | DONE（CLI／桌面路徑；瀏覽器儲存未驗證） | 2026-09-16 交付 SaveCodec、兩世代槽位、checksum、File／Web storage adapter、SaveManager、匯出／匯入 UI 與 `tests/m1c_persistence_runner.gd`（exit 0）；詳見 `docs/verification/m1-c.md`。IndexedDB 落盤、兩分頁互斥、瀏覽器重載未驗證。 |
| M1-D | DONE（CLI／桌面路徑；瀏覽器、跨程序未驗證） | 2026-09-16 以 fusion 編排交付離線結算（24h 上限、游標提交、不雙領）、協調器、摘要 UI 與 `tests/m1d_offline_runner.gd`（exit 0）；詳見 `docs/verification/m1-d.md`。 |
| M1-E | DONE（CLI／桌面路徑；瀏覽器 UI 與真實 corpus 未驗證） | 2026-09-16 交付 `LegacyImporter`、9 個隔離樣本、支援矩陣 `docs/legacy-compatibility.md` 與 `tests/m1e_import_runner.gd`（exit 0）；預覽差異、新槽提交、原文保留、`backfill_policy="none"`。詳見 `docs/verification/m1-e.md`。 |
| M2-A | DONE（核心正流程重新驗證；AGY 裝置驗收待 M2-D） | 2026-09-23 補齊金錢等已解鎖資源採集入口、玄銅解鎖及錯誤名稱；`core_positive_flow_runner.gd` 由全零新檔支付成本，走到十種 Era 1 建築、首升境、輪迴及下一世重建，並驗各產線實際入庫。此前單元 runner 直接注入資源，未揭露木屋前金錢斷鏈。 |
| M2-B | DONE（CLI／桌面路徑；全量 11 個 Runner 通過） | 2026-09-19 交付首次升境規則、Era 2（築基期）定義、小階修煉積累、大境界突破容量門檻（不扣庫存）、突破演出場景控制器（可跳過／可重播不重發）、洞府天象反饋與 `m2b_breakthrough_runner.gd`（exit 0）；詳見 `docs/verification/m2-b.md`。 |
| M2-C | DONE（CLI／桌面路徑；全量 12 個 Runner 通過） | 2026-09-19 交付第一分鐘九界鉤子、引氣事件觸發、6–8 秒可跳過相機抽遠、九界法則願景預覽、標記嚮往（零副作用契約）、返回洞府、存檔持久化防重複與 `m2c_nine_realms_runner.gd`（exit 0）；詳見 `docs/verification/m2-c.md`。 |
| M2-D | DONE | 2026-09-26 使用者於真實瀏覽器環境進行完整操作與視覺驗收，確認緊湊營造清單、內嵌採集、直式/橫式自適應排版、空島地標點擊與流暢度通過。 |
| M3-A | DONE（核心閉環與 UI 面板全量交付） | 2026-09-22 交付輪迴轉世規則、天賦系統與持久化；2026-09-24 交付 `reincarnation_panel.gd` 雙分頁互動 UI 面板與 `tests/m3a_reincarnation_ui_runner.gd`（exit 0）。全量 17 項 Runner 與 Web export 均通過。 |
| M3-B | IN_PROGRESS（丹藥系統 DONE、BUFF系統 DONE） | 2026-09-26 第一彈完成丹藥與煉丹房系統；2026-09-27 第二彈完成 BUFF 與狀態時效增益系統（時效衰減、同類刷新、永久特質、大境突破餘韻連動、跨世繼承、自適應 HUD 狀態列與調試工具支援），全量 22 Runner 通過；天時、宗門、機緣、靈獸、成就後續推進。 |
| M4-A | DONE（全閉環交付） | 2026-09-27 交付第二界（靈界 · 天靈洞天）、三大據點（天樞陣眼、化靈仙池、虛空引靈台）、雙界並行模擬、靈石轉化極品靈晶、天青靈液全洞府反哺、跨界神遊傳送面板、遠景天標與全量 23 Runner 驗證。 |
| M4-B | TODO | 九界法則資料擴充、正式地理尺度與遠界旅程 |
| M5-A/B | TODO | 按需生成、封存與逐界內容 |


目前無已確認的外部阻塞；未選定基準手機與實機測量仍待安排。不因這一項未知而停掉可做的 CLI／fixture 工作。

## 已知限制與檢查線索

2026-09-23 核心正流程稽核：見 `docs/verification/core-positive-flow.md`。原 15 runner 加新正流程 runner 共 16 項、Godot import、主場景啟動及 Web Release 匯出皆 exit 0。CLI 與場景訊號未代替 AGY 真實 Web 點擊、手機觸控與 IndexedDB 落盤。`foundation_pill` 目前解鎖顯示但無配方或取得命令，也尚非本期建築成本；避免在介面宣稱可生產。既有舊快照可用零餘數載入；規則版本已升 `core-flow-2`。

1. 主場景已完整切換至 GameSession 與 SaveManager；展示數值與 float process 已由正式 Tick 與 AmountCompat 取代。
2. 目前場景測試直接呼叫函式；2026-09-13 已額外在桌面 Web 實測建築命中、HUD、拖曳、滾輪、歸家及遠景。雙指／實體觸控、拖出 HUD 後釋放和不同手機 DPI 仍待 M2-D 前補證。
3. 主場景已改為 1280×720 桌面橫版設計，完整 CLI／Web 匯出與瀏覽器畫面已於本輪重驗。手機直式適配、360 CSS px 可讀性與44px觸控區仍需在 M2-D 前量測，不能由桌面畫面推定通過。
4. region 是重用地形的視覺示範，没有新據點經濟；飛劍／靈流已有動畫程式，但視覺強度、位置對齊與手機效能待實測。
5. all_resources 匯出會帶入 src/效果圖 和 tests；正式發布前需明確排除開發／參考內容，保留來源原圖。
6. 2026-09-19 M1 全量 Commit 595cea6，M2-A 提交 0f460e0，M2-B 提交 464d76c，M2-C 通過全量 12 項 Runner 驗證。

## 下一個動作

先在 AGY 強制更新 Web build，以新檔開「營造設施」，同時開建築詳情，確認清單不再填滿左側、詳情底部操作可捲動取得；再於窄橫式／直式驗證焦點詳情的「收起→回清單」，旋轉手機時無裁切或互蓋。從「更多功能」驗證存檔、九界、輪迴與低特效入口。隨後重跑核心正流程：引氣建茅屋、逐秒觀察靈氣、升茅屋 2 階確認產率提高；從營造清單採集金錢建木屋，續建林場、採石場並檢查下品靈石／玄銅入庫。記錄 CSS viewport、瀏覽器縮放與畫面；再續觸控、IndexedDB 與效能矩陣。若 AGY 重現異常，附操作時間、存檔版本與畫面。

## 本輪交付

2026-09-25 M2-D 雙狀態主介面規劃：依使用者要求盤點空島常態與資源／建築常態兩種布局，新增 `docs/09-two-mode-main-ui-plan.md`。確認現行清單同一 ScrollContainer 使資源與後段建築無法同時監看，短橫式中央世界區不足以作為可操作空島；清單的 40px 密度／收起鍵及緊湊列也低於既定約 44 CSS px 觸控目標。提案為「空島精簡 HUD／最小資源／三主鍵」及「單一管理欄固定資源、建築獨立捲動、詳情原位替換」，列出各控制的資訊／尺寸／命中預算與五種 viewport 驗收。此輪只交付設計契約，未改 Godot 實作、未聲稱新布局或觸控通過；M2-D 保持 IN_PROGRESS。

2026-09-25 M2-D 版型與導航修正：使用者 `1920×902` 截圖指出營造清單佔滿空白、建築詳情超出下緣。`src/presentation/building_catalog.gd` 按可見列估算高度；`src/abode/living_abode.gd` 限制清單寬／高、詳情與系統訊息正文獨立捲動、詳情固定收起鈕，短橫式／直式採可返回清單的焦點詳情，方向切換同步重排。底部只保留營造、神識及更多功能；低特效、存檔、九界、說明、突破重播及輪迴移至次級選單，轉世可用時在更多入口標星。更新 M2-D／M2-B／M3-A UI runner 與規格、驗收紀錄。M2-D 幾何回歸覆蓋 `1920×902`、`1280×720`、`844×390`、`360×640`、`360×480`，包括清單／HUD／訊息／詳情邊界、固定收起鈕、詳情操作捲動、橫直切換。全量 17 項 Runner、Godot import 與 Web Release export 均 exit 0；損壞檔／非法 Base64 的防護測試會印預期 ERROR 但 Runner 為 PASS。實際瀏覽器工具仍因 Windows sandbox helper 初始化失敗，未取得新版畫面；AGY 實際點擊、手機觸控及 IndexedDB 未驗，M2-D 保持 IN_PROGRESS。

2026-09-24 M3-A 輪迴轉世與道心天賦 UI 面板：新增 `src/presentation/reincarnation_panel.gd`，提供雙分頁對比彈窗，支援世次概覽、資格狀態高亮、保底收益預覽、起手傳承試算、轉世入定送出與道心天賦（資源傳承、長生久視、先天道體）即時參悟升級。主場景 `src/abode/living_abode.gd` 接入工具列「輪迴天道」按鈕與直式 `more_menu` 選單，支援自適應 360 CSS px 窄螢幕排版，並於轉世完成後自動返回洞府近景與重載 HUD。新增 `tests/m3a_reincarnation_ui_runner.gd`（exit 0，面板開關、分頁切換、天賦購買扣除道心、築基資格高亮、入定轉世重置與起手資源發放全數 PASS）。全量 17 項 Runner 與 Web export 均通過。

2026-09-22 M3-A 輪迴轉世機制閉環：擴充 `GameState` 跨世持久化欄位（`reincarnation_count`、`highest_era`、`dao_heart`、`dao_proof`、`talents`），並在 `SaveCodec` 實現向後相容解碼。新增 `src/simulation/reincarnation_rules.gd`，嚴格對齊唯讀來源黃金測資（建築等級總和 $B$、道心 $B/10$、保底 0/15/20/25、道證 $B/50$ 與 $B/30$、起始資源傳承比率 40%/80%）；新增 `src/simulation/talent_system.gd` 實現道心天賦購買（資源傳承、長生久視、先天道體）與全局產率/壽元倍率；`CommandProcessor` 接入 `reincarnate` 與 `learn_talent`；`TimeAdvancer` 接入天賦壽元與產率加成；`GameSession` 暴露輪迴預覽、便利命令與完整視圖。新增 `tests/m3a_reincarnation_runner.gd`（exit 0，黃金測資比對、資格門檻、狀態重置與傳承、天賦生效、存檔往返全數 PASS）。全量 15 項 Runner 與 Web export 均 exit 0。


2026-09-20 M2-D 營造呈現修訂：AGY 第二張測試圖顯示上一版十地塊的加號與名稱牌缺少圖形化空地、部分貼近崖壁；該方案已廢止。新增 `src/presentation/building_catalog.gd`、`docs/08-building-presentation-and-era-expansion.md`，修改 `src/abode/living_abode.gd`／`abode_building.gd`：未建建築由清單操作，建成茅屋才進世界，其他一般資源設施留在清單；同一 `GameSession`／建築 ID／存檔規則不變。修正 `src/application/game_session.gd` 於 Era 2 隱藏已建／早期建築的顯示錯誤。更新 `AGENTS.md`、README、Roadmap、`docs/07-responsive-ui-web-spec.md`、AI 交接與 M2-D 驗證，以及六個受影響 runner。Godot import、七個相關 runner 與 Web export 均 exit 0。未通過項：Codex CUA 瀏覽器啟動失敗、headless Edge 只截到 Godot 載入畫面；AGY 實際清單、地景、滑鼠／觸控、手機及效能待驗。下一個任務仍是 M2-D AGY／裝置驗收；聚靈壇世界地標必須等專屬圖與預備地基，不自動排到島上。


2026-09-20 M2-D 資源與建築畫面（已否決的中間方案，保留歷史）：AGY 截圖顯示茅屋 2 階後左上資源列撐破面板，待建木屋／庫房用完整圖擠到崖邊。修改 `src/abode/living_abode.gd`，將左上限為單行摘要，完整列表改入可捲動且可關閉的 Godot 資源面板；狀態高度推開縮放鍵，短橫式無空間時收起該列，十個地塊重排在草地上。修改 `src/abode/abode_building.gd`，待建只畫可選地基，建成才顯示完整圖，保持可讀底牌與不互蓋的命中區。更新 `tests/m2d_responsive_ui_runner.gd`、`docs/07-responsive-ui-web-spec.md`、`docs/verification/m2-d.md`。Godot import、七個相關 runner 與 Web export 均 exit 0；本機 Web 頁 HTTP 200。未通過項：AGY 實際草地配置、滑鼠／觸控命中、CSS 字級與效能尚無新證據。下一個任務仍為 M2-D 的 AGY 視覺及裝置驗收；正式建築美術與新浮島分區另按需求排程。

2026-09-20 M2-D 文字可讀性：新增 `src/presentation/ui_typography.gd`，以現有可變字型的 `wght` 600／700 建立 Godot 共同字體角色與面板樣式；主 HUD、建築底牌、九界卡片與突破畫面接入，九界正文／狀態／操作從 12–13 提高至 16–18，存檔與離線摘要增加深色實底。突破直式版以視窗重排文字與按鈕；修正築基後重溫入口在直式版擠回 toolbar 的問題。更新 `docs/07-responsive-ui-web-spec.md` 與 `docs/verification/m2-d.md` 的字級／字重／對比／預渲染邊界及 AGY 重測項。Godot 4.7.2 import、六個受影響 runner 與 Web export 均 exit 0；本機 Web 頁面回應 HTTP 200；瀏覽器視覺工具兩次啟動失敗，實際辨識度待 AGY 驗證。

2026-09-20 M2-D 實作：`project.godot` 明確設為 `stretch/aspect="expand"`；`living_abode.gd` 改為寬式、緊湊橫式及直式 HUD，使用可換行的操作容器，直式將低特效、存檔、九界與說明收進「更多」，建築詳情採底部抽屜。存檔、離線摘要與九界預覽可依可視區域縮放，九界直式改為單欄卡片。AGY 回報九界彈窗溢出後，`nine_realms_preview.gd` 改為固定標題／關閉列與獨立可捲動內容區；`tests/m2d_responsive_ui_runner.gd` 增 `360×480` 短可視區斷言，確認關閉控制仍在畫面內。實測 Godot 4.7.2 import、儲存／字型、洞府、響應式與 M2-D slice runner，以及 Web export 全部通過；AGY 的真實瀏覽器／觸控／效能與九界修正重測待驗證。
2026-09-20 M2-D 規格：新增 `docs/07-responsive-ui-web-spec.md` 與待填寫的 `docs/verification/m2-d.md`，固定 Godot 世界與 Web canvas 邊界、`1280×720` 構圖基準、`canvas_items`／`expand`、寬式／緊湊橫式／直式面板行為、觸控輸入隔離與最低瀏覽器／實機測試矩陣；並在 `AGENTS.md`、README、Roadmap、技術架構與 AI 交接指南建立必讀入口。未修改 Godot 場景、project/export 設定或 Web shell，未執行遊戲測試；本次文件變更不構成 M2-D 驗收通過。

2026-09-19 M2-C：新增 `content/realms/realms.json`（九界法則願景定義）；擴充 `src/domain/game_state.gd` 與 `src/persistence/save_codec.gd` 支援 `tutorial_flags` 存檔持久化；相機 `src/abode/abode_camera.gd` 增加 `focus_cosmos()`（0.08 抽遠）；新增 `src/presentation/nine_realms_preview.gd`（神識抽遠、即時跳過、九界卡片網格、標記嚮往零副作用、收回神識返回洞府）；主場景 `src/abode/living_abode.gd` 首次引氣自動觸發鉤子、toolbar 提供「九界星圖」隨時重溫；新增 `tests/m2c_nine_realms_runner.gd`（exit 0，開局觸發、跳過、九界資料、標記零副作用、返回洞府、存檔重載不重複、重播無二次獎勵全通）；全量 12 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-c.md`。

2026-09-19 M2-B：新增 `content/eras/era2.json`（築基期）並註冊至 `content/manifest.json`；擴充 `src/simulation/command_processor.gd` 與 `src/application/game_session.gd` 支援 `level_up_cultivation` 與 `breakthrough_era`（容量門檻嚴格防護、突破不扣庫存）；新增 `src/presentation/breakthrough_sequence.gd`（突破演出：天地異象、可跳過、可重播不重發獎勵）；主場景 `src/abode/living_abode.gd` 整合修煉晉階與突破按鈕、掛載突破演出、築基後浮現天幕祥雲與聚靈壇光環；新增 `tests/m2b_breakthrough_runner.gd`（exit 0，小階累積、突破契約、演出跳過與重播、存檔重載全通）；全量 11 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-b.md`。

2026-09-19 M2-A：重構 `src/abode/living_abode.gd` 徹底接入 `GameSession`、`SaveManager`、`OfflineCoordinator` 與 `Onboarding`；擴充 `src/abode/abode_building.gd` 支援未建造狀態；修復 `web_storage_adapter.gd` 關鍵字衝突並增補 `AmountCompat.to_float()`；更新 `tests/living_abode_runner.gd` 並新增 `tests/m2a_abode_runner.gd`（exit 0，6 階段驗證全通）；全量 10 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-a.md`。

## 已知限制與檢查線索

1. 主場景已完整切換至 GameSession 與 SaveManager；展示數值與 float process 已由正式 Tick 與 AmountCompat 取代。
2. 目前場景測試直接呼叫函式；2026-09-13 已額外在桌面 Web 實測建築命中、HUD、拖曳、滾輪、歸家及遠景。雙指／實體觸控、拖出 HUD 後釋放和不同手機 DPI 仍待 M2-D 前補證。
3. 主場景已改為 1280×720 桌面橫版設計，完整 CLI／Web 匯出與瀏覽器畫面已於本輪重驗。手機直式適配、360 CSS px 可讀性與44px觸控區仍需在 M2-D 前量測，不能由桌面畫面推定通過。
4. region 是重用地形的視覺示範，没有新據點經濟；飛劍／靈流已有動畫程式，但視覺強度、位置對齊與手機效能待實測。
5. all_resources 匯出會帶入 src/效果圖 和 tests；正式發布前需明確排除開發／參考內容，保留來源原圖。
6. 2026-09-19 M1 全量 Commit 595cea6，M2-A 順利交付並通過 10 項 Runner 驗證。

## 下一個動作

M2-A 已完成（CLI／桌面路徑；實機觸控待 M2-D）。下一個主線依 ROADMAP 進入 M2-B（首次升境與可重播演出；相依 M2-A）。由舊依賴資料補齊第一個升境必需功法、配方、材料，實現首度境界突破演出。

## 本輪交付


2026-09-19 M2-A：重構 `src/abode/living_abode.gd` 徹底接入 `GameSession`、`SaveManager`、`OfflineCoordinator` 與 `Onboarding`；擴充 `src/abode/abode_building.gd` 支援未建造狀態；修復 `web_storage_adapter.gd` 關鍵字衝突並增補 `AmountCompat.to_float()`；更新 `tests/living_abode_runner.gd` 並新增 `tests/m2a_abode_runner.gd`（exit 0，6 階段驗證全通）；全量 10 項 Runner、Headless 啟動與 Web 匯出全部 PASS。詳見 `docs/verification/m2-a.md`。

2026-09-13：新增 ROADMAP、AGENTS、AI handoff 與本狀態檔，更新 README 和舊規劃入口。只修改文件，未改遊戲程式或再次跑遊戲測試；已核對現有檔案與測試入口，並檢查新增文件 UTF-8、相對連結和 Roadmap 任務覆蓋。
2026-09-13 M0-A：新增 `tools/run_m0a.ps1`、隔離周天 probe、兩個 Godot source-scan ignore 及鏡頭觀察記錄。完整 CLI 匯入／runner／雙 Web export 成功；桌面瀏覽器實測周天保存 1→2→3、洞府選取／升級／藥圃停復／低特效／遠景／歸家／拖曳／滾輪。詳見 [M0-A 驗收紀錄](verification/m0-a.md)。實體 touch/pinch 與效能未測，故 M0-A 保持 IN_PROGRESS。

2026-09-13 可讀性調整：主場景設計尺寸改為 1280×720；HUD 改為左側狀態、中央洞府、右側詳情與底部操作，面板提高不透明度、字級與按鈕尺寸，建築名稱加深色底牌；低優先的常駐操作提示移出主畫面，保留操作說明按鈕。初始洞府鏡頭提高至 0.70，讓地形在桌面畫布成為主視覺。`tools/run_m0a.ps1` 最後一次完整匯入、三個 runner、啟動與兩個 Web export 均成功；localhost Web 實測茅屋選取及右側升級詳情通過。此調整未改展示數值、經濟或保存。手機直式適配仍未做。

2026-09-14 M0-B：新增 `docs/legacy-source-manifest.md`、`docs/rule-differences.md`、`tests/fixtures/legacy/m0-b-v1.json`、`tests/fixtures/legacy/m0b_reference.test.ts` 與驗收紀錄。`E:\Python\test1` 不是 Git work tree，故以 package 版本、精選規則／測試／CSV 的 SHA-256 和資料列數固定來源。隔離 Vitest runner 直接從唯讀舊規則模組驗證建築成本、容量容差、修煉時間、Amount 代表字串、壽元、輪迴、新手解鎖與 ASCII／繁中／數字 SeededRandom state 恢復；1 test 通過。完整 Amount 演算與 GDScript RNG 實作尚未開始，列入 M0-C。

2026-09-14 M0-C（前一輪交付，本輪補記錄）：Git `9e35c43` 新增 `src/domain/amount_compat.gd`、`src/domain/seeded_random_compat.gd`、`tests/fixtures/legacy/m0-c-v1..v3.json`、三個 m0c runner、`docs/verification/m0-c.md` 與 ADR-008；當時實測 import、M0-C runner 與 M0-B vitest 皆通過。該輪未同步更新本狀態檔的任務板（M0-C 仍標 TODO），屬記錄衝突，本輪以程式與測試證據修正為 DONE。

2026-09-15 進度確認：工作區已是 Git repository（master，工作樹乾淨，最新提交 `9e35c43`）。重跑 Godot 4.7.2 版本檢查、`--import`、`m0c_compat_v3_runner.gd`（PASS: M0-C AmountCompat canonical contract and SeededRandomCompat match the fixture.）、`abode_state_runner.gd` 與 `living_abode_runner.gd`（皆 PASS）。未重跑 Web export、瀏覽器互動與 vitest；本輪僅改本狀態檔，未動遊戲程式。下一個任務 M1-A。

2026-09-16 M1-A：新增 `content/`（manifest＋era1 資源 7／建築 10）、`src/content/game_content.gd`、`src/content/content_loader.gd`（驗證與 SHA-256 content_version）、`src/domain/game_state.gd`、`src/simulation/onboarding.gd`、`building_costs.gd`、`production.gd`、`command_processor.gd`、`src/application/game_session.gd`（冪等登記、revision、get_view）與 `tests/m1a_core_runner.gd`。實測 `--import` 成功、runner 退出碼 0（PASS 行如上，無 SCRIPT ERROR），涵蓋費用／onboarding parity（m0-b-v1.json）、空白初始、Gather／升級、冪等、過時 revision、確定性與內容驗證。同輪更新 `docs/verification/m1-a.md`、`docs/rule-differences.md`（LP-001／002 收斂，新增 LP-009～011、V2-004）與 `docs/ai-handoff.md` 命令區。未 commit；`src/abode/` 展示與 ADR-008 早期候選檔未動（後者待使用者確認刪除）。

2026-09-16 M1-B 前置（fusion）：新增 opencode fusion 設定 `.opencode/skills/fusion/SKILL.md`、六個 subagents（`fusion-worker-a` glm-5.3-flash、`-b` qwen3.8-flash、`-c` deepseek-v4-flash、`-d` nemotron-3.5-lightning-free、`fusion-scout`、`fusion-auditor`，後兩者 edit deny）與命令 `fusion-m1b`。完成 M1-B 舊規則研究並凍結於 `docs/m1-b-execution-plan.md`：tick=60 秒／年、修練時間公式與向量（47.5／33.75／36／1）、壽元公式與向量（4800／13500／68400；累積 80／200／740 祀）、升境不重置 `totalElapsedSeconds`、每 tick 步驟與容量 clamp。Era1 的 baseTime／levelUp 需求等未固定項留 scout。opencode 設定不熱重載：**需重啟後執行 `/fusion-m1b`**。本輪未寫 M1-B 遊戲程式、未跑引擎。

2026-09-16 M1-B（fusion 執行）：以 fusion 編排完成。新增 `src/simulation/game_clock.gd`、`time_advancer.gd`、`cultivation.gd`、`lifespan.gd`、`content/eras/era1.json`、`tests/m1b_time_runner.gd`；擴充 `GameContent`／`ContentLoader`（era 定義、引用驗證、content_version 含 eras）、`Production.compute_rates`（resource_multiplier）、`GameState`（training_seconds／total_elapsed_seconds）、`GameSession`（clock／advance_time／view）。Era1 數值對照唯讀 `eras.csv`（SHA-256 `E71F03AB…CA404`）。實測 `--import` 退出碼 0、`m1b_time_runner.gd` 退出碼 0（`PASS: M1-B clock, ticks, cultivation, lifespan, boundaries, determinism.`，無 SCRIPT ERROR／FAIL）。fusion-auditor 稽核後修正：runner 內容載入失敗不再靜默 fallback、`_expect_close` 加 NaN 檢查、補 level 10 邊界與 Era1 lv5–lv9 向量。未實作：突破／升境、維持費、丹藥天時、`lv9Item`。未 commit。

2026-09-16 M1-C（fusion 執行）：以 fusion 編排完成。新增 `src/persistence/storage_adapter.gd`、`save_codec.gd`、`save_slots.gd`、`save_manager.gd`、`file_storage_adapter.gd`、`web_storage_adapter.gd`、`src/presentation/save_controls.gd`、`tests/m1c_persistence_runner.gd`（11 群）。信封依 docs/02 §7.1；checksum 為 SHA-256，並修正 Godot JSON int→float 往返造成的雜湊不符（數字正規化）；decode 增 `REVISION_MISMATCH` 一致性檢查。實測 `--import` 退出碼 0、`m1c_persistence_runner.gd` 退出碼 0（`PASS: M1-C save codec, two-slot persistence, checksum, export/import.`，無 SCRIPT ERROR）。fusion-auditor 稽核後修正：runner 損壞復原改為真正覆寫 active 槽、移除恆真斷言、匯入／匯出改以 `to_snapshot_dict()` 比較。未驗證：IndexedDB 落盤、兩分頁互斥、瀏覽器重載、web quota、匯出匯入 UI 互動。未 commit。

2026-09-16 M1-D（fusion 執行）：以 fusion 編排完成。新增 `src/simulation/offline_settlement.gd`、`src/application/offline_coordinator.gd`、`src/presentation/offline_summary.gd`、`tests/m1d_offline_runner.gd`；`time_advancer.gd` 增 `advance_time_only`；`game_state.gd` 增 `duplicate_state()`；`save_manager.gd` 增 `_envelope`／`last_settled_utc_ms()`／`envelope()`；`save_codec.gd` `RULES_VERSION` 升 `offline-24h-1`。政策：收益窗 24h 上限、超出只推年歲與壽盡、游標提交至 now、保存失敗可重試不雙領。實測 `--import` 退出碼 0；`m1d_offline_runner.gd`、`m1c_persistence_runner.gd`、`m1b_time_runner.gd` 皆退出碼 0、無 SCRIPT ERROR（m1d PASS：`PASS: M1-D offline settlement, cap 24h, cursor commit, no double grant.`）。fusion-auditor 稽核後修正：NO_STATE／NO_CONTENT 回 `{}`、`advance_time_only` 改用 `SECONDS_PER_TICK`、DETERMINISM 改結算兩次比 report、補重載不補領與深拷貝隔離測試、強化摘要靜態檢查。未驗證：IndexedDB 落盤、兩分頁互斥、跨程序關閉再開、丹藥／天時到期、自動輪迴、`advance_to` 邊界驅動與批次讓出、匯出匯入 UI 互動。未 commit。

2026-09-16 M1-E（fusion 執行）：以 fusion 編排完成。新增 `src/persistence/legacy_importer.gd`、`tests/m1e_import_runner.gd`、`tests/fixtures/legacy/import_samples/`（9 個去識別化樣本：compact 開局、Base64 中期、長鍵中期／輪迴／大數／靈獸缺欄、未知 ID、截斷損壞、損壞 JSON）與 `docs/legacy-compatibility.md`（14 列支援／部分／拒絕矩陣，含 docs §7.2「s／skills」更正為 `s`=sect）。`save_manager.gd` 增 `LEGACY_RAW_KEY`／`import_legacy_text()`／`legacy_raw()`；`save_controls.gd` 增舊檔匯入 UI。政策：使用者主動貼上／選檔、`backfill_policy="none"` 不按舊時間戳補獎、成功另存新槽 `revision=max(prev+1,1)`、原文存 `legacy_import_raw`、未知 ID／金額問題列入報告且不寫入狀態。修掉 `build_report` 兩個缺陷（迭代包裝字典 `{ok,map,error}` 的鍵、將整個資源 entry 直接送 `deserialize_amount`）與長形式 `buildings` 拆包。實測 `--import` 退出碼 0；`m1e_import_runner.gd` 退出碼 0（PASS：`PASS: M1-E legacy import decode, mapping, reports, and slot commit.`），m1d／m1c／m1b 回歸皆退出碼 0、無 SCRIPT ERROR。fusion-auditor 稽核九項準則全 MET。未驗證：瀏覽器 UI 互動、真實 corpus、`~20000` 字元截斷、layer>3 算術、獸進度不被分享碼攜帶、門派／技能／天賦等僅列報告不映射。未 commit。

2026-09-23 驗收程序補記：日後執行的實機觸控操作單已記入 `docs/verification/m2-d.md`；IndexedDB 實際提交、重載、quota 與多分頁操作單已記入 `docs/verification/m1-c.md`。兩者均為待執行，未新增通過宣稱。
2026-09-25 M2-D 操作節奏修正：回應每 60 秒才見資源入庫的體驗問題，`TimeAdvancer.SECONDS_PER_TICK` 改為 1；線上每秒累積一次，離線固定產率批次結算並維持 60 秒＝1 祀。左上 HUD 將境界／層數與修煉／壽元拆行，資源顯示兩位小數。舊 60 秒餘數快照仍可讀，規則版號為 `core-flow-3`。檔案：`src/simulation/time_advancer.gd`、`src/abode/living_abode.gd`、`src/application/offline_coordinator.gd`、`src/persistence/save_codec.gd`、相關 runner 與 `docs/verification/core-positive-flow.md`／`m2-d.md`／`rule-differences.md`。驗證結果與未通過項見後續記錄；真實手機觸控和 IndexedDB 仍待執行。
2026-09-25 驗證結果：Godot 4.7.2 `--import` exit 0；全量 17 個現行 Runner（含 `core_positive_flow_runner.gd`、`m3a_reincarnation_ui_runner.gd`）依序 exit 0；最高層 HUD 文案與舊版 `core-flow-2` 餘數測試補強後，核心正流程與 M2-D 響應式 Runner 再次 exit 0。主場景 headless 啟動 exit 0，Web Release 匯出 exit 0，`git diff --check` exit 0。真實瀏覽器畫面、實機每秒數值觀察、觸控與 IndexedDB 落盤尚未取得本輪證據；M2-D 仍為 IN_PROGRESS。下一步在 AGY 強制更新 Web build，以新檔建茅屋，逐秒確認靈氣小數增長與茅屋升級後的產率，並檢查練氣／築基名稱與目前層數在桌面及手機版型清楚可見。
2026-09-25 M2-D HUD／系統訊息整合：`src/abode/living_abode.gd` 移除獨立「資源總覽」按鈕與面板；資源庫存、產率與練氣採集整合到 `src/presentation/building_catalog.gd` 的營造清單。系統訊息接入 DAO1 仍適用的起始採集／木屋提示，以 DAO2 `next_objective`、成本與現行順序引導茅屋→木屋→林場→採石場→靈植場；未接入的宗門／丹藥舊提示不顯示。開清單時寬式／橫式 HUD 與訊息移右，直式改垂直堆疊；短橫式暫收底部導航，收清單後恢復。詳情區也在清單模式移至訊息卡下方。文件更新 `docs/07-responsive-ui-web-spec.md` 與 `docs/verification/m2-d.md`。驗證：M2-D responsive Runner（新增全建築引導順序、訊息／詳情不重疊、資源入口移除與三版型版位斷言）通過；全量 17 Runner、Godot 4.7.2 import、Web Release export、`git diff --check` 均 exit 0。瀏覽器電腦操作 helper 失敗，故實際瀏覽器畫面、滑鼠／觸控、手機 viewport 仍待 AGY 驗證；M2-D 維持 IN_PROGRESS。
