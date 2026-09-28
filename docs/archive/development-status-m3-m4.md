# M3–M4 歷史交付記錄

2026-09-28 REF-A 從 development-status.md 歸檔，來源提交 d77bca3。

原檔存在非法 UTF-8 位元組，歸檔以 `\xNN` 轉義保留；可由 Git `d77bca3:docs/development-status.md` 取回原始位元組。此處保留原文與原段落序號，包含當時的重複任務板、過時狀態及既有截斷文字；交錯提及其他里程碑的段落保留完整。不要把歷史的「下一步」當成目前工作。最新狀態見 [開發狀態](../development-status.md)。

<!-- 原狀態段落 3 -->
2026-09-28 M3-B 第三彈：宗門系統（Sect System）、委託派遣、宗門真訣與坊市全閉環交付：完成宗門系統規則模組 `src/simulation/sect_system.gd`。（1）門檻與五大宗門：築基期（`era_id >= 2`）或轉世次數 $\ge 1$ 解鎖，可拜入太虛天闕、天劍聖宗、縹緲仙宮、萬佛靈宗或紫霄玄門；（2）三大委託槽位派遣：支援 5 種品質（普通、優秀、稀有、史詩、傳說）隨機懸賞委託，冷卻刷新、耗時倒數結算，產出宗門貢獻、金錢、靈草、靈石、玄銅乃至頓悟靈光增益；完全移除 `Time.`/`OS.` 系統時鐘依賴，確保純邏輯確定性；（3）宗門真訣與常駐修仙倍率：神農靈訣（草木產能）、太虛吐納（靈氣產能）、天劍戰訣（修煉速度）、紫霄護體（壽元增益），支援 10 級修習與貢獻／物料消耗；（4）宗門坊市物資兌換：提供凝血草、玄陰朱果、三階聚靈丹等資源限購兌換；（5）主場景與 HUD：`src/presentation/sect_panel.gd` 接入三頁式自適應面板，主場景頂部自適應入口與次級選單第 10 項直達；`GameState` 與 `SaveCodec` 擴充 `sect` 狀態持久化；輪迴轉世清除肉身弟子身份與普通真訣。新增 `tests/m3b_sect_runner.gd` 與 `tests/m3b_sect_ui_runner.gd`。全量 25 項 Runner 與 Web Release 匯出均 exit 0。

<!-- 原狀態段落 4 -->
2026-09-27 M3-A 轉生九界俯衝回空島特效表演全閉環交付：完成專屬全螢幕轉生儀式感演出組件 `src/presentation/reincarnation_sequence.gd`。（1）演出節奏：3 階段動態插值（總時長 3.4 秒），階段一（0.0s~0.8s）靈魂太虛出神，瞬移至 Cosmos 視野（zoom 0.08，pos (0, -100)），白金柔光淡入，浮現偈語「肉身有盡，道心無窮。」；階段二（0.8s~2.4s）穿越輪迴，平滑加速放大下沉（zoom 0.08 ➔ 0.70），繪製 16 條虛空向外穿梭的光芒粒子線條，浮現偈語「歷經千劫，神返靈山。」；階段三（2.4s~3.4s）仙身聚頂，落定 Home 空島視野（zoom 0.70，pos (0, -40)），空島靈樹中心釋放向外擴散的青藍金靈環波（draw_arc 半徑擴大至 240px），浮現偈語「重塑仙身，再問長生！」並彈出當世結算卡片（世數、凝聚道心點數與入世按鈕）。（2）支援「跳過演出（Skip）」與全螢幕點擊跳過，支援 `reduced_motion` 低動態無障礙模式。（3）`src/abode/living_abode.gd` 接入演出掛載與運鏡控制，並理順與首次轉生九界星圖導引（`NineRealmsPreview`）之層級協調。（4）更新 `tests/m3a_reincarnation_ui_runner.gd` 測試斷言覆蓋階段運鏡、徽章與跳過機制。全量 23 項 Runner exit 0 / PASS，最新 Web Release 已重新匯出至 `build/web/`。

