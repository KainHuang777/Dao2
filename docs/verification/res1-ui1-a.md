# RES1-UI1-A：Godot 空島簡版與集中製造

2026-10-08。**DONE（UI1-A 有界實作與驗證）**；UI1-B／C TODO。依 [精簡計畫](../16-multi-island-ui-simplification-plan.md) 接續 DESIGN，不提升完整 RES1-C/D、裝置、美術或效能狀態。

## 交付

- 經營統一 `buildings`／`outposts`／`manufacturing`／`transport`。空島基本詳情只列採集原料與採集／倉儲升級，祖島不複製全庫存；啟用、舊三島延伸、開拓、前往世界、洞府建築與靈界洞天保留。右欄四分頁在三橫式可直接操作。
- 製造集中八配方，精煉／合成分類與島篩選有選中狀態。寬式兩欄、短橫式一欄；四島各一份工作摘要／活動進度。配方詳情取代清單，固定返回；Escape 先回配方再回洞府。Container／Godot 內部捲動，刷新復用卡片／摘要節點。
- 詳情提供單批、指定批數、持續、原料保留量、切方及停工；顯示當地可用、祖島共用靈力、實際在途倒數、加工待完成與容量預留。缺本地草導回丹霞採集；共用靈力導向祖島建築；外島原料導向現有航線。更精確的 resource_id／route_id 定位留 UI1-B。
- 加工坊移至製造詳情，讀核心有效秒數。工坊用既有圖像透明度命中，導向同一島／配方；島體導基本詳情。沒有新增圖形資產或世界地塊。
- 多島啟用且 Era>=2 時，煉丹的築基丹按鈕前往祖島同一工作，不送第二次加工；服用、聚靈丹／延壽丹保留。修復輪迴 Era1 留有 economy 時被錯送禁用加工的起手入口，仍用既有即時煉製費用／效果。
- 七條舊航線操作移至獨立運輸頁以保持可達；沿用原控制版型，**不宣稱 UI1-B 精簡列表／設定詳情完成**。移位升階保留 enabled，避免停航升階偷啟動。
- 命令拒絕與保存失敗分開顯示。加工成功而保存失敗可「重試保存」，不重送命令；恢復後撤下失敗提示。啟用失敗保留原檔並明示需再次啟用。

## 來源與保存

修改：`src/presentation/island_management_panel.gd`、`feature_navigation.gd`、`island_world.gd`、`alchemy_panel.gd`、`abode_modal_manager.gd`、`src/abode/living_abode.gd`；新增 `manufacturing_panel.gd`／`island_transport_panel.gd` 及 Godot 生成 UID。

`IslandEconomy._check_start` 從原 `_start` 抽出純唯讀資格，執行和 View 共用門檻；`manufacturing_view` 供 `GameSession.get_view()` 提供地點、有效耗時、費用／庫存、容量、採集率。沒有另外複製加工公式。`alchemy_system.gd` 提供製造捷徑，`command_processor.gd` 修復 Era1 起手。`save_codec.gd` rules_version 更新 **core-flow-12-ui1a-era1-alchemy**；schema3、economy res1-d-2、配方、成本、航向與產線数保持原契約，既有舊 envelope 可解碼；不新增 UI 存檔欄位。

測試／工具：新增 `tests/res1_ui1a_runner.gd`、`tools/res1_ui1a_preview.gd` 與 UID，更新 `res1c_progression_runner`、`feature_navigation_runner`、`res1d2_world_runner`、`res1c2_world_runner` 和 `run_all_runners.ps1`。`island_preview_server.py` 增加明確測試尺寸按鈕；開发 launcher 不是正式 Web shell。全量 runner 按現有行為重產隔離 earned／offline fixtures，保留已有工作區修改，不 commit／push。

## 命令與結果

引擎：Windows Godot `4.7.2.stable.official.ed1daf0bf`；現有 Compatibility／單執行緒 Web。引擎路徑 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`。

| 命令 | 結果／證據 |
| --- | --- |
| Godot `--version` | exit0，版本一致 |
| Godot `--headless --path . --import` | exit0；初沙箱有 user:// 目錄診斷，不能稱零錯誤 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1` | 兩輪 **55/55、exit0**；後輪日誌 `artifacts/res1-ui1-a-all-runners-final.log`，該輪專項117 checks |
| Godot `--headless --path . --script res://tests/res1_ui1a_runner.gd` | 最後 **127 checks、exit0**；涵蓋 UI 啟用／開拓／升級、八配方各成功、JOB_BUSY／首次缺料／滿倉／未解鎖／未開拓拒絕、三批精確完成、持續多批、等待／進行中切方及停止、保留量草稿、相同煉丹工作／服用／Era1、保存拒寫／重試／重新解碼、50次管理切換節點／全狀態不變 |
| Godot `--headless --path . --script res://tests/res1d2_world_runner.gd` | 最後59 checks、exit0；含透明度工坊命中與同丹霞製造路由 |
| Godot `--headless --path . --script res://tests/res1c2_world_runner.gd` | 26 checks、exit0；三島／舊版相容回歸 |
| Godot `--headless --path . --script res://tests/feature_navigation_runner.gd` | exit0；四群組／新route／互斥／返回／HUD 恢復 |
| Godot `--headless --path . --script res://tests/abode_presentation_parity_runner.gd` | exit0；公共委託、signal、保存順序與 teardown |
| Godot `--path . --script res://tools/res1_ui1a_preview.gd` | exit0；9張原生 PNG、獨立 review envelope。最後使用實際 viewport；844×390 PNG 的 Godot 邏輯區約779×360 |
| Godot `--headless --path . --export-release Web build/web/index.html` | 最後 exit0；只從來源重新匯出 |
| `node tools/prepare_web_compression.mjs build/web` | exit0；Brotli 往返、四首 BGM companions；核心 br 26,763,071 bytes，不是性能放行 |
| `python tools/island_preview_server.py --port 4291 --normal-build --fixture res1-ui1-a-review.json --gzip` | 獨立 localhost origin 正常供應；新增尺寸按鈕重啟過一次。伺服器啟動期間曾偵測正在重產的舊 companion，安全 fallback gzip；最後 companion hash與來源一致 |

