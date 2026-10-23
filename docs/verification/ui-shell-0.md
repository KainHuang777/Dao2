# UI-SHELL-0：正式接入的政策與返回契約

2026-10-22。使用者「接續正式遊戲接入」授權開始實作；本階段先完成 docs28 的純政策／狀態及入口盤點。這不是對歷史樣張布局、題名條件或保存世數的人工美術接受。F-C800／900的既有字體決定保留，正式字型接線仍在後續階段。

## 交付與界線

- `src/presentation/ui_shell_policy.gd`：13個canonical route與原群組／名稱、合法route回退、HUD／資源／訊息／輸入政策。讀入呈現快照、viewport與資料上下文；不接觸Session、Node、存檔或RNG，不計算成本。
- `src/presentation/ui_shell_state.gd`：洞府偏好與本頁暫收分離，合法返回route／子頁，確認／詳情取消順序，單一覆層與遞增token。高優先層拒絕低優先請求；過期關閉回呼不能解鎖新層。頁面草稿／捲動仍由原panel持有，不另複製一份。
- `feature_navigation.gd`正式共用政策檔的GROUPS與owner；其餘既有布局和開關行為保持。新解析器尚未接管Control顯示，不聲稱目前多重visible寫入問題已解決。
- 新runner已登錄固定全量入口。`tools/ui_shell_audit.ps1`保存9份來源hash與帶函式／行號的靜態盤點。

解析器採docs07既有960px／比例1.45起點，並集中要求高度至少500才用寬式；1280×390仍短式。沒有採HTML樣張的1100px為正式門檻。本階段不配置Control矩形；UI-SHELL-1需以容器實際minimum size驗證，若需調整共同門檻同步規範及測試。

## canonical入口與恢復盤點

定位依本階段[source-audit.json](artifacts/ui-shell-0/source-audit.json)，為靜態證據，未以此聲稱入口實際可達／滑鼠已驗。

| 入口／責任 | 現況與後續接線位置 |
| --- | --- |
| 四主入口／群組分頁 | FeatureNavigation.open_group／open／home，共用13頁註冊；FeatureUnlocks維持available／preview／hidden政策 |
| 世界建築、引導與HUD通知 | living_abode建築入口、HUD主目標／技能／宗門、BUFF通知經既有canonical導航；不得以新殼另建命令入口 |
| 製造／運輸／島嶼捷徑 | open_manufacturing／open_transport／_open_island_page會選島／配方／航線；新殼不可只記route而丟失panel上下文 |
| 世界九界 | living_abode公開入口走realms；Navigation內部再呼叫ModalManager._open_nine_realms_overview，避免接線時遞迴 |
| More與舊toggle | 正式More已清空／隱藏；ModalManager仍有舊toggle及_more_menu分派，不能未證不可達就刪。living_abode公開sect／alchemy／fortune／outposts／reincarnation入口已走canonical route |
| 設定／保存／Debug／閱讀 | settings目前有先home與工具互關；show_help與toggle_guidance仍直接改訊息意圖，後者讀hint_panel.visible。SHELL-1需接工具覆層／原route返回，而非另保存visible快照 |
| Escape | living_abode轉Navigation.back；目前僅製造／運輸詳情先回列表，其他回home。新state契約依覆層→確認→詳情→home處理；尚未接管正式Escape |
| HUD與資源／訊息 | HudController._layout_overlay_panels先寫header／resource_ribbon／hint_panel；Navigation.layout再覆寫。短建築頁還reparent晉階／突破。SHELL-1由共用套用者接管已遷移頁，未遷移頁保留明示legacy邊界 |
| 演出／保護／報告 | living_abode突破／輪迴結束仍有visible或camera快照恢復；ModalManager文字演出亦還原camera。SHELL-1需用當前route／覆層token重算，不用舊回呼恢復新保護層。離線結算與保存保護維持必要處置，不由Escape繞過 |

**單一visibility責任契約**：政策只輸出資料；state只存意圖；未來共用殼套用者唯一寫共用HUD／資源／訊息與導航，panel只管理自身內容、成本與結果。這是0階段完成的責任劃分，並非全頁接線已完成。數值bounds、共用精簡HUD與工具UI實作在1階段；其餘route遷移在2階段。

