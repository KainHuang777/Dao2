# M2-D-UI6：思源黑體試套與取捨

## 2026-10-02 追加：UI6-R1 黑體資訊＋粗明體題字

使用者接受混搭，要求章節題字加粗。新增 `UiTypography.chapter_font()`：既有 Noto Serif TC 可變字型 **800**；營造簿、煉丹、宗門、輪迴、跨界、機緣、九界七個主標題與洞府題字採此角色。正文與密集數值仍為思源黑體 400，操作及小型建築標籤仍為黑體 600。未變更文字內容、字級、命令與存檔。

**字重證據更正**：本輪從 TextServer 讀取真正的 variation coordinates，發現先前字串 `wght` 設定在此引擎／資源組合沒有生效（座標為空）。改為 OpenType 整數 tag `0x77676874`，實際座標確認 400／600／800。10-01 的原生圖像仍是當日證據，但不能當成已生效 400／600 的證據；當日取樣寬度是當時的實際顯示值，不能當成指定字重比較。`tools/font_trial_audit.gd` 現在會在實際座標不符時 exit 1，新取樣與原明體中繼資料見 `artifacts/ui-mixed/font-audit.json`。使用 [Godot 官方 FontVariation 範例](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html) 的唯一軸 tag 方式。

明體中繼資料確認 Noto Serif TC／Adobe、2017–2023 Adobe 版權、OFL 1.1、200–900 軸範圍；原字型未修改，原始下載雜湊來源仍不追認。新增 `assets/fonts/NotoSerifTC-LICENSE.txt` 保留嵌入版權及完整 OFL，`export_presets.cfg` 恢復打包明體並包含兩份授權。

修改檔案：`ui_typography.gd`、`living_abode.gd`、七個主要面板標題（`building_catalog.gd`、`alchemy_panel.gd`、`sect_panel.gd`、`reincarnation_panel.gd`、`realm_teleport_modal.gd`、`fortune_modal.gd`、`nine_realms_preview.gd`）、`tools/font_trial_audit.gd`、`tools/ui_material_preview.gd`、`export_presets.cfg`、資產授權及 README。

引擎仍為 Godot 4.7.2；命令：`--headless --path . --script tools/font_trial_audit.gd --quit-after 600 -- --mixed-font`（實際字重與來源覆蓋驗證 exit 0）；`--path . --script tools/ui_material_preview.gd --quit-after 600 -- --mixed-font` 及追加 `--guidance-hud`（共 20 張 native 圖，exit 0；桌面管理、宗門、短橫向煉丹已檢查）。其餘最終回歸與 Web 匯出結果見 `artifacts/ui-mixed/runners.log`、`parity.log`、`export.log`。

最終結果：`tools/run_all_runners.ps1` 33/33 PASS、exit 0；`--headless --path . --script tests/abode_presentation_parity_runner.gd --quit-after 600` PASS、exit 0；`--headless --path . --export-release Web build/web/index.html` exit 0，4178 HTTP 200。均在整數字重軸修正後完成。

此修訂 IN_PROGRESS：方向已使用者核定，實際粗字視覺／Web DPR／手機證據待驗。既有退出資源警告保留；native 與 HTTP 證據不代替實機。預覽 `http://127.0.0.1:4178/index.html?ui=mixed-font-20261002`；下一步先收混搭視覺回饋，不自動展開大型功能。

2026-10-01，IN_PROGRESS：來源、授權、全遊戲試套及 CLI/native 證據完成，使用者與 Web／手機視覺待驗。

依使用者指定 Adobe Source Han Sans 官方 README-TW，採 **2.005R 的 `SourceHanSansTW-VF.ttf`**，官方 Taiwan 區域設定、可變 TrueType，未自行裁字或修改字型。11911704 bytes，SHA256 `CF6889F4C0F1ADEAF814CA3E98CC692D9E2D706501CF7545B9B58F6E3966B6AC`。Adobe SIL OFL 1.1 完整授權在 `assets/fonts/SourceHanSans-LICENSE.txt`，Web `include_filter` 明確打包該檔。舊明體保留在來源作比較，但從 release 排除；沒有刪除舊素材。

## 實作

共用 `UiTypography` 正文 400、強調 600（舊版明體為 600／700），RichTextLabel normal/bold 也接入共用角色。九界舊直接 preload 改為新字型，基本字型 Runner 同步。既有字級、紙底／玉石、Godot 容器及命令不變。Godot 匯入使用灰階抗鋸齒、hinting=3、subpixel_positioning=4，不新增全域 MSDF 或世界模糊。

