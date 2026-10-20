import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
import fs from 'node:fs';
import path from 'node:path';

const CDP_PORT = Number(process.env.CDP_PORT || 9240);
const HTTP_PORT = Number(process.env.HTTP_PORT || 4380);
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/gatherdiag';
const RELOAD = process.env.RELOAD === '1';
const SETTLE = Number(process.env.SETTLE || 1600);
const PTS = (process.env.PTS || '').split(';').map(s => s.trim()).filter(Boolean)
  .map(s => { const [x, y] = s.split(',').map(Number); return { x, y }; });

fs.mkdirSync(DIR, { recursive: true });

const api = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const cons = [];
api.onConsoleLine(l => { cons.push(l.text); });
await api.bringToFront();
const g = await api.geo();
console.log('geo', JSON.stringify(g.rect), 'scale', g.scale);
if (RELOAD) {
  await api.reload();
  await api.waitFor(() => api.evaluate('document.readyState').then(v => v === 'complete'), 30000, 500, 'reload');
  await api.waitABODE_READY(120000);
  await sleep(2500);
}

function sm(s) {
  const sum = summarizeSave(s);
  return { rev: sum.revision, empty: sum.empty, era: sum.era, level: sum.level,
    lingli: sum.resources.lingli && sum.resources.lingli.value,
    money: sum.resources.money && sum.resources.money.value,
    wood: sum.resources.wood && sum.resources.wood.value,
    hut: sum.buildings.hut };
}

await api.screenshot(path.join(DIR, 'shot-00-before.png'));
console.log('before', JSON.stringify(sm(await api.readSave())));

let i = 0;
for (const p of PTS) {
  i++;
  const beforeCons = cons.length;
  await api.click(p);
  await sleep(SETTLE);
  const f = path.join(DIR, 'shot-' + String(i).padStart(2, '0') + '-' + p.x + 'x' + p.y + '.png');
  await api.screenshot(f);
  console.log('click#' + i, p.x + ',' + p.y, JSON.stringify(sm(await api.readSave())), 'shot', f);
  const newLines = cons.slice(beforeCons).filter(t => /採集|gather|STALE|受阻|受限|失敗|阻/.test(t));
  if (newLines.length) console.log('  cons:', JSON.stringify(newLines));
}

const tail = cons.slice(-40).filter(t => /ABODE|gather|採集|STALE|資源/.test(t));
console.log('consoleTail', JSON.stringify(tail));
await api.close();
process.exit(0);