覆層同時只有一個；相同／更高優先請求取代舊層並使舊token失效，**不保存任意彈窗堆疊，也不自動復活被取代演出**。正式adapter接受保護層前必須停止或交接舊演出，保護處置完成後依當前合法route重算。獨立回呼不能藉finish_overlay觸發遊戲命令。旋轉提示由viewport推導，不改route／偏好；本階段只有CLI契約驗證。

## 機緣規則核對

`FortuneSystem.advance_time`在pending_encounter非空時直接返回，暫停冷卻；`trigger_fortune`存待決並設定下一輪冷卻；`resolve_fortune`提交時重新檢查當下資源，成功後才清pending。沒有新增選擇倒數或逾期規則。Modal關閉不呼叫resolve；頁面重開讀同一待決，保存重試只保存。ShellState從不持有核心pending或扣料；CLI測試也確認傳入View／pending不變。未聲稱本輪重新驗證Web重載或保存落盤。

## 驗證

本機引擎 `4.7.2.stable.official.ed1daf0bf`，`--version` exit0。

```powershell
& .\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file E:/WORK/Dao2/docs/verification/artifacts/ui-shell-0/policy-engine.log --script res://tests/ui_shell_policy_runner.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ui_shell_audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_all_runners.ps1
```

最終專項261 checks、failures=[]、exit0，見[日誌](artifacts/ui-shell-0/policy.log)。覆蓋13頁×三橫式與直式的確定性、偏好隔離、資料刷新不重開、子頁資源政策、工具返回、Escape優先序、確認輸入、演出／保存保護、過期回呼、輪迴後路由失效與preview可閱讀。全量重跑採較早258 checks版本，最後補上的三項另由261專項驗證。

首次直接專項曾因user://預設log目錄無寫權出現log診斷，改工作區絕對--log-file後專項乾淨通過。首次全量在mfg3測試啟動遭SAVE_FAILED並引發Nil.hide腳本錯誤，已Ctrl+C中止（exit1），[原日誌](artifacts/ui-shell-0/full-runners.log)保留。未將此當通過；使用專案授權以非沙箱重跑隔離測試專用user://，重跑全量83／83 Runner通過，exit0，見[完整日誌](artifacts/ui-shell-0/full-runners-retry.log)。日誌有既有RID／ObjectDB退出診斷及故意破損存檔案例的JSON錯誤，未發現SCRIPT ERROR。既有來源定位曾誤用presentation/living_abode及PowerShell的rg萬用路徑，已改正為src/abode與實際fortune_system.gd。

未新增畫面／新字型／美術，不匯出Web；本輪沒有原生渲染、瀏覽器滑鼠、保存落盤或FPS的新證據。後續UI-SHELL-1必須完成真實三橫式開關、跨頁／返回與保存異常驗證。

## 收結

**UI-SHELL-0 DONE（政策／狀態／入口責任契約）；正式共用殼接入整體IN_PROGRESS。** 最終專項261、全量83／83均exit0；9份來源hash一致、16檔嚴格UTF-8與本報告5個本地連結通過。未以此宣稱共同visible實際已單方接管。

`--headless --editor --import --log-file E:/WORK/Dao2/docs/verification/artifacts/ui-shell-0/import-engine.log` exit0並生成三份.uid；[import日誌](artifacts/ui-shell-0/import.log)仍報既有`early-v1-c/final-reload.png`為ERR_FILE_CORRUPT。其簽名FF-D8為JPEG，git hash-object與HEAD blob均de7a25f346e5cf54dc81d18529936e806a378ffe，證明不是本輪改壞；不修改舊圖／不聲稱乾淨import。另保留user:// profiler目錄及巢狀專案忽略警告。未有新GDScript解析錯誤。

全量Runner再生的10份既有fixture在開始時皆乾淨，完成後僅這10檔git restore --worktree還原；首次index.lock權限拒絕，授權重試exit0。兩個新生的既有研究／截圖.import sidecar已移除；原有dirty文件／設計工具保留。未commit/push。依AGENTS Context Guard建立updata英文頂部交接，於本階段停止；下一New Chat接UI-SHELL-1洞府＋一個工作頁的正式接線與原生／桌面Web三橫式驗收，之後UI-SHELL-2完整矩陣。小傳／帳目不在本階段。
