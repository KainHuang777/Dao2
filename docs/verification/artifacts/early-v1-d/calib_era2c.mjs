import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2c';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(300); }
await driver.click({ x: 85, y: 666 }); await sleep(700);
await driver.click({ x: 175, y: 666 }); await sleep(1300);
for (const x of [297, 519, 770]) { await driver.click({ x, y: 46 }); await sleep(900); } // force buildings page
await shot('page0');
await driver.click({ x: 754, y: 214 }); await sleep(900);   // 全部
await shot('all-top');
await driver.wheel({ x: 1050, y: 430 }, 1200); await sleep(800);
await shot('all-down1');
await driver.wheel({ x: 1050, y: 430 }, 1200); await sleep(800);
await shot('all-down2');
console.log('buildings ' + JSON.stringify((await summarizeSave(await driver.readSave())).buildings));
await driver.close();
process.exit(0);
