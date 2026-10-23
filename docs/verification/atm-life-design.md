# ATM-LIFE-DESIGN 驗收與邊界

2026-10-22 · **IN_PROGRESS：設計交付；待使用者接受。** [方案](../30-atm-life-design.md)。

## 範圍與修改

新增docs30、`docs/visual-prototype/atm-life-design/{index,screen}.html`、`style.css`、`screen.js`、`cases.json`，唯讀本機服務`tools/atm_life_design_server.py`、設計稽核`tools/atm_life_design_audit.py`及`artifacts/atm-life-design/`；更新入口、共用規範的候選狀態與英文交接。保留接手時大量既有dirty檔，沒有重設／覆寫先前UI-SHELL工作。

未改正式GDScript／規則／schema／原字檔／遊戲資產／build／玩家資料，未commit或push。比較頁是開發設計工具，不是正式核心HTML化。

## 命令與結果

- PowerShell `Get-Content`／`rg`／`git status --short`：閱讀入口、docs02／07／19／26～29與機緣／輪迴／Lifespan／SaveCodec實作。數次rg對不存在src/core及PowerShell檔名萬用字元失敗，改rg --files與實際目錄完成盤點。
- `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --version`：exit0，`4.7.2.stable.official.ed1daf0bf`。設計專項未跑import／遊戲Runner／原生渲染／Web匯出。
- `python tools/atm_life_design_audit.py`：exit0，[design-audit.json](artifacts/atm-life-design/design-audit.json)。17句來源、十題fixture可達、8192種存在性組合、UTF-8容量合成24,076 bytes；failures=[]。組合含不可能進程，不能解讀為實際觸發機率。時序／同獸身分與正式命令掛點未由此驗證。
- `python tools/atm_life_design_server.py --port 4396`：正常啟動；只綁127.0.0.1，只服務設計及指定現有資產檔案。需保持程序運行供審閱。最初4395沙箱服務不可由IAB存取，HTTP探查報socket權限不足；改正常升權流程啟4396後可讀。第一次IAB錯誤頁與其data URL policy錯誤不算驗收，未繞過該policy。
- CUA IAB真實桌面瀏覽器，viewport 1280×720／844×390／800×360。32 PNG與[最終browser-checks.json](artifacts/atm-life-design/browser-checks.json)：載圖／三字族可用、44px命中、固定控制無出界、頁面尺寸等於視口、閱讀／footer／heading無水平溢出，failures=[]；本輪console warn/error查詢空。使用者可直接在比較頁切換全部十題。
- 7項互動：滑鼠滾輪內捲、機緣暫收重開、資源不足重驗禁用、已結算保存失敗鎖轉世、樣張重試後仍為220靈草同收據無選項、resize保留收據、頁內確認取消。另實際點查記錄並拍逐句來源。樣張未讀寫localStorage，不能稱正式保存去重通過。

初輪[報告](artifacts/atm-life-design/browser-checks-initial.json)保留：early寬式圖片尚在載入時被量測為broken。增加觀察後重拍，最終圖片正常；期間嘗試在read-only DOM代理呼叫`img.decode()`不支援而TypeError，改可見狀態／截圖觀察完成後量測。沒有把失敗抹除或當成功。最終同名PNG覆蓋早期載入畫面，JSON初輪保留。

## 視覺與素材

三橫式首屏、在世寬式、800長文內捲人工目視；所有32圖另做總覽供檢視。沿既有暖紙／深墨／青玉及粗明體800／題簽900；CSS只表達共用元件方向，正式版仍用GameTab／SegmentChips／CloseSeal／UiTypography，不把CSS當Godot字寬證據。

只引用既有背景、熄滅命燈、輪迴盤及三字檔；沒有ImageGen／下載新圖。來源hash／用途／原manifest與字型授權見[provenance.json](artifacts/atm-life-design/provenance.json)。既有圖片的prompt／切層／來源保留原manifest，不重新宣稱第三方商用授權。

## 未通過項與下一步

尚待使用者接受布局、十題優先／原創文稿與保存世數；故本任務未DONE。全部事實是明示虛構fixture，沒有同一自然玩家生命的逐句證據；正式事實記錄、時序／實例驗證、封存與故障復原留LEDGER-0／ATM-LIFE-A，不冒充已有實作。F-C已接受，不重開字體選擇。

本階段停止，New Chat先收設計回饋或核定後接LEDGER-0；不在本輪自動展開下一大型任務。完整結果與英文checkpoint見入口及updata.txt。

收尾：`python tools/atm_life_design_artifacts.py` exit0（12來源、3總覽、32連結）；targeted tracked `git diff --check` exit0。新10份文字檔與新checkpoint嚴格UTF-8／尾空白檢查通過。第一次把歷史updata全文納入尾空白檢查遇既有尾空白而exit1，改只驗本輪新增區塊，不改寫歷史。初始4395服務以所屬session Ctrl+C停止（exit1為主動終止）；4396保留供審閱。
