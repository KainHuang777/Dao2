import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/drive-era2';
const MAX_MS = Number(process.env.MAX_MS || 6000000);
const LINGLI_PER_LEVEL = 200;
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'events.jsonl'), { flags: 'a' });
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(line + '\n'); console.log(line); }

const P = {
  offline_close: { x: 278, y: 287 },
  dock_home: { x: 95, y: 668 },
  dock_management: { x: 191, y: 668 },
  level_up: { x: 278, y: 82 },
  breakthrough: { x: 252, y: 112 },
};

const TAB_FROM_BUILDINGS = { buildings: { x: 770, y: 46 }, outposts: { x: 875, y: 46 }, manufacturing: { x: 951, y: 46 }, transport: { x: 1038, y: 46 } };
const TAB_IN_MFG = { buildings: { x: 496, y: 46 }, outposts: { x: 612, y: 46 }, transport: { x: 780, y: 46 } };
const CAT = { all: { x: 758, y: 214 }, produce: { x: 950, y: 214 }, storage: { x: 1154, y: 214 } };
const RESERVOIR_BUILD = { x: 909, y: 543 };

const RECIPES = {
  bronze_essence: { island: 'ore', title: { x: 613, y: 220 }, label: '銅精' },
  spirit_timber: { island: 'wood', title: { x: 1006, y: 220 }, label: '靈材' },
  liquid: { island: 'home', title: { x: 613, y: 446 }, label: '丹液' },
};
const TITLE_Y_TRY = { bronze_essence: [220, 232, 210], spirit_timber: [220, 232, 210], liquid: [446, 458, 468, 432, 470] };
const MODE_DD = { x: 855, y: 468 };
const MODE_REPEAT = { x: 560, y: 596 };
const SCROLL_AT = { x: 850, y: 560 };
const START_BTN = { x: 848, y: 577 };
const START_YS = [577, 560, 600, 620, 640, 540, 660, 512, 690];
const BACK_LIST = { x: 1190, y: 126 };
const ROUTE_XS = [852, 822, 882, 912, 792, 940];
const ROUTE_YS = [410, 380, 440, 350, 470, 500, 520, 560, 600];
const LIQUID_STOP_XS = [780, 780, 780];
const LIQUID_STOP_YS = [488, 452, 516];

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (label) => { try { const f = path.join(DIR, 'shot-' + label + '.png'); await driver.screenshot(f); return f; } catch (e) { return null; } };
const save = async () => summarizeSave(await driver.readSave());
function rv(s, id) { const r = s.resources[id]; return r ? Number(r.value) : 0; }
function exportSave(tag) {
  try {
    const raw = driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'),main:localStorage.getItem(ns+':'+slot)};})()`);
    return raw.then(r => {
      fs.writeFileSync(path.join(DIR, tag + '.json'), r.main || '', 'utf8');
      fs.writeFileSync(path.join(DIR, tag + '.index.json'), r.index || '', 'utf8');
    }).catch(e => rec('export_error', { tag, error: String(e) }));
  } catch (e) { rec('export_error', { tag, error: String(e) }); return Promise.resolve(); }
}

let page = 'unknown';
async function dismiss() { for (let i = 0; i < 3; i++) { try { await driver.click(P.offline_close); } catch (e) {} await sleep(350); } }
async function gotoBuildings() {
  await driver.bringToFront();
  await driver.reload();
  await sleep(6500);
  await driver.bringToFront();
  await dismiss();
  await driver.click(P.dock_management);
  await sleep(1800);
  page = 'buildings';
}
async function tab(target, from) {
  const map = from === 'manufacturing' ? TAB_IN_MFG : TAB_FROM_BUILDINGS;
  const p = map[target];
  if (!p) throw new Error('no tab ' + target + ' from ' + from);
  await driver.click(p);
  await sleep(1500);
  page = target;
}

async function startContinuous(key) {
  const r = RECIPES[key];
  if ((await save()).economy.jobs[r.island] !== undefined) { rec('already_running', { key, island: r.island }); return true; }
  await gotoBuildings();
  await tab('manufacturing', 'buildings');
  const ys = TITLE_Y_TRY[key] || [r.title.y];
  for (const ty of ys) {
    await driver.click({ x: r.title.x, y: ty });
    await sleep(1500);
    await driver.click(MODE_DD);
    await sleep(1000);
    await driver.click(MODE_REPEAT);
    await sleep(1000);
    for (const y of START_YS) {
      await driver.click({ x: START_BTN.x, y });
      await sleep(1300);
      const s = await save();
      const job = s.economy.jobs[r.island];
      if (job !== undefined) {
        rec('start_continuous', { key, island: r.island, titleY: ty, startY: y, job });
        await exportSave('save-start-' + key);
        return true;
      }
    }
    rec('start_attempt_failed', { key, titleY: ty });
    await gotoBuildings();
    await tab('manufacturing', 'buildings');
  }
  rec('start_continuous_failed', { key });
  return false;
}

async function enableCopperRoute() {
  if ((await save()).economy.routes.includes('bronze_home')) { rec('route_already', {}); return true; }
  await gotoBuildings();
  await tab('transport', 'buildings');
  for (const y of ROUTE_YS) {
    for (const x of ROUTE_XS) {
      await driver.click({ x, y });
      await sleep(1000);
      const s = await save();
      if (s.economy.routes.includes('bronze_home')) { rec('route_enabled', { x, y, routes: s.economy.routes }); return true; }
    }
  }
  rec('route_enable_failed', {});
  return false;
}

