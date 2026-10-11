# UIX-R3-F2 — 共用分頁、黑體、關閉與前期入口

2026-10-11 有界修訂 DONE，人工美術／實體觸控／高DPR待驗。使用者指定第二張資源三態截圖為目前共用分頁樣式，覆蓋R3-F1的明體／朱砂小印。正式共用規範：[19 UI／UX](../19-ui-ux-guidelines.md)。

改動：GameTab與SegmentChips沿 `UiMaterial.mark_paper_tab()`，功能分頁／資源三態／建築分类／製造分类／島嶼單選共用紙面未選中、青玉選中與細金底線。正文／分頁黑體400，標題同黑體600；舊明體資產保留但章題不再使用。CloseSeal44px深墨叉號，常態透明背景，hover／按下淡墨回饋。

查核核心：IslandProgression.preview要求Era2；IslandEconomy正式產業命令要求Era2，青木／玄礦Era2、丹霞Era3；manufacturing_view也在Era2且產業已啟用才可操作。因此FeatureUnlocks在Era1隱藏outposts／manufacturing／transport，FeatureNavigation攔情境捷徑並回建築。Era2顯示三頁但原啟用／開拓／設施／缺料資格不變。Era1原煉丹保留，無規則／保存schema変更。

修改檔案：src/presentation/components/{game_tab,segment_chips,close_seal}.gd、ui_material.gd、ui_typography.gd、feature_unlocks.gd、feature_navigation.gd、building_catalog.gd、manufacturing_panel.gd、island_management_panel.gd；tests/{feature_navigation,uix_r1_components,uix_r2_hud}_runner.gd；AGENTS、README、ROADMAP、docs07/12/18、docs/ui_overhaul_plan、ai-handoff、development-status、updata、新docs19及本頁。既有dirty成果保持，未commit/push，無新素材或Windows匯出。

命令與結果：

- 現有Godot4.7.2（上輪已確認4.7.2.stable.official.ed1daf0bf）。各次APPDATA隔離至build/uix-r3f2-*；--headless --path . --script res://tests/<name>_runner.gd：feature_navigation、uix_r1_components（80／0）、uix_r2_hud（67／0）、res1_ui1a（217）、m2d_responsive_ui、ui_material_states、uix_r4_building_cards七項exit0。新增Era1隱藏／情境返回、Era2顯示、共用字型及樣式斷言。HUD製造布局用隔離Era2。未重跑全量。
- 初始components舊測試要求CloseSeal黑底，exit1；按使用者新方向更新為透明底再跑80／0。既有Font／CanvasItem／ObjectDB退出診斷保留。
- --headless --path . --export-release Web build/web/index.html：exit0。bundled Node tools/prepare_web_compression.mjs build/web：exit0。正常Web已同步。
- bundled Python tools/island_preview_server.py --port48222／48223 --normal-build --gzip：兩個隔離origin服務成功；以Ctrl+C主動停止，exit1為中止。

真實IAB：48222正常新檔Era1，844×390經營僅建築、與資源三態樣式一致；修行煉丹→成就及800×360、固定叉號返回通過。48222的Seed保留已存在隔離進度，未覆寫，改用全新48223載入既有命令生成築基fixture，這是呈現驗證而非本輪自然時間築基。Era2四經營分頁、製造精煉分類、運輸與尚未啟用時的禁用內容通過。1280×720桌面呈現與800×360實際切頁／關閉通過；桌面關閉座標超出工具當前content bounds，切短式實際驗關閉，不把該失敗當成功。兩tab console warn/error查詢空；驗收tab已關閉。

截圖與日誌：artifacts/uix-r3-f2/。可看[Era1經營](artifacts/uix-r3-f2/era1-844.png)、[修行844](artifacts/uix-r3-f2/cultivation-844.png)、[修行800](artifacts/uix-r3-f2/cultivation-800.png)、[Era2經營](artifacts/uix-r3-f2/era2-800.png)、[桌面運輸](artifacts/uix-r3-f2/transport-1280.png)。無新增FPS／保存故障矩陣／實體觸控或高DPR證據。

下一步：收本輪美術回饋，較大的UIX-R5用New Chat界定範圍。完整C/D與實機／人工節奏限制保持。未重做已過保存／FPS或暫緩冷啟動。

工具clip截圖回傳白底，已刪除無效近照，以上完整截圖為有效證據；未使用該白底圖作驗收。git diff --check相關tracked來源／文件exit0，僅LF→CRLF提示。
