# RES1-UI1-R6：空島圖形化與簡化

2026-10-09，**DONE（有界呈現與桌面驗證）**。使用者要求將製造／運輸的簡化與圖形風格同步到空島；相依 UI1-A／R4／R5 已滿足。DoD 為既有開拓／升級命令回歸、庫存／成本手繪框、三橫式版型與真實 Web 操作、一般 Web 同步。人工美術接受、實機／高 DPR 與完整 UI1-C／C／D 仍待驗。

## 交付

- `src/presentation/island_management_panel.gd`：採集物品卡顯示 ICON、可用量、資源名、實際每秒產率與容量條；條含可用量＋容量預留，完整量與容量保留 tooltip。展開本島庫存顯示原料／產物物品卡，保留可用與預留明細。
- 開拓、採集設施及倉儲使用既有 `recipe_material_tile.gd` 成本框，祖島來源與需求量、缺料朱紅／補料恢復；設施等級／產率或容量變化與升級按鈕分開。上限收起成本框，命令仍由 canonical controller 提交；經濟／schema 未改。
- 寬式固定四島選取與前往；短式固定島名下拉／前往／關閉，收起已開拓島的重複說明，把首屏留給採集卡。內容內部捲動，保存失敗／重試與成功收據沿用原契約。製造／運輸繼承此父類，其新增切島控制保持隱藏。
- `tests/res1_ui1a_runner.gd` 追加實際成本貨種、產率、缺料→恰好滿足、三橫式固定入口／最小寬度檢查；原本庫存文字檢查改為圖形卡＋明細 tooltip。`tests/res1d2_world_runner.gd` 世界返回入口檢查改為新的固定控制，不再依賴 body 第一個子節點。
- `tools/res1_ui1r6_preview.gd`／Godot UID、隔離 review fixture、12 張原生 PNG 與 Web PNG；僅重置 `user://res1_ui1r6_preview`，不接觸玩家存檔。
- 重用 R3 的手繪透明 PNG，來源、提示詞及授權沿用 `assets/ui/resources-painted/manifest.json`；沒有新外部圖形資產。

## 命令與結果

引擎 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` = `4.7.2.stable.official.ed1daf0bf`。Compatibility／同版模板／單執行緒 Web 保持。

| 命令 | 結果 |
| --- | --- |
| Godot `--headless --path . --import` | 初次父類 MaterialTile 與兩個子類同名常數衝突；改 IslandTile 後 repaired import 通過。 |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | 初次編譯與 sandbox user:// 寫入失敗保留；修正後授權隔離執行 217 checks PASS。 |
| PowerShell `tools/run_all_runners.ps1` | 首次世界測試依賴舊 body 第一按鈕失敗；第二次隱藏 selector 幾何檢查失敗；修正測試為實際固定入口後 **56/56／exit0**，A217／B220。最終 `artifacts/res1-ui1-r6-all-runners-final2.log`。 |
| Godot `--path . --script res://tools/res1_ui1r6_preview.gd` | 最終 exit0，12 PNG，無 OVERSIZE／SCRIPT ERROR；原生名義844在日誌為779×360，精確844以 Web 補驗。 |
| Python `tools/subset_game_fonts.py --check` | 初次「種」缺字；改既有字元後 PASS，1823 glyphs，字型未重生成。 |
| Godot `--headless --path . --export-release Web build/web/index.html` | exit0，一般 Web 同步。 |
| Node `tools/prepare_web_compression.mjs build/web` | exit0，Brotli 往返與四首 BGM companions。 |
| Python `tools/island_preview_server.py --port 4302 --normal-build --fixture res1-ui1-r6-review.json --gzip` | 正常服務與真實 Web 操作通過。4301 受限服務／重試未回應，停止後以單一授權4302服務成功。 |
| `git diff --check -- src/presentation/island_management_panel.gd tests/res1_ui1a_runner.gd tests/res1d2_world_runner.gd` | exit0，僅 LF／CRLF 提示。 |

最終 PCK SHA256：`44267cd2d4c8f7a56d7458b9c10e02f5858819562ac1e095c3e9361a39645760`。全量保存故障 runner 的預期損壞 JSON 與既有 Font／CanvasItem／ObjectDB／resource 退出診斷保留，不稱零診斷。初次 CIM 程序查詢權限拒絕、一次 Windows rg glob 錯誤、瀏覽器 DOM 跨 iframe 讀取失敗均非成功證據，後續使用已支援 API。沒有 auto-review 拒絕。未 commit／push、未更新 Windows 包。

## 真實瀏覽器

computer-use／cua_repl IAB，launcher 下 DOM 核對 iframe **1280×720、844×390、800×360 CSS px**。4302 是新的隔離 origin，只成功 seed 一次命令走出的 Era3 fixture；重載後一次舊 AX index 誤按 seed 被「已有進度保留原檔」保護拒絕，另誤開 rAF 對照不作效能證據，隨後以具名 Play 開啟，實際重載保留升階已確認。

1. 玄礦採集卡、兩貨種、容量與每秒产率、固定切島／世界入口正常：`artifacts/res1-ui1-r6/web-ore-1280.png`。
2. 玄礦倉儲1→2，材料支付與成功收據、容量200→300下一階費用正常：`web-upgrade.png`。採集設施1→2也實際點擊成功，次階預覽4→6與費用40／4正常。
3. 844下拉切青木、800首屏採集卡；800內部捲動可到倉儲升級，實際1→2成功，固定前往進入青木世界：`web-wood-844.png`、`web-wood-800.png`、`web-upgrade-800.png`。
4. 真實頁面 reload／Play，青木倉儲仍2階、下一升級3階，無重複操作：`web-reload.png`。
5. 360×640 iframe有旋轉遮罩，返回800恢復青木頁；本次直式提示呈現很小，**不宣稱直式文字可讀性通過**，保留 UI1-C 後續核對。

## 待驗與下一步

最終人工美術／密度接受、實機觸控、高 DPR、完整 UI1-C 剩餘裝置範圍仍待驗；本輪不重跑已驗保存400矩陣／FPS，也不因暫緩冷啟動阻擋。下一 New Chat 收空島介面回饋或續剩餘裝置，不開 Era4。交接同步 `updata.txt` 與 development-status。

Closure: 4302 service stopped (Ctrl+C); successful game tab closed and viewport override reset. Two 4301 network-error tabs could not be explicitly closed because Browser Use rejected their data: error-page URL; leave temporary-tab cleanup to the browser. No policy bypass attempted.

