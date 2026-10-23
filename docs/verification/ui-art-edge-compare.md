2026-10-23 後續：正式 Godot 共用呈現接線已完成，最新狀態與驗收見[UI-ART-EDGE](ui-art-edge.md)。下方規範採納當時的待實作文字保留為歷史。

# UI-ART-EDGE-COMPARE：淡底圖像輪廓樣張

2026-10-23。使用者指定丹爐、百工器具、白狐三圖的「原版／細描邊投影／貼紙框」同底比較。**DONE：使用者已選B，並納入共用UI規範；正式Godot共用呈現接線仍待實作。** CONTENT-P1-TALENT 原美術接受與 DONE 狀態保持。

比較頁直接引用三張已接受透明PNG，使用正式天賦卡 `assets/ui/material/silk_row.svg` 的14px九宮格紙面。每個圖案在三欄具有相同尺寸、相同紙底、相同位置；外框額外向外擴張，不縮小原圖來配齊外框尺寸。主圖可切換192px／112px，右側小圖固定64px。

| 欄 | 呈現參數 |
| --- | --- |
| A 原版 | 原始RGBA，無描邊／投影 |
| B 細描邊投影 | 暖灰褐 `#5c5345`，alpha實體輪廓向外1.15px、58%強度；柔影 `#514b3d`／24%、模糊1.5px、向下1.8px。低透明度微光保持原柔邊 |
| C 貼紙框 | 米白 `#fff8e8` 出血3px，外加 `#706451` 1px／65%外緣；柔影20%、模糊1.7px、向下2px |

以上是瀏覽器CSS／SVG即時呈現效果，沒有重新生成／編輯／去背／裁切原始PNG。B、C的alpha門檻與參數均保留在比較頁中，可重跑；不是已驗證的正式Godot shader或效能方案。

- [192px放大比較，含64px小圖](artifacts/ui-art-edge-compare/comparison-192.jpg)
- [112px常用尺寸比較，含64px小圖](artifacts/ui-art-edge-compare/comparison-112.jpg)
- [比較頁原始檔](../visual-prototype/ui-art-edge-compare/index.html)
- 本機互動頁：[打開比較](http://127.0.0.1:4421/)。本輪為方便審閱，保留僅綁127.0.0.1的預覽服務；不需帳號，不存玩家資料。服務若已停止，於專案根執行 `python tools/ui_art_edge_compare_server.py --port 4421`。

## 驗證與界線

真實IAB瀏覽器已檢查九格、18個圖像實例全部載入，112px切換後九張主圖實際皆為112×112、固定小圖64×64；兩尺寸各保存完整頁面截圖。初稿SVG背景按比例留白，已改為九宮格拉伸，最終整幅圖都位於同一淡紙底；沒有把初稿當最後比較圖。

`browser-check.json`保留DOM觀測；`source-audit.json`保留三圖／紙面／比較來源hash，原圖與已接受manifest一致，既有正式來源與凍結Web hash另核。截圖原bytes為JPEG，使用.jpg副檔名。使用PowerShell／Python建立本機樣張與server，瀏覽器操作切換尺寸並截圖；無Godot執行、Runner重跑、Web遊戲匯出或新圖片生成。

本輪新增比較HTML、只提供樣張及assets的本機server、兩張截圖與稽核；更新README、ROADMAP、handoff、development-status與英文updata checkpoint。未改正式GDScript、PNG、規則、schema、玩家進度、已接受美術metadata或凍結包，未commit/push。

觀察：B改善白狐與淡氣帶的分離，同時較接近既有手繪；C輪廓最明確，但64px外框較搶眼、整體更像貼紙。這只是建議，尚未替使用者選定。下一步收A／B／C回饋；選定後在新對話承接共用呈現接線，不在本輪套用全部圖片或開工P丹藥。

## 2026-10-23 B選定與共用規則採納

使用者明確回覆「選擇 B 並且帶入共用規則」。B已核定為淡紙底透明手繪UI插圖的共用方向，精確參數、適用範圍、微光／細毛例外、顯示像素與共用元件責任已寫入[docs19](../19-ui-ux-guidelines.md)，docs07加入同一規則入口；C不列共用預設。比較頁標示B已選定，[selection.json](artifacts/ui-art-edge-compare/selection.json)保留選定語句、參數、前後HTML hash。

本輪更新共用規範、比較頁標示、狀態與英文交接；沒有修改正式GDScript或PNG，沒有執行Godot、Runner或重新匯出遊戲。樣張截圖與瀏覽器證據沿用前輪，設計採納與正式接線分開記錄。既有插圖與正式來源hash、UTF-8、文件連結及diff-check另核。下一個實作階段在New Chat接共享插圖輪廓元件，沿已核定B執行，不重新要求選A／B／C；P丹藥仍未開工。

本輪規範收結檢查：三張原圖、22份既有正式來源與凍結Web hash保持；九份修改文字UTF-8、B選定metadata／比較頁hash及新連結目標檢查通過，文件diff-check exit0。[紀錄](artifacts/ui-art-edge-compare/selection-validation.json)。
