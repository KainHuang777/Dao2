import path from 'node:path';
import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const DIR = process.env.DIR || 'drive-era2';

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'cat-' + label + '.png'); await driver.screenshot(f); return f; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(400); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1400);
  await driver.click({ x: 505, y: 46 });
  await sleep(1400);
  await shot('home');
  await driver.click({ x: 960, y: 213 });
  await sleep(1000);
  await shot('produce');
} finally { await driver.close().catch(() => {}); }
