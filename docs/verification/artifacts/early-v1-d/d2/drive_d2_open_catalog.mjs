import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../../res1d2-natural-mouse-driver.mjs';
const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
const log = (obj) => fs.appendFileSync(path.join(OUT, 'events-second-life.jsonl'), JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
await d.bringToFront();
for (let i = 0; i < 12; i++) { await d.click({ x: 307, y: 397 }); await sleep(170); }
await sleep(600);
await d.screenshot(path.join(OUT, 'second-life-lingli-27.png'));
log({ kind: 'click-open-catalog', ...await d.click({ x: 183, y: 665 }) });
await sleep(1500);
await d.screenshot(path.join(OUT, 'second-life-catalog.png'));
const save = await d.readSave();
log({ kind: 'save-open-catalog', revision: save.revision, lingli: save.state?.resources?.lingli?.value, total: save.state?.total_elapsed_seconds });
await d.close();
