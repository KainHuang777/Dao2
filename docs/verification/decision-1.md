# DECISION-1：機緣收據與抉擇簿驗收

2026-10-22。使用者指定 `DECISION-1`。前置 ATM-LIFE-A／REPORT-1A、LEDGER-0 與共用殼已完成。本輪正式接線範圍為機緣選前資訊、待決暫收／重開、權威實得收據及當世報告抉擇簿。契約見 [ADR-014](../decisions/ADR-014-fortune-choice-receipts.md)。全量回歸收結狀態見本頁末。

## 修改檔案

- `src/domain/decision_receipt.gd`：穩定待決身分、version1收據驗證／有界簿；`life_ledger.gd`：選填子簿、JSON型別回復與原封存額度裁減。
- `src/simulation/fortune_system.gd`：實際分項觀測與原規則發放；`command_processor.gd`：傳遞命令來源／所見實例、正式結果事件帶收據。
- `src/application/game_session.gd`：所見待決實例提交、明確深複製 get_decision_book API；不把歷史塞入每幀View。
- `src/persistence/save_codec.gd`：新待決實例驗證，沿原checksum／雙槽／schema5。
- `src/presentation/decision_book_view.gd`、`fortune_modal.gd`、`reincarnation_panel.gd`、`abode_modal_manager.gd`、`src/abode/living_abode.gd`：共用收據閱讀、固定效果、報告重讀與保存保護只讀。
- `tests/decision_receipt_runner.gd`、`decision_ui_runner.gd`、`life_report_ui_runner.gd` 舊測試閱讀節點遷移、`tools/run_all_runners.ps1`。
- `src/verification/decision_acceptance.gd/.tscn`、project／DecisionAcceptance preset：獨立合成進度與拒寫adapter；正常Web仍排除驗證來源。
- runtime字型兩份與manifest由原OFL來源再產生；ADR／本驗收／docs19／README／Roadmap／交接／updata。未新增圖片、字型下載或外部授權資產。

## 命令與結果

Godot 實測 `4.7.2.stable.official.ed1daf0bf`，未升級／重裝。APPDATA 指向專案 build/decision-1-user 或 decision-1-final-user，所有fixture與玩家進度隔離。

| 命令 | 結果 |
| --- | --- |
| Godot `--version` | exit0，同版4.7.2。 |
| Godot `--headless --path . --import` | exit0；保留既有user目錄／JPEG誤名PNG診斷，不稱乾淨import。 |
| Godot `--headless --path . --script res://tests/decision_receipt_runner.gd` | 最終1665 checks、failures=[]、exit0。全部26機緣所有選項×6種庫存；小數／1e16／1e30、拒絕不動、同資源收支、丹藥／修煉／BUFF、命令／實例去重、深複製、JSON、待決時間、容量及封存；拒寫／重試／完整讀回／未知版本另一槽回復／雙壞拒絕覆寫。 |
| Godot `--path . --script res://tests/decision_ui_runner.gd` | 原生28 checks、failures=[]、exit0；三橫式待決、結果、報告及保存保護共10圖、低特效、44px、內捲、資源變動重開重新核對。 |
| Godot `--headless --path . --script res://tests/uix_r10_fortune_ui_runner.gd` | 58 checks、failed=false、exit0；沿原真實命令／拒寫重試與讀回、長文三橫式回歸。 |
| Godot `--headless --path . --script res://tests/m3b_fortune_runner.gd` | 最後實扣精度修正後追加回歸exit0。 |
| `python tools/subset_game_fonts.py`／`--check` | 重建及check exit0；原資產／OFL保持。 |
| Godot `--export-release Web build/web-decision-1/index.html` | 正常候選；結果及hash見頁末。 |
| Godot `--export-release DecisionAcceptance build/decision-1-acceptance/index.html` | 合成隔離候選；結果及hash見頁末。 |
| `node tools/prepare_web_compression.mjs <候選目錄>` | 兩包壓縮往返與BGM companions，結果見頁末。 |
| `python tools/ui_shell_server.py --build build/decision-1-acceptance --port 4401` | 沙箱服務初次瀏覽器timeout；改用已授權的本機可達服務後成功，未改防火牆或安全設定。 |

完整原始輸出位於 [artifacts/decision-1](artifacts/decision-1)。全量回歸有初輪中斷日誌與最後完整結果；不能把已發出命令當成功。

## 真實桌面 Web

IAB／滑鼠／遊戲iframe實測1280×720、844×390、800×360，外層測試工具不是正式Web shell。固定fixture標示合成，第二世50靈草／游方丹師，沒有自然一生或玩家保存聲稱。

