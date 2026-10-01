# M2-D-UI2 核心介面材質與狀態效果

記錄：2026-10-01。狀態：IN_PROGRESS；核心實作與 CLI／native 渲染檢查完成，完整 Web／手機與本輪使用者視覺验收待補。

## 授權與範圍

使用者已明確接受 M2-D-UI1 樣板視覺，並要求完成其他核心介面與舊進度／可建造效果的整合。本輪沿用已接受的青玉古金、淡絹紙方向，不修改玩法、成本、解鎖、存檔版本或演出收益。

交付：資源區、营造簿／建築詳情、引導與操作入口、系統／功能選單、煉丹、宗門、輪迴／天賦、跨界、九界圖鑑、存檔、離線摘要及突破／轉世結果面板的共用材質。外層仍有古金角飾；新增簡潔內層 jade_card.svg，密集卡片不重複大型角飾。字型／文字、命令訊號和材質保持分離。

## 營造狀態契約

| 狀態 | 呈現 | 操作 |
| --- | --- | --- |
| 材料不足 | 淡絹紙、玉綠需求條，取所有成本中最低的庫存／需求比 | 材料不足，停用建造／升級 |
| 材料與資格滿足 | 暖金紙面及滿條，保留「可建／可升」文字 | 依既有 Domain affordable 啟用操作 |
| 材料已齊、前置不足 | 赭色滿條與「前置不足」，提示所需建築與階級 | 維持停用，100% 材料不等於可以建造 |
| 已滿階 | 顯示「已滿」，隱藏需求條 | 維持停用 |

需求條改為原生 ProgressBar + 抗鋸齒圓角 StyleBoxFlat，放在紙面內側，不壓住外框；移除原螢光側條與綠色發光邊框。裝飾 MOUSE_FILTER_IGNORE，不截走建築列點擊。Tooltip 明示比例是材料需求，不是建造時間。刷新回到缺料時不殘留滿條／可建提示。保留 progress_bars.bg 查詢入口以維持既有版面測試。

共用 Theme 統一按鈕、選單、輸入框、滾動條與面板；選中分頁直接改材質，取消宗門分頁把整顆控制項壓暗的舊效果。BUFF／領域與重要狀態保留文字及原有語意色彩。

## 畫面檢查中的修正

- 小資源卡沿用大角飾會擠壓文字：新增無角飾內卡，保留外框與內卡層級。
- 煉丹摘要在短橫向可溢出：改為可換行文字，保持內容可捲動。
- 宗門標題初次换行后，內容區仍按過時最小高度排版：监听標題 minimum_size_changed，合併延後重排。實測桌面内容區由錯誤的 60 高度恢復至 433；回歸驗證桌面／短橫向內容在面板内。

## 修改檔案

- `src/presentation/ui_material.gd`、`ui_typography.gd`：材質角色、狀態、共同 Theme。
- `src/abode/living_abode.gd`、`src/presentation/abode_hud_controller.gd`：主 HUD、資源、引導、導航、操作／設定入口。
- `src/presentation/building_catalog.gd`：全部營造列、內縮需求條、狀態材質。
- `src/presentation/alchemy_panel.gd`、`sect_panel.gd`、`reincarnation_panel.gd`、`realm_teleport_modal.gd`、`nine_realms_preview.gd`、`buff_hud_bar.gd`：核心卡片與狀態呈現；既有其他面板透過共同 Theme／dialog_surface 更新。
- `assets/ui/material/jade_card.svg`（含引擎匯入設定）、`assets/ui/material/README.md`：原創向量來源、用途與圖層；沒有複製 GodTower 資產或使用 ImageGen。
- `tests/ui_material_states_runner.gd`（含引擎生成 UID）、`tools/run_all_runners.ps1`：新增有意義的狀態／布局回歸並納入固定入口。
- `tools/ui_material_preview.gd`：隔離渲染範例；M2-D-UI1 圖片保留，UI2 輸出至 `artifacts/ui-core/`。
- 本頁、Roadmap、development-status、updata：驗收與交接。

## 命令及結果

