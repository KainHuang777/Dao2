# UIX-R8-SKILLS：研習卷冊

2026-10-17，IN_PROGRESS：素材、Godot接入、CLI／原生／桌面Web驗收交付；美術待使用者接受。當次「R8 開工」覆蓋歷史不開R8指示；R9不在本輪範圍。

## 交付

- `assets/ui/skills-painted/`：六技能透明PNG＋研習卷軸題圖，runtime各336px。桌面技能112px、短式80px，頁首題圖64px且短式收起。完整alpha輪廓配適，16px透明邊界；未重畫生成alpha。
- [manifest](../../assets/ui/skills-painted/manifest.json)、[完整提示詞及生成路徑](artifacts/uix-r8/generation-records.json)、`artifacts/uix-r8/originals/`與逐圖prompt：內建ImageGen、2026-10-17、無外部參考圖；來源為本專案生成，不宣稱第三方商用授權。
- `src/presentation/skill_study_view.gd`：獨立技能呈現，固定技能點／來源／經營建築捷徑，內容內捲；工作區最多1120px、內容寬至少1000px雙欄，其餘單欄。短式保留來源於技能點列，經書殿擴容／選修與輪迴規則保留TIP；桌面常駐完整說明。
- 每張卡為圖、名稱／等級、當前與下階累積效果、每階成本、固定右側44px以上研習。狀態為研習未開／點數不足／研習／已滿級。刷新重用卡片及按鈕，不因點數增減重建滑鼠目標。
- `src/simulation/skill_system.gd`只擴充View的`current_effect`／`next_effect`文字，乘數由既有amount乘冪、加值由amount×level；未改成本、效果、上限、解鎖、輪迴或保存schema。下階顯示下階總加成，不虛構全域收益；完整作用條件沿原description TIP。
- `system_actions_panel.gd`沿原卷軸接技能子頁；靈獸／決策mode保留。保存回饋固定在頁首；新增重試按鈕只呼叫保存、不重送命令，普通保存與背景恢復均清除失敗狀態。
- `feature_navigation.gd` skills頁擴工作區；頁首預留設定鈕以viewport為準，修正從洞府重開時使用舊設定矩形導致CloseSeal遮擋。未更換GameTab、CloseSeal或字型規則。
- 保存恢復接線：`src/abode/living_abode.gd`、`feature_navigation.gd`；獨立fixture：`src/verification/uix_r8_acceptance.gd/.tscn`、`project.godot`、`export_presets.cfg`、`tools/uix_r8_server.py`。fixture初始化明示Era2／藏經閣／經書殿／6200點，已有fixture標記不重種；不冒充自然前期流程。
- 測試／工具：`tests/uix_r8_skills_ui_runner.gd`、`tools/uix_r8_preview.gd`、`tools/uix_r8_assets.py`、固定入口追加R8 runner。字型子集補「種／閱」兩字，原TTF未改。

## CLI與原生

引擎驗證：`tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`。所有Godot測試APPDATA隔離至`build/uix-r8-tests`。

1. `--headless --path . --editor --import`：exit0，保留各輪import log。沒有手改`.godot/`或匯出物。
2. `--headless --path . --script tests/uix_r8_skills_ui_runner.gd`：最終 **92 checks failed=false、exit0**，見[專項log](artifacts/uix-r8/uix_r8_skills_ui-verified.log)。覆蓋Era1／缺藏經閣／缺點、真實研習扣90、原子升級、拒寫重試不重扣、實際隔離檔重新configure後讀回、滿級、按鈕穩定、三尺寸安全邊界／最後操作／固定頁首／重開CloseSeal、長數字、建築導覽及共用mode往返。
3. `tools/run_all_runners.ps1`：第一段前44項exit0，於EARLY-FLOW1-B舊文字斷言停止；修正後從B到結尾25項全部exit0，**固定入口69項已分段通過**，不稱一次全量無失敗。第一段[完整log](artifacts/uix-r8/all-runners.log)與[後段輸出摘要](artifacts/uix-r8/remainder-summary.txt)。最終導覽／HUD／響應式另重跑exit0，見各`*-verified.log`。技能基線41、靈獸、天道決策、輪迴與命令保存相交回歸均包含。
4. `--path . --script tools/uix_r8_preview.gd`：exit0，三橫式1280×720／844×390／800×360，每尺寸locked／ready／last／save-error，共12張；[桌面](artifacts/uix-r8/ready-1280x720.png)、[短式](artifacts/uix-r8/ready-800x360.png)。原生僅fixture視覺證據。
5. bundled Python＋`PYTHONPATH=build/tool-deps`，`tools/subset_game_fonts.py`重建，再`--check`：exit0。缺字初次失敗log保留。
6. `--headless --path . --export-release Web`與`R8Acceptance`：均exit0。bundled Node `tools/prepare_web_compression.mjs build/web`與`build/r8-acceptance`：均exit0，包含既有音樂companions。

