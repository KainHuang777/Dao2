import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'drive-era2';

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
const shot = async (n, label) => { const f = path.join(DIR, 'calib-' + n + '-' + label + '.png'); await driver.screenshot(f); return f; };
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch (e) {} await sleep(600); }
  await driver.click({ x: 191, y: 668 });
  await sleep(1500);
  await shot('01', 'management');
  await driver.click({ x: 692, y: 47 });
  await sleep(1200);
  await shot('02', 'manu-list');
  const s = summarizeSave(await driver.readSave());
  console.log('geo', JSON.stringify(await driver.geo()));
  console.log('era', s.era, 'lv', s.level, 'jobs', JSON.stringify(s.economy.jobs), 'routes', JSON.stringify(s.economy.routes), 'trips', JSON.stringify(s.economy.trips));
  console.log('res', JSON.stringify(Object.fromEntries(Object.keys(s.resources).filter(k => s.resources[k].unlocked).map(k => [k, s.resources[k].value]))));
  console.log('bld', JSON.stringify(s.buildings));
} finally { await driver.close().catch(() => {}); }
