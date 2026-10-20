import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era3';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
const click = async (p, d = 900) => { await driver.click(p); await sleep(d); };
for (let i = 0; i < 3; i++) { try { await click({ x: 278, y: 287 }, 300); } catch {} }
await click({ x: 85, y: 666 }, 900);
await click({ x: 175, y: 666 }, 1500);
for (const x of [297, 519, 770]) await click({ x, y: 46 }, 700);
await click({ x: 951, y: 46 }, 1500);      // manufacturing
await click({ x: 1100, y: 126 }, 1300);    // 精鍊
await shot('refine-list');
await click({ x: 988, y: 424 }, 1600);     // try stone_mid card title
await shot('refine-after-title');
await click({ x: 854, y: 602 }, 1600);     // 開始製造 (era3 detail y)
await shot('refine-after-start');
const s = await summarizeSave(await driver.readSave());
console.log('jobs ' + JSON.stringify(s.economy.jobs));
console.log('stone_mid ' + JSON.stringify(s.resources.stone_mid));
await driver.close();
process.exit(0);