最終PCK SHA256：

- 一般Web：`23C9F0600BBE1D936B65ED52CB7FAD6E213844EDE038C311794199E7154C951A`
- R8驗收：`778CD9F4DBF6CD71A08E30679FF4C7D836D58044A7694BA3AC66BB56CBB6DB99`

本輪中間錯誤保留：GDScript不支援`%g`（改`%.0f`）；初版測試誤用不存在的`load_game`（改configure後`load_state`）；卡片過高導致最後操作不可完整見（縮減間距／精簡效果文字修正）。HUD舊測試要求所有製造卷軸必為正式軸，按既有R7短式細軸規範修正。EARLY-FLOW1-B期待「啟用空島」，實際View／畫面為「下一步：開拓青木島」，更新斷言核對真實View及現行目標，未改前期規則。退出Font RID／CanvasItem／ObjectDB／資源與anchor診斷仍在，故障資料測試含預期JSON錯誤，不宣稱日誌零錯誤。

## 桌面瀏覽器

CUA IAB，隔離`localhost:48774`，與玩家origin分離。`tools/uix_r8_server.py --port 48774`只綁127.0.0.1。沙箱服務首次IAB連線`ERR_CONNECTION_TIMED_OUT`；停止後以主機層啟動同一loopback服務成功。最終匯出後重啟服務清除prewarm舊快取。

- 初版真實滑鼠：6200→6110／冥想0→1；重載1階保留（離線正常產點後6124）；844px再研習2階、建築精通付款200後1/1滿級；800px內捲、關閉重開與經營建築捷徑。此段先於最終頁首修正，不冒充最終hash。
- 最終版：`fault.html`正常讀既有2階、6200點；DOM按拒寫，再真實滑鼠研習→全畫面保存遮罩；拒寫中重試仍被拒；恢復儲存後重試→3階、頁面顯示已恢復保存，重試鈕消失。正常`index.html`重載仍3階及建築精通1/1。背景結算會依實際離開時間產技能點，恢復後6122、再重載6136屬正常產點；CLI另以凍結時鐘精確證明只扣90。
- 最終1280／844／800px：技能點／來源、真實卡片、固定分頁與關閉、內捲到底、800px從洞府重開關閉印不被設定遮擋；360×640顯示阻擋旋轉提示，回844保持技能頁。DOM量測844×390、canvas843×389，無頁面捲軸；這是桌面響應式驗證。
- `?r8long=1`為純呈現fixture：替換View中的30位點數與長冥想名稱，不寫入狀態。三尺寸均完整可讀，桌面長名稱換行，操作固定；不以fixture宣稱實際持有該大數或Amount全量契約。
- 最後正常長文頁console warn/error查詢為空；故障頁有預期SecurityError。所有瀏覽器操作經CUA真實滑鼠／捲輪，未用JS注入遊戲命令、庫存或保存。

證據：[最終桌面重載](artifacts/uix-r8/web-final-reload.jpg)、[800px](artifacts/uix-r8/web-final-800.jpg)、[844px](artifacts/uix-r8/web-final-844.jpg)、[內捲](artifacts/uix-r8/web-final-scroll-800.jpg)、[拒寫](artifacts/uix-r8/web-denied.jpg)、[恢復](artifacts/uix-r8/web-recovered.jpg)、[桌面長文](artifacts/uix-r8/web-long-1280.jpg)、[短式長文](artifacts/uix-r8/web-long-800.jpg)。

## 尚未結案與下一步

R8美術／比例待使用者接受，保持IN_PROGRESS。下一New Chat只接R8回饋，不自動開R9宗門。沒有修改玩家保存，未commit/push，保留既有dirty成果。依使用者政策，觸控／實機延期，非當前阻擋；不重做已接受FPS或暫緩冷啟動矩陣。驗收自建服務與暫時分頁於收尾關閉，viewport reset。

收尾檢查：`git diff --check` exit0；12份當輪檔案嚴格UTF-8、驗收本地連結與七項manifest路徑均PASS；PCK再次核對與上列hash相同。服務以Ctrl+C停止，exit1為主動終止；沒有停止其他服務。僅清理本輪R8 evidence資料夾生成的`.import` sidecars，保留原圖、PNG與所有`.uid`；較早逾時產生的無法取得分頁仍未操作。最終全覽見[Web畫面](artifacts/uix-r8/web-final-overview.jpg)。
