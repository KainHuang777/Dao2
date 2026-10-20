import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = 'docs/verification/artifacts/early-v1-d/diag-recipe';
fs.mkdirSync(DIR, { recursive: true });
const TAG = process.env.TAG || 'click';
const PTS = (process.env.PTS || '').split(';').filter(Boolean).map(s => { const [x, y, w] = s.split(',').map(Number); return { x, y, w: w || 2500 }; });
const driver = await connectDriver({ cdpPort: CDP_PORT, httpPort: HTTP_PORT, debugPrinter: () => {} });
let n = 0;
async function shot(label) { n++; const f = path.join(DIR, TAG + '-' + String(n).padStart(2, '0') + '-' + label + '.png'); try { await driver.screenshot(f); console.log('shot', f); } catch (e) { console.log('shotfail', String(e)); } }
const st = async (t) => { const s = summarizeSave(await driver.readSave()); console.log(t, 'era', s.era, 'level', s.level, 'lingli', s.resources.lingli && Number(s.resources.lingli.value).toFixed(0)); };
try {
  await driver.bringToFront();
  await sleep(400);
  await shot('before');
  await st('before');
  for (const p of PTS) {
    console.log('click', p.x, p.y);
    await driver.click({ x: p.x, y: p.y });
    await sleep(p.w);
    await shot('after-' + p.x + '-' + p.y);
    await st('after ' + p.x + ',' + p.y);
  }
} finally { await driver.close().catch(() => {}); }
process.exit(0);
