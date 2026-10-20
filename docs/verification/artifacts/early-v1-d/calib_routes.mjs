import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const DIR = process.env.DIR || 'drive-era2';

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'recon-' + label + '.png'); await driver.screenshot(f); return f; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(400); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1400);
  await shot('mgmt-home');
  await driver.click({ x: 781, y: 46 });
  await sleep(1400);
  await shot('routes');
  const s = summarizeSave(await driver.readSave());
  console.log('routes', JSON.stringify(s.economy.routes), 'trips', JSON.stringify(s.economy.trips), 'jobs', JSON.stringify(s.economy.jobs));
} finally { await driver.close().catch(() => {}); }