1. 原機緣頁成本50／20與固定延壽丹可讀。原返回暫收，再點遊歷回同一待決instance，仍50草、0結算；沒有重抽。
2. 800×360真實滑鼠內捲到付費選項；啟用拒寫後點選，實扣20→餘30、得延壽丹1、只一件收據，pending清除。保存保護可讀所選、敘事、已付／實得／未入庫／餘量，固定重試44px。
3. 拒寫下再次重試，收據／來源／實例／草30／結算1完全相同。三橫式resize保存保護可閱讀／內捲，世界仍鎖住。
4. 恢復寫入並點固定重試，保存恢復；原背景結算可推進年歲／冷卻，未重送機緣。收據全份相同，仍草30、結算1。
5. 修行→輪迴天賦→原轉世頁，內捲展開抉擇簿，實讀同一筆游方丹師／已付20／餘30／丹1；三橫式固定底列與閱讀狀態保持。
6. 重載仍草30／結算1／pending空與完全相同receipt source／instance／內容，沒有重發。機緣頁直接讀已保存簿。

`browser-observations.json` 八項全true（含最終匯出包讀回），含畫面／真實輸入與DOM觀測核對；DOM僅輔助，不把讀JSON當滑鼠證據。`browser-console.json`保留一則無來源URL的MutationObserver TypeError，歸屬未定，不聲稱console乾淨。首個不可達暫時tab及DOM iframe contentWindow讀取限制失敗保留；未繞過政策。成功分頁已關閉，視口override已reset。

[故障收據800](artifacts/decision-1/web-protection-800.jpg)、[報告1280](artifacts/decision-1/web-book-1280.jpg)、[報告844](artifacts/decision-1/web-book-844.jpg)、[報告800](artifacts/decision-1/web-book-800.jpg)、[重載](artifacts/decision-1/web-reload.jpg)。瀏覽器圖實際為JPEG，原生圖為PNG。

## 初輪修正與證據界線

- 第一輪新增固定抉擇簿列壓低短式閱讀區，R10最後選項不可達；入口改置故事標題列，狀態短句／詳細TIP後，R10 58項通過。保留ui-first.log。
- 新native runner曾誤用SceneTree.get_tree()，保存保護has_reading推導缺明確bool造成解析失敗；修正後原生28項通過。兩次全量初輪被這些錯誤／舊測試硬取閱讀首節點阻塞，以本輪所建exec的Ctrl+C停止，未終止其他程序；最後以新完整輸出為準。
- 報告native初次沿Era1開隱藏輪迴被正確路由至煉丹，不能算報告通過；fixture改成明確第二世並重建本世ledger，最終三尺寸報告才通過。未提前開正式門檻。
- 最後細化實付為實際扣款差額，Amount極大庫存可能無法表示20扣款，不能照標稱冒充已付；專項新增精度反例1665及fortune回歸通過，候選重新匯出。原通常50→30案例行為與收據保持。
- 保留既有Font RID／CanvasItem／ObjectDB退出診斷。未宣稱FPS、全量大數精確、全舊檔corpus、IndexedDB或quota全矩陣通過。
- 觸控／實機按既定政策延期，非當前阻擋。界域法令收據不在本次奇遇DECISION-1範圍；九世API可讀封存簿，選世介面仍REPORT-2。

## 最終收結

**DONE（CLI／原生／桌面Web有界）**。完整固定入口90／90 Runner exit0，最後全量SCRIPT ERROR 0；`all-final-2.log`保留完整原始輸出。整輪開頭為1655項專項版本，其後只增測試至1665與最後實扣差額細化，再以1665專項、fortune回歸及原生28補驗；無因測試新增再重跑整輪。原生最後10圖由native-last.log對應版本重新產生。兩最終候選匯出／壓縮／BGM companion均exit0，最終包重開原隔離origin仍完全相同收據，八項Web觀察全true。

初次專項seal validity失敗是fixture未把新世年歲歸零，已修正測試生命切換前置；沒有改正式輪迴重置規則。首次diff-check發現PowerShell文字寫入多一個尾端空行，已修正並重新匯出／驗原生，最終check通過。

本輪自建可達4401服務已Ctrl+C停止，exit1是主動停止；初始沙箱服務亦由本輪exec停止，未終止其他程序。10份開始時乾淨的tracked合成fixture已精確還原HEAD，生成版本另存generated-fixtures，依據與hash見fixture-restoration.json；既有dirty成果均保留。未commit／push、未操作玩家origin或原凍結build/web。

| 最終產物 | PCK SHA256 |
| --- | --- |
| `build/web-decision-1` 正常候選 | `f2f27fe69c8a45ba4033e60ebd6cfa092415a68e1718cba57e4867e4e5f6591a` |
| `build/decision-1-acceptance` 隔離候選 | `9db45697a38bcb520c5e948419b604587af3bb71fd269b4e22465d8a65d56f84` |
| `build/web` 原凍結包，保持 | `7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400` |

36份來源／UID／配置／文件初次嚴格UTF-8與8個本地連結檢查通過，最後文件更新後再產生final-manifest。退出診斷與界線沿上節保留。當輪無未完成的桌面阻擋；下一New Chat由使用者指定 **LEDGER-1／REPORT-1B**，不在本輪續開全量帳目。
