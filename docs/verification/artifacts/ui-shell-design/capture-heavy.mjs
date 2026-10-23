import fs from 'node:fs';
import {connectDriver,sleep} from '../res1d2-natural-mouse-driver.mjs';
const out='docs/verification/artifacts/ui-shell-design/heavy-serif';
fs.mkdirSync(out,{recursive:true});
const api=await connectDriver({cdpPort:9251,matchPort:4392});
const results=[];
try{
for(const [w,h]of [[1280,720],[844,390],[800,360]])for(const long of [false,true]){
 await api.send('Emulation.setDeviceMetricsOverride',{width:w,height:h,deviceScaleFactor:1,mobile:false});
 await api.navigate(`http://127.0.0.1:4392/screen.html?route=life&font=c${long?'&long=1&error=1':''}`);
 await api.waitFor(()=>api.evaluate('!!window.designState'),5000,100,'design loaded');
 await api.evaluate('document.fonts.ready.then(()=>true)');await sleep(100);
 const row=await api.evaluate(`(()=>{let title=document.querySelector('.story h1'),seal=document.querySelector('.story .seal');return{viewport:[innerWidth,innerHeight],document:[document.documentElement.scrollWidth,document.documentElement.scrollHeight],title:{font:getComputedStyle(title).fontFamily,weight:getComputedStyle(title).fontWeight},sealWeight:getComputedStyle(seal).fontWeight,loaded:document.fonts.check('800 26px DaoSerif'),smallButtons:[...document.querySelectorAll('button')].filter(b=>b.getClientRects().length).filter(b=>{let r=b.getBoundingClientRect();return r.width<44||r.height<44}).length,horizontal:[...document.querySelectorAll('.scroll,.hud,.footer')].filter(e=>e.getClientRects().length&&e.scrollWidth>e.clientWidth+1).length}})()`);
 const name=`fc800-${w}x${h}${long?'-long-error':''}`;
 await api.screenshot(`${out}/${name}.png`);
 row.name=name;row.pass=row.title.weight==='800'&&row.sealWeight==='900'&&row.loaded&&row.document[0]===w&&row.document[1]===h&&!row.smallButtons&&!row.horizontal;
 results.push(row);
}
fs.writeFileSync(`${out}/checks.json`,JSON.stringify(results,null,2)+'\n');
console.log(JSON.stringify({screens:results.length,failures:results.filter(x=>!x.pass)}));
await api.send('Emulation.clearDeviceMetricsOverride');
await api.navigate('http://127.0.0.1:4392/index.html');
if(results.some(x=>!x.pass))process.exitCode=1;
}finally{await api.close();}