最後 PCK SHA256：`9add87fab482d4b6d3a2298a143c773953160c2b83aaf948f96ca3d26f1c6712`。來源最後小修後專項127／世界59／C2世界26／parity補驗；沒有把較早全量的117檢查寫成127。

CLI 成功案例使用診斷 clone 補足材料，以驗證 UI 命令／來源庫存，不宣稱正常玩法已贈料或滑鼠通關。啟用來源是真正從空白命令生成且 economy 空的 Era2 檔；正常到 Era3 的既有 D2 契約由本輪全量重跑。所有保存皆 Runner 自有 `user://res1_ui1a_runner`／`user://res1_ui1a_preview` 或 MemoryAdapter；原玩家存檔未存取。

## 原生與真實 Web

原生圖片位於 `artifacts/res1-ui1-a/`，三尺寸各 basics／recipes／detail。逐圖檢視修復初版配方文字暗底對比與按鈕最小寬度；擷取工具最初誤用 CSS 等量尺寸而非 Godot 邏輯區，已改用 `root.get_visible_rect()` 重產。沒有用初版超界截圖作通過證據。

IAB/cua_repl 在 `127.0.0.1:4291/launcher` 真實點擊、捲動及重載；DPR約1，非實體裝置。桌面最初實際 iframe **1280×720.4 CSS**（整數720的原生 PNG 另有證據），最後以專用按鈕追加精確 **1280×720 CSS** 四分頁／製造操作；另實測 **844×390**、**800×360**、**360×640** DOM矩形。

- 桌面：關閉離線摘要→經營／空島簡版→製造祖島篩選→全部空島兩欄→點銅精詳情→本批後停止，可見剩餘2秒及停止安排。
- 844×390：固定分頁／返回／底部四入口保留；內容內部下捲到開始，再上捲核對玄銅及下品靈石已扣、原生採集持續；無外部瀏覽器捲動代替內容。
- 800×360：最終四分頁直接可見→製造單欄→點青木產線詳情，可見當地原料與實際靈石在途5／剩餘秒數。
- 360×640：旋轉遮罩出現，背景點擊後轉回800×360仍是靈材詳情；此有界檢查不是全觸控或遮罩字級美術放行。
- 真正重整 launcher、沿用該origin保存重開正常，舊世界建築與已停銅精／仍運轉靈材保留；未解析 Web 保存值逐項核對。最後微小樣式／錯誤文案修改又重載檢視；browser error/warn 查詢空。

瀏覽器截圖在工具中檢視；兩次直接保存至專案／視覺目錄皆 EPERM，沒有虛構本地 Web 截圖檔。可交付的本地圖為正式 Godot 原生 PNG。唯讀 evaluate 讀 localStorage 的嘗試因工具 scope不提供而失敗，重載證據以實際畫面為限。一個載入期間的尺寸點擊遇 CDP DOM.resolveNode timeout，重新觀察後以可見按鈕完成。

## 未通過嘗試／限制與下一步

初沙箱 navigation 的 user:// 寫入失敗，啟動中止；停止該 Runner 後依既有授權重跑通過。最初 PowerShell 字串及 delete/add 同一路徑 patch 驗證失敗，未套用；Runner 初次型別推導／不存在load方法錯誤已修正。篩選初次metadata讀取曾報錯，改預設值後又產生int與bool比較SCRIPT ERROR（即使Runner exit0也不算通過）；最後以has_meta＋bool比較修復，新增卡片刷新確實完成斷言，最後127 Runner與原生日誌另以SCRIPT ERROR／selection診斷掃描為硬失敗檢查，均通過。新增解碼重載案例曾被不同診斷 clone 的 revision 舊槽干擾，改獨立 MemoryAdapter後通過，沒有修改正式保存選槽規則。

成功日誌仍有既有 Font RID／CanvasItem／ObjectDB／resource退出診斷，負面測試故意損壞 JSON／拒寫的錯誤亦保留。沒有新資產生成、Windows 包匯出、實體觸控／DPR2–3／FPS／GPU／自然時間完整首段／IndexedDB或完整 Web 故障矩陣。

UI1-A DoD 已由核心／呈現命令證據與桌面操作達成。**下一 New Chat：RES1-UI1-B**，將運輸改七航線列＋設定詳情、保留草稿／自訂值與實際瓶頸定位，再 UI1-C 做最終 Web 三尺寸全流程、保存故障、装置、性能與使用者易用性驗收。本輪止於 A，不展開 B。

驗後清理：IAB兩個本輪建立分頁皆已關閉，viewport override已reset；4291服務以Ctrl+C停止（exit1為主動終止）。本輪16份主要新增／更新文字嚴格UTF-8檢查通過，限定diff-check exit0；未操作其他服務／分頁。