<!-- 原狀態段落 6 -->
2026-09-27 M3-A 輪迴門檻對齊舊版與 HUD 壽盡直達橫幅交付：嚴格修正 `src/simulation/reincarnation_rules.gd` 輪迴資格門檻，徹底移除過渡性的「築基期（era_id >= 2）直接放行」設定，完全回歸 Dao1 經典雙軌門檻：（1）被動壽元已盡（含天賦、丹藥與 BUFF 累加壽元）；（2）主動提前輪迴需修築特定輪迴建築【往生蓮臺】（`rebirth_lotus`）或【太虛輪迴境】（`void_mirror`）。於主場景 `src/abode/living_abode.gd` 的 `header_box` 實作頂層高醒目度的仙俠風懸浮警示卡 `LifespanBanner`（亮橘暖金發光邊框），於壽元已盡時立即彈出「⏳【壽元已盡 · 天命難違】」，並配備「🪷 輪迴證道」專用按鈕直達轉世面板；壽元未盡時自動隱藏零佔位。同步更新 `reincarnation_panel.gd` 資格提示文字。更新 `tests/m3a_reincarnation_runner.gd`、`tests/m3a_reincarnation_ui_runner.gd`、`tests/core_positive_flow_runner.gd`、`tests/m2c_nine_realms_runner.gd`、`tests/m2d_slice_release_runner.gd`、`tests/m3b_alchemy_runner.gd` 與 `tests/buff_system_runner.gd`。全量 23 項 Runner 與 Web Release 匯出均 exit 0。

<!-- 原狀態段落 7 -->
2026-09-27 M4-A 手工第二界（靈界 · 天靈洞天）與雙界法則系統全閉環交付：完成靈界體系規則模組 `src/simulation/realm_system.gd`。定義三大活躍據點（天樞陣眼 `celestial_hub`、化靈仙池 `pure_pool`、虛空引靈台 `void_beacon`），支援至 10 級擴建。實作跨界法則與機會成本供給取捨：天樞陣眼每級每秒消耗人界靈石轉化極品靈晶；化靈仙池每級每秒消耗極品靈晶凝練天青靈液；化靈仙池提供全洞府修煉速度 +15%/級跨界反哺加成；虛空引靈台擴充靈界專屬資源容量上限。`TimeAdvancer` 接入雙界並行模擬（不論玩家當前身處人界或靈界，兩界產能與消耗持續運轉）。`GameState` 與 `SaveCodec` 擴充 `current_realm` 與 `realms_data`，具備向後相容解碼。`CommandProcessor` 接入 `switch_realm` 與 `upgrade_realm_outpost` 指令。`living_abode.gd` 接入金色高亮遠景「靈界方向 · 【跨界神遊】」天標、自適應跨界神遊面板 `RealmTeleportModal`、次級選單入口「靈界洞天」與切景天幕色調調諧。新增 `tests/m4a_realm_runner.gd`（exit 0，解鎖條件、切界返家、據點升級、並行模擬與機會成本、修煉反哺、存檔往返、UI 面板全通）。全量 23 項 Runner 與 Web Release 匯出均 exit 0。

<!-- 原狀態段落 8 -->
2026-09-27 M3-B 第二彈：BUFF 與狀態時效增益系統全閉環交付：完成 BUFF 系統規則模組 `src/simulation/buff_system.gd`，支援時效衰減、同類刷新、永久特質（長生龜息）及跨世道痕（transmigratable）繼承規則。首發預置「天靈氣湧」、「頓悟靈光」、「破境餘韻」與「長生龜息」四種經典修仙增益。`GameState` 與 `SaveCodec` 擴充 `buffs` 持久化欄位並保持向後相容。`TimeAdvancer` 接入每秒 tick 衰減、動態產率、專屬資源加成、修煉速度倍率與壽元上限。`CommandProcessor` 接入 `apply_buff` 與 `remove_buff`，並在大境界突破（`breakthrough_era`）成功時自動為玩家施加 120 秒「破境餘韻」。`living_abode.gd` 與 `src/presentation/buff_hud_bar.gd` 接入自適應微徽章狀態列，無 BUFF 時自動隱藏零佔位；`debug_panel.gd` 擴充一鍵施加測試 BUFF。新增 `tests/buff_system_runner.gd`（exit 0，生命週期、衰減、倍率、大境突破連動、存檔往返、輪迴保留/清空及 HUD UI 全通）。全量 22 項 Runner 與 Web Release 匯出均 exit 0。

