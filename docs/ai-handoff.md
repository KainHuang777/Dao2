# 給下一位 AI 的開發交接

更新：2026-10-03（ISLAND1：38 Runner、小院／小景與驗收邊界）。適用 GPT-5.6、OpenCode、Codex 或其他可讀寫檔案與執行 CLI 的工具；不要求付費外掛或本次對話上下文。

## 閱讀與恢復工作

1. 根目錄 `AGENTS.md`：開發約束。
2. `ROADMAP.md`：產品目的、任務 ID、相依與完成定義。
3. `docs/development-status.md`：實際進度與證據，找到當前未完成工作。
4. 按任務讀 docs/02 技術架構、docs/00 舊規則來源；美術任務讀 docs/04、06。
5. 涉及世界場景、HUD、輸入、畫面尺寸、Web shell 或 Web 匯出時，閱讀 `docs/07-responsive-ui-web-spec.md`；它規定 `1280×720` 構圖基準、Godot 響應式版型與瀏覽器證據，不可用固定畫布取代適配。
6. 涉及新建築、修行境界（Era）擴充、島面與可布置空間時，閱讀 `docs/08-building-presentation-and-era-expansion.md`；多數建築進營造清單，只有有圖形化地基與獨立美術的少數地標可進世界場景。
7. 涉及功能入口、群組分頁、資源或升級清單整合，必讀 `docs/12-feature-navigation-and-integration-spec.md`；新系統不得塞進 More 或新增重複入口。

如果工具不自動讀 AGENTS.md，請在首個提示明確要求閱讀。歷史文件 docs/03 保留初期推理與案例，開發順序以根目錄 Roadmap 為準。不要因舊文有「下一步建立環境」而重裝。

依修改類型查 [呈現層索引](abode-presentation-map.md)。歷史長記錄已歸檔，不作每次必讀；目前缺口與驗證以 [開發狀態](development-status.md) 為準。

## 最新接手狀態

- **2026-10-03 RES1-B-WEB-R1 DONE，下一 RES1-C**：251 checks／native三程序與桌面Web保存故障矩陣已交付、最終固定入口47/47 PASS、exit0。讀 [驗收](verification/res1-b-web-r1.md)／development-status及updata頂部。localStorage＋lifetime Web Lock，拒絕讀寫／quota／損壞／索引中斷／重載與重試、受控Web幀恢復已驗；正式manifest保持opt-in。自然分頁／OS背景凍結、裝置與長離線CPU另待驗。本節後續A／B待做順序是本日較早歷史，不重做已交付核心。下個大型任務用New Chat。

- **2026-10-03 RES1-A 已完成首批契約／隔離核心，下一 RES1-B**：讀 [驗收](verification/res1-a.md) 與 updata 頂部。15 資源／8 配方、145 checks、新舊差異與唯讀 DAO1 8/8 參照、全量 42 Runner PASS。正式 ContentLoader 不附掛 processing_catalog，Craft 為 opt-in；正式 manifest／schema／rules 未變，新經濟不可先接玩家保存。B 將 A 的即時命令契約接批次時間、地方庫存、固定航線、容量保留、版本遷移與離線／輪迴／故障重試，補相交 M1-C/D 後開啟；百年草取得、Era3 技能／材料消耗與 UI 在 C/D。以下 A TODO 為較早歷史方向。

- **2026-10-03 RES1 最新指示優先於本節後續歷史次序**：使用者重申 Era 解鎖資源島、多階加工／融合與實際供給運輸。RES1-DESIGN 文件與靜態來源稽核 DONE，runtime 尚未改；先讀 [docs/14](14-multi-island-resource-progression.md)、[ADR-009](decisions/ADR-009-multi-island-resource-economy.md)、[稽核](verification/resource-progression-audit.md)。DAO1 61 資源／30 配方，DAO2 manifest 7／10 建築／Era 1–2，完整承接缺口從 Era 2–3 起。**下一 RES1-A（資源／配方／需求契約與 Craft 核心），再 B 加工／庫存／物流／保存、C 三島、D Era 3／三級材料**；M1-C/D 相交持久化／離線驗收仍是正式放行條件。已建立英文 checkpoint，使用 New Chat 開始實作，不把設計表當已上線玩法。

