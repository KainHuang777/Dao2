# M2-D 主介面質感評估

日期：2026-09-30。狀態：設計評估完成；實作與視覺驗收未開始。

## 範圍與證據

依使用者當次要求，唯讀比較 GodTower 天賦頁，提出 Dao2 的 Godot 原生介面改善方向。未替換 UI、修改規則或拷貝參考資產。

- 閱讀 README、ROADMAP、ai-handoff、development-status、技術架構、響應式規格及呈現層索引。
- GodTower 已讀當地 AGENTS.md；參考 src/ui/visualRefresh.css 的 talent-atlas-v2 樣式與 docs/mockups/ui-talent-meridian-v1.png。圖片為概念圖，並非此次取得的實際執行畫面。
- Dao2 共用 _style() 使用單色 StyleBoxFlat、1px 金色邊框與 4px 圓角；_button() 主要以背景變色區分操作狀態。UiTypography 共用字型已採 600/700 字重；字型已有灰階抗鋸齒，並非完全未啟用。
- Godot --version 成功，exit 0：4.7.2.stable.official.ed1daf0bf。git status 顯示大量既有變更，本輪保留。
- 預設 shell 與 Node REPL 因 helper_unknown_error 啟動失敗；透過正常 escalation 執行唯讀 PowerShell 成功。
- 未執行 import、Runner、Web export、即時瀏覽器或手機驗收；不宣稱平滑度、效能或新介面已通過。

## 推薦方向

GodTower 的質感來自材質、明暗、框體厚度、飾角與資訊層級，而不僅是像素精度。Dao2 建議採低顆粒青玉面板、柔和古金包邊、局部淡絹紙詳情頁。主 HUD 輕薄，完整卷冊框用於營造、天賦等大面板。裝飾集中在標題與角部，正文區保持乾淨。

Godot 實作保留 Control、Container、CanvasLayer 與正式文字節點；共用 Theme 管理材質與互動狀態。平面基底可用 StyleBoxFlat；有手繪包邊的框體使用 StyleBoxTexture / NinePatchRect 九宮格，避免拉伸角飾。材質、角飾、圖示、文字分層，裝飾不攔截輸入。新資產另記來源、授權、提示詞與切層。

以局部 CanvasItem shader 表現緩慢玉光，Tween 表現短促按下回彈及抽屜淡入；世界中的有限靈流或光點回應已提交事件。低特效模式提供靜態表現。收益不依賴演出完成。

## 平滑度處理

- 先檢查 CSS canvas 尺寸、DPR、drawing buffer、Godot 邏輯 viewport 及 UI 縮放，避免低解析畫布被放大；維持 canvas_items / expand 與 Adaptive。
- 圓角檢查 StyleBoxFlat 抗鋸齒及 corner_detail；線條使用 draw_line / draw_arc 的 antialiased。ui_icon.gd 部分線條已啟用，不能把全面開 AA 當作新修復。
- 目前 Compatibility 不支援 Godot 2D MSAA；不以改渲染器解決此任務。MSAA 也不處理字型、shader 內部或貼圖透明輪廓的全部鋸齒。
- 貼圖按實際顯示尺度選擇足夠解析度與 Linear filtering；有縮小情境時比較 mipmaps。圖像自身的像素階梯與高頻噪點需重製，不能僅靠模糊。
- 正文保留動態字型與 hinting；避免整組 Label 縮小。MSDF 只對大幅縮放標題試驗，不全量切換繁中小字。SVG 在 Godot 匯入時會光柵化，也需要足夠匯入解析度。

## 下一個可驗收切片

先製作左上修行面板、一張營造列、底部導航的 Godot 原生樣板，不擴展 M5-A。驗收：同一遊戲狀態下比較新舊材質；1280x720、844x390，以及不同 DPR 檢查文字、圓角、透明輪廓、按鈕命中與世界輸入隔離；主要控制項至少 44 CSS px。依現行規格提供直式旋轉提示。檢查低特效、效能與資產下載影響；實體手機仍需獨立證據。使用者視覺驗收前不將 UI 改版標 DONE。

## 官方技術依據

- https://docs.godotengine.org/en/stable/tutorials/2d/2d_antialiasing.html
- https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html
- https://docs.godotengine.org/en/stable/classes/class_styleboxflat.html
- https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html