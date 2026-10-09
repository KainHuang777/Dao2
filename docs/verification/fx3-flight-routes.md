# M2-D-FX3-ROUTES — 飛劍用途調整

2026-10-07，使用者同意撤下洞府裝飾飛劍、保留主角吸靈、將飛劍用於實際島間載貨。此子項實作及有界驗證完成；完整 FX3 美術／裝置／長效能仍 IN_PROGRESS。

## 修改

- living_abode.gd 不再建立 AbodeFlows，撤下九把固定循環飛劍、三條光軌、無對應建築的中央裝飾光圈與粒子；CloakedCultivator 的主角吸靈與突破特效保留。舊 abode_flows.gd／UID 和美術資產保留為歷史可用來源，正式場景不再引用。
- island_world.gd 的原貨船圖形換為原有 sword.png 與 NativeVfx.SWORD 發光材質；每條既有航線預建一個 Sprite2D，最多七個，不逐幀新增。僅 Era2+ 且 trips 中有正數 cargo 時顯示，位置依核心十秒 loaded leg 的 remaining 計算，朝向目的島。無貨物／到貨後隱藏，不虛構空返程。低特效保留貨物位置與細路線、停 shader 時鐘並取消短拖尾。
- tests/res1d2_world_runner.gd 加入 idle/source/midpoint/direction/reduced-motion/delivery 與完整規則快照不變檢查；island_breakthrough_runner.gd 更新為主角低特效及舊 emitter 不存在的契約；native_vfx_preview.gd 移除舊 flow 存取。

## 驗證

Godot 4.7.2；import exit0（sandbox user:// 診斷保留）。初次 sandbox world runner 無法寫入測試專用 user://，初始化失敗／Nil 後停止，未視為通過。獲准重跑：世界 runner 51 checks／exit0，突破 runner exit0，涵蓋正式突破、保存失敗重試、試播零收益、低特效及版型。退出仍有既有 Font／CanvasItem／ObjectDB／resource 診斷。

Godot --headless --path . --export-release Web build/web/index.html 與 node tools/prepare_web_compression.mjs build/web 均 exit0，BGM companions 完整。PCK SHA256 9c7eab2b8aa68a91fbaa3f69913c28055cdb2190e07c605e8a04db37423aa1d2。日誌在 build/verification/flight-purpose/（ignored，非版本資產）。

真實 IAB 隔離 origin 4268：啟動並以滑鼠關閉離線摘要，畫面有新背景／島體／披風角色，閒置洞府無九把飛劍或固定光軌。只驗當前瀏覽器可用版型；本輪未在 browser 執行完整載貨鏈、實機／高DPR／FPS長觀測。七條貨物顯示由隔離 runner 驗證，不能替代上述實際互動證據。未讀寫 4175 玩家存檔。

未提交／推送 Git，未更新 Windows 包。下一步使用者重新載入一般 Web 入口確認美術，另補 browser 實際載貨與裝置／效能；不啟動下一大型 Roadmap 階段。
全量 tools/run_all_runners.ps1：54/54 PASS、exit0。來源與文件 git diff --check：exit0。
