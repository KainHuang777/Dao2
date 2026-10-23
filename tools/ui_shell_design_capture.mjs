// Design-only browser checks. No access to game state or player origins.
import fs from 'node:fs';
import {connectDriver, sleep} from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';
const dir='docs/verification/artifacts/ui-shell-design';
fs.mkdirSync(dir,{recursive:true});
const api=await connectDriver({cdpPort:9251,matchPort:4392});
const evidence={date:'2026-10-21',kind:'HTML design proposal only; not Godot acceptance',screens:[],interactions:[]};
async function load(route,w,h,extra=''){
  await api.send('Emulation.setDeviceMetricsOverride',{width:w,height:h,deviceScaleFactor:1,mobile:false});
  await api.navigate(`http://127.0.0.1:4392/screen.html?route=${route}${extra}`);
  await api.waitFor(()=>api.evaluate('!!window.designState'),5000,100,'design loaded');
  await api.evaluate('document.fonts.ready.then(()=>true)');
  await sleep(180);
}
async function capture(name){
  const result=await api.evaluate(`(()=>{let visible=e=>e.getClientRects().length&&getComputedStyle(e).visibility!=='hidden';let rect=e=>{let r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}};return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,documentSize:[document.documentElement.scrollWidth,document.documentElement.scrollHeight],fonts:['DaoSans','DaoSerif','DaoWen'].map(n=>[n,document.fonts.check('18px '+n)]),brokenImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src),smallButtons:[...document.querySelectorAll('button')].filter(visible).filter(b=>{let r=b.getBoundingClientRect();return r.width<44||r.height<44}).map(b=>({text:b.textContent,...rect(b)})),fixedOutside:[...document.querySelectorAll('button')].filter(visible).filter(b=>!b.closest('.scroll')).filter(b=>{let r=b.getBoundingClientRect();return r.left<0||r.top<0||r.right>innerWidth+.5||r.bottom>innerHeight+.5}).map(b=>b.textContent),horizontalOverflow:[...document.querySelectorAll('.scroll,.context,.heading,.hud,.footer')].filter(visible).filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.className),scrollAreas:[...document.querySelectorAll('.scroll')].filter(visible).map(rect)}})()`);
  await api.screenshot(`${dir}/${name}.png`);
  evidence.screens.push({name,...result});
}
async function click(selector){
 const p=await api.evaluate(`(()=>{let b=document.querySelector(${JSON.stringify(selector)});if(!b)throw Error('missing target');let r=b.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2}})()`);
 for(let type of ['mouseMoved','mousePressed','mouseReleased'])await api.send('Input.dispatchMouseEvent',{type,...p,button:type==='mouseMoved'?'none':'left',buttons:type==='mousePressed'?1:0,clickCount:1,pointerType:'mouse'});
 await sleep(80);
}
function assert(name,value){evidence.interactions.push({name,passed:!!value});if(!value)throw Error(name)}
try{
 for(const [w,h]of [[1280,720],[844,390],[800,360]]){
  for(const route of ['home','buildings','manufacturing','skills','fortune','life']){await load(route,w,h);await capture(`${route}-${w}x${h}`)}
  await load('life',w,h,'&font=c');await capture(`life-fc-${w}x${h}`);
  await load('life',w,h,'&font=c&long=1&error=1');await capture(`life-long-error-${w}x${h}`);
 }
 await load('home',800,360);
 await click('[data-action="res:off"]');await click('[data-action="togglemsg"]');
 await click('[data-action="go:buildings"]');
 assert('Cost route supplies resources without changing home preference',await api.evaluate('designState.resource==="off" && !!document.querySelector(".context")'));
 await click('[data-action="inventory"]');await capture('resource-drawer-800x360');
 await click('[data-action="dismiss"]');
 assert('Resource drawer returns to buildings',await api.evaluate('designState.route==="buildings" && !designState.overlay'));
 await click('[data-action="go:skills"]');await click('[data-action="settings"]');await click('[data-action="error"]');
 assert('Global save error visible on skills',await api.evaluate('!!document.querySelector(".save")'));
 await click('[data-action="messages"]');await capture('message-overlay-error-800x360');
 await click('[data-action="dismiss"]');
 assert('Reading returns to skills and keeps save error',await api.evaluate('designState.route==="skills" && !!document.querySelector(".save")'));
 await api.send('Emulation.setDeviceMetricsOverride',{width:1280,height:720,deviceScaleFactor:1,mobile:false});
 assert('Resize preserves route and home intent',await api.evaluate('designState.route==="skills" && designState.resource==="off" && !designState.messages'));
 await click('[data-action="home"]');
 assert('Home restores resource-off and message-off intent',await api.evaluate('designState.route==="home" && !document.querySelector(".home-message") && document.querySelector(".stock .scroll").children.length===0'));
 await click('[data-action="retry"]');assert('Mock retry only clears design banner',await api.evaluate('!designState.failed'));
 await load('life',800,360,'&life=early');await capture('life-early-800x360');
 await load('life',800,360,'&life=living');await capture('life-living-800x360');
 await api.send('Emulation.setDeviceMetricsOverride',{width:360,height:640,deviceScaleFactor:1,mobile:false});
 assert('Portrait rotation cover shown',await api.evaluate('getComputedStyle(document.querySelector(".rotation")).display==="flex"'));
 await api.send('Emulation.setDeviceMetricsOverride',{width:800,height:360,deviceScaleFactor:1,mobile:false});
 assert('Landscape restores route',await api.evaluate('designState.route==="life" && designState.life==="living"'));
 await load('life',800,360,'&font=b&long=1');await capture('life-fb-long-800x360');
 evidence.browser=(await api.send('Browser.getVersion')).product;
 evidence.failures=evidence.screens.filter(s=>s.brokenImages.length||s.smallButtons.length||s.fixedOutside.length||s.horizontalOverflow.length||s.documentSize[0]>s.viewport[0]||s.documentSize[1]>s.viewport[1]);
 fs.writeFileSync(`${dir}/browser-checks.json`,JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify({screens:evidence.screens.length,interactions:evidence.interactions.length,failures:evidence.failures.map(s=>({name:s.name,broken:s.brokenImages,small:s.smallButtons,outside:s.fixedOutside,overflow:s.horizontalOverflow,size:s.documentSize}))}));
 await api.send('Emulation.clearDeviceMetricsOverride');
 await api.navigate('http://127.0.0.1:4392/index.html');
}finally{await api.close();}
