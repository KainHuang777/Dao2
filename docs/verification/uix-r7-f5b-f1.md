# UIX-R7-F5-B-F1 裸盤接合／強泛光／梵文字柱

2026-10-18：**修訂試演交付，IN_PROGRESS／待視覺接受**。使用者指出 B 裸盤中央切割感與文字泛光太弱，並要求試加梵文延長字柱。本輪止於 B 修訂，不開 C。

## 可直接比較

- [同一隔離 Web](http://127.0.0.1:48915/index.html)：已重新匯出，必要時重新整理。
- [裸盤完整一圈](artifacts/uix-r7-f5b-f1/bare-motion.mp4)、[中文＋梵文合成動畫](artifacts/uix-r7-f5b-f1/composite-motion.mp4)：各800×600／24fps／8秒，固定時間的實際Godot渲染；不是即時FPS證據。
- [Web 裸盤](artifacts/uix-r7-f5b-f1/web-bare.png)、[泛光開](artifacts/uix-r7-f5b-f1/web-glow-on.png)／[泛光關](artifacts/uix-r7-f5b-f1/web-glow-off.png)：同一暫停時刻，以實際滑鼠切換。
- [原生裸盤](artifacts/uix-r7-f5b-f1/solo-0.png)、[直排字獨播](artifacts/uix-r7-f5b-f1/solo-3.png)、[800×360](artifacts/uix-r7-f5b-f1/composite-800x360.png)。
- 八角度裸盤：`bare-angle-000/045/090/135/180/225/270/315.png`，位於本輪 artifacts。

## 修正

舊盤面沒有透明破洞，但這不足以排除使用者指出的切割感。目視中央紋樣、裸盤與接合後，確認轉盤相對固定開口過大，外圈紋飾部分受遮，固定開口中心也不是工作畫布中心。本輪並行修正圖與組合：

1. 以內建 ImageGen 重繪連續完整的盤心與同心刻紋，保留青玉／古金／三枚朱砂旋紋。新資產放 `assets/ui/reincarnation-layered-f5b-f1/disc_face.png`，原A素材未覆寫。原稿、[完整prompt](artifacts/uix-r7-f5b-f1/generation-record.md)、[manifest](../../assets/ui/reincarnation-layered-f5b-f1/manifest.json)與hash保存。
2. 以 alpha>0.5 的實體範圍註冊至1024畫布、560×560矩形、pivot(512,512)；旋轉Sprite縮為0.86，保留普通外唇與外殼的小幅遮擋，不再以外殼截去主要刻紋。固定外殼開口中心(517.5,500.5)以offset(-5.5,11.5)對準旋轉中心。只盤面轉、外殼不轉。
3. 文字獨立新 `glyph_glow.gdshader`：暖白芯、金色近光、橙色外暈，半徑22來源px、強度4.5；開關可直接看見輪廓外差異。蓮花沿原局部呼吸光。
4. 每柱改192×480快取：上方中文兩字，下方完整梵文字群 `ॐ`／`मणि`／`पद्मे`／`हूँ`（Om mani padme hum）。這是重複裝飾咒句，**不是六個中文道名的逐一翻譯**。[用語參考](https://www.dalailama.com/news/2019/empowerment-of-avalokiteshvara-lord-of-the-world)。Godot保留每組連字及母音符號，不逐Unicode碼位拆行；快取後停止Viewport更新。
5. 新增未修改的官方 [Noto Sans Devanagari](https://github.com/notofonts/noto-fonts/tree/main/hinted/ttf/NotoSansDevanagari) 字型與OFL；[來源／hash／用途](../../assets/fonts/reincarnation-f5b/README.md)、`Noto-OFL.txt`保存且列入隔離匯出。中文與控制字型保持。長柱初版重疊後，出場間隔調為1.3秒、循環7.8秒、單柱3.6秒；同時約2–3列。

附圖只作泛光強度／暖色感參考；沒有複製其法陣、字體圖樣或符文。新盤圖由本專案AI參考編修；不宣稱取得附圖商用授權。固定外殼、蓮花及霧圖未重製。

## 驗證與命令

Godot版本仍 `4.7.2.stable.official.ed1daf0bf`；原生Compatibility／GTX1660Ti。APPDATA保持`build/r7f5b-user`；獨立場景不載入GameSession或玩家存檔。

| 命令／工具 | 結果 |
| --- | --- |
| Godot `--version` | exit0，4.7.2 |
| 內建ImageGen一次 | 完成透明盤圖；原稿及prompt保存。官方Noto下載／OFL完成 |
| Godot `--headless --path . --script res://tools/r7f5b_f1_assets.gd --log-file .../asset-registration.log` | exit0；註冊成功，半徑225中央區域alpha缺口0。這僅驗alpha，非美術通過 |
| `powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_r7f5b.ps1 -ExportWeb` | 最終exit0；本輪import/export.log無ERROR，單執行緒Web。build工具可用EvidenceName另存日誌 |
| Godot `--path build/r7f5b-project --script res://capture.gd --log-file .../capture-delivery.log` | exit0，checks.json failures=[]；中文／梵文字形涵蓋、快取停更、3尺寸44px／控制可達、旋轉獨立／開口對齊、隱藏／暫停／低特效通過；8角度及384影格存圖成功 |
| ffmpeg：`-framerate 24 -i .../frame-%03d.png -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart .../composite-motion.mp4`；裸盤以`bare-frame-%03d.png`另編 | 兩次exit0；各192影格／8秒，編碼log保留 |
| IAB真實滑鼠／截圖 | 暫停、泛光開關、裸盤／合成、三尺寸、低特效與重載已核對；記錄於browser-evidence.json。規則回歸與FPS未重跑 |

初次重繪後仍觀察到舊外殼裁切，隨後補縮正／對位；初次長柱出場重疊已修。這些中間版本不作最終通過證據。以capture-delivery.log、checks.json及最終Web hash為準；舊B圖像／錄影保留供對照，舊驗收中的可用判定不代表使用者視覺接受。

修改：新盤圖與manifest／生成紀錄、Noto字型與授權、effect.gd、glyph_glow.gdshader、capture.gd、獨立export_presets.cfg、build_r7f5b.ps1、r7f5b_f1_assets.gd與文件交接；保留UID。正式輪迴／規則／一般Web／玩家資料未修改，未commit/push。

狀態仍為 **B修訂已交付、待使用者接受**；下一New Chat先收本版裸盤與文字效果回饋。C接線及D持續效能未開。
