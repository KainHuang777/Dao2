import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../../res1d2-natural-mouse-driver.mjs';
const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
const log = (obj) => fs.appendFileSync(path.join(OUT, 'events-click-close.jsonl'), JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
await d.bringToFront();
for (const p of [{ x: 250, y: 336 }, { x: 330, y: 340 }, { x: 250, y: 350 }]) {
  log({ kind: 'click', ...await d.click(p) });
  await sleep(900);
}
await d.screenshot(path.join(OUT, 'after-click-close-calibrated.png'));
await d.close();
