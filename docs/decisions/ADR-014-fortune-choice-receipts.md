# ADR-014：機緣權威收據與有界抉擇簿

日期：2026-10-22。任務 `DECISION-1`，承接 docs27 §7／§9。僅機緣；界域法令、全量資源流水、歷世卷冊與事件回聲各留原後續批次。

## 身分與待決政策

正式觸發時，以存檔內 life_id、機緣序號與內容 ID 產生 SHA256 instance_id；不消耗新 RNG。舊 pending 沒有 instance_id 時，以原生命／序號／內容 ID 推導穩定身分，讀取不寫入舊檔、不重抽。核心直接重觸發亦回傳原 pending，不替換事件。Session 與正式頁面提交所見 instance_id，過期畫面的選項拒絕為 STALE_PENDING_ENCOUNTER；原無 instance 的命令形狀仍支援。

同時一件待決、沒有到期時間。暫收只關閉原閱讀頁，原遊歷／機緣通知重開。等待只暫停下一件機緣冷卻，世界與其他操作照舊，輪迴沿原規則清除 pending。重新開啟刷新持有／需求，真正提交再驗庫存；不鎖定舊畫面的負擔能力。

## 權威收據

FortuneSystem 在成本核對通過後，於實際扣款／發放處觀測，回傳 version1 收據。包括生命、年歲、事件實例、選項與凍結原文、雜湊命令來源，資源 before／paid／nominal／gained／overflow／after，以及修煉實增、丹藥實得、BUFF 套用後剩餘／常駐。paid／gained 分開記；同資源先付20再得30不能變成淨收入10。當次餘量是歷史，並非目前庫存。

收據不改既有經濟公式或套容量規則。現有機緣資源直接入庫，不按倉庫容量截斷；一般未入庫為0。Amount 支援邊界及精度保持，數字未能改變庫存時不假造扣款／入庫；未入庫亦可能是 Amount 精度限制，不可一律解讀為滿倉。對帳依原 Amount 運算契約，未承諾全量大數精確性。修煉與丹藥依原發放路徑；BUFF 用刷新後剩餘，不把標稱秒數當額外疊加。

同一收據由命令結果事件帶出，深複製寫入 LifeLedger 當世 decisions；UI 只讀，不自行算收益。原 command_receipts 與去重保護保持。保存失敗的記憶體結果只讀，重試只走原保存／背景結算，不再 resolve，不重擲。保存狀態只反映當前流程，不烘入永久歷史收據。內容 log 保留原敘事；金額以結構化收據為準。

## 版本、容量與歷史

schema5／LifeLedger version1 的生命結構新增**選填** decisions，內部 version1；原無欄位的新舊生命仍可讀，顯示未有紀錄，不能用既有 total_fortunes_claimed 補造收據。首次觀測記 started_at；不承諾該時間以前的完整覆蓋。

每世保留最近8件、每件最多8192 UTF-8 JSON bytes、整簿最多16KiB；全部包含在 ADR-013 原當世64KiB／封存32KiB／最近9世／敘事總352KiB內，不另加一份無界歷史。超限淘汰整件最舊收據，omitted 計數明示，不切 Unicode。封存凍結小傳後再次按原32KiB裁減收據，里程碑與既定小傳優先。原 command_receipts 仍有256筆上限，其原快照成本不屬敘事子樹額度；352KiB從來不是全檔或 quota 預算。

版本／欄位／型別／數值／對帳／同世／唯一實例／時間順序／byte 上限皆驗證；未知或損壞拒絕該槽，原 read_best 使用另一合法代，兩槽皆非法拒絕覆寫。JSON 往返依契約恢復數字型別。保存故障與重試沿原雙槽 readback／checksum，不跳過驗證。舊 schema2／3／4 原文備份導入沿 ADR-013；不以本子欄位宣稱支援降級到舊引擎。

`GameSession.get_decision_book(life_id=0)` 是深複製讀 API，支援當世及已保存九世；不將歷史併入每幀 HUD View。機緣頁與輪迴報告按狀態 identity＋revision 快取；前世卷冊的選世介面仍屬 REPORT-2。

## 呈現

選前固定效果副標、集中資源／丹藥／BUFF 名稱與分開契合條件沿原圖卡。抉擇簿入口用 GameTab，資料用共用黑體16與暖紙墨字，原 CloseSeal／canonical route／44px保持。短式入口在原故事標題列，內容單一內捲；輪迴報告簿在原內容內，固定收益與確認不變。保存保護層可讀當次簿與既有封存小傳，世界仍被鎖住。

命令、檔案、證據與限制見 [DECISION-1 驗收](../verification/decision-1.md)。
