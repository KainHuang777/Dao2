# UIX-R2-F1 卷軸內層底板修訂

2026-10-10。狀態：實作／CLI／原生渲染及桌面Web有界通過，最終使用者美術接受待確認。

使用者兩張截圖指出分頁紙牌與卷軸軸頭衝突、目標卷軸中又套一層底板，要求不放大界面試調整。採單一紙面：分頁／返回／目標／說明按鈕常態透明，選中分頁為淡青玉底、深青文字與2px底線，hover／pressed保留不同濃度。FeatureTabs與GoalScroll使用細軸compact九宮格，其餘詳細卷軸與正式主操作保持既有樣式。沒有改外框位置、尺寸公式、觸控最小值或經濟／保存。

修改：`src/presentation/ui_material.gd`、`feature_navigation.gd`、`abode_hud_controller.gd`；原創`assets/ui/material/uix_scroll_compact.svg`及Godot生成import；資產manifest；隔離渲染工具`tools/uix_r2f1_preview.gd`／Godot UID；本驗收、ROADMAP、development-status、ai-handoff、UIX計畫及updata。開工既有大量dirty檔案保留，不commit／push。

命令與證據：

- 本機`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：4.7.2.stable.official.ed1daf0bf。
- 進程APPDATA=`E:/WORK/Dao2/build/uix-r2f1-user`；`--headless --path . --editor --import --quit` exit0，log=`build/uix-r2f1-import.log`。
- `--headless --path . --script res://tests/<runner>_runner.gd`：uix_r2_hud52/52、feature_navigation、m2d_responsive_ui、early_flow1b110，各exit0；四組log=`build/uix-r2f1-*-console.log`。既有RID／CanvasItem／ObjectDB及resource-in-use退出診斷仍存在，不宣稱引擎日誌零錯誤。
- `Start-Process -WindowStyle Hidden -Wait`執行`--path E:/WORK/Dao2 --script res://tools/uix_r2f1_preview.gd`，exit0。實際Godot渲染三橫式1280×720／844×390／800×360，五頁共15張全圖＋裁切；導覽高60，桌面目標高68。短橫式目標依既有規格隱藏，裁切工具的小圖不是可見目標證據。見[圖像目錄](artifacts/uix-r2-f1)，最終log=`build/uix-r2f1-preview.log`。
- `--headless --path . --export-release Web build/web/index.html` exit0；bundled Node `tools/prepare_web_compression.mjs build/web`完成三份壓縮與四首BGM companions，之後服務成功啟動。PCK SHA256=`FA94E46E74A937F0887C32E94ABE2BDC8B3A236800DB18D37CAE4E3A129D4BF8`。Windows未更新。
- bundled Python `tools/island_preview_server.py --port 48215 --normal-build --gzip`，獨立origin新檔Play，沒有seed或覆寫4175玩家存檔。沙箱服務初次連線timeout；停止後透過既有授權localhost服務重啟，成功載入。首次Cua tab變數綁定失敗但已開頁，後續取得同頁，未冒稱該次API成功。
- 真實滑鼠關閉離線摘要、進經營、切製造，再切800×360 CSS iframe與返回洞府。桌面首次iframe1280×650，DPR1.25，不能稱Web1280×720。截圖在[桌面製造](artifacts/uix-r2-f1/web-manufacturing.jpg)、[800製造](artifacts/uix-r2-f1/web-800.jpg)、[800返回](artifacts/uix-r2-f1/web-return-800.jpg)。最終warn/error查詢limit20為空。沒有新觸控／DPR2-3／保存或FPS矩陣聲明。
- Read-only文件命令曾有TotalCount文字參數及rg Windows glob錯誤，已改正讀取；與遊戲失敗無關。服務完成後Ctrl+C為刻意exit1，測試分頁已關閉。

仍待：使用者對單層紙面／細青銅軸的美術回饋；實體觸控／高DPR保持原待驗。EARLY-FLOW1-D節奏基線不改。依Context Guard完成本有界修訂即checkpoint，下一New Chat收畫面／節奏回饋，不開R3或Era4–12。
