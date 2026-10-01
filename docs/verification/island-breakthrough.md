# 空島境界突破演出 — AGY 驗收交接

## 2026-09-28 淚佛背景 v6 構圖修正

本節為目前背景版本。`living_abode.gd` 載入 `assets/abode/sky_tearfall_island_v6.png`；佛首移至畫面約 39% 寬，左側以重新繪製的雲海／遠山填滿。背景取景不越界平移，不會 clamp 拉伸邊緣像素。瀑布 shader 遮罩依新眼下水路移位，窄版焦點置中取景。原 v5 保留於來源庫但由 Web Release 排除。生成來源、提示詞與雜湊見 `docs/abode-art/sky-tearfall-island-v6.md`。

Godot 匯入、M2-D 響應式 Runner、全量 25 Runner 及 Web Release 均通過。遊戲內真實瀏覽器合成畫面仍待複核；先前 Computer Use 啟動受 `helper_unknown_error: setup refresh had errors` 阻擋。

瀏覽器恢復後，以目前常態「營造」版型檢查左側沒有拉伸／接縫、佛首位於兩側 HUD 間的可視區；另核對 844×390、360×640 版型、低特效瀑布與「更多功能→重溫突破」。

## 2026-09-27 新參考圖整合 v5 歷史補記

此節是 v6 之前的歷史驗收。依使用者提供的 GPT 修正近景圖，v5 曾加入雙眼下瀑簾與承水平台；2026-09-28 已由 v6 重新構圖取代。資產、提示詞與授權記錄見 `docs/abode-art/sky-tearfall-island-v5.md`。v5 保留來源但從 Release 排除。

Godot 4.7.2 import exit 0；`tests/island_breakthrough_runner.gd` exit 0 且 PASS；Web Release export exit 0。生成圖已目視檢查；本轮真實 Web 動態／畫質與裝置觀感待 AGY。

以原測試 origin Ctrl+F5。先檢查眼下瀑簾→承水平台→多級寬瀑是否符合使用者新參考，佛首仍為遠處独立空島；再重播突破並檢查標準／低特效，以及横式／直式的水路辨識度。

## 2026-09-27 淚瀑 v4 最新補記

本節優先於下方 v3／v1 美術描述。使用者指出 v3 雖保留較寬瀑簾與獨立空島，卻取消了石佛流淚設定；當前場景已改用 `assets/abode/sky_tearfall_island_v4.png`，恢復雙眼角可察覺的流水，沿風化臉頰與石縫匯入平台和較寬瀑簾。Shader 增加低幅臉頰水流，雕刻眼睛保持静止；低特效停止局部動態。來源、切層、授權及提示詞見 `docs/abode-art/sky-tearfall-island-v4.md`。v1／v3 資產保留且從 Release 排除。

本次 Godot 4.7.2 import、`tests/island_breakthrough_runner.gd`、Web Release export 均 exit 0，runner 有 PASS。生成圖已目視檢查；真实 Web 動態與裝置觀感仍待驗收。

AGY 以原測試 origin 按 Ctrl+F5。檢查兩眼水源、臉頰水路与寬瀑之間有連結，石佛仍為遠方獨立空島、年代與破敗感保留；再以「更多功能→重溫突破」核對新遠景與法陣的搭配。觀察是否兼顧「遠看自然瀑布、細看石佛流淚」；横式與直式、低特效均需視覺檢查。

## 2026-10-02 M2-B-FX2 — 金環／雷電強度回饋

狀態 IN_PROGRESS，CLI、原生圖像與匯出完成，使用者視覺與 Web／手機動態效能待驗。此節覆蓋歷史「柔和弧光」描述；舊验收仍保留其日期，不當作本次效果已放行。

使用者指出升 ERA 光環與雷電過弱，提供渡劫參考圖。檢查舊程式：只有 attained 布林、三圈細線與兩道平滑弧光，沒有依 ERA 分級；重溫入口亦固定練氣→築基名稱。因此不是高境界會自動更華麗的既有設計。

本輪原創世界座標繪圖：金環增加多層柔光、白金核心及原創幾何符印；上環改至世界 y=-590，光柱頂部由 -1050 改 -700，避免主光效伸出既有演出取景。加寬光柱、前景不規則分岔雷電與光點，慢速連續變形、不使用逐幀 RNG 或全屏頻閃。日常淡金環仍輕量，低特效維持一秒柔和法陣，不畫雷電／光柱／碎岩／光點。沒有複製參考圖像、字樣或人物，也未新增圖形資產。

| ERA | 主雷電 | 法陣圈數（每組） | 光點 | 光暈係數 |
| --- | --- | --- | --- | --- |
| 2–3 | 3 | 4 | 48 | 1.00 |
| 4–6 | 4 | 5 | 60 | 1.18 |
| 7–9 | 5 | 6 | 72 | 1.36 |
| 10–12 | 6 | 7 | 84 | 1.54 |

各雷電另含三條短分枝，最高繪製預算有上限。此為純視覺分級，並非新增渡劫判定／獎懲或承諾高 ERA 遊戲內容已全部完成。

