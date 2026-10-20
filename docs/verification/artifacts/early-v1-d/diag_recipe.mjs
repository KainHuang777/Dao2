import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = 'docs/verification/artifacts/early-v1-d/diag-recipe';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, httpPort: HTTP_PORT, debugPrinter: () => {} });
let n = 0;
async function shot(label) { n++; const f = path.join(DIR, String(n).padStart(2, '0') + '-' + label + '.png'); try { await driver.screenshot(f); console.log('shot', f); } catch (e) { console.log('shotfail', String(e)); } }
const j = async () => { const s = await driver.readSave(); const e = s.state.economy || s.state.eco || {}; return JSON.stringify(e.jobs || {}); };
try {
  await driver.bringToFront();
  await driver.reload();
  await sleep(7000);
  for (let i = 0; i < 3; i++) { await driver.click({ x: 278, y: 287 }); await sleep(500); }
  await driver.click({ x: 191, y: 668 }); await sleep(1600);
  await shot('buildings');
  await driver.click({ x: 951, y: 46 }); await sleep(1600);
  await shot('mfg-list');
  console.log('jobs after list', await j());
  await driver.click({ x: 613, y: 488 }); await sleep(1600);
  await shot('after-title-liquid-488');
  await driver.click({ x: 613, y: 424 }); await sleep(1500);
  await shot('after-title-424');
  await driver.click({ x: 613, y: 446 }); await sleep(1500);
  await shot('after-title-446');
  console.log('jobs', await j());
} finally { await driver.close().catch(() => {}); }
process.exit(0);
