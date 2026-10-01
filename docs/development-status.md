# 開發狀態與交接紀錄

更新：2026-10-02；重構基線：`d77bca3`。日常只讀本頁與當次任務涉及的文件。

## 目前任務與下一步

- **M2-D-UI7 常態介面材質與配色統一**：讀取專案後修正提案並實作：保留左側資源／橫式／混搭字型／轻微舊紙邊，普通操作紙色墨字、選中霧面青玉、晉階／突破朱砂、舊玉石功能面板墨色化，訊息收斂。34/34 Runner、呈現回歸、最終響應式 Runner、21 張 native PNG 與 Web 匯出 exit 0；IAB 1280×720／844×390 實際滑鼠及 360×640 旋轉提示已驗，DPR 約 1。IN_PROGRESS，使用者美術放行／高 DPR／實體手機待驗。檔案、初次執行政策與 sandbox fixture 失敗、指令與證據見 [本輪驗收](verification/ui-quiet-materials.md)。預覽 origin 4182 與玩家 4178 分離，未改存檔或規則。下一步先收本輪視覺回饋，新大型任務請在 New Chat 繼續。

- **ENV-TERMINAL 終端初始化修復（2026-10-02）**：DONE，PowerShell 7.6.5 並非過舊；本機日誌定位 `.git` 根目錄為 CodexSandboxOffline 擁有，helper 無法更新保護 ACL。備份 SDDL，UAC 執行單一目錄 owner 修復，DACL 保持不變；一般沙箱文件讀取與 Godot 4.7.2 版本檢查 exit 0，helper `errors=[]`。初次一般權限修復 exit 5 已記錄；細節與檔案見 [環境驗證](verification/terminal-initialization-2026-10-02.md)。Windows 升級因果未證實，瀏覽器 runtime 尚未重測。
- **常態 UI 配色提案（待開工）**：使用者要求先保存「宣紙＋墨色＋少量青玉／朱砂」，橫式／響應式、字型混搭保留。已保存 [設計結論](ui-material-direction-2026-10-02.md)，尚未修改 UI 或宣稱驗收；新對話先對照現有材質與 Roadmap，再確定試版範圍。

- **M2-B-FX2 升境光環／雷電加強**：舊版沒有 ERA 視覺分級；本輪加強築基基礎金環、光柱、不規則分岔雷電，新增四檔 2–3／4–6／7–9／10–12 視覺預算。正式演出／重溫傳真實 ERA，內部重播保留目標；低特效維持柔和無雷電。34/34 Runner、呈現回歸、八張 native 截圖與 Web 匯出 exit 0；IN_PROGRESS，視覺／真實 Web／手機效能待驗。檔案、命令、視口 fixture 修正及下一步見 [本轮補記](verification/island-breakthrough.md)。

- **M2-D-TEXT1 過場文字樣板**：參考使用者附件與 Text APNG Maker，依作者禁止未授權複製工具主要部分之條款改作原創原生元件。設定新增試播；黑底粗明體、展字／淡入、細線副標、跳過與低動態，試播不改遊戲狀態。34/34 Runner、呈現層回歸、四張 native PNG、Web 匯出 exit 0；IN_PROGRESS，視覺／真實 Web／手機待驗。修改檔案、命令、首次測試修正、退出警告、API 與下一步見 [驗收紀錄](verification/ui-text-transition.md)。先收本切片回饋；新大型事件整合請在 New Chat 繼續。

- **M2-D-UI6-R1 黑體資訊＋粗明體题字**：使用者接受混搭；七個主面板標題與洞府題字改用明體 800，資訊／操作黑體 400／600。發現先前字串字重未實際生效，已改 OpenType tag 並驗證 TextServer 真實座標；20 張 native 圖重產生，兩份授權納入匯出。IN_PROGRESS，實際粗字視覺／Web／手機待驗。修改、最終命令及舊證據更正見 [UI6 追加紀錄](verification/ui-source-han-sans.md)。

