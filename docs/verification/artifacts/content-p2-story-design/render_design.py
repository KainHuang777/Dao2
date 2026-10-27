"""Render the review document from authored proposal plus explicit contracts."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[4]
p=json.loads((ROOT/'docs/design-data/content-p2-story-proposal.json').read_text(encoding='utf-8'))
doc='''# CONTENT-P2-STORY：成就／機緣逐項設計（方案 Y）

2026-10-27。**設計階段 DONE；Y1／Y2／Y-save／Y-art 待核定；實作 TODO，整批 IN_PROGRESS。**

使用者指定「P2 成就／機緣」。依 [內容擴充計畫](25-system-content-expansion-plan.md) 先交逐項規則與核定表。P2 供給、技能、天賦、丹藥、宗門與靈獸均已分批收結；沿其已核定數值。這是原創 v2 提案，不是舊版公式、正式附掛或自然流程驗收。完整機讀原稿與20項提示詞見 [proposal](design-data/content-p2-story-proposal.json)；[L1驗收](verification/content-p2-story-design.md) 記錄本輪命令與界線。

## 1. 交付與來源事實

正式目前30成就／38機緣；本批新增18／18，目標48／56，每則三分支共54。成就六類各3；機緣按物資、加工航運、宗門、丹道、靈獸、輪迴各3。P2只引用已存在的Era4–6，不開Era7、不開九界，不新增法令、世界地標、獸種或永久倍率。事件無最高Era限制，但只在人界生成；最高歷史境界不代替當世境界。

| 權威入口 | 現況及本案限制 |
| --- | --- |
| `src/simulation/achievement_system.gd` | 18 legacy＋12 P1；新18全為終身一次，不增道心、道證、魂或技能點。原30 ID／已領旗標保持 |
| `src/simulation/story_progress.gd` | VERSION=1；僅P1加工／到貨／四丹／狐旗標。不能拿舊庫存、帳本截片或總服丹數推斷P2歷史 |
| `content/encounters/encounters.json`／`fortune_system.gd` | 正式38題；P1專用前置、凍結與整筆付款分支只認 `enc_p1_`／`content-p1-story`，不能直接附加JSON即宣稱完成 |
| `src/persistence/story_save_contract.gd` | 現定義限制Era≤3、基礎資源、P1丹、固定art白名單及story v1。Y必須明確擴版本及有限白名單，舊分支仍驗原契約 |
| `content/supply/era4_6.json` | 7資源、5回運航線、3配方、三島正式供給；使用祖島可用庫存，不從地方或在途取料 |
| `content/skills/era4_6.json`；alchemy／sect／beast／talent systems | 所有引用ID按當前來源稽核；兩新獸及龜鳳單世互斥。玄龜Era4、鶴Era5、火鳳Era6；不加入尚未可玩雲蛟鏈 |
| `save_codec.gd`／`game_state.gd` | 正式schema5、story1、rules core-flow-23-content-p2-beasts。新版本提案見Y-save，實作前重查占用 |

## 2. Y1：十八成就

下表era為最早可能達成境界。snapshot在導入／成功命令後讀正式狀態；行為mask只認更新後成功提交。達成後永久解鎖，後世可領基本補給；不因低境重開而重領，領取仍驗容量。解鎖時間沿P1零哨兵，不能捏造歷史達成時間。常駐卡只顯示題名、獎勵與必要狀態；條件留既有可讀入口。

| ID／名稱 | 類別／最早Era | 條件與證據 | 獎勵 | 徽章題材 |
| --- | --- | --- | --- | --- |
'''
names={'lingli':'靈力','money':'金錢','wood':'靈木','stone_low':'下品靈石','stone_mid':'中品靈石','stone_high':'上品靈石','spirit_grass_low':'低階靈草','spirit_grass_100y':'百年靈草','spirit_grass_1000y':'千年靈草','refined_iron':'精鐵','cold_iron':'寒鐵','mithril':'秘銀','void_essence':'虛空精華'}
def amounts(data):
    return '、'.join(names.get(k,k)+' '+str(v) for k,v in data.items()) or '無'
def rewards(r):
    pieces=[]
    if r.get('resources'): pieces.append(amounts(r['resources']))
    if r.get('sect_contribution'): pieces.append('貢獻 '+str(r['sect_contribution']))
    if r.get('training_seconds'): pieces.append('當級修煉進度 '+str(r['training_seconds'])+'秒')
    return '；'.join(pieces) or '無數值收益'
for a in p['achievements']:
    doc+=f"| {a['key']} `{a['id']}` {a['name']} | {a['category']}／{a['era']} | {a['condition']}（`{a['proof']}`） | {rewards(a['rewards'])} | {a['art']} |\n"
doc+='''
本批一次性總獎勵為靈力4000、下石700、低階草420、木160、貢獻180；不相加不同單位。較Era4–6每次修行靈力與物料需求只是補給，不支撐主線必需容量或開島成本；滿倉可延領。A15需龜、鳳兩個生命週期；同時拿A13／14／15至少四個不同持獸世，導入既有成熟獸至多抵一種，不宣稱一世全成就。A10三組委託也非保證刷新時間；A18三天賦首階共30道心，會失去這30點持有加成，沿U方案機會成本，不送補償道心。

## 3. Y2：十八機緣與完整選文

共同資格：story2、已保存的新內容候選、人界、當世至少表列Era、正式P2供給已接。`*_open`讀當世已開島；`*_arrived`讀本世指定航線實際入庫正數；`joined_sect`讀非空current_sect；`p2_task_claimed`／`p2_refined`／`p2_consumed`讀本世P2 mask非0；`second_life`為輪迴次數≥1；`any_p2_talent`為U三項至少一項≥1。active_stag／crane／phoenix讀實際活動獸ID，不要求成熟，不看終身成熟mask。沒有付款能力不阻止生成，提交再驗成本；C永遠可免費離開。

每題權重60、三bias皆空；維持舊Era每小時次數與單一待決，無保底／額外擲骰。A／B成本均固定，不套煉丹／天賦／宗門／餵費折扣；交易所得不設親煉、服丹、回運、委託、坊市或餵養旗標。所有高階產物先要求其來源島已開；不贈丹、不自動服丹、不改永久能力。

'''
for e in p['encounters']:
    doc+=f"### {e['key']} {e['title']} — `{e['id']}`\n\n{e['desc']}\n\nEra≥{e['min_era']}；額外資格：`{' + '.join(e['requires'])}`；題圖 `{e['art']}`。\n\n| 選項 | 祖島固定代價 | 固定結果 | 結果文稿 |\n| --- | --- | --- | --- |\n"
    for label,o in zip('ABC',e['options']):
        doc+=f"| {label} {o['text']} | {amounts(o['costs'])} | {rewards(o['rewards'])} | {o['rewards']['log_text']} |\n"
    doc+='\n取捨／正式替代：'+e['tradeoff']+'\n\n'
doc+='''## 4. 節奏與機會成本

物料秒數只按無技能／天賦／獸／丹／調度的裸地方率；未計回運、堵塞、滿倉或已有資源，不能當自然取得耗時。正式自煉可受折扣，機緣交易固定費，因此E04／05買成品通常更貴；隨機相遇不是主線穩定供給。跨事件反向兌換亦須檢查，不能只驗同題A／B；本案將E07B定為3鐵換40草，避免與E13A的30草換2鐵形成增殖。L1稽核枚舉單輸入單輸出資源閉環，以Fraction精確驗倍率≤1；此檢查不等於含多原料／正式配方的全經濟無套利證明。

E10／12／16／18的60–180秒助益與P1固定機緣相同屬當級修煉秒數，**不是快轉世界時間**：不增加年歲、不轉冷卻、不產資源、不加速派遣／物流、不改突破成功率。先要求活著且仍有當級缺口；實得=min(名義秒數,缺口)，餘額明示捨棄，零實得時在付款前拒絕。不跨級、自動晉階或觸發丹藥共享衰減；不乘丹心收益。無材料替代是等待同樣秒數；付費助益僅供選擇。

權重算表由 [audit.json](verification/artifacts/content-p2-story-design/audit.json) 輸出。假設人界、空嚮往、中性時辰／天候，已具所有當境可共存行為旗標；逐Era／世次／單一獸分列，P1靈狐題也受同一活動獸限制。對指定新題：p=60/(舊有效權重+60×當前新題數)，平均機會數=1/p，平均小時=1/(p×Era)。這是假設固定池且每次立即決策的幾何期望，沒有最長等候保證，不是自然命中證據；實際閱讀、資格與天候會改變機會。Era≤3新18題全部不入池，P1早期池保持。

## 5. Y-save：版本與有限事實

提案schema5保持、story_version由1→2，rules `core-flow-24-content-p2-story`、content identity新增實際成就／機緣定義hash及`+content-p2-story`；版本號實作前重查。其他economy／skill／talent／pill／sect／beast子版本保持既有值。SaveCodec的rules優先須能辨認story2，同時保留獸／宗門等版本契約，不能因新增分支遮掉舊子版本驗證。

保留P1的全部鍵、mask範圍、起點與語意；`achievements.story.version=2`擴一個固定`p2`物件，內含started_life_id、started_age_seconds、lifetime、current。原story.current_life_id仍是唯一當世ID。兩份p2 facts皆只含以下六mask，位序完整列於JSON：

| mask | 位序／上限 | 寫入事件 |
| --- | --- | --- |
| refined_mask | P2八丹固定順序／255 | 正式煉製成功；交易成品不算 |
| consumed_mask | 同八丹／255 | 正式服丹成功且實際生效；護劫拒服／淨延拒服不算 |
| arrival_mask | 5條新航線／31 | 到祖島實際入庫delta>0；滿倉全棄、名義貨物、事件交易不算 |
| task_mask | 10模板順序／1023 | 正式委託領獎成功，不是派遣或倒數完成 |
| market_mask | 精鐵儲備／古藥儲備／3 | 正式坊市交易成功；不能重扣限購次數 |
| mature_mask | 鹿／鶴／龜／鳳／15 | 活動獸正式轉成熟；舊檔導入可證明當前成熟的單隻可補記 |

A10群組：deep=bit0／2／4／7／8任一；ancient=bit1／3／5／9任一；void=bit6。bit7護劫備材屬寒銀，不誤列太虛。三群可跨世，不能把任意三筆委託湊成三島。每次成功提交先設lifetime與current，再檢查解鎖；到貨的在線與離線／準備快取分支共用觀測點。正式輪迴封存後清current，lifetime／unlocked／claimed保留；起點不重寫，成熟即設bit但不發魂。debug重置需明訂同清新旗標以符合原全成就重置用途，不改玩家正常輪迴規則。

有限嚴格驗證：story≤4KiB、achievements≤16KiB、pending≤12KiB UTF-8；不得為18項直接加大額度。固定鍵、有限非負age、合理life_id、int mask（可正規化JSON整值數字，拒bool／小數／負值／超界）、current必為lifetime子集合；起點不晚於當世且同世age≤目前年歲。未來版本／未知p2 ID／未知mask鍵／偽digest／偽型別均拒讀、保留原文；舊stats不授權新行為。新增claimed必為bool，unlocked為有限非負哨兵；v0／v1攜帶P2旗標或pending直接拒讀，不能用缺版本繞過。

v0→v2仍需完成原P1的合法補欄及RNG初始化；v1→v2保留P1事實與RNG原值，P2行為清0，snapshot只讀現在可證的條件。舊庫存、魂、天賦、總服丹量、限購累計或封存截片均不補造新行為；只有當前成熟獸允許上述補記。舊30成就已領原樣保留。v2首次attach／load／import前先將原JSON逐字以hash命名歸檔並讀回，再提交同份候選；任何原文、讀回、主槽、索引故障保留舊槽並鎖住命令及線上／離線游標。沿既有story原文／candidate閘擴為v2，不另建互相覆蓋的遷移通道；其他子系統待保存原文亦不得互蓋。再次匯入不得換掉待保存候選。

原legacy與P1待決完整文稿、instance、digest、資格摘要保留，按各自原definition_version驗證，不重抽／重寫新選項；新P2使用獨立content_batch與definition_version=1，資格摘要只含固定白名單bool，generation_era／realm及完整定義凍結。擴ContentLoader、FortuneSystem、StorySaveContract全部明確分流P1／P2，不能只把VERSION等號改成2而讓P1失效。獨立fortune RNG仍v1，UI開關／暫收／保存／重載／重試不消耗序列；擴池後同seed選題可改變，已待決不得改變。

所有新成就與54分支透過正式Session命令。提交先檢查現在缺料、壽盡、容量、可表達Amount；全部費用／收益以Amount對帳，after=before-paid+gain，扣除在途預留容量。正數實際變化不可表示時拒絕，不許付0得獎。新高階資源須用IslandEconomy同一home_cap／available／reserved權威接口，避免直接套基礎Production cap把合法3000庫存誤判0，或繞過預留。物料不夠、部分可裝、丹藥型別／未知key皆整筆拒絕；claimed／pending／bits／RNG不動。C零交易不受已超容量限制。沿DecisionReceipt v1分項付款／實得／捨棄、ResourceLedger achievement／fortune來源與既有8件／16KiB、九世／352KiB封存限額，不另存全量敘事。

成功後保存失敗保持同份回執與pending結算結果，重試只保存，不重扣料／重發／重抽。跨重啟僅承諾已合法落盤槽；雙槽損壞／未來版本不得自動覆寫。新統計不依Node、畫面或動畫。所有測試均用隔離資料。

## 6. Y-art 與呈現

計畫18張獨立金框徽章＋2張透明題圖frontier／herbarium，共20張，完整提示詞、題材、用途、單層RGBA／來源與待接受metadata在JSON。其餘industry／sect／beast／ruins沿現有已接受題圖與manifest。核定製作計畫後才由內建ImageGen生成，保留原圖／runtime／hash與授權紀錄；本輪未生成、未美術接受，不宣稱第三方商用授權。

成就沿[07](07-responsive-ui-web-spec.md)／[19](19-ui-ux-guidelines.md)的共用殼、GameTab／SegmentChips、黑體與CloseSeal；徽章128px／短式≤112px、金框沿既有免描邊例外。機緣題圖寬式256／一般112／短式64、沿B細邊柔影。成本、固定收益、精確權威TIP、44px操作、固定回饋、單區內捲與暫收／抉擇簿保留；刷新不得重建按鈕或換instance。保存保護可讀原結果、只保存重試。沒有新增共用UI規則，故不改docs19；不新增世界Node或把概念圖當場景。

## 7. 分段交付與驗收

| 階段 | 交付／DoD |
| --- | --- |
| 本設計 | Y逐ID／54文稿、固定事實、數值取捨、互斥加權算表、20提示詞、L1靜態稽核；核定前實作TODO |
| STORY-1 | 18成就／18事件、純規則與flags、ContentLoader／save v2／候選閘。L1先List選1–5支；共用時間／保存依賴超5則列理由按L2。全54成功／缺料／滿倉／付款後容量／精度／免費C／壽盡與重送，Era3排除、非人界排除、當世vs最高境界、錯獸互斥、在線離線旗標一致、四獸成熟跨世、各版本遷移與錯槽／拒寫／再試 |
| STORY-2 | 20圖與卡片正式View；合法已賺得Era4–6起點，各關鍵命令→回運／親煉／服丹／委託領取／市場／成熟→成就實領；至少自然時間觸發一則P2事件、決策保存重載。各ID合成資格測試與自然代表流程分列；不等待自然抽齊18題，不冒充全自然可達。L2單尺寸原生＋當次包1280×720真實鼠標、保存拒寫／再次重試／恢復／重載、返回 |
| 整批收尾 | 使用者接受20圖／卡片／文稿與節奏後，僅此時一次L3完整runner全尺寸、正常Web候選／壓縮／BGM、桌面三橫式。小修只補相關驗證；保留失敗原日誌，不回寫成全綠。完成後才標整批DONE |

不把設計靜態算表當正式Runner／瀏覽器證據。既有長時WebGL限制沿日期化證據保留，不在本批宣稱修復；不為設計產出日常Web候選包。

## 8. 核定表

| 代碼 | 待核定內容 | 狀態 |
| --- | --- | --- |
| Y1 | 六類各3成就、18條資格／補記政策／一次性獎勵、無新增道心道證 | 待核定 |
| Y2 | 18則全文／54分支、權重60、單獸互斥、人界資格、固定成本與零收益拒絕／免費離開 | 待核定 |
| Y-save | schema5＋story2、固定mask／4／16／12KiB、舊待決保留／原文歸檔讀回／同候選重試 | 待核定 |
| Y-art | 18新徽章＋2新題圖、既有共用呈現、完整prompt／來源紀錄 | 製作計畫待核定；實際圖未生成 |

可回覆「採Y，接STORY-1」一次核定四組，或按代碼／ID指定修訂；此句是操作提示，**不代表已收到核定**。依AGENTS Context Guard，本設計階段完成後停止，在New Chat接續同批，不開其他P2／P3。
'''
audit_path=ROOT/'docs/verification/artifacts/content-p2-story-design/audit.json'
if audit_path.exists():
    audit=json.loads(audit_path.read_text(encoding='utf-8'))
    table='\n| 情境（其餘當境資格已具） | 舊有效權重 | 新題數 | 新池合計率 | 指定新題率 | 指定題平均模擬小時 |\n| --- | ---: | ---: | ---: | ---: | ---: |\n'
    selected={(4,1,'frost_stag'),(5,1,'herb_crane'),(6,1,'fire_phoenix'),(6,2,'fire_phoenix')}
    for s in audit['pool_scenarios']:
        if (s['era'],s['life'],s['active_beast']) in selected:
            table+=f"| Era{s['era']}／第{s['life']}世／{s['active_beast']} | {s['baseline_weight']} | {s['new_count']} | {100*s['new_share']:.2f}% | {100*s['specific_probability']:.2f}% | {s['mean_hours']:.2f} |\n"
    table+='\n第二世Era6持鹿／鶴／鳳時新池最多16題，不能寫18題全資格同時存在；指定題平均約11.18模擬小時。這個低頻、跨世逐步遇見的節奏列為Y2核定內容，不隱藏等候或暗加保底。\n\n'
    doc=doc.replace('## 5. Y-save',table+'## 5. Y-save')
(ROOT/'docs/40-content-p2-story-design.md').write_text(doc,encoding='utf-8')
print('Rendered docs/40-content-p2-story-design.md')
