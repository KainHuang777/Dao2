import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2h';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
const scroll = async (n) => { await driver.evaluate(`(()=>{const c=document.querySelector('canvas');for(let i=0;i<${n};i++){c.dispatchEvent(new WheelEvent('wheel',{deltaY:120,deltaX:0,bubbles:true,cancelable:true}));}return true;})()`); await sleep(600); };
for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(250); }
await driver.click({ x: 85, y: 666 }); await sleep(800);
await driver.click({ x: 175, y: 666 }); await sleep(1400);
for (const x of [297, 519, 770]) { await driver.click({ x, y: 46 }); await sleep(600); }
await driver.click({ x: 1100, y: 620 }); await sleep(400);
await scroll(30); await shot('bld-scroll1');
await scroll(30); await shot('bld-scroll2');
console.log('buildings ' + JSON.stringify((await summarizeSave(await driver.readSave())).buildings));
// transport
await driver.click({ x: 1038, y: 46 }); await sleep(1500);
await shot('transport');
const env = await driver.readSave();
console.log('routes ' + JSON.stringify(env.state.economy.routes));
console.log('islands ' + JSON.stringify(env.state.economy.islands));
await driver.close();
process.exit(0);
