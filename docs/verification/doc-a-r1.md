# DOC-A-R1｜GitHub 同步後文件現況複核

日期：2026-10-02。狀態：DONE（文件複核／更新範圍）。本輪未修改遊戲實作，不新增玩法驗收承諾。

## 複核依據

- 讀取 README、ROADMAP、AGENTS、AI handoff、development-status、updata 9/29–10/2 checkpoint；按需核對技術／響應式／建築規格。
- Git 歷史：9/28 66df79c 至 10/2 53b864f 集中包含 479 個變更檔；ed63330 保存 GitHub 推送交接。main 的本地 origin/main 指向 ed63330，origin URL 為 https://github.com/KainHuang777/Dao2.git。
- 本輪 GitHub 網頁讀取回覆 Cache miss，未以網頁核實遠端即時內容；上述 GitHub 同步依使用者通知、既有 checkpoint 與本機 Git refs，不宣稱本輪重新推送或遠端即時比對。
- 直接核對 GameSession 白名單／便利函式、RealmSystem、WorldAddress、ScaleLawContract、WorldGenerator／Descriptor、ChronoSystem、FortuneSystem、RealmDecisionSystem、相關資料與 runners。
- UI7 已有 34/34 PASS 日誌、Web 匯出與 IAB 操作記錄；參見 [UI7](ui-quiet-materials.md)。本輪只沿用該證據，不虛報新瀏覽器操作。

## 修正內容

1. README／Roadmap／AI 交接日期與固定 Runner 數量更新至 10/2／34，加入近幾日天時、機緣、生成、決策、音訊、材質、字型及演出摘要。
2. 移除目前入口的「Session 尚未放行」與「M5 尚未開始」說法；M3-B／M4-A／REF-A 在歷史段落前追加日期化更正。
3. 正式界域切換目前仍主要人界／靈界；九界資料不等於全部界域可玩。M5-A／B 的歷史 DONE 只涵蓋核心／契約或資料測試；整體完整 DoD 列 IN_PROGRESS，保留三種手工法則可玩、版本升級保留描述、逐界美術／試玩、串流／負載驗證要求。
4. R1 白名單實作已有證據，但完整全命令成功／拒絕／冪等／保存及真實 Web 未逐項補齊；不沿用無證據的整體 DONE。R1 版型按 9/30 使用者核定橫式核心與直式提示更新，實機／高 DPR 待驗。
5. 天時／機緣從 M3-B 未開工清單移到已交付；目前先驗 UI7／字型／FX2／TEXT1，後续功能候選為靈獸或成就。
6. 核對 export_presets.cfg 已排除參考圖、測試／文件／工具、音樂草稿、舊背景及 MP4，修正 Roadmap／交接仍稱未排除的說法；尚未量測打包下載量。
7. 保存 [整理前開發狀態](../archive/development-status-2026-10-02-before-doc-a-r1.md)；只調整移至 archive 後相對連結，歷史內容不改。英文 checkpoint 加至 updata 頂部。

## 修改檔案

- README.md、ROADMAP.md、docs/development-status.md、docs/ai-handoff.md。
- docs/verification/m3-b.md、m4-a.md、ref-a.md、本頁。
- docs/archive/development-status-2026-10-02-before-doc-a-r1.md、updata.txt。
- 本輪新增 doc-a-r1-runners.log（首次失敗）、doc-a-r1-runners-retry.log（重跑）、doc-a-r1-doc-check.log（文件檢查）。
- 既有 docs/verification/ui-quiet-http-errors.log 在任務開始前已修改，本輪保留，未歸入文件更新。

## 命令與結果

- git status --short、git log、git show、git remote -v：核對來源與工作區，exit 0。
- 本機 tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version：4.7.2.stable.official.ed1daf0bf，exit 0。
- powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1：首次沙箱執行 exit 1；不能寫 user:// 日誌及獨立 web_probe_runner fixture，另見根憑證讀取診斷。未測到後續 Runner，不能列為 34 項規則失敗。
- 依 AGENTS 常態測試授權使用正常 require_escalated 重跑同命令：**34/34 PASS、程序 exit 0**，完整日誌 [重跑結果](doc-a-r1-runners-retry.log)。原 fixture 與玩家正式存檔分離；只用程序 ExecutionPolicy Bypass，未改全機政策。
- UTF-8 嚴格解碼、修改文件 Markdown 本地連結與路徑檢查、git diff --check：最終 10 檔解碼／149 個本地連結通過，git diff --check exit 0；結果見 [文件檢查](doc-a-r1-doc-check.log)。
- 本輪未執行 Godot import／Web export、追加 parity runner 或瀏覽器／手機測試；相關舊命令保留各日期驗收頁。

## 限制與下一步

現有 Runner 退出仍有 Font RID／CanvasItem／ObjectDB 診斷及負面資料測試預期錯誤；exit 0 不代表日誌無診斷。高 DPR、實體手機、音訊聽感、IndexedDB、效能與 M5 完整驗收仍依狀態頁補證。

初次文件複核結束時未 commit／push；使用者隨後明確要求提交並推送 main。此次提交僅含 DOC-A-R1 文件與驗證紀錄，保留任務開始前的 ui-quiet-http-errors.log 變更。Git 提交／遠端推送結果另以實際命令回報為準。下一步在 New Chat 收取 UI7、混搭字型、FX2／TEXT1 回饋並補裝置驗收；若轉回功能主線，先確認 M5 DoD 與靈獸／成就範圍。
