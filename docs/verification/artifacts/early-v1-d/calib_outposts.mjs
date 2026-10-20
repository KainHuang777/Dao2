import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/calib';
fs.mkdirSync(DIR, { recursive: true });

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (label) => { const f = path.join(DIR, 'calib-' + label + '.png'); await driver.screenshot(f); console.log('shot', f); };
const rec = (t, d) => console.log(JSON.stringify({ utc: new Date().toISOString(), t, d }));
try {
  await driver.bringToFront();
  await sleep(800);
  await shot('00-now');
  const s0 = summarizeSave(await driver.readSave());
  rec('state', { era: s0.era, level: s0.level, islands: s0.economy.islands, routes: s0.economy.routes });
  // dismiss any offline modal
  for (const c of [{ x: 278, y: 287 }, { x: 275, y: 287 }]) { await driver.click(c); await sleep(400); }
  await shot('01-after-dismiss');
  // open management (dock 經營)
  for (const c of [{ x: 191, y: 668 }, { x: 164, y: 664 }]) { await driver.click(c); await sleep(1600); }
  await shot('02-management');
  rec('console', driver.consoleLines.slice(-6).map(l => l.text));
} catch (e) {
  rec('error', { e: String(e) });
  await shot('99-error');
} finally {
  await driver.close().catch(() => {});
  process.exit(0);
}
