import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2e';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
const b = async () => (await summarizeSave(await driver.readSave())).buildings;
await driver.bringToFront();
for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(300); }
await driver.click({ x: 85, y: 666 }); await sleep(700);
await driver.click({ x: 175, y: 666 }); await sleep(1300);
for (const x of [297, 519, 770]) { await driver.click({ x, y: 46 }); await sleep(800); }
await driver.click({ x: 950, y: 214 }); await sleep(900);   // 全部
await shot('before');
console.log('before ' + JSON.stringify(await b()));
for (let i = 0; i < 4; i++) {
  await driver.click({ x: 1214, y: 427 }); await sleep(1100);
  const bb = await b();
  if (bb.storage_lingli >= 2) break;
}
await shot('after-lingli2');
console.log('after ' + JSON.stringify(await b()));
await driver.close();
process.exit(0);
