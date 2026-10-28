# IMM-3C 全頁一致性核對（2026-10-28）

範圍：洞府＋十三功能頁，以及訊息、資源抽屜、設定／存檔、保存保護、離線報告五類共用覆層。依 [docs43](43-full-ui-adjustment-plan.md) IMM-3C 與 [docs42](42-graphic-inventory-review.md) 剩餘清單核對圖像層級、共用操作與文字串列；本輪只做 L1／L2，未執行 L3、全尺寸矩陣、正式候選包、觸控或實機。

狀態用語：

- **已調整**：本輪原始碼有變更，且有 runner／瀏覽器證據。
- **沿用且已核對**：既有接入已符合規範，本輪只核對並留證據，未重做。
- **不適用**：該頁沒有常態資源主區，或依閱讀目的保留文字（敘事／帳目／報告）。

## 本輪調整

1. `src/presentation/manufacturing_panel.gd:419-432`：`detail_stock` 不再逐項輸出「名稱：當地／祖島可用 x／需求 y」多行文字；材料需求只由 `detail_costs` 圖像成本列（`:470`）與格內 TIP 承載。保留在途到貨列（`:425`）與產物狀態列（產物可用／容量／在途／加工待完成／容量預留，`:432`），因為它們是狀態事實而非資源清單。
2. 同檔 `:450-451`：加工坊按鈕文字改為「加工坊N階・秒數／批」＋已達上限，不再內嵌「祖島支付：…」價格；升級成本只由 `workshop_costs` 成本列（`:491`，標題「升級加工坊 N→N+1 階」）呈現。
3. `src/presentation/island_transport_panel.gd:392`：升階按鈕只保留「運力N→M／10秒」與「升階保留啟停與已保存設定」，不再內嵌支付文字；成本由 `upgrade_costs` 成本列（`:421`，標題「升級運力 N→M／10秒」）呈現。`detail_stock`（`:380-382`）保留來源餘貨、已保存保留、目的容量預留、剩餘空間、已保存目標、運力與在途等帶標籤事實，不當物品清單。
4. `tests/content_p2_supply_ui_runner.gd:107` 改為驗證運輸升階成本列格數等於 `_info(id).upgrade_cost`，且按鈕不含「祖島支付」，不再假設按鈕內有價格字串。
5. 新增 `tests/imm3c_page_consistency_runner.gd`（已登錄 `tools/run_all_runners.ps1`），覆蓋十四頁與共用覆層；未改規則、存檔 schema、命令 payload、獎勵或既有禁用語意。

## 逐頁核對

| 頁面 | 狀態 | 核對與證據 |
| --- | --- | --- |
| 洞府 | 沿用且已核對 | 資源帶仍是 `building_catalog.resource_grid` 圖示列；IMM-1C 大圖選島與世界安全區未改。Runner 檢查 home 無工作列、`resource_ribbon` 可見；Web `ev-02/03` 顯示世界與管理殼。 |
| 洞府建築 | 沿用且已核對 | `building_catalog.gd:439` 的 `resource_summary` 未掛載（docs42 列為非缺陷）；卡片材料列沿用 24px 圖示＋可用／需求文字。建築詳情成本由 `abode.detail_costs` 共用成本列承載；runner 選可升級建築後核對格數、需求與 56×56 圖印。 |
| 空島 | 沿用且已核對 | `island_management_panel.gd:305-321` 地方庫存有圖示格，`local_stock` 僅作可見標題與 TIP（`tooltip_text` 多行只供查閱）；開拓／設施／付款為圖示格組，不混入跨界倉庫。Runner 核對 opening／facility／payment 圖印、來源 caption 隱藏與付款分組。 |
| 製造 | 已調整 | 本輪移除逐項材料可用／需求文字列，保留在途與產物狀態事實；加工坊按鈕去價格、保留成本列。Runner 核對 `detail_stock` 無逐項「：」清單、仍有產物／加工待完成、`workshop_costs` 有圖印、按鈕無「祖島支付」。Web `ev-17` 顯示材料需求成本列（玄鐵／磁晶圖印＋數量＋來源）而無文字資源列。 |
| 運輸 | 已調整 | 升階按鈕去價格，`upgrade_costs` 圖示列承接成本；來源餘貨／保留／目標／運力維持事實列。Runner 核對按鈕無「祖島支付」、成本列格數等於 `_info().upgrade_cost`、事實標籤存在。Web `ev-08` 直接顯示「運力10→20／10秒」按鈕＋「升級運力 10→20／10秒」圖示成本列。 |
| 技能 | 沿用且已核對 | 每階研習成本為單格技能點（來源當世）；效果、前置、禁用不變。Runner 掃描 `skill_view` 成本列圖印。 |
| 煉丹 | 沿用且已核對 | 沿用原圖像配方與共用物品格（28／44px 圖示、需求數量、摘要列）；摘要為壽元／產量／消耗事實，非資源清單。Runner 核對丹藥格圖印。 |
| 靈獸 | 沿用且已核對 | 餵養材料為祖島來源圖示成本列，獸魂維持獨立事實列「同種獸魂…不用於餵養」。Runner 核對成本列圖印與獸魂文字；docs43 的靈獸頁已由 IMM-3B 覆蓋。 |
| 成就 | 沿用且已核對 | 直接徽章領取／領訖印，無庫存主區；獎勵文字 `獎勵 · …` 為已接受的 UIX-R6-F2 例外。Runner 確認面板內無 CostStrip。 |
| 輪迴／天賦／歷世 | 沿用且已核對 | 天賦成本為道心圖示列（來源傳承），道心／道證仍分開；預設輪迴頁無資源入口，天賦頁才轉 focused。歷世數值表、卷末敘事與確認區保留閱讀形式（例外）。Runner 切換天賦頁核對成本列與抽屜，再切回輪迴頁確認 none。 |
| 九界 | 不適用 | 無共用庫存主欄；境界、法則與說明為資訊文字，不硬塞庫存。舊靈界據點晉升消耗已在 IMM-3A 使用成本列（`realm_teleport_modal.gd`），本頁不重複。Runner 確認九界預覽開啟且無資源入口。 |
| 宗門 | 沿用且已核對 | 功法／坊市貢獻＋材料為成本列（來源宗門），P2 短式保留單行文字成本（IMM-3B 明示例外，非主區多行清單）；委託獎勵沿用卡片圖示。Runner 核對功法／坊市 inventory 與貢獻圖印、歷練頁 fallback 文字。 |
| 機緣 | 沿用且已核對 | 主頁維持原版；選項成本與缺料為共用成本列，無成本時資源入口為 none。Runner 注入 pending 後核對付費選項成本列、免費選項無成本列、抽屜 inventory。 |
| 天道決策 | 沿用且已核對 | 法令成本為共用成本列；壽元消耗維持獨立「壽元消耗N秒」標籤，不混入物品格。Runner 掃描可見成本列圖印。 |

