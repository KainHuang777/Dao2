# UIX-R4-F2：遊戲式雙欄營造卡片

2026-10-11，有界來源／CLI／桌面Web DONE；人工美術、實體觸控與高DPR待驗。

依使用者本輪兩張圖片與明確要求，覆蓋R4-F1的常態單欄。沿用現有手繪PNG：整張紙卡包住建築縮圖、名稱／階級、材料圖示與庫存／需求及小型操作。縮圖56px，材料字16px，需求比例只繞縮圖，沒有独立進度條。操作寬64px、至少44px命中；材料不足／前置不足分兩行，滿階縮為「滿階」，禁用按鈕較暗，必要成本文字保持可讀。沒有新增圖形資產、世界地塊、成本、工時、收益或schema。

桌面最大620px雙欄，極窄內容寬不足520px才回單欄；桌面主動開啟訊息時沿400px單欄避免重疊。短橫式採完整抽屜寬度與雙欄，收起分類／分組標題與左側HUD／資源，材料仍在卡片；原晉階／突破按鈕移至固定頁首，離開後回原HUD。頁首／關閉固定、清單內捲、詳情取代清單並返回原位置。

修改：src/presentation/building_catalog.gd、feature_navigation.gd、abode_hud_controller.gd；tests/uix_r4_building_cards_runner.gd、ui_material_states_runner.gd、feature_navigation_runner.gd、m2d_responsive_ui_runner.gd、abode_presentation_parity_runner.gd；README、ROADMAP、docs07/08/18/19、handoff、status、updata與本頁。開工既有大量dirty均保留；未commit／push或Windows匯出。

命令與結果：

- 現有tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version：4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA=build/uix-r4-f2-user，--headless --path . --script res://tests/<name>_runner.gd：uix_r4_building_cards、ui_material_states、feature_navigation、uix_r2_hud、abode_presentation_parity、m2d_responsive_ui最終全部exit0。沒有重跑全套62。首次材料／navigation斷言因舊單欄／樣式／提示開關狀態exit1，更新新契約後通過。parity原先未計R3-F2的Era1空島回建築導致exit1，補計可見營造簿後exit0。引擎既有Font RID／CanvasItem／ObjectDB／resource退出診斷保留。
- --headless --path . --export-release Web build/web/index.html：最終exit0。
- bundled Node tools/prepare_web_compression.mjs build/web：最終exit0，BGM companions同步。
- git diff --check受影響來源／測試：exit0，僅LF→CRLF提醒。
- 最終PCK SHA256：F56B5F8B215EE5C5A632F5A14E34FA6B988852DC51D1DDAE67900921D1510B63。

真實IAB／DPR約1：bundled Python tools/island_preview_server.py --port48761 --normal-build --gzip，使用獨立origin與正常命令築基fixture。舊48222測試origin已有離線進度，保留並改用全新48761，不清除或覆寫玩家資料。沙箱localhost連入逾時，正常授權服務後可用；最終匯出／壓縮完成後重啟測試服務以避免prewarm舊包。

實際滑鼠聚靈壇2→3階、扣金錢85／靈木34，重載保留3階；最終版建造築基靈池1階、庫存由800／300／300降至約707.68／252.40／282.4（持續產率造成少量回補）。1280×720、844×390、800×360 CSS iframe雙欄、短式首排材料／操作完整、內捲／固定關閉、頁首晉階、桌面恢復HUD、木料庫展開／詳情／收起返回通過。最終console warn/error查詢空。

初次短橫式實測出現左HUD與卡片重疊且邏輯寬779導致單欄；修為完整抽屜後重新匯出與驗收。後續收緊頁首留白／短式分組標題，使800×360首排成本與操作完整可見。不能用早期失敗截圖作最終證據。

證據：[桌面](artifacts/uix-r4-f2/web-1280.png)、[圖卡](artifacts/uix-r4-f2/catalog-final.png)、[844](artifacts/uix-r4-f2/web-844.png)、[800](artifacts/uix-r4-f2/web-800.png)、[建造](artifacts/uix-r4-f2/web-build.png)、[詳情](artifacts/uix-r4-f2/web-detail.png)。CLI／匯出日誌同目錄。

未驗：使用者美術接受、實體觸控／高DPR、既有C/D缺口。未重測已接受FPS／保存故障矩陣或暫緩冷啟動。完成後依Context Guard更新英文checkpoint並停止；下一New Chat收本輪回饋，再界定大型UIX-R5。

驗收收尾：本輪建立的分頁已關閉，viewport override已reset；48221／48222／48761測試服務以Ctrl+C停止（exit1為正常中止）。未操作其他服務。最終文件git diff --check exit0，僅CRLF提醒。
