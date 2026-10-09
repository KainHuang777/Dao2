# M2-D-FX3-ART1 — 概念背景、島體與披風主角

2026-10-06，使用者插入任務。實作與本輪有界驗證 PASS；完整 FX3 維持 IN_PROGRESS，待使用者美術放行、高 DPR／實機與長觀測。

交付：以使用者 GPT 調整概念圖製作 scenery-only 背景，去除近景平台／階梯／人物；保留夕照、石像淚瀑、遠山與雲海。獨立透明島體保留既有布局與建築錨點，改善岩層、苔蘚、石台與暖光。新增覆頭遮臉、中性長披風角色，常態18顆靈氣光點向胸口收束，12.5Hz繪製上限；低特效停止更新。主角腳底 `(0,-85)`／胸口 `(0,-170)` 與法陣／光束／雷電共用中心。原有升境提交、保存重試與演出流程沿用，無新保存欄位或收益。

修改：`src/abode/living_abode.gd`、`src/presentation/island_breakthrough_fx.gd`、新增 `cloaked_cultivator.gd`／UID、`assets/abode/fx3art1/`（三項資產、Shader／UID、提示詞、hero透明化／QC資料）、`tests/island_breakthrough_runner.gd`、`tools/concept_art_preview.gd`／UID、本驗收與交接文件。開始前的 `.gitignore`、project／export設定及三份fixture dirty均保留，非本輪設計修改。

環境：Windows，Godot `4.7.2.stable.official.ed1daf0bf`，Compatibility，NVIDIA GTX1660Ti。內建瀏覽器 CSS 1280×720、844×390，後者canvas843×389、DPR約1；不是實體手機。

命令與結果：

- `Godot --version`：4.7.2確認。
- built-in `image_gen` 三次；提示詞見資產目錄。generate2dsprite `process --target player --mode single --rows 1 --cols 1 --cell-size 512 --single-size 512 --fit-scale 0.84 --align feet --component-mode largest --strict-qc`：exit0，無空格、邊緣碰觸或paste clamp。
- `Godot --headless --path . --editor --import`：exit0；初次sandbox環境報user目錄不可開啟，未發現GDScript parse錯誤。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`：在獲准的user測試目錄下54/54、exit0。初次sandbox執行在test_runner因user://無寫入權限失敗，未視為通過。
- 最後新增共用錨點／低特效契約與停止低特效重繪後：`Godot --headless --path . --script res://tests/island_breakthrough_runner.gd` exit0，正式升境、保存失敗／重試、零狀態重播、跳過、四版型、角色存在／共用錨點／冻结時鐘均PASS。全量54項結果在此最後小修改前；最後針對性回歸通過。
- `Godot --path . --script res://tools/concept_art_preview.gd`：隔離user://concept_art_review_20261006，exit0；兩尺寸idle／tribulation PNG，完整快照未改。原生844×390受既有畫面缩放策略影響logical779×360，有界原生證據，不冒稱browser CSS尺寸。
- `Godot --headless --path . --export-release Web build/fx3art1-web/index.html`、bundled Node `tools/prepare_web_compression.mjs build/fx3art1-web`：exit0，獨立Web包與BGM companions。
- bundled Python `tools/web_static_server.py --port 4267 --directory build/fx3art1-web`：本機review服務。4266 sandbox服務不可由browser連線，不作成功證據。

真實瀏覽器滑鼠：關閉離線摘要／收起引導；設定→引擎特效試播→重播→返回；兩橫式均呈現新背景、透明島體、角色與收束雷電；844×390設定→低特效開→試播，角色保留、無雷電動效。截圖：`artifacts/fx3art1/web-idle-*`、`web-climax-*`、`web-reduced-*`。試播不升境；正式升境正確性由既有CLI整合驗證，未在本輪browser跑正常完整升境鏈。

限制：程序退出仍有FontAdvanced／CanvasItem／ObjectDB釋放警告（全量已有同類），exit0不等同無警告或長期記憶體放行。新圖增加下載資產，未重跑20Mbps／100ms啟動或ADR-010 FPS長觀測；舊版效能PASS不能直接轉用。使用者美術、實機觸控、高DPR與後續Era美術仍待驗。來源／用途／切層與商用權利限制見assets README。

下一步：使用者審閱夕照色調、島體質感、主角大小與神秘感；New Chat按回饋微調或補新資產效能驗證。完整RES1／FX3既有缺口保持原狀。
