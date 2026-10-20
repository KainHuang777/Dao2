import fs from 'node:fs';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const driver = await connectDriver({ cdpPort: 9240, matchPort: '4380', debugPrinter: l => console.log('[drv]', l) });
const st = await driver.evaluate(`(()=>{const c=document.querySelector('canvas');const r=c?c.getBoundingClientRect():null;let ls=0;try{ls=localStorage.length}catch(e){}return {href:location.href, rs:document.readyState, ls, canvas: r?{w:r.width,h:r.height,left:r.left,top:r.top}:null, bodyText:(document.body?document.body.innerText:'').slice(0,300)};})()`);
console.log('STATE:', JSON.stringify(st, null, 2));
console.log('CONSOLE (' + driver.consoleLines.length + '):');
for (const l of driver.consoleLines.slice(-25)) console.log('  ', l.text);
try { const r = await driver.send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync('docs/verification/artifacts/early-v1-d-20261018/edge-screen.png', Buffer.from(r.data, 'base64')); console.log('screenshot ok'); } catch (e) { console.log('screenshot ERR', String(e).slice(0, 150)); }
await driver.close();
