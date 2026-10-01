# M2-D-TEXT1 — 原生過場文字樣板

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
