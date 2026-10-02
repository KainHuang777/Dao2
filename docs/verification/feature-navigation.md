# M2-D-NAV1 功能導覽與介面整合

日期：2026-10-03。狀態：IN_PROGRESS；功能與 CLI 回歸已交付，使用者分類／視覺回饋與實體裝置驗收待補。規格見 [入口整合規範](../12-feature-navigation-and-integration-spec.md)。

## 交付

四個主入口「洞府／經營／修行／遊歷」，九個玩法分頁，移除可見 More 與重複宗門／輪迴入口。洞天據點升級並入經營，共用資源區追加靈晶／靈液、道心／道證及獸魂。靈獸與天道決策由正式 Session 命令操作，補足原有核心只有規則資料而缺操作頁的情況。

新導覽集中管理互斥、群組內記憶、返回、Escape、相機鎖定與設定工具開啟順序；輪迴／煉丹／機緣頁加入內部捲動，九界網格使用工作區寬度並由共用返回列收回神識。洞天鎖定提示、成本換行與機緣紙卡對比一併修正。

| 修改檔案 | 責任 |
| --- | --- |
| `src/presentation/feature_navigation.gd`、`system_actions_panel.gd`（含 `.uid`） | 統一導覽、資源讀數、靈獸／決策操作頁 |
| `src/abode/living_abode.gd`、`src/presentation/abode_hud_controller.gd`、`abode_modal_manager.gd` | 原場景相容入口、HUD、設定及命令接線 |
| `src/presentation/nine_realms_preview.gd`、`reincarnation_panel.gd`、`alchemy_panel.gd`、`fortune_modal.gd`、`realm_teleport_modal.gd` | 工作區、內部捲動、命中尺寸、鎖定提示與可讀性 |
| `src/application/game_session.gd`、`src/simulation/beast_system.gd` | 靈獸唯讀 view 與共用餵食成本；命令仍走原規則 |
| `tests/feature_navigation_runner.gd`（含 `.uid`） | 歸屬、互斥、狀態不變、相機鎖定、資源與成功命令 |
| `tests/abode_presentation_parity_runner.gd`、`m2b_breakthrough_runner.gd`、`m2d_responsive_ui_runner.gd`、`m3a_reincarnation_ui_runner.gd`、`m3b_alchemy_ui_runner.gd` | 更新舊入口契約，保留原功能驗證 |
| `tools/run_all_runners.ps1`、`tools/navigation_preview.gd`（含 `.uid`） | 36 項固定回歸、隔離原生截圖 |
| README、ROADMAP、docs/07、08、12、呈現索引、AI 交接、development-status、updata.txt | 現況、接入規範、歷史與下一步 |

## 命令與證據

- 本機 Godot `4.7.2.stable.official.ed1daf0bf`；`--headless --editor --path . --import --quit` 成功，另掃描 Parse／Compile／SCRIPT ERROR，見 `nav1-import-final.log`。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1`：**36/36 PASS、exit 0**，見 `nav1-runners-final.log`。包括原靈獸規則／保存與新導覽回歸。
- 最後可讀性修正另跑 feature_navigation、m3b_fortune_ui、m2d_responsive_ui、abode_presentation_parity；對應 `nav1-*-final.log`，煉丹整頁捲動後另跑 m3b_alchemy_ui。九界固定返回列收斂後另補九界／響應式／導覽回歸。
- `--path . --script res://tools/navigation_preview.gd`：exit 0；隔離 Era 3 靈獸 fixture，產出兩尺寸 × 十頁 **20 張原生 PNG**，見 `nav1-native-final.log`、`artifacts/nav1/`。
- `--headless --path . --export-release Web build/web/index.html`：exit 0，見 `nav1-export.log`。
- 本機 `python -m http.server 4183 --bind 127.0.0.1 --directory build/web`；獨立 origin，不碰既有 4178／4182 玩家資料。IAB 使用 CUA 真實滑鼠操作，桌面逐頁確認經營／洞天／煉丹／靈獸／輪迴／九界／宗門／機緣／天道決策；短橫向另檢查九頁切換、返回、Escape 與內容捲動；360×640 檢查旋轉提示與轉橫恢復。實際證據圖列於 artifacts/nav1/web-*.png。844×390 CSS viewport 實測 canvas 843×389、document scroll 844×390、DPR 約 1；沒有瀏覽器頁面捲軸；最終錯誤 console 擷取為空，保存截圖後已恢復 viewport override。

導覽 Runner 使用 `user://nav1_runner`；原生截圖工具使用 `user://nav1_native_preview`。成功餵食扣款、天賦獸魂消耗及決策 revision／冷卻來自隔離 UI 訊號回歸，不能當作瀏覽器成功命令或 IndexedDB 落盤證據。

## 過程中發現與修正

- 舊 Runner 假設 More 有玩法項目、輪迴只在窄版常駐，已改驗新的入口契約；保留原規則與版面檢查。
- 編輯時曾有九界 `panel_size` 誤用於建立 UI 的 Parse Error，已移至 layout 範圍並重驗；不以 import exit 0 掩蓋腳本錯誤。
- 文字試播回歸找出「已在洞府時返回」覆蓋其他演出相機鎖定，改成無動作並補測試。
- 快速九界往返測到分頁重建使等待釋放的按鈕記憶體超門檻，改為同群組重用分頁，原 50 次切換檢查已通過。
- Web 短橫向發現九界自己的 footer 與內容重疊；嵌入工作區時改用共用固定返回列。
- Web 短橫向發現機緣內容最低高度超出工作區，改為獨立 ScrollContainer，保留固定分頁與返回；重新匯出與 UI 回歸通過。
- Web 短橫向發現煉丹 ScrollContainer 的 120px 最低高度超出工作區，改為整頁內容捲動，補煉丹／機緣捲動區不超出工作區的回歸；窄版經營分頁縮成「建築／洞天」。
- 直式 Web 複核發現新導覽繪圖層高於旋轉提示；提示提高至 HUD z=100，補導覽／響應式回歸及重新匯出，保持方向引導覆蓋玩法。
- 初次開 Web 時 HTTP 尚未啟動曾 connection refused；服務啟動後成功載入，無安全警告繞過。

## 未完成項與下一步

使用者需回饋「宗門歸遊歷」是否符合習慣；目前依建議四入口實作。分類改動只需要修改 GROUPS／主入口，不改遊戲資料。360×640 直式冷啟動的既有 1280 內容縮放使提示字級偏小；本輪修正遮罩層次，提示可讀性另列 R1 待補，不能將直式遮罩出現當作直式完成。實體觸控、高 DPR、音訊、FPS、IndexedDB 故障復原及逐界完整成功命令仍未由本輪證明。

既有核心仍有高階靈獸餵料（精鐵等）與界域決策舊資源 ID 的供給／映射整合缺口；本輪保留核心費用，UI 不偷偷替換或贈送資源。後續需用獨立規則任務核對高階可玩路徑。

引擎退出時仍有 Font／CanvasItem／ObjectDB 資源未釋放診斷；Runner 和原生程序 exit 0，不宣稱零警告。下個任務為 NAV1 使用者回饋及實機驗收；新的大型系統請從 New Chat 開始。
