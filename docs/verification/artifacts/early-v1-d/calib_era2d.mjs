import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2d';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
await driver.bringToFront();
await driver.click({ x: 950, y: 214 }); await sleep(900);   // 全部
await shot('all-top');
for (let i = 0; i < 3; i++) { await driver.wheel({ x: 1100, y: 400 }, -300); await sleep(500); }
await shot('all-up3');
for (let i = 0; i < 3; i++) { await driver.wheel({ x: 1100, y: 400 }, 300); await sleep(500); }
await shot('all-down3');
await driver.click({ x: 1064, y: 214 }); await sleep(900);  // 生產
await shot('prod');
await driver.close();
process.exit(0);
