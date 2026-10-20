import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep, summarizeSave, prettySummary } from '../../res1d2-natural-mouse-driver.mjs';

const OUT = path.resolve('docs/verification/artifacts/early-v1-d/d2');
fs.mkdirSync(OUT, { recursive: true });
const eventsPath = path.join(OUT, 'events-phase1.jsonl');
const log = (obj) => fs.appendFileSync(eventsPath, JSON.stringify({ utc: new Date().toISOString(), ...obj }) + '\n');
const d = await connectDriver({ cdpPort: 9242, matchPort: '4380' });
d.onConsoleLine(line => log({ kind: 'console', ...line }));
log({ kind: 'attached', targets: 'ok' });
await d.bringToFront();

const canvas = await d.waitFor(async () => {
  const g = await d.geo().catch(() => null);
  return g && g.rect ? g.rect : false;
}, 60000, 1000, 'canvas');
log({ kind: 'geo', ...canvas });
await d.screenshot(path.join(OUT, 'phase1-attach.png'));

let last = null;
const deadline = Date.now() + 240000;
let reported = false;
while (Date.now() < deadline) {
  try {
    last = await d.readSave();
    const st = last.state || {};
    const rep = st.last_offline_report || null;
    const rev = Number(last.revision || 0);
    log({ kind: 'poll', rev, total: st.total_elapsed_seconds, rep });
    if (rep && rep.stopped === 'lifespan_exhausted') { reported = true; break; }
    if (rev > 9254 && !rep) { /* revision advanced without report */ }
  } catch (e) {
    log({ kind: 'poll-error', error: String(e && e.message || e) });
  }
  await sleep(3000);
}
if (!last) throw new Error('no save read');
const sum = summarizeSave(last);
console.log(prettySummary(sum));
fs.writeFileSync(path.join(OUT, 'save-after-settlement.json'), JSON.stringify(last, null, 2));
fs.writeFileSync(path.join(OUT, 'summary-after-settlement.json'), JSON.stringify(sum, null, 2));
log({ kind: 'settlement-observed', reported, summary: sum });
await d.screenshot(path.join(OUT, 'phase1-after-settlement.png'));
await d.close();
