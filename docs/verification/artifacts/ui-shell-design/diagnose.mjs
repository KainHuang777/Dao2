import {connectDriver} from '../res1d2-natural-mouse-driver.mjs';
const a=await connectDriver({cdpPort:9251,matchPort:4392});
await a.send('Emulation.setDeviceMetricsOverride',{width:800,height:360,deviceScaleFactor:1,mobile:false});
for(const route of ['home','life&error=1']){
await a.navigate('http://127.0.0.1:4392/screen.html?route='+route);
console.log(route,await a.evaluate(`JSON.stringify([...document.querySelectorAll('.app,.main,.goal,.dock,.dock button,.home-stack,.stock,.workspace,.biography,.context,.footer,.hud')].map(e=>({c:e.className,t:e.textContent.slice(0,12),r:e.getBoundingClientRect().toJSON(),sh:e.scrollHeight})))`));
}
await a.close();
