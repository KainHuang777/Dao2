# UIX-R2-F3：Debug自動建造BUFF圖示

2026-10-11。IN_PROGRESS：來源／CLI／原生三橫式交付，Web實際滑鼠／觸控／高DPR待驗。

使用者要求Debug自動建造開啟時顯示於BUFF ICON區。沿BuffHudBar現有44px字印／TIP／點擊詳情：新增「建」圖示，說明來源Debug、每30秒自動隨機建造／升級、持續至Debug面板關閉。開關立即_refresh_hud；開啟新增、關閉移除，與正式BUFF共存、沿既有＋N分頁與短橫式建築暫收HUD。Debug狀態是呈現參數，不塞入GameSession View或正式buff存檔，圖示點擊只看說明，不執行建造。

修改src/presentation/buff_hud_bar.gd、abode_hud_controller.gd、abode_modal_manager.gd、tests/uix_r2_hud_runner.gd、tools/uix_r2f3_preview.gd及其Godot生成uid；ROADMAP、docs/19、status、updata與本紀錄同步。既有dirty保留，無新圖片資產／外部授權／规则或schema修改。

驗證工具與結果：固定tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version確認4.7.2.stable.official.ed1daf0bf，exit0。隔離APPDATA=build/uix-r2-f3-*；--headless --path . --script res://tests/uix_r2_hud_runner.gd為100 checks／0 failures／exit0，包含即時新增移除／一般BUFF共存／TIP／共用詳情與快照不變；buff_system、m2d_responsive_ui回歸均exit0。沒有重跑全量。

--path . --script res://tools/uix_r2f3_preview.gd原生1280×720、844×390、800×360／洞府與建築六張渲染exit0；800×360已看圖确认「建」位於BUFF區。--headless --path . --export-release Web build/web/index.html及bundled Node tools/prepare_web_compression.mjs build/web皆exit0。受影響檔案git diff --check exit0。既有Font RID／CanvasItem／ObjectDB退出診斷保持，不宣稱零錯誤。

本輪沒有新的Web互動證據；同Session前一輪IAB localhost在隔離服務啟動後逾時，詳見uix-r4-f4.md，Web實際滑鼠与裝置保持待驗，不以headless popup斷言或原生渲染代替。Web PCK SHA256：FECF0AACFAEE005703B89EBCCE6788771B3CA2D8B11C767A3D63A14C8C320B83。

[截圖與log](artifacts/uix-r2-f3/)。下一New Chat：隔離Web開Debug→開自動建造→關面板，看「建」圖示／TIP／點擊詳情→再關自動建造確認消失；一般BUFF共存與＋N、三橫式均待實際互動，並續前輪茅屋Web驗收。依Context Guard不展開大型下一任務。