- **M2-D-UI6 思源黑體試套**：依使用者指定官方免費商用字型，全遊戲共用角色改用 Source Han Sans TW VF 2.005R（正文 400／強調 600），保留授權與舊字型來源。掃描來源 1501 種漢字全覆蓋，五個未內建裝飾符號改為文字／星號；度量與非容量取捨已記錄。IN_PROGRESS，使用者／Web／手機視覺待驗；修改、命令、版型證據及下一步見 [評估紀錄](verification/ui-source-han-sans.md)。

- **M2-D-UI5 引導完成與系統訊息**：依本輪要求，兩處引導按鈕完成後隱藏、有效目標恢復再顯示；訊息預設開啟、17 字級、較大且有視口上限的閱讀區。33/33 Runner、呈現層回歸、native 桌面／短橫向與 Web 匯出通過；IN_PROGRESS，使用者與真實 Web／手機驗收待補。修改檔案、命令、初次型別編譯修正、短橫向管理自動收起規則與下一步見 [本輪紀錄](verification/ui-guidance-messages.md)。

- **M2-D-UI4-R1 舊紙邊緣**：依使用者回饋，絹紙新增輕微不規則輪廓、赭黃邊緣、破角與纖維磨損，保留元件尺寸及內容內縮。資源三態／響應式 Runner PASS、原生桌面／短橫向檢查及 Web 匯出 exit 0；IN_PROGRESS，磨損強度與真實 Web／手機驗收待補。來源僅 `assets/ui/material/silk_panel.svg`，資產 README 與 [UI4 追加紀錄](verification/ui-paper-hud.md) 已同步；下一步先收視覺回饋。

- **M2-D-UI4 絹紙＋青玉 HUD 樣板**：依當次要求先局部試做修行面板與資源區，紙底／墨字承載資訊、玉石承載操作，滿倉與三態提示保留。IN_PROGRESS，使用者視覺與 Web／手機驗證待補；修改檔案、回歸結果、首次色碼斷言失敗及下一步見 [樣板紀錄](verification/ui-paper-hud.md)。未延伸其他功能面板。

- **M2-D-UI3 空島文字風格**：依使用者追加要求，建築／靈木銘牌、洞府題字與採集浮字已延伸青玉古金材質，文字不受飛劍光尾覆蓋。30/30 Runner、呈現層回歸、四張 native 截圖與 Web 匯出完成；IN_PROGRESS，使用者視覺與 Web／手机驗證待補。修改檔案、命令結果、警告與下一步見 [本輪紀錄](verification/ui-world-typography.md)。

- **M2-D-UI2 核心介面材質與狀態效果**：使用者已放行 UI1 樣板視覺，授權全面延伸核心介面。UI2 實作、29 Runner、呈現層回歸、native 圖像與 Web 匯出完成；IN_PROGRESS，Web／實體手機與本輪視覺驗收待補。詳見 [驗收紀錄](verification/ui-core-materials.md)。依當次要求先完成此切片與回饋，再回到 M5-A。

- **M3-B 天時系統（Chrono / Weather System）**：已交付；DONE（十二時辰陰陽節律、五行大運天候、產率修煉倍率疊加、存檔持久化與 HUD 視覺更新；全量 27 項 Runner PASS）。
- 保持玩法、存檔格式、根場景公共屬性與函式／訊號接線相容。
- **M5-A 受控生成與世界描述（九界道法深化）**：已交付；DONE（道教性命雙修宇宙觀、七維法則矩陣、心印嚮往共鳴、純函數確定性生成器 `WorldGenerator`、`WorldDescriptor` 與存檔快照；全量 30 項 Runner PASS、Web 匯出 exit 0）。見 [九界與生成規範](11-nine-realms-law-and-world-generation-spec.md)。
- **M3-B 機緣奇遇系統（Fortune & Encounter System）**：已交付；DONE（境界每小時頻率門檻、心印嚮往 2.0x 偏向、天時天候 1.5x 加權、8 種道家經典奇遇、原子性決策獎懲、存檔持久化與輪迴重置、FortuneModal 絹紙青玉介面；全量 32 項 Runner PASS、Web 匯出 exit 0）。
- **M5-B 逐界特色內容擴展（九界戰略決策與地貌事件）**：已交付；DONE（14 項九界專屬天道戰略決策 RealmDecisionSystem、九界地貌詞條池深化至 6~8 項與互斥校驗、26 種界域專屬深度道家奇遇與當前身處界域 3.0x 加權、Session 白名單命令 execute_realm_decision 與存檔相容；全量 33 項 Runner PASS、Web 匯出 exit 0）。
- 下一步：**M3-B 靈獸培育系統** 或 **M3-B 成就系統**。
- M3-B 天時、機緣、靈獸、成就按 Roadmap 相依交錯推進。