- 2026-10-03 M4-A-R1 DONE：251 checks／40 Runner、兩版型 IAB 真實滑鼠及重整恢復通過；rules_version=core-flow-5-session-receipts，schema 2 選填最近 256 筆成功命令收據。最後舊任務 alias 修正另重跑四項相關 Runner，全部 exit 0。Web adapter 實際是 localStorage；下一步 M1-C/D 權威儲存與離線故障矩陣，實機／高 DPR 獨立待驗。看 verification/m4-a-r1.md 及 updata.txt 頂部；使用 New Chat，不重做白名單。本節以下為本日較早接手紀錄，已由此項取代後續順序。

- 2026-10-03 最新：成就已交付，固定入口 39 Runner，UI8 R1 全量 39/39 PASS；建造訊息修復另有兩項 Runner／Web 證據且使用者測試 OK。下一步 M4-A-R1 補正式 Session 成功／拒絕／冪等／保存與 Web 矩陣，不能重做已存在白名單。再補 M1-C/D 瀏覽器持久化與離線證據；實機／高 DPR 仍待驗。下列按日期的 38 Runner 為歷史結果。

- NAV1 四主入口與九分頁已實作；靈獸核心及正式操作頁已接，下一步收分類／視覺回饋與實機驗收，見 verification/feature-navigation.md。

- Session 已放行宗門／跨界／BUFF，不能照 9/28 提示重做白名單；全部新命令端到端／Web 證據仍按 R1 補齊。
- M4-B、M5-A／B 已有核心／資料實作；完整可玩／美術／試玩／長期負載尚未全驗。最新 UI7 已實作，優先收 UI／字型／演出回饋與裝置驗收。
- 倉庫 origin 為 https://github.com/KainHuang777/Dao2.git，main 追蹤 origin/main；引擎／模板、.godot、build 被忽略。乾淨 clone 不含本機引擎，需同版 4.7.2 執行檔及模板，不自動更新環境。
- 執行政策 Bypass 僅作用於該測試子程序。若沙箱阻擋隔離 user:// fixture，記錄失敗並使用正常授權重跑；不要改玩家存檔。

## 實際路徑與現有檔案

| 路徑 | 已有用途 |
| --- | --- |
| `project.godot`、`export_presets.cfg` | 已鎖定環境；主場景 living_abode；Web 單執行緒 |
| `scenes/living_abode.tscn` | Node2D 啟動場景，運行時建構地形、建築、鏡頭和 HUD |
| `src/abode/living_abode.gd` | 世界與正式 Session／保存協調、公共相容入口 |
| `src/presentation/abode_hud_controller.gd` | HUD 組裝／版型／數值與引導更新 |
| `src/presentation/abode_modal_manager.gd` | 次級彈窗掛載／位置／事件分發 |
| `src/abode/abode_state.gd` | 純展示經濟，尚用 float、無持久化、無正式離線 |
| `src/abode/abode_camera.gd` | 平移、滑鼠／觸控縮放、HUD 排除、遠近景；待完整手勢驗收 |
| `src/abode/abode_building.gd` | 獨立 sprite、命中區、標籤、選取及升級特效 |
| `src/abode/abode_flows.gd` | 飛劍與靈氣的程式動畫；不發放資源 |
| `assets/abode/` | terrain、sky、hut、garden、altar、sword 分層圖片 |
| `assets/fonts/`、`src/presentation/ui_typography.gd` | 思源黑體 TW VF 400／600 資訊字與粗明體 800 題字；保留字型授權 |
| `docs/abode-art/` | 生成提示詞、原始與處理紀錄，非正式遊戲模組 |
| `scenes/web_probe.tscn`、`src/presentation/web_probe.gd` | 舊計數探針；`user://web_probe_state.json`；與洞府不同存檔契約 |
| `tools/test_runner.gd` | 基本 JSON／user 儲存與字型探針 |
| `tests/abode_state_runner.gd` | 展示產率、升級、藥圃停止測試 |
| `tests/living_abode_runner.gd` | 直接呼叫場景選取／升級／停產／鏡頭函式，非真實輸入 E2E |
| `docs/visual-prototype/` | 早期 HTML 視覺提案，不能作為正式遊戲核心 |
| `src/效果圖/` | 現有參考圖，勿任意刪除；export_presets.cfg 已排除 release 打包 |
| `build/`、`.godot/` | 匯出與快取，可重建；修改來源後重新生成 |

