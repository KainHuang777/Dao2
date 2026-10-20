2026-10-18 最終更新：本工作已隨F5最終組合接受與本次簡單驗收收結（DONE）；下方待接受／未開及舊效能判定為歷史。F5-A僅記素材交付隨B接受收結，不追認獨立靜態審查。舊60／300秒PASS只證明背景運行，未涵蓋輪迴操作負載；依使用者本次指令不再以長時壓測阻擋。見[最終簡單驗收與範圍](uix-r7-f5-simple.md)。

2026-10-18 後續使用者回饋：本版裸盤有切割感、泛光不足，不能視為已接受。已由[F5-B-F1修訂](uix-r7-f5b-f1.md)接續；下方是原始B歷史紀錄，當前隔離URL已更新為F1。

# UIX-R7-F5-B 隔離動態試演

2026-10-18：**試演、原生檢查與桌面 Web 交付；IN_PROGRESS，待使用者視覺接受**。

本輪使用者明確指定「F5-B 隔離動態試演」，授權接續 B；不將此指令記成 A 的獨立美術接受。沿用 A 九層與 manifest，A 的歷史素材／靜態證據保留。B 接受前不開始 C 正式接線或 D 持續效能驗收。

## 檢視入口

- [可互動隔離 Web](http://127.0.0.1:48915/index.html)：獨立專案，沒有玩家進度或存檔操作。服務只提供 `build/web-r7-f5b`。
- [8 秒 Godot 合成動畫](artifacts/uix-r7-f5b/isolated-motion.mp4)：800×600，192 張實際 Compatibility 渲染影格，以明確時間步進至 8 秒並編為 24fps MP4。這是固定時間渲染錄影，**不是即時 FPS 或 D 的效能證據**。
- [桌面原生](artifacts/uix-r7-f5b/composite-1280x720.png)、[844 原生](artifacts/uix-r7-f5b/composite-844x390.png)、[800 原生](artifacts/uix-r7-f5b/composite-800x360.png)。
- [Web 最小橫式](artifacts/uix-r7-f5b/web-800-css-final.png)、[Web 紙底](artifacts/uix-r7-f5b/web-800-paper.png)、[Web 中間尺寸](artifacts/uix-r7-f5b/web-844-css-final.png)。
- [原生柔光開](artifacts/uix-r7-f5b/glow-on.png)／[關](artifacts/uix-r7-f5b/glow-off.png)；[裸盤](artifacts/uix-r7-f5b/solo-0.png)、[花光](artifacts/uix-r7-f5b/solo-1.png)、[雲霧](artifacts/uix-r7-f5b/solo-2.png)、[直排字](artifacts/uix-r7-f5b/solo-3.png)。

操作：暫停／繼續、重播、演出／常態速度、柔光開關、低特效、合成／裸盤／花光／雲霧／直排字、紙／夜。常態 36 秒一圈，演出 8 秒一圈；B 是可反覆觀察的連續試演，尚未接正式 6.2 秒轉世時間軸。

## 實作與來源

來源放在 `src/verification/r7f5b/`；`.gdignore` 隔離主專案掃描。`tools/build_r7f5b.ps1` 將來源與指定素材複製到 `build/r7f5b-project`，以現有 4.7.2 匯入與匯出到 `build/web-r7-f5b`。僅修改來源再重建，沒有手改 `.godot` 或匯出物。新的 Godot `.uid` 已保存回來源。

`effect.gd` 將盤面 Sprite2D 放在固定投影 Node2D 內，盤面先轉、父投影保持 (962/1024,922/1024)、中心 (512,450)；外殼同投影但不轉。花、遮罩、掛飾及前後霧獨立；花上下 14/1024、3.6 秒週期，霧左右錯速移動。Shader 均為本案自寫，沒有複製外部特效程式或安裝套件；花瓣與字外柔光採局部 alpha 鄰域取樣，沒有全螢幕 pass 或環境 Glow 依賴。

六組字串為「天人、人間、修羅、畜生、餓鬼、地獄」，各字正立上下排。每秒錯開一組、生命 3.6 秒、同時最多四列；末段噪聲消散，另有 24 個確定性裝飾微粒。每組 128×256 SubViewport 初始化一次後 UPDATE_DISABLED，運行只動 Sprite。全部動畫／霧 Shader 使用傳入 clock；暫停、隱藏與低特效停止推進。低特效保持固定盤／花／六組字。

裝飾字採未修改的 [Google Fonts 官方 LXGW WenKai TC Regular](https://github.com/google/fonts/tree/main/ofl/lxgwwenkaitc)，SIL OFL 1.1；[下載來源、hash 與用途](../../assets/fonts/reincarnation-f5b/README.md)、[完整授權](../../assets/fonts/reincarnation-f5b/OFL.txt)已保存，未安裝到系統。十二字由 Godot Font.has_char 檢查；按鈕沿現有 Dao2 Sans。這是文楷候選，筆觸與最終水墨風格仍由使用者接受。紙底用深青墨芯／淡金暈，夜底用暖白芯／青綠暈。

桌面控制列在下方；高度 <500 改右側三欄工具區，讓主圖保有高度。以容器與錨點配置，按鈕至少44px。此為獨立開發試演工具，不修改正式 GameTab／CloseSeal 或頁面樣式。

## 命令與實測結果

環境：Windows、Godot `4.7.2.stable.official.ed1daf0bf`、Compatibility；原生 OpenGL 3.3 NVIDIA GTX1660Ti，驅動610.88。Web 為 Codex 內建 Chromium，三 CSS 尺寸1280×720／844×390／800×360、尺寸覆寫時DPR約1，恢復預設為DPR1.25；兩者均檢視。Web以CSS寬高設定Godot content_scale_size，避免backing buffer的DPR縮小44px操作；非實體裝置。

| 命令／工具 | 結果 |
| --- | --- |
| 引擎 `--version` | exit0，4.7.2 |
| PowerShell 下載官方字型／OFL | 沙箱首跑DNS失敗；正常授權程序重跑完成，hash保存 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_r7f5b.ps1 -ExportWeb` | 最終 exit0；[匯入](artifacts/uix-r7-f5b/import.log)／[匯出](artifacts/uix-r7-f5b/export.log)無 ERROR。建置工具另掃描錯誤，不只依退出碼 |
| `Godot --path build/r7f5b-project --script res://capture.gd --log-file .../capture-verified.log`，APPDATA 指向 `build/r7f5b-user` | exit0；[檢查](artifacts/uix-r7-f5b/checks.json) failures=[]；[原生log](artifacts/uix-r7-f5b/capture-verified.log) |
| 原生捕捉腳本 | 三尺寸全部控制可達／44px；字形涵蓋；快取停止；盤兩秒90°且花／殼不轉；霧反向；暫停／隱藏停止；低特效靜態；192張PNG寫入均通過 |
| `ffmpeg -framerate 24 -i .../frame-%03d.png -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart .../isolated-motion.mp4` | exit0；[編碼log](artifacts/uix-r7-f5b/encode-final.log)；192影格／8秒 |
| `python tools/web_static_server.py --port 48915 --directory build/web-r7-f5b` | 已啟動，提供隔離包。沙箱服務對IAB的127.0.0.1／localhost首試逾時；停止本輪該服務後，正常授權重啟服務可連線 |
| `cua_repl` IAB 真實滑鼠／截圖 | 三尺寸、暫停／繼續、柔光關、裸盤／合成、低特效、紙底及重載可操作；最終預覽恢復動畫與夜底。截圖與browser-evidence.json保存 |

首輪 Godot 雖 exit0 仍出現 `shown` 型別推斷錯誤及 user:// profiler 目錄錯誤；改明確 bool 與隔離 APPDATA 後重建成功。目視另修短式主圖太小、字出場重疊、Shader 將外暈再乘來源alpha導致柔光消失、試演標籤「豎」未在既有字型子集中（改「直排字」）；最後補CSS尺寸橋接與延後讀取resize，修正DPR1.25按鈕縮小及resize事件時序造成留黑邊，最終三尺寸重排與預設比例已複核。初期錯誤不算通過；最終原生／Web為修訂後版本。保留較早capture/build日誌作過程記錄，最終以 verified／final 檔及目前匯出hash為準。

隔離 PCK SHA256：`7FE40622EA6C02F5A89756B3B6B399AF50E6D18340ABB8DF196509D35C6DD272`。

## 邊界與交接

沒有改正式輪迴頁／轉世序列、規則、Session、存檔或一般 Web；這個獨立專案未載入任何遊戲核心，也沒有 user:// 寫入程式。只用隔離引擎資料目錄。保留所有既有 dirty 工作，未 commit／push。本輪不因隔離視覺程式而重跑正式全量 Runner；不以直接呼叫檢查代替上表真實滑鼠證據。

仍待使用者接受盤面轉動、蓮光、霧流、字體與柔光的組合視覺；B 不標 DONE。C 正式接線／保存／skip 回歸與 D 60秒＋5分鐘效能尚未執行。下一 New Chat 先收 B 回饋，接受後再明確開 C。觸控／實機依既定政策延期，非當前阻擋。
