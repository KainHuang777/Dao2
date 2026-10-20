import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = 'docs/verification/artifacts/early-v1-d/diag-recipe';
fs.mkdirSync(DIR, { recursive: true });
const driver = await connectDriver({ cdpPort: CDP_PORT, httpPort: HTTP_PORT, debugPrinter: () => {} });
const n = process.env.TAG || 'home';
try {
  await driver.bringToFront();
  await sleep(500);
  const f = path.join(DIR, 'L10-' + n + '.png');
  await driver.screenshot(f);
  console.log('shot', f);
  const s = summarizeSave(await driver.readSave());
  console.log('era', s.era, 'level', s.level, 'res', JSON.stringify(s.resources), 'jobs', JSON.stringify(s.economy.jobs));
} finally { await driver.close().catch(() => {}); }
process.exit(0);
