# 可操作的視覺提案

開啟 `index.html`。不需安裝套件。若瀏覽器限制 file URL，從 `E:\WORK\Dao2` 執行：

```powershell
python -m http.server 4174 --bind 127.0.0.1
```

瀏覽 `http://127.0.0.1:4174/docs/visual-prototype/index.html`。

操作：引氣入體 → 天外一瞥 → 九界圖 → 點任意界域查看或標記 → 返回洞府。左側「九界經營」直接切後期示意。「重播開局」只重設本原型記憶中的展示值。

畫面使用內建 image_gen 產生的三联背景；UI、動效、點選與抽屜為 HTML/CSS/JS。繁中字體引用現有 `assets/fonts/NotoSerifTC-VF.ttf`。無第三方前端依賴，無遊戲存檔讀寫，不代表 Godot 渲染或完整經濟已完成。

詳見 [完整設計](../06-first-minute-visual-direction.md) 與 [美術提示詞](generation-prompt.md)。
