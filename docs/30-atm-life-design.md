2026-10-22 **ATM-LIFE-DESIGN DONE（使用者審閱核定）**：使用者先回覆「布局OK」，再明確回覆「優先序與文稿沿用」。採用卷末一頁＋按需查記錄、十題優先與逐句文稿，正式接入任務 `ATM-LIFE-A／REPORT-1A` 開始；字體沿 F-C800／900＋文楷。容量已另行核定最近9世／352KiB，不重問。下方候選、待審閱與10世文字均保留為歷史，由本段及 ADR-013 覆蓋；設計接受不等於正式程式驗收完成。

2026-10-22 LEDGER-0容量決策：使用者核定保存「9世」，沿每世32KiB／64事件、當世64KiB，敘事子樹硬上限352KiB；取代下方5／10／20世容量候選。正式契約見[ADR-013](decisions/ADR-013-bounded-life-facts.md)。

# 一世卷末：專項設計與選文契約

2026-10-22 · `ATM-LIFE-DESIGN` · **IN_PROGRESS：設計已交付，待使用者審閱布局、選文與容量。**

本輪承接[整合規劃](27-life-report-and-decision-ux-integration-plan.md)與[共用殼樣張](29-ui-shell-design-proposal.md)，不重做已完成的 UI-SHELL-0～2。既定視角為旁觀立傳；字體沿已選 F-C：題名 Noto Serif TC 800、題簽900，小傳／卷末句文楷，數字／操作／收據黑體。以下布局、文稿與容量仍是候選；指定任務不等於接受候選。

## 審閱入口與建議

