import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const driver = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || 9240), debugPrinter: l => console.log('[drv]', l) });
const info = await driver.evaluate(`(()=>{
  const out = { href: location.href, origin: location.origin, readyState: document.readyState };
  try { out.lsKeys = localStorage.length; out.lsOk = true; } catch (e) { out.lsOk = false; out.lsErr = String(e); }
  const c = document.querySelector('canvas');
  out.canvas = c ? (()=>{const r=c.getBoundingClientRect();return {w:r.width,h:r.height,left:r.left,top:r.top};})() : null;
  out.title = document.title;
  return out;
})()`);
console.log(JSON.stringify(info, null, 2));
await sleep(500);
console.log('console tail:', driver.consoleLines.slice(-8).map(l => l.text));
await driver.close();
