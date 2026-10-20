import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const driver = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || 9240), debugPrinter: l => console.log('[drv]', l) });
console.log('target url:', driver.pageUrl);
try { await driver.send('Page.navigate', { url: 'http://127.0.0.1:4310/index.html' }); } catch (e) { console.log('navigate err', String(e)); }
for (let i = 0; i < 20; i++) {
  await sleep(2000);
  let st;
  try { st = await driver.evaluate(`({href:location.href, origin:location.origin, rs:document.readyState, canvas: !!document.querySelector('canvas')})`); }
  catch (e) { st = { err: String(e).slice(0, 160) }; }
  console.log(i, JSON.stringify(st), '| console:', driver.consoleLines.slice(-2).map(l => l.text));
  if (st && st.canvas) break;
}
await driver.close();
