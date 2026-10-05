# M2-D-FX3：Godot 原生粒子、Shader 與泛光

日期：2026-10-03。IN_PROGRESS：實作交付；使用者視覺放行與實機／效能驗收待補。

## 需求、依賴與本輪範圍

使用者指出飛劍、小光環及渡劫雷電／光環過弱，要求參考 Godot 特效／Shader 庫、引入粒子與泛光，並考慮文字霓虹效果。相依既有 FX2／TEXT1、正式突破先提交再播放、低特效與橫式響應式已具備。本輪先改善上述四類；未建立未驗收聚靈壇地標或靈界據點場景。

| 效果 | 本輪實作 |
| --- | --- |
| 飛劍／流光／邊緣光 | 9 個 Sprite2D 與原創發光 Shader；每劍一個 16 粒子的 CPUParticles2D 拖尾，沿既有 Curve2D 路線移動；停產路線停止發射並降亮度 |
| 靈氣／迷你光環 | 64 粒子的上升靈氣，極座標 Shader 產生青玉光環與沿圈流光；純裝飾，不代表聚靈壇已建成 |
| 渡劫雷電／光環／Noise | 最多六條原創噪聲雷電 Shader、上下法陣 Shader、96 粒子的升境靈火花；保留既有前後遮擋、金色刻度與分境界層級 |
| 世界泛光 | WorldEnvironment＋Environment 的原生 Glow，Canvas Max Layer=0；Compatibility LDR，threshold=0.96、intensity=0.65、bloom=0.03，HUD 在 layer 10 不參與全世界泛光 |
| 文字霓虹泛光 | 演出標題／副標的透明 SubViewport 只畫字形，25 次局部 Gaussian 取樣加色光暈；保留原生 Label、字型、展字、換行和主要字芯，普通 HUD 數值／成本不套霓虹 |
| 低特效 | 停止且隱藏飛劍拖尾／靈氣／突破粒子，關閉雷電 Shader 與世界 Glow，停止題字光暈 viewport 更新；保留靜態弱光圈與少量靜態光點 |

常態 engine 粒子上限 208，突破額外 96，合計上限 304；CPUParticles2D fixed_fps=30。節點在 ready 時建立，重播重用，不逐幀新增；粒子 RNG 不使用 domain／世界 RNG，完成動畫不發放資源。這是節點／取樣預算，不是已量測手機 FPS 的宣告。

設定新增「引擎特效樣板（試播）」：新檔也能觀賞 ERA8 視覺樣板，明示試播，不提升境界或發放收益。跳過、重播、返回使用既有相機／HUD 鎖定；正式突破仍從 GameSession 的成功命令開始，試播不能替代解鎖。題字另由既有「過場文字樣板（試播）」查看。

## 查核的官方能力與候選庫