## 共用覆層

| 覆層 | 狀態 | 核對與證據 |
| --- | --- | --- |
| 訊息 | 沿用且已核對 | 敘事訊息保留文字閱讀；共用 CloseSeal／遮罩與返回原頁。Runner 開訊息後核對 shield、`hint_panel`、44px 關閉並返回原路由。 |
| 資源抽屜 | 已調整（沿用結構化接入） | supported 路由顯示共用 `InventoryPanel`（島別分組、圖示、數量、選中詳情），不再顯示 legacy 多行 `context_text`；宗門歷練與舊靈界據點保留 fallback 文字並註明原因。Runner 對 inventory／focused 路由開抽屜核對 `context_inventory` 可見、`context_scroll` 隱藏；Web `ev-09` 顯示分組圖示與「靈木 可用150／容量150 來源：青木島」。 |
| 設定／存檔 | 沿用且已核對 | 共用工具覆層、CloseSeal 44px、焦點與返回不退化；存檔命令不因排版改變。Runner 開 `save_controls` 核對 tool overlay、可見性與返回。 |
| 保存保護 | 沿用且已核對 | 保存失敗顯示既有警示與固定「重試保存」按鈕（≥44px），成功後清除；不新增自動重試。Runner 以 `set_save_result({"ok":false})` 核對警示與按鈕尺寸。 |
| 離線報告 | 不適用 | 離線結算／收益摘要屬報告與敘事，保留文字與原呈現，不強制改成圖示庫存。Runner 確認 `offline_summary` 無成本列。 |

## 例外（明確保留）

- 宗門 P2 功法／坊市成本：單行「貢獻＋材料」文字，沿 IMM-3B 決策保留；非 P2 已是圖示成本列。
- 宗門歷練、舊靈界據點的抽屜 fallback 文字：資料契約未提供結構化群組時明示原因，不反向解析文案。
- 空島 `local_stock` 與 `building_catalog.resource_summary`：只作 TIP／未掛載，不是可見多行資源主區。
- 敘事、訊息、收據、帳目、歷世數值表、離線報告、成就獎勵說明：依閱讀目的保留文字。
- 運輸保留量／目標／運力、製造產物容量／預留、決策壽元：是設定或事實標籤，不是物品數量。

## 驗證

- L1 單尺寸 1280×720：`imm3c` PASS 18.7 秒；`content_p2_supply_ui` 4.7、`imm3a` 8.6、`imm3b` 7.5 秒 PASS；`res1_ui1a`、`res1_ui1b` 為既有長測試，預設 45 秒逾時後以 `-TimeoutSeconds 150` 單獨重跑，分別 PASS 49.3／91.5 秒。全部無 `SCRIPT ERROR`。日誌：`C:/Users/asus/AppData/Local/Temp/dao2_runners_5cda3579eeae4e738246d8224c3dd567`、`.../dao2_runners_c33f9c60b70d4907b1016718492b6994`、`.../dao2_runners_252e21ac1d26412b8924327b3d2771b3`、`.../dao2_runners_967c2ad9bf5945d39d0369f3110afa99`。
- L2 桌面 Web 1280×720：本輪來源匯出 `build/web-imm3c`，於 `127.0.0.1:4418/launcher` 載入 Era3 隔離存檔，Edge／CDP 真實滑鼠抽驗管理殼、製造材料成本列、運輸詳情、資源抽屜。證據在 gitignored `.test-output/imm3c-web/`：`ev-02-shell.png`、`ev-03-manufacturing.png`、`ev-08-transport-detail-down.png`、`ev-09-resources-drawer.png`、`ev-17-manufacturing-title-select.png`。Web 只證明桌面滑鼠／尺寸呈現，不聲稱 IndexedDB 落盤、FPS、觸控或實機通過；製造設定卡在 Web 抽驗中只展開至材料需求區，加工坊成本列與按鈕文字以原生 runner 為準。

## 結論

十四頁與五類覆層均留下狀態與證據；本輪已清除 docs42 指出的製造逐項資源文字列與製造／運輸按鈕重複價格文字，未發現其他未處理的常態多行資源主區。敘事／帳目／報告與 P2 短式成本例外已明列。完整介面尚未結案，下一個任務為 IMM-4 整批收尾（唯一 L3）。