## 精簡任務板

| 任務 | 狀態與證據邊界 | 入口 |
| --- | --- | --- |
| M0-A | 桌面已驗；指定實體手機手勢／效能待補 | [驗收](verification/m0-a.md) |
| M0-B/C | DONE；來源 fixture、Amount/RNG 契約 | [M0-B](verification/m0-b.md)、[M0-C](verification/m0-c.md) |
| M1-A/B | DONE；正式核心、時間、修煉與壽元；後續正流程修正已有測試 | [正流程](verification/core-positive-flow.md) |
| M1-C/D/E | CLI 契約已通過；IndexedDB、跨程序、quota、多分頁與真實舊檔 corpus 仍依各驗收表補證 | [保存](verification/m1-c.md)、[離線](verification/m1-d.md)、[相容矩陣](legacy-compatibility.md) |
| M2-A/B/C | 已交付；新檔首升境、演出、九界鉤子均有 Runner | [M2-A](verification/m2-a.md)、[M2-B](verification/m2-b.md)、[M2-C](verification/m2-c.md) |
| M2-D | 桌面 Web 於 2026-09-28 放行；窄版 CSS viewport 列 M2-D-R1 修復，實體手機另待驗 | [M2-D](verification/m2-d.md)、[演出](verification/island-breakthrough.md) |
| M3-A | 已交付雙軌輪迴門檻、壽盡橫幅、天賦與轉生演出 | [M3-A](verification/m3-a.md) |
| M3-B | 丹藥／BUFF／宗門／天時／機緣奇遇已交付（DONE）；靈獸、成就後續推進 | [M3-B](verification/m3-b.md) |
| M4-A | 領域／存檔／面板程式已交付；`switch_realm`／據點命令未進正式 Session 白名單，M4-A-R1 修復 | [M4-A](verification/m4-a.md)、[本輪發現](verification/ref-a.md) |
| REF-A | DONE（重構／CLI／Web smoke） | [本輪驗收](verification/ref-a.md)、[呈現層索引](abode-presentation-map.md) |
| UI-ICON-R1 | DONE；移除宗門／壽元／輪迴面板依賴 emoji 字型的圖示，換成 Godot 繪製或 SVG 圖示 | [本輪記錄](verification/ui-icons.md) |
| M2-D-R2/R3 | IN_PROGRESS；v6 背景完成重構，前景洞府島縮小並下移；CLI／匯出通過，遊戲內畫面複查待補 | [本輪記錄](verification/m2d-background-framing.md) |
| M2-D-A1 | IN_PROGRESS；第一稿旋律不協調，已依 DAO1 唯讀參考重寫；第二稿獨奏及五版 60 秒試聽待人耳驗收 | [第二稿](audio/dao2-main-theme-v2.md)、[第一稿](audio/dao2-main-theme.md) |
| M4-A-R1 | DONE；Session 白名單與宗門／跨界／BUFF 成功路徑全部通過 | [REF-A](verification/ref-a.md)、[Roadmap](../ROADMAP.md) |
| M2-D-R1 | DONE；確立橫式排版唯一核心，直屏提示旋轉；修復手機橫向（844×390 等）可讀性與 44px 觸控門檻 | [REF-A](verification/ref-a.md)、[UI 規格](07-responsive-ui-web-spec.md) |
| M4-B | DONE；九界法則核心數值、修煉速度/壽元/靈氣池空間尺度契約、WorldAddress 全量交付 | [Roadmap](../ROADMAP.md) |
| M5-A | DONE；九界道法深化、七維契約、心印嚮往、純函數受控生成與存檔快照 | [九界規格](11-nine-realms-law-and-world-generation-spec.md) |
| M5-B | DONE；九界戰略決策、深化地貌詞條池與界域深度奇遇擴展 | [Roadmap](../ROADMAP.md) |

