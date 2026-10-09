# M2-D-FX3-AMBIENCE — 淚佛瀑布、遠景浮動與境界吸靈

2026-10-07，使用者插入的三項美術調整。實作／下列有界驗證交付；本子項及完整 FX3 保持 IN_PROGRESS，最後審美、實機／高 DPR、長效能與 Windows 實際操作仍待驗。

## 修改

- `assets/abode/fx3art1/concept_sky.gdshader`：依目前背景的實際淚瀑位置重對遮罩，增加沿水柱下行的亮紋與兩軸輕擾動。兩處雲面落點各有三團柔霧，隨週期升起、擴散、淡出；每週期用 shader 局部雜湊改變偏移，沒有遊戲 RNG。瀑布與佛頭之間五處碎片／浮岩使用羽化的局部 UV 升降，約 2–4 原圖像素、25–37 秒不同週期；仍是背景圖中的局部動態，沒有製作獨立可互動島嶼圖層。低特效直接取靜態原圖，停水流／浮動／霧氣。
- `src/presentation/cloaked_cultivator.gd`：增加三條向胸口匯聚的青藍流光、雙層光尾與藍金亮點。Era1/3/7 分別 24/32/48 點，半徑 180/198/234 world units；速度／亮點尺寸隨境界增強，Era7 後有界封頂。仍為原生 Godot 畫面呈現，不發放靈氣或修為；低特效留下角色和接地環，停所有吸靈動態。
- `src/abode/living_abode.gd`：將正式 `session.state.era_id` 傳给角色呈現，特效試播不冒充玩家已達境界。
- `tests/island_breakthrough_runner.gd`：補常態境界增強、12境界限制／48點預算及快照不變契約；保留低特效、重播不重複收益等原案例。
- `tools/ambience_preview.gd`／`.uid`：專用隔離原生預覽，手動演出時間／境界強度，產出兩橫式三強度、低特效及背景三相位，共13張圖片。比較標準背景不同時間確實改變、低特效0／18秒像素完全一致，預覽前後完整規則快照一致。預覽用三種視覺 Era，但 HUD 為相同新檔境界，不能視為玩家到達高境界的證據。
- 資產來源／用途更新於 `assets/abode/fx3art1/README.md`；未新增生成圖，舊提示詞與權利限制保留。

## 驗證

Godot `4.7.2.stable.official.ed1daf0bf`。命令使用現有 `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe`。

1. `--headless --path . --editor --import`：exit0。
2. `--headless --path . --script res://tests/<runner>_runner.gd`：island_breakthrough、living_abode、m2d_responsive_ui、m3a_reincarnation_ui、res1d2_world 五項 exit0（world58）；流光新增後演出 runner 再次 exit0。未重跑全量54。
3. `--path . --script res://tools/ambience_preview.gd`：最後 exit0，畫面與 motion/freeze／快照檢查通過。初稿訊息遮住角色，調整診斷工具收起訊息、固定 redraw 與鏡頭後重拍，沒有把遮挡圖當最終美術證據。`1280×720`／`844×390` native（短橫式實際 logical779×360）圖在 [artifacts/ambience](artifacts/ambience/)。既有 Font／CanvasItem／ObjectDB 退出診斷仍在，無 shader 編譯錯誤。
4. `--headless --path . --export-release Web build/web/index.html` 與 `--export-release WindowsDesktop build/windows/dao2.exe`：最終 exit0；`node tools/prepare_web_compression.mjs build/web` 最終 exit0，BGM companions 保留。期間細調霧氣及流光後重新匯出，不將較早包當最後版本。
5. IAB 隔離 `http://localhost:4282/launcher`：指定 command-earned Era3 fixture，沒有使用4175玩家資料。真實滑鼠關閉離線摘要／訊息，檢視一般橫式畫面與844×390切換成功；最後版本重載另記下方追加。畫面觀看是桌面有界證據，不是手機／高DPR、長FPS或完整新手流程證據。

日誌：`build/verification/ambience/`。全工作區既有 ui_icon 空白問題未改；本輪追蹤來源／文件限定 diff-check。無 commit／push，其他未提交成果保留。開發狀態與 updata 英文checkpoint同步。

## 人工複驗與下一步

重新開啟一般Web或新版Windows包，使用標準特效：觀察瀑布下行與落點霧氣20–40秒、五處碎片緩慢升降、角色青藍流光匯聚；切低特效確認停止。正常進度Era1→3可看亮點增強，不用Debug改玩家進度。手機／高DPR需另測。本階段止於三項美術調整；下一New Chat收流光強度／霧量回饋及補装置／長效能，不開新大型階段。

最終追加（跨午夜收尾）：4282服務重啟至最終包後，IAB沿用既有隔離进度重開，滑鼠關閉摘要／訊息；DOM實測iframe844×390，待resize穩定後祖島三核心、青藍吸靈光跡及單排導覽可見。瞬間resize曾短暫呈舊控制列位置，穩定後恢復，未把瞬間圖當穩定PASS。未測整段動畫週期的FPS／裝置，browser低特效仍待人工；native低特效像素完全凍結已驗。最後退回launcher釋放writer鎖，測試服務PID575872保留，按「開啟隔離遊戲」繼續，勿重新種檔。

最終Web PCK SHA256：`a0452138c3a1faae24c95a5a017969affc1b9b14d4e6c34e20fd32f4dbd976bb`；Windows PCK：`b8615ff5d7250a24875527aff367bdf184a1f57c45ec30f13f20cbc91fde2eb3`。最後13張原生圖片與五項回歸證據保留，僅最終亮度調整後重拍native，不為純亮度再次跑全量規則。