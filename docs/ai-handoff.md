# 給下一位 AI 的開發交接

更新：2026-09-13。適用 GPT-5.6、OpenCode、Codex 或其他可讀寫檔案與執行 CLI 的工具；不要求付費外掛或本次對話上下文。

## 閱讀與恢復工作

1. 根目錄 `AGENTS.md`：開發約束。
2. `ROADMAP.md`：產品目的、任務 ID、相依與完成定義。
3. `docs/development-status.md`：實際進度與證據，找到當前未完成工作。
4. 按任務讀 docs/02 技術架構、docs/00 舊規則來源；美術任務讀 docs/04、06。
5. 涉及世界場景、HUD、輸入、畫面尺寸、Web shell 或 Web 匯出時，閱讀 `docs/07-responsive-ui-web-spec.md`；它規定 `1280×720` 構圖基準、Godot 響應式版型與瀏覽器證據，不可用固定畫布取代適配。
6. 涉及新建築、修行境界（Era）擴充、島面與可布置空間時，閱讀 `docs/08-building-presentation-and-era-expansion.md`；多數建築進營造清單，只有有圖形化地基與獨立美術的少數地標可進世界場景。

如果工具不自動讀 AGENTS.md，請在首個提示明確要求閱讀。歷史文件 docs/03 保留初期推理與案例，開發順序以根目錄 Roadmap 為準。不要因舊文有「下一步建立環境」而重裝。

## 實際路徑與現有檔案

| 路徑 | 已有用途 |
| --- | --- |
| `project.godot`、`export_presets.cfg` | 已鎖定環境；主場景 living_abode；Web 單執行緒 |
| `scenes/living_abode.tscn` | Node2D 啟動場景，運行時建構地形、建築、鏡頭和 HUD |
| `src/abode/living_abode.gd` | 現有組裝、HUD、展示 state 協調；正式接入時逐步拆分 |
| `src/abode/abode_state.gd` | 純展示經濟，尚用 float、無持久化、無正式離線 |
| `src/abode/abode_camera.gd` | 平移、滑鼠／觸控縮放、HUD 排除、遠近景；待完整手勢驗收 |
| `src/abode/abode_building.gd` | 獨立 sprite、命中區、標籤、選取及升級特效 |
| `src/abode/abode_flows.gd` | 飛劍與靈氣的程式動畫；不發放資源 |
| `assets/abode/` | terrain、sky、hut、garden、altar、sword 分層圖片 |
| `assets/fonts/NotoSerifTC-VF.ttf` | 繁中字型；文字不可烘焙在底圖上 |
| `docs/abode-art/` | 生成提示詞、原始與處理紀錄，非正式遊戲模組 |
| `scenes/web_probe.tscn`、`src/presentation/web_probe.gd` | 舊計數探針；`user://web_probe_state.json`；與洞府不同存檔契約 |
| `tools/test_runner.gd` | 基本 JSON／user 儲存與字型探針 |
| `tests/abode_state_runner.gd` | 展示產率、升級、藥圃停止測試 |
| `tests/living_abode_runner.gd` | 直接呼叫場景選取／升級／停產／鏡頭函式，非真實輸入 E2E |
| `docs/visual-prototype/` | 早期 HTML 視覺提案，不能作為正式遊戲核心 |
| `src/效果圖/` | 現有參考圖，勿任意刪除；待從 release 打包排除 |
| `build/`、`.godot/` | 匯出與快取，可重建；修改來源後重新生成 |

舊來源 `E:\Python\test1`、塔防參考 `E:\WORK\GodTower` 僅供讀取。其他機器沒有這些路徑時，可先做不依賴來源的驗收；公式 fixture 任務應報缺來源，不從記憶或圖片猜公式。

## 可重跑命令（目前已存在的入口）

以下在 Windows PowerShell 執行。每一步確認退出碼；這些命令列於文件不表示本輪全部重跑。非 Windows 接手者需提供同版本當地 Godot 執行檔與模板，保留來源專案設定。

