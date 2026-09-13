# Godot 環境與最小 Web 專案探針

日期：2026-09-13。狀態：核心環境、繁中 UI 與瀏覽器持久化測試均通過。

## 固定環境

| 項目 | 設定 | 已驗證 |
| --- | --- | --- |
| 引擎 | Godot `4.7.2.stable.official.ed1daf0bf` | `--version` 與 CLI 執行均成功 |
| 安裝方式 | 官方 Windows x86_64 標準版，放於 `tools/godot/4.7.2/` | 使用 `_sc_` 自我包含模式；引擎與模板不納入版本控制 |
| 模板 | 官方 4.7.2 export templates，放於 `editor_data/export_templates/4.7.2.stable/` | Web release export 成功 |
| 腳本 | GDScript | JSON 讀寫測試與主場景執行成功 |
| 渲染 | Compatibility | `project.godot` 固定 `gl_compatibility` |
| Web | 單執行緒、無 GDExtension | `export_presets.cfg` 將 `variant/thread_support` 設為 false |
| 設計尺寸 | 主洞府 1280 × 720 viewport／視窗覆寫 | 桌面橫版為目前視覺驗收基線；周天 probe 仍是獨立環境探針 |

官方下載頁確認 Godot 4.7.2 為 stable；Web 匯出採 WebAssembly／WebGL 2.0 與 Compatibility。[官方下載檔案庫](https://godotengine.org/download/archive/4.7.2-stable/) [官方 Web 匯出文件](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

## 已建立的最小專案

| 檔案 | 用途 |
| --- | --- |
| [project.godot](../project.godot) | 引擎、桌面橫版視窗與 Compatibility 基線 |
| [export_presets.cfg](../export_presets.cfg) | 名為 `Web` 的單執行緒 release 匯出設定；排除 docs、tools 和 build |
| [web_probe.tscn](../scenes/web_probe.tscn) | 獨立周天 UI，提供啟動次數、按鈕和繁中文字檢查 |
| [web_probe.gd](../src/presentation/web_probe.gd) | 使用 `user://web_probe_state.json` 寫入啟動／操作次數 |
| [test_runner.gd](../tools/test_runner.gd) | 不依賴 UI 的 JSON 與 `user://` 寫讀測試 |
| [.gitignore](../.gitignore) | 排除 Godot 快取、匯出、引擎和模板大檔 |

`web_probe.gd` 是環境探針，不是正式存檔架構；正式 M1 仍使用規劃文件中的快照、版本與遷移設計。

## 實際驗證結果

| 檢查 | 結果 | 證據 |
| --- | --- | --- |
| 專案匯入 | 通過 | Godot headless 匯入與腳本掃描無 parse error |
| 儲存 runner | 通過 | 輸出 `PASS: project script, JSON serialization, and user storage fixture are available.` |
| 主場景 runtime | 通過 | 輸出 `PASS: Web probe main scene completed a headless runtime start.` |
| Web release | 通過 | 生成 `build/web/index.html`、`index.js`、`index.wasm`、`index.pck` 等檔案 |
| 繁中 UI 字型 | 通過 | `NotoSerifTC-VF.ttf` 已套用到所有探針文字；runner 驗證「修、仙、道、周」字形可用 |
| 打包範圍 | 通過 | docs、tools、build 均排除；因嵌入繁中字型，`index.pck` 約 14.9 MB |
| localhost 服務 | 通過 | Python HTTP server 對 `index.html` 回覆 HTTP 200 |
| Edge WebAssembly 啟動 | 通過到引擎啟動畫面 | [啟動截圖](../build/verification/web-probe-render.png) 顯示 Godot loader；無頭截圖工具未等待首場景完成 |
| 瀏覽器實測 | 通過 | 手動確認繁體中文正常顯示；點擊「運轉一次周天」後重整，計數仍正確保留 |

Windows headless Edge 的擷取流程會在 Godot canvas 完成首場景前截圖，因此不能把這張啟動畫面當作 UI 完整驗收。headless Godot 已實際載入主場景與執行 `web_probe.gd`；瀏覽器層的繁中顯示與重載持久化則已由手動實測確認。

## 可重跑命令

在 PowerShell、專案根目錄執行。`$engine` 指向目前可攜式引擎；`_sc_` 會讓編輯器資料與模板放在引擎旁的 `editor_data/`。Codex 的受限 shell 會阻擋原生程式寫入使用者資料夾，故自動驗證以授權的本機程序執行；一般本機 PowerShell 可直接執行。

```powershell
$engine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path . --import
& $engine --headless --path . --script res://tools/test_runner.gd
New-Item -ItemType Directory -Path .\build\web -Force
& $engine --headless --path . --export-release 'Web' .\build\web\index.html
& $engine --headless --path . --quit-after 2
```

Web 成品需要以 HTTP／HTTPS 服務，不可直接雙擊 `index.html`。本機快速檢查：

```powershell
python -m http.server 4173 --bind 127.0.0.1 --directory .\build\web
```

## 下一個驗收

2026-09-13 交接修正：本文件的「環境探針完成」不代表 Roadmap M0 全部完成。主場景現為 living_abode，洞府本身尚未接存檔；周天重載自動化及完整手勢驗收列為 [M0-A](../ROADMAP.md)，其後補來源 fixture 與 Amount／RNG。以下保留原階段建議供參考。

M0 環境探針已完成。下一步進入 M1：建立 Amount 大數值、模擬時鐘、快照存檔與舊版修煉公式 fixture，並將它們與畫面層解耦。
