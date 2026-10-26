# CONTENT-P2-BEAST／BEAST-2：兩圖、靈獸卡與代表流程

2026-10-26。**BEAST-2 技術交付完成（L1／有界 L2，桌面1280×720）；整批 IN_PROGRESS。兩圖、卡片與整合節奏待使用者接受，未做 L3。** 沿已核定[方案X](../39-content-p2-beast-design.md)，不重問數值、不擴U／W龜鳳白名單。沒有改規則、魂價、版本或玩家進度，未commit／push。

## 交付與檔案

- `src/presentation/beast_care_view.gd`：六獸沿同一靈獸route呈現，新兩獸使用透明插圖，八天賦復用所屬獸圖與T階。容器／內捲、黑體16／18px、44px動作、UiIllustration B保持。操作節點持續存在，倒數與庫存刷新不重建按鈕。未新增世界獸Node／地標／名牌。舊四獸仍顯示階段、累積XP、實費及冷卻。
- `system_actions_panel.gd`：beasts交由專用子視圖，保留原feed公共alias、Session命令signal與保存錯誤／重試。技能與天道視圖原路由保持。
- `beast_system.gd` **僅View投影**：`care`提供單一feed_costs結果、新兩獸下一餵XP、實際指定地方加成及永久容量；結契使用既有acquire_requirements。新獸壽盡餵養／天賦及獸版本未保存天賦禁用與命令一致。沒有改餵料／XP／冷卻／產率／容量／輪迴算法。T1明示幼10→11%、成長15→16%、成熟20→21%、卵0；鶴T3百草5→3、千草2→1，不寫成恆40%實省。
- `assets/ui/beasts-painted/{frost_stag,herb_crane}.png`及`beast2-manifest.json`；[原圖／來源／全prompt](artifacts/content-p2-beasts-ui/art-manifest.json)。使用內建ImageGen，單層RGBA、byte-identical原圖與runtime，保留alpha；鹿首稿貼邊另存，使用內建編輯補留白，未以程式裁切／去背。AI原創候選、無第三方參考，未主張獨占權或第三方商用授權。**PENDING_USER_ART_ACCEPTANCE**。
- `assets/fonts/runtime/Dao2Sans-VF.ttf`、`Dao2Serif-VF.ttf`、`manifest.json`：沿既有子集工具補本批文字；原來源字型與授權保持。
- `src/verification/beast2_acceptance.gd/.tscn`、`beast2-review-era4.json`、`beast2-review-era5.json`、`beast2-reborn-t1.json`：隔離驗收場景與命令賺得快照。`project.godot`、`export_presets.cfg`、`living_abode.gd`只增加`Beast2Acceptance`測試feature／namespace，普通Web主場景保持。
- `tests/content_p2_beasts_{ui,flow}_runner.gd`與Godot生成UID；`tools/run_all_runners.ps1`登錄兩支。導覽／R8／R11既有runner遵循DAO_TEST_STORAGE_ROOT，R11改核對新的beast_view可見性，未放寬功能斷言。
- `tools/run_beast2_checks.ps1`、`prepare_beast2_art.py`、`beast2_evidence.py`、`beast2_acceptance_server.py`、`audit_beast2_delivery.py`保留可重跑命令與隔離產物。

## L1／L2 CLI與原生證據

現有引擎`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`；未更新引擎或模板。

每批由`tools/run_beast2_checks.ps1 -Only '<完整runner檔名,...>'`**先List、再執行同一選取**，matrix=single；各批1–4支。跨共享View、保存與自然流程，總計七支唯一相關runner，依L2列領域範圍，沒有全量回歸聲稱。

| runner | 最終結果 |
|---|---|
| content_p2_beasts_runner.gd | 1656項，exit0 |
| content_p2_beasts_save_runner.gd | 998項，exit0 |
| content_p2_beasts_flow_runner.gd | 326項，exit0，320.1秒；已知含成熟及壽盡逐秒模擬，單支明確600秒預算 |
| content_p2_beasts_ui_runner.gd | 57項，exit0；原生渲染同57項exit0 |
| feature_navigation_runner.gd | exit0，包含既有靈狐結契／餵養／天賦Session路徑 |
| uix_r8_skills_ui_runner.gd | exit0 |
| uix_r11_decisions_ui_runner.gd | 37項，exit0 |

原始[分批命令及stdout/stderr](artifacts/content-p2-beasts-ui/runs/)保持。新UI首次`current`型別推斷錯誤、測試未啟用島狀態錯誤；導覽／R8／R11的user://沙箱寫入失敗；R11舊文字清單節點斷言失敗均保留。修正後只補受影響選取，**不是首輪全綠**。引擎user://日誌／profiler目錄、anchor warning及Font RID／CanvasItem／ObjectDB退出診斷仍存在，不稱零錯誤。CIM列程序權限失敗僅診斷，沒有用它推定程序結果。

`--headless --editor --path . --import --quit`最終exit0且無SCRIPT ERROR，見[最終匯入](artifacts/content-p2-beasts-ui/import-delivery.log)。`subset_game_fonts.py --check`首輪發現七個缺字；沿工具生成後[最終check](artifacts/content-p2-beasts-ui/fonts-check.log)exit0。原生`--path . --script res://tests/content_p2_beasts_ui_runner.gd --log-file .../native-engine.log`exit0，見[原生日誌](artifacts/content-p2-beasts-ui/native.log)、[鹿](artifacts/content-p2-beasts-ui/native-1280-frost_stag.png)、[鶴](artifacts/content-p2-beasts-ui/native-1280-herb_crane.png)。後續舊獸XP補顯示以新UI／導覽runner補驗；新兩卡畫面未變。

## 已賺得流程的精確邊界