## 本輪交付與驗證

- `src/abode/living_abode.gd`：2,285 → 1,097 行；保留世界、時間／保存協調、突破運鏡及既有呼叫入口。
- `src/presentation/abode_hud_controller.gd`：HUD 組裝、版型、數值／修煉／BUFF、引導與日誌。
- `src/presentation/abode_modal_manager.gd`：彈窗組裝、位置與事件分發；維持原堆疊與開關方式。
- `tests/abode_presentation_parity_runner.gd`：追加場景層回歸；同一組斷言對原版／重構版皆通過。
- 文件：歷史歸檔、精簡狀態、呈現層索引、交接命令、Roadmap REF-A 與驗收紀錄。
- Godot `--version`：`4.7.2.stable.official.ed1daf0bf`。
- 重構前後 `powershell -File .\tools\run_all_runners.ps1`：各 25/25 PASS、exit 0。
- `--headless --path . --import`：exit 0；Web `--export-release Web .\build\web\index.html`：exit 0。
- 新增呈現層回歸 Runner：原版與重構版皆 exit 0；測試只使用隔離資料。
- Runner 仍有原版就存在的字型／CanvasItem 退出洩漏診斷，以及損壞輸入測試的預期錯誤；未新增腳本編譯錯誤。
- Edge 隔離 profile、127.0.0.1:4176：WebGL 2.0 載入、煉丹／存檔開關、更多選單及四種 CSS viewport 切換，console/page/HTTP errors 為 0。
- 窄版視覺發現：360 CSS px 下 HUD 字級／按鈕過小，未通過 docs/07 可讀性／44px 觸控門檻；沿用既有 stretch／版型計算，本次不改行為。
- 完整命令、證據與未通過項見 [REF-A](verification/ref-a.md)。

2026-09-28 DOC-A 文件現況同步：README 收斂為現況／入口／驗證／文件地圖；Roadmap 移除早期「M0-A 建議下一項」誤導，新增 M4-A-R1 與 M2-D-R1 並更新 M4-B 相依；M3-B／M4-A 驗收頁重新界定為模組交付、Session 整合待驗；環境探針與核心正流程中的日期狀態標為歷史。M0–M4 原狀態段落保留於 archive，不覆寫測試／交付歷史。README 46 行、development-status 62 行；文件 UTF-8、現行入口相對連結檢查通過，本輪未執行遊戲測試。

2026-09-28 UI-ICON-R1：新增 `src/presentation/ui_icon.gd`，以 Godot 原生線段／多邊形繪製沙漏與卷軸標題圖示；領獎、刷新、輪迴按鈕使用 SVG 貼圖。宗門、壽元、輪迴、跨界及靈光文字移除 emoji／箭頭字型依賴。Godot 4.7.2 `--headless --editor --path . --import --quit` 通過；`tests/m3b_sect_ui_runner.gd` 通過，檢查標題圖示節點與宗門 UI 無 emoji；`tools/run_all_runners.ps1` 25/25 PASS、exit 0；Web Release 匯出通過。負面資料測試會輸出預期 JSON/Base64 錯誤診斷，既有場景仍有 Font RID 退出診斷；本次未新增腳本錯誤。瀏覽器畫面人工檢查待做。