直接掃描 `src/*.gd` 及 `content/*.json`（遞迴，包含註解），關閉系統補字後檢查：**1501 種漢字均由字型自身覆蓋**。第一次找到五種非漢字缺字：⏩、⏳、✨、⤡、⤢；分別移除跳過／壽盡／展開按鈕的裝飾符號、以原已有 ★ 取代機緣提醒，保留提示語意與操作。最終相同來源範圍的漢字及非 ASCII 字元缺字清單均為空。這不代表完整 Unicode、使用者自訂姓名或未來文本皆有字形。

修改：`src/presentation/ui_typography.gd`、`src/presentation/nine_realms_preview.gd`、`src/presentation/abode_hud_controller.gd`、`src/presentation/reincarnation_sequence.gd`、`tools/test_runner.gd`、`tools/ui_material_preview.gd`、`tools/font_trial_audit.gd`、`export_presets.cfg`；新字型、授權與来源 README 在 `assets/fonts/`。未修改玩法或存檔。

## 容量以外的評估

1. **美術氣質**：原生主畫面、資源、訊息與宗門截圖中，小字筆畫較均勻，但明體的粗細與收筆消失，章節題字與世界銘牌較現代。此為視覺判斷，仍需使用者確認。建議日後可讓黑體承擔密集資訊，少數標題再用獨立明體角色；本次先全套試黑體，未偷偷混搭。
2. **度量改變**：用實際正文角色比較；17px「境界：練氣期 · 6/10 層」舊 170、新 181（+6.5%）；「系統訊息 · 新手引導」151→161（+6.6%）；「修煉 32/121 秒 · 壽元 58/88 祀」227→235（+3.5%）；ASCII 數字例151→146。取樣總行高 25→25。不能以同字級推定同寬，按鈕、換行、表格應回歸；原生 core 及短橫向圖像、版型測試已檢查。
3. **地區字形與字元範圍**：TW 適合目前繁中預設，但未來日文、韓文、港式字形或罕字名稱需要按地區和實際內容選擇字型／fallback。此次沒有把 TW 子集當作所有 CJK 或所有 emoji 的保證。
4. **縮放與效能**：黑體不會自行解決低 DPI、非整數鏡頭縮小、描邊或字型快取問題。沿用既有可變字型角色與灰階抗鋸齒；未做 FPS、GPU atlas 記憶體或弱手機效能基準，不宣稱新字型更快或所有倍率皆無鋸齒。
5. **授權維護**：商用嵌入／軟體分發可行，但分發需保留版權及 OFL，不能把字型單獨出售；若未來自行修改／裁字須核對 Reserved Font Name 規則。当前為未修改官方檔。

官方來源：[README-TW](https://github.com/adobe-fonts/source-han-sans/blob/2.005R/README-TW.md)、[2.005R 發行](https://github.com/adobe-fonts/source-han-sans/releases/tag/2.005R)、[完整授權](https://github.com/adobe-fonts/source-han-sans/blob/2.005R/LICENSE.txt)。Godot 字型角色與 fallback 依[官方字型指南](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)。

## 命令與證據

- Godot 4.7.2 `--headless --path . --import` exit 0；`SourceHanSansTW-VF.ttf.import` 自動生成，未手改 `.godot`。
- `--headless --path . --script tools/font_trial_audit.gd --quit-after 600` exit 0；字形範圍、可變軸 250–900 與實測度量見 `artifacts/ui-sans/font-audit.json`。
- `tools/run_all_runners.ps1`：最終 33/33 Runner PASS、exit 0（`artifacts/ui-sans/runners.log`）。
- `--headless --path . --script tests/abode_presentation_parity_runner.gd --quit-after 600` PASS、exit 0（`artifacts/ui-sans/parity.log`）。
- `--path . --script tools/ui_material_preview.gd --quit-after 600 -- --font-trial`，加 `--guidance-hud` 另擷取引導完成視圖：exit 0，`artifacts/ui-sans/core/` 16 張及 `guidance/` 四張。已檢查桌面、短橫向主介面／訊息與宗門；皆為隔離 native Compatibility 截圖。
- `--headless --path . --export-release Web build/web/index.html`：exit 0，授權文字確實打包（`artifacts/ui-sans/export.log`），本機服務 HTTP 200。預覽 `http://127.0.0.1:4178/index.html?ui=sans-20261001`。

既有 Font RID／CanvasItem／ObjectDB 結束警告保留。待驗：真實 Web 高 DPI、輸入、實體手機、冷啟動／效能測量及使用者對全套黑體的視覺選擇。Native 字形與 CLI 成功不能替代以上證據。下一步先比較黑體正文與美術氣質，再決定是否保留少量明體標題，不自動新增下一個大型 UI 工作。
