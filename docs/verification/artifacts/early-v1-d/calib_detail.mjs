import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const DIR = process.env.DIR || 'drive-era2';
const CARD_TITLE = { x: 613, y: 220 };

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'calib-' + label + '.png'); await driver.screenshot(f); return f; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(500); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1400);
  await driver.click({ x: 692, y: 46 });
  await sleep(1200);
  await driver.click(CARD_TITLE);
  await sleep(1200);
  await shot('detail-top');
  await driver.click({ x: 855, y: 468 });
  await sleep(900);
  await shot('detail-mode-open');
} finally { await driver.close().catch(() => {}); }
