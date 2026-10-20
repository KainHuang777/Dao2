import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../../res1d2-natural-mouse-driver.mjs';
const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
const log = (obj) => fs.appendFileSync(path.join(OUT, 'events-second-life.jsonl'), JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
await d.bringToFront();
for (let i = 0; i < 25; i++) { await d.click({ x: 297, y: 362 }); await sleep(150); }
await sleep(600);
await d.screenshot(path.join(OUT, 'second-life-money-gathered.png'));
const save = await d.readSave();
log({ kind: 'save-money', revision: save.revision, total: save.state?.total_elapsed_seconds, lingli: save.state?.resources?.lingli?.value, money: save.state?.resources?.money?.value, wood: save.state?.resources?.wood?.value });
await d.close();
