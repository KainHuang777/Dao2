# IMM-4 整批收尾（2026-10-28，L3）

> 同日後續複核：145支原始PASS與Web校驗已核實，但發現技能短式14px正文不符合最低16px；原記錄「鍵盤焦點依10/17延期」不成立（該指令僅延期觸控／實機），殘留亦無另行使用者核定。IMM-4-R1現已完成有界修正，原始L3結果保留；最新結果見[開發狀態](../development-status.md#imm-4-r1)。

範圍：docs43 的 IMM-4 收尾。對已完成批次 IMM-1A／1B／1C／3A／3B／3C 的整批介面做一次唯一 L3：全部 runner、全尺寸矩陣、正式 Web 同步與候選包、桌面瀏覽器三橫式真實滑鼠抽驗，並記錄 IMM-2 決定。本輪未改規則、存檔 schema、命令 payload、獎勵或既有禁用／送單語意。

## 一、整批結論

IMM-1A～3C 的靜態遷移、共用元件、成本列與庫存呈現已整批核對；L3 全矩陣首輪抓出的短式溢位（見第二節）已修正，最終 **145／145 runner PASS（matrix=full）**、Web 匯出與壓縮通過、桌面三橫式滑鼠抽驗可讀可操作。完整介面本輪結案；觸控／實機與慢網冷啟動依既有指令維持延期，非本輪阻擋。

## 二、L3 首輪抓出並修正的短式溢位（收尾修正）

首輪 L3（145 支、全矩陣）為 133 PASS／12 FAIL，失敗集中在 844×390 與 800×360：IMM-3A／3B 的圖像成本列與 IMM-1C 選島列只做過單尺寸驗收，短式容器高度不足。修正均為版面層，不放寬檢查。

- 共用：`cost_strip.gd` 新增 `set_compact(bool)`／`is_compact()`；`recipe_material_tile.gd` 新增 `cell`、`compact`、`set_compact(bool)`（36×36 格、28px 圖示、48 最小寬、3/2 邊距、隱藏 caption），無圖資源的 `refresh()` fallback 不再強制顯示 caption。
- `ui_shell_controller.gd`：工具覆層高度改為上緣 68 至工具列上緣，修正選島清單／存檔／除錯工具底板超出工具列。
- `alchemy_panel.gd`：煉丹列 `size.y<400` 進入 micro，成本格 compact、動作按鈕移入橫向列、隱藏非必要狀態列；卡片約 78～90，低於短式捲動區 132。
- `reincarnation_panel.gd`：天賦列 `<400` 時道心成本列 compact；`<380` 改顯示文字「道心：N」並隱藏圖像列，效果說明不隱藏。
- `sect_panel.gd`：功法 P1 卡於 `_compact`（<350）套 `strip.set_compact`、隱藏描述、縮圖 56、邊距 6/4；市場與 P2 短式不變。
- `skill_study_view.gd`：卡片 `compact`（<340）套成本列 compact、縮圖 56、邊距 6/4、字級 16/14/14；保留功法來源與完整累積倍率文字。
- `island_world.gd`／`island_selector.gd`：選島幾何改為無條件配置（不再沿用隱藏時的舊 rect）；compact 收合標題列／頁尾、列高 80、當前島置頂；窄式 640 寬的世界列改為可縮配置，按鈕維持 ≥44 且高於工具列。

測試端只修正「與設計不符的期望」與隔離問題，不降低驗收：`imm3c_page_consistency_runner.gd` 依 ShellPolicy 的 compact「summary」呈現調整短式期望、`_tiles_are_seals` 接受 compact 36px 格；`res1_ui1a_runner.gd` 在矩陣迴圈後把版面還原到 1280×720（原本後續 1280 檢查沿用 800×360 版面，屬測試隔離缺陷）。`world46`、`res1d2_world`、`content_p1/p2` UI 檢查條件未放寬。

## 三、逐頁總表（洞府＋十三功能頁＋五類覆層）

| 頁面／覆層 | 最終狀態 | 本輪確認 |
| --- | --- | --- |
| 洞府 | 已調整 | 大圖選島列、選中與清單內捲、短式選島面板與窄式世界列；安全區、歸家與 resize 正確（`world46` 92 檢查、`res1d2_world`、`imm1c` 全矩陣 PASS）。 |
| 洞府建築 | 已調整 | 建造／升級成本列圖像格、來源與缺料；短式卡片仍可完整捲入（`content_p1_buildings`、`imm3a`）。 |
| 空島（經營） | 已調整 | 地方庫存／祖島付款分組、設施與開拓成本列；付款格沿用共用圖示格且不重複 caption（`res1_ui1a`）。 |
| 製造 | 已調整 | 左欄庫存、材料／產物格、就地設定、加工坊成本列；短式輸出格 56px、數量右下對齊（`res1_ui1a`、`imm3a`、`imm3b`）。 |
| 運輸 | 已調整 | 兩端庫存／在途分開，升階成本只由成本列承載；短式詳情可讀（`content_p2_supply_ui`、`imm3c`）。 |
| 技能 | 已調整 | 技能點成本列；短式卡套 compact 成本列並保留來源與完整倍率（`content_p1_skills_ui`、`uix_r8`）。 |
| 煉丹 | 已調整 | 丹藥配方材料／產物圖示列；短式列進入 micro，卡片可完整顯示（`content_p2_pills_ui`、`imm3a`）。 |
| 靈獸 | 已調整 | 餵養材料圖示、缺料朱紅、獸魂獨立事實列；短式不新增裁切（`content_p2_beasts_ui`、`imm3b`）。 |
| 成就 | 沿用且已核對 | 直接徽章領取／領訖印與焦點狀態；無庫存主欄（`imm3c`）。 |
| 輪迴／天賦／歷世 | 已調整 | 天賦道心成本列；短式 compact／文字道心成本；歷世數值表與敘事維持閱讀形式（`content_p1_talents_ui`、`content_p2_talents_ui`、`m3a_reincarnation_ui`）。 |
| 九界 | 不適用（沿用） | 無共用庫存主欄；未開放入口與據點成本沿用既有呈現（`imm3c`、`realm_teleport` 相關 runner）。 |
| 宗門 | 已調整 | 參悟／兌換成本列（貢獻＋靈木／下品靈石）、P2 短式保留文字成本；短式卡片完整（`content_p1_sect_ui`、`uix_r9`）。 |
| 機緣 | 沿用且已核對 | 主頁原版；選項成本列與缺料註記，無成本選項不硬塞（`uix_r10`、`imm3b`）。 |
| 天道決策 | 已調整 | 法令成本列；壽元維持獨立標籤，不混入物品格（`uix_r11`）。 |
| 訊息 | 沿用且已核對 | 共用 CloseSeal／遮罩返回；短式面板高度受限、可捲動（見第六節殘留觀察）。 |
| 資源抽屜 | 已調整 | 島別分組圖示、選中詳情、focused 路由；短式可開關（蝴蝶三橫式實測）。 |
| 設定／存檔 | 沿用且已核對 | 工具覆層高度修正後不壓工具列；CloseSeal 44px（`ui_shell_*`）。 |
| 保存保護 | 沿用且已核對 | 保存失敗警示與固定重試；不新增自動重試（`ui_shell_*`）。 |
| 離線報告 | 不適用（沿用） | 離線結算屬敘事性摘要，不強制改圖示；短式完整顯示（三橫式實測）。 |

## 四、IMM-2 決定：不新增微動態工程

現有回饋已集中且足夠，記錄為「無新增需求」：

- 主題層：`ui_material.gd:213-239` 的 `populate_theme()` 已設定 Button 的 normal／hover／pressed／disabled／hover_pressed 與字色、LineEdit focus、下拉 hover、捲軸 grabber 狀態；`ui_typography.gd:48-55` 建立後由 `abode_hud_controller.gd:118` 套到整個 HUD，所有 `hud.add_child` 的覆層自動繼承。
- 狀態皮層：`ui_material.gd` 的 `surface`／`apply_jade_navigation`／`apply_scroll_button`／`mark_paper_tab`／`mark_selected`／`apply_button`（含金色 focus 環）覆蓋五態。
- 共用元件：`graphic_action.gd`（hover／focus 墨線、pressed 加粗、`reduced_motion` 抑制脈動）、`game_tab.gd`、`close_seal.gd`、`segment_chips.gd`、`dock_button.gd`、`inventory_item_cell.gd`、`building_card_button.gd`；十五頁與覆層均使用或繼承。
- 原始實作現況（2026-10-28 R1更正，無另行使用者接受）：(a) 覆層開關無 tween，依 docs43:29「不全面掃光／縮放／消融」；(b) 製造 `recipe_row.gd:68-100` 的 `recipe_badge`／`title` 為選取捷徑、無獨立 hover，同列動作／設定按鈕具完整回饋；(c) 純主題按鈕沿引擎的focus框；2026-10-17僅延期觸控／實機，桌面鍵盤未延期。R1核對既有框線並補正共用focus字色，結果以開發狀態R1段為準。

## 五、L3 驗收（唯一一次，全量）

命令：`tools\run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 1800`（matrix=full，145 runner，時間 11:51:43→12:20:37）。結果：**SELECTED 145 RUNNERS PASSED (matrix=full)**，每支皆為 `RUNNER_RESULT status=PASS exit=0`，輸出無 `SCRIPT ERROR:`；`docs/verification/artifacts` 與 `src/verification` 無內容變更（僅新增 7 個 `.import` sidecar，與 repo 既有慣例一致）。日誌：`C:\Users\asus\AppData\Local\Temp\dao2_runners_e101659f673444538a928a0a443f6582`。

最長：`content_p2_supply_progression` 1304.7s、`content_p2_pills_flow` 531.3s、`content_p2_beasts_flow` 359.7s、`content_p2_talents_flow` 324.0s、`content_p2_story_flow` 208.0s、`sks_p2_flow` 162.6s、`content_p1_accept` 125.8s、`offline_closed_form_parity` 105.6s。兩支長流程原本在預設／600 秒逾時，延長至 1800 秒後正常完成，屬已確認的長測試而非版面缺陷。

## 六、Web 匯出、壓縮與候選包

Godot 4.7.2.stable.official.ed1daf0bf，`--headless --path . --import` exit 0；`--export-release Web` 分別輸出 `build/web/index.html`（正式同步）與 `build/web-imm4/index.html`（候選包），皆 exit 0。`node tools\prepare_web_compression.mjs build/web`、`... build/web-imm4` 皆 exit 0，兩份報告一致：

| 檔案 | 原始 bytes | sha256 | br bytes |
| --- | --- | --- | --- |
| index.js | 279,815 | 33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba | 64,438 |
| index.wasm | 39,514,754 | fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0 | 7,996,785 |
| index.pck | 125,639,700 | f9ea0e553f4a2c0383fbe2fe5f6d756267d61aefa74f086f54b1dcedddca3e48 | 124,983,094 |

合計 br 133,044,317 bytes；`audio/bgm` 四首 mp3 由 `src/BGM` 逐位元複製（01 1,361,177／02 1,360,989／03 1,430,633／04 1,194,791 bytes）。`python tools\delivery_check.py --web build\web` 與 `--web build\web-imm4` 均 `[web] 7/7 files match compression.json`、`RESULT PASS`。

## 七、桌面瀏覽器三橫式（真實滑鼠）

環境：Edge `--guest`、獨立 profile `build/imm4-edge`、CDP 9243、`--window-size=1420,920`；本機 `127.0.0.1:4420/launcher`（wrapper 以 `build/web-imm4` 為 BUILD、Era3 隔離存檔為 fixture、namespace `dao2_saves`），`node --experimental-websocket` 以 CDP 真實 `Input.dispatchMouseEvent` 操作。尺寸以 `Emulation.setDeviceMetricsOverride`（deviceScaleFactor 1、mobile false）＋ iframe CSS 精確設定，實測：

- 1280×720：iframe (0,70,1280,720.4)，canvas 1279×720。
- 844×390：iframe 844×390，canvas 843×389。
- 800×360：iframe 800×360.4，canvas 799×360（DPR1 的 1px 取整，照實記錄）。

操作與結果（每項以操作前後截圖確認）：三尺寸皆以滑鼠點擊 經營 dock 開啟洞府建築／營造簿殼、點擊 資源 開啟資源抽屜、以 Escape 關閉；resize 後遊戲狀態保留、HUD 重排；啟動的離線收益摘要於 844（x14..530,y20..297）與 800（x14..497,y20..270）完整落在畫面內且關閉鈕可點。1280 殼顯示營造簿＋全部／生產／倉儲分頁與茅屋卡；短式殼隱藏分頁與「下一步」提示條（compact 呈現），茅屋卡與「材料不足／0/20」仍可讀。資源抽屜三尺寸均顯示靈氣／極品靈晶／天青靈液／道心／道證與數量欄。全程 console 無 ERROR／exception。

證據（gitignored `.test-output/imm4-web/`）：1280 `p12-01-world-1280.png`／`p12-02-shell-1280.png`／`p12-03-drawer-1280.png`；844 `p15-01-world-844.png`／`p15-02-shell-844.png`／`p15-03-drawer-844.png`，離線摘要 `p14-01-world-844.png`；800 `p15-04-world-800.png`／`p15-05-shell-800.png`／`p15-06-drawer-800.png`，離線摘要 `p14-04-world-800.png`；主控台紀錄 `console.jsonl`，幾何 `phase12/14/15*.json`。

人工版面判定：三橫式 HUD 可讀可操作、dock 44px 命中正常、無控制項硬裁切、覆層完整；短式殼隱藏分頁與下一步條屬既定 compact 呈現。

## 八、殘留與未驗證（照實記錄）

- 觸控／實機（含高 DPR、旋轉、GPU）依 2026-10-17 指令延期，非本輪阻擋；本輪僅桌面瀏覽器滑鼠。
- Web 慢網冷啟動預算依 2026-10-09 指令暫緩，本輪未量測。
- FPS 未另測：本輪變更為靜態版面與成本列尺寸，未新增持續動態；依效能驗收標準的針對性原則記錄，不宣稱 FPS 通過。既有 FPS 證據維持原日期。
- 短式「系統訊息·新手引導」面板高度受限且自動捲到最新行，只露出尾端約兩行（可捲動）；僅在即時改寬後出現一次換行寬度未更新，重新佈局或於該尺寸載入即正常。非本輪回歸，列為已知呈現限制。
- 844／800 的 canvas 為 843×389／799×360，為 DPR1 取整；未以 1.25 DPR 冒充整數尺寸。
- 本輪未宣稱 IndexedDB 落盤、音效播放或長期存檔相容；Web 只作桌面滑鼠與尺寸呈現證據。

## 九、結論

IMM-4 完成：唯一 L3 全量與全矩陣通過、正式 Web 與候選包同源輸出並通過壓縮校驗、桌面三橫式滑鼠抽驗完成、IMM-2 已記錄為無新增工程。此為原批次結案時點；其後字級／鍵盤焦點缺口已由IMM-4-R1有界補正，最新狀態見開發狀態R1段。觸控／實機延期，非當前阻擋。
