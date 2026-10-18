2026-10-17 最新結案：使用者明確回覆「R7 美術接受」。UIX-R7-REINCARNATION於桌面／Web有界範圍標記DONE；最終以F3無空白槽版本為準，F1／F2技術證據沿用，下方待接受／下一輪回饋記載保留為歷史。觸控／實機延期，非當前阻擋。本次僅文件／既有log與hash核對，未重跑遊戲或改玩家資料；R8尚未開工。

# UIX-R7-F2 · 卷軸裝飾安全邊界

2026-10-17。使用者指出輪迴主按鈕與底軸相碰，並詢問是否漏算圖片底部厚度。本輪修正呈現邊界；不改輪迴、收益、保存或自動彈出規則。R7整體仍待最終美術接受，不開R8。

## 根因與修正

`reincarnation_panel.gd`原本使用背景 `Panel` 與同層 `MarginContainer`。Panel只畫StyleBox，不像PanelContainer自動將內容放到StyleBox的content margins內。獨立MarginContainer寫死上下8px，正式SVG底軸由y115畫到125（128px圖），占底部約13px；因此按鈕雖然在Control矩形內，仍碰到可見底軸。原測試只查面板矩形包含footer，沒有檢查裝飾安全區。

- `src/presentation/ui_material.gd`：正式卷軸上下內容內距20px，底軸外另留約7px淨距；細軸版上10／下14px。新增 `apply_scroll_content_margins()`，讓手動MarginContainer沿同一素材StyleBox內距，不再另寫一組數字。texture margin（九宮格切片）、content margin（內容安全區）分開使用。
- `reincarnation_panel.gd`、`achievement_panel.gd`、`alchemy_panel.gd`：背景／手動內容內距共同選正式或短式細軸版本。輪迴主按鈕仍置中；桌面圖176px、短式56px，短式以命燈／資格標題及收益兩行優先。保留44px操作、內捲與確認取消，不以固定上移座標修正。
- `island_management_panel.gd`：PanelContainer自動沿共用StyleBox；短式用細軸，內層欄間距8→4。包含繼承的製造／運輸，避免增加邊界後把首卡材料或完整航線卡推出畫面。system_actions與轉世結算卡等原生PanelContainer也沿正式20px安全邊界；既有額外card_margin保留。
- `tests/uix_r7_reincarnation_ui_runner.gd`：三尺寸新增footer避開底軸、內容避開頂軸與短式收益可見檢查，從68→75 checks。`tools/uix_r7f2_preview.gd`提供三尺寸輪迴五狀態與成就／煉丹／技能對照。
- 同步07、19共用規範、Roadmap、README、handoff、development-status及英文updata頂部；保持既有dirty成果，不commit/push。

## 命令與結果

實測Godot `4.7.2.stable.official.ed1daf0bf`，未升級環境。CLI／預覽APPDATA與user資料隔離於`build/uix-r7f2-*`，未覆寫玩家進度。

| 命令／工具 | 最終結果 |
| --- | --- |
| Godot `--version` | exit0，4.7.2 |
| `--headless --path . --script res://tests/uix_r7_reincarnation_ui_runner.gd` | 75 checks、failed=false、exit0 |
| `uix_r6_achievement_ui_runner.gd` | 221 checks、failed=false、exit0；128px／短式112px保持 |
| `m3b_alchemy_ui`、`feature_navigation`、`m2d_responsive_ui` runners | 各exit0 |
| `res1_ui1a_runner.gd`／`res1_ui1b_runner.gd` | 223／220 checks、各exit0 |
| `uix_r1_components_runner.gd` | 80 checks、0 failures、exit0 |
| `--path . --script res://tools/uix_r7f2_preview.gd` | exit0；1280×720、844×390、800×360共24張PNG |
| bundled Python `tools/subset_game_fonts.py --check` | exit0，無需重建字型 |
| Godot `--export-release R7Acceptance build/r7-acceptance/index.html`／`--export-release Web build/web/index.html` | 最終各exit0 |
| bundled Node `tools/prepare_web_compression.mjs build/r7-acceptance`／`build/web` | 最終各exit0 |
| `git diff --check`／嚴格UTF-8回讀 | 均通過；diff exit0 |

中間失敗如實保留：第一輪正式邊界壓縮成就800px短式徽章可用高度（`enlarged badge follows available height`）；製造800px首卡材料及運輸800／600px首卡被推出可視區。已以短式細軸及內部欄間距修正，沒有放寬既有驗收斷言。最終相關runner均重新通過。既有Font RID／CanvasItem／ObjectDB退出診斷仍在，不能稱零錯誤日誌。未跑全量runner或重做既有FPS／冷啟動矩陣。

## 桌面Web與接手

最終CUA IAB桌面Web：獨立 `127.0.0.1:48773/index.html?r7f1=1`，1280×720、844×390、800×360，DPR約1；短式畫布有瀏覽器約1px取整。實際壽盡自動開頁，1280主按鈕／確認／取消，以及800確認／重置全文內捲／取消、切成就／煉丹／返回洞府均通過。畫面可見主按鈕與底軸分離；`web-*.jpg`保存原始瀏覽器截圖，console warn/error查詢空。只驗本輪UI範圍，未把此輪廻頁間距測試宣稱為完整自然修行／保存矩陣。

獨立版PCK SHA256 `b282ea6d881101c30d1159215323296c85444ca88d2007a9cd604a00f3df6692`；一般Web `cb522ce8f4ef95538ab38e4cf0213485435aa7b610d12a240dd75f0486b1fafd`，兩版已最終匯出／壓縮。服務48773以Ctrl+C停止（exit1為主動停止）、本輪分頁關閉、viewport覆寫還原。沿明示R7Acceptance fixture，不是自然玩家進度證據；未碰玩家origin。原生24圖與CLI日誌在`artifacts/uix-r7-f2/`。本輪無新美術生成，不改原圖／素材授權。

下一New Chat收R7美術與間距回饋；R7維持IN_PROGRESS，不開R8。觸控／實機延期，非當前阻擋；不把CLI矩形檢查冒充實際滑鼠操作證據。
