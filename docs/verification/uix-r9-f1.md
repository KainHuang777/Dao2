# UIX-R9-F1 — 宗門委託圖像減字

2026-10-17。依使用者三項回饋實作；本輪來源、CLI、原生與桌面Web交付完成，R9整體美術仍待使用者接受。

## 修改

- `src/presentation/sect_panel.gd`：22px品階寶石白／綠／藍／紫／金，名稱後直接`120s`；品階名／任務敘述留TIP。任務卡移除常駐長說明及「預期獎勵」字樣，獎勵用28px圖示＋數字，可依容器寬換行。已派遣任務沿相同品階與獎勵呈現。
- 貢獻頁首與獎勵共用令牌圖；金錢／下品靈石／靈草／玄銅復用現有手繪圖。無專圖的頓悟靈光保留文字；未知資源保留名稱／數字，不漏獎勵。
- 派遣改無框飛劍圖片Button，56×56命中；hover提亮、按下變色、忙碌禁用壓暗，保留操作TIP、鍵盤焦點及原Session信號。數值倒數不重建按鈕。保留領獎／保存重試動作。
- 收起已入宗的重複介紹與空閒狀態卡，固定分頁／貢獻、內容內捲與卷軸安全區保持。
- 三張原創獨立SVG記錄於[manifest](../../assets/ui/icons/sect-manifest.json)，使用者設計要求作為design brief保存；沒有使用ImageGen或複製第三方圖，圖內沒有文字。Godot獨立渲染數值及輸入。
- `tests/uix_r9_sect_ui_runner.gd`改以圖片動作派遣並確認每任務對應操作，保留真實結算／拒寫恢復不重扣與三尺寸幾何回歸；`tools/uix_r9f1_preview.gd`產出本輪24張圖。共用規範19、README／ROADMAP／handoff／status及英文updata同步。

## 命令與結果

於專案根執行。CLI／原生APPDATA隔離在`build/uix-r9-f1-tests`，現有玩家進度未覆寫。證據目錄為[artifacts/uix-r9-f1](artifacts/uix-r9-f1)。

- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：`4.7.2.stable.official.ed1daf0bf`。
- 同引擎`--headless --path . --import`：exit0。
- 同引擎`--headless --path . --script res://tests/<runner>.gd`：`uix_r9_sect_ui_runner` **166 checks failed=false、exit0**；`m3b_sect_ui_runner`、`feature_navigation_runner`、`m2d_responsive_ui_runner`均exit0。日誌以runner名稱保存。
- 同引擎非headless `--path . --script res://tools/uix_r9f1_preview.gd`：exit0、三橫式各8狀態，共24PNG。檢查委託獎勵橫排／換行、派遣圖、三尺寸及活動／待領狀態；[寬式](artifacts/uix-r9-f1/tasks-1280x720.png)、[最小橫式](artifacts/uix-r9-f1/tasks-800x360.png)。
- `python tools/subset_game_fonts.py`及`--check`：最後皆exit0。
- 同引擎`--headless --path . --export-release R9Acceptance build/r9-acceptance/index.html`、`--export-release Web build/web/index.html`：皆exit0；每版接`node tools/prepare_web_compression.mjs <build-dir>`皆exit0。
- `python tools/uix_r9_server.py --port 48781`：本機隔離服務。IAB初次沙箱服務逾時，停止自有服務後主機層同命令啟動；新分頁正常載入。`127.0.0.1`與`localhost`為不同隔離origin，皆明示`?r9funded=1`之Era2／1000貢獻／5s委託fixture，不作自然進程證據。
- 真實桌面Web 1280×720：圖示／秒數／無框飛劍已見；滑鼠點派遣→顯示派遣中5s→完成待領→領取獎勵，貢獻1000→1080。另一隔離origin在844×390檢查固定分頁與內捲完整圖卡，800×360實際點飛劍、捲動到領獎並領取，貢獻亦1000→1080。截圖可見於本輪工具結果，未另存瀏覽器PNG；原生PNG為fixture渲染，不冒充瀏覽器證據。CSS尺寸與畫布有1px取整差，精確尺寸由原生圖補證。

## 失敗與邊界

- 首輪獎勵Label被通用自動換行縮為直排，最小橫式末項可見檢查失敗；獎勵數值保持自然寬度、僅整組獎勵在HFlow換行，收重複文字後166檢查通過。初輪日誌保留。
- 第一次字型重建與原生預覽同時占用TTF，`Invalid argument`失敗；待預覽退出後依序重建／check／匯出成功，保留fonts.log。
- 既有Font RID／CanvasItem／ObjectDB退出診斷仍存在，exit0不代表日誌無error。沒有重跑全量Runner；本輪執行上述四項相關回歸。
- 初次逾時分頁轉為data URL錯誤頁，被Browser Use URL policy拒絕操作；未繞過限制。停止沙箱服務、主機層啟動後以新正常URL分頁完成驗收。
- 本輪未新增保存schema或更動數值／RNG／收益規則。觸控／實機依核定延期，非目前阻擋。未commit/push，既有dirty成果保留。

本階段停止；下一New Chat收R9外觀回饋，再依使用者指示接R10，不於本輪開始下個大型任務。

收尾：UTF-8／本頁本地連結／SVG manifest引用／24PNG數量核對PASS，`git diff --check` exit0（既有LF／CRLF提示）。自有48781伺服器Ctrl+C停止（exit1為刻意終止），正常驗收分頁關閉、viewport reset。

web PCK SHA256: `D8B7C0A3EBC3972DA59A24A2A233FBE6448049F455FCD67B382A729D0D320CBC`。

r9-acceptance PCK SHA256: `CB02FD3C3342EC3B401BB0FDE945874A28AB16E2DC1C79E5CA5459EE59D015A6`。
