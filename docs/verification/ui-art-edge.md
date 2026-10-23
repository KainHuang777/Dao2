# UI-ART-EDGE：正式 Godot 共用插圖呈現

2026-10-23；**DONE（CLI／原生／桌面Web有界）**。相依 UI-ART-EDGE-COMPARE 的 B 選定及 CONTENT-P1-TALENT 美術接受均已滿足。此次使用者指定「正式 Godot 共用呈現接線」。

## 交付範圍

- `src/presentation/ui_illustration.gd`／`.gdshader`：原創 TextureRect 子類及 Compatibility canvas_item shader；實體 alpha≥0.75、暖灰褐58%／1.15顯示像素，原alpha柔影24%／下移1.8px／sigma1.5。3×3有界方形擴張、5×5 Gaussian近似；不是SVG filter逐像素複製。
- 依實際 keep-aspect 圖幅與 screen transform 換算取樣；四邊頂點外擴7顯示像素，原圖不縮小，超出UV取透明而非重複邊緣。每張圖獨立uniform、同一shader；只在可見且圖幅／scale／texture有變時更新uniform。原色依alpha合成並只套一次modulate。
- 接入 `skill_study_view`、`reincarnation_panel`、`fortune_modal`、`realm_decision_view`、`sect_panel`、`building_catalog`、`resource_icon`、`building_card_button`，成就 `achievement_panel` 亦走同一入口但集中免加邊。既有金框成就不重複描邊；低於40顯示像素小圖保留原柔邊，28px原尺寸已核對。配方36／28px圖印及HUD小圖、向量印記保持原呈現。
- 建築 Button 保留原icon的尺寸契約，內建icon繪色設透明，由 IGNORE 滑鼠的插圖子節點繪製一次；原文字、狀態環與命令保持。沒有把shader套到整顆按鈕。
- `src/verification/ui_art_edge_acceptance.*`、`tests/ui_art_edge_runner.gd`、固定Runner入口、新增 `UiArtEdgeAcceptance` preset與main-scene feature；正常主場景未改。正常候選 `build/web-ui-art-edge`，獨立樣本 `build/web-ui-art-edge-acceptance`，天賦正式隔離頁 `build/ui-art-edge-talents`。所有本輪匯出命令均指定上述候選目錄。續行時觀測到 `build/web/index.pck` 已於11:33被替換，SHA256與正常候選一致；保留現況，前後hash另記，不宣稱整輪凍結包保持。

## 驗證

引擎實測 `4.7.2.stable.official.ed1daf0bf`，原生 NVIDIA GTX1660Ti／OpenGL Compatibility；Web為桌面IAB。未安排實體裝置測試。所有檔案位於 [artifacts/ui-art-edge](artifacts/ui-art-edge/)。

- 最終專項：headless **161 checks／failures=[]**；原生 **166 checks／failures=[]**。三橫式1280×720、844×390、800×360及192／112／64／28圖幅；不縮圖、無水平溢出、滑鼠IGNORE、縮放與動態替圖、獨立uniform、金框免加邊通過。額外真實SubViewport像素檢查原色、細邊外擴、透明區無矩形暈、向下柔影、透明度合成，均通過。原生12張圖及JSON／log保留。
- 桌面Web：真實滑鼠切換112／64與短式28px，同底原圖／共用B可見；原生與Web白狐毛邊、丹爐光霧維持原alpha，實體氣帶若alpha≥0.75依同一門檻描邊。短式紙面與單區捲動無圖像外緣裁斷。
- 正式天賦頁三橫式滑鼠／捲動；1280購入丹心1階，20→15道心；800購入靈契1階，15→10；真實重載後兩項仍1階、10道心、save_failed=false。截圖與 `browser-reload-state.txt` 保留。800經營頁顯示茅屋縮圖、狀態環與密集資源圖；未把圖像點後無可見變化宣稱成新命令通過。
- 樣本的HTML外層僅測試iframe尺寸與故障按鈕，正式內容全為Godot。1280測試iframe大於IAB可視寬高時，外層瀏覽器會捲動；不拿該測試殼捲軸冒充正式遊戲的響應式處理。
- 字型 `python tools/subset_game_fonts.py --check` 通過，未重產字型。正常與驗收Web匯出、`node tools/prepare_web_compression.mjs <candidate>` 壓縮及四首BGM companions已準備。最後來源稽核與全量結果另見收結段。

## 命令及初輪問題

`Godot --version`、`--headless --path . --import`、專項 `--headless --path . --script res://tests/ui_art_edge_runner.gd` 及原生同指令去除headless；固定回歸 `tools/run_all_runners.ps1`；Web `--export-release Web/UiArtEdgeAcceptance/ContentP1TalentsAcceptance <candidate>/index.html`。具體輸出存本目錄log，沒有以已發出命令當通過。

