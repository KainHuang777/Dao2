# EAR2-UI-F1：首次空島直接圖形化開拓

2026-10-11。IN_PROGRESS：來源／CLI／原生三橫式已交付，Web實際滑鼠、人工美術、觸控／高DPR待驗。

使用者核定省略獨立啟用說明流程。首次築基進空島直接選青木島，顯示靈木／下品靈石手繪物品框與可用／需求、開拓按鈕；材料不足或境界／啟用資格不符時禁用。首次開拓同時啟用產業，沒有額外「保留原檔並啟用」確認頁。系統訊息說明成本、祖島保留、輪迴清除與先青木後玄礦；短式摘要／TIP指引保持。尚未開拓不顯示無用產線入口／閒置訊息，前往世界禁用。短橫式開拓固定於頁首，材料內捲，無需先捲動找付款。

本島庫存直接展開，原展開按鈕不再建立；採集與加工物品仍使用原手繪圖格，無新增資產。其他制造／運輸／靈界入口保留於已開拓狀態。

首次開拓保存：SaveManager.activate_islands新增選填first_island（空值仍沿原行為）；先保存並歸檔精確原始資料，在候選Session初始化並提交正常open_island命令，候選雙槽驗證提交成功才替換正式state。原檔歸檔、schema／version不變。候選初始化／扣料失敗或保存失敗不替換來源、不扣正式材料；玩家可再次按開拓重試。既有已初始化開拓仍沿原命令與保存失敗／重試契約；未把普通操作改成第二套經濟。

修改src/presentation/island_management_panel.gd、feature_navigation.gd、src/persistence/save_manager.gd、src/simulation/onboarding.gd（只改引導文案）；tests/res1_ui1a_runner.gd、res1c_progression_runner.gd；tools/ear2_ui_f1_preview.gd及Godot生成uid；ROADMAP、docs/19／development-status、updata與本頁。既有dirty成果保留，沒有改成本／公式／保存版本／玩家origin，未commit/push。

工具與命令結果：

- 固定引擎tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version：4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA=build/ear2-ui-f1-*；--headless --path . --script res://tests/<name>_runner.gd：res1_ui1a（最終220 checks）、res1c_progression（最終91 checks）、early_flow1c、feature_navigation、m2d_responsive_ui、res1_ui1b六項exit0。包含原檔／候選提交故障、缺料首次開拓不變、拒寫後重試初始化＋開拓、一次扣料、庫存直接展開、Era2丹霞禁用與舊路由回歸。短頁首操作修訂後UI1A再次exit0；未重跑全量。
- --path . --script res://tools/ear2_ui_f1_preview.gd：隔離已賺得Era2來源fixture，三橫式首次／開拓後六圖，exit0；final-*為最終呈現證據。800×360人工確認固定開拓和兩材料完整；原生直接命令不等於Web滑鼠。
- --headless --path . --export-release Web build/web/index.html、bundled Node tools/prepare_web_compression.mjs build/web：最終exit0。PCK SHA256：CAC3D41B594123EB3920E10BE247D641DC69D67BBB944CFCC99EC8E59CD7D922。
- git diff --check受影響來源／測試／文件exit0。初跑can_initialize缺少bool型別導致解析錯誤且runner未退出，Ctrl+C停止後加明確型別重跑通過；corrupt fixture的預期JSON錯誤与既有Font RID／CanvasItem／ObjectDB退出診斷保留，不宣稱零錯誤。res1c_progression按原流程重新生成隔離earned-era2 fixture。

[圖片與log](artifacts/ear2-ui-f1/)。本輪沒有新的瀏覽器通過證據：同Session前輪IAB本機服務連線持續逾時，見uix-alchemy.md；不捏造實際滑鼠、觸控或IndexedDB。下一New Chat：隔離Era2未啟用origin首次進空島→材料不足／補料→固定開拓付款→青木庫存→玄礦開拓→重載；保存拒寫／原檔恢復與跨尺寸需實際Web驗證。收美術與裝置結果；依Context Guard本輪checkpoint，不展開大型下一任務，不重做已接受FPS或暫緩冷啟動。