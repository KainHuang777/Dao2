# IMM-0 介面修訂樣張

[開啟對照頁](index.html) · [洞府R2](r2/home-compare.png) · [製造R3](r3/manufacturing-compare.png) · [R1歷史比較](r1-index.html)

R3：製造左欄改圖像庫存，空島／運輸共用元件同步示例；新增20張PNG／10對（正常、缺料、庫存抽屜、運輸與空島，寬式／短式）。洞府沿R2，機緣主頁保留原版；[R2歷史](r2-index.html)。本輪取樣 `tools/imm0_r3_samples.gd`，共用研究元件 `tools/imm0_inventory_study.gd`，原始輸出 `.test-output/imm0-r3/`、交付 `r3/`。來源檢查見 [docs42](../../42-graphic-inventory-review.md)。正式共用元件尚未遷移。

這是原生 Godot 畫面的靜態審閱工具。現況直接使用目前正式元件；候選由 `tools/imm0_samples.gd` 在隔離場景修改呈現節點。兩者讀同份展示資料，不接玩家進度。R2依使用者決策修訂洞府大圖清單及製造正方形物品格，方向已寫入docs19；相關靜態原則已於2026-10-27由使用者接受，後續依[完整介面排程](../../43-full-ui-adjustment-plan.md)分批正式接入。機緣保留正式原版，R1分欄候選已撤下。

R2新增12張截圖／6組對照，另保留原版機緣；`r2/captures.json`及`r2/native-capture.log`記本輪取樣。R2取樣改用 `tools/imm0_r2_samples.gd`，輸出 `.test-output/imm0-r2/`。

R1歷史共26張截圖／13組對照：六個狀態各含1280×720與844×390，加一組短式選項末段。`captures.json` 記錄PNG、來源檔hash、成對狀態hash及渲染不改狀態的結果。比較大圖僅將兩張原尺寸截圖並排並加外側標題，沒有重畫介面文字。

素材全部沿用本專案現有世界、資源、機緣、紙面及字型，原有來源／提示詞／授權不變；沒有新增生成圖片、音效、Shader或第三方素材。介面文案仍由Godot Label／Button排版。

原生重新取樣（需要圖形環境，不能使用 `--headless`）：

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/imm0_samples.gd --audio-driver Dummy --rendering-method gl_compatibility --log-file .test-output/imm0-engine.log
```

原始輸出及隔離存檔位於 `.test-output/imm0/`；重新取樣不會自動更新本資料夾的已交付圖。這是靜態視覺研究，不是正常命令可達、瀏覽器遊戲輸入、保存故障或效能驗收。

本地檢視（也可直接以瀏覽器開啟 `index.html`）：

```powershell
python -m http.server 4402 --bind 127.0.0.1 --directory docs/visual-prototype/imm0
```

詳細交付狀態只記於 [development-status](../../development-status.md#imm-0-r3)。
