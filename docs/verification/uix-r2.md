# UIX-R2 主 HUD／共用卷軸 — 2026-10-10

**DONE（有界主 HUD、共用外殼與 CLI／桌面 Web；2026-10-10 使用者美術接受）。實體觸控與高 DPR 獨立待驗，完整裝置驗收仍未完成。** 使用者「R2 開始實作」覆蓋歷史等待設計／僅文件提示。R1 不重做，EARLY-FLOW1-D 自然時間及 C/D 裝置缺口不提升。

本輪：青玉四入口、青銅細框與原生圓形道印；選中亮玉／按下變暗／禁用對比；右上朱紅圓點讀真實輪迴、成就、餵食、機緣與宗門完成狀態，開頁不清除。viewport-relative 青銅轉角忽略滑鼠。左側主目標獨立掛軸；洞府預設資源摘要＋可展開資源控制，展開完整清單或進工作區時收摘要，設定始終保留。經營初入自動展開原有採集清單。短橫式天時移到身分欄，壽元單行；沒有字級縮小或鎖畫布。

共用卷軸九宮格供固定功能分頁／返回、訊息、空島／製造／運輸及技能／靈獸／決策外殼使用；舊詳細內容、成本圖框、命令、捲动與保存重試保持。未全面翻新建築、宗門、九界等所有頁內卡片。像素美術與玩家切換系統本輪未實作。


## 2026-10-10 美術接受後結案複核

使用者本次明確表示「美術接受、觸控／高 DPR 仍待驗」，要求確認 R2 完成與後續推進。依 docs/18-uix-components-and-hud-plan.md 的 R2 DoD，裝置項目獨立保留；R2 有界實作／桌面驗收 DONE，可續既有四島／前期流程。下方「下一先收美術」為此前交接，現已解除；下一 New Chat 優先 EARLY-FLOW1-D 剩餘自然流程與節奏驗收，觸控／高 DPR 有實機時另補。不推定存在已核定的 UIX-R3，不放行完整 C/D 或 Era4 擴充。

本輪命令與結果：PowerShell Get-Content／rg／git status --short 核對 DoD、來源與既有日誌；Get-FileHash build/web/index.pck 與記錄的 2AE02BA02B068170C92A000E2718B6562AE0EB68B55EC313150D83BDD3E4280F 一致；本地 tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version 為 4.7.2.stable.official.ed1daf0bf。進程級 APPDATA=E:/WORK/Dao2/build/uix-r2-audit-user，執行 --headless --path . --script res://tests/uix_r2_hud_runner.gd --log-file E:/WORK/Dao2/build/uix-r2-acceptance-audit.log：52 checks、0 failures、exit0。退出 RID／CanvasItem／ObjectDB／resource-in-use 診斷仍存在，不宣稱日誌零錯誤。這是隔離 CLI 複核，沒有新增真實 Web／實體觸控／高 DPR／自然流程證據。

修改文件：README.md、ROADMAP.md、docs/18-uix-components-and-hud-plan.md、docs/verification/uix-r2.md、docs/development-status.md、docs/ai-handoff.md、updata.txt。保留既有工作區變更，未改正式程式／資產／匯出／玩家進度，未 commit／push。依 Context Guard 在此結案 checkpoint，下一大型階段使用 New Chat。

## 修改檔案

- `src/presentation/abode_hud_controller.gd`：玉質入口、GoalScroll、裝飾、資源互斥與短式排版。
- `src/abode/living_abode.gd`：初始資源模式 0（呈現狀態，不保存）。
- `src/presentation/feature_navigation.gd`：固定卷軸分頁、玉質選中、待辦圓點／tooltip、經營採集恢復。
- `src/presentation/ui_material.gd`、`components/dock_button.gd`、`dao_seal.gd`、`resource_chip.gd`、新 `hud_bronze_frame.gd`／UID；兩張新 SVG／import 與 [資產來源／設計 brief](../../assets/ui/material/uix-r2-manifest.md)。原創程式／向量材質，未使用第三方圖片像素。
- `src/presentation/island_management_panel.gd`、`system_actions_panel.gd`：共用卷軸外殼，後者暖紙深墨。
- `tests/uix_r2_hud_runner.gd`／UID、`uix_r1_components_runner.gd`、`feature_navigation_runner.gd`、`tools/run_all_runners.ps1`，本頁、Roadmap／README／交接／狀態與 updata。保留所有進入本輪前已有的修改。

## CLI／匯出

