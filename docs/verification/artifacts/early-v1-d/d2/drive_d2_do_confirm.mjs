import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../../res1d2-natural-mouse-driver.mjs';
const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
const log = (obj) => fs.appendFileSync(path.join(OUT, 'events-reincarnate-confirm.jsonl'), JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
await d.bringToFront();
log({ kind: 'click-confirm', ...await d.click({ x: 670, y: 586 }) });
for (const [ms, name] of [[800,'seq-0.8s.png'],[1500,'seq-2.3s.png'],[2500,'seq-4.8s.png'],[4000,'seq-8.8s.png']]) {
  await sleep(ms);
  await d.screenshot(path.join(OUT, name));
  const save = await d.readSave();
  log({ kind: 'save', name, revision: save.revision, era: save.state?.era_id, level: save.state?.level, total: save.state?.total_elapsed_seconds, rc: save.state?.reincarnation_count, dh: save.state?.dao_heart });
}
await d.close();
