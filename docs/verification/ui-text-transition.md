# M2-D-TEXT1 — 原生過場文字樣板

## 2026-10-03 R1：Era 內等級提升接線

使用者要求 Era 內每次等級提升顯示文字並加黑底。本輪實作／CLI／桌面 Web 通過；使用者視覺、實體手機／高 DPR 待驗，整體保留 IN_PROGRESS。下方 10/2「未接正式事件」為歷史狀態。

- 成功提交 `cultivation_leveled_up` 並保存／刷新後，顯示實際新 LV、境界名稱／ERA、當時剩餘壽元（與 HUD 同一換算）；提升 Era 沿用原突破演出。載入、拒絕、DEBUG 直接設定等級不觸發；DEBUG 自動晉階共用正式路徑，會播放。
- 黑底全程不透明，文字展字／淡出，約 3.05 秒，可點跳過或 Esc。z_index 90 與播放時移至 HUD 最末子節點確保遮住導覽／操作頁並攔截輸入；旋轉提示仍優先。播放時阻擋再次晉階／突破，結束恢復原鏡頭鎖定；模擬持續，動畫不修改收益或保存。
- 修改 `src/abode/living_abode.gd`、`src/presentation/abode_modal_manager.gd`、`src/presentation/text_transition.gd`、`tests/text_transition_runner.gd`；新增 `tools/text_level_web_fixture.gd`、`tools/text_level_web_server.py`。
- Godot `--version`：4.7.2.stable.official.ed1daf0bf。六項 Runner（text_transition、m2b_breakthrough、island_breakthrough、m2d_responsive_ui、debug_autobuild_and_time、abode_presentation_parity）皆 PASS／exit 0；命令 `--headless --path . --script res://tests/<runner>.gd`，日誌 `artifacts/text-level-<runner>.log`。新增案例涵蓋內容表 Era 1／2 的 LV1→2、LV9→10、拒絕／防重入、真實文案、低動態、遮罩層級、跳過／自然完成與 snapshot 不變。正式內容表目前僅 Era 1／2，未捏造高階資料；未宣稱全量重跑。
- Web `--export-release Web build/web/index.html` exit 0，日誌 `artifacts/text-level-export.log`；fixture 產生命令 exit 0。Python server 綁定 127.0.0.1，隔離 origin 4188／4189；玩家 4175 未觸碰。最初 4187 fixture 庫存被容量截住，補測試倉儲後在新 origin 重驗。
- IAB 1280×720 真實點晉階看到黑底／展字，自然結束後重載仍為築基 LV9、不重播；844×390 晉階完整文案「境界等級提升至 LV9／築基期 ERA2 · 壽元剩餘 198 祀」，實際點跳過回到 LV9、拖曳鏡頭恢復。console warn/error 空。截圖 `artifacts/text-level-desktop.png`、`text-level-short.png`、`text-level-reload.png`。頁籤關閉、viewport reset、臨時 server 停止。
- 初次測試誤以為十二 Era 全有正式資料，Nil 型別錯誤後改遍歷已配置 Era；強制退出 exit 0 未算 PASS，修正後確認明確 PASS。沙箱 M2-B 保存重載失敗，正常授權重跑通過。根憑證／既有退出資源診斷保留，不宣稱日誌零錯誤。
- 下一步：收使用者閱讀／节奏回饋；實體手機／高 DPR／本輪 Web Esc 待驗。大型 M1-C/D 使用 New Chat。

2026-10-02，IN_PROGRESS：原生樣板、CLI 與 Web 匯出完成；使用者視覺、真實瀏覽器／觸控驗收待補。

## 方案與來源

