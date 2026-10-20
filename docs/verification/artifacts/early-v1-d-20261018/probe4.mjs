import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const driver = await connectDriver({ cdpPort: 9240, matchPort: '4310', debugPrinter: l => console.log('[drv]', l) });
await driver.send('Page.enable').catch(() => {});
for (const url of ['http://127.0.0.1:4310/compression.json', 'http://127.0.0.1:4310/index.html']) {
  try {
    const r = await driver.send('Page.navigate', { url });
    console.log('navigate', url, '=>', JSON.stringify(r));
  } catch (e) { console.log('navigate', url, 'ERR', String(e).slice(0, 200)); }
  await sleep(4000);
  try {
    const h = await driver.send('Page.getNavigationHistory');
    console.log('  history entries:', h.entries.length, 'index:', h.currentIndex, h.entries.slice(-3).map(e => e.url));
    const st = await driver.evaluate(`({href:location.href, origin:location.origin})`);
    console.log('  eval:', JSON.stringify(st));
  } catch (e) { console.log('  post ERR', String(e).slice(0, 200)); }
}
await driver.close();
