import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9241');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-blank2';
fs.mkdirSync(DIR, { recursive: true });

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: '4380' });
const shot = async (l) => { const f = path.join(DIR, l + '.png'); await driver.screenshot(f); console.log('shot ' + f); };
const save = async () => summarizeSave(await driver.readSave());

console.log('start ' + JSON.stringify(await save()));
await shot('a-start');

await driver.click({ x: 799, y: 448 }); await sleep(700);
await driver.click({ x: 286, y: 272 }); await sleep(700);
await shot('b-full-ribbon');
console.log('after-ribbon ' + JSON.stringify((await save()).resources));

await driver.click({ x: 165, y: 668 }); await sleep(1500);
await shot('c-management');

await driver.close();
process.exit(0);
