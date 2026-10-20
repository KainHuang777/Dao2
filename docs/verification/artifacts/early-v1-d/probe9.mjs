import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || 9240);
const HTTP_PORT = Number(process.env.HTTP_PORT || 4380);

function dump(label, api, g) {
  console.log(label, JSON.stringify({ rect: g.rect, scale: Number(g.scale.toFixed(5)) }));
}

const api = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
console.log('page', api.pageUrl);
await api.bringToFront();
try { dump('geo-initial', api, await api.geo()); } catch (e) { console.log('geo-initial ERR', String(e.message)); }

await api.reload();
await api.waitFor(() => api.evaluate('document.readyState').then(v => v === 'complete'), 30000, 500, 'reload');
await api.waitABODE_READY(120000);
await sleep(2000);
try { dump('geo-after-reload', api, await api.geo()); } catch (e) { console.log('geo-after-reload ERR', String(e.message)); }

const dims = await api.evaluate(`(()=>{const c=document.querySelector('canvas');return {canvasW:c?c.width:null,canvasH:c?c.height:null,styleW:c?c.style.width:null,styleH:c?c.style.height:null,iw:window.innerWidth,ih:window.innerHeight,dpr:window.devicePixelRatio};})()`);
console.log('dims', JSON.stringify(dims));
await api.screenshot('docs/verification/artifacts/early-v1-d/probe9-pinned.png');
const sum = summarizeSave(await api.readSave());
console.log('save', JSON.stringify({ era: sum.era, level: sum.level, rev: sum.revision, empty: sum.empty }));
await api.close();
process.exit(0);