使用者參考 [Text APNG Maker](https://kumachansteps.github.io/trpg-web-tools/tools/text-apng-maker/) 及附件，要求可供未來遊戲過場使用的文字演出。已讀官方 README 與 [使用條款第七節](https://kumachansteps.github.io/trpg-web-tools/tools/text-apng-maker/terms.html)。作者禁止未经許可複製、散布工具本體／主要部分；生成物使用許可不等於工具程式碼許可。官方 GitHub API 的 license 欄位亦為 null。因此沒有複製其 JS、編碼器、字型包或預設資料，改寫原創 Godot GDScript。

網頁生成器適合固定影片素材／外部 APNG；遊戲內使用原生 Label、容器、StyleBoxLine 與時間驅動動畫，可維持動態數值、已授權字型、解析度適配、跳過與低動態偏好，不必為每種壽元／境界輸出影格。本樣板不提供 APNG 編碼、雜訊特效或網站全部效果。

## 交付

- `src/presentation/text_transition.gd`：黑底白字；明體 800 主標、黑體 600 副標、兩側細線。展字／整句淡入、0.8 秒進場、預設 1.8 秒停留、0.45 秒退場。低動態只淡入。Esc 或 120×44 跳過按鈕。
- 使用全屏錨點、Center/VBox/HBox 容器，字級按可用高度與字寬縮小，長句可換行。竪向元件有測試，但正式遊戲仍遵循轉向提示。
- `living_abode.gd` 公開元件引用，`abode_modal_manager.gd` 建立元件、試播與鏡頭鎖定／恢復，`abode_hud_controller.gd` 設定選單加「過場文字樣板（試播）」ID 102。
- 試播固定示例「境界等級提升至 LV2／築基期 ERA2 — 壽元剩餘 80祀」；不是玩家突破結果。沒有接入正式突破／輪迴事件。遊戲模擬仍照常運行；播放完成與收益、存檔無關。
- `tests/text_transition_runner.gd`，`tools/run_all_runners.ps1` 登錄第 34 個 Runner；`tools/text_transition_preview.gd` 原生截圖，不讀取玩家存檔。
- 沒有新增第三方圖形資產；字型來源與授權沿用 `assets/fonts/README.md`。視覺構圖依使用者附件，動畫程式原創。

呼叫契約：在節點 ready 後 `play(main_text, detail_text, options)`。選項 `mode: "reveal" / "fade"`、`hold: 0.5..30.0`、`reduced_motion: bool`。`sequence_started` 與 `sequence_finished(skipped)` 供呈現層管理輸入；重播先取消前次，每次播放只完成一次。未來由成功的規則命令結果組合文案，先結算再演出；不得在動畫完成時發放收益。

## 驗證與限制

引擎仍為本機 4.7.2.stable.official.ed1daf0bf，Compatibility／單執行緒 Web。

| 命令／證據 | 結果 |
| --- | --- |
| Godot `--headless --path . --import` | exit 0 |
| Godot `--headless --path . --script res://tests/text_transition_runner.gd --quit-after 600` | 最終 PASS；中間展字、淡入、低動態、重播、跳過／自然完成唯一性；1280×720、844×390、390×844 長標題；設定選單接線、原鏡頭鎖狀態恢复、遊戲 snapshot 不變 |
| `powershell -NoProfile -File tools/run_all_runners.ps1` | 34/34 PASS，exit 0；`artifacts/text-transition/runners.log` |
| Godot `--headless --path . --script res://tests/abode_presentation_parity_runner.gd` | PASS，exit 0；`artifacts/text-transition/parity.log` |
| Godot `--path . --script res://tools/text_transition_preview.gd --quit-after 600` | exit 0；NVIDIA 1660 Ti 原生 GPU，四張 reveal／hold PNG；已檢視桌面與短橫向 hold |
| Godot `--headless --path . --export-release Web build/web/index.html` | exit 0；`artifacts/text-transition/export.log` |

首次新增 runner 因動態 panel 的 Rect2 推斷編譯失敗，補明確型別後重跑。首次縮放斷言使用實體尺寸卻仍受專案 stretch 影響；獨立 runner／截圖關閉視口 stretch 後測試真正的指定尺寸，正式遊戲不改 stretch 設定。移除 full-rect 元件的多餘 size 寫入，消除新增錨點警告。

完整 runner 的損坏保存 fixture 會故意產生 JSON/base64 錯誤；既有場景退出仍有 Font RID、CanvasItem、ObjectDB／resource in use 警告，exit 0 不能宣稱所有退出警告已修復。這些紀錄保留於 log。

CLI 訊號／函式測試不證明真實點擊命中、Esc、觸控或 Web DPR。瀏覽器工具此前不可用，本輪未取得真實瀏覽器互動證據；不要把匯出或 HTTP 200 當作互動通過。人工驗收：設定 → 過場文字樣板（試播），查看進退場，再分別點跳過／按 Esc；短橫向、DPR 1/2、手機重播並確認鏡頭可恢復操作。另驗低特效與長文案。

下一步先收使用者樣板回饋與瀏覽器／手機驗收；視覺放行後，再單獨決定哪些突破／章節事件使用此元件及各事件文案／停留時間。不要直接替換現有突破長演出或誤把示例數值當正式結果。
