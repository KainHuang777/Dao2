import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2f';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
await driver.bringToFront();
await driver.click({ x: 1100, y: 620 }); await sleep(400); // hover near panel bottom (empty)
const disp = (dy) => `(()=>{const c=document.querySelector('canvas');c.dispatchEvent(new WheelEvent('wheel',{deltaY:${dy},deltaX:0,bubbles:true,cancelable:true}));return true;})()`;
for (let i = 0; i < 5; i++) { await driver.evaluate(disp(120)); await sleep(250); }
await shot('synth-down');
for (let i = 0; i < 5; i++) { await driver.evaluate(disp(-120)); await sleep(250); }
await shot('synth-up');
// also try CDP wheel with negative and positive
await driver.wheel({ x: 1100, y: 500 }, 120); await sleep(300);
await driver.wheel({ x: 1100, y: 500 }, 120); await sleep(300);
await shot('cdp-down');
await driver.close();
process.exit(0);
