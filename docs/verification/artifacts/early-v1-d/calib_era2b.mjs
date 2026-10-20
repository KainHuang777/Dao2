import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2b';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { const f = path.join(DIR, l + '.png'); await driver.screenshot(f); console.log('shot ' + l); };
const save = async () => summarizeSave(await driver.readSave());

for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(300); }

// --- try open ore island ---
await driver.click({ x: 85, y: 666 }); await sleep(700);
await driver.click({ x: 175, y: 666 }); await sleep(1300);
await driver.click({ x: 875, y: 46 }); await sleep(1200);
await driver.click({ x: 1064, y: 177 }); await sleep(900);
await driver.click({ x: 1062, y: 429 }); await sleep(4000);
let s = await save();
console.log('ore opened? ' + s.economy.islands.ore.opened);
if (!s.economy.islands.ore.opened) {
  await shot('ore-after-firstclick');
  // try a second candidate in case of confirm dialog
  await driver.click({ x: 1062, y: 429 }); await sleep(3500);
  s = await save();
  console.log('ore opened after 2nd? ' + s.economy.islands.ore.opened);
  await shot('ore-after-secondclick');
}

// --- storage tab scroll ---
await driver.click({ x: 770, y: 46 }); await sleep(1200);
await driver.click({ x: 1156, y: 214 }); await sleep(900);
await shot('storage-top');
await driver.wheel({ x: 1050, y: 430 }, -600); await sleep(700);
await shot('storage-up');
await driver.wheel({ x: 1050, y: 430 }, 600); await sleep(700);
await shot('storage-down');

// --- manufacturing page ---
await driver.click({ x: 951, y: 46 }); await sleep(1300);
await shot('mfg');

console.log('islands ' + JSON.stringify((await save()).economy.islands));
await driver.close();
process.exit(0);
