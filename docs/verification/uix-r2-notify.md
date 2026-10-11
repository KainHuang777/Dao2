# UIX-R2-NOTIFY 紅點與提示解鎖修復

2026-10-10。狀態：來源／CLI／Web匯出與桌面滑鼠紅點流程通過；Web tooltip停留畫面與實體觸控／高DPR待驗。

根因：任一修行待辦成立就固定列三項文字，遊歷同樣固定列兩項；紅點與HUD狀態列未套用FeatureUnlocks。修正以共用notification_flags判定頁面AVAILABLE與真實待辦，逐項組合tooltip，保留壽元耗盡時的輪迴頁資格。成就Era1可用，靈獸Era1/2不提示，機緣Era1不提示，宗門保留輪迴過一次後Era1可用例外。頁面一般路由、規則與存檔版本未改。

修改來源：src/presentation/feature_unlocks.gd、feature_navigation.gd、buff_hud_bar.gd。測試：tests/uix_r2_hud_runner.gd、feature_navigation_runner.gd、buff_system_runner.gd。既有合成fixture補上已解鎖Era，沒有刪除舊斷言。

命令／結果：

- 本機tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version：4.7.2.stable.official.ed1daf0bf。
- 隔離APPDATA=E:/WORK/Dao2/build/uix-r2-notify-user；--headless --path . --script res://tests/<runner>_runner.gd：HUD67/67、feature_navigation、buff_system、uix_r1_components74/74、m2d_responsive_ui全部exit0。log為build/uix-r2-notify-hud.log及各runner同前綴log。覆蓋Era1僅成就、鎖定flags、Era2獸預覽、Era3餵養、多項合併、壽盡輪迴、輪迴後宗門、通知唯讀。
- 原有Font RID／CanvasItem／ObjectDB／resource-in-use退出診斷保留，不稱日誌零錯誤。
- --headless --path . --export-release Web build/web/index.html exit0，build/uix-r2-notify-export.log；bundled Node執行tools/prepare_web_compression.mjs build/web exit0。PCK SHA256=55C4CF18EEC1A6F4C228C1BE4A2A7A176C0836E1BF69E8C6ACD0F4341DFFD6C3。
- git diff --check針對本輪tracked來源／測試exit0（CRLF提醒）；feature_unlocks原本為untracked，已保留。
- bundled Python tools/island_preview_server.py --port 48216 --normal-build --gzip。初次未啟動連線refused、沙箱localhost timeout，重啟已授權服務後成功。Cua IAB新origin Play/no seed：正常Era1新檔、關離線摘要、20次採集、真實建茅屋，修行紅點／成就1成立，開修行不清除。桌面iframe1280x650，未稱1280x720。warn/error查詢limit10為空。CLI精確tooltip字串已驗，瀏覽器停留tooltip未成功顯示，不以紅點截圖替代tooltip證據。

不觸碰4175玩家origin或既有dirty成果；不更新Windows、不commit/push、不重跑已接受FPS／保存矩陣。一般Web已更新，已開啟頁面需重新載入新版。

下一步：收使用者紅點提示回饋；可補Web tooltip停留及實機驗收，原EARLY-FLOW1-D人類節奏／装置限制保持。完成本有界修訂即checkpoint，不開下一大型任務。
追加桌面Web驗收：滑鼠切成就頁→內部捲動→領取仙家草廬，顯示已領取，成就•1與修行紅點同時清除。測試tab已關閉，48216服務Ctrl+C刻意停止exit1。