舊來源 `E:\Python\test1`、塔防參考 `E:\WORK\GodTower` 僅供讀取。其他機器沒有這些路徑時，可先做不依賴來源的驗收；公式 fixture 任務應報缺來源，不從記憶或圖片猜公式。

## 可重跑命令（目前已存在的入口）

以下在 Windows PowerShell 執行。每一步確認退出碼；2026-10-03 ISLAND1 重跑固定入口 38/38 PASS，清單以 tools/run_all_runners.ps1 為準。追加呈現層回歸不在固定入口；歷史結果見各驗收頁，本輪未重跑。非 Windows 接手者需提供同版本當地 Godot 執行檔與模板，保留來源專案設定。

```powershell
Set-Location 'E:\WORK\Dao2'
$daoEngine = '.\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $daoEngine --version
if ($LASTEXITCODE -ne 0) { throw 'Godot version check failed' }
& $daoEngine --headless --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
if ($LASTEXITCODE -ne 0) { throw 'A runner failed' }
& $daoEngine --headless --path . --script res://tests/abode_presentation_parity_runner.gd
if ($LASTEXITCODE -ne 0) { throw 'Presentation facade regression failed' }
New-Item -ItemType Directory -Path '.\build\web' -Force | Out-Null
& $daoEngine --headless --path . --export-release Web '.\build\web\index.html'
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
```

另外開一個終端啟動本機 HTTP（若已有相同服務，先確認不用重開）：

```powershell
Set-Location 'E:\WORK\Dao2'
python -m http.server 4175 --bind 127.0.0.1 --directory '.\build\web'
```

開啟 `http://127.0.0.1:4175/index.html`；不要直接雙擊本機 HTML。此服務只提供 build/web，不公開整個專案。停止該終端中的服務用 Ctrl+C，不終止不相關程序。若換 port，origin 與瀏覽器存檔也不同；存檔回歸必須保持固定 origin。

現有 Godot 採 `_sc_` 自我包含模式，模板在引擎旁 `editor_data/export_templates/4.7.2.stable/`；引擎與模板被 .gitignore 排除。若工具沙箱阻止引擎寫入，使用該工具的正常授權流程，不繞過限制。

周天探針不再是主場景；M0-A 需提供獨立 export/config 的可重跑方式，不直接改 release main_scene 又忘記還原。`tools/` 被 release 排除，CLI runner 可從源專案執行；不要把 runner 的存在當作 release 可載入保證。

## 瀏覽器驗收的正確做法