2026-09-28 M2-D-R2：首次 shader UV 平移造成左側越界像素被 clamp 成橫條，依使用者截圖撤除。改用非破壞式 v6 背景重構，把淚佛移到畫面約 39% 寬處並自然補繪左側雲海；`living_abode.gd` 改載 v6，v5 保留並從 Release 排除。直式 viewport 焦點同步調至 0.39，寬版保持完整原圖取樣 0.5；Shader 瀑布遮罩改對齊新眼下水路，新增 UV 範圍斷言。Godot 4.7.2 import、M2-D Runner、全量 25/25 Runner、Web Release export 及 `git diff --check` 均通過。遊戲瀏覽器視覺複查受 `helper_unknown_error: setup refresh had errors` 阻擋。

2026-09-28 M2-D-R3：依使用者截圖將洞府島前景（地形、建築、靈木、飛劍、法陣與洞府標記）納入同一構圖節點，整體縮放至 0.92 並下移 18 世界單位；HUD、背景及遊戲規則不變。建築／樹木原有 `to_local()` 命中區隨父節點變換，點選 Runner 改用節點全域座標。M2-D Runner 通過；全量 25 Runner 通過、exit 0；Godot 4.7.2 Web Release 匯出成功。畫面複查因 CUA kernel 啟動失敗尚待補；本項維持 IN_PROGRESS，不能以 CLI 結果代替視覺驗收。

2026-09-28 M2-D-A1：依使用者提供的《星際效應》配樂解析影片，採「親近旋律隨場景擴大」敘事方法創作 Dao2 原創四小節主旋律。64 BPM、4/4、16 小節共 60 秒；洞府、靜修、突破、輪迴、宇宙五版均有 Ogg 試聽與分軌 MIDI。`tools/compose_theme_prototypes.py` 可重建，`docs/audio/dao2-main-theme.md` 記錄音符、音色、銜接與來源。五版均經 ffprobe 時長、ffmpeg 解碼與 MIDI 軌道結構檢查；未進遊戲，也尚待實際聽感與跨版切換驗收，因此維持 IN_PROGRESS。下一個音訊步驟是人工試聽與正式音色製作；功能主線仍先做 M4-A-R1。

2026-09-28 M2-D-A1 第二稿：使用者指出第一稿主旋律不協調，底噪、低音與整體質感可保留。DAO1 `Whispers_of_the_Jade_Mountain.mp3` 唯讀分析顯示約 30.77 秒，主音級候選偏 C、E♭、F、G、B♭、A♭，較長的高音分句常見。重寫為 C 小調、四小節 12 音的較疏旋律，先輸出鋼琴感獨奏 `v2/00_theme_lead.ogg`，再輸出洞府等五種 60 秒變體及分軌 MIDI；第一稿音檔保留供比較。技術檢查與人耳聽感各自記錄，音樂方向尚待使用者試聽，狀態維持 IN_PROGRESS。來源與音符詳見 [第二稿](audio/dao2-main-theme-v2.md)。

2026-09-29 UI-SETTINGS-R1：將「更多功能」與「系統設定」分開。右上角新增 44×44px 系統設定齒輪按鈕（`settings_menu`，含 `UiIcon.Kind.GEAR` 向量圖示），收納背景音樂、低特效、存檔管理、操作說明與調試工具；「更多功能」（`more_menu`）收斂為純修行玩法（煉丹、宗門、靈界、輪迴、星圖、突破）。引入原創 60 秒洞府主題背景音樂（`assets/audio/bgm/abode_theme.ogg`）與專屬 `AudioStreamPlayer`，支援動態開關與瀏覽器手勢 WebAudio 自動解鎖。`m2d_responsive_ui_runner`、`debug_features_runner` 與全量 25 個 Runner 全部通過，Web Release 匯出完成。

## 必須保留的限制

