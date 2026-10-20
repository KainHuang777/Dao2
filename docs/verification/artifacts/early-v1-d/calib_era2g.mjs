import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2g';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
const disp = (dy) => `(()=>{const c=document.querySelector('canvas');c.dispatchEvent(new WheelEvent('wheel',{deltaY:${dy},deltaX:0,bubbles:true,cancelable:true}));return true;})()`;
await driver.bringToFront();
await driver.click({ x: 950, y: 214 }); await sleep(600);   // 全部
await driver.click({ x: 1100, y: 620 }); await sleep(300);
for (let i = 0; i < 14; i++) { await driver.evaluate(disp(120)); await sleep(180); }
await shot('all-bottom');
await driver.click({ x: 1182, y: 214 }); await sleep(600);   // 倉儲
await driver.click({ x: 1100, y: 620 }); await sleep(300);
for (let i = 0; i < 14; i++) { await driver.evaluate(disp(120)); await sleep(180); }
await shot('storage-bottom');
await driver.close();
process.exit(0);
