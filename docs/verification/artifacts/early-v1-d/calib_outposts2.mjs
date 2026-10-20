import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/calib';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'calib-' + label + '.png'); await driver.screenshot(f); console.log('shot', f); };
try {
  await driver.bringToFront(); await sleep(600);
  await driver.click({ x: 875, y: 46 }); await sleep(1500);
  await driver.click({ x: 1139, y: 179 }); await sleep(1500); await shot('20-outposts-herb');
  await driver.click({ x: 994, y: 179 }); await sleep(1200); await shot('21-outposts-wood');
} catch (e) { console.log('error', String(e)); await shot('99-error'); }
finally { await driver.close().catch(() => {}); process.exit(0); }
