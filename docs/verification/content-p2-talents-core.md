# CONTENT-P2-TALENT / TALENT-1 核心與保存驗收

2026-10-24。**TALENT-1 DONE（L1／有界 L2，單尺寸）；整批 CONTENT-P2-TALENT IN_PROGRESS**。依使用者「P2 輪迴天賦 TALENT-1，依已核定 U 實作」，沿[方案 U](../36-content-p2-talent-design.md)；不重新核定價格，不製作三圖或交付 Web 候選包。

## 交付

- `src/simulation/talent_system.gd`：正式九項；U1／U2／U3 各五階、10／20／40／80／160 道心。首次輪迴與最高 Era4 門檻、當世 Era1 仍可購買；原六項費用／上限不變。版本 1／2／3 各 ID 白名單，拒絕零階跨版本 ID、未知／非法階數與矛盾取得資格。
- `alchemy_system.gd`：共用 refinement_cost 的兩丹指定直接草費每階 −4%，整批 Amount 計算；其他成本、嵌套丹與丹效不變。v3 兩種直接草付款用 Amount 差額的正負判定，避免近似 compare_to 放行相鄰浮點缺料；不改 Amount 共用比較契約。
- `island_economy.gd`：SUPPLY 三島、五資源白名單，每階 +10%，與調度／地方技能乘算。擴充經濟未開島 rate=0；舊 economy 的 rate 行為保持。共用 tick／offline／View 入口沿同源，prepared 仍僅限無命令結算；購買後下一次 advance 重建。
- `beast_system.gd`：僅玄龜／火鳳，在原獸魂 floor 後每階加10經驗。原餵費／300秒／成熟門檻與被動保持，靈狐不套新加數。
- `save_codec.gd`：schema5 保持、talent_version3、rules `core-flow-20-content-p2-talents` 優先於 skill4／supply；舊 talent version 維持原規則識別。economy `res1-e-46-1`、skill4、pill1不變。
- `save_manager.gd`：load／import 均登記原文及同一候選，沿 SHA256 命名備份、讀回核對與雙槽提交；migration_pending 延伸啟動閘。GameSession／OfflineCoordinator 拒絕未保存候選的命令／時間／離線結算；living_abode 啟動重試沿既有 UI，提示改為「遷移資料」。供給既有錯誤碼保持，天賦使用 TALENT_SAVE_REQUIRED。原 settled cursor 保存後才結算；不贈點、不回補。
- `tests/content_p2_talents_runner.gd` 與固定入口註冊；調整 P1／SKS／供給舊版本斷言和 SKS 未開島 fixture 前置。其他同步工作新增的 RunnerResult 共用改動保留，未宣稱由本任務完成。

## 實際命令與結果

本機 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。未更新引擎／模板。

所有選取均先執行相同 `-Only ... -List`，預設 matrix=single（1280×720），沒有 `-Full`。因共用保存／時間閘涉及多系統，九支唯一覆蓋按 L2 計，分段執行：

1. `tools/run_all_runners.ps1 -Only 'content_p2_talents_runner.gd,sks_p2_core_runner.gd'`：最終 exit0；新專項826、SKS81 checks 通過。其後僅新 runner 改用相鄰 IEEE double 缺料測試，再執行 `-Only 'content_p2_talents_runner.gd'` exit0，826 checks／failures=[]；見[最終邊界輸出](artifacts/content-p2-talents/final-boundary-output.txt)、[結果](artifacts/content-p2-talents/runner.json)。
2. `-Only 'content_p2_talents_runner.gd,content_p2_supply_economy_runner.gd'`：最終 exit0，供給283 checks 通過；見[輸出](artifacts/content-p2-talents/final-core-output.txt)。
3. `-Only 'content_p2_talents_runner.gd,sks_p2_core_runner.gd,m1c_persistence_runner.gd,web_persistence_fault_runner.gd,m3a_reincarnation_runner.gd'`：最終 exit0，五支通過；磁碟測試設 `DAO_TEST_STORAGE_ROOT=E:/WORK/Dao2/tmp/talent1-storage-final`，僅隔離測試目錄。見[輸出](artifacts/content-p2-talents/final-regression-output.txt)，stdout／stderr另存 final-regression-logs。
4. `-Only 'content_p1_talents_runner.gd,m3b_alchemy_runner.gd,m3b_spirit_beast_runner.gd'`：最終三支通過，P1天賦913 checks；見[輸出](artifacts/content-p2-talents/final-effects-output.txt)，stdout／stderr另存 final-effects-logs。
5. Godot `--headless --path . --check-only --script res://src/abode/living_abode.gd`：exit0，啟動來源編譯通過。保留沙箱 `user://logs/godot.log` 無法寫入診斷，沒有 SCRIPT ERROR。

新專項以記憶體 StorageAdapter 注入 archive write／readback／slot write 故障，驗證舊主槽保持、同候選重試／重載單次扣10，v1/v2原文字節歸檔、import空白保留、非法v3矛盾拒絕。各階／批量1與99的單一成本、付款零餘草、相鄰浮點缺料原子拒絕、三島線上60tick與離線一致、調度／技能疊乘、滿倉、各階獸魂65+10L／無魂50+10L、成熟與輪迴保留均有有界證據。直接設定資格與Era屬明示 fixture，不是自然取得或自然養成證據。

## 失敗與限制

初輪新測試出現 soul_id／direct_herb 型別推斷、誤用 Amount.is_zero、故事／生命紀錄 fixture life_id 未同步，以及 StringName 測試鍵被 TALENT_ID 拒絕；均修正後重驗。兩次含 SCRIPT ERROR 的45秒逾時均算失敗，未延長預設時限。一次輸出 checks 通過但後段 SCRIPT ERROR 仍由工具拒絕，不採作成功。

付款邊界初測實際揭露 Amount compare_to 近似放行缺草，已限定修正v3兩種草費。SKS舊fixture未開島卻測產率、供給舊rules identity斷言已修正。L2原七支命令exit1：供給舊斷言及磁碟user路徑失敗；改斷言／隔離路徑後分段通過，不能將原命令改寫全綠。保留[失敗補驗輸出](artifacts/content-p2-talents/l2-retry-output.txt)。歷史暫存路徑因工具沙箱生命週期未能再讀，現行最終輸出與三組stdout／stderr已另存專案。

工作中偵測到外部同步修改多支runner、RunnerResult與測試工具，保留不覆蓋；本報告只認上述選取範圍。P1 runner會重寫來源fixture，本輪產物另存後逐字還原至開始時乾淨的HEAD版本，見fixture-preservation.json；未改玩家槽、未手改build／.godot、未commit/push。

未跑 L3／全尺寸／Web匯出／真實滑鼠，也未生成或接受三圖。沒有人工節奏或自然Era4代表路徑的新證據；這些為TALENT-2／整批範圍，不冒稱整批DONE。

## 下一步

依 Context Guard 本階段停止。下一 New Chat 接同任務 **TALENT-2**：三卡／三圖、當前與下一階精確作用說明、合法Era4輪迴道心代表路徑、同版1280×720桌面Web滑鼠與保存故障互動。沿U，不重問價格、不開其他P2／P3；整批節奏與美術接受後才唯一L3。
