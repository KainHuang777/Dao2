import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const driver = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2i';
fs.mkdirSync(DIR, { recursive: true });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(250); }
await driver.click({ x: 85, y: 666 }); await sleep(800);
await driver.click({ x: 175, y: 666 }); await sleep(1400);
for (const x of [297, 519, 770]) { await driver.click({ x, y: 46 }); await sleep(600); }
await driver.click({ x: 946, y: 214 }); await sleep(900); await shot('all');
await driver.click({ x: 1182, y: 214 }); await sleep(900); await shot('st');
console.log('before ' + JSON.stringify((await summarizeSave(await driver.readSave())).buildings));
await driver.click({ x: 1212, y: 510 }); await sleep(1500);
console.log('after ' + JSON.stringify((await summarizeSave(await driver.readSave())).buildings));
await shot('st-built');
await driver.close();
process.exit(0);
