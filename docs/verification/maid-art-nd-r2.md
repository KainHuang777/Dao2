# MAID-ART-ND-R2 接入驗收（L1＋原生渲染抽驗）

日期：2026-11-01
範圍：糯美子／丹霞 R2 立繪與初遇 CG 正式接入人物頁；青蘅美術不變。

## 驗收級別

L1（單一 1280×720）＋一次非 headless 原生渲染抽驗。未跑 L3 全量、全尺寸矩陣、Web 匯出或桌面瀏覽器。

## 修改檔案

- `src/presentation/maid_character_panel.gd`：`ART` 表按角色路由立繪／CG；`STORIES` 提供各角色小傳與初遇文本；切換角色時重置對話並刷新立繪／CG；印章、書籤、小傳佔位依 `art_ready` 顯示；新增 `_art()`／`_story()`／`_has_art()`／`_load_portrait()`／`_load_meeting()`／`_sync_story()`／`_sync_choices()`。
- `src/presentation/maid_portrait_viewer.gd`：`present(texture, owner)`，完整立繪標題顯示當前角色，不再固定青蘅。
- `src/presentation/feature_navigation.gd`：`portrait_requested` 改帶角色名並呼叫 `present()`。
- `src/simulation/maid_system.gd`：新增 `ART_READY`，`get_view()` 的 `art_ready` 對三位角色為 true；不參與招募／羈絆／職掌判定。
- `tests/maid_art_r2_runner.gd`（新增）：78 checks。
- `tools/run_all_runners.ps1`：註冊新 runner。
- Godot import 產生 `assets/characters/{nuomeizi,danxia}/*.png.import` sidecar（R1 與 R2 共八份）。

## 資源路由

| 角色 | 立繪 | 初遇 CG |
|---|---|---|
| 青蘅 | `res://assets/characters/qingheng/portrait.png` | `res://assets/characters/qingheng/first-meeting.png` |
| 糯美子 | `res://assets/characters/nuomeizi/portrait-r2.png` | `res://assets/characters/nuomeizi/first-meeting-r2.png` |
| 丹霞 | `res://assets/characters/danxia/portrait-r2.png` | `res://assets/characters/danxia/first-meeting-r2.png` |

R1 `portrait.png`／`first-meeting.png` 對糯美子／丹霞保留為歷史檔，不再被程式引用。

## 命令與結果

1. `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`
   - exit 0，輸出無 `SCRIPT ERROR`；生成四位角色共八份 `.import`。
2. `tools\run_all_runners.ps1 -Only 'maid_ui_runner,maid_ui2_runner,maid_art_r2_runner'`
   - 3/3 PASS，matrix=single（1280×720）。
   - `MAID-UI checks=37 failures=[]`
   - `MAID-UI2 checks=56 failures=[]`
   - `MAID-ART-R2 checks=78 failures=[]`
   - 日誌無 `SCRIPT ERROR`。
3. 原生渲染抽驗（非 headless，1280×720，`DAO_TEST_STORAGE_ROOT` 隔離輸出）
   - `Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/maid_art_r2_runner.gd --resolution 1280x720`
   - exit 0，`MAID-ART-R2 checks=78 failures=[]`。
   - 六張截圖：三位角色人物頁與初遇頁，存於 `docs/verification/artifacts/maid-art-r2-20261101/`。
   - 目視確認：糯美子劍尖、靴子與髮尾完整；丹霞長裙與鞋完整；青蘅不變；初遇標題／說話者／開場與角色對應；小傳、標籤、印章顯示正確。

## MAID-ART-R2 runner 覆蓋

- `MaidSystem.get_view()` 三位角色 `art_ready == true`。
- `ART` 路徑表與凍結預期一致，六個檔案 `ResourceLoader.exists`。
- 每位角色立繪 `texture.resource_path` 切換正確；名稱直排、印章文字正確。
- 小傳完整落在 `copy_box` 內；開場、小傳、角色小傳各欄位、標籤、選項、回覆跨角色兩兩不同。
- 初遇 CG 路徑、開場句、說話者場景正確；糯美子選項→回覆→重播流程。
- 立繪與 CG 均為 `STRETCH_KEEP_ASPECT_CENTERED`。
- 切換美術與對話後 `GameState` 快照不變；未招募的糯美子／丹霞仍顯示美術。
- 完整立繪檢視器標題顯示當前角色（丹霞）並可返回人物頁。

## 未驗證

- 未跑 L3 全量 runner、全尺寸矩陣、跨尺寸版面。
- 未做 Web 匯出、桌面瀏覽器或觸控實機驗收（依 2026-10-17 指令延期，非當前阻擋）。
- 未宣稱 MAID-CLOSE 完成；整體仙侍任務仍 IN_PROGRESS。
