import path from 'node:path';
import fs from 'node:fs';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era3';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
const shot = async (l) => { await driver.screenshot(path.join(DIR, l + '.png')); console.log('shot ' + l); };
const click = async (p, d = 900) => { await driver.click(p); await sleep(d); };
const jobs = async () => (await summarizeSave(await driver.readSave())).economy.jobs;
console.log('jobs-before ' + JSON.stringify(await jobs()));
// already on stone_mid detail page; open dropdown at correct y
await click({ x: 854, y: 466 }, 1200);
await shot('s3-menu');
await driver.close();
process.exit(0);
