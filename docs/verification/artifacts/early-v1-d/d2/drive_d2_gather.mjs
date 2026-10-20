import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../../res1d2-natural-mouse-driver.mjs';
const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
const log = (obj) => fs.appendFileSync(path.join(OUT, 'events-second-life.jsonl'), JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
await d.bringToFront();
for (let i = 0; i < 15; i++) {
  await d.click({ x: 307, y: 397 });
  await sleep(180);
}
await sleep(800);
await d.screenshot(path.join(OUT, 'second-life-after-gather.png'));
const save = await d.readSave();
log({ kind: 'save-after-gather', revision: save.revision, total: save.state?.total_elapsed_seconds, lingli: save.state?.resources?.lingli?.value, money: save.state?.resources?.money?.value });
await d.close();