<!-- 原狀態段落 13 -->
2026-09-26 M3-B 第一彈：丹藥與煉丹房系統全閉環交付：完成丹藥系統規則模組 `src/simulation/alchemy_system.gd`、`GameState` 與 `SaveCodec` 持久化欄位（`pills`、`pill_effects` 向後相容）、`TimeAdvancer` 丹藥加壽與產率倍率接入、`ReincarnationRules` 轉世清空肉身丹藥重置、`CommandProcessor` 接入 `refine_pill` 與 `consume_pill`。主場景 `src/abode/living_abode.gd` 與 `src/presentation/alchemy_panel.gd` 接入自適應煉丹房面板、次級選單入口「洞府煉丹」與 HUD 即時同步。新增 `tests/m3b_alchemy_runner.gd` 與 `tests/m3b_alchemy_ui_runner.gd`（exit 0）。全量 19 項 Runner 與 Web Release export \xe5\x9d| M2-D | DONE | 2026-09-26 緊湊清單與響應式排版通過；2026-09-28 修復 WebGL 背景閃爍後，遠景 v5、Shader 瀑布、突破演出與低特效經使用者於真實 Web 環境親測驗收放行（見 `docs/verification/m2-d.md` 與 `island-breakthrough.md`）。實體手機手勢持續補證。 |
| M3-A | DONE（核心閉環與 UI 面板全量交付） | 2026-09-22 交付輪迴轉世規則、天賦系統與持久化；2026-09-24 交付 `reincarnation_panel.gd` 雙分頁互動 UI 面板；2026-09-27 對齊經典雙軌門檻、交付 3.4 秒轉生九界俯衝演出與壽盡直達橫幅。全量 25 項 Runner 通過。 |
| M3-B | IN_PROGRESS（丹藥 DONE、BUFF DONE、宗門 DONE） | 2026-09-26 第一彈完成丹藥與煉丹房；2026-09-27 第二彈完成 BUFF 增益系統；2026-09-28 第三彈完成宗門系統（拜入山門、五品質委託派遣、四大宗門真訣倍率、宗門坊市與自適應面板），全量 25 Runner 通過；天時、機緣、靈獸、成就後續推進。 |
| M4-A | DONE（全閉環交付） | 2026-09-27 交付第二界（靈界 · 天靈洞天）、三大據點（天樞陣眼、化靈仙池、虛空引靈台）、雙界並行模擬、靈石轉化極品靈晶、天青靈液全洞府反哺、跨界神遊傳送面板、遠景天標與全量 25 Runner 驗證（見 `docs/verification/m4-a.md`）。 |
| M4-B | TODO（下一個主線任務） | 九界法則資料擴充、正式地理尺度與遠界旅程（相依 M4-A 已達成） |
| M5-A/B | TODO | 按需生成、封存與逐界內容 |

<!-- 原狀態段落 37 -->
2026-09-24 M3-A 輪迴轉世與道心天賦 UI 面板：新增 `src/presentation/reincarnation_panel.gd`，提供雙分頁對比彈窗，支援世次概覽、資格狀態高亮、保底收益預覽、起手傳承試算、轉世入定送出與道心天賦（資源傳承、長生久視、先天道體）即時參悟升級。主場景 `src/abode/living_abode.gd` 接入工具列「輪迴天道」按鈕與直式 `more_menu` 選單，支援自適應 360 CSS px 窄螢幕排版，並於轉世完成後自動返回洞府近景與重載 HUD。新增 `tests/m3a_reincarnation_ui_runner.gd`（exit 0，面板開關、分頁切換、天賦購買扣除道心、築基資格高亮、入定轉世重置與起手資源發放全數 PASS）。全量 17 項 Runner 與 Web export 均通過。

<!-- 原狀態段落 38 -->
2026-09-22 M3-A 輪迴轉世機制閉環：擴充 `GameState` 跨世持久化欄位（`reincarnation_count`、`highest_era`、`dao_heart`、`dao_proof`、`talents`），並在 `SaveCodec` 實現向後相容解碼。新增 `src/simulation/reincarnation_rules.gd`，嚴格對齊唯讀來源黃金測資（建築等級總和 $B$、道心 $B/10$、保底 0/15/20/25、道證 $B/50$ 與 $B/30$、起始資源傳承比率 40%/80%）；新增 `src/simulation/talent_system.gd` 實現道心天賦購買（資源傳承、長生久視、先天道體）與全局產率/壽元倍率；`CommandProcessor` 接入 `reincarnate` 與 `learn_talent`；`TimeAdvancer` 接入天賦壽元與產率加成；`GameSession` 暴露輪迴預覽、便利命令與完整視圖。新增 `tests/m3a_reincarnation_runner.gd`（exit 0，黃金測資比對、資格門檻、狀態重置與傳承、天賦生效、存檔往返全數 PASS）。全量 15 項 Runner 與 Web export 均 exit 0。
