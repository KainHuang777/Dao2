import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, prettySummary, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9241');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = 'docs/verification/artifacts/early-v1-d/calib-blank';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (l) => { const f = path.join(DIR, 'blank-' + l + '.png'); await driver.screenshot(f); console.log('shot', f); };
try {
  await driver.bringToFront(); await sleep(700);
  console.log('initial', prettySummary(summarizeSave(await driver.readSave())));
  await shot('00-home-offline');
  for (let i = 0; i < 3; i++) { await driver.click({ x: 275, y: 287 }); await sleep(400); }
  await shot('01-home');
  await driver.click({ x: 164, y: 664 }); await sleep(1800);
  await shot('02-management');
} catch (e) { console.log('error', String(e)); await shot('99-error'); }
finally { await driver.close().catch(() => {}); process.exit(0); }