修改：`src/presentation/island_breakthrough_fx.gd` 的 set_era／visual_profile 與繪圖；`breakthrough_sequence.gd` play 增加相容的預設 target_era_id，內部重播保留目標；`living_abode.gd` 成功結果傳真實 ERA，重溫依當前 ERA／前境名稱；`tests/island_breakthrough_runner.gd` 補分級上限、重播目標及不改快照；新增 `tools/breakthrough_fx_preview.gd`，使用隔離資料只播呈現 fixture。

本機 Godot 4.7.2.stable.official.ed1daf0bf：

- `--headless --path . --script res://tests/island_breakthrough_runner.gd --quit-after 600` PASS exit 0；真实命令先提交、保存失敗重試、跳過、重播、鏡頭恢復、低特效、失焦及四版型等既有案例仍通過。
- `powershell -NoProfile -File tools/run_all_runners.ps1`：34/34 PASS exit 0，log `artifacts/breakthrough-fx2/runners.log`。
- `--headless --path . --script res://tests/abode_presentation_parity_runner.gd`：PASS exit 0，`parity.log`。
- `--path . --script res://tools/breakthrough_fx_preview.gd --quit-after 600`：exit 0，原生 NVIDIA 1660 Ti；八張 ERA2／8／12／低特效截图，1280×720 與 844×390。已檢查築基、高階與低特效畫面。初次短橫向 fixture 錯把實體 844×390 當邏輯視口，造成 skip 裁切；改用 root.get_visible_rect() 的實際 779×360 重新出圖，最終按鈕完整。`capture.log` 記錄物理／邏輯大小。
- `--headless --path . --export-release Web build/web/index.html`：exit 0，`export.log`。最後微調雷電不規則路徑後重新原生出圖及匯出，編譯／繪圖正常。

初次 rg Windows glob 與來源路徑讀取失敗已改讀正確 presentation 路徑。既有 Font RID、CanvasItem、ObjectDB/resource in use 退出訊息仍存在；沒有捏造零警告或 FPS。CLI／native 渲染不能證明 Web 點擊、DPR、手機 GPU 動態效能；真實瀏覽器工具尚無可用證據。請以既有隔離測試檔「更多功能→重溫突破」檢查強度／遮擋、跳過／關閉、低特效及高 ERA 動畫預算，先取得視覺回饋再擴充其他大型效果。

## 2026-09-27 遠景 v3 最新補記

本節優先於下方 v1 美術描述，歷史命令與結果保留。當前場景使用 `assets/abode/sky_ruin_island_v3.png`；圖與提示詞／授權見 `docs/abode-art/sky-ruin-island-v3.md`。佛首為獨立遠景空島，斷裂島底與雲海間隙可見；寬瀑簾由不同高度的島緣／平台落下，眼部沒有成對水柱或發亮動畫。Shader 改為三段寬瀑遮罩、直式取景焦點 0.215；突破結果文字保留遺跡伏筆而不直接稱淚瀑。v1 遠景保留來源檔並從 Release 排除。

本次實測 Godot 4.7.2 `--headless --path . --import` exit 0；`tests/island_breakthrough_runner.gd` exit 0 且 PASS；`--export-release Web ./build/web/index.html` exit 0；本輪來源檔 `git diff --check` exit 0。生成圖已目視檢查；沒有以 headless 檢查替代真實瀑布動態／GPU 或觸控驗收。

AGY 使用原本測試 origin 按 Ctrl+F5。先檢查遠景佛首是獨立懸島、三段瀑布有較寬水量而非眼淚線條，再以「更多功能→重溫突破」檢查新背景與突破光效的搭配。横式及直式均檢查佛首島身與主瀑是否自然、沒有夸張眼部高光；低特效仍須停止瀑布局部動態。其餘突破／跳過／保存驗收沿用下方操作單。

日期：2026-09-27 實作，2026-09-28 驗收通過。任務：M2-B 演出擴充／M2-D 美術接入。
狀態：DONE。2026-09-28 排除 WebGL Shader 溢出與相機抖動導致的背景閃爍後，經使用者於真實瀏覽器環境（固定 origin http://127.0.0.1:4175）完成遠景佛首、Shader 瀑布動態、低特效純淨穩定與突破演出實測驗收，確認全數通過。

## 已交付

- 維持既有正式 `level_up_cultivation`、`breakthrough_era` 命令及容量門檻；目前內容支援練氣→築基，沒有新增後續境界公式。
- 成功升境與保存先於演出；5.6 秒空島法陣、靈光、柔和弧光、碎岩、金色光點與雲海波環由獨立 Node2D 圖層繪製。這是升境靈氣異象，沒有加入金丹渡劫判定。
- 石佛流淚瀑布／懸山作為常駐遠景；瀑布局部 Shader 流動，背景依視窗比例調整焦點，直式仍保留佛首。島、茅屋與靈木保持既有獨立 Godot 物件。
- 演出暫收 HUD，世界輸入鎖定；關閉或失去前景焦點後恢復鏡頭／HUD。跳過顯示結果，重播只播放畫面；築基後保留淡金法陣，輪迴返回練氣則撤下。
- 低特效改為 1 秒柔和法陣，不畫光柱、碎岩、弧光與光點；背景瀑布不動。演出不持有 GameState、不讀玩法 RNG、不發放收益。
- 保存失敗保留已提交的當前境界，明示未保存並提供「重試保存」；重試與自動保存只寫既有狀態，不再執行突破命令。未增加存檔欄位或 schema。