```powershell
Set-Location 'E:\WORK\Dao2'
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
if ($LASTEXITCODE -ne 0) { throw 'Godot version check failed' }
& $daoEngine --headless --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
& $daoEngine --headless --path . --script res://tools/test_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Storage/font probe failed' }
& $daoEngine --headless --path . --script res://tests/abode_state_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Abode state test failed' }
& $daoEngine --headless --path . --script res://tests/living_abode_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Abode scene test failed' }
& $daoEngine --headless --path . --script res://tests/m0c_compat_v3_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M0-C compat test failed' }
& $daoEngine --headless --path . --script res://tests/m1a_core_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M1-A core test failed' }
& $daoEngine --headless --path . --script res://tests/m1b_time_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M1-B time test failed' }
& $daoEngine --headless --path . --script res://tests/m1c_persistence_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M1-C persistence test failed' }
& $daoEngine --headless --path . --script res://tests/m1d_offline_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M1-D offline test failed' }
& $daoEngine --headless --path . --script res://tests/m1e_import_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M1-E legacy import test failed' }
& $daoEngine --headless --path . --script res://tests/m2a_abode_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M2-A abode test failed' }
& $daoEngine --headless --path . --script res://tests/m2b_breakthrough_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M2-B breakthrough test failed' }
& $daoEngine --headless --path . --script res://tests/m2c_nine_realms_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'M2-C nine realms test failed' }
& $daoEngine --headless --path . --quit-after 3
if ($LASTEXITCODE -ne 0) { throw 'Main scene startup failed' }
New-Item -ItemType Directory -Path '.\build\web' -Force | Out-Null
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
```

另外開一個終端啟動本機 HTTP（若已有相同服務，先確認不用重開）：

```powershell
Set-Location 'E:\WORK\Dao2'
python -m http.server 4175 --bind 127.0.0.1 --directory '.\build\web'
```

開啟 `http://127.0.0.1:4175/index.html`；不要直接雙擊本機 HTML。此服務只提供 build/web，不公開整個專案。停止該終端中的服務用 Ctrl+C，不終止不相關程序。若換 port，origin 與瀏覽器存檔也不同；存檔回歸必須保持固定 origin。

現有 Godot 採 `_sc_` 自我包含模式，模板在引擎旁 `editor_data/export_templates/4.7.2.stable/`；引擎與模板被 .gitignore 排除。若工具沙箱阻止引擎寫入，使用該工具的正常授權流程，不繞過限制。

周天探針不再是主場景；M0-A 需提供獨立 export/config 的可重跑方式，不直接改 release main_scene 又忘記還原。`tools/` 被 release 排除，CLI runner 可從源專案執行；不要把 runner 的存在當作 release 可載入保證。

## 瀏覽器驗收的正確做法

- 先等實際場景可互動；loader 截圖與 console 的 ABODE_READY 都不足以證明畫面品質。
- 從當次截圖／viewport 確認座標，記錄 CSS 尺寸和 DPR；不要複用上一回的固定座標。Godot 畫布內部文字通常不在 DOM，不能把 AX 的 canvas fallback 文字視為畫面錯誤。
- 真實點建築／按鈕並核對文字與狀態；拖曳檢查位置、縮放檢查比例及命中；UI 上拖放後再點世界，確認不黏住拖曳。
- 測試暫停藥圃前後一段固定時間的靈草增量，恢復後繼續；鏡頭切換與低特效不能改產率。展示版允許重載重置，正式存檔接入後更新此預期。
- 周天持久化記錄初值、點後值、重載值；不能以檔案存在、函式返回或 headless JSON 往返代替瀏覽器持久化。
- 缺瀏覽器自動化能力就提供人工步驟並標待驗證，不擅自宣稱全通過。手機模擬 viewport 不等於實體手機 GPU、觸控或效能驗證。

## 任務與驗收紀錄模板

每項工作在 `docs/verification/<task-id>.md` 建立紀錄（此目錄待第一項任務建立）：

```text
任務 ID／日期／狀態：
目標與非目標：
已滿足相依：
來源 hash 或規則版本：
修改檔案：
驗收環境（引擎、OS、瀏覽器、裝置、CSS尺寸/DPR）：
命令／退出碼／結果（實測或未執行）：
瀏覽器操作、預期、觀察、截圖路徑：
資料安全／存檔相容影響：
未通過項、阻塞原因、下一步：
```

調整已決定的架構或規則時，在 `docs/decisions/ADR-xxx.md` 記錄理由、替代方案、影響及驗證，並更新 Roadmap。ADR-001–007 已存在 docs/03，不重用編號。

## 可直接貼给下一個 AI 的提示

> 請接續 E:\WORK\Dao2 的修仙問道 v2。先閱讀 AGENTS.md、README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md、docs/02-technical-architecture.md 與 docs/07-responsive-ui-web-spec.md，核對實際程式與最新狀態。使用既有 Godot 4.7.2／GDScript／Compatibility／單執行緒 Web。M0-B、M0-C、M1 與 M2-A～M2-C 已有 CLI／桌面證據；目前主線為 M2-D，先完成 Godot 響應式版型與瀏覽器／實機驗收，不能以 runner 推定觸控、CSS 尺寸或畫質通過。舊碼 E:\Python\test1 和 GodTower 唯讀。不要把展示數值當原作經濟，不重做環境、不直接展開完整九界。交付實際檔案、命令與結果，更新開發狀態；未驗證項明確標示。
