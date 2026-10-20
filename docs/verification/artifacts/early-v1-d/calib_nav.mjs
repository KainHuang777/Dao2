import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const DIR = process.env.DIR || 'drive-era2';

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'nav-' + label + '.png'); await driver.screenshot(f); return f; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  await driver.reload();
  await sleep(6000);
  await driver.bringToFront();
  for (let i = 0; i < 4; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(500); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1800);
  await shot('A-open');
  const s = summarizeSave(await driver.readSave());
  console.log('era', s.era, 'lv', s.level, 'jobs', JSON.stringify(s.economy.jobs));
} finally { await driver.close().catch(() => {}); }
