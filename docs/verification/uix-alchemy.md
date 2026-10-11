# UIX-R5-ALCHEMY：煉丹圖形化與同屏HUD

2026-10-11。使用者指定此有界範圍；IN_PROGRESS（來源／CLI／原生已交付，Web實際互動與人工美術／觸控／高DPR待驗）。R4與現有製造／運輸圖示契約已滿足相依。

交付：煉丹頁橫式保留左修行HUD、BUFF與資源清單，右工作區依HUD實際邊界分配。入頁時原資源模式為關閉則展開數量。桌面保留三態選擇；短橫式暫收資源模式列以留出至少一列可讀庫存，原模式保持、返回恢復。資源可內捲。煉丹頁常態不再覆蓋HUD或BUFF。

右側沿製造／運輸物品框：材料圖示與祖島可用／需求、局部缺料朱紅→丹藥圖與持有量→44px以上煉製／服用按鈕。可用工作寬≥850雙欄、其餘单欄，材料HFlow換行、配方內捲。移除長敘述正文，以標題／丹藥／按鈕TIP提供效果與操作條件；固定簡短丹道摘要、頁內成功／拒絕回饋。短工作區暫收重複頁題／摘要，使用上方固定煉丹分頁與CloseSeal返回，增加配方可視高度。共用紙底深墨、字型、CloseSeal与Theme。

即時效果：聚靈丹仍為立即修煉進度；延壽丹與築基丹既有當世加成由唯讀alchemy.effects追加「壽」／「丹」BUFF字印，點擊沿既有詳細popup；不新增假倒數或正式buff存檔，輪迴後View清零即移除。服用命令成功後沿_refresh_hud即時更新HUD／BUFF／庫存。築基丹在已啟用Era2產業時保留前往祖島製造入口，材料讀manufacturing.inputs實際需求／可用量，不顯示Era1舊成本。

修改檔案：src/presentation/alchemy_panel.gd、feature_navigation.gd、abode_hud_controller.gd、buff_hud_bar.gd、abode_modal_manager.gd；tests/m3b_alchemy_ui_runner.gd；tools/uix_alchemy_preview.gd及Godot生成uid；ROADMAP、docs/07／18／19／development-status、updata與本頁。未改規則、成本、收益、schema或玩家存檔；既有dirty成果保持，未commit/push。

資產沿用assets/ui/resources-painted既有手繪材料与foundation_pill（來源／提示詞／切層／授權沿既有manifest）。聚靈丹／延壽丹本輪共用同一丹藥家族示意圖，名稱與TIP區別實際效果，沒有宣稱三種專用原畫；沒有新生成圖或外部資產。BUFF字印沿既有共用元件。

驗證命令與結果：

- 固定引擎tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe，同Session --version確認4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA=build/uix-alchemy-*；引擎 --headless --path . --script res://tests/<name>_runner.gd：m3b_alchemy_ui、feature_navigation、m3b_alchemy、buff_system、uix_r2_hud、res1_ui1a、early_flow1b與m2d_responsive_ui八項exit0。UI新增煉製／服用／頁內回饋／丹藥效果BUFF、三橫式HUD／資源／BUFF同屏、HUD不重疊、固定返回、资源至少38px行、材料庫存需求與TIP／深墨文字斷言。最终小修字名後alchemy UI再次exit0。未重跑全量。
- 原生 --path . --script res://tools/uix_alchemy_preview.gd：三橫式各服用前後、最終exit0；人工看圖1280×720、844×390、800×360確認同屏HUD／BUFF／資源、配方字色與頁內服用回饋。最終圖以verified-*為準；初稿圖保留歷史（淺字、重複摘要占位，以及跨尺寸fixture未補丹的拒絕提示已修正）。不以原生當Web／触控證據。
- --headless --path . --export-release Web build/web/index.html与bundled Node tools/prepare_web_compression.mjs build/web：最终皆exit0。
- bundled Python tools/island_preview_server.py --port 48765 --normal-build --gzip：啟動成功；IAB createBrowserTab仍net::ERR_CONNECTION_TIMED_OUT，沒有進遊戲、沒有Web通過證據。服務Ctrl+C停止（exit1為主動中止），其他origin未操作。
- git diff --check（受影響來源／測試／文件）exit0。既有Font RID／CanvasItem／ObjectDB退出診斷保留，未宣稱零錯誤。

[最終原生圖與log](artifacts/uix-alchemy/)。Web PCK SHA256：057C00420D71CECDE6629950CFAAA6C2AEC13F19AABBF9C199F6F58B5F97762C。

下一New Chat：使用隔離origin實際滑鼠煉製／服用聚靈丹、延壽丹與築基丹，核對資源扣除／持有量、訓練與壽元／產率BUFF即時變更；Era2產線入口與真實成本、配方捲動／TIP／固定返回／資源內捲與三橫式實際命中。另收美術與實體觸控／高DPR；茅屋與Debug圖示前輪Web待驗保持。依Context Guard停止在本輪checkpoint，不展開下一大型階段，不重做已接受FPS或暫緩冷啟動。