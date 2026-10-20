import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || 9240);
const HTTP_PORT = Number(process.env.HTTP_PORT || 4380);
const SHOT = process.env.SHOT || 'docs/verification/artifacts/early-v1-d/calib.png';
const CLICKS = (process.env.CLICKS || '').split(';').map(s => s.trim()).filter(Boolean)
  .map(s => { const [x, y] = s.split(',').map(Number); return { x, y }; });
const WHEELS = (process.env.WHEELS || '').split(';').map(s => s.trim()).filter(Boolean)
  .map(s => { const [x, y, d] = s.split(',').map(Number); return { p: { x, y }, d }; });
const RELOAD = process.env.RELOAD === '1';
const RESET = process.env.RESET === '1';
const SETTLE = Number(process.env.SETTLE || 1200);

const api = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
await api.bringToFront();
if (RESET) {
  const n = await api.evaluate('(()=>{for(let i=localStorage.length-1;i>=0;i--)localStorage.removeItem(localStorage.key(i));return localStorage.length;})()');
  console.log('cleared', n);
}
if (RELOAD || RESET) {
  await api.reload();
  await api.waitFor(() => api.evaluate('document.readyState').then(v => v === 'complete'), 30000, 500, 'reload');
  await api.waitABODE_READY(120000);
  await sleep(2500);
}
console.log('geo', JSON.stringify((await api.geo()).rect));
for (const c of CLICKS) {
  console.log('click', JSON.stringify(c));
  await api.click(c);
  await sleep(SETTLE);
}
for (const w of WHEELS) {
  console.log('wheel', JSON.stringify(w));
  await api.wheel(w.p, w.d);
  await sleep(SETTLE);
}
const sum = summarizeSave(await api.readSave());
console.log('save', JSON.stringify({ era: sum.era, level: sum.level, rev: sum.revision, empty: sum.empty, lingli: sum.resources.lingli && sum.resources.lingli.value, money: sum.resources.money && sum.resources.money.value, wood: sum.resources.wood && sum.resources.wood.value, hut: sum.buildings.hut }));
await api.screenshot(SHOT);
console.log('shot', SHOT);
await api.close();
process.exit(0);
