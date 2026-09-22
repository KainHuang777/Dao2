# M2-D 視覺、裝置與首切片驗收

狀態：IN_PROGRESS。AGY 已否決原先十地塊浮島方案；目前改成島上少量地標與 Godot 營造清單，CLI 驗證已通過，真實 Web 畫面與點擊待 AGY 重測。此檔是 M2-D 的實測證據，不得以規格、CLI runner 或桌面截圖取代。

規格依據：[響應式介面與 Web 畫布規格](../07-responsive-ui-web-spec.md)、[Roadmap M2-D](../../ROADMAP.md)。

## 實測紀錄

每次測試新增一列；需保留畫面紀錄或可重現步驟。未測以「待驗證」表示。

| 日期 | Build／commit | 裝置與瀏覽器 | CSS viewport／方向 | 輸入 | 通過項 | 未通過項或限制 | 證據 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 待驗證 | — | — | `1280×720` 橫式 | 滑鼠 | — | — | — |
| 待驗證 | — | — | `844×390` 橫式 | 觸控或模擬觸控 | — | — | — |
| 2026-09-20 | 待重新驗證 | AGY 瀏覽器 | 尺寸待記錄 | 點擊「聚氣引靈」 | — | 原版九界彈窗超出畫面，內容不能捲動且關閉控制不可用；已修正，待重測 | 使用者回報 |
| 2026-09-20 | 待重新驗證 | AGY 瀏覽器 | 多個畫面，尺寸待記錄 | 閱讀主 HUD 與次級介面 | — | 使用者回報文字極難辨識；已加粗字重、放大九界正文及提高面板對比，待重測 | 使用者回報 |
| 2026-09-20 | 待重新驗證 | AGY Chrome 截圖 | 約 `1920×910` 可視畫布，實際 CSS viewport 待量測 | 茅屋建造並升至 2 階 | — | 左上資源列撐出狀態面板並與縮放鍵重疊；待建資源建築以完整圖佔滿單島且部分延伸至崖邊。當時改成小型待建地基／重排十地塊；後續 AGY 圖像顯示仍不成立，已廢止此方案 | 使用者本輪截圖 |
| 2026-09-20 | 原十地塊方案已否決 | AGY Chrome 截圖 | 約 `1920×910` 可視畫布，實際 CSS viewport 待量測 | 茅屋 2 階後檢視木屋、聚靈壇與庫房 | 左上資源摘要不再撐破面板 | 小型加號與名稱牌缺少圖形化空地，部分貼到崖壁；已改為清單＋茅屋地標，待重測 | 使用者截圖 `codex-clipboard-390ab15f-9675-4035-92b7-ad63fb14249b.png` |
| 待驗證 | — | — | `360×640` 直式 | 觸控或模擬觸控 | — | — | — |
| 待驗證 | — | 指定實體手機 | 直式與橫式 | 單指、雙指 | — | — | — |

## 2026-09-20 CLI 與匯出結果

- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`：通過。
- `tools/test_runner.gd`、`tests/living_abode_runner.gd`、`tests/m2d_responsive_ui_runner.gd`、`tests/m2d_slice_release_runner.gd`：通過。
- `tests/m2d_responsive_ui_runner.gd` 已檢查 `1280×720` 寬式、`844×390` 緊湊橫式、`360×640` 直式，並以 `360×480` 短可視區驗證九界內容可捲動、固定關閉列不會被內容推離畫面。
- `--export-release Web build/web/index.html`：通過。

這些結果不涵蓋瀏覽器實際 CSS viewport、滑鼠命中、雙指縮放、虛擬鍵盤或實機幀時間。請以本檔的實測紀錄表補入 AGY 結果。

## 2026-09-20 文字可讀性修正

- 主 HUD 與建築底牌使用 Godot `FontVariation` 的 `wght` 600／700；字型仍由現有 Noto Serif TC 向量檔動態光柵化。已確認字型檔具有 `wght` 軸。
- 九界卡片將原先 12–13 的說明／狀態／操作字級提高至 16–18，增加換行與卡片高度；存檔和離線摘要加深色實底；突破畫面按直式可視區重排。
- `tests/m2d_responsive_ui_runner.gd`：`360×480` 九界內容可實際捲動，關閉列仍在畫面內；`360×640` 突破內容與關閉鈕在可視區內。`tests/m2b_breakthrough_runner.gd`：築基後直式從「更多」進入重溫，寬式保留原按鈕。
- Godot 4.7.2 `--import`、`tools/test_runner.gd`、`living_abode_runner.gd`、`m2b_breakthrough_runner.gd`、`m2c_nine_realms_runner.gd`、`m2d_responsive_ui_runner.gd`、`m2d_slice_release_runner.gd`、Web export 均 exit 0。字體實際辨識度仍待 AGY 瀏覽器／裝置觀察。
- 本機 Web 測試頁 `http://127.0.0.1:4175/index.html` 回應 HTTP 200；本輪瀏覽器視覺工具連續兩次回報 `trusted Node process exited unexpectedly`，未取得新截圖或真實點擊證據。
## 2026-09-20 資源與地塊畫面修正（已否決方案，保留歷史）

