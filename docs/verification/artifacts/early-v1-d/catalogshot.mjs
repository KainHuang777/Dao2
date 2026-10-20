import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/catalogshot';
fs.mkdirSync(DIR, { recursive: true });

const P = {
  popup_offline_close: { x: 275, y: 287 },
  dock_management: { x: 172, y: 668 },
  tab_all: { x: 754, y: 213 },
  tab_production: { x: 960, y: 213 },
  tab_storage: { x: 1161, y: 213 }
};

let n = 0;
async function shot(driver, label) {
  n++;
  const f = path.join(DIR, String(n).padStart(2, '0') + '-' + label + '.png');
  await driver.screenshot(f);
  console.log('shot ' + f);
  return f;
}

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
try {
  const geo = driver.geo();
  console.log('geo', JSON.stringify(geo));
  for (let i = 0; i < 2; i++) { try { await driver.click(P.popup_offline_close); } catch (e) {} await sleep(800); }
  await driver.click(P.dock_management);
  await sleep(1800);
  await shot(driver, 'open');
  await driver.click(P.tab_all);
  await sleep(1200);
  await shot(driver, 'tab-all');
  await driver.click(P.tab_production);
  await sleep(1200);
  await shot(driver, 'tab-production');
  await driver.click(P.tab_storage);
  await sleep(1200);
  await shot(driver, 'tab-storage');
  const save = await driver.readSave();
  const sum = summarizeSave(save);
  console.log('summary', JSON.stringify(sum));
  console.log('buildings', JSON.stringify(sum.buildings));
} finally {
  await driver.close().catch(() => {});
}
