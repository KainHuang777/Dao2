# HUD-F1-PROGRESSION-LIFE — 2026-10-17

使用者回饋已完成桌面範圍修正。本項插入美術排程之前；R8／R9美術接受狀態與 R10→R11→RES1-E-SKILLS-PLAN 尾階段順序不變。

## 原因與結果

原本 `can_level_up` 同時要求修練與材料，HUD又用該欄位控制按鈕可見性。五層修滿仍缺下品靈石時，按鈕會等生產補足才出現，並非額外十五秒冷卻。另外四捨五入可能在實際尚未修滿時提前顯示105/105。

現在 View 分開提供 `training_complete` 和 `level_up_missing_resources`。修滿立即顯示入口；缺料時顯示「晉階 · 缺料」且禁用，TIP列出所有持有／需求，寬式境界列另顯第一個缺料。普通時間推進補足即啟用；沿用命令核心的1e-6容差。未修滿以向下取整顯示，完整需求向上取整，避免提前滿格。晉階成本、修練時間、存檔版本及壽盡規則保持原值。

壽元改成已用／上限，從0累計，80/80表示壽盡。依原始秒數判定，文字與沙漏圖示同步：

|已用比例|顏色|
|---|---|
|低於1/3|綠 #39734d|
|至少1/3、低於2/3|黃 #907000|
|至少2/3、低於90%|橙 #b45a18|
|至少90%，含壽盡|紅 #b43832|

整數年數向下取整並限於上限，79.99不提前顯示80/80；TIP補精確已用／剩餘。延壽保留累計已用並按新上限重算顏色。短橫式修滿後由動作文字表達狀態，境界列保留層數、完整缺料放TIP，確保資源列空間與44px動作。

## 修改檔案

- `src/application/game_session.gd`：View修滿與缺料。
- `src/presentation/abode_hud_controller.gd`：晉階可見／禁用、訓練數字、累計壽元、配色與密度重排。
- `tests/hud_readiness_life_runner.gd`、`tools/run_all_runners.ps1`：57專項與固定清單新增為71個。
- `tools/hud_readiness_life_preview.gd`：三尺寸、七狀態原生圖。
- `src/verification/hud_readiness_acceptance.gd/.tscn`、`project.godot`、`export_presets.cfg`：隔離驗收入口與專用匯出。
- `tools/hud_readiness_server.py`：loopback限定驗收服務。
- README／ROADMAP／handoff／status／07／19／updata：狀態與規範。

## 命令與證據

Godot `4.7.2.stable.official.ed1daf0bf` 已驗證，測試APPDATA為build內隔離資料，未操作玩家進度。引擎路徑 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`。

- `--headless --path . --editor --quit`：import exit0。
- `--headless --path . --script tests/hud_readiness_life_runner.gd`：最終57 checks failed=false、exit0。涵蓋部分秒不假滿、缺料可見禁用、真正命令容差、正常advance_time補足即啟用、按鈕升五→六、配色邊界／延壽及三尺寸幾何。
- `tools/run_all_runners.ps1`：初輪前40成功，第41煉丹UI資源列高度失敗；修正短式rank密度後，從該項跑至最後31項全部exit0，終端明示 `REMAINDER_PASSED=31 EXIT=0`。該續跑只有終端輸出，沒有完整原始log；不得描述成一次不中斷的71通過。最後另外重跑HUD本項、uix_r2、m2d responsive、feature_navigation、m3b_alchemy五項，均exit0，原始log保留。
- `--path . --script tools/hud_readiness_life_preview.gd`：最終21PNG，1280×720／844×390／800×360，exit0。紅色短式圖已視覺檢查。
- `--headless --path . --export-release HudReadinessAcceptance build/hud-readiness-acceptance/index.html` 與一般 `Web build/web/index.html`：最終兩版exit0；`tools/prepare_web_compression.mjs`兩目錄壓縮／音樂companions成功。
- `python tools/subset_game_fonts.py --check`：exit0，未因本項重建字型。

初期測試呼叫不存在的session API導致等待，手動終止exit1後改成正式submit；第二次fixture缺倉庫導致三項失敗，補正fixture後通過，未放寬正式規則。上述初次log保留。退出Font／CanvasItem／ObjectDB／resource診斷和既有anchor警告仍存在，不宣稱零錯誤log。

## 真實桌面Web

`python tools/hud_readiness_server.py --port 48810` 僅服務127.0.0.1隔離origin，使用專用level5／stone38／礦1 fixture。實際看到功滿且「晉階 · 缺料」，普通生產至stone40後變成「修為晉階」，滑鼠點擊升至六層；重載仍六層。最初保存名為web-full-shortage的圖實際已補足，已更名web-ready-before-click，不宣稱有Web禁用點擊證據（CLI另驗禁用）。最終包重新啟動服務排除prewarm舊快取，重載六層通過。

同一頁 `?life=yellow|orange|red|expired` 僅覆寫View，未改存檔；1280黃色26/80、橙色53/80、844紅色72/80、800壽盡80/80與禁用入口均已視覺核對。整數26／53是向下取整，顏色依精確比例。CSS請求1280×720／844×390／800×360，canvas觀察比CSS小1px；精確尺寸由原生PNG另驗，不混稱同一證據。最終warn/error查詢為空。自身頁已關閉、viewport已重設；自身服務以Ctrl+C停止（預期exit1）。

## 匯出SHA256

一般Web PCK：`6C08A0BE022591C27B7811A5C33F96275134968AD0B4A0695A3EF02819C681DB`。

驗收PCK：`B78CE21FCC5688072CE1810DA48FE4167CF530856BBF698EB6FD4025E544D261`。

原始log及圖片在 [artifacts](artifacts/hud-readiness-life-r1)。未commit/push，保留既有工作區修改。下一New Chat收本項畫面回饋，再依核定序列接R10；本輪不展開下一大型美術任務。
