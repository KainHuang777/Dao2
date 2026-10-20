import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-era2';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { const f = path.join(DIR, l + '.png'); await driver.screenshot(f); console.log('shot ' + f); };
const save = async () => summarizeSave(await driver.readSave());

for (let i = 0; i < 2; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(300); }
console.log('state ' + JSON.stringify({ era: (await save()).era, islands: (await save()).economy.islands, routes: (await save()).economy.routes }));

await driver.click({ x: 85, y: 666 }); await sleep(800);           // home
await driver.click({ x: 175, y: 666 }); await sleep(1300);          // management
await shot('a-managed');

await driver.click({ x: 875, y: 46 }); await sleep(1300);           // outposts
await shot('b-outposts');

await driver.click({ x: 1053, y: 179 }); await sleep(1000);         // ore island tab
await shot('c-outposts-ore');

await driver.click({ x: 1038, y: 46 }); await sleep(1300);          // transport
await shot('d-transport');

await driver.click({ x: 297, y: 46 }); await sleep(1300);           // buildings
await driver.click({ x: 1161, y: 214 }); await sleep(1000);         // storage tab
await shot('e-storage');

console.log('done');
await driver.close();
process.exit(0);
