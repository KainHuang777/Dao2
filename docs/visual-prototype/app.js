/* Presentation-only prototype. No access to Godot saves or game economy. */
const $=id=>document.getElementById(id);
const realms=[
  {name:'人界',x:50,y:60.5,state:'你的起點',body:'晨霧中的茅屋仍在運轉。這裡是你的根基，也是返回任何一次遠行的起點。',fact:'現在：建設洞府，平衡修煉供給與容量。'},
  {name:'靈界',x:21,y:43,state:'已窺見',body:'懸島隨靈潮呼吸。潮汐偏向不同的供給，你可以選擇藥材據點，或調整靈石生產。',fact:'玩法提案：預備下一輪靈潮所需材料，離線仍可運作。'},
  {name:'妖界',x:80,y:43,state:'已窺見',body:'古木遮天，巨獸在林海深處行走。有限的靈獸協作位置，讓駐守產地與支援修煉形成取捨。',fact:'玩法提案：配置有限靈獸位置。'},
  {name:'冥界',x:21,y:55,state:'遠景',body:'魂燈映在墨河中。今世的積累，可能成為下一世的起點。',fact:'玩法提案：當世收益與傳承資源的交換。'},
  {name:'魔界',x:80,y:55,state:'遠景',body:'赤色熔脈流過破碎陣法。維持穩定的代價，換來短期更強的供給。',fact:'玩法提案：可預覽的維持成本，不要求準時救火。'},
  {name:'仙界',x:50,y:23,state:'遠景',body:'仙闕屹立雲海之上。你的洞府成為航路一端，有限樞紐連起跨界據點。',fact:'玩法提案：選擇據點用途與跨界供給。'},
  {name:'神界',x:22,y:30,state:'遠景',body:'碑文環繞世界。法則槽位有限，要為產出、修煉與轉換作出選擇。',fact:'玩法提案：有限法則槽，不只堆疊倍率。'},
  {name:'混沌界',x:78,y:30,state:'遠景',body:'世界尚未定形。探索前比較規則組合，再選擇適合自身修行配置的去處。',fact:'玩法提案：可預覽的世界條件與有限探索內容。'},
  {name:'太初界',x:50,y:37.25,state:'遠景',body:'有朝一日，你不只尋找洞天，也能親手塑造一方天地的法則。',fact:'遠期目標：在有限預算下創界；尚未實作。'}
];
let view='home',late=false,awake=false,qi=0,pinned='靈界',visionTimer,toastTimer,lastFocus;
const notes={home:['開局 · 0–60 秒的體驗提案','先有生活，再有天地。','點一下「引氣入體」，靈氣開始自行流轉。接著抬眼看見天門；你的第一個操作，與遙遠目標連成一條線。'],vision:['鉤子 · 首次引氣後的短演出','看見未來，記住自己的位置。','熟悉的茅屋縮為一盞燈。天門第一次出現，但它還不能通行。看完可標記嚮往的界域，隨時回到眼前的修行。'],late:['後期 · 示範狀態','每一界，帶來一個新決策。','人界與靈界示範為已建立據點。點靈界看供給與法則；其他界域仍可查看遠期差異。底部永遠保留返回洞府的入口。']};
function note(mode){const n=notes[mode];$('noteTag').textContent=n[0];$('noteTitle').textContent=n[1];$('noteBody').textContent=n[2];document.querySelectorAll('[data-mode]').forEach(b=>b.classList.toggle('active',b.dataset.mode===mode));}
function message(text){clearTimeout(toastTimer);$('toast').textContent=text;$('toast').classList.add('show');toastTimer=setTimeout(()=>$('toast').classList.remove('show'),3200);}
function change(next,lateMode=false){clearTimeout(visionTimer);closeDrawer();view=next;late=lateMode;$('game').dataset.view=next;$('homeLayer').hidden=next!=='home';$('visionLayer').hidden=next!=='vision';$('atlasLayer').hidden=next!=='atlas';$('progress').hidden=next!=='home';$('navHome').classList.toggle('selected',next==='home');$('navWorld').classList.toggle('selected',next!=='home');note(late?'late':next==='home'?'home':'vision');render();}
function render(){
 if(view==='home'){$('realmStatus').textContent='人界 · 無名山谷';$('realmTitle').textContent='練氣初境';$('statusLeft').textContent='壽元 80 年 · 示意';$('statusRight').textContent=awake?'靈氣 +1 / 秒 · 示意':'洞府尚待啟靈';$('goalTag').textContent=awake?'下一步 · 穩固修行根基':'當下 · 引第一縷靈氣';$('goalTitle').textContent=awake?'天門之外，仍有天地':'讓洞府開始呼吸';$('goalText').textContent=awake?'先建藥圃、改善供給，再準備築基。':'引氣之後，修行會自行延續。';$('metric').textContent=`${qi} / 100`;$('bar').style.width=qi+'%';$('primary').innerHTML=awake?'查看藥圃 <span>↗</span>':'引氣入體 <span>↗</span>';$('secondary').textContent=awake?`道途已記 · 嚮往${pinned}`:'眺望九界 · 道途預覽';}
 else if(view==='vision'){$('realmStatus').textContent='道途一瞬 · 演出提案';$('realmTitle').textContent='天外一瞥';$('statusLeft').textContent='九界已窺見';$('statusRight').textContent='通行尚未開放';$('goalTag').textContent='遙遠 · 建立自己的跨界據點';$('goalTitle').textContent='從一座茅屋，到一方天地';$('goalText').textContent='先記住想去的地方，再回來踏實修行。';$('metric').textContent='可隨時返回';$('primary').textContent='展開九界圖';$('secondary').textContent='回到洞府 · 繼續修行';}
 else{$('realmStatus').textContent=late?'後期狀態 · 展示資料':'九界圖 · 道途預覽';$('realmTitle').textContent=late?'諸天有我的燈火':'九界皆在天外';$('statusLeft').textContent='界域分類 · 非境界階級';$('statusRight').textContent=late?'已立 2 處據點 · 示意':'人界可居 · 八界未抵';$('goalTag').textContent=late?'經營 · 靈界據點供給':'眼前 · 洞府 → 築基準備';$('goalTitle').textContent=late?'靈潮將轉，先備靈草':`道途所向 · ${pinned}`;$('goalText').textContent=late?'檢視法則與供給，再安排下一步配置。':'遠景可看，通行條件待玩法驗證後定案。';$('metric').textContent=late?'法則提案':'未解鎖';$('primary').textContent=late?'查看靈界據點':'返回洞府 · 修行不輟';$('secondary').textContent=late?'返回洞府 · 看見你的起點':'重看天外一瞥';renderNodes();}
 $('footerHint').textContent=view==='atlas'?'九個界域皆可點選；標記目標不等於解鎖通行':'可直接點選畫面中的建築與按鈕';
}
function renderNodes(){$('nodes').replaceChildren(...realms.map((r,i)=>{const b=document.createElement('button');b.className='node'+(!i?' home':'')+(late&&i===1?' open':'')+(r.name===pinned?' pinned':'');b.style.left=r.x+'%';b.style.top=r.y+'%';const name=document.createElement('span');name.textContent=r.name;const state=document.createElement('small');state.textContent=late&&i===1?'據點 · 示意':r.state;b.append(name,state);b.setAttribute('aria-label',`查看${r.name}`);b.onclick=()=>realmDetail(i);return b;}));}
function openDrawer(tag,title,body,fact,action,handler){lastFocus=document.activeElement;$('drawerTag').textContent=tag;$('drawerTitle').textContent=title;$('drawerBody').textContent=body;$('drawerFact').textContent=fact;$('drawerAction').textContent=action;$('drawerAction').onclick=handler;$('drawer').hidden=false;$('close').focus();}
function closeDrawer(){if(!$('drawer').hidden){$('drawer').hidden=true;if(lastFocus?.isConnected)lastFocus.focus();}}
function realmDetail(i){const r=realms[i];openDrawer(late&&i===1?'已建立據點 · 後期示意':'道途圖鑑 · 界域提案',r.name,r.body,late&&i===1?'法則：靈潮將轉。供給示意：靈草送往人界丹爐；預備靈石供給。':r.fact,i===0?'返回洞府':late&&i===1?'記下配置方向':'標記為嚮往',()=>{closeDrawer();if(i===0){change('home');return;}pinned=r.name;render();message(late&&i===1?'已預覽配置方向；正式調度尚未實作。':`已記下${r.name}，通行尚未解鎖。`);});}
function garden(){openDrawer('洞府建設 · 介面示意','藥圃','從山谷取得靈草，建立穩定供給。點選場景建築後，抽屜說明它對修行的作用。','此處只預覽操作方式；造價、產量與解鎖條件將對照舊版公式實作。','回到修行',closeDrawer);}
$('primary').onclick=()=>{if(view==='home'){if(awake){garden();return;}awake=true;qi=1;$('game').classList.add('awake');$('floatLine').textContent='靈氣入體，天門在雲外回應。';render();visionTimer=setTimeout(()=>change('vision'),2200);}else if(view==='vision')change('atlas');else if(late)realmDetail(1);else change('home');};
$('secondary').onclick=()=>{if(view==='home')change('atlas');else if(view==='vision'||late)change('home');else change('vision');};
document.querySelectorAll('[data-mode]').forEach(b=>b.onclick=()=>change(b.dataset.mode==='late'?'atlas':b.dataset.mode,b.dataset.mode==='late'));
$('navHome').onclick=()=>change('home');$('navWorld').onclick=()=>change('atlas',late);$('navInner').onclick=()=>openDrawer('內景 · 後續介面','一身經脈，通向天地','內景承接先前的工筆人物、五行印章與功法／天賦圖譜；本原型先驗證洞府到九界的觀看路徑。','從經脈查看功法與天賦，再回洞府觀察供給變化。','回到當前畫面',closeDrawer);
$('hut').onclick=()=>openDrawer('根基 · 你的第一座洞府','茅屋','窗內一盞燈，映出修行的起點。啟靈後，以呼吸光與靈氣流呈現自動運作。','同一間茅屋會在天外一瞥中保留；返回洞府時能立即認出。','回到修行',closeDrawer);$('garden').onclick=garden;$('close').onclick=closeDrawer;
$('reset').onclick=()=>{awake=false;qi=0;pinned='靈界';$('game').classList.remove('awake');$('floatLine').textContent='一方山谷，便是道途的起點。';change('home');};
$('motion').onclick=()=>{const on=document.body.classList.toggle('reduced');$('motion').setAttribute('aria-pressed',String(on));$('motion').textContent=on?'恢復動態':'減少動態';};
document.addEventListener('keydown',e=>{if(e.key==='Escape')closeDrawer();if(e.key==='Tab'&&!$('drawer').hidden){const first=$('close'),last=$('drawerAction');if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
for(let i=0;i<18;i++){const p=document.createElement('i');p.style.left=(13+(i*37)%77)+'%';p.style.top=(31+(i*13)%39)+'%';p.style.animationDelay=-(i*.49)+'s';$('particles').append(p);}
setInterval(()=>{if(awake&&qi<100){qi++;if(view==='home'){$('metric').textContent=`${qi} / 100`;$('bar').style.width=qi+'%';}}},1000);
change('home');
