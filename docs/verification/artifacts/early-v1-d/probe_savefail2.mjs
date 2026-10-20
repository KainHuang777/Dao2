import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const DIR = 'docs/verification/artifacts/early-v1-d/unified-run';
const log = fs.createWriteStream(path.join(DIR, 'probe-savefail2.jsonl'), { flags: 'a' });
const rec = (t, d) => { const l = JSON.stringify({ utc: new Date().toISOString(), type: t, data: d || {} }); log.write(l + '\n'); console.log(l); };
const driver = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || '9242'), matchPort: '4380' });
await driver.bringToFront();
const RETRY = { x: 638, y: 414 };
try {
  let s = await driver.readSave(); rec('before_retry', { revision: s.revision });
  await driver.click(RETRY); await sleep(2500);
  await driver.screenshot(path.join(DIR, 'probe-savefail-3-recovered.png'));
  s = await driver.readSave(); rec('after_retry', { revision: s.revision, advanced: s.revision > (await driver.readSave()).revision });
  for (let i = 0; i < 20; i++) {
    await sleep(3000);
    const n = await driver.readSave();
    if (n.revision > s.revision) { rec('recovered', { revision: n.revision }); break; }
    if (i === 19) rec('not_recovered', { revision: n.revision });
  }
  await driver.screenshot(path.join(DIR, 'probe-savefail-4-after.png'));
  rec('summary', { era: summarizeSave(await driver.readSave()).era, level: summarizeSave(await driver.readSave()).level });
} catch (e) { rec('error', { error: String(e) }); }
finally { await driver.close().catch(() => {}); log.end(); process.exit(0); }
