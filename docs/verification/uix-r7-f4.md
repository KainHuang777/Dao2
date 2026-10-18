2026-10-18 使用者回饋更新：本試作視覺與目標差距大，狀態改為「視覺需重做」，非僅待接受。既有測試證據只證明舊試作技術行為，不證明新的拆層方案。後續依[UIX-R7-F5規劃](../22-reincarnation-layered-vfx-plan.md)；本輪僅規劃，未回退或更改F4程式與匯出。

# UIX-R7-F4 輪迴動態試作

日期：2026-10-18。狀態：試作交付，IN_PROGRESS（美術接受與持續FPS量測未完成）。原R7接受為舊版歷史，不代表本次動態已獲接受。

## 範圍與來源
- 桌面命盤176→300邏輯像素，收益／傳承／詳情置右；短式維持56以保留壽盡收益與44px操作。
- 新reincarnation_mandala.gd：兩個反向旋轉六段符環、28個解析式光粒、六道上浮文字；原圖微幅擺動／呼吸縮放。隱藏停算、低特效靜止，不讀寫Session、不使用遊戲RNG。
- 轉世演出6.2秒，命盤依viewport配置最高460；深青背景與淡靈環取代粗光柱，跳過／結算隱藏命盤。六道只是意象，不新增投胎抽選或收益規則。
- 沿用assets/ui/reincarnation-painted/reincarnation_wheel.png與life_lamp_spent.png；來源、提示詞與授權沿UIX-R7既有紀錄。本輪未新生成或切割美術；新增符環／粒子為Godot程式繪製。GIF是實際元件渲染的獨立展示，並非全遊戲錄影。

## 修改檔案
src/presentation/reincarnation_mandala.gd（及Godot生成uid）、reincarnation_panel.gd、reincarnation_sequence.gd、abode_hud_controller.gd；assets/fonts/runtime兩字型與manifest；tests/uix_r7_reincarnation_ui_runner.gd、reincarnation_motion_runner.gd（及uid）；tools/run_all_runners.ps1、uix_r7f4_preview.gd、reincarnation_motion_capture.gd（及uid）。同步README／ROADMAP／handoff／status／19規範／updata及本報告。保留所有先存dirty成果，不commit/push。

## 命令與證據
執行引擎tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe，--version確認4.7.2.stable.official.ed1daf0bf。
- --headless --path . --editor --import --quit：匯入成功。
- --headless --path . --script res://tests/uix_r7_reincarnation_ui_runner.gd：75 checks failed=false、exit0。確認／取消、天賦、拒寫重試與短式邊界沿此隔離Runner驗證。
- 同命令執行m3a_reincarnation_runner.gd、m3a_reincarnation_ui_runner.gd：PASS、exit0。
- 同命令執行reincarnation_motion_runner.gd：failures=0、exit0；可見動作、隱藏停算、低特效、三尺寸避讓、跳過／完成與低特效自然結束。已登記固定runner；本輪未跑全量。
- --path . --script res://tools/uix_r7f4_preview.gd：exit0，三尺寸共18張原生圖；檢視桌面主圖、演出及短式演出。
- --path . --script res://tools/reincarnation_motion_capture.gd：exit0，48幀原生元件渲染；Pillow合成6秒GIF，僅作視覺預覽。
- python tools/subset_game_fonts.py及--check：最終通過；--export-release Web / R7Acceptance，並node tools/prepare_web_compression.mjs build/web與build/r7-acceptance：見export-final與compression-final log。
- IAB真實滑鼠：48774隔離origin開啟輪迴→確認→6.2秒演出→第2世結算→入世→輪迴；844×390、800×360、1280×720桌面iframe頁面核對。web-result／web-844／web-800／web-1280.png為證據。Web使用已帶資格的fixture，非自然進度；未宣稱瀏覽器拒寫／重載或FPS新驗收。

## 初期失敗與限制
- 初次普通沙箱Godot無法寫user://log／隔離存檔，runner後續Nil，程序已中止；正常權限重跑成功。
- 初次字型缺畜、餓，重建；刪除舊光束註解後corpus coverage變動令manifest check失敗，再生成／check成功。
- 初版短式96px造成壽盡收益出界，ui-first-failed.log保留；改回短式56通過。桌面收益移右，消除大圖導致收益被推下。
- 首次瀏覽器在服務啟動前connection refused；服務啟動後重新開tab成功。
- 原生整場退出仍有Font／CanvasItem／ObjectDB資源洩漏診斷（既有）；不把exit0解讀為無警告。
- 未量測本次持續FPS；美術尚待使用者接受。下一步僅收動態回饋、必要時微調與效能量測；不在本輪開突破大型任務。

## 試看
動態元件：artifacts/uix-r7-f4/motion-preview.gif。
隔離遊戲：http://127.0.0.1:48774/launcher（已有本輪測試第2世進度，命盤可看；不覆寫玩家origin）。一般Web已同步本次呈現。