Godot 最新官方資料列出 Compatibility 支援 Glow；其簡化實作不提供 Forward+ 的全部控制項。HDR 2D 是 Forward+／Mobile 路徑；目前 Web 使用 Compatibility 的 LDR Canvas Glow 與局部加色 Shader。不能沿用早期「Compatibility 完全無 Glow」的資訊，也不能把目前效果說成 HDR Bloom。[渲染器能力](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)、[Glow／2D Canvas](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html#glow)。本輪以本機 `4.7.2.stable.official.ed1daf0bf` 及其 Web 匯出確認實際行為。

| 候選 | 本輪判斷 |
| --- | --- |
| [GODOT-VFX-LIBRARY](https://github.com/haowg/GODOT-VFX-LIBRARY) | MIT；2D 動作型粒子、雷電、Portal、水面／扭曲等可作後續候選。先逐個確認 Compatibility、成本與畫風，不引入整套戰鬥 manager |
| [GDQuest Godot 4 VFX Assets](https://github.com/gdquest-demos/godot-4-VFX-assets) | 程式／場景／Shader 為 MIT，圖片／模型是 CC-BY-NC-SA 4.0；適合研究組合方法，美術不能跟程式授權混用 |
| [Godot Shaders](https://godotshaders.com/about-godot-shaders/)＋[Library Plugin](https://github.com/Kelpekk/Godot-Shader-Library) | Plugin 為 MIT，各 Shader 保留其個別授權；以原作者頁面及實際碼為準，不能以插件授權概括所有 Shader |
| [官方 Asset Library](https://godotengine.org/asset-library/asset?category=3) | 是發現與分發入口，不表示其中所有社群資產都由引擎官方維護；逐項核對版本、授權與渲染器 |
| [CPUParticles2D](https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html) | 使用原生 CPU 粒子作低數量、Web 可驗證的初稿；Shader 負責圖像計算。若量測顯示 CPU 瓶頸，再比較 GPUParticles2D，不預先承諾 GPU 粒子必然更快 |

本輪採原創可控的少量 Shader 與原生粒子；候選庫只作技術評估，沒有安裝插件或搬入第三方程式／圖片。來源／用途／圖層記於 [assets/vfx](../../assets/vfx/README.md)。

## 其他列舉效果的安排

| 效果 | 建議用處／狀態 |
| --- | --- |
| 水面 | 後續仙池場景用局部 UV 扭曲與反光；本輪維持既有瀑布 Shader，不宣稱已新增水面 |
| 雲霧／背景扭曲 | 後續用局部透明 Noise 層與受限位移，先驗場景遮擋及填充率；不把完整背景永久模糊 |
| 溶解／傳送／Portal | 靈界獨立場景完成後用於切景過渡，動畫結束不提交切界命令；本輪未製作 |
| 火焰 | 可用於煉丹／燈火，先有正式物件再加有界粒子；本輪火花不是完成火焰資產 |
| 卡片閃光／Outline | 升級成功或選取時短暫使用，避免所有卡片持續閃爍；本輪僅飛劍發光邊緣已交付 |

## 修改檔案

- `assets/vfx/`：四個 Shader、共用光點 `.tres` 與來源 README，保留引擎產生的 `.uid`。
- `src/presentation/native_vfx.gd`、`title_glow.gd`：有界工廠、原生粒子與局部題字泛光。
- `src/abode/abode_flows.gd`、`living_abode.gd`：劍圖／拖尾／靈氣及世界 Glow；停產與低特效接線。
- `src/presentation/island_breakthrough_fx.gd`、`breakthrough_sequence.gd`、`text_transition.gd`：法陣／雷電／粒子與題字；試播明示與重播。
- `src/presentation/abode_hud_controller.gd`、`abode_modal_manager.gd`：設定試播入口。
- `tests/island_breakthrough_runner.gd`：原生特效啟用／低特效關閉、固定節點、試播零收益與鎖定還原。
- `tools/native_vfx_preview.gd`、`breakthrough_fx_preview.gd`：隔離存檔及 FX3 專用截圖，不覆寫 FX2 歷史證據。
- `tools/run_all_runners.ps1`：加入可選 `EnginePath`，預設路徑與 36 項清單不變，方便沒有引擎的 worktree 重用同版執行檔。
- README／Roadmap／handoff／development-status／本頁及 updata checkpoint。

## 命令與驗證

使用本工作樹 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`，從既有環境複製 console＋主執行檔及 Web 模板，未升版／下載／重裝。外部原檔未修改，副本保持 Git 忽略。所有存檔 Runner 用其專用隔離 `user://`，預覽另用 `native_vfx_preview`／`native_vfx_home_preview`。

```powershell
& $daoEngine --version
& $daoEngine --headless --path . --editor --import --quit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_all_runners.ps1
& $daoEngine --path . --script res://tools/breakthrough_fx_preview.gd -- --fx3
& $daoEngine --path . --script res://tools/native_vfx_preview.gd
& $daoEngine --headless --path . --export-release Web .\build\web\index.html
```

- 版本 4.7.2 exit 0；最終 import exit 0；36/36 Runner exit 0，原生兩支預覽及 Web export exit 0。最後追加保存提示隔離後，突破 Runner 再驗 exit 0，Web 再匯出 exit 0；沒有宣稱此小修後重新執行全部 36 項。原生共 14 PNG，`1280×720`／`844×390`；小視窗的 Godot 邏輯尺寸為 `(779, 360)`，物理截圖為 `844×390`，不把物理像素當邏輯 viewport。
- 50 次切換曾失敗：FX3 1706.21 KB，原碼隔離對照 1187.91 KB。去除文字樣式對照 1187.66 KB，定位額外字型描邊快取；重用原有描邊尺寸後回到 1187.66 KB，保持 1500 KB 門檻。沒有放寬測試。
- 初次外部引擎測試被 sandbox 拒寫隔離 user://，未視為成功；正常授權重跑後保存重試／重載通過。初次 import 含既有歷史 PNG 損壞／外部 editor settings 拒寫，最終 worktree import exit 0。
- 中途新增測試有未明確型別的 parse error；已改為 `int`。原碼比較備份曾以 `.gd` 存於 build 被引擎掃到重複 global class；已改為 `.gd.bak` 並透過正常 import 重建索引，沒有手改 `.godot`。首次原生歷史 FX2 圖被重產，已將本輪圖另存 FX3 並還原原歷史圖。
- 退出仍有既有 Font RID／CanvasItem／ObjectDB 診斷；不能稱日誌零錯誤。沒有改規則、費用、保存 schema 或玩家正式進度。

命令日誌及 PNG 保存在 `docs/verification/artifacts/native-vfx/`；`fx3-all-runners.log` 為完整 36 項結果，`fx3-breakthrough-final.log` 為最後保存提示隔離回歸，`fx3-export.log` 為最後匯出。原碼比較與文字隔離日誌亦保存。

最後完整回歸的 50 次切換記憶體結果為 1461.19 KB，通過原 1500 KB 門檻；上述 1187.66 KB 是定位描邊快取時的較早測量。文件檢查：`git diff --check` exit 0；9 份文件嚴格 UTF-8 與 103 個本地連結檢查 PASS。

## 真實 Web 操作證據

- IAB、滑鼠，獨立 origin `http://127.0.0.1:4197/index.html`。啟動前確認 port 無 listener，只提供本 worktree 的 `build/web`。先前 4184／4185 已有另一份 E:/WORK/Dao2 根目錄服務，嘗試得到 404，未用來驗收，也未終止既有服務；本輪在該兩個 port 新開的子程序已停止。
- CSS `1280×720`，DPR 約 1.000000015，canvas 邊界約 `1279×719`：實際關閉離線摘要、開設定、播放文字／引擎特效、重播、返回；看到飛劍流光、小光環、金環及白藍雷電。連續 screenshot 取樣於重播約 1054／2399／3816 ms，保存 `web-replay-frame-7/15/23.png`，不是直接呼叫遊戲函式的畫面。
- CSS `844×390`：實際切低特效、試播、返回、再開標準特效試播；`web-trial-low-844x390.png`／`web-trial-844x390.png` 對照。返回後 HUD 仍顯示練氣期 1/10，ERA8 樣板沒有提升修為。短橫向試播會自行配合鏡頭，常態近景的既有裁切不由此宣稱已重做。
- 以 Escape 關閉、切 CSS `360×640`，旋轉提示仍出現且遮住玩法；保存 `web-portrait-360x640.png`。提示字級仍受既有 content-scale 問題影響偏小，不能稱直式可讀性已修復或完整裝置驗收通過。
- `tab.dev.logs` 查詢 warning／error 為空，結果保存 `browser-warnings.json`。不是 FPS／p95 測量，也沒有用 DOM canvas fallback 的文字當成畫面錯誤。
- 最後的保存提示隔離小修只有指定 Runner 及重新匯出證據，未再次重跑上述整組瀏覽器互動；改動不涉及 Shader／版型。工具暫設 viewport 在結束前還原。

## 未完成 DoD 與下一步

使用者視覺放行、實體手機觸控／GPU、DPR 2／3、冷啟動與 p95／FPS、長期 native/Web 50 次切換負載待補。CLI 記憶體通過與桌面截圖不能代替 GPU／手機效能。後續先調整本組視覺強度並驗裝置，另開 New Chat 再處理水面／雲霧／Portal；聚靈壇與靈界專屬場景仍按 ART-A1 保持未放行。
