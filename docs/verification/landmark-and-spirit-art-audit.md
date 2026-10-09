# ART-A1：聚靈壇與靈界洞天美術現況複核

2026-10-07 **ART-A1-HOME（當次使用者核定）**：祖島左居所／中央修士／右聚靈壇已接入，覆蓋下方10/3中央放壇的歷史配置。聚靈壇只在storage_lingli已建時顯示，世界／營造同命令，輪迴空地；人工美術與裝置門檻待驗。見[本輪驗收](home-landmarks.md)。靈界專屬場景本輪未開展。

日期：2026-10-03。狀態：複核 DONE；兩項美術均尚未完成驗收。

## 使用者要求與結論

| 項目 | 要求 | 目前證據 | 美術狀態 |
| --- | --- | --- | --- |
| 聚靈壇（`storage_lingli`） | 已建成且美術驗收通過，中央陣台才顯示對應建築 | 有 `assets/abode/altar.png` 候選獨立圖及提示詞／處理紀錄；正式世界目前只顯示茅屋，聚靈壇仍由清單管理 | 圖片已有；中央對位、建前／建後與正式放行尚未完成 |
| 靈界洞天 | 不同據點有自己的場景，與人界境界升級分開 | 已有跨界規則、三項據點資料與操作面板；世界沿用人界地形，切界改文字與遮罩色 | 專屬場景美術及驗收未完成 |

本輪是確認既有交付，不將本次要求解讀為已通過美術驗收，也未新生成或整合美術。

## 實際來源與畫面核對

- `src/abode/living_abode.gd`：共用 `TERRAIN`／`SKY`；`_setup_buildings()` 建立候選聚靈壇節點於舊三排配置的 `(175, -85)`，不代表已對齊中央陣台。`_update_buildings_visual()` 只允許 `target_id == "hut"` 的世界建築可見；聚靈壇即使有等級也不顯示。現況符合「未放行不顯示」，但尚未交付放行後的顯示路徑。
- `assets/abode/altar.png`：實際開圖確認為獨立青玉／古金圓壇。`docs/abode-art/altar.prompt.txt`、`altar/prompt-used.txt`、`altar/pipeline-meta.json` 有生成與切圖紀錄；紀錄不等於正式美術或授權放行。
- `assets/abode/terrain.png`：實際開圖確認中央空圓形石基屬於地形本身；空石基存在不代表聚靈壇已建成。
- `docs/verification/artifacts/nav1/home-1280x720.png`：檢視既有 NAV1 畫面，中央保留空石基。這是既有截圖，並非本輪重跑或瀏覽器驗收。
- `src/presentation/abode_modal_manager.gd` 的 `_on_switch_realm_requested()`：送 Session 切界命令、保存並刷新 HUD；沒有掛載不同據點的世界場景。
- `src/presentation/abode_hud_controller.gd`：`realm_spirit` 分支改麵包屑、遮罩及洞府題字；`island_fx.set_attained(cur_era >= 2)` 仍讀共同 Era 狀態，尚未將人界升境世界演出依據點分開。
- `src/simulation/realm_system.gd`：領域 ID 為 `realm_human`／`realm_spirit`；靈界有 `celestial_hub`、`pure_pool`、`void_beacon` 設施資料。資料中有三項設施不等於已有三套場景，也不自行推定每項設施就是一處獨立地理據點。
- 查核 `assets/`、`scenes/` 與既有驗收紀錄，未找到靈界專屬地形／地標／場景交付證據；M4-A 歷史「全閉環」描述涵蓋規則與面板，不能作為專屬美術完成證據。

## 後續交付與驗收門檻

1. 聚靈壇：確認候選圖的來源／授權、透視、尺寸及錨點；以中央石基製作建前／建後組合畫面及運轉狀態，完成使用者美術放行。正式顯示須同時滿足建成與該資產版本已放行；缺圖／未放行保留空基，清單不失效。新檔、已建檔、輪迴及升境均核對顯示條件，世界點選與清單送同一命令。
2. 靈界洞天：先明訂據點身份及場景範圍，再製作分層地形、少量獨立地標、背景與返回入口，記錄提示詞及授權。按界域／據點身份切景，人界 Era 只控制其升境外觀／演出；保留現有解鎖規則。驗證切界、返回、重載、升境與雙界並行模擬，不能以人界改色冒充不同據點完成品。
3. 兩項皆須在 Godot 與真實 Web 的 `1280×720`、`844×390` 檢查構圖、命中與返回；直式遵守旋轉提示。美術放行、觸控／高 DPR／實機證據各自記錄，不由 headless 推定。

## 本輪修改、命令與證據邊界

- 修改：本頁、`docs/08-building-presentation-and-era-expansion.md`、`ROADMAP.md`、`docs/development-status.md`、`docs/verification/m4-a.md`、`updata.txt`。
- `git status --short`：開始時工作區乾淨。
- PowerShell `Get-Content`／`Get-ChildItem`、`rg -n`／`rg --files`：核對來源、資產與歷史記錄；一次 `rg tools/*.ps1` 的 Windows glob 搜尋失敗，已改直接讀取測試入口，不作成功證據。
- 外部既有引擎 `E:/WORK/Dao2/tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit 0，`4.7.2.stable.official.ed1daf0bf`。本工作樹未附帶被 Git 忽略的引擎。
- `view_image`：開圖核對上述三張既有圖片。
- `git diff --check`：exit 0；5 份文件嚴格 UTF-8 解碼及 76 個本地連結檢查 PASS。Git 提示後續可能轉為 CRLF，未有差異格式錯誤。
- 本輪未改程式、資產或存檔；未重跑 Runner、import、Web export 或瀏覽器／實機測試，沒有新增 FPS 或互動驗收證據。

下一步：先交付聚靈壇中央對位美術，再在獨立工作階段製作靈界據點場景；兩項保持未放行，不開始成就等其他大型功能。
