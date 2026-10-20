import fs from 'node:fs';
import { connectDriver, httpJson, sleep } from '../res1d2-natural-mouse-driver.mjs';

const list = await httpJson(9240, '/json/list');
console.log('TARGETS:');
for (const t of list) console.log(' ', t.type, '|', JSON.stringify(t.url), '|', t.id, t.title ? ('| ' + t.title) : '');

const driver = await connectDriver({ cdpPort: 9240, matchPort: '4310', debugPrinter: l => console.log('[drv]', l) });
try {
  await driver.bringToFront();
  const r = await driver.send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync('docs/verification/artifacts/early-v1-d-20261018/edge-screen.png', Buffer.from(r.data, 'base64'));
  console.log('screenshot saved');
} catch (e) { console.log('screenshot err', String(e)); }
await driver.close();
