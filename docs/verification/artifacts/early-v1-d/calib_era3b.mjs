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
await click({ x: 951, y: 46 }, 1500);
await click({ x: 1100, y: 126 }, 1300);    // 精鍊
await click({ x: 986, y: 464 }, 1700);     // stone_mid title
await shot('s2-detail');
await click({ x: 854, y: 496 }, 1200);     // open 單批 dropdown
await shot('s2-dropdown-open');
const s = await summarizeSave(await driver.readSave());
console.log('jobs ' + JSON.stringify(s.economy.jobs));
await driver.close();
process.exit(0);
