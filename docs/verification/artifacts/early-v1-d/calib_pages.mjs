import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/calib';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'calib-' + label + '.png'); await driver.screenshot(f); console.log('shot', f); };
const rec = (t, d) => console.log(JSON.stringify({ utc: new Date().toISOString(), t, d }));
try {
  await driver.bringToFront();
  await sleep(600);
  // Tab bar (from buildings page). Click 空島 outposts.
  await driver.click({ x: 875, y: 46 }); await sleep(1600); await shot('10-outposts');
  await driver.click({ x: 951, y: 46 }); await sleep(1600); await shot('11-manufacturing');
  await driver.click({ x: 1038, y: 46 }); await sleep(1600); await shot('12-transport');
} catch (e) {
  rec('error', { e: String(e) }); await shot('99-error');
} finally { await driver.close().catch(() => {}); process.exit(0); }
