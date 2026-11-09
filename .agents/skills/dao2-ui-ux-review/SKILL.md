---
name: dao2-ui-ux-review
description: 審查 Dao2 的介面與互動體驗設計，依據 docs/19-ui-ux-guidelines.md 與響應式規範，檢查點擊穿透、操作命中區、容器佈局、古典主題視覺一致性及導航返回動線。
---

# Dao2 UI / UX 體驗與介面審查

本技能專用於 Dao2 所有 HUD、面板、彈窗、抽屜與引導元件的設計與代碼審查。在建立或修改任何介面元件前後調用，確保遵循 `docs/19-ui-ux-guidelines.md`、`docs/07-responsive-ui-web-spec.md` 與 KISS 原則。

## 審查核心清單

### 1. 互動防護與事件穿透（Ghost Blocker Defense）
- **隱藏元件重置**：所有彈出式、浮動式或動態淡出之引導/氣泡/對話框（如 `MaidGuidanceDock`、Tooltip），在隱藏或關閉時，必須確保其容器 `mouse_filter` 設為 `MOUSE_FILTER_IGNORE`，並將位置或邊界移出互動區域（例如重置為 `(-9999, -9999)` / `(0, 0)`），嚴禁殘留隱形矩形攔截下層按鈕點擊。
- **全屏遮罩與模態**：模態對話框需有明確的黑色半透明遮罩並正確吞噬事件；非模態懸浮視窗或底欄（Dock）嚴禁遮擋背後主要操作區。

### 2. 操作人體工學與尺寸規範（Ergonomics & Touch Target）
- **最小命中面積**：所有可點擊互動元素（Button、TextureButton、SpinBox、CheckBox）之有效點擊區域至少維持 **44×44 像素**（`custom_minimum_size = Vector2(44, 44)`）。
- **控件變形防範**：輸入框、SpinBox、數值調節鈕必須配合合適的尺寸旗標（如 `SIZE_SHRINK_CENTER`），嚴禁因父容器 `SIZE_EXPAND_FILL` 被垂直或水平拉伸成不自然的巨型方塊（例如高度達到 80px+）。
- **文字包裝與排版**：長說明文本與標題解耦，標題優先單行展示（`autowrap_mode = TextServer.AUTOWRAP_OFF`），說明欄位預留足夠寬度並開啟適切的換行與截斷保護，防止文字與輸入框重疊或撐破邊框。

### 3. 古典修仙視覺規範（Theme & Aesthetic Consistency）
- **紙墨古典風格**：凡涉及輸入框（LineEdit）、面板背景與彈窗，必須遵守統一的修仙古典配色：
  - 底色：宣紙淡雅黃/米白（`#f5f0e4` 或同等質感）。
  - 文字：水墨濃黑（`#2c2416`）。
  - 邊框：青銅古金（`#bfa15f`）或冷翡翠青（`#4a7060`）。
- **禁止外觀**：嚴禁直接使用 Godot 預設的黑色生硬矩形框或未套用風格的現代預設主題。

### 4. 導航、狀態與返回動線（Navigation & Wayfinding）
- **出口明確**：任何次級面板或全屏彈窗必須具備明確且一致的「關閉」或「返回」按鈕，位置需符合通則（右上角關閉或左上角返回）。
- **當前位置感知**：導航與分頁標籤必須清晰高亮當前所在分頁，不可讓玩家產生「我在哪裡、怎麼回去」的視窗迷航。
- **操作反饋**：點擊、切換、製造、派遣等動作必須伴隨明確的即時回饋（音效、短暫高亮或狀態切換），不讓玩家反覆無效點擊。

## 輸出結構
審查完畢後輸出：
1. **符合項清單**（確認無違規點）。
2. **違規/風險項**（指出具體檔案、行號與潛在操作摩擦）。
3. **最小修正建議**（符合 KISS 原則的最小代碼調整）。

流程參考 [Claude Code Game Studios 的 ux-review 與 ux-designer](https://github.com/Donchitos/Claude-Code-Game-Studios)。