## 本輪修改檔案

`src/abode/living_abode.gd`、`src/abode/abode_camera.gd`、`src/presentation/breakthrough_sequence.gd`、`src/presentation/island_breakthrough_fx.gd`、`assets/abode/sky_tearfall_v1.png`、`assets/abode/tearfall_sky.gdshader`、`tests/island_breakthrough_runner.gd`、`tools/run_all_runners.ps1`、本驗收表、`docs/abode-art/sky-tearfall-v1.md` 與提示詞、`docs/development-status.md`。既有 AGY 煉丹／DEBUG／核心檔案變更保留。

## 實際 CLI 證據

固定引擎：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，版本 `4.7.2.stable.official.ed1daf0bf`。

以下 `--headless --path . --script res://...` 均 exit 0 且有 PASS：

- `tests/m2b_breakthrough_runner.gd`：修煉、容量與库存區分、升境、重播、保存／重載。
- `tests/island_breakthrough_runner.gd`：真正主場景突破命令、保存失敗重試、完整快照在重播／跳過後不變、鏡頭與輸入恢復、低特效、四種版型、重載後持續法陣。
- `tests/m2d_responsive_ui_runner.gd`：管理介面與突破關閉控制邊界。
- `tests/m2d_slice_release_runner.gd`：首切片全流程與 50 次切換；本輪記憶體觀察增量 338.54 KB，這不是瀏覽器 GPU／實機效能證據。
- `tests/m2a_abode_runner.gd`、`tests/m2c_nine_realms_runner.gd`：空白開局與九界既有流程回歸。

`--export-release Web ./build/web/index.html` exit 0，包含新背景、Shader 與特效腳本。匯出時掃描／编譯沒有 SCRIPT ERROR。

初次匯入曾出現新增腳本的註解語法與浮點推斷錯誤；已修正並由上述 runner／Release 編譯重驗。Headless 結束仍回報 Font／CanvasItem／ObjectDB 資源未釋放訊息，未把它稱為零警告或長期無洩漏。整個工作樹 `git diff --check` 因既有 AGY 修改 `src/domain/game_state.gd:80` 的 EOF 空白行 exit 1；本輪修改檔案另行檢查。

## AGY 驗收步驟

1. 使用最新 `build/web`，以原本測試 origin 強制重新整理（Ctrl+F5）；確認遠景已出現石佛雙眼淚瀑。請用隔離測試存檔，不覆蓋玩家進度。
2. 在測試檔達到練氣十層與靈氣容量至少 500。可用既有 DEBUG 提升至十層；容量仍由建築提供，DEBUG 不會自動免除正式容量條件。不足時按鈕應提示容量，不能播放成功演出。
3. 點「突破至築基期」：境界先變築基一層；演出中 HUD 暫收，島下金環、島心靈光、周圍光點／碎岩與雲海波環依序出現，佛首仍為遠景。
4. 約 5.6 秒出現結果卡，點「圓滿出關」恢復原視角／管理狀態；點「更多功能→重溫突破」可重播。核對重播未再改境界／扣庫存。
5. 演出中點「跳過演出」，應直接進結果卡；Esc 或切到背景分頁應解開演出鎖。返回後世界拖曳、縮放、建築點擊與營造清單可用。
6. 「更多功能→低特效」後重播：不出現移動雷光／碎岩／光點，約 1 秒顯示結果；升境與產出一致。
7. 重載：仍為築基、保留淡金環、不強制再播。檢查存檔成功提示與實際 IndexedDB 重載結果一致。
8. 分別在 `1280×720`、`844×390`、`360×640`、`360×480` 檢查法陣、島身、石佛、跳過、結果卡與關閉／重播按鈕；記錄實際 CSS viewport／DPR、視覺截圖、滑鼠／觸控命中。

## 2026-09-28 實測驗收結果
- **測試環境**：Chrome / Edge，固定本地 Origin `http://127.0.0.1:4175`，最新 Web Release build。
- **測試項目與結論**：
  1. 遠景佛首為獨立懸空空島，三段瀑布水路連貫自然，無突兀眼部高光。
  2. 瀑布 Shader 流動自然，背景全螢幕無頻閃與撕裂。
  3. 切換「低特效」模式後，背景天幕維持高穩定性，水流動態乾淨停止。
  4. 突破演出各階段運鏡、法陣、跳過與重溫功能正常，重載存檔後金環保留。
  5. 驗收結論：**PASS / 放行**。
