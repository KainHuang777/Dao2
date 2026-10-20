import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/drive-era1';
const MAX_MS = Number(process.env.MAX_MS || 2400000);
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'log.jsonl'), { flags: 'a' });
function rec(type, data) { log.write(JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }) + '\n'); }

const P = {
  popup_offline_close: { x: 278, y: 287 },
  dock_management: { x: 176, y: 668 },
  tab_all: { x: 754, y: 213 },
  ribbon_mode_full: { x: 289, y: 268 },
  level_up: { x: 323, y: 75 },
  gather_lingli: { x: 306, y: 329 },
  gather_money: { x: 306, y: 393 },
  gather_wood: { x: 306, y: 456 },
  gather_stone: { x: 306, y: 519 }
};

// clean 全部 layout (no expansion, no scroll): row1 y=328/297, row2 y=451, row3 y=573
const BTN = {
  hut: { x: 908, y: 328 },
  storage_lingli: { x: 1214, y: 297 },
  wooden_house: { x: 908, y: 451 },
  forest_farm: { x: 1212, y: 451 },
  stone_mine: { x: 905, y: 573 },
  herb_farm: { x: 1213, y: 573 }
};
const COSTS = {
  hut: { base: { lingli: 20 }, cf: 1.5 },
  wooden_house: { base: { money: 20, lingli: 30 }, cf: 1.45 },
  forest_farm: { base: { money: 20, lingli: 20 }, cf: 1.5 },
  stone_mine: { base: { wood: 10, money: 20 }, cf: 1.5 },
  herb_farm: { base: { stone_low: 10, wood: 20 }, cf: 1.7 },
  storage_lingli: { base: { money: 50, wood: 20 }, cf: 1.2 }
};
const PREREQ = {
  wooden_house: { hut: 2 },
  forest_farm: { wooden_house: 2 },
  stone_mine: { forest_farm: 3 },
  herb_farm: { stone_mine: 3 },
  storage_lingli: { herb_farm: 3 },
  hut: {}
};
// era1 needs, in order
const NEEDS = [
  { id: 'hut', target: 2 },
  { id: 'wooden_house', target: 2 },
  { id: 'forest_farm', target: 3 },
  { id: 'stone_mine', target: 3 },
  { id: 'herb_farm', target: 3 },
  { id: 'storage_lingli', target: 1 }
];

let shotN = 0;
async function shot(driver, label) { shotN++; const f = path.join(DIR, String(shotN).padStart(3, '0') + '-' + label + '.png'); try { await driver.screenshot(f); } catch (e) {} return f; }
async function exportSave(driver, tag) {
  try {
    const raw = await driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'), main:localStorage.getItem(ns+':'+slot)};})()`);
    fs.writeFileSync(path.join(DIR, tag + '.json'), raw.main || '', 'utf8');
    fs.writeFileSync(path.join(DIR, tag + '.index.json'), raw.index || '', 'utf8');
  } catch (e) { rec('export_error', { tag, error: String(e) }); }
}
const g = (b, id) => Number(b[id] || 0);
function rv(sum, id) { const r = sum.resources[id]; return r ? Number(r.value) : 0; }
function costOf(id, level) { const c = COSTS[id]; const out = {}; for (const k of Object.keys(c.base)) out[k] = c.base[k] * Math.pow(c.cf, level - 1); return out; }
function prereqMet(b, id) { const p = PREREQ[id] || {}; for (const k of Object.keys(p)) if (g(b, k) < p[k]) return false; return true; }
function affordable(sum, cost) { for (const k of Object.keys(cost)) if (rv(sum, k) < cost[k]) return false; return true; }
function bsum(b) { return NEEDS.map(n => n.id + '=' + g(b, n.id)).join(' '); }

