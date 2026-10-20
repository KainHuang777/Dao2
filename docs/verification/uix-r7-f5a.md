2026-10-18 最終更新：本工作已隨F5最終組合接受與本次簡單驗收收結（DONE）；下方待接受／未開及舊效能判定為歷史。F5-A僅記素材交付隨B接受收結，不追認獨立靜態審查。舊60／300秒PASS只證明背景運行，未涵蓋輪迴操作負載；依使用者本次指令不再以長時壓測阻擋。見[最終簡單驗收與範圍](uix-r7-f5-simple.md)。

# UIX-R7-F5-A 拆層與補繪

2026-10-18：**素材與靜態檢查已交付；IN_PROGRESS，待使用者美術接受**。F5-B 未開始。本輪依原畫同風格重建完整圖層，不是逐像素復原原圖被遮住的部分。

## 可檢查成果

- [四角度重組標示圖](artifacts/uix-r7-f5a/four-angles-labeled.png)：由左上到右下為順時針 0／90／180／270°。只有盤面改變角度。
- [四角度裸盤](artifacts/uix-r7-f5a/four-angles-bare-labeled.png)：移除花、流光與霧，直接檢查完整盤面及固定外殼接合。
- [九層標示圖](artifacts/uix-r7-f5a/layers-labeled.png)：後霧、盤面、外殼、掛飾、蓮花、發光遮罩、流光、左前霧、右前霧。
- [黑底](artifacts/uix-r7-f5a/composite-black.png)、[灰底](artifacts/uix-r7-f5a/composite-gray.png)、[白底](artifacts/uix-r7-f5a/composite-white.png)重組。每個圖層同時有 `圖層ID-black/gray/white.png`。
- [尺寸比較](artifacts/uix-r7-f5a/resolution-comparison.png)：左至右為512／768／1024來源縮至460px；本輪保留1024候選，細遮罩有較多取樣餘裕。這是離線PNG比較，不是實機GPU／FPS證據。
- [資產與manifest](../../assets/ui/reincarnation-layered-f5a/manifest.json)、[完整生成提示詞與來源](artifacts/uix-r7-f5a/generation-records.json)、[檢查結果](artifacts/uix-r7-f5a/qa.json)。

## 資產契約

`assets/ui/reincarnation-layered-f5a/` 有九張1024×1024 RGBA PNG。所有圖層原點為左上(0,0)，基準縮放1；盤面／外殼平面pivot=(512,512)。盤面先旋轉，再由固定父投影縮放(962/1024,922/1024)、平移(31,-11)，投影中心為(512,450)。其他圖層已在重組座標內，不可再次套盤面投影。

原畫1254×1254保留於R7原目錄。本輪內建ImageGen十次輸出（含兩版遮罩）均複製到本專案 `artifacts/uix-r7-f5a/originals/`；生成尺寸不一，離線工具明確對位到共同工作畫布。蓮花／遮罩保留整張來源畫布按同一矩形縮放，不能分別自動裁切再對位。掛飾來源左右分半後註冊到固定外殼兩側；未生成新的UI文字或字型。

盤面補滿中央與360°外周，沒有花、霧、流光和掛飾；朱砂三旋紋章作轉動追蹤。固定外殼保留自己的玉帶／金銅花紋與底右厚度，無旋轉盤紋殘片。前後雲霧完整獨立，移開後盤面也有完整內容；不靠遮霧補洞。

遮罩首稿與第二稿皆仍含灰色花瓣填色及外暈，不直接當發光圖。工具按生成灰階 `smoothstep(0.88,0.98)` ×來源alpha讀出近白邊線，輸出白RGB／alpha強度遮罩；灰色填色不發光。已目視灰底遮罩為花瓣細線，沒有整朵白花。尚未宣稱柔光Shader、呼吸動畫或實際Godot材質視覺通過；F5-B必須確認動態疊加與局部光暈。

manifest記錄prompt、來源與成品SHA256、用途ID、尺寸、pivot、z序、mask關係、投影與授權說明。來源為本專案既有AI圖＋本輪內建ImageGen重建；沒有引入外部第三方圖片，亦不冒稱第三方商業授權。

## 命令與結果

| 命令／工具 | 結果 |
| --- | --- |
| `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` | exit0；4.7.2.stable.official.ed1daf0bf |
| 內建 `image_gen.imagegen` | 十次完成；九種層，遮罩保留兩次原稿；所有prompt與原圖落盤 |
| `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/uix_r7f5a_assets.gd` 首跑 | exit0、九層包裝通過；有 `Failed to open log file ... user://logs/godot.log`，不宣稱零錯誤 |
| 同上加 `--log-file E:/WORK/Dao2/docs/verification/artifacts/uix-r7-f5a/packaging.log` 最終跑 | exit0，9 layers、failures=[]；[日誌](artifacts/uix-r7-f5a/packaging.log) |
| `tools/uix_r7f5a_review.ps1` | exit0；System.Drawing標示九層與兩組四角度QA圖 |
| PowerShell `Get-FileHash`／嚴格UTF-8解碼／`git diff --check` | 九組原稿與成品hash、九份文字UTF-8及限定文件diff-check通過；Git提示updata未來轉CRLF，非檢查失敗 |

工具檢查PNG寫入、各層至少24px透明安全邊、四角度中央盤面覆蓋；目視四角度裸盤／重組、黑白底、遮罩與尺寸比較，未見盤面洞、花霧殘影或旋轉帶動外殼。這是靜態檢查，不代替連續動畫證據。生成圖與重組圖由 `view_image` 實際查看。

修改檔案：上述新資產／證據資料夾、`tools/uix_r7f5a_assets.gd`、`tools/uix_r7f5a_review.ps1`、本驗收頁，以及README、ROADMAP、ai-handoff、development-status、docs22與updata頂部交接。保留工作區所有既有dirty成果，未commit／push。未更動正式遊戲接線、規則、保存、字型或一般Web匯出。

## 未通過與下一步

使用者靜態美術接受仍待取得，因此不標F5-A完整DONE。F5-B待A接受後在New Chat開始：單一隔離Godot盤／花／霧／豎排字試演，提供實際組合錄影與可互動預覽。B視覺接受前不更新一般Web。F5-C／D接線與效能證據未由本輪靜態素材推定。

英文checkpoint已置於 `updata.txt` 頂部；本階段停止於F5-A交付。