Godot 4.7.2.stable.official.ed1daf0bf、Compatibility／OpenGL 3.3、NVIDIA GTX 1660 Ti；沒有升級引擎或模板。

- `--headless --editor --path . --import --quit`：exit 0，`artifacts/ui-core/import.log`；無新增脚本編譯錯誤。
- `--headless --path . --script res://tests/m2d_responsive_ui_runner.gd`：PASS，exit 0。
- `--headless --path . --script res://tests/ui_material_states_runner.gd`：PASS，exit 0；`artifacts/ui-core/states.log`。涵蓋多材料最低比例、前置不足、可建、滿階、回退缺料、裝飾輸入隔離、內縮邊界與宗門重新排版。
- `powershell -File tools/run_all_runners.ps1`：29/29 PASS，exit 0；`artifacts/ui-core/runners.log`。
- `--headless --path . --script res://tests/abode_presentation_parity_runner.gd`：PASS，exit 0；`artifacts/ui-core/parity.log`。公共介面、訊號、保存順序與版型維持。
- `--path . --script res://tools/ui_material_preview.gd`：exit 0；`artifacts/ui-core/preview.log`。採 `user://ui_material_preview`，測試完只清空該隔離槽；不覆蓋正式 Web 進度。
- `--headless --path . --export-release Web build/web/index.html`：exit 0；`artifacts/ui-core/export.log`。
- `git diff --check -- src/presentation src/abode/living_abode.gd tools/ui_material_preview.gd tests/ui_material_states_runner.gd`：exit 0；僅 LF／CRLF 提示。
- 既有本機 4178 服務回覆 HTTP 200，提供新版 Web 匯出；open_in_codex 回覆 queued。

Runner 和預覽仍有既有 Font RID、CanvasItem／ObjectDB 退出清理警告及負面輸入測試的預期診斷；不能宣稱完全無警告。本輪沒有修改其他既有工作區變更。

## 圖像證據與限制

已用 view_image 檢查 native 渲染圖，涵蓋桌面與短橫向核心面板：

- [營造四種狀態](artifacts/ui-core/catalog-states-1280x720.png)
- [橫向營造](artifacts/ui-core/catalog-844x390.png)
- [主畫面](artifacts/ui-core/home-1280x720.png)
- [煉丹短橫向](artifacts/ui-core/alchemy_panel-844x390.png)
- [宗門短橫向](artifacts/ui-core/sect_panel-844x390.png)
- [天賦面板](artifacts/ui-core/reincarnation_panel-1280x720.png)
- [跨界短橫向](artifacts/ui-core/realm_modal-844x390.png)
- [存檔短橫向](artifacts/ui-core/save_controls-844x390.png)
- [九界面板](artifacts/ui-core/nine-realms-1280x720.png)

工具共输出 16 张原生渲染截圖；營造狀態與已加入宗門使用隔離展示 fixture，未改正式 GameSession 資料。桌面 1280×720／邏輯1280×720；短橫向視窗844×390／邏輯779×360。列表被捲動視口裁切的下方內容可透過列表捲動访问，不將其當作固定內容缺失。

這些不是瀏覽器截图，也不證明滑鼠／觸控命中、DPR、高 DPI 清晰度、IndexedDB、實體手機 GPU、FPS／p95 或下載預算達標。此 session 的瀏覽器工具既有啟動問題 `helper_unknown_error: setup refresh had errors` 尚未取得恢復證據；本輪完成 native／CLI 可驗部分，不宣稱 Web E2E 已通過。

## 本機檢視與下一步

試玩 http://127.0.0.1:4178/index.html?ui=core-20261001 ：重新載入，切空島／營造，觀察資源三態、材料不足→可建／可升、詳情返回、所有功能面板與系統選單；拖曳／縮放世界並確認 UI 不穿透。以1280×720、844×390與一台實體手機橫向，測試內容捲動、關閉、主要控制項44 CSS px、低特效與選中態。前置不足須用符合條件的隔離測試資料，不消耗使用者進度。

本輪停在核心介面更迭；下一步先處理使用者對新面板與狀態效果的視覺回饋並補 Web／手機證據，未通過 DoD 前維持 IN_PROGRESS，不展開其他大型任務。