const driver = await connectDriver({ cdpPort: CDP_PORT, debugPrinter: () => {} });
try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click(P.popup_offline_close); } catch (e) {} await sleep(700); }
  await driver.click(P.dock_management);
  await sleep(1500);
  try { await driver.click(P.tab_all); } catch (e) {}
  await sleep(800);
  rec('open_catalog', { geo: driver.geo() });
  const start = Date.now();
  let iter = 0;
  let lastShot = 0;
  let lastBuildClick = 0;
  let lastExport = 0;
  for (;;) {
    if (Date.now() - start > MAX_MS) { console.log('BUDGET'); break; }
    const sum = summarizeSave(await driver.readSave());
    if (!sum.empty && sum.era >= 2) { console.log('BREAKTHROUGH HIT era=' + sum.era); break; }
    if (!sum.empty && sum.era === 1 && sum.level >= 10 && sum.helpers.lingliCap >= 500) { console.log('GOAL reached level=' + sum.level + ' cap=' + sum.helpers.lingliCap); break; }
    iter++;
    const b = sum.buildings || {};
    // keep ribbon + tab stable
    try { await driver.click(P.ribbon_mode_full); } catch (e) {}
    try { await driver.click(P.tab_all); } catch (e) {}
    // find objective
    let obj = null;
    for (const n of NEEDS) { if (g(b, n.id) < n.target) { obj = n; break; } }
    let action;
    let clicked = null;
    if (!obj) {
      action = 'level';
    } else {
      const nextLevel = g(b, obj.id) + 1;
      const cost = costOf(obj.id, nextLevel);
      if (prereqMet(b, obj.id) && affordable(sum, cost)) {
        action = 'build';
        clicked = BTN[obj.id];
      } else {
        action = 'gather';
        // pick the scarcest required resource
        let needId = null, worst = 1;
        for (const k of Object.keys(cost)) {
          const ratio = rv(sum, k) / Math.max(1e-9, cost[k]);
          if (ratio < worst) { worst = ratio; needId = k; }
        }
        if (!needId) needId = 'money';
        const map = { lingli: P.gather_lingli, money: P.gather_money, wood: P.gather_wood, stone_low: P.gather_stone };
        clicked = map[needId] || P.gather_money;
      }
    }
    if (clicked) { try { await driver.click(clicked); } catch (e) {} }
    if (action === 'build') lastBuildClick = Date.now();
    // level-up attempt (harmless if disabled)
    try { await driver.click(P.level_up); } catch (e) {}
    rec('iter', { iter, era: sum.era, level: sum.level, cap: sum.helpers.lingliCap, obj: obj ? obj.id + '/' + obj.target : 'none', action, lingli: rv(sum, 'lingli'), money: rv(sum, 'money'), wood: rv(sum, 'wood'), stone: rv(sum, 'stone_low'), grass: rv(sum, 'spirit_grass_low'), buildings: b });
    if (iter % 6 === 0) console.log('iter=' + iter + ' lv=' + sum.level + ' ' + bsum(b) + ' lingli=' + rv(sum, 'lingli').toFixed(0) + ' money=' + rv(sum, 'money').toFixed(0) + ' wood=' + rv(sum, 'wood').toFixed(0) + ' stone=' + rv(sum, 'stone_low').toFixed(0) + ' obj=' + (obj ? obj.id : '-') + ' act=' + action);
    if (Date.now() - lastShot > 90000) { await shot(driver, 'progress-' + iter); lastShot = Date.now(); }
    if (Date.now() - lastExport > 600000) { await exportSave(driver, 'periodic-' + iter); lastExport = Date.now(); }
    await sleep(650);
  }
  await shot(driver, 'final');
  await exportSave(driver, 'drive-era1-final');
  const fin = summarizeSave(await driver.readSave());
  console.log('final ' + JSON.stringify({ era: fin.era, level: fin.level, cap: fin.helpers.lingliCap, buildings: fin.buildings, lingli: rv(fin, 'lingli'), money: rv(fin, 'money'), wood: rv(fin, 'wood'), stone: rv(fin, 'stone_low'), grass: rv(fin, 'spirit_grass_low') }));
} finally {
  await driver.close().catch(() => {});
}