執行 `python tools/atm_life_design_server.py --port 4396`，開啟[比較頁](http://127.0.0.1:4396/index.html)。可以切十種人生樣本、三種時機、三橫式、F-B同文對照、長文與保存失敗。比較工具外層可捲；畫框內僅閱讀內容內捲，不以頁面捲軸容納遊戲UI。

**建議採「卷末一頁＋按需查記錄」及最近10世方案。** 第一批只顯生平，不設空帳目／抉擇分頁。每個題名可查為何選中、小傳每句的事實來源；沒有事件就留白，不硬湊三件留痕。閱讀不發獎、不強制完成、不自動轉世。完成設計審閱後才接 LEDGER-0 最小事實層。

| 樣張 | 1280×720 | 844×390 | 800×360 |
| --- | --- | --- | --- |
| 壽盡 F-C | [圖](verification/artifacts/atm-life-design/cloud-1280x720.png) | [圖](verification/artifacts/atm-life-design/cloud-844x390.png) | [圖](verification/artifacts/atm-life-design/cloud-800x360.png) |
| 提前預覽 | [圖](verification/artifacts/atm-life-design/early-1280x720.png) | [圖](verification/artifacts/atm-life-design/early-844x390.png) | [圖](verification/artifacts/atm-life-design/early-800x360.png) |
| 在世查看 | [圖](verification/artifacts/atm-life-design/living-1280x720.png) | [圖](verification/artifacts/atm-life-design/living-844x390.png) | [圖](verification/artifacts/atm-life-design/living-800x360.png) |
| 缺紀錄 | [圖](verification/artifacts/atm-life-design/partial-1280x720.png) | [圖](verification/artifacts/atm-life-design/partial-844x390.png) | [圖](verification/artifacts/atm-life-design/partial-800x360.png) |
| F-B同文參照 | [圖](verification/artifacts/atm-life-design/fb-1280x720.png) | [圖](verification/artifacts/atm-life-design/fb-844x390.png) | [圖](verification/artifacts/atm-life-design/fb-800x360.png) |
| 長文＋保存失敗 | [圖](verification/artifacts/atm-life-design/long-error-1280x720.png) | [圖](verification/artifacts/atm-life-design/long-error-844x390.png) | [圖](verification/artifacts/atm-life-design/long-error-800x360.png) |

專項：[逐句來源](verification/artifacts/atm-life-design/sources-844x390.png)、[頁內確認](verification/artifacts/atm-life-design/confirmation-844x390.png)、[機緣待決](verification/artifacts/atm-life-design/fortune-pending-800x360.png)、[不足禁用](verification/artifacts/atm-life-design/fortune-insufficient-800x360.png)、[收據](verification/artifacts/atm-life-design/fortune-receipt-800x360.png)。

## 時機與版面

| 時機 | 文案／終點 | 轉世與關閉 |
| --- | --- | --- |
| 壽盡 | 一世卷末、壽盡、實際年歲與終點；熄滅命燈，沿F3不加0壽元槽 | 沿既有提醒開canonical輪迴頁；等待其他報告／演出，關閉不反覆搶頁 |
| 提前轉世預覽 | 此世暫結預覽、當前年歲／境界；「此卷暫擱，待另啟新程。」 | 只有規則允許時可確認；不得寫享年／壽終；取消不封存 |
| 在世查看 | 此世行跡、當前狀態；「行跡仍在續寫。」 | 樣張主動作禁用；正式可提前轉世資格仍讀原View，不由查看模式另定新門檻 |
| 舊檔／缺紀錄 | 明示記錄開始年歲／區間及缺漏；已知終點仍可顯示 | 可正常沿原轉世規則；缺紀錄不阻塞收益或玩家保存 |

寬式：固定精簡HUD、共用GameTab與CloseSeal；左側命燈／世次／記錄覆蓋，右側題名→卷末句→小傳→查記錄→最多三件留痕；底部固定收益預覽、保留／重置與原頁內確認。正式版保留完整canonical群組與子頁，樣張的簡化導航不作刪除授權。

短式：摘要一列、題名與卷末句可換行，閱讀單區內捲。正文18px，資料16px，命中至少44px；保存異常固定於頁外，不能隨故事捲走。800×360長文＋異常時先保留操作與判詞，其他段落往下讀，不能縮字。候選斷點沿現殼寬≥960、高≥500、比例≥1.45；正式Godot仍由殼解析器與容器決定，不複製CSS常數。

關閉回原路由；切頁／離開取消確認，resize只重排、保留閱讀狀態。保存拒寫不重送轉世命令。樣張頁內確認只展示位置，完整保留／重置內容仍待正式View接入。往世只讀凍結文字；本世預覽隨已提交revision重建，讀過不代表已封存。

## 十種題名與優先序

機器可讀樣本：[cases.json](visual-prototype/atm-life-design/cases.json)。表中為**尚待新增的事實語意**，不是現有欄位承諾。只接受同一life_id、已提交結果與穩定事件排序；排除失敗命令、未保存UI草稿、HUD日誌、跨世highest_era／獸魂／成就。保存失敗但核心已提交的當次事實可供本次記憶體閱讀，持久化與重試由原Session協調。

按1→10選首個成立項；同世重開無RNG、無姓名雜湊、無文案隨機。首版每題一個文稿，先不擴充2–3個變體。新內容版本不得重寫已封存文字。

| 優先／ID | 題名 | 全部必要條件 | 不足以成立的反例 |
| --- | --- | --- | --- |
| 1 cloud | 雲外初行 | 本世築屋完成、青木／玄礦均開拓、首次結丹 | 僅已有三島或當前金丹、跨世峰值 |
| 2 after | 劫後續途 | 正式渡劫失敗，且事件排序較後仍有晉階 | 命令ok=true、只有演出／回播、失敗前曾晉階 |
| 3 core | 丹成有記 | 本世首次結丹已提交 | 當前境界／跨世最高；終點降境不抹除確有結丹事實 |
| 4 routes | 雲路相連 | 本世青木／玄礦開拓與一筆實際到貨 | 只有航線設定、啟航或在途貨物 |
| 5 companion | 同行一程 | 本世取得靈獸，其後成熟；同一beast instance | 繼承獸魂、跨世天賦、別隻靈獸的成熟 |
| 6 sect | 山門留跡 | 本世入宗，且其後委託完成 | 派遣、計時結束動畫、未提交領取／完成狀態 |
| 7 garden | 草木成居 | 本世築屋完成與靈草圃建成 | 升級按鈕可點、只有庫存達標 |
| 8 hut | 一屋初築 | 本世首次築屋完成 | 讀到輪迴繼承的建築／debug狀態 |
| 9 quiet | 靜修有痕 | 本世有一次已提交晉階 | 累積修行時間、功滿但未晉階 |
| 10 fallback | 此世行跡 | 無以上充分已知事實 | 不寫「一生無事」「從未遇緣」；缺紀錄不等於0 |

相較docs29草案，7縮為具體靈草圃、4縮為具名兩島，避免寫一段不受條件保證的故事；9限定晉階，避免把任意修行秒數說成進境。1仍優先於2，是沿既有候選順序的選擇，不宣稱最稀有或最重要。可在審閱時把「劫後續途」調前；不由代理擅自更換已交優先序。

缺完整覆蓋也可用已知正面事實選題，並另顯覆蓋缺口；缺少某事件不得做「未發生」敘述。兜底的「卷中所存有限」只描述記錄狀態。樣本年歲取無加成容量作設計快照：煉氣80、築基200、金丹740（80＋120＋540）；正式年歲／上限仍讀Lifespan及實際加成，不硬編樣本值。

## 文稿與來源

所有小傳為本專案原創，逐句引用表中事實ID；卷末句為意境，不追加事件或替玩家評價成敗。以下17句完整存於cases.json，點「查記錄」可核對；判詞依生命狀態獨立，不由題名斷定死亡。

| 題名 | 原創小傳 | 來源 |
| --- | --- | --- |
| 雲外初行 | 初居山中，築屋修行。其後開拓青木、玄礦兩島，往來漸遠。及至結丹，山中所記又添一頁。 | hut；wood＋ore；core |
| 劫後續途 | 曾於渡劫中受挫。此後仍有晉階之記，修行未止於當日。 | failed；later，且later在後 |
| 丹成有記 | 此世曾結金丹，留下一頁修行之記。 | core |
| 雲路相連 | 先後開拓青木、玄礦兩島。航船已有貨物運抵，雲路開始承載往來。 | wood＋ore；arrival |
| 同行一程 | 此世得一靈獸。後見其長成，同行之日於此有記。 | beast；mature，同一實例 |
| 山門留跡 | 此世入宗門，留名山中。委託已有完成之記，不只一紙派遣。 | sect；quest |
| 草木成居 | 先築一屋，而後建成靈草圃。居處之外，又添一處草木之地。 | hut＋build，順序須成立；build |
| 一屋初築 | 此世有築屋之記，山中初有棲身之所。 | hut |
| 靜修有痕 | 此世修行曾進一層，留有晉階之記。 | level |
| 此世行跡 | 卷中所存有限，未有完整紀錄。 | 覆蓋缺口，不是事件 |

若築屋與靈草圃順序不成立，garden仍可成立但第一句改為「此世築屋，亦建成靈草圃。」；不能為符合文稿改事件順序。純條件樣本只盤點存在性，時序、同獸實例與提交／life過濾須在LEDGER-0／正式選文驗證，不能把樣張JS當正式selector搬入遊戲。

留痕依選中主題選關鍵事實，最多三件，同類去重；缺第三件只顯一或兩件。cloud用築屋／兩島中的青木代表／結丹，查記錄仍列玄礦；正式版可合併「兩島開拓」一件並保留雙事件ref。不以庫存推職業，不以消耗判後悔，不寫無來源的關係或心境。

## 待決機緣：現況與採用契約

靜態盤點來源：`src/simulation/fortune_system.gd`、`src/simulation/reincarnation_rules.gd`、`src/presentation/fortune_modal.gd`、`src/application/game_session.gd`。本輪沒有改正式來源。

現況：fortune字典只有一個pending_encounter；advance_time有pending就不減下一次冷卻，未見到期欄位；暫收UI不清pending，核心resolve重驗成本；轉世明確清pending並重置冷卻。核心resolve清pending後只回log與標稱rewards，沒有完整實得／截斷／餘量／穩定實例收據。UI現有JSON.stringify(pending)只供顯示刷新身分，不可當未來跨世交易ID。

| 流程 | 契約候選與下一批責任 |
| --- | --- |
| 稍後查看／關閉 | 同一pending保留；下一機緣冷卻暫停，世界其他時間不額外凍結；不加倒數或放棄判定 |
| 查資源後重開 | 返回同一事件，從最新View刷新持有／需求與禁用，提交核心再次驗證；不鎖舊價格、不重抽 |
| 選擇成功 | 只用核心已提交結果建立收據；資源、修行秒數、丹藥、BUFF分別表達，不能從rewards推實得 |
| 保存失敗 | 保留已結算收據與固定異常提示；重試只保存。原儲存保護閘門保持，不重送選擇／轉世 |
| 壽盡未決 | 不自動選擇；壽盡畫面按原規則處理，卷末最多記「尚有未決機緣」，不編造結局 |
| 正式轉世 | 清待決沿現規則；若有ID才封存「未決結束」事實，不當已完成抉擇；不新增懲罰 |
| reload／重試／離線 | 新增life ID＋pending instance ID＋settlement ID及去重，須經版本化保存／遷移；舊資料無收據明示未記錄 |

DECISION-1前先在LEDGER-0保留可擴充ID／覆蓋位置，不預建完整抉擇帳簿。樣張「雲路遇客／20靈草換10靈木」為虛構交換情境，不是新增正式事件、公式或已證明截斷為0的遊戲結果。

## 保存容量提案（待核定）

| 選項 | 最近封存世數 | 敘事資料硬上限（含當世64KiB） | 取捨 |
| --- | --- | --- | --- |
| 精簡 | 5 | 224KiB | 少量往世、較早淘汰 |
| **建議** | **10** | **384KiB** | 足夠回看；界線明確 |
| 延伸 | 20 | 704KiB | 更多歷史，重複快照成本較大 |

每個封存世含JSON鍵與UTF-8序列化文字，最多32KiB；最多64事件、每事件最多384 bytes；凍結小傳／卷末句合計最多4096 bytes，其他欄位仍計入32KiB。當世64KiB含有界事實、覆蓋、ID／去重／敘事草稿；不存每秒資源流水，不把完整經濟帳目塞進此額度。10×32＋64＝384KiB為敘事子樹上限，**不含原存檔、checksum外層、localStorage字串表示及復原副本**；不是總存檔大小／quota保證。

必要欄位候選：version、life_id、recording_started_at、coverage區間與狀態、end_state、peak（有證據才有）、events、omitted_count、title_id、content_version、frozen_text、settlement_id。實際schema版本從目前SaveCodec **schema4** 的實際狀態往前設計，不能照舊研究寫回schema2／3。

超限策略候選：48個主題關鍵槽＋16個最近事件環；首次築屋、具名島開拓、首次結丹、劫敗後進境、同獸取得成熟與宗門完成等核心事實先保留。超出槽／字節上限不得截斷半個事件或UTF-8字元；略去完整非必要事件，增加omitted_count並標partial／truncated。當世peak等有界聚合獨立更新，不能隨事件淘汰而失真。凍結文字若仍超限，改用有依據的短版／中性回退並標明缺漏，不寫半句。

第11世提交成功後才淘汰最舊封存世，保留單調life序號；提示「僅保留最近10世」，不清跨世道心／獸魂／成就等原進度。封存和道果同一候選狀態原子提交，保存失敗仍可讀本次結果，重試不二次封存／領獎。新文案版本不改舊frozen_text。

舊檔沒有記錄時以導入時刻開partial覆蓋，不倒推前半生。未知敘事版本／損壞／超限先走既有完整envelope驗證與兩代復原，禁止跳過checksum。若需丟棄可選敘事子樹，必須在驗證可信外層後經明確版本遷移、記錄原因並保留匯出途徑；不能原樣保存無界未知字典。故障與quota依原保存保護／重試，不因敘事錯誤覆寫玩家進度。

容量盤點用64個中英混合／emoji事件＋400次「修行🌙」文字做UTF-8合成樣本：24,076 bytes，在32KiB內；只是序列化預算演算，尚非SaveCodec遷移／長壽／線上離線／quota測試。LEDGER-0須驗新舊檔、拒寫復原、重試去重、截斷與最壞輸入，而後才能承諾上限。

## 驗收、決策與交接

[驗收紀錄](verification/atm-life-design.md)：32張真實桌面瀏覽器PNG，三橫式與7項樣張互動通過；最終failures=[]。8,192組候選條件有界盤點、17句來源及容量合成盤點exit0。沒有正式Godot畫面／遊戲持久化／FPS驗收聲稱。

待使用者決策：採用此卷末布局、十題優先／文稿、以及最近10世容量方案，或指出修改。字體F-C不重問。只有上述審閱通過才將ATM-LIFE-DESIGN標DONE；LEDGER-0／ATM-LIFE-A仍未開始。下一大型工作請New Chat，依本頁與updata.txt頂部接手。
