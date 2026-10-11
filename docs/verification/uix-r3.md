# UIX-R3 頁面外殼與開放進度接入

2026-10-10。使用者選擇「接續 UI 改造：整理下一階段範圍並實作」。R1／R2 有界交付滿足相依。本輪收斂至共用分頁、關閉、三態接入與資源策略；完整美術／實體觸控／高 DPR 仍待驗。

## 範圍與實作

- 固定洞府／經營／修行／遊歷四入口，沿用已接受的玉質 Dock 與 F1 輕量卷軸。不採舊提案的依進度減少 Dock 數量，也不變更資源三態或新建儲物袋。
- 頁面分頁使用 GameTab，紙面透明常態、選中淡青玉底線；CloseSeal 固定 44×44，固定頁首，內容獨立捲動。初次 Web 發現原「✕」缺字，改為 runtime 字型支援的「×」，增加實際字型 has_char 斷言。
- FeatureUnlocks 的現有 View 三態接入：隱藏不佔分頁空間、預告灰化＋「·鎖」及解鎖 tooltip、可用正常。預告可進既有頁面查看核心禁用原因；明確情境 deep link 仍能開既有頁面，隱藏不是核心權限。未知 route 仍拒絕。
- 同群組不重建節點；signature 變更才重算三態與待辦文字。升境／壽盡／輪迴後隨 View 更新，沒有新增存檔欄位或永久已看過旗標。群組記住分頁；記住的頁隱藏時優先回到可用頁，再退預告。
- PAGE_POLICY 集中工作區／資源策略：建築與空島使用右欄／共用資源；製造中央大工作區、寬≥1100且高≥500保留左庫存；運輸與其餘頁面成本內嵌、不顯示外部庫存。幾何、相機、命令及返回資源偏好沿現有契約。

修改：src/presentation/feature_navigation.gd、components/game_tab.gd、components/close_seal.gd；tests/feature_navigation_runner.gd、uix_r1_components_runner.gd；本驗收及 Roadmap／規格／狀態／英文交接。沒有新美術素材、規則或保存 schema。開工的所有 dirty 成果保留。

## 命令與結果

- Godot 本機 --version：4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離 APPDATA=E:/WORK/Dao2/build/uix-r3-user；`--headless --path . --script res://tests/<runner>_runner.gd`：feature_navigation、uix_r1_components74、uix_r2_hud67、m2d_responsive_ui、res1_ui1a、res1_ui1b、early_flow1d 全部 exit0。最終關閉字元修正後 components／navigation／responsive 再驗 exit0。日誌 build/uix-r3-*.log。導航新增新檔三態、原節點沿用、Era2／3切換、壽盡、分頁記憶與 viewport 資源政策斷言；保留舊命令／規則中立斷言。
- Python tools/subset_game_fonts.py --check：exit0，1831 codepoints，未重建字型。
- Web `--headless --path . --export-release Web build/web/index.html` exit0，bundled Node `tools/prepare_web_compression.mjs build/web` exit0。最終 PCK SHA256=55C61BF23D201C976F96B6AE3D2F5E9196CF6B734C0ED0B7E7F30595FF09A86C。
- 全量 run_all_runners 與最終 diff 檢查結果於本頁末追加。Font RID／CanvasItem／ObjectDB／resource-in-use 退出診斷保留，不能稱日誌零錯誤。

## 真實 Web 證據

bundled Python tools/island_preview_server.py --port 48217 --normal-build --gzip；IAB 新 origin，正常新檔 Play。桌面 DOM 明確量測 iframe1280×720／DPR約1，launcher viewport1280×790；844×390、800×360及360×640使用既有測試按鈕。圖像在 [本輪圖像目錄](artifacts/uix-r3)。

真實滑鼠：修行三分頁（技能預告／煉丹／成就）、技能頁核心禁用與解鎖说明、844內捲／固定×／重開記住技能；800遊歷預告、切機緣再回宗門、×返回洞府、經營→製造。800外部庫存隱藏、1280製造左庫存保留；直式遮罩後轉回橫式恢復製造。最終 warn/error limit20 查詢空。測試 tab 關閉，viewport reset；48217服務Ctrl+C刻意停止exit1。玩家4175未操作。

初次 tooltip補驗48216沙箱連線timeout，依授權重啟後成功，但在使用者選R3後停止該補驗，原tooltip停留仍待驗。該服務停止exit1。重載48217時索引改變曾誤點seed，launcher回覆已有進度、保留原檔；未載入fixture，之後Play沿用原檔。首次關閉印鈕缺字是實際失敗，修正、重匯出／服務重啟後圖片證明×正常。

## 交接邊界

R3 本有界來源／CLI／桌面 Web 可交付；人工美術、實體觸控／高DPR及EARLY-FLOW1-D人類節奏仍待驗。沒有重跑已接受的FPS／保存故障矩陣或暫緩冷啟動；未更新Windows、commit或push。下一New Chat收R3回饋，再續 UIX-R4 建築清單圖形化（需按建築規格界定範圍）；本輪不展開R4，不進Era4–12。

追加最終驗證：隔離 APPDATA=build/uix-r3-all-user，powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1：**61/61、exit0**（build/uix-r3-all.log）。導航新增宗門預告字尾斷言另以最終navigation runner exit0補驗。tracked來源／文件 git diff --check exit0（CRLF提醒）；七文件strict UTF-8通過。初次untracked whitespace檢查發現CloseSeal原有空白行尾tab，已清理、再檢查PASS，無語意改變。

**狀態：UIX-R3 DONE（本輪明訂的共用外殼／三態／資源策略、CLI與桌面Web有界範圍）**。最終美術／實體觸控／高DPR待驗，不提升完整UI1-C／C／D或EARLY-FLOW1-D人類節奏。
