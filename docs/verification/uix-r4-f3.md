# UIX-R4-F3：放大建築與右側資訊

2026-10-11。有界來源／CLI／桌面Web DONE；使用者美術接受、實體觸控／高DPR仍待驗。

使用者指出F2卡片右側空白過多，要求放大建築圖並將資訊放在圖右。沿用F2雙欄／框內材料／外環／禁用暗色：建築縮圖56→88px（約57%放大），104×108px圖像操作區在左，右側VBox填滿剩餘寬度；名稱／階級和64px小型動作並排於右上，材料ICON＋庫存／需求位於右下，窄卡自動逐項換行。原展開說明與詳情入口由建築圖點入；晉階／突破／頁首／短橫式抽屜保持F2。

修改src/presentation/building_catalog.gd，及tests/ui_material_states_runner.gd、uix_r4_building_cards_runner.gd、m2d_responsive_ui_runner.gd；更新README、ROADMAP、docs07/08/18/19、status、handoff、updata與本頁。沿用现有圖片與授權紀錄，沒有新資產、世界配置、經濟或存檔變更；開工dirty保持，未commit/push。

命令結果：

- 固定引擎tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version確認4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA=build/uix-r4-f3-user；--headless --path . --script res://tests/<name>_runner.gd：uix_r4_building_cards、ui_material_states、m2d_responsive_ui、feature_navigation四項exit0。追加幾何斷言確認材料位於圖右且動作包含於卡框，card／responsive再跑exit0。未重跑全套62。
- --headless --path . --export-release Web build/web/index.html exit0；bundled Node tools/prepare_web_compression.mjs build/web exit0。
- git diff --check受影響來源／測試exit0。既有Font RID／CanvasItem／ObjectDB退出診斷保留，不稱乾淨日誌。

真實IAB／獨立origin48763：bundled Python tools/island_preview_server.py --port48763 --normal-build --gzip，正常命令築基fixture；1280×720、844×390與800×360 CSS iframe（DPR約1）雙欄圖文無重疊、首排成本與操作完整。實際新位置聚靈壇升級2→3、扣料與成本85/34→112/44刷新；點放大圖展開說明、詳情／收起返回，以及小尺寸固定關閉皆通過。console warn/error查詢空。本輪沒有新增重載或保存故障證據，F2重載證據保留，未覆寫其他origin玩家進度。

截圖與命令log：[目錄](artifacts/uix-r4-f3/)，[最終卡片](artifacts/uix-r4-f3/catalog-final.png)、[桌面](artifacts/uix-r4-f3/web-1280.png)、[844](artifacts/uix-r4-f3/web-844.png)、[800](artifacts/uix-r4-f3/web-800.png)、[升級](artifacts/uix-r4-f3/web-upgrade.png)、[詳情](artifacts/uix-r4-f3/web-detail.png)。

未驗與下一步：使用者比例／美術回饋、實體觸控／高DPR及既有C/D保持待驗。不重跑已接受FPS或暫緩冷啟動。本輪完成checkpoint；下一New Chat收卡片比例回饋，不開大型UIX-R5。

最終PCK SHA256：D99709A1C2EA4C364B4058506D5CB3ECAD5B17931E19A2955DD965A737EB31D5。

收尾：測試分頁已關閉／viewport reset；48763服務Ctrl+C停止（exit1正常中止）。