- 先等實際場景可互動；loader 截圖與 console 的 ABODE_READY 都不足以證明畫面品質。
- 從當次截圖／viewport 確認座標，記錄 CSS 尺寸和 DPR；不要複用上一回的固定座標。Godot 畫布內部文字通常不在 DOM，不能把 AX 的 canvas fallback 文字視為畫面錯誤。
- 真實點建築／按鈕並核對文字與狀態；拖曳檢查位置、縮放檢查比例及命中；UI 上拖放後再點世界，確認不黏住拖曳。
- 測試暫停藥圃前後一段固定時間的靈草增量，恢復後繼續；鏡頭切換與低特效不能改產率。展示版允許重載重置，正式存檔接入後更新此預期。
- 周天持久化記錄初值、點後值、重載值；不能以檔案存在、函式返回或 headless JSON 往返代替瀏覽器持久化。
- 缺瀏覽器自動化能力就提供人工步驟並標待驗證，不擅自宣稱全通過。手機模擬 viewport 不等於實體手機 GPU、觸控或效能驗證。

## 任務與驗收紀錄模板

每項工作在既有 `docs/verification/<task-id>.md` 建立或追加紀錄：

```text
任務 ID／日期／狀態：
目標與非目標：
已滿足相依：
來源 hash 或規則版本：
修改檔案：
驗收環境（引擎、OS、瀏覽器、裝置、CSS尺寸/DPR）：
命令／退出碼／結果（實測或未執行）：
瀏覽器操作、預期、觀察、截圖路徑：
資料安全／存檔相容影響：
未通過項、阻塞原因、下一步：
```

調整已決定的架構或規則時，在 `docs/decisions/ADR-xxx.md` 記錄理由、替代方案、影響及驗證，並更新 Roadmap。ADR-001–007 已存在 docs/03，不重用編號。

## 上下文管理與主動剎車協定（Context Guard & Checkpoint）

1. **防禦 Context Drift**：長 Session 會累積過多終端輸出與代碼檢視，導致模型注意力分散、代碼品質下降與幻覺。
2. **主動剎車標準**：
   - 當前任務（Task/Bugfix）已完成且測試通過，準備進行下一個不相關的大任務時。
   - 單一對話對話輪數過多、或終端大量錯誤日誌累積時。
3. **固化與交接 SOP**：
   - **寫入 `updata.txt`**：按照專案規定，在最頂部追加最新英文更新日誌（含變更檔案、關鍵邏輯、測試驗證結果）。
   - **更新狀態**：將當前進度與下一步標記在 `docs/development-status.md`。
   - **提示重啟**：在回覆末端提示使用者點擊「New Chat」開啟新對話。
4. **冷啟動接手**：新開啟的對話**不依賴任何舊歷史記憶**，只需閱讀 `AGENTS.md`、`updata.txt`（頂部最新日誌）與 `docs/development-status.md`，即可 100% 精準恢復上下文並立刻推進下一任務。

## 可直接貼给下一個 AI 的提示

> 請接續 E:\WORK\Dao2。先閱讀 AGENTS.md、README.md、ROADMAP.md、docs/ai-handoff.md、docs/development-status.md 與 updata.txt 頂部 checkpoint；按呈現層索引定位來源，UI 必讀 docs/07。使用現有 Godot 4.7.2／GDScript／Compatibility／單執行緒 Web。34 Runner 於 2026-10-02 重跑通過，Session 白名單已補，M4-B 與 M5-A／B 核心資料已交付；不重做舊接線，也不把數值測試當作九界完整遊玩驗收。先接續最新 UI7、混搭字型、FX2／TEXT1 的回饋及裝置驗收，再選靈獸／成就或補 M5 完整 DoD；缺少證據的項目照狀態頁保留待驗。

## RES1-B 冷啟動入口（2026-10-03）

先讀 [B 驗收](verification/res1-b.md) 及 updata 頂部：核心 251 checks／native 三程序交付，整體 IN_PROGRESS；下一 RES1-B／M1-C/D Web 故障矩陣，尚未進 RES1-C。重跑 `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_res1b_verification.ps1`。測試資料只在 docs/verification/artifacts/res1-b-cross-process；全量最近一輪 44/45、exit 1（其他新增 DebugActions 面板失敗），不要忽略。schema3 decoder支援舊schema2，但正式processing catalog仍未啟用；瀏覽器matrix不能由native結果推定。
