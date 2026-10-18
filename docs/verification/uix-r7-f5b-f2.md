# UIX-R7-F5-B-F2 轉盤位於外框上方

2026-10-18：**方案2已交付，IN_PROGRESS／待視覺接受**。

使用者確認轉盤圖本身完整，指出仍被外圈遮擋，提出精準接合留2px或提高轉盤圖層兩案。本輪採方案2：`effect.gd` 在固定外框加入共同投影父節點後，以 `move_child` 將轉盤移至同層最後繪製。外框index0、轉盤index1；這兩層局部換序，花、掛飾、霧與字柱的前後關係保持。保留F1素材、0.86縮放及中心校正，未重新繪圖，也未實作2px間隙方案。F1「修復接合」的描述不能視為使用者接受，仍受本次回饋修正。

[隔離Web](http://127.0.0.1:48915/index.html)已更新；[裸盤整圈](artifacts/uix-r7-f5b-f2/bare-motion.mp4)、[原生裸盤](artifacts/uix-r7-f5b-f2/solo-0.png)、[實際Web裸盤](artifacts/uix-r7-f5b-f2/web-bare.png)可比較。新證據放獨立F2資料夾，F1素材與影格保留。

- Godot `--version`：exit0，4.7.2.stable.official.ed1daf0bf。
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_r7f5b.ps1 -ExportWeb -EvidenceName uix-r7-f5b-f2`：exit0；本輪import/export.log無ERROR，僅更新隔離Web。
- `Godot --path build/r7f5b-project --script res://capture.gd --log-file .../uix-r7-f5b-f2/capture.log`，APPDATA=`build/r7f5b-user`：exit0；checks.json failures=[]，記錄draw_order為housing0／rotor1。三原生尺寸、低特效／暫停／隱藏與字形沿同runner通過，八角度及384影格已輸出。
- `ffmpeg -framerate 24 -i .../bare-frame-%03d.png -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart .../bare-motion.mp4`：exit0；800×600、192影格、8秒固定時間實際Godot渲染，不是即時FPS證據。
- IAB重載與實際滑鼠切裸盤，目視轉盤邊緣／刻紋完整顯示；截圖與browser-evidence.json保留。未重跑與本次層序無關的完整Web操作矩陣或持續效能。

修改檔：`src/verification/r7f5b/effect.gd`、`capture.gd`、本輪證據與交接文件。沒有新增美術或改正式頁／遊戲規則／保存／一般Web／玩家資料，未commit/push。下一New Chat先收方案2視覺回饋；B尚未接受，C／D未開。
