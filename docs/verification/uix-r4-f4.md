# UIX-R4-F4：茅屋建成導航與首次施工提示

2026-10-11。IN_PROGRESS：來源、CLI與原生三橫式渲染已交付；Web實際互動／人工美術／觸控與高DPR待驗。

依使用者兩項要求，首次建造茅屋成功後直接開啟營造簿，清除詳情選取；島上施工不再接著呼叫詳情。清單建造亦沿同一成功路徑。命令失敗保持錯誤回饋，不當作完成。已建茅屋仍可手動開詳情。

首次可負擔而未建時，茅屋藍圖提高亮度、加粗青色地面光圈與金色向下提示，銘牌顯示「點擊建造茅屋」。屋頂／屋身及鏡頭縮放補償後的文字均可點擊；低特效保持明亮靜態提示。建成移除施工提示。小橫式自動訊息在施工入口亮起時暫收，主動展開說明仍保留；資源足額引導文案同步指向島上施工。

修改：src/abode/living_abode.gd、src/abode/abode_building.gd、src/presentation/abode_hud_controller.gd、tests/m2d_responsive_ui_runner.gd、tools/uix_r4f4_preview.gd（含Godot生成uid），及ROADMAP、docs/19、status、updata與本紀錄。原dirty成果保留，無規則／保存schema／玩家存檔／第三方資產變更。新箭頭為原創Godot draw幾何，非新增圖形檔，無生成提示詞或外部授權。

命令與結果：

- 固定引擎 --version：4.7.2.stable.official.ed1daf0bf，exit0。
- 隔離APPDATA位於build/uix-r4-f4-*；引擎 --headless --path . --script res://tests/<name>_runner.gd：m2d_responsive_ui、uix_r4_building_cards、early_flow1b（110 checks）、gather_guidance_highlight（11 checks）、uix_r2_hud（92 checks）全部exit0。World caption命中、正常命令一次扣料、成功清單／詳情關閉、短橫式訊息避讓、低特效亮度與建成提示撤除已斷言。未重跑全量。
- 原生 --path . --script res://tools/uix_r4f4_preview.gd：1280×720、844×390、800×360各施工前／建成清單，exit0。人工看圖確認小橫式施工文字可见，建成清單沒有詳情；這不是Web滑鼠／CSS／觸控證據。
- --headless --path . --export-release Web build/web/index.html，以及bundled Node tools/prepare_web_compression.mjs build/web：最終皆exit0。
- git diff --check（受影響來源／測試）：exit0。
- bundled Python tools/island_preview_server.py --port 48764 --normal-build --gzip：啟動成功；IAB第一次在服務前開啟為REFUSED，服務啟動後新分頁仍TIMED_OUT，既有錯誤頁再綁定另遭URL policy拒絕，未進遊戲。服務收尾Ctrl+C（exit1為主動停止）。沒有Web通過證據，沒有改其他origin。

初次新增測試誤把View成本數字當Amount，產生型別錯誤且未退出，Ctrl+C停止後改用AmountCompat.from_number重跑成功。新增訊息避讓斷言曾受測試較早主動展開狀態影響，已限定自動訊息狀態後通過。第二次原生覆寫已載入PNG失敗（exit1），改新檔名保存最終圖並exit0；較早圖保留歷史。既有Font RID／CanvasItem／ObjectDB退出診斷仍存在，未宣稱零錯誤。

證據：[目錄](artifacts/uix-r4-f4/)，最終圖檔為verified-home-*及verified-buildings-*；最終命令log亦已複製於此。PCK SHA256：F2BF997691F1FE9E0C896C8A601766CF55B78DE4903BB2A5376A7B2E7AFBB39F。

下一步（New Chat）：在隔離新origin實際滑鼠採集靈氣至可建，確認提示亮起，點提示或屋身一次→茅屋1階／靈氣正常扣除／直接營造簿，再手動開茅屋詳情及返回；1280×720、844×390、800×360各驗。另收使用者美術、實體觸控／高DPR結果。依Context Guard不展開大型下一任務，不重做已接受FPS／保存或暫緩冷啟動。