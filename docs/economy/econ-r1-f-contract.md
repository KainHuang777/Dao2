# ECON-R1-F 契約：調參凍結、隔離候選與舊入口驗證

狀態：執行中（2026-11-07）
上游：`docs/52-economy-reconstruction-reference.md` §13（ECON-R1-F 整批收尾）
相依：ECON-R1-D／E 已完成（見 `docs/development-status.md`）

## 交付範圍

1. 調參凍結：把四個研究內容檔的位元組指紋與執行期常數固化成可重跑檢查。
2. 隔離新版候選：Web 匯出 `build/econ-r1-f-web`，brotli 壓縮與交付檢查。
3. 舊入口／存檔仍可用：預設（legacy）入口啟動、舊 schema 讀取、跨版本互不污染。
4. 此大型里程碑僅此一次 L3：全量 runner＋全尺寸矩陣、Web 候選包、Chrome 三橫式。

## 凍結面

| 項目 | 位置 |
| --- | --- |
| 研究節點 R01–R07 | `content/research/econ_r1.json` |
| 研究節點 R08–R11 | `content/research/econ_r1_d1.json` |
| 研究節點 R12–R14 | `content/research/econ_r1_d2.json` |
| 後段資源／配方／建築 | `content/research/econ_r1_d2_components.json` |
| 效果上限與精度 | `src/economy/economy_effects.gd` |
| 研究版本、繼承階梯、最短工時 | `src/economy/research_system.gd` |
| profile／rules／economy 版本 | `src/economy/economy_profile.gd` |
| 切片標籤與閘門 | `src/economy/economy_slice.gd` |

凍結清單檔案：`tests/fixtures/econ_r1_f/tuning-freeze.json`

凍結含義：內容檔 SHA-256、節點表（era／cost／seconds／unlocks／facility／island／prereq／produced）、元件資源上限／配方／工時／建築、執行期常數與繼承階梯。任何調參變更都必須同步更新凍結清單，否則 `tests/econ_r1_freeze_runner.gd` 失敗。這是刻意的：凍結不是禁止調整，而是要求調整留痕。

## 驗證介面（凍結簽名）

- `tests/econ_r1_freeze_runner.gd`：extends `SceneTree`，載入凍結清單與真實內容，輸出 `ECON-R1-F freeze checks=<n> failures=<...>`，結尾恰好一行 `RUNNER_RESULT status=PASS|FAIL exit=N`。
- `tests/econ_r1_release_runner.gd`：extends `SceneTree`，以隔離存檔目錄實例化 `scenes/living_abode.tscn`（預設 legacy 版本），驗證舊入口／舊存檔／跨版本隔離，輸出 `ECON-R1-F release checks=<n> failures=<...>`。
- 兩支 runner 都使用 `RunnerResult.output_path()`／`RunnerResult.finish()`，不觸碰真實使用者進度。

## 驗收級別

- L1：`tools\run_all_runners.ps1 -Only 'econ_r1_freeze,econ_r1_release'`
- L3（僅此一次）：`tools\run_all_runners.ps1 -Full -Parallel 3 -TimeoutSeconds 1800`
- Web：`--export-release Web build/econ-r1-f-web/index.html` → `node tools/prepare_web_compression.mjs build/econ-r1-f-web` → `python tools/delivery_check.py --web build/econ-r1-f-web`
- Chrome：1280×720、844×390、800×360 三橫式，同時檢查預設入口與 `?edition=econ-r1`。

## 非範圍

- 不新增第二個匯出 preset；兩個版本共用同一 Web 包，執行期以 `edition` 參數選擇。
- 不改動既有研究數值（除凍結清單記錄外）。
- 不進行觸控／實機驗收（延後，非阻擋）。
- 不自動 commit。