async function stopLiquid() {
  if ((await save()).economy.jobs.home === undefined) return true;
  await gotoBuildings();
  await tab('manufacturing', 'buildings');
  for (let i = 0; i < LIQUID_STOP_YS.length; i++) {
    await driver.click({ x: LIQUID_STOP_XS[i], y: LIQUID_STOP_YS[i] });
    await sleep(2500);
    const s = await save();
    if (s.economy.jobs.home === undefined) { rec('liquid_stopped', { at: LIQUID_STOP_YS[i] }); return true; }
  }
  rec('liquid_stop_failed', { jobs: (await save()).economy.jobs });
  return false;
}

async function buildReservoir(level) {
  await driver.click(CAT.storage);
  await sleep(900);
  for (const y of [RESERVOIR_BUILD.y, RESERVOIR_BUILD.y - 60, RESERVOIR_BUILD.y + 60, RESERVOIR_BUILD.y + 120]) {
    await driver.click({ x: RESERVOIR_BUILD.x, y });
    await sleep(1600);
    const s = await save();
    if (Number(s.buildings.foundation_reservoir || 0) >= level) { rec('reservoir_built', { level, at: y, now: s.buildings.foundation_reservoir }); return true; }
  }
  rec('reservoir_build_failed', { level });
  return false;
}

const t0 = Date.now();
let tick = 0;
let lastSetupCheck = 0;
try {
  driver.onConsoleLine(() => {});
  rec('run_start', { cdpPort: CDP_PORT });
  await gotoBuildings();
  let s = await save();
  rec('state_initial', { era: s.era, level: s.level, buildings: s.buildings, jobs: s.economy.jobs, routes: s.economy.routes });
  await exportSave('save-000-initial');
  await shot('000-initial');

  // ---- setup burst: reservoir L1/L2, continuous production, copper route ----
  if (Number(s.buildings.foundation_reservoir || 0) < 2) {
    await buildReservoir(1);
    await buildReservoir(2);
  }
  await tab('manufacturing', 'buildings');
  await shot('010-mfg-list');
  for (const key of ['spirit_timber', 'bronze_essence']) {
    const s2 = await save();
    if (s2.economy.jobs[RECIPES[key].island] !== undefined) continue;
    await startContinuous(key);
  }
  await stopLiquid();
  await enableCopperRoute();
  await exportSave('save-001-setup');
  rec('setup_done', { s: await save().then(x => ({ jobs: x.economy.jobs, routes: x.economy.routes, buildings: x.buildings })) });
  await driver.click(P.dock_home);
  await sleep(1500);
  page = 'home';

  // ---- passive loop ----
  for (;;) {
    if (Date.now() - t0 > MAX_MS) { rec('budget_exit', {}); break; }
    tick++;
    s = await save();
    const lv = s.level, era = s.era;
    // level up / breakthrough
    await driver.click(P.level_up);
    await sleep(400);
    if (tick % 20 === 0) {
      rec('tick', { tick, era, level: lv, lingli: rv(s, 'lingli'), money: rv(s, 'money'), wood: rv(s, 'wood'), stone_low: rv(s, 'stone_low'), spirit_timber: rv(s, 'spirit_timber'), bronze_essence: rv(s, 'bronze_essence'), liquid: rv(s, 'liquid'), spirit_grass_low: rv(s, 'spirit_grass_low'), black_copper: rv(s, 'black_copper'), jobs: s.economy.jobs, trips: s.economy.trips, routes: s.economy.routes, reservoir: s.buildings.foundation_reservoir });
    }
    if (Date.now() - lastSetupCheck > 90000) {
      lastSetupCheck = Date.now();
      const missing = ['spirit_timber', 'bronze_essence'].filter(k => s.economy.jobs[RECIPES[k].island] === undefined);
      if (missing.length) {
        rec('setup_refresh', { missing });
        await gotoBuildings();
        await tab('manufacturing', 'buildings');
        for (const key of missing) { await startContinuous(key); }
      }
      if (s.economy.jobs.home !== undefined) { await stopLiquid(); }
      if (rv(s, 'liquid') < 40 && s.economy.jobs.home === undefined) {
        rec('liquid_topup', { liquid: rv(s, 'liquid') });
        await startContinuous('liquid');
      }
      if (!s.economy.routes.includes('bronze_home')) { await enableCopperRoute(); }
      if (Number(s.buildings.foundation_reservoir || 0) < 2) {
        await gotoBuildings();
        await buildReservoir(2);
      }
      await gotoBuildings();
      await exportSave('save-tick-' + tick);
      await shot('tick-' + tick);
    }
    if (era !== 2 || lv >= 10) {
      rec('phase_change', { era, level: lv });
      break;
    }
    await sleep(2200);
  }
  await exportSave('save-final');
  await shot('999-final');
  rec('run_end', { tick, s: await save().then(x => ({ era: x.era, level: x.level, buildings: x.buildings, jobs: x.economy.jobs, routes: x.economy.routes })) });
} catch (e) {
  rec('run_error', { error: String(e && e.stack ? e.stack : e) });
  await shot('999-error');
} finally {
  await driver.close().catch(() => {});
  log.end();
  process.exit(0);
}
