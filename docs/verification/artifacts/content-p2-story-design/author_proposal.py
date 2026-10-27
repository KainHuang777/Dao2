"""One-time authoring source for proposal Y. Does not attach runtime content."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'docs/design-data/content-p2-story-proposal.json'
if OUT.exists() and '--replace' not in sys.argv:
    raise SystemExit('Refusing to overwrite authored proposal')

def reward(**resources):
    return {'resources': resources}

achievements = []
def achievement(id, name, category, era, condition, proof, refs, rewards, art):
    achievements.append(dict(key=f'A{len(achievements)+1:02}', id='p2_'+id, name=name,
        category=category, era=era, condition=condition, proof=proof, refs=refs,
        rewards=rewards, art=art, lifetime_once=True))

achievement('deep_student','寒脈入微','cultivation',4,'當世寒脈共鳴訣至少一階。','snapshot',['deep_vein_resonance'],reward(lingli=300),'銀色礦脈環抱一枚初生道芽')
achievement('herb_student','古藥通神','cultivation',5,'當世古藥養靈術、神海納息訣各至少一階。','snapshot',['ancient_herb_attunement','spirit_sea_breath'],reward(lingli=500),'古藥根鬚與神海水紋交織')
achievement('void_storekeeper','三島藏真','cultivation',6,'當世太虛採元術、三島藏真法各至少一階。','snapshot',['void_essence_attunement','frontier_storekeeping'],reward(lingli=800),'三枚浮島玉印圍繞虛空露珠')
achievement('deep_arrivals','寒銀三舸','abode',4,'更新後三條寒銀航線均曾向祖島實際入庫正數，可跨世。','arrival_mask=7',['deep_iron_home','deep_mithril_home','deep_cold_home'],reward(stone_low=120),'三艘載有不同礦石的小舟')
achievement('ancient_arrival','千草歸倉','abode',5,'更新後古藥千草航線曾向祖島實際入庫正數。','arrival_mask&8',['ancient_grass_home'],reward(spirit_grass_low=100),'草束與靠岸貨舟')
achievement('void_arrival','虛華歸匣','abode',6,'更新後太虛虛華航線曾向祖島實際入庫正數。','arrival_mask&16',['void_essence_home'],reward(stone_low=200),'盛有紫色虛華的開口木匣')
achievement('training_alchemist','嬰虛雙爐','alchemy',6,'更新後親煉凝嬰丹、虛明丹各一次，可跨世；交易取得不算。','refined_mask&3=3',['nascent_breath_pill','void_meditation_pill'],reward(spirit_grass_low=120),'兩爐分映嬰形與空明丹光')
achievement('local_elixirs','藥引雙島','alchemy',6,'更新後成功服用古藥凝露丹、太虛聚華丹各一次，可跨世。','consumed_mask&12=12',['ancient_herb_dew_pill','void_gathering_pill'],reward(lingli=600),'青綠藥露與紫色浮島相映')
achievement('vessels_and_wards','藏器護劫','alchemy',5,'更新後成功服用靈府拓容丹、藏石丹、定心護劫丹、銀罡護劫丹各一次，可跨世。','consumed_mask&240=240',['spirit_vessel_pill','stone_vault_pill','calm_tribulation_pill','silver_ward_pill'],reward(stone_low=180),'石匣與靈瓶前展開兩道護符')
achievement('frontier_commissions','三島供簿','sect',6,'更新後領取寒銀、古藥、太虛類新委託各至少一次，可跨世。','task_groups=deep+ancient+void',['deep_stock_register','ancient_dew_register','void_supply_chart'],{'sect_contribution':60},'三冊無字帳簿與宗門印')
achievement('two_sect_methods','丹獸同修','sect',6,'兩項P2宗門功法各至少一階；沿正式持久功法狀態判定。','snapshot',['p2_pill_qi_conservation','sacred_beast_feed_conservation'],{'sect_contribution':80},'丹爐與玄甲羽翎環繞雙卷')
achievement('two_reserves','備糧有度','sect',5,'更新後成功購買精鐵儲備、古藥儲備各一次，可跨世。','market_mask=3',['refined_iron_reserve','ancient_herb_reserve'],{'sect_contribution':40},'鐵錠與一束古藥置於小秤兩端')
achievement('mature_stag','霜角長伴','beast_fate',4,'現有成熟霜角鹿，或更新後曾養成成熟霜角鹿。','mature_mask&1',['frost_stag'],reward(spirit_grass_low=100),'霜角鹿側首與銀白角枝')
achievement('mature_crane','銜芝長伴','beast_fate',5,'現有成熟銜芝鶴，或更新後曾養成成熟銜芝鶴。','mature_mask&2',['herb_crane'],reward(spirit_grass_low=100),'銜芝鶴展翼護住靈芝')
achievement('turtle_and_phoenix','玄羽兩世','beast_fate',6,'更新後分世養成成熟玄龜、火鳳；導入時只可補記當前成熟的一隻。','mature_mask&12=12',['iron_turtle','fire_phoenix'],reward(lingli=800),'玄甲與火羽分置陰陽兩側')
achievement('second_nascent','再證元嬰','reincarnation',4,'至少輪迴一次，且當世Era至少4；最高歷史境界不能代替當世。','snapshot',[],reward(wood=160),'舊命燈旁再生一枚元嬰道芽')
achievement('second_void','重履太虛','reincarnation',6,'至少輪迴一次，且當世Era至少6。','snapshot',[],reward(lingli=1000),'新舊兩道足跡穿過紫色雲門')
achievement('three_memories','三慧續道','reincarnation',4,'丹材、拓脈、玄靈宿慧各至少一階。','snapshot',['elixir_conservation_memory','frontier_prospector_memory','sacred_beast_nurture_memory'],reward(stone_low=200),'三枚不同色澤的宿慧玉珠')

events = []
def event(id,title,desc,group,era,requires,art,a,b,tradeoff):
    options=[]
    for text,costs,rewards,log in [a,b,('拱手辭行',{}, {},f'你謝過對方，未取分毫，將「{title}」留在身後。')]:
        options.append(dict(text=text,costs=costs,rewards={**rewards,'log_text':log}))
    events.append(dict(key=f'E{len(events)+1:02}',id='enc_p2_'+id,title=title,desc=desc,group=group,
        min_era=era,requires=requires,art=art,weight=60,content_batch='content-p2-story',
        definition_version=1,weather_bias='',shichen_bias='',realm_bias='',options=options,tradeoff=tradeoff))

event('silver_scale','寒銀換秤','寒銀島歸舟靠岸，一名礦師攤開兩副小秤。他願用精鐵換取靈石，也願收下你手中的精鐵，價碼寫在無字刻痕旁。','resources',4,['deep_open'],'frontier',
 ('以靈石換三塊精鐵',{'stone_low':80},reward(refined_iron=3),'你付出八十下品靈石，換得精鐵三塊。'),
 ('售出兩塊精鐵',{'refined_iron':2},reward(stone_low=40),'你交出兩塊精鐵，收下四十下品靈石。'),
 '買3鐵需80石、賣2鐵得40石，往返不能增殖；原始地方採3鐵30秒，不含回運。')
event('cold_assay','寒鐵試紋','老匠用銀針劃過寒鐵，說這一爐只差一種礦材。你可補上寒鐵換秘銀，也可拿秘銀換回較多的寒鐵。','resources',4,['deep_open'],'frontier',
 ('交寒鐵換秘銀',{'cold_iron':4},reward(mithril=2),'四塊寒鐵換得兩塊秘銀，銀針上的紋路漸漸平息。'),
 ('交秘銀換寒鐵',{'mithril':3},reward(cold_iron=4),'你交出三塊秘銀，收下四塊寒鐵。'),
 '等裸產率0.05/s；A讓出80秒寒鐵換40秒秘銀，B讓出60秒秘銀換80秒寒鐵；A+B淨少1秘銀。')
event('dew_exchange','古藥餘露','藥客正在分裝凝在葉背的餘露。千年草稀少，百年草卻正缺一批；他邀你按眼前用途交換。','resources',5,['ancient_open'],'herbarium',
 ('以百年草換千年草',{'spirit_grass_100y':12},reward(spirit_grass_1000y=1),'十二株百年草換回一株千年草。'),
 ('以千年草換百年草',{'spirit_grass_1000y':1},reward(spirit_grass_100y=8),'你留出一株千年草，換得八株百年草。'),
 '往返少4百草；1千草裸採25秒，交換省回運等候但消耗另一鏈材料。')
event('bulk_stone','碎石封舟','貨舟騰出一格空艙，船家正把碎石分裝成堆。若你願提供足量石料與靈力，他便直接交出已煉好的中品靈石。','industry',4,['deep_open','deep_arrived'],'industry',
 ('託船家代煉一小堆',{'stone_low':60,'lingli':150},reward(stone_mid=10),'船家收妥六十下品靈石與一百五十靈力，交回十枚中品靈石。'),
 ('拆售十枚中品靈石',{'stone_mid':10},reward(stone_low=40),'你將十枚中品靈石交付，收回四十下品靈石。'),
 '正式批量100中石需500下石+1000靈力/10秒，A單位更貴且不受天工折扣；B回收損失石與原煉製靈力。')
event('high_stone','上石分盞','上品靈石的冷光照著船艙。船家願讓出一枚整石，也能把你的整石換成幾枚可立即使用的中石。','industry',5,['ancient_open','ancient_arrived'],'industry',
 ('換取一枚整石',{'stone_mid':4,'lingli':70},reward(stone_high=1),'你以四枚中品靈石與七十靈力換得一枚上品靈石。'),
 ('拆換一枚整石',{'stone_high':1},reward(stone_mid=2),'一枚上品靈石換回兩枚中品靈石。'),
 '正式1上石需3中石+50靈力/10秒，A較貴，B有耗損；不增加配方完工旗標。')
event('void_cargo','虛華壓艙','太虛歸舟的舷側泛起紫光。押艙人不願多留這團輕若無物的精華，願換取穩定的上品靈石。','industry',6,['void_open','void_arrived'],'frontier',
 ('用上石換虛華',{'stone_high':2},reward(void_essence=2),'兩枚上品靈石換來兩縷虛空精華。'),
 ('交虛華換上石',{'void_essence':3},reward(stone_high=1),'你封存三縷虛空精華，換得一枚上品靈石。'),
 '虛華裸採2份40秒／3份60秒；A+B淨少1上石及1虛華，不把不同資源相加當回本。')
event('sect_iron','宗門餘鐵','執事合上新一輪供給簿，桌上還留有少量鐵料。他只接受物資交換，這筆往來不算委託，也不添貢獻。','sect',4,['deep_open','joined_sect','p2_task_claimed'],'sect',
 ('補靈石領餘鐵',{'stone_low':100},reward(refined_iron=4),'你付出一百下品靈石，領回四塊餘鐵。'),
 ('歸還鐵料換草',{'refined_iron':3},reward(spirit_grass_low=40),'你歸還三塊鐵料，換回四十株低階靈草。'),
 '不扣貢獻、不改限購餘次；與有限坊市及免費等待委託相比，多一條隨機且有價交換。')
event('sect_herbs','藥房兩籃','藥房管事把百年草與千年草分成兩籃，問你這次更缺哪一籃。這不是新的派遣，須由你自行決定取捨。','sect',5,['ancient_open','joined_sect','p2_task_claimed'],'sect',
 ('用下石換一株千草',{'stone_low':160},reward(spirit_grass_1000y=1),'你付出一百六十下品靈石，取走一株千年靈草。'),
 ('交千草補百草',{'spirit_grass_1000y':2},reward(spirit_grass_100y=18),'兩株千年靈草換回十八株百年靈草。'),
 'B每千草換9百草，高於E03的8但只在入宗且本世已領P2委託後可遇；不當普遍最優或新增限購。')
event('sect_chart','太虛圖角','供給圖的一角被風吹起，露出押圖人的備用材料。他願用一點虛華交換祖島靈力，或反向收購。','sect',6,['void_open','joined_sect','p2_task_claimed'],'sect',
 ('以靈力換虛華',{'lingli':1500},reward(void_essence=1),'一千五百靈力換得一縷虛空精華。'),
 ('以虛華換靈力',{'void_essence':2},reward(lingli=1000),'你交出兩縷虛空精華，收回一千靈力。'),
 'A換50秒裸採，B犧牲40秒裸採；靈力實際產率隨建築變，往返淨少500靈力及1虛華。')
event('pill_fire','丹房借火','一名丹師守著將熄的爐火，願用片刻調息所得換取燃料。爐中沒有可供領取的丹藥，只有一份明確的修煉助益。','alchemy',4,['deep_open','p2_refined'],'sect',
 ('添靈力借火調息',{'lingli':600},{'training_seconds':60},'你添入六百靈力，在爐旁調息六十秒所對應的修煉進度。'),
 ('添百年草細察丹息',{'spirit_grass_100y':2},{'training_seconds':90},'你付出兩株百年草，參得九十秒所對應的修煉進度。'),
 '比較等待60/90秒零材料，或凝嬰丹900秒後共享衰減；事件固定助益不吃丹心、不佔丹藥衰減，不縮壽元與冷卻。')
event('herb_residue','藥渣留香','古藥丹的餘香尚未散盡，丹師請你挑一包材料回去補爐。你得先拿出自己的草藥，不能把這當成親煉。','alchemy',5,['ancient_open','p2_consumed'],'herbarium',
 ('以千草換靈力',{'spirit_grass_1000y':1},reward(lingli=600),'你交出一株千年草，獲得六百靈力。'),
 ('用靈力補兩株百草',{'lingli':800},reward(spirit_grass_100y=2),'你付出八百靈力，補得兩株百年草。'),
 '材料交易不贈丹、不設親煉或服丹bit，不觸發容量丹或護劫次數；A耗千草，B耗800靈力。')
event('ward_scraps','雷前餘箋','遠空雷聲漸近，修士將用過的護符收起，只留下幾張可供參詳的餘箋。他明言這份心得不能替你抵擋天劫。','alchemy',6,['void_open','deep_open','p2_consumed'],'ruins',
 ('以寒鐵換調息心得',{'cold_iron':2},{'training_seconds':120},'你交出兩塊寒鐵，獲得一百二十秒所對應的修煉進度，未增加護劫機率。'),
 ('以靈力換留存銀屑',{'lingli':900},reward(mithril=1),'九百靈力換得一塊秘銀，沒有附帶護劫效果。'),
 'A換120秒等待但耗40秒寒鐵裸採；B換20秒秘銀裸採；不給護劫百分點或保證突破。')
event('stag_shed','霜角落屑','霜角鹿在石旁磨去一點角屑，礦師稱可用它指認礦紋。鹿仍留在你身邊，不會因交換再次成長。','beast',4,['deep_open','active_stag'],'beast',
 ('用草請礦師辨鐵',{'spirit_grass_low':30},reward(refined_iron=2),'三十株低階靈草換回兩塊精鐵；霜角鹿未獲餵養經驗。'),
 ('用精鐵換草',{'refined_iron':2},reward(spirit_grass_low=20),'你留下兩塊精鐵，收回二十株低階靈草。'),
 'A+B少10草；不扣餵養冷卻、不加XP、不給魂；鹿正式每餵10鐵+20草，不能以交易冒充實餵。')
event('crane_herb','鶴喙遺芝','銜芝鶴停在藥籃旁，一名藥師循著它的目光認出草藥年份。你可付費請他分揀，鶴卻不會代你吞服。','beast',5,['ancient_open','active_crane'],'beast',
 ('以靈力請藥師分揀',{'lingli':1000},reward(spirit_grass_1000y=1),'你付出一千靈力，分得一株千年草；鶴的經驗不變。'),
 ('拿百草換一株千草',{'spirit_grass_100y':10},reward(spirit_grass_1000y=1),'十株百年草換得一株千年草，仍須自行餵養。'),
 '較E03便宜但限定當世鶴；與直接等待25秒裸採及運輸相比不保證划算；不受鶴餵費折扣。')
event('phoenix_ember','鳳羽留溫','火鳳落羽的餘溫尚在，過路修士想借這點暖意煉息。他只談物資，沒有收取獸魂的法門。','beast',6,['ancient_open','active_phoenix'],'beast',
 ('付千草換取煉息所得',{'spirit_grass_1000y':2},reward(lingli=1600),'兩株千年草換回一千六百靈力，火鳳仍需另行餵養。'),
 ('付靈力補一株千草',{'lingli':1200},reward(spirit_grass_1000y=1),'你付出一千二百靈力，補得一株千年草。'),
 '兩次B再A淨少800靈力；玄靈宿慧及宗門餵費折扣均不作用本交易，無鳳則不能生成。')
event('old_mark','前世礦記','舊石壁上的刻痕似曾相識。同行者請你以材料驗證礦記，也願用自己的一點積蓄換下你不急用的材料。','reincarnation',4,['deep_open','second_life'],'ruins',
 ('耗秘銀參詳舊記',{'mithril':1},{'training_seconds':90},'你用一塊秘銀驗明刻痕，得到九十秒所對應的修煉進度。'),
 ('以木材補靈石',{'wood':80},reward(stone_low=60),'八十靈木換回六十下品靈石，舊記沒有留下新天賦。'),
 'A消耗秘銀而非道心換90秒等待，B木石互換；不發跨世本金、不保留技能。')
event('memory_garden','宿慧藥圃','你在荒圃邊認出一段前世手法，園主人願拿靈力交換這次整理藥草的材料。記憶只幫你選擇，不憑空生出藥材。','reincarnation',5,['ancient_open','second_life','any_p2_talent'],'herbarium',
 ('付百草換靈力',{'spirit_grass_100y':3},reward(lingli=300),'三株百年草換得三百靈力。'),
 ('付靈力補百草',{'lingli':1000},reward(spirit_grass_100y=2),'一千靈力換回兩株百年草，未增加宿慧階數。'),
 '不把天賦倍率套在交易；A對B往返同尺度耗損，與自產/等待比較，無新增永久加成。')
event('returning_echo','重訪虛渡','太虛渡口的老人說，你這次的腳步比上一世沉穩。他願用自己收藏的一點物資交換你此刻的選擇，卻不能替你走完下一世。','reincarnation',6,['void_open','second_life','any_p2_talent'],'ruins',
 ('耗虛華參悟歸途',{'void_essence':2},{'training_seconds':180},'你放開兩縷虛空精華，換得一百八十秒所對應的修煉進度。'),
 ('以中石補祖島靈力',{'stone_mid':20},reward(lingli=1200),'二十枚中品靈石換回一千二百靈力，沒有額外道心或道證。'),
 'A耗40秒虛華裸採換180秒當級缺口；B耗20中石（正式批量基準100下石+200靈力，實際仍按完整批次），不增壽元。')

proposal=dict(task='CONTENT-P2-STORY',date='2026-10-27',scheme='Y',approval='PENDING',
    status='DESIGN_DONE_IMPLEMENTATION_TODO',runtime_attached=False,origin='Original v2 design; not legacy parity',
    baseline={'achievements':30,'encounters':38},target={'achievements':48,'encounters':56},
    policy={'realm':'realm_human','schema_version':5,'story_version':2,'rules_proposal':'core-flow-24-content-p2-story',
        'encounter_weight':60,'no_max_era':True,'no_new_dao_heart_or_proof':True,'resource_scope':'home available inventory; never local/cargo/reserved',
        'capacity':'Whole transaction after payment; reject partial fit or unrepresentable Amount; free departure always available',
        'pending':'Freeze full definition/digest/qualification/instance at generation; preserve legacy and P1 pending',
        'rng':'Keep fortune rng_version=1 and saved stream; one roll only on generation; no reward RNG',
        'save_gate':'Archive original bytes and read back before candidate commit; failed retry saves same candidate only',
        'byte_limits':{'story':4096,'achievements':16384,'pending':12288},
        'art':{'new_badges':18,'new_vignettes':['frontier','herbarium'],'generated':False,'accepted':False}},
    facts={'p2_pill_order':['nascent_breath_pill','void_meditation_pill','ancient_herb_dew_pill','void_gathering_pill','spirit_vessel_pill','stone_vault_pill','calm_tribulation_pill','silver_ward_pill'],
        'arrival_order':['deep_iron_home','deep_mithril_home','deep_cold_home','ancient_grass_home','void_essence_home'],
        'task_order':['deep_stock_register','ancient_dew_register','silver_convoy_accounts','ancient_herb_sorting','cold_iron_assay','ancient_pill_herb_catalog','void_supply_chart','tribulation_material_check','turtle_nursery_reserve','phoenix_nursery_reserve'],
        'market_order':['refined_iron_reserve','ancient_herb_reserve'],
        'mature_order':['frost_stag','herb_crane','iron_turtle','fire_phoenix'],
        'masks':{'refined_mask':255,'consumed_mask':255,'arrival_mask':31,'task_mask':1023,'market_mask':3,'mature_mask':15}},
    achievements=achievements,encounters=events)
prompt_base = 'Original Chinese xianxia game illustration, painterly ink and gouache, elegant restrained jade and warm gold palette, clean readable silhouette, centered complete isolated subject, generous transparent safety margin, RGBA transparent background, no text, letters, numerals, UI, watermark or logo. '
proposal['art_assets'] = [dict(id=a['id'],kind='badge',subject=a['art'],prompt=prompt_base+'Unique detailed antique gold rim achievement medallion: '+a['art'],layers='One flattened RGBA badge; frame included; external background transparent',runtime_path='TBD after generation',source='Planned built-in ImageGen; not generated',license='Record generation provenance; no third-party commercial license asserted',acceptance='PENDING') for a in achievements]
for id,subject in [('frontier','A small returning cargo boat, silver ore samples and a violet essence lantern, floating frontier landscape suggested only inside the isolated vignette'),('herbarium','An old herbalists basket of ancient green herbs, dew drops and a small ceramic sorting tray')]:
    proposal['art_assets'].append(dict(id=id,kind='vignette',subject=subject,prompt=prompt_base+subject,layers='One flattened RGBA vignette; no world background layer',runtime_path='TBD after generation',source='Planned built-in ImageGen; not generated',license='Record generation provenance; no third-party commercial license asserted',acceptance='PENDING'))
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text(json.dumps(proposal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Authored {len(achievements)} achievements / {len(events)} encounters / {sum(len(e["options"]) for e in events)} options')