- `CommandProcessor` 已有宗門、跨界／據點與 `apply_buff` 分支，但 `GameSession.KNOWN_COMMAND_TYPES` 尚未放行它們；因此部分元件／Domain 測試通過仍不足以證明正式場景可玩。
- 本輪在原版場景用宗門／靈界訊號重現 `UNKNOWN_COMMAND`；純重構保留現況，另案修復並補正式 Session 成功路徑。
- 面板／ViewModel 會沿用既有 `ensure_*` 初始化宗門／靈界資料；REF-A 未改此狀態語意。
- 目前一般彈窗依原行為可同時開啟；突破演出 HUD 遮罩／鏡頭鎖定仍由根場景維護。
- 真實手機手勢／GPU／效能與 IndexedDB 落盤不能由 CLI 或桌面瀏覽器取代。

## 歷史與按需閱讀

- [M0–M2 舊記錄與舊交接](archive/development-status-m0-m2.md)：保留原段落，不作當前任務入口。
- [M3–M4 詳細交付歷史](archive/development-status-m3-m4.md)：丹藥、BUFF、宗門、輪迴與靈界的歷史說明。
- [呈現層索引](abode-presentation-map.md)：依修改類型定位檔案，不再一律讀完整主場景。
- [AI 交接](ai-handoff.md)：環境、完整 Runner 與 Web 匯出命令。

2026-09-30 M2-D 介面質感設計評估：唯讀比較 GodTower 天賦頁 CSS 與經脈概念圖，確認目前共用 HUD 為單色 StyleBoxFlat／細金框。建議青玉古金主 HUD、局部絹紙詳情、九宮格材質及有限原生動態；Compatibility 不支援 2D MSAA，平滑度需分別檢查 DPR／canvas、幾何、貼圖與字型。本輪只新增評估文件並更新交接，Godot --version exit 0；未修改正式 UI，未執行 Runner／匯出／瀏覽器驗收。下一 UI 切片為修行面板、單張營造列、底部導航原生樣板，待實作與視覺驗收，詳見 [設計評估](verification/ui-material-review.md)。

2026-09-30 M2-D-UI1（IN_PROGRESS）：已接入修行面板青玉古金九宮格、茅屋絹紙列與底部玉牌導航。新增 UiMaterial、三張原創 SVG 與來源說明、隔離 native 渲染工具；修正 MenuButton flat 導致不繪材質。Godot import、響應式 Runner、全量 28/28 Runner、呈現層回歸、Web export 均 exit 0；既有退出 RID／ObjectDB 警告保留。桌面 1280×720 與視窗 844×390（邏輯 779×360）native 截圖已檢查。CUA kernel 啟動失敗，Web／DPR／手機與使用者視覺驗收待補；4178 本機 HTTP 回覆 200，面板開啟 queued。下一步先驗收本切片再調整，不展開下一大型任務。詳見 [樣板驗收](verification/ui-material-prototype.md)。

2026-10-01 M2-D-UI2：全核心介面共用青玉古金 Theme，所有营造列採淡絹紙；需求條改為內縮原生圓角 ProgressBar，移除螢光邊線，金色表示可建／可升，赭色滿條仍保留前置不足停用。新增簡潔 jade_card.svg 避免密集卡片角飾擠字；修正煉丹摘要換行與宗門標題高度變化後的內容重排。修改 UiMaterial、UiTypography、HUD／living_abode、building_catalog、煉丹／宗門／輪迴／跨界／九界／BUFF 卡片，新增 ui_material_states_runner 並納入固定入口。Godot import、29/29 Runner、呈現層回歸、native 預覽與 Web export 均 exit 0；既有退出 RID／ObjectDB 警告保留。16 張 native 預覽與代表案例已檢查，營造測試 fixture 不改正式資料；4178 HTTP 200、頁面開啟 queued。Web DPR／真實輸入與實體手機仍待補，維持 IN_PROGRESS。下一步為新核心面板的使用者視覺回饋與裝置驗證，詳見 [本輪紀錄](verification/ui-core-materials.md)。