初輪沙箱拒絕user://導致天賦場景未初始化，已停止並以正常授權重跑，117項通過；不是正式新bug。新Runner的型別推斷及Shader TEXTURE作用域錯誤已修正；headless對builtin sampler參數另有診斷，改由顯式art_texture uniform避免；最終專項無SCRIPT／SHADER ERROR。一次Python未指定UTF-8解碼失敗，已指定編碼並重跑。最初全量的子PowerShell於既有mfg3 fixture寫入返回null而停住，手動停止、直接重跑該支65項通過，再以同一PowerShell重跑全量。天賦首次匯出因目標目錄不存在失敗，建立專案內隔離目錄後重試成功。首次沙箱localhost服務逾時，停止後以正常權限僅綁127.0.0.1，重建失效瀏覽器tab後連線成功。樣本初版短式沿720基準縮小，已改成等像素驗收畫布並重匯出，正式遊戲的scale政策保持。

完整回歸仍可能有既有Font RID／CanvasItem／ObjectDB退出診斷、預期負面資料錯誤；最終應逐項記SCRIPT ERROR而非只看exit0。不宣稱全日誌零錯誤或效能FPS已量測。

## 資料界線與交接

原PNG、既有圖像來源／授權、規則、保存schema與玩家進度不改；本輪無ImageGen、圖片重繪、commit或push。初輪受保護圖檔／simulation／persistence共138份與凍結包合計139份hash均保持；續行時僅觀測build/web已變，138份正式圖檔／規則／保存來源仍保持。全量生成docs fixture按末次全量前快照還原；第一段生成的天賦fixture與前輪audit hash不一致，讀前輪PCK亦得到相同現存bytes，故保留實測產物、不推測還原為未知初值；這是隔離fixture，非玩家資料。只在獨立4423／4424 origin測試；天賦使用原有隔離命名空間。

下一步收正式畫面回饋；若無修正，下一大型內容工作由使用者於New Chat指定，P丹藥未開工。沒有把工程接線自動當成新的美術接受。

續行補記：第一段程序未留下整批結束碼，已從res1c2_perf續跑。入口盤點實際為102唯一Runner（包含tools/test_runner）；初段日誌的early_pacing2_pill曾重複執行一次，按名稱去重對照固定入口，不虛稱整批單次完成。續跑在ui_material_states遇到舊測試的「零子節點」斷言失敗；已改直接驗證每個呈現子節點的mouse_filter為IGNORE，保持原有不攔截命令契約。失敗log保留，最後從該支續跑。

後續early_flow1d的舊ready fixture寫入亦曾失敗（161檢查中fixture file ready拒絕，exit1），唯讀開啟權限探針確認可寫且未變更bytes；直接單獨重跑161項exit0，不改規則或測試門檻。其餘未完成中段12支與末13支分開執行，最後按固定入口名稱去重逐一核對，失敗不混充成功。

## 最後收結

- 固定入口 **102／102 唯一Runner已完成**：先前中斷前50唯一項（51次執行，含既有pill重複一次），續行12項、修正舊UI斷言後14項、early_flow1d直接重試1項、未完成中段12項、末13項。每項均可對應成功段；各成功段SCRIPT ERROR／SHADER ERROR為0，預期負面解析與既有退出RID診斷仍保留。不是宣稱一次整批無中斷。`tools/ui_art_edge_audit.py`逐項對照實際入口，failures=[]。
- 最終CLI161、原生166、字型check、兩候選Web匯出／壓縮／四首BGM companions通過；最後Web匯出以明確退出碼檢查再次收結，日誌為export-*-closure.log。其餘最終來源hash與候選hash見audit.json。
- 8份docs隔離fixture按末次全量前snapshot還原，保留fixture-restoration.json；結果報告不回填成歷史通過。第一段產生的天賦fixture保留及舊包觀測界線如前述。
- 所有接入資產目錄均非全不透明PNG，alpha-inventory.json記原alpha範圍與hash。138份正式圖檔／simulation／persistence保持；build/web於空檔被替換的觀測如前述，未在本輪回復。
- 修改清單由audit.json列正式程式／測試／設定；共用規範docs07／19、README、ROADMAP、handoff、development-status及updata同步。保留引擎產生的.uid，未手改.godot或build來修來源。
- 本階段停止，不開P丹藥或其他大型任務。下一New Chat由使用者指定；正式畫面可收後續回饋，本輪不代替新美術接受。