Godot `4.7.2.stable.official.ed1daf0bf`；進程級 `APPDATA=E:/WORK/Dao2/build/uix-r2-user`。命令均在專案執行，未更新引擎／模板。

- `tools/run_all_runners.ps1`：修正卷軸內距與通知接線後 **61/61、exit0**，[log](artifacts/uix-r2/all-runners-pass.log)。全量期間追加的 GoalScroll／短式天時最終補丁另跑以下五項，不能把全量說成最後補丁後完整重跑。
- 最終 `--headless --path . --script res://tests/<runner>.gd`：`uix_r2_hud` **52/52**（含三橫式經營至少一列38px可讀資源）、`m2d_responsive_ui`、`feature_navigation`、`early_flow1b` **110**、`early_flow1d` **118** 全部 exit0；各 `*-final.log`。先前 margin 修正後運輸 **220**、exit0。
- 最終 `--headless --path . --export-release Web build/web/index.html`、bundled Node `tools/prepare_web_compression.mjs build/web`：exit0，[匯出](artifacts/uix-r2/export-release-final.log)、[壓縮](artifacts/uix-r2/compression-release-final.log)。一般 Web 已同步，Windows 未重匯出。
- 最終 PCK SHA256 `2AE02BA02B068170C92A000E2718B6562AE0EB68B55EC313150D83BDD3E4280F`，見 `package-sha256.txt`。經營自動展開清單只影響工作區，返回恢復進入前的洞府資源模式；最後此修正亦通過上述52專項／五相关回歸並重新匯出壓縮。

修正／失敗保留：首次 importer 未加 --quit，以 Ctrl+C 停止；既有四張 R1 PNG 匯入失敗診斷留於 build/uix-r2-import.log，新 SVG 成功。新 HUD 初測初始化硬編碼 mode1、首次切經營在 tabs 建立前 reflow 已修。全量首次沙箱既有 fixture 寫入失敗並掛起（Ctrl+C exit1），授權升權再跑；第二次運輸 800／600 短式首卡不全，卷軸內距由18恢復10，220及後續全量通過。最初 server fixture 帶整條路徑 exit2，改檔名啟動成功。歷史 RID／CanvasItem／ObjectDB 退出警告與損壞保存預期ERROR保留；不宣稱所有日誌零錯誤。

## Web 與接手

CUA IAB；隔離 localhost **48212**，既有 `early-flow1d-ready.json` 只 seed 一次，之後只 Play。使用 bundled Python：`tools/island_preview_server.py --port 48212 --normal-build --gzip --fixture early-flow1d-ready.json`。4175 玩家 origin 未碰。

實際滑鼠新版經營入口、製造卷軸、設定；1280×720 金丹1→2正常實付晉階、過場後恢復，真正 reload／Play 保留金丹二層。iframe 三橫式、固定返回與內容內捲、直式轉回之最終畫面存於 [artifacts/uix-r2](artifacts/uix-r2)。尺寸從 launcher DOM/iframe確認，不以 CLI 冒稱 CSS 命中或實體觸控。沒有新的 FPS／IndexedDB／quota 矩陣或自然首段通關證據，冷啟動依使用者暫緩。

下一 New Chat：先收 R2 玉質／青銅／卷軸的人工美術回饋，再補實體觸控／高 DPR；不直接開下一大型介面階段。參考圖只作方向，不代表第三方商用授權。未 commit／push。

最終收尾：DOM iframe=1280×720、DPR約1；[桌面](artifacts/uix-r2/web-home-1280.png)、[844](artifacts/uix-r2/web-home-844.png)、[800](artifacts/uix-r2/web-home-800.png)、[800經營可讀資源](artifacts/uix-r2/web-management-800.png)、[固定頁首內捲](artifacts/uix-r2/web-scroll-800.png)、[設定](artifacts/uix-r2/web-settings-844.png)、[旋轉遮罩](artifacts/uix-r2/web-portrait.png)。最後返回摘要偏好修正後重新驗800經營／固定返回、844設定、1280地標詳情／返回與截圖；內捲／旋轉證據是同輪此返回偏好修正之前的包，版面來源相同。console error/warn最終查詢為空，存 `browser-final-logs.json`；不是Godot負面測試日誌零錯誤。有效驗收分頁已關閉、viewport已reset，48212服務Ctrl+C停止（exit1為主動停止），origin保留金丹二層；開頭連線失敗的临時分頁交工具自動清理。文件UTF-8／本頁相對連結與受影響來源 `git diff --check` exit0；換行正規化提示保留。