[flow.json](artifacts/content-p2-beasts-ui/flow.json)記錄來源SHA、起訖年齡與等待原因。兩條**獨立**2026-10-24供給賺得快照（Era4／Era5）原本空獸槽，經SaveManager正式原文歸檔／候選提交；正式開寒銀／古藥、啟用航線、地方採集回運籌料，再免費結契。

兩獸各20次正式feed命令，每次精確扣祖島實費、50XP；每次冷卻用正式advance_time推進，沒有直接寫XP／冷卻／庫存。各5700秒模擬時間後成熟，地方實際倍率1.20；成熟不授魂。鹿年齡12753→18453，鶴27163→32863。這不是95分鐘真實牆鐘等待，也不是從空白新檔重跑。

鹿成熟→正式OfflineSettlement模擬壽盡→reincarnate→同種1魂→T1實付1魂→新生命Era1保留→保存重載。新世未開寒銀時倍率仍1，不提前解島。[reborn-t1](artifacts/content-p2-beasts-ui/reborn-t1.json)是命令賺得結果。**重新達Era4後的正向T1終值，沿本輪核心／UI合成資格fixture驗1.11／1.16／1.21；未宣稱完成第二世自然重爬到Era4。** 二世保留／未開島零作用與合成終值是分開證據，不冒充同一連續自然長跑。

玄龜採獨立Era4合法分支結契／自然材料餵養；火鳳沿Era6已賺得持獸快照，補合法材料／冷卻後實餵。沒有同世換獸或刪除活動獸。八天賦11魂UI預算是明確合成，未宣稱已自然完成11次或22次成熟輪迴。

## 當次桌面 Web 滑鼠

`--export-release Beast2Acceptance build/beast2-acceptance/index.html`最終exit0，見[最終匯出](artifacts/content-p2-beasts-ui/export-delivery.log)；本機L2測試包，不是交付候選包。使用同版單執行緒Compatibility。`prepare_web_compression.mjs build/beast2-acceptance`曾備妥四BGM及測試companions，後續重匯不沿用舊compression hash作證；最終伺服器按當前檔案產生gzip，最終PCK hash見audit。沒有為此升L3。

localhost4482；外層桌面1680×820便於觀測，**Godot內部1280×720**，所有30筆狀態均核對此尺寸。Godot核心/UI仍原生，HTML僅隔離測試殼。IAB初連逾時與PowerShell socket權限不足保留；只留一個隱藏本機服務後HTTP200與IAB可達。初版驗收場景ready名稱衝突／retry型別錯誤與舊編譯快取已修並重新import/export；原console保留。初次保存暫停也停了觀測，改PROCESS_MODE_ALWAYS，改用`dao2_beast2_acceptance_v2_*`新隔離槽，舊測試槽保留。未動玩家namespace。

- 真實滑鼠兩獸結契、餵養；鹿拒寫當下精鐵32.2→22.2／草210→190、XP0→50；鶴百草100→95／千草13.68→11.68、XP0→50。拒寫再按重試保持同狀態，恢復與重新載入仍只有50XP。
- 恢復保存沿正式離線補時，正常產出會增加庫存、減少冷卻並提升revision；**不宣稱恢復後庫存仍精確等於拒寫當下**。以拒寫時實費、權威XP與天賦／魂記錄核對不重送命令。普通時鐘暫停不等於停用正式保存恢復結算。
- 合成兩組11魂，實際鼠標逐ID領悟8天賦，各1／2／3／5，共11；鹿T1另做拒寫→再次重試→恢復，10魂不重扣。兩獸四階重載保留且魂0；頁面返回洞府／重開保持。原生及Web內捲均實際操作，沒有裁切解決操作可達性。
- [30筆狀態](artifacts/content-p2-beasts-ui/browser-states.jsonl)、[原console](artifacts/content-p2-beasts-ui/browser-console.json)、[鹿拒寫](artifacts/content-p2-beasts-ui/web-v2-stag-denied.png)、[鶴重載](artifacts/content-p2-beasts-ui/web-crane-reloaded.png)、[獸魂拒寫](artifacts/content-p2-beasts-ui/web-soul-denied.png)、[鹿四階重載](artifacts/content-p2-beasts-ui/web-stag-talents-reloaded.png)、[鶴最終卡](artifacts/content-p2-beasts-ui/web-final-crane.png)。故障注入錯誤是預期證據；沒有FPS或長時WebGL穩定性通過聲稱。

## 交付稽核與下一步

`tools/audit_beast2_delivery.py` → **31 checks、0 failures、30 Web observations**，[報告／來源及當次PCK SHA](artifacts/content-p2-beasts-ui/delivery-audit.json)。內建圖片原圖／runtime hash一致，未假定美術接受。`tools/beast2_evidence.py capture/restore`核對28190份既有JSON，**差異0**，[結果](artifacts/content-p2-beasts-ui/restore.json)。未改玩家進度、引擎環境、R46、規則版本，未commit／push。

最後僅做靜態檢查：本批受影響既有程式／設定的`git diff --check`無輸出通過，文件嚴格UTF-8、20個本地驗收連結及四支Python AST通過，見[靜態結果](artifacts/content-p2-beasts-ui/static-final.json)。新增本段結果連結已確認檔案存在；沒有因文件metadata再跑遊戲或匯出。測試服務以隱藏程序PID49864保留於localhost4482供審閱；IAB暫時分頁已關閉、viewport override已reset。

依Context Guard停在此子階段。下一New Chat先收**兩圖、卡片與目前整合節奏的接受或具體修改**；接受後才做同批唯一L3收尾，不重問X、不開其他P2／P3。本次無全量／全尺寸／三橫式候選驗收。實機依既有延期政策，非目前阻擋。