- `living_abode.gd`：左上資源改為一行靈氣摘要與「資源總覽」入口；完整可見資源列放在有固定關閉鈕和 `ScrollContainer` 的 Godot 面板。狀態面板依實際最小高度推開縮放列，短橫式空間不足時隱藏該列；十個地塊重排至草地上層。
- `abode_building.gd`：未建造地塊只繪製小型選取標記；建成後才顯示完整建築圖。名稱底牌保留 26 邏輯像素字級；收緊命中區並檢查十地塊全建成時互不重疊。這些圖仍有多棟重用臨時美術，獨立正式圖待後續美術任務。
- `tests/m2d_responsive_ui_runner.gd`：增加茅屋 2 階／七資源最壞情況下的摘要與縮放列間距、完整資源面板可開關、待建地塊可選／不顯示整棟圖、地塊範圍和全建成命中區不重疊，以及窄橫式／直式面板檢查。
- Godot 4.7.2 import、`tools/test_runner.gd`、`living_abode_runner.gd`、M2-A／M2-B／M2-C／M2-D responsive／M2-D slice runner 與 Web release export 均 exit 0；本機 `http://127.0.0.1:4175/index.html` 回應 HTTP 200。CLI 不能證明實際草地遮擋、CSS 字體清晰度或滑鼠／觸控命中。
- 這輪曾要求重測木屋／聚靈壇／靈石庫地基；AGY 後續截圖顯示這些抽象地基與文字牌不合地景，相關重測項已由下節的營造清單案例取代。

## 2026-09-20 營造清單與地標修訂（目前方案）

- 新增 `src/presentation/building_catalog.gd`；洞府新增「營造設施」入口，依核心／生產／倉儲分組顯示可管理建築、用途與等級／可建狀態。按列開既有詳情，建造／升級仍走同一 `GameSession` 命令。清單有固定關閉列與可捲動內容；直式使用可視範圍內的版面。
- `living_abode.gd` 不再顯示木屋、聚靈壇與其他一般設施的島面節點；未建造茅屋也從營造清單進入，建成後才在浮島出現。保留穩定建築 ID 與原存檔欄位；`GameSession.get_view()` 修正為突破到 Era 2 後仍保留先前建築的管理可見性。
- `tests/living_abode_runner.gd`、`m2a_abode_runner.gd`、`m2b_breakthrough_runner.gd`、`m2c_nine_realms_runner.gd`、`m2d_responsive_ui_runner.gd` 與 `m2d_slice_release_runner.gd` 已改驗營造入口、清單選取、重載、Era 2 延續、`360×640` 捲動及固定關閉列；Godot import 與七個相關 runner exit 0。Web release export exit 0。
- 嘗試用本機 headless Edge 擷取 Web 畫面，只取得 Godot 載入畫面，無法據此判定島面或清單在真實瀏覽器中的最終視覺。Codex CUA 啟動失敗（Windows sandbox helper）；AGY 實際滑鼠／觸控仍待測。
- AGY 重測：強制重新載入頁面；新檔開「營造」選茅屋、引氣並建造，確認茅屋建前無漂浮牌、建後在島上；升至 2 階後在清單找木屋、聚靈壇、靈石庫，開詳情並建造／升級；確認島面沒有這些設施的抽象地基或文字。以 `360×640` 再測清單捲動、固定收起與詳情切換；若已有築基存檔，確認先前建築仍可在清單管理。

## 每個案例的最低檢查

- 建築選取、詳情開關與目前可用的建造／升級動作。
- 世界拖曳、縮放、回到洞府，且 UI 輸入不穿透至世界。
- 底部導航、低特效與存檔入口可讀且可操作。
- 主 HUD、建築底牌、九界卡片、存檔、離線摘要及突破演出的繁中正文清楚可讀；無關鍵裁切、重疊或小於約 44×44 CSS px 的主要觸控區。
- 方向或瀏覽器可視高度變動後，抽屜與九界彈窗只有內容區可捲動，固定關閉控制保持可見且可點擊。

## 效能與放行

另記錄桌面／手機幀時間、冷啟動、下載量與 50 次視圖切換記憶體趨勢。未取得全部實機、互動與效能證據前，M2-D 保持 IN_PROGRESS。
