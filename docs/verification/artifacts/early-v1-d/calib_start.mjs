import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const DIR = process.env.DIR || 'drive-era2';

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'calib-' + label + '.png'); await driver.screenshot(f); return f; };
const dump = async (tag) => { const s = summarizeSave(await driver.readSave()); console.log(tag, 'jobs=' + JSON.stringify(s.economy.jobs), 'trips=' + JSON.stringify(s.economy.trips)); return s; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(500); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1400);
  await driver.click({ x: 692, y: 46 });
  await sleep(1200);
  await driver.click({ x: 613, y: 220 });
  await sleep(1200);
  await driver.click({ x: 855, y: 468 });
  await sleep(900);
  await driver.click({ x: 560, y: 595 });
  await sleep(900);
  await dump('after-select');
  for (let i = 0; i < 6; i++) { await driver.wheel({ x: 850, y: 560 }, 300); await sleep(150); }
  await sleep(500);
  await driver.click({ x: 848, y: 512 });
  await sleep(2500);
  await shot('after-start');
  await dump('after-start');
} finally { await driver.close().catch(() => {}); }